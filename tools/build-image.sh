#!/usr/bin/env bash
set -euo pipefail

# Build a single OpenEdge Docker image (compiler, db_adv, or pas_dev)
# with optional devcontainer build for compiler component

usage() {
  cat >&2 <<EOF
Usage: $0 -c <component> -v <version> [options]

Required:
  -c <component>     Component to build: compiler, db_adv, or pas_dev
  -v <version>       Version in MAJOR.MINOR.PATCH format (e.g., 12.8.6)

Optional:
  -t <tag>           Docker image tag (defaults to version)
  -i <image>         Override default image name
  -b <binroot>       Custom binaries root directory
  -j <jdkversion>    JDK version (default: 21)
  -o <oeversion>     OE version code (default: auto-mapped from series)
  -d                 Build devcontainer (compiler only)
  -s                 Build sports2020-db (db_adv only)
  -h                 Show this help

Examples:
  $0 -c compiler -v 12.8.6 -t 12.8.6
  $0 -c compiler -v 12.8.6 -t 12.8.6 -d
  $0 -c db_adv -v 12.8.6 -t 12.8.6
  $0 -c db_adv -v 12.8.6 -t 12.8.6 -s
EOF
}

# Parse arguments
COMPONENT=""
VERSION=""
TAG=""
IMAGE_NAME=""
BINARIES_ROOT=""
JDKVERSION=21
OEVERSION=""
BUILD_DEVCONTAINER=0
BUILD_SPORTS2020=0

while getopts ":c:v:t:i:b:j:o:dsh" opt; do
  case $opt in
    c) COMPONENT="$OPTARG";;
    v) VERSION="$OPTARG";;
    t) TAG="$OPTARG";;
    i) IMAGE_NAME="$OPTARG";;
    b) BINARIES_ROOT="$OPTARG";;
    j) JDKVERSION="$OPTARG";;
    o) OEVERSION="$OPTARG";;
    d) BUILD_DEVCONTAINER=1;;
    s) BUILD_SPORTS2020=1;;
    h) usage; exit 0;;
    *) usage; exit 1;;
  esac
done

# Validate required arguments
if [[ -z "$COMPONENT" || -z "$VERSION" ]]; then
  echo "Error: -c and -v are required" >&2
  usage
  exit 1
fi

# Validate component
if [[ "$COMPONENT" != "compiler" && "$COMPONENT" != "db_adv" && "$COMPONENT" != "pas_dev" && "$COMPONENT" != "pas_base" && "$COMPONENT" != "pas_orads" ]]; then
  echo "Error: Invalid component '$COMPONENT'. Allowed: compiler, db_adv, pas_dev, pas_base, pas_orads" >&2
  exit 1
fi

# Validate devcontainer option
if [[ $BUILD_DEVCONTAINER -eq 1 && "$COMPONENT" != "compiler" ]]; then
  echo "Error: The -d (devcontainer) option can only be used with -c compiler" >&2
  exit 1
fi

# Validate sports2020 option
if [[ $BUILD_SPORTS2020 -eq 1 && "$COMPONENT" != "db_adv" ]]; then
  echo "Error: The -s (sports2020-db) option can only be used with -c db_adv" >&2
  exit 1
fi

# Parse version
if [[ ! "$VERSION" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
  echo "Error: Version must be MAJOR.MINOR.PATCH (e.g., 12.8.6). Got: $VERSION" >&2
  exit 1
fi
MAJOR="${BASH_REMATCH[1]}"
MINOR="${BASH_REMATCH[2]}"
PATCH="${BASH_REMATCH[3]}"
SERIES="${MAJOR}.${MINOR}"

# Default tag to version if not provided
if [[ -z "$TAG" ]]; then
  TAG="$VERSION"
fi

# Set defaults per component
case "$COMPONENT" in
  compiler)
    [[ -z "$IMAGE_NAME" ]] && IMAGE_NAME="rdroge/oe_compiler"
    CTYPE="compiler"
    ;;
  db_adv)
    [[ -z "$IMAGE_NAME" ]] && IMAGE_NAME="rdroge/oe_db_adv"
    CTYPE="db"
    ;;
  pas_dev)
    [[ -z "$IMAGE_NAME" ]] && IMAGE_NAME="rdroge/oe_pas_dev"
    CTYPE="pas"
    ;;
  pas_base)
    [[ -z "$IMAGE_NAME" ]] && IMAGE_NAME="rdroge/oe_pas_base"
    CTYPE="pas"
    ;;
  pas_orads)
    [[ -z "$IMAGE_NAME" ]] && IMAGE_NAME="rdroge/oe_pas_orads"
    CTYPE="pas"
    ;;
esac

# Map OEVERSION if not provided
if [[ -z "$OEVERSION" ]]; then
  case "$SERIES" in
    12.2) OEVERSION="122";;
    12.7) OEVERSION="127";;
    12.8) OEVERSION="128";;
    *) echo "Warning: OEVERSION not mapped for series $SERIES; leaving empty.";;
  esac
fi

# Get script directory and root
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Validate response.ini exists before building (skip for pas_orads - it uses base image)
if [[ "$COMPONENT" != "pas_orads" ]]; then
  RESPONSE_INI="$ROOT/$COMPONENT/response.ini"
  if [[ ! -f "$RESPONSE_INI" ]]; then
    echo "Error: response.ini not found at: $RESPONSE_INI" >&2
    echo "" >&2
    echo "Please configure OpenEdge control codes in the response.ini file before building." >&2
    echo "See the 'Configure control codes' section in README.md for details." >&2
    exit 1
  fi
fi

# Prepare installers
PREP_SCRIPT="$SCRIPT_DIR/prepare-installers.sh"
if [[ ! -f "$PREP_SCRIPT" ]]; then
  echo "Error: Missing $PREP_SCRIPT" >&2
  exit 1
fi

PREP_ARGS="-c $COMPONENT -v $VERSION"
if [[ -n "$BINARIES_ROOT" ]]; then
  PREP_ARGS="$PREP_ARGS -b $BINARIES_ROOT"
fi

echo "Preparing installers..."
bash "$PREP_SCRIPT" $PREP_ARGS

# Build docker image
DOCKERFILE="$ROOT/$COMPONENT/Dockerfile"
if [[ ! -f "$DOCKERFILE" ]]; then
  echo "Error: Dockerfile not found: $DOCKERFILE" >&2
  exit 1
fi

# Resolve JDK version from jdkversions.json
JDK_JSON="$ROOT/jdkversions.json"
if [[ ! -f "$JDK_JSON" ]]; then
  echo "Error: Missing jdkversions.json at $JDK_JSON" >&2
  exit 1
fi

if [[ -z "$OEVERSION" ]]; then
  echo "Error: OEVERSION is empty; cannot determine JDK version mapping" >&2
  exit 1
fi

JDK_KEY="jdk${OEVERSION}"
JDK_VERSION_VALUE=$(jq -r ".${JDK_KEY}" "$JDK_JSON")
if [[ -z "$JDK_VERSION_VALUE" || "$JDK_VERSION_VALUE" == "null" ]]; then
  echo "Error: No JDK mapping found for key '$JDK_KEY' in $JDK_JSON" >&2
  exit 1
fi

# Create temporary Dockerfile with placeholders replaced
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT
TEMP_DOCKERFILE="$TEMP_DIR/Dockerfile"
sed "s/JDKVERSION/$JDK_VERSION_VALUE/g" "$DOCKERFILE" > "$TEMP_DOCKERFILE"

# For pas_orads, replace the base image tag with the current tag
if [[ "$COMPONENT" == "pas_orads" ]]; then
  sed -i "s|rdroge/oe_pas_base:latest|rdroge/oe_pas_base:$TAG|g" "$TEMP_DOCKERFILE"
fi

echo "Using JDK version: $JDK_VERSION_VALUE (key: $JDK_KEY)"

TAG_REF="${IMAGE_NAME}:${TAG}"
echo "Building $TAG_REF using $DOCKERFILE"

# Build the image
docker build -f "$TEMP_DOCKERFILE" \
  --build-arg CTYPE="$CTYPE" \
  --build-arg JDKVERSION="$JDKVERSION" \
  --build-arg OEVERSION="$OEVERSION" \
  -t "$TAG_REF" \
  "$ROOT"

echo "Done: $TAG_REF"

# Build devcontainer if requested
if [[ $BUILD_DEVCONTAINER -eq 1 ]]; then
  echo ""
  echo "Building devcontainer using local compiler image: $TAG_REF"
  
  DEVCONTAINER_DIR="$ROOT/devcontainer"
  DEVCONTAINER_DOCKERFILE="$DEVCONTAINER_DIR/Dockerfile"
  
  if [[ ! -f "$DEVCONTAINER_DOCKERFILE" ]]; then
    echo "Error: Devcontainer Dockerfile not found: $DEVCONTAINER_DOCKERFILE" >&2
    exit 1
  fi
  
  # Create temporary Dockerfile with local base image
  DEV_TEMP_DIR=$(mktemp -d)
  trap "rm -rf $DEV_TEMP_DIR" EXIT
  DEV_TEMP_DOCKERFILE="$DEV_TEMP_DIR/Dockerfile"
  
  # Replace the FROM line to use the local compiler image
  ORIGINAL_FROM="FROM docker.io/progressofficial/oe_compiler:latest"
  NEW_FROM="FROM $TAG_REF"
  
  echo "Replacing base image:"
  echo "  Original: $ORIGINAL_FROM"
  echo "  New:      $NEW_FROM"
  
  sed "s|$ORIGINAL_FROM|$NEW_FROM|g" "$DEVCONTAINER_DOCKERFILE" > "$DEV_TEMP_DOCKERFILE"
  
  # Verify the replacement worked
  FIRST_FROM=$(grep "^FROM" "$DEV_TEMP_DOCKERFILE" | head -1)
  echo "  Verified: $FIRST_FROM"
  
  DEV_IMAGE_NAME="rdroge/oe_devcontainer"
  DEV_TAG_REF="${DEV_IMAGE_NAME}:${TAG}"
  
  echo "Building $DEV_TAG_REF using $DEVCONTAINER_DOCKERFILE"
  
  docker build -f "$DEV_TEMP_DOCKERFILE" \
    -t "$DEV_TAG_REF" \
    "$ROOT"
  
  echo "Done: $DEV_TAG_REF"
fi

# Build sports2020-db if requested
if [[ $BUILD_SPORTS2020 -eq 1 ]]; then
  echo ""
  echo "Building sports2020-db using local db_adv image: $TAG_REF"
  
  SPORTS2020_DIR="$ROOT/sports2020-db"
  SPORTS2020_DOCKERFILE="$SPORTS2020_DIR/Dockerfile"
  
  if [[ ! -f "$SPORTS2020_DOCKERFILE" ]]; then
    echo "Error: Sports2020-db Dockerfile not found: $SPORTS2020_DOCKERFILE" >&2
    exit 1
  fi
  
  # Create temporary Dockerfile with local base image
  SPORTS_TEMP_DIR=$(mktemp -d)
  trap "rm -rf $SPORTS_TEMP_DIR" EXIT
  SPORTS_TEMP_DOCKERFILE="$SPORTS_TEMP_DIR/Dockerfile"
  
  # Replace the FROM line to use the local db_adv image
  ORIGINAL_FROM="FROM progressofficial/oe_db_adv:latest AS install"
  NEW_FROM="FROM $TAG_REF AS install"
  
  echo "Replacing base image:"
  echo "  Original: $ORIGINAL_FROM"
  echo "  New:      $NEW_FROM"
  
  sed "s|$ORIGINAL_FROM|$NEW_FROM|g" "$SPORTS2020_DOCKERFILE" > "$SPORTS_TEMP_DOCKERFILE"
  
  # Verify the replacement worked
  FIRST_FROM=$(grep "^FROM" "$SPORTS_TEMP_DOCKERFILE" | head -1)
  echo "  Verified: $FIRST_FROM"
  
  SPORTS_IMAGE_NAME="rdroge/oe_sports2020_db"
  SPORTS_TAG_REF="${SPORTS_IMAGE_NAME}:${TAG}"
  
  echo "Building $SPORTS_TAG_REF using $SPORTS2020_DOCKERFILE"
  
  docker build -f "$SPORTS_TEMP_DOCKERFILE" \
    -t "$SPORTS_TAG_REF" \
    "$SPORTS2020_DIR"
  
  echo "Done: $SPORTS_TAG_REF"
fi
