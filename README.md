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

### 2. **Clone This Repository**
Clone the OpenEdge Docker repository to your local machine:

```bash
git clone https://github.com/rwdroge/oe_docker.git
cd oe_docker
```

### 3. **Add Valid License Addendum File**
Download your OpenEdge license addendum file (Click on the OpenEdge version i.e. Progress OpenEdge 12.8.x, select the specific update i.e. Progress® OpenEdge® 12.8.9 (all platforms) and choose 'View License' and then 'Download' the Linux 64-bit only!) from **[Progress ESD](https://downloads.progress.com)** and place it in the `addendum/` folder:

**For OpenEdge 12.8.x:**
```
addendum/
├── your_12.8_license_addendum.txt  ← Your license file here
└── license_addendum_placeholder.txt
```

**For OpenEdge 12.2.x:**
```
addendum/
├── your_12.2_license_addendum.txt  ← Your license file here
└── license_addendum_placeholder.txt
```

> 📝 **Note:** The quickstart script will help you generate `response.ini` files from your license addendum.

### 4. **OpenEdge Installer Binaries**
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

> ⚠️ **Important for 12.2.17-12.2.18 and 12.8.4 - 12.8.8:** You must place both the base installer (12.2.0/12.8.0) and the update installer in the same directory for incremental installations.

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

For advanced users who prefer command-line automation over the interactive quickstart script:

### Quickstart Script - Batch Mode

**Generate response.ini files only:**
```powershell
# Windows
.\oe_container_build_quickstart.ps1 -Action generate -Version 12.8.9 -DockerUsername your-username -Batch

# Linux/macOS  
./oe_container_build_quickstart.sh -a generate -v 12.8.9 -u your-username -b
```

**Build specific components:**
```powershell
# Windows - Single component
.\oe_container_build_quickstart.ps1 -Action build -Version 12.8.9 -DockerUsername your-username -Component compiler -Batch

# Windows - Multiple components
.\oe_container_build_quickstart.ps1 -Action build -Version 12.8.9 -DockerUsername your-username -Component "compiler,pas_dev" -Batch

# Linux/macOS - Single component
./oe_container_build_quickstart.sh -a build -v 12.8.9 -u your-username -c compiler -b

# Linux/macOS - Multiple components  
./oe_container_build_quickstart.sh -a build -v 12.8.9 -u your-username -c "compiler,pas_dev" -b
```

**Build all DevContainer images:**
```powershell
# Windows - All images
.\oe_container_build_quickstart.ps1 -Action build -Version 12.8.9 -DockerUsername your-username -Component all -Batch

# Linux/macOS - All images  
./oe_container_build_quickstart.sh -a build -v 12.8.9 -u your-username -c all -b
```

**Generate and build in one command:**
```powershell
# Windows - Complete workflow
.\oe_container_build_quickstart.ps1 -Action both -Version 12.8.9 -DockerUsername your-username -Component all -Batch

# Linux/macOS - Complete workflow
./oe_container_build_quickstart.sh -a both -v 12.8.9 -u your-username -c all -b
```

### Direct Tool Usage

**Generate response.ini files only:**
```powershell
# Windows
.\tools\Generate-ResponseIni.ps1 -Version 12.8.9

# Linux/macOS  
./tools/generate-response-ini.sh -v 12.8.9
```

**Build specific images:**
```powershell
# Windows - Single component
.\tools\build-image.ps1 -Component compiler -Version 12.8.9 -DockerUsername your-username

# Linux/macOS - Single component
./tools/build-image.sh -c compiler -v 12.8.9 -u your-username
```

**Build all images:**
```powershell
# Windows - All images
.\tools\build-all-images.ps1 -Version 12.8.9 -DockerUsername your-username

# Linux/macOS - All images  
./tools/build-all-images.sh -v 12.8.9 -u your-username
```

### Available Components
- **Base Images:** `compiler`, `pas_dev`, `db_adv` (can be built independently)
- **Dependent Images:** `devcontainer` (requires compiler), `sports2020-db` (requires db_adv)
- **All DevContainer Images:** Use `all` to build: compiler, pas_dev, db_adv, devcontainer, sports2020-db

> 📖 **For detailed documentation:** See [tools/README_Generate-ResponseIni.md](tools/README_Generate-ResponseIni.md)

## Credits

This project was inspired by the OpenEdge and Docker work of [Bronco Oostermeijer](https://github.com/bfv). Many thanks for the pioneering efforts in containerizing OpenEdge!
