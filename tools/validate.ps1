param(
    [Parameter(Mandatory = $true)]
    [string]$Godot
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$validationRoot = Join-Path $projectRoot ('.godot/validation/run-' + [guid]::NewGuid().ToString('N'))
$previousEnvironment = @{}
foreach ($key in @('APPDATA', 'LOCALAPPDATA', 'APRENDE_VALIDATION')) {
    $previousEnvironment[$key] = [Environment]::GetEnvironmentVariable($key, 'Process')
}

try {
    # Godot editor settings and user:// saves stay inside this validation run.
    $env:APPDATA = Join-Path $validationRoot 'roaming'
    $env:LOCALAPPDATA = Join-Path $validationRoot 'local'
    $env:APRENDE_VALIDATION = '1'
    New-Item -ItemType Directory -Force -Path $env:APPDATA, $env:LOCALAPPDATA | Out-Null
    & $Godot --headless --path $projectRoot --editor --quit --log-file (Join-Path $validationRoot 'import.log') | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'Godot import failed.' }
    & python (Join-Path $PSScriptRoot 'audit_project.py')
    if ($LASTEXITCODE -ne 0) { throw 'Resource audit failed.' }
    & $Godot --headless --path $projectRoot --script res://tests/smoke_test.gd --log-file (Join-Path $validationRoot 'smoke.log') 2>&1 | Tee-Object -FilePath (Join-Path $validationRoot 'runtime-console.log')
    if ($LASTEXITCODE -ne 0) { throw 'Runtime validation failed.' }
    & $Godot --headless --path $projectRoot --script res://tests/regression_test.gd --log-file (Join-Path $validationRoot 'regression.log') 2>&1 | Tee-Object -FilePath (Join-Path $validationRoot 'regression-console.log')
    if ($LASTEXITCODE -ne 0) { throw 'Regression validation failed.' }
    & $Godot --headless --path $projectRoot --script res://tests/numbers_test.gd --log-file (Join-Path $validationRoot 'numbers.log') 2>&1 | Tee-Object -FilePath (Join-Path $validationRoot 'numbers-console.log')
    if ($LASTEXITCODE -ne 0) { throw 'Numbers validation failed.' }
    & $Godot --headless --path $projectRoot --script res://tests/learning_sections_test.gd --log-file (Join-Path $validationRoot 'learning.log') 2>&1 | Tee-Object -FilePath (Join-Path $validationRoot 'learning-console.log')
    if ($LASTEXITCODE -ne 0) { throw 'Learning sections validation failed.' }
    & $Godot --headless --path $projectRoot --script res://tests/stories_test.gd --log-file (Join-Path $validationRoot 'stories.log') 2>&1 | Tee-Object -FilePath (Join-Path $validationRoot 'stories-console.log')
    if ($LASTEXITCODE -ne 0) { throw 'Stories validation failed.' }
    $logs = Get-Content -LiteralPath (Join-Path $validationRoot 'import.log'), (Join-Path $validationRoot 'runtime-console.log'), (Join-Path $validationRoot 'regression-console.log'), (Join-Path $validationRoot 'numbers-console.log'), (Join-Path $validationRoot 'learning-console.log'), (Join-Path $validationRoot 'stories-console.log')
    if ($logs | Select-String -Pattern 'SCRIPT ERROR:|^ERROR:') { throw 'Godot reported errors. Review the validation logs.' }
    Write-Host "Validation passed. Logs: $validationRoot"
}
finally {
    foreach ($key in $previousEnvironment.Keys) {
        [Environment]::SetEnvironmentVariable($key, $previousEnvironment[$key], 'Process')
    }
}
