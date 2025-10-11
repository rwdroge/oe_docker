# OpenEdge Version Installation Matrix

## Quick Reference Guide

This guide shows the installation requirements for different OpenEdge versions when building Docker images.

## Installation Patterns by Version

### Pattern 1: Single Installer (Simple)
**Versions**: 12.2.0-12.2.16, 12.2.20+, 12.8.0-12.8.3, 12.8.9+

```
Single installer contains complete version
├── PROGRESS_OE_12.8.9_LNX_64.tar.gz (complete 12.8.9)
└── response.ini (one file)
```

**Requirements**:
- ✅ One installer file
- ✅ One `response.ini` file
- ❌ No `response_update.ini` needed

---

### Pattern 2: Base + Patch (Dual Response) ⚠️
**Versions**: 12.2.17, 12.2.18, 12.8.4, 12.8.5, 12.8.6, 12.8.7, 12.8.8

```
Two installers + two response files
├── PROGRESS_OE_12.8_LNX_64.tar.gz (base 12.8.0)
├── PROGRESS_OE_12.8.7_LNX_64.tar.gz (patch to 12.8.7)
├── response.ini (for base installation)
└── response_update.ini (for patch installation)
```

**Requirements**:
- ✅ Two installer files (base + patch)
- ✅ Two response files: `response.ini` AND `response_update.ini`
- 🔧 Build system uses correct file for each phase

---

## Version Timeline

```
12.2.0-12.2.16 ───────────────────────────────────────────────────────
               Pattern 1: Single installer

 
12.2.17 ──┐   
12.2.18 ──┘─ Pattern 2: Base + Patch (dual response) ⚠️
 

12.2.19+ ─────────────────────────────────────────────────────────────
         Pattern 1: Single installer (simplified)
         
12.8.0-12.8.3 ────────────────────────────────────────────────────────
              Pattern 1: Single installer

12.8.4 ──┐
12.8.5   │
12.8.6   ├─ Pattern 2: Base + Patch (dual response) ⚠️
12.8.7   │
12.8.8 ──┘

12.8.9+ ──────────────────────────────────────────────────────────────
        Pattern 1: Single installer (simplified)
```

## Detailed Comparison Table

| Version | Installer Count | response.ini | response_update.ini | Pattern | Notes |
|---------|----------------|--------------|---------------------|---------|-------|
| 12.2.0-12.2.16 | 1 | ✅ | ❌ | Single | Full version in one file |
| **12.2.17** | **2** | **✅** | **✅** | **Base+Patch** | **Dual response required** |
| **12.2.18** | **2** | **✅** | **✅** | **Base+Patch** | **Dual response required** |
| 12.2.19+ | 1 | ✅ | ❌ | Single | Back to single installer |
| 12.8.0-12.8.3 | 1 | ✅ | ❌ | Single | Full version in one file |
| **12.8.4** | **2** | **✅** | **✅** | **Base+Patch** | **Dual response required** |
| **12.8.5** | **2** | **✅** | **✅** | **Base+Patch** | **Dual response required** |
| **12.8.6** | **2** | **✅** | **✅** | **Base+Patch** | **Dual response required** |
| **12.8.7** | **2** | **✅** | **✅** | **Base+Patch** | **Dual response required** |
| **12.8.8** | **2** | **✅** | **✅** | **Base+Patch** | **Dual response required** |
| 12.8.9+ | 1 | ✅ | ❌ | Single | Back to single installer |

## Setup Instructions by Pattern

### For Pattern 1 (12.2.0-12.2.15, 12.2.20+, 12.8.0-12.8.3, 12.8.9+)

```powershell
# 1. Place installer
binaries/oe/12.8/PROGRESS_OE_12.8.9_LNX_64.tar.gz

# 2. Create response.ini
cp compiler/response_ini_example.txt compiler/response.ini
# Edit with your license info

# 3. Build
./tools/build-image.ps1 -Component compiler -Version 12.8.9 -Tag 12.8.9
```

### For Pattern 2 (12.2.16-12.2.19, 12.8.4-12.8.8) ⚠️

```powershell
# 1. Place installers
binaries/oe/12.8/PROGRESS_OE_12.8_LNX_64.tar.gz
binaries/oe/12.8/PROGRESS_OE_12.8.7_LNX_64.tar.gz

# 2. Create BOTH response files
cp compiler/response_ini_example.txt compiler/response.ini
cp compiler/response_update_ini_example.txt compiler/response_update.ini
# Edit BOTH files with your license info

# 3. Build
./tools/build-image.ps1 -Component compiler -Version 12.8.7 -Tag 12.8.7
```

## Why the Change?

### Pattern Evolution

Progress has changed the installation approach multiple times:

**12.2.0-12.2.15 → 12.2.16-12.2.19 (Dual Response)**
- Introduced base + patch with separate response files
- More complex update scenarios
- Better separation of base vs. update configuration

**12.2.19 → 12.2.20+ (Back to Single)**
- Simplified back to single installer
- Easier to manage and distribute

**12.8.0-12.8.3 (Single) → 12.8.4-12.8.8 (Dual Response)**
- Same pattern as 12.2.16-12.2.19
- Separate response files for base and patch

**12.8.8 → 12.8.9+ (Back to Single)**
- Returned to single installer
- Simpler installation process
- Fewer files to manage
- Reduced chance of version mismatch

## Troubleshooting

### "response.ini not found"
- Check you've created the file in the correct component directory
- Verify filename is exactly `response.ini` (case-sensitive)

### "Patch installation failed" (12.2.16-12.2.19, 12.8.4-12.8.8)
- Ensure `response_update.ini` exists
- Verify it contains the `[Update]` section
- Check license information is correct

### "Wrong installer for version"
- **12.2.16-12.2.19**: Need base (12.2) + patch (12.2.x)
- **12.2.20+**: Need only single installer (12.2.20)
- **12.8.4-12.8.8**: Need base (12.8) + patch (12.8.x)
- **12.8.9+**: Need only single installer (12.8.9)
- Check installer filenames match expected pattern

## Build System Compatibility

The build system automatically handles all three patterns:

```bash
# install-oe.sh logic
if [ -f /install/patch/proinst ]; then
  if [ -f /install/openedge/response_update.ini ]; then
    # Pattern 3: Use separate update file (12.8.4-12.8.8)
    /install/patch/proinst -b /install/openedge/response_update.ini ...
  else
    # Pattern 2: Auto-append Update section (12.8.0-12.8.3)
    echo -e "\n[Update]\nProgressInstallDir=/usr/dlc\n" >> response.ini
    /install/patch/proinst -b /install/openedge/response.ini ...
  fi
else
  # Pattern 1: Single installer (12.2.x, 12.8.9+)
  # No patch to install
fi
```

## References

- [RESPONSE_INI_GUIDE.md](RESPONSE_INI_GUIDE.md) - Detailed response.ini configuration
- [README.md](README.md) - Main documentation
- [OpenEdge Installation Guide](https://docs.progress.com/bundle/openedge-install-guide)
