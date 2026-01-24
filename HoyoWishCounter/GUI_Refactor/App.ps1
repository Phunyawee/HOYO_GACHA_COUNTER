# File: App.ps1
# ============================
#  0. BOOTSTRAP & TRACING (INIT SYSTEM)
# ============================
# ส่วนนี้ทำงานด้วย PowerShell ล้วนๆ ไม่พึ่งพาไฟล์อื่น
$BootLogDir = Join-Path $PSScriptRoot "Logs"
if (-not (Test-Path $BootLogDir)) { New-Item -ItemType Directory -Path $BootLogDir -Force | Out-Null }
$BootLogPath = Join-Path $BootLogDir "boot_trace.txt"

# ฟังก์ชัน Log แบบบ้านๆ แต่ชัวร์ (ใช้เฉพาะช่วงเปิดโปรแกรม)
function Write-BootTrace {
    param($Msg)
    $Time = Get-Date -Format "HH:mm:ss.fff"
    "[$Time] [BOOT] $Msg" | Out-File -FilePath $BootLogPath -Append -Encoding UTF8
}

# เริ่มบันทึกทันที
Write-BootTrace "=========================================="
Write-BootTrace "Application Launch Sequence Started"
Write-BootTrace "Runtime: PowerShell $($PSVersionTable.PSVersion)"

# ดัก Error ระดับ Code (Syntax/Loading Error) ตั้งแต่หัวม้วน
trap {
    $err = $_.Exception.Message
    $stack = $_.InvocationInfo.PositionMessage
    Write-BootTrace "FATAL CRASH TRAPPED: $err"
    Write-BootTrace "Location: $stack"
    # พยายามแสดง Dialog ถ้าทำได้
    try { [System.Windows.Forms.MessageBox]::Show("Critical Boot Error: $err", "Launch Failed") } catch {}
    exit 1
}

# ============================
#  1. GLOBAL & DEBUG SETUP
# ============================
$script:AppRoot = $PSScriptRoot
$script:AppVersion = "7.0.0"
$script:DevBypassDebug = $false  
$script:DebugMode = $script:DevBypassDebug
$global:ErrorActionPreference = "Continue"

# Setup Trap (Crash Catcher)
trap {
    $err = $_.Exception.Message
    $stack = $_.InvocationInfo.PositionMessage
    if (Get-Command "Write-LogFile" -ErrorAction SilentlyContinue) {
        Write-LogFile -Message "CRITICAL ERROR: $err`nLocation: $stack" -Level "CRASH"
    } else {
        Write-Host "CRITICAL ERROR: $err" -ForegroundColor Red
    }
    continue 
}

# Load Assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms.DataVisualization
Add-Type -AssemblyName PresentationFramework

Write-BootTrace "Loading Splash Screen..."
# ============================
#  2. SPLASH SCREEN & CORE LOADING
# ============================
$splashPath = Join-Path $PSScriptRoot "Image\splash1.png"
$script:AbortLaunch = $false

try {
    if (Test-Path $splashPath) {
        # --- SETUP SPLASH FORM ---
        $splash = New-Object System.Windows.Forms.Form
        $splashImg = [System.Drawing.Image]::FromFile($splashPath)
        $splash.BackgroundImage = $splashImg
        $splash.BackgroundImageLayout = "Stretch"
        $splash.Size = $splashImg.Size 
        $splash.FormBorderStyle = "None"
        $splash.StartPosition = "CenterScreen"
        $splash.ShowInTaskbar = $false
        
        # Label Status
        $lblStatus = New-Object System.Windows.Forms.Label
        $lblStatus.Size = New-Object System.Drawing.Size($splash.Width, 30)
        $lblStatus.Location = New-Object System.Drawing.Point(0, ($splash.Height - 40))
        $lblStatus.BackColor = "Transparent"; $lblStatus.ForeColor = "Black"
        $lblStatus.Font = New-Object System.Drawing.Font("Consolas", 9, [System.Drawing.FontStyle]::Bold)
        $lblStatus.Text = "Initializing..."
        $splash.Controls.Add($lblStatus)

        # Loading Bar
        $loadBack = New-Object System.Windows.Forms.Panel
        $loadBack.Height = 6; $loadBack.Dock = "Bottom"; $loadBack.BackColor = [System.Drawing.Color]::FromArgb(40,40,40)
        $loadFill = New-Object System.Windows.Forms.Panel
        $loadFill.Height = 6; $loadFill.Width = 0; $loadFill.BackColor = "LimeGreen"
        $loadBack.Controls.Add($loadFill)
        $splash.Controls.Add($loadBack)
        
        # Kill Button
        $lblKill = New-Object System.Windows.Forms.Label
        $lblKill.Text = "X"; $lblKill.ForeColor = "Red"; $lblKill.BackColor = "Transparent"
        $lblKill.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
        $lblKill.Location = New-Object System.Drawing.Point(($splash.Width - 25), 5)
        $lblKill.Cursor = [System.Windows.Forms.Cursors]::Hand
        $lblKill.Add_Click({ $script:AbortLaunch = $true })
        $splash.Controls.Add($lblKill)

        $splash.Show()
        $splash.Refresh()

        function Set-SplashLog {
            param($MsgUser, $Progress)
            $lblStatus.Text = "> $MsgUser"
            $loadFill.Width = ($splash.Width * $Progress / 100)
            [System.Windows.Forms.Application]::DoEvents()
            Start-Sleep -Milliseconds 50 
            if ($script:AbortLaunch) { $splash.Close(); exit }
        }

        # --- LOADING SEQUENCE ---
        Write-BootTrace "Executing SystemLoader..."
        # 2.1 Load Logger
        Set-SplashLog "Initializing Logger..." 10
        $LogPath = Join-Path $PSScriptRoot "System\LogCreate.ps1"
        if (Test-Path $LogPath) { . $LogPath }

        # 2.2 Load System Loader (Theme, Utils, Config Helper)
        Set-SplashLog "Loading System Components..." 30
        $SysLoaderPath = Join-Path $PSScriptRoot "System\SystemLoader.ps1"
        if (Test-Path $SysLoaderPath) { 
            . $SysLoaderPath 
        } else {
            # Fallback: ถ้าไม่มี Loader ให้โหลด Theme กับ Logic เองตรงนี้ (ตามโค้ดเดิมคุณ)
            . "$PSScriptRoot\utils\Theme.ps1"
        }

        # 2.3 Load Core Engine & Controllers
        Set-SplashLog "Loading Core Engine..." 60

        # รายชื่อไฟล์ Core ทั้งหมดที่ต้องโหลด
        $CoreFiles = @(
            "Engine\HoyoEngine.ps1",          # ตัวดึงกาชา (Backend)
            "controllers\MainLogic.ps1",      # ตัวคำนวณหน้าบ้าน (Frontend Logic)
            "controllers\ChartLogic.ps1"      # ตัวคำนวณกราฟ
        )

        foreach ($file in $CoreFiles) {
            $fPath = Join-Path $PSScriptRoot $file
            
            if (Test-Path $fPath) { 
                . $fPath 
                # ถ้ามี BootTrace ให้เขียนบันทึกด้วย
                if (Get-Command "Write-BootTrace" -ErrorAction SilentlyContinue) {
                    Write-BootTrace "Loaded Core: $file"
                }
            } else {
                # ถ้าไฟล์หาย ให้แจ้งเตือน แต่ลองรันต่อ
                Write-Host "WARNING: Core file missing: $file" -ForegroundColor Yellow
                if (Get-Command "Write-BootTrace" -ErrorAction SilentlyContinue) {
                    Write-BootTrace "MISSING Core: $file"
                }
            }
        }

        # 2.4 Load/Verify Config
        Set-SplashLog "Reading Configuration..." 80
        if (-not $script:AppConfig) { 
            if (Get-Command "Get-AppConfig" -ErrorAction SilentlyContinue) {
                $script:AppConfig = Get-AppConfig 
            } else {
                 # Config Default กรณีฉุกเฉิน
                 $script:AppConfig = @{ AccentColor = "Cyan"; Opacity = 1.0; AutoSendDiscord = $true; LastGame="Genshin" }
            }
        }
        
        # [CRITICAL STEP] Set Current Game Variable HERE before UI Loads
        if ($script:AppConfig.LastGame) { 
            $script:CurrentGame = $script:AppConfig.LastGame 
        } else {
            $script:CurrentGame = "Genshin"
        }

        Set-SplashLog "Ready. Launching..." 100
        Start-Sleep -Milliseconds 200

        $splash.Close()
        $splash.Dispose()
        $splashImg.Dispose()
    }
} catch {
    # Fatal Error Handler
    Write-Host "`n[FATAL ERROR] Launcher Crashed!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Yellow
    Read-Host "Press Enter to exit..."
    exit
}

if ($script:AbortLaunch) { exit }

Write-BootTrace "Executing ViewLoader..."
# ============================
#  3. GUI ASSEMBLY (BUILDING THE VIEW)
# ============================
# เรียก ViewLoader ตัวเดียวจบ!
$ViewLoaderPath = Join-Path $PSScriptRoot "views\ViewLoader.ps1"
if (Test-Path $ViewLoaderPath) {
    . $ViewLoaderPath
} else {
    # กรณีเลวร้ายสุด หา ViewLoader ไม่เจอ
    Write-Host "CRITICAL: ViewLoader.ps1 missing!" -ForegroundColor Red
    Write-LogFile -Message "CRITICAL: ViewLoader.ps1 missing at $ViewLoaderPath" -Level "FATAL"
    exit
}

# Finalize Size (Override if needed)
$form.Size = New-Object System.Drawing.Size(600, 950)


# ============================
#  4. POST-LOAD LOGIC
# ============================

# Debug Mode Override
if ($script:DevBypassDebug) {
    $script:DebugMode = $true
    if ($txtLog) { $txtLog.AppendText("`n[DEV] Debug Bypass ACTIVE`n") }
} else {
    $script:DebugMode = $script:AppConfig.DebugConsole
}

# Auto Create Config if missing
if (-not (Test-Path "config.json")) {
    if (Get-Command "Save-AppConfig" -ErrorAction SilentlyContinue) {
        Save-AppConfig -ConfigObj $script:AppConfig
    }
}

# Banner List Initialization
Update-BannerList
WriteGUI-Log "Welcome back! Selected Game: $($script:CurrentGame)" "Cyan"

# Initialize State
if (Get-Command "Initialize-AppState" -ErrorAction SilentlyContinue) {
    Initialize-AppState
}

# Clean Old Logs
try {
    $logDir = Join-Path $PSScriptRoot "Logs"
    if (Test-Path $logDir) {
        $limitDate = (Get-Date).AddDays(-7)
        Get-ChildItem -Path $logDir -Filter "debug_*.log" | Where-Object { $_.LastWriteTime -lt $limitDate } | Remove-Item -Force -ErrorAction SilentlyContinue
    }
} catch {}

# Load History Data (Last Step)
Load-LocalHistory -GameName $script:CurrentGame


# ============================
#  5. SHOW APPLICATION
# ============================
if (Get-Command "Play-Sound" -ErrorAction SilentlyContinue) { Play-Sound "startup" }
$form.ShowDialog() | Out-Null