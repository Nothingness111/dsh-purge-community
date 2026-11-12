#requires -Version 5.1
<#
  dsh-purge-community · publish to GitHub in one shot
  Fixes: missing git identity, wrong/placeholder remote URL, missing first commit.
  Usage: .\publish.cmd
#>
param(
  [string]$Owner,
  [string]$Repo = 'dsh-purge-community',
  [string]$Email,
  [string]$GitName
)
$ErrorActionPreference = 'Continue'
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root

Write-Host '=== 1. git identity ==='
if (-not $Owner) { $Owner = Read-Host 'GitHub login (the name in github.com/<HERE>/)' }
if (-not $Owner) { Write-Host 'aborted: empty owner'; Read-Host 'Press Enter'; exit 1 }
if (-not $GitName) {
  $GitName = Read-Host ("git user.name [" + $Owner + "]")
  if (-not $GitName) { $GitName = $Owner }
}
if (-not $Email) {
  $Email = Read-Host ("git user.email [" + $Owner + "@users.noreply.github.com]")
  if (-not $Email) { $Email = $Owner + '@users.noreply.github.com' }
}
git config --local user.name "$GitName"
git config --local user.email "$Email"
Write-Host ('  user.name  = ' + (git config --get user.name))
Write-Host ('  user.email = ' + (git config --get user.email))

Write-Host '=== 2. remote url ==='
$url = 'https://github.com/' + $Owner + '/' + $Repo + '.git'
git remote remove origin 2>$null | Out-Null
git remote add origin $url
Write-Host ('  origin -> ' + (git remote get-url origin))

Write-Host '=== 3. commit ==='
git add -A
git commit -m "feat: community fork 1.1.83 - dsh 0.2.2-rc.2 compat + asar swap fallback"
if ($LASTEXITCODE -ne 0) { Write-Host 'FAIL: commit failed (maybe nothing to commit)'; Read-Host 'Press Enter'; exit 2 }

Write-Host '=== 4. push ==='
git push -u origin main
if ($LASTEXITCODE -ne 0) {
  Write-Host 'FAIL: push rejected.'
  Write-Host '  - repo must already exist on GitHub (create it, do NOT add README/.gitignore/license)'
  Write-Host '  - when asked for a password, use a Personal Access Token, not your account password'
  Read-Host 'Press Enter'; exit 3
}

Write-Host '=== 5. tag ==='
git tag -f v1.1.83
git push --tags

Write-Host ''
Write-Host ('DONE -> https://github.com/' + $Owner + '/' + $Repo)
Read-Host 'Press Enter to close'
