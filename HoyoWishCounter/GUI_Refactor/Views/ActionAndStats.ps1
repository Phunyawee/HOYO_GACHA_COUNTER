# views/ActionAndStats.ps1

# ============================================
#  --- ROW 4: CONTROL BUTTONS ---
# ============================================

# ปุ่ม START
$btnRun = New-Object System.Windows.Forms.Button
$btnRun.Text = "START FETCHING"
$btnRun.Location = New-Object System.Drawing.Point(20, 310)
$btnRun.Size = New-Object System.Drawing.Size(400, 45)
# (ต้องมั่นใจว่า Apply-ButtonStyle ถูกประกาศไว้ใน App.ps1 แล้ว)
Apply-ButtonStyle -Button $btnRun -BaseColorName "ForestGreen" -HoverColorName "LimeGreen" -CustomFont $script:fontHeader
$form.Controls.Add($btnRun)

# ปุ่ม STOP
$btnStop = New-Object System.Windows.Forms.Button
$btnStop.Text = "STOP"
$btnStop.Location = New-Object System.Drawing.Point(430, 310)
$btnStop.Size = New-Object System.Drawing.Size(140, 45)
$btnStop.BackColor = "Firebrick"
$btnStop.ForeColor = "White"
$btnStop.Font = $script:fontBold
$btnStop.FlatStyle = "Flat"
$btnStop.FlatAppearance.BorderSize = 0
$btnStop.Enabled = $false
$form.Controls.Add($btnStop)


# ============================================
#  --- ROW 4.5: STATS DASHBOARD ---
# ============================================
$grpStats = New-Object System.Windows.Forms.GroupBox
$grpStats.Text = " Luck Analysis (Based on fetched data) "
$grpStats.Location = New-Object System.Drawing.Point(20, 360)
$grpStats.Size = New-Object System.Drawing.Size(550, 60)
$grpStats.ForeColor = "Silver"
$form.Controls.Add($grpStats)

# 1. Total Pulls
$lblStat1 = New-Object System.Windows.Forms.Label
$lblStat1.Text = "Total: 0"
$lblStat1.AutoSize = $true
$lblStat1.Location = New-Object System.Drawing.Point(15, 25)
$lblStat1.Font = $script:fontNormal
$grpStats.Controls.Add($lblStat1)

# 2. Avg Pity
$script:lblStatAvg = New-Object System.Windows.Forms.Label
$script:lblStatAvg.Text = "Avg: -"
$script:lblStatAvg.AutoSize = $true
$script:lblStatAvg.Location = New-Object System.Drawing.Point(100, 25)
$script:lblStatAvg.Font = $script:fontBold
$script:lblStatAvg.ForeColor = "White"
$grpStats.Controls.Add($script:lblStatAvg)

# 3. Max / Min Pity
$script:lblExtremes = New-Object System.Windows.Forms.Label
$script:lblExtremes.Text = "Max: -  Min: -"
$script:lblExtremes.AutoSize = $true
$script:lblExtremes.Location = New-Object System.Drawing.Point(190, 25)
$script:lblExtremes.Font = $script:fontNormal
$script:lblExtremes.ForeColor = "Silver"
$grpStats.Controls.Add($script:lblExtremes)

# (ต้องมั่นใจว่า $toolTip ถูกประกาศไว้ใน App.ps1 แล้ว)
if ($toolTip) {
    $toolTip.SetToolTip($script:lblExtremes, "Historical Extremes:`nMax = Unluckiest Pity`nMin = Luckiest Pity")
}

# 4. Luck Grade
$script:lblLuckGrade = New-Object System.Windows.Forms.Label
$script:lblLuckGrade.Text = "Grade: -"
$script:lblLuckGrade.AutoSize = $true
$script:lblLuckGrade.Location = New-Object System.Drawing.Point(320, 25)
$script:lblLuckGrade.Font = $script:fontBold
$script:lblLuckGrade.ForeColor = "DimGray"
$script:lblLuckGrade.Cursor = [System.Windows.Forms.Cursors]::Help
$grpStats.Controls.Add($script:lblLuckGrade)

$gradeInfo = "Luck Grading Criteria (Global Standard):`n`n" +
                 "SS : Avg < 50   (Godlike)`n" +
                 " A : 50 - 60    (Lucky)`n" +
                 " B : 61 - 73    (Average)`n" +
                 " C : 74 - 76    (Salty)`n" +
                 " F : > 76       (Cursed)"
                 
if ($toolTip) {
    $toolTip.SetToolTip($script:lblLuckGrade, $gradeInfo)
}

# 5. Cost
$script:lblStatCost = New-Object System.Windows.Forms.Label
$script:lblStatCost.Text = "Cost: 0"
$script:lblStatCost.AutoSize = $true
$script:lblStatCost.Location = New-Object System.Drawing.Point(410, 25)
$script:lblStatCost.Font = $script:fontNormal
$script:lblStatCost.ForeColor = "Gold"
$grpStats.Controls.Add($script:lblStatCost)


# 3. Stop
$btnStop.Add_Click({
    Stop-MainProcess
})
# 5. START FETCHING
$btnRun.Add_Click({
    Start-MainProcess
})