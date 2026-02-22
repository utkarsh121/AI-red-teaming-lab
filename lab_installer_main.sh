#!/bin/bash

# =============================================================================
# AI Red Team Lab - Main Installer
# =============================================================================
# Course   : Certified AI Penetration Tester - Red Team (CAIPT-RT)
# File     : lab_installer_main.sh
# Target OS: Ubuntu 24.04 LTS
# Author   : Lab Assistant
#
# Purpose:
#   Full automated setup of the AI Red Team Lab environment including:
#   - Python virtual environment and all required libraries
#   - Lab folder structure on the Desktop
#   - Dataset downloads from UCI ML Repository
#   - Notebook downloads from GitHub
#   - Jupyter configuration with hardcoded token and default notebook
#   - Systemd service for auto-start on boot
#   - Desktop HTML shortcut for one-click browser access
#   - Backup start_jupyter.sh on desktop
#   - Verbose log file on desktop for review
#
# Usage:
#   bash lab_installer_main.sh
#
# DO NOT run with sh. Must be run with bash explicitly.
# =============================================================================

# =============================================================================
# STRICT MODE
# =============================================================================
# -e : exit immediately if any command returns a non-zero exit code
# -u : treat unset variables as errors
# -o pipefail : if any command in a pipe fails, the whole pipe fails
# This prevents the script from silently continuing after an error
# =============================================================================
set -euo pipefail

# =============================================================================
# CONFIGURATION VARIABLES
# =============================================================================
# All key settings are defined here at the top so they are easy to find
# and modify if needed for future versions of the lab.
# =============================================================================

# The user running this installer (captured dynamically)
LAB_USER="$USER"
LAB_HOME="$HOME"

# Virtual environment location
VENV_PATH="$LAB_HOME/lab_env"

# Lab folder on the desktop
LAB_DIR="$LAB_HOME/Desktop/AI_Red_Team_Lab"

# Log file location (on desktop for easy access)
LOG_FILE="$LAB_HOME/Desktop/lab_installer_log.txt"

# Jupyter hardcoded token (students use this to access Jupyter)
JUPYTER_TOKEN="airedteamlab"

# Jupyter port
JUPYTER_PORT="8888"

# Jupyter URL that will go in the desktop shortcut
JUPYTER_URL="http://localhost:${JUPYTER_PORT}/lab?token=${JUPYTER_TOKEN}"

# GitHub repository raw base URL for downloading notebooks
GITHUB_RAW="https://raw.githubusercontent.com/utkarsh121/AI-red-teaming-lab/main"

# Notebook filenames to download
NOTEBOOKS=(
    "START_HERE.ipynb"
    "Lab1_Evasion_Attack.ipynb"
    "Lab2_Poisoning_Attack.ipynb"
    "Lab3_Inference_Attack.ipynb"
    "Lab4_Extraction_Attack.ipynb"
)

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

# Print a clearly visible section header to terminal only
print_header() {
    echo ""
    echo "============================================="
    echo "  $1"
    echo "============================================="
}

# Print a status message to terminal AND write to log file
print_status() {
    echo "--> $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Print an error and exit
print_error() {
    echo ""
    echo "ERROR: $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$LOG_FILE"
    echo ""
    echo "Installation failed. Check the log file for details:"
    echo "  $LOG_FILE"
    exit 1
}

# Write a section header to the log file
log_header() {
    echo "" >> "$LOG_FILE"
    echo "=============================================" >> "$LOG_FILE"
    echo "  $1" >> "$LOG_FILE"
    echo "=============================================" >> "$LOG_FILE"
}

# =============================================================================
# SECTION 1: SYSTEM UPDATE AND UPGRADE
# =============================================================================
# We do this BEFORE starting the log file because apt output is extremely
# noisy and would make the log file hard to read. The log starts after this.
# Students and instructors can still see apt output in the terminal.
# =============================================================================

print_header "STEP 1: Updating System Packages (not logged - too noisy)"
echo "This may take a few minutes. Please wait..."
echo ""

sudo apt-get update -y
sudo apt-get upgrade -y

echo ""
echo "System update complete. Starting detailed log now."
echo ""

# =============================================================================
# START THE LOG FILE
# =============================================================================
# Everything from this point is logged to the desktop log file.
# We use tee in some places to print to both terminal and log simultaneously.
# =============================================================================

# Create or overwrite the log file with a header
cat > "$LOG_FILE" << EOF
=============================================================================
AI Red Team Lab - Installation Log
=============================================================================
Date        : $(date)
User        : $LAB_USER
Home        : $LAB_HOME
Lab folder  : $LAB_DIR
Virtual env : $VENV_PATH
Jupyter URL : $JUPYTER_URL
GitHub repo : $GITHUB_RAW
=============================================================================

EOF

print_status "Log file started at: $LOG_FILE"

# =============================================================================
# SECTION 2: INSTALL SYSTEM DEPENDENCIES
# =============================================================================
# Install all required system-level packages.
# These are installed system-wide (not in the venv) because they are
# OS-level tools, not Python libraries.
#
#   python3        : the Python interpreter
#   python3-pip    : pip package manager for Python
#   python3-venv   : tool to create Python virtual environments
#   python3-full   : complete Python installation
#   curl           : downloads files from URLs
#   git            : version control (useful for students)
#   unzip          : extracts zip archives (needed for SMS dataset)
# =============================================================================

print_header "STEP 2: Installing System Dependencies"
log_header "STEP 2: Installing System Dependencies"

print_status "Installing Python and system tools..."

sudo apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-full \
    curl \
    git \
    unzip >> "$LOG_FILE" 2>&1

print_status "System dependencies installed successfully."

# Log Python version for reference
PYTHON_VERSION=$(python3 --version)
print_status "Python version: $PYTHON_VERSION"

# =============================================================================
# SECTION 3: CREATE PYTHON VIRTUAL ENVIRONMENT
# =============================================================================
# Ubuntu 24.04 enforces PEP 668 which prevents installing Python libraries
# directly into the system Python using pip. The fix is a virtual environment.
#
# A virtual environment is an isolated Python workspace. All libraries are
# installed inside it, never touching the system Python installation.
#
# We use . (dot) instead of 'source' for POSIX compatibility even in bash.
# =============================================================================

print_header "STEP 3: Creating Python Virtual Environment"
log_header "STEP 3: Creating Python Virtual Environment"

if [ ! -d "$VENV_PATH" ]; then
    print_status "Creating virtual environment at: $VENV_PATH"
    python3 -m venv "$VENV_PATH" >> "$LOG_FILE" 2>&1
    print_status "Virtual environment created successfully."
else
    print_status "Virtual environment already exists at: $VENV_PATH — skipping creation."
fi

# Activate the virtual environment
# Using . (dot) instead of source for bash compatibility
print_status "Activating virtual environment..."
. "$VENV_PATH/bin/activate"
print_status "Virtual environment activated."

# =============================================================================
# SECTION 4: UPGRADE PIP
# =============================================================================
# Always upgrade pip first to avoid installation errors caused by
# an outdated pip version.
# =============================================================================

print_header "STEP 4: Upgrading pip"
log_header "STEP 4: Upgrading pip"

print_status "Upgrading pip to latest version..."
pip install --upgrade pip >> "$LOG_FILE" 2>&1
print_status "pip upgraded successfully."

# =============================================================================
# SECTION 5: INSTALL PYTHON LIBRARIES
# =============================================================================
# All libraries are installed inside the virtual environment.
#
#   adversarial-robustness-toolbox : IBM's ART - the core attack toolkit
#   scikit-learn                   : builds and trains ML models
#   pandas                         : loads and handles datasets
#   numpy                          : numerical computing foundation
#   jupyterlab                     : browser-based notebook interface
#   matplotlib                     : charts and graphs
#   seaborn                        : prettier charts built on matplotlib
#   ipywidgets                     : interactive widgets in notebooks
# =============================================================================

print_header "STEP 5: Installing Python Libraries"
log_header "STEP 5: Installing Python Libraries"

print_status "Installing all required Python libraries..."
print_status "(This may take 3-5 minutes depending on connection speed)"

pip install \
    adversarial-robustness-toolbox \
    scikit-learn \
    pandas \
    numpy \
    jupyterlab \
    matplotlib \
    seaborn \
    ipywidgets >> "$LOG_FILE" 2>&1

print_status "All Python libraries installed successfully."

# Log installed versions for reference
print_status "Logging installed library versions..."
python3 -c "
import sklearn, numpy, pandas, matplotlib, art
versions = {
    'scikit-learn' : sklearn.__version__,
    'numpy'        : numpy.__version__,
    'pandas'       : pandas.__version__,
    'matplotlib'   : matplotlib.__version__,
    'ART'          : art.__version__,
}
for lib, ver in versions.items():
    print(f'  {lib:<20}: {ver}')
" | tee -a "$LOG_FILE"

# =============================================================================
# SECTION 6: CREATE LAB FOLDER STRUCTURE
# =============================================================================
# Creates a tidy folder on the desktop:
#   AI_Red_Team_Lab/
#     datasets/   - data files the models learn from
#     notebooks/  - the Jupyter lab notebooks
#     outputs/    - student results, charts, reflection answers
# =============================================================================

print_header "STEP 6: Creating Lab Folder Structure"
log_header "STEP 6: Creating Lab Folder Structure"

mkdir -p "$LAB_DIR/datasets"
mkdir -p "$LAB_DIR/notebooks"
mkdir -p "$LAB_DIR/outputs"

print_status "Lab folder structure created at: $LAB_DIR"

# =============================================================================
# SECTION 7: DOWNLOAD DATASETS
# =============================================================================
# Downloads both datasets used across the four attack labs.
#
# Nursery dataset  : used in Lab 3 (Inference) and Lab 4 (Extraction)
#                    Source: UCI ML Repository
#
# SMS Spam dataset : used in Lab 1 (Evasion) and Lab 2 (Poisoning)
#                    Source: UCI ML Repository
#                    Comes as a zip - we extract and clean up afterwards
# =============================================================================

print_header "STEP 7: Downloading Datasets"
log_header "STEP 7: Downloading Datasets"

# --- Nursery Dataset ---
print_status "Downloading Nursery dataset..."
curl -fsSL \
    "https://archive.ics.uci.edu/ml/machine-learning-databases/nursery/nursery.data" \
    -o "$LAB_DIR/datasets/nursery.data" >> "$LOG_FILE" 2>&1

if [ -f "$LAB_DIR/datasets/nursery.data" ]; then
    NURSERY_SIZE=$(wc -l < "$LAB_DIR/datasets/nursery.data")
    print_status "Nursery dataset downloaded: $NURSERY_SIZE records."
else
    print_error "Nursery dataset download failed. Check your internet connection."
fi

# --- SMS Spam Dataset ---
print_status "Downloading SMS Spam dataset (zip)..."
curl -fsSL \
    "https://archive.ics.uci.edu/ml/machine-learning-databases/00228/smsspamcollection.zip" \
    -o "$LAB_DIR/datasets/sms_spam.zip" >> "$LOG_FILE" 2>&1

print_status "Unzipping SMS Spam dataset..."
unzip -o "$LAB_DIR/datasets/sms_spam.zip" \
    -d "$LAB_DIR/datasets/" >> "$LOG_FILE" 2>&1

# Clean up files we do not need
# The zip itself is no longer needed after extraction
# The readme is not useful to students during lab work
print_status "Cleaning up zip and readme files..."
rm -f "$LAB_DIR/datasets/sms_spam.zip"
rm -f "$LAB_DIR/datasets/readme"

if [ -f "$LAB_DIR/datasets/SMSSpamCollection" ]; then
    SMS_SIZE=$(wc -l < "$LAB_DIR/datasets/SMSSpamCollection")
    print_status "SMS Spam dataset ready: $SMS_SIZE messages."
else
    print_error "SMS Spam dataset extraction failed."
fi

# =============================================================================
# SECTION 8: DOWNLOAD NOTEBOOKS FROM GITHUB
# =============================================================================
# Downloads all five lab notebooks directly from the public GitHub repo
# into the notebooks folder so students have everything ready on launch.
#
# If a notebook fails to download, we warn but do not stop the installer
# because the rest of the environment is still useful.
# =============================================================================

print_header "STEP 8: Downloading Lab Notebooks from GitHub"
log_header "STEP 8: Downloading Lab Notebooks from GitHub"

print_status "Downloading notebooks from: $GITHUB_RAW"

for NOTEBOOK in "${NOTEBOOKS[@]}"; do
    print_status "  Downloading $NOTEBOOK..."

    curl -fsSL \
        "$GITHUB_RAW/$NOTEBOOK" \
        -o "$LAB_DIR/notebooks/$NOTEBOOK" >> "$LOG_FILE" 2>&1

    if [ -f "$LAB_DIR/notebooks/$NOTEBOOK" ]; then
        print_status "  $NOTEBOOK downloaded successfully."
    else
        # Warn but do not exit - instructor can copy notebooks manually
        echo "  WARNING: Failed to download $NOTEBOOK" | tee -a "$LOG_FILE"
        echo "  You can manually copy it from GitHub to: $LAB_DIR/notebooks/"
    fi
done

print_status "All notebooks downloaded."

# =============================================================================
# SECTION 9: CONFIGURE JUPYTER
# =============================================================================
# We configure Jupyter with:
#
# 1. A hardcoded token so the URL never changes between restarts
#    Token: airedteamlab
#    Full URL: http://localhost:8888/lab?token=airedteamlab
#
# 2. A default URL that opens START_HERE.ipynb automatically
#    So students land on the welcome page without navigating
#
# 3. No browser auto-open (the desktop shortcut handles this)
#    Because when Jupyter runs as a systemd service there is no
#    display to open a browser on at service start time
#
# The config file lives at: ~/.jupyter/jupyter_lab_configuration.py
# =============================================================================

print_header "STEP 9: Configuring Jupyter"
log_header "STEP 9: Configuring Jupyter"

# Create the Jupyter config directory if it does not exist
mkdir -p "$LAB_HOME/.jupyter"

print_status "Writing Jupyter configuration..."

cat > "$LAB_HOME/.jupyter/jupyter_lab_configuration.py" << EOF
# =============================================================================
# Jupyter Lab Configuration
# AI Red Team Lab - CAIPT-RT Course
# Generated by lab_installer_main.sh
# =============================================================================

# Hardcoded token - students use this to access Jupyter
# URL: http://localhost:8888/lab?token=airedteamlab
c.ServerApp.token = '${JUPYTER_TOKEN}'

# Do not open a browser automatically when Jupyter starts
# The desktop shortcut handles browser opening
c.ServerApp.open_browser = False

# The port Jupyter listens on
c.ServerApp.port = ${JUPYTER_PORT}

# The directory Jupyter serves files from
# Set to the notebooks folder so students see notebooks immediately
c.ServerApp.root_dir = '${LAB_DIR}/notebooks'

# Default URL - opens START_HERE.ipynb automatically when Jupyter loads
# This means students land on the welcome notebook without navigating
c.ServerApp.default_url = '/lab/tree/START_HERE.ipynb'

# Allow connections from localhost only (security best practice for lab VMs)
c.ServerApp.ip = '127.0.0.1'

# Disable password requirement (token is the only auth needed)
c.ServerApp.password = ''
EOF

print_status "Jupyter configuration written to: $LAB_HOME/.jupyter/jupyter_lab_configuration.py"
print_status "Token set to: $JUPYTER_TOKEN"
print_status "Default notebook set to: START_HERE.ipynb"

# =============================================================================
# SECTION 10: CREATE SYSTEMD SERVICE FOR AUTO-START ON BOOT
# =============================================================================
# Systemd is Ubuntu's service manager. It controls what programs start
# automatically when the computer boots.
#
# We create a service file that tells systemd:
#   - Who to run Jupyter as (the current user, not root)
#   - What command to run (jupyter lab using the venv)
#   - When to run it (after the network is available)
#   - What to do if it crashes (restart automatically)
#
# The service file goes in: /etc/systemd/system/jupyterlab.service
# After creating it we enable it so it survives reboots.
# =============================================================================

print_header "STEP 10: Creating Systemd Auto-Start Service"
log_header "STEP 10: Creating Systemd Auto-Start Service"

print_status "Creating systemd service file..."

sudo bash -c "cat > /etc/systemd/system/jupyterlab.service << EOF
[Unit]
Description=JupyterLab - AI Red Team Lab
# Start after network is available so Jupyter can bind to the port cleanly
After=network.target

[Service]
# Run as the lab user, not as root
User=${LAB_USER}
# Set the working directory to the notebooks folder
WorkingDirectory=${LAB_DIR}/notebooks
# The command that starts Jupyter
# We use the full path to jupyter inside the venv to ensure the right
# Python environment and libraries are always used
ExecStart=${VENV_PATH}/bin/jupyter lab
# If Jupyter crashes, restart it automatically after 10 seconds
Restart=on-failure
RestartSec=10
# Pass the user's environment variables so Jupyter finds its config
Environment=HOME=${LAB_HOME}
Environment=PATH=${VENV_PATH}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

[Install]
# Start this service when the system reaches the normal multi-user mode
WantedBy=multi-user.target
EOF"

print_status "Systemd service file created."

# Reload systemd so it picks up the new service file
print_status "Reloading systemd daemon..."
sudo systemctl daemon-reload >> "$LOG_FILE" 2>&1

# Enable the service so it starts on every boot
print_status "Enabling JupyterLab service to start on boot..."
sudo systemctl enable jupyterlab.service >> "$LOG_FILE" 2>&1

# Start the service right now so students do not need to reboot
print_status "Starting JupyterLab service now..."
sudo systemctl start jupyterlab.service >> "$LOG_FILE" 2>&1

# Give Jupyter a few seconds to start before checking status
sleep 5

# Check if it started successfully
if sudo systemctl is-active --quiet jupyterlab.service; then
    print_status "JupyterLab service is running successfully."
else
    echo "WARNING: JupyterLab service may not have started correctly." | tee -a "$LOG_FILE"
    echo "         Check with: sudo systemctl status jupyterlab.service" | tee -a "$LOG_FILE"
fi

# =============================================================================
# SECTION 11: CREATE DESKTOP HTML SHORTCUT
# =============================================================================
# A simple HTML file that when opened in a browser goes directly to Jupyter.
# We use an HTML redirect rather than a .desktop launcher because HTML files
# open reliably in a browser across all desktop environments.
#
# The URL includes the hardcoded token so students do not need to type it.
# The page auto-redirects after 2 seconds, showing a friendly message first.
# =============================================================================

print_header "STEP 11: Creating Desktop Shortcut"
log_header "STEP 11: Creating Desktop Shortcut"

HTML_SHORTCUT="$LAB_HOME/Desktop/Open_Jupyter_Lab.html"

cat > "$HTML_SHORTCUT" << EOF
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Opening AI Red Team Lab...</title>
    <!-- Auto-redirect to Jupyter after 2 seconds -->
    <meta http-equiv="refresh" content="2;url=${JUPYTER_URL}">
    <style>
        body {
            font-family: Arial, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            background-color: #1a1a2e;
            color: #e0e0e0;
        }
        .container {
            text-align: center;
            padding: 40px;
            background-color: #16213e;
            border-radius: 12px;
            border: 2px solid #e94560;
        }
        h1 { color: #e94560; margin-bottom: 10px; }
        p  { color: #a0a0a0; }
        a  { color: #e94560; }
        .token {
            font-family: monospace;
            background: #0f3460;
            padding: 8px 16px;
            border-radius: 4px;
            font-size: 1.1em;
            color: #ffffff;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔴 AI Red Team Lab</h1>
        <p>Opening JupyterLab in 2 seconds...</p>
        <p>If nothing happens, <a href="${JUPYTER_URL}">click here</a></p>
        <br>
        <p>Manual URL:</p>
        <p class="token">${JUPYTER_URL}</p>
        <br>
        <p style="font-size:0.85em; color:#606060;">
            Token: ${JUPYTER_TOKEN} &nbsp;|&nbsp; Port: ${JUPYTER_PORT}
        </p>
    </div>
</body>
</html>
EOF

print_status "Desktop HTML shortcut created at: $HTML_SHORTCUT"

# =============================================================================
# SECTION 12: CREATE BACKUP start_jupyter.sh ON DESKTOP
# =============================================================================
# If the systemd service ever stops, students or instructors can use this
# script to manually restart Jupyter without needing to know the commands.
# It also prints the URL clearly so there is no confusion.
# =============================================================================

print_header "STEP 12: Creating Backup start_jupyter.sh"
log_header "STEP 12: Creating Backup start_jupyter.sh"

BACKUP_LAUNCHER="$LAB_HOME/Desktop/start_jupyter.sh"

cat > "$BACKUP_LAUNCHER" << EOF
#!/bin/bash
# =============================================================================
# AI Red Team Lab - Backup Jupyter Launcher
# =============================================================================
# Use this script if JupyterLab does not start automatically on boot,
# or if you need to restart it manually for any reason.
#
# Usage:
#   bash start_jupyter.sh
# =============================================================================

echo ""
echo "============================================="
echo "  AI Red Team Lab - Starting JupyterLab"
echo "============================================="
echo ""

# Activate the virtual environment
. "${VENV_PATH}/bin/activate"

echo "JupyterLab is starting..."
echo ""
echo "Once started, open your browser and go to:"
echo ""
echo "  ${JUPYTER_URL}"
echo ""
echo "Or double-click Open_Jupyter_Lab.html on the Desktop."
echo ""
echo "Press Ctrl+C in this terminal to stop JupyterLab."
echo ""

# Change to the notebooks directory and launch Jupyter
cd "${LAB_DIR}/notebooks"
jupyter lab
EOF

chmod +x "$BACKUP_LAUNCHER"

print_status "Backup launcher created at: $BACKUP_LAUNCHER"

# =============================================================================
# SECTION 13: FINAL VERIFICATION
# =============================================================================
# Run a final check to confirm all key components are in place.
# Results are printed to the terminal AND written to the log file.
# =============================================================================

print_header "STEP 13: Final Verification"
log_header "STEP 13: Final Verification"

print_status "Running final checks..."
echo ""

# Activate the venv for verification
. "$VENV_PATH/bin/activate"

# Check Python libraries
python3 -c "
import sys

checks = []

# Check all required libraries
try:
    import numpy as np
    checks.append(('numpy', np.__version__, True))
except ImportError:
    checks.append(('numpy', 'NOT FOUND', False))

try:
    import pandas as pd
    checks.append(('pandas', pd.__version__, True))
except ImportError:
    checks.append(('pandas', 'NOT FOUND', False))

try:
    import sklearn
    checks.append(('scikit-learn', sklearn.__version__, True))
except ImportError:
    checks.append(('scikit-learn', 'NOT FOUND', False))

try:
    import matplotlib
    checks.append(('matplotlib', matplotlib.__version__, True))
except ImportError:
    checks.append(('matplotlib', 'NOT FOUND', False))

try:
    import art
    checks.append(('ART', art.__version__, True))
except ImportError:
    checks.append(('ART', 'NOT FOUND', False))

print('Library Check:')
print('-' * 40)
all_ok = True
for name, version, ok in checks:
    status = '✓' if ok else '✗'
    print(f'  {status} {name:<20}: {version}')
    if not ok:
        all_ok = False

print('')
if all_ok:
    print('All libraries OK.')
else:
    print('Some libraries are missing. Re-run the installer.')
    sys.exit(1)
" | tee -a "$LOG_FILE"

echo ""

# Check datasets
echo "Dataset Check:" | tee -a "$LOG_FILE"
echo "-" | tee -a "$LOG_FILE"

for DATASET in "nursery.data" "SMSSpamCollection"; do
    if [ -f "$LAB_DIR/datasets/$DATASET" ]; then
        LINES=$(wc -l < "$LAB_DIR/datasets/$DATASET")
        echo "  ✓ $DATASET ($LINES records)" | tee -a "$LOG_FILE"
    else
        echo "  ✗ $DATASET NOT FOUND" | tee -a "$LOG_FILE"
    fi
done

echo ""

# Check notebooks
echo "Notebook Check:" | tee -a "$LOG_FILE"
echo "-" | tee -a "$LOG_FILE"

for NOTEBOOK in "${NOTEBOOKS[@]}"; do
    if [ -f "$LAB_DIR/notebooks/$NOTEBOOK" ]; then
        echo "  ✓ $NOTEBOOK" | tee -a "$LOG_FILE"
    else
        echo "  ✗ $NOTEBOOK NOT FOUND" | tee -a "$LOG_FILE"
    fi
done

echo ""

# Check Jupyter service
echo "Service Check:" | tee -a "$LOG_FILE"
echo "-" | tee -a "$LOG_FILE"

if sudo systemctl is-active --quiet jupyterlab.service; then
    echo "  ✓ JupyterLab systemd service is running" | tee -a "$LOG_FILE"
else
    echo "  ✗ JupyterLab service is NOT running" | tee -a "$LOG_FILE"
    echo "    Use: bash ~/Desktop/start_jupyter.sh" | tee -a "$LOG_FILE"
fi

# Check desktop files
echo ""
echo "Desktop Files Check:" | tee -a "$LOG_FILE"
echo "-" | tee -a "$LOG_FILE"

for DFILE in "Open_Jupyter_Lab.html" "start_jupyter.sh" "lab_installer_log.txt"; do
    if [ -f "$LAB_HOME/Desktop/$DFILE" ]; then
        echo "  ✓ $DFILE" | tee -a "$LOG_FILE"
    else
        echo "  ✗ $DFILE NOT FOUND" | tee -a "$LOG_FILE"
    fi
done

# =============================================================================
# DONE
# =============================================================================

print_header "INSTALLATION COMPLETE"
log_header "INSTALLATION COMPLETE"

FINISH_TIME=$(date)
print_status "Installation finished at: $FINISH_TIME"

echo ""
echo "  Lab folder  : $LAB_DIR"
echo "  Jupyter URL : $JUPYTER_URL"
echo "  Token       : $JUPYTER_TOKEN"
echo "  Log file    : $LOG_FILE"
echo ""
echo "  Desktop shortcuts created:"
echo "    - Open_Jupyter_Lab.html  (double-click to open lab in browser)"
echo "    - start_jupyter.sh       (backup launcher if service stops)"
echo "    - lab_installer_log.txt  (this installation log)"
echo ""
echo "  JupyterLab will start automatically on every boot."
echo "  Students open the browser shortcut and land on START_HERE.ipynb"
echo ""
echo "  Good luck with the class!"
echo ""

echo "" >> "$LOG_FILE"
echo "Installation completed successfully at: $FINISH_TIME" >> "$LOG_FILE"
