#requires -Version 5.1
<#
  dsh-purge-community · asar swap (automatic)
  Switches Electron from resources/app.asar to the patched resources/app tree.
  WARNING: this force-closes DeepSeek Harness (tray included).
#>
$ErrorActionPreference = 'Continue'
. (Join-Path $PSScriptRoot '_dsh-root.ps1')

$script:killed = 0
$P = Get-DshPaths
if (-not $P) {
  Say 'FATAL: cannot locate the DeepSeek Harness install folder.'
  Say 'Set it explicitly then rerun:  $env:DSH_ROOT = "D:/deepseek"'
  Read-Host 'Press Enter to exit'; exit 1
}
Say ('DSH root = ' + $P.Root)

Say '== 0. preflight =='
$need = @(
  (Join-Path $P.App 'package.json'),
  (Join-Path $P.App 'lib\main.js'),
  (Join-Path $P.App 'dsh\node_modules\@deepseek-ai\dsh-desktop-host\lib\index.js')
)
foreach ($f in $need) {
  if (-not (Test-Path -LiteralPath $f)) { Say ('FATAL missing: ' + $f); Read-Host 'Press Enter to exit'; exit 2 }
}
Say 'preflight ok'

if (-not (Test-Path -LiteralPath $P.Asar)) {
  if (Test-Path -LiteralPath $P.Bak) { Say 'already switched - just starting'; Start-Process -FilePath $P.Exe; Start-Sleep 2; exit 0 }
  Say 'FATAL: neither app.asar nor app.asar.bak exists'; Read-Host 'Press Enter to exit'; exit 3
}

Say '== 1. stop DeepSeek Harness =='
$n = Stop-DshProcesses $P.Root
Say ('killed=' + $n)
Start-Sleep -Milliseconds 800

Say '== 2. rename app.asar -> app.asar.bak =='
$ok = $false
for ($i = 1; $i -le 120; $i++) {
  try { [System.IO.File]::Move($P.Asar, $P.Bak); $ok = $true; break }
  catch { Start-Sleep -Milliseconds 500 }
}
if (-not $ok) {
  Say 'FAIL: app.asar still locked after 60s'
  Say 'TIP: add the install folder to the 360 trust list (or pause real-time protection), then run again.'
  Read-Host 'Press Enter to exit'; exit 4
}
Say ('renamed ok -> ' + $P.Bak)

Say '== 3. launch =='
Start-Process -FilePath $P.Exe
Start-Sleep -Seconds 10
$rend = Get-CimInstance Win32_Process -Filter "Name='DeepSeek Harness.exe'" | Where-Object { $_.CommandLine -match '--type=renderer' } | Select-Object -First 1
if ($rend -and ($rend.CommandLine -match '--app-path="([^"]+)"')) {
  Say ('app-path = ' + $Matches[1])
  if ($Matches[1] -match '\.asar') { Say 'WARN: still loading asar' } else { Say 'VERIFIED: loading resources/app (patched)' }
} else {
  Say 'note: renderer not observed yet, please check manually'
}
Say 'DONE'
Read-Host 'Press Enter to close'
