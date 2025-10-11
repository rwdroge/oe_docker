# Response.ini Configuration Guide

## Overview

OpenEdge Docker builds require `response.ini` files containing license information for unattended installations.

**Most versions** use a single `response.ini` file. However, **versions 12.2.17-12.2.18 and 12.8.4-12.8.8** require two separate files:

1. **`response.ini`** - Base version installation
2. **`response_update.ini`** - Patch/update installation

The build system automatically detects which files are needed based on the version.

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

**Required for:** `compiler`, `db_adv`, `pas_dev`, `pas_base`  
**Not required for:** `devcontainer`, `pas_orads`, `sports2020-db` (extend base images)

### Steps

1. **Copy example file(s)** for each component:
   ```bash
   # All versions
   cp compiler/response_ini_example.txt compiler/response.ini
   
   # Only for 12.2.17-12.2.18 and 12.8.4-12.8.8
   cp compiler/response_update_ini_example.txt compiler/response_update.ini
   ```

2. **Edit the file(s)** and add your license information:
   - Company name
   - Serial number  
   - Control code
   - Component-specific settings

3. **Repeat** for `db_adv`, `pas_dev`, and `pas_base`

## Version Requirements

| Version | response.ini | response_update.ini | Installer Type |
|---------|--------------|---------------------|----------------|
| 12.2.0-12.2.16 | ✅ Required | ❌ Not needed | Single |
| **12.2.17-12.2.18** | **✅ Required** | **✅ Required** | **Base + Patch** |
| 12.2.19+ | ✅ Required | ❌ Not needed | Single |
| 12.8.0-12.8.3 | ✅ Required | ❌ Not needed | Single |
| **12.8.4-12.8.8** | **✅ Required** | **✅ Required** | **Base + Patch** |
| 12.8.9+ | ✅ Required | ❌ Not needed | Single |

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
- For 12.2.17-12.2.18 or 12.8.4-12.8.8, ensure `response_update.ini` exists
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
