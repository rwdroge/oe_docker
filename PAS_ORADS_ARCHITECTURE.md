# pas_orads Architecture Change

## Overview

The `pas_orads` image has been restructured to follow a **layered architecture** pattern, building on top of `pas_base` instead of being a standalone image. This aligns with the existing patterns used by `devcontainer` (extends `compiler`) and `sports2020-db` (extends `db_adv`).

## Architecture Comparison

### Before (Standalone)
```
pas_orads:
  ├── Ubuntu 22.04 base
  ├── OpenEdge installation (from scratch)
  ├── PASOE instance creation
  └── Oracle client installation
  
Size: ~10.5GB (with duplication issues)
```

### After (Layered)
```
pas_base:
  ├── Ubuntu 22.04 base
  ├── OpenEdge installation
  └── PASOE production instance

pas_orads (extends pas_base):
  ├── pas_base (all features inherited)
  ├── Oracle dependencies (libaio)
  ├── Oracle users/groups
  └── Oracle Instant Client 19.3

Size: pas_base (~2.7GB) + pas_orads layer (~2.3GB) = ~5GB total
```

## Benefits

### 1. **Consistency**
- Follows the same pattern as other layered images in the repository
- Makes the architecture more predictable and maintainable

### 2. **Reduced Duplication**
- No need to duplicate OpenEdge installation and PASOE setup
- Oracle client is the only difference from pas_base

### 3. **Smaller Total Size**
- **Before**: 10.5GB (standalone with duplication issues)
- **After**: ~5GB (layered, properly optimized)
- **Savings**: ~5.5GB

### 4. **Easier Maintenance**
- Changes to base PASOE configuration only need to be made in `pas_base`
- `pas_orads` only contains Oracle-specific additions
- Simpler Dockerfile (60 lines vs 135 lines)

### 5. **Faster Builds**
- If `pas_base` is already built, `pas_orads` only needs to add Oracle layer
- Can leverage Docker layer caching more effectively

## Dockerfile Changes

### Key Differences

**Old Dockerfile** (standalone):
- Full OpenEdge installation from scratch
- PASOE instance creation
- Oracle client installation
- 135 lines

**New Dockerfile** (layered):
- Starts from `rdroge/oe_pas_base:latest`
- Only adds Oracle dependencies and client
- 60 lines

### New Structure

```dockerfile
# Stage 1: Prepare Oracle client
FROM ubuntu:22.04 AS oracle
# ... unzip and prepare Oracle client ...

# Stage 2: Extend pas_base
FROM rdroge/oe_pas_base:latest
# Install Oracle dependencies
# Copy Oracle client from stage 1
# Set up Oracle users/groups
# Inherit everything else from pas_base
```

## Build Process Changes

### Build Script Updates

Both `build-image.ps1` and `build-image.sh` now:

1. **Skip installer preparation** for `pas_orads` (uses base image)
2. **Replace base image tag** dynamically:
   - `FROM rdroge/oe_pas_base:latest` → `FROM rdroge/oe_pas_base:12.8.7`
   - Ensures version consistency

### Build Order

**Important**: `pas_base` must be built before `pas_orads`

```powershell
# 1. Build pas_base first
pwsh ./tools/build-image.ps1 -Component pas_base -Version 12.8.7 -Tag 12.8.7

# 2. Then build pas_orads (will use the pas_base:12.8.7 image)
pwsh ./tools/build-image.ps1 -Component pas_orads -Version 12.8.7 -Tag 12.8.7
```

### Build-All Script

The `build-all-images` scripts build in this order:
1. compiler
2. devcontainer (extends compiler)
3. pas_dev
4. **pas_base**
5. **pas_orads** (extends pas_base)
6. db_adv
7. sports2020_db (extends db_adv, if requested)

## Prerequisites

### For pas_orads

1. **Base image**: `rdroge/oe_pas_base` must be built first
2. **Oracle client**: `binaries/oracle/LINUX.X64_193000_client_home.zip`
3. **No OpenEdge installers needed** (inherited from base image)
4. **No response.ini needed** (inherited from base image)

## Image Hierarchy

```
ubuntu:22.04
    │
    ├── compiler ──────────> devcontainer
    │
    ├── db_adv ────────────> sports2020-db
    │
    ├── pas_dev
    │
    └── pas_base ──────────> pas_orads
```

## Migration Notes

### What Was Removed from pas_orads

- OpenEdge installer preparation
- OpenEdge installation steps
- PASOE instance creation
- response.ini requirement
- Most user/group setup (except Oracle-specific)
- start.sh (inherited from pas_base)

### What Was Added to pas_orads

- Dependency on `pas_base` image
- Oracle-specific users/groups only
- Simplified Oracle client installation

### Breaking Changes

**None** - The final image has the same functionality and behavior as before, just built differently.

## Testing

### Verify the Layered Structure

```powershell
# Check image history
docker history rdroge/oe_pas_orads:12.8.7

# Verify base image
docker inspect rdroge/oe_pas_orads:12.8.7 | Select-String "pas_base"

# Check size
docker images | Select-String "pas"
```

### Expected Results

- `pas_base`: ~2.7GB
- `pas_orads`: ~5GB total (includes pas_base layers)
- Oracle layer addition: ~2.3GB

## Future Considerations

### Potential Enhancements

1. **Multi-stage Oracle build** could be further optimized
2. **Oracle client version** could be parameterized
3. **Additional DataServer types** (MS SQL, etc.) could follow the same pattern
4. **Version pinning** for base images in production

### Similar Patterns

This architecture could be applied to:
- `pas_mssql` - PASOE with MS SQL DataServer
- `pas_db2` - PASOE with DB2 DataServer
- `pas_custom` - PASOE with custom extensions

## References

- [Docker Multi-stage Builds](https://docs.docker.com/build/building/multi-stage/)
- [Docker Image Layering](https://docs.docker.com/storage/storagedriver/)
- [Best Practices for Writing Dockerfiles](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
