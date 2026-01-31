# =============================================================================
# FILE: SettingChild\02_TabAppearance.ps1
# DESCRIPTION: แก้ไขโดยยัด Logic เข้า Event โดยตรง (เลียนแบบ TabGeneral)
# =============================================================================

$script:tApp = New-Tab "Appearance"

# -----------------------------------------------------------
# Section 1: Theme Presets
# -----------------------------------------------------------
$lblPreset = New-Object System.Windows.Forms.Label
$lblPreset.Text = "Theme Presets:"
$lblPreset.Location = "20, 20"
$lblPreset.AutoSize = $true
$lblPreset.ForeColor = "Silver"
$script:tApp.Controls.Add($lblPreset)

$script:cmbPresets = New-Object System.Windows.Forms.ComboBox
$script:cmbPresets.Location = "150, 18"
$script:cmbPresets.Width = 200
$script:cmbPresets.DropDownStyle = "DropDownList"
$script:cmbPresets.BackColor = [System.Drawing.Color]::FromArgb(50,50,50)
$script:cmbPresets.ForeColor = "White"
$script:cmbPresets.FlatStyle = "Flat"
$script:tApp.Controls.Add($script:cmbPresets)

$ThemeList = @{ 
    "Cyber Cyan"   = "#00FFFF"
    "Genshin Gold" = "#FFD700"
    "HSR Purple"   = "#9370DB"
    "ZZZ Orange"   = "#FF4500"
    "Dendro Green" = "#32CD32"
    "Cryo Blue"    = "#00BFFF"
    "Pyro Red"     = "#DC143C"
    "Monochrome"   = "#A9A9A9" 
}
foreach ($key in $ThemeList.Keys) { [void]$script:cmbPresets.Items.Add($key) }

# Check Config
$foundMatch = $false
foreach ($key in $ThemeList.Keys) { 
    if ($ThemeList[$key] -eq $conf.AccentColor) { 
        $script:cmbPresets.SelectedItem = $key
        $foundMatch = $true; break 
    } 
}
if (-not $foundMatch) { $script:cmbPresets.Text = "Custom User Color" }

# -----------------------------------------------------------
# Section 2: Color Preview & Picker
# -----------------------------------------------------------
# สร้าง Panel Preview
$script:pnlColorPreview = New-Object System.Windows.Forms.Panel
$script:pnlColorPreview.Location = "150, 58"
$script:pnlColorPreview.Size = "30, 20"
$script:pnlColorPreview.BorderStyle = "FixedSingle"
try { $startColor = [System.Drawing.ColorTranslator]::FromHtml($conf.AccentColor) } catch { $startColor = [System.Drawing.Color]::Cyan }
$script:pnlColorPreview.BackColor = $startColor
$script:tApp.Controls.Add($script:pnlColorPreview)

# ปุ่ม Pick Color
$btnPickColor = New-Object System.Windows.Forms.Button
$btnPickColor.Text = "Pick Color..."
$btnPickColor.Location = "190, 55"
$btnPickColor.Size = "100, 28"
Apply-ButtonStyle -Button $btnPickColor -BaseColorName "DimGray" -HoverColorName "Gray" -CustomFont $script:fontNormal
$script:tApp.Controls.Add($btnPickColor)

# -----------------------------------------------------------
# Section 3: Mock Preview
# -----------------------------------------------------------
$grpPreview = New-Object System.Windows.Forms.GroupBox
$grpPreview.Text = " Preview "
$grpPreview.Location = "20, 100"
$grpPreview.Size = "480, 150"
$grpPreview.ForeColor = "Silver"
$script:tApp.Controls.Add($grpPreview)

$script:lblMockMenu = New-Object System.Windows.Forms.Label
$script:lblMockMenu.Text = ">> Show Graph"
$script:lblMockMenu.Location = "350, 25"
$script:lblMockMenu.AutoSize = $true
$script:lblMockMenu.Font = $script:fontBold
$script:lblMockMenu.ForeColor = $startColor
$grpPreview.Controls.Add($script:lblMockMenu)

$script:txtMock = New-Object System.Windows.Forms.TextBox
$script:txtMock.Text = "C:\GameData\..."
$script:txtMock.Location = "20, 55"
$script:txtMock.Width = 250
$script:txtMock.BackColor = [System.Drawing.Color]::FromArgb(45,45,45)
$script:txtMock.BorderStyle = "FixedSingle"
$script:txtMock.ForeColor = $startColor
$grpPreview.Controls.Add($script:txtMock)

# -----------------------------------------------------------
# Section 4: Opacity
# -----------------------------------------------------------
$lblOp = New-Object System.Windows.Forms.Label
$lblOp.Text = "Window Opacity:"
$lblOp.Location = "20, 270"
$lblOp.AutoSize = $true
$script:tApp.Controls.Add($lblOp)

$script:trackOp = New-Object System.Windows.Forms.TrackBar
$script:trackOp.Location = "20, 295"
$script:trackOp.Width = 300
$script:trackOp.Minimum = 50
$script:trackOp.Maximum = 100
$script:trackOp.Value = [int]($conf.Opacity * 100)
$script:trackOp.TickStyle = "None"
$script:tApp.Controls.Add($script:trackOp)

$script:trackOp.Add_Scroll({ 
    if ($script:form) { $script:form.Opacity = ($script:trackOp.Value / 100) }
    $lblOp.Text = "Window Opacity: $($script:trackOp.Value)%" 
})

# -----------------------------------------------------------
# Section 5: Logic & Events (แก้ไขใหม่: ยัด Logic ใส่ Event ตรงๆ)
# -----------------------------------------------------------

# กำหนดค่าเริ่มต้นให้ตัวแปร Global (สำคัญมาก! ไม่งั้นกด Save จะได้ค่าว่าง)
$script:TempHexColor = $conf.AccentColor

# EVENT 1: Dropdown Selection
$script:cmbPresets.Add_SelectedIndexChanged({ 
    if ($script:cmbPresets.SelectedItem -and $ThemeList.ContainsKey($script:cmbPresets.SelectedItem)) {
        # 1. Get Color
        $c = [System.Drawing.ColorTranslator]::FromHtml($ThemeList[$script:cmbPresets.SelectedItem])
        
        # 2. Update UI Directly
        $script:pnlColorPreview.BackColor = $c
        $script:txtMock.ForeColor = $c
        $script:lblMockMenu.ForeColor = $c
        
        # 3. Update Global Variable for Saving
        $script:TempHexColor = "#{0:X2}{1:X2}{2:X2}" -f $c.R, $c.G, $c.B
    } 
})

# EVENT 2: Button Pick Color
$btnPickColor.Add_Click({ 
    $cd = New-Object System.Windows.Forms.ColorDialog
    if ($cd.ShowDialog() -eq "OK") {
        $c = $cd.Color
        
        # 1. Update UI Directly
        $script:pnlColorPreview.BackColor = $c
        $script:txtMock.ForeColor = $c
        $script:lblMockMenu.ForeColor = $c
        
        # 2. Update Global Variable for Saving
        $script:TempHexColor = "#{0:X2}{1:X2}{2:X2}" -f $c.R, $c.G, $c.B
        
        # 3. Reset Dropdown Text
        $script:cmbPresets.SelectedIndex = -1
        $script:cmbPresets.Text = "Custom"
    } 
})