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
  [switch]$BuildSports2020Db = $false
)

$ErrorActionPreference = 'Stop'

<#
  Build all OpenEdge images (compiler, devcontainer, pas_dev, db_adv) in one command.
  
  Example:
    pwsh ./tools/build-all-images.ps1 -Version 12.8.7 -Tag 12.8.7
    pwsh ./tools/build-all-images.ps1 -Version 12.8.7 -Tag 12.8.7 -SkipDevcontainer
    pwsh ./tools/build-all-images.ps1 -Version 12.8.7 -Tag 12.8.7 -BuildSports2020Db
#>

if (-not $Tag) { $Tag = $Version }

$buildImageScript = Join-Path $PSScriptRoot 'build-image.ps1'
if (-not (Test-Path $buildImageScript)) {
  throw "build-image.ps1 not found at: $buildImageScript"
}

$components = @('compiler', 'pas_dev', 'pas_base', 'pas_orads', 'db_adv')
$buildDevcontainer = -not $SkipDevcontainer
$buildSports2020 = $BuildSports2020Db

# Validate all response.ini files exist before starting
$root = Resolve-Path (Join-Path $PSScriptRoot '..')
$missingResponseIni = @()
foreach ($comp in $components) {
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
Write-Host "  Sports2020-db: $buildSports2020" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$startTime = Get-Date
$results = @()

foreach ($component in $components) {
  Write-Host ""
  Write-Host "========================================" -ForegroundColor Yellow
  Write-Host "Building: $component" -ForegroundColor Yellow
  Write-Host "========================================" -ForegroundColor Yellow
  Write-Host ""
  
  $componentStartTime = Get-Date
  
  try {
    $buildArgs = @('-Component', $component, '-Version', $Version, '-Tag', $Tag)
    
    if ($BinariesRoot) {
      $buildArgs += @('-BinariesRoot', $BinariesRoot)
    }
    
    if ($JDKVERSION) {
      $buildArgs += @('-JDKVERSION', $JDKVERSION)
    }
    
    if ($OEVERSION) {
      $buildArgs += @('-OEVERSION', $OEVERSION)
    }
    
    # Only add -BuildDevcontainer for compiler component
    if ($component -eq 'compiler' -and $buildDevcontainer) {
      $buildArgs += '-BuildDevcontainer'
    }
    
    # Only add -BuildSports2020Db for db_adv component
    if ($component -eq 'db_adv' -and $buildSports2020) {
      $buildArgs += '-BuildSports2020Db'
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
    Write-Host "✓ $component completed in $($componentDuration.ToString('mm\:ss'))" -ForegroundColor Green
    
  } catch {
    $componentDuration = (Get-Date) - $componentStartTime
    $results += [PSCustomObject]@{
      Component = $component
      Status = 'Failed'
      Duration = $componentDuration
      Error = $_.Exception.Message
    }
    
    Write-Host ""
    Write-Host "✗ $component failed: $($_.Exception.Message)" -ForegroundColor Red
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
  $statusSymbol = if ($result.Status -eq 'Success') { '✓' } else { '✗' }
  
  Write-Host "$statusSymbol $($result.Component): " -NoNewline
  Write-Host "$($result.Status) " -ForegroundColor $statusColor -NoNewline
  Write-Host "($($result.Duration.ToString('mm\:ss')))"
  
  if ($result.Error) {
    Write-Host "  Error: $($result.Error)" -ForegroundColor Red
  }
}

Write-Host ""
Write-Host "Total time: $($totalDuration.ToString('hh\:mm\:ss'))" -ForegroundColor Cyan

$successCount = ($results | Where-Object { $_.Status -eq 'Success' }).Count
$failCount = ($results | Where-Object { $_.Status -eq 'Failed' }).Count

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
  Write-Host "  - rdroge/oe_db_adv:$Tag" -ForegroundColor White
  if ($buildSports2020) {
    Write-Host "  - rdroge/oe_sports2020_db:$Tag" -ForegroundColor White
  }
}
