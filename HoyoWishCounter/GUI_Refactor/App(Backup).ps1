# --- CONFIGURATION (DEBUG MODE) ---
# ตั้งเป็น $true เพื่อให้แสดงข้อความในหน้าต่าง PowerShell (Console) ด้วย
# ตั้งเป็น $false เพื่อปิด (แสดงแค่ใน GUI)
# --- DEVELOPMENT CONFIGURATION ---
# ตั้งเป็น $true เพื่อบังคับเปิด Debug (ไม่สน Config) -> เหมาะสำหรับ Dev/Test
# ตั้งเป็น $false เพื่อให้ระบบไปอ่านค่าจาก Config ของผู้ใช้ (Production)
$script:DevBypassDebug = $false  

# ค่าเริ่มต้น: ให้เชื่อตัวแปร Bypass ก่อนเสมอ
$script:DebugMode = $script:DevBypassDebug
# --- VERSION CONTROL ---
$script:AppRoot = $PSScriptRoot
$script:AppVersion = "6.5.0"    # <--- แก้เลขเวอร์ชัน GUI ตรงนี้ที่เดียว จบ!
# ============================
#  GLOBAL ERROR TRAP (CRASH CATCHER)
# ============================
# 1. ดัก Error ทั่วไปใน PowerShell Scripts
$global:ErrorActionPreference = "Continue" # อย่าหยุดทำงานถ้าเจอ Error (แต่เราจะจดไว้)
# สร้างตัวแปรดัก Error (Trap)
trap {
    # เมื่อเกิด Error แดงๆ ขึ้น Code ในนี้จะทำงานทันที
    $err = $_.Exception.Message
    $stack = $_.InvocationInfo.PositionMessage
    Write-LogFile -Message "CRITICAL ERROR: $err`nLocation: $stack" -Level "CRASH"
    
    # (Optional) ถ้าอยากให้แจ้งเตือน User ด้วย
    # [System.Windows.Forms.MessageBox]::Show("Error Captured: $err", "System Error", 0, 16)
    
    continue # สั่งให้โปรแกรมพยายามรันต่อ (ถ้าไหว)
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms.DataVisualization
Add-Type -AssemblyName PresentationFramework


. "$PSScriptRoot\utils\Theme.ps1"

. "$PSScriptRoot\controllers\MainLogic.ps1"
. "$PSScriptRoot\controllers\ChartLogic.ps1"
# File: App.ps1

# --- 0. SPLASH SCREEN (PRO EDITION) ---
$splashPath = Join-Path $PSScriptRoot "Image\splash1.png"
$script:AbortLaunch = $false

# Error Handling รวม: ถ้าพังตรงไหน ให้หยุดดู Error ก่อนปิด
try {
    if (Test-Path $splashPath) {
        # 1. Setup Form
        $splash = New-Object System.Windows.Forms.Form
        $splashImg = [System.Drawing.Image]::FromFile($splashPath)
        $splash.BackgroundImage = $splashImg
        $splash.BackgroundImageLayout = "Stretch"
        $splash.Size = $splashImg.Size 
        $splash.FormBorderStyle = "None"
        $splash.StartPosition = "CenterScreen"
        $splash.ShowInTaskbar = $false
        
        # Setup Labels
        $lblStatus = New-Object System.Windows.Forms.Label
        $lblStatus.Size = New-Object System.Drawing.Size($splash.Width, 30)
        $lblStatus.Location = New-Object System.Drawing.Point(0, ($splash.Height - 40))
        $lblStatus.BackColor = "Transparent"; $lblStatus.ForeColor = "Black"
        $lblStatus.Font = New-Object System.Drawing.Font("Consolas", 9, [System.Drawing.FontStyle]::Bold)
        $lblStatus.Text = "Initializing..."
        $splash.Controls.Add($lblStatus)

        $loadBack = New-Object System.Windows.Forms.Panel
        $loadBack.Height = 6; $loadBack.Dock = "Bottom"; $loadBack.BackColor = [System.Drawing.Color]::FromArgb(40,40,40)
        $loadFill = New-Object System.Windows.Forms.Panel
        $loadFill.Height = 6; $loadFill.Width = 0; $loadFill.BackColor = "LimeGreen"
        $loadBack.Controls.Add($loadFill)
        $splash.Controls.Add($loadBack)
        
        $lblKill = New-Object System.Windows.Forms.Label
        $lblKill.Text = "X"; $lblKill.ForeColor = "Red"; $lblKill.BackColor = "Transparent"
        $lblKill.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
        $lblKill.Location = New-Object System.Drawing.Point(($splash.Width - 25), 5)
        $lblKill.Cursor = [System.Windows.Forms.Cursors]::Hand
        $lblKill.Add_Click({ $script:AbortLaunch = $true })
        $splash.Controls.Add($lblKill)

        $splash.Show()
        $splash.Refresh()

        # --- HELPER: อัปเดตข้อความ ---
        function Set-SplashLog {
            param($MsgUser, $Progress)
            $lblStatus.Text = "> $MsgUser"
            $loadFill.Width = ($splash.Width * $Progress / 100)
            [System.Windows.Forms.Application]::DoEvents()
            Start-Sleep -Milliseconds 50 
            if ($script:AbortLaunch) { $splash.Close(); exit }
        }

        # =========================================================
        #  STARTUP SEQUENCE (SAFE MODE)
        # =========================================================

        # 1. LOAD LOGGER (โหลดก่อนเพื่อนเลย กันตาย)
        Set-SplashLog "Initializing Logger..." 10
        $LogPath = Join-Path $PSScriptRoot "System\LogCreate.ps1"
        if (Test-Path $LogPath) { 
            . $LogPath
            Write-LogFile -Message "[Loader] Logger initialized manually in App.ps1" -Level "INFO"
        } else {
            Write-Host "CRITICAL: LogCreate.ps1 not found!" -ForegroundColor Red
        }

        # 2. LOAD SYSTEM LOADER (ให้มันโหลดไฟล์ที่เหลือ: UI, Data, Sound, etc.)
        Set-SplashLog "Loading System Components..." 30
        $SysLoaderPath = Join-Path $PSScriptRoot "System\SystemLoader.ps1"
        
        if (Test-Path $SysLoaderPath) {
            # หมายเหตุ: SystemLoader จะพยายามโหลด LogCreate ซ้ำอีกรอบ
            # ซึ่งใน PowerShell ไม่เป็นไร (แค่ทับฟังก์ชันเดิม) แต่มั่นใจได้ว่าไฟล์อื่นจะถูกโหลดครบ
            . $SysLoaderPath
        } else {
            Write-LogFile -Message "[Loader] SystemLoader.ps1 missing!" -Level "ERROR"
        }

        # 3. LOAD CORE ENGINE
        Set-SplashLog "Loading Core Engine..." 60
        $EnginePath = Join-Path $PSScriptRoot "Engine\HoyoEngine.ps1"
        if (Test-Path $EnginePath) { 
            . $EnginePath 
            Write-LogFile -Message "[Loader] Engine Loaded." -Level "INFO"
        } else {
            Write-LogFile -Message "[Loader] HoyoEngine.ps1 missing!" -Level "FATAL"
            throw "HoyoEngine missing"
        }

        # 4. CONFIG & LAUNCH
        Set-SplashLog "Reading Configuration..." 80
        if (-not $script:AppConfig) { $script:AppConfig = Get-AppConfig }

        Set-SplashLog "Ready. Launching..." 100
        Start-Sleep -Milliseconds 200

        $splash.Close()
        $splash.Dispose()
        $splashImg.Dispose()
    }
} catch {
    # ดักจับ Error ทั้งหมดที่ทำให้โปรแกรมเปิดไม่ขึ้น
    Write-Host "`n[FATAL ERROR] Launcher Crashed!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Yellow
    Write-Host $_.ScriptStackTrace -ForegroundColor Gray
    
    # ถ้ามี Logger แล้ว ให้บันทึก Error ลงไฟล์ด้วย
    if (Get-Command "Write-LogFile" -ErrorAction SilentlyContinue) {
        Write-LogFile -Message "[CRASH] $($_.Exception.Message)" -Level "FATAL"
    }

    Read-Host "Press Enter to exit..." # รอให้คนอ่าน Error ก่อนปิด
    exit
}

if ($script:AbortLaunch) { exit }


# 1. โหลด Config
if (Get-Command "Get-AppConfig" -ErrorAction SilentlyContinue) {
    $script:AppConfig = Get-AppConfig
} else {
    $script:AppConfig = @{ AccentColor = "Cyan"; Opacity = 1.0; AutoSendDiscord = $true; LastGame="Genshin" }
}



# --- GUI SETUP ---
. "$PSScriptRoot\views\MainLayout.ps1" 
Write-LogFile -Message "[System] Loaded component: MainLayout.ps1" -Level "INFO"



. "$PSScriptRoot\views\MenuBar.ps1"

Write-LogFile -Message "[System] Loaded component: Theme.ps1" -Level "INFO"
Write-LogFile -Message "[System] Loaded component: MainLogic.ps1" -Level "INFO"
Write-LogFile -Message "[System] Loaded component: ChartLogic.ps1" -Level "INFO"
Write-LogFile -Message "[System] Loaded component: MenuBar.ps1" -Level "INFO"



# --- ROW 1: GAME BUTTONS (Y=40) ---
. "$PSScriptRoot\views\GameSelector.ps1"
Write-LogFile -Message "[System] Loaded component: GameSelector.ps1" -Level "INFO"

# --- ROW 2: SETTINGS (RE-DESIGNED & FIXED) ---
. "$PSScriptRoot\views\SettingsPanel.ps1"
Write-LogFile -Message "[System] Loaded component: SettingsPanel.ps1" -Level "INFO"

# ============================================
#  --- ROW 3: PITY METER (Re-designed) ---
#  (ย้ายลงมาที่ Y=250 เพื่อหลบ Settings อันใหม่)
# ============================================
. "$PSScriptRoot\views\PityMeter.ps1"
Write-LogFile -Message "[System] Loaded component: PityMeter.ps1" -Level "INFO"


# ============================================
#  --- ROW 4: BUTTONS (No Loading Bar) ---
#  (ขยับขึ้นมาแทนที่ Progress Bar เดิมที่เอาออกไป)
# ============================================
. "$PSScriptRoot\views\ActionAndStats.ps1"
Write-LogFile -Message "[System] Loaded component: ActionAndStats.ps1" -Level "INFO"


# ============================================
#  --- ROW 5: SCOPE & FILTER (Redesigned) ---
# ============================================
. "$PSScriptRoot\views\FilterPanel.ps1"
Write-LogFile -Message "[System] Loaded component: FilterPanel.ps1" -Level "INFO"


# ============================================
#  ROW 6: LOG WINDOW (Moved Down to Y=540)
# ============================================
. "$PSScriptRoot\views\LogWindow.ps1"
Write-LogFile -Message "[System] Loaded component: LogWindow.ps1" -Level "INFO"

# ============================================
#  ROW 7: EXPORT (Moved Down to Y=850)
# ============================================
. "$PSScriptRoot\views\ExportPanel.ps1"
Write-LogFile -Message "[System] Loaded component: ExportPanel.ps1" -Level "INFO"
$form.Size = New-Object System.Drawing.Size(600, 950)

# ============================================
#  SIDE PANEL: ANALYTICS GRAPH (Hidden Area)
# ============================================
. "$PSScriptRoot\views\AnalyticsPanel.ps1"
Write-LogFile -Message "[System] Loaded component: AnalyticsPanel.ps1" -Level "INFO"


# ============================
#  STARTUP LOGIC (แก้ใหม่ - บังคับค่าตัวแปร)
# ============================

# 1. โหลด Config
if (-not $script:AppConfig) { $script:AppConfig = Get-AppConfig }

# [เพิ่มตรงนี้] ถ้ายังไม่มีไฟล์ ให้สร้างไฟล์ Default ทันทีเลย
if (-not (Test-Path "config.json")) {
    Save-AppConfig -ConfigObj $script:AppConfig
}

# LOGIC: ตัดสินใจว่าจะใช้ Debug Mode หรือไม่?
if ($script:DevBypassDebug) {
    # กรณี: นักพัฒนากำลังเทส (Force ON)
    $script:DebugMode = $true
    
    # (Optional) แจ้งเตือนใน Write-GuiLogหน่อยจะได้รู้ตัวว่า Bypass อยู่
    if ($txtLog) {
        $txtLog.AppendText("`n[DEV SYSTEM] Debug Bypass is ACTIVE (Ignoring Config)`n")
    }
} else {
    # กรณี: ใช้งานจริง (Production) -> เชื่อ Config
    $script:DebugMode = $script:AppConfig.DebugConsole
}

# 2. อ่านค่าจาก Config หรือใช้ Default เป็น Genshin
$targetGame = "Genshin"
if ($script:AppConfig.LastGame) { 
    $targetGame = $script:AppConfig.LastGame 
}


# 5. โหลดรายชื่อตู้ของเกมนั้นมารอไว้เลย
Update-BannerList
WriteGUI-Log "Welcome back! Selected Game: $targetGame" "Cyan"

# 6. Apply Settings อื่นๆ
Initialize-AppState


try {
    $logDir = Join-Path $PSScriptRoot "Logs"
    if (Test-Path $logDir) {
        # หาไฟล์ .log ที่เก่ากว่า 7 วัน
        $limitDate = (Get-Date).AddDays(-7)
        Get-ChildItem -Path $logDir -Filter "debug_*.log" | Where-Object { $_.LastWriteTime -lt $limitDate } | Remove-Item -Force -ErrorAction SilentlyContinue
    }
} catch {
    # ถ้าลบไม่ได้ก็ช่างมัน
}

# [ADD THIS] 7. โหลดข้อมูล Local History ของเกมล่าสุดทันที!
WriteGUI-Log "Welcome back! Selected Game: $targetGame" "Cyan"
Load-LocalHistory -GameName $script:CurrentGame

# ============================
#  SHOW UI
# ============================
Play-Sound "startup"
$form.ShowDialog() | Out-Null