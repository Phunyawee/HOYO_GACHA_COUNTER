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
    $lblBk = New-Object System.Windows.Forms.Label; $lblBk.Text = "Auto-Backup Folder:"; $lblBk.Location = "20, 30"; $lblBk.AutoSize = $true; $lblBk.ForeColor = "White"; $grpStorage.Controls.Add($lblBk)
    $txtBackup = New-Object System.Windows.Forms.TextBox; $txtBackup.Location = "20, 55"; $txtBackup.Width = 380; $txtBackup.BackColor = [System.Drawing.Color]::FromArgb(60,60,60); $txtBackup.ForeColor = "Cyan"; $txtBackup.BorderStyle = "FixedSingle"; $txtBackup.Text = $conf.BackupPath; $grpStorage.Controls.Add($txtBackup)
    $btnBrowseBk = New-Object System.Windows.Forms.Button; $btnBrowseBk.Text = "..."; $btnBrowseBk.Location = "410, 54"; $btnBrowseBk.Size = "75, 25"; Apply-ButtonStyle -Button $btnBrowseBk -BaseColorName "DimGray" -HoverColorName "Gray" -CustomFont $script:fontNormal
    $btnBrowseBk.Add_Click({ $fbd = New-Object System.Windows.Forms.FolderBrowserDialog; if ($fbd.ShowDialog() -eq "OK") { $txtBackup.Text = $fbd.SelectedPath } }); $grpStorage.Controls.Add($btnBrowseBk)
    
    $lblCsv = New-Object System.Windows.Forms.Label; $lblCsv.Text = "CSV Separator:"; $lblCsv.Location = "20, 100"; $lblCsv.AutoSize = $true; $lblCsv.ForeColor = "White"; $grpStorage.Controls.Add($lblCsv)
    $cmbCsvSep = New-Object System.Windows.Forms.ComboBox; $cmbCsvSep.Location = "20, 125"; $cmbCsvSep.Width = 200; $cmbCsvSep.DropDownStyle = "DropDownList"; $cmbCsvSep.BackColor = [System.Drawing.Color]::FromArgb(60,60,60); $cmbCsvSep.ForeColor = "White"; $cmbCsvSep.FlatStyle = "Flat"
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
    $lblUrl = New-Object System.Windows.Forms.Label; $lblUrl.Text = "Webhook URL:"; $lblUrl.Location="20,20"; $lblUrl.AutoSize=$true; $tDis.Controls.Add($lblUrl)
    $txtWebhook = New-Object System.Windows.Forms.TextBox; $txtWebhook.Location="20,45"; $txtWebhook.Width=400; $txtWebhook.Text=$conf.WebhookUrl; $tDis.Controls.Add($txtWebhook)
    $chkAutoSend = New-Object System.Windows.Forms.CheckBox; $chkAutoSend.Text="Auto-Send Report"; $chkAutoSend.Location="20,80"; $chkAutoSend.AutoSize=$true; $chkAutoSend.Checked=$conf.AutoSendDiscord; $tDis.Controls.Add($chkAutoSend)

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
    function Add-HealthCheck($t, $p, $opt=$false) {
        $ex=Test-Path $p; if($opt -and (-not $ex)){return}
        $l=New-Object System.Windows.Forms.Label; $l.Text=$t; $l.Location="20,$script:HealthY"; $l.AutoSize=$true; $l.ForeColor="White"; $grpHealth.Controls.Add($l)
        $fn=Split-Path $p -Leaf; if($fn.Length-gt 15){$fn=$fn.Substring(0,12)+"..."}; $lf=New-Object System.Windows.Forms.Label; $lf.Text=$fn; $lf.Location="140,$script:HealthY"; $lf.AutoSize=$true; $lf.ForeColor="Gray"; $grpHealth.Controls.Add($lf)
        $sz="?"; if($ex){try{$i=Get-Item $p;if($i.PSIsContainer){$sz="DIR"}else{$sz="{0:N0} KB"-f($i.Length/1KB)}}catch{}}; $ls=New-Object System.Windows.Forms.Label; $ls.Text=$sz; $ls.Location="260,$script:HealthY"; $ls.AutoSize=$true; $ls.ForeColor="SkyBlue"; $grpHealth.Controls.Add($ls)
        $st=New-Object System.Windows.Forms.Label; $st.AutoSize=$true; $st.Location="320,$script:HealthY"; if($ex){$st.Text="OK";$st.ForeColor="LimeGreen"}else{$st.Text="MISSING";$st.ForeColor="Crimson"}; $grpHealth.Controls.Add($st)
        $script:HealthY+=30
    }

    # [FIX] ใช้ $AppRoot แทน $PSScriptRoot ทั้งหมด!
    Add-HealthCheck "Config"   (Join-Path $AppRoot "Settings\config.json")
    Add-HealthCheck "Engine"   (Join-Path $AppRoot "Engine\HoyoEngine.ps1")
    Add-HealthCheck "Logs"     (Join-Path $AppRoot "Logs")
    foreach ($g in @("Genshin", "HSR", "ZZZ")) { Add-HealthCheck "DB ($g)" (Join-Path $AppRoot "UserData\MasterDB_$($g).json") -opt ($g -ne $script:CurrentGame) }

    $grpHealth.Height = $script:HealthY+10; $tData.Controls.Add((New-Object System.Windows.Forms.Label -Property @{Text=""; Location="0,$($grpHealth.Bottom+20)"; Size="10,10"}))

    # ================= SAVE & EXIT =================
    $btnSave = New-Object System.Windows.Forms.Button; $btnSave.Text = "APPLY SETTINGS"; $btnSave.Location = "180, 500"; $btnSave.Size = "180, 40"; Apply-ButtonStyle -Button $btnSave -BaseColorName "ForestGreen" -HoverColorName "LimeGreen" -CustomFont $script:fontBold
    $btnSave.Add_Click({
        $conf.DebugConsole=$chkDebug.Checked; $conf.Opacity=($trackOp.Value/100); $conf.BackupPath=$txtBackup.Text; $conf.WebhookUrl=$txtWebhook.Text; $conf.AutoSendDiscord=$chkAutoSend.Checked; $conf.EnableSound=$chkSound.Checked; $conf.EnableFileLog=$chkFileLog.Checked; $conf.AccentColor=$script:TempHexColor; $conf.CsvSeparator=if($cmbCsvSep.SelectedIndex-eq 1){";"}else{","}
        
        # [FIX] บันทึกไฟล์ที่ Path ใหม่ ($AppRoot\Settings)
        $setDir = Join-Path $AppRoot "Settings"; if(-not(Test-Path $setDir)){New-Item -Type Directory -Path $setDir -Force|Out-Null}
        $conf | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $setDir "config.json") -Encoding UTF8

        $script:AppConfig=$conf; Apply-Theme -NewHex $conf.AccentColor -NewOpacity $conf.Opacity; $script:DebugMode=$conf.DebugConsole
        if($menuExpand){$menuExpand.ForeColor=[System.Drawing.ColorTranslator]::FromHtml($conf.AccentColor)}; if($chkSendDiscord){$chkSendDiscord.Checked=$conf.AutoSendDiscord}
        [System.Windows.Forms.MessageBox]::Show("Saved!", "Done"); $fSet.Close()
    })
    $fSet.Controls.Add($btnSave)
    
    $btnReset=New-Object System.Windows.Forms.Button; $btnReset.Text="Defaults"; $btnReset.Location="20,505"; $btnReset.Size="80,30"; $btnReset.FlatStyle="Flat"; $btnReset.ForeColor="Gray"; $btnReset.FlatAppearance.BorderSize=0
    $btnReset.Add_Click({if([System.Windows.Forms.MessageBox]::Show("Reset?","Confirm",4)-eq"Yes"){$chkDebug.Checked=$false;$trackOp.Value=100;$cmbPresets.SelectedIndex=0; [System.Windows.Forms.MessageBox]::Show("Reset done. Click APPLY.")}}); $fSet.Controls.Add($btnReset)

    $fSet.ShowDialog()
}