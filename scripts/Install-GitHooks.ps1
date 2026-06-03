param(
  [string]$RepositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\.." )).Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Push-Location $RepositoryRoot
try {
  & git config core.hooksPath .githooks
  Write-Host 'Git hooks enabled for this repository (core.hooksPath=.githooks).'
}
finally {
  Pop-Location
}
