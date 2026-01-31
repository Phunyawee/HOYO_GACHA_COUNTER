# =============================================================================
# FILE: SettingChild\04_TabDataMaintenance.ps1
# DESCRIPTION: หน้าจัดการข้อมูล, Backup/Restore Config และ Health Check
# DEPENDENCIES: 
#   - Function: New-Tab, Apply-ButtonStyle, Apply-Theme
#   - Variable: $AppRoot (หรือ $PSScriptRoot), $script:form, $script:CurrentGame
#   - UI Elements from other tabs (for Restore): $script:chkDebug, $script:txtBackup, etc.
# =============================================================================

# Fallback: ถ้า $AppRoot ยังไม่ได้ประกาศ ให้ใช้ $PSScriptRoot
if (-not $AppRoot) { $AppRoot = $PSScriptRoot }

$script:tData = New-Tab "Data & Storage"
$script:tData.AutoScroll = $true

# -----------------------------------------------------------
# Section 1: Backup & Restore Actions
# -----------------------------------------------------------

# [Button] Open Data Folder (ปุ่มเดิม: เปิด Root Folder)
$btnOpenFolder = New-Object System.Windows.Forms.Button
$btnOpenFolder.Text = "[ Open Data Folder ]"
$btnOpenFolder.Location = "20, 50"
$btnOpenFolder.Size = "250, 35"
Apply-ButtonStyle -Button $btnOpenFolder -BaseColorName "DimGray" -HoverColorName "Gray" -CustomFont $script:fontNormal
$btnOpenFolder.Add_Click({ Invoke-Item $AppRoot }) 
$script:tData.Controls.Add($btnOpenFolder)

# [NEW BUTTON] Open Backups Folder (ปุ่มใหม่: เปิด Backups)
$btnOpenBackupDir = New-Object System.Windows.Forms.Button
$btnOpenBackupDir.Text = "[ Open Backups ]"
$btnOpenBackupDir.Location = "280, 50"
$btnOpenBackupDir.Size = "180, 35"
Apply-ButtonStyle -Button $btnOpenBackupDir -BaseColorName "DimGray" -HoverColorName "Gray" -CustomFont $script:fontNormal

$btnOpenBackupDir.Add_Click({
    $backupPath = Join-Path $AppRoot "Backups"
    
    if (Test-Path $backupPath) {
        # ถ้ามีโฟลเดอร์ ให้เปิดเลย
        Invoke-Item $backupPath
    } else {
        # ถ้าไม่มี ให้แจ้งเตือน
        [System.Windows.Forms.MessageBox]::Show("Backups folder not found.`nPlease click 'Create Config Backup' first.", "Folder Missing", 0, 48) # 48 = Icon Warning
    }
})
$script:tData.Controls.Add($btnOpenBackupDir)


# [Button] Create Config Backup (เลื่อนตำแหน่ง Y ลงมานิดหน่อยเพื่อให้สวยงาม หรือไว้ที่เดิมก็ได้)
$btnForceBackup = New-Object System.Windows.Forms.Button
$btnForceBackup.Text = ">> Create Config Backup"
$btnForceBackup.Location = "20, 95"
$btnForceBackup.Size = "250, 35"
Apply-ButtonStyle -Button $btnForceBackup -BaseColorName "RoyalBlue" -HoverColorName "CornflowerBlue" -CustomFont $script:fontNormal

$btnForceBackup.Add_Click({
    $srcConfig = Join-Path $AppRoot "Settings\config.json"
    $backupDir = Join-Path $AppRoot "Backups"
    
    # สร้างโฟลเดอร์ถ้ายังไม่มี
    if (-not (Test-Path $backupDir)) { 
        New-Item -ItemType Directory -Path $backupDir | Out-Null 
    }
    
    if (Test-Path $srcConfig) {
        $destName = "config_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
        Copy-Item -Path $srcConfig -Destination (Join-Path $backupDir $destName)
        [System.Windows.Forms.MessageBox]::Show("Backup created in 'Backups' folder.", "Success", 0, 64)
    } else { 
        [System.Windows.Forms.MessageBox]::Show("Config not found in Settings.", "Error", 0, 48) 
    }
})
$script:tData.Controls.Add($btnForceBackup)

# [Button] Restore Config
$btnRestore = New-Object System.Windows.Forms.Button
$btnRestore.Text = "<< Restore Config"
$btnRestore.Location = "280, 95"
$btnRestore.Size = "180, 35"
Apply-ButtonStyle -Button $btnRestore -BaseColorName "DimGray" -HoverColorName "Gray" -CustomFont $script:fontNormal

$btnRestore.Add_Click({
    $backupDir = Join-Path $AppRoot "Backups"
    
    # เพิ่มการเช็คตรงนี้ด้วย (เผื่อคนกด Restore ก่อนเลย)
    if (-not (Test-Path $backupDir)) {
        [System.Windows.Forms.MessageBox]::Show("No backups found.`nPlease create a backup first.", "Warning", 0, 48)
        return
    }

    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = "JSON|*.json"
    $ofd.InitialDirectory = $backupDir
    
    if ($ofd.ShowDialog() -eq "OK") {
        try {
            # 1. อ่านไฟล์ Backup
            $jsonContent = Get-Content $ofd.FileName -Raw -Encoding UTF8
            $newConf = $jsonContent | ConvertFrom-Json
            
            if (-not $newConf.PSObject.Properties["AccentColor"]) { throw "Invalid Format" }
            
            # 2. บันทึกลงไฟล์จริง (Overwrite config.json)
            $configDir = Join-Path $AppRoot "Settings"
            if (-not (Test-Path $configDir)) { New-Item -ItemType Directory -Path $configDir -Force | Out-Null }
            Set-Content -Path (Join-Path $configDir "config.json") -Value $jsonContent -Encoding UTF8

            # 3. APPLY ค่าเข้าสู่ระบบทันที
            $script:AppConfig = $newConf
            
            # Update UI Elements
            $script:chkDebug.Checked     = $newConf.DebugConsole
            $script:trackOp.Value        = [int]($newConf.Opacity * 100)
            $script:txtBackup.Text       = $newConf.BackupPath
            if ($newConf.PSObject.Properties["EnableAutoBackup"]) { $script:chkEnableBk.Checked = $newConf.EnableAutoBackup }
            $script:chkFileLog.Checked   = $newConf.EnableFileLog
            $script:chkSound.Checked     = $newConf.EnableSound
            
            if ($newConf.CsvSeparator -eq ";") { 
                if ($script:cmbCsvSep) { $script:cmbCsvSep.SelectedIndex = 1 }
            } else { 
                if ($script:cmbCsvSep) { $script:cmbCsvSep.SelectedIndex = 0 }
            }

            $script:txtWebhook.Text      = $newConf.WebhookUrl
            $script:chkAutoSend.Checked  = $newConf.AutoSendDiscord

            if ($newConf.PSObject.Properties["NotificationEmail"]) { $script:txtEmail.Text = $newConf.NotificationEmail }
            if ($newConf.PSObject.Properties["AutoSendEmail"])     { $script:chkAutoEmail.Checked = $newConf.AutoSendEmail }
            if ($newConf.PSObject.Properties["SmtpServer"])        { $script:txtSmtpHost.Text = $newConf.SmtpServer }
            if ($newConf.PSObject.Properties["SmtpPort"])          { $script:txtPort.Text = [string]$newConf.SmtpPort }
            if ($newConf.PSObject.Properties["SenderEmail"])       { $script:txtSender.Text = $newConf.SenderEmail }
            if ($newConf.PSObject.Properties["SenderPassword"])    { $script:txtPass.Text = $newConf.SenderPassword }

            # 4. เรียกใช้ Function เปลี่ยนธีม
            Apply-Theme -NewHex $newConf.AccentColor -NewOpacity $newConf.Opacity
            $script:TempHexColor = $newConf.AccentColor

            [System.Windows.Forms.MessageBox]::Show("Configuration Restored & Applied Successfully!", "Success", 0, 64)

        } catch { 
            [System.Windows.Forms.MessageBox]::Show("Error: $($_.Exception.Message)", "Error", 0, 16) 
        }
    }
})
$script:tData.Controls.Add($btnRestore)


# -----------------------------------------------------------
# Section 2: Maintenance (Clear Cache)
# -----------------------------------------------------------
$grpDanger = New-Object System.Windows.Forms.GroupBox
$grpDanger.Text = " Maintenance "
$grpDanger.Location = "20, 160"
$grpDanger.Size = "440, 80"
$grpDanger.ForeColor = "IndianRed"
$script:tData.Controls.Add($grpDanger)

$btnClearCache = New-Object System.Windows.Forms.Button
$btnClearCache.Text = "Clear Cache"
$btnClearCache.Location = "20, 30"
$btnClearCache.Size = "180, 30"
$btnClearCache.BackColor = "Maroon"
$btnClearCache.ForeColor = "White"
$btnClearCache.FlatStyle = "Flat"
$btnClearCache.Add_Click({ 
    if ([System.Windows.Forms.MessageBox]::Show("Delete temp files?", "Confirm", 4, 32) -eq "Yes") {
        Remove-Item (Join-Path $AppRoot "temp_data_2") -Recurse -Force -ErrorAction SilentlyContinue
        [System.Windows.Forms.MessageBox]::Show("Cache Cleared.", "Done")
    }
})
$grpDanger.Controls.Add($btnClearCache)


# -----------------------------------------------------------
# Section 3: Health Check System
# -----------------------------------------------------------
$grpHealth = New-Object System.Windows.Forms.GroupBox
$grpHealth.Text = " System Status "
$grpHealth.Location = "20, 260"
$grpHealth.Size = "440, 100"
$grpHealth.ForeColor = "Silver"
$script:tData.Controls.Add($grpHealth)

# Helper: Add Header
function Add-Header($text, $x) { 
    $h = New-Object System.Windows.Forms.Label
    $h.Text = $text
    $h.Location = "$x, 25"
    $h.AutoSize = $true
    $h.ForeColor = "DimGray"
    $grpHealth.Controls.Add($h) 
}

Add-Header "COMPONENT" 20
Add-Header "FILENAME" 140
Add-Header "SIZE" 260
Add-Header "STATUS" 320

$script:HealthY = 50

# Helper: Add Row
function Add-HealthCheck {
    param($LabelText, $FilePath, $IsOptional=$false)
    
    $exists = Test-Path $FilePath
    if ($IsOptional -and (-not $exists)) { return }

    # 1. Label Component Name
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = $LabelText
    $lbl.Location = "20, $script:HealthY"
    $lbl.AutoSize = $true
    $lbl.ForeColor = "White"
    $grpHealth.Controls.Add($lbl)
    
    # 2. Filename
    $fname = Split-Path $FilePath -Leaf
    if ($fname.Length -gt 15) { $fname = $fname.Substring(0, 12) + "..." }
    
    $lblF = New-Object System.Windows.Forms.Label
    $lblF.Text = $fname
    $lblF.Location = "140, $script:HealthY"
    $lblF.AutoSize = $true
    $lblF.ForeColor = "Gray"
    $grpHealth.Controls.Add($lblF)
    
    # 3. Calculate Size
    $sz = "-"
    if ($exists) {
        try {
            $item = Get-Item $FilePath
            if ($item.PSIsContainer) {
                $sz = "DIR"
            } else {
                if ($item.Length -gt 1GB) {
                    $sz = "{0:N2} GB" -f ($item.Length / 1GB)
                } elseif ($item.Length -gt 1MB) {
                    $sz = "{0:N2} MB" -f ($item.Length / 1MB)
                } else {
                    $sz = "{0:N0} KB" -f ($item.Length / 1KB)
                }
            }
        } catch { $sz = "Err" }
    }

    $lblS = New-Object System.Windows.Forms.Label
    $lblS.Text = $sz
    $lblS.Location = "260, $script:HealthY"
    $lblS.AutoSize = $true
    $lblS.ForeColor = "SkyBlue"
    $grpHealth.Controls.Add($lblS)
    
    # 4. Status Label
    $lblSt = New-Object System.Windows.Forms.Label
    $lblSt.AutoSize = $true
    $lblSt.Location = "320, $script:HealthY"
    $lblSt.Font = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
    if ($exists) { 
        $lblSt.Text = "OK"; $lblSt.ForeColor = "LimeGreen" 
    } else { 
        $lblSt.Text = "MISSING"; $lblSt.ForeColor = "Crimson" 
    }
    $grpHealth.Controls.Add($lblSt)
    
    # 5. [OPEN] Button
    if ($exists) {
        $btnOpen = New-Object System.Windows.Forms.Button
        $btnOpen.Text = "OPEN"
        $btnOpen.Size = New-Object System.Drawing.Size(45, 23)
        $btnOpen.Location = "380, " + ($script:HealthY - 3) 
        $btnOpen.FlatStyle = "Flat"
        $btnOpen.ForeColor = "Silver"
        $btnOpen.Font = New-Object System.Drawing.Font("Arial", 7)
        $btnOpen.FlatAppearance.BorderSize = 1
        $btnOpen.FlatAppearance.BorderColor = "DimGray"
        $btnOpen.Cursor = [System.Windows.Forms.Cursors]::Hand
        
        # [FIX] สร้างตัวแปร local เก็บค่า path ไว้ก่อนส่งเข้า Block
        $targetPath = $FilePath 

        $btnOpen.Add_Click({
            try {
                # ใช้ $targetPath ที่ถูก Capture เข้ามาแทน $FilePath
                $realPath = (Resolve-Path $targetPath).Path
                Start-Process "explorer.exe" -ArgumentList "/select,`"$realPath`""
            } catch {
                # Fallback
                Invoke-Item $targetPath
            }
        }.GetNewClosure()) # GetNewClosure จะจับค่า $targetPath ไว้ให้แต่ละปุ่มแยกกัน
        
        $grpHealth.Controls.Add($btnOpen)
    }
    
    $script:HealthY += 30
}

# Add Rows
Add-HealthCheck "Config"   (Join-Path $AppRoot "Settings\config.json")
Add-HealthCheck "Engine"   (Join-Path $AppRoot "Engine\HoyoEngine.ps1")

# Check DB for games
foreach ($g in @("Genshin", "HSR", "ZZZ")) { 
    Add-HealthCheck "DB ($g)" (Join-Path $AppRoot "UserData\MasterDB_$($g).json") -opt ($g -ne $script:CurrentGame) 
}

# Adjust GroupBox Height & Add bottom spacer
$grpHealth.Height = $script:HealthY + 10
$script:tData.Controls.Add((New-Object System.Windows.Forms.Label -Property @{Text=""; Location="0,$($grpHealth.Bottom+20)"; Size="10,10"}))