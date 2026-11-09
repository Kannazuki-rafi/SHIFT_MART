param([Parameter(Mandatory=$true)][string]$Godot, [int]$Port = 24671, [switch]$Exported)
$ErrorActionPreference = 'Stop'
$projectPath = Split-Path $PSScriptRoot -Parent
$logPath = Join-Path $env:TEMP ('shift-mart-test-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $logPath | Out-Null
$processes = @()
$baseArgs = @('--headless')
if (-not $Exported) { $baseArgs += @('--path',('"' + $projectPath + '"')) }
try {
    $processes += Start-Process -FilePath $Godot -ArgumentList ($baseArgs + @('--log-file',('"' + (Join-Path $logPath 'host.log') + '"'),'--',"--auto-host=$Port",'--name=HOST','--test-ready','--test-seconds=18')) -WindowStyle Hidden -PassThru
    Start-Sleep -Milliseconds 600
    foreach ($index in 1..3) {
        $processes += Start-Process -FilePath $Godot -ArgumentList ($baseArgs + @('--log-file',('"' + (Join-Path $logPath "client-$index.log") + '"'),'--',"--auto-join=$Port","--name=RIDER$index",'--test-ready','--test-seconds=16')) -WindowStyle Hidden -PassThru
    }
    foreach ($process in $processes) {
        if (-not $process.WaitForExit(30000)) { throw 'A test process timed out.' }
        if ($process.ExitCode -ne 0) { throw "Process failed: $($process.ExitCode)" }
    }
    foreach ($log in Get-ChildItem -LiteralPath $logPath -Filter '*.log') {
        $content = Get-Content -LiteralPath $log.FullName -Raw
        if ($content -notmatch 'NETWORK VERIFIED: session=1 carts=4' -or $content -notmatch 'WORLD LOADED session=2 players=4' -or $content -notmatch 'SHIFT VERIFIED: session=1 layout=Orange host_gear=Rush' -or $content -match 'SCRIPT ERROR|above the MTU') { throw "Verification failed: $($log.FullName)" }
    }
    Write-Output "PASS: four ENet processes, authoritative movement, shared shift/gear snapshots and clean rematch. Logs: $logPath"
} finally {
    foreach ($process in $processes) { if (-not $process.HasExited) { Stop-Process -Id $process.Id } }
}
