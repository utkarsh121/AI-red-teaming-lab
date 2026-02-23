# =============================================================================
# AI Red Team Lab - Windows Launcher Installer
# =============================================================================
# Course   : Certified AI Penetration Tester - Red Team (CAIPT-RT)
# File     : windows_lab_installer.ps1
# Platform : Windows 10 / Windows 11
#
# Purpose  : This is the ONLY file you need to download manually.
#            It sets the PowerShell execution policy, installs curl if needed,
#            then fetches and runs the full installer from GitHub.
#
# Usage:
#   1. Download this file to your Desktop
#   2. Right-click the file and select "Run with PowerShell"
#      OR open PowerShell and run:
#        powershell -ExecutionPolicy Bypass -File windows_lab_installer.ps1
#
# That is all. Everything else is automatic.
# =============================================================================

Write-Host ""
Write-Host "=============================================" -ForegroundColor Red
Write-Host "  AI Red Team Lab - Windows Installation"    -ForegroundColor Red
Write-Host "=============================================" -ForegroundColor Red
Write-Host ""

# -----------------------------------------------------------------------------
# STEP 0: Set PowerShell Execution Policy
# -----------------------------------------------------------------------------
# By default Windows blocks PowerShell scripts from running as a security
# measure. We set the policy to RemoteSigned for the current user only.
# This allows locally created scripts to run without affecting system policy.
# -----------------------------------------------------------------------------

Write-Host "--> Setting PowerShell execution policy for current user..." -ForegroundColor Yellow
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
Write-Host "--> Execution policy set." -ForegroundColor Green
Write-Host ""

# -----------------------------------------------------------------------------
# STEP 1: Check curl is available
# -----------------------------------------------------------------------------
# curl is built into Windows 10 and 11 (version 1803+).
# If for any reason it is missing, we use PowerShell's Invoke-WebRequest
# as a fallback to download the main installer.
# -----------------------------------------------------------------------------

$DesktopPath = [Environment]::GetFolderPath("Desktop")
$MainInstaller = "$DesktopPath\windows_lab_installer_main.ps1"
$GitHubRaw = "https://raw.githubusercontent.com/utkarsh121/AI-red-teaming-lab/main"

Write-Host "--> Downloading main installer from GitHub..." -ForegroundColor Yellow
Write-Host ""

try {
    # Try curl first (available on Windows 10/11)
    curl.exe -fsSL "$GitHubRaw/windows_lab_installer_main.ps1" -o "$MainInstaller"
    Write-Host "--> Main installer downloaded via curl." -ForegroundColor Green
} catch {
    # Fall back to PowerShell native download
    Write-Host "--> curl not available, using PowerShell download..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri "$GitHubRaw/windows_lab_installer_main.ps1" -OutFile "$MainInstaller"
    Write-Host "--> Main installer downloaded via PowerShell." -ForegroundColor Green
}

# Verify download succeeded
if (-Not (Test-Path $MainInstaller)) {
    Write-Host "ERROR: Failed to download windows_lab_installer_main.ps1" -ForegroundColor Red
    Write-Host "Please check your internet connection and try again." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "--> Launching main installer..." -ForegroundColor Yellow
Write-Host ""

# Run the main installer
& PowerShell -ExecutionPolicy Bypass -File "$MainInstaller"
