#!/usr/bin/env bash
set -euo pipefail

# Build all OpenEdge images (compiler, devcontainer, pas_dev, pas_base, pas_orads, db_adv, sports2020-db) in one command
# By default, all images are built. Use skip options to exclude specific images.

usage() {
  cat >&2 <<EOF
Usage: $0 -v <version> -u <username> [options]

Required:
  -v <version>       Version in MAJOR.MINOR.PATCH format (e.g., 12.8.6)
  -u <username>      Docker username for image tagging

Optional:
  -t <tag>           Docker image tag (defaults to version)
  -b <binroot>       Custom binaries root directory
  -o <oeversion>     OE version code (default: auto-mapped from series)
  -s                 Skip devcontainer build
  -S                 Skip sports2020-db build
  -D                 Build only devcontainer images (compiler, devcontainer, pas_dev, db_adv, sports2020-db)
  -h                 Show this help

Examples:
  $0 -v 12.8.6 -t 12.8.6 -u myusername
  $0 -v 12.8.6 -t 12.8.6 -u myusername -s
  $0 -v 12.8.6 -t 12.8.6 -u myusername -S
  $0 -v 12.8.6 -t 12.8.6 -u myusername -D
EOF
}

# Parse arguments
VERSION=""
TAG=""
BINARIES_ROOT=""
DOCKER_USERNAME=""
OEVERSION=""
SKIP_DEVCONTAINER=0
SKIP_SPORTS2020=0
DEVCONTAINER_ONLY=0

while getopts ":v:t:b:u:j:o:sSDh" opt; do
  case $opt in
    v) VERSION="$OPTARG";;
    t) TAG="$OPTARG";;
    b) BINARIES_ROOT="$OPTARG";;
    u) DOCKER_USERNAME="$OPTARG";;
    o) OEVERSION="$OPTARG";;
    s) SKIP_DEVCONTAINER=1;;
    S) SKIP_SPORTS2020=1;;
    D) DEVCONTAINER_ONLY=1;;
    h) usage; exit 0;;
    *) usage; exit 1;;
  esac
done

# Validate required arguments
if [[ -z "$VERSION" || -z "$DOCKER_USERNAME" ]]; then
  echo "Error: -v and -u are required" >&2
  usage
  exit 1
fi

# Default tag to version if not provided
if [[ -z "$TAG" ]]; then
  TAG="$VERSION"
fi

# Get script directory and root
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_IMAGE_SCRIPT="$SCRIPT_DIR/build-image.sh"

if [[ ! -f "$BUILD_IMAGE_SCRIPT" ]]; then
  echo "Error: build-image.sh not found at: $BUILD_IMAGE_SCRIPT" >&2
  exit 1
fi

# If DEVCONTAINER_ONLY is set, build only the images needed for devcontainer setups
if [[ $DEVCONTAINER_ONLY -eq 1 ]]; then
  COMPONENTS=("compiler" "pas_dev" "db_adv")
  BUILD_DEVCONTAINER=1
  BUILD_SPORTS=1
else
  COMPONENTS=("compiler" "pas_dev" "db_adv")
  BUILD_DEVCONTAINER=$((1 - SKIP_DEVCONTAINER))
  BUILD_SPORTS=$((1 - SKIP_SPORTS2020))
fi

# Validate all response.ini files exist before starting
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MISSING_RESPONSE_INI=()
for comp in "${COMPONENTS[@]}"; do
  RESPONSE_INI="$ROOT/$comp/response.ini"
  if [[ ! -f "$RESPONSE_INI" ]]; then
    MISSING_RESPONSE_INI+=("$RESPONSE_INI")
  fi
done

if [[ ${#MISSING_RESPONSE_INI[@]} -gt 0 ]]; then
  echo -e "\033[0;31mError: Missing response.ini file(s):\033[0m" >&2
  for missing in "${MISSING_RESPONSE_INI[@]}"; do
    echo -e "\033[0;31m  - $missing\033[0m" >&2
  done
  echo "" >&2
  echo -e "\033[0;33mPlease configure OpenEdge control codes in the response.ini files before building.\033[0m" >&2
  echo -e "\033[0;33mSee the 'Configure control codes' section in README.md for details.\033[0m" >&2
  exit 1
fi

echo -e "\033[0;36m========================================\033[0m"
if [[ $DEVCONTAINER_ONLY -eq 1 ]]; then
  echo -e "\033[0;36mBuilding OpenEdge images for devcontainer\033[0m"
else
  echo -e "\033[0;36mBuilding all OpenEdge images\033[0m"
fi
echo -e "\033[0;36m  Version: $VERSION\033[0m"
echo -e "\033[0;36m  Tag: $TAG\033[0m"
echo -e "\033[0;36m  Components: ${COMPONENTS[*]}\033[0m"
echo -e "\033[0;36m  Devcontainer: $([[ $BUILD_DEVCONTAINER -eq 1 ]] && echo "true" || echo "false")\033[0m"
echo -e "\033[0;36m  Sports2020-db: $([[ $BUILD_SPORTS -eq 1 ]] && echo "true" || echo "false")\033[0m"
echo -e "\033[0;36m========================================\033[0m"
echo ""

START_TIME=$(date +%s)
declare -a RESULTS
declare -a DURATIONS
declare -a STATUSES

for comp in "${COMPONENTS[@]}"; do
  
  echo ""
  echo -e "\033[0;33m========================================\033[0m"
  echo -e "\033[0;33mBuilding: $comp\033[0m"
  echo -e "\033[0;33m========================================\033[0m"
  echo ""
  
  COMP_START_TIME=$(date +%s)
  
  # Build arguments
  BUILD_ARGS="-c $comp -v $VERSION -t $TAG -u $DOCKER_USERNAME"
  
  if [[ -n "$BINARIES_ROOT" ]]; then
    BUILD_ARGS="$BUILD_ARGS -b $BINARIES_ROOT"
  fi
  
  
  if [[ -n "$OEVERSION" ]]; then
    BUILD_ARGS="$BUILD_ARGS -o $OEVERSION"
  fi
  
  # Only add -d for compiler component
  if [[ "$comp" == "compiler" && $BUILD_DEVCONTAINER -eq 1 ]]; then
    BUILD_ARGS="$BUILD_ARGS -d"
  fi
  
  # Only add -s for db_adv component
  if [[ "$comp" == "db_adv" && $BUILD_SPORTS -eq 1 ]]; then
    BUILD_ARGS="$BUILD_ARGS -s"
  fi
  
  # Run build
  if bash "$BUILD_IMAGE_SCRIPT" $BUILD_ARGS; then
    COMP_END_TIME=$(date +%s)
    COMP_DURATION=$((COMP_END_TIME - COMP_START_TIME))
    DURATIONS+=("$COMP_DURATION")
    STATUSES+=("Success")
    
    MINUTES=$((COMP_DURATION / 60))
    SECONDS=$((COMP_DURATION % 60))
    
    echo ""
    echo -e "\033[0;32m $comp completed in ${MINUTES}m ${SECONDS}s\033[0m"
  else
    COMP_END_TIME=$(date +%s)
    COMP_DURATION=$((COMP_END_TIME - COMP_START_TIME))
    DURATIONS+=("$COMP_DURATION")
    STATUSES+=("Failed")
    
    echo ""
    echo -e "\033[0;31m $comp failed\033[0m"
    echo ""
    echo -e "\033[0;31mStopping build process due to failure.\033[0m"
    break
  fi
done

END_TIME=$(date +%s)
TOTAL_DURATION=$((END_TIME - START_TIME))

echo ""
echo -e "\033[0;36m========================================\033[0m"
echo -e "\033[0;36mBuild Summary\033[0m"
echo -e "\033[0;36m========================================\033[0m"
echo ""

SUCCESS_COUNT=0
FAIL_COUNT=0

for i in "${!COMPONENTS[@]}"; do
  if [[ $i -lt ${#STATUSES[@]} ]]; then
    comp="${COMPONENTS[$i]}"
    status="${STATUSES[$i]}"
    duration="${DURATIONS[$i]}"
    
    MINUTES=$((duration / 60))
    SECONDS=$((duration % 60))
    
    if [[ "$status" == "Success" ]]; then
      echo -e "\033[0;32m $comp: $status (${MINUTES}m ${SECONDS}s)\033[0m"
      SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
      echo -e "\033[0;31m $comp: $status (${MINUTES}m ${SECONDS}s)\033[0m"
      FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
  fi
done

echo ""
TOTAL_HOURS=$((TOTAL_DURATION / 3600))
TOTAL_MINUTES=$(((TOTAL_DURATION % 3600) / 60))
TOTAL_SECONDS=$((TOTAL_DURATION % 60))
echo -e "\033[0;36mTotal time: ${TOTAL_HOURS}h ${TOTAL_MINUTES}m ${TOTAL_SECONDS}s\033[0m"

if [[ $FAIL_COUNT -gt 0 ]]; then
  echo ""
  echo -e "\033[0;31mBuild completed with $FAIL_COUNT failure(s) and $SUCCESS_COUNT success(es).\033[0m"
  exit 1
else
  echo ""
  echo -e "\033[0;32mAll builds completed successfully!\033[0m"
  
  echo ""
  echo -e "\033[0;36mBuilt images:\033[0m"
  echo "  - $DOCKER_USERNAME/oe_compiler:$TAG"
  if [[ $BUILD_DEVCONTAINER -eq 1 ]]; then
    echo "  - $DOCKER_USERNAME/oe_devcontainer:$TAG"
  fi
  echo "  - $DOCKER_USERNAME/oe_pas_dev:$TAG"
  echo "  - $DOCKER_USERNAME/oe_db_adv:$TAG"
  if [[ $BUILD_SPORTS -eq 1 ]]; then
    echo "  - $DOCKER_USERNAME/oe_sports2020_db:$TAG"
  fi
fi
