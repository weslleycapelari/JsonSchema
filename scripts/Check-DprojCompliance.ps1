<#
.SYNOPSIS
    Checks all .dproj files under the tools folder for compliance with project standards.

.DESCRIPTION
    Validates (and optionally fixes) two rules across every .dproj file found recursively
    inside the tools folder:

    1. MANIFEST CHECK
       Every <Manifest_File> tag must use the automatic BDS path:
           $(BDS)\bin\default_app.manifest

    2. BASE PLATFORM PROPERTY GROUP CHECK
       Every <PropertyGroup> whose Condition attribute references a Base_* platform
       (Base_Linux64, Base_OSX64, Base_OSXARM64, Base_Win32, Base_Win64) must contain
       the required child properties with the correct values, as defined by project standards.

    When -Fix is supplied the script rewrites each non-compliant file in place.
    NOTE: saving via XmlDocument normalises whitespace; the resulting files are
    semantically identical but may differ cosmetically from the originals.

.PARAMETER ToolsPath
    Path to the tools folder. Defaults to ..\tools relative to this script.

.PARAMETER Fix
    Apply corrections to non-compliant files instead of only reporting them.

.PARAMETER Backup
    When used with -Fix, saves a copy of each original file as <file>.dproj.bak
    before overwriting it.

.PARAMETER Strict
    When set, any Base_* PropertyGroup found in the file that is NOT one of the known
    platforms will also be reported as an unknown/unverified group.

.EXAMPLE
    .\Check-DprojCompliance.ps1
    .\Check-DprojCompliance.ps1 -Fix
    .\Check-DprojCompliance.ps1 -Fix -Backup
    .\Check-DprojCompliance.ps1 -ToolsPath 'C:\MyProject\tools' -Strict
#>
[CmdletBinding()]
param(
  [string]$ToolsPath = (Join-Path $PSScriptRoot '..\tools'),
  [switch]$Fix,
  [switch]$Backup = $false,
  [switch]$Strict
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------------------
# Expected values
# ---------------------------------------------------------------------------
$ExpectedManifest = '$(BDS)\bin\default_app.manifest'
$ExpectedIcon = '..\..\images\icon-blue.ico'
$ExpectedLogo44 = '..\..\images\icon-blue-44.png'
$ExpectedLogo150 = '..\..\images\icon-blue-150.png'

# ---------------------------------------------------------------------------
# Per-platform required properties for Base_* PropertyGroups
# ---------------------------------------------------------------------------
$PlatformRules = [ordered]@{
  'Base_Linux64'  = [ordered]@{
    'Debugger_Launcher'   = '/usr/bin/gnome-terminal -- "%debuggee%"'
    'Icon_MainIcon'       = $ExpectedIcon
    'Manifest_File'       = $ExpectedManifest
    'AppDPIAwarenessMode' = 'none'
  }
  'Base_OSX64'    = [ordered]@{
    'Debugger_Launcher'   = '/usr/X11/bin/xterm -e "%debuggee%"'
    'Icon_MainIcon'       = $ExpectedIcon
    'Manifest_File'       = $ExpectedManifest
    'AppDPIAwarenessMode' = 'none'
  }
  'Base_OSXARM64' = [ordered]@{
    'Debugger_Launcher'   = '/usr/X11/bin/xterm -e "%debuggee%"'
    'Icon_MainIcon'       = $ExpectedIcon
    'Manifest_File'       = $ExpectedManifest
    'AppDPIAwarenessMode' = 'none'
  }
  'Base_Win32'    = [ordered]@{
    'Icon_MainIcon'       = $ExpectedIcon
    'Manifest_File'       = $ExpectedManifest
    'AppDPIAwarenessMode' = 'none'
    'UWP_DelphiLogo44'    = $ExpectedLogo44
    'UWP_DelphiLogo150'   = $ExpectedLogo150
  }
  'Base_Win64'    = [ordered]@{
    'Icon_MainIcon'       = $ExpectedIcon
    'Manifest_File'       = $ExpectedManifest
    'AppDPIAwarenessMode' = 'none'
    'UWP_DelphiLogo44'    = $ExpectedLogo44
    'UWP_DelphiLogo150'   = $ExpectedLogo150
  }
}

# ---------------------------------------------------------------------------
# Helper: safely read a child element value from a PropertyGroup XML node
# ---------------------------------------------------------------------------
function Get-PgProperty {
  param([System.Xml.XmlElement]$Node, [string]$Name)
  $child = $Node.SelectSingleNode("*[local-name()='$Name']")
  if ($null -eq $child) { return $null }
  return $child.InnerText
}

# ---------------------------------------------------------------------------
# Helper: set (or create) a child element value on a PropertyGroup XML node
# ---------------------------------------------------------------------------
function Set-PgProperty {
  param(
    [System.Xml.XmlElement]$Node,
    [string]$Name,
    [string]$Value,
    [System.Xml.XmlDocument]$Doc
  )
  $child = $Node.SelectSingleNode("*[local-name()='$Name']")
  if ($null -ne $child) {
    $child.InnerText = $Value
  }
  else {
    $newElem = $Doc.CreateElement($Name, $Doc.DocumentElement.NamespaceURI)
    $newElem.InnerText = $Value
    [void]$Node.AppendChild($newElem)
  }
}

# ---------------------------------------------------------------------------
# Helper: save XmlDocument preserving UTF-8 with XML declaration
# ---------------------------------------------------------------------------
function Save-Xml {
  param([System.Xml.XmlDocument]$Doc, [string]$Path)
  $settings = [System.Xml.XmlWriterSettings]::new()
  $settings.Indent = $true
  $settings.IndentChars = '    '
  $settings.Encoding = [System.Text.UTF8Encoding]::new($false)
  $settings.OmitXmlDeclaration = $false
  $writer = [System.Xml.XmlWriter]::Create($Path, $settings)
  try {
    $Doc.Save($writer)
  }
  finally {
    $writer.Dispose()
  }
}

# ---------------------------------------------------------------------------
# Helper: extract Base_<Platform> name from a Condition attribute, or $null
# ---------------------------------------------------------------------------
function Get-BasePlatform {
  param([string]$Condition)
  if ($Condition -match "\'\`$\(Base_(\w+)\)\'!=''") {
    return "Base_$($Matches[1])"
  }
  return $null
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
$ToolsPath = (Resolve-Path $ToolsPath).Path

Write-Host ''
Write-Host "Scanning .dproj files under: $ToolsPath" -ForegroundColor Cyan
Write-Host ''

$dprojFiles = Get-ChildItem -Path $ToolsPath -Filter '*.dproj' -Recurse | Sort-Object FullName

if ($dprojFiles.Count -eq 0) {
  Write-Warning "No .dproj files found under $ToolsPath"
  exit 0
}

$totalFiles = $dprojFiles.Count
$totalChecks = 0
$totalIssues = 0
$totalFixed = 0
$fileResults = [System.Collections.Generic.List[object]]::new()

if ($Fix) {
  Write-Host '  Mode: FIX (files will be rewritten)' -ForegroundColor Magenta
  if ($Backup) { Write-Host '  Backups enabled (.dproj.bak)' -ForegroundColor Magenta }
  Write-Host ''
}

foreach ($file in $dprojFiles) {
  $relPath = $file.FullName.Substring($ToolsPath.Length).TrimStart('\', '/')
  $fileIssues = [System.Collections.Generic.List[string]]::new()
  $fileFixes = [System.Collections.Generic.List[string]]::new()

  try {
    [xml]$xml = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
  }
  catch {
    $fileIssues.Add("  [PARSE ERROR] Could not load XML: $_")
    $fileResults.Add([pscustomobject]@{ File = $relPath; Issues = $fileIssues; Fixes = $fileFixes })
    $totalIssues++
    continue
  }

  $propertyGroups = $xml.Project.PropertyGroup
  if ($null -eq $propertyGroups) {
    $fileResults.Add([pscustomobject]@{ File = $relPath; Issues = $fileIssues; Fixes = $fileFixes })
    continue
  }

  # Ensure we always work with an array
  if ($propertyGroups -isnot [System.Array]) {
    $propertyGroups = @($propertyGroups)
  }

  $fileModified = $false

  foreach ($pg in $propertyGroups) {
    if ($pg -isnot [System.Xml.XmlElement]) { continue }
    $condition = $pg.GetAttribute('Condition').Trim()

    # ---------------------------------------------------------------
    # CHECK 1: All Manifest_File elements must use the automatic path
    # ---------------------------------------------------------------
    $manifestValue = Get-PgProperty -Node $pg -Name 'Manifest_File'
    if ($null -ne $manifestValue) {
      $totalChecks++
      if ($manifestValue -ne $ExpectedManifest) {
        $fileIssues.Add("  [MANIFEST] Unexpected value in PropertyGroup (Condition: '$condition')")
        $fileIssues.Add("             Found   : '$manifestValue'")
        $fileIssues.Add("             Expected: '$ExpectedManifest'")
        $totalIssues++
        if ($Fix) {
          Set-PgProperty -Node $pg -Name 'Manifest_File' -Value $ExpectedManifest -Doc $xml
          $fileFixes.Add("  [FIXED:MANIFEST] (Condition: '$condition') set to '$ExpectedManifest'")
          $fileModified = $true
        }
      }
    }

    # ---------------------------------------------------------------
    # CHECK 2: Base_* PropertyGroups must have required icon/manifest
    # ---------------------------------------------------------------
    $platform = Get-BasePlatform -Condition $condition
    if ($null -ne $platform) {
      if ($PlatformRules.Contains($platform)) {
        $rules = $PlatformRules[$platform]
        foreach ($propName in $rules.Keys) {
          $totalChecks++
          $actual = Get-PgProperty -Node $pg -Name $propName
          $expected = $rules[$propName]

          if ($null -eq $actual -or $actual -eq '') {
            $fileIssues.Add("  [PLATFORM:$platform] Missing <$propName>")
            $fileIssues.Add("             Expected: '$expected'")
            $totalIssues++
            if ($Fix) {
              Set-PgProperty -Node $pg -Name $propName -Value $expected -Doc $xml
              $fileFixes.Add("  [FIXED:$platform] Added <$propName> = '$expected'")
              $fileModified = $true
            }
          }
          elseif ($actual -ne $expected) {
            $fileIssues.Add("  [PLATFORM:$platform] Wrong value for <$propName>")
            $fileIssues.Add("             Found   : '$actual'")
            $fileIssues.Add("             Expected: '$expected'")
            $totalIssues++
            if ($Fix) {
              Set-PgProperty -Node $pg -Name $propName -Value $expected -Doc $xml
              $fileFixes.Add("  [FIXED:$platform] Corrected <$propName> to '$expected'")
              $fileModified = $true
            }
          }
        }
      }
      elseif ($Strict) {
        $fileIssues.Add("  [PLATFORM:UNKNOWN] Unrecognised Base_* platform group: '$platform' (Condition: '$condition')")
        $totalIssues++
      }
    }
  }

  if ($Fix -and $fileModified) {
    if ($Backup) {
      Copy-Item -LiteralPath $file.FullName -Destination "$($file.FullName).bak" -Force
    }
    Save-Xml -Doc $xml -Path $file.FullName
    $totalFixed++
  }

  $fileResults.Add([pscustomobject]@{ File = $relPath; Issues = $fileIssues; Fixes = $fileFixes })
}

# ---------------------------------------------------------------------------
# Output results
# ---------------------------------------------------------------------------
$passCount = 0
$failCount = 0

foreach ($result in $fileResults) {
  if ($result.Issues.Count -eq 0) {
    Write-Host "  [PASS] $($result.File)" -ForegroundColor Green
    $passCount++
  }
  else {
    $label = if ($Fix -and $result.Fixes.Count -gt 0) { '[FIXED]' } else { '[FAIL]' }
    $color = if ($Fix -and $result.Fixes.Count -gt 0) { 'Cyan' } else { 'Red' }
    Write-Host "  $label $($result.File)" -ForegroundColor $color
    foreach ($issue in $result.Issues) {
      Write-Host $issue -ForegroundColor Yellow
    }
    if ($Fix -and $result.Fixes.Count -gt 0) {
      foreach ($fix in $result.Fixes) {
        Write-Host $fix -ForegroundColor Cyan
      }
    }
    $failCount++
  }
}

Write-Host ''
Write-Host '---------------------------------------------------------------' -ForegroundColor Cyan
Write-Host "Files scanned : $totalFiles"
Write-Host "Checks run    : $totalChecks"
Write-Host "Files passing : $passCount" -ForegroundColor Green
Write-Host "Files failing : $failCount" $(if ($Fix) { '' } elseif ($failCount -gt 0) { '  <-- ACTION REQUIRED' }) -ForegroundColor $(if ($failCount -gt 0 -and -not $Fix) { 'Red' } else { 'Green' })
Write-Host "Total issues  : $totalIssues" -ForegroundColor $(if ($totalIssues -gt 0) { 'Red' } else { 'Green' })
if ($Fix) {
  Write-Host "Files fixed   : $totalFixed" -ForegroundColor $(if ($totalFixed -gt 0) { 'Cyan' } else { 'Green' })
}
Write-Host '---------------------------------------------------------------' -ForegroundColor Cyan
Write-Host ''

exit $(if ($totalIssues -gt 0) { 1 } else { 0 })
