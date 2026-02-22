#!/bin/bash

# =============================================================================
# AI Red Team Lab - Launcher Installer
# =============================================================================
# Course   : Certified AI Penetration Tester - Red Team (CAIPT-RT)
# File     : lab_installer.sh
# Purpose  : This is the ONLY file you need to download manually.
#            It installs curl if missing, then fetches the full installer
#            from GitHub and runs it.
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

# -----------------------------------------------------------------------------
# STEP 0: Make sure curl is installed
# -----------------------------------------------------------------------------
# Fresh Ubuntu installs sometimes do not include curl.
# We need curl to download the main installer from GitHub.
# This check installs it if missing before anything else runs.
# -----------------------------------------------------------------------------

if ! command -v curl &> /dev/null; then
    echo "curl not found. Installing curl first..."
    echo ""
    sudo apt-get update -y
    sudo apt-get install -y curl
    echo ""
    echo "curl installed successfully."
    echo ""
else
    echo "curl is already installed. Continuing..."
    echo ""
fi

# -----------------------------------------------------------------------------
# STEP 1: Download the main installer from GitHub
# -----------------------------------------------------------------------------
# curl flags:
#   -f : fail on HTTP errors
#   -s : silent mode
#   -S : show error if silent mode is on and something goes wrong
#   -L : follow redirects
#   -o : save to this filename
# -----------------------------------------------------------------------------

echo "Fetching main installer from GitHub..."
echo ""

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
