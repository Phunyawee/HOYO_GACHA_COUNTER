# views/FilterPanel.ps1

# ============================================
#  --- ROW 5: SCOPE & FILTER ---
# ============================================
$grpFilter = New-Object System.Windows.Forms.GroupBox
$grpFilter.Text = " Scope & Analysis (Time Machine) "
$grpFilter.Location = New-Object System.Drawing.Point(20, 430)
$grpFilter.Size = New-Object System.Drawing.Size(550, 95)
$grpFilter.ForeColor = "Silver"
$grpFilter.Enabled = $false # ปิดไว้ก่อน รอ Fetch เสร็จค่อยเปิด
$form.Controls.Add($grpFilter)

# ============================================
#  LINE 1: ENABLE & DATE PICKERS
# ============================================

# 1. Checkbox เปิด Filter
$chkFilterEnable = New-Object System.Windows.Forms.CheckBox
$chkFilterEnable.Text = "Enable Filter"
$chkFilterEnable.Location = New-Object System.Drawing.Point(15, 22)
$chkFilterEnable.Size = New-Object System.Drawing.Size(100, 20)
$chkFilterEnable.AutoSize = $true
$chkFilterEnable.ForeColor = $script:Theme.Accent
$chkFilterEnable.Cursor = [System.Windows.Forms.Cursors]::Hand
$grpFilter.Controls.Add($chkFilterEnable)

# 2. Date Pickers
$lblFrom = New-Object System.Windows.Forms.Label
$lblFrom.Text = "From:"
$lblFrom.Location = New-Object System.Drawing.Point(160, 24); $lblFrom.AutoSize = $true
$grpFilter.Controls.Add($lblFrom)

$dtpStart = New-Object System.Windows.Forms.DateTimePicker
$dtpStart.Location = New-Object System.Drawing.Point(200, 21); $dtpStart.Size = New-Object System.Drawing.Size(105, 23)
$dtpStart.Format = "Short"
$grpFilter.Controls.Add($dtpStart)

$lblTo = New-Object System.Windows.Forms.Label
$lblTo.Text = "To:"
$lblTo.Location = New-Object System.Drawing.Point(315, 24); $lblTo.AutoSize = $true
$grpFilter.Controls.Add($lblTo)

$dtpEnd = New-Object System.Windows.Forms.DateTimePicker
$dtpEnd.Location = New-Object System.Drawing.Point(340, 21); $dtpEnd.Size = New-Object System.Drawing.Size(105, 23)
$dtpEnd.Format = "Short"
$grpFilter.Controls.Add($dtpEnd)

# ============================================
#  LINE 2: MODES & ACTIONS
# ============================================

# 3. Radio Buttons (Pity Mode)
$radModeAbs = New-Object System.Windows.Forms.RadioButton
$radModeAbs.Text = "True Pity"
$radModeAbs.Location = New-Object System.Drawing.Point(15, 55); $radModeAbs.Size = New-Object System.Drawing.Size(75, 20)
$radModeAbs.Checked = $true
$grpFilter.Controls.Add($radModeAbs)

$radModeRel = New-Object System.Windows.Forms.RadioButton
$radModeRel.Text = "Reset (1)"
$radModeRel.Location = New-Object System.Drawing.Point(95, 55); $radModeRel.Size = New-Object System.Drawing.Size(75, 20)
$grpFilter.Controls.Add($radModeRel)

# 4. Checkbox Sort
$chkSortDesc = New-Object System.Windows.Forms.CheckBox
$chkSortDesc.Text = "Newest First"
$chkSortDesc.Location = New-Object System.Drawing.Point(175, 55)
$chkSortDesc.Size = New-Object System.Drawing.Size(100, 20)
$chkSortDesc.Checked = $true
$chkSortDesc.ForeColor = "Gold"
$grpFilter.Controls.Add($chkSortDesc)

# 5. Buttons
$btnSmartSnap = New-Object System.Windows.Forms.Button
$btnSmartSnap.Text = "Snap Reset"
$btnSmartSnap.Location = New-Object System.Drawing.Point(300, 51)
$btnSmartSnap.Size = New-Object System.Drawing.Size(100, 28)
$btnSmartSnap.BackColor = "DimGray"; $btnSmartSnap.ForeColor = "White"
$btnSmartSnap.FlatStyle = "Flat"; $btnSmartSnap.FlatAppearance.BorderSize = 0
$grpFilter.Controls.Add($btnSmartSnap)

$btnDiscordScope = New-Object System.Windows.Forms.Button
$btnDiscordScope.Text = "Discord Report"
$btnDiscordScope.Location = New-Object System.Drawing.Point(410, 51) 
$btnDiscordScope.Size = New-Object System.Drawing.Size(120, 28)
$btnDiscordScope.BackColor = "Indigo"; $btnDiscordScope.ForeColor = "White"
$btnDiscordScope.FlatStyle = "Flat"; $btnDiscordScope.FlatAppearance.BorderSize = 0
$grpFilter.Controls.Add($btnDiscordScope)

if ($toolTip) {
    $toolTip.SetToolTip($btnDiscordScope, "Manual Send: Sends a CUSTOM REPORT based on your current Date Filter and Sort settings.`nUseful for sharing specific pulls (e.g., 'My monthly pulls').")
}


# views/FilterPanel.ps1 (ส่วนท้ายสุด)

# ==========================================
#  EVENT HANDLERS (INPUTS & UI)
# ==========================================

# 1. ปุ่มเปิด/ปิด Filter (Logic UI ล้วนๆ ไว้ตรงนี้ได้)
$chkFilterEnable.Add_CheckedChanged({
    $status = if ($chkFilterEnable.Checked) { "ACTIVE" } else { "Disabled" }
    $grpFilter.Text = " Scope & Analysis ($status)"
    
    # เปิด/ปิดปุ่มย่อย
    $dtpStart.Enabled = $chkFilterEnable.Checked
    $dtpEnd.Enabled   = $chkFilterEnable.Checked
    $radModeAbs.Enabled = $chkFilterEnable.Checked
    $radModeRel.Enabled = $chkFilterEnable.Checked
    $btnSmartSnap.Enabled = $chkFilterEnable.Checked
    
    # เรียก Refresh หน้าจอ (ถ้ามีฟังก์ชันนี้)
    if (Get-Command "Update-FilteredView" -ErrorAction SilentlyContinue) {
        Update-FilteredView
    }
})

# 2. Trigger อัปเดตเมื่อมีการเปลี่ยนค่า (UI Interaction)
$triggerUpdate = { 
    if ($grpFilter.Enabled -and (Get-Command "Update-FilteredView" -ErrorAction SilentlyContinue)) { 
        Update-FilteredView 
    } 
}
$dtpStart.Add_ValueChanged($triggerUpdate)
$dtpEnd.Add_ValueChanged($triggerUpdate)
$radModeAbs.Add_CheckedChanged($triggerUpdate)
$radModeRel.Add_CheckedChanged($triggerUpdate)
$chkSortDesc.Add_CheckedChanged($triggerUpdate)


# ==========================================
#  BUTTON ACTIONS (เรียก MainLogic)
# ==========================================

# 3. ปุ่ม Snap Reset
$btnSmartSnap.Add_Click({
    Start-SmartSnap
})

# 4. ปุ่ม Discord Scope
$btnDiscordScope.Add_Click({
    Start-DiscordScopeReport
})