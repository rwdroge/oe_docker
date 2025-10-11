# PASOE with Oracle DataServer (pas_orads)

This image extends `pas_base` by adding Oracle DataServer support and the Oracle Instant Client. It follows a layered architecture similar to `devcontainer` (which extends `compiler`) and `sports2020-db` (which extends `db_adv`).

## Prerequisites

### Oracle Instant Client

You need to download the Oracle Instant Client and place it in the `binaries/oracle/` directory:

1. Download **Oracle Instant Client 19.3 for Linux x86-64** from Oracle's website
   - File: `LINUX.X64_193000_client_home.zip`
   - URL: https://www.oracle.com/database/technologies/instant-client/downloads.html

2. Place the file in the repository:
   ```
   binaries/oracle/LINUX.X64_193000_client_home.zip
   ```

### Base Image

This image requires `pas_base` to be built first:

```powershell
# Build pas_base first
pwsh ./tools/build-image.ps1 -Component pas_base -Version 12.8.7 -Tag 12.8.7
```

## Building

### Using build script (recommended)

```bash
# PowerShell
pwsh ./tools/build-image.ps1 -Component pas_orads -Version 12.8.6 -Tag 12.8.6

# Bash
./tools/build-image.sh -c pas_orads -v 12.8.6 -t 12.8.6
```

### Manual build

```bash
docker build -f pas_orads/Dockerfile \
  --build-arg CTYPE=pas \
  --build-arg OEVERSION=128 \
  --build-arg JDKVERSION=21 \
  -t rdroge/oe_pas_orads:12.8.6 .
```

## Configuration

### TNS Names (Optional)

If you need to configure Oracle TNS names, uncomment the line in the Dockerfile and create a `tnsnames.ora` file:

```dockerfile
# Uncomment this line in pas_orads/Dockerfile:
COPY pas_orads/tnsnames.ora /opt/oracle/client/network/admin/tnsnames.ora
```

Then create `pas_orads/tnsnames.ora` with your Oracle connection details.

## Running

```bash
docker run -d \
  -p 8220:8220 \
  -p 8221:8221 \
  -v /path/to/progress.cfg:/usr/dlc/progress.cfg \
  rdroge/oe_pas_orads:12.8.6
```

## Image Details

- **Base Image**: `rdroge/oe_pas_base` (inherits all pas_base features)
- **Additional User**: oracle (for Oracle client files)
- **Additional Groups**: oinstall, dba, oper
- **Oracle Client**: 19.3 installed in `/opt/oracle/client`
- **Inherited from pas_base**:
  - User: openedge (UID 1000)
  - PASOE Instance: prodpas (production profile)
  - Exposed Ports: 8220 (HTTP), 8221 (HTTPS), 8899 (Health Check)
  - Environment variables (DLC, WRKDIR, JAVA_HOME, PATH)

## Notes

- The Oracle client libraries are installed in `/opt/oracle/client`
- Oracle-related users and groups (oracle, oinstall, dba, oper) are created
- The `libaio` libraries required by Oracle client are installed
- Health check is enabled on the PASOE instance
