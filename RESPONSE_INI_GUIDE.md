# Response.ini Configuration Guide

## Overview

OpenEdge Docker builds require `response.ini` files containing license information for unattended installations. For certain OpenEdge versions, you need **two separate response.ini files**:

1. **`response.ini`** - For base version installation (e.g., OE 12.2, 12.8)
2. **`response_update.ini`** - For patch/update installation (e.g., 12.2.17, 12.8.7)

**Versions requiring dual response files:**
- **12.2.17, 12.2.18**
- **12.8.4, 12.8.5, 12.8.6, 12.8.7, 12.8.8**

## Why Two Files?

For specific OpenEdge versions, Progress changed the installation process to use base + patch with separate response files:

**12.2 Series:**
- **12.2.17-12.2.18**: Base (12.2) + patch requires separate response files
- **12.2.19+**: Back to single installer

**12.8 Series:**
- **12.8.4-12.8.8**: Base (12.8) + patch requires separate response files  
- **12.8.9+**: Back to single installer

The build system automatically detects and uses the correct file during installation.

## File Structure

### response.ini (Base Installation)

```ini
[General]
CompanyName=Your Company Name
SerialNumber=YOUR-SERIAL-NUMBER
ControlCode=YOUR-CONTROL-CODE

[Install]
# Component-specific settings
# See response_ini_example.txt in each component directory
```

### response_update.ini (Patch Installation)

```ini
[Update]
ProgressInstallDir=/usr/dlc

[General]
CompanyName=Your Company Name
SerialNumber=YOUR-SERIAL-NUMBER
ControlCode=YOUR-CONTROL-CODE
```

**Key difference**: The `[Update]` section tells the installer to update an existing installation.

## Setup Instructions

### For Each Component (compiler, db_adv, pas_dev, pas_base)

1. **Create base response.ini**:
   ```bash
   cp <component>/response_ini_example.txt <component>/response.ini
   ```

2. **Edit response.ini** and add your license information:
   - Company name
   - Serial number
   - Control code
   - Component-specific settings

3. **Create update response.ini** (for 12.8.4+):
   ```bash
   cp <component>/response_update_ini_example.txt <component>/response_update.ini
   ```

4. **Edit response_update.ini** and add your license information:
   - Company name
   - Serial number
   - Control code
   - Keep the `[Update]` section

### Example for compiler

```powershell
# PowerShell
Copy-Item compiler/response_ini_example.txt compiler/response.ini
Copy-Item compiler/response_update_ini_example.txt compiler/response_update.ini

# Edit both files with your license information
notepad compiler/response.ini
notepad compiler/response_update.ini
```

## Version-Specific Behavior

### OpenEdge 12.2.0 - 12.2.15
- ✅ Only requires `response.ini`
- ❌ No `response_update.ini` needed
- Single installer for the full version

### OpenEdge 12.2.16 - 12.2.19 ⚠️
- ✅ Requires both `response.ini` and `response_update.ini`
- Base + patch installers with separate response files
- Build system automatically uses correct file for each installation phase

### OpenEdge 12.2.20+
- ✅ Only requires `response.ini`
- ❌ No `response_update.ini` needed
- **Single installer** for the full version (simplified)

### OpenEdge 12.8.0 - 12.8.3
- ✅ Only requires `response.ini`
- ❌ No `response_update.ini` needed
- Single installer for the full version

### OpenEdge 12.8.4 - 12.8.8 ⚠️
- ✅ Requires both `response.ini` and `response_update.ini`
- Base + patch installers with separate response files
- Build system automatically uses correct file for each installation phase

### OpenEdge 12.8.9+
- ✅ Only requires `response.ini`
- ❌ No `response_update.ini` needed
- **Single installer** for the full version (simplified)
- Example: `PROGRESS_OE_12.8.9_LNX_64.tar.gz` contains the complete 12.8.9 installation

## How It Works

### Build Process

1. **Dockerfile** copies all response*.ini files:
   ```dockerfile
   COPY compiler/response*.ini /install/openedge/
   ```

2. **install-oe.sh** detects and uses the correct file:
   ```bash
   # Base installation
   /install/openedge/proinst -b /install/openedge/response.ini ...
   
   # Patch installation
   if [ -f /install/openedge/response_update.ini ]; then
     # Use separate update file (12.8.4+)
     /install/patch/proinst -b /install/openedge/response_update.ini ...
   else
     # Use response.ini with Update section (12.8.0-12.8.3)
     echo -e "\n[Update]\nProgressInstallDir=/usr/dlc\n" >> /install/openedge/response.ini
     /install/patch/proinst -b /install/openedge/response.ini ...
   fi
   ```

### Backward Compatibility

The system is backward compatible:
- If `response_update.ini` doesn't exist, it falls back to the old method
- Older versions (12.2.x, 12.8.0-12.8.3) work without changes
- New versions (12.8.4+) benefit from separate update file

## Component-Specific Notes

### compiler
- Requires: `response.ini` (and `response_update.ini` for 12.8.4+)
- Includes: Development tools, compiler, debugger

### db_adv
- Requires: `response.ini` (and `response_update.ini` for 12.8.4+)
- Includes: Database server components

### pas_dev
- Requires: `response.ini` (and `response_update.ini` for 12.8.4+)
- Includes: PASOE development instance

### pas_base
- Requires: `response.ini` (and `response_update.ini` for 12.8.4+)
- Includes: PASOE production instance

### pas_orads
- **Does NOT require response.ini files**
- Extends `pas_base` image (inherits OpenEdge installation)
- Only requires Oracle client installer

## Security Best Practices

1. **Never commit response.ini files** to version control
   - They contain sensitive license information
   - Already in `.gitignore`

2. **Keep example files generic**
   - Use placeholders like `<your company name>`
   - Commit only `response_ini_example.txt` and `response_update_ini_example.txt`

3. **Use environment-specific files**
   - Different licenses for dev/test/prod
   - Store securely (e.g., GitHub Secrets, Azure Key Vault)

## Troubleshooting

### "response.ini not found" error
- Ensure you've created `response.ini` from the example file
- Check the file is in the correct component directory
- Verify filename is exactly `response.ini` (case-sensitive on Linux)

### Patch installation fails
- For 12.8.4+, ensure `response_update.ini` exists
- Verify `[Update]` section is present in `response_update.ini`
- Check license information is correct in both files

### Build fails with "Invalid license"
- Verify serial number and control code are correct
- Ensure no extra spaces or line breaks in license fields
- Check that the license is valid for the OpenEdge version being installed

## GitHub Actions Integration

The GitHub Actions workflow uses secrets for response.ini files:
- `RESPONSE_INI_<VERSION>_<COMPONENT>` - Base installation
- Secrets are injected at build time
- Same two-file logic applies in CI/CD

## References

- [OpenEdge Installation Guide](https://docs.progress.com/bundle/openedge-install-guide)
- [Response File Format](https://docs.progress.com/bundle/openedge-install-guide/page/Response-file-format.html)
- [Unattended Installation](https://docs.progress.com/bundle/openedge-install-guide/page/Unattended-installation.html)

## Quick Reference

| Version | response.ini | response_update.ini | Installer Type | Notes |
|---------|--------------|---------------------|----------------|-------|
| 12.2.0-12.2.16 | ✅ Required | ❌ Not needed | Single | Full version installer |
| **12.2.17-12.2.18** | **✅ Required** | **✅ Required** | **Base + Patch** | **Separate response files** |
| 12.2.19+ | ✅ Required | ❌ Not needed | Single | Full version installer (simplified) |
| 12.8.0-12.8.3 | ✅ Required | ❌ Not needed | Single | Full version installer |
| **12.8.4-12.8.8** | **✅ Required** | **✅ Required** | **Base + Patch** | **Separate response files** |
| 12.8.9+ | ✅ Required | ❌ Not needed | Single | Full version installer (simplified) |
