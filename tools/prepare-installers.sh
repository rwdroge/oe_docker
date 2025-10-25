#!/usr/bin/env bash
set -euo pipefail

usage(){
  echo "Usage: $0 -c <compiler|db_adv|pas_dev> -v <12.8.x> [-b <binariesRoot>]" >&2
}

COMPONENT=""; VERSION=""; BINROOT="$(cd "$(dirname "$0")"/.. && pwd)/binaries/oe"
while getopts ":c:v:b:" opt; do
  case $opt in
    c) COMPONENT="$OPTARG";;
    v) VERSION="$OPTARG";;
    b) BINROOT="$OPTARG";;
    *) usage; exit 1;;
  esac
done

if [[ -z "$COMPONENT" || -z "$VERSION" ]]; then usage; exit 1; fi
if [[ "$COMPONENT" != "compiler" && "$COMPONENT" != "db_adv" && "$COMPONENT" != "pas_dev" ]]; then
  echo "Invalid component: $COMPONENT" >&2; exit 1
fi


if [[ ! "$VERSION" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
  echo "Version must be MAJOR.MINOR.PATCH (e.g. 12.8.6). Got: $VERSION" >&2; exit 1
fi
MAJOR="${BASH_REMATCH[1]}"; MINOR="${BASH_REMATCH[2]}"; PATCH="${BASH_REMATCH[3]}"
SERIES="${MAJOR}.${MINOR}"

ROOT="$(cd "$(dirname "$0")"/.. && pwd)"
COMP_DIR="$ROOT/$COMPONENT"
INST_DIR="$ROOT/installer"
rm -rf "$INST_DIR" && mkdir -p "$INST_DIR"

SINGLE_TAR="$BINROOT/$SERIES/PROGRESS_OE_${VERSION}_LNX_64.tar.gz"
BASE_TAR="$BINROOT/$SERIES/PROGRESS_OE_${MAJOR}.${MINOR}_LNX_64.tar.gz"
PATCH_TAR="$BINROOT/$SERIES/PROGRESS_OE_${VERSION}_LNX_64.tar.gz"

if [[ "$SERIES" == "12.8" ]]; then
  if [[ $PATCH -lt 4 || $PATCH -gt 8 ]]; then
    [[ -f "$SINGLE_TAR" ]] || { echo "Missing $SINGLE_TAR" >&2; exit 1; }
    cp "$SINGLE_TAR" "$INST_DIR/PROGRESS_OE.tar.gz"
    # Create a valid empty patch tarball
    tmpdir=$(mktemp -d)
    tar -czf "$INST_DIR/PROGRESS_PATCH_OE.tar.gz" -C "$tmpdir" .
    rm -rf "$tmpdir"
    echo "Prepared single installer for $COMPONENT $VERSION (created empty patch tar)"
  else
    [[ -f "$BASE_TAR"  ]] || { echo "Missing $BASE_TAR" >&2; exit 1; }
    [[ -f "$PATCH_TAR" ]] || { echo "Missing $PATCH_TAR" >&2; exit 1; }
    cp "$BASE_TAR"  "$INST_DIR/PROGRESS_OE.tar.gz"
    cp "$PATCH_TAR" "$INST_DIR/PROGRESS_PATCH_OE.tar.gz"
    echo "Prepared base+patch installers for $COMPONENT $VERSION"
  fi
else
  [[ -f "$SINGLE_TAR" ]] || { echo "Missing $SINGLE_TAR" >&2; exit 1; }
  cp "$SINGLE_TAR" "$INST_DIR/PROGRESS_OE.tar.gz"
  # Create a valid empty patch tarball
  tmpdir=$(mktemp -d)
  tar -czf "$INST_DIR/PROGRESS_PATCH_OE.tar.gz" -C "$tmpdir" .
  rm -rf "$tmpdir"
  echo "Prepared single installer for $COMPONENT $VERSION (created empty patch tar; non-12.8 series)"
fi

echo "Output directory: $INST_DIR"
