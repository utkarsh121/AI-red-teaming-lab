#!/bin/bash

# =============================================================================
# AI Red Team Lab - macOS Main Installer
# =============================================================================
# Course   : Certified AI Penetration Tester - Red Team (CAIPT-RT)
# File     : mac_lab_installer_main.sh
# Platform : macOS 12 Monterey or later
#
# Usage:
#   bash mac_lab_installer_main.sh
#
# What this script does:
#   - Checks for and installs Python 3 if missing (via official .pkg)
#   - Creates a Python virtual environment
#   - Installs all required Python libraries
#   - Creates lab folder structure on the Desktop
#   - Downloads datasets from UCI ML Repository
#   - Downloads notebooks from GitHub
#   - Configures Jupyter with hardcoded token and default notebook
#   - Creates a LaunchAgent plist for auto-start on login
#   - Creates a desktop HTML shortcut for one-click browser access
#   - Creates a backup start_jupyter.sh on the Desktop
#   - Writes a verbose log file to the Desktop
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
LAUNCH_AGENT_DIR="$LAB_HOME/Library/LaunchAgents"
LAUNCH_AGENT_PLIST="$LAUNCH_AGENT_DIR/com.airedteamlab.jupyterlab.plist"

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
    echo "Check log file: $LOG_FILE"
    exit 1
}

log_header() {
    echo "" >> "$LOG_FILE"
    echo "=============================================" >> "$LOG_FILE"
    echo "  $1" >> "$LOG_FILE"
    echo "=============================================" >> "$LOG_FILE"
}

# =============================================================================
# START LOG FILE
# =============================================================================

cat > "$LOG_FILE" << EOF
=============================================================================
AI Red Team Lab - macOS Installation Log
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
# SECTION 1: CHECK AND INSTALL PYTHON
# =============================================================================
# macOS ships with Python 3 on recent versions, but it may be outdated.
# We check for Python 3.9+ and install from the official .pkg if needed.
# We deliberately avoid Homebrew to keep the installer self-contained.
# =============================================================================

print_header "STEP 1: Checking Python Installation"
log_header "STEP 1: Checking Python Installation"

PYTHON_OK=false

if command -v python3 &> /dev/null; then
    PYTHON_VER=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
    PYTHON_MINOR=$(python3 -c "import sys; print(sys.version_info.minor)")
    if [ "$PYTHON_MINOR" -ge 9 ]; then
        print_status "Python already installed: $(python3 --version)"
        PYTHON_OK=true
    fi
fi

if [ "$PYTHON_OK" = false ]; then
    print_status "Python 3.9+ not found. Downloading official macOS installer..."
    print_status "(This may take a few minutes)"

    # Detect architecture for correct installer
    ARCH=$(uname -m)
    if [ "$ARCH" = "arm64" ]; then
        # Apple Silicon (M1/M2/M3)
        PY_PKG_URL="https://www.python.org/ftp/python/3.12.0/python-3.12.0-macos11.pkg"
    else
        # Intel
        PY_PKG_URL="https://www.python.org/ftp/python/3.12.0/python-3.12.0-macos11.pkg"
    fi

    PY_PKG="/tmp/python_installer.pkg"
    curl -fsSL "$PY_PKG_URL" -o "$PY_PKG" 2>&1 | tee -a "$LOG_FILE"

    print_status "Running Python installer (you may be asked for your password)..."
    sudo installer -pkg "$PY_PKG" -target / 2>&1 | tee -a "$LOG_FILE"

    print_status "Python installed successfully."
fi

print_status "Python version: $(python3 --version)"

# =============================================================================
# SECTION 2: CREATE PYTHON VIRTUAL ENVIRONMENT
# =============================================================================

print_header "STEP 2: Creating Python Virtual Environment"
log_header "STEP 2: Creating Python Virtual Environment"

if [ ! -d "$VENV_PATH" ]; then
    print_status "Creating virtual environment at: $VENV_PATH"
    python3 -m venv "$VENV_PATH" 2>&1 | tee -a "$LOG_FILE"
    print_status "Virtual environment created."
else
    print_status "Virtual environment already exists - skipping."
fi

print_status "Activating virtual environment..."
. "$VENV_PATH/bin/activate"
print_status "Virtual environment activated."

# =============================================================================
# SECTION 3: UPGRADE PIP
# =============================================================================

print_header "STEP 3: Upgrading pip"
log_header "STEP 3: Upgrading pip"

print_status "Upgrading pip..."
pip install --upgrade pip 2>&1 | tee -a "$LOG_FILE"
print_status "pip upgraded."

# =============================================================================
# SECTION 4: INSTALL PYTHON LIBRARIES
# =============================================================================

print_header "STEP 4: Installing Python Libraries"
log_header "STEP 4: Installing Python Libraries"

print_status "Installing all required libraries..."
print_status "(This may take 3-5 minutes)"

pip install \
    adversarial-robustness-toolbox \
    scikit-learn \
    pandas \
    numpy \
    jupyterlab \
    matplotlib \
    seaborn \
    ipywidgets 2>&1 | tee -a "$LOG_FILE"

print_status "All libraries installed."

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
# SECTION 5: CREATE LAB FOLDER STRUCTURE
# =============================================================================

print_header "STEP 5: Creating Lab Folder Structure"
log_header "STEP 5: Creating Lab Folder Structure"

mkdir -p "$LAB_DIR/datasets"
mkdir -p "$LAB_DIR/notebooks"
mkdir -p "$LAB_DIR/outputs"

print_status "Lab folders created at: $LAB_DIR"

# =============================================================================
# SECTION 6: DOWNLOAD DATASETS
# =============================================================================

print_header "STEP 6: Downloading Datasets"
log_header "STEP 6: Downloading Datasets"

print_status "Downloading Nursery dataset..."
curl -fsSL \
    "https://archive.ics.uci.edu/ml/machine-learning-databases/nursery/nursery.data" \
    -o "$LAB_DIR/datasets/nursery.data" 2>&1 | tee -a "$LOG_FILE"

if [ -f "$LAB_DIR/datasets/nursery.data" ]; then
    print_status "Nursery dataset downloaded: $(wc -l < "$LAB_DIR/datasets/nursery.data") records."
else
    print_error "Nursery dataset download failed."
fi

print_status "Downloading SMS Spam dataset..."
curl -fsSL \
    "https://archive.ics.uci.edu/ml/machine-learning-databases/00228/smsspamcollection.zip" \
    -o "$LAB_DIR/datasets/sms_spam.zip" 2>&1 | tee -a "$LOG_FILE"

print_status "Extracting SMS Spam dataset..."
unzip -o "$LAB_DIR/datasets/sms_spam.zip" -d "$LAB_DIR/datasets/" 2>&1 | tee -a "$LOG_FILE"

print_status "Cleaning up zip and readme..."
rm -f "$LAB_DIR/datasets/sms_spam.zip"
rm -f "$LAB_DIR/datasets/readme"

if [ -f "$LAB_DIR/datasets/SMSSpamCollection" ]; then
    print_status "SMS Spam dataset ready: $(wc -l < "$LAB_DIR/datasets/SMSSpamCollection") messages."
else
    print_error "SMS Spam dataset extraction failed."
fi

# =============================================================================
# SECTION 7: DOWNLOAD NOTEBOOKS
# =============================================================================

print_header "STEP 7: Downloading Lab Notebooks from GitHub"
log_header "STEP 7: Downloading Lab Notebooks from GitHub"

for NOTEBOOK in "${NOTEBOOKS[@]}"; do
    print_status "  Downloading $NOTEBOOK..."
    curl -fsSL "$GITHUB_RAW/$NOTEBOOK" -o "$LAB_DIR/notebooks/$NOTEBOOK" 2>&1 | tee -a "$LOG_FILE"
    if [ -f "$LAB_DIR/notebooks/$NOTEBOOK" ]; then
        print_status "  $NOTEBOOK downloaded."
    else
        echo "  WARNING: $NOTEBOOK download failed." | tee -a "$LOG_FILE"
    fi
done

print_status "All notebooks downloaded."

# =============================================================================
# SECTION 8: CONFIGURE JUPYTER
# =============================================================================

print_header "STEP 8: Configuring Jupyter"
log_header "STEP 8: Configuring Jupyter"

mkdir -p "$LAB_HOME/.jupyter"

cat > "$LAB_HOME/.jupyter/jupyter_lab_configuration.py" << EOF
c.ServerApp.token = '${JUPYTER_TOKEN}'
c.ServerApp.open_browser = False
c.ServerApp.port = ${JUPYTER_PORT}
c.ServerApp.root_dir = '${LAB_DIR}/notebooks'
c.ServerApp.default_url = '/lab/tree/START_HERE.ipynb'
c.ServerApp.ip = '127.0.0.1'
c.ServerApp.password = ''
EOF

cat > "$LAB_HOME/.jupyter/jupyter_server_configuration.py" << EOF
c.ServerApp.token = '${JUPYTER_TOKEN}'
c.ServerApp.open_browser = False
c.ServerApp.port = ${JUPYTER_PORT}
c.ServerApp.root_dir = '${LAB_DIR}/notebooks'
c.ServerApp.default_url = '/lab/tree/START_HERE.ipynb'
c.ServerApp.ip = '127.0.0.1'
c.ServerApp.password = ''
EOF

print_status "Jupyter config written."
print_status "Token set to   : $JUPYTER_TOKEN"
print_status "Default URL set: /lab/tree/START_HERE.ipynb"

# =============================================================================
# SECTION 9: CREATE LAUNCHAGENT FOR AUTO-START ON LOGIN
# =============================================================================
# macOS uses LaunchAgents instead of systemd. A LaunchAgent is a plist file
# placed in ~/Library/LaunchAgents/ that macOS reads at login and uses to
# start programs automatically. It is the macOS equivalent of systemd user
# services on Linux.
#
# The plist tells macOS:
#   - What label to use for this job (unique identifier)
#   - What program to run and with what arguments
#   - Where to write stdout and stderr logs
#   - To keep the job alive if it crashes (KeepAlive)
#   - To run it at login (RunAtLoad)
# =============================================================================

print_header "STEP 9: Creating LaunchAgent for Auto-Start on Login"
log_header "STEP 9: Creating LaunchAgent for Auto-Start on Login"

mkdir -p "$LAUNCH_AGENT_DIR"

# Create backup launcher first (referenced by the LaunchAgent)
BACKUP_LAUNCHER="$LAB_HOME/Desktop/start_jupyter.sh"

cat > "$BACKUP_LAUNCHER" << EOF
#!/bin/bash
# =============================================================================
# AI Red Team Lab - Backup Jupyter Launcher (macOS)
# =============================================================================
# Use this if JupyterLab does not start automatically on login.
# Usage: bash start_jupyter.sh
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
echo "Press Ctrl+C to stop JupyterLab."
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

# Create the LaunchAgent plist
cat > "$LAUNCH_AGENT_PLIST" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
    "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Unique label for this LaunchAgent -->
    <key>Label</key>
    <string>com.airedteamlab.jupyterlab</string>

    <!-- Command to run: bash + the backup launcher script -->
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>${BACKUP_LAUNCHER}</string>
    </array>

    <!-- Start at login automatically -->
    <key>RunAtLoad</key>
    <true/>

    <!-- Restart if it crashes -->
    <key>KeepAlive</key>
    <true/>

    <!-- Log stdout and stderr for debugging -->
    <key>StandardOutPath</key>
    <string>${LAB_HOME}/Desktop/jupyter_stdout.log</string>
    <key>StandardErrorPath</key>
    <string>${LAB_HOME}/Desktop/jupyter_stderr.log</string>

    <!-- Working directory -->
    <key>WorkingDirectory</key>
    <string>${LAB_DIR}/notebooks</string>
</dict>
</plist>
EOF

print_status "LaunchAgent plist created at: $LAUNCH_AGENT_PLIST"

# Load the LaunchAgent immediately without requiring a reboot
print_status "Loading LaunchAgent now..."
launchctl load "$LAUNCH_AGENT_PLIST" 2>&1 | tee -a "$LOG_FILE" || true

print_status "JupyterLab will now start automatically every time you log in."

# =============================================================================
# SECTION 10: CREATE DESKTOP HTML SHORTCUT
# =============================================================================

print_header "STEP 10: Creating Desktop HTML Shortcut"
log_header "STEP 10: Creating Desktop HTML Shortcut"

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

print_status "Desktop HTML shortcut created."

# =============================================================================
# SECTION 11: FINAL VERIFICATION
# =============================================================================

print_header "STEP 11: Final Verification"
log_header "STEP 11: Final Verification"

. "$VENV_PATH/bin/activate"

python3 -c "
import sys, warnings
warnings.filterwarnings('ignore')
checks = []
try:
    import numpy as np; checks.append(('numpy', np.__version__, True))
except: checks.append(('numpy', 'NOT FOUND', False))
try:
    import pandas as pd; checks.append(('pandas', pd.__version__, True))
except: checks.append(('pandas', 'NOT FOUND', False))
try:
    import sklearn; checks.append(('scikit-learn', sklearn.__version__, True))
except: checks.append(('scikit-learn', 'NOT FOUND', False))
try:
    import matplotlib; checks.append(('matplotlib', matplotlib.__version__, True))
except: checks.append(('matplotlib', 'NOT FOUND', False))
try:
    import art; checks.append(('ART', art.__version__, True))
except: checks.append(('ART', 'NOT FOUND', False))

print('Library Check:')
print('-' * 40)
all_ok = True
for name, version, ok in checks:
    status = 'OK' if ok else 'MISSING'
    print(f'  [{status}] {name:<20}: {version}')
    if not ok: all_ok = False
print('')
print('All libraries verified OK.' if all_ok else 'Some libraries missing.')
" 2>&1 | tee -a "$LOG_FILE"

echo ""

echo "Dataset Check:" | tee -a "$LOG_FILE"
echo "----------------------------------------" | tee -a "$LOG_FILE"
for DATASET in "nursery.data" "SMSSpamCollection"; do
    if [ -f "$LAB_DIR/datasets/$DATASET" ]; then
        echo "  [OK] $DATASET" | tee -a "$LOG_FILE"
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

echo "LaunchAgent Check:" | tee -a "$LOG_FILE"
echo "----------------------------------------" | tee -a "$LOG_FILE"
if [ -f "$LAUNCH_AGENT_PLIST" ]; then
    echo "  [OK] LaunchAgent plist exists" | tee -a "$LOG_FILE"
else
    echo "  [MISSING] LaunchAgent plist not found" | tee -a "$LOG_FILE"
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
echo "    - start_jupyter.sh       (backup if LaunchAgent stops working)"
echo "    - lab_installer_log.txt  (this installation log)"
echo ""
echo "  JupyterLab starts automatically every time you log in."
echo "  Students double-click the HTML shortcut and land on START_HERE."
echo ""
echo "  Good luck with the class!"
echo ""

echo "" >> "$LOG_FILE"
echo "Installation completed successfully at: $FINISH_TIME" >> "$LOG_FILE"
