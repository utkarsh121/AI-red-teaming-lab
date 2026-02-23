#!/bin/bash

# =============================================================================
# AI Red Team Lab — Azure VM Admin Installer (All-in-One)
# =============================================================================
# Course   : Certified AI Penetration Tester - Red Team (CAIPT-RT)
# File     : lab_installer_admin.sh
# Target   : Fresh Azure Ubuntu 24.04 LTS Server (no desktop)
#
# WHAT THIS SCRIPT DOES (in order):
#   1.  System update and upgrade
#   2.  XFCE desktop environment     — lightweight GUI for the VM
#   3.  xrdp remote desktop server   — lets students RDP in (port 3389)
#   4.  Google Chrome                — fixes "failed to execute default browser"
#   5.  Emoji font + font cache      — renders lab notebook emoji correctly
#   6.  Python + system tools
#   7.  Python virtual environment
#   8.  pip upgrade
#   9.  All Python libraries         — ART, sklearn, pandas, jupyter, etc.
#   10. Lab folder structure on Desktop
#   11. Datasets from UCI ML Repository
#   12. Lab notebooks from GitHub
#   13. Jupyter configuration        — token, default notebook
#   14. Systemd service              — Jupyter auto-starts on every boot
#   15. Desktop HTML shortcut        — double-click to open the lab
#   16. Backup start_jupyter.sh
#   17. Final verification checklist
#
# USAGE — on a fresh Azure Ubuntu 24.04 VM over SSH:
#
#   curl -fsSL https://raw.githubusercontent.com/utkarsh121/AI-red-teaming-lab/main/lab_installer_admin.sh | bash
#
#   Or download first, then run:
#   curl -fsSL https://raw.githubusercontent.com/utkarsh121/AI-red-teaming-lab/main/lab_installer_admin.sh -o setup.sh
#   bash setup.sh
#
# AFTER INSTALL:
#   - If port 3389 is not already open: Azure Portal → VM → Networking
#     → Add inbound rule → TCP 3389
#   - Connect via any RDP client to the VM's public IP
#   - Log in with your Azure username and password
#     (if SSH-key only: run  sudo passwd <your-username>  first)
#   - Double-click Open_Jupyter_Lab.html on the desktop
#
# REQUIREMENTS:
#   - Must run as a regular user WITH sudo privileges (e.g. azureuser)
#   - Do NOT run as root — the lab is built in $HOME, which root cannot RDP to
#   - Safe to re-run on a partially configured VM (all steps are idempotent)
# =============================================================================

set -euo pipefail

# =============================================================================
# GUARD: REFUSE TO RUN AS ROOT
# =============================================================================
# If run as root, $HOME is /root which is inaccessible over RDP.
# The desktop, venv, and Jupyter service must all live in the real user's HOME.
# =============================================================================

if [ "$EUID" -eq 0 ]; then
    echo ""
    echo "ERROR: Do not run this script as root."
    echo "       SSH in as your regular Azure user (e.g. azureuser) and try again."
    echo ""
    exit 1
fi

# =============================================================================
# CONFIGURATION
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
# HELPERS
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
    echo "Installation failed. Check: $LOG_FILE"
    exit 1
}

log_header() {
    echo "" >> "$LOG_FILE"
    echo "=============================================" >> "$LOG_FILE"
    echo "  $1" >> "$LOG_FILE"
    echo "=============================================" >> "$LOG_FILE"
}

# =============================================================================
# INIT LOG
# =============================================================================
# Desktop directory may not exist yet on a fresh server VM — create it first.
# =============================================================================

mkdir -p "$LAB_HOME/Desktop"

cat > "$LOG_FILE" << EOF
=============================================================================
AI Red Team Lab - Azure Admin Installation Log
=============================================================================
Date        : $(date)
User        : $LAB_USER
Home        : $LAB_HOME
Lab folder  : $LAB_DIR
Virtual env : $VENV_PATH
Jupyter URL : $JUPYTER_URL
GitHub raw  : $GITHUB_RAW
=============================================================================

EOF

echo ""
echo "============================================="
echo "  AI Red Team Lab — Azure Admin Installer"
echo "  User : $LAB_USER"
echo "  Log  : $LOG_FILE"
echo "============================================="
echo ""

# =============================================================================
# STEP 1 — SYSTEM UPDATE
# =============================================================================

print_header "STEP 1: System Update and Upgrade"
log_header  "STEP 1: System Update"

echo "--> Running apt update + upgrade (may take a few minutes)..."
sudo apt-get update  -y
sudo apt-get upgrade -y
print_ok "System packages up to date."

# =============================================================================
# STEP 2 — XFCE DESKTOP ENVIRONMENT
# =============================================================================
# Azure Ubuntu Server ships with no GUI at all. We install XFCE4 — the
# lightweight desktop recommended by Microsoft in their official Azure xrdp
# guide for Ubuntu 24.04:
#   https://learn.microsoft.com/en-us/azure/virtual-machines/linux/use-remote-desktop
#
# xfce4         : the core desktop environment
# xfce4-session : manages the XFCE user session lifecycle (login/logout)
# =============================================================================

print_header "STEP 2: XFCE Desktop Environment"
log_header  "STEP 2: XFCE"

if dpkg -l xfce4 &>/dev/null; then
    print_status "XFCE4 already installed — skipping."
else
    print_status "Installing XFCE4 desktop environment..."
    sudo apt-get install -y xfce4 xfce4-session 2>&1 | tee -a "$LOG_FILE"
    print_ok "XFCE4 installed."
fi

# =============================================================================
# STEP 3 — XRDP REMOTE DESKTOP SERVER
# =============================================================================
# xrdp is the open-source RDP server that lets Windows Remote Desktop
# Connection (and any RDP client) connect to this VM.
#
# These steps follow the official Microsoft Azure guide exactly:
#   https://learn.microsoft.com/en-us/azure/virtual-machines/linux/use-remote-desktop
#
# sudo apt install xrdp
#   Installs the xrdp daemon.
#
# sudo systemctl enable xrdp
#   Registers xrdp with systemd so it starts automatically on every boot.
#
# sudo adduser xrdp ssl-cert
#   Ubuntu 24.04 specific step from the Microsoft guide.
#   xrdp needs read access to the TLS certificate files to encrypt the
#   RDP connection. The ssl-cert group owns those files. Without this,
#   connections may silently fail on Ubuntu 24.
#
# echo xfce4-session > ~/.xsession
#   When xrdp starts a desktop session for a connecting user it reads
#   ~/.xsession to know which desktop environment to launch.
#   Without this file xrdp does not know to start XFCE and the session
#   fails with a blank or grey screen.
#
# sudo systemctl restart xrdp
#   Applies all the configuration changes above.
# =============================================================================

print_header "STEP 3: xrdp Remote Desktop Server"
log_header  "STEP 3: xrdp"

if dpkg -l xrdp &>/dev/null; then
    print_status "xrdp already installed — reconfiguring to ensure correct state."
else
    print_status "Installing xrdp..."
    sudo apt-get install -y xrdp 2>&1 | tee -a "$LOG_FILE"
    print_ok "xrdp installed."
fi

print_status "Enabling xrdp to start on every boot..."
sudo systemctl enable xrdp 2>&1 | tee -a "$LOG_FILE"

print_status "Granting xrdp access to SSL certificates (Ubuntu 24 requirement)..."
sudo adduser xrdp ssl-cert 2>&1 | tee -a "$LOG_FILE" || true
# || true: adduser exits 1 if the user is already in the group — that is fine

print_status "Configuring xrdp to launch XFCE on login..."
echo xfce4-session > "$LAB_HOME/.xsession"
print_ok ".xsession set to xfce4-session"

print_status "Restarting xrdp to apply all changes..."
sudo systemctl restart xrdp 2>&1 | tee -a "$LOG_FILE"

if sudo systemctl is-active --quiet xrdp; then
    print_ok "xrdp is running and listening on port 3389."
else
    print_warn "xrdp did not start cleanly. Check: sudo systemctl status xrdp"
fi

# =============================================================================
# STEP 4 — GOOGLE CHROME BROWSER
# =============================================================================
# Problem: XFCE has no browser installed by default. When a student
# double-clicks the Jupyter HTML shortcut, XFCE calls xdg-open to open
# the URL and fails with:
#   "xrdp failed to execute default web browser"
#
# Fix: Install Google Chrome and register it as the system default.
#
# We download the official .deb directly from Google (the same method
# used in the manual fix). The .deb also adds Google's apt repository
# so Chrome receives automatic updates via apt going forward.
#
# update-alternatives --set x-www-browser
#   Registers Chrome at the system level. Many tools and scripts check
#   this setting when they need to open a URL.
#
# xdg-settings set default-web-browser
#   Registers Chrome with the XDG desktop standard that XFCE uses when
#   a user double-clicks a file or URL on the desktop.
#
# --no-sandbox in the wrapper:
#   Chrome's security sandbox requires Linux kernel namespace features
#   that may be unavailable inside an RDP session without a full PAM
#   user session stack. --no-sandbox bypasses this so Chrome starts
#   reliably inside XFCE over RDP.
# =============================================================================

print_header "STEP 4: Google Chrome Browser"
log_header  "STEP 4: Chrome"

if command -v google-chrome-stable &>/dev/null || command -v google-chrome &>/dev/null; then
    print_status "Google Chrome already installed — skipping download."
else
    print_status "Downloading Google Chrome stable .deb..."
    curl -fsSL \
        "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" \
        -o /tmp/google-chrome-stable.deb 2>&1 | tee -a "$LOG_FILE"

    print_status "Installing Google Chrome..."
    sudo apt-get install -y /tmp/google-chrome-stable.deb 2>&1 | tee -a "$LOG_FILE"
    rm -f /tmp/google-chrome-stable.deb
    print_ok "Google Chrome installed."
fi

# Register as default at both system and XDG levels
print_status "Registering Chrome as the default browser..."
sudo update-alternatives --set x-www-browser \
    /usr/bin/google-chrome-stable 2>&1 | tee -a "$LOG_FILE" || true
xdg-settings set default-web-browser google-chrome.desktop 2>/dev/null || true
print_ok "Chrome registered as system default browser."

# Create a --no-sandbox wrapper so Chrome always starts correctly in RDP
print_status "Creating Chrome RDP wrapper (handles --no-sandbox for RDP sessions)..."
mkdir -p "$LAB_HOME/.local/bin"
cat > "$LAB_HOME/.local/bin/chrome-rdp" << 'CHROME_WRAPPER'
#!/bin/bash
exec /usr/bin/google-chrome-stable --no-sandbox "$@"
CHROME_WRAPPER
chmod +x "$LAB_HOME/.local/bin/chrome-rdp"

# Create a .desktop entry so XFCE's file manager uses the wrapper for HTML files
mkdir -p "$LAB_HOME/.local/share/applications"
cat > "$LAB_HOME/.local/share/applications/chrome-rdp.desktop" << DESKTOP_EOF
[Desktop Entry]
Name=Chrome (RDP)
Exec=$LAB_HOME/.local/bin/chrome-rdp %U
Type=Application
Terminal=false
MimeType=text/html;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;
DESKTOP_EOF

update-desktop-database "$LAB_HOME/.local/share/applications" 2>/dev/null || true
xdg-mime default chrome-rdp.desktop text/html 2>/dev/null || true
print_ok "Chrome wrapper set as handler for HTML files in XFCE."

# =============================================================================
# STEP 5 — EMOJI FONT + FONT CACHE REFRESH
# =============================================================================
# Azure Ubuntu XFCE VMs ship without colour emoji support. Without the
# Noto Color Emoji font, all emoji in Jupyter notebooks render as blank
# boxes. The lab notebooks use emoji as visual indicators throughout.
#
# fc-cache -f -v
#   Rebuilds the system-wide font cache. The -f flag forces a full rebuild,
#   -v prints verbose progress. This makes the new font available without
#   requiring a reboot or logout.
# =============================================================================

print_header "STEP 5: Emoji Font and Font Cache"
log_header  "STEP 5: Emoji Font"

if dpkg -l fonts-noto-color-emoji &>/dev/null; then
    print_status "Emoji font already installed — skipping."
else
    print_status "Installing Noto Color Emoji font..."
    sudo apt-get install -y fonts-noto-color-emoji 2>&1 | tee -a "$LOG_FILE"
    print_ok "Emoji font installed."
fi

print_status "Rebuilding font cache (fc-cache -f -v)..."
fc-cache -f -v 2>&1 | tee -a "$LOG_FILE"
print_ok "Font cache rebuilt. Emoji will render correctly in Jupyter."

# =============================================================================
# STEP 6 — PYTHON AND SYSTEM TOOLS
# =============================================================================

print_header "STEP 6: Python and System Tools"
log_header  "STEP 6: Python"

print_status "Installing Python and system tools..."
sudo apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-full \
    curl \
    git \
    unzip 2>&1 | tee -a "$LOG_FILE"

print_ok "Python version: $(python3 --version)"

# =============================================================================
# STEP 7 — PYTHON VIRTUAL ENVIRONMENT
# =============================================================================
# Ubuntu 24.04 enforces PEP 668 — pip cannot install into the system Python.
# A virtual environment is mandatory.
# =============================================================================

print_header "STEP 7: Python Virtual Environment"
log_header  "STEP 7: Venv"

if [ ! -d "$VENV_PATH" ]; then
    print_status "Creating virtual environment at: $VENV_PATH"
    python3 -m venv "$VENV_PATH" 2>&1 | tee -a "$LOG_FILE"
    print_ok "Virtual environment created."
else
    print_status "Virtual environment already exists — skipping creation."
fi

print_status "Activating virtual environment..."
. "$VENV_PATH/bin/activate"
print_ok "Virtual environment active."

# =============================================================================
# STEP 8 — UPGRADE PIP
# =============================================================================

print_header "STEP 8: Upgrade pip"
log_header  "STEP 8: pip"

pip install --upgrade pip 2>&1 | tee -a "$LOG_FILE"
print_ok "pip upgraded."

# =============================================================================
# STEP 9 — INSTALL PYTHON LIBRARIES
# =============================================================================

print_header "STEP 9: Python Libraries"
log_header  "STEP 9: Libraries"

print_status "Installing all required libraries (3-5 minutes)..."
pip install \
    adversarial-robustness-toolbox \
    scikit-learn \
    pandas \
    numpy \
    jupyterlab \
    matplotlib \
    seaborn \
    ipywidgets 2>&1 | tee -a "$LOG_FILE"

print_status "Installed versions:"
python3 -c "
import warnings; warnings.filterwarnings('ignore')
import sklearn, numpy, pandas, matplotlib, art
for lib, ver in {
    'scikit-learn': sklearn.__version__,
    'numpy':        numpy.__version__,
    'pandas':       pandas.__version__,
    'matplotlib':   matplotlib.__version__,
    'ART':          art.__version__,
}.items():
    print(f'  {lib:<20}: {ver}')
" 2>&1 | tee -a "$LOG_FILE"

print_ok "All libraries installed."

# =============================================================================
# STEP 10 — LAB FOLDER STRUCTURE
# =============================================================================

print_header "STEP 10: Lab Folder Structure"
log_header  "STEP 10: Folders"

mkdir -p "$LAB_DIR/datasets"
mkdir -p "$LAB_DIR/notebooks"
mkdir -p "$LAB_DIR/outputs"
print_ok "Folders created at: $LAB_DIR"

# =============================================================================
# STEP 11 — DOWNLOAD DATASETS
# =============================================================================

print_header "STEP 11: Downloading Datasets"
log_header  "STEP 11: Datasets"

print_status "Downloading Nursery dataset..."
curl -fsSL \
    "https://archive.ics.uci.edu/ml/machine-learning-databases/nursery/nursery.data" \
    -o "$LAB_DIR/datasets/nursery.data" 2>&1 | tee -a "$LOG_FILE"

[ -f "$LAB_DIR/datasets/nursery.data" ] \
    && print_ok "Nursery dataset: $(wc -l < "$LAB_DIR/datasets/nursery.data") records." \
    || print_error "Nursery dataset download failed."

print_status "Downloading SMS Spam dataset..."
curl -fsSL \
    "https://archive.ics.uci.edu/ml/machine-learning-databases/00228/smsspamcollection.zip" \
    -o "$LAB_DIR/datasets/sms_spam.zip" 2>&1 | tee -a "$LOG_FILE"

unzip -o "$LAB_DIR/datasets/sms_spam.zip" -d "$LAB_DIR/datasets/" 2>&1 | tee -a "$LOG_FILE"
rm -f "$LAB_DIR/datasets/sms_spam.zip" "$LAB_DIR/datasets/readme"

[ -f "$LAB_DIR/datasets/SMSSpamCollection" ] \
    && print_ok "SMS Spam dataset: $(wc -l < "$LAB_DIR/datasets/SMSSpamCollection") messages." \
    || print_error "SMS Spam extraction failed."

# =============================================================================
# STEP 12 — DOWNLOAD NOTEBOOKS FROM GITHUB
# =============================================================================

print_header "STEP 12: Downloading Lab Notebooks"
log_header  "STEP 12: Notebooks"

for NOTEBOOK in "${NOTEBOOKS[@]}"; do
    print_status "  Downloading $NOTEBOOK..."
    curl -fsSL "$GITHUB_RAW/$NOTEBOOK" \
        -o "$LAB_DIR/notebooks/$NOTEBOOK" 2>&1 | tee -a "$LOG_FILE"
    if [ -f "$LAB_DIR/notebooks/$NOTEBOOK" ]; then
        print_ok "  $NOTEBOOK"
    else
        print_warn "$NOTEBOOK download failed — copy manually from GitHub."
    fi
done

# =============================================================================
# STEP 13 — CONFIGURE JUPYTER
# =============================================================================
# Token is written to both config file variants that different Jupyter
# versions look for. Belt-and-suspenders — the primary guarantee is the
# token on the ExecStart command line in Step 14.
# =============================================================================

print_header "STEP 13: Jupyter Configuration"
log_header  "STEP 13: Jupyter Config"

mkdir -p "$LAB_HOME/.jupyter"

for CONFIG in \
    "$LAB_HOME/.jupyter/jupyter_lab_configuration.py" \
    "$LAB_HOME/.jupyter/jupyter_server_configuration.py"; do
cat > "$CONFIG" << EOF
# AI Red Team Lab - Jupyter Configuration
# Generated by lab_installer_admin.sh
c.ServerApp.token        = '${JUPYTER_TOKEN}'
c.ServerApp.open_browser = False
c.ServerApp.port         = ${JUPYTER_PORT}
c.ServerApp.root_dir     = '${LAB_DIR}/notebooks'
c.ServerApp.default_url  = '/lab/tree/START_HERE.ipynb'
c.ServerApp.ip           = '127.0.0.1'
c.ServerApp.password     = ''
EOF
done

print_ok "Jupyter config written. Token: $JUPYTER_TOKEN  Default: START_HERE.ipynb"

# =============================================================================
# STEP 14 — SYSTEMD SERVICE (JUPYTER AUTO-START ON BOOT)
# =============================================================================
# Token is passed directly on the ExecStart command line — the most reliable
# method. Works regardless of config file discovery or HOME env loading order.
# =============================================================================

print_header "STEP 14: Jupyter Auto-Start Systemd Service"
log_header  "STEP 14: Systemd"

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

sudo systemctl daemon-reload              2>&1 | tee -a "$LOG_FILE"
sudo systemctl enable jupyterlab.service  2>&1 | tee -a "$LOG_FILE"
sudo systemctl start  jupyterlab.service  2>&1 | tee -a "$LOG_FILE"

sleep 5

if sudo systemctl is-active --quiet jupyterlab.service; then
    print_ok "JupyterLab service is running."
else
    print_warn "JupyterLab did not start. Check: sudo systemctl status jupyterlab.service"
fi

# =============================================================================
# STEP 15 — DESKTOP HTML SHORTCUT
# =============================================================================

print_header "STEP 15: Desktop HTML Shortcut"
log_header  "STEP 15: Shortcut"

cat > "$LAB_HOME/Desktop/Open_Jupyter_Lab.html" << EOF
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
        <h1>AI Red Team Lab</h1>
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

print_ok "Desktop shortcut created: Open_Jupyter_Lab.html"

# =============================================================================
# STEP 16 — BACKUP LAUNCHER
# =============================================================================

print_header "STEP 16: Backup Jupyter Launcher"
log_header  "STEP 16: Backup Launcher"

cat > "$LAB_HOME/Desktop/start_jupyter.sh" << EOF
#!/bin/bash
# =============================================================================
# AI Red Team Lab - Backup Jupyter Launcher
# =============================================================================
# Use this if JupyterLab did not start automatically on boot.
# Open a terminal and run:  bash start_jupyter.sh
# Leave the terminal window open while using the lab.
# =============================================================================

echo ""
echo "Starting JupyterLab..."
echo ""
echo "Once started, open Chrome and go to:"
echo "  ${JUPYTER_URL}"
echo ""
echo "Or double-click Open_Jupyter_Lab.html on the Desktop."
echo "Press Ctrl+C to stop JupyterLab."
echo ""

. "${VENV_PATH}/bin/activate"
cd "${LAB_DIR}/notebooks"

jupyter lab \\
    --ServerApp.token='${JUPYTER_TOKEN}' \\
    --ServerApp.open_browser=False \\
    --ServerApp.port=${JUPYTER_PORT} \\
    --ServerApp.root_dir='${LAB_DIR}/notebooks' \\
    --ServerApp.default_url='/lab/tree/START_HERE.ipynb' \\
    --ServerApp.ip='127.0.0.1' \\
    --ServerApp.password=''
EOF

chmod +x "$LAB_HOME/Desktop/start_jupyter.sh"
print_ok "Backup launcher created: start_jupyter.sh"

# =============================================================================
# STEP 17 — FINAL VERIFICATION
# =============================================================================

print_header "STEP 17: Final Verification"
log_header  "STEP 17: Verification"

. "$VENV_PATH/bin/activate"

echo ""
echo "Library Check:" | tee -a "$LOG_FILE"
echo "----------------------------------------" | tee -a "$LOG_FILE"
python3 -c "
import sys, warnings; warnings.filterwarnings('ignore')
results = []
for lib, mod in [
    ('numpy',        'numpy'),
    ('pandas',       'pandas'),
    ('scikit-learn', 'sklearn'),
    ('matplotlib',   'matplotlib'),
    ('ART',          'art'),
]:
    try:
        m = __import__(mod)
        results.append((lib, m.__version__, True))
    except:
        results.append((lib, 'NOT FOUND', False))

all_ok = True
for name, ver, ok in results:
    tag = 'OK' if ok else 'MISSING'
    print(f'  [{tag}] {name:<20}: {ver}')
    if not ok: all_ok = False
print()
print('All libraries OK.' if all_ok else 'SOME LIBRARIES MISSING — re-run the script.')
" 2>&1 | tee -a "$LOG_FILE"

echo ""
echo "Dataset Check:" | tee -a "$LOG_FILE"
echo "----------------------------------------" | tee -a "$LOG_FILE"
for DS in "nursery.data" "SMSSpamCollection"; do
    if [ -f "$LAB_DIR/datasets/$DS" ]; then
        echo "  [OK] $DS ($(wc -l < "$LAB_DIR/datasets/$DS") lines)" | tee -a "$LOG_FILE"
    else
        echo "  [MISSING] $DS" | tee -a "$LOG_FILE"
    fi
done

echo ""
echo "Notebook Check:" | tee -a "$LOG_FILE"
echo "----------------------------------------" | tee -a "$LOG_FILE"
for NB in "${NOTEBOOKS[@]}"; do
    if [ -f "$LAB_DIR/notebooks/$NB" ]; then
        echo "  [OK] $NB" | tee -a "$LOG_FILE"
    else
        echo "  [MISSING] $NB" | tee -a "$LOG_FILE"
    fi
done

echo ""
echo "Services Check:" | tee -a "$LOG_FILE"
echo "----------------------------------------" | tee -a "$LOG_FILE"

if sudo systemctl is-active --quiet xrdp; then
    echo "  [OK] xrdp running on port 3389" | tee -a "$LOG_FILE"
else
    echo "  [STOPPED] xrdp — run: sudo systemctl start xrdp" | tee -a "$LOG_FILE"
fi

if sudo systemctl is-active --quiet jupyterlab.service; then
    echo "  [OK] JupyterLab service running" | tee -a "$LOG_FILE"
else
    echo "  [STOPPED] JupyterLab — use Desktop/start_jupyter.sh" | tee -a "$LOG_FILE"
fi

echo ""
echo "Desktop and Config Check:" | tee -a "$LOG_FILE"
echo "----------------------------------------" | tee -a "$LOG_FILE"

if command -v google-chrome-stable &>/dev/null; then
    echo "  [OK] Google Chrome: $(google-chrome-stable --version 2>/dev/null)" | tee -a "$LOG_FILE"
else
    echo "  [MISSING] Google Chrome" | tee -a "$LOG_FILE"
fi

if [ -f "$LAB_HOME/.xsession" ] && grep -q "xfce4-session" "$LAB_HOME/.xsession"; then
    echo "  [OK] ~/.xsession -> xfce4-session" | tee -a "$LOG_FILE"
else
    echo "  [MISSING] ~/.xsession not configured" | tee -a "$LOG_FILE"
fi

if dpkg -l fonts-noto-color-emoji &>/dev/null; then
    echo "  [OK] Emoji font installed" | tee -a "$LOG_FILE"
else
    echo "  [MISSING] Emoji font" | tee -a "$LOG_FILE"
fi

for F in "Open_Jupyter_Lab.html" "start_jupyter.sh" "lab_installer_log.txt"; do
    if [ -f "$LAB_HOME/Desktop/$F" ]; then
        echo "  [OK] Desktop/$F" | tee -a "$LOG_FILE"
    else
        echo "  [MISSING] Desktop/$F" | tee -a "$LOG_FILE"
    fi
done

# =============================================================================
# DONE
# =============================================================================

print_header "INSTALLATION COMPLETE"

FINISH_TIME=$(date)
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Done." >> "$LOG_FILE"

VM_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "  User        : $LAB_USER"
echo "  VM IP       : $VM_IP"
echo "  Jupyter URL : $JUPYTER_URL"
echo "  Token       : $JUPYTER_TOKEN"
echo "  Log file    : $LOG_FILE"
echo ""
echo "  ─────────────────────────────────────────────────────────"
echo "  NEXT STEPS"
echo "  ─────────────────────────────────────────────────────────"
echo ""
echo "  1. Open port 3389 in Azure (if not already done):"
echo "       Azure Portal -> VM -> Networking -> Add inbound rule"
echo "       Protocol: TCP   Destination port: 3389   Action: Allow"
echo ""
echo "  2. If you only have SSH keys (no password set):"
echo "       sudo passwd $LAB_USER"
echo ""
echo "  3. Connect via RDP:"
echo "       Windows : Start -> Remote Desktop Connection -> $VM_IP"
echo "       Mac     : Microsoft Remote Desktop -> Add PC -> $VM_IP"
echo "       Linux   : rdesktop $VM_IP  or  Remmina"
echo ""
echo "  4. Log in with username [ $LAB_USER ] and your password."
echo ""
echo "  5. On the XFCE desktop, double-click:"
echo "       Open_Jupyter_Lab.html"
echo "     Chrome opens and lands on START_HERE.ipynb automatically."
echo ""
echo "  JupyterLab starts automatically on every VM boot."
echo "  Finished: $FINISH_TIME"
echo ""
