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
#
# Changes in this version:
#   - Terminal output re-enabled for all steps using tee
#   - Token passed directly on ExecStart command line in systemd service
#     to guarantee it is always applied regardless of config file discovery
#   - Token also written to both jupyter_lab_configuration.py and
#     jupyter_server_configuration.py for belt-and-suspenders coverage
# =============================================================================

set -euo pipefail

# =============================================================================
# CONFIGURATION VARIABLES
# =============================================================================

LAB_USER="$USER"
LAB_HOME="$HOME"
VENV_PATH="$LAB_HOME/lab_env"
LAB_DIR="$LAB_HOME/Desktop/AI_Red_Team_Lab"
LOG_FILE="$LAB_HOME/Desktop/lab_installer_log.txt"
JUPYTER_TOKEN="airedteamlab"
JUPYTER_PORT="8888"
JUPYTER_URL="http://localhost:${JUPYTER_PORT}/lab?token=${JUPYTER_TOKEN}"
GITHUB_RAW="https://raw.githubusercontent.com/utkarsh121/AI-red-teaming-lab/main"

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

print_header() {
    echo ""
    echo "============================================="
    echo "  $1"
    echo "============================================="
}

print_status() {
    echo "--> $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

print_error() {
    echo ""
    echo "ERROR: $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >> "$LOG_FILE"
    echo ""
    echo "Installation failed. Check the log file for details:"
    echo "  $LOG_FILE"
    exit 1
}

log_header() {
    echo "" >> "$LOG_FILE"
    echo "=============================================" >> "$LOG_FILE"
    echo "  $1" >> "$LOG_FILE"
    echo "=============================================" >> "$LOG_FILE"
}

# =============================================================================
# SECTION 1: SYSTEM UPDATE AND UPGRADE
# =============================================================================
# Done BEFORE starting the log file because apt output is very noisy.
# Output goes to terminal only here — this is intentional.
# The log starts cleanly after this step completes.
# =============================================================================

print_header "STEP 1: Updating System Packages (terminal only - too noisy for log)"
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
# Output goes to BOTH terminal and log file using tee.
# tee -a appends to the log while also printing to the terminal.
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
    unzip 2>&1 | tee -a "$LOG_FILE"

print_status "System dependencies installed successfully."

PYTHON_VERSION=$(python3 --version)
print_status "Python version: $PYTHON_VERSION"

# =============================================================================
# SECTION 3: CREATE PYTHON VIRTUAL ENVIRONMENT
# =============================================================================

print_header "STEP 3: Creating Python Virtual Environment"
log_header "STEP 3: Creating Python Virtual Environment"

if [ ! -d "$VENV_PATH" ]; then
    print_status "Creating virtual environment at: $VENV_PATH"
    python3 -m venv "$VENV_PATH" 2>&1 | tee -a "$LOG_FILE"
    print_status "Virtual environment created successfully."
else
    print_status "Virtual environment already exists at: $VENV_PATH — skipping creation."
fi

print_status "Activating virtual environment..."
. "$VENV_PATH/bin/activate"
print_status "Virtual environment activated."

# =============================================================================
# SECTION 4: UPGRADE PIP
# =============================================================================

print_header "STEP 4: Upgrading pip"
log_header "STEP 4: Upgrading pip"

print_status "Upgrading pip to latest version..."
pip install --upgrade pip 2>&1 | tee -a "$LOG_FILE"
print_status "pip upgraded successfully."

# =============================================================================
# SECTION 5: INSTALL PYTHON LIBRARIES
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
    ipywidgets 2>&1 | tee -a "$LOG_FILE"

print_status "All Python libraries installed successfully."

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
" 2>&1 | tee -a "$LOG_FILE"

# =============================================================================
# SECTION 6: CREATE LAB FOLDER STRUCTURE
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

print_header "STEP 7: Downloading Datasets"
log_header "STEP 7: Downloading Datasets"

print_status "Downloading Nursery dataset..."
curl -fsSL \
    "https://archive.ics.uci.edu/ml/machine-learning-databases/nursery/nursery.data" \
    -o "$LAB_DIR/datasets/nursery.data" 2>&1 | tee -a "$LOG_FILE"

if [ -f "$LAB_DIR/datasets/nursery.data" ]; then
    NURSERY_SIZE=$(wc -l < "$LAB_DIR/datasets/nursery.data")
    print_status "Nursery dataset downloaded: $NURSERY_SIZE records."
else
    print_error "Nursery dataset download failed. Check your internet connection."
fi

print_status "Downloading SMS Spam dataset (zip)..."
curl -fsSL \
    "https://archive.ics.uci.edu/ml/machine-learning-databases/00228/smsspamcollection.zip" \
    -o "$LAB_DIR/datasets/sms_spam.zip" 2>&1 | tee -a "$LOG_FILE"

print_status "Unzipping SMS Spam dataset..."
unzip -o "$LAB_DIR/datasets/sms_spam.zip" \
    -d "$LAB_DIR/datasets/" 2>&1 | tee -a "$LOG_FILE"

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

print_header "STEP 8: Downloading Lab Notebooks from GitHub"
log_header "STEP 8: Downloading Lab Notebooks from GitHub"

print_status "Downloading notebooks from: $GITHUB_RAW"

for NOTEBOOK in "${NOTEBOOKS[@]}"; do
    print_status "  Downloading $NOTEBOOK..."
    curl -fsSL \
        "$GITHUB_RAW/$NOTEBOOK" \
        -o "$LAB_DIR/notebooks/$NOTEBOOK" 2>&1 | tee -a "$LOG_FILE"

    if [ -f "$LAB_DIR/notebooks/$NOTEBOOK" ]; then
        print_status "  $NOTEBOOK downloaded successfully."
    else
        echo "  WARNING: Failed to download $NOTEBOOK" | tee -a "$LOG_FILE"
        echo "  Copy it manually from GitHub to: $LAB_DIR/notebooks/"
    fi
done

print_status "All notebooks downloaded."

# =============================================================================
# SECTION 9: CONFIGURE JUPYTER
# =============================================================================
# Token is written to BOTH config file variants that different Jupyter
# versions look for. Belt-and-suspenders approach.
# Primary token guarantee is on the ExecStart command line in Section 10.
# =============================================================================

print_header "STEP 9: Configuring Jupyter"
log_header "STEP 9: Configuring Jupyter"

mkdir -p "$LAB_HOME/.jupyter"

print_status "Writing Jupyter configuration files..."

# For JupyterLab 3.x
cat > "$LAB_HOME/.jupyter/jupyter_lab_configuration.py" << EOF
c.ServerApp.token = '${JUPYTER_TOKEN}'
c.ServerApp.open_browser = False
c.ServerApp.port = ${JUPYTER_PORT}
c.ServerApp.root_dir = '${LAB_DIR}/notebooks'
c.ServerApp.default_url = '/lab/tree/START_HERE.ipynb'
c.ServerApp.ip = '127.0.0.1'
c.ServerApp.password = ''
EOF

# For JupyterLab 4.x / jupyter-server 2.x
cat > "$LAB_HOME/.jupyter/jupyter_server_configuration.py" << EOF
c.ServerApp.token = '${JUPYTER_TOKEN}'
c.ServerApp.open_browser = False
c.ServerApp.port = ${JUPYTER_PORT}
c.ServerApp.root_dir = '${LAB_DIR}/notebooks'
c.ServerApp.default_url = '/lab/tree/START_HERE.ipynb'
c.ServerApp.ip = '127.0.0.1'
c.ServerApp.password = ''
EOF

print_status "Config written to jupyter_lab_configuration.py and jupyter_server_configuration.py"
print_status "Token set to   : $JUPYTER_TOKEN"
print_status "Default URL set: /lab/tree/START_HERE.ipynb"

# =============================================================================
# SECTION 10: CREATE SYSTEMD SERVICE FOR AUTO-START ON BOOT
# =============================================================================
# KEY FIX: Token passed DIRECTLY on the ExecStart command line.
# This is the primary and most reliable method — does not depend on
# config file discovery or environment variable loading at service start.
# =============================================================================

print_header "STEP 10: Creating Systemd Auto-Start Service"
log_header "STEP 10: Creating Systemd Auto-Start Service"

print_status "Creating systemd service file..."

sudo bash -c "cat > /etc/systemd/system/jupyterlab.service << EOF
[Unit]
Description=JupyterLab - AI Red Team Lab
After=network.target

[Service]
User=${LAB_USER}
WorkingDirectory=${LAB_DIR}/notebooks
ExecStart=${VENV_PATH}/bin/jupyter lab \\
    --ServerApp.token='${JUPYTER_TOKEN}' \\
    --ServerApp.open_browser=False \\
    --ServerApp.port=${JUPYTER_PORT} \\
    --ServerApp.root_dir='${LAB_DIR}/notebooks' \\
    --ServerApp.default_url='/lab/tree/START_HERE.ipynb' \\
    --ServerApp.ip='127.0.0.1' \\
    --ServerApp.password=''
Restart=on-failure
RestartSec=10
Environment=HOME=${LAB_HOME}
Environment=PATH=${VENV_PATH}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

[Install]
WantedBy=multi-user.target
EOF"

print_status "Systemd service file created."

print_status "Reloading systemd daemon..."
sudo systemctl daemon-reload 2>&1 | tee -a "$LOG_FILE"

print_status "Enabling JupyterLab service to start on boot..."
sudo systemctl enable jupyterlab.service 2>&1 | tee -a "$LOG_FILE"

print_status "Starting JupyterLab service now..."
sudo systemctl start jupyterlab.service 2>&1 | tee -a "$LOG_FILE"

sleep 5

if sudo systemctl is-active --quiet jupyterlab.service; then
    print_status "JupyterLab service is running successfully."
else
    echo "WARNING: JupyterLab service may not have started correctly." | tee -a "$LOG_FILE"
    echo "         Check with: sudo systemctl status jupyterlab.service" | tee -a "$LOG_FILE"
fi

# =============================================================================
# SECTION 11: CREATE DESKTOP HTML SHORTCUT
# =============================================================================

print_header "STEP 11: Creating Desktop HTML Shortcut"
log_header "STEP 11: Creating Desktop HTML Shortcut"

HTML_SHORTCUT="$LAB_HOME/Desktop/Open_Jupyter_Lab.html"

cat > "$HTML_SHORTCUT" << EOF
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Opening AI Red Team Lab...</title>
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
# Token also passed on command line here for the same reliability reason.
# =============================================================================

print_header "STEP 12: Creating Backup start_jupyter.sh"
log_header "STEP 12: Creating Backup start_jupyter.sh"

BACKUP_LAUNCHER="$LAB_HOME/Desktop/start_jupyter.sh"

cat > "$BACKUP_LAUNCHER" << EOF
#!/bin/bash
# =============================================================================
# AI Red Team Lab - Backup Jupyter Launcher
# =============================================================================
# Use this if JupyterLab does not start automatically on boot,
# or if you need to restart it manually.
#
# Usage:
#   bash start_jupyter.sh
# =============================================================================

echo ""
echo "============================================="
echo "  AI Red Team Lab - Starting JupyterLab"
echo "============================================="
echo ""

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

cd "${LAB_DIR}/notebooks"

jupyter lab \
    --ServerApp.token='${JUPYTER_TOKEN}' \
    --ServerApp.open_browser=False \
    --ServerApp.port=${JUPYTER_PORT} \
    --ServerApp.root_dir='${LAB_DIR}/notebooks' \
    --ServerApp.default_url='/lab/tree/START_HERE.ipynb' \
    --ServerApp.ip='127.0.0.1' \
    --ServerApp.password=''
EOF

chmod +x "$BACKUP_LAUNCHER"
print_status "Backup launcher created at: $BACKUP_LAUNCHER"

# =============================================================================
# SECTION 13: FINAL VERIFICATION
# =============================================================================

print_header "STEP 13: Final Verification"
log_header "STEP 13: Final Verification"

print_status "Running final checks..."
echo ""

. "$VENV_PATH/bin/activate"

python3 -c "
import sys
checks = []

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
    status = 'OK' if ok else 'MISSING'
    print(f'  [{status}] {name:<20}: {version}')
    if not ok:
        all_ok = False
print('')
if all_ok:
    print('All libraries verified OK.')
else:
    print('Some libraries missing. Please re-run the installer.')
    sys.exit(1)
" 2>&1 | tee -a "$LOG_FILE"

echo ""

echo "Dataset Check:" | tee -a "$LOG_FILE"
echo "----------------------------------------" | tee -a "$LOG_FILE"
for DATASET in "nursery.data" "SMSSpamCollection"; do
    if [ -f "$LAB_DIR/datasets/$DATASET" ]; then
        LINES=$(wc -l < "$LAB_DIR/datasets/$DATASET")
        echo "  [OK] $DATASET ($LINES records)" | tee -a "$LOG_FILE"
    else
        echo "  [MISSING] $DATASET" | tee -a "$LOG_FILE"
    fi
done

echo ""

echo "Notebook Check:" | tee -a "$LOG_FILE"
echo "----------------------------------------" | tee -a "$LOG_FILE"
for NOTEBOOK in "${NOTEBOOKS[@]}"; do
    if [ -f "$LAB_DIR/notebooks/$NOTEBOOK" ]; then
        echo "  [OK] $NOTEBOOK" | tee -a "$LOG_FILE"
    else
        echo "  [MISSING] $NOTEBOOK" | tee -a "$LOG_FILE"
    fi
done

echo ""

echo "Service Check:" | tee -a "$LOG_FILE"
echo "----------------------------------------" | tee -a "$LOG_FILE"
if sudo systemctl is-active --quiet jupyterlab.service; then
    echo "  [OK] JupyterLab systemd service is running" | tee -a "$LOG_FILE"
else
    echo "  [STOPPED] JupyterLab service is not running" | tee -a "$LOG_FILE"
    echo "  Use: bash ~/Desktop/start_jupyter.sh" | tee -a "$LOG_FILE"
fi

echo ""

echo "Desktop Files Check:" | tee -a "$LOG_FILE"
echo "----------------------------------------" | tee -a "$LOG_FILE"
for DFILE in "Open_Jupyter_Lab.html" "start_jupyter.sh" "lab_installer_log.txt"; do
    if [ -f "$LAB_HOME/Desktop/$DFILE" ]; then
        echo "  [OK] $DFILE" | tee -a "$LOG_FILE"
    else
        echo "  [MISSING] $DFILE" | tee -a "$LOG_FILE"
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
echo "  Desktop shortcuts:"
echo "    - Open_Jupyter_Lab.html  (double-click to open lab in browser)"
echo "    - start_jupyter.sh       (backup if service stops)"
echo "    - lab_installer_log.txt  (this installation log)"
echo ""
echo "  JupyterLab starts automatically on every boot."
echo "  Students open the browser shortcut and land on START_HERE.ipynb"
echo ""
echo "  Good luck with the class!"
echo ""

echo "" >> "$LOG_FILE"
echo "Installation completed successfully at: $FINISH_TIME" >> "$LOG_FILE"
