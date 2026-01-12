# --- CONFIGURATION (DEBUG MODE) ---
# ตั้งเป็น $true เพื่อให้แสดงข้อความในหน้าต่าง PowerShell (Console) ด้วย
# ตั้งเป็น $false เพื่อปิด (แสดงแค่ใน GUI)
$script:DebugMode = $false 

# # Load Engine
# $EnginePath = Join-Path $PSScriptRoot "HoyoEngine.ps1"
# if (-not (Test-Path $EnginePath)) { 
#     [System.Windows.Forms.MessageBox]::Show("Error: HoyoEngine.ps1 not found!", "Error", 0, 16)
#     exit 
# }
#. $EnginePath # Load Functions

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms.DataVisualization

# --- 3. GLOBAL FONT SETTINGS (Refactored) ---
# Helper Function เล็กๆ เพื่อลดการเขียน New-Object ซ้ำๆ
function Get-GuiFont ($Family, $Size, $Style="Regular") {
    try {
        return New-Object System.Drawing.Font($Family, $Size, [System.Drawing.FontStyle]::$Style)
    } catch {
        # Fallback กรณี Font ไม่มี ให้ไปใช้ Arial/Courier แทน
        $Fallback = if ($Family -match "Consolas|Code") { "Courier New" } else { "Arial" }
        return New-Object System.Drawing.Font($Fallback, $Size, [System.Drawing.FontStyle]::$Style)
    }
}

# กำหนดตัวแปรแบบ Global ($script:) เพื่อให้ Function อื่น (เช่น Apply-ButtonStyle) มองเห็น
$script:fontNormal = Get-GuiFont "Segoe UI" 9
$script:fontBold   = Get-GuiFont "Segoe UI" 9 "Bold"
$script:fontHeader = Get-GuiFont "Segoe UI" 12 "Bold"
$script:fontLog    = Get-GuiFont "Consolas" 10


# ============================
#  FUNCTIONS
# ============================
# ฟังก์ชันแต่งปุ่ม Modern Style (ฉบับแก้ไข Scope)
function Apply-ButtonStyle {
    param($Button, $BaseColorName, $HoverColorName, $CustomFont)

    $Button.FlatStyle = "Flat"
    $Button.FlatAppearance.BorderSize = 0
    $Button.BackColor = [System.Drawing.Color]::FromName($BaseColorName)
    $Button.ForeColor = "White"
    $Button.Cursor = [System.Windows.Forms.Cursors]::Hand 
    
    if ($CustomFont) { $Button.Font = $CustomFont } 
    else { $Button.Font = $script:fontBold }

    # --- แก้ไขตรงนี้ ---
    # 1. ใช้ $this แทน $Button (เพื่อให้มันรู้ว่าคือปุ่มตัวเอง)
    # 2. ใช้ .GetNewClosure() เพื่อล็อคค่าสีไว้ในหน่วยความจำ ไม่ให้หายไปหลังจบฟังก์ชัน

    $enterEvent = { 
        $this.BackColor = [System.Drawing.Color]::FromName($HoverColorName) 
    }.GetNewClosure()

    $leaveEvent = { 
        if ($this.Enabled) {
            $this.BackColor = [System.Drawing.Color]::FromName($BaseColorName) 
        }
    }.GetNewClosure()

    $Button.Add_MouseEnter($enterEvent)
    $Button.Add_MouseLeave($leaveEvent)
}


# --- 0. SPLASH SCREEN (LOADING) ---
$splashPath = Join-Path $PSScriptRoot "splash1.png"
$script:AbortLaunch = $false # ตัวแปรเช็คว่ากดยกเลิกไหม

if (Test-Path $splashPath) {
    # 1. สร้างหน้าต่าง Splash
    $splash = New-Object System.Windows.Forms.Form
    $splashImg = [System.Drawing.Image]::FromFile($splashPath)
    $splash.BackgroundImage = $splashImg
    $splash.BackgroundImageLayout = "Stretch"
    $splash.Size = $splashImg.Size 
    $splash.FormBorderStyle = "None"       # ไร้ขอบ
    $splash.StartPosition = "CenterScreen" # กลางจอ
    $splash.ShowInTaskbar = $false        

    # --- ปุ่ม X (Close) ---
    $lblKill = New-Object System.Windows.Forms.Label
    $lblKill.Text = "X" 
    $lblKill.Font = New-Object System.Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Bold)
    $lblKill.Size = New-Object System.Drawing.Size(40, 40)
    $lblKill.TextAlign = "MiddleCenter"
    $lblKill.Cursor = [System.Windows.Forms.Cursors]::Hand
    
    # สไตล์ (แดง พื้นใส)
    $lblKill.ForeColor = "red"       
    $lblKill.BackColor = "Transparent" 

    # [จุดสำคัญ] คำนวณตำแหน่งขวาสุดจากขนาดรูปภาพ
    $RightX = $splashImg.Width - 40
    $lblKill.Location = New-Object System.Drawing.Point($RightX, 0)

    # Event
    $lblKill.Add_MouseEnter({ $lblKill.BackColor = "Crimson"; $lblKill.ForeColor = "White" })
    $lblKill.Add_MouseLeave({ $lblKill.BackColor = "Transparent"; $lblKill.ForeColor = "White" })
    $lblKill.Add_Click({ $script:AbortLaunch = $true })

    $splash.Controls.Add($lblKill)
    $lblKill.BringToFront()
    # ----------------------------------------

    # 2. สร้างหลอด Loading
    $loadBack = New-Object System.Windows.Forms.Panel
    $loadBack.Height = 6
    $loadBack.Dock = "Bottom"
    $loadBack.BackColor = [System.Drawing.Color]::FromArgb(40,40,40)
    
    $loadFill = New-Object System.Windows.Forms.Panel
    $loadFill.Height = 6
    $loadFill.Width = 0
    $loadFill.BackColor = "LimeGreen" 
    $loadFill.Left = 0
    
    $loadBack.Controls.Add($loadFill)
    $splash.Controls.Add($loadBack)

    # 3. โชว์หน้าต่าง
    $splash.Show()
    $splash.Refresh()

    # 4. จำลองการโหลด (Animation Loop)
    
    # ฟังก์ชันเช็คการยกเลิก (เพื่อความสะอาดของโค้ด)
    function Check-Abort {
        [System.Windows.Forms.Application]::DoEvents() # สำคัญมาก! ต้องมีเพื่อให้รับคลิกได้
        if ($script:AbortLaunch) {
            $splash.Close()
            $splash.Dispose()
            $splashImg.Dispose()
            exit # <--- ปิดโปรแกรมทันที
        }
    }

    # ช่วง 1: โหลดเร็ว
    for ($i = 0; $i -le 40; $i+=2) {
        Check-Abort # เช็คก่อนขยับหลอด
        $loadFill.Width = ($splash.Width * $i / 100)
        Start-Sleep -Milliseconds 10
    }

    # ช่วง 2: โหลด Engine จริง
    Check-Abort
    if (Test-Path (Join-Path $PSScriptRoot "HoyoEngine.ps1")) {
        . (Join-Path $PSScriptRoot "HoyoEngine.ps1")
    }
    
    # ช่วง 3: วิ่งให้เต็มหลอด
    for ($i = 41; $i -le 100; $i+=5) {
        Check-Abort # เช็คตลอดทาง
        $loadFill.Width = ($splash.Width * $i / 100)
        Start-Sleep -Milliseconds 20 
    }

    Start-Sleep -Milliseconds 200 # ค้างแป๊บนึง
    Check-Abort

    # ปิด Splash ปกติ (ถ้าไม่ถูกยกเลิก)
    $splash.Close()
    $splash.Dispose()
    $splashImg.Dispose()
}

# ถ้ากดยกเลิกจังหวะสุดท้ายก่อนปิด Loop
if ($script:AbortLaunch) { exit }

# --- GUI SETUP ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "Universal Hoyo Wish Counter (Final)"
$form.Size = New-Object System.Drawing.Size(600, 820) # เพิ่มความสูงนิดนึงรับปุ่ม Export
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$form.ForeColor = "White"

# ============================
#  UI SECTION (FIXED LAYOUT)
# ============================

# --- FORM SETUP ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "Universal Hoyo Wish Counter (Final)"
$form.Size = New-Object System.Drawing.Size(600, 900)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$form.ForeColor = "White"
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false

# --- TOOLTIP MANAGER ---
$toolTip = New-Object System.Windows.Forms.ToolTip
$toolTip.AutoPopDelay = 5000    # โชว์นาน 5 วิ
$toolTip.InitialDelay = 500     # รอ 0.5 วิค่อยขึ้น
$toolTip.ReshowDelay = 500      # ถ้าขยับเมาส์ไปตัวอื่นก็รอ 0.5 วิ
$toolTip.ShowAlways = $true
$toolTip.IsBalloon = $false     # เอาแบบสี่เหลี่ยมเรียบๆ (ถ้าอยากได้บอลลูนแก้เป็น $true)

# --- MENU BAR (อยู่บนสุด) ---
$menuStrip = New-Object System.Windows.Forms.MenuStrip
$menuStrip.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
$menuStrip.ForeColor = "White"
$form.Controls.Add($menuStrip)
$form.MainMenuStrip = $menuStrip


# เมนู File
$menuFile = New-Object System.Windows.Forms.ToolStripMenuItem("File")
[void]$menuStrip.Items.Add($menuFile)

# เมนูย่อย Reset
$itemClear = New-Object System.Windows.Forms.ToolStripMenuItem("Reset / Clear All")
$itemClear.ShortcutKeys = [System.Windows.Forms.Keys]::F5
$itemClear.Add_Click({
    Log ">>> User requested RESET. Clearing all data... <<<" "OrangeRed"
    
    # 1. Clear Data & UI เดิม
    $txtLog.Clear()
    $script:pnlPityFill.Width = 0
    $script:lblPityTitle.Text = "Current Pity Progress: 0 / 90"; $script:lblPityTitle.ForeColor = "White"; $script:pnlPityFill.BackColor = "LimeGreen"
    $script:LastFetchedData = @()
    $script:FilteredData = @()
    $script:progressBar.Value = 0
    $btnExport.Enabled = $false; $btnExport.BackColor = "DimGray"
    $lblStat1.Text = "Total Pulls: 0"; $script:lblStatAvg.Text = "Avg. Pity: -"; $script:lblStatAvg.ForeColor = "White"
    $script:lblStatCost.Text = "Est. Cost: 0"
    
    # --- [NEW] 2. Reset Filter Panel ---
    $grpFilter.Enabled = $false
    $chkFilterEnable.Checked = $false
    $dtpStart.Value = Get-Date # Reset วันที่
    $dtpEnd.Value = Get-Date
    
    # --- [NEW] 3. Clear Graph & Panel ---
    $chart.Series.Clear()
    $chart.Visible = $false
    $lblNoData.Visible = $true
    
    # ถ้ากราฟเปิดอยู่ ให้ยุบกลับด้วย (Optional) หรือจะเปิดค้างไว้แต่โล่งๆ ก็ได้
    # ถ้าอยากยุบกลับ:
    if ($script:isExpanded) {
        $form.Width = 600
        $menuExpand.Text = ">> Show Graph"
        $script:isExpanded = $false
    }

    Log "--- System Reset Complete. Ready. ---" "Gray"
})
[void]$menuFile.DropDownItems.Add($itemClear)

# เมนูย่อย Exit
$itemExit = New-Object System.Windows.Forms.ToolStripMenuItem("Exit")
$itemExit.Add_Click({ $form.Close() })
[void]$menuFile.DropDownItems.Add($itemExit)

# 2. [NEW] ปุ่ม Toggle Expand (ขวาสุด)
$menuExpand = New-Object System.Windows.Forms.ToolStripMenuItem(">> Show Graph")
$menuExpand.Alignment = "Right" # สั่งชิดขวา
$menuExpand.ForeColor = "Cyan"  # สีฟ้าเด่นๆ
$menuExpand.Font = $script:fontBold
[void]$menuStrip.Items.Add($menuExpand)

# ตัวแปรสถานะ
$script:isExpanded = $false

# Event คลิกปุ่มนี้
$menuExpand.Add_Click({
    if ($script:isExpanded) {
        # ยุบกลับ
        $form.Width = 600
        $menuExpand.Text = ">> Show Graph"
        $script:isExpanded = $false
    } else {
        # ขยายออก
        $form.Width = 1200
        $menuExpand.Text = "<< Hide Graph"
        $script:isExpanded = $true
        
        $pnlChart.Size = New-Object System.Drawing.Size(580, 880)

        # สั่งวาดกราฟ (ถ้ามีข้อมูล)
        if ($grpFilter.Enabled) { Update-FilteredView }
    }
})

# --- ROW 1: GAME BUTTONS (Y=40) ---
$btnGenshin = New-Object System.Windows.Forms.Button
$btnGenshin.Text = "Genshin"
$btnGenshin.Location = New-Object System.Drawing.Point(20, 40); 
$btnGenshin.Size = New-Object System.Drawing.Size(170, 45)
$btnGenshin.FlatStyle = "Flat"; $btnGenshin.BackColor = "Gold"; 
$btnGenshin.ForeColor = "Black"; $btnGenshin.FlatAppearance.BorderSize = 0
$btnGenshin.Font = $script:fontHeader  # <--- เพิ่มบรรทัดนี้ (ใช้ Font ใหญ่)
$form.Controls.Add($btnGenshin)

$btnHSR = New-Object System.Windows.Forms.Button
$btnHSR.Text = "Star Rail"
$btnHSR.Location = New-Object System.Drawing.Point(210, 40);
$btnHSR.Size = New-Object System.Drawing.Size(170, 45)
$btnHSR.FlatStyle = "Flat"; 
$btnHSR.BackColor = "Gray"; 
$btnHSR.FlatAppearance.BorderSize = 0
$btnHSR.Font = $script:fontHeader      # <--- เพิ่มบรรทัดนี้ (ใช้ Font ใหญ่)
$form.Controls.Add($btnHSR)

$btnZZZ = New-Object System.Windows.Forms.Button
$btnZZZ.Text = "ZZZ"
$btnZZZ.Location = New-Object System.Drawing.Point(400, 40); 
$btnZZZ.Size = New-Object System.Drawing.Size(170, 45)
$btnZZZ.FlatStyle = "Flat"; 
$btnZZZ.BackColor = "Gray"; 
$btnZZZ.FlatAppearance.BorderSize = 0
$btnZZZ.Font = $script:fontHeader      # <--- เพิ่มบรรทัดนี้ (ใช้ Font ใหญ่)
$form.Controls.Add($btnZZZ)

# --- ROW 2: SETTINGS (Y=100) ---
# ขยับหนีปุ่มด้านบนลงมาที่ Y=100 (เดิม 80 ชนกัน)
$grpSettings = New-Object System.Windows.Forms.GroupBox
$grpSettings.Text = " Settings "
$grpSettings.Location = New-Object System.Drawing.Point(20, 100); $grpSettings.Size = New-Object System.Drawing.Size(550, 110)
$grpSettings.ForeColor = "White"
$form.Controls.Add($grpSettings)

$txtPath = New-Object System.Windows.Forms.TextBox
$txtPath.Location = New-Object System.Drawing.Point(15, 25); $txtPath.Size = New-Object System.Drawing.Size(350, 25)
$txtPath.BackColor = [System.Drawing.Color]::FromArgb(50,50,50); $txtPath.ForeColor = "White"; $txtPath.BorderStyle = "FixedSingle"
$grpSettings.Controls.Add($txtPath)

$btnAuto = New-Object System.Windows.Forms.Button
$btnAuto.Text = "Auto-Detect"
$btnAuto.Location = New-Object System.Drawing.Point(375, 24); $btnAuto.Size = New-Object System.Drawing.Size(80, 27)

# Style
$btnAuto.BackColor = "DodgerBlue"  # สีฟ้าสด
$btnAuto.ForeColor = "White"
$btnAuto.FlatStyle = "Flat"
$btnAuto.FlatAppearance.BorderSize = 0
$btnAuto.Font = $script:fontNormal        # ใช้ตัวแปร Font
$btnAuto.Cursor = [System.Windows.Forms.Cursors]::Hand

# Hover Effect (ฟ้าสว่างขึ้น)
$btnAuto.Add_MouseEnter({ $btnAuto.BackColor = "DeepSkyBlue" })
$btnAuto.Add_MouseLeave({ $btnAuto.BackColor = "DodgerBlue" })

$grpSettings.Controls.Add($btnAuto)

$btnBrowse = New-Object System.Windows.Forms.Button
$btnBrowse.Text = "..."
$btnBrowse.Location = New-Object System.Drawing.Point(465, 24); $btnBrowse.Size = New-Object System.Drawing.Size(70, 27)

# Style
$btnBrowse.BackColor = "DimGray"
$btnBrowse.ForeColor = "White"
$btnBrowse.FlatStyle = "Flat"
$btnBrowse.FlatAppearance.BorderSize = 0
$btnBrowse.Font = $script:fontNormal      # ใช้ตัวแปร Font
$btnBrowse.Cursor = [System.Windows.Forms.Cursors]::Hand

# Hover Effect (เทาสว่างขึ้น)
$btnBrowse.Add_MouseEnter({ $btnBrowse.BackColor = "Gray" })
$btnBrowse.Add_MouseLeave({ $btnBrowse.BackColor = "DimGray" })

$grpSettings.Controls.Add($btnBrowse)

$chkSendDiscord = New-Object System.Windows.Forms.CheckBox
$chkSendDiscord.Text = "Send Discord"; $chkSendDiscord.Location = New-Object System.Drawing.Point(15, 60); $chkSendDiscord.AutoSize = $true
$chkSendDiscord.ForeColor = "Cyan"; $chkSendDiscord.Checked = $true
$grpSettings.Controls.Add($chkSendDiscord)
$toolTip.SetToolTip($chkSendDiscord, "Auto-Send: Automatically sends a FULL REPORT to Discord immediately after fetching completes.")

$chkShowNo = New-Object System.Windows.Forms.CheckBox
$chkShowNo.Text = "Show [No.]"; $chkShowNo.Location = New-Object System.Drawing.Point(15, 82); $chkShowNo.AutoSize = $true
$chkShowNo.ForeColor = "Silver"
$grpSettings.Controls.Add($chkShowNo)

$lblBanner = New-Object System.Windows.Forms.Label
$lblBanner.Text = "Banner:"; $lblBanner.AutoSize = $true; $lblBanner.Location = New-Object System.Drawing.Point(140, 66)
$grpSettings.Controls.Add($lblBanner)

$script:cmbBanner = New-Object System.Windows.Forms.ComboBox
$script:cmbBanner.Location = New-Object System.Drawing.Point(200, 62); $script:cmbBanner.Size = New-Object System.Drawing.Size(335, 25)
$script:cmbBanner.DropDownStyle = "DropDownList"
$script:cmbBanner.BackColor = [System.Drawing.Color]::FromArgb(50,50,50); $script:cmbBanner.ForeColor = "White"; $script:cmbBanner.FlatStyle = "Flat"
$grpSettings.Controls.Add($script:cmbBanner)

# --- ROW 3: PITY METER (Y=225) ---
# ขยับลงมาตามลำดับ
$script:lblPityTitle = New-Object System.Windows.Forms.Label
$script:lblPityTitle.Text = "Current Pity Progress: 0 / 90"; 
$script:lblPityTitle.Location = New-Object System.Drawing.Point(20, 225); 
$script:lblPityTitle.AutoSize = $true
$form.Controls.Add($script:lblPityTitle)

$pnlPityBack = New-Object System.Windows.Forms.Panel
$pnlPityBack.Location = New-Object System.Drawing.Point(20, 245); $pnlPityBack.Size = New-Object System.Drawing.Size(550, 25)
$pnlPityBack.BackColor = [System.Drawing.Color]::FromArgb(60,60,60)
$form.Controls.Add($pnlPityBack)

$script:pnlPityFill = New-Object System.Windows.Forms.Panel
$script:pnlPityFill.Location = New-Object System.Drawing.Point(0, 0); $script:pnlPityFill.Size = New-Object System.Drawing.Size(0, 25)
$script:pnlPityFill.BackColor = "LimeGreen"
$pnlPityBack.Controls.Add($script:pnlPityFill)

# --- ROW 4: BUTTONS & PROGRESS (Y=285) ---
$script:progressBar = New-Object System.Windows.Forms.ProgressBar
$script:progressBar.Location = New-Object System.Drawing.Point(20, 285); $script:progressBar.Size = New-Object System.Drawing.Size(550, 10)
$form.Controls.Add($script:progressBar)

# --- ROW 4: BUTTONS & PROGRESS ---
# Button: START FETCHING
$btnRun = New-Object System.Windows.Forms.Button
$btnRun.Text = "START FETCHING"; $btnRun.Location = New-Object System.Drawing.Point(20, 305); $btnRun.Size = New-Object System.Drawing.Size(400, 45)
# บรรทัดนี้จัดการสีและฟอนต์ให้แล้ว
Apply-ButtonStyle -Button $btnRun -BaseColorName "ForestGreen" -HoverColorName "LimeGreen" -CustomFont $script:fontHeader
$form.Controls.Add($btnRun)

$btnStop = New-Object System.Windows.Forms.Button
$btnStop.Text = "STOP"; 
$btnStop.Location = New-Object System.Drawing.Point(430, 305); 
$btnStop.Size = New-Object System.Drawing.Size(140, 45)
$btnStop.BackColor = "Firebrick"; 
$btnStop.ForeColor = "White"; 
$btnStop.Font = $script:fontBold
$btnStop.FlatStyle = "Flat"; 
$btnStop.FlatAppearance.BorderSize = 0
$btnStop.Enabled = $false
$form.Controls.Add($btnStop)

# --- ROW 4.5: STATS DASHBOARD (Y=360) [NEW!] ---
$grpStats = New-Object System.Windows.Forms.GroupBox
$grpStats.Text = " Luck Analysis (Based on fetched data) "
$grpStats.Location = New-Object System.Drawing.Point(20, 360); $grpStats.Size = New-Object System.Drawing.Size(550, 60)
$grpStats.ForeColor = "Silver"
$form.Controls.Add($grpStats)

# Label 1: Total Pulls
$lblStat1 = New-Object System.Windows.Forms.Label
$lblStat1.Text = "Total Pulls: 0"; $lblStat1.AutoSize = $true
$lblStat1.Location = New-Object System.Drawing.Point(20, 25); 
$lblStat1.Font = $script:fontNormal
$grpStats.Controls.Add($lblStat1)

# Label 2: Avg Pity (Highlight)
$script:lblStatAvg = New-Object System.Windows.Forms.Label
$script:lblStatAvg.Text = "Avg. Pity: -"; $script:lblStatAvg.AutoSize = $true
$script:lblStatAvg.Location = New-Object System.Drawing.Point(200, 25); 
$script:lblStatAvg.Font = $script:fontBold
$script:lblStatAvg.ForeColor = "White"
$grpStats.Controls.Add($script:lblStatAvg)

# Label 3: Cost
$script:lblStatCost = New-Object System.Windows.Forms.Label
$script:lblStatCost.Text = "Est. Cost: 0"; $script:lblStatCost.AutoSize = $true
$script:lblStatCost.Location = New-Object System.Drawing.Point(380, 25); 
$script:lblStatCost.Font = $script:fontNormal
$script:lblStatCost.ForeColor = "Gold" # สีทองให้ดูแพง
$grpStats.Controls.Add($script:lblStatCost)

# ============================================
#  --- ROW 5: SCOPE & FILTER (Redesigned) ---
# ============================================
$grpFilter = New-Object System.Windows.Forms.GroupBox
$grpFilter.Text = " Scope & Analysis (Time Machine) "
$grpFilter.Location = New-Object System.Drawing.Point(20, 430)
$grpFilter.Size = New-Object System.Drawing.Size(550, 95) # ความสูงกระชับขึ้น
$grpFilter.ForeColor = "Silver"
$grpFilter.Enabled = $false
$form.Controls.Add($grpFilter)

# --- แถวที่ 1: เปิดใช้งาน และ วันที่ (Y=22) ---

# 1. Checkbox เปิด Filter
$chkFilterEnable = New-Object System.Windows.Forms.CheckBox
$chkFilterEnable.Text = "Enable Filter"
$chkFilterEnable.Location = New-Object System.Drawing.Point(15, 22)
$chkFilterEnable.Size = New-Object System.Drawing.Size(100, 20)
$chkFilterEnable.AutoSize = $true
$chkFilterEnable.ForeColor = "Cyan"
$chkFilterEnable.Cursor = [System.Windows.Forms.Cursors]::Hand
$grpFilter.Controls.Add($chkFilterEnable)

# 2. Date Pickers (จัดกึ่งกลางค่อนขวา)
$lblFrom = New-Object System.Windows.Forms.Label
$lblFrom.Text = "From:"
$lblFrom.Location = New-Object System.Drawing.Point(160, 24); $lblFrom.AutoSize = $true
$grpFilter.Controls.Add($lblFrom)

$dtpStart = New-Object System.Windows.Forms.DateTimePicker
$dtpStart.Location = New-Object System.Drawing.Point(200, 21); $dtpStart.Size = New-Object System.Drawing.Size(105, 23)
$dtpStart.Format = "Short"
$grpFilter.Controls.Add($dtpStart)

$lblTo = New-Object System.Windows.Forms.Label
$lblTo.Text = "To:"
$lblTo.Location = New-Object System.Drawing.Point(315, 24); $lblTo.AutoSize = $true
$grpFilter.Controls.Add($lblTo)

$dtpEnd = New-Object System.Windows.Forms.DateTimePicker
$dtpEnd.Location = New-Object System.Drawing.Point(340, 21); $dtpEnd.Size = New-Object System.Drawing.Size(105, 23)
$dtpEnd.Format = "Short"
$grpFilter.Controls.Add($dtpEnd)

# --- แถวที่ 2: ตั้งค่า Pity / Sort / ปุ่ม Action (Y=55) ---

# 3. Radio Buttons (Pity Mode) - วางชิดซ้าย
$radModeAbs = New-Object System.Windows.Forms.RadioButton
$radModeAbs.Text = "True Pity"
$radModeAbs.Location = New-Object System.Drawing.Point(15, 55); $radModeAbs.Size = New-Object System.Drawing.Size(75, 20)
$radModeAbs.Checked = $true
$grpFilter.Controls.Add($radModeAbs)

$radModeRel = New-Object System.Windows.Forms.RadioButton
$radModeRel.Text = "Reset (1)"
$radModeRel.Location = New-Object System.Drawing.Point(95, 55); $radModeRel.Size = New-Object System.Drawing.Size(75, 20)
$grpFilter.Controls.Add($radModeRel)

# 4. Checkbox Sort (วางต่อจาก Radio เพื่อประหยัดที่)
$chkSortDesc = New-Object System.Windows.Forms.CheckBox
$chkSortDesc.Text = "Newest First"
$chkSortDesc.Location = New-Object System.Drawing.Point(175, 55)
$chkSortDesc.Size = New-Object System.Drawing.Size(100, 20)
$chkSortDesc.Checked = $true
$chkSortDesc.ForeColor = "Gold" # เปลี่ยนสีให้เด่นนิดนึง
$grpFilter.Controls.Add($chkSortDesc)

# 5. ปุ่ม Action (วางขวาสุด)
$btnSmartSnap = New-Object System.Windows.Forms.Button
$btnSmartSnap.Text = "Snap Reset"
$btnSmartSnap.Location = New-Object System.Drawing.Point(300, 51)
$btnSmartSnap.Size = New-Object System.Drawing.Size(100, 28)
$btnSmartSnap.BackColor = "DimGray"; $btnSmartSnap.ForeColor = "White"
$btnSmartSnap.FlatStyle = "Flat"; $btnSmartSnap.FlatAppearance.BorderSize = 0
$grpFilter.Controls.Add($btnSmartSnap)

$btnDiscordScope = New-Object System.Windows.Forms.Button
$btnDiscordScope.Text = "Discord Report"
$btnDiscordScope.Location = New-Object System.Drawing.Point(410, 51) 
$btnDiscordScope.Size = New-Object System.Drawing.Size(120, 28)
$btnDiscordScope.BackColor = "Indigo"; $btnDiscordScope.ForeColor = "White"
$btnDiscordScope.FlatStyle = "Flat"; $btnDiscordScope.FlatAppearance.BorderSize = 0
$grpFilter.Controls.Add($btnDiscordScope)
$toolTip.SetToolTip($btnDiscordScope, "Manual Send: Sends a CUSTOM REPORT based on your current Date Filter and Sort settings.`nUseful for sharing specific pulls (e.g., 'My monthly pulls').")

# ============================================
#  ROW 6: LOG WINDOW (Moved Down to Y=540)
# ============================================
$txtLog = New-Object System.Windows.Forms.RichTextBox
$txtLog.Location = New-Object System.Drawing.Point(20, 540) # ขยับลงมา
$txtLog.Size = New-Object System.Drawing.Size(550, 300)      # ลดความสูงลงนิดหน่อยเพื่อให้พอดีจอ

$txtLog.BackColor = "Black"
$txtLog.ForeColor = "Lime"
$txtLog.BorderStyle = "FixedSingle"
$txtLog.Font = $script:fontLog
$txtLog.ReadOnly = $true
$txtLog.ScrollBars = "Vertical"
$form.Controls.Add($txtLog)

# ============================================
#  ROW 7: EXPORT (Moved Down to Y=850)
# ============================================
$btnExport = New-Object System.Windows.Forms.Button
$btnExport.Text = ">> Export History to CSV (Excel)"; 
$btnExport.Location = New-Object System.Drawing.Point(20, 850); $btnExport.Size = New-Object System.Drawing.Size(550, 35)
Apply-ButtonStyle -Button $btnExport -BaseColorName "DimGray" -HoverColorName "Gray";
$btnExport.Enabled = $false
$form.Controls.Add($btnExport)
# ปรับขนาด Form ให้ยาวขึ้นรับของใหม่
$form.Size = New-Object System.Drawing.Size(600, 950)

# ============================================
#  SIDE PANEL: ANALYTICS GRAPH (Hidden Area)
# ============================================

# 1. Panel พื้นหลังกราฟ (วางที่ X=600 เริ่มต้น)
$pnlChart = New-Object System.Windows.Forms.Panel
$pnlChart.Location = New-Object System.Drawing.Point(600, 24) # เว้นที่ให้ MenuBar 24px
$pnlChart.Size = New-Object System.Drawing.Size(480, 900) # กว้างเกือบ 500
$pnlChart.BackColor = [System.Drawing.Color]::FromArgb(25, 25, 25) # พื้นหลังมืดๆ
$pnlChart.Anchor = "Top, Bottom, Left, Right" # ยืดหดตาม Form
$form.Controls.Add($pnlChart)

# 2. ข้อความ No Data (โชว์เมื่อไม่มีข้อมูล)
$lblNoData = New-Object System.Windows.Forms.Label
$lblNoData.Text = "NO DATA AVAILABLE`n`nFetch data to see analytics."
$lblNoData.ForeColor = "DimGray"
$lblNoData.AutoSize = $false
$lblNoData.TextAlign = "MiddleCenter"
$lblNoData.Dock = "Fill" 
$lblNoData.Font = $script:fontHeader
$pnlChart.Controls.Add($lblNoData)

# 3. สร้าง Chart Object
$chart = New-Object System.Windows.Forms.DataVisualization.Charting.Chart
$chart.Dock = "Fill"
$chart.BackColor = "Transparent"
$chart.Visible = $false # ซ่อนไว้ก่อน
$pnlChart.Controls.Add($chart)

# --- Chart Setup (Dark Theme) ---
$chartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
$chartArea.Name = "MainArea"
$chartArea.BackColor = "Transparent" # พื้นหลังใส (เพื่อให้เห็นสี Panel)

# แกน X (ชื่อตัวละคร)
$chartArea.AxisX.LabelStyle.ForeColor = "Silver"
$chartArea.AxisX.LineColor = "Gray"
$chartArea.AxisX.MajorGrid.LineColor = [System.Drawing.Color]::FromArgb(30, 255, 255, 255) # เส้น Grid จางๆ
$chartArea.AxisX.Interval = 1 # โชว์ทุกชื่อ
$chartArea.AxisX.LabelStyle.Angle = -45 # เอียงชื่อให้อ่านง่าย

# แกน Y (Pity 0-90)
$chartArea.AxisY.LabelStyle.ForeColor = "Silver"
$chartArea.AxisY.LineColor = "Gray"
$chartArea.AxisY.MajorGrid.LineColor = [System.Drawing.Color]::FromArgb(30, 255, 255, 255)
$chartArea.AxisY.Maximum = 90 
$chartArea.AxisY.Title = "Pity Count"
$chartArea.AxisY.TitleForeColor = "Gray"

$chart.ChartAreas.Add($chartArea)

# Title
$title = New-Object System.Windows.Forms.DataVisualization.Charting.Title
$title.Text = "5-Star Pity History"
$title.ForeColor = "Gold"
$title.Font = $script:fontHeader
$chart.Titles.Add($title)

# ============================================
#  Function
# ============================================
function Log($msg, $color="Lime") { 
    # --- ส่วนที่เพิ่มเข้ามา: Debug Mode ---
    if ($script:DebugMode) {
        # แปลงชื่อสีจาก System.Drawing เป็น ConsoleColor (แก้สี Lime ให้เป็น Green เพราะ Console ไม่มี Lime)
        $consoleColor = $color
        if ($color -eq "Lime") { $consoleColor = "Green" }
        if ($color -eq "Gold") { $consoleColor = "Yellow" }
        if ($color -eq "OrangeRed") { $consoleColor = "Red" }
        if ($color -eq "DimGray") { $consoleColor = "Gray" }
        
        try {
            Write-Host "[DEBUG] $msg" -ForegroundColor $consoleColor
        } catch {
            # ถ้าชื่อสีไม่ตรงกับ ConsoleColor ให้พ่นออกมาเป็นสีขาวปกติ
            Write-Host "[DEBUG] $msg"
        }
    }
    # ------------------------------------

    # --- โค้ดเดิม (แสดงบน GUI) ---
    $txtLog.SelectionStart = $txtLog.Text.Length
    $txtLog.SelectionColor = [System.Drawing.Color]::FromName($color)
    $txtLog.AppendText("$msg`n")
    $txtLog.ScrollToCaret() 
}

function Update-BannerList {
    $conf = Get-GameConfig $script:CurrentGame
    $script:cmbBanner.Items.Clear()
    
    # เติม [void] ข้างหน้า เพื่อปิดปากไม่ให้มันคืนค่าตัวเลข
    [void]$script:cmbBanner.Items.Add("* FETCH ALL (Recommended)") 
    
    foreach ($b in $conf.Banners) {
        [void]$script:cmbBanner.Items.Add("$($b.Name)")
    }
    
    if ($script:cmbBanner.Items.Count -gt 0) {
        $script:cmbBanner.SelectedIndex = 0
    }
}

# Config Check
if (-not (Test-Path "config.json")) {
    $chkSendDiscord.Checked = $false
    $chkSendDiscord.Enabled = $false
    $chkSendDiscord.Text = "Send to Discord (No config.json)"
    $chkSendDiscord.ForeColor = "Gray"
}

# ============================
#  EVENTS
# ============================

# 1. Switch Game
$btnGenshin.Add_Click({ 
    $btnGenshin.BackColor="Gold"; $btnGenshin.ForeColor="Black"
    $btnHSR.BackColor="Gray"; $btnZZZ.BackColor="Gray"
    $script:CurrentGame = "Genshin"
    Log "Switched to Genshin Impact" "Cyan"
    Update-BannerList
    $btnExport.Enabled = $false
})
$btnHSR.Add_Click({ 
    $btnHSR.BackColor="MediumPurple"; $btnHSR.ForeColor="White"
    $btnGenshin.BackColor="Gray"; $btnZZZ.BackColor="Gray"
    $script:CurrentGame = "HSR"
    Log "Switched to Honkai: Star Rail" "Cyan"
    Update-BannerList
    $btnExport.Enabled = $false
})
$btnZZZ.Add_Click({ 
    $btnZZZ.BackColor="OrangeRed"; $btnZZZ.ForeColor="White"
    $btnGenshin.BackColor="Gray"; $btnHSR.BackColor="Gray"
    $script:CurrentGame = "ZZZ"
    Log "Switched to Zenless Zone Zero" "Cyan"
    Update-BannerList
    $btnExport.Enabled = $false
})

# 2. File
$btnAuto.Add_Click({
    $conf = Get-GameConfig $script:CurrentGame
    Log "Attempting to auto-detect data_2..." "Yellow"
    try {
        $found = Find-GameCacheFile -Config $conf -StagingPath $script:StagingFile
        $txtPath.Text = $found
        Log "File found! Copied to Staging." "Lime"
    } catch {
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "Not Found", 0, 48)
        Log "Auto-detect failed." "Red"
    }
})

$btnBrowse.Add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Filter = "data_2|data_2|All Files|*.*"
    if ($dlg.ShowDialog() -eq "OK") { $txtPath.Text = $dlg.FileName }
})

# 3. Stop
$btnStop.Add_Click({
    $script:StopRequested = $true
    Log ">>> STOP COMMAND RECEIVED! <<<" "Red"
})

# 4. Export CSV (New)
# 4. Export CSV (Fixed: Support Filter + No Emoji)
$btnExport.Add_Click({
    # ตรวจสอบว่าจะเอาข้อมูลชุดไหน (ชุดที่กรองแล้ว หรือ ชุดทั้งหมด)
    $dataToExport = $script:LastFetchedData
    
    if ($chkFilterEnable.Checked) {
        if ($null -ne $script:FilteredData) {
            $dataToExport = $script:FilteredData
        }
    }

    if ($dataToExport.Count -eq 0) { return }
    
    $fileName = "$($script:CurrentGame)_WishHistory_$(Get-Date -Format 'yyyyMMdd_HHmm').csv"
    $exportPath = Join-Path $PSScriptRoot $fileName
    
    try {
        # Select เฉพาะ Column ที่จำเป็น
        $dataToExport | Select-Object time, name, item_type, rank_type, _BannerName, id | Export-Csv -Path $exportPath -NoTypeInformation -Encoding UTF8
        Log "Saved to: $fileName" "Lime"
        [System.Windows.Forms.MessageBox]::Show("Saved successfully to:`n$exportPath", "Export Done", 0, 64)
    } catch {
        Log "Export Failed: $_" "Red"
        [System.Windows.Forms.MessageBox]::Show("Export Failed: $_", "Error", 0, 16)
    }
})

# 5. START FETCHING
$btnRun.Add_Click({
    $txtLog.Clear()
    $conf = Get-GameConfig $script:CurrentGame
    $targetFile = $txtPath.Text
    $ShowNo = $chkShowNo.Checked
    $SendDiscord = $chkSendDiscord.Checked
    
    if (-not (Test-Path $targetFile)) {
        [System.Windows.Forms.MessageBox]::Show("Please select a valid data_2 file!", "Error", 0, 16)
        return
    }

    $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
    $btnRun.Enabled = $false; $btnExport.Enabled = $false
    $btnStop.Enabled = $true
    $script:StopRequested = $false
    $script:LastFetchedData = @() # Reset Data

    if ($script:cmbBanner.SelectedIndex -le 0) {
        $TargetBanners = $conf.Banners 
    } else {
        $TargetBanners = @($conf.Banners[$script:cmbBanner.SelectedIndex - 1]) 
    }

    try {
        Log "Extracting AuthKey..." "Yellow"
        $auth = Get-AuthLinkFromFile -FilePath $targetFile -Config $conf
        Log "AuthKey Found!" "Lime"
        
        $allHistory = @()

        $script:progressBar.Style = "Marquee" # หลอดวิ่งไปมา
        $script:progressBar.MarqueeAnimationSpeed = 30

        # --- FETCH LOOP ---
        foreach ($banner in $TargetBanners) {
            if ($script:StopRequested) { throw "STOPPED" }

            Log "Fetching: $($banner.Name)..." "Magenta"

            $items = Fetch-GachaPages -Url $auth.Url -HostUrl $auth.Host -Endpoint $conf.ApiEndpoint -BannerCode $banner.Code -PageCallback { 
                param($p) 
                
                # --- GUI Update ---
                $form.Text = "Fetching $($banner.Name) - Page $p..." 
                
                # --- Console Debug Update (เขียนทับบรรทัดเดิม) ---
                if ($script:DebugMode) {
                    # `r คือกลับไปต้นบรรทัด เพื่อเขียนทับเลขหน้าเก่า
                    Write-Host -NoNewline "`r[DEBUG] Fetching Page: $p" -ForegroundColor Cyan
                }

                [System.Windows.Forms.Application]::DoEvents()
                if ($script:StopRequested) { throw "STOPPED" }
            }
            
            # ขึ้นบรรทัดใหม่ใน Console หลังจบ Loop ของ Banner นี้
            if ($script:DebugMode) { Write-Host "" } 
            
            foreach ($item in $items) { 
                $item | Add-Member -MemberType NoteProperty -Name "_BannerName" -Value $banner.Name -Force
            }
            $allHistory += $items
            Log "  > Found $($items.Count) items." "Gray"
        }
        
        # Save to memory for Export
        $script:LastFetchedData = $allHistory
        
        # --- CALCULATION ---
        if ($script:StopRequested) { throw "STOPPED" }
        Log "`nCalculating Pity..." "Green"
        
        $sortedItems = $allHistory | Sort-Object { [decimal]$_.id }
        $pityTrackers = @{}
        foreach ($b in $conf.Banners) { $pityTrackers[$b.Code] = 0 }
        
        $highRankHistory = @()

        foreach ($item in $sortedItems) {
            $code = [string]$item.gacha_type
            if ($script:CurrentGame -eq "Genshin" -and $code -eq "400") { $code = "301" }

            if (-not $pityTrackers.ContainsKey($code)) { $pityTrackers[$code] = 0 }
            $pityTrackers[$code]++

            if ($item.rank_type -eq $conf.SRank) {
                $highRankHistory += [PSCustomObject]@{
                    Time   = $item.time
                    Name   = $item.name
                    Banner = $item._BannerName
                    Pity   = $pityTrackers[$code]
                }
                $pityTrackers[$code] = 0 
            }
        }

        # --- DISPLAY ---
        Log "`n=== $($conf.Name) HIGH RANK HISTORY ===" "Cyan"
        if ($highRankHistory.Count -gt 0) {
            for ($i = $highRankHistory.Count - 1; $i -ge 0; $i--) {
                $h = $highRankHistory[$i]
                
                $pColor = "Lime"
                if ($h.Pity -gt 75) { $pColor = "Red" } elseif ($h.Pity -gt 50) { $pColor = "Yellow" }
                
                $idxTxt = if ($ShowNo) { "[No.$($i+1)]".PadRight(12) } else { "[$($h.Time)] " }
                $txtLog.SelectionColor = [System.Drawing.Color]::Gray; $txtLog.AppendText($idxTxt)
                
                $txtLog.SelectionColor = [System.Drawing.Color]::Gold; $txtLog.AppendText("$($h.Name.PadRight(18)) ")
                
                $txtLog.SelectionColor = [System.Drawing.Color]::FromName($pColor); $txtLog.AppendText("Pity: $($h.Pity)`n")
            }
        } else {
            Log "No High Rank items found." "Gray"
        }

        # --- UPDATE PITY GAUGE UI (Current Pity Logic) ---
        
        # 1. คำนวณ Pity ปัจจุบัน (นับถอยหลังจากตัวล่าสุด จนกว่าจะเจอ 5 ดาว)
        $currentPity = 0
        if ($allHistory.Count -gt 0) {
            # $allHistory[0] คือตัวใหม่ล่าสุด
            foreach ($item in $allHistory) {
                if ($item.rank_type -eq $conf.SRank) { 
                    break # เจอ 5 ดาวแล้ว หยุดนับ
                }
                $currentPity++
            }
        }

        # 2. คำนวณความยาวหลอด (เต็มหลอด 550px = 90 pity)
        $percent = $currentPity / 90
        if ($percent -gt 1) { $percent = 1 }
        $newWidth = [int](550 * $percent)
        
        # 3. อัปเดต UI
        $script:pnlPityFill.Width = $newWidth
        
        # อัปเดตข้อความบนหัวข้อแทน (ชัดเจนกว่า ไม่โดนบัง)
        $script:lblPityTitle.Text = "Current Pity Progress: $currentPity / 90"

        # 4. เปลี่ยนสีหลอดตามความเกลือ
        if ($currentPity -ge 74) {
            $script:pnlPityFill.BackColor = "Crimson" # แดงเข้ม (Soft Pity)
            $script:lblPityTitle.ForeColor = "Red"    # ตัวหนังสือแดงด้วย
        } elseif ($currentPity -ge 50) {
            $script:pnlPityFill.BackColor = "Gold"    # เหลือง
            $script:lblPityTitle.ForeColor = "Gold"
        } else {
            $script:pnlPityFill.BackColor = "LimeGreen" # เขียว
            $script:lblPityTitle.ForeColor = "White"
        }
        
        # หยุด Progress Bar ด้านล่าง
        $script:progressBar.Style = "Blocks"
        $script:progressBar.Value = 100

        # --- CALCULATE LUCK STATS ---
        $totalPulls = $allHistory.Count
        $total5Star = $highRankHistory.Count
        $avgPity = 0
        
        # 1. Update Total
        $lblStat1.Text = "Total Pulls: $totalPulls"

        # 2. Update Avg Pity
        if ($total5Star -gt 0) {
            # สูตร: เอาจำนวนโรลทั้งหมด หารด้วย จำนวน 5 ดาวที่ออก
            $avgPity = "{0:N2}" -f ($totalPulls / $total5Star)
            $script:lblStatAvg.Text = "Avg. Pity: $avgPity"
            
            # เปลี่ยนสีตามความเฮง
            if ([double]$avgPity -le 55) { $script:lblStatAvg.ForeColor = "Lime" }   # เฮงจัด
            elseif ([double]$avgPity -le 73) { $script:lblStatAvg.ForeColor = "Gold" } # ทั่วไป
            else { $script:lblStatAvg.ForeColor = "OrangeRed" }                       # เกลือ
        } else {
            $script:lblStatAvg.Text = "Avg. Pity: N/A"
            $script:lblStatAvg.ForeColor = "Gray"
        }

        # 3. Update Cost (Currency)
        $cost = $totalPulls * 160
        $currencyName = "Primos"
        if ($script:CurrentGame -eq "HSR") { $currencyName = "Jades" }
        elseif ($script:CurrentGame -eq "ZZZ") { $currencyName = "Polychromes" }
        
        # จัด Format ใส่ลูกน้ำ (เช่น 160,000)
        $costStr = "{0:N0}" -f $cost
        $script:lblStatCost.Text = "Est. Cost: $costStr $currencyName"
        
        # === DISCORD ===
        if ($SendDiscord) {
            Log "`nSending report to Discord..." "Magenta"
            $discordMsg = Send-DiscordReport -HistoryData $highRankHistory -PityTrackers $pityTrackers -Config $conf -ShowNoMode $ShowNo
            Log "Discord: $discordMsg" "Lime"
        } else {
            Log "`nDiscord: Skipped" "Gray"
        }
        
        # Enable Export Button
        if ($allHistory.Count -gt 0) {
            $btnExport.Enabled = $true
            $btnExport.BackColor = "RoyalBlue" # เปลี่ยนสีให้รู้ว่ากดได้
        }

    } catch {
        if ($_.Exception.Message -match "STOPPED") {
             Log "`n!!! PROCESS STOPPED BY USER !!!" "Red"
        } else {
             Log "ERROR: $($_.Exception.Message)" "Red"
             [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "Error", 0, 16)
        }
    } finally {
        $form.Cursor = [System.Windows.Forms.Cursors]::Default
        $btnRun.Enabled = $true
        $btnStop.Enabled = $false
        $form.Text = "Universal Hoyo Wish Counter (Final)"
        
        # --- เพิ่มบรรทัดนี้ ---
        if ($script:LastFetchedData.Count -gt 0) { $grpFilter.Enabled = $true }
        # -------------------
    }
})

# ==========================================
#  CORE LOGIC: UPDATE VIEW (GUI & LOG)
# ==========================================
# ตัวแปรเก็บข้อมูลที่ผ่านการกรองแล้ว
$script:FilteredData = @()

function Update-FilteredView {
    # ถ้ายังไม่มีข้อมูลดิบ ให้จบไป
    if ($null -eq $script:LastFetchedData -or $script:LastFetchedData.Count -eq 0) { return }

    $conf = Get-GameConfig $script:CurrentGame
    $txtLog.Clear()

    # 1. เช็คว่าเปิด Filter ไหม?
    if ($chkFilterEnable.Checked) {
        $startDate = $dtpStart.Value.Date
        $endDate = $dtpEnd.Value.Date.AddDays(1).AddSeconds(-1) # ครอบคลุมถึงวินาทีสุดท้ายของวัน

        # กรองข้อมูลเก็บไว้ในตัวแปร Global
        $script:FilteredData = $script:LastFetchedData | Where-Object { 
            [DateTime]$_.time -ge $startDate -and [DateTime]$_.time -le $endDate 
        }
        Log "--- FILTERED VIEW ($($startDate.ToString('yyyy-MM-dd')) to $($endDate.ToString('yyyy-MM-dd'))) ---" "Cyan"
    } else {
        $script:FilteredData = $script:LastFetchedData
        Log "--- FULL HISTORY VIEW ---" "Cyan"
    }

    # 2. คำนวณ Stats พื้นฐาน (Total, Cost)
    $totalPulls = $script:FilteredData.Count
    $lblStat1.Text = "Total Pulls: $totalPulls"
    
    $cost = $totalPulls * 160
    $currencyName = if ($script:CurrentGame -eq "HSR") { "Jades" } elseif ($script:CurrentGame -eq "ZZZ") { "Polychromes" } else { "Primos" }
    $script:lblStatCost.Text = "Est. Cost: $(" {0:N0}" -f $cost) $currencyName"

    # 3. เตรียมคำนวณ Pity (ต้องเรียงจาก เก่า -> ใหม่ เสมอ)
    $sortedItems = $script:FilteredData | Sort-Object { [decimal]$_.id } 
    
    $pityTrackers = @{} 
    foreach ($b in $conf.Banners) { $pityTrackers[$b.Code] = 0 }

    # [Logic: True Pity Offset] 
    # ถ้าเปิด Filter และเลือก True Pity -> ต้องไปนับย้อนหลังในอดีตมาบวกเพิ่ม
    if ($chkFilterEnable.Checked -and $radModeAbs.Checked) {
        if ($sortedItems.Count -gt 0) {
            $firstItemInScope = $sortedItems[0]
            # ขุดข้อมูลทั้งหมดมาไล่นับ
            $allHistorySorted = $script:LastFetchedData | Sort-Object { [decimal]$_.id }
            
            foreach ($item in $allHistorySorted) {
                # หยุดเมื่อชนตัวแรกของ Scope
                if ($item.id -eq $firstItemInScope.id) { break }
                
                # นับ Pity สะสม
                $code = [string]$item.gacha_type
                if ($script:CurrentGame -eq "Genshin" -and $code -eq "400") { $code = "301" }
                if (-not $pityTrackers.ContainsKey($code)) { $pityTrackers[$code] = 0 }

                $pityTrackers[$code]++
                if ($item.rank_type -eq $conf.SRank) { $pityTrackers[$code] = 0 }
            }
        }
    }

    # 4. Loop ข้อมูลใน Scope เพื่อหา 5 ดาว และ Pity ที่แท้จริง
    $highRankCount = 0
    $pitySum = 0
    $displayList = @() 

    foreach ($item in $sortedItems) {
        $code = [string]$item.gacha_type
        if ($script:CurrentGame -eq "Genshin" -and $code -eq "400") { $code = "301" }
        if (-not $pityTrackers.ContainsKey($code)) { $pityTrackers[$code] = 0 }

        $pityTrackers[$code]++
        
        if ($item.rank_type -eq $conf.SRank) {
            $highRankCount++
            $pitySum += $pityTrackers[$code]
            
            # เก็บข้อมูลไว้โชว์
            $displayList += [PSCustomObject]@{
                Time = $item.time
                Name = $item.name
                Banner = $item._BannerName
                Pity = $pityTrackers[$code]
            }
            $pityTrackers[$code] = 0 
        }
    }

    # 5. อัปเดต UI Avg Pity
    if ($highRankCount -gt 0) {
        $avg = $pitySum / $highRankCount
        $script:lblStatAvg.Text = "Avg. Pity: $(" {0:N2}" -f $avg)"
        if ($avg -le 55) { $script:lblStatAvg.ForeColor = "Lime" }
        elseif ($avg -le 73) { $script:lblStatAvg.ForeColor = "Gold" }
        else { $script:lblStatAvg.ForeColor = "OrangeRed" }
    } else {
        $script:lblStatAvg.Text = "Avg. Pity: -"
        $script:lblStatAvg.ForeColor = "White"
    }

    # 6. แสดงผลลง Log Window
    if ($displayList.Count -gt 0) {
        
        # Helper: Print บรรทัดเดียว
        function Print-Line($h, $idx) {
            $pColor = "Lime"
            if ($h.Pity -gt 75) { $pColor = "Red" } elseif ($h.Pity -gt 50) { $pColor = "Yellow" }
            
            $prefix = if ($chkShowNo.Checked) { "[No.$idx] ".PadRight(12) } else { "[$($h.Time)] " }
            
            $txtLog.SelectionColor = "Gray"; $txtLog.AppendText($prefix)
            $txtLog.SelectionColor = "Gold"; $txtLog.AppendText("$($h.Name.PadRight(18)) ")
            $txtLog.SelectionColor = $pColor; $txtLog.AppendText("Pity: $($h.Pity)`n")
        }

        if ($chkSortDesc.Checked) {
            # Newest First (ถอยหลัง)
            for ($i = $displayList.Count - 1; $i -ge 0; $i--) {
                Print-Line -h $displayList[$i] -idx ($i+1)
            }
        } else {
            # Oldest First (เดินหน้า)
            for ($i = 0; $i -lt $displayList.Count; $i++) {
                Print-Line -h $displayList[$i] -idx ($i+1)
            }
        }
    } else {
        Log "No 5-Star items found in this range." "Gray"
    }

    # [NEW] สั่งวาดกราฟ
    Update-Chart -DataList $displayList
}

function Update-Chart {
    param($DataList)

    # 1. Clear กราฟเก่า
    $chart.Series.Clear()
    
    # ถ้าไม่มีข้อมูล หรือไม่ได้เปิด Panel อยู่ -> จบ
    if ($null -eq $DataList -or $DataList.Count -eq 0) {
        $chart.Visible = $false
        $lblNoData.Visible = $true
        return
    }

    # ถ้ามีข้อมูล -> โชว์กราฟ
    $chart.Visible = $true
    $lblNoData.Visible = $false

    # 2. สร้าง Series (กราฟแท่ง)
    $series = New-Object System.Windows.Forms.DataVisualization.Charting.Series
    $series.Name = "Pity"
    $series.ChartType = "Column" 
    $series.IsValueShownAsLabel = $true # โชว์ตัวเลขบนแท่ง
    $series.LabelForeColor = "White"
    $series["PixelPointWidth"] = "25" # ความกว้างแท่ง
    
    # 3. เตรียมข้อมูล (กลับหัวให้เรียงจาก อดีต -> ปัจจุบัน เพื่อให้กราฟวิ่งซ้ายไปขวา)
    # $DataList ที่รับมา มันเรียง ใหม่ -> เก่า (เพื่อโชว์ Log)
    $plotData = @()
    if ($DataList.Count -gt 0) {
        for ($i = $DataList.Count - 1; $i -ge 0; $i--) {
            $plotData += $DataList[$i]
        }
    }
    # นับ Index (เริ่มต้นที่ 1)
    $idx = 1
    # 4. Plot ลงกราฟ
    foreach ($item in $plotData) {
        # สร้าง Label แกน X (เช่น "Jean (12/01)")
        $label = ""
        
        if ($chkShowNo.Checked) {
            # ถ้าเลือก Show No. -> "Jean (#1)"
            $label = "$($item.Name)`n(#$idx)"
        } else {
            # ถ้าปกติ -> "Jean (12/01)"
            $dateStr = [DateTime]::Parse($item.Time).ToString("dd/MM")
            $label = "$($item.Name)`n($dateStr)"
        }
        
        $ptIndex = $series.Points.AddXY($label, $item.Pity)
        $pt = $series.Points[$ptIndex]
        
        # Tooltip (เอาเมาส์ชี้)
        $pt.ToolTip = "Name: $($item.Name)`nDate: $($item.Time)`nPity: $($item.Pity)`nBanner: $($item.Banner)"

        # ใส่สีตามความเกลือ (Gradient)
        $pt.BackGradientStyle = "TopBottom"
        
        if ($item.Pity -gt 75) {
            $pt.Color = "Crimson"       # แดง (เกลือ)
            $pt.BackSecondaryColor = "Maroon"
        } elseif ($item.Pity -gt 50) {
            $pt.Color = "Gold"          # ทอง (เฉยๆ)
            $pt.BackSecondaryColor = "DarkGoldenrod"
        } else {
            $pt.Color = "LimeGreen"     # เขียว (ดวงดี)
            $pt.BackSecondaryColor = "DarkGreen"
        }

        $idx++
    }

    $chart.Series.Add($series)
    $chart.Update()
}
# ==========================================
#  EVENT HANDLERS (INPUTS)
# ==========================================

# 1. ปุ่มเปิด/ปิด Filter
$chkFilterEnable.Add_CheckedChanged({
    $status = if ($chkFilterEnable.Checked) { "ACTIVE" } else { "Disabled" }
    $grpFilter.Text = " Scope & Analysis ($status)"
    
    # เปิด/ปิดปุ่มย่อย
    $dtpStart.Enabled = $chkFilterEnable.Checked
    $dtpEnd.Enabled   = $chkFilterEnable.Checked
    $radModeAbs.Enabled = $chkFilterEnable.Checked
    $radModeRel.Enabled = $chkFilterEnable.Checked
    $btnSmartSnap.Enabled = $chkFilterEnable.Checked
    
    Update-FilteredView
})

# 2. Trigger อัปเดตเมื่อมีการเปลี่ยนค่า
$dtpStart.Add_ValueChanged({ Update-FilteredView })
$dtpEnd.Add_ValueChanged({ Update-FilteredView })
$radModeAbs.Add_CheckedChanged({ if ($radModeAbs.Checked) { Update-FilteredView } })
$radModeRel.Add_CheckedChanged({ if ($radModeRel.Checked) { Update-FilteredView } })
$chkSortDesc.Add_CheckedChanged({ Update-FilteredView })

# 3. ปุ่ม Snap Reset (หาจุดเริ่ม Roll 1)
$btnSmartSnap.Add_Click({
    if ($null -eq $script:LastFetchedData) { return }
    $conf = Get-GameConfig $script:CurrentGame
    
    $targetDate = $dtpStart.Value
    # เรียงจาก ใหม่ -> เก่า (id มาก -> น้อย)
    $allDesc = $script:LastFetchedData | Sort-Object { [decimal]$_.id } -Descending
    $found = $false
    
    for ($i = 0; $i -lt $allDesc.Count; $i++) {
        $item = $allDesc[$i]
        $itemDate = [DateTime]$item.time
        
        # หา 5 ดาว ที่เก่ากว่าวันที่เลือก (เพื่อจะเริ่มนับใหม่ต่อจากมัน)
        if ($itemDate -lt $targetDate -and $item.rank_type -eq $conf.SRank) {
            if ($i -gt 0) {
                # ตัวถัดไป (ซึ่งใหม่กว่ามัน 1 step) คือจุดเริ่มนับ 1
                $snapItem = $allDesc[$i - 1]
                $dtpStart.Value = [DateTime]$snapItem.time
                Log "Snapped Start Date to: $($snapItem.time)" "Lime"
                $found = $true
            }
            break
        }
    }
    if (-not $found) { Log "Could not find a reset point in the past." "Red" }
})

# ==========================================
#  EVENT: BUTTON DISCORD SCOPE (FIXED SORT)
# ==========================================
$btnDiscordScope.Add_Click({
    if ($null -eq $script:LastFetchedData) { return }

    Log "Preparing Discord Report..." "Magenta"

    # 1. กำหนด Scope
    $startDate = [DateTime]::MinValue
    $endDate   = [DateTime]::MaxValue

    if ($chkFilterEnable.Checked) {
        $startDate = $dtpStart.Value.Date
        $endDate   = $dtpEnd.Value.Date.AddDays(1).AddSeconds(-1)
    }

    $conf = Get-GameConfig $script:CurrentGame
    
    # 2. Re-calculate Pity (จาก เก่า -> ใหม่ เสมอ)
    $pityTrackers = @{}
    foreach ($b in $conf.Banners) { $pityTrackers[$b.Code] = 0 }
    
    $allSorted = $script:LastFetchedData | Sort-Object { [decimal]$_.id } 
    $listToSend = @()

    foreach ($item in $allSorted) {
        $code = [string]$item.gacha_type
        if ($script:CurrentGame -eq "Genshin" -and $code -eq "400") { $code = "301" }
        if (-not $pityTrackers.ContainsKey($code)) { $pityTrackers[$code] = 0 }
        
        $pityTrackers[$code]++
        
        if ($item.rank_type -eq $conf.SRank) {
            # Filter Time
            $t = [DateTime]$item.time
            if ($t -ge $startDate -and $t -le $endDate) {
                $listToSend += [PSCustomObject]@{
                    Time   = $item.time
                    Name   = $item.name
                    Banner = $item._BannerName
                    Pity   = $pityTrackers[$code]
                }
            }
            $pityTrackers[$code] = 0
        }
    }

    # 3. [FIXED] Logic การเรียงลำดับ (Engine อ่านจาก ท้าย->หน้า)
    # $listToSend ตอนนี้เรียง [เก่า ... ใหม่]
    
    $finalList = @()
    
    if ($chkSortDesc.Checked) {
        # ต้องการ: Newest First (ใหม่ -> เก่า)
        # Engine อ่านถอยหลัง: ดังนั้นเราต้องส่ง [เก่า ... ใหม่] (Original) ให้มัน
        # มันจะอ่านตัวท้าย (ใหม่) ก่อน -> ถูกต้อง!
        $finalList = $listToSend
    } else {
        # ต้องการ: Oldest First (เก่า -> ใหม่)
        # Engine อ่านถอยหลัง: ดังนั้นเราต้องส่ง [ใหม่ ... เก่า] (Reversed) ให้มัน
        # มันจะอ่านตัวท้าย (เก่า) ก่อน -> ถูกต้อง!
        
        if ($listToSend.Count -gt 0) {
            for ($i = $listToSend.Count - 1; $i -ge 0; $i--) {
                $finalList += $listToSend[$i]
            }
        }
    }

    # 4. ส่ง
    $res = Send-DiscordReport -HistoryData $finalList -PityTrackers $pityTrackers -Config $conf -ShowNoMode $chkShowNo.Checked
    
    $modeText = if ($chkSortDesc.Checked) { "Newest First" } else { "Oldest First" }
    Log "Discord Report Sent ($modeText): $res" "Lime"
})

# ============================
#  CLOSING SPLASH LOGIC (Skip Button Support)
# ============================
$form.Add_FormClosing({
    $form.Hide()

    # Config
    $WaitSeconds = 2.0      # ตามสั่ง 2 วิ
    $FadeSpeed   = 30
    $script:SkipClosing = $false # ตัวแปรเช็คว่ากดข้ามไหม

    # เช็ครูป
    $exitPath = Join-Path $PSScriptRoot "splash_exit.gif"
    if (-not (Test-Path $exitPath)) { $exitPath = Join-Path $PSScriptRoot "splash_exit.png" }
    if (-not (Test-Path $exitPath)) { $exitPath = Join-Path $PSScriptRoot "splash.png" }

    if (Test-Path $exitPath) {
        $closeSplash = New-Object System.Windows.Forms.Form
        $closeSplash.FormBorderStyle = "None"
        $closeSplash.StartPosition = "CenterScreen"
        $closeSplash.ShowInTaskbar = $false
        $closeSplash.TopMost = $true
        
        $img = [System.Drawing.Image]::FromFile($exitPath)
        $closeSplash.Size = $img.Size

        # PictureBox สำหรับ GIF
        $picBox = New-Object System.Windows.Forms.PictureBox
        $picBox.Dock = "Fill"
        $picBox.Image = $img
        $picBox.SizeMode = "StretchImage"
        $closeSplash.Controls.Add($picBox)

        # --- [NEW] ปุ่ม X สำหรับปิดทันที ---
        $lblExit = New-Object System.Windows.Forms.Label
        $lblExit.Text = "X"
        $lblExit.Font = New-Object System.Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Bold)
        $lblExit.Size = New-Object System.Drawing.Size(40, 40)
        $lblExit.TextAlign = "MiddleCenter"
        $lblExit.Cursor = [System.Windows.Forms.Cursors]::Hand
        
        # Style
        $lblExit.ForeColor = "Red"        # สีแดงตามสั่ง
        $lblExit.BackColor = "Transparent"
        $lblExit.Parent = $picBox         # สำคัญ: ต้องเกาะกับ PicBox ถึงจะใสบน GIF
        $lblExit.Location = New-Object System.Drawing.Point(($img.Width - 40), 0)

        # Events
        $lblExit.Add_MouseEnter({ $lblExit.BackColor = "Crimson"; $lblExit.ForeColor = "White" })
        $lblExit.Add_MouseLeave({ $lblExit.BackColor = "Transparent"; $lblExit.ForeColor = "Red" })
        $lblExit.Add_Click({ $script:SkipClosing = $true }) # กดปุ๊บ set flag

        # (Optional) Text
        $lblBye = New-Object System.Windows.Forms.Label
        $lblBye.Text = "Saving Data..."
        $lblBye.Font = $script:fontBold
        $lblBye.ForeColor = "White"
        $lblBye.BackColor = "Transparent"
        $lblBye.Parent = $picBox
        $lblBye.AutoSize = $true
        
        # [FIXED] Cast Height to int explicitly
        $yPos = [int]$closeSplash.Height - 30
        $lblBye.Location = New-Object System.Drawing.Point(10, $yPos)

        $closeSplash.Show()
        $closeSplash.Refresh()

        # Loop 1: Wait (เช็ค Skip ทุก 50ms)
        $steps = $WaitSeconds * 20 
        for ($i=0; $i -lt $steps; $i++) {
            if ($script:SkipClosing) { break } # ออกจากลูปทันที
            Start-Sleep -Milliseconds 50
            [System.Windows.Forms.Application]::DoEvents()
        }

        # Loop 2: Fade Out (เช็ค Skip ด้วย)
        if (-not $script:SkipClosing) {
            for ($op = 1; $op -ge 0; $op -= 0.05) {
                if ($script:SkipClosing) { break }
                $closeSplash.Opacity = $op
                Start-Sleep -Milliseconds $FadeSpeed
                [System.Windows.Forms.Application]::DoEvents()
            }
        }

        $closeSplash.Close()
        $closeSplash.Dispose()
        $img.Dispose()
    }
})

# Initial
Update-BannerList
$form.ShowDialog() | Out-Null