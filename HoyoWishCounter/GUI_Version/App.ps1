# --- CONFIGURATION (DEBUG MODE) ---
# ตั้งเป็น $true เพื่อให้แสดงข้อความในหน้าต่าง PowerShell (Console) ด้วย
# ตั้งเป็น $false เพื่อปิด (แสดงแค่ใน GUI)
$script:DebugMode = $true 

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
Add-Type -AssemblyName PresentationFramework

# ตรวจสอบก่อนว่าเคยโหลดไปหรือยัง (กัน Error เวลารันซ้ำ)
if (-not ([System.Management.Automation.PSTypeName]'DarkMenuRenderer').Type) {
    Add-Type -TypeDefinition @"
    using System.Windows.Forms;
    using System.Drawing;

    public class DarkMenuRenderer : ProfessionalColorTable {
        // 1. สีพื้นหลังตอนเอาเมาส์ชี้ (Hover)
        public override Color MenuItemSelected { get { return Color.FromArgb(65, 65, 65); } }
        public override Color MenuItemBorder { get { return Color.DimGray; } }

        // 2. สีพื้นหลังตอนคลิก (Pressed) - แก้จอขาว
        public override Color MenuItemPressedGradientBegin { get { return Color.FromArgb(45, 45, 48); } }
        public override Color MenuItemPressedGradientEnd { get { return Color.FromArgb(45, 45, 48); } }
        public override Color MenuBorder { get { return Color.DimGray; } }

        // 3. สีพื้นหลังตอนเลือก (Selected)
        public override Color MenuItemSelectedGradientBegin { get { return Color.FromArgb(65, 65, 65); } }
        public override Color MenuItemSelectedGradientEnd { get { return Color.FromArgb(65, 65, 65); } }

        // 4. [สำคัญ] แก้แถบสีขาวด้านซ้าย (Image Margin)
        public override Color ImageMarginGradientBegin { get { return Color.FromArgb(45, 45, 48); } }
        public override Color ImageMarginGradientMiddle { get { return Color.FromArgb(45, 45, 48); } }
        public override Color ImageMarginGradientEnd { get { return Color.FromArgb(45, 45, 48); } }
        
        // 5. สี Dropdown
        public override Color ToolStripDropDownBackground { get { return Color.FromArgb(45, 45, 48); } }
    }
"@ -ReferencedAssemblies System.Windows.Forms, System.Drawing
}

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

    if ($script:DebugMode) { Write-Host "[INIT] Splash Screen: Started" -ForegroundColor Cyan }

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
        if ($script:DebugMode -and $i -eq 50) { Write-Host "[INIT] Engine Loading..." -ForegroundColor Gray }
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
        if ($script:DebugMode -and $i -eq 50) { Write-Host "[INIT] Engine Loading..." -ForegroundColor Gray }
    }

    Start-Sleep -Milliseconds 200 # ค้างแป๊บนึง
    Check-Abort

    if ($script:DebugMode) { Write-Host "[INIT] Splash Screen: Completed. Launching Main UI." -ForegroundColor Green }
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
$menuStrip.Renderer = New-Object System.Windows.Forms.ToolStripProfessionalRenderer((New-Object DarkMenuRenderer))
$menuStrip.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
$menuStrip.ForeColor = "White"
$form.Controls.Add($menuStrip)
$form.MainMenuStrip = $menuStrip


# เมนู File
$menuFile = New-Object System.Windows.Forms.ToolStripMenuItem("File")
[void]$menuStrip.Items.Add($menuFile)

# --- MENU: TOOLS (Forecast) ---
$menuTools = New-Object System.Windows.Forms.ToolStripMenuItem("Tools")
$menuStrip.Items.Add($menuTools) | Out-Null

# สร้างเมนูย่อย Simulator
$script:itemForecast = New-Object System.Windows.Forms.ToolStripMenuItem("Wish Forecast (Simulator)")
$script:itemForecast.ShortcutKeys = "F8"  # คีย์ลัดกด F8 ได้เลย เท่ๆ
$script:itemForecast.Enabled = $false     # ปิดไว้ก่อน รอ Fetch เสร็จ
$script:itemForecast.ForeColor = "White"
$menuTools.DropDownItems.Add($script:itemForecast) | Out-Null

# เมนูย่อย Reset
$itemClear = New-Object System.Windows.Forms.ToolStripMenuItem("Reset / Clear All")
$itemClear.ShortcutKeys = [System.Windows.Forms.Keys]::F5
$itemClear.Add_Click({
    # เรียกใช้ Helper บรรทัดเดียวจบ!
    Reset-LogWindow
    
    # 3. เริ่ม Log ข้อความ Reset
    Log ">>> User requested RESET. Clearing all data... <<<" "OrangeRed"
    
    # 4. Reset ค่าตัวแปรอื่นๆ ตามเดิม
    $script:pnlPityFill.Width = 0
    $script:lblPityTitle.Text = "Current Pity Progress: 0 / 90"; $script:lblPityTitle.ForeColor = "White"; $script:pnlPityFill.BackColor = "LimeGreen"
    $script:LastFetchedData = @()
    $script:FilteredData = @()
    $script:progressBar.Value = 0
    $btnExport.Enabled = $false; $btnExport.BackColor = "DimGray"
    $lblStat1.Text = "Total Pulls: 0"; $script:lblStatAvg.Text = "Avg. Pity: -"; $script:lblStatAvg.ForeColor = "White"
    $script:lblStatCost.Text = "Est. Cost: 0"
    
    # 5. Reset Filter Panel
    $grpFilter.Enabled = $false
    $chkFilterEnable.Checked = $false
    $dtpStart.Value = Get-Date
    $dtpEnd.Value = Get-Date
    
    # 6. Clear Graph & Panel
    $chart.Series.Clear()
    $chart.Visible = $false
    $lblNoData.Visible = $true
    
    # ถ้ากราฟเปิดอยู่ ให้ยุบกลับ
    if ($script:isExpanded) {
        $form.Width = 600
        $menuExpand.Text = ">> Show Graph"
        $script:isExpanded = $false
    }

    # เพิ่มบรรทัดนี้เข้าไปใน Reset Logic (ใน $itemClear.Add_Click)
    $script:lblLuckGrade.Text = "Grade: -"; $script:lblLuckGrade.ForeColor = "DimGray"

    Log "--- System Reset Complete. Ready. ---" "Gray"
})
[void]$menuFile.DropDownItems.Add($itemClear)

# เมนูย่อย Exit
$itemExit = New-Object System.Windows.Forms.ToolStripMenuItem("Exit")
$itemExit.Add_Click({ $form.Close() })
[void]$menuFile.DropDownItems.Add($itemExit)

# --- [NEW] MENU HELP / CREDITS ---
$menuHelp = New-Object System.Windows.Forms.ToolStripMenuItem("Help")
[void]$menuStrip.Items.Add($menuHelp)

$itemCredits = New-Object System.Windows.Forms.ToolStripMenuItem("About & Credits")
$itemCredits.ShortcutKeys = "F1" # กด F1 เพื่อเรียกดูได้ด้วย
[void]$menuHelp.DropDownItems.Add($itemCredits)

$itemCredits.Add_Click({
    # 1. เคลียร์หน้าจอ Log
    $txtLog.Clear()
    
    # 2. ปรับการจัดวางกึ่งกลาง (ให้ดูแพง)
    $txtLog.SelectionAlignment = "Center"

    # --- HEADER ---
    $txtLog.SelectionFont = New-Object System.Drawing.Font("Consolas", 14, [System.Drawing.FontStyle]::Bold)
    $txtLog.SelectionColor = "Cyan"
    $txtLog.AppendText("`n================================`n")
    $txtLog.AppendText(" HOYO WISH COUNTER (ULTIMATE) `n")
    $txtLog.AppendText("================================`n`n")

    # --- VERSION ---
    $txtLog.SelectionFont = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
    $txtLog.SelectionColor = "DimGray"
    $txtLog.AppendText("Version 5.0.0`n`n")

    # --- DEVELOPER (ใส่ชื่อคุณตรงนี้) ---
    $txtLog.SelectionFont = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $txtLog.SelectionColor = "Silver"
    $txtLog.AppendText("Created & Designed by`n")

    $txtLog.SelectionFont = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
    $txtLog.SelectionColor = "Gold"
    # [แก้ชื่อตรงนี้] ใส่ชื่อเล่นหรือนามปากกาคุณเลย
    $txtLog.AppendText(" [ PHUNYAWEE ] `n`n") 

    # --- QUOTE ---
    $txtLog.SelectionFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Italic)
    $txtLog.SelectionColor = "LimeGreen"
    $txtLog.AppendText("`"May all your pulls be gold,`nand your 50/50s never lost.`"`n`n")

    # --- FOOTER ---
    $txtLog.SelectionFont = New-Object System.Drawing.Font("Consolas", 8, [System.Drawing.FontStyle]::Regular)
    $txtLog.SelectionColor = "Gray"
    $txtLog.AppendText("Powered by PowerShell & .NET WinForms`n")
    $txtLog.AppendText("Data Source: Official Game Cache API`n")
    
    # 3. คืนค่าการจัดวางกลับเป็นชิดซ้าย (สำคัญ! ไม่งั้น Log ปกติจะเบี้ยว)
    $txtLog.SelectionAlignment = "Left"
    $txtLog.SelectionStart = 0 # เลื่อน Scroll ขึ้นบนสุด
})


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
        Log "Action: Collapse Graph Panel (Hide)" "DimGray"
        # ยุบกลับ
        $form.Width = 600
        $menuExpand.Text = ">> Show Graph"
        $script:isExpanded = $false
    } else {
        Log "Action: Expand Graph Panel (Show)" "Cyan"  
        # ขยายออก
        $form.Width = 1200
        $menuExpand.Text = "<< Hide Graph"
        $script:isExpanded = $true
        
        $pnlChart.Size = New-Object System.Drawing.Size(580, 880)

        # สั่งวาดกราฟ (ถ้ามีข้อมูล)
        if ($grpFilter.Enabled) { Update-FilteredView }
    }
})

# --- [FIX] FORCE WHITE TEXT LOOP ---
# สั่งให้ทุกเมนูย่อยเป็นสีขาว (ถ้า Disabled มันจะเทาเอง)
foreach ($topItem in $menuStrip.Items) {
    $topItem.ForeColor = "White"
    foreach ($subItem in $topItem.DropDownItems) {
        $subItem.ForeColor = "White"
    }
}
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

# --- ROW 2: SETTINGS (RE-DESIGNED & FIXED) ---
$grpSettings = New-Object System.Windows.Forms.GroupBox
$grpSettings.Text = " Configuration "
$grpSettings.Location = New-Object System.Drawing.Point(20, 100)
$grpSettings.Size = New-Object System.Drawing.Size(550, 135) 
$grpSettings.ForeColor = "Silver"
$form.Controls.Add($grpSettings)

# --- LINE 1: PATH & ACTIONS (Y=25) ---
$txtPath = New-Object System.Windows.Forms.TextBox
$txtPath.Location = New-Object System.Drawing.Point(15, 26); 
$txtPath.Size = New-Object System.Drawing.Size(340, 25)
$txtPath.BackColor = [System.Drawing.Color]::FromArgb(45,45,45)
$txtPath.ForeColor = "Cyan"
$txtPath.BorderStyle = "FixedSingle"
$grpSettings.Controls.Add($txtPath)

# ปุ่ม Auto-Detect
$btnAuto = New-Object System.Windows.Forms.Button
$btnAuto.Text = "Auto Find"
$btnAuto.Location = New-Object System.Drawing.Point(365, 25); 
$btnAuto.Size = New-Object System.Drawing.Size(100, 27) 
Apply-ButtonStyle -Button $btnAuto -BaseColorName "DodgerBlue" -HoverColorName "DeepSkyBlue" -CustomFont $script:fontNormal
$grpSettings.Controls.Add($btnAuto)

# ปุ่ม Browse
$btnBrowse = New-Object System.Windows.Forms.Button
$btnBrowse.Text = "..."
$btnBrowse.Location = New-Object System.Drawing.Point(475, 25); 
$btnBrowse.Size = New-Object System.Drawing.Size(60, 27)
Apply-ButtonStyle -Button $btnBrowse -BaseColorName "DimGray" -HoverColorName "Gray" -CustomFont $script:fontNormal
$grpSettings.Controls.Add($btnBrowse)

# --- LINE 2: TOGGLES (Y=65) ---

# 1. Discord Toggle
$chkSendDiscord = New-Object System.Windows.Forms.CheckBox
$chkSendDiscord.Appearance = "Button" 
$chkSendDiscord.Size = New-Object System.Drawing.Size(255, 30) 
$chkSendDiscord.Location = New-Object System.Drawing.Point(15, 65)
$chkSendDiscord.FlatStyle = "Flat"; $chkSendDiscord.FlatAppearance.BorderSize = 0
$chkSendDiscord.TextAlign = "MiddleCenter"
$chkSendDiscord.Cursor = [System.Windows.Forms.Cursors]::Hand
$chkSendDiscord.Checked = $true 

# Logic เปลี่ยนสี Discord (แก้ตรงนี้ครับ)
$discordToggleEvent = {
    if ($chkSendDiscord.Checked) {
        $chkSendDiscord.Text = "Discord Report: ON"
        $chkSendDiscord.BackColor = "MediumSlateBlue" 
        $chkSendDiscord.ForeColor = "White"
    } else {
        $chkSendDiscord.Text = "Discord Report: OFF"
        # ต้องใช้ [System.Drawing.Color]::FromArgb(...)
        $chkSendDiscord.BackColor = [System.Drawing.Color]::FromArgb(60,60,60) 
        $chkSendDiscord.ForeColor = "Gray"
    }
}
$chkSendDiscord.Add_CheckedChanged($discordToggleEvent)
& $discordToggleEvent # Apply สีเริ่มต้น
$grpSettings.Controls.Add($chkSendDiscord)
$toolTip.SetToolTip($chkSendDiscord, "Auto-Send report to Discord after fetching.")

# 2. View Toggle (Show No.)
$chkShowNo = New-Object System.Windows.Forms.CheckBox
$chkShowNo.Appearance = "Button"
$chkShowNo.Size = New-Object System.Drawing.Size(255, 30) 
$chkShowNo.Location = New-Object System.Drawing.Point(280, 65)
$chkShowNo.FlatStyle = "Flat"; $chkShowNo.FlatAppearance.BorderSize = 0
$chkShowNo.TextAlign = "MiddleCenter"
$chkShowNo.Cursor = [System.Windows.Forms.Cursors]::Hand
$chkShowNo.Checked = $false

# Logic เปลี่ยนสี View (แก้ตรงนี้ครับ)
$viewToggleEvent = {
    if ($chkShowNo.Checked) {
        $chkShowNo.Text = "View: Index [No.]"
        $chkShowNo.BackColor = "Gold" 
        $chkShowNo.ForeColor = "Black"
    } else {
        $chkShowNo.Text = "View: Timestamp"
        # ต้องใช้ [System.Drawing.Color]::FromArgb(...)
        $chkShowNo.BackColor = [System.Drawing.Color]::FromArgb(60,60,60)
        $chkShowNo.ForeColor = "Gray"
    }
    
    # Realtime Update Logic
    if ($null -ne $script:LastFetchedData -and $script:LastFetchedData.Count -gt 0) {
        Update-FilteredView
    }
}
$chkShowNo.Add_CheckedChanged($viewToggleEvent)
& $viewToggleEvent # Apply สีเริ่มต้น
$grpSettings.Controls.Add($chkShowNo)

# --- LINE 3: BANNER SELECTOR (Y=105) ---
$lblBanner = New-Object System.Windows.Forms.Label
$lblBanner.Text = "Target Banner:"
$lblBanner.AutoSize = $true
$lblBanner.Location = New-Object System.Drawing.Point(15, 108)
$lblBanner.ForeColor = "Silver"
$grpSettings.Controls.Add($lblBanner)

$script:cmbBanner = New-Object System.Windows.Forms.ComboBox
$script:cmbBanner.Location = New-Object System.Drawing.Point(110, 105); 
$script:cmbBanner.Size = New-Object System.Drawing.Size(425, 25) 
$script:cmbBanner.DropDownStyle = "DropDownList"
$script:cmbBanner.BackColor = [System.Drawing.Color]::FromArgb(45,45,45)
$script:cmbBanner.ForeColor = "White"
$script:cmbBanner.FlatStyle = "Flat"
$grpSettings.Controls.Add($script:cmbBanner)

# ============================================
#  --- ROW 3: PITY METER (Re-designed) ---
#  (ย้ายลงมาที่ Y=250 เพื่อหลบ Settings อันใหม่)
# ============================================

# Title Label (ปรับตำแหน่ง + ฟอนต์)
$script:lblPityTitle = New-Object System.Windows.Forms.Label
$script:lblPityTitle.Text = "Current Pity Status"; 
$script:lblPityTitle.Location = New-Object System.Drawing.Point(20, 250); 
$script:lblPityTitle.AutoSize = $true
$script:lblPityTitle.Font = $script:fontBold
$script:lblPityTitle.ForeColor = "Silver"
$form.Controls.Add($script:lblPityTitle)

# Meter Background (ทำให้ดู Modern ขึ้น: ผอมลงแต่ยาว)
$pnlPityBack = New-Object System.Windows.Forms.Panel
$pnlPityBack.Location = New-Object System.Drawing.Point(20, 275); 
$pnlPityBack.Size = New-Object System.Drawing.Size(550, 15) # ลดความสูงเหลือ 15px ดู Sleek
$pnlPityBack.BackColor = [System.Drawing.Color]::FromArgb(40,40,40)
$pnlPityBack.BorderStyle = "None"
$form.Controls.Add($pnlPityBack)

# Meter Fill (ไส้ใน)
$script:pnlPityFill = New-Object System.Windows.Forms.Panel
$script:pnlPityFill.Location = New-Object System.Drawing.Point(0, 0); 
$script:pnlPityFill.Size = New-Object System.Drawing.Size(0, 15)
$script:pnlPityFill.BackColor = "DodgerBlue" # เปลี่ยนสี Default เป็นฟ้า
$pnlPityBack.Controls.Add($script:pnlPityFill)

# ============================================
#  --- ROW 4: BUTTONS (No Loading Bar) ---
#  (ขยับขึ้นมาแทนที่ Progress Bar เดิมที่เอาออกไป)
# ============================================
$btnRun = New-Object System.Windows.Forms.Button
$btnRun.Text = "START FETCHING"; 
$btnRun.Location = New-Object System.Drawing.Point(20, 310); # Y=310
$btnRun.Size = New-Object System.Drawing.Size(400, 45)
Apply-ButtonStyle -Button $btnRun -BaseColorName "ForestGreen" -HoverColorName "LimeGreen" -CustomFont $script:fontHeader
$form.Controls.Add($btnRun)

$btnStop = New-Object System.Windows.Forms.Button
$btnStop.Text = "STOP"; 
$btnStop.Location = New-Object System.Drawing.Point(430, 310); # Y=310
$btnStop.Size = New-Object System.Drawing.Size(140, 45)
$btnStop.BackColor = "Firebrick"; 
$btnStop.ForeColor = "White"; 
$btnStop.Font = $script:fontBold
$btnStop.FlatStyle = "Flat"; 
$btnStop.FlatAppearance.BorderSize = 0
$btnStop.Enabled = $false
$form.Controls.Add($btnStop)

# --- ROW 4.5: STATS DASHBOARD (Y=360) [MODIFIED] ---
$grpStats = New-Object System.Windows.Forms.GroupBox
$grpStats.Text = " Luck Analysis (Based on fetched data) "
$grpStats.Location = New-Object System.Drawing.Point(20, 360); $grpStats.Size = New-Object System.Drawing.Size(550, 60)
$grpStats.ForeColor = "Silver"
$form.Controls.Add($grpStats)

# Label 1: Total Pulls (ขยับซ้ายสุด X=15)
$lblStat1 = New-Object System.Windows.Forms.Label
$lblStat1.Text = "Total Pulls: 0"; $lblStat1.AutoSize = $true
$lblStat1.Location = New-Object System.Drawing.Point(15, 25); 
$lblStat1.Font = $script:fontNormal
$grpStats.Controls.Add($lblStat1)

# Label 2: Avg Pity (ขยับมาที่ X=130)
$script:lblStatAvg = New-Object System.Windows.Forms.Label
$script:lblStatAvg.Text = "Avg. Pity: -"; $script:lblStatAvg.AutoSize = $true
$script:lblStatAvg.Location = New-Object System.Drawing.Point(130, 25); 
$script:lblStatAvg.Font = $script:fontBold
$script:lblStatAvg.ForeColor = "White"
$grpStats.Controls.Add($script:lblStatAvg)

# [NEW] Label 3: Luck Grade (แทรกตรงกลาง X=260)
$script:lblLuckGrade = New-Object System.Windows.Forms.Label
$script:lblLuckGrade.Text = "Grade: -"; $script:lblLuckGrade.AutoSize = $true
$script:lblLuckGrade.Location = New-Object System.Drawing.Point(260, 25); 
$script:lblLuckGrade.Font = $script:fontBold
$script:lblLuckGrade.ForeColor = "DimGray"
$script:lblLuckGrade.Cursor = [System.Windows.Forms.Cursors]::Help # เปลี่ยนเมาส์เป็นรูปเครื่องหมาย ?
$grpStats.Controls.Add($script:lblLuckGrade)

# ใส่ Tooltip อธิบายเกณฑ์
$gradeInfo = "Luck Grading Criteria (Global Standard):`n`n" +
             "SS : Avg < 50   (Godlike)`n" +
             " A : 50 - 60    (Lucky)`n" +
             " B : 61 - 73    (Average)`n" +
             " C : 74 - 76    (Salty)`n" +
             " F : > 76       (Cursed)"
$toolTip.SetToolTip($script:lblLuckGrade, $gradeInfo)

# Label 4: Cost (ขยับไปขวาสุด X=390)
$script:lblStatCost = New-Object System.Windows.Forms.Label
$script:lblStatCost.Text = "Est. Cost: 0"; $script:lblStatCost.AutoSize = $true
$script:lblStatCost.Location = New-Object System.Drawing.Point(390, 25); 
$script:lblStatCost.Font = $script:fontNormal
$script:lblStatCost.ForeColor = "Gold" 
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

# --- [NEW] 1. CHART TYPE SELECTOR (มุมขวาบนของกราฟ) ---
$cmbChartType = New-Object System.Windows.Forms.ComboBox
$cmbChartType.Items.AddRange(@("Column", "Bar", "Spline", "Line", "Area", "StepLine", "Rate Analysis"))
$cmbChartType.SelectedIndex = 0 # Default = Column
$cmbChartType.Size = New-Object System.Drawing.Size(80, 25)
$cmbChartType.Anchor = "Top, Right"
$cmbChartType.Location = New-Object System.Drawing.Point(($pnlChart.Width - 90), 5)
$cmbChartType.DropDownStyle = "DropDownList"
$cmbChartType.BackColor = "DimGray"
$cmbChartType.ForeColor = "White"
$cmbChartType.FlatStyle = "Flat"
$cmbChartType.Font = $script:fontNormal

# --- [NEW] 2. SAVE IMAGE BUTTON ---
$btnSaveImg = New-Object System.Windows.Forms.Button
$btnSaveImg.Text = "Save IMG"
$btnSaveImg.Size = New-Object System.Drawing.Size(80, 25)
# วางข้างๆ ComboBox (ขยับซ้ายมา 85px)
$btnSaveImg.Location = New-Object System.Drawing.Point(($pnlChart.Width - 175), 5) 
$btnSaveImg.Anchor = "Top, Right"

# Style
$btnSaveImg.BackColor = "Indigo" # สีม่วงเข้มดูหรู
$btnSaveImg.ForeColor = "White"
$btnSaveImg.FlatStyle = "Flat"
$btnSaveImg.FlatAppearance.BorderSize = 0
$btnSaveImg.Font = $script:fontNormal
$btnSaveImg.Cursor = [System.Windows.Forms.Cursors]::Hand

$pnlChart.Controls.Add($btnSaveImg)
$btnSaveImg.BringToFront()

# สั่งให้เปลี่ยนกราฟทันทีเมื่อเลือก
$cmbChartType.Add_SelectedIndexChanged({ 
    $type = $cmbChartType.SelectedItem
    # [NEW] สั่ง Log บอกว่า user เปลี่ยนไปดูกราฟแบบไหน
    Log "User switched chart view to: [$type]" "DimGray"
    
    if ($chart.Visible) { Update-Chart -DataList $script:CurrentChartData }
})
$pnlChart.Controls.Add($cmbChartType)
$cmbChartType.BringToFront() # ดึงมาบัง Chart ไว้

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
# Helper สำหรับล้างหน้าจอและคืนค่า Style เริ่มต้น
function Reset-LogWindow {
    # 1. ล้างข้อความ
    $txtLog.Clear()
    
    # 2. บังคับคืนค่า Style (กันเหนียวกรณีมาจากหน้า Credits)
    $txtLog.SelectionAlignment = "Left"       # ชิดซ้าย
    $txtLog.SelectionFont = $script:fontLog   # ใช้ Font ปกติ (Consolas)
    $txtLog.SelectionColor = "Lime"           # สีเขียว
}

function Log($msg, $color="Lime") { 
    # --- ส่วนแสดงผลใน Debug Console (PowerShell Window) ---
    if ($script:DebugMode) {
        # แปลงชื่อสีจาก System.Drawing เป็น ConsoleColor
        $consoleColor = "White" # Default
        switch ($color) {
            "Lime"      { $consoleColor = "Green" }
            "Gold"      { $consoleColor = "Yellow" }
            "OrangeRed" { $consoleColor = "Red" }
            "Crimson"   { $consoleColor = "Red" }
            "DimGray"   { $consoleColor = "DarkGray" }
            "Cyan"      { $consoleColor = "Cyan" }
            "Magenta"   { $consoleColor = "Magenta" }
            "Gray"      { $consoleColor = "Gray" }
            "Yellow"    { $consoleColor = "Yellow" }
        }
        
        # พิมพ์ลง Console พร้อมระบุเวลา
        $timeStamp = Get-Date -Format "HH:mm:ss"
        Write-Host "[$timeStamp] $msg" -ForegroundColor $consoleColor
    }

    # --- ส่วนแสดงผลใน GUI (เหมือนเดิม) ---
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
# 5. START FETCHING
$btnRun.Add_Click({
    Reset-LogWindow

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

    # Reset UI Pity Meter
    $script:pnlPityFill.Width = 0
    $script:lblPityTitle.Text = "Fetching Data..."
    $script:lblPityTitle.ForeColor = "Cyan"

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

        # --- FETCH LOOP ---
        foreach ($banner in $TargetBanners) {
            if ($script:StopRequested) { throw "STOPPED" }

            Log "Fetching: $($banner.Name)..." "Magenta"

            $items = Fetch-GachaPages -Url $auth.Url -HostUrl $auth.Host -Endpoint $conf.ApiEndpoint -BannerCode $banner.Code -PageCallback { 
                param($p) 
                # Update GUI Text
                $form.Text = "Fetching $($banner.Name) - Page $p..." 
                [System.Windows.Forms.Application]::DoEvents()
                if ($script:StopRequested) { throw "STOPPED" }
            }
            
            if ($script:DebugMode) { Write-Host "" } 
            
            foreach ($item in $items) { 
                $item | Add-Member -MemberType NoteProperty -Name "_BannerName" -Value $banner.Name -Force
            }
            $allHistory += $items
            Log "  > Found $($items.Count) items." "Gray"
        }
        
        # Save to memory
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
        $grpFilter.Enabled = $true
        Update-FilteredView

        # --- [NEW] UPDATE PITY GAUGE UI (Dynamic Max Pity 80/90) ---
        
        # 1. คำนวณ Pity ปัจจุบัน
        $currentPity = 0
        $latestGachaType = "" 

        if ($allHistory.Count -gt 0) {
            # $allHistory[0] คือตัวใหม่ล่าสุด (เพราะตอน Fetch มันเรียง Newest มา)
            $latestGachaType = $allHistory[0].gacha_type 
            foreach ($item in $allHistory) {
                if ($item.rank_type -eq $conf.SRank) { 
                    break 
                }
                $currentPity++
            }
        }

        # 2. Logic ตรวจสอบ Max Pity (90 หรือ 80)
        $maxPity = 90
        $typeLabel = "Character"
        
        # รหัสตู้: 302=Genshin Weapon, 12=HSR LC, 3=ZZZ W-Engine, 5=ZZZ Bangboo
        if ($latestGachaType -match "^(302|12|3|5)$") {
            $maxPity = 80
            $typeLabel = "Weapon/LC"
        }

        # 3. คำนวณความยาวหลอด (เต็มหลอด 550px)
        $percent = 0
        if ($maxPity -gt 0) { $percent = $currentPity / $maxPity }
        if ($percent -gt 1) { $percent = 1 }
        
        $newWidth = [int](550 * $percent)
        
        # อัปเดต UI
        $script:pnlPityFill.Width = $newWidth
        $script:lblPityTitle.Text = "Current Pity ($typeLabel): $currentPity / $maxPity"

        # 4. Logic สีหลอด
        if ($percent -ge 0.82) { # Soft Pity zone
            $script:pnlPityFill.BackColor = "Crimson" 
            $script:lblPityTitle.ForeColor = "Red"    
        } elseif ($percent -ge 0.55) { 
            $script:pnlPityFill.BackColor = "Gold"    
            $script:lblPityTitle.ForeColor = "Gold"
        } else { 
            $script:pnlPityFill.BackColor = "DodgerBlue" 
            $script:lblPityTitle.ForeColor = "White"
        }

        # --- STATS CALCULATION ---
        $totalPulls = $allHistory.Count
        $total5Star = $highRankHistory.Count
        $avgPity = 0
        
        $lblStat1.Text = "Total Pulls: $totalPulls"

        if ($total5Star -gt 0) {
            $avgPity = "{0:N2}" -f ($totalPulls / $total5Star)
            $script:lblStatAvg.Text = "Avg. Pity: $avgPity"
            
            if ([double]$avgPity -le 55) { $script:lblStatAvg.ForeColor = "Lime" }   
            elseif ([double]$avgPity -le 73) { $script:lblStatAvg.ForeColor = "Gold" } 
            else { $script:lblStatAvg.ForeColor = "OrangeRed" }                       
        } else {
            $script:lblStatAvg.Text = "Avg. Pity: N/A"
            $script:lblStatAvg.ForeColor = "Gray"
        }

        # Cost
        $cost = $totalPulls * 160
        $currencyName = "Primos"
        if ($script:CurrentGame -eq "HSR") { $currencyName = "Jades" }
        elseif ($script:CurrentGame -eq "ZZZ") { $currencyName = "Polychromes" }
        
        $costStr = "{0:N0}" -f $cost
        $script:lblStatCost.Text = "Est. Cost: $costStr $currencyName"
        
        # === DISCORD ===
        if ($SendDiscord) {
            Log "`nSending report to Discord..." "Magenta"
            $discordMsg = Send-DiscordReport -HistoryData $highRankHistory -PityTrackers $pityTrackers -Config $conf -ShowNoMode $ShowNo
            Log "Discord: $discordMsg" "Lime"
        }
        
        if ($allHistory.Count -gt 0) {
            $btnExport.Enabled = $true
            Apply-ButtonStyle -Button $btnExport -BaseColorName "RoyalBlue" -HoverColorName "CornflowerBlue" -CustomFont $script:fontBold
            $script:itemForecast.Enabled = $true
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
        
        if ($script:LastFetchedData.Count -gt 0) { $grpFilter.Enabled = $true }
    }
})
$btnSaveImg.Add_Click({
    Log "User clicked [Save Image] button." "Magenta"
    
    if (-not $chart.Visible) { 
        [System.Windows.Forms.MessageBox]::Show("No graph to save!", "Error", 0, 16)
        return 
    }

    # ใช้ตัวแปรเก็บนอก Loop
    $memName = ""
    $memUID = ""
    $loop = $true 

    while ($loop) {
        # ==========================================
        # STEP 1: INPUT POPUP
        # ==========================================
        $inputForm = New-Object System.Windows.Forms.Form
        $inputForm.Text = "Add Watermark"
        $inputForm.Size = New-Object System.Drawing.Size(350, 180)
        $inputForm.StartPosition = "CenterParent"
        $inputForm.FormBorderStyle = "FixedDialog"
        $inputForm.MaximizeBox = $false; $inputForm.MinimizeBox = $false
        $inputForm.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40); $inputForm.ForeColor = "White"

        $lbl1 = New-Object System.Windows.Forms.Label; $lbl1.Text = "Player Name:"; $lbl1.Location = "20,20"; $lbl1.AutoSize=$true
        $txtName = New-Object System.Windows.Forms.TextBox; $txtName.Location = "120,18"; $txtName.Width = 180; $txtName.BackColor="60,60,60"; $txtName.ForeColor="Cyan"
        
        # [จุดสำคัญ] ดึงค่าเดิมมาใส่
        $txtName.Text = $memName 

        $lbl2 = New-Object System.Windows.Forms.Label; $lbl2.Text = "UID (Game):"; $lbl2.Location = "20,55"; $lbl2.AutoSize=$true
        $txtUID = New-Object System.Windows.Forms.TextBox; $txtUID.Location = "120,53"; $txtUID.Width = 180; $txtUID.BackColor="60,60,60"; $txtUID.ForeColor="Gold"
        
        # [จุดสำคัญ] ดึงค่าเดิมมาใส่
        $txtUID.Text = $memUID 

        $btnOK = New-Object System.Windows.Forms.Button; $btnOK.Text = "Preview >"; $btnOK.DialogResult = "OK"; $btnOK.Location = "130,100"; $btnOK.BackColor="RoyalBlue"; $btnOK.ForeColor="White"; $btnOK.FlatStyle="Flat"
        $btnCancel = New-Object System.Windows.Forms.Button; $btnCancel.Text = "Close"; $btnCancel.DialogResult = "Cancel"; $btnCancel.Location = "220,100"; $btnCancel.BackColor="DimGray"; $btnCancel.ForeColor="White"; $btnCancel.FlatStyle="Flat"

        $inputForm.Controls.AddRange(@($lbl1, $txtName, $lbl2, $txtUID, $btnOK, $btnCancel))
        $inputForm.AcceptButton = $btnOK

        # ถ้ากด Close หรือกากบาทในหน้า Input -> จบการทำงานทันที
        if ($inputForm.ShowDialog() -ne "OK") { 
            $loop = $false 
            $inputForm.Dispose()
            break 
        }
        
        # จำค่าไว้ใช้รอบหน้า
        $memName = $txtName.Text.Trim()
        $memUID  = $txtUID.Text.Trim()
        $inputForm.Dispose()

        # ==========================================
        # STEP 2: GENERATE BITMAP
        # ==========================================
        try {
            $footerHeight = 70
            $finalWidth = $chart.Width
            $finalHeight = $chart.Height + $footerHeight
            
            $previewBmp = New-Object System.Drawing.Bitmap($finalWidth, $finalHeight)
            $g = [System.Drawing.Graphics]::FromImage($previewBmp)
            $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias
            $g.Clear([System.Drawing.Color]::FromArgb(25,25,25)) 

            $chartBmp = New-Object System.Drawing.Bitmap($chart.Width, $chart.Height)
            $chart.DrawToBitmap($chartBmp, $chart.ClientRectangle)
            $g.DrawImage($chartBmp, 0, 0)
            $chartBmp.Dispose()

            $footerRect = New-Object System.Drawing.Rectangle(0, $chart.Height, $finalWidth, $footerHeight)
            $brushFooter = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(40,40,40))
            $g.FillRectangle($brushFooter, $footerRect)
            $penLine = New-Object System.Drawing.Pen([System.Drawing.Color]::Gold, 2)
            $g.DrawLine($penLine, 0, $chart.Height, $finalWidth, $chart.Height)

            $fontBrand = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
            $brandText = "Universal Hoyo Wish Counter"
            $g.DrawString($brandText, $fontBrand, [System.Drawing.Brushes]::Gray, 20, ($chart.Height + 22))
            
            $brandSize = $g.MeasureString($brandText, $fontBrand)
            $safeZoneLeft = 20 + $brandSize.Width + 30 
            
            $fontInfo = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
            $fontDate = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Regular)
            
            $rawName = if ($memName -ne "") { "Player: $memName" } else { "Player: Traveler" }
            $rawUID  = if ($memUID -ne "")  { "  |  UID: $memUID" } else { "" }
            
            $maxAvailableWidth = $finalWidth - 20 - $safeZoneLeft 
            $fullText = $rawName + $rawUID
            
            if ($g.MeasureString($fullText, $fontInfo).Width -gt $maxAvailableWidth) {
                $tempName = $memName
                while ($true) {
                    if ($tempName.Length -eq 0) { break }
                    $tempName = $tempName.Substring(0, $tempName.Length - 1)
                    $tryText = "Player: $tempName..." + $rawUID
                    if ($g.MeasureString($tryText, $fontInfo).Width -le $maxAvailableWidth) {
                        $fullText = $tryText; break
                    }
                }
            }
            
            $dateText = "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
            $formatRight = New-Object System.Drawing.StringFormat; $formatRight.Alignment = "Far"
            
            $g.DrawString($fullText, $fontInfo, [System.Drawing.Brushes]::White, ($finalWidth - 20), ($chart.Height + 12), $formatRight)
            $g.DrawString($dateText, $fontDate, [System.Drawing.Brushes]::LightGray, ($finalWidth - 20), ($chart.Height + 38), $formatRight)
            $g.Dispose()

            # ==========================================
            # STEP 3: PREVIEW WINDOW
            # ==========================================
            $previewForm = New-Object System.Windows.Forms.Form
            $previewForm.Text = "Preview Image"
            $previewForm.Size = New-Object System.Drawing.Size(800, 600)
            $previewForm.StartPosition = "CenterParent"
            $previewForm.BackColor = [System.Drawing.Color]::FromArgb(30,30,30)

            $pnlBottom = New-Object System.Windows.Forms.Panel
            $pnlBottom.Dock = "Bottom"
            $pnlBottom.Height = 60
            $pnlBottom.BackColor = [System.Drawing.Color]::FromArgb(50,50,50)

            $picPreview = New-Object System.Windows.Forms.PictureBox
            $picPreview.Dock = "Fill"
            $picPreview.Image = $previewBmp
            $picPreview.SizeMode = "Zoom"
            $picPreview.BackColor = "Black"
            
            # ปุ่ม Confirm
            $btnConfirm = New-Object System.Windows.Forms.Button
            $btnConfirm.Text = "Confirm & Save"
            $btnConfirm.Size = New-Object System.Drawing.Size(140, 35)
            $btnConfirm.Anchor = "Top, Right" 
            $btnConfirm.Location = New-Object System.Drawing.Point(($pnlBottom.Width - 160), 12)
            Apply-ButtonStyle -Button $btnConfirm -BaseColorName "ForestGreen" -HoverColorName "LimeGreen" -CustomFont $script:fontBold
            
            # ปุ่ม Back
            $btnBack = New-Object System.Windows.Forms.Button
            $btnBack.Text = "< Back to Edit"
            $btnBack.Size = New-Object System.Drawing.Size(120, 35)
            $btnBack.Anchor = "Top, Right"
            $btnBack.Location = New-Object System.Drawing.Point(($pnlBottom.Width - 300), 12)
            Apply-ButtonStyle -Button $btnBack -BaseColorName "DimGray" -HoverColorName "Gray" -CustomFont $script:fontBold

            # [FIXED] ใช้ Hashtable เก็บค่า State (เพื่อให้ส่งค่าข้าม Scope ของปุ่มได้)
            $state = @{ Action = "None" }

            $btnConfirm.Add_Click({
                $sfd = New-Object System.Windows.Forms.SaveFileDialog
                $sfd.Filter = "PNG Image|*.png|JPEG Image|*.jpg"
                $gName = $script:CurrentGame
                $dateStr = Get-Date -Format 'yyyyMMdd_HHmm'
                $sfd.FileName = "${gName}_LuckChart_${dateStr}"

                if ($sfd.ShowDialog() -eq "OK") {
                    try {
                        $format = [System.Drawing.Imaging.ImageFormat]::Png
                        if ($sfd.FileName.EndsWith(".jpg") -or $sfd.FileName.EndsWith(".jpeg")) { 
                            $format = [System.Drawing.Imaging.ImageFormat]::Jpeg 
                        }
                        $previewBmp.Save($sfd.FileName, $format)
                        Log "Image saved to: $($sfd.FileName)" "Lime"
                        [System.Windows.Forms.MessageBox]::Show("Saved!", "Success", 0, 64)
                        
                        $state.Action = "Save" # อัปเดต state
                        $previewForm.Close()
                    } catch {
                        [System.Windows.Forms.MessageBox]::Show("Error: $($_.Exception.Message)", "Error", 0, 16)
                    }
                }
            })

            $btnBack.Add_Click({
                $state.Action = "Back" # อัปเดต state
                $previewForm.Close()
            })

            $pnlBottom.Controls.Add($btnConfirm)
            $pnlBottom.Controls.Add($btnBack)
            $previewForm.Controls.Add($pnlBottom) 
            $previewForm.Controls.Add($picPreview)
            $pnlBottom.SendToBack()

            $previewForm.ShowDialog()
            
            $previewBmp.Dispose()
            $previewForm.Dispose()

            # [CHECK STATE]
            if ($state.Action -eq "Save") {
                $loop = $false # จบงาน
            } elseif ($state.Action -eq "Back") {
                # วนลูปต่อ (กลับไปหน้า Input พร้อมค่า $memName เดิม)
                Log "User requested Back to Edit." "DimGray"
            } else {
                # กดปิดหน้าต่าง Preview (กากบาท)
                $loop = $false
            }

        } catch {
            Log "Error: $($_.Exception.Message)" "Red"
            $loop = $false
        }
    } # End Loop
})

# ==========================================
#  EVENT: MENU FORECAST CLICK
# ==========================================
$script:itemForecast.Add_Click({
    Log "Action: Open Forecast Simulator Window" "Cyan"

    # 1. AUTO-DETECT DATA
    $currentPity = 0; $isGuaranteed = $false; $mode = "Character (90)"; $hardCap = 90; $softCap = 74
    if ($null -ne $script:LastFetchedData -and $script:LastFetchedData.Count -gt 0) {
        $conf = Get-GameConfig $script:CurrentGame
        foreach ($item in $script:LastFetchedData) {
            if ($item.rank_type -eq $conf.SRank) { 
                $status = Get-GachaStatus -GameName $script:CurrentGame -CharName $item.name -BannerCode $item.gacha_type
                if ($status -eq "LOSS") { $isGuaranteed = $true }
                break 
            }
            $currentPity++
        }
        $lastType = $script:LastFetchedData[0].gacha_type
        if ($lastType -match "^(302|12|3|5)$") { $mode = "Weapon/LC (80)"; $hardCap = 80; $softCap = 64 }
        Log "[Forecast] Auto-Detected: Pity=$currentPity, Guaranteed=$isGuaranteed, Mode=$mode" "Gray"
    }

    # 2. UI SETUP
    $fSim = New-Object System.Windows.Forms.Form
    $fSim.Text = "Hoyo Wish Forecast (v5.1.0)"
    $fSim.Size = New-Object System.Drawing.Size(900, 580)
    $fSim.StartPosition = "CenterParent"
    $fSim.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 40)
    $fSim.ForeColor = "White"
    $fSim.FormBorderStyle = "FixedDialog"
    $fSim.MaximizeBox = $false

    # Init Stop Flag
    $script:SimStopRequested = $false

    # --- LEFT PANEL: INPUTS ---
    $pnlLeft = New-Object System.Windows.Forms.Panel; $pnlLeft.Location="0,0"; $pnlLeft.Size="380,550"; $pnlLeft.BackColor="Transparent"; $fSim.Controls.Add($pnlLeft)

    $l1 = New-Object System.Windows.Forms.Label; $l1.Text="CURRENT STATUS"; $l1.Location="20,20"; $l1.AutoSize=$true; $l1.Font=$script:fontBold; $l1.ForeColor="Gold"; $pnlLeft.Controls.Add($l1)
    
    $l2 = New-Object System.Windows.Forms.Label; $l2.Text="Current Pity:"; $l2.Location="30,50"; $l2.AutoSize=$true; $l2.ForeColor="Silver"; $pnlLeft.Controls.Add($l2)
    $txtPity = New-Object System.Windows.Forms.TextBox; $txtPity.Text="$currentPity"; $txtPity.Location="120,48"; $txtPity.Width=50; $txtPity.BackColor="30,30,50"; $txtPity.ForeColor="Cyan"; $txtPity.BorderStyle="FixedSingle"; $txtPity.TextAlign="Center"; $pnlLeft.Controls.Add($txtPity)

    $l3 = New-Object System.Windows.Forms.Label; $l3.Text="Guaranteed?"; $l3.Location="200,50"; $l3.AutoSize=$true; $l3.ForeColor="Silver"; $pnlLeft.Controls.Add($l3)
    $chkG = New-Object System.Windows.Forms.CheckBox; $chkG.Location="290,46"; $chkG.Text="YES"; $chkG.Checked=$isGuaranteed; $chkG.ForeColor="Lime"; $chkG.AutoSize=$true; $pnlLeft.Controls.Add($chkG)
    $chkG.Add_CheckedChanged({ if($chkG.Checked){$chkG.Text="YES";$chkG.ForeColor="Lime"}else{$chkG.Text="NO";$chkG.ForeColor="Gray"} })

    $l4 = New-Object System.Windows.Forms.Label; $l4.Text="Mode: $mode"; $l4.Location="30,80"; $l4.AutoSize=$true; $l4.ForeColor="DimGray"; $pnlLeft.Controls.Add($l4)

    $l5 = New-Object System.Windows.Forms.Label; $l5.Text="RESOURCES"; $l5.Location="20,120"; $l5.AutoSize=$true; $l5.Font=$script:fontBold; $l5.ForeColor="Gold"; $pnlLeft.Controls.Add($l5)
    $l6 = New-Object System.Windows.Forms.Label; $l6.Text="Primos / Jades:"; $l6.Location="30,150"; $l6.AutoSize=$true; $l6.ForeColor="Silver"; $pnlLeft.Controls.Add($l6)
    $txtPrimos = New-Object System.Windows.Forms.TextBox; $txtPrimos.Text="0"; $txtPrimos.Location="140,148"; $txtPrimos.Width=100; $txtPrimos.BackColor="30,30,50"; $txtPrimos.ForeColor="Cyan"; $txtPrimos.BorderStyle="FixedSingle"; $txtPrimos.TextAlign="Center"; $pnlLeft.Controls.Add($txtPrimos)
    $l7 = New-Object System.Windows.Forms.Label; $l7.Text="Fates / Tickets:"; $l7.Location="30,180"; $l7.AutoSize=$true; $l7.ForeColor="Silver"; $pnlLeft.Controls.Add($l7)
    $txtFates = New-Object System.Windows.Forms.TextBox; $txtFates.Text="0"; $txtFates.Location="140,178"; $txtFates.Width=100; $txtFates.BackColor="30,30,50"; $txtFates.ForeColor="Cyan"; $txtFates.BorderStyle="FixedSingle"; $txtFates.TextAlign="Center"; $pnlLeft.Controls.Add($txtFates)

    $l8 = New-Object System.Windows.Forms.Label; $l8.Text="Total Pulls:"; $l8.Location="30,215"; $l8.AutoSize=$true; $l8.Font=$script:fontBold; $l8.ForeColor="White"; $pnlLeft.Controls.Add($l8)
    $lblTotalPulls = New-Object System.Windows.Forms.Label; $lblTotalPulls.Text="0"; $lblTotalPulls.Location="140,215"; $lblTotalPulls.AutoSize=$true; $lblTotalPulls.Font=$script:fontBold; $lblTotalPulls.ForeColor="Cyan"; $pnlLeft.Controls.Add($lblTotalPulls)

    $calcAction = { try { $lblTotalPulls.Text = "$([math]::Floor([int]$txtPrimos.Text / 160) + [int]$txtFates.Text)" } catch { $lblTotalPulls.Text="0" } }
    $txtPrimos.Add_TextChanged($calcAction); $txtFates.Add_TextChanged($calcAction)

    # --- [NEW] BUTTON LAYOUT (Run & Stop) ---
    $btnSim = New-Object System.Windows.Forms.Button; $btnSim.Text="RUN SIMULATION"; $btnSim.Location="40, 260"; $btnSim.Size="220, 45" # ลดขนาดลง
    Apply-ButtonStyle -Button $btnSim -BaseColorName "MediumSlateBlue" -HoverColorName "SlateBlue" -CustomFont $script:fontHeader
    $pnlLeft.Controls.Add($btnSim)

    $btnStopSim = New-Object System.Windows.Forms.Button; $btnStopSim.Text="STOP"; $btnStopSim.Location="270, 260"; $btnStopSim.Size="80, 45"
    $btnStopSim.BackColor = "Firebrick"; $btnStopSim.ForeColor = "White"; $btnStopSim.FlatStyle = "Flat"; $btnStopSim.FlatAppearance.BorderSize = 0; $btnStopSim.Font = $script:fontBold
    $btnStopSim.Enabled = $false
    $pnlLeft.Controls.Add($btnStopSim)

    # RESULT BOX
    $pnlRes = New-Object System.Windows.Forms.Panel; $pnlRes.Location="20,320"; $pnlRes.Size="345,180"; $pnlRes.BackColor="25,25,45"; $pnlRes.BorderStyle="FixedSingle"; $pnlLeft.Controls.Add($pnlRes)
    $lResTitle = New-Object System.Windows.Forms.Label; $lResTitle.Text="SIMULATION RESULT"; $lResTitle.Location="10,10"; $lResTitle.AutoSize=$true; $lResTitle.ForeColor="Silver"; $lResTitle.Font=$script:fontBold; $pnlRes.Controls.Add($lResTitle)
    
    $btnHelp = New-Object System.Windows.Forms.Button; $btnHelp.Text="?"; $btnHelp.Size="25,25"; $btnHelp.Location="310,5"; $btnHelp.FlatStyle="Flat"; $btnHelp.FlatAppearance.BorderSize=0; $btnHelp.BackColor="Transparent"; $btnHelp.ForeColor="Cyan"; $btnHelp.Font=$script:fontBold; $btnHelp.Cursor="Hand"; $pnlRes.Controls.Add($btnHelp)
    $btnHelp.Add_Click({ [System.Windows.Forms.MessageBox]::Show("Shows how many simulations succeeded at each pull count.", "Histogram Info", 0, 64) })

    $lblChance = New-Object System.Windows.Forms.Label; $lblChance.Text="Win Rate: -"; $lblChance.Location="10,40"; $lblChance.AutoSize=$true; $lblChance.ForeColor="White"; $lblChance.Font=$script:fontHeader; $pnlRes.Controls.Add($lblChance)
    $lblCost = New-Object System.Windows.Forms.Label; $lblCost.Text="Avg. Cost: -"; $lblCost.Location="10,80"; $lblCost.AutoSize=$true; $lblCost.ForeColor="Gray"; $pnlRes.Controls.Add($lblCost)
    
    $pbBack = New-Object System.Windows.Forms.Panel; $pbBack.Location="10,120"; $pbBack.Size="320,10"; $pbBack.BackColor="40,40,60"; $pnlRes.Controls.Add($pbBack)
    $pbFill = New-Object System.Windows.Forms.Panel; $pbFill.Location="0,0"; $pbFill.Size="0,10"; $pbFill.BackColor="Lime"; $pbBack.Controls.Add($pbFill)

    # --- RIGHT PANEL: CHART ---
    $pnlRight = New-Object System.Windows.Forms.Panel; $pnlRight.Location="380,20"; $pnlRight.Size="480,480"; $pnlRight.BackColor="Transparent"; $fSim.Controls.Add($pnlRight)
    $chartSim = New-Object System.Windows.Forms.DataVisualization.Charting.Chart; $chartSim.Dock="Fill"; $chartSim.BackColor="Transparent"; $pnlRight.Controls.Add($chartSim)
    $caSim = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea; $caSim.Name="SimArea"; $caSim.BackColor="Transparent"
    $caSim.AxisX.LabelStyle.ForeColor="Silver"; 
    $caSim.AxisX.LineColor="Gray"; 
    $caSim.AxisX.MajorGrid.LineColor=[System.Drawing.Color]::FromArgb(20,255,255,255); 
    $caSim.AxisX.Title="Pulls Used"; $caSim.AxisX.TitleForeColor="Gray"; 
    $caSim.AxisX.Interval=20

    $caSim.AxisY.LabelStyle.ForeColor="DimGray"; 
    $caSim.AxisY.LineColor="Gray"; 
    $caSim.AxisY.MajorGrid.LineColor=[System.Drawing.Color]::FromArgb(20,255,255,255); 
    
    $caSim.AxisY.Title = "Frequency (Simulations)" # ชื่อป้าย
    $caSim.AxisY.TitleForeColor = "Silver"
    $caSim.AxisY.TextOrientation = "Rotated270"      # หมุนแนวตั้ง
    $caSim.AxisY.TitleFont = $script:fontNormal      # ใช้ฟอนต์ปกติ

    $caSim.AxisY.LabelStyle.Enabled=$false
    
    
    $chartSim.ChartAreas.Add($caSim)
    $titleSim = New-Object System.Windows.Forms.DataVisualization.Charting.Title; $titleSim.Text="Probability Distribution"; $titleSim.ForeColor="Gold"; $titleSim.Font=$script:fontBold; $chartSim.Titles.Add($titleSim)

    # --- [NEW] STOP BUTTON LOGIC ---
    $btnStopSim.Add_Click({
        $script:SimStopRequested = $true
        Log "----------------------------------------" "DimGray"
        Log "[Action] Simulation CANCELLED by User!" "Red"
    })

    # --- RUN LOGIC ---
    $btnSim.Add_Click({
        $budget = [int]$lblTotalPulls.Text
        if ($budget -le 0) { [System.Windows.Forms.MessageBox]::Show("Please enter resources!", "No Budget", 0, 48); return }
        
        $fSim.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        $btnSim.Enabled = $false; $btnStopSim.Enabled = $true # เปิดปุ่ม Stop
        $script:SimStopRequested = $false # Reset Flag
        
        Log "----------------------------------------" "DimGray"
        Log "[Action] Initializing Simulation ($budget Pulls)..." "Cyan"
        [System.Windows.Forms.Application]::DoEvents()
        
        # Call Engine (Pass ref Flag)
        $res = Invoke-GachaSimulation -SimCount 100000 `
                                      -MyPulls $budget `
                                      -StartPity ([int]$txtPity.Text) `
                                      -IsGuaranteed ($chkG.Checked) `
                                      -HardPityCap $hardCap `
                                      -SoftPityStart $softCap `
                                      -StopFlag ([ref]$script:SimStopRequested) `
                                      -ProgressCallback { 
                                          param($r)
                                          $pct=($r/100000)*100
                                          $btnSim.Text="Running... $pct%"
                                          Log "[Forecast] Simulating: $pct%" "Gray"
                                          [System.Windows.Forms.Application]::DoEvents()
                                      }
        
        # Check if Cancelled
        if ($res.IsCancelled) {
             Log "[Forecast] Process Aborted." "Red"
             $lblChance.Text = "Cancelled"
             $lblCost.Text = "-"
             $pbFill.Width = 0
             $btnSim.Text = "RUN SIMULATION"
             $btnSim.Enabled = $true
             $btnStopSim.Enabled = $false
             $fSim.Cursor = "Default"
             return
        }

        # Update UI Results (Normal)
        $winRate = "{0:N1}" -f $res.WinRate
        $lblChance.Text = "Success Chance: $winRate%"
        $lblCost.Text = "Avg. Cost: ~$('{0:N0}' -f $res.AvgCost) pulls"
        
        Log "[Forecast] COMPLETE! WinRate=$winRate%, AvgCost=$('{0:N0}' -f $res.AvgCost)" "Lime"
        
        if ($res.WinRate -ge 80) { $lblChance.ForeColor="Lime"; $pbFill.BackColor="Lime" }
        elseif ($res.WinRate -ge 50) { $lblChance.ForeColor="Gold"; $pbFill.BackColor="Gold" }
        else { $lblChance.ForeColor="Crimson"; $pbFill.BackColor="Crimson" }
        $pbFill.Width = [int](320 * ($res.WinRate / 100))

        # --- UPDATE CHART ---
        $chartSim.Series.Clear(); 
        $caSim.AxisX.StripLines.Clear(); 
        $chartSim.Legends.Clear()
        $caSim.AxisX.Minimum = 0; 
        if ($budget -gt 100) { 
            $caSim.AxisX.Maximum = $NaN 
        } 
        else 
        { 
            $caSim.AxisX.Maximum = 100 
        }

        $leg = New-Object System.Windows.Forms.DataVisualization.Charting.Legend; $leg.Name="Legend1"; $leg.Docking="Bottom"; $leg.Alignment="Center"; $leg.BackColor="Transparent"; $leg.ForeColor="Silver"; $chartSim.Legends.Add($leg)

        if ($null -ne $res.Distribution -and $res.Distribution.Count -gt 0) {
            $s = New-Object System.Windows.Forms.DataVisualization.Charting.Series; $s.Name="Simulation"; $s.ChartType="Column"; $s.IsVisibleInLegend=$false; $s["PixelPointWidth"]="40"
            $startP = [int]$txtPity.Text
            $keys = $res.Distribution.Keys | Sort-Object { [int]$_ }
            foreach ($k in $keys) {
                $val = $res.Distribution[$k]
                if ($val -gt 0) {
                    $ptIdx = $s.Points.AddXY([int]$k, [int]$val)
                    $pt = $s.Points[$ptIdx]
                    $totalPityReached = $startP + $k
                    if ($totalPityReached -lt 74) { $pt.Color = "LimeGreen" } elseif ($totalPityReached -le 85) { $pt.Color = "Gold" } else { $pt.Color = "Crimson" }
                    $pct = "{0:N2}" -f (($val / 100000) * 100)
                    $pt.ToolTip = "Used: ~$k Pulls (Total Pity: $totalPityReached)`nChance: $pct%"
                }
            }
            $chartSim.Series.Add($s)

            function Add-LegendItem($name, $color) { $dum=New-Object System.Windows.Forms.DataVisualization.Charting.Series; $dum.Name=$name; $dum.Color=$color; $dum.ChartType="Column"; $chartSim.Series.Add($dum); [void]$dum.Points.AddXY(-1000,0) }
            Add-LegendItem "Lucky (<74)" "LimeGreen"; Add-LegendItem "Soft Pity (74-85)" "Gold"; Add-LegendItem "Hard Pity (>85)" "Crimson"

            $markerSoft = 74 - $startP; $markerHard = 90 - $startP
            if ($markerSoft -gt 0) { $slSoft = New-Object System.Windows.Forms.DataVisualization.Charting.StripLine; $slSoft.IntervalOffset=$markerSoft; $slSoft.StripWidth=0.5; $slSoft.BackColor="Gold"; $slSoft.BorderDashStyle="Dash"; $slSoft.Text="Soft Pity Start"; $slSoft.TextOrientation="Rotated270"; $slSoft.TextAlignment="Far"; $slSoft.ForeColor="Gold"; $caSim.AxisX.StripLines.Add($slSoft) }
            if ($markerHard -gt 0) { $slHard = New-Object System.Windows.Forms.DataVisualization.Charting.StripLine; $slHard.IntervalOffset=$markerHard; $slHard.StripWidth=0.5; $slHard.BackColor="Red"; $slHard.Text="Hard Pity (90)"; $slHard.TextOrientation="Rotated270"; $slHard.TextAlignment="Far"; $slHard.ForeColor="Red"; $caSim.AxisX.StripLines.Add($slHard) }
            $chartSim.Update()
        }

        $fSim.Cursor="Default"; $btnSim.Enabled=$true; $btnSim.Text="RUN SIMULATION"; $btnStopSim.Enabled=$false
    })

    $fSim.ShowDialog() | Out-Null
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
    
    # เรียก Helper ล้างหน้าจอ
    Reset-LogWindow

    # 1. เช็คว่าเปิด Filter ไหม?
    if ($chkFilterEnable.Checked) {
        $startDate = $dtpStart.Value.Date
        $endDate = $dtpEnd.Value.Date.AddDays(1).AddSeconds(-1) 

        $script:FilteredData = $script:LastFetchedData | Where-Object { 
            [DateTime]$_.time -ge $startDate -and [DateTime]$_.time -le $endDate 
        }
        Log "--- FILTERED VIEW ($($startDate.ToString('yyyy-MM-dd')) to $($endDate.ToString('yyyy-MM-dd'))) ---" "Cyan"
    } else {
        $script:FilteredData = $script:LastFetchedData
        Log "--- FULL HISTORY VIEW ---" "Cyan"
    }

    # 2. คำนวณ Stats พื้นฐาน
    $totalPulls = $script:FilteredData.Count
    $lblStat1.Text = "Total Pulls: $totalPulls"
    
    $cost = $totalPulls * 160
    $currencyName = if ($script:CurrentGame -eq "HSR") { "Jades" } elseif ($script:CurrentGame -eq "ZZZ") { "Polychromes" } else { "Primos" }
    $script:lblStatCost.Text = "Est. Cost: $(" {0:N0}" -f $cost) $currencyName"

    # 3. เตรียมคำนวณ Pity
    $sortedItems = $script:FilteredData | Sort-Object { [decimal]$_.id } 
    
    $pityTrackers = @{} 
    foreach ($b in $conf.Banners) { $pityTrackers[$b.Code] = 0 }

    # [Logic: True Pity Offset] 
    if ($chkFilterEnable.Checked -and $radModeAbs.Checked) {
        if ($sortedItems.Count -gt 0) {
            $firstItemInScope = $sortedItems[0]
            $allHistorySorted = $script:LastFetchedData | Sort-Object { [decimal]$_.id }
            
            foreach ($item in $allHistorySorted) {
                if ($item.id -eq $firstItemInScope.id) { break }
                $code = [string]$item.gacha_type
                if ($script:CurrentGame -eq "Genshin" -and $code -eq "400") { $code = "301" }
                if (-not $pityTrackers.ContainsKey($code)) { $pityTrackers[$code] = 0 }

                $pityTrackers[$code]++
                if ($item.rank_type -eq $conf.SRank) { $pityTrackers[$code] = 0 }
            }
        }
    }

    # 4. Loop ข้อมูลใน Scope
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
            
            $displayList += [PSCustomObject]@{
                Time = $item.time
                Name = $item.name
                Banner = $item._BannerName
                Pity = $pityTrackers[$code]
            }
            $pityTrackers[$code] = 0 
        }
    }

    # 5. [EDITED] อัปเดต UI Avg Pity และ Luck Grade
    if ($highRankCount -gt 0) {
        $avg = $pitySum / $highRankCount
        $script:lblStatAvg.Text = "Avg. Pity: $(" {0:N2}" -f $avg)"
        
        # สี Avg Pity
        if ($avg -le 55) { $script:lblStatAvg.ForeColor = "Lime" }
        elseif ($avg -le 73) { $script:lblStatAvg.ForeColor = "Gold" }
        else { $script:lblStatAvg.ForeColor = "OrangeRed" }

        # --- [NEW] คำนวณ Grade ---
        $grade = ""
        $gColor = "White"

        if ($avg -lt 50)     { $grade = "SS"; $gColor = "Cyan" }
        elseif ($avg -le 60) { $grade = "A";  $gColor = "Lime" }
        elseif ($avg -le 73) { $grade = "B";  $gColor = "Gold" }
        elseif ($avg -le 76) { $grade = "C";  $gColor = "Orange" }
        else                 { $grade = "F";  $gColor = "Red" }
        
        $script:lblLuckGrade.Text = "Grade: $grade"
        $script:lblLuckGrade.ForeColor = $gColor
        # -------------------------

    } else {
        $script:lblStatAvg.Text = "Avg. Pity: -"
        $script:lblStatAvg.ForeColor = "White"
        
        # Reset Grade
        $script:lblLuckGrade.Text = "Grade: -"
        $script:lblLuckGrade.ForeColor = "DimGray"
    }

    # 6. แสดงผลลง Log Window
    if ($displayList.Count -gt 0) {
        
        # Helper: Print บรรทัดเดียว พร้อมเช็ค Win/Loss
        function Print-Line($h, $idx) {
            $pColor = "Lime"
            if ($h.Pity -gt 75) { $pColor = "Red" } elseif ($h.Pity -gt 50) { $pColor = "Yellow" }
            
            # Logic เช็คสีชื่อ (แดง = หลุดเรท)
            $nameColor = "Gold"
            $isStandardChar = $false
            switch ($script:CurrentGame) {
                "Genshin" { if ($h.Name -match "^(Diluc|Jean|Mona|Qiqi|Keqing|Tighnari|Dehya)$") { $isStandardChar = $true } }
                "HSR"     { if ($h.Name -match "^(Himeko|Welt|Bronya|Gepard|Clara|Yanqing|Bailu)$") { $isStandardChar = $true } }
                "ZZZ"     { if ($h.Name -match "^(Grace|Rina|Koleda|Nekomata|Soldier 11|Lycaon)$") { $isStandardChar = $true } }
            }
            $isNotEventBanner = ($h.Banner -match "Standard|Novice|Weapon|Light Cone|W-Engine|Bangboo")
            
            if ($isStandardChar -and (-not $isNotEventBanner)) {
                $nameColor = "Crimson" 
            }

            $prefix = if ($chkShowNo.Checked) { "[No.$idx] ".PadRight(12) } else { "[$($h.Time)] " }
            
            $txtLog.SelectionColor = "Gray"; $txtLog.AppendText($prefix)
            $txtLog.SelectionColor = $nameColor; $txtLog.AppendText("$($h.Name.PadRight(18)) ")
            $txtLog.SelectionColor = $pColor; $txtLog.AppendText("Pity: $($h.Pity)`n")
        }

        $chartData = @()

        if ($chkSortDesc.Checked) {
            # Newest First
            for ($i = $displayList.Count - 1; $i -ge 0; $i--) {
                Print-Line -h $displayList[$i] -idx ($i+1)
                $chartData += $displayList[$i]
            }
        } else {
            # Oldest First
            for ($i = 0; $i -lt $displayList.Count; $i++) {
                Print-Line -h $displayList[$i] -idx ($i+1)
                $chartData += $displayList[$i]
            }
        }
        
        Update-Chart -DataList $chartData

    } else {
        Log "No 5-Star items found in this range." "Gray"
        Update-Chart -DataList @()
    }
}

# ตัวแปร Global (ประกาศไว้นอกฟังก์ชันเพื่อให้แน่ใจว่ามีอยู่จริง)
$script:CurrentChartData = @()

function Update-Chart {
    param($DataList)

    # 0. Caching Data
    if ($null -ne $DataList) { $script:CurrentChartData = $DataList }
    else { $DataList = $script:CurrentChartData }

    # 1. Clear กราฟเก่า
    $chart.Series.Clear()
    $chart.Titles.Clear()
    $chart.Legends.Clear() # [สำคัญ] ลบ Legend เก่าทิ้งด้วย
    
    $typeStr = $cmbChartType.SelectedItem
    if ($null -eq $typeStr) { $typeStr = "Column" }

    # ==================================================
    # CASE A: RATE ANALYSIS (Doughnut Chart) - PRO DESIGN
    # ==================================================
    if ($typeStr -eq "Rate Analysis") {
        $chart.Visible = $true; $lblNoData.Visible = $false

        $sourceData = $script:FilteredData
        if ($null -eq $sourceData -or $sourceData.Count -eq 0) { return }

        $conf = Get-GameConfig $script:CurrentGame
        $count5 = ($sourceData | Where-Object { $_.rank_type -eq $conf.SRank }).Count
        $count4 = ($sourceData | Where-Object { $_.rank_type -eq "4" }).Count
        $count3 = $sourceData.Count - $count5 - $count4

        $series = New-Object System.Windows.Forms.DataVisualization.Charting.Series
        $series.Name = "Rates"
        $series.ChartType = "Doughnut" # <--- เปลี่ยนเป็นโดนัท ดูแพงกว่า
        $series.IsValueShownAsLabel = $true
        
        # ตั้งค่าโดนัท
        $series["DoughnutRadius"] = "60" # ความหนาของวง
        $series["PieLabelStyle"] = "Outside" # ให้ป้ายชื่ออยู่ข้างนอก มีเส้นชี้ (ดู Pro)
        $series["PieLineColor"] = "Gray"     # สีเส้นชี้
        
        # --- Data Points ---
        # Label บนกราฟ: #VALY (แสดงแค่จำนวนตัวเลข)
        # Legend: ชื่อ - #VALY (#PERCENT{P2}) (แสดงครบ)

        # 1. 5-Star (Gold)
        $dp5 = New-Object System.Windows.Forms.DataVisualization.Charting.DataPoint(0, $count5)
        $dp5.Label = "#VALY" 
        $dp5.LegendText = "5-Star :  #VALY  (#PERCENT{P2})" 
        $dp5.Color = "Gold"
        $dp5.LabelForeColor = "Gold" # ตัวเลขสีทองตามสีแท่ง
        $dp5.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $series.Points.Add($dp5)

        # 2. 4-Star (Purple)
        $dp4 = New-Object System.Windows.Forms.DataVisualization.Charting.DataPoint(0, $count4)
        $dp4.Label = "#VALY"
        $dp4.LegendText = "4-Star :  #VALY  (#PERCENT{P2})"
        $dp4.Color = "MediumPurple"
        $dp4.LabelForeColor = "MediumPurple"
        $dp4.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $series.Points.Add($dp4)

        # 3. 3-Star (Blue)
        $dp3 = New-Object System.Windows.Forms.DataVisualization.Charting.DataPoint(0, $count3)
        $dp3.Label = "#VALY"
        $dp3.LegendText = "3-Star :  #VALY  (#PERCENT{P2})"
        $dp3.Color = "DodgerBlue"
        $dp3.LabelForeColor = "DodgerBlue"
        $dp3.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $series.Points.Add($dp3)

        $chart.Series.Add($series)

        # Legend Styling (สำคัญมากสำหรับความ Pro)
        $leg = New-Object System.Windows.Forms.DataVisualization.Charting.Legend
        $leg.Name = "MainLegend"
        $leg.Docking = "Bottom"
        $leg.Alignment = "Center"
        $leg.BackColor = "Transparent"
        $leg.ForeColor = "Silver"
        $leg.Font = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Regular) # ใช้ Font monospace เพื่อให้ตัวเลขตรงกัน
        $chart.Legends.Add($leg)

        # Title
        $t = New-Object System.Windows.Forms.DataVisualization.Charting.Title
        $t.Text = "Drop Rate Analysis (Total: $($sourceData.Count))"
        $t.ForeColor = "Silver"
        $t.Font = $script:fontHeader
        $t.Alignment = "TopLeft"
        $chart.Titles.Add($t)

        $chart.ChartAreas[0].AxisX.Enabled = "False"
        $chart.ChartAreas[0].AxisY.Enabled = "False"
        $chart.ChartAreas[0].BackColor = "Transparent"
        $chart.Update()
        return 
    }


    # ==================================================
    # CASE B: PITY HISTORY (Normal Graph)
    # ==================================================
    if ($null -eq $DataList -or $DataList.Count -eq 0) {
        $chart.Visible = $false; $lblNoData.Visible = $true; return
    }

    $chart.Visible = $true; $lblNoData.Visible = $false
    $chart.ChartAreas[0].AxisX.Enabled = "True"
    $chart.ChartAreas[0].AxisY.Enabled = "True"
    $chart.ChartAreas[0].AxisY.Title = "Pity Count"

    # Title (ย้ายไปซ้ายบน เช่นกัน)
    $t = New-Object System.Windows.Forms.DataVisualization.Charting.Title
    $t.Text = "5-Star Pity History"
    $t.ForeColor = "Gold"
    $t.Font = $script:fontHeader
    $t.Alignment = "TopLeft" # <--- ชิดซ้ายบน
    $chart.Titles.Add($t)

    $series = New-Object System.Windows.Forms.DataVisualization.Charting.Series
    $series.Name = "Pity"
    $series.ChartType = $typeStr
    $series.IsValueShownAsLabel = $true 
    $series.LabelForeColor = "White"
    
    if ($typeStr -match "Line|Spline") {
        $series.BorderWidth = 3
        $series.MarkerStyle = "Circle"; $series.MarkerSize = 8
    } else { $series["PixelPointWidth"] = "30" }

    $idx = 1
    foreach ($item in $DataList) {
        $label = if ($chkShowNo.Checked) { "$($item.Name)`n(#$idx)" } else { "$($item.Name)`n($([DateTime]::Parse($item.Time).ToString("dd/MM")))" }
        
        $ptIndex = $series.Points.AddXY($label, $item.Pity)
        $pt = $series.Points[$ptIndex]
        $pt.ToolTip = "Name: $($item.Name)`nDate: $($item.Time)`nPity: $($item.Pity)`nBanner: $($item.Banner)"

        if ($typeStr -eq "Column" -or $typeStr -eq "Bar") {
            $pt.BackGradientStyle = "TopBottom"
            if ($item.Pity -gt 75) { $pt.Color = "Crimson"; $pt.BackSecondaryColor = "Maroon" } 
            elseif ($item.Pity -gt 50) { $pt.Color = "Gold"; $pt.BackSecondaryColor = "DarkGoldenrod" } 
            else { $pt.Color = "LimeGreen"; $pt.BackSecondaryColor = "DarkGreen" }
        } else {
            $series.Color = "White"
            if ($item.Pity -gt 75) { $pt.MarkerColor = "Red" } 
            elseif ($item.Pity -gt 50) { $pt.MarkerColor = "Gold" } 
            else { $pt.MarkerColor = "LimeGreen" }
        }
        $idx++
    }
    $chart.Series.Add($series)
    $chart.ChartAreas[0].AxisX.Interval = 1
    if ($typeStr -eq "Bar") { $chart.ChartAreas[0].AxisY.Title = "Pity Count" }
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