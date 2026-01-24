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
$lblFrom.Location = New-Object System.Drawing.Point(135, 24); $lblFrom.AutoSize = $true
$grpFilter.Controls.Add($lblFrom)

$dtpStart = New-Object System.Windows.Forms.DateTimePicker
$dtpStart.Location = New-Object System.Drawing.Point(175, 21); $dtpStart.Size = New-Object System.Drawing.Size(100, 23)
$dtpStart.Format = "Short"
$grpFilter.Controls.Add($dtpStart)

$lblTo = New-Object System.Windows.Forms.Label
$lblTo.Text = "To:"
$lblTo.Location = New-Object System.Drawing.Point(285, 24); $lblTo.AutoSize = $true
$grpFilter.Controls.Add($lblTo)

$dtpEnd = New-Object System.Windows.Forms.DateTimePicker
$dtpEnd.Location = New-Object System.Drawing.Point(310, 21); $dtpEnd.Size = New-Object System.Drawing.Size(100, 23)
$dtpEnd.Format = "Short"
$grpFilter.Controls.Add($dtpEnd)

# ============================================
#  LINE 2: MODES & ACTIONS (RE-DESIGNED)
# ============================================

# 3. Radio Buttons (Pity Mode)
$radModeAbs = New-Object System.Windows.Forms.RadioButton
$radModeAbs.Text = "True"
$radModeAbs.Location = New-Object System.Drawing.Point(15, 55); $radModeAbs.Size = New-Object System.Drawing.Size(50, 20)
$radModeAbs.Checked = $true
$grpFilter.Controls.Add($radModeAbs)

$radModeRel = New-Object System.Windows.Forms.RadioButton
$radModeRel.Text = "Reset"
$radModeRel.Location = New-Object System.Drawing.Point(70, 55); $radModeRel.Size = New-Object System.Drawing.Size(60, 20)
$grpFilter.Controls.Add($radModeRel)

# 4. Checkbox Sort (ลดขนาด)
$chkSortDesc = New-Object System.Windows.Forms.CheckBox
$chkSortDesc.Text = "Newest"
$chkSortDesc.Location = New-Object System.Drawing.Point(135, 55)
$chkSortDesc.Size = New-Object System.Drawing.Size(70, 20)
$chkSortDesc.Checked = $true
$chkSortDesc.ForeColor = "Gold"
$grpFilter.Controls.Add($chkSortDesc)

# 5. Buttons (จัดเรียงใหม่ 3 ปุ่ม)
# 5.1 Snap
$btnSmartSnap = New-Object System.Windows.Forms.Button
$btnSmartSnap.Text = "Snap Reset"
$btnSmartSnap.Location = New-Object System.Drawing.Point(215, 51)
$btnSmartSnap.Size = New-Object System.Drawing.Size(85, 28) # ลด size ลงนิดนึง
$btnSmartSnap.BackColor = "DimGray"; $btnSmartSnap.ForeColor = "White"
$btnSmartSnap.FlatStyle = "Flat"; $btnSmartSnap.FlatAppearance.BorderSize = 0
$grpFilter.Controls.Add($btnSmartSnap)

# 5.2 Discord (สีม่วง)
$btnDiscordScope = New-Object System.Windows.Forms.Button
$btnDiscordScope.Text = "Discord"
$btnDiscordScope.Location = New-Object System.Drawing.Point(310, 51) 
$btnDiscordScope.Size = New-Object System.Drawing.Size(100, 28)
$btnDiscordScope.BackColor = "Indigo"; $btnDiscordScope.ForeColor = "White"
$btnDiscordScope.FlatStyle = "Flat"; $btnDiscordScope.FlatAppearance.BorderSize = 0
$grpFilter.Controls.Add($btnDiscordScope)

# 5.3 [NEW] Email (สีเขียวเข้ม)
$btnEmailScope = New-Object System.Windows.Forms.Button
$btnEmailScope.Text = "Email Report"
$btnEmailScope.Location = New-Object System.Drawing.Point(420, 51) 
$btnEmailScope.Size = New-Object System.Drawing.Size(110, 28)
$btnEmailScope.BackColor = "DarkSlateGray"; $btnEmailScope.ForeColor = "White"
$btnEmailScope.FlatStyle = "Flat"; $btnEmailScope.FlatAppearance.BorderSize = 0
$grpFilter.Controls.Add($btnEmailScope)

if ($toolTip) {
    $toolTip.SetToolTip($btnSmartSnap, "Auto-set 'Start Date' to the day AFTER your last 5-Star pull.")
    $toolTip.SetToolTip($btnDiscordScope, "Send filtered report to Discord Webhook.")
    $toolTip.SetToolTip($btnEmailScope, "Send filtered report to your Email (HTML Table).")
}

# ==========================================
#  EVENT HANDLERS (INPUTS & UI)
# ==========================================

# 1. ปุ่มเปิด/ปิด Filter
$chkFilterEnable.Add_CheckedChanged({
    $status = if ($chkFilterEnable.Checked) { "ACTIVE" } else { "Disabled" }
    $grpFilter.Text = " Scope & Analysis ($status)"
    
    $dtpStart.Enabled = $chkFilterEnable.Checked
    $dtpEnd.Enabled   = $chkFilterEnable.Checked
    $radModeAbs.Enabled = $chkFilterEnable.Checked
    $radModeRel.Enabled = $chkFilterEnable.Checked
    $btnSmartSnap.Enabled = $chkFilterEnable.Checked
    # ปุ่มส่ง Report ให้กดได้ตลอด (ถ้ามีข้อมูล) หรือจะปิดตามก็ได้
    # $btnDiscordScope.Enabled = $chkFilterEnable.Checked 
    
    if (Get-Command "Update-FilteredView" -ErrorAction SilentlyContinue) {
        Update-FilteredView
    }
})

# 2. Trigger Update
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
    WriteGUI-Log "Discord Report Click..." "Cyan"
    Start-DiscordScopeReport
})

# 5. [NEW] ปุ่ม Email Scope
$btnEmailScope.Add_Click({
    WriteGUI-Log "Email Report Click..." "Cyan"
    Start-EmailScopeReport
})