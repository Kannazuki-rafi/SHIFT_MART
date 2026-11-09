param([Parameter(Mandatory=$true)][string]$Godot, [int]$Port = 24671, [switch]$Exported)
$ErrorActionPreference = 'Stop'
$projectPath = Split-Path $PSScriptRoot -Parent
$logPath = Join-Path $env:TEMP ('shift-mart-test-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $logPath | Out-Null
$processes = @()
$baseArgs = @('--headless')
if (-not $Exported) { $baseArgs += @('--path',('"' + $projectPath + '"')) }
try {
    $processes += Start-Process -FilePath $Godot -ArgumentList ($baseArgs + @('--log-file',('"' + (Join-Path $logPath 'host.log') + '"'),'--',"--auto-host=$Port",'--name=HOST','--test-ready','--test-events','--test-seconds=18')) -WindowStyle Hidden -PassThru
    Start-Sleep -Milliseconds 600
    foreach ($index in 1..3) {
        $processes += Start-Process -FilePath $Godot -ArgumentList ($baseArgs + @('--log-file',('"' + (Join-Path $logPath "client-$index.log") + '"'),'--',"--auto-join=$Port","--name=RIDER$index",'--test-ready','--test-events','--test-seconds=16')) -WindowStyle Hidden -PassThru
    }
    foreach ($process in $processes) {
        if (-not $process.WaitForExit(30000)) { throw 'A test process timed out.' }
        if ($process.ExitCode -ne 0) { throw "Process failed: $($process.ExitCode)" }
    }
    foreach ($log in Get-ChildItem -LiteralPath $logPath -Filter '*.log') {
        $content = Get-Content -LiteralPath $log.FullName -Raw
        if ($content -notmatch 'NETWORK VERIFIED: session=1 carts=4' -or $content -notmatch 'WORLD LOADED session=2 players=4' -or $content -notmatch 'SHIFT VERIFIED: session=1 layout=Orange host_gear=Rush' -or $content -notmatch 'EVENT VERIFIED: cabinet_trigger=' -or $content -match 'SCRIPT ERROR|above the MTU') { throw "Verification failed: $($log.FullName)" }
    }
    $triggers = @(Get-ChildItem -LiteralPath $logPath -Filter '*.log' | ForEach-Object { [regex]::Match((Get-Content -LiteralPath $_.FullName -Raw),'EVENT VERIFIED: cabinet_trigger=(\d+)').Groups[1].Value } | Select-Object -Unique)
    if ($triggers.Count -ne 1) { throw 'Cabinet trigger timestamp differs across peers.' }
    Write-Output "PASS: four ENet processes, movement, shift/gear, identical cabinet warning timestamps and clean rematch. Logs: $logPath"
} finally {
    foreach ($process in $processes) { if (-not $process.HasExited) { Stop-Process -Id $process.Id } }
}
