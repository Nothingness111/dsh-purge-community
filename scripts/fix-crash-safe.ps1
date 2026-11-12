#requires -Version 5.1
<#
  dsh-purge-community · asar swap (safe / wait for manual quit)
  Waits up to 300s for you to quit DeepSeek Harness from the tray, then swaps.
#>
$ErrorActionPreference = 'Continue'
. (Join-Path $PSScriptRoot '_dsh-root.ps1')

$script:killed = 0
$P = Get-DshPaths
if (-not $P) {
  Say 'FATAL: cannot locate the DeepSeek Harness install folder.'
  Read-Host 'Press Enter to exit'; exit 1
}
Say ('DSH root = ' + $P.Root)

foreach ($f in @((Join-Path $P.App 'package.json'), (Join-Path $P.App 'lib\main.js'))) {
  if (-not (Test-Path -LiteralPath $f)) { Say ('FATAL missing: ' + $f); Read-Host 'Press Enter to exit'; exit 2 }
}

if ((-not (Test-Path -LiteralPath $P.Asar)) -and (Test-Path -LiteralPath $P.Bak)) {
  Say 'already switched - just starting'; Start-Process -FilePath $P.Exe; exit 0
}

Say '== wait for app.asar to be released =='
Say '   QUIT DeepSeek Harness now: right-click the TRAY icon -> Exit (closing the window is not enough)'
$deadline = (Get-Date).AddSeconds(300)
$free = $false
while ((Get-Date) -lt $deadline) {
  try { $fs = [System.IO.File]::Open($P.Asar, 'Open', 'ReadWrite', 'None'); $fs.Close(); $free = $true; break }
  catch { Start-Sleep -Milliseconds 700 }
}
if (-not $free) { Say 'FAIL: app.asar still locked after 300s'; Read-Host 'Press Enter to exit'; exit 4 }
Say 'asar released'

try { [System.IO.File]::Move($P.Asar, $P.Bak) } catch { Say ('FAIL move: ' + $_.Exception.Message); Read-Host 'Press Enter to exit'; exit 5 }
Say ('renamed ok -> ' + $P.Bak)
Start-Process -FilePath $P.Exe
Say 'DONE'
Read-Host 'Press Enter to close'
