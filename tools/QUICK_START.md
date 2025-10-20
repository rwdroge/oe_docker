# Quick Start: Generate Response.ini Files

This guide provides a quick walkthrough for generating `response.ini` files from your Progress license addendum.

## Prerequisites

✅ Progress Software License Addendum file (e.g., `US263472 License Addendum.txt`)  
✅ PowerShell 5.1+ (Windows) or PowerShell Core 7+ (Linux/macOS)

## Step-by-Step

### 1. Place Your License File

Copy your license addendum file to the `addendum/` directory:

```
c:\docker\openedge\addendum\
└── US263472 License Addendum.txt  ← Your license file
```

### 2. Run the Script

**Windows:**
```powershell
cd c:\docker\openedge\tools
.\Generate-ResponseIni.ps1
```

**Linux/macOS:**
```bash
cd /path/to/docker/openedge/tools
./generate-response-ini.sh
```

### 3. Review Output

The script will:
- ✅ Validate your license file format
- ✅ Extract company name and license information
- ✅ Detect OpenEdge version from license file
- ✅ Generate `response.ini` files in each component directory
- ✅ Generate `response_update.ini` files (for versions 12.2.17-12.2.18 and 12.8.4-12.8.8)

Example output:
```
=== OpenEdge Response.ini Generator ===

Using license file: c:\docker\openedge\addendum\US263472 License Addendum.txt

✓ License file format validated
Company Name: Progress Software ESD

Found 18 licensed products

Processing: compiler
  - Found: 4GL Development System (Serial: 006275022)
  - Found: Client Networking (Serial: 006275023)
  - Found: Progress Dev AS for OE (Serial: 006275040)
✓ Generated: c:\docker\openedge\compiler\response.ini

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
```

### 4. Verify Generated Files

Check that `response.ini` files were created:

```
c:\docker\openedge\
├── compiler\response.ini    ← Generated ✓
├── db_adv\response.ini      ← Generated ✓
├── pas_dev\response.ini     ← Generated ✓
└── pas_base\response.ini    ← Generated ✓
```

### 5. Build Your Containers

Now you're ready to build your Docker images:

```powershell
# Build all images
pwsh ./tools/build-all-images.ps1 -Version 12.8.6 -Tag 12.8.6

# Or build individual images
pwsh ./tools/build-image.ps1 -Component compiler -Version 12.8.6 -Tag 12.8.6
```

## Common Options

### Devcontainer Mode

Generate files for all devcontainer images:

```powershell
.\Generate-ResponseIni.ps1 -Devcontainer
```

### Force Overwrite

Skip confirmation prompts:

```powershell
.\Generate-ResponseIni.ps1 -Force
```

### Specify License File

Use a specific license file:

```powershell
.\Generate-ResponseIni.ps1 -LicenseFile "C:\path\to\license.txt"
```

### Specify Version

Override version detection (useful for versions requiring response_update.ini):

```powershell
.\Generate-ResponseIni.ps1 -Version 12.8.6
```

### Verbose Output

See detailed parsing information:

```powershell
.\Generate-ResponseIni.ps1 -Verbose
```

## Troubleshooting

### "License file not found"

**Problem:** No license file found in `addendum/` directory.

**Solution:** Place your `US*.txt` license file in the `addendum/` directory.

### "Invalid license file format"

**Problem:** License file doesn't match expected format.

**Solution:** Ensure you're using an official Progress Software License Addendum file. See [LICENSE_ADDENDUM_FORMAT.md](../addendum/LICENSE_ADDENDUM_FORMAT.md) for format details.

### "No matching products found"

**Problem:** Your license doesn't include required products for a component.

**Solution:** Check your license addendum to confirm you have licenses for:
- **compiler**: 4GL Development System, Client Networking, Progress Dev AS for OE
- **db_adv**: OE RDBMS Adv Enterprise
- **pas_dev**: Progress Dev AS for OE
- **pas_base**: Progress App Server for OE

### PowerShell not found (Linux/macOS)

**Problem:** `pwsh` command not available.

**Solution:** Install PowerShell Core:
```bash
# Ubuntu/Debian
sudo apt-get install -y powershell

# macOS
brew install --cask powershell
```

## Next Steps

After generating `response.ini` files:

1. ✅ **Review files** - Open each `response.ini` and verify license information
2. ✅ **Place installers** - Ensure OpenEdge installers are in `binaries/oe/<version>/`
3. ✅ **Build images** - Run the build scripts to create Docker images
4. ✅ **Test containers** - Verify your containers work correctly

## Additional Resources

- **[README_Generate-ResponseIni.md](README_Generate-ResponseIni.md)** - Detailed script documentation
- **[LICENSE_ADDENDUM_FORMAT.md](../addendum/LICENSE_ADDENDUM_FORMAT.md)** - License file format reference
- **[RESPONSE_INI_GUIDE.md](../RESPONSE_INI_GUIDE.md)** - Response.ini file format guide
- **[Main README](../README.md)** - Complete repository documentation

## Need Help?

If you encounter issues:
1. Run with `-Verbose` flag for detailed output
2. Check error messages for specific problems
3. Verify your license file format matches the expected structure
4. Review the documentation links above
