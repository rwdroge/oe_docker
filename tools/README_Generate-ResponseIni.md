# Generate-ResponseIni.ps1

Automated script to generate `response.ini` files for OpenEdge container builds from Progress Software License Addendum files.

## Overview

This PowerShell script parses your Progress Software License Addendum file and automatically generates tailored `response.ini` files for each required container build. It eliminates manual copying and editing of license information across multiple configuration files.

## Features

- ✅ **Validates license file format** - Ensures the addendum file has the correct structure
- ✅ **Extracts license information** - Automatically parses company name, serial numbers, and control codes
- ✅ **Generates multiple configs** - Creates response.ini for compiler, db_adv, pas_dev, and pas_base
- ✅ **Auto-generates response_update.ini** - For versions 12.2.17-12.2.18 and 12.8.4-12.8.8 that require patch installers
- ✅ **Version detection** - Automatically detects version from license file or accepts manual override
- ✅ **Devcontainer support** - Option to generate all files needed for devcontainer configuration
- ✅ **Safe overwrites** - Prompts before overwriting existing files (unless -Force is used)
- ✅ **Cross-platform** - Works on Windows, Linux, and macOS with PowerShell Core

## Prerequisites

- PowerShell 5.1+ (Windows) or PowerShell Core 7+ (Linux/macOS)
- A valid Progress Software License Addendum file in the `addendum/` directory

## Usage

### Basic Usage

```powershell
# Navigate to tools directory
cd c:\docker\openedge\tools

# Run the script (auto-detects license file in ../addendum/)
.\Generate-ResponseIni.ps1
```

### Specify License File

```powershell
.\Generate-ResponseIni.ps1 -LicenseFile "C:\path\to\US263472 License Addendum.txt"
```

### Specify Version

Override version detection (useful for generating files for a specific version):

```powershell
.\Generate-ResponseIni.ps1 -Version 12.8.6
```

This is particularly useful for versions **12.2.17-12.2.18** and **12.8.4-12.8.8** which require both `response.ini` and `response_update.ini` files.

### Devcontainer Mode

Generate response.ini files for all images required for devcontainer configuration:

```powershell
.\Generate-ResponseIni.ps1 -Devcontainer
```

### Force Overwrite

Overwrite existing response.ini files without prompting:

```powershell
.\Generate-ResponseIni.ps1 -Force
```

### Verbose Output

See detailed parsing information:

```powershell
.\Generate-ResponseIni.ps1 -Verbose
```

## What It Does

1. **Locates License File**: Searches for `US*.txt` or `*License*Addendum*.txt` in the `addendum/` directory
2. **Validates Format**: Checks that the file contains required sections (header, products, serial/control codes)
3. **Extracts Company Name**: Parses the "Registered To" section for your company name
4. **Parses Products**: Extracts all licensed products with their serial numbers and control codes
5. **Matches Products to Builds**: Maps products to the appropriate container configurations:
   - **compiler**: 4GL Development System, Client Networking, Progress Dev AS for OE
   - **db_adv**: OE RDBMS Adv Enterprise
   - **pas_dev**: Progress Dev AS for OE
   - **pas_base**: Progress App Server for OE / Progress Prod AppServer for OE
6. **Generates response.ini**: Creates properly formatted files in each component directory

## Output

The script generates `response.ini` files in the following locations:

```
c:\docker\openedge\
├── compiler\
│   ├── response.ini          ← Generated
│   └── response_update.ini   ← Generated (if version requires it)
├── db_adv\
│   ├── response.ini          ← Generated
│   └── response_update.ini   ← Generated (if version requires it)
├── pas_dev\
│   ├── response.ini          ← Generated
│   └── response_update.ini   ← Generated (if version requires it)
└── pas_base\
    ├── response.ini          ← Generated
    └── response_update.ini   ← Generated (if version requires it)
```

**Note:** `response_update.ini` files are only generated for versions **12.2.17-12.2.18** and **12.8.4-12.8.8** which require both base and patch installers.

## Example Output

```
=== OpenEdge Response.ini Generator ===

Using license file: c:\docker\openedge\addendum\US263472 License Addendum.txt

✓ License file format validated
Company Name: Progress Software ESD

Found 18 licensed products
Version 12.8.6 requires response_update.ini files

Processing: compiler
  - Found: 4GL Development System (Serial: 006275022)
  - Found: Client Networking (Serial: 006275023)
  - Found: Progress Dev AS for OE (Serial: 006275040)
✓ Generated: c:\docker\openedge\compiler\response.ini
✓ Generated: c:\docker\openedge\compiler\response_update.ini

Processing: db_adv
  - Found: OE RDBMS Adv Enterprise (Serial: 006275036)
✓ Generated: c:\docker\openedge\db_adv\response.ini

Processing: pas_dev
  - Found: Progress Dev AS for OE (Serial: 006275040)
✓ Generated: c:\docker\openedge\pas_dev\response.ini

Processing: pas_base
  - Found: Progress Prod AppServer for OE (Serial: 006275041)
✓ Generated: c:\docker\openedge\pas_base\response.ini

=== Generation Complete ===

Next steps:
1. Review the generated response.ini files in each component directory
2. Verify the license information is correct
3. Build your Docker containers
```

## License File Format

The script expects a Progress Software License Addendum file downloaded from ESD (https://esd.progress.com/).



## Supported Products

The script recognizes and processes the following products:

- 4GL Development System
- Client Networking
- Progress Dev AS for OE
- Progress Prod AppServer for OE
- Progress App Server for OE
- OE RDBMS Adv Enterprise


## Troubleshooting

### "License file not found"

**Solution**: Ensure your license addendum file is in the `addendum/` directory and has a `.txt` extension.

### "Invalid license file format"

**Solution**: Verify your file is a genuine Progress Software License Addendum. Check for:
- "Progress Software Corporation" header
- Product listing section
- Serial numbers and control codes

### "No matching products found"

**Solution**: Your license may not include the required products for that build. Check your license addendum to confirm you have licenses for:
- Compiler: 4GL Development System, Client Networking, Progress Dev AS for OE
- DB Advanced: OE RDBMS Adv Enterprise
- PAS Dev: Progress Dev AS for OE
- PAS Base: Progress App Server for OE

### Script fails on Linux/macOS

**Solution**: Install PowerShell Core:
```bash
# Ubuntu/Debian
sudo apt-get install -y powershell

# macOS
brew install --cask powershell

# Then run with pwsh
pwsh ./Generate-ResponseIni.ps1
```

## Security Notes

- ⚠️ **Never commit response.ini files** - They contain sensitive license information
- ✅ Response.ini files are already in `.gitignore`
- ✅ Keep your license addendum files secure
- ✅ Use environment-specific licenses for dev/test/prod

## Related Documentation

- [RESPONSE_INI_GUIDE.md](../RESPONSE_INI_GUIDE.md) - Detailed guide on response.ini files
- [OpenEdge Installation Guide](https://docs.progress.com/bundle/openedge-install-guide)

## Support

For issues or questions:
1. Check the [RESPONSE_INI_GUIDE.md](../RESPONSE_INI_GUIDE.md)
2. Verify your license addendum file format
3. Run with `-Verbose` flag for detailed output
4. Check the script's error messages for specific issues

## Version History

- **v1.0** (2024-10-20): Initial release
  - Auto-detection of license files
  - Support for compiler, db_adv, pas_dev, pas_base
  - Devcontainer mode
  - Format validation
