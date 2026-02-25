#!/bin/bash

# =============================================================================
# AI Red Team Lab - Main Installer
# =============================================================================
# Course   : Certified AI Penetration Tester - Red Team (CAIPT-RT)
# File     : lab_installer_main.sh
# Target OS: Ubuntu 24.04 LTS (with desktop — local machine)
#
# Purpose:
#   Full automated setup of the AI Red Team Lab environment including:
#   - Python virtual environment and all required libraries
#   - Ollama local LLM runtime + TinyLlama model (for Lab 5)
#   - Lab folder structure on the Desktop
#   - Dataset downloads from UCI ML Repository
#   - Notebook downloads from GitHub (Labs 1-5)
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
# DO NOT run as root.
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
OLLAMA_MODEL="tinyllama"

NOTEBOOKS=(
    "START_HERE.ipynb"
    "Lab1_Evasion_Attack.ipynb"
    "Lab2_Poisoning_Attack.ipynb"
    "Lab3_Inference_Attack.ipynb"
    "Lab4_Extraction_Attack.ipynb"
    "Lab5_Prompt_Injection.ipynb"
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

print_ok() {
    echo "    OK: $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] OK: $1" >> "$LOG_FILE"
}

print_warn() {
    echo "    WARNING: $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1" >> "$LOG_FILE"
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
# GUARD: REFUSE TO RUN AS ROOT
# =============================================================================

if [ "$EUID" -eq 0 ]; then
    echo ""
    echo "ERROR: Do not run this script as root."
    echo "       Run as your regular user account and try again."
    echo ""
    exit 1
fi

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

mkdir -p "$LAB_HOME/Desktop"

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
Ollama model: $OLLAMA_MODEL
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

# -----------------------------------------------------------------------------
# EMOJI FONT
# -----------------------------------------------------------------------------
# Ubuntu VMs frequently ship without colour emoji support, causing emoji in
# notebooks to render as blank boxes. We check first, then refresh the font
# cache immediately so the change takes effect without a reboot.
# -----------------------------------------------------------------------------

print_status "Checking emoji font (fonts-noto-color-emoji)..."

if dpkg -l fonts-noto-color-emoji &>/dev/null; then
    print_status "Emoji font already installed - skipping."
else
    print_status "Emoji font not found - installing..."
    sudo apt-get install -y fonts-noto-color-emoji 2>&1 | tee -a "$LOG_FILE"
    print_ok "Emoji font installed."
fi

print_status "Refreshing system font cache (fc-cache)..."
fc-cache -f -v 2>&1 | tee -a "$LOG_FILE"
print_ok "Font cache refreshed. Emoji will render correctly in Jupyter."

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
    print_ok "Virtual environment created."
else
    print_status "Virtual environment already exists at: $VENV_PATH — skipping creation."
fi

print_status "Activating virtual environment..."
. "$VENV_PATH/bin/activate"
print_ok "Virtual environment activated."

# =============================================================================
# SECTION 4: UPGRADE PIP
# =============================================================================

print_header "STEP 4: Upgrading pip"
log_header "STEP 4: Upgrading pip"

print_status "Upgrading pip to latest version..."
pip install --upgrade pip 2>&1 | tee -a "$LOG_FILE"
print_ok "pip upgraded."

# =============================================================================
# SECTION 5: INSTALL PYTHON LIBRARIES
# =============================================================================
# requests is added here — required by Lab 5 to call the Ollama REST API.
# All other libraries are unchanged from previous version.
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
    ipywidgets \
    requests 2>&1 | tee -a "$LOG_FILE"

print_ok "All Python libraries installed."

print_status "Logging installed library versions..."
python3 -c "
import sklearn, numpy, pandas, matplotlib, art, requests
versions = {
    'scikit-learn' : sklearn.__version__,
    'numpy'        : numpy.__version__,
    'pandas'       : pandas.__version__,
    'matplotlib'   : matplotlib.__version__,
    'ART'          : art.__version__,
    'requests'     : requests.__version__,
}
for lib, ver in versions.items():
    print(f'  {lib:<20}: {ver}')
" 2>&1 | tee -a "$LOG_FILE"

# =============================================================================
# SECTION 6: INSTALL OLLAMA
# =============================================================================
# Ollama runs open-source LLMs locally and exposes a simple REST API at
# http://localhost:11434. Lab 5 (Prompt Injection) sends HTTP requests to
# this API to interact with TinyLlama.
#
# The official Ollama install script:
#   - Downloads and installs the ollama binary to /usr/local/bin
#   - Creates an 'ollama' system user
#   - Registers and starts a systemd service (ollama.service)
#   - The service auto-starts on every boot
#
# We check if Ollama is already installed before running the install script
# so this section is safe to re-run on a partially configured machine.
# =============================================================================

print_header "STEP 6: Installing Ollama (Local LLM Runtime)"
log_header "STEP 6: Ollama"

if command -v ollama &>/dev/null; then
    print_status "Ollama already installed — skipping install."
    OLLAMA_VERSION=$(ollama --version 2>/dev/null || echo "installed")
    print_ok "Ollama version: $OLLAMA_VERSION"
else
    print_status "Downloading and installing Ollama..."
    print_status "(This installs the binary and registers the systemd service)"

    # The official install script from ollama.com
    # It handles architecture detection, binary download, and service setup
    curl -fsSL https://ollama.com/install.sh | sh 2>&1 | tee -a "$LOG_FILE"

    print_ok "Ollama installed."
fi

# =============================================================================
# SECTION 7: VERIFY OLLAMA SERVICE AND PULL TINYLLAMA
# =============================================================================
# The Ollama install script starts the service immediately, but we verify
# it is actually running before attempting to pull the model.
#
# Rather than a blind sleep timer, we poll systemctl status in a loop
# with a timeout — the same way production deployment scripts do it.
# Only once the service is confirmed running do we pull the model.
#
# ollama pull tinyllama:
#   Downloads TinyLlama-1.1B (~600MB) from the Ollama model registry.
#   The model is stored on disk permanently — subsequent runs of the
#   installer will find it already present and skip the download.
#
# ollama list:
#   Lists all models Ollama has downloaded. We use this to verify the
#   pull succeeded before declaring success.
# =============================================================================

print_header "STEP 7: Verifying Ollama Service and Pulling TinyLlama"
log_header "STEP 7: Ollama Service + TinyLlama"

print_status "Waiting for Ollama service to be ready..."

OLLAMA_READY=false
MAX_WAIT=60       # maximum seconds to wait
POLL_INTERVAL=3   # check every 3 seconds
ELAPSED=0

while [ $ELAPSED -lt $MAX_WAIT ]; do
    if sudo systemctl is-active --quiet ollama; then
        OLLAMA_READY=true
        break
    fi
    sleep $POLL_INTERVAL
    ELAPSED=$((ELAPSED + POLL_INTERVAL))
    print_status "  Ollama not ready yet... waited ${ELAPSED}s / ${MAX_WAIT}s"
done

if [ "$OLLAMA_READY" = false ]; then
    # Service did not come up on its own — try starting it explicitly
    print_warn "Ollama service did not start automatically. Trying manual start..."
    sudo systemctl start ollama 2>&1 | tee -a "$LOG_FILE" || true
    sleep 5

    if sudo systemctl is-active --quiet ollama; then
        OLLAMA_READY=true
        print_ok "Ollama service started manually."
    else
        print_warn "Ollama service is still not running."
        print_warn "Lab 5 will not work until Ollama is running."
        print_warn "After install, run:  sudo systemctl start ollama"
    fi
fi

if [ "$OLLAMA_READY" = true ]; then
    print_ok "Ollama service is running."

    # Double-check the API is actually responding, not just the service unit
    print_status "Verifying Ollama API is responding on port 11434..."
    API_READY=false
    for i in 1 2 3 4 5; do
        if curl -sf http://localhost:11434/api/tags > /dev/null 2>&1; then
            API_READY=true
            break
        fi
        sleep 3
    done

    if [ "$API_READY" = true ]; then
        print_ok "Ollama API is responding."
    else
        print_warn "Ollama API not responding yet — continuing anyway."
    fi

    # Check if TinyLlama is already downloaded
    if ollama list 2>/dev/null | grep -q "tinyllama"; then
        print_status "TinyLlama already downloaded — skipping pull."
        print_ok "TinyLlama ready."
    else
        print_status "Pulling TinyLlama model (~600MB, this may take a few minutes)..."
        ollama pull "$OLLAMA_MODEL" 2>&1 | tee -a "$LOG_FILE"

        # Verify the pull succeeded
        if ollama list 2>/dev/null | grep -q "tinyllama"; then
            print_ok "TinyLlama downloaded and verified."
        else
            print_warn "TinyLlama pull may have failed."
            print_warn "After install, run manually:  ollama pull tinyllama"
        fi
    fi

    # Log the final model list
    print_status "Ollama models available:"
    ollama list 2>&1 | tee -a "$LOG_FILE"
fi

# Ensure Ollama is enabled to start on every boot
print_status "Enabling Ollama service to start on boot..."
sudo systemctl enable ollama 2>&1 | tee -a "$LOG_FILE"
print_ok "Ollama will start automatically on boot."

# =============================================================================
# SECTION 8: CREATE LAB FOLDER STRUCTURE
# =============================================================================

print_header "STEP 8: Creating Lab Folder Structure"
log_header "STEP 8: Creating Lab Folder Structure"

mkdir -p "$LAB_DIR/datasets"
mkdir -p "$LAB_DIR/notebooks"
mkdir -p "$LAB_DIR/outputs"

print_ok "Lab folder structure created at: $LAB_DIR"

# =============================================================================
# SECTION 9: DOWNLOAD DATASETS
# =============================================================================

print_header "STEP 9: Downloading Datasets"
log_header "STEP 9: Downloading Datasets"

print_status "Downloading Nursery dataset..."
curl -fsSL \
    "https://archive.ics.uci.edu/ml/machine-learning-databases/nursery/nursery.data" \
    -o "$LAB_DIR/datasets/nursery.data" 2>&1 | tee -a "$LOG_FILE"

if [ -f "$LAB_DIR/datasets/nursery.data" ]; then
    print_ok "Nursery dataset: $(wc -l < "$LAB_DIR/datasets/nursery.data") records."
else
    print_error "Nursery dataset download failed. Check internet connection."
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
    print_ok "SMS Spam dataset: $(wc -l < "$LAB_DIR/datasets/SMSSpamCollection") messages."
else
    print_error "SMS Spam dataset extraction failed."
fi

# =============================================================================
# SECTION 10: DOWNLOAD NOTEBOOKS FROM GITHUB
# =============================================================================
# Lab5_Prompt_Injection.ipynb is now included in the NOTEBOOKS array.
# No other changes to this section — the loop handles it automatically.
# =============================================================================

print_header "STEP 10: Downloading Lab Notebooks from GitHub"
log_header "STEP 10: Downloading Lab Notebooks from GitHub"

print_status "Downloading notebooks from: $GITHUB_RAW"

for NOTEBOOK in "${NOTEBOOKS[@]}"; do
    print_status "  Downloading $NOTEBOOK..."
    curl -fsSL \
        "$GITHUB_RAW/$NOTEBOOK" \
        -o "$LAB_DIR/notebooks/$NOTEBOOK" 2>&1 | tee -a "$LOG_FILE"

    if [ -f "$LAB_DIR/notebooks/$NOTEBOOK" ]; then
        print_ok "  $NOTEBOOK"
    else
        print_warn "Failed to download $NOTEBOOK — copy manually from GitHub."
    fi
done

# =============================================================================
# SECTION 11: CONFIGURE JUPYTER
# =============================================================================
# Token is written to BOTH config file variants that different Jupyter
# versions look for. Primary guarantee is the token on ExecStart (Section 12).
# =============================================================================

print_header "STEP 11: Configuring Jupyter"
log_header "STEP 11: Configuring Jupyter"

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

print_ok "Jupyter config written. Token: $JUPYTER_TOKEN  Default: START_HERE.ipynb"

# =============================================================================
# SECTION 12: CREATE SYSTEMD SERVICE FOR AUTO-START ON BOOT
# =============================================================================
# Token passed DIRECTLY on ExecStart command line — most reliable method.
# Does not depend on config file discovery or HOME env loading order.
# =============================================================================

print_header "STEP 12: Creating Systemd Auto-Start Service"
log_header "STEP 12: Creating Systemd Auto-Start Service"

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

print_status "Reloading systemd daemon..."
sudo systemctl daemon-reload 2>&1 | tee -a "$LOG_FILE"

print_status "Enabling JupyterLab service to start on boot..."
sudo systemctl enable jupyterlab.service 2>&1 | tee -a "$LOG_FILE"

print_status "Starting JupyterLab service now..."
sudo systemctl start jupyterlab.service 2>&1 | tee -a "$LOG_FILE"

sleep 5

if sudo systemctl is-active --quiet jupyterlab.service; then
    print_ok "JupyterLab service is running."
else
    print_warn "JupyterLab service may not have started correctly."
    print_warn "Check with: sudo systemctl status jupyterlab.service"
fi

# =============================================================================
# SECTION 13: CREATE DESKTOP HTML SHORTCUT
# =============================================================================

print_header "STEP 13: Creating Desktop HTML Shortcut"
log_header "STEP 13: Creating Desktop HTML Shortcut"

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

print_ok "Desktop HTML shortcut created at: $HTML_SHORTCUT"

# =============================================================================
# SECTION 14: CREATE BACKUP start_jupyter.sh ON DESKTOP
# =============================================================================

print_header "STEP 14: Creating Backup start_jupyter.sh"
log_header "STEP 14: Creating Backup start_jupyter.sh"

BACKUP_LAUNCHER="$LAB_HOME/Desktop/start_jupyter.sh"

cat > "$BACKUP_LAUNCHER" << EOF
#!/bin/bash
# =============================================================================
# AI Red Team Lab - Backup Jupyter Launcher
# =============================================================================
# Use this if JupyterLab does not start automatically on boot.
# Usage:  bash start_jupyter.sh
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
echo "  ${JUPYTER_URL}"
echo ""
echo "Or double-click Open_Jupyter_Lab.html on the Desktop."
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
print_ok "Backup launcher created at: $BACKUP_LAUNCHER"

# =============================================================================
# SECTION 15: FINAL VERIFICATION
# =============================================================================

print_header "STEP 15: Final Verification"
log_header "STEP 15: Final Verification"

print_status "Running final checks..."
echo ""

. "$VENV_PATH/bin/activate"

# Python library check
python3 -c "
import sys
checks = []

for lib, mod in [
    ('numpy',        'numpy'),
    ('pandas',       'pandas'),
    ('scikit-learn', 'sklearn'),
    ('matplotlib',   'matplotlib'),
    ('ART',          'art'),
    ('requests',     'requests'),
]:
    try:
        m = __import__(mod)
        checks.append((lib, m.__version__, True))
    except ImportError:
        checks.append((lib, 'NOT FOUND', False))

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

# Dataset check
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

# Notebook check
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

# Service check — JupyterLab and Ollama
echo "Service Check:" | tee -a "$LOG_FILE"
echo "----------------------------------------" | tee -a "$LOG_FILE"

if sudo systemctl is-active --quiet jupyterlab.service; then
    echo "  [OK] JupyterLab service is running" | tee -a "$LOG_FILE"
else
    echo "  [STOPPED] JupyterLab — use: bash ~/Desktop/start_jupyter.sh" | tee -a "$LOG_FILE"
fi

if sudo systemctl is-active --quiet ollama; then
    echo "  [OK] Ollama service is running on port 11434" | tee -a "$LOG_FILE"

    # Check TinyLlama is present
    if ollama list 2>/dev/null | grep -q "tinyllama"; then
        echo "  [OK] TinyLlama model is downloaded and ready" | tee -a "$LOG_FILE"
    else
        echo "  [MISSING] TinyLlama model — run: ollama pull tinyllama" | tee -a "$LOG_FILE"
    fi
else
    echo "  [STOPPED] Ollama — run: sudo systemctl start ollama" | tee -a "$LOG_FILE"
    echo "  [UNKNOWN] TinyLlama — cannot check while Ollama is stopped" | tee -a "$LOG_FILE"
fi

echo ""

# Desktop files check
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
echo "  Services running on boot:"
echo "    - JupyterLab  : http://localhost:${JUPYTER_PORT}"
echo "    - Ollama      : http://localhost:11434"
echo ""
echo "  JupyterLab starts automatically on every boot."
echo "  Ollama starts automatically on every boot."
echo "  Students open the browser shortcut and land on START_HERE.ipynb"
echo ""
echo "  Good luck with the class!"
echo ""

echo "" >> "$LOG_FILE"
echo "Installation completed successfully at: $FINISH_TIME" >> "$LOG_FILE"
