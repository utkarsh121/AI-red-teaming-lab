#!/bin/bash

# =============================================================================
# AI Red Team Lab - macOS Launcher Installer
# =============================================================================
# Course   : Certified AI Penetration Tester - Red Team (CAIPT-RT)
# File     : mac_lab_installer.sh
# Platform : macOS 12 Monterey or later
#
# Purpose  : This is the ONLY file you need to download manually.
#            It checks for curl, then fetches and runs the full installer
#            from GitHub.
#
# Usage:
#   1. Download this file to your Desktop
#   2. Open Terminal and run:
#        bash mac_lab_installer.sh
# =============================================================================

set -e

echo ""
echo "============================================="
echo "  AI Red Team Lab - macOS Installation"
echo "============================================="
echo ""

# -----------------------------------------------------------------------------
# STEP 0: Ensure curl is available
# -----------------------------------------------------------------------------
# curl is built into every macOS version. This check is a safety net.
# -----------------------------------------------------------------------------

if ! command -v curl &> /dev/null; then
    echo "ERROR: curl not found. Please install Xcode Command Line Tools:"
    echo "  xcode-select --install"
    echo "Then re-run this script."
    exit 1
fi

echo "--> curl found. Continuing..."
echo ""

# -----------------------------------------------------------------------------
# STEP 1: Download the main installer from GitHub
# -----------------------------------------------------------------------------

echo "--> Fetching main installer from GitHub..."
echo ""

curl -fsSL \
    "https://raw.githubusercontent.com/utkarsh121/AI-red-teaming-lab/main/mac_lab_installer_main.sh" \
    -o "$HOME/Desktop/mac_lab_installer_main.sh"

if [ ! -f "$HOME/Desktop/mac_lab_installer_main.sh" ]; then
    echo "ERROR: Failed to download mac_lab_installer_main.sh from GitHub."
    echo "Please check your internet connection and try again."
    exit 1
fi

echo "--> Main installer downloaded successfully."
echo ""
echo "--> Making it executable and launching..."
echo ""

chmod +x "$HOME/Desktop/mac_lab_installer_main.sh"
bash "$HOME/Desktop/mac_lab_installer_main.sh"
