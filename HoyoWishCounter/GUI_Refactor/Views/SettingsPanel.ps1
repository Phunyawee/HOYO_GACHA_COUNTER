# views/SettingsPanel.ps1

# --- ROW 2: SETTINGS GROUP BOX ---
$grpSettings = New-Object System.Windows.Forms.GroupBox
$grpSettings.Text = " Configuration "
$grpSettings.Location = New-Object System.Drawing.Point(20, 100)
$grpSettings.Size = New-Object System.Drawing.Size(550, 135) 
$grpSettings.ForeColor = "Silver"
$form.Controls.Add($grpSettings)

# ==============================================================================
# LINE 1: PATH INPUT & BUTTONS
# ==============================================================================
$txtPath = New-Object System.Windows.Forms.TextBox
$txtPath.Location = New-Object System.Drawing.Point(15, 26)
$txtPath.Size = New-Object System.Drawing.Size(340, 25)
$txtPath.BackColor = [System.Drawing.Color]::FromArgb(45,45,45)
$txtPath.ForeColor = $script:Theme.Accent
$txtPath.BorderStyle = "FixedSingle"
$grpSettings.Controls.Add($txtPath)

# ปุ่ม Auto-Detect
$btnAuto = New-Object System.Windows.Forms.Button
$btnAuto.Text = "Auto Find"
$btnAuto.Location = New-Object System.Drawing.Point(365, 25)
$btnAuto.Size = New-Object System.Drawing.Size(100, 27) 
# ! ต้องมีฟังก์ชันนี้ใน App.ps1 แล้วนะ !
Apply-ButtonStyle -Button $btnAuto -BaseColorName "DodgerBlue" -HoverColorName "DeepSkyBlue" -CustomFont $script:fontNormal
$grpSettings.Controls.Add($btnAuto)

# ปุ่ม Browse
$btnBrowse = New-Object System.Windows.Forms.Button
$btnBrowse.Text = "..."
$btnBrowse.Location = New-Object System.Drawing.Point(475, 25)
$btnBrowse.Size = New-Object System.Drawing.Size(60, 27)
Apply-ButtonStyle -Button $btnBrowse -BaseColorName "DimGray" -HoverColorName "Gray" -CustomFont $script:fontNormal
$grpSettings.Controls.Add($btnBrowse)


# ==============================================================================
# LINE 2: TOGGLES (Discord & View Mode)
# ==============================================================================

# 1. Discord Toggle
$chkSendDiscord = New-Object System.Windows.Forms.CheckBox
$chkSendDiscord.Appearance = "Button" 
$chkSendDiscord.Size = New-Object System.Drawing.Size(255, 30) 
$chkSendDiscord.Location = New-Object System.Drawing.Point(15, 65)
$chkSendDiscord.FlatStyle = "Flat"; $chkSendDiscord.FlatAppearance.BorderSize = 0
$chkSendDiscord.TextAlign = "MiddleCenter"
$chkSendDiscord.Cursor = [System.Windows.Forms.Cursors]::Hand
$chkSendDiscord.Checked = $true 

# Logic เปลี่ยนสี Discord
$discordToggleEvent = {
    if ($chkSendDiscord.Checked) {
        $chkSendDiscord.Text = "Discord Report: ON"
        $chkSendDiscord.BackColor = "MediumSlateBlue" 
        $chkSendDiscord.ForeColor = "White"
    } else {
        $chkSendDiscord.Text = "Discord Report: OFF"
        $chkSendDiscord.BackColor = [System.Drawing.Color]::FromArgb(60,60,60) 
        $chkSendDiscord.ForeColor = "Gray"
    }
}
$chkSendDiscord.Add_CheckedChanged($discordToggleEvent)
& $discordToggleEvent # รัน 1 ครั้งเพื่อ Apply สีเริ่มต้น
$grpSettings.Controls.Add($chkSendDiscord)

# ! ต้องมี $toolTip ใน App.ps1 แล้วนะ !
if ($toolTip) { $toolTip.SetToolTip($chkSendDiscord, "Auto-Send report to Discord after fetching.") }


# 2. View Toggle (Show No.)
$chkShowNo = New-Object System.Windows.Forms.CheckBox
$chkShowNo.Appearance = "Button"
$chkShowNo.Size = New-Object System.Drawing.Size(255, 30) 
$chkShowNo.Location = New-Object System.Drawing.Point(280, 65)
$chkShowNo.FlatStyle = "Flat"; $chkShowNo.FlatAppearance.BorderSize = 0
$chkShowNo.TextAlign = "MiddleCenter"
$chkShowNo.Cursor = [System.Windows.Forms.Cursors]::Hand
$chkShowNo.Checked = $false

# Logic เปลี่ยนสี View
$viewToggleEvent = {
    if ($chkShowNo.Checked) {
        $chkShowNo.Text = "View: Index [No.]"
        $chkShowNo.BackColor = "Gold" 
        $chkShowNo.ForeColor = "Black"
    } else {
        $chkShowNo.Text = "View: Timestamp"
        $chkShowNo.BackColor = [System.Drawing.Color]::FromArgb(60,60,60)
        $chkShowNo.ForeColor = "Gray"
    }
    
    # เช็คก่อนเรียก Update-FilteredView (กัน Error ตอนเปิดโปรแกรมครั้งแรกที่ยังไม่มีข้อมูล)
    if ($null -ne $script:LastFetchedData -and $script:LastFetchedData.Count -gt 0) {
        # ต้องมั่นใจว่าฟังก์ชันนี้โหลดมาแล้ว
        if (Get-Command "Update-FilteredView" -ErrorAction SilentlyContinue) {
            Update-FilteredView
        }
    }
}
$chkShowNo.Add_CheckedChanged($viewToggleEvent)
& $viewToggleEvent 
$grpSettings.Controls.Add($chkShowNo)


# ==============================================================================
# LINE 3: BANNER SELECTOR
# ==============================================================================
$lblBanner = New-Object System.Windows.Forms.Label
$lblBanner.Text = "Target Banner:"
$lblBanner.AutoSize = $true
$lblBanner.Location = New-Object System.Drawing.Point(15, 108)
$lblBanner.ForeColor = $script:Theme.TextSub
$grpSettings.Controls.Add($lblBanner)

$script:cmbBanner = New-Object System.Windows.Forms.ComboBox
$script:cmbBanner.Location = New-Object System.Drawing.Point(110, 105)
$script:cmbBanner.Size = New-Object System.Drawing.Size(425, 25) 
$script:cmbBanner.DropDownStyle = "DropDownList"
$script:cmbBanner.BackColor = [System.Drawing.Color]::FromArgb(45,45,45)
$script:cmbBanner.ForeColor = "White"
$script:cmbBanner.FlatStyle = "Flat"
$grpSettings.Controls.Add($script:cmbBanner)


# ============================
# EVENT HANDLERS
# ============================
# 2. File
$btnAuto.Add_Click({
    $conf = Get-GameConfig $script:CurrentGame
    WriteGUI-Log "Attempting to auto-detect data_2..." "Yellow"
    try {
        $found = Find-GameCacheFile -Config $conf -StagingPath $script:StagingFile
        $txtPath.Text = $found
        WriteGUI-Log "File found! Copied to Staging." "Lime"
    } catch {
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "Not Found", 0, 48)
        WriteGUI-Log "Auto-detect failed." "Red"
    }
})
$btnBrowse.Add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Filter = "data_2|data_2|All Files|*.*"
    if ($dlg.ShowDialog() -eq "OK") { $txtPath.Text = $dlg.FileName }
})

# ==========================================
#  EVENT: BANNER DROPDOWN CHANGE
# ==========================================
# เช็คก่อนว่าปุ่มมีตัวตนไหม (กัน Error แดง)
$script:cmbBanner.Add_SelectedIndexChanged({
    # 1. เช็คข้อมูล
    if ($null -eq $script:LastFetchedData -or $script:LastFetchedData.Count -eq 0) { return }

    # ==================================================
    # [ADD THIS] RESET UI INSTANTLY (กันเลขผิดโผล่)
    # ==================================================
    # สั่งให้หลอด Pity หดเหลือ 0 และขึ้นข้อความรอทันที
    $script:pnlPityFill.Width = 0
    $script:lblPityTitle.Text = "Updating..." 
    $script:lblPityTitle.ForeColor = "DimGray"
    
    # สั่งวาดหน้าจอทันที 1 รอบ (เพื่อให้ตาเห็นว่ามันถูกรีเซ็ตแล้ว)
    $form.Refresh() 
    # ==================================================

    # 2. เริ่มกระบวนการคำนวณ
    Reset-LogWindow
    $chart.Series.Clear()
    
    WriteGUI-Log "Switching view to: $($script:cmbBanner.SelectedItem)" "DimGray"
    
    # ฟังก์ชันนี้ใช้เวลาคำนวณนิดนึง...
    Update-FilteredView 
    
    # 3. พอคำนวณเสร็จ มันจะเอาเลขใหม่มาแปะแทนคำว่า "Updating..." เอง
    $form.Refresh()
})
