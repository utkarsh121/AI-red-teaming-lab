#!/bin/bash

# =============================================================================
# AI Red Team Lab - Launcher Installer
# =============================================================================
# Course   : Certified AI Penetration Tester - Red Team (CAIPT-RT)
# File     : lab_installer.sh
# Purpose  : This is the ONLY file you need to download manually.
#            It fetches the full installer from GitHub and runs it.
#
# Usage:
#   1. Download this file to the desktop of the target VM
#   2. Open a terminal and run:
#        bash lab_installer.sh
#
# That is all. Everything else is automatic.
# =============================================================================

# Exit immediately if any command fails
set -e

echo ""
echo "============================================="
echo "  AI Red Team Lab - Starting Installation"
echo "============================================="
echo ""
echo "Fetching main installer from GitHub..."
echo ""

# -----------------------------------------------------------------------------
# Download the main installer from GitHub
# -----------------------------------------------------------------------------
# curl flags:
#   -f : fail silently on HTTP errors (returns error code instead of HTML)
#   -s : silent mode (no progress bar)
#   -S : show error if -s is used and something goes wrong
#   -L : follow redirects (GitHub sometimes redirects raw URLs)
#   -o : save output to this filename
# -----------------------------------------------------------------------------

curl -fsSL \
    "https://raw.githubusercontent.com/utkarsh121/AI-red-teaming-lab/main/lab_installer_main.sh" \
    -o "$HOME/Desktop/lab_installer_main.sh"

# Confirm the download succeeded
if [ ! -f "$HOME/Desktop/lab_installer_main.sh" ]; then
    echo "ERROR: Failed to download lab_installer_main.sh from GitHub."
    echo "Please check your internet connection and try again."
    exit 1
fi

echo "Main installer downloaded successfully."
echo ""
echo "Making it executable and launching..."
echo ""

# Make the main installer executable
chmod +x "$HOME/Desktop/lab_installer_main.sh"

# Run the main installer with bash explicitly
bash "$HOME/Desktop/lab_installer_main.sh"
