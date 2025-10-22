# oe_docker

This repository contains Dockerfiles and tooling to build local OpenEdge Docker container images such as `compiler`, `db_adv`, and `pas_dev` using locally provided installers. Focused on DevContainer workflows.

## 🚀 Quick Start

**New to this repository?** Use the quickstart tool for an easy interactive setup:

**Windows PowerShell:**
```powershell
.\oe_container_build_quickstart.ps1
```

**Linux/macOS:**
```bash
./oe_container_build_quickstart.sh
```

This provides an interactive menu to:
1. Generate `response.ini` files from your license addendum
2. Create all images for DevContainer configuration
3. Create specific container images with dependency validation

## Available Image Types

This repository supports building the following OpenEdge container images:

### Base Images (can be built independently)
- **`compiler`** - OpenEdge compiler and development tools
- **`pas_dev`** - PASOE development instance with volumes for source code and libraries
- **`db_adv`** - OpenEdge database server (Advanced Enterprise Edition)

### Dependent Images (require parent images)
- **`devcontainer`** - Development container (requires: compiler)
- **`sports2020_db`** - Sports2020 demo database (requires: db_adv)

### DevContainer Focus

This repository is optimized for **DevContainer workflows**, providing:
- **`pas_dev`**: Development-focused PASOE with:
  - Volumes for `/app/src`, `/app/lib`, `/app/config`
  - Development-type PASOE instance
  - Suitable for local development and testing
- **`devcontainer`**: Complete development environment with OpenEdge compiler and tools
- **Dependency validation**: Ensures dependent images are built in correct order

## Using with Dev Containers

The **`devcontainer`**, **`sports2020_db`**, and **`pas_dev`** images built from this repository can be used with the OpenEdge development container setups available at:

**[https://github.com/rwdroge/oedevcontainer](https://github.com/rwdroge/oedevcontainer)**

This provides a complete containerized OpenEdge development environment with VS Code integration.

### Building Images for Dev Containers Only

**If you only need images for dev container setups**, you can use the quickstart tool's option 2 to build all required images (compiler, devcontainer, pas_dev, db_adv, sports2020-db):

**Windows:**
```powershell
.\oe_container_build_quickstart.ps1
# Then select option 2: "Create all images for DevContainer configuration"
```

**Linux/macOS:**
```bash
./oe_container_build_quickstart.sh
# Then select option 2: "Create all images for DevContainer configuration"
```

This significantly reduces build time by only creating the images needed for development container workflows.

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

## Getting Started

Once you have the prerequisites ready, simply run the quickstart script and it will guide you through the process:

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


### Configure control codes

> ⚠️ **Required:** You must configure valid OpenEdge control codes before building images.

**Required components** (need response.ini):
- `compiler`, `db_adv`, `pas_dev`, `pas_base`

**Not required** (extend base images):
- `devcontainer`, `pas_orads`, `sports2020-db`

#### Automated Setup (Recommended)

Use the automated script to generate response.ini files from your license addendum:

**Windows PowerShell:**
```powershell
cd tools
.\Generate-ResponseIni.ps1
```

**Linux/macOS:**
```bash
cd tools
./generate-response-ini.sh
```

**For devcontainer images:**
```powershell
.\Generate-ResponseIni.ps1 -Devcontainer
```

The script will:
- ✅ Validate your license addendum file format
- ✅ Extract company name, serial numbers, and control codes
- ✅ Generate response.ini files for all required components
- ✅ Match products to the correct container configurations

> 📖 **See [tools/README_Generate-ResponseIni.md](tools/README_Generate-ResponseIni.md) for detailed usage**

#### Manual Setup

If you prefer manual configuration:

Execute the following command from the root folder of the repository

1. Copy example file(s) to `response.ini` (and `response_update.ini` for dual-response versions):
   ```bash
   # Most versions (single file)
   cp compiler/response_ini_example.txt compiler/response.ini
   
   # Versions 12.2.17-12.2.18 and 12.8.4-12.8.8 (two files)
   cp compiler/response_ini_example.txt compiler/response.ini
   cp compiler/response_update_ini_example.txt compiler/response_update.ini
   ```

2. Edit the file(s) and add your company name, serial numbers, and control codes based on the License Addendum downloaded from ESD

3. You'll need to adjust the response.ini/response_update.ini files for every required Docker image that you want to build: `compiler` (example as shown above), `db_adv`, `pas_dev`, `pas_base`

> **Note:** Build scripts will validate required files exist before starting and fail with clear error messages if any are missing.

> 📖 **See [RESPONSE_INI_GUIDE.md](RESPONSE_INI_GUIDE.md) for detailed instructions**, especially for versions **12.2.17-12.2.18** and **12.8.4-12.8.8** which require two response files.

## Building Images

### Build a single image (Windows PowerShell)

You can run a single command that prepares installers and builds the image:

```powershell
pwsh ./tools/build-image.ps1 -Component compiler  -Version 12.8.6 -Tag 12.8.6
pwsh ./tools/build-image.ps1 -Component db_adv    -Version 12.8.6 -Tag 12.8.6
pwsh ./tools/build-image.ps1 -Component pas_dev   -Version 12.8.6 -Tag 12.8.6
```

Options:
- `-ImageName` to override default repository name per component.
- `-BinariesRoot` to point to a custom binaries root.
- `-OEVERSION` to override the automatic mapping of series to OEVERSION (defaults: 12.2→122, 12.7→127, 12.8→128).
- `-BuildDevcontainer` (compiler only) to also build a devcontainer image using the just-created local compiler image as the base. The devcontainer image will be tagged as `rdroge/oe_devcontainer:<Tag>`.
- `-BuildSports2020Db` (db_adv only) to also build a sports2020-db image using the just-created local db_adv image as the base. The sports2020-db image will be tagged as `rdroge/oe_sports2020_db:<Tag>`.

Example with devcontainer:

```powershell
pwsh ./tools/build-image.ps1 -Component compiler -Version 12.8.6 -Tag 12.8.6 -BuildDevcontainer
```

Example with sports2020-db:

```powershell
pwsh ./tools/build-image.ps1 -Component db_adv -Version 12.8.6 -Tag 12.8.6 -BuildSports2020Db
```

> **Note:** The `-BuildDevcontainer` switch can only be used with `-Component compiler` and the `-BuildSports2020Db` switch can only be used with `-Component db_adv`. Both require their base image to be built first (which happens automatically in the same script execution).

### Build a single image (Linux/macOS Bash)

You can run a single command that prepares installers and builds the image:

```bash
./tools/build-image.sh -c compiler  -v 12.8.6 -t 12.8.6
./tools/build-image.sh -c db_adv    -v 12.8.6 -t 12.8.6
./tools/build-image.sh -c pas_dev   -v 12.8.6 -t 12.8.6
```

Options:
- `-i <image>` to override default repository name per component
- `-b <binroot>` to point to a custom binaries root
- `-o <oeversion>` to override the automatic mapping of series to OEVERSION (defaults: 12.2→122, 12.7→127, 12.8→128)
- `-d` (compiler only) to also build a devcontainer image using the just-created local compiler image as the base
- `-s` (db_adv only) to also build a sports2020-db image using the just-created local db_adv image as the base

Example with devcontainer:

```bash
./tools/build-image.sh -c compiler -v 12.8.6 -t 12.8.6 -d
```

Example with sports2020-db:

```bash
./tools/build-image.sh -c db_adv -v 12.8.6 -t 12.8.6 -s
```

> **Note:** The `-d` option can only be used with `-c compiler` and the `-s` option can only be used with `-c db_adv`. Both require their base image to be built first (which happens automatically in the same script execution).

### Build all images (Windows PowerShell)

You can build all images (compiler, devcontainer, pas_dev, db_adv, sports2020-db) with a single command:

```powershell
pwsh ./tools/build-all-images.ps1 -Version 12.8.6 -Tag 12.8.6
```

**By default, all images are built.** This includes:
1. compiler image
2. devcontainer image (using the local compiler image as base)
3. pas_dev image
4. db_adv image
5. sports2020-db image (using the local db_adv image as base)

Options (use Skip* flags to exclude specific images):
- `-SkipDevcontainer` to skip building the devcontainer image
- `-SkipSports2020Db` to skip building the sports2020-db image
- `-DevcontainerOnly` to build only images required for devcontainer setups (compiler, devcontainer, pas_dev, db_adv, sports2020-db)
- `-BinariesRoot` to point to a custom binaries root
- `-OEVERSION` to override the automatic mapping of series to OEVERSION

Example building only devcontainer images:

```powershell
pwsh ./tools/build-all-images.ps1 -Version 12.8.6 -Tag 12.8.6 -DevcontainerOnly
```

Example skipping devcontainer:

```powershell
pwsh ./tools/build-all-images.ps1 -Version 12.8.6 -Tag 12.8.6 -SkipDevcontainer
```

Example skipping sports2020-db:

```powershell
pwsh ./tools/build-all-images.ps1 -Version 12.8.6 -Tag 12.8.6 -SkipSports2020Db
```

The script will display a summary at the end showing the build status and duration for each component.

### Build all images (Linux/macOS Bash)

You can build all images (compiler, devcontainer, pas_dev, db_adv, sports2020-db) with a single command:

```bash
./tools/build-all-images.sh -v 12.8.6 -t 12.8.6
```

**By default, all images are built.** This includes:
1. compiler image
2. devcontainer image (using the local compiler image as base)
3. pas_dev image
4. db_adv image
5. sports2020-db image (using the local db_adv image as base)

Options (use skip flags to exclude specific images):
- `-s` to skip building the devcontainer image
- `-S` to skip building the sports2020-db image
- `-D` to build only images required for devcontainer setups (compiler, devcontainer, pas_dev, db_adv, sports2020-db)
- `-b <binroot>` to point to a custom binaries root
- `-o <oeversion>` to override the automatic mapping of series to OEVERSION

Example building only devcontainer images:

```bash
./tools/build-all-images.sh -v 12.8.6 -t 12.8.6 -D
```

Example skipping devcontainer:

```bash
./tools/build-all-images.sh -v 12.8.6 -t 12.8.6 -s
```

Example skipping sports2020-db:

```bash
./tools/build-all-images.sh -v 12.8.6 -t 12.8.6 -S
```

The script will display a summary at the end showing the build status and duration for each component.

### Series note (12.2, 12.8)

For 12.2 the base installer filename follows the same convention as 12.8: the base tar omits `.0` in the filename.

Examples:

- 12.2 base+patch:
  - `binaries/oe/12.2/PROGRESS_OE_12.2_LNX_64.tar.gz`
  - `binaries/oe/12.2/PROGRESS_OE_12.2.x_LNX_64.tar.gz` (patch)
- 12.8 base+patch:
  - `binaries/oe/12.8/PROGRESS_OE_12.8_LNX_64.tar.gz`
  - `binaries/oe/12.8/PROGRESS_OE_12.8.x_LNX_64.tar.gz` (patch)

## Credits

This project was also inspired by the OpenEdge and Docker work of [Bronco Oostermeijer](https://github.com/bfv). Many thanks for the pioneering efforts in containerizing OpenEdge!






