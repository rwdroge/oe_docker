# oe_docker

This repository contains Dockerfiles and tooling to build local OpenEdge Docker container images such as `compiler`, `db_adv`, `pas_dev`, `pas_base`, and `pas_orads` using locally provided installers.

> **Note:** Pro2 replication demos have been moved to a separate repository: [oe_pro2_docker](https://github.com/rwdroge/oe_pro2_docker)

## Available Image Types

This repository supports building the following OpenEdge container images:

- **`compiler`** - OpenEdge compiler and development tools
- **`devcontainer`** - Development container based on compiler image (built automatically with compiler)
- **`db_adv`** - OpenEdge database server (Advanced Enterprise Edition)
- **`pas_dev`** - PASOE development instance with volumes for source code and libraries
- **`pas_base`** - PASOE production instance (basic configuration)
- **`pas_orads`** - PASOE production instance with Oracle DataServer support
- **`sports2020_db`** - Sports2020 demo database (built automatically with db_adv if requested)

### PASOE Image Differences

- **`pas_dev`**: Development-focused PASOE with:
  - Volumes for `/app/src`, `/app/lib`, `/app/config`
  - Development profile configuration
  - Suitable for local development and testing

- **`pas_base`**: Production PASOE with:
  - Pre-created production instance (`prodpas`)
  - Health check enabled
  - Minimal configuration for production deployment

- **`pas_orads`**: Production PASOE with Oracle DataServer:
  - **Builds on top of `pas_base`** (layered image)
  - Adds Oracle Client 19.3 (Linux 64-bit)
  - Oracle DataServer components included
  - Requires Oracle client installer in `binaries/oracle/` directory
  - **Note**: Must build `pas_base` first

## Getting Started

### 1. Clone the repository

First, clone this repository to your local machine:

```bash
git clone https://github.com/rwdroge/oe_docker.git
cd oe_docker
```

### 2. Add OpenEdge installers

Download the Linux 64-bit installers for the required OE versions from ESD.
Place those OpenEdge installer binaries in the `binaries/oe/<major.minor>/` directory (see [Binaries folder layout](#binaries-folder-layout) below).

### 3. Configure control codes

Rename the response_._ini_example.txt files to response.ini and add your OpenEdge control codes (see [Configure control codes](#configure-control-codes) below).

### 4. Build images

Use the provided build scripts to create your Docker images (see build sections below).

## Prerequisites

Before building images, ensure you have:

1. **OpenEdge installer binaries** placed in `binaries/oe/<major.minor>/` (see below)
2. **Valid control codes** configured in each component's `response.ini` file (see [Configure control codes](#configure-control-codes))
   - Example files (`response_ini_example.txt`) are provided in each component directory
   - Copy/rename to `response.ini` and add your company name, serials, and control codes

> ⚠️ **Important:** The build scripts will validate that both installers and `response.ini` files exist before starting the build. Missing files will result in clear error messages.

### Binaries folder layout

Place your binaries under `binaries/oe/<major.minor>/` relative to the repo root:

- Single installer example:
  - `binaries/oe/12.8/PROGRESS_OE_12.8.9_LNX_64.tar.gz`
- Base + patch example:
  - `binaries/oe/12.8/PROGRESS_OE_12.8_LNX_64.tar.gz` (base)
  - `binaries/oe/12.8/PROGRESS_OE_12.8.6_LNX_64.tar.gz` (patch)

> **Important (OpenEdge 12.8.4â€“12.8.8):** You must place the 12.8 base installer next to the update installer (OE 12.8.x) in the same directory. The tooling expects both base and update to be present side-by-side to stage and install correctly.

Example required pair for 12.8.6:

- `binaries/oe/12.8/PROGRESS_OE_12.8_LNX_64.tar.gz` (base)
- `binaries/oe/12.8/PROGRESS_OE_12.8.6_LNX_64.tar.gz` (update)


If your tarball names differ, you can override filenames via script parameters (see below). The scripts will stage the patch file to `installer/PROGRESS_PATCH_OE.tar.gz` for the Dockerfile.

### Configure control codes

> ⚠️ **Required:** You must configure valid OpenEdge control codes before building images.

> 📖 **See [RESPONSE_INI_GUIDE.md](RESPONSE_INI_GUIDE.md) for detailed instructions**, especially for versions **12.2.17-12.2.18** and **12.8.4-12.8.8** which require two response files.

Each component directory contains example response.ini files:

- `compiler/response_ini_example.txt` (and `response_update_ini_example.txt` for dual-response versions)
- `db_adv/response_ini_example.txt` (and `response_update_ini_example.txt` for dual-response versions)
- `pas_dev/response_ini_example.txt` (and `response_update_ini_example.txt` for dual-response versions)
- `pas_base/response_ini_example.txt` (and `response_update_ini_example.txt` for dual-response versions)
- ~~`pas_orads/`~~ - No response.ini needed (extends pas_base)

**Quick setup:**

1. Copy `response_ini_example.txt` to `response.ini` in each component directory
2. **For OpenEdge 12.2.17-12.2.18 or 12.8.4-12.8.8**: Also copy `response_update_ini_example.txt` to `response_update.ini`
3. Edit the file(s) and add your company name, serial numbers, and control codes

> **Note**: Most versions use a single installer/response file. Only 12.2.17-12.2.18 and 12.8.4-12.8.8 require dual response files.

**Example for dual-response versions (12.2.17-12.2.18, 12.8.4-12.8.8):**
```powershell
# Base installation file (always needed)
cp compiler/response_ini_example.txt compiler/response.ini

# Update/patch installation file (ONLY for dual-response versions)
cp compiler/response_update_ini_example.txt compiler/response_update.ini

# Edit both files with your license info
```

**Example for single-installer versions (most versions):**
```powershell
# Only one file needed
cp compiler/response_ini_example.txt compiler/response.ini

# Edit with your license info
```

**Required files after configuration:**

- `compiler/response.ini` (+ `response_update.ini` for 12.2.17-12.2.18, 12.8.4-12.8.8)
- `db_adv/response.ini` (+ `response_update.ini` for 12.2.17-12.2.18, 12.8.4-12.8.8)
- `pas_dev/response.ini` (+ `response_update.ini` for 12.2.17-12.2.18, 12.8.4-12.8.8)
- `pas_base/response.ini` (+ `response_update.ini` for 12.2.17-12.2.18, 12.8.4-12.8.8)
- ~~`pas_orads/response.ini`~~ - Not needed (extends pas_base)

**What happens if missing:**
- `build-image.ps1` will fail immediately with a clear error message pointing to the missing file
- `build-all-images.ps1` will check all three files upfront and list any that are missing before starting the build


### Prepare installers (Windows PowerShell)

Use `tools/prepare-installers.ps1` to stage installers for a component and version:

```powershell
pwsh ./tools/prepare-installers.ps1 -Component compiler  -Version 12.8.6
pwsh ./tools/prepare-installers.ps1 -Component db_adv    -Version 12.8.6
pwsh ./tools/prepare-installers.ps1 -Component pas_dev   -Version 12.8.6
pwsh ./tools/prepare-installers.ps1 -Component pas_base  -Version 12.8.6
pwsh ./tools/prepare-installers.ps1 -Component pas_orads -Version 12.8.6
```

Optional parameters:

- `-BinariesRoot` to point to a custom binaries root.
- `-SingleTar`, `-BaseTar`, `-PatchTar` to explicitly specify filenames if they differ from the defaults.

### Prepare installers (POSIX shell)

If you are on Linux/macOS:

```bash
./tools/prepare-installers.sh -c compiler  -v 12.8.6
./tools/prepare-installers.sh -c db_adv    -v 12.8.6
./tools/prepare-installers.sh -c pas_dev   -v 12.8.6
./tools/prepare-installers.sh -c pas_base  -v 12.8.6
./tools/prepare-installers.sh -c pas_orads -v 12.8.6
```

Use `-b </path/to/binaries/oe>` to override the binaries root.

### Build images locally

After preparing the installers, build images as usual from the repo root. Example:

```bash
# compiler
docker build -f compiler/Dockerfile \
  --build-arg CTYPE=compiler \
  --build-arg OEVERSION=128 \
  --build-arg JDKVERSION=21 \
  -t oe_compiler:12.8.6 .

# db_adv
docker build -f db_adv/Dockerfile \
  --build-arg CTYPE=db \
  --build-arg JDKVERSION=21 \
  -t oe_db_adv:12.8.6 .

# pas_dev (development PASOE)
docker build -f pas_dev/Dockerfile \
  --build-arg CTYPE=pas \
  --build-arg OEVERSION=128 \
  --build-arg JDKVERSION=21 \
  -t oe_pas_dev:12.8.6 .

# pas_base (production PASOE)
docker build -f pas_base/Dockerfile \
  --build-arg CTYPE=pas \
  --build-arg OEVERSION=128 \
  --build-arg JDKVERSION=21 \
  -t oe_pas_base:12.8.6 .

# pas_orads (production PASOE with Oracle DataServer)
docker build -f pas_orads/Dockerfile \
  --build-arg CTYPE=pas \
  --build-arg OEVERSION=128 \
  --build-arg JDKVERSION=21 \
  -t oe_pas_orads:12.8.6 .
```

Notes:

- The `OEVERSION` build-arg is already used by Dockerfiles for minor differences (e.g., creating `/etc/openedge.d` for certain versions). Keep using your existing conventions.
- The install flow is managed by `scripts/install-oe.sh`, which installs the base and, if present, the patch (`/install/patch/proinst`).

### One-step wrapper (Windows PowerShell)

You can run a single command that prepares installers and builds the image:

```powershell
pwsh ./tools/build-image.ps1 -Component compiler  -Version 12.8.6 -Tag 12.8.6
pwsh ./tools/build-image.ps1 -Component db_adv    -Version 12.8.6 -Tag 12.8.6
pwsh ./tools/build-image.ps1 -Component pas_dev   -Version 12.8.6 -Tag 12.8.6
pwsh ./tools/build-image.ps1 -Component pas_base  -Version 12.8.6 -Tag 12.8.6
pwsh ./tools/build-image.ps1 -Component pas_orads -Version 12.8.6 -Tag 12.8.6
```

Options:
- `-ImageName` to override default repository name per component.
- `-BinariesRoot` to point to a custom binaries root.
- `-JDKVERSION` to control the Java version propagated as build-arg.
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

### One-step wrapper (Linux/macOS Bash)

You can run a single command that prepares installers and builds the image:

```bash
./tools/build-image.sh -c compiler  -v 12.8.6 -t 12.8.6
./tools/build-image.sh -c db_adv    -v 12.8.6 -t 12.8.6
./tools/build-image.sh -c pas_dev   -v 12.8.6 -t 12.8.6
./tools/build-image.sh -c pas_base  -v 12.8.6 -t 12.8.6
./tools/build-image.sh -c pas_orads -v 12.8.6 -t 12.8.6
```

Options:
- `-i <image>` to override default repository name per component
- `-b <binroot>` to point to a custom binaries root
- `-j <jdkversion>` to control the Java version propagated as build-arg
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

### Build all images at once (Windows PowerShell)

You can build all images (compiler, devcontainer, pas_dev, pas_base, pas_orads, db_adv) with a single command:

```powershell
pwsh ./tools/build-all-images.ps1 -Version 12.8.6 -Tag 12.8.6
```

This will:
1. Build the compiler image
2. Build the devcontainer image (using the local compiler image as base)
3. Build the pas_dev image
4. Build the pas_base image
5. Build the pas_orads image
6. Build the db_adv image

Options:
- `-SkipDevcontainer` to skip building the devcontainer image
- `-BuildSports2020Db` to also build the sports2020-db image after db_adv
- `-BinariesRoot` to point to a custom binaries root
- `-JDKVERSION` to control the Java version propagated as build-arg
- `-OEVERSION` to override the automatic mapping of series to OEVERSION

Example without devcontainer:

```powershell
pwsh ./tools/build-all-images.ps1 -Version 12.8.6 -Tag 12.8.6 -SkipDevcontainer
```

Example with sports2020-db:

```powershell
pwsh ./tools/build-all-images.ps1 -Version 12.8.6 -Tag 12.8.6 -BuildSports2020Db
```

The script will display a summary at the end showing the build status and duration for each component.

### Build all images at once (Linux/macOS Bash)

You can build all images (compiler, devcontainer, pas_dev, pas_base, pas_orads, db_adv) with a single command:

```bash
./tools/build-all-images.sh -v 12.8.6 -t 12.8.6
```

This will:
1. Build the compiler image
2. Build the devcontainer image (using the local compiler image as base)
3. Build the pas_dev image
4. Build the pas_base image
5. Build the pas_orads image
6. Build the db_adv image

Options:
- `-s` to skip building the devcontainer image
- `-S` to also build the sports2020-db image after db_adv
- `-b <binroot>` to point to a custom binaries root
- `-j <jdkversion>` to control the Java version propagated as build-arg
- `-o <oeversion>` to override the automatic mapping of series to OEVERSION

Example without devcontainer:

```bash
./tools/build-all-images.sh -v 12.8.6 -t 12.8.6 -s
```

Example with sports2020-db:

```bash
./tools/build-all-images.sh -v 12.8.6 -t 12.8.6 -S
```

The script will display a summary at the end showing the build status and duration for each component.

### Series note (12.2, 12.7, 12.8)

For 12.2 and 12.7 series the base installer filename follows the same convention as 12.8: the base tar omits `.0` in the filename.

Examples:

- 12.2 base+patch:
  - `binaries/oe/12.2/PROGRESS_OE_12.2_LNX_64.tar.gz`
  - `binaries/oe/12.2/PROGRESS_OE_12.2.x_LNX_64.tar.gz` (patch)
- 12.7 base+patch:
  - `binaries/oe/12.7/PROGRESS_OE_12.7_LNX_64.tar.gz`
  - `binaries/oe/12.7/PROGRESS_OE_12.7.x_LNX_64.tar.gz` (patch)

