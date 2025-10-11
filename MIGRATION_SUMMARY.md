# Migration Summary: pas_base and pas_orads

## Overview

Successfully migrated `pas_base` and `pas_orads` from standalone Dockerfiles to the standardized build system used by other components (compiler, db_adv, pas_dev).

## Changes Made

### New Directory Structure

Created two new component directories following the same pattern as `pas_dev`:

```
pas_base/
├── Dockerfile
├── response_ini_example.txt
├── start.sh
└── README.md

pas_orads/
├── Dockerfile
├── response_ini_example.txt
├── start.sh
└── README.md
```

### Dockerfile Updates

Both Dockerfiles now:
- Use Ubuntu 22.04 as base (consistent with other components)
- Follow multi-stage build pattern (install → instance)
- Use standardized build arguments: `CTYPE`, `OEVERSION`, `JDKVERSION`
- Use the centralized installer preparation system
- Use placeholder `JDKVERSION` that gets replaced at build time
- Include proper user/group setup
- Follow the same file structure as `pas_dev`

#### pas_base Features
- Production PASOE instance (`prodpas`)
- Health check enabled
- User: `openedge` (UID 1000)
- Ports: 8220 (HTTP), 8221 (HTTPS), 8899 (Health Check)

#### pas_orads Features
- All features of `pas_base`
- Oracle Instant Client 19.3 support
- Oracle DataServer components
- Additional Oracle users/groups (oracle, oinstall, dba, oper)
- User: `pscadmin` (UID 1000)
- Requires: `binaries/oracle/LINUX.X64_193000_client_home.zip`

### Build Script Updates

Updated all build scripts to support the new components:

#### PowerShell Scripts
- `tools/build-image.ps1`: Added `pas_base` and `pas_orads` to valid components
- `tools/build-all-images.ps1`: Added to build sequence

#### Bash Scripts
- `tools/build-image.sh`: Added `pas_base` and `pas_orads` to valid components
- `tools/build-all-images.sh`: Added to build sequence

### Build Order

The `build-all-images` scripts now build in this order:
1. compiler
2. devcontainer (if not skipped)
3. pas_dev
4. pas_base
5. pas_orads
6. db_adv
7. sports2020_db (if requested)

### Documentation Updates

#### Main README.md
- Added new "Available Image Types" section
- Added "PASOE Image Differences" subsection explaining the three PASOE variants
- Updated all component lists to include `pas_base` and `pas_orads`
- Updated build examples and commands
- Updated response.ini configuration sections

#### Component READMEs
- Created `pas_base/README.md` with build and usage instructions
- Created `pas_orads/README.md` with Oracle client setup instructions

## Usage Examples

### Building Individual Images

```powershell
# PowerShell
pwsh ./tools/build-image.ps1 -Component pas_base -Version 12.8.6 -Tag 12.8.6
pwsh ./tools/build-image.ps1 -Component pas_orads -Version 12.8.6 -Tag 12.8.6
```

```bash
# Bash
./tools/build-image.sh -c pas_base -v 12.8.6 -t 12.8.6
./tools/build-image.sh -c pas_orads -v 12.8.6 -t 12.8.6
```

### Building All Images

```powershell
# PowerShell - builds all components including pas_base and pas_orads
pwsh ./tools/build-all-images.ps1 -Version 12.8.6 -Tag 12.8.6
```

```bash
# Bash - builds all components including pas_base and pas_orads
./tools/build-all-images.sh -v 12.8.6 -t 12.8.6
```

## Prerequisites

### For pas_base
- OpenEdge installer binaries in `binaries/oe/<version>/`
- Configured `pas_base/response.ini` with valid control codes

### For pas_orads
- OpenEdge installer binaries in `binaries/oe/<version>/`
- Configured `pas_orads/response.ini` with valid control codes (with DataServer enabled)
- Oracle Instant Client: `binaries/oracle/LINUX.X64_193000_client_home.zip`

## Migration Benefits

1. **Consistency**: All components now use the same build system and patterns
2. **Maintainability**: Centralized installer management and version handling
3. **Flexibility**: Easy to build any combination of components
4. **Documentation**: Clear separation of concerns with component-specific READMEs
5. **Automation**: Can build all images with a single command
6. **Version Control**: Proper response.ini examples with .gitignore protection

## Old Files

The following old files can be removed after verification:
- `Dockerfile_pas_base_128`
- `Dockerfile_pas_orads_128`
- `start.sh` (root level - if only used by old pas dockerfiles)
- `response128_pas_prod.ini` (if it exists - now replaced by pas_base/response.ini)

## Testing Checklist

- [ ] Verify `pas_base/response.ini` is created from example
- [ ] Verify `pas_orads/response.ini` is created from example
- [ ] For pas_orads: Download and place Oracle client in `binaries/oracle/`
- [ ] Test building pas_base individually
- [ ] Test building pas_orads individually
- [ ] Test building all images together
- [ ] Verify pas_base container starts and PASOE is accessible
- [ ] Verify pas_orads container starts with Oracle client available
- [ ] Test health check endpoints on both images
