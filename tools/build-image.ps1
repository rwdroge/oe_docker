param(
  [Parameter(Mandatory=$true, Position=0)]
  [string]$Component,

  [Parameter(Mandatory=$true, Position=1)]
  [string]$Version,

  [Parameter(Position=2)]
  [string]$Tag = $null,

  [Parameter(Position=3)]
  [string]$ImageName = $null,

  [Parameter(Position=4)]
  [string]$BinariesRoot = $null,

  [int]$JDKVERSION = 21,
  [string]$OEVERSION = $null,
  [switch]$BuildDevcontainer = $false,
  [switch]$BuildSports2020Db = $false
)

$ErrorActionPreference = 'Stop'

<#
  Fallback shim: some hosts may pass switches as plain arguments, causing
  $Component to receive '-Component'. Detect and re-parse simple -Name value pairs.
#>
if ($Component -like '-*') {
  $raw = @($Component) + $args
  for ($i=0; $i -lt $raw.Count; $i++) {
    switch -Regex ($raw[$i]) {
      '^-(Component)$'   { if ($i+1 -lt $raw.Count) { $Component   = $raw[$i+1] } }
      '^-(Version)$'     { if ($i+1 -lt $raw.Count) { $Version     = $raw[$i+1] } }
      '^-(Tag)$'         { if ($i+1 -lt $raw.Count) { $Tag         = $raw[$i+1] } }
      '^-(ImageName)$'   { if ($i+1 -lt $raw.Count) { $ImageName   = $raw[$i+1] } }
      '^-(BinariesRoot)$'{ if ($i+1 -lt $raw.Count) { $BinariesRoot= $raw[$i+1] } }
      '^-(JDKVERSION)$'  { if ($i+1 -lt $raw.Count) { $JDKVERSION  = [int]$raw[$i+1] } }
      '^-(OEVERSION)$'   { if ($i+1 -lt $raw.Count) { $OEVERSION   = $raw[$i+1] } }
    }
  }
}

if (@('compiler','db_adv','pas_dev','pas_base','pas_orads') -notcontains $Component) {
  throw "Invalid -Component '$Component'. Allowed: compiler, db_adv, pas_dev, pas_base, pas_orads"
}

if ($BuildDevcontainer -and $Component -ne 'compiler') {
  throw "The -BuildDevcontainer switch can only be used with -Component compiler"
}

if ($BuildSports2020Db -and $Component -ne 'db_adv') {
  throw "The -BuildSports2020Db switch can only be used with -Component db_adv"
}

function Convert-ToVersionParts([string]$v){
  if(-not ($v -match '^(\d+)\.(\d+)\.(\d+)$')){ throw "Version must be MAJOR.MINOR.PATCH (e.g. 12.8.6). Got: $v" }
  return [PSCustomObject]@{ Major=[int]$Matches[1]; Minor=[int]$Matches[2]; Patch=[int]$Matches[3] }
}

$ver = Convert-ToVersionParts $Version
$series = "$($ver.Major).$($ver.Minor)"
if(-not $Tag){ $Tag = $Version }

# Defaults per component
switch ($Component) {
  'compiler'  { if(-not $ImageName){ $ImageName = 'rdroge/oe_compiler' }  ; $CTYPE='compiler' }
  'db_adv'    { if(-not $ImageName){ $ImageName = 'rdroge/oe_db_adv' }    ; $CTYPE='db' }
  'pas_dev'   { if(-not $ImageName){ $ImageName = 'rdroge/oe_pas_dev' }   ; $CTYPE='pas' }
  'pas_base'  { if(-not $ImageName){ $ImageName = 'rdroge/oe_pas_base' }  ; $CTYPE='pas' }
  'pas_orads' { if(-not $ImageName){ $ImageName = 'rdroge/oe_pas_orads' } ; $CTYPE='pas' }
}

# Map OEVERSION if not provided (122, 127, 128)
if(-not $OEVERSION){
  $map = @{ '12.2'='122'; '12.7'='127'; '12.8'='128' }
  $OEVERSION = $map[$series]
  if(-not $OEVERSION){ Write-Host "OEVERSION not mapped for series $series; leaving empty." }
}

# Validate response.ini exists before building
$responseIni = Join-Path $root (Join-Path $Component 'response.ini')
if(-not (Test-Path $responseIni)){
  throw "response.ini not found at: $responseIni`n`nPlease configure OpenEdge control codes in the response.ini file before building.`nSee the 'Configure control codes' section in README.md for details."
}

# Prepare installers
$prep = Join-Path $PSScriptRoot 'prepare-installers.ps1'
if(-not (Test-Path $prep)){ throw "Missing $prep" }
$prepArgs = @('-Component', $Component, '-Version', $Version)
if($BinariesRoot){ $prepArgs += @('-BinariesRoot', $BinariesRoot) }

# Invoke the local prepare script directly with named parameters (more robust in some hosts)
if ($BinariesRoot) {
  & $prep -Component $Component -Version $Version -BinariesRoot $BinariesRoot
} else {
  & $prep -Component $Component -Version $Version
}

# Build docker image
$root = Resolve-Path (Join-Path $PSScriptRoot '..')
$dockerfile = Join-Path $root (Join-Path $Component 'Dockerfile')
if(-not (Test-Path $dockerfile)){ throw "Dockerfile not found: $dockerfile" }

# Resolve JDK version like in GitHub Actions by reading jdkversions.json
$jdkJsonPath = Join-Path $root 'jdkversions.json'
if(-not (Test-Path $jdkJsonPath)) { throw "Missing jdkversions.json at $jdkJsonPath" }
$jdkMap = Get-Content -Raw $jdkJsonPath | ConvertFrom-Json
if(-not $OEVERSION) { throw "OEVERSION is empty; cannot determine JDK version mapping" }
$jdkKey = "jdk$OEVERSION"
$JdkVersionValue = $jdkMap.$jdkKey
if(-not $JdkVersionValue) { throw "No JDK mapping found for key '$jdkKey' in $jdkJsonPath" }

# Create a temporary Dockerfile with JDKVERSION placeholder replaced
$tempDir = New-Item -ItemType Directory -Path (Join-Path $env:TEMP ("oe_build_" + [guid]::NewGuid().ToString()))
$tempDockerfile = Join-Path $tempDir.FullName 'Dockerfile'
(Get-Content -Raw $dockerfile).Replace('JDKVERSION', $JdkVersionValue) | Set-Content -NoNewline $tempDockerfile
Write-Host "Using JDK version: $JdkVersionValue (key: $jdkKey)"

$buildArgs = @('--build-arg', "CTYPE=$CTYPE", '--build-arg', "JDKVERSION=$JDKVERSION")
if($OEVERSION){ $buildArgs += @('--build-arg', "OEVERSION=$OEVERSION") }

$tagRef = "$( $ImageName):$Tag"

Write-Host "Building $tagRef using $dockerfile"

$cmd = @('docker','build','-f', $tempDockerfile, '-t', $tagRef) + $buildArgs + @($root)
Write-Host ($cmd -join ' ')
$proc = Start-Process -FilePath $cmd[0] -ArgumentList $cmd[1..($cmd.Length-1)] -NoNewWindow -Wait -PassThru
if($proc.ExitCode -ne 0){ throw "docker build failed with exit code $($proc.ExitCode)" }

Write-Host "Done: $tagRef"

# Cleanup temp
Remove-Item -Recurse -Force $tempDir

# Build devcontainer if requested
if ($BuildDevcontainer) {
  Write-Host ""
  Write-Host "Building devcontainer using local compiler image: $tagRef"
  
  $devcontainerDir = Join-Path $root 'devcontainer'
  $devcontainerDockerfile = Join-Path $devcontainerDir 'Dockerfile'
  
  if (-not (Test-Path $devcontainerDockerfile)) {
    throw "Devcontainer Dockerfile not found: $devcontainerDockerfile"
  }
  
  # Create temporary Dockerfile with local base image
  $devTempDir = New-Item -ItemType Directory -Path (Join-Path $env:TEMP ("oe_devcontainer_" + [guid]::NewGuid().ToString()))
  $devTempDockerfile = Join-Path $devTempDir.FullName 'Dockerfile'
  
  # Replace the FROM line to use the local compiler image
  $devDockerfileContent = Get-Content -Raw $devcontainerDockerfile
  $originalFrom = 'FROM docker.io/progressofficial/oe_compiler:latest'
  $newFrom = "FROM $tagRef"
  
  Write-Host "Replacing base image:"
  Write-Host "  Original: $originalFrom"
  Write-Host "  New:      $newFrom"
  
  $devDockerfileContent = $devDockerfileContent -replace [regex]::Escape($originalFrom), $newFrom
  $devDockerfileContent | Set-Content -NoNewline $devTempDockerfile
  
  # Verify the replacement worked
  $firstLine = (Get-Content $devTempDockerfile -TotalCount 5)[2]
  Write-Host "  Verified: $firstLine"
  
  $devImageName = 'rdroge/oe_devcontainer'
  $devTagRef = "$($devImageName):$Tag"
  
  Write-Host "Building $devTagRef using $devcontainerDockerfile"
  
  $devCmd = @('docker','build','-f', $devTempDockerfile, '-t', $devTagRef, $root)
  Write-Host ($devCmd -join ' ')
  $devProc = Start-Process -FilePath $devCmd[0] -ArgumentList $devCmd[1..($devCmd.Length-1)] -NoNewWindow -Wait -PassThru
  
  if ($devProc.ExitCode -ne 0) {
    Remove-Item -Recurse -Force $devTempDir
    throw "devcontainer build failed with exit code $($devProc.ExitCode)"
  }
  
  Write-Host "Done: $devTagRef"
  
  # Cleanup devcontainer temp
  Remove-Item -Recurse -Force $devTempDir
}

# Build sports2020-db if requested
if ($BuildSports2020Db) {
  Write-Host ""
  Write-Host "Building sports2020-db using local db_adv image: $tagRef"
  
  $sports2020Dir = Join-Path $root 'sports2020-db'
  $sports2020Dockerfile = Join-Path $sports2020Dir 'Dockerfile'
  
  if (-not (Test-Path $sports2020Dockerfile)) {
    throw "Sports2020-db Dockerfile not found: $sports2020Dockerfile"
  }
  
  # Create temporary Dockerfile with local base image
  $sportsTempDir = New-Item -ItemType Directory -Path (Join-Path $env:TEMP ("oe_sports2020_" + [guid]::NewGuid().ToString()))
  $sportsTempDockerfile = Join-Path $sportsTempDir.FullName 'Dockerfile'
  
  # Replace the FROM line to use the local db_adv image
  $sportsDockerfileContent = Get-Content -Raw $sports2020Dockerfile
  $originalFrom = 'FROM progressofficial/oe_db_adv:latest AS install'
  $newFrom = "FROM $tagRef AS install"
  
  Write-Host "Replacing base image:"
  Write-Host "  Original: $originalFrom"
  Write-Host "  New:      $newFrom"
  
  $sportsDockerfileContent = $sportsDockerfileContent -replace [regex]::Escape($originalFrom), $newFrom
  $sportsDockerfileContent | Set-Content -NoNewline $sportsTempDockerfile
  
  # Verify the replacement worked
  $firstLine = (Get-Content $sportsTempDockerfile -TotalCount 1)[0]
  Write-Host "  Verified: $firstLine"
  
  $sportsImageName = 'rdroge/oe_sports2020_db'
  $sportsTagRef = "$($sportsImageName):$Tag"
  
  Write-Host "Building $sportsTagRef using $sports2020Dockerfile"
  
  $sportsCmd = @('docker','build','-f', $sportsTempDockerfile, '-t', $sportsTagRef, $sports2020Dir)
  Write-Host ($sportsCmd -join ' ')
  $sportsProc = Start-Process -FilePath $sportsCmd[0] -ArgumentList $sportsCmd[1..($sportsCmd.Length-1)] -NoNewWindow -Wait -PassThru
  
  if ($sportsProc.ExitCode -ne 0) {
    Remove-Item -Recurse -Force $sportsTempDir
    throw "sports2020-db build failed with exit code $($sportsProc.ExitCode)"
  }
  
  Write-Host "Done: $sportsTagRef"
  
  # Cleanup sports2020 temp
  Remove-Item -Recurse -Force $sportsTempDir
}
