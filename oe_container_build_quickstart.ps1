<#
.SYNOPSIS
    OpenEdge Container Build Quickstart - Interactive tool for building OpenEdge Docker containers.

.DESCRIPTION
    This script provides an interactive menu to:
    1. Generate response.ini files from license addendum
    2. Create all images for DevContainer configuration
    3. Create specific container images with dependency validation
    
    Focused on devcontainer workflows with simplified interface.

.PARAMETER Action
    Specifies the action to perform: 'generate', 'build', or 'both'
    If not specified, runs in interactive mode

.PARAMETER Version
    OpenEdge version (e.g., 12.8.9)

.PARAMETER LicenseFile
    Path to the license addendum file (for generate action)

.PARAMETER Component
    Component to build (for build action): compiler, db_adv, pas_dev, sports2020-db, or all

.PARAMETER DockerUsername
    Docker Hub username (default: empty)

.PARAMETER BuildDevcontainer
    Build devcontainer image after building components

.PARAMETER Force
    Skip confirmation prompts

.PARAMETER Batch
    Run in non-interactive batch mode

.EXAMPLE
    .\oe_container_build_quickstart.ps1
    Runs in interactive mode with menu

.EXAMPLE
    .\oe_container_build_quickstart.ps1 -Action generate -Version 12.8.9 -Force
    Generates response.ini files in batch mode

.EXAMPLE
    .\oe_container_build_quickstart.ps1 -Action build -Component all -Version 12.8.9
    Builds all Docker images in batch mode

.EXAMPLE
    .\oe_container_build_quickstart.ps1 -Action both -Version 12.8.9 -Component all -Force
    Generates response.ini files and builds all images
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('generate', 'build', 'both')]
    [string]$Action,
    
    [Parameter(Mandatory=$false)]
    [string]$Version,
    
    [Parameter(Mandatory=$false)]
    [string]$LicenseFile,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('compiler', 'db_adv', 'pas_dev', 'sports2020-db', 'all')]
    [string]$Component,
    
    [Parameter(Mandatory=$false)]
    [string]$DockerUsername = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$BuildDevcontainer,
    
    [Parameter(Mandatory=$false)]
    [switch]$Force,
    
    [Parameter(Mandatory=$false)]
    [switch]$Batch
)

# Get script directory (now in root)
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$toolsDir = Join-Path $scriptDir "tools"

# Helper function to show menu
function Show-Menu {
    param([string]$DockerUsername)
    
    Clear-Host
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host '      OpenEdge Container Build Quickstart                  ' -ForegroundColor Cyan
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host ''
    Write-Host "  Docker Username: $DockerUsername" -ForegroundColor Green
    Write-Host ''
    Write-Host '  1. Generate response.ini files from license addendum' -ForegroundColor Yellow
    Write-Host '  2. Create all images for DevContainer configuration' -ForegroundColor Yellow
    Write-Host '  3. Select which container images to build' -ForegroundColor Yellow
    Write-Host '  4. Exit' -ForegroundColor Yellow
    Write-Host ''
}

# Helper function to get user choice
function Get-UserChoice {
    param(
        [string]$Prompt,
        [string[]]$ValidChoices
    )
    
    do {
        Write-Host $Prompt -NoNewline -ForegroundColor Yellow
        $choice = Read-Host
        if ($ValidChoices -contains $choice) {
            return $choice
        }
        Write-Host 'Invalid choice. Please try again.' -ForegroundColor Red
    } while ($true)
}

function Get-ComponentSelection {
    param(
        [string]$Title = "Select Components to Build"
    )
    
    $components = @(
        @{ Name = 'compiler'; Description = 'OpenEdge compiler and development tools'; Type = 'Base' },
        @{ Name = 'pas_dev'; Description = 'OpenEdge PAS for development'; Type = 'Base' },
        @{ Name = 'db_adv'; Description = 'OpenEdge database server'; Type = 'Base' },
        @{ Name = 'devcontainer'; Description = 'DevContainer configuration (requires: compiler)'; Type = 'Dependent' },
        @{ Name = 'sports2020-db'; Description = 'Sports2020 database (requires: db_adv)'; Type = 'Dependent' }
    )
    
    $selected = @{}
    foreach ($comp in $components) {
        $selected[$comp.Name] = $false
    }
    
    do {
        Clear-Host
        Write-Host "================================================================" -ForegroundColor Cyan
        Write-Host " $Title" -ForegroundColor Cyan
        Write-Host "================================================================" -ForegroundColor Cyan
        Write-Host ""
        
        Write-Host "Use number keys to toggle selection, 'm' for manual entry, 'c' to continue, or 'q' to quit" -ForegroundColor Yellow
        Write-Host ""
        
        # Display base components
        Write-Host "Base Images (can be built independently):" -ForegroundColor White
        $index = 1
        foreach ($comp in $components | Where-Object { $_.Type -eq 'Base' }) {
            $checkbox = if ($selected[$comp.Name]) { "[X]" } else { "[ ]" }
            $color = if ($selected[$comp.Name]) { 'Green' } else { 'Gray' }
            Write-Host "  $index. $checkbox $($comp.Name)" -ForegroundColor $color -NoNewline
            Write-Host " - $($comp.Description)" -ForegroundColor Gray
            $index++
        }
        
        Write-Host ""
        Write-Host "Dependent Images (require parent images):" -ForegroundColor White
        foreach ($comp in $components | Where-Object { $_.Type -eq 'Dependent' }) {
            $checkbox = if ($selected[$comp.Name]) { "[X]" } else { "[ ]" }
            $color = if ($selected[$comp.Name]) { 'Green' } else { 'Gray' }
            Write-Host "  $index. $checkbox $($comp.Name)" -ForegroundColor $color -NoNewline
            Write-Host " - $($comp.Description)" -ForegroundColor Gray
            $index++
        }
        
        Write-Host ""
        Write-Host "Selected: " -NoNewline -ForegroundColor Yellow
        $selectedNames = $selected.Keys | Where-Object { $selected[$_] }
        if ($selectedNames.Count -gt 0) {
            Write-Host ($selectedNames -join ', ') -ForegroundColor Green
        } else {
            Write-Host "None" -ForegroundColor Red
        }
        
        Write-Host ""
        Write-Host "Enter choice (1-5 to toggle, m for manual entry, c to continue, q to quit): " -NoNewline -ForegroundColor Yellow
        $choice = Read-Host
        
        switch ($choice.ToLower()) {
            '1' { $selected['compiler'] = -not $selected['compiler'] }
            '2' { $selected['pas_dev'] = -not $selected['pas_dev'] }
            '3' { $selected['db_adv'] = -not $selected['db_adv'] }
            '4' { $selected['devcontainer'] = -not $selected['devcontainer'] }
            '5' { $selected['sports2020-db'] = -not $selected['sports2020-db'] }
            'm' {
                Write-Host ""
                Write-Host 'Enter component(s) to build (comma-separated):' -ForegroundColor Yellow
                Write-Host 'Examples: compiler | pas_dev,db_adv | compiler,devcontainer' -ForegroundColor Gray
                $manualInput = Read-Host 'Components'
                
                if (-not [string]::IsNullOrEmpty($manualInput)) {
                    $manualComponents = $manualInput -split ',' | ForEach-Object { $_.Trim() }
                    $validComponents = @('compiler', 'pas_dev', 'db_adv', 'devcontainer', 'sports2020-db')
                    $invalidComponents = $manualComponents | Where-Object { $validComponents -notcontains $_ }
                    
                    if ($invalidComponents.Count -eq 0) {
                        # Reset all selections
                        foreach ($comp in $selected.Keys) {
                            $selected[$comp] = $false
                        }
                        # Set selected components
                        foreach ($comp in $manualComponents) {
                            $selected[$comp] = $true
                        }
                        Write-Host "Manual selection applied: $($manualComponents -join ', ')" -ForegroundColor Green
                    } else {
                        Write-Host "Invalid component(s): $($invalidComponents -join ', ')" -ForegroundColor Red
                        Write-Host "Valid components: $($validComponents -join ', ')" -ForegroundColor Yellow
                    }
                    Start-Sleep 2
                }
            }
            'c' {
                $selectedComponents = $selected.Keys | Where-Object { $selected[$_] }
                if ($selectedComponents.Count -eq 0) {
                    Write-Host "Please select at least one component." -ForegroundColor Red
                    Start-Sleep 2
                    continue
                }
                
                # Check dependencies
                $dependencyErrors = @()
                if ($selected['devcontainer'] -and -not $selected['compiler']) {
                    $dependencyErrors += 'devcontainer requires compiler to be built first or included in the same build'
                }
                if ($selected['sports2020-db'] -and -not $selected['db_adv']) {
                    $dependencyErrors += 'sports2020-db requires db_adv to be built first or included in the same build'
                }
                
                if ($dependencyErrors.Count -gt 0) {
                    Write-Host ""
                    Write-Host 'Dependency errors:' -ForegroundColor Red
                    foreach ($depError in $dependencyErrors) {
                        Write-Host "  - $depError" -ForegroundColor Red
                    }
                    Write-Host ""
                    Write-Host "Press Enter to continue..." -ForegroundColor Yellow
                    Read-Host
                    continue
                }
                
                return ($selectedComponents -join ',')
            }
            'q' { 
                return $null 
            }
            default {
                Write-Host "Invalid choice. Please try again." -ForegroundColor Red
                Start-Sleep 1
            }
        }
    } while ($true)
}

# Helper function to run Generate-ResponseIni.ps1
function Invoke-GenerateResponseIni {
    param(
        [string]$Version,
        [string]$LicenseFile,
        [switch]$Force,
        [switch]$Devcontainer
    )
    
    Write-Host ''
    Write-Host '═══════════════════════════════════════════════════════════' -ForegroundColor Cyan
    Write-Host '  Generating response.ini files...' -ForegroundColor Cyan
    Write-Host '═══════════════════════════════════════════════════════════' -ForegroundColor Cyan
    Write-Host ''
    
    $generateScript = Join-Path $toolsDir "Generate-ResponseIni.ps1"
    
    $params = @{}
    if ($Version) { $params['Version'] = $Version }
    if ($LicenseFile) { $params['LicenseFile'] = $LicenseFile }
    if ($Force) { $params['Force'] = $true }
    if ($Devcontainer) { $params['Devcontainer'] = $true }
    
    & $generateScript @params
    
    if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) {
        Write-Host ""
        Write-Host 'Response.ini generation failed!' -ForegroundColor Red
        return $false
    }
    
    Write-Host ""
    Write-Host 'Response.ini generation completed!' -ForegroundColor Green
    return $true
}

# Helper function to run build-all-images.ps1 or build-image.ps1
function Invoke-BuildImages {
    param(
        [string]$Component,
        [string]$Version,
        [string]$Tag,
        [string]$DockerUsername,
        [string]$BinariesRoot,
        [string]$OeVersion,
        [switch]$SkipDevcontainer,
        [switch]$SkipSports2020Db,
        [switch]$SkipPasOrads,
        [switch]$DevcontainerOnly,
        [switch]$BuildDevcontainer,
        [switch]$BuildSports2020Db
    )
    
    Write-Host ''
    Write-Host '═══════════════════════════════════════════════════════════' -ForegroundColor Cyan
    Write-Host '  Building Docker images...' -ForegroundColor Cyan
    Write-Host '═══════════════════════════════════════════════════════════' -ForegroundColor Cyan
    Write-Host ''
    
    # Check if Component contains comma-separated list
    if ($Component -and $Component.Contains(',')) {
        # Build multiple components
        $components = $Component -split ',' | ForEach-Object { $_.Trim() }
        $buildScript = Join-Path $toolsDir "build-image.ps1"
        
        foreach ($comp in $components) {
            if (@('compiler','db_adv','pas_dev','devcontainer','sports2020-db') -notcontains $comp) {
                Write-Host 'Invalid component: ' -NoNewline -ForegroundColor Red; Write-Host $comp -ForegroundColor Red
                Write-Host 'Valid components: compiler, db_adv, pas_dev, devcontainer, sports2020-db' -ForegroundColor Yellow
                return $false
            }
            
            Write-Host ""
            Write-Host 'Building component: ' -NoNewline -ForegroundColor Cyan; Write-Host $comp -ForegroundColor Cyan
            
            $params = @{
                'Component' = $comp
                'Version' = $Version
                'DockerUsername' = $DockerUsername
            }
            if ($Tag) { $params['Tag'] = $Tag }
            if ($BinariesRoot) { $params['BinariesRoot'] = $BinariesRoot }
            if ($OeVersion) { $params['OEVERSION'] = $OeVersion }
            
            # Special handling for devcontainer and sports2020-db
            if ($comp -eq 'devcontainer') {
                $params['Component'] = 'compiler'
                $params['BuildDevcontainer'] = $true
            }
            elseif ($comp -eq 'sports2020-db') {
                $params['Component'] = 'db_adv'
                $params['BuildSports2020Db'] = $true
            }
            
            & $buildScript @params
            
            if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) {
                Write-Host ""
                Write-Host 'Failed to build component: ' -NoNewline -ForegroundColor Red; Write-Host $comp -ForegroundColor Red
                return $false
            }
        }
        
        Write-Host ""
        Write-Host 'All components built successfully!' -ForegroundColor Green
        return $true
    }
    elseif ($Component -eq 'all' -or [string]::IsNullOrEmpty($Component)) {
        # Build all images
        $buildScript = Join-Path $toolsDir "build-all-images.ps1"
        
        $params = @{
            'Version' = $Version
            'DockerUsername' = $DockerUsername
        }
        if ($Tag) { $params['Tag'] = $Tag }
        if ($BinariesRoot) { $params['BinariesRoot'] = $BinariesRoot }
        if ($OeVersion) { $params['OEVERSION'] = $OeVersion }
        if ($SkipDevcontainer) { $params['SkipDevcontainer'] = $true }
        if ($SkipSports2020Db) { $params['SkipSports2020Db'] = $true }
        if ($SkipPasOrads) { $params['SkipPasOrads'] = $true }
        if ($DevcontainerOnly) { $params['DevcontainerOnly'] = $true }
        
        & $buildScript @params
        
        if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) {
            Write-Host ""
            Write-Host 'Docker image build failed!' -ForegroundColor Red
            return $false
        }
        
        Write-Host ""
        Write-Host 'Docker image build completed!' -ForegroundColor Green
        return $true
    }
    else {
        # Build single component
        $buildScript = Join-Path $toolsDir "build-image.ps1"
        
        $params = @{
            'Component' = $Component
            'Version' = $Version
            'DockerUsername' = $DockerUsername
        }
        if ($Tag) { $params['Tag'] = $Tag }
        if ($BinariesRoot) { $params['BinariesRoot'] = $BinariesRoot }
        if ($OeVersion) { $params['OEVERSION'] = $OeVersion }
        if ($BuildDevcontainer) { $params['BuildDevcontainer'] = $true }
        if ($BuildSports2020Db) { $params['BuildSports2020Db'] = $true }
        
        & $buildScript @params
        
        if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) {
            Write-Host ""
            Write-Host 'Docker image build failed!' -ForegroundColor Red
            return $false
        }
        
        Write-Host ""
        Write-Host 'Docker image build completed!' -ForegroundColor Green
        return $true
    }
}

# Main execution logic
function Invoke-Main {
    # Interactive mode
    if ([string]::IsNullOrEmpty($Action) -and -not $Batch) {
        # Get Docker username first if not provided
        if ([string]::IsNullOrEmpty($DockerUsername) -or $DockerUsername -eq "") {
            Clear-Host
            Write-Host '============================================================' -ForegroundColor Cyan
            Write-Host '      OpenEdge Container Build Quickstart                  ' -ForegroundColor Cyan
            Write-Host '============================================================' -ForegroundColor Cyan
            Write-Host ''
            Write-Host 'Please enter your Docker Hub username to continue.' -ForegroundColor White
            Write-Host 'This will be used to tag the built images.' -ForegroundColor Gray
            Write-Host ''
            do {
                $DockerUsername = Read-Host 'Docker Username'
                if ([string]::IsNullOrEmpty($DockerUsername)) {
                    Write-Host 'Docker username is required.' -ForegroundColor Red
                }
            } while ([string]::IsNullOrEmpty($DockerUsername))
        }
        
        do {
            Show-Menu -DockerUsername $DockerUsername
            $choice = Get-UserChoice -Prompt 'Select an option (1-4)' -ValidChoices @('1', '2', '3', '4')
            
            if ($choice -eq '4') {
                Write-Host 'Exiting...' -ForegroundColor Yellow
                return
            }
            
            # Get version if not provided
            if ([string]::IsNullOrEmpty($Version)) {
                Write-Host ""
                $Version = Read-Host 'Enter OpenEdge version (e.g., 12.8.9)'
            }
            
            switch ($choice) {
                '1' {
                    # Generate response.ini
                    $devcontainer = Get-UserChoice -Prompt 'Only generate response.ini files for DevContainer configuration (pas_dev,compiler,db_adv)? (y/n)' -ValidChoices @('y', 'n')
                    $success = Invoke-GenerateResponseIni -Version $Version -Force:$Force -Devcontainer:($devcontainer -eq 'y')
                    
                    Write-Host ""
                    Read-Host 'Press Enter to continue'
                }
                '2' {
                    # Create all images for DevContainer configuration
                    Write-Host ""
                    Write-Host 'Building all images required for DevContainer configuration...' -ForegroundColor Cyan
                    Write-Host 'This will build: compiler, pas_dev, db_adv, devcontainer, sports2020-db' -ForegroundColor Gray
                    
                    $buildParams = @{
                        'Component' = 'all'
                        'Version' = $Version
                        'DockerUsername' = $DockerUsername
                        'DevcontainerOnly' = $true
                    }
                    
                    $success = Invoke-BuildImages @buildParams
                    
                    Write-Host ""
                    Read-Host 'Press Enter to continue'
                }
                '3' {
                    # Create specific container images
                    $comp = Get-ComponentSelection -Title "Select Components to Build"
                    
                    if ($null -eq $comp) {
                        # User chose to quit
                        continue
                    }
                    
                    $buildParams = @{
                        'Component' = $comp
                        'Version' = $Version
                        'DockerUsername' = $DockerUsername
                    }
                    
                    $success = Invoke-BuildImages @buildParams
                    
                    Write-Host ""
                    Read-Host 'Press Enter to continue'
                }
            }
        } while ($true)
    }
    # Batch mode
    else {
        if ([string]::IsNullOrEmpty($Action)) {
            Write-Host 'Error: -Action parameter is required in batch mode' -ForegroundColor Red
            Write-Host 'Use -Action generate, -Action build, or -Action both' -ForegroundColor Yellow
            exit 1
        }
        
        if ([string]::IsNullOrEmpty($Version)) {
            Write-Host 'Error: -Version parameter is required' -ForegroundColor Red
            exit 1
        }
        
        $success = $true
        
        if ($Action -eq 'generate' -or $Action -eq 'both') {
            $success = Invoke-GenerateResponseIni -Version $Version -LicenseFile $LicenseFile -Force:$Force -Devcontainer:$BuildDevcontainer
        }
        
        if ($success -and ($Action -eq 'build' -or $Action -eq 'both')) {
            if ([string]::IsNullOrEmpty($Component)) { $Component = 'all' }
            $success = Invoke-BuildImages -Component $Component -Version $Version -DockerUsername $DockerUsername -BuildDevcontainer:$BuildDevcontainer
        }
        
        if (-not $success) {
            exit 1
        }
    }
}

# Run main function
Invoke-Main
