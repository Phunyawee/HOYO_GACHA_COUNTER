# =============================================================================
# FILE: SettingChild\06_SettingsFooter.ps1
# DESCRIPTION: ปุ่ม Save หลัก, ปุ่ม Reset และ Event Listener สำหรับการสลับ Tab
# DEPENDENCIES: 
#   - Variable: $fSet (Settings Form), $conf, $AppRoot
#   - UI Controls from all tabs ($script:chkDebug, $script:txtEmail, etc.)
# =============================================================================

# Fallback
if (-not $AppRoot) { $AppRoot = $PSScriptRoot }

# -----------------------------------------------------------
# MAIN SAVE BUTTON
# -----------------------------------------------------------
$btnSave = New-Object System.Windows.Forms.Button
$btnSave.Text = "APPLY SETTINGS"
$btnSave.Location = "180, 500"
$btnSave.Size = "180, 40"
Apply-ButtonStyle -Button $btnSave -BaseColorName "ForestGreen" -HoverColorName "LimeGreen" -CustomFont $script:fontBold

$btnSave.Add_Click({
    # Helper Function: Set Value safely
    function Set-ConfVal($Name, $Val) {
        if (-not $conf.PSObject.Properties[$Name]) {
            $conf | Add-Member -NotePropertyName $Name -NotePropertyValue $Val
        } else {
            $conf.$Name = $Val
        }
    }

    # 1. Collect Values from UI (Using $script: variables from child files)
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
    
    # 2. Save to File
    $setDir = Join-Path $AppRoot "Settings"
    if (-not (Test-Path $setDir)) { New-Item -Type Directory -Path $setDir -Force | Out-Null }
    
    $conf | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $setDir "config.json") -Encoding UTF8

    # 3. Reload System Variables
    $script:AppConfig = $conf
    Apply-Theme -NewHex $conf.AccentColor -NewOpacity $conf.Opacity
    $script:DebugMode = $conf.DebugConsole
    
    # Update Menu Color if exists
    if ($script:menuExpand) { 
        $script:menuExpand.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($conf.AccentColor) 
    }
    
    [System.Windows.Forms.MessageBox]::Show("Configuration (including SMTP) Saved!", "Done")
    $fSet.Close()
})
$fSet.Controls.Add($btnSave)

# -----------------------------------------------------------
# RESET BUTTON
# -----------------------------------------------------------
$btnReset = New-Object System.Windows.Forms.Button
$btnReset.Text = "Defaults"
$btnReset.Location = "20,505"
$btnReset.Size = "80,30"
$btnReset.FlatStyle = "Flat"
$btnReset.ForeColor = "Gray"
$btnReset.FlatAppearance.BorderSize = 0

$btnReset.Add_Click({
    if ([System.Windows.Forms.MessageBox]::Show("Reset to defaults? UI will update but not save until you click APPLY.","Confirm",4) -eq "Yes") {
        $script:chkDebug.Checked = $false
        $script:trackOp.Value = 100
        $script:cmbPresets.SelectedIndex = 0
        [System.Windows.Forms.MessageBox]::Show("Reset done. Click APPLY to save.")
    }
})
$fSet.Controls.Add($btnReset)

# -----------------------------------------------------------
# LOGIC: AUTO REFRESH JSON (TAB SWITCHING)
# -----------------------------------------------------------
$tabs.Add_SelectedIndexChanged({
    # Check if selected tab is "Advanced"
    if ($tabs.SelectedTab.Text -match "Advanced") {
        
        # 1. General Tab
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

        # 2. Appearance Tab
        $conf.AccentColor = $script:TempHexColor
        $conf.Opacity     = ($script:trackOp.Value / 100)

        # 3. Integrations Tab
        $conf.WebhookUrl      = $script:txtWebhook.Text
        $conf.AutoSendDiscord = $script:chkAutoSend.Checked
        
        # Helper for dynamic properties
        $SetProp = { param($n, $v) if (-not $conf.PSObject.Properties[$n]) { $conf | Add-Member -NotePropertyName $n -NotePropertyValue $v } else { $conf.$n = $v } }
        
        & $SetProp "NotificationEmail" $script:txtEmail.Text
        & $SetProp "AutoSendEmail"     $script:chkAutoEmail.Checked
        & $SetProp "SmtpServer"        $script:txtSmtpHost.Text
        & $SetProp "SmtpPort"          ([int]$script:txtPort.Text)
        & $SetProp "SenderEmail"       $script:txtSender.Text
        & $SetProp "SenderPassword"    $script:txtPass.Text

        # 4. Update JSON Box
        $script:txtJson.Text = $conf | ConvertTo-Json -Depth 5
    }
})