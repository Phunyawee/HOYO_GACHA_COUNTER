# =============================================================================
# FILE: SettingChild\06_SettingsFooter.ps1
# DESCRIPTION: Footer Panel with Save (Apply), Cancel, Reset Buttons
# =============================================================================

# Fallback path check
if (-not $AppRoot) { $AppRoot = $PSScriptRoot }

# -----------------------------------------------------------
# [STEP 1] CREATE FOOTER CONTAINER
# สร้าง Panel ด้านล่างสุด (ต้องทำก่อนปุ่ม)
# -----------------------------------------------------------
$footerPnl = New-Object System.Windows.Forms.Panel
$footerPnl.Dock = "Bottom"
$footerPnl.Height = 60
$footerPnl.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30) # สีพื้นหลังเข้ม

# เพิ่ม Panel เข้าไปใน Form หลัก ($fSet)
$fSet.Controls.Add($footerPnl)

# *** สำคัญมาก: สั่งให้ Panel นี้ลอยอยู่บนสุดเสมอ เพื่อไม่ให้ TabControl บัง ***
$footerPnl.BringToFront()

# -----------------------------------------------------------
# [STEP 2] APPLY BUTTON (ปุ่ม Save - ขวาสุด)
# -----------------------------------------------------------
$btnSave = New-Object System.Windows.Forms.Button
$btnSave.Text = "APPLY SETTINGS"
# ตำแหน่ง: นับจากขอบซ้ายของ Panel
$btnSave.Location = "520, 10"  
$btnSave.Size = "160, 40"
$btnSave.Anchor = "Bottom, Right" # ยึดกับขอบขวาล่าง
$btnSave.DialogResult = [System.Windows.Forms.DialogResult]::None

# ใส่ Style สีเขียว
Apply-ButtonStyle -Button $btnSave -BaseColorName "ForestGreen" -HoverColorName "LimeGreen" -CustomFont $script:fontBold

$btnSave.Add_Click({
    # --- Helper Function: Set Value safely ---
    function Set-ConfVal($Name, $Val) {
        if (-not $conf.PSObject.Properties[$Name]) {
            $conf | Add-Member -NotePropertyName $Name -NotePropertyValue $Val
        } else {
            $conf.$Name = $Val
        }
    }

    # --- 1. Collect Values from UI ---
    Set-ConfVal "EnableAutoBackup"  $script:chkEnableBk.Checked
    Set-ConfVal "NotificationEmail" $script:txtEmail.Text
    Set-ConfVal "AutoSendEmail"     $script:chkAutoEmail.Checked
    
    # SMTP Settings
    Set-ConfVal "SmtpServer"        $script:txtSmtpHost.Text
    Set-ConfVal "SmtpPort"          ([int]$script:txtPort.Text)
    Set-ConfVal "SenderEmail"       $script:txtSender.Text
    Set-ConfVal "SenderPassword"    $script:txtPass.Text

    # Base Configs
    $conf.DebugConsole      = $script:chkDebug.Checked
    $conf.Opacity           = ($script:trackOp.Value / 100)
    $conf.BackupPath        = $script:txtBackup.Text
    $conf.WebhookUrl        = $script:txtWebhook.Text
    $conf.AutoSendDiscord   = $script:chkAutoSend.Checked
    $conf.EnableSound       = $script:chkSound.Checked
    $conf.EnableFileLog     = $script:chkFileLog.Checked
    $conf.AccentColor       = $script:TempHexColor
    
    if ($script:cmbCsvSep.SelectedIndex -eq 1) { 
        $conf.CsvSeparator = ";" 
    } else { 
        $conf.CsvSeparator = "," 
    }
    
    # --- 2. Save to File ---
    $setDir = Join-Path $AppRoot "Settings"
    if (-not (Test-Path $setDir)) { New-Item -Type Directory -Path $setDir -Force | Out-Null }
    
    $conf | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $setDir "config.json") -Encoding UTF8

    # --- 3. Reload System Variables (Live Update) ---
    $script:AppConfig = $conf
    Apply-Theme -NewHex $conf.AccentColor -NewOpacity $conf.Opacity
    $script:DebugMode = $conf.DebugConsole
    
    # Update Menu Color if exists
    if ($script:menuExpand) { 
        $script:menuExpand.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($conf.AccentColor) 
    }

    # --- SAVE EMAIL PREFS (ถ้ามี) ---
    if ($script:EmailStyleCmb) {
        $EmailData = @{
            Style         = $script:EmailStyleCmb.SelectedItem
            SubjectPrefix = $script:EmailSubjTxt.Text
            ContentType   = $script:EmailTypeCmb.SelectedItem
            ChartType     = $script:EmailChartCmb.SelectedItem 
            Updated       = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        }
        $EmailData | ConvertTo-Json | Set-Content -Path $script:EmailJsonPath -Encoding UTF8
    }
    
    [System.Windows.Forms.MessageBox]::Show("Configuration Saved Successfully!", "Done")
    # Reset Hint Label
    $lblHint.Text = "*Click APPLY to save"
    $lblHint.ForeColor = [System.Drawing.Color]::DimGray
})

$footerPnl.Controls.Add($btnSave)

# -----------------------------------------------------------
# [STEP 3] CANCEL BUTTON (ปุ่ม Cancel - ตรงกลางค่อนขวา)
# -----------------------------------------------------------
$btnCancel = New-Object System.Windows.Forms.Button
$btnCancel.Text = "Cancel"
$btnCancel.Location = "410, 15" # อยู่ทางซ้ายของปุ่ม Save
$btnCancel.Size = "100, 30"
$btnCancel.Anchor = "Bottom, Right"
$btnCancel.FlatStyle = "Flat"
$btnCancel.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
$btnCancel.ForeColor = "WhiteSmoke"
$btnCancel.FlatAppearance.BorderSize = 0

# Hover Effect for Cancel
$btnCancel.Add_MouseEnter({ $btnCancel.BackColor = [System.Drawing.Color]::FromArgb(80, 80, 80) })
$btnCancel.Add_MouseLeave({ $btnCancel.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60) })

$btnCancel.Add_Click({
    # ปิดหน้าต่าง Settings ทิ้ง (ไม่บันทึก)
    $fSet.Close()
})

$footerPnl.Controls.Add($btnCancel)

# -----------------------------------------------------------
# [STEP 4] RESET DEFAULTS BUTTON (ปุ่ม Reset - ซ้ายสุด)
# -----------------------------------------------------------
$btnReset = New-Object System.Windows.Forms.Button
$btnReset.Text = "Defaults"
$btnReset.Location = "20, 10" 
$btnReset.Size = "80,30"
$btnReset.Anchor = "Bottom, Left"
$btnReset.FlatStyle = "Flat"
$btnReset.ForeColor = "Gray"
$btnReset.FlatAppearance.BorderSize = 0

# Hint Label (ข้อความเตือนเล็กๆ)
$lblHint = New-Object System.Windows.Forms.Label
$lblHint.Text = "*Click APPLY to save"
$lblHint.Font = New-Object System.Drawing.Font("Segoe UI", 7, [System.Drawing.FontStyle]::Italic)
$lblHint.ForeColor = [System.Drawing.Color]::DimGray
$lblHint.AutoSize = $true
$lblHint.Location = "22, 42" # ใต้ปุ่ม Reset
$footerPnl.Controls.Add($lblHint)

$btnReset.Add_Click({
    $msgResult = [System.Windows.Forms.MessageBox]::Show(
        "Reset ALL settings to defaults?`n(UI will update but not save until you click APPLY)",
        "Confirm Reset",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )

    if ($msgResult -eq "Yes") {
        # --- 1. General Tab ---
        $script:chkDebug.Checked    = $false       
        $script:trackOp.Value       = 100          
        $script:cmbPresets.SelectedIndex = 0       
        $script:txtBackup.Text      = ""           
        $script:chkEnableBk.Checked = $true        
        $script:chkFileLog.Checked  = $true        
        $script:chkSound.Checked    = $false       
        if ($script:cmbCsvSep) { $script:cmbCsvSep.SelectedIndex = 0 }

        # --- 2. Integrations Tab ---
        $script:txtWebhook.Text     = ""           
        $script:chkAutoSend.Checked = $true        

        # --- 3. Notification / Email Tab ---
        $script:txtEmail.Text       = ""           
        $script:chkAutoEmail.Checked= $false       
        
        # SMTP Defaults
        $script:txtSmtpHost.Text    = "smtp.gmail.com"
        $script:txtPort.Text        = "587"
        $script:txtSender.Text      = ""
        $script:txtPass.Text        = ""
        
        # Optional Email Styles
        if ($script:EmailStyleCmb) { $script:EmailStyleCmb.SelectedIndex = 0 }
        if ($script:EmailTypeCmb)  { $script:EmailTypeCmb.SelectedIndex = 0 }
        if ($script:EmailChartCmb) { $script:EmailChartCmb.SelectedIndex = 0 }
        if ($script:EmailSubjTxt)  { $script:EmailSubjTxt.Text = "Gacha Report" }

        # Change Hint Label to Alert User
        $lblHint.ForeColor = [System.Drawing.Color]::Orange
        $lblHint.Text = "* Pending Save..."
        
        [System.Windows.Forms.MessageBox]::Show("Values reset. Please click APPLY to save.", "Reset Done")
    }
})

$footerPnl.Controls.Add($btnReset)

# -----------------------------------------------------------
# [STEP 5] TAB SWITCHING LOGIC (REFRESH JSON PREVIEW)
# -----------------------------------------------------------
$tabs.Add_SelectedIndexChanged({
    # Check if selected tab is "Advanced" (or whatever name you gave the JSON tab)
    if ($tabs.SelectedTab.Text -match "Advanced") {
        
        # Pull values from UI into $conf just for display
        $conf.BackupPath = $script:txtBackup.Text
        if (-not $conf.PSObject.Properties["EnableAutoBackup"]) { 
            $conf | Add-Member -NotePropertyName "EnableAutoBackup" -NotePropertyValue $script:chkEnableBk.Checked 
        } else { 
            $conf.EnableAutoBackup = $script:chkEnableBk.Checked 
        }
        
        if ($script:cmbCsvSep.SelectedIndex -eq 1) { $conf.CsvSeparator = ";" } else { $conf.CsvSeparator = "," }
        
        $conf.DebugConsole  = $script:chkDebug.Checked
        $conf.EnableFileLog = $script:chkFileLog.Checked
        $conf.EnableSound   = $script:chkSound.Checked
        $conf.AccentColor   = $script:TempHexColor
        $conf.Opacity       = ($script:trackOp.Value / 100)
        $conf.WebhookUrl    = $script:txtWebhook.Text
        $conf.AutoSendDiscord = $script:chkAutoSend.Checked
        
        # Helper for dynamic properties
        $SetProp = { param($n, $v) if (-not $conf.PSObject.Properties[$n]) { $conf | Add-Member -NotePropertyName $n -NotePropertyValue $v } else { $conf.$n = $v } }
        
        & $SetProp "NotificationEmail" $script:txtEmail.Text
        & $SetProp "AutoSendEmail"     $script:chkAutoEmail.Checked
        & $SetProp "SmtpServer"        $script:txtSmtpHost.Text
        & $SetProp "SmtpPort"          ([int]$script:txtPort.Text)
        & $SetProp "SenderEmail"       $script:txtSender.Text
        & $SetProp "SenderPassword"    $script:txtPass.Text

        # Update JSON Box
        $script:txtJson.Text = $conf | ConvertTo-Json -Depth 5
    }
})