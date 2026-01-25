# =============================================================================
# FILE: SettingChild\01_TabGeneral.ps1
# DESCRIPTION: สร้าง Tab General, ตั้งค่า Storage (Backup) และ System Settings
# DEPENDENCIES: 
#   - Function: New-Tab, Apply-ButtonStyle
#   - Variable: $conf (Config Object), $script:fontNormal
# =============================================================================

# สร้าง Tab General
$script:tGen = New-Tab "General"

# -----------------------------------------------------------
# GroupBox: Storage
# -----------------------------------------------------------
$grpStorage = New-Object System.Windows.Forms.GroupBox
$grpStorage.Text = " Storage "
$grpStorage.Location = "15, 15"
$grpStorage.Size = "505, 160"
$grpStorage.ForeColor = "Silver"
$script:tGen.Controls.Add($grpStorage)

# [Checkbox] เปิด/ปิด Auto-Backup
$script:chkEnableBk = New-Object System.Windows.Forms.CheckBox
$script:chkEnableBk.Text = "Enable Auto-Backup System"
$script:chkEnableBk.Location = "20, 25"
$script:chkEnableBk.AutoSize = $true
$script:chkEnableBk.ForeColor = "LimeGreen"

# Logic: ถ้าไม่มีคีย์นี้ใน Config ให้ถือว่าเป็น True ไว้ก่อน
$script:chkEnableBk.Checked = if ($conf.PSObject.Properties["EnableAutoBackup"] -and $conf.EnableAutoBackup -eq $false) { $false } else { $true }

# Event: กดปิดแล้วช่อง Path สีเทา
$script:chkEnableBk.Add_CheckedChanged({ 
    $script:txtBackup.Enabled   = $script:chkEnableBk.Checked
    $script:btnBrowseBk.Enabled = $script:chkEnableBk.Checked 
})
$grpStorage.Controls.Add($script:chkEnableBk)

# [Label] Backup Path
$lblBk = New-Object System.Windows.Forms.Label
$lblBk.Text = "Backup Folder Path:"
$lblBk.Location = "20, 55"
$lblBk.AutoSize = $true
$lblBk.ForeColor = "White"
$grpStorage.Controls.Add($lblBk)

# [TextBox] Backup Path
$script:txtBackup = New-Object System.Windows.Forms.TextBox
$script:txtBackup.Location = "20, 80"
$script:txtBackup.Width = 380
$script:txtBackup.BackColor = [System.Drawing.Color]::FromArgb(60,60,60)
$script:txtBackup.ForeColor = "Cyan"
$script:txtBackup.BorderStyle = "FixedSingle"
$script:txtBackup.Text = $conf.BackupPath
$script:txtBackup.Enabled = $script:chkEnableBk.Checked # Disable ถ้า Checkbox ไม่ได้ติ๊ก
$grpStorage.Controls.Add($script:txtBackup)

# [Button] Browse
$script:btnBrowseBk = New-Object System.Windows.Forms.Button
$script:btnBrowseBk.Text = "..."
$script:btnBrowseBk.Location = "410, 79"
$script:btnBrowseBk.Size = "75, 25"
$script:btnBrowseBk.Enabled = $script:chkEnableBk.Checked
Apply-ButtonStyle -Button $script:btnBrowseBk -BaseColorName "DimGray" -HoverColorName "Gray" -CustomFont $script:fontNormal

$script:btnBrowseBk.Add_Click({ 
    $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
    if ($fbd.ShowDialog() -eq "OK") { 
        $script:txtBackup.Text = $fbd.SelectedPath 
    } 
})
$grpStorage.Controls.Add($script:btnBrowseBk)

# [Combobox] CSV Separator
$lblCsv = New-Object System.Windows.Forms.Label
$lblCsv.Text = "CSV Separator:"
$lblCsv.Location = "20, 115"
$lblCsv.AutoSize = $true
$lblCsv.ForeColor = "White"
$grpStorage.Controls.Add($lblCsv)

$script:cmbCsvSep = New-Object System.Windows.Forms.ComboBox
$script:cmbCsvSep.Location = "130, 112"
$script:cmbCsvSep.Width = 100
$script:cmbCsvSep.DropDownStyle = "DropDownList"
$script:cmbCsvSep.BackColor = [System.Drawing.Color]::FromArgb(60,60,60)
$script:cmbCsvSep.ForeColor = "White"
$script:cmbCsvSep.FlatStyle = "Flat"
[void]$script:cmbCsvSep.Items.Add("Comma (,)")
[void]$script:cmbCsvSep.Items.Add("Semicolon (;)")

if ($conf.CsvSeparator -eq ";") { 
    $script:cmbCsvSep.SelectedIndex = 1 
} else { 
    $script:cmbCsvSep.SelectedIndex = 0 
}
$grpStorage.Controls.Add($script:cmbCsvSep)

# -----------------------------------------------------------
# GroupBox: System
# -----------------------------------------------------------
$grpSys = New-Object System.Windows.Forms.GroupBox
$grpSys.Text = " System "
$grpSys.Location = "15, 190"
$grpSys.Size = "505, 120"
$grpSys.ForeColor = "Silver"
$script:tGen.Controls.Add($grpSys)

# [Checkbox] Debug Console
$script:chkDebug = New-Object System.Windows.Forms.CheckBox
$script:chkDebug.Text = "Enable Debug Console"
$script:chkDebug.Location = "20, 30"
$script:chkDebug.AutoSize = $true
$script:chkDebug.Checked = $conf.DebugConsole
$script:chkDebug.ForeColor = "White"
$grpSys.Controls.Add($script:chkDebug)

# [Checkbox] System Logging
$script:chkFileLog = New-Object System.Windows.Forms.CheckBox
$script:chkFileLog.Text = "Enable System Logging"
$script:chkFileLog.Location = "20, 70"
$script:chkFileLog.AutoSize = $true
$script:chkFileLog.Checked = $conf.EnableFileLog
$script:chkFileLog.ForeColor = "White"
$grpSys.Controls.Add($script:chkFileLog)

# [Checkbox] Sound Effects
$script:chkSound = New-Object System.Windows.Forms.CheckBox
$script:chkSound.Text = "Enable Sound Effects"
$script:chkSound.Location = "20, 95"
$script:chkSound.AutoSize = $true
$script:chkSound.Checked = $conf.EnableSound
$script:chkSound.ForeColor = "White"
$grpSys.Controls.Add($script:chkSound)