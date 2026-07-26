# PASOE with Oracle DataServer (pas_orads)

This image provides a complete OpenEdge PASOE installation with Oracle DataServer support and Oracle Instant Client. It uses a multi-stage build approach similar to `pas_base` for optimal image size, installing OpenEdge from scratch rather than extending an existing image.

## Prerequisites

### 1. OpenEdge License Configuration

Generate `response.ini` files with your OpenEdge control codes:

```bash
# Using the quickstart script (recommended)
./oe_container_build_quickstart.ps1  # Windows
./oe_container_build_quickstart.sh   # Linux/macOS

# Or directly
./tools/Generate-ResponseIni.ps1 -Version 12.8.9  # Windows
./tools/generate-response-ini.sh -v 12.8.9        # Linux/macOS
```

This will create `pas_orads/response.ini` (and `response_update.ini` if needed).

### 2. Oracle Instant Client

Download the Oracle Instant Client and place it in the `binaries/oracle/` directory:

1. Download **Oracle Instant Client 19.3 for Linux x86-64** from Oracle's website
   - File: `LINUX.X64_193000_client_home.zip`
   - URL: https://www.oracle.com/database/technologies/instant-client/downloads.html

2. Place the file in the repository:
   ```
   binaries/oracle/LINUX.X64_193000_client_home.zip
   ```

### 3. OpenEdge Installer Files

Place OpenEdge installer files in `binaries/oe/<version>/`:
- `PROGRESS_OE_<version>_LNX_64.tar.gz`
- `PROGRESS_OE_<version>_LNX_64_PATCH.tar.gz` (if applicable)

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

### Build Architecture
- **Multi-stage build** with 3 stages for optimal size:
  1. **Install stage**: OpenEdge installation and cleanup
  2. **Oracle stage**: Oracle Instant Client extraction
  3. **Runtime stage**: Minimal final image with only runtime dependencies

### Users and Groups
- **openedge** (UID 1000, GID 1000): Primary user for OpenEdge processes
- **oracle** (oinstall group): For Oracle client files
- **Additional groups**: oinstall (54321), dba (54322), oper (54323)

### Installed Components
- **OpenEdge PASOE**: Full installation in `/usr/dlc`
- **Oracle Client**: 19.3 in `/opt/oracle/client`
- **Java**: Eclipse Temurin JDK (version based on OpenEdge version)
- **Runtime libraries**: net-tools, netbase, libaio1, libaio-dev

### Environment Variables
- `DLC=/usr/dlc`
- `WRKDIR=/usr/wrk`
- `JAVA_HOME=/opt/java/openjdk`
- `ORACLE_HOME=/opt/oracle/client`
- `LD_LIBRARY_PATH=/opt/oracle/client/lib`
- `PATH` includes DLC, Java, and Oracle paths

### Key Differences from pas_base
- **No PASOE instance created**: Unlike `pas_base`, this image does not create a PASOE instance during build. The Pro2 installer or your application should create the instance as needed.
- **Oracle DataServer support**: Includes Oracle client libraries and configuration
- **Optimized for size**: Multi-stage build removes installation artifacts

## Size Optimization

This image uses several techniques to minimize size:
- Multi-stage build discards installation files
- `clean-oe-files.sh` removes unnecessary OpenEdge components
- Only runtime dependencies in final image
- No intermediate build tools or installers in final layer
