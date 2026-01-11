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

# State Variables
$script:CurrentGame = "Genshin"
$script:StagingFile = Join-Path $PSScriptRoot "temp_data_2"
$script:StopRequested = $false
$script:LastFetchedData = @() # ตัวแปรเก็บข้อมูลสำหรับ Export

# ============================
#  UI SECTION
# ============================

# --- ROW 1: GAME BUTTONS (Y=20) ---
$btnGenshin = New-Object System.Windows.Forms.Button
$btnGenshin.Text = "Genshin"
$btnGenshin.Location = New-Object System.Drawing.Point(20, 20); $btnGenshin.Size = New-Object System.Drawing.Size(170, 50)
$btnGenshin.FlatStyle = "Flat"; $btnGenshin.BackColor = "Gold"; $btnGenshin.ForeColor = "Black"
$form.Controls.Add($btnGenshin)

$btnHSR = New-Object System.Windows.Forms.Button
$btnHSR.Text = "Star Rail"
$btnHSR.Location = New-Object System.Drawing.Point(210, 20); $btnHSR.Size = New-Object System.Drawing.Size(170, 50)
$btnHSR.FlatStyle = "Flat"; $btnHSR.BackColor = "Gray"
$form.Controls.Add($btnHSR)

$btnZZZ = New-Object System.Windows.Forms.Button
$btnZZZ.Text = "ZZZ"
$btnZZZ.Location = New-Object System.Drawing.Point(400, 20); $btnZZZ.Size = New-Object System.Drawing.Size(170, 50)
$btnZZZ.FlatStyle = "Flat"; $btnZZZ.BackColor = "Gray"
$form.Controls.Add($btnZZZ)

# --- ROW 2: FILE SELECTION (Y=90) ---
$grpFile = New-Object System.Windows.Forms.GroupBox
$grpFile.Text = "Cache File Selection"
$grpFile.Location = New-Object System.Drawing.Point(20, 90); $grpFile.Size = New-Object System.Drawing.Size(545, 70)
$grpFile.ForeColor = "White"
$form.Controls.Add($grpFile)

$txtPath = New-Object System.Windows.Forms.TextBox
$txtPath.Location = New-Object System.Drawing.Point(15, 25); $txtPath.Size = New-Object System.Drawing.Size(340, 30)
$grpFile.Controls.Add($txtPath)

$btnAuto = New-Object System.Windows.Forms.Button
$btnAuto.Text = "Auto-Detect"
$btnAuto.Location = New-Object System.Drawing.Point(365, 23); $btnAuto.Size = New-Object System.Drawing.Size(80, 25)
$btnAuto.BackColor = "DodgerBlue"; $btnAuto.FlatStyle = "Flat"
$grpFile.Controls.Add($btnAuto)

$btnBrowse = New-Object System.Windows.Forms.Button
$btnBrowse.Text = "Browse..."
$btnBrowse.Location = New-Object System.Drawing.Point(455, 23); $btnBrowse.Size = New-Object System.Drawing.Size(80, 25)
$btnBrowse.BackColor = "DimGray"; $btnBrowse.FlatStyle = "Flat"
$grpFile.Controls.Add($btnBrowse)

# --- ROW 3: OPTIONS (Y=170) ---
$chkSendDiscord = New-Object System.Windows.Forms.CheckBox
$chkSendDiscord.Text = "Send Report to Discord"; 
$chkSendDiscord.Location = New-Object System.Drawing.Point(30, 168); $chkSendDiscord.AutoSize = $true
$chkSendDiscord.ForeColor = "Cyan"
$chkSendDiscord.Checked = $true
$form.Controls.Add($chkSendDiscord)

$chkShowNo = New-Object System.Windows.Forms.CheckBox
$chkShowNo.Text = "Show [No. XX] (In Discord)"; 
$chkShowNo.Location = New-Object System.Drawing.Point(30, 192); $chkShowNo.AutoSize = $true
$form.Controls.Add($chkShowNo)

$lblBanner = New-Object System.Windows.Forms.Label
$lblBanner.Text = "Banner:"; $lblBanner.AutoSize = $true; $lblBanner.ForeColor = "Cyan"
$lblBanner.Location = New-Object System.Drawing.Point(200, 185)
$form.Controls.Add($lblBanner)

$script:cmbBanner = New-Object System.Windows.Forms.ComboBox
$script:cmbBanner.Location = New-Object System.Drawing.Point(260, 182)
$script:cmbBanner.Size = New-Object System.Drawing.Size(305, 30)
$script:cmbBanner.DropDownStyle = "DropDownList"
$form.Controls.Add($script:cmbBanner)

# --- ROW 4: MAIN ACTIONS (Y=230) ---
$btnRun = New-Object System.Windows.Forms.Button
$btnRun.Text = "START FETCHING"; $btnRun.Location = New-Object System.Drawing.Point(20, 230); $btnRun.Size = New-Object System.Drawing.Size(400, 50)
$btnRun.BackColor = "ForestGreen"; $btnRun.Font = New-Object System.Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Bold); $btnRun.FlatStyle = "Flat"
$form.Controls.Add($btnRun)

$btnStop = New-Object System.Windows.Forms.Button
$btnStop.Text = "STOP"; $btnStop.Location = New-Object System.Drawing.Point(430, 230); $btnStop.Size = New-Object System.Drawing.Size(135, 50)
$btnStop.BackColor = "Firebrick"; $btnStop.ForeColor = "White"; $btnStop.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold); $btnStop.FlatStyle = "Flat"
$btnStop.Enabled = $false
$form.Controls.Add($btnStop)

# --- ROW 5: EXPORT (Y=290) - [NEW] ---
$btnExport = New-Object System.Windows.Forms.Button
$btnExport.Text = ">> Export History to CSV (Excel)"; 
$btnExport.Location = New-Object System.Drawing.Point(20, 290); $btnExport.Size = New-Object System.Drawing.Size(545, 35)
$btnExport.BackColor = "DimGray"; $btnExport.ForeColor = "White"; $btnExport.FlatStyle = "Flat"
$btnExport.Enabled = $false # เปิดเมื่อ Fetch เสร็จ
$form.Controls.Add($btnExport)

# --- ROW 6: LOG WINDOW (Y=335) ---
$txtLog = New-Object System.Windows.Forms.RichTextBox
$txtLog.Location = New-Object System.Drawing.Point(20, 335); $txtLog.Size = New-Object System.Drawing.Size(545, 400)
$txtLog.BackColor = "Black"; $txtLog.ForeColor = "Lime"; $txtLog.ReadOnly = $true; $txtLog.Font = New-Object System.Drawing.Font("Consolas", 10)
$form.Controls.Add($txtLog)


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