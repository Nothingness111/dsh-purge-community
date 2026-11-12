#requires -Version 5.1
<#
  dsh-purge-community · one-time repo setup
  Replaces <OWNER> / <REPO> / <COMMUNITY_MAINTAINER> placeholders in package.json.
  Usage:  .\setup-repo.cmd   (interactive)
     or:  powershell -File setup-repo.ps1 -Owner yourname -Repo dsh-purge-community
#>
param(
  [string]$Owner,
  [string]$Repo
)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$pkgPath = Join-Path $root 'package.json'

if (-not $Owner) { $Owner = Read-Host 'GitHub user/org (e.g. yourname)' }
if (-not $Repo)  { $Repo  = Read-Host 'Repo name (e.g. dsh-purge-community)' }
if (-not $Owner -or -not $Repo) { Write-Host 'aborted: empty input'; exit 1 }

$raw = [System.IO.File]::ReadAllText($pkgPath, [System.Text.Encoding]::UTF8)
$raw = $raw.Replace('<OWNER>', $Owner).Replace('<REPO>', $Repo).Replace('<COMMUNITY_MAINTAINER>', $Owner)
[System.IO.File]::WriteAllText($pkgPath, $raw, (New-Object System.Text.UTF8Encoding($false)))

$json = Get-Content -LiteralPath $pkgPath -Raw | ConvertFrom-Json
Write-Host ('name       = ' + $json.name)
Write-Host ('version    = ' + $json.version)
Write-Host ('repository = ' + $json.repository.url)
Write-Host ('tarball    = ' + $json.dsh.install.tarball)
Write-Host ''
Write-Host 'OK. Now run:'
Write-Host ('  git remote add origin https://github.com/' + $Owner + '/' + $Repo + '.git')
Read-Host 'Press Enter to close'
