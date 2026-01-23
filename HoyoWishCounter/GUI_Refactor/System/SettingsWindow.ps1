function Show-SettingsWindow {
    # 1. Load Config (ดึงค่าปัจจุบันมา)
    $conf = Get-AppConfig 

    # --- FORM SETUP ---
    $fSet = New-Object System.Windows.Forms.Form
    $fSet.Text = "Preferences & Settings"
    $fSet.Size = New-Object System.Drawing.Size(550, 500) # ขยายความสูงนิดนึงให้พอดี
    $fSet.StartPosition = "CenterParent"
    $fSet.BackColor = [System.Drawing.Color]::FromArgb(35, 35, 35)
    $fSet.ForeColor = "White"
    $fSet.FormBorderStyle = "FixedToolWindow"

    # --- TABS ---
    $tabs = New-Object System.Windows.Forms.TabControl
    $tabs.Dock = "Top"
    $tabs.Height = 390
    $tabs.Appearance = "FlatButtons" 
    $fSet.Controls.Add($tabs)

    # Helper สร้าง Tab Page
    function New-Tab($title) {
        $page = New-Object System.Windows.Forms.TabPage
        $page.Text = "  $title  " 
        $page.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 45)
        $tabs.TabPages.Add($page)
        return $page
    }

    # ==================================================
    # TAB 1: GENERAL (REDESIGNED LAYOUT)
    # ==================================================
    $tGen = New-Tab "General"

    # --- GROUP 1: STORAGE & EXPORT ---
    $grpStorage = New-Object System.Windows.Forms.GroupBox
    $grpStorage.Text = " Storage & Export Options "
    $grpStorage.Location = "15, 15"; $grpStorage.Size = "505, 160"
    $grpStorage.ForeColor = "Silver"
    $tGen.Controls.Add($grpStorage)

    # 1. Backup Path
    $lblBk = New-Object System.Windows.Forms.Label
    $lblBk.Text = "Auto-Backup Folder (Optional):"
    $lblBk.Location = "20, 30"; $lblBk.AutoSize = $true
    $lblBk.ForeColor = "White"
    $grpStorage.Controls.Add($lblBk)
    
    $txtBackup = New-Object System.Windows.Forms.TextBox
    $txtBackup.Location = "20, 55"; $txtBackup.Width = 380
    $txtBackup.BackColor = [System.Drawing.Color]::FromArgb(60,60,60)
    $txtBackup.ForeColor = "Cyan"
    $txtBackup.BorderStyle = "FixedSingle"
    $txtBackup.Text = $conf.BackupPath
    $grpStorage.Controls.Add($txtBackup)
    
    $btnBrowseBk = New-Object System.Windows.Forms.Button
    $btnBrowseBk.Text = "Browse..."
    $btnBrowseBk.Location = "410, 54"; $btnBrowseBk.Size = "75, 25"
    Apply-ButtonStyle -Button $btnBrowseBk -BaseColorName "DimGray" -HoverColorName "Gray" -CustomFont $script:fontNormal
    $btnBrowseBk.Add_Click({
        $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
        if ($fbd.ShowDialog() -eq "OK") { $txtBackup.Text = $fbd.SelectedPath }
    })
    $grpStorage.Controls.Add($btnBrowseBk)

    # 2. CSV Separator
    $lblCsv = New-Object System.Windows.Forms.Label
    $lblCsv.Text = "CSV Export Separator (For Excel Compatibility):"
    $lblCsv.Location = "20, 100"; $lblCsv.AutoSize = $true
    $lblCsv.ForeColor = "White"
    $grpStorage.Controls.Add($lblCsv)

    $cmbCsvSep = New-Object System.Windows.Forms.ComboBox
    $cmbCsvSep.Location = "20, 125"; $cmbCsvSep.Width = 200
    $cmbCsvSep.DropDownStyle = "DropDownList"
    $cmbCsvSep.BackColor = [System.Drawing.Color]::FromArgb(60,60,60)
    $cmbCsvSep.ForeColor = "White"
    $cmbCsvSep.FlatStyle = "Flat"
    
    [void]$cmbCsvSep.Items.Add("Comma (,)")
    [void]$cmbCsvSep.Items.Add("Semicolon (;)")
    
    if ($conf.CsvSeparator -eq ";") { $cmbCsvSep.SelectedIndex = 1 } else { $cmbCsvSep.SelectedIndex = 0 }
    $grpStorage.Controls.Add($cmbCsvSep)

    # --- GROUP 2: SYSTEM & DEBUGGING ---
    $grpSys = New-Object System.Windows.Forms.GroupBox
    $grpSys.Text = " System & Troubleshooting "
    $grpSys.Location = "15, 190"; $grpSys.Size = "505, 120"
    $grpSys.ForeColor = "Silver"
    $tGen.Controls.Add($grpSys)

    # 3. Debug Console
    $chkDebug = New-Object System.Windows.Forms.CheckBox
    $chkDebug.Text = "Enable Debug Console (Show CMD Window)"
    $chkDebug.Location = "20, 30"; $chkDebug.AutoSize = $true
    $chkDebug.Checked = $conf.DebugConsole
    $chkDebug.ForeColor = "White"
    $grpSys.Controls.Add($chkDebug)

    # 4. File Logging
    $chkFileLog = New-Object System.Windows.Forms.CheckBox
    $chkFileLog.Text = "Enable System Logging (Save errors to debug_session.log)"
    $chkFileLog.Location = "20, 70"; $chkFileLog.AutoSize = $true
    $chkFileLog.Checked = $conf.EnableFileLog
    $chkFileLog.ForeColor = "White"
    $toolTip.SetToolTip($chkFileLog, "Useful for reporting bugs. Saves actions to a text file.")
    $grpSys.Controls.Add($chkFileLog)


    # 5. Enable Sound Effects
    $chkSound = New-Object System.Windows.Forms.CheckBox
    $chkSound.Text = "Enable Audio Feedback (Sound Effects)"
    $chkSound.Location = "20, 95"; $chkSound.AutoSize = $true # ขยับ Y ลงมาหน่อย
    $chkSound.Checked = $conf.EnableSound
    $chkSound.ForeColor = "White"
    $grpSys.Controls.Add($chkSound)
    # ==================================================
    # TAB 2: APPEARANCE (UPGRADE: Presets + Preview)
    # ==================================================
    $tApp = New-Tab "Appearance"

    # --- 1. THEME PRESETS (ส่วนใหม่ที่เพิ่มเข้ามา) ---
    $lblPreset = New-Object System.Windows.Forms.Label
    $lblPreset.Text = "Quick Theme Presets:"
    $lblPreset.Location = "20, 20"; $lblPreset.AutoSize = $true
    $lblPreset.ForeColor = "Silver"
    $tApp.Controls.Add($lblPreset)

    $cmbPresets = New-Object System.Windows.Forms.ComboBox
    $cmbPresets.Location = "150, 18"; $cmbPresets.Width = 200
    $cmbPresets.DropDownStyle = "DropDownList"
    $cmbPresets.BackColor = [System.Drawing.Color]::FromArgb(50,50,50)
    $cmbPresets.ForeColor = "White"
    $cmbPresets.FlatStyle = "Flat"
    $tApp.Controls.Add($cmbPresets)

    # สร้างรายการธีม (ชื่อธีม = รหัสสี Hex)
    $ThemeList = @{
        "Cyber Cyan (Default)" = "#00FFFF"
        "Genshin Gold"         = "#FFD700"
        "HSR Purple"           = "#9370DB" # MediumPurple
        "ZZZ Orange"           = "#FF4500" # OrangeRed
        "Dendro Green"         = "#32CD32" # LimeGreen
        "Cryo Blue"            = "#00BFFF" # DeepSkyBlue
        "Pyro Red"             = "#DC143C" # Crimson
        "Monochrome (Gray)"    = "#A9A9A9"
    }

    # ใส่รายการลง ComboBox
    foreach ($key in $ThemeList.Keys) { [void]$cmbPresets.Items.Add($key) }

    # [NEW] Logic: ตรวจสอบว่าสีปัจจุบัน ตรงกับ Preset ไหนไหม?
    $foundMatch = $false
    foreach ($key in $ThemeList.Keys) {
        # เปรียบเทียบ Hex Code (แบบไม่สนตัวพิมพ์เล็กใหญ่)
        if ($ThemeList[$key] -eq $conf.AccentColor) {
            $cmbPresets.SelectedItem = $key
            $foundMatch = $true
            break
        }
    }

    # ถ้าสีไม่ตรงกับ Preset ไหนเลย (แปลว่าเป็น Custom)
    if (-not $foundMatch) {
        $cmbPresets.Text = "Custom User Color"
    }
    # --- 2. CUSTOM PICKER (แบบเดิม แต่ขยับตำแหน่ง) ---
    $lblCustom = New-Object System.Windows.Forms.Label
    $lblCustom.Text = "Or Custom Color:"
    $lblCustom.Location = "20, 60"; $lblCustom.AutoSize = $true
    $tApp.Controls.Add($lblCustom)

    # กล่องโชว์สี
    $pnlColorPreview = New-Object System.Windows.Forms.Panel
    $pnlColorPreview.Location = "150, 58"; $pnlColorPreview.Size = "30, 20"
    
    # แปลงสีปัจจุบันมาโชว์
    try { $startColor = [System.Drawing.ColorTranslator]::FromHtml($conf.AccentColor) } 
    catch { $startColor = [System.Drawing.Color]::Cyan }
    $pnlColorPreview.BackColor = $startColor
    $pnlColorPreview.BorderStyle = "FixedSingle"
    $tApp.Controls.Add($pnlColorPreview)

    # ปุ่มเลือกสีเอง
    $btnPickColor = New-Object System.Windows.Forms.Button
    $btnPickColor.Text = "Pick Color..."
    $btnPickColor.Location = "190, 55"; $btnPickColor.Size = "100, 28"
    Apply-ButtonStyle -Button $btnPickColor -BaseColorName "DimGray" -HoverColorName "Gray" -CustomFont $script:fontNormal
    $tApp.Controls.Add($btnPickColor)

    # --- 3. LIVE PREVIEW AREA (Mockup เดิมที่ทำไว้) ---
    $grpPreview = New-Object System.Windows.Forms.GroupBox
    $grpPreview.Text = "  UI Preview (Simulation)  "
    $grpPreview.Location = "20, 100"; $grpPreview.Size = "480, 150"
    $grpPreview.ForeColor = "Silver"
    $tApp.Controls.Add($grpPreview)

    # 3.1 Mock Menu
    $lblMockMenu = New-Object System.Windows.Forms.Label
    $lblMockMenu.Text = ">> Show Graph"
    $lblMockMenu.Location = "350, 25"; $lblMockMenu.AutoSize = $true
    $lblMockMenu.Font = $script:fontBold
    $lblMockMenu.ForeColor = $startColor
    $grpPreview.Controls.Add($lblMockMenu)

    # 3.2 Mock Input
    $lblMockInput = New-Object System.Windows.Forms.Label; $lblMockInput.Text = "Input Field Focus:"; $lblMockInput.Location = "20, 30"; $lblMockInput.AutoSize=$true
    $grpPreview.Controls.Add($lblMockInput)

    $txtMock = New-Object System.Windows.Forms.TextBox
    $txtMock.Text = "C:\GameData\..."
    $txtMock.Location = "20, 55"; $txtMock.Width = 250
    $txtMock.BackColor = [System.Drawing.Color]::FromArgb(45,45,45)
    $txtMock.BorderStyle = "FixedSingle"
    $txtMock.ForeColor = $startColor
    $grpPreview.Controls.Add($txtMock)

    # 3.3 Mock Checkbox
    $chkMock = New-Object System.Windows.Forms.CheckBox
    $chkMock.Text = "Active Option"
    $chkMock.Location = "20, 95"; $chkMock.AutoSize = $true
    $chkMock.Checked = $true
    $chkMock.ForeColor = $startColor
    $grpPreview.Controls.Add($chkMock)

    # --- 4. OPACITY (เอาไว้ที่นี่ที่เดียว) ---
    $lblOp = New-Object System.Windows.Forms.Label
    $lblOp.Text = "Window Opacity (Ghost Mode):"
    $lblOp.Location = "20, 270"; $lblOp.AutoSize = $true
    $tApp.Controls.Add($lblOp)

    $trackOp = New-Object System.Windows.Forms.TrackBar
    $trackOp.Location = "20, 295"; $trackOp.Width = 300
    $trackOp.Minimum = 50; $trackOp.Maximum = 100
    
    # ดึงค่าเดิมมาใส่
    $trackOp.Value = [int]($conf.Opacity * 100)
    $trackOp.TickStyle = "None"
    $tApp.Controls.Add($trackOp)

    # [สำคัญ!] ต้องใส่ Event ตรงนี้ด้วย มันถึงจะ Real-time
    $trackOp.Add_Scroll({
        $liveVal = $trackOp.Value / 100
        $script:form.Opacity = $liveVal
        
        # (Optional) อัปเดตตัวเลขบอก % หลัง Label
        $lblOp.Text = "Window Opacity (Ghost Mode): $($trackOp.Value)%"
    })

    # --- LOGIC การทำงาน ---
    $script:TempHexColor = $conf.AccentColor # ตัวแปรพักค่าสี

    # Helper Function เพื่ออัปเดตหน้า Preview (จะได้ไม่ต้องเขียนซ้ำ)
    $UpdatePreview = {
        param($NewColor)
        $pnlColorPreview.BackColor = $NewColor
        $txtMock.ForeColor = $NewColor
        $chkMock.ForeColor = $NewColor
        $lblMockMenu.ForeColor = $NewColor
        
        # แปลงเป็น Hex เก็บใส่ตัวแปร
        $script:TempHexColor = "#{0:X2}{1:X2}{2:X2}" -f $NewColor.R, $NewColor.G, $NewColor.B
    }

    # Event 1: เมื่อเลือก Preset จาก ComboBox
    $cmbPresets.Add_SelectedIndexChanged({
        $selectedName = $cmbPresets.SelectedItem
        
        # [FIX: เพิ่มบรรทัดนี้] ถ้าค่าเป็น null (เช่น กรณีเลือก Custom Color) ให้จบการทำงานทันที ไม่ต้องเช็คต่อ
        if ($null -eq $selectedName) { return }

        if ($ThemeList.ContainsKey($selectedName)) {
            $hex = $ThemeList[$selectedName]
            $c = [System.Drawing.ColorTranslator]::FromHtml($hex)
            & $UpdatePreview -NewColor $c
        }
    })
    # Event 2: เมื่อกดปุ่ม Pick Color (Custom)
    $btnPickColor.Add_Click({
        $cd = New-Object System.Windows.Forms.ColorDialog
        try { $cd.Color = $pnlColorPreview.BackColor } catch {}

        if ($cd.ShowDialog() -eq "OK") {
            & $UpdatePreview -NewColor $cd.Color
            # รีเซ็ต ComboBox ให้รู้ว่าเราใช้ Custom (Desipired selection)
            $cmbPresets.SelectedIndex = -1 
            $cmbPresets.Text = "Custom User Color"
        }
    })

    # ==================================================
    # TAB 3: DISCORD (กู้คืนกลับมาครบถ้วน)
    # ==================================================
    $tDis = New-Tab "Integrations"
    
    $lblUrl = New-Object System.Windows.Forms.Label; $lblUrl.Text = "Webhook URL:"; $lblUrl.Location="20,20"; $lblUrl.AutoSize=$true
    $tDis.Controls.Add($lblUrl)
    
    $txtWebhook = New-Object System.Windows.Forms.TextBox; $txtWebhook.Location="20,45"; $txtWebhook.Width=400; $txtWebhook.Text=$conf.WebhookUrl
    $tDis.Controls.Add($txtWebhook)
    
    $chkAutoSend = New-Object System.Windows.Forms.CheckBox; $chkAutoSend.Text="Auto-Send Report after fetching"; $chkAutoSend.Location="20,80"; $chkAutoSend.AutoSize=$true; $chkAutoSend.Checked=$conf.AutoSendDiscord
    $tDis.Controls.Add($chkAutoSend)

    # ==================================================
    # TAB 4: DATA & MAINTENANCE (NO EMOJI)
    # ==================================================
    $tData = New-Tab "Data & Storage"
    $tData.AutoScroll = $true  # เปิด Scrollbar

    # 1. Info Label
    $lblDataInfo = New-Object System.Windows.Forms.Label
    $lblDataInfo.Text = "Manage local files, backups, and cache settings."
    $lblDataInfo.Location = "20, 20"; $lblDataInfo.AutoSize = $true; $lblDataInfo.ForeColor = "Gray"
    $tData.Controls.Add($lblDataInfo)

    # 2. Open Folder Button
    $btnOpenFolder = New-Object System.Windows.Forms.Button
    $btnOpenFolder.Text = "[ Open Data Folder ]"
    $btnOpenFolder.Location = "20, 50"; $btnOpenFolder.Size = "250, 35"
    Apply-ButtonStyle -Button $btnOpenFolder -BaseColorName "DimGray" -HoverColorName "Gray" -CustomFont $script:fontNormal
    $btnOpenFolder.Add_Click({ Invoke-Item $PSScriptRoot })
    $tData.Controls.Add($btnOpenFolder)

    # 3. Manual Backup Button
    $btnForceBackup = New-Object System.Windows.Forms.Button
    $btnForceBackup.Text = ">> Create Config Backup"
    $btnForceBackup.Location = "20, 95"; $btnForceBackup.Size = "250, 35"
    Apply-ButtonStyle -Button $btnForceBackup -BaseColorName "RoyalBlue" -HoverColorName "CornflowerBlue" -CustomFont $script:fontNormal
    $btnForceBackup.Add_Click({
        $backupDir = Join-Path $PSScriptRoot "Backups"
        if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir | Out-Null }
        
        $dateStr = Get-Date -Format "yyyyMMdd_HHmmss"
        if (Test-Path "config.json") {
            $destName = "config_backup_$dateStr.json"
            $destPath = Join-Path $backupDir $destName
            Copy-Item "config.json" -Destination $destPath
            WriteGUI-Log "User manually triggered Config Backup. Saved to: $destName" "Lime"
            [System.Windows.Forms.MessageBox]::Show("Backup created successfully inside 'Backups' folder.", "Success", 0, 64)
        } else {
             WriteGUI-Log "Manual Config Backup failed: config.json not found." "OrangeRed"
             [System.Windows.Forms.MessageBox]::Show("Config file not found.", "Info", 0, 48)
        }
    })
    $tData.Controls.Add($btnForceBackup)

    # 4. Restore Button
    $btnRestore = New-Object System.Windows.Forms.Button
    $btnRestore.Text = "<< Restore Config from File"
    $btnRestore.Location = "280, 95"; $btnRestore.Size = "180, 35"
    Apply-ButtonStyle -Button $btnRestore -BaseColorName "DimGray" -HoverColorName "Gray" -CustomFont $script:fontNormal
    $btnRestore.Add_Click({
        $ofd = New-Object System.Windows.Forms.OpenFileDialog
        $ofd.Title = "Select Backup File to Restore"
        $ofd.Filter = "JSON Config|*.json"
        $bkDir = Join-Path $PSScriptRoot "Backups"
        if (Test-Path $bkDir) { $ofd.InitialDirectory = $bkDir }
        
        if ($ofd.ShowDialog() -eq "OK") {
            try {
                $targetFile = $ofd.FileName
                $jsonContent = Get-Content $targetFile -Raw -Encoding UTF8
                $newConf = $jsonContent | ConvertFrom-Json
                if (-not $newConf.PSObject.Properties["AccentColor"]) { throw "Invalid Config Format" }

                if (Test-Path "config.json") { Copy-Item "config.json" -Destination "config.json.old" -Force }
                Set-Content -Path "config.json" -Value $jsonContent -Encoding UTF8
                
                # Hot Reload Settings
                $chkDebug.Checked = $newConf.DebugConsole
                $txtBackup.Text = $newConf.BackupPath
                $txtWebhook.Text = $newConf.WebhookUrl
                $chkAutoSend.Checked = $newConf.AutoSendDiscord
                $chkFileLog.Checked = $newConf.EnableFileLog
                if ($newConf.CsvSeparator -eq ";") { $cmbCsvSep.SelectedIndex = 1 } else { $cmbCsvSep.SelectedIndex = 0 }
                
                $trackOp.Value = [int]($newConf.Opacity * 100)
                $script:form.Opacity = $newConf.Opacity
                $script:TempHexColor = $newConf.AccentColor
                
                try { $restoredColor = [System.Drawing.ColorTranslator]::FromHtml($newConf.AccentColor) } catch { $restoredColor = [System.Drawing.Color]::Cyan }
                $foundTheme = $false
                foreach ($key in $ThemeList.Keys) {
                    if ($ThemeList[$key] -eq $newConf.AccentColor) { $cmbPresets.SelectedItem = $key; $foundTheme = $true; break }
                }
                if (-not $foundTheme) { $cmbPresets.Text = "Custom User Color" }

                & $UpdatePreview -NewColor $restoredColor
                Apply-Theme -NewHex $newConf.AccentColor -NewOpacity $newConf.Opacity
                
                WriteGUI-Log "Configuration Restored from: $($ofd.SafeFileName)" "Lime"
                [System.Windows.Forms.MessageBox]::Show("Settings restored successfully!", "Restored", 0, 64)
            } catch {
                WriteGUI-Log "Restore Failed: $($_.Exception.Message)" "Red"
                [System.Windows.Forms.MessageBox]::Show("Error restoring file: $($_.Exception.Message)", "Error", 0, 16)
            }
        }
    })
    $tData.Controls.Add($btnRestore)

    # 5. Maintenance Zone
    $grpDanger = New-Object System.Windows.Forms.GroupBox
    $grpDanger.Text = " Maintenance Zone "
    $grpDanger.Location = "20, 160"; $grpDanger.Size = "440, 100"
    $grpDanger.ForeColor = "IndianRed"
    $tData.Controls.Add($grpDanger)

    $lblWarn = New-Object System.Windows.Forms.Label
    $lblWarn.Text = "Delete temporary files created during fetch process."
    $lblWarn.Location = "20, 25"; $lblWarn.AutoSize = $true; $lblWarn.ForeColor = "Silver"
    $grpDanger.Controls.Add($lblWarn)

    $btnClearCache = New-Object System.Windows.Forms.Button
    $btnClearCache.Text = "Clear Temporary Cache"
    $btnClearCache.Location = "20, 50"; $btnClearCache.Size = "180, 30"
    $btnClearCache.BackColor = "Maroon"; $btnClearCache.ForeColor = "White"; $btnClearCache.FlatStyle = "Flat"
    $btnClearCache.Add_Click({
        if ([System.Windows.Forms.MessageBox]::Show("Delete temporary cache files?", "Confirm", 4, 32) -eq "Yes") {
            $targetFile = Join-Path $PSScriptRoot "temp_data_2"
            if (Test-Path $targetFile) { Remove-Item $targetFile -Force -ErrorAction SilentlyContinue }
            Get-ChildItem -Path $PSScriptRoot -Filter "*.tmp" | Remove-Item -Force -ErrorAction SilentlyContinue
            WriteGUI-Log "Cache cleanup performed (Temp files removed)." "Gray"
            [System.Windows.Forms.MessageBox]::Show("Cache Cleared.", "Done", 0, 64)
        }
    })
    $grpDanger.Controls.Add($btnClearCache)

    # ==================================================
    # SYSTEM HEALTH MONITOR (MODERN GRID LAYOUT)
    # ==================================================
    $grpHealth = New-Object System.Windows.Forms.GroupBox
    $grpHealth.Text = " System Integrity Dashboard "
    $grpHealth.Location = "20, 270"
    $grpHealth.Size = "440, 100" # ความสูงเริ่มต้น (เดี๋ยวดีดตัวอัตโนมัติ)
    $grpHealth.ForeColor = "Silver"
    $tData.Controls.Add($grpHealth)

    # --- TABLE HEADERS (หัวตารางแบบโปร่ง) ---
    function Add-Header($text, $x) {
        $h = New-Object System.Windows.Forms.Label
        $h.Text = $text
        $h.Location = "$x, 25"; $h.AutoSize = $true
        $h.ForeColor = "DimGray"
        $h.Font = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
        $grpHealth.Controls.Add($h)
    }
    # จัดตำแหน่ง Header ใหม่
    Add-Header "COMPONENT" 20
    Add-Header "FILENAME" 140
    Add-Header "SIZE" 260
    Add-Header "STATUS" 320
    # (ปุ่ม OPEN ไม่ต้องมี Header)

    # เริ่มต้นที่บรรทัดแรก (เว้นที่ให้ Header 30px)
    $script:HealthY = 50

    # --- ROW RENDERER ---
    function Add-HealthCheck {
        param($LabelText, $FilePath, $IsOptional=$false)
        
        $exists = Test-Path $FilePath
        if ($IsOptional -and (-not $exists)) { return }

        # 1. Component Name (ขาว)
        $lbl = New-Object System.Windows.Forms.Label
        $lbl.Text = $LabelText
        $lbl.Location = "20, $script:HealthY"; $lbl.AutoSize = $true
        $lbl.ForeColor = "White"
        $lbl.Font = New-Object System.Drawing.Font("Segoe UI", 9)
        $grpHealth.Controls.Add($lbl)

        # 2. Filename (เทา - ตัดคำ)
        $fileName = Split-Path $FilePath -Leaf
        if ($fileName.Length -gt 15) { $fileName = $fileName.Substring(0, 12) + "..." }
        
        $lblFile = New-Object System.Windows.Forms.Label
        $lblFile.Text = "$fileName"
        $lblFile.Location = "140, $script:HealthY"; $lblFile.AutoSize = $true
        $lblFile.ForeColor = "Gray"
        $lblFile.Font = New-Object System.Drawing.Font("Consolas", 9)
        $grpHealth.Controls.Add($lblFile)
        
        # 3. Size (ฟ้า)
        $sizeTxt = "-"
        if ($exists) {
            try {
                $item = Get-Item $FilePath
                if ($item.PSIsContainer) { $sizeTxt = "DIR" } 
                else {
                    $kb = $item.Length / 1KB
                    if ($kb -gt 1024) { $sizeTxt = "{0:N1} MB" -f ($kb/1024) } 
                    else { $sizeTxt = "{0:N0} KB" -f $kb }
                }
            } catch { $sizeTxt = "?" }
        }
        $lblSize = New-Object System.Windows.Forms.Label
        $lblSize.Text = $sizeTxt
        $lblSize.Location = "260, $script:HealthY"; $lblSize.AutoSize = $true
        $lblSize.ForeColor = [System.Drawing.Color]::FromArgb(80, 200, 255) # ฟ้าสว่าง
        $lblSize.Font = New-Object System.Drawing.Font("Consolas", 9)
        $grpHealth.Controls.Add($lblSize)

        # 4. Status (เขียว/แดง)
        $lblStat = New-Object System.Windows.Forms.Label
        $lblStat.AutoSize = $true
        $lblStat.Location = "320, $script:HealthY"
        $lblStat.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
        
        if ($exists) {
            $lblStat.Text = "OK"
            $lblStat.ForeColor = "LimeGreen"
        } else {
            $lblStat.Text = "MISSING"
            $lblStat.ForeColor = "Crimson"
        }
        $grpHealth.Controls.Add($lblStat)
        
        # 5. Action Button (ทำเป็นปุ่มเล็กๆ Minimal)
        if ($exists) {
            $btnLoc = New-Object System.Windows.Forms.Button
            $btnLoc.Text = "OPEN"
            $btnLoc.Size = "45, 22"
            # จัดตำแหน่ง Y ให้ตรงกับ Text (-2 px เพื่อ center)
            $btnLoc.Location = "380, " + ($script:HealthY - 2)
            $btnLoc.FlatStyle = "Flat"
            $btnLoc.ForeColor = "Silver"
            $btnLoc.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 45)
            $btnLoc.Font = New-Object System.Drawing.Font("Segoe UI", 7)
            $btnLoc.FlatAppearance.BorderSize = 1
            $btnLoc.FlatAppearance.BorderColor = "DimGray"
            $btnLoc.Cursor = [System.Windows.Forms.Cursors]::Hand
            
            # Hover Effect (เปลี่ยนสีขอบเมื่อชี้)
            # [FIX] ใช้ $this แทน $btnLoc เพื่ออ้างอิงปุ่มปัจจุบันอย่างถูกต้อง
            $btnLoc.Add_MouseEnter({ $this.ForeColor = "White"; $this.FlatAppearance.BorderColor = "Cyan" })
            $btnLoc.Add_MouseLeave({ $this.ForeColor = "Silver"; $this.FlatAppearance.BorderColor = "DimGray" })
            $clickAction = { 
                try {
                    $fullPath = (Resolve-Path $FilePath).Path
                    & explorer.exe "/select,`"$fullPath`""
                } catch { Invoke-Item $FilePath }
            }.GetNewClosure()
            
            $btnLoc.Add_Click($clickAction)
            $grpHealth.Controls.Add($btnLoc)
        }

        # เพิ่มระยะห่างบรรทัด (30px) ให้ดูไม่อึดอัด
        $script:HealthY += 30
    }

    # --- ITEMS LIST ---
    Add-HealthCheck "Config"   (Join-Path $PSScriptRoot "config.json")
    Add-HealthCheck "Engine"   (Join-Path $PSScriptRoot "HoyoEngine.ps1")
    
    $gamesToCheck = @("Genshin", "HSR", "ZZZ")
    foreach ($g in $gamesToCheck) {
        $dbPath = Join-Path $PSScriptRoot "UserData\MasterDB_$($g).json"
        $isOpt = ($g -ne $script:CurrentGame)
        Add-HealthCheck "DB ($g)" $dbPath -IsOptional $isOpt
    }

    Add-HealthCheck "System Logs" (Join-Path $PSScriptRoot "Logs")
    
    # ==================================================
    # [FIX] DYNAMIC HEIGHT & SCROLL PADDING
    # ==================================================
    
    # 1. ปรับความสูง GroupBox ให้คลุมทุกบรรทัด + Padding 10px
    $grpHealth.Height = $script:HealthY + 10

    # 2. ปรับตำแหน่ง Ghost Label ให้ต่ำกว่าก้นกล่อง 50px
    # สูตร: Y ของกล่อง (270) + ความสูงกล่องใหม่ + 50
    $ghostY = 270 + $grpHealth.Height + 50
    
    $lblGhost = New-Object System.Windows.Forms.Label
    $lblGhost.Text = ""
    $lblGhost.Size = New-Object System.Drawing.Size(10, 20)
    $lblGhost.Location = New-Object System.Drawing.Point(0, $ghostY)
    
    $tData.Controls.Add($lblGhost)
    
    # ==================================================
    # FOOTER (SAVE BUTTON)
    # ==================================================
    $btnSave = New-Object System.Windows.Forms.Button
    $btnSave.Text = "APPLY"
    $btnSave.Location = "180, 410"; $btnSave.Size = "180, 40"
    Apply-ButtonStyle -Button $btnSave -BaseColorName "ForestGreen" -HoverColorName "LimeGreen" -CustomFont $script:fontBold
    
    $btnSave.Add_Click({
        # 1. Update ค่าลง Object (รวบรวมจากทุก Tab)
        $conf.DebugConsole = $chkDebug.Checked
        $conf.Opacity = ($trackOp.Value / 100)
        $conf.BackupPath = $txtBackup.Text
        $conf.WebhookUrl = $txtWebhook.Text
        $conf.AutoSendDiscord = $chkAutoSend.Checked
        $conf.EnableSound = $chkSound.Checked
        
        # เพิ่มบรรทัดนี้ใน Block Save
        $conf.EnableFileLog = $chkFileLog.Checked

        # จัดการสี (เอามาจากตัวแปรชั่วคราวที่เราอัปเดตตอนเลือก)
        $conf.AccentColor = $script:TempHexColor

        # 2. Save ลงไฟล์ JSON
        Save-AppConfig -ConfigObj $conf
        $script:AppConfig = $conf # อัปเดต Global

        # 3. [สำคัญ] Apply Theme ทันที!
        Apply-Theme -NewHex $conf.AccentColor -NewOpacity $conf.Opacity
        
        # [FIX] บังคับแก้สีปุ่ม Expand ตรงนี้ด้วย (เผื่อมันไม่เปลี่ยน)
        if ($menuExpand) {
             $menuExpand.ForeColor = [System.Drawing.ColorTranslator]::FromHtml($conf.AccentColor)
        }

        # 4. Apply ค่าอื่นๆ
        $script:DebugMode = $conf.DebugConsole
        $chkSendDiscord.Checked = $conf.AutoSendDiscord

        # เพิ่มในส่วน Save
        $sepChar = if ($cmbCsvSep.SelectedIndex -eq 1) { ";" } else { "," }
        $conf.CsvSeparator = $sepChar

        WriteGUI-Log "Configuration updated manually by user." "Cyan"
        
        [System.Windows.Forms.MessageBox]::Show("Settings Saved!", "Done", 0, 64)
        #$fSet.Close()
    })

    # ==================================================
    # RESTORE DEFAULTS BUTTON
    # ==================================================
    $btnResetDef = New-Object System.Windows.Forms.Button
    $btnResetDef.Text = "Restore Defaults"
    $btnResetDef.Location = "20, 415"; $btnResetDef.Size = "120, 30"
    $btnResetDef.FlatStyle = "Flat"; $btnResetDef.ForeColor = "Gray"; $btnResetDef.FlatAppearance.BorderSize = 0
    $btnResetDef.Cursor = [System.Windows.Forms.Cursors]::Hand
    
    $btnResetDef.Add_Click({
        if ([System.Windows.Forms.MessageBox]::Show("Reset all settings to default values?", "Confirm Reset", 4, 48) -eq "Yes") {
            # คืนค่า UI ให้ User เห็น
            $chkDebug.Checked = $false
            $trackOp.Value = 100
            $cmbPresets.SelectedIndex = 0 # Default Theme
            $txtWebhook.Text = ""
            $chkAutoSend.Checked = $true
            $cmbCsvSep.SelectedIndex = 0
            
            WriteGUI-Log "User performed Factory Reset on settings." "OrangeRed"
            # แจ้งเตือน
            [System.Windows.Forms.MessageBox]::Show("Settings reset. Please click 'APPLY' to confirm.", "Info", 0, 64)
        }
    })
    $fSet.Controls.Add($btnResetDef)

    $fSet.Controls.Add($btnSave)
    $fSet.ShowDialog()
}