param([string]$Api = 'http://127.0.0.1:5137/api')
$ErrorActionPreference = 'Stop'
function Call-Api($method, $path, $token, $body, $expected = 200) {
    $headers = @{}
    if ($token) { $headers.Authorization = "Bearer $token" }
    $parameters = @{ Uri="$Api/$path"; Method=$method; Headers=$headers; SkipHttpErrorCheck=$true }
    if ($null -ne $body) { $parameters.ContentType='application/json'; $parameters.Body=($body | ConvertTo-Json -Depth 8) }
    $response = Invoke-WebRequest @parameters
    if ([int]$response.StatusCode -ne $expected) { throw "$method $path : expected $expected, got $($response.StatusCode)" }
    if ($response.Content) { return $response.Content | ConvertFrom-Json }
}
$suffix = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
$credentialsA = @{username="test_a_$suffix"; password='OnlyForTests12345'}
$credentialsB = @{username="test_b_$suffix"; password='OnlyForTests12345'}
$a = Call-Api POST 'auth/register' $null $credentialsA
$b = Call-Api POST 'auth/register' $null $credentialsB
if ($a.player.totalExp -ne 0 -or $b.player.totalExp -ne 0) { throw 'New player must start at zero' }
$null = Call-Api POST 'auth/register' $null $credentialsA 409
$null = Call-Api POST 'auth/register' $null @{username='x'; password='short'} 400
$null = Call-Api POST 'auth/login' $null @{username=$credentialsA.username; password='WrongPassword123'} 401
$null = Call-Api GET "players/$($a.player.id)" $null $null 401
$null = Call-Api GET "players/$($a.player.id)" ('0' * 64) $null 401
$null = Call-Api GET "players/$($a.player.id)" $b.token $null 403
$null = Call-Api GET "stages?playerId=$($a.player.id)" $b.token $null 403
$null = Call-Api PUT "players/$($a.player.id)/target" $b.token @{universityId=1} 403
$null = Call-Api POST 'stages/1/start' $b.token @{playerId=$a.player.id; restart=$true} 403
$null = Call-Api POST 'players/login' $a.token @{name='bypass'} 410
$target = Call-Api PUT "players/$($a.player.id)/target" $a.token @{universityId=1}
$attempt = Call-Api POST 'stages/1/start' $a.token @{playerId=$a.player.id; restart=$true}
foreach ($path in @("attempts/$($attempt.attemptId)","attempts/$($attempt.attemptId)/summary")) {
    $null = Call-Api GET $path $b.token $null 403
}
foreach ($action in @('answer','hint/next','finish')) {
    $null = Call-Api POST "attempts/$($attempt.attemptId)/$action" $b.token @{questionId=$attempt.questions[0].questionId;selectedOption='A'} 403
}
for ($i=0; $i -lt $attempt.questions.Count; $i++) {
    $option = if ($i -eq 0) { 'B' } else { 'A' }
    $null = Call-Api POST "attempts/$($attempt.attemptId)/answer" $a.token @{questionId=$attempt.questions[$i].questionId;selectedOption=$option}
}
$null = Call-Api POST "attempts/$($attempt.attemptId)/finish" $a.token $null
$before = Call-Api GET "players/$($a.player.id)" $a.token $null
if ($before.totalExp -lt 200) { throw 'Stage EXP not saved' }
$null = Call-Api POST 'practice/answer' $a.token @{questionId='t1';selectedIndex=0}
$a2 = Call-Api POST 'auth/login' $null $credentialsA
if ($a2.player.id -ne $a.player.id -or $a2.player.totalExp -ne $before.totalExp -or $a2.player.targetUniversityId -ne 1) { throw 'Cross-session player sync failed' }
$progress = Call-Api GET 'practice/progress' $a2.token $null
if ($progress.t1 -ne $false) { throw 'Cross-session notebook sync failed' }
$other = Call-Api GET 'practice/progress' $b.token $null
if ($other.PSObject.Properties.Name -contains 't1') { throw 'Progress leaked across players' }
$null = Call-Api POST 'practice/answer' $a2.token @{questionId='t1';selectedIndex=1}
$progress = Call-Api GET 'practice/progress' $a.token $null
if ($progress.t1 -ne $true) { throw 'Resolved mistake failed to sync' }
$null = Call-Api POST 'auth/logout' $a2.token $null 204
$null = Call-Api GET 'practice/progress' $a2.token $null 401
$null = Call-Api GET 'practice/progress' $a.token $null
for ($i=0; $i -lt 5; $i++) {
    $null = Call-Api POST 'auth/login' $null @{username=$credentialsB.username;password='WrongPassword123'} 401
}
$null = Call-Api POST 'auth/login' $null $credentialsB 401
Write-Host 'PASS: registration, duplicate/weak credentials, login, ownership/IDOR checks, stage EXP + target sync, practice sync/isolation, logout revocation.'
Write-Host 'Test accounts are isolated fixtures with a test_ prefix, not real user accounts.'
