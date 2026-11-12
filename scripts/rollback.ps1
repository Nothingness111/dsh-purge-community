#requires -Version 5.1
<#
  dsh-purge-community · rollback
  Moves app.asar.bak back to app.asar so the original sealed archive loads again.
#>
$ErrorActionPreference = 'Continue'
. (Join-Path $PSScriptRoot '_dsh-root.ps1')

$script:killed = 0
$P = Get-DshPaths
if (-not $P) { Say 'FATAL: cannot locate the DeepSeek Harness install folder.'; Read-Host 'Press Enter'; exit 1 }
Say ('DSH root = ' + $P.Root)

if (-not (Test-Path -LiteralPath $P.Bak)) { Say 'no app.asar.bak found; nothing to roll back'; Read-Host 'Press Enter'; exit 0 }
if (Test-Path -LiteralPath $P.Asar) { Say 'app.asar already present; nothing to do'; Read-Host 'Press Enter'; exit 0 }

Say 'stopping DeepSeek Harness'
[void](Stop-DshProcesses $P.Root)
Start-Sleep -Milliseconds 800

$ok = $false
for ($i = 1; $i -le 120; $i++) {
  try { [System.IO.File]::Move($P.Bak, $P.Asar); $ok = $true; break }
  catch { Start-Sleep -Milliseconds 500 }
}
if (-not $ok) { Say 'FAIL: app.asar.bak still locked'; Read-Host 'Press Enter to exit'; exit 4 }
Say 'restored app.asar'
Start-Process -FilePath $P.Exe
Say 'DONE'
Read-Host 'Press Enter to close'
