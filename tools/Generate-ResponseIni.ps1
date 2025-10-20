#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Generates response.ini files for OpenEdge container builds from license addendum file.

.DESCRIPTION
    This script parses a Progress Software License Addendum file and generates tailored
    response.ini files for each required container build (compiler, db_adv, pas_dev, pas_base).
    It extracts company name, serial numbers, and control codes for each product.
    For versions 12.2.17-12.2.18 and 12.8.4-12.8.8, it also generates response_update.ini files.

.PARAMETER LicenseFile
    Path to the license addendum file. Defaults to ../addendum/US*.txt

.PARAMETER Version
    OpenEdge version (e.g., 12.8.6). Used to determine if response_update.ini is needed.
    If not specified, the script will extract version from the license file.

.PARAMETER Devcontainer
    When specified, generates response.ini files for all images required for devcontainer configuration.

.PARAMETER Force
    Overwrites existing response.ini files without prompting.

.EXAMPLE
    .\Generate-ResponseIni.ps1
    Generates response.ini files for standard container builds.

.EXAMPLE
    .\Generate-ResponseIni.ps1 -Devcontainer
    Generates response.ini files for all devcontainer images.

.EXAMPLE
    .\Generate-ResponseIni.ps1 -LicenseFile "C:\path\to\license.txt" -Force
    Uses a specific license file and overwrites existing files.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$LicenseFile,
    
    [Parameter(Mandatory=$false)]
    [string]$Version,
    
    [Parameter(Mandatory=$false)]
    [switch]$Devcontainer,
    
    [Parameter(Mandatory=$false)]
    [switch]$Force
)

# Set strict mode
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Get script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Split-Path -Parent $scriptDir

# Container build configurations
$buildConfigs = @{
    "compiler" = @{
        "Products" = @("4GL Development System", "Client Networking", "Progress Dev AS for OE")
        "Path" = Join-Path $rootDir "compiler"
    }
    "db_adv" = @{
        "Products" = @("OE RDBMS Adv Enterprise")
        "Path" = Join-Path $rootDir "db_adv"
    }
    "pas_dev" = @{
        "Products" = @("Progress Dev AppServer for OE")
        "Path" = Join-Path $rootDir "pas_dev"
    }
    "pas_base" = @{
        "Products" = @("Progress App Server for OE", "Progress Prod AppServer for OE")
        "Path" = Join-Path $rootDir "pas_base"
    }
}

# Devcontainer requires all of the above
if ($Devcontainer) {
    Write-Host "Devcontainer mode: Will generate response.ini for all required images" -ForegroundColor Cyan
}

function Test-RequiresUpdateIni {
    param([string]$Version)
    
    if ([string]::IsNullOrEmpty($Version)) {
        return $false
    }
    
    # Parse version
    if ($Version -match '^(\d+)\.(\d+)\.(\d+)') {
        $major = [int]$Matches[1]
        $minor = [int]$Matches[2]
        $patch = [int]$Matches[3]
        
        # Check if version requires response_update.ini
        # 12.2.17-12.2.18 or 12.8.4-12.8.8
        if ($major -eq 12 -and $minor -eq 2 -and $patch -ge 17 -and $patch -le 18) {
            return $true
        }
        if ($major -eq 12 -and $minor -eq 8 -and $patch -ge 4 -and $patch -le 8) {
            return $true
        }
    }
    
    return $false
}

function Test-LicenseFileFormat {
    param([string]$FilePath)
    
    if (-not (Test-Path $FilePath)) {
        throw "License file not found: $FilePath"
    }
    
    $content = Get-Content $FilePath -Raw
    
    # Check for required format markers
    $hasHeader = $content -match 'Progress Software Corporation.*License Addendum'
    $hasProducts = $content -match 'Product\s+Ship\s+Units\s+Release'
    $hasSerialControl = $content -match 'Serial #:\s+\d+\s+Rel:\s+[\d\.]+\s+Control#:'
    
    if (-not $hasHeader) {
        throw "Invalid license file format: Missing Progress Software Corporation License Addendum header"
    }
    
    if (-not $hasProducts) {
        throw "Invalid license file format: Missing product listing section"
    }
    
    if (-not $hasSerialControl) {
        throw "Invalid license file format: Missing serial number and control code information"
    }
    
    Write-Host "✓ License file format validated" -ForegroundColor Green
    return $true
}

function Get-CompanyName {
    param([string]$Content)
    
    # Extract company name from "Registered To" section
    if ($Content -match 'Registered To:\d+\s+(.+?)(?:\r?\n)') {
        $companyName = $Matches[1].Trim()
        Write-Verbose "Found company name: $companyName"
        return $companyName
    }
    
    # Fallback: try Customer/Partner section
    if ($Content -match 'Customer/Partner:\d+\s+(.+?)(?:\r?\n)') {
        $companyName = $Matches[1].Trim()
        Write-Verbose "Found company name (fallback): $companyName"
        return $companyName
    }
    
    throw "Could not extract company name from license file"
}

function Get-LicenseProducts {
    param([string]$Content)
    
    $products = @{}
    
    # Split content into lines
    $lines = $Content -split '[\r\n]+'
    
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        
        # Match product lines with serial and control codes
        # Format: "Linux 64bit        Serial #:    006275022  Rel: 12.8    Control#:YZFRS XQP2M NMG?R"
        if ($line -match 'Serial #:\s+(\d+)\s+Rel:\s+([\d\.]+)\s+Control#:(.+)$') {
            $serial = $Matches[1].Trim()
            $release = $Matches[2].Trim()
            $control = $Matches[3].Trim()
            
            # Look backwards for product name
            for ($j = $i - 1; $j -ge 0 -and $j -ge ($i - 10); $j--) {
                $prevLine = $lines[$j]
                
                # Match various product name patterns
                if ($prevLine -match '^\s*(4GL Development System|Client Networking|Progress Dev AS for OE|Progress Prod AppServer for OE|OE RDBMS Adv Enterprise|OE AuthenticationGateway|Progress App Server for OE)') {
                    $productName = $Matches[1].Trim()
                    
                    $productKey = "$productName|$serial"
                    
                    if (-not $products.ContainsKey($productKey)) {
                        $products[$productKey] = @{
                            "Name" = $productName
                            "Serial" = $serial
                            "Release" = $release
                            "Control" = $control
                        }
                        Write-Verbose "Found product: $productName (Serial: $serial, Control: $control)"
                    }
                    break
                }
            }
        }
        
        # Also check for bundle products with separate control codes
        # Format: "      Progress Dev AppServer for OE          Units: 1"
        # Followed by: "      Serial #:    006275040   Rel: 12.8     Control#:Z8DRS 2PP2N N4C?4"
        if ($line -match '^\s+(4GL Development System|Client Networking|Progress Dev AS for OE|Progress Prod AppServer for OE|OE RDBMS Adv Enterprise|OE AuthenticationGateway|Progress App Server for OE)\s+Units:\s+\d+') {
            $productName = $Matches[1].Trim()
            
            # Look ahead for serial and control
            for ($j = $i + 1; $j -lt $lines.Count -and $j -le ($i + 3); $j++) {
                $nextLine = $lines[$j]
                if ($nextLine -match 'Serial #:\s+(\d+)\s+Rel:\s+([\d\.]+)\s+Control#:(.+)$') {
                    $serial = $Matches[1].Trim()
                    $release = $Matches[2].Trim()
                    $control = $Matches[3].Trim()
                    
                    $productKey = "$productName|$serial"
                    
                    if (-not $products.ContainsKey($productKey)) {
                        $products[$productKey] = @{
                            "Name" = $productName
                            "Serial" = $serial
                            "Release" = $release
                            "Control" = $control
                        }
                        Write-Verbose "Found bundle product: $productName (Serial: $serial, Control: $control)"
                    }
                    break
                }
            }
        }
    }
    
    return $products
}

function New-ResponseIni {
    param(
        [string]$TargetPath,
        [string]$CompanyName,
        [array]$Products,
        [string]$TemplateFile
    )
    
    $outputFile = Join-Path $TargetPath "response.ini"
    
    # Check if file exists
    if ((Test-Path $outputFile) -and -not $Force) {
        $response = Read-Host "File $outputFile already exists. Overwrite? (y/N)"
        if ($response -ne 'y' -and $response -ne 'Y') {
            Write-Host "Skipping $outputFile" -ForegroundColor Yellow
            return
        }
    }
    
    # Read template
    if (-not (Test-Path $TemplateFile)) {
        throw "Template file not found: $TemplateFile"
    }
    
    $template = Get-Content $TemplateFile -Raw
    
    # Update configuration count
    $configCount = $Products.Count
    $template = $template -replace "NumberofConfigurations=\d+", "NumberofConfigurations=$configCount"
    
    # Generate product configurations
    $productConfigs = @()
    for ($i = 0; $i -lt $Products.Count; $i++) {
        $product = $Products[$i]
        $configNum = $i + 1
        
        $config = @"

[Product Configuration $configNum]
name=$CompanyName
serial=$($product.Serial)
version=$($product.Release)
control=$($product.Control)
prodname=$($product.Name)
"@
        $productConfigs += $config
    }
    
    # Replace existing product configurations
    $template = $template -replace '(?s)\[Product Configuration 1\].*?(?=\r?\n\r?\n\[|\r?\n;|\Z)', ''
    
    # Insert new configurations after [Configuration Count] section
    $insertPoint = $template.IndexOf('[Configuration Count]')
    if ($insertPoint -ge 0) {
        $endOfSection = $template.IndexOf("`n`n", $insertPoint)
        if ($endOfSection -ge 0) {
            $template = $template.Substring(0, $endOfSection) + ($productConfigs -join "") + $template.Substring($endOfSection)
        }
    }
    
    # Write output
    $template | Out-File -FilePath $outputFile -Encoding UTF8 -NoNewline
    Write-Host "Generated: $outputFile" -ForegroundColor Green
}

function New-ResponseUpdateIni {
    param(
        [string]$TargetPath,
        [string]$CompanyName,
        [string]$Version,
        [string]$TemplateFile
    )
    
    $outputFile = Join-Path $TargetPath "response_update.ini"
    
    # Check if file exists
    if ((Test-Path $outputFile) -and -not $Force) {
        $response = Read-Host "File $outputFile already exists. Overwrite? (y/N)"
        if ($response -ne 'y' -and $response -ne 'Y') {
            Write-Host "Skipping $outputFile" -ForegroundColor Yellow
            return
        }
    }
    
    # Read template
    if (-not (Test-Path $TemplateFile)) {
        throw "Template file not found: $TemplateFile"
    }
    
    $template = Get-Content $TemplateFile -Raw
    
    # Update company name in [Application] section
    $template = $template -replace "Company=.*", "Company=$CompanyName"
    
    # Update version if provided
    if ($Version -match '^(\d+)\.(\d+)') {
        $majorMinor = "$($Matches[1]).$($Matches[2])"
        $template = $template -replace "Version=[\d\.]+", "Version=$majorMinor"
        
        # Update backup directory path with version
        if ($Version -match '^(\d+)\.(\d+)\.(\d+)') {
            $fullVersion = "$($Matches[1]).$($Matches[2]).$($Matches[3])"
            $template = $template -replace "_sSPBackupDir=/usr/dlc/Backup[\d\.]+", "_sSPBackupDir=/usr/dlc/Backup$fullVersion"
        }
    }
    
    # Write output
    $template | Out-File -FilePath $outputFile -Encoding UTF8 -NoNewline
    Write-Host "Generated: $outputFile" -ForegroundColor Green
}

# Main execution
try {
    Write-Host "`n=== OpenEdge Response.ini Generator ===" -ForegroundColor Cyan
    Write-Host ""
    
    # Find license file
    if (-not $LicenseFile) {
        $addendumDir = Join-Path $rootDir "addendum"
        $licenseFiles = Get-ChildItem -Path $addendumDir -Filter "*.txt" | Where-Object { $_.Name -match "^US\d+" -or $_.Name -match "License.*Addendum" }
        
        if ($licenseFiles.Count -eq 0) {
            throw "No license addendum file found in $addendumDir. Please specify -LicenseFile parameter."
        }
        
        if ($licenseFiles.Count -gt 1) {
            Write-Host "Multiple license files found:" -ForegroundColor Yellow
            for ($i = 0; $i -lt $licenseFiles.Count; $i++) {
                Write-Host "  [$i] $($licenseFiles[$i].Name)"
            }
            $selection = Read-Host "Select file number"
            $LicenseFile = $licenseFiles[$selection].FullName
        } else {
            $LicenseFile = $licenseFiles[0].FullName
        }
    }
    
    Write-Host "Using license file: $LicenseFile" -ForegroundColor Cyan
    Write-Host ""
    
    # Validate license file format
    Test-LicenseFileFormat -FilePath $LicenseFile
    
    # Read license file
    $licenseContent = Get-Content $LicenseFile -Raw
    
    # Extract company name
    $companyName = Get-CompanyName -Content $licenseContent
    Write-Host "Company Name: $companyName" -ForegroundColor Cyan
    Write-Host ""
    
    # Extract products
    $allProducts = Get-LicenseProducts -Content $licenseContent
    Write-Host "Found $($allProducts.Count) licensed products" -ForegroundColor Cyan
    
    # Detect version from license file if not provided
    $detectedVersion = $null
    if ([string]::IsNullOrEmpty($Version)) {
        # Try to extract version from first product
        foreach ($productKey in $allProducts.Keys) {
            $product = $allProducts[$productKey]
            if ($product.Release) {
                $detectedVersion = $product.Release
                break
            }
        }
    } else {
        $detectedVersion = $Version
    }
    
    # Check if response_update.ini is needed
    $requiresUpdateIni = Test-RequiresUpdateIni -Version $detectedVersion
    if ($requiresUpdateIni) {
        Write-Host "Version $detectedVersion requires response_update.ini files" -ForegroundColor Cyan
    }
    Write-Host ""
    
    # Generate response.ini for each build configuration
    foreach ($buildName in $buildConfigs.Keys) {
        $config = $buildConfigs[$buildName]
        $buildPath = $config.Path
        $requiredProducts = $config.Products
        
        Write-Host "Processing: $buildName" -ForegroundColor Yellow
        
        # Find matching products
        $matchedProducts = @()
        foreach ($productKey in $allProducts.Keys) {
            $product = $allProducts[$productKey]
            
            # Check if this product matches any required product
            foreach ($required in $requiredProducts) {
                if ($product.Name -eq $required -or $product.Name -like "*$required*") {
                    $matchedProducts += $product
                    Write-Host "  - Found: $($product.Name) (Serial: $($product.Serial))" -ForegroundColor Gray
                    break
                }
            }
        }
        
        if ($matchedProducts.Count -eq 0) {
            Write-Host "   No matching products found for $buildName" -ForegroundColor Yellow
            continue
        }
        
        # Special handling for Client Networking (serial = 0)
        if ($buildName -eq "compiler") {
            $clientNetworking = $matchedProducts | Where-Object { $_.Name -eq "Client Networking" }
            if ($clientNetworking) {
                # Client Networking typically uses serial 0
                # But keep the control code from the license
            }
        }
        
        # Generate response.ini
        $templateFile = Join-Path $buildPath "response_ini_example.txt"
        New-ResponseIni -TargetPath $buildPath -CompanyName $companyName -Products $matchedProducts -TemplateFile $templateFile
        
        # Generate response_update.ini if needed
        if ($requiresUpdateIni) {
            $updateTemplateFile = Join-Path $buildPath "response_update_ini_example.txt"
            if (Test-Path $updateTemplateFile) {
                New-ResponseUpdateIni -TargetPath $buildPath -CompanyName $companyName -Version $detectedVersion -TemplateFile $updateTemplateFile
            } else {
                Write-Host "   Warning: response_update_ini_example.txt not found in $buildPath" -ForegroundColor Yellow
            }
        }
        
        Write-Host ""
    }
    
    Write-Host "=== Generation Complete ===" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Review the generated response.ini files in each component directory"
    Write-Host "2. Verify the license information is correct"
    Write-Host "3. Build your Docker containers"
    Write-Host ""
    
} catch {
    Write-Host "`nError: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}
