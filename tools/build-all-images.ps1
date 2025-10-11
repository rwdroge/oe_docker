param(
  [Parameter(Mandatory=$true, Position=0)]
  [string]$Version,

  [Parameter(Position=1)]
  [string]$Tag = $null,

  [Parameter(Position=2)]
  [string]$BinariesRoot = $null,

  [int]$JDKVERSION = 21,
  [string]$OEVERSION = $null,
  [switch]$SkipDevcontainer = $false,
  [switch]$SkipSports2020Db = $false,
  [switch]$SkipPasOrads = $false
)

$ErrorActionPreference = 'Stop'

<#
  Build all OpenEdge images (compiler, devcontainer, pas_dev, pas_base, pas_orads, db_adv, sports2020-db) in one command.
  By default, all images are built. Use Skip* parameters to exclude specific images.
  
  Example:
    pwsh ./tools/build-all-images.ps1 -Version 12.8.7 -Tag 12.8.7
    pwsh ./tools/build-all-images.ps1 -Version 12.8.7 -Tag 12.8.7 -SkipDevcontainer
    pwsh ./tools/build-all-images.ps1 -Version 12.8.7 -Tag 12.8.7 -SkipSports2020Db -SkipPasOrads
#>

if (-not $Tag) { $Tag = $Version }

$buildImageScript = Join-Path $PSScriptRoot 'build-image.ps1'
if (-not (Test-Path $buildImageScript)) {
  throw "build-image.ps1 not found at: $buildImageScript"
}

$components = @('compiler', 'pas_dev', 'pas_base', 'pas_orads', 'db_adv')
$buildDevcontainer = -not $SkipDevcontainer
$buildSports2020 = -not $SkipSports2020Db
$buildPasOrads = -not $SkipPasOrads

# Validate all response.ini files exist before starting
# Note: pas_orads builds from pas_base and doesn't need its own response.ini
$root = Resolve-Path (Join-Path $PSScriptRoot '..')
$missingResponseIni = @()
foreach ($comp in $components) {
  # Skip pas_orads as it builds from pas_base and doesn't need response.ini
  if ($comp -eq 'pas_orads') {
    continue
  }
  $responseIni = Join-Path $root (Join-Path $comp 'response.ini')
  if (-not (Test-Path $responseIni)) {
    $missingResponseIni += $responseIni
  }
}

if ($missingResponseIni.Count -gt 0) {
  Write-Host "Error: Missing response.ini file(s):" -ForegroundColor Red
  foreach ($missing in $missingResponseIni) {
    Write-Host "  - $missing" -ForegroundColor Red
  }
  Write-Host ""
  Write-Host "Please configure OpenEdge control codes in the response.ini files before building." -ForegroundColor Yellow
  Write-Host "See the 'Configure control codes' section in README.md for details." -ForegroundColor Yellow
  throw "Missing required response.ini file(s)"
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Building all OpenEdge images" -ForegroundColor Cyan
Write-Host "  Version: $Version" -ForegroundColor Cyan
Write-Host "  Tag: $Tag" -ForegroundColor Cyan
Write-Host "  Components: $($components -join ', ')" -ForegroundColor Cyan
Write-Host "  Devcontainer: $buildDevcontainer" -ForegroundColor Cyan
Write-Host "  PAS for ORADS: $buildPasOrads" -ForegroundColor Cyan
Write-Host "  Sports2020-db: $buildSports2020" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$startTime = Get-Date
$results = @()

foreach ($component in $components) {
  # Skip pas_orads if requested
  if ($component -eq 'pas_orads' -and -not $buildPasOrads) {
    Write-Host ""
    Write-Host "Skipping pas_orads (use without -SkipPasOrads to build)" -ForegroundColor Yellow
    continue
  }
  
  Write-Host ""
  Write-Host "========================================" -ForegroundColor Yellow
  Write-Host "Building: $component" -ForegroundColor Yellow
  Write-Host "========================================" -ForegroundColor Yellow
  Write-Host ""
  
  $componentStartTime = Get-Date
  
  try {
    $buildArgs = @{
      Component = $component
      Version = $Version
      Tag = $Tag
    }
    
    if ($BinariesRoot) {
      $buildArgs['BinariesRoot'] = $BinariesRoot
    }
    
    if ($JDKVERSION) {
      $buildArgs['JDKVERSION'] = $JDKVERSION
    }
    
    if ($OEVERSION) {
      $buildArgs['OEVERSION'] = $OEVERSION
    }
    
    # Only add -BuildDevcontainer for compiler component
    if ($component -eq 'compiler' -and $buildDevcontainer) {
      $buildArgs['BuildDevcontainer'] = $true
    }
    
    # Only add -BuildSports2020Db for db_adv component
    if ($component -eq 'db_adv' -and $buildSports2020) {
      $buildArgs['BuildSports2020Db'] = $true
    }
    
    & $buildImageScript @buildArgs
    
    if ($LASTEXITCODE -ne 0) {
      throw "Build failed with exit code $LASTEXITCODE"
    }
    
    $componentDuration = (Get-Date) - $componentStartTime
    $results += [PSCustomObject]@{
      Component = $component
      Status = 'Success'
      Duration = $componentDuration
    }
    
    Write-Host ""
    $durationStr = "{0:mm\:ss}" -f $componentDuration
    Write-Host "[OK] $component completed in $durationStr" -ForegroundColor Green
    
  } catch {
    $componentDuration = (Get-Date) - $componentStartTime
    $results += [PSCustomObject]@{
      Component = $component
      Status = 'Failed'
      Duration = $componentDuration
      Error = $_.Exception.Message
    }
    
    Write-Host ""
    Write-Host "[FAIL] $component failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Stopping build process due to failure." -ForegroundColor Red
    break
  }
}

$totalDuration = (Get-Date) - $startTime

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Build Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

foreach ($result in $results) {
  $statusColor = if ($result.Status -eq 'Success') { 'Green' } else { 'Red' }
  $statusSymbol = if ($result.Status -eq 'Success') { '[OK]' } else { '[FAIL]' }
  
  Write-Host "$statusSymbol $($result.Component): " -NoNewline
  Write-Host "$($result.Status) " -ForegroundColor $statusColor -NoNewline
  $resultDurationStr = "{0:mm\:ss}" -f $result.Duration
  Write-Host "($resultDurationStr)"
  
  if ($result.Error) {
    Write-Host "  Error: $($result.Error)" -ForegroundColor Red
  }
}

Write-Host ""
$totalTimeStr = "{0:hh\:mm\:ss}" -f $totalDuration
Write-Host "Total time: $totalTimeStr" -ForegroundColor Cyan

$successCount = ($results | Where-Object { $_.Status -eq "Success" }).Count
$failCount = ($results | Where-Object { $_.Status -eq "Failed" }).Count

if ($failCount -gt 0) {
  Write-Host ""
  Write-Host "Build completed with $failCount failure(s) and $successCount success(es)." -ForegroundColor Red
  exit 1
} else {
  Write-Host ""
  Write-Host "All builds completed successfully!" -ForegroundColor Green
  
  Write-Host ""
  Write-Host "Built images:" -ForegroundColor Cyan
  Write-Host "  - rdroge/oe_compiler:$Tag" -ForegroundColor White
  if ($buildDevcontainer) {
    Write-Host "  - rdroge/oe_devcontainer:$Tag" -ForegroundColor White
  }
  Write-Host "  - rdroge/oe_pas_dev:$Tag" -ForegroundColor White
  Write-Host "  - rdroge/oe_pas_base:$Tag" -ForegroundColor White
  if ($buildPasOrads) {
    Write-Host "  - rdroge/oe_pas_orads:$Tag" -ForegroundColor White
  }
  Write-Host "  - rdroge/oe_db_adv:$Tag" -ForegroundColor White
  if ($buildSports2020) {
    Write-Host "  - rdroge/oe_sports2020_db:$Tag" -ForegroundColor White
  }
}
