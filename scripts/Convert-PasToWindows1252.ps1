param(
  [string]$RootPath = (Resolve-Path (Join-Path $PSScriptRoot ".." )).Path,
  [switch]$StageChanges,
  [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-ByteArrayEqual {
  param(
    [byte[]]$Left,
    [byte[]]$Right
  )

  if ($Left.Length -ne $Right.Length) {
    return $false
  }

  for ($i = 0; $i -lt $Left.Length; $i++) {
    if ($Left[$i] -ne $Right[$i]) {
      return $false
    }
  }

  return $true
}

function Test-ValidUtf8 {
  param([byte[]]$Bytes)

  $strictUtf8 = [System.Text.UTF8Encoding]::new($false, $true)
  try {
    $null = $strictUtf8.GetString($Bytes)
    return $true
  }
  catch {
    return $false
  }
}

function Get-DetectedEncoding {
  param([byte[]]$Bytes)

  if ($Bytes.Length -ge 3 -and $Bytes[0] -eq 0xEF -and $Bytes[1] -eq 0xBB -and $Bytes[2] -eq 0xBF) {
    return @{
      Name           = 'utf-8-bom'
      Encoding       = [System.Text.UTF8Encoding]::new($false, $true)
      PreambleLength = 3
    }
  }

  if ($Bytes.Length -ge 4 -and $Bytes[0] -eq 0xFF -and $Bytes[1] -eq 0xFE -and $Bytes[2] -eq 0x00 -and $Bytes[3] -eq 0x00) {
    return @{
      Name           = 'utf-32-le'
      Encoding       = [System.Text.UTF32Encoding]::new($false, $true, $true)
      PreambleLength = 4
    }
  }

  if ($Bytes.Length -ge 4 -and $Bytes[0] -eq 0x00 -and $Bytes[1] -eq 0x00 -and $Bytes[2] -eq 0xFE -and $Bytes[3] -eq 0xFF) {
    return @{
      Name           = 'utf-32-be'
      Encoding       = [System.Text.UTF32Encoding]::new($true, $true, $true)
      PreambleLength = 4
    }
  }

  if ($Bytes.Length -ge 2 -and $Bytes[0] -eq 0xFF -and $Bytes[1] -eq 0xFE) {
    return @{
      Name           = 'utf-16-le'
      Encoding       = [System.Text.UnicodeEncoding]::new($false, $true, $true)
      PreambleLength = 2
    }
  }

  if ($Bytes.Length -ge 2 -and $Bytes[0] -eq 0xFE -and $Bytes[1] -eq 0xFF) {
    return @{
      Name           = 'utf-16-be'
      Encoding       = [System.Text.UnicodeEncoding]::new($true, $true, $true)
      PreambleLength = 2
    }
  }

  if (Test-ValidUtf8 -Bytes $Bytes) {
    return @{
      Name           = 'utf-8'
      Encoding       = [System.Text.UTF8Encoding]::new($false, $true)
      PreambleLength = 0
    }
  }

  return @{
    Name           = 'windows-1252'
    Encoding       = [System.Text.Encoding]::GetEncoding(1252)
    PreambleLength = 0
  }
}

function Convert-ToWindows1252 {
  param([string]$Text)

  $converted = $Text
  $converted = $converted.Replace([string][char]0x2018, "'")
  $converted = $converted.Replace([string][char]0x2019, "'")
  $converted = $converted.Replace([string][char]0x201C, '"')
  $converted = $converted.Replace([string][char]0x201D, '"')
  $converted = $converted.Replace([string][char]0x2013, '-')
  $converted = $converted.Replace([string][char]0x2014, '-')
  $converted = $converted.Replace([string][char]0x2026, '...')
  $converted = $converted.Replace([string][char]0x00A0, ' ')
  $converted = $converted.Replace([string][char]0xFEFF, '')
  $converted = $converted.Replace([string][char]0xFFFD, '?')

  return $converted
}

$windows1252 = [System.Text.Encoding]::GetEncoding(
  1252,
  [System.Text.EncoderExceptionFallback]::new(),
  [System.Text.DecoderExceptionFallback]::new()
)

$allPasFiles = Get-ChildItem -Path $RootPath -Recurse -File -Filter '*.pas' |
Where-Object { $_.FullName -notmatch '[\\/]\.git[\\/]' }

$changedFiles = New-Object 'System.Collections.Generic.List[string]'
$failedFiles = New-Object 'System.Collections.Generic.List[string]'

foreach ($file in $allPasFiles) {
  $originalBytes = [System.IO.File]::ReadAllBytes($file.FullName)
  $detected = Get-DetectedEncoding -Bytes $originalBytes

  $offset = [int]$detected.PreambleLength
  $length = $originalBytes.Length - $offset

  try {
    $text = $detected.Encoding.GetString($originalBytes, $offset, $length)
    $normalizedText = Convert-ToWindows1252 -Text $text
    $convertedBytes = $windows1252.GetBytes($normalizedText)
  }
  catch {
    $failedFiles.Add($file.FullName)
    continue
  }

  if (-not (Test-ByteArrayEqual -Left $originalBytes -Right $convertedBytes)) {
    if (-not $DryRun) {
      [System.IO.File]::WriteAllBytes($file.FullName, $convertedBytes)
    }

    $changedFiles.Add($file.FullName)
    Write-Host "converted: $($file.FullName) ($($detected.Name) -> windows-1252)"
  }
}

if ($failedFiles.Count -gt 0) {
  Write-Host ''
  Write-Host 'ERROR: Some files contain characters outside Windows-1252 and were not converted:' -ForegroundColor Red
  foreach ($failedFile in $failedFiles) {
    Write-Host " - $failedFile" -ForegroundColor Red
  }

  Write-Host ''
  Write-Host 'Commit aborted to avoid character corruption.' -ForegroundColor Red
  exit 1
}

if ($StageChanges -and $changedFiles.Count -gt 0) {
  Push-Location $RootPath
  try {
    $relativeFiles = $changedFiles | ForEach-Object { [System.IO.Path]::GetRelativePath($RootPath, $_) }
    & git add -- $relativeFiles
  }
  finally {
    Pop-Location
  }
}

Write-Host ''
Write-Host "PAS files scanned: $($allPasFiles.Count)"
Write-Host "PAS files converted: $($changedFiles.Count)"

exit 0
