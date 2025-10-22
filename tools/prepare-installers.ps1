param(
  [Parameter(Mandatory=$true)][string]$Component,
  [Parameter(Mandatory=$true)][string]$Version,
  [string]$BinariesRoot = "$(Resolve-Path (Join-Path $PSScriptRoot '..'))/binaries/oe",
  [string]$SingleTar = $null,
  [string]$BaseTar = $null,
  [string]$PatchTar = $null
)

$ErrorActionPreference = 'Stop'

function New-VersionObject([string]$v){
  if(-not ($v -match '^(\d+)\.(\d+)\.(\d+)$')){ throw "Version must be MAJOR.MINOR.PATCH (e.g. 12.8.6). Got: $v" }
  return [PSCustomObject]@{ Major=[int]$Matches[1]; Minor=[int]$Matches[2]; Patch=[int]$Matches[3] }
}

function New-EmptyDir([string]$path){ if(Test-Path $path){ Remove-Item -Recurse -Force $path } ; New-Item -ItemType Directory -Path $path | Out-Null }

$allowedComponents = @('compiler','db_adv','pas_dev','pas_base','pas_orads')
if ($allowedComponents -notcontains $Component) { throw "Invalid -Component '$Component'. Allowed: $($allowedComponents -join ', ')" }

# pas_orads doesn't need installer preparation (uses pas_base as base image)
if ($Component -eq 'pas_orads') {
  Write-Host "Skipping installer preparation for pas_orads (uses pas_base as base image)"
  exit 0
}

$ver = New-VersionObject $Version
$series = "$($ver.Major).$($ver.Minor)"

$root = Resolve-Path (Join-Path $PSScriptRoot '..')
$componentDir = Join-Path $root $Component

$installerDir = Join-Path $root 'installer'
New-EmptyDir $installerDir

# Build default filenames if not provided
if(-not $SingleTar){ $SingleTar = Join-Path (Join-Path $BinariesRoot $series) ("PROGRESS_OE_{0}_LNX_64.tar.gz" -f $Version) }
if(-not $BaseTar){ $BaseTar   = Join-Path (Join-Path $BinariesRoot $series) ("PROGRESS_OE_{0}_LNX_64.tar.gz" -f "$($ver.Major).$($ver.Minor)") }
if(-not $PatchTar){ $PatchTar  = Join-Path (Join-Path $BinariesRoot $series) ("PROGRESS_OE_{0}_LNX_64.tar.gz" -f $Version) }
if($series -eq '12.8'){
  $useSingle = ($ver.Patch -lt 4 -or $ver.Patch -gt 8)
} else {
  $useSingle = $true
}

if($useSingle){
  if(-not (Test-Path $SingleTar)){ throw "Single installer not found: $SingleTar" }
  Copy-Item $SingleTar (Join-Path $installerDir 'PROGRESS_OE.tar.gz') -Force

  # Always create a valid empty patch tarball so Docker ADD succeeds
  $emptyTar = Join-Path $installerDir 'PROGRESS_PATCH_OE.tar.gz'
  $tarCmd = Get-Command tar -ErrorAction SilentlyContinue
  if($tarCmd){
    $tmp = New-Item -ItemType Directory -Path (Join-Path $env:TEMP ("oe_empty_patch_" + [guid]::NewGuid().ToString()))
    try {
      Push-Location $tmp.FullName
      # Create an empty file list for tar to read from
      $emptyFileList = Join-Path $tmp.FullName 'empty_files.txt'
      New-Item -ItemType File -Path $emptyFileList -Force | Out-Null
      & $tarCmd.Source -czf $emptyTar -T $emptyFileList 2>$null
      if(-not (Test-Path $emptyTar)){ throw "Failed to create empty patch tar at $emptyTar" }
    } finally {
      Pop-Location
      Remove-Item -Recurse -Force $tmp
    }
  } else {
    throw "'tar' not found. Please ensure tar is available (e.g., install Git for Windows, use WSL, or run from a shell that provides tar), or create an empty tar.gz named PROGRESS_PATCH_OE.tar.gz in $installerDir manually."
  }

  Write-Host "Prepared single installer for $Component $Version (created empty patch tar)"
}else{
  if(-not (Test-Path $BaseTar)){ throw "Base installer not found: $BaseTar" }
  if(-not (Test-Path $PatchTar)){ throw "Patch installer not found: $PatchTar" }
  Copy-Item $BaseTar  (Join-Path $installerDir 'PROGRESS_OE.tar.gz') -Force
  Copy-Item $PatchTar (Join-Path $installerDir 'PROGRESS_PATCH_OE.tar.gz') -Force
  Write-Host "Prepared base+patch installers for $Component $Version (base $($ver.Major).$($ver.Minor) + patch $Version)"
}

Write-Host "Output directory: $installerDir"
