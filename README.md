# oe_demos_docker

This repository contains Dockerfiles and tooling to build local OpenEdge images such as `compiler`, `db_adv`, and `pas_dev` using locally provided installers.

> **Note:** Pro2 replication demos have been moved to a separate repository: [oe_pro2_docker](https://github.com/rwdroge/oe_pro2_docker)

## Getting Started

### 1. Clone the repository

First, clone this repository to your local machine:

```bash
git clone https://github.com/rwdroge/oe_demos_docker.git
cd oe_demos_docker
```

### 2. Add OpenEdge installers

Place your OpenEdge installer binaries in the `binaries/oe/<major.minor>/` directory (see [Binaries folder layout](#binaries-folder-layout) below).

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

Each component directory contains an example response.ini file called `response_ini_example.txt` that you can use as a template:

- `compiler/response_ini_example.txt`
- `db_adv/response_ini_example.txt`
- `pas_dev/response_ini_example.txt`

**To configure:**

1. Copy or rename `response_ini_example.txt` to `response.ini` in each component directory
2. Edit the **Product Configuration** section(s) in each `response.ini` file
3. Add your company name, serial numbers, and control codes

**Example Product Configuration section:**
```ini
[Product Configuration 1]
name=YourCompanyName
serial=YourSerialNumber
version=12.8
control=YourControlCode
prodname=4GL Development System
```

**Required files after configuration:**

- `compiler/response.ini`
- `db_adv/response.ini`
- `pas_dev/response.ini`

**What happens if missing:**
- `build-image.ps1` will fail immediately with a clear error message pointing to the missing file
- `build-all-images.ps1` will check all three files upfront and list any that are missing before starting the build


### Prepare installers (Windows PowerShell)

Use `tools/prepare-installers.ps1` to stage installers for a component and version:

```powershell
pwsh ./tools/prepare-installers.ps1 -Component compiler -Version 12.8.6
pwsh ./tools/prepare-installers.ps1 -Component db_adv   -Version 12.8.6
pwsh ./tools/prepare-installers.ps1 -Component pas_dev  -Version 12.8.6
```

Optional parameters:

- `-BinariesRoot` to point to a custom binaries root.
- `-SingleTar`, `-BaseTar`, `-PatchTar` to explicitly specify filenames if they differ from the defaults.

### Prepare installers (POSIX shell)

If you are on Linux/macOS:

```bash
./tools/prepare-installers.sh -c compiler -v 12.8.6
./tools/prepare-installers.sh -c db_adv   -v 12.8.6
./tools/prepare-installers.sh -c pas_dev  -v 12.8.6
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

# pas_dev
docker build -f pas_dev/Dockerfile \
  --build-arg CTYPE=pas \
  --build-arg OEVERSION=128 \
  --build-arg JDKVERSION=21 \
  -t oe_pas_dev:12.8.6 .
```

Notes:

- The `OEVERSION` build-arg is already used by Dockerfiles for minor differences (e.g., creating `/etc/openedge.d` for certain versions). Keep using your existing conventions.
- The install flow is managed by `scripts/install-oe.sh`, which installs the base and, if present, the patch (`/install/patch/proinst`).

### One-step wrapper (Windows PowerShell)

You can run a single command that prepares installers and builds the image:

```powershell
pwsh ./tools/build-image.ps1 -Component compiler -Version 12.8.6 -Tag 12.8.6
pwsh ./tools/build-image.ps1 -Component db_adv   -Version 12.8.6 -Tag 12.8.6
pwsh ./tools/build-image.ps1 -Component pas_dev  -Version 12.8.6 -Tag 12.8.6
```

Options:
- `-ImageName` to override default repository name per component.
- `-BinariesRoot` to point to a custom binaries root.
- `-JDKVERSION` to control the Java version propagated as build-arg.
- `-OEVERSION` to override the automatic mapping of series to OEVERSION (defaults: 12.2→122, 12.7→127, 12.8→128).
- `-BuildDevcontainer` (compiler only) to also build a devcontainer image using the just-created local compiler image as the base. The devcontainer image will be tagged as `rdroge/oe_devcontainer:<Tag>`.

Example with devcontainer:

```powershell
pwsh ./tools/build-image.ps1 -Component compiler -Version 12.8.6 -Tag 12.8.6 -BuildDevcontainer
```

> **Note:** The `-BuildDevcontainer` switch can only be used with `-Component compiler` and requires the compiler image to be built first (which happens automatically in the same script execution).

### One-step wrapper (Linux/macOS Bash)

You can run a single command that prepares installers and builds the image:

```bash
./tools/build-image.sh -c compiler -v 12.8.6 -t 12.8.6
./tools/build-image.sh -c db_adv   -v 12.8.6 -t 12.8.6
./tools/build-image.sh -c pas_dev  -v 12.8.6 -t 12.8.6
```

Options:
- `-i <image>` to override default repository name per component
- `-b <binroot>` to point to a custom binaries root
- `-j <jdkversion>` to control the Java version propagated as build-arg
- `-o <oeversion>` to override the automatic mapping of series to OEVERSION (defaults: 12.2→122, 12.7→127, 12.8→128)
- `-d` (compiler only) to also build a devcontainer image using the just-created local compiler image as the base

Example with devcontainer:

```bash
./tools/build-image.sh -c compiler -v 12.8.6 -t 12.8.6 -d
```

> **Note:** The `-d` option can only be used with `-c compiler` and requires the compiler image to be built first (which happens automatically in the same script execution).

### Build all images at once (Windows PowerShell)

You can build all four images (compiler, devcontainer, pas_dev, db_adv) with a single command:

```powershell
pwsh ./tools/build-all-images.ps1 -Version 12.8.6 -Tag 12.8.6
```

This will:
1. Build the compiler image
2. Build the devcontainer image (using the local compiler image as base)
3. Build the pas_dev image
4. Build the db_adv image

Options:
- `-SkipDevcontainer` to skip building the devcontainer image
- `-BinariesRoot` to point to a custom binaries root
- `-JDKVERSION` to control the Java version propagated as build-arg
- `-OEVERSION` to override the automatic mapping of series to OEVERSION

Example without devcontainer:

```powershell
pwsh ./tools/build-all-images.ps1 -Version 12.8.6 -Tag 12.8.6 -SkipDevcontainer
```

The script will display a summary at the end showing the build status and duration for each component.

### Build all images at once (Linux/macOS Bash)

You can build all four images (compiler, devcontainer, pas_dev, db_adv) with a single command:

```bash
./tools/build-all-images.sh -v 12.8.6 -t 12.8.6
```

This will:
1. Build the compiler image
2. Build the devcontainer image (using the local compiler image as base)
3. Build the pas_dev image
4. Build the db_adv image

Options:
- `-s` to skip building the devcontainer image
- `-b <binroot>` to point to a custom binaries root
- `-j <jdkversion>` to control the Java version propagated as build-arg
- `-o <oeversion>` to override the automatic mapping of series to OEVERSION

Example without devcontainer:

```bash
./tools/build-all-images.sh -v 12.8.6 -t 12.8.6 -s
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
