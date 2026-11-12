# Shared helper: locate the DeepSeek Harness install root.
# Priority: $env:DSH_ROOT > running process > common install paths > registry.
function Get-DshRoot {
  if ($env:DSH_ROOT) { return $env:DSH_ROOT }
  $cands = New-Object System.Collections.ArrayList
  $p = Get-CimInstance Win32_Process -Filter "Name='DeepSeek Harness.exe'" -ErrorAction SilentlyContinue |
       Where-Object { $_.ExecutablePath } | Select-Object -First 1
  if ($p) { [void]$cands.Add((Split-Path $p.ExecutablePath -Parent)) }
  [void]$cands.Add((Join-Path $env:LOCALAPPDATA 'Programs\deepseek'))
  [void]$cands.Add((Join-Path $env:LOCALAPPDATA 'Programs\DeepSeek Harness'))
  [void]$cands.Add('D:\deepseek')
  [void]$cands.Add('C:\deepseek')
  [void]$cands.Add((Join-Path $env:ProgramFiles 'DeepSeek Harness'))
  $uni = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
  Get-ItemProperty $uni -ErrorAction SilentlyContinue | ForEach-Object {
    if ($_.DisplayName -like '*DeepSeek*' -and $_.InstallLocation) { [void]$cands.Add($_.InstallLocation) }
  }
  foreach ($c in $cands) {
    if (-not $c) { continue }
    if (Test-Path -LiteralPath (Join-Path $c 'DeepSeek Harness.exe')) { return $c }
  }
  return $null
}

function Get-DshPaths {
  $root = Get-DshRoot
  if (-not $root) { return $null }
  $res = Join-Path $root 'resources'
  return [pscustomobject]@{
    Root  = $root
    Res   = $res
    App   = (Join-Path $res 'app')
    Asar  = (Join-Path $res 'app.asar')
    Bak   = (Join-Path $res 'app.asar.bak')
    Exe   = (Join-Path $root 'DeepSeek Harness.exe')
  }
}

function Say($m) { Write-Host (('[{0}] {1}') -f (Get-Date).ToString('HH:mm:ss'), $m) }

function Stop-DshProcesses($root) {
  $killed = 0
  $self = $PID
  $parent = (Get-CimInstance Win32_Process -Filter ("ProcessId=" + $PID) -ErrorAction SilentlyContinue).ParentProcessId
  Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
    $_.ProcessId -ne $self -and $_.ProcessId -ne $parent -and (
    ($_.ExecutablePath -and $_.ExecutablePath.ToLower().StartsWith($root.ToLower())) -or
    ($_.CommandLine -and $_.CommandLine.ToLower().Contains($root.ToLower())))
  } | ForEach-Object {
    try { Stop-Process -Id $_.ProcessId -Force -ErrorAction Stop; $script:killed++ } catch {}
  }
  Get-Process -Name 'DeepSeek Harness' -ErrorAction SilentlyContinue | ForEach-Object {
    try { Stop-Process -Id $_.Id -Force -ErrorAction Stop; $script:killed++ } catch {}
  }
  return $script:killed
}
