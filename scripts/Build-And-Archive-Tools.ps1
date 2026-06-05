[CmdletBinding()]
param (
  [string]$RootPath = ""
)

if ([string]::IsNullOrWhiteSpace($RootPath)) {
  $RootPath = (git rev-parse --show-toplevel).Trim()
}

Write-Host "Starting build and archive script..." -ForegroundColor Cyan
Write-Host "Repository root: $RootPath" -ForegroundColor Gray

# Define Delphi rsvars path
$rsvarsPath = "C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\rsvars.bat"
if (-not (Test-Path $rsvarsPath)) {
  Write-Error "Delphi installation rsvars.bat not found at: $rsvarsPath"
  exit 1
}

# Target tools definition
$tools = @(
  @{
    Name    = "SchemaMockGen"
    Desc    = "Data mock generator for JSON Schema."
    CliHelp = "SchemaMockGenCLI.exe -s <schema_path> [-o <output_path>] [-n <count>] [-seed <seed>]"
    VclHelp = "SchemaMockGenVCL.exe"
  },
  @{
    Name    = "Schema2Delphi"
    Desc    = "Delphi DTO class generator from JSON Schema."
    CliHelp = "Schema2DelphiCLI.exe -s <schema_path> -u <unit_name> -c <class_name> [-o <output_path>]"
    VclHelp = "Schema2DelphiVCL.exe"
  },
  @{
    Name    = "SchemaValidator"
    Desc    = "JSON Schema validator utility."
    CliHelp = "SchemaValidatorCLI.exe -s <schema_path> [-i <instance_path>] [-d <draft>] [-l <locale>] [-f <format>]"
    VclHelp = "SchemaValidatorVCL.exe"
  },
  @{
    Name    = "Delphi2Schema"
    Desc    = "JSON Schema generator from Delphi classes/records using RTTI."
    CliHelp = "Delphi2SchemaCLI.exe -t <type_name> [-b <bpl_path>] [-o <output_path>] [--no-enum-names]"
    VclHelp = "Delphi2SchemaVCL.exe"
  }
)

# Output directory for releases
$releaseDir = Join-Path $RootPath "releases"
if (-not (Test-Path $releaseDir)) {
  New-Item -ItemType Directory -Path $releaseDir -Force | Out-Null
}

foreach ($tool in $tools) {
  $toolName = $tool.Name
  Write-Host "Building tool: $toolName..." -ForegroundColor Yellow

  $toolDir = Join-Path $RootPath "tools\$toolName"
  $groupProj = Join-Path $toolDir "$toolName.groupproj"

  if (-not (Test-Path $groupProj)) {
    Write-Error "Group project not found: $groupProj"
    continue
  }

  # Clean output folders to prevent Bad Unit Format (x64 vs x86) compilation errors
  $trashDir = Join-Path $toolDir ".trash"
  $binDir = Join-Path $toolDir ".bin"
  if (Test-Path $trashDir) {
    Remove-Item -Path $trashDir -Recurse -Force | Out-Null
  }
  if (Test-Path $binDir) {
    Remove-Item -Path $binDir -Recurse -Force | Out-Null
  }

  # Run MSBuild
  Write-Host "Running MSBuild command..." -ForegroundColor Gray
  & cmd.exe /c "call `"$rsvarsPath`" && msbuild `"$groupProj`" /p:DCC_UseMSBuildExternally=true /p:Config=Release /p:Platform=Win32"

  if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to compile $toolName. Check MSBuild output above."
    exit 1
  }

  # Staging directory for zip
  $stagingDir = Join-Path $toolDir "dist"
  if (Test-Path $stagingDir) {
    Remove-Item -Path $stagingDir -Recurse -Force | Out-Null
  }
  New-Item -ItemType Directory -Path $stagingDir -Force | Out-Null

  # Copy files
  $binDir = Join-Path $toolDir ".bin"
  $cliExe = Join-Path $binDir "$($toolName)CLI.exe"
  $vclExe = Join-Path $binDir "$($toolName)VCL.exe"

  if (-not (Test-Path $cliExe)) {
    $cliExe = Join-Path $toolDir "$($toolName)CLI.exe"
  }
  if (-not (Test-Path $vclExe)) {
    $vclExe = Join-Path $toolDir "$($toolName)VCL.exe"
  }

  if (-not (Test-Path $cliExe) -or -not (Test-Path $vclExe)) {
    Write-Error "Executables not found for $toolName in .bin or tool root."
    continue
  }

  Copy-Item -Path $cliExe -Destination $stagingDir -Force
  Copy-Item -Path $vclExe -Destination $stagingDir -Force

  # Write README.txt
  $readmePath = Join-Path $stagingDir "README.txt"
  $readmeContent = @"
================================================================================
$toolName - $($tool.Desc)
================================================================================

This package contains both the Command-Line Interface (CLI) and the VCL Desktop
GUI version of the tool.

FILE LIST:
  - $($toolName)CLI.exe : Command-Line Interface
  - $($toolName)VCL.exe : Desktop GUI Application
  - README.txt          : This guide

--------------------------------------------------------------------------------
1. How to run the CLI version
--------------------------------------------------------------------------------
Open your command prompt or terminal and run:
  $($tool.CliHelp)

--------------------------------------------------------------------------------
2. How to run the VCL GUI version
--------------------------------------------------------------------------------
Double-click:
  $($tool.VclHelp)

================================================================================
"@
  Set-Content -Path $readmePath -Value $readmeContent -Encoding utf8

  # Create Zip archive
  $zipPath = Join-Path $releaseDir "$toolName.zip"
  if (Test-Path $zipPath) {
    Remove-Item -Path $zipPath -Force | Out-Null
  }

  Write-Host "Creating archive: $zipPath..." -ForegroundColor Green
  Compress-Archive -Path "$stagingDir\*" -DestinationPath $zipPath -Force

  # Clean staging directory
  Remove-Item -Path $stagingDir -Recurse -Force | Out-Null
}

# Auto stage zips in git
Write-Host "Staging archives in Git..." -ForegroundColor Gray
$zipsWildcard = Join-Path $releaseDir "*.zip"
git add $zipsWildcard

Write-Host "Build and archiving completed successfully!" -ForegroundColor Green
