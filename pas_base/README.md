# PASOE Production Base (pas_base)

This image builds a production PASOE instance with a basic configuration suitable for production deployment.

## Prerequisites

### OpenEdge Control Codes

Configure your OpenEdge control codes in `pas_base/response.ini`:

1. Copy the example file:
   ```bash
   cp pas_base/response_ini_example.txt pas_base/response.ini
   ```

2. Edit `pas_base/response.ini` and add your:
   - Company name
   - Serial number
   - Control code

## Building

### Using build script (recommended)

```bash
# PowerShell
pwsh ./tools/build-image.ps1 -Component pas_base -Version 12.8.6 -Tag 12.8.6

# Bash
./tools/build-image.sh -c pas_base -v 12.8.6 -t 12.8.6
```

### Manual build

```bash
docker build -f pas_base/Dockerfile \
  --build-arg CTYPE=pas \
  --build-arg OEVERSION=128 \
  --build-arg JDKVERSION=21 \
  -t rdroge/oe_pas_base:12.8.6 .
```

## Running

```bash
docker run -d \
  -p 8220:8220 \
  -p 8221:8221 \
  -v /path/to/progress.cfg:/usr/dlc/progress.cfg \
  rdroge/oe_pas_base:12.8.6
```

## Image Details

- **Base OS**: Ubuntu 22.04
- **User**: openedge (UID 1000)
- **PASOE Instance**: prodpas (production profile)
- **Exposed Ports**: 8220 (HTTP), 8221 (HTTPS), 8899 (Health Check)

## Features

- Pre-created production PASOE instance
- Health check enabled via `tcman.sh feature HealthCheck=on`
- Minimal configuration for production use
- Multi-stage build for smaller image size

## Environment Variables

- `DLC=/usr/dlc`
- `WRKDIR=/usr/wrk`
- `JAVA_HOME=/opt/java/openjdk`
- `PATH` includes DLC and Java binaries

## Differences from pas_dev

Unlike `pas_dev`, this image:
- Uses production profile (`-Z prod`) instead of development
- Does not include volumes for source code mounting
- Is optimized for production deployment
- Has a simpler, more locked-down configuration
