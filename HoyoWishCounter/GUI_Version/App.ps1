# Load Engine
$EnginePath = Join-Path $PSScriptRoot "HoyoEngine.ps1"
if (-not (Test-Path $EnginePath)) { 
    [System.Windows.Forms.MessageBox]::Show("Error: HoyoEngine.ps1 not found!", "Error", 0, 16)
    exit 
}
. $EnginePath # Load Functions

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

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

# --- MENU BAR (อยู่บนสุด) ---
$menuStrip = New-Object System.Windows.Forms.MenuStrip
$menuStrip.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
$menuStrip.ForeColor = "White"
$form.Controls.Add($menuStrip)
$form.MainMenuStrip = $menuStrip

# เมนู File
$menuFile = New-Object System.Windows.Forms.ToolStripMenuItem("File")
$menuStrip.Items.Add($menuFile)

# เมนูย่อย Reset
$itemClear = New-Object System.Windows.Forms.ToolStripMenuItem("Reset / Clear All")
$itemClear.ShortcutKeys = [System.Windows.Forms.Keys]::F5
$itemClear.Add_Click({
    $txtLog.Clear()
    $script:pnlPityFill.Width = 0
    $script:lblPityTitle.Text = "Current Pity Progress: 0 / 90"
    $script:lblPityTitle.ForeColor = "White"
    $script:pnlPityFill.BackColor = "LimeGreen"
    $script:LastFetchedData = @()
    $script:progressBar.Value = 0
    $btnExport.Enabled = $false
    $btnExport.BackColor = "DimGray"
})
$menuFile.DropDownItems.Add($itemClear)

# เมนูย่อย Exit
$itemExit = New-Object System.Windows.Forms.ToolStripMenuItem("Exit")
$itemExit.Add_Click({ $form.Close() })
$menuFile.DropDownItems.Add($itemExit)

# --- ROW 1: GAME BUTTONS (Y=40) ---
# ขยับลงมาเพื่อให้พ้นเมนูบาร์
$btnGenshin = New-Object System.Windows.Forms.Button
$btnGenshin.Text = "Genshin"
$btnGenshin.Location = New-Object System.Drawing.Point(20, 40); $btnGenshin.Size = New-Object System.Drawing.Size(170, 45)
$btnGenshin.FlatStyle = "Flat"; $btnGenshin.BackColor = "Gold"; $btnGenshin.ForeColor = "Black"; $btnGenshin.FlatAppearance.BorderSize = 0
$form.Controls.Add($btnGenshin)

$btnHSR = New-Object System.Windows.Forms.Button
$btnHSR.Text = "Star Rail"
$btnHSR.Location = New-Object System.Drawing.Point(210, 40); $btnHSR.Size = New-Object System.Drawing.Size(170, 45)
$btnHSR.FlatStyle = "Flat"; $btnHSR.BackColor = "Gray"; $btnHSR.FlatAppearance.BorderSize = 0
$form.Controls.Add($btnHSR)

$btnZZZ = New-Object System.Windows.Forms.Button
$btnZZZ.Text = "ZZZ"
$btnZZZ.Location = New-Object System.Drawing.Point(400, 40); $btnZZZ.Size = New-Object System.Drawing.Size(170, 45)
$btnZZZ.FlatStyle = "Flat"; $btnZZZ.BackColor = "Gray"; $btnZZZ.FlatAppearance.BorderSize = 0
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
$btnAuto.Text = "Auto-Detect"; $btnAuto.Location = New-Object System.Drawing.Point(375, 24); $btnAuto.Size = New-Object System.Drawing.Size(80, 27)
$btnAuto.BackColor = "DodgerBlue"; $btnAuto.FlatStyle = "Flat"; $btnAuto.FlatAppearance.BorderSize = 0
$grpSettings.Controls.Add($btnAuto)

$btnBrowse = New-Object System.Windows.Forms.Button
$btnBrowse.Text = "..."; $btnBrowse.Location = New-Object System.Drawing.Point(465, 24); $btnBrowse.Size = New-Object System.Drawing.Size(70, 27)
$btnBrowse.BackColor = "DimGray"; $btnBrowse.FlatStyle = "Flat"; $btnBrowse.FlatAppearance.BorderSize = 0
$grpSettings.Controls.Add($btnBrowse)

$chkSendDiscord = New-Object System.Windows.Forms.CheckBox
$chkSendDiscord.Text = "Send Discord"; $chkSendDiscord.Location = New-Object System.Drawing.Point(15, 60); $chkSendDiscord.AutoSize = $true
$chkSendDiscord.ForeColor = "Cyan"; $chkSendDiscord.Checked = $true
$grpSettings.Controls.Add($chkSendDiscord)

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
$script:lblPityTitle.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
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

$btnRun = New-Object System.Windows.Forms.Button
$btnRun.Text = "START FETCHING"; $btnRun.Location = New-Object System.Drawing.Point(20, 305); $btnRun.Size = New-Object System.Drawing.Size(400, 45)
$btnRun.BackColor = "ForestGreen"; $btnRun.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold); $btnRun.FlatStyle = "Flat"; $btnRun.FlatAppearance.BorderSize = 0
$form.Controls.Add($btnRun)

$btnStop = New-Object System.Windows.Forms.Button
$btnStop.Text = "STOP"; $btnStop.Location = New-Object System.Drawing.Point(430, 305); $btnStop.Size = New-Object System.Drawing.Size(140, 45)
$btnStop.BackColor = "Firebrick"; $btnStop.ForeColor = "White"; $btnStop.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold); $btnStop.FlatStyle = "Flat"; $btnStop.FlatAppearance.BorderSize = 0
$btnStop.Enabled = $false
$form.Controls.Add($btnStop)

# --- ROW 5: LOG WINDOW (Y=365) ---
$txtLog = New-Object System.Windows.Forms.RichTextBox
$txtLog.Location = New-Object System.Drawing.Point(20, 365); $txtLog.Size = New-Object System.Drawing.Size(550, 420) 
$txtLog.BackColor = "Black"; $txtLog.ForeColor = "Lime"; $txtLog.ReadOnly = $true; $txtLog.Font = New-Object System.Drawing.Font("Consolas", 10); $txtLog.BorderStyle = "None"
$form.Controls.Add($txtLog)

# --- ROW 6: EXPORT (Y=800) ---
$btnExport = New-Object System.Windows.Forms.Button
$btnExport.Text = ">> Export History to CSV (Excel)"; 
$btnExport.Location = New-Object System.Drawing.Point(20, 800); $btnExport.Size = New-Object System.Drawing.Size(550, 35)
$btnExport.BackColor = "DimGray"; $btnExport.ForeColor = "White"; $btnExport.FlatStyle = "Flat"; $btnExport.FlatAppearance.BorderSize = 0
$btnExport.Enabled = $false
$form.Controls.Add($btnExport)

# ============================
#  FUNCTIONS
# ============================

function Log($msg, $color="Lime") { 
    $txtLog.SelectionStart = $txtLog.Text.Length
    $txtLog.SelectionColor = [System.Drawing.Color]::FromName($color)
    $txtLog.AppendText("$msg`n")
    $txtLog.ScrollToCaret() 
}

function Update-BannerList {
    $conf = Get-GameConfig $script:CurrentGame
    $script:cmbBanner.Items.Clear()
    $script:cmbBanner.Items.Add("* FETCH ALL (Recommended)") 
    foreach ($b in $conf.Banners) {
        $script:cmbBanner.Items.Add("$($b.Name)")
    }
    $script:cmbBanner.SelectedIndex = 0
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
$btnExport.Add_Click({
    if ($script:LastFetchedData.Count -eq 0) { return }
    
    $fileName = "$($script:CurrentGame)_WishHistory_$(Get-Date -Format 'yyyyMMdd_HHmm').csv"
    $exportPath = Join-Path $PSScriptRoot $fileName
    
    try {
        # Select เฉพาะ Column ที่จำเป็น
        $script:LastFetchedData | Select-Object time, name, item_type, rank_type, _BannerName, id | Export-Csv -Path $exportPath -NoTypeInformation -Encoding UTF8
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
                $form.Text = "Fetching $($banner.Name) - Page $p..." 
                [System.Windows.Forms.Application]::DoEvents()
                if ($script:StopRequested) { throw "STOPPED" }
            }
            
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
        
        # --- DISCORD ---
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
    }
})

# Initial
Update-BannerList
$form.ShowDialog() | Out-Null