param([string]$Api = 'http://127.0.0.1:5137/api', [string]$Token)
$ErrorActionPreference = 'Stop'
if (!$Token) { throw 'Provide -Token from a test account login; grading writes to that account practice notebook.' }
$PSDefaultParameterValues = @{'Invoke-RestMethod:Headers' = @{Authorization="Bearer $Token"}}
$base = "$Api/practice"
$topics = Invoke-RestMethod "$base/topics"
$questions = Invoke-RestMethod "$base/questions"
if ($topics.Count -ne 4 -or $questions.Count -ne 24) { throw 'Bank count mismatch' }
if (@($questions.id | Select-Object -Unique).Count -ne 24) { throw 'Duplicate IDs' }
foreach ($topic in $topics) {
    $subset = Invoke-RestMethod "$base/questions?topicId=$($topic.id)"
    if ($subset.Count -ne $topic.questionCount) { throw 'Topic count mismatch' }
}
foreach ($q in $questions) {
    if ($q.PSObject.Properties.Name -contains 'correctIndex' -or
        $q.PSObject.Properties.Name -contains 'explanation') { throw 'Answer leak' }
    if ($q.options.Count -ne 4) { throw 'Invalid options' }
    $correct = 0
    for ($i = 0; $i -lt 4; $i++) {
        $result = Invoke-RestMethod "$base/answer" -Method Post -ContentType 'application/json' -Body (
            @{questionId=$q.id; selectedIndex=$i} | ConvertTo-Json)
        if ($result.isCorrect) { $correct++ }
        if ($result.isCorrect -ne ($result.correctIndex -eq $i) -or
            [string]::IsNullOrWhiteSpace($result.explanation)) { throw 'Invalid grade' }
    }
    if ($correct -ne 1) { throw 'Question must have exactly one correct answer' }
}
Write-Host 'PASS: 4 topics, 24 unique questions, 96 grading checks, no early answer leak.'
