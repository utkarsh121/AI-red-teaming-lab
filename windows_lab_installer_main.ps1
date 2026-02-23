# =============================================================================
# AI Red Team Lab - Windows Main Installer
# =============================================================================
# Course   : Certified AI Penetration Tester - Red Team (CAIPT-RT)
# File     : windows_lab_installer_main.ps1
# Platform : Windows 10 / Windows 11
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File windows_lab_installer_main.ps1
#
# What this script does:
#   - Checks for and installs Python 3 if missing
#   - Creates a Python virtual environment
#   - Installs all required Python libraries
#   - Creates lab folder structure on the Desktop
#   - Downloads datasets from UCI ML Repository
#   - Downloads notebooks from GitHub
#   - Configures Jupyter with hardcoded token and default notebook
#   - Creates a Windows Task Scheduler job for auto-start on login
#   - Creates a desktop HTML shortcut for one-click browser access
#   - Creates a backup start_jupyter.ps1 on the Desktop
#   - Writes a verbose log file to the Desktop
# =============================================================================

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# =============================================================================
# CONFIGURATION VARIABLES
# =============================================================================

$DesktopPath   = [Environment]::GetFolderPath("Desktop")
$UserHome      = $env:USERPROFILE
$VenvPath      = "$UserHome\lab_env"
$LabDir        = "$DesktopPath\AI_Red_Team_Lab"
$LogFile       = "$DesktopPath\lab_installer_log.txt"
$JupyterToken  = "airedteamlab"
$JupyterPort   = "8888"
$JupyterUrl    = "http://localhost:${JupyterPort}/lab?token=${JupyterToken}"
$GitHubRaw     = "https://raw.githubusercontent.com/utkarsh121/AI-red-teaming-lab/main"
$Notebooks     = @(
    "START_HERE.ipynb",
    "Lab1_Evasion_Attack.ipynb",
    "Lab2_Poisoning_Attack.ipynb",
    "Lab3_Inference_Attack.ipynb",
    "Lab4_Extraction_Attack.ipynb"
)

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

function Print-Header($msg) {
    Write-Host ""
    Write-Host "=============================================" -ForegroundColor Red
    Write-Host "  $msg"                                        -ForegroundColor Red
    Write-Host "=============================================" -ForegroundColor Red
}

function Print-Status($msg) {
    Write-Host "--> $msg" -ForegroundColor Yellow
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $LogFile -Value "[$timestamp] $msg"
}

function Print-OK($msg) {
    Write-Host "--> $msg" -ForegroundColor Green
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $LogFile -Value "[$timestamp] OK: $msg"
}

function Print-Error($msg) {
    Write-Host ""
    Write-Host "ERROR: $msg" -ForegroundColor Red
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $LogFile -Value "[$timestamp] ERROR: $msg"
    Write-Host "Check the log file: $LogFile"
    Read-Host "Press Enter to exit"
    exit 1
}

function Log-Header($msg) {
    Add-Content -Path $LogFile -Value ""
    Add-Content -Path $LogFile -Value "============================================="
    Add-Content -Path $LogFile -Value "  $msg"
    Add-Content -Path $LogFile -Value "============================================="
}

# =============================================================================
# START LOG FILE
# =============================================================================

$StartTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Set-Content -Path $LogFile -Value @"
=============================================================================
AI Red Team Lab - Windows Installation Log
=============================================================================
Date        : $StartTime
User        : $env:USERNAME
Home        : $UserHome
Lab folder  : $LabDir
Virtual env : $VenvPath
Jupyter URL : $JupyterUrl
GitHub repo : $GitHubRaw
=============================================================================

"@

Print-Status "Log file started at: $LogFile"

# =============================================================================
# SECTION 1: CHECK AND INSTALL PYTHON
# =============================================================================
# We check if Python 3 is already installed and meets minimum version.
# If not, we download the official installer from python.org and run it
# silently. The installer adds Python to PATH automatically.
# =============================================================================

Print-Header "STEP 1: Checking Python Installation"
Log-Header "STEP 1: Checking Python Installation"

$PythonOk = $false
try {
    $PyVersion = python --version 2>&1
    if ($PyVersion -match "Python 3\.(\d+)") {
        $Minor = [int]$Matches[1]
        if ($Minor -ge 9) {
            Print-OK "Python already installed: $PyVersion"
            $PythonOk = $true
        }
    }
} catch {}

if (-Not $PythonOk) {
    Print-Status "Python 3.9+ not found. Downloading official Python installer..."
    Print-Status "(This may take a few minutes)"

    $PyInstaller = "$env:TEMP\python_installer.exe"
    # Python 3.12 stable release
    $PyUrl = "https://www.python.org/ftp/python/3.12.0/python-3.12.0-amd64.exe"

    try {
        curl.exe -fsSL $PyUrl -o $PyInstaller
    } catch {
        Invoke-WebRequest -Uri $PyUrl -OutFile $PyInstaller
    }

    if (-Not (Test-Path $PyInstaller)) {
        Print-Error "Python installer download failed. Check your internet connection."
    }

    Print-Status "Running Python installer silently..."
    # /quiet        : no UI
    # InstallAllUsers=0 : install for current user only (no admin needed)
    # PrependPath=1 : add Python to PATH automatically
    Start-Process -FilePath $PyInstaller -ArgumentList "/quiet InstallAllUsers=0 PrependPath=1" -Wait

    # Refresh PATH so python command is available immediately
    $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH","User") + ";" + [System.Environment]::GetEnvironmentVariable("PATH","Machine")

    Print-OK "Python installed successfully."
}

$PyVersion = python --version 2>&1
Print-Status "Python version: $PyVersion"

# =============================================================================
# SECTION 2: CREATE PYTHON VIRTUAL ENVIRONMENT
# =============================================================================

Print-Header "STEP 2: Creating Python Virtual Environment"
Log-Header "STEP 2: Creating Python Virtual Environment"

if (-Not (Test-Path $VenvPath)) {
    Print-Status "Creating virtual environment at: $VenvPath"
    python -m venv $VenvPath 2>&1 | Tee-Object -Append -FilePath $LogFile
    Print-OK "Virtual environment created."
} else {
    Print-Status "Virtual environment already exists - skipping creation."
}

# Activate the virtual environment
Print-Status "Activating virtual environment..."
& "$VenvPath\Scripts\Activate.ps1"
Print-OK "Virtual environment activated."

# =============================================================================
# SECTION 3: UPGRADE PIP
# =============================================================================

Print-Header "STEP 3: Upgrading pip"
Log-Header "STEP 3: Upgrading pip"

Print-Status "Upgrading pip..."
python -m pip install --upgrade pip 2>&1 | Tee-Object -Append -FilePath $LogFile
Print-OK "pip upgraded."

# =============================================================================
# SECTION 4: INSTALL PYTHON LIBRARIES
# =============================================================================

Print-Header "STEP 4: Installing Python Libraries"
Log-Header "STEP 4: Installing Python Libraries"

Print-Status "Installing all required libraries..."
Print-Status "(This may take 3-5 minutes)"

pip install `
    adversarial-robustness-toolbox `
    scikit-learn `
    pandas `
    numpy `
    jupyterlab `
    matplotlib `
    seaborn `
    ipywidgets 2>&1 | Tee-Object -Append -FilePath $LogFile

Print-OK "All libraries installed."

# Log versions
python -c @"
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
"@ 2>&1 | Tee-Object -Append -FilePath $LogFile

# =============================================================================
# SECTION 5: CREATE LAB FOLDER STRUCTURE
# =============================================================================

Print-Header "STEP 5: Creating Lab Folder Structure"
Log-Header "STEP 5: Creating Lab Folder Structure"

New-Item -ItemType Directory -Force -Path "$LabDir\datasets"  | Out-Null
New-Item -ItemType Directory -Force -Path "$LabDir\notebooks" | Out-Null
New-Item -ItemType Directory -Force -Path "$LabDir\outputs"   | Out-Null

Print-OK "Lab folders created at: $LabDir"

# =============================================================================
# SECTION 6: DOWNLOAD DATASETS
# =============================================================================

Print-Header "STEP 6: Downloading Datasets"
Log-Header "STEP 6: Downloading Datasets"

# Nursery dataset
Print-Status "Downloading Nursery dataset..."
try {
    curl.exe -fsSL "https://archive.ics.uci.edu/ml/machine-learning-databases/nursery/nursery.data" `
        -o "$LabDir\datasets\nursery.data"
} catch {
    Invoke-WebRequest -Uri "https://archive.ics.uci.edu/ml/machine-learning-databases/nursery/nursery.data" `
        -OutFile "$LabDir\datasets\nursery.data"
}

if (Test-Path "$LabDir\datasets\nursery.data") {
    Print-OK "Nursery dataset downloaded."
} else {
    Print-Error "Nursery dataset download failed."
}

# SMS Spam dataset
Print-Status "Downloading SMS Spam dataset (zip)..."
try {
    curl.exe -fsSL "https://archive.ics.uci.edu/ml/machine-learning-databases/00228/smsspamcollection.zip" `
        -o "$LabDir\datasets\sms_spam.zip"
} catch {
    Invoke-WebRequest -Uri "https://archive.ics.uci.edu/ml/machine-learning-databases/00228/smsspamcollection.zip" `
        -OutFile "$LabDir\datasets\sms_spam.zip"
}

Print-Status "Extracting SMS Spam dataset..."
Expand-Archive -Path "$LabDir\datasets\sms_spam.zip" -DestinationPath "$LabDir\datasets\" -Force

Print-Status "Cleaning up zip and readme..."
Remove-Item -Force "$LabDir\datasets\sms_spam.zip"  -ErrorAction SilentlyContinue
Remove-Item -Force "$LabDir\datasets\readme"         -ErrorAction SilentlyContinue

if (Test-Path "$LabDir\datasets\SMSSpamCollection") {
    Print-OK "SMS Spam dataset ready."
} else {
    Print-Error "SMS Spam dataset extraction failed."
}

# =============================================================================
# SECTION 7: DOWNLOAD NOTEBOOKS
# =============================================================================

Print-Header "STEP 7: Downloading Lab Notebooks from GitHub"
Log-Header "STEP 7: Downloading Lab Notebooks from GitHub"

foreach ($Notebook in $Notebooks) {
    Print-Status "  Downloading $Notebook..."
    try {
        curl.exe -fsSL "$GitHubRaw/$Notebook" -o "$LabDir\notebooks\$Notebook"
    } catch {
        Invoke-WebRequest -Uri "$GitHubRaw/$Notebook" -OutFile "$LabDir\notebooks\$Notebook"
    }
    if (Test-Path "$LabDir\notebooks\$Notebook") {
        Print-OK "  $Notebook downloaded."
    } else {
        Write-Host "  WARNING: $Notebook download failed." -ForegroundColor Magenta
        Add-Content -Path $LogFile -Value "  WARNING: $Notebook download failed."
    }
}

# =============================================================================
# SECTION 8: CONFIGURE JUPYTER
# =============================================================================

Print-Header "STEP 8: Configuring Jupyter"
Log-Header "STEP 8: Configuring Jupyter"

$JupyterConfigDir = "$UserHome\.jupyter"
New-Item -ItemType Directory -Force -Path $JupyterConfigDir | Out-Null

$JupyterConfig = @"
# =============================================================================
# Jupyter Configuration - AI Red Team Lab (Windows)
# Generated by windows_lab_installer_main.ps1
# =============================================================================

c.ServerApp.token = '$JupyterToken'
c.ServerApp.open_browser = False
c.ServerApp.port = $JupyterPort
c.ServerApp.root_dir = r'$LabDir\notebooks'
c.ServerApp.default_url = '/lab/tree/START_HERE.ipynb'
c.ServerApp.ip = '127.0.0.1'
c.ServerApp.password = ''
"@

Set-Content -Path "$JupyterConfigDir\jupyter_lab_configuration.py"    -Value $JupyterConfig
Set-Content -Path "$JupyterConfigDir\jupyter_server_configuration.py" -Value $JupyterConfig

Print-OK "Jupyter configuration written."
Print-Status "Token set to   : $JupyterToken"
Print-Status "Default URL set: /lab/tree/START_HERE.ipynb"

# =============================================================================
# SECTION 9: CREATE WINDOWS TASK SCHEDULER JOB FOR AUTO-START ON LOGIN
# =============================================================================
# Windows Task Scheduler is the equivalent of Linux systemd for auto-starting
# programs. We create a task that runs Jupyter automatically when the user
# logs in, so students never need to start it manually.
#
# The task runs the backup launcher script at login using PowerShell.
# =============================================================================

Print-Header "STEP 9: Creating Task Scheduler Auto-Start Job"
Log-Header "STEP 9: Creating Task Scheduler Auto-Start Job"

# First create the backup launcher (needed by the scheduled task)
$BackupLauncher = "$DesktopPath\start_jupyter.ps1"

$LauncherContent = @"
# =============================================================================
# AI Red Team Lab - Backup Jupyter Launcher (Windows)
# =============================================================================
# Use this if JupyterLab does not start automatically on login.
# Double-click or run: powershell -ExecutionPolicy Bypass -File start_jupyter.ps1
# =============================================================================

Write-Host ""
Write-Host "=============================================" -ForegroundColor Red
Write-Host "  AI Red Team Lab - Starting JupyterLab"    -ForegroundColor Red
Write-Host "=============================================" -ForegroundColor Red
Write-Host ""

# Activate virtual environment
& "$VenvPath\Scripts\Activate.ps1"

Write-Host "JupyterLab is starting..." -ForegroundColor Yellow
Write-Host ""
Write-Host "Once started, open your browser and go to:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  $JupyterUrl" -ForegroundColor Green
Write-Host ""
Write-Host "Or double-click Open_Jupyter_Lab.html on the Desktop."
Write-Host ""
Write-Host "Close this window to stop JupyterLab."
Write-Host ""

Set-Location "$LabDir\notebooks"

# Token passed directly on command line for guaranteed authentication
jupyter lab ``
    --ServerApp.token='$JupyterToken' ``
    --ServerApp.open_browser=False ``
    --ServerApp.port=$JupyterPort ``
    --ServerApp.root_dir='$LabDir\notebooks' ``
    --ServerApp.default_url='/lab/tree/START_HERE.ipynb' ``
    --ServerApp.ip='127.0.0.1' ``
    --ServerApp.password=''
"@

Set-Content -Path $BackupLauncher -Value $LauncherContent
Print-OK "Backup launcher created at: $BackupLauncher"

# Now create the scheduled task that runs the launcher at login
Print-Status "Registering Windows Task Scheduler job..."

$TaskName   = "JupyterLab-AIRedTeamLab"
$Action     = New-ScheduledTaskAction `
    -Execute "PowerShell.exe" `
    -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$BackupLauncher`""
$Trigger    = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$Settings   = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 1)
$Principal  = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive

# Remove existing task if present (clean reinstall)
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue

Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $Action `
    -Trigger $Trigger `
    -Settings $Settings `
    -Principal $Principal `
    -Description "Starts JupyterLab for the AI Red Team Lab at user login" | Out-Null

Print-OK "Task Scheduler job registered: $TaskName"
Print-Status "Jupyter will now start automatically every time you log in."

# Start Jupyter right now without requiring a reboot
Print-Status "Starting JupyterLab now in the background..."
Start-Process PowerShell -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$BackupLauncher`"" -WindowStyle Hidden
Start-Sleep -Seconds 5
Print-OK "JupyterLab started in background."

# =============================================================================
# SECTION 10: CREATE DESKTOP HTML SHORTCUT
# =============================================================================

Print-Header "STEP 10: Creating Desktop HTML Shortcut"
Log-Header "STEP 10: Creating Desktop HTML Shortcut"

$HtmlShortcut = "$DesktopPath\Open_Jupyter_Lab.html"

$HtmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Opening AI Red Team Lab...</title>
    <meta http-equiv="refresh" content="2;url=$JupyterUrl">
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
        <p>If nothing happens, <a href="$JupyterUrl">click here</a></p>
        <br>
        <p>Manual URL:</p>
        <p class="token">$JupyterUrl</p>
        <br>
        <p style="font-size:0.85em; color:#606060;">
            Token: $JupyterToken &nbsp;|&nbsp; Port: $JupyterPort
        </p>
    </div>
</body>
</html>
"@

Set-Content -Path $HtmlShortcut -Value $HtmlContent
Print-OK "Desktop HTML shortcut created."

# =============================================================================
# SECTION 11: FINAL VERIFICATION
# =============================================================================

Print-Header "STEP 11: Final Verification"
Log-Header "STEP 11: Final Verification"

Print-Status "Running final checks..."
Write-Host ""

# Library check
python -c @"
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
"@ 2>&1 | Tee-Object -Append -FilePath $LogFile

Write-Host ""

# Dataset check
Write-Host "Dataset Check:" | Tee-Object -Append -FilePath $LogFile
Write-Host "----------------------------------------"
foreach ($ds in @("nursery.data", "SMSSpamCollection")) {
    if (Test-Path "$LabDir\datasets\$ds") {
        $msg = "  [OK] $ds"
    } else {
        $msg = "  [MISSING] $ds"
    }
    Write-Host $msg
    Add-Content -Path $LogFile -Value $msg
}

Write-Host ""

# Notebook check
Write-Host "Notebook Check:"
foreach ($nb in $Notebooks) {
    if (Test-Path "$LabDir\notebooks\$nb") {
        $msg = "  [OK] $nb"
    } else {
        $msg = "  [MISSING] $nb"
    }
    Write-Host $msg
    Add-Content -Path $LogFile -Value $msg
}

Write-Host ""

# Desktop files check
Write-Host "Desktop Files Check:"
foreach ($f in @("Open_Jupyter_Lab.html", "start_jupyter.ps1", "lab_installer_log.txt")) {
    if (Test-Path "$DesktopPath\$f") {
        $msg = "  [OK] $f"
    } else {
        $msg = "  [MISSING] $f"
    }
    Write-Host $msg
    Add-Content -Path $LogFile -Value $msg
}

# =============================================================================
# DONE
# =============================================================================

Print-Header "INSTALLATION COMPLETE"
Log-Header "INSTALLATION COMPLETE"

$FinishTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Print-OK "Installation finished at: $FinishTime"

Write-Host ""
Write-Host "  Lab folder  : $LabDir"          -ForegroundColor Cyan
Write-Host "  Jupyter URL : $JupyterUrl"       -ForegroundColor Cyan
Write-Host "  Token       : $JupyterToken"     -ForegroundColor Cyan
Write-Host "  Log file    : $LogFile"          -ForegroundColor Cyan
Write-Host ""
Write-Host "  Desktop shortcuts:" -ForegroundColor Cyan
Write-Host "    - Open_Jupyter_Lab.html   (double-click to open lab in browser)"
Write-Host "    - start_jupyter.ps1       (backup if auto-start stops working)"
Write-Host "    - lab_installer_log.txt   (this installation log)"
Write-Host ""
Write-Host "  JupyterLab starts automatically every time you log in." -ForegroundColor Green
Write-Host "  Students double-click the HTML shortcut and land on START_HERE." -ForegroundColor Green
Write-Host ""
Write-Host "  Good luck with the class!" -ForegroundColor Green
Write-Host ""

Add-Content -Path $LogFile -Value ""
Add-Content -Path $LogFile -Value "Installation completed successfully at: $FinishTime"

Read-Host "Press Enter to close this window"
