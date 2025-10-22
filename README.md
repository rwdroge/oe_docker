# oe_docker

This repository contains Dockerfiles and tooling to build local OpenEdge Docker container images using locally provided installers. **Focused on DevContainer workflows** for modern OpenEdge development.

## Prerequisites

Before running the quickstart script, ensure you have the following:

### 1. **Docker Installed**
- **Windows:** [Docker Desktop for Windows](https://docs.docker.com/desktop/install/windows-install/)
- **Linux:** [Docker Engine](https://docs.docker.com/engine/install/) or [Docker Desktop for Linux](https://docs.docker.com/desktop/install/linux-install/)
- **macOS:** [Docker Desktop for Mac](https://docs.docker.com/desktop/install/mac-install/)

Verify Docker is running:
```bash
docker --version
docker ps
```

### 2. **Valid License Addendum File**
Download your OpenEdge license addendum file from **[Progress ESD](https://downloads.progress.com)** and place it in the `addendum/` folder:

**For OpenEdge 12.8.x:**
```
addendum/
├── US263472 License Addendum.txt  ← Your license file here
└── license_addendum_placeholder.txt
```

**For OpenEdge 12.2.x:**
```
addendum/
├── your_12.2_license_addendum.txt  ← Your license file here
└── license_addendum_placeholder.txt
```

> 📝 **Note:** The quickstart script will help you generate `response.ini` files from your license addendum.

### 3. **OpenEdge Installer Binaries**
Download your OpenEdge installer files from **[Progress ESD](https://downloads.progress.com)** and place them in the `binaries/oe/<version>/` folder:

**Single installer example (12.8.9):**
```
binaries/oe/12.8/
└── PROGRESS_OE_12.8.9_LNX_64.tar.gz
```

**Base + incremental installer example (12.8.6):**
```
binaries/oe/12.8/
├── PROGRESS_OE_12.8_LNX_64.tar.gz     ← Base installer (12.8.0)
└── PROGRESS_OE_12.8.6_LNX_64.tar.gz   ← Update installer (12.8.6)
```

> ⚠️ **Important for 12.8.4 - 12.8.8:** You must place both the base installer (12.8.0) and the update installer in the same directory for incremental installations.

## 🚀 Quick Start

Once you have the prerequisites ready, simply run the quickstart script:

**Windows:**
```powershell
.\oe_container_build_quickstart.ps1
```

**Linux/macOS:**
```bash
./oe_container_build_quickstart.sh
```

The script will:
1. Ask for your Docker Hub username
2. Present an interactive menu with build options
3. Validate all prerequisites before starting
4. Generate response.ini files from your license (if needed)
5. Build the requested Docker images

> ✅ **Validation:** The quickstart script automatically validates that all required files exist before starting any build process.

## Available Images

This repository builds the following OpenEdge container images:

### Base Images (can be built independently)
- **`compiler`** - OpenEdge compiler and development tools
- **`pas_dev`** - PASOE development instance with volumes for source code and libraries
- **`db_adv`** - OpenEdge database server (Advanced Enterprise Edition)

### Dependent Images (require parent images)
- **`devcontainer`** - Development container (requires: compiler)
- **`sports2020_db`** - Sports2020 demo database (requires: db_adv)

## Using with Dev Containers

The images built from this repository can be used with the OpenEdge development container setups available at:

**[https://github.com/rwdroge/oedevcontainer](https://github.com/rwdroge/oedevcontainer)**

This provides a complete containerized OpenEdge development environment with VS Code integration.

## Advanced Usage

For advanced users who prefer command-line tools over the interactive quickstart script:

### Generate response.ini files only
```powershell
# Windows
.\tools\Generate-ResponseIni.ps1 -Version 12.8.9

# Linux/macOS  
./tools/generate-response-ini.sh
```

### Build specific images
```powershell
# Windows - Single component
.\tools\build-image.ps1 -Component compiler -Version 12.8.9

# Linux/macOS - Single component
./tools/build-image.sh -c compiler -v 12.8.9
```

### Build all images
```powershell
# Windows - All images
.\tools\build-all-images.ps1 -Version 12.8.9

# Linux/macOS - All images  
./tools/build-all-images.sh -v 12.8.9
```

> 📖 **For detailed documentation:** See [tools/README_Generate-ResponseIni.md](tools/README_Generate-ResponseIni.md)

## Credits

This project was inspired by the OpenEdge and Docker work of [Bronco Oostermeijer](https://github.com/bfv). Many thanks for the pioneering efforts in containerizing OpenEdge!
