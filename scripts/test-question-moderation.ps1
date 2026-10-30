$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$testDir = Join-Path ([IO.Path]::GetTempPath()) ('quest-moderation-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testDir | Out-Null
$dll = Join-Path $repo 'backend_api/bin/moderation-check/EnglishRpg.Api.dll'
if (!(Test-Path $dll)) { throw 'Build first: dotnet build backend_api -o backend_api/bin/moderation-check' }
$env:ConnectionStrings__Sqlite = "Data Source=$testDir/test.db"
$env:ASPNETCORE_ENVIRONMENT = 'Development'
$env:Logging__LogLevel__Microsoft = 'Warning'
dotnet $dll --seed *> (Join-Path $testDir 'seed.log')
if ($LASTEXITCODE -ne 0) { throw "Seed failed: $testDir" }
$server = Start-Process dotnet -ArgumentList @($dll, '--urls', 'http://127.0.0.1:5151') -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $testDir 'server.log') -RedirectStandardError (Join-Path $testDir 'error.log')
try {
  for ($i=0; $i -lt 30; $i++) { try { Invoke-RestMethod 'http://127.0.0.1:5151/health' | Out-Null; break } catch { Start-Sleep -Milliseconds 300 } }
  function Api($path, $data=$null, $token='', $method='POST', $expected=200) {
    $args=@{Uri="http://127.0.0.1:5151/api/$path"; Method=$method; SkipHttpErrorCheck=$true; Headers=@{}}
    if($token){$args.Headers.Authorization="Bearer $token"}
    if($null -ne $data){$args.ContentType='application/json';$args.Body=$data|ConvertTo-Json -Depth 8}
    $r=Invoke-WebRequest @args
    if([int]$r.StatusCode -ne $expected){throw "$path expected $expected got $($r.StatusCode): $($r.Content)"}
    if($r.Content){return $r.Content|ConvertFrom-Json}
  }
  function Assert($condition,$message){if(!$condition){throw $message}; Write-Host "PASS $message"}
  $admin=Api 'auth/login' @{username='admin';password='Admin123456'}
  $user=Api 'auth/register' @{username='moderation_test';password='TestPassword123'}
  $token=$user.token; $id=$user.player.id; $at=$admin.token
  $bank=Api 'admin/questions' $null $at 'GET'
  $keys=@{}; foreach($q in $bank){$keys[$q.id]=$q}
  function Attempt($stage,$correct) {
    $a=Api "stages/$stage/start" @{playerId=$id;restart=$true} $token
    $index=0
    foreach($q in $a.questions){$key=$keys[$q.questionId]; $qid=$key.id; $choice=$key.correctOption; if($index -ge $correct){$choice=if($choice -eq 'A'){'B'}else{'A'}}; Api "attempts/$($a.attemptId)/answer" @{questionId=$qid;selectedOption=$choice} $token | Out-Null; $index++ }
    return $a
  }
  $a=Attempt 1 7
  $wrong=$a.questions[7]; $qid=if($wrong.id){$wrong.id}else{$wrong.questionId}; $old=$keys[$qid]; $choice=if($old.correctOption -eq 'A'){'B'}else{'A'}
  Api "attempts/$($a.attemptId)/hint/next" @{questionId=$qid} $token | Out-Null
  $finish=Api "attempts/$($a.attemptId)/finish" $null $token
  Assert ($finish.expEarned -eq 1340) 'initial hint cost and failed score'
  Api "admin/questions/$qid/resolve" @{mode='correct';reason='Wrong answer key';correctOption=$choice} $at | Out-Null
  $p=Api "players/$id" $null $token 'GET'
  Assert ($p.totalExp -eq 1600) 'correction adds EXP and refunds hint'
  $history=Api "players/$id/history" $null $token 'GET'
  Assert ($history[0].status -eq 'Passed' -and $history[0].compensationExp -eq 260) 'retroactive pass and compensation visible'
  $stages=Api "stages?playerId=$id" $null $token 'GET'
  Assert ($stages[1].status -ne 'locked') 'next stage unlocked'
  $repeat=Api "admin/questions/$qid/resolve" @{mode='correct';reason='Repeat correction';correctOption=$choice} $at
  Assert ($repeat.exp -eq 0) 'repeated correction cannot duplicate credit'
  $q2=$a.questions[8]; $qid2=if($q2.id){$q2.id}else{$q2.questionId}
  Api "admin/questions/$qid2/resolve" @{mode='void';reason='Ambiguous question'} $at | Out-Null
  $p=Api "players/$id" $null $token 'GET'
  Assert ($p.totalExp -eq 1800) 'void grants full credit without reducing balance'
  $q3=$a.questions[9]; $qid3=if($q3.id){$q3.id}else{$q3.questionId}
  Api "admin/questions/$qid3/resolve" @{mode='retire';reason='Old curriculum'} $at | Out-Null
  $p=Api "players/$id" $null $token 'GET'
  Assert ($p.totalExp -eq 1800) 'retire preserves history and balance'
  $used=$keys[$a.questions[0].questionId]
  $edit=@{stageId=1;content='Replacement text';optionA=$used.optionA;optionB=$used.optionB;optionC=$used.optionC;optionD=$used.optionD;correctOption=$used.correctOption}
  $replacement=Api "admin/questions/$($used.id)" $edit $at 'PUT' 201
  $original=Api "admin/questions/$($used.id)" $null $at 'GET'
  Assert ($original.content -eq $used.content -and $replacement.id -ne $used.id) 'editing used question creates immutable replacement'
  foreach($s in @(2,3)){ $b=Attempt $s 10; Api "attempts/$($b.attemptId)/finish" $null $token | Out-Null }
  $boss=Attempt 4 12; Api "attempts/$($boss.attemptId)/finish" $null $token | Out-Null
  $before=Api "players/$id" $null $token 'GET'
  foreach($index in @(12,13)) {
    $q=$boss.questions[$index]; $bid=if($q.id){$q.id}else{$q.questionId}; $choice=if($keys[$bid].correctOption -eq 'A'){'B'}else{'A'}
    Api "admin/questions/$bid/resolve" @{mode='correct';reason='Boss key correction';correctOption=$choice} $at | Out-Null
  }
  $after=Api "players/$id" $null $token 'GET'
  Assert (($after.totalExp-$before.totalExp) -eq 2000) 'Boss compensation bonus paid exactly once'
  $active=Attempt 2 7
  $qidActive=$active.questions[7].questionId
  $choiceActive=if($keys[$qidActive].correctOption -eq 'A'){'B'}else{'A'}
  Api "admin/questions/$qidActive/resolve" @{mode='correct';reason='Correction while playing';correctOption=$choiceActive} $at | Out-Null
  $activeFinish=Api "attempts/$($active.attemptId)/finish" $null $token
  Assert ($activeFinish.correctCount -eq 8 -and $activeFinish.expEarned -eq 2400) 'in-progress correction applied on finish'
  $history=Api "players/$id/history" $null $token 'GET'
  Assert (@($history | Where-Object { $_.stageName -like '*2:*' -and $_.correctCount -eq 10 }).Count -eq 1) 'previously correct answers remain credited'
  $voidAgain=Api "admin/questions/$qid2/resolve" @{mode='void';reason='Repeat void'} $at
  Assert ($voidAgain.exp -eq 0) 'repeat void cannot award twice'
  $stages=Api "stages?playerId=$id" $null $token 'GET'
  Assert (($stages | Where-Object status -eq 'locked').Count -eq 0) 'all unlocked stages stay unlocked'
  Api "admin/questions/$qid/resolve" @{mode='void';reason='Unauthorized'} $token 'POST' 403 | Out-Null
  Write-Host "ALL MODERATION CHECKS PASSED. Isolated fixtures: $testDir"
} finally { Stop-Process -Id $server.Id -ErrorAction SilentlyContinue }
