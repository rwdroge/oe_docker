# pas_orads Optimization Changes

## Overview

The `pas_orads` image has been restructured to use a multi-stage build approach similar to `pas_base`, resulting in significant size reduction while maintaining full functionality.

## Previous Architecture

**Before**: `pas_orads` extended the pre-built `pas_base` image and added Oracle client support on top.

```dockerfile
FROM progressofficial/oe_pas_base:12.8.11
# Add Oracle client
# Inherit PASOE instance from pas_base
```

**Issues**:
- Carried all layers from `pas_base` including its PASOE instance
- No opportunity to optimize or remove unnecessary files
- Larger image size due to layered approach

## New Architecture

**After**: `pas_orads` builds OpenEdge from scratch using a 3-stage multi-stage build.

```dockerfile
Stage 1: Install OpenEdge → clean up installation files
Stage 2: Extract Oracle client → remove installer
Stage 3: Copy only runtime files → minimal final image
```

**Benefits**:
- ✅ Significant size reduction (installation artifacts discarded)
- ✅ No unnecessary PASOE instance (Pro2 installer creates its own)
- ✅ Optimized layer structure
- ✅ Better control over what's included in final image

## Key Changes

### 1. Dockerfile Structure (`pas_orads/Dockerfile`)

**Multi-stage build with 3 stages**:

1. **Install stage**: 
   - Installs OpenEdge from installer files
   - Runs `clean-oe-files.sh` to remove unnecessary components
   - Discards all installation artifacts

2. **Oracle stage**:
   - Extracts Oracle Instant Client from ZIP
   - Configures Oracle libraries
   - Removes installer files

3. **Runtime stage**:
   - Fresh Ubuntu base
   - Copies only runtime files from previous stages
   - Installs minimal runtime dependencies
   - Sets up users, groups, and permissions
   - **Does NOT create a PASOE instance** (Pro2 handles this)

### 2. Build Script Updates

**Files modified**:
- `tools/build-image.sh`: Removed pas_orads exception from response.ini validation
- `tools/generate-response-ini.sh`: Added pas_orads support
- `tools/Generate-ResponseIni.ps1`: Added pas_orads support

**Reason**: pas_orads now installs OpenEdge from scratch, so it requires `response.ini` files like other components.

### 3. Pro2 Dockerfile Updates (`pas_orads/pro2/Dockerfile`)

**Changes**:
- Uses `ARG BASE_IMAGE` for flexible base image reference
- Removed redundant `apt-get install libaio1` (already in base)
- Removed redundant `ldconfig` (already configured in base)
- Cleaner structure with better comments
- Switches to `openedge` user at the end

### 4. Documentation Updates

**Updated `pas_orads/README.md`**:
- Added response.ini prerequisite
- Documented multi-stage build architecture
- Explained size optimization techniques
- Clarified that no PASOE instance is created (Pro2 handles it)
- Added detailed component and environment variable documentation

## Migration Guide

### For Existing Users

If you were building `pas_orads` before, you now need to:

1. **Generate response.ini files**:
   ```bash
   # Windows
   ./oe_container_build_quickstart.ps1
   
   # Linux/macOS
   ./oe_container_build_quickstart.sh
   ```

2. **Build as usual**:
   ```bash
   # The build process is the same
   ./tools/build-image.sh -c pas_orads -v 12.8.9 -u yourusername
   ```

### For Pro2 Builds

The Pro2 Dockerfile now uses a build argument for the base image. When building manually:

```bash
docker build -f pas_orads/pro2/Dockerfile \
  --build-arg BASE_IMAGE=yourusername/oe_pas_orads:12.8.9 \
  -t yourusername/oe_pas_pro2:12.8.9 .
```

## Size Comparison

Expected size reduction (approximate):

- **Before**: ~2.5-3 GB (includes pas_base layers + Oracle)
- **After**: ~1.8-2.2 GB (optimized multi-stage build)
- **Savings**: ~700-800 MB (25-30% reduction)

*Actual sizes depend on OpenEdge version and installed components*

## Compatibility

✅ **Fully compatible**: The optimized image maintains all functionality of the previous version.

- Oracle DataServer support: ✅ Unchanged
- Environment variables: ✅ All preserved
- Users and permissions: ✅ Same structure
- Pro2 installation: ✅ Works identically

## Technical Details

### Clean-up Operations

The build uses `clean-oe-files.sh` with `CTYPE=pas` to remove:
- Sports demo databases
- SQL tools (not needed for PASOE)
- Database server binaries
- OE Management components
- Gradle, templates, source files
- ODBC, Perl, help files
- Unused language files

### Runtime Dependencies

Minimal dependencies in final image:
- `net-tools`, `netbase`: Network utilities
- `libaio1`, `libaio-dev`: Oracle client requirements
- No build tools or compilers

### File Permissions

Properly configured for security:
- OpenEdge binaries: `_*` files owned by root with setuid
- PASOE directories: Owned by openedge:openedge
- Oracle files: Owned by oracle:oinstall
- Work directory: World-writable (777)

## Troubleshooting

### "response.ini not found" error

**Cause**: pas_orads now requires response.ini files.

**Solution**: Run the generate-response-ini script:
```bash
./tools/generate-response-ini.sh -v 12.8.9
```

### Pro2 build fails with "BASE_IMAGE not set"

**Cause**: The Pro2 Dockerfile now requires a BASE_IMAGE build argument.

**Solution**: Use the build scripts which handle this automatically, or provide the argument manually:
```bash
docker build --build-arg BASE_IMAGE=yourusername/oe_pas_orads:12.8.9 ...
```

## Future Enhancements

Potential further optimizations:
- [ ] Use distroless base for even smaller runtime image
- [ ] Implement BuildKit cache mounts for faster rebuilds
- [ ] Consider Alpine Linux base (if OpenEdge supports it)
- [ ] Add health check endpoint
- [ ] Multi-architecture builds (amd64/arm64)

## Questions?

See the main README.md or pas_orads/README.md for detailed build instructions.
