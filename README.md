# oe_docker

This repository contains Dockerfiles and tooling to build local OpenEdge Docker container images such as `compiler`, `db_adv`, `pas_dev`, `pas_base`, and `pas_orads` using locally provided installers.

> **Note:** Pro2 replication demos have been moved to a separate repository: [oe_pro2_docker](https://github.com/rwdroge/oe_pro2_docker)

## Available Image Types

This repository supports building the following OpenEdge container images:

- **`compiler`** - OpenEdge compiler and development tools
- **`devcontainer`** - Development container (extends compiler image)
- **`db_adv`** - OpenEdge database server (Advanced Enterprise Edition)
- **`pas_dev`** - PASOE development instance with volumes for source code and libraries
- **`pas_base`** - PASOE production instance (basic configuration)
- **`pas_orads`** - PASOE production instance with Oracle DataServer (extends pas_base image)
- **`sports2020_db`** - Sports2020 demo database (extends db_adv image)

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

### Prerequisites

Before building images, ensure you have:

1. **OpenEdge installer binaries** placed in `binaries/oe/<major.minor>/` (see below)
2. **Valid control codes** configured in base component `response.ini` files (see [Configure control codes](#configure-control-codes))
   - Required for: `compiler`, `db_adv`, `pas_dev`, `pas_base`
   - Not required for: `devcontainer`, `pas_orads`, `sports2020-db` (these extend base images)
   - Example files (`response_ini_example.txt`) are provided in each component directory
   - Copy/rename to `response.ini` and add your company name, serials, and control codes

> ⚠️ **Important:** The build scripts will validate that both installers and required `response.ini` files exist before starting the build. Missing files will result in clear error messages.

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

**Note:** The following images don't need response.ini files as they build on top of base images:
- ~~`devcontainer/`~~ - Extends compiler image
- ~~`pas_orads/`~~ - Extends pas_base image
- ~~`sports2020-db/`~~ - Extends db_adv image

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

**Not required** (these extend base images):
- ~~`devcontainer/response.ini`~~ - Not needed (extends compiler)
- ~~`pas_orads/response.ini`~~ - Not needed (extends pas_base)
- ~~`sports2020-db/response.ini`~~ - Not needed (extends db_adv)

**What happens if missing:**
- Build scripts will validate required files upfront and fail with clear error messages if any are missing

## Building Images

### Build a single image (Windows PowerShell)

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

### Build a single image (Linux/macOS Bash)

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

### Build all images (Windows PowerShell)

You can build all images (compiler, devcontainer, pas_dev, pas_base, pas_orads, db_adv, sports2020-db) with a single command:

```powershell
pwsh ./tools/build-all-images.ps1 -Version 12.8.6 -Tag 12.8.6
```

**By default, all images are built.** This includes:
1. compiler image
2. devcontainer image (using the local compiler image as base)
3. pas_dev image
4. pas_base image
5. pas_orads image (using the local pas_base image as base)
6. db_adv image
7. sports2020-db image (using the local db_adv image as base)

Options (use Skip* flags to exclude specific images):
- `-SkipDevcontainer` to skip building the devcontainer image
- `-SkipPasOrads` to skip building the pas_orads image
- `-SkipSports2020Db` to skip building the sports2020-db image
- `-BinariesRoot` to point to a custom binaries root
- `-JDKVERSION` to control the Java version propagated as build-arg
- `-OEVERSION` to override the automatic mapping of series to OEVERSION

Example skipping devcontainer:

```powershell
pwsh ./tools/build-all-images.ps1 -Version 12.8.6 -Tag 12.8.6 -SkipDevcontainer
```

Example skipping optional images:

```powershell
pwsh ./tools/build-all-images.ps1 -Version 12.8.6 -Tag 12.8.6 -SkipPasOrads -SkipSports2020Db
```

The script will display a summary at the end showing the build status and duration for each component.

### Build all images (Linux/macOS Bash)

You can build all images (compiler, devcontainer, pas_dev, pas_base, pas_orads, db_adv, sports2020-db) with a single command:

```bash
./tools/build-all-images.sh -v 12.8.6 -t 12.8.6
```

**By default, all images are built.** This includes:
1. compiler image
2. devcontainer image (using the local compiler image as base)
3. pas_dev image
4. pas_base image
5. pas_orads image (using the local pas_base image as base)
6. db_adv image
7. sports2020-db image (using the local db_adv image as base)

Options (use skip flags to exclude specific images):
- `-s` to skip building the devcontainer image
- `-P` to skip building the pas_orads image
- `-S` to skip building the sports2020-db image
- `-b <binroot>` to point to a custom binaries root
- `-j <jdkversion>` to control the Java version propagated as build-arg
- `-o <oeversion>` to override the automatic mapping of series to OEVERSION

Example skipping devcontainer:

```bash
./tools/build-all-images.sh -v 12.8.6 -t 12.8.6 -s
```

Example skipping optional images:

```bash
./tools/build-all-images.sh -v 12.8.6 -t 12.8.6 -P -S
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

