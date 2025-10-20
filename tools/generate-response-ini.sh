#!/bin/bash
# Wrapper script for Generate-ResponseIni.ps1
# Provides a convenient bash interface for Linux/macOS users

set -e

# Check if pwsh is installed
if ! command -v pwsh &> /dev/null; then
    echo "Error: PowerShell Core (pwsh) is not installed."
    echo ""
    echo "Please install PowerShell Core:"
    echo "  Ubuntu/Debian: sudo apt-get install -y powershell"
    echo "  macOS: brew install --cask powershell"
    echo "  Other: https://github.com/PowerShell/PowerShell#get-powershell"
    exit 1
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PS_SCRIPT="$SCRIPT_DIR/Generate-ResponseIni.ps1"

# Check if PowerShell script exists
if [ ! -f "$PS_SCRIPT" ]; then
    echo "Error: Generate-ResponseIni.ps1 not found at $PS_SCRIPT"
    exit 1
fi

# Pass all arguments to PowerShell script
pwsh -File "$PS_SCRIPT" "$@"
