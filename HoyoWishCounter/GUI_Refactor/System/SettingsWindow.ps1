function Show-SettingsWindow {
    # 1. [FIX] กำหนด Root ของโปรแกรม (ถอยจาก System ออกมา 1 ขั้น)
    $AppRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

    # 2. Load Config
    $conf = Get-AppConfig 

    # --- FORM SETUP ---
    $fSet = New-Object System.Windows.Forms.Form
    $fSet.Text = "Preferences & Settings"
    $fSet.Size = New-Object System.Drawing.Size(550, 600)
    $fSet.StartPosition = "CenterParent"
    $fSet.BackColor = [System.Drawing.Color]::FromArgb(35, 35, 35)
    $fSet.ForeColor = "White"
    $fSet.FormBorderStyle = "FixedToolWindow"

    # --- TABS ---
    $tabs = New-Object System.Windows.Forms.TabControl; $tabs.Dock = "Top"; $tabs.Height = 480; $tabs.Appearance = "FlatButtons"; $fSet.Controls.Add($tabs)
    function New-Tab($title) { $page = New-Object System.Windows.Forms.TabPage; $page.Text = "  $title  "; $page.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 45); $tabs.TabPages.Add($page); return $page }

    # ================= TAB 1: GENERAL =================
    $tGen = New-Tab "General"
    
    $grpStorage = New-Object System.Windows.Forms.GroupBox; $grpStorage.Text = " Storage "; $grpStorage.Location = "15, 15"; $grpStorage.Size = "505, 160"; $grpStorage.ForeColor = "Silver"; $tGen.Controls.Add($grpStorage)
    
    # [NEW] Checkbox เปิด/ปิด Backup (เพิ่มตรงนี้)
    $chkEnableBk = New-Object System.Windows.Forms.CheckBox; $chkEnableBk.Text = "Enable Auto-Backup System"; $chkEnableBk.Location = "20, 25"; $chkEnableBk.AutoSize = $true; $chkEnableBk.ForeColor = "LimeGreen"
    # Logic: ถ้าไม่มีคีย์นี้ใน Config ให้ถือว่าเป็น True ไว้ก่อน, ถ้ามีก็เอาตามค่าจริง
    $chkEnableBk.Checked = if ($conf.PSObject.Properties["EnableAutoBackup"] -and $conf.EnableAutoBackup -eq $false) { $false } else { $true }
    $chkEnableBk.Add_CheckedChanged({ $txtBackup.Enabled = $chkEnableBk.Checked; $btnBrowseBk.Enabled = $chkEnableBk.Checked }) # กดปิดแล้วช่องสีเทา
    $grpStorage.Controls.Add($chkEnableBk)

    # ขยับตำแหน่งของเดิมลงมา (Y จาก 30->55, 55->80)
    $lblBk = New-Object System.Windows.Forms.Label; $lblBk.Text = "Backup Folder Path:"; $lblBk.Location = "20, 55"; $lblBk.AutoSize = $true; $lblBk.ForeColor = "White"; $grpStorage.Controls.Add($lblBk)
    $txtBackup = New-Object System.Windows.Forms.TextBox; $txtBackup.Location = "20, 80"; $txtBackup.Width = 380; $txtBackup.BackColor = [System.Drawing.Color]::FromArgb(60,60,60); $txtBackup.ForeColor = "Cyan"; $txtBackup.BorderStyle = "FixedSingle"; $txtBackup.Text = $conf.BackupPath; $grpStorage.Controls.Add($txtBackup)
    # สั่ง Disable ถ้า Checkbox ไม่ได้ติ๊ก
    $txtBackup.Enabled = $chkEnableBk.Checked 

    $btnBrowseBk = New-Object System.Windows.Forms.Button; $btnBrowseBk.Text = "..."; $btnBrowseBk.Location = "410, 79"; $btnBrowseBk.Size = "75, 25"; Apply-ButtonStyle -Button $btnBrowseBk -BaseColorName "DimGray" -HoverColorName "Gray" -CustomFont $script:fontNormal
    $btnBrowseBk.Add_Click({ $fbd = New-Object System.Windows.Forms.FolderBrowserDialog; if ($fbd.ShowDialog() -eq "OK") { $txtBackup.Text = $fbd.SelectedPath } })
    $btnBrowseBk.Enabled = $chkEnableBk.Checked 
    $grpStorage.Controls.Add($btnBrowseBk)
    
    # CSV Separator ขยับลงนิดหน่อย (Y=115, 135)
    $lblCsv = New-Object System.Windows.Forms.Label; $lblCsv.Text = "CSV Separator:"; $lblCsv.Location = "20, 115"; $lblCsv.AutoSize = $true; $lblCsv.ForeColor = "White"; $grpStorage.Controls.Add($lblCsv)
    $cmbCsvSep = New-Object System.Windows.Forms.ComboBox; $cmbCsvSep.Location = "130, 112"; $cmbCsvSep.Width = 100; $cmbCsvSep.DropDownStyle = "DropDownList"; $cmbCsvSep.BackColor = [System.Drawing.Color]::FromArgb(60,60,60); $cmbCsvSep.ForeColor = "White"; $cmbCsvSep.FlatStyle = "Flat"
    [void]$cmbCsvSep.Items.Add("Comma (,)"); [void]$cmbCsvSep.Items.Add("Semicolon (;)")
    if ($conf.CsvSeparator -eq ";") { $cmbCsvSep.SelectedIndex = 1 } else { $cmbCsvSep.SelectedIndex = 0 }
    $grpStorage.Controls.Add($cmbCsvSep)

    $grpSys = New-Object System.Windows.Forms.GroupBox; $grpSys.Text = " System "; $grpSys.Location = "15, 190"; $grpSys.Size = "505, 120"; $grpSys.ForeColor = "Silver"; $tGen.Controls.Add($grpSys)
    $chkDebug = New-Object System.Windows.Forms.CheckBox; $chkDebug.Text = "Enable Debug Console"; $chkDebug.Location = "20, 30"; $chkDebug.AutoSize = $true; $chkDebug.Checked = $conf.DebugConsole; $chkDebug.ForeColor = "White"; $grpSys.Controls.Add($chkDebug)
    $chkFileLog = New-Object System.Windows.Forms.CheckBox; $chkFileLog.Text = "Enable System Logging"; $chkFileLog.Location = "20, 70"; $chkFileLog.AutoSize = $true; $chkFileLog.Checked = $conf.EnableFileLog; $chkFileLog.ForeColor = "White"; $grpSys.Controls.Add($chkFileLog)
    $chkSound = New-Object System.Windows.Forms.CheckBox; $chkSound.Text = "Enable Sound Effects"; $chkSound.Location = "20, 95"; $chkSound.AutoSize = $true; $chkSound.Checked = $conf.EnableSound; $chkSound.ForeColor = "White"; $grpSys.Controls.Add($chkSound)

    # ================= TAB 2: APPEARANCE =================
    $tApp = New-Tab "Appearance"
    $lblPreset = New-Object System.Windows.Forms.Label; $lblPreset.Text = "Theme Presets:"; $lblPreset.Location = "20, 20"; $lblPreset.AutoSize = $true; $lblPreset.ForeColor = "Silver"; $tApp.Controls.Add($lblPreset)
    $cmbPresets = New-Object System.Windows.Forms.ComboBox; $cmbPresets.Location = "150, 18"; $cmbPresets.Width = 200; $cmbPresets.DropDownStyle = "DropDownList"; $cmbPresets.BackColor = [System.Drawing.Color]::FromArgb(50,50,50); $cmbPresets.ForeColor = "White"; $cmbPresets.FlatStyle = "Flat"; $tApp.Controls.Add($cmbPresets)
    $ThemeList = @{ "Cyber Cyan"="#00FFFF"; "Genshin Gold"="#FFD700"; "HSR Purple"="#9370DB"; "ZZZ Orange"="#FF4500"; "Dendro Green"="#32CD32"; "Cryo Blue"="#00BFFF"; "Pyro Red"="#DC143C"; "Monochrome"="#A9A9A9" }
    foreach ($key in $ThemeList.Keys) { [void]$cmbPresets.Items.Add($key) }
    $foundMatch = $false; foreach ($key in $ThemeList.Keys) { if ($ThemeList[$key] -eq $conf.AccentColor) { $cmbPresets.SelectedItem = $key; $foundMatch = $true; break } }
    if (-not $foundMatch) { $cmbPresets.Text = "Custom User Color" }

    $pnlColorPreview = New-Object System.Windows.Forms.Panel; $pnlColorPreview.Location = "150, 58"; $pnlColorPreview.Size = "30, 20"; $pnlColorPreview.BorderStyle = "FixedSingle"
    try { $startColor = [System.Drawing.ColorTranslator]::FromHtml($conf.AccentColor) } catch { $startColor = [System.Drawing.Color]::Cyan }
    $pnlColorPreview.BackColor = $startColor; $tApp.Controls.Add($pnlColorPreview)
    $btnPickColor = New-Object System.Windows.Forms.Button; $btnPickColor.Text = "Pick Color..."; $btnPickColor.Location = "190, 55"; $btnPickColor.Size = "100, 28"; Apply-ButtonStyle -Button $btnPickColor -BaseColorName "DimGray" -HoverColorName "Gray" -CustomFont $script:fontNormal; $tApp.Controls.Add($btnPickColor)

    $grpPreview = New-Object System.Windows.Forms.GroupBox; $grpPreview.Text = " Preview "; $grpPreview.Location = "20, 100"; $grpPreview.Size = "480, 150"; $grpPreview.ForeColor = "Silver"; $tApp.Controls.Add($grpPreview)
    $lblMockMenu = New-Object System.Windows.Forms.Label; $lblMockMenu.Text = ">> Show Graph"; $lblMockMenu.Location = "350, 25"; $lblMockMenu.AutoSize = $true; $lblMockMenu.Font = $script:fontBold; $lblMockMenu.ForeColor = $startColor; $grpPreview.Controls.Add($lblMockMenu)
    $txtMock = New-Object System.Windows.Forms.TextBox; $txtMock.Text = "C:\GameData\..."; $txtMock.Location = "20, 55"; $txtMock.Width = 250; $txtMock.BackColor = [System.Drawing.Color]::FromArgb(45,45,45); $txtMock.BorderStyle = "FixedSingle"; $txtMock.ForeColor = $startColor; $grpPreview.Controls.Add($txtMock)
    
    $lblOp = New-Object System.Windows.Forms.Label; $lblOp.Text = "Window Opacity:"; $lblOp.Location = "20, 270"; $lblOp.AutoSize = $true; $tApp.Controls.Add($lblOp)
    $trackOp = New-Object System.Windows.Forms.TrackBar; $trackOp.Location = "20, 295"; $trackOp.Width = 300; $trackOp.Minimum = 50; $trackOp.Maximum = 100; $trackOp.Value = [int]($conf.Opacity * 100); $trackOp.TickStyle = "None"; $tApp.Controls.Add($trackOp)
    $trackOp.Add_Scroll({ $script:form.Opacity = ($trackOp.Value / 100); $lblOp.Text = "Window Opacity: $($trackOp.Value)%" })

    $script:TempHexColor = $conf.AccentColor
    $UpdatePreview = { param($NewColor); $pnlColorPreview.BackColor = $NewColor; $txtMock.ForeColor = $NewColor; $lblMockMenu.ForeColor = $NewColor; $script:TempHexColor = "#{0:X2}{1:X2}{2:X2}" -f $NewColor.R, $NewColor.G, $NewColor.B }
    $cmbPresets.Add_SelectedIndexChanged({ if($cmbPresets.SelectedItem){if($ThemeList.ContainsKey($cmbPresets.SelectedItem)){& $UpdatePreview -NewColor ([System.Drawing.ColorTranslator]::FromHtml($ThemeList[$cmbPresets.SelectedItem]))}} })
    $btnPickColor.Add_Click({ $cd = New-Object System.Windows.Forms.ColorDialog; if($cd.ShowDialog()-eq"OK"){& $UpdatePreview -NewColor $cd.Color; $cmbPresets.SelectedIndex=-1; $cmbPresets.Text="Custom"} })

    # ================= TAB 3: INTEGRATIONS =================
    $tDis = New-Tab "Integrations"
    $tDis.AutoScroll = $true # เผื่อจอเล็กจะได้เลื่อนได้

    # --- 1. Discord ---
    $grpDisc = New-Object System.Windows.Forms.GroupBox; $grpDisc.Text = " Discord Webhook "; $grpDisc.Location = "15, 15"; $grpDisc.Size = "500, 100"; $grpDisc.ForeColor = "Silver"; $tDis.Controls.Add($grpDisc)
    
    $lblUrl = New-Object System.Windows.Forms.Label; $lblUrl.Text = "Webhook URL:"; $lblUrl.Location = "20, 25"; $lblUrl.AutoSize = $true; $lblUrl.ForeColor = "White"; $grpDisc.Controls.Add($lblUrl)
    $txtWebhook = New-Object System.Windows.Forms.TextBox; $txtWebhook.Location = "20, 45"; $txtWebhook.Width = 460; $txtWebhook.BackColor = [System.Drawing.Color]::FromArgb(60,60,60); $txtWebhook.ForeColor = "Cyan"; $txtWebhook.BorderStyle = "FixedSingle"; $txtWebhook.Text = $conf.WebhookUrl; $grpDisc.Controls.Add($txtWebhook)
    
    $chkAutoSend = New-Object System.Windows.Forms.CheckBox; $chkAutoSend.Text = "Auto-Send Report to Discord"; $chkAutoSend.Location = "20, 75"; $chkAutoSend.AutoSize = $true; $chkAutoSend.ForeColor = "White"; $chkAutoSend.Checked = $conf.AutoSendDiscord; $grpDisc.Controls.Add($chkAutoSend)

    # --- 2. Email Recipient (คนรับ) ---
    $grpMail = New-Object System.Windows.Forms.GroupBox; $grpMail.Text = " Email Notification (To) "; $grpMail.Location = "15, 125"; $grpMail.Size = "500, 80"; $grpMail.ForeColor = "Silver"; $tDis.Controls.Add($grpMail)

    $lblMail = New-Object System.Windows.Forms.Label; $lblMail.Text = "Receiver Email:"; $lblMail.Location = "20, 25"; $lblMail.AutoSize = $true; $lblMail.ForeColor = "White"; $grpMail.Controls.Add($lblMail)
    $txtEmail = New-Object System.Windows.Forms.TextBox; $txtEmail.Location = "20, 45"; $txtEmail.Width = 300; $txtEmail.BackColor = [System.Drawing.Color]::FromArgb(60,60,60); $txtEmail.ForeColor = "Yellow"; $txtEmail.BorderStyle = "FixedSingle"
    if ($conf.PSObject.Properties["NotificationEmail"]) { $txtEmail.Text = $conf.NotificationEmail }
    $grpMail.Controls.Add($txtEmail)

    $chkAutoEmail = New-Object System.Windows.Forms.CheckBox; $chkAutoEmail.Text = "Auto-Send"; $chkAutoEmail.Location = "340, 45"; $chkAutoEmail.AutoSize = $true; $chkAutoEmail.ForeColor = "White"
    if ($conf.PSObject.Properties["AutoSendEmail"]) { $chkAutoEmail.Checked = $conf.AutoSendEmail }
    $grpMail.Controls.Add($chkAutoEmail)

    # --- 3. [NEW] SMTP Settings (คนส่ง) ---
    $grpSmtp = New-Object System.Windows.Forms.GroupBox; $grpSmtp.Text = " SMTP Sender Config (Advanced) "; $grpSmtp.Location = "15, 215"; $grpSmtp.Size = "500, 160"; $grpSmtp.ForeColor = "Orange"; $tDis.Controls.Add($grpSmtp)

    # Server & Port
    $lblSmtpHost = New-Object System.Windows.Forms.Label; $lblSmtpHost.Text = "SMTP Host (e.g. smtp.gmail.com):"; $lblSmtpHost.Location = "20, 25"; $lblSmtpHost.AutoSize = $true; $grpSmtp.Controls.Add($lblSmtpHost)
    $txtSmtpHost = New-Object System.Windows.Forms.TextBox; $txtSmtpHost.Location = "20, 45"; $txtSmtpHost.Width = 300; $txtSmtpHost.BackColor = [System.Drawing.Color]::FromArgb(50,50,50); $txtSmtpHost.ForeColor = "White"; $txtSmtpHost.BorderStyle = "FixedSingle"
    # Default Value
    if ($conf.PSObject.Properties["SmtpServer"]) { $txtSmtpHost.Text = $conf.SmtpServer } else { $txtSmtpHost.Text = "smtp.gmail.com" }
    $grpSmtp.Controls.Add($txtSmtpHost)

    $lblPort = New-Object System.Windows.Forms.Label; $lblPort.Text = "Port:"; $lblPort.Location = "340, 25"; $lblPort.AutoSize = $true; $grpSmtp.Controls.Add($lblPort)
    $txtPort = New-Object System.Windows.Forms.TextBox; $txtPort.Location = "340, 45"; $txtPort.Width = 60; $txtPort.BackColor = [System.Drawing.Color]::FromArgb(50,50,50); $txtPort.ForeColor = "White"; $txtPort.BorderStyle = "FixedSingle"
    if ($conf.PSObject.Properties["SmtpPort"]) { $txtPort.Text = $conf.SmtpPort } else { $txtPort.Text = "587" }
    $grpSmtp.Controls.Add($txtPort)

    # Sender Email & Password
    $lblSender = New-Object System.Windows.Forms.Label; $lblSender.Text = "Sender Email (Bot):"; $lblSender.Location = "20, 80"; $lblSender.AutoSize = $true; $grpSmtp.Controls.Add($lblSender)
    $txtSender = New-Object System.Windows.Forms.TextBox; $txtSender.Location = "20, 100"; $txtSender.Width = 220; $txtSender.BackColor = [System.Drawing.Color]::FromArgb(50,50,50); $txtSender.ForeColor = "White"; $txtSender.BorderStyle = "FixedSingle"
    if ($conf.PSObject.Properties["SenderEmail"]) { $txtSender.Text = $conf.SenderEmail }
    $grpSmtp.Controls.Add($txtSender)

    $lblPass = New-Object System.Windows.Forms.Label; $lblPass.Text = "App Password:"; $lblPass.Location = "260, 80"; $lblPass.AutoSize = $true; $grpSmtp.Controls.Add($lblPass)
    $txtPass = New-Object System.Windows.Forms.TextBox; $txtPass.Location = "260, 100"; $txtPass.Width = 200; $txtPass.BackColor = [System.Drawing.Color]::FromArgb(50,50,50); $txtPass.ForeColor = "White"; $txtPass.BorderStyle = "FixedSingle"
    $txtPass.UseSystemPasswordChar = $true # ซ่อนรหัสผ่านเป็นจุดๆ
    if ($conf.PSObject.Properties["SenderPassword"]) { $txtPass.Text = $conf.SenderPassword }
    $grpSmtp.Controls.Add($txtPass)
    
    # Checkbox Show Password
    $chkShowPass = New-Object System.Windows.Forms.CheckBox; $chkShowPass.Text = "Show"; $chkShowPass.Location = "470, 100"; $chkShowPass.AutoSize = $true; $chkShowPass.ForeColor = "DimGray"
    $chkShowPass.Add_CheckedChanged({ $txtPass.UseSystemPasswordChar = -not $chkShowPass.Checked })
    $grpSmtp.Controls.Add($chkShowPass)


    # ================= TAB 4: DATA & MAINTENANCE =================
    $tData = New-Tab "Data & Storage"; $tData.AutoScroll = $true

    # [FIX] ใช้ $AppRoot แทน $PSScriptRoot
    $btnOpenFolder = New-Object System.Windows.Forms.Button; $btnOpenFolder.Text = "[ Open Data Folder ]"; $btnOpenFolder.Location = "20, 50"; $btnOpenFolder.Size = "250, 35"; Apply-ButtonStyle -Button $btnOpenFolder -BaseColorName "DimGray" -HoverColorName "Gray" -CustomFont $script:fontNormal
    $btnOpenFolder.Add_Click({ Invoke-Item $AppRoot }) 
    $tData.Controls.Add($btnOpenFolder)

    $btnForceBackup = New-Object System.Windows.Forms.Button; $btnForceBackup.Text = ">> Create Config Backup"; $btnForceBackup.Location = "20, 95"; $btnForceBackup.Size = "250, 35"; Apply-ButtonStyle -Button $btnForceBackup -BaseColorName "RoyalBlue" -HoverColorName "CornflowerBlue" -CustomFont $script:fontNormal
    $btnForceBackup.Add_Click({
        # [FIX] Path ใช้ $AppRoot
        $srcConfig = Join-Path $AppRoot "Settings\config.json"
        $backupDir = Join-Path $AppRoot "Backups"
        if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir | Out-Null }
        if (Test-Path $srcConfig) {
            $destName = "config_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
            Copy-Item -Path $srcConfig -Destination (Join-Path $backupDir $destName)
            [System.Windows.Forms.MessageBox]::Show("Backup created in 'Backups'.", "Success", 0, 64)
        } else { [System.Windows.Forms.MessageBox]::Show("Config not found in Settings.", "Error", 0, 48) }
    })
    $tData.Controls.Add($btnForceBackup)

    $btnRestore = New-Object System.Windows.Forms.Button; $btnRestore.Text = "<< Restore Config"; $btnRestore.Location = "280, 95"; $btnRestore.Size = "180, 35"; Apply-ButtonStyle -Button $btnRestore -BaseColorName "DimGray" -HoverColorName "Gray" -CustomFont $script:fontNormal
    $btnRestore.Add_Click({
        $ofd = New-Object System.Windows.Forms.OpenFileDialog; $ofd.Filter = "JSON|*.json"; $ofd.InitialDirectory = Join-Path $AppRoot "Backups"
        if ($ofd.ShowDialog() -eq "OK") {
            try {
                $jsonContent = Get-Content $ofd.FileName -Raw -Encoding UTF8; $newConf = $jsonContent | ConvertFrom-Json
                if (-not $newConf.PSObject.Properties["AccentColor"]) { throw "Invalid Format" }
                
                # [FIX] Restore ลง Settings โดยใช้ $AppRoot
                $configDir = Join-Path $AppRoot "Settings"
                if (-not (Test-Path $configDir)) { New-Item -ItemType Directory -Path $configDir -Force | Out-Null }
                Set-Content -Path (Join-Path $configDir "config.json") -Value $jsonContent -Encoding UTF8

                $chkDebug.Checked=$newConf.DebugConsole; $txtBackup.Text=$newConf.BackupPath; $txtWebhook.Text=$newConf.WebhookUrl; $chkAutoSend.Checked=$newConf.AutoSendDiscord; $chkFileLog.Checked=$newConf.EnableFileLog; $trackOp.Value=[int]($newConf.Opacity*100); $script:form.Opacity=$newConf.Opacity
                Apply-Theme -NewHex $newConf.AccentColor -NewOpacity $newConf.Opacity
                [System.Windows.Forms.MessageBox]::Show("Settings restored!", "Success", 0, 64)
            } catch { [System.Windows.Forms.MessageBox]::Show("Error: $($_.Exception.Message)", "Error", 0, 16) }
        }
    })
    $tData.Controls.Add($btnRestore)

    $grpDanger = New-Object System.Windows.Forms.GroupBox; $grpDanger.Text = " Maintenance "; $grpDanger.Location = "20, 160"; $grpDanger.Size = "440, 80"; $grpDanger.ForeColor = "IndianRed"; $tData.Controls.Add($grpDanger)
    $btnClearCache = New-Object System.Windows.Forms.Button; $btnClearCache.Text = "Clear Cache"; $btnClearCache.Location = "20, 30"; $btnClearCache.Size = "180, 30"; $btnClearCache.BackColor = "Maroon"; $btnClearCache.ForeColor = "White"; $btnClearCache.FlatStyle = "Flat"
    $btnClearCache.Add_Click({ 
        if ([System.Windows.Forms.MessageBox]::Show("Delete temp files?", "Confirm", 4, 32) -eq "Yes") {
            Remove-Item (Join-Path $AppRoot "temp_data_2") -Recurse -Force -ErrorAction SilentlyContinue
            [System.Windows.Forms.MessageBox]::Show("Cache Cleared.", "Done")
        }
    }); $grpDanger.Controls.Add($btnClearCache)

    # --- HEALTH CHECK ---
    $grpHealth = New-Object System.Windows.Forms.GroupBox; $grpHealth.Text = " System Status "; $grpHealth.Location = "20, 260"; $grpHealth.Size = "440, 100"; $grpHealth.ForeColor = "Silver"; $tData.Controls.Add($grpHealth)
    function Add-Header($text, $x) { $h = New-Object System.Windows.Forms.Label; $h.Text=$text; $h.Location="$x, 25"; $h.AutoSize=$true; $h.ForeColor="DimGray"; $grpHealth.Controls.Add($h) }
    Add-Header "COMPONENT" 20; Add-Header "FILENAME" 140; Add-Header "SIZE" 260; Add-Header "STATUS" 320; $script:HealthY=50
    # --- ROW RENDERER (UPGRADED) ---
    function Add-HealthCheck {
        param($LabelText, $FilePath, $IsOptional=$false)
        
        $exists = Test-Path $FilePath
        if ($IsOptional -and (-not $exists)) { return }

        # 1. Label ชื่อ Component
        $lbl = New-Object System.Windows.Forms.Label; $lbl.Text = $LabelText; $lbl.Location = "20, $script:HealthY"; $lbl.AutoSize = $true; $lbl.ForeColor = "White"; $grpHealth.Controls.Add($lbl)
        
        # 2. ชื่อไฟล์
        $fname = Split-Path $FilePath -Leaf; if ($fname.Length -gt 15) { $fname = $fname.Substring(0, 12)+"..." }
        $lblF = New-Object System.Windows.Forms.Label; $lblF.Text = $fname; $lblF.Location = "140, $script:HealthY"; $lblF.AutoSize = $true; $lblF.ForeColor = "Gray"; $grpHealth.Controls.Add($lblF)
        
        # 3. คำนวณขนาด (File เท่านั้น, Folder โชว์ DIR)
        $sz = "-"
        if ($exists) {
            try {
                $item = Get-Item $FilePath
                
                if ($item.PSIsContainer) {
                    # ถ้าเป็น Folder ให้จบเลย พิมพ์ว่า DIR
                    $sz = "DIR"
                } else {
                    # ถ้าเป็น File ค่อยคำนวณ
                    if ($item.Length -gt 1GB) {
                        $sz = "{0:N2} GB" -f ($item.Length / 1GB)
                    } elseif ($item.Length -gt 1MB) {
                        $sz = "{0:N2} MB" -f ($item.Length / 1MB)
                    } else {
                        $sz = "{0:N0} KB" -f ($item.Length / 1KB)
                    }
                }
            } catch { 
                $sz = "Err" 
            }
        }

        $lblS = New-Object System.Windows.Forms.Label
        $lblS.Text = $sz
        $lblS.Location = "260, $script:HealthY"
        $lblS.AutoSize = $true
        $lblS.ForeColor = "SkyBlue"
        $grpHealth.Controls.Add($lblS)
        # 4. สถานะ
        $lblSt = New-Object System.Windows.Forms.Label; $lblSt.AutoSize = $true; $lblSt.Location = "320, $script:HealthY"; $lblSt.Font = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
        if ($exists) { $lblSt.Text = "OK"; $lblSt.ForeColor = "LimeGreen" } else { $lblSt.Text = "MISSING"; $lblSt.ForeColor = "Crimson" }
        $grpHealth.Controls.Add($lblSt)
        
        # --- [NEW] 5. ปุ่ม OPEN (เพิ่มส่วนนี้) ---
        if ($exists) {
            $btnOpen = New-Object System.Windows.Forms.Button
            $btnOpen.Text = "OPEN"
            $btnOpen.Size = New-Object System.Drawing.Size(45, 23)
            # วางตำแหน่งถัดจากสถานะไปทางขวา (X=380)
            $btnOpen.Location = "380, " + ($script:HealthY - 3) 
            $btnOpen.FlatStyle = "Flat"
            $btnOpen.ForeColor = "Silver"
            $btnOpen.Font = New-Object System.Drawing.Font("Arial", 7)
            $btnOpen.FlatAppearance.BorderSize = 1
            $btnOpen.FlatAppearance.BorderColor = "DimGray"
            $btnOpen.Cursor = [System.Windows.Forms.Cursors]::Hand
            
            # Action: เปิด Explorer แล้วชี้ไปที่ไฟล์นั้น
            $btnOpen.Add_Click({
                try {
                    $realPath = (Resolve-Path $FilePath).Path
                    # ใช้ explorer.exe /select,"path" เพื่อเปิดแล้ว highlight ไฟล์เลย
                    Start-Process "explorer.exe" -ArgumentList "/select,`"$realPath`""
                } catch {
                    # Fallback: ถ้าเปิดแบบ select ไม่ได้ ให้เปิดปกติ
                    Invoke-Item $FilePath
                }
            }.GetNewClosure()) # สำคัญ: ใช้ GetNewClosure เพื่อจำค่า $FilePath ของบรรทัดนี้ไว้
            
            $grpHealth.Controls.Add($btnOpen)
        }
        
        $script:HealthY += 30
    }

    # [FIX] ใช้ $AppRoot แทน $PSScriptRoot ทั้งหมด!
    Add-HealthCheck "Config"   (Join-Path $AppRoot "Settings\config.json")
    Add-HealthCheck "Engine"   (Join-Path $AppRoot "Engine\HoyoEngine.ps1")
    # Add-HealthCheck "Logs"     (Join-Path $AppRoot "Logs")
    foreach ($g in @("Genshin", "HSR", "ZZZ")) { Add-HealthCheck "DB ($g)" (Join-Path $AppRoot "UserData\MasterDB_$($g).json") -opt ($g -ne $script:CurrentGame) }

    $grpHealth.Height = $script:HealthY+10; $tData.Controls.Add((New-Object System.Windows.Forms.Label -Property @{Text=""; Location="0,$($grpHealth.Bottom+20)"; Size="10,10"}))

    
    # ==================================================
    # TAB 5: ADVANCED (RAW JSON EDITOR)
    # ==================================================
    $tAdv = New-Tab "Advanced"
    
    # 1. คำเตือนแบบ Hacker Style
    $lblAdvInfo = New-Object System.Windows.Forms.Label
    $lblAdvInfo.Text = "CAUTION: Direct JSON Editing Mode. Syntax errors may reset config."
    $lblAdvInfo.Location = "15, 15"; $lblAdvInfo.AutoSize = $true
    $lblAdvInfo.ForeColor = "Orange"
    $lblAdvInfo.Font = New-Object System.Drawing.Font("Consolas", 8)
    $tAdv.Controls.Add($lblAdvInfo)

    # 2. พื้นที่เขียน Code (Text Area)
    $txtJson = New-Object System.Windows.Forms.TextBox
    $txtJson.Multiline = $true
    $txtJson.ScrollBars = "Vertical"
    $txtJson.Location = "15, 40"
    $txtJson.Size = "505, 360" # ใหญ่สะใจ
    $txtJson.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 20) # ดำเกือบสนิท
    $txtJson.ForeColor = "LimeGreen" # สีเขียว Matrix
    $txtJson.Font = New-Object System.Drawing.Font("Consolas", 10) # ฟอนต์โค้ด
    $txtJson.BorderStyle = "FixedSingle"
    
    # ดึง JSON สวยๆ มาโชว์
    $txtJson.Text = $conf | ConvertTo-Json -Depth 5
    $tAdv.Controls.Add($txtJson)

    # 3. แถบปุ่มควบคุม (Button Bar)
    $pnlAdvBtns = New-Object System.Windows.Forms.Panel
    $pnlAdvBtns.Location = "15, 410"; $pnlAdvBtns.Size = "505, 35"
    $tAdv.Controls.Add($pnlAdvBtns)

    # ปุ่ม 3.1: Open Folder
    $btnAdvOpen = New-Object System.Windows.Forms.Button
    $btnAdvOpen.Text = "Open Folder"
    $btnAdvOpen.Location = "0, 0"; $btnAdvOpen.Size = "100, 30"
    Apply-ButtonStyle -Button $btnAdvOpen -BaseColorName "DimGray" -HoverColorName "Gray" -CustomFont $script:fontNormal
    $btnAdvOpen.Add_Click({ Invoke-Item (Join-Path $AppRoot "Settings") })
    $pnlAdvBtns.Controls.Add($btnAdvOpen)

    # ปุ่ม 3.2: Revert/Reload (เผื่อแก้พัง)
    $btnAdvReload = New-Object System.Windows.Forms.Button
    $btnAdvReload.Text = "Revert Changes"
    $btnAdvReload.Location = "110, 0"; $btnAdvReload.Size = "120, 30"
    Apply-ButtonStyle -Button $btnAdvReload -BaseColorName "IndianRed" -HoverColorName "Red" -CustomFont $script:fontNormal
    $btnAdvReload.Add_Click({
        # โหลดค่าจากตัวแปร $conf เดิมมาทับใหม่ (Undo สิ่งที่พิมพ์ไป)
        $txtJson.Text = $conf | ConvertTo-Json -Depth 5
        WriteGUI-Log "Reverted JSON editor changes." "Yellow"
    })
    $pnlAdvBtns.Controls.Add($btnAdvReload)

    # ปุ่ม 3.3: SAVE & HOT RELOAD (พระเอกของเรา)
    $btnAdvSave = New-Object System.Windows.Forms.Button
    $btnAdvSave.Text = "SAVE & APPLY (HOT RELOAD)"
    $btnAdvSave.Location = "285, 0"; $btnAdvSave.Size = "220, 30"
    Apply-ButtonStyle -Button $btnAdvSave -BaseColorName "SeaGreen" -HoverColorName "Lime" -CustomFont $script:fontBold
    $btnAdvSave.Add_Click({
        try {
            # 1. แปลง Text กลับเป็น Object (Validation ในตัว ถ้า Syntax ผิดจะเด้งเข้า Catch)
            $newRawObj = $txtJson.Text | ConvertFrom-Json
            
            # 2. บันทึกลงไฟล์ทันที
            $setDir = Join-Path $AppRoot "Settings"
            if (-not (Test-Path $setDir)) { New-Item -ItemType Directory -Path $setDir -Force | Out-Null }
            $txtJson.Text | Out-File (Join-Path $setDir "config.json") -Encoding UTF8

            # 3. อัปเดต Global Config (สำคัญมาก: นี่คือที่มาของ Hot Reload)
            $script:AppConfig = $newRawObj
            
            # 4. สั่ง UI ให้เปลี่ยนตามทันที!
            Apply-Theme -NewHex $newRawObj.AccentColor -NewOpacity $newRawObj.Opacity
            
            # อัปเดตค่าใน UI หน้า Settings ด้วย (จะได้ไม่ตีกัน)
            $conf = $newRawObj 
            $script:TempHexColor = $newRawObj.AccentColor
            $trackOp.Value = [int]($newRawObj.Opacity * 100)
            
            WriteGUI-Log "Advanced Config Saved & Hot-Reloaded!" "Lime"
            [System.Windows.Forms.MessageBox]::Show("Configuration updated and applied live!", "Success", 0, 64)
            
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Invalid JSON Syntax!`nCheck your commas and brackets.`n`nError: $($_.Exception.Message)", "JSON Error", 0, 16)
        }
    })
    $pnlAdvBtns.Controls.Add($btnAdvSave)
    
    # ================= SAVE & EXIT =================
    $btnSave = New-Object System.Windows.Forms.Button; $btnSave.Text = "APPLY SETTINGS"; $btnSave.Location = "180, 500"; $btnSave.Size = "180, 40"; Apply-ButtonStyle -Button $btnSave -BaseColorName "ForestGreen" -HoverColorName "LimeGreen" -CustomFont $script:fontBold
    $btnSave.Add_Click({
        # 1. Helper Function: วิธีเพิ่มคีย์ถ้าไม่มี (จะได้ไม่ต้องเขียน if ซ้ำๆ)
        function Set-ConfVal($Name, $Val) {
            if (-not $conf.PSObject.Properties[$Name]) {
                $conf | Add-Member -NotePropertyName $Name -NotePropertyValue $Val
            } else {
                $conf.$Name = $Val
            }
        }

        # 2. เก็บค่าจาก UI ลงตัวแปร $conf
        Set-ConfVal "EnableAutoBackup" $chkEnableBk.Checked
        Set-ConfVal "NotificationEmail" $txtEmail.Text
        Set-ConfVal "AutoSendEmail" $chkAutoEmail.Checked
        
        # --- [NEW] SMTP SAVING ---
        Set-ConfVal "SmtpServer" $txtSmtpHost.Text
        Set-ConfVal "SmtpPort" ([int]$txtPort.Text)
        Set-ConfVal "SenderEmail" $txtSender.Text
        Set-ConfVal "SenderPassword" $txtPass.Text
        # -------------------------

        # 3. ค่า Config พื้นฐาน
        $conf.DebugConsole=$chkDebug.Checked
        $conf.Opacity=($trackOp.Value/100)
        $conf.BackupPath=$txtBackup.Text
        $conf.WebhookUrl=$txtWebhook.Text
        $conf.AutoSendDiscord=$chkAutoSend.Checked
        $conf.EnableSound=$chkSound.Checked
        $conf.EnableFileLog=$chkFileLog.Checked
        $conf.AccentColor=$script:TempHexColor
        $conf.CsvSeparator=if($cmbCsvSep.SelectedIndex-eq 1){";"}else{","}
        
        # 4. บันทึกลงไฟล์
        $setDir = Join-Path $AppRoot "Settings"
        if (-not (Test-Path $setDir)) { New-Item -Type Directory -Path $setDir -Force | Out-Null }
        
        $conf | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $setDir "config.json") -Encoding UTF8

        # 5. Reload & Close
        $script:AppConfig=$conf
        Apply-Theme -NewHex $conf.AccentColor -NewOpacity $conf.Opacity
        $script:DebugMode=$conf.DebugConsole
        if ($menuExpand) { $menuExpand.ForeColor=[System.Drawing.ColorTranslator]::FromHtml($conf.AccentColor) }
        
        [System.Windows.Forms.MessageBox]::Show("Configuration (including SMTP) Saved!", "Done")
        $fSet.Close()
    })
    $fSet.Controls.Add($btnSave)
    
    $btnReset=New-Object System.Windows.Forms.Button; $btnReset.Text="Defaults"; $btnReset.Location="20,505"; $btnReset.Size="80,30"; $btnReset.FlatStyle="Flat"; $btnReset.ForeColor="Gray"; $btnReset.FlatAppearance.BorderSize=0
    $btnReset.Add_Click({if([System.Windows.Forms.MessageBox]::Show("Reset?","Confirm",4)-eq"Yes"){$chkDebug.Checked=$false;$trackOp.Value=100;$cmbPresets.SelectedIndex=0; [System.Windows.Forms.MessageBox]::Show("Reset done. Click APPLY.")}}); $fSet.Controls.Add($btnReset)


    # ==================================================
    # [FIX] AUTO REFRESH JSON WHEN SWITCHING TABS
    # ==================================================
    $tabs.Add_SelectedIndexChanged({
        # เช็คว่า Tab ที่เลือกคือ "Advanced" หรือไม่
        if ($tabs.SelectedTab.Text -match "Advanced") {
            
            # 1. ดึงค่าปัจจุบันจาก Tab General (UI -> Object)
            $conf.BackupPath = $txtBackup.Text
            if (-not $conf.PSObject.Properties["EnableAutoBackup"]) { 
                $conf | Add-Member -NotePropertyName "EnableAutoBackup" -NotePropertyValue $chkEnableBk.Checked 
            } else { 
                $conf.EnableAutoBackup = $chkEnableBk.Checked 
            }
            $conf.CsvSeparator = if ($cmbCsvSep.SelectedIndex -eq 1) { ";" } else { "," }
            $conf.DebugConsole = $chkDebug.Checked
            $conf.EnableFileLog = $chkFileLog.Checked
            $conf.EnableSound = $chkSound.Checked

            # 2. ดึงค่าจาก Tab Appearance
            # (สีเอาจาก TempHexColor ล่าสุด, Opacity เอาจาก TrackBar)
            $conf.AccentColor = $script:TempHexColor
            $conf.Opacity = ($trackOp.Value / 100)

            # 3. ดึงค่าจาก Tab Integrations (Discord + Email ใหม่)
            $conf.WebhookUrl = $txtWebhook.Text
            $conf.AutoSendDiscord = $chkAutoSend.Checked
            
            # จัดการ Email
            if (-not $conf.PSObject.Properties["NotificationEmail"]) { 
                $conf | Add-Member -NotePropertyName "NotificationEmail" -NotePropertyValue $txtEmail.Text 
            } else { 
                $conf.NotificationEmail = $txtEmail.Text 
            }
            # จัดการ AutoSendEmail
            if (-not $conf.PSObject.Properties["AutoSendEmail"]) { 
                $conf | Add-Member -NotePropertyName "AutoSendEmail" -NotePropertyValue $chkAutoEmail.Checked 
            } else { 
                $conf.AutoSendEmail = $chkAutoEmail.Checked 
            }

            # 4. [สำคัญ] เขียน JSON ใหม่ลงกล่องข้อความ
            $txtJson.Text = $conf | ConvertTo-Json -Depth 5
            
            # แอบบอก User หน่อยว่ารีเฟรชแล้ว (Optional)
            # Write-Host "JSON View Refreshed form UI inputs."
        }
    })
    
    $fSet.ShowDialog()
}