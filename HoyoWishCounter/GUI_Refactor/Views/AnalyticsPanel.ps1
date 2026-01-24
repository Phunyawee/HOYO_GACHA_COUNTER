# views/AnalyticsPanel.ps1

# ============================================
#  SIDE PANEL: ANALYTICS GRAPH (Hidden Area)
# ============================================

# 1. Panel พื้นหลังกราฟ
$pnlChart = New-Object System.Windows.Forms.Panel
$pnlChart.Location = New-Object System.Drawing.Point(600, 24) # X=600, Y=24 (เว้น MenuBar)
$pnlChart.Size = New-Object System.Drawing.Size(480, 900) 
$pnlChart.BackColor = [System.Drawing.Color]::FromArgb(25, 25, 25) 
$pnlChart.Anchor = "Top, Bottom, Left, Right" # ให้ยืดหดตาม Form ได้
$form.Controls.Add($pnlChart)

# 2. ข้อความ No Data
$lblNoData = New-Object System.Windows.Forms.Label
$lblNoData.Text = "NO DATA AVAILABLE`n`nFetch data to see analytics."
$lblNoData.ForeColor = "DimGray"
$lblNoData.AutoSize = $false
$lblNoData.TextAlign = "MiddleCenter"
$lblNoData.Dock = "Fill" 
$lblNoData.Font = $script:fontHeader
$pnlChart.Controls.Add($lblNoData)

# 3. สร้าง Chart Object
$chart = New-Object System.Windows.Forms.DataVisualization.Charting.Chart
$chart.Dock = "Fill"
$chart.BackColor = "Transparent"
$chart.Visible = $false
$pnlChart.Controls.Add($chart)

# ============================================
#  CONTROLS (Combo & Button)
# ============================================

# 4. CHART TYPE SELECTOR
$cmbChartType = New-Object System.Windows.Forms.ComboBox
$cmbChartType.Items.AddRange(@("Column", "Bar", "Spline", "Line", "Area", "StepLine", "Rate Analysis"))
$cmbChartType.SelectedIndex = 0
$cmbChartType.Size = New-Object System.Drawing.Size(80, 25)
$cmbChartType.Anchor = "Top, Right"
$cmbChartType.Location = New-Object System.Drawing.Point(($pnlChart.Width - 90), 5)
$cmbChartType.DropDownStyle = "DropDownList"
$cmbChartType.BackColor = "DimGray"
$cmbChartType.ForeColor = "White"
$cmbChartType.FlatStyle = "Flat"
# ต้องมี $script:fontNormal ใน App.ps1 แล้ว
$cmbChartType.Font = $script:fontNormal 

$pnlChart.Controls.Add($cmbChartType)
$cmbChartType.BringToFront()

# 5. SAVE IMAGE BUTTON
$btnSaveImg = New-Object System.Windows.Forms.Button
$btnSaveImg.Text = "Save IMG"
$btnSaveImg.Size = New-Object System.Drawing.Size(80, 25)
$btnSaveImg.Location = New-Object System.Drawing.Point(($pnlChart.Width - 175), 5) 
$btnSaveImg.Anchor = "Top, Right"
$btnSaveImg.BackColor = "Indigo"
$btnSaveImg.ForeColor = "White"
$btnSaveImg.FlatStyle = "Flat"
$btnSaveImg.FlatAppearance.BorderSize = 0
$btnSaveImg.Font = $script:fontNormal
$btnSaveImg.Cursor = [System.Windows.Forms.Cursors]::Hand

$pnlChart.Controls.Add($btnSaveImg)
$btnSaveImg.BringToFront()

# ============================================
#  CHART STYLING
# ============================================
$chartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
$chartArea.Name = "MainArea"
$chartArea.BackColor = "Transparent"

# แกน X
$chartArea.AxisX.LabelStyle.ForeColor = "Silver"
$chartArea.AxisX.LineColor = "Gray"
$chartArea.AxisX.MajorGrid.LineColor = [System.Drawing.Color]::FromArgb(30, 255, 255, 255)
$chartArea.AxisX.Interval = 1 
$chartArea.AxisX.LabelStyle.Angle = -45

# แกน Y
$chartArea.AxisY.LabelStyle.ForeColor = "Silver"
$chartArea.AxisY.LineColor = "Gray"
$chartArea.AxisY.MajorGrid.LineColor = [System.Drawing.Color]::FromArgb(30, 255, 255, 255)
$chartArea.AxisY.Maximum = 90 
$chartArea.AxisY.Title = "Pity Count"
$chartArea.AxisY.TitleForeColor = "Gray"

$chart.ChartAreas.Add($chartArea)

# Title
$title = New-Object System.Windows.Forms.DataVisualization.Charting.Title
$title.Text = "5-Star Pity History"
$title.ForeColor = "Gold"
$title.Font = $script:fontHeader
$chart.Titles.Add($title)


# ============================================
#  EVENT HANDLERS
# ============================================

# เมื่อเลือกประเภทกราฟ
$cmbChartType.Add_SelectedIndexChanged({ 
    $type = $cmbChartType.SelectedItem
    WriteGUI-Log "User switched chart view to: [$type]" "DimGray"
    
    # เรียกฟังก์ชัน Update-Chart (ต้องมีใน ChartLogic.ps1 หรือ MainLogic.ps1)
    if ($chart.Visible) { 
        if (Get-Command "Update-Chart" -ErrorAction SilentlyContinue) {
            Update-Chart -DataList $script:CurrentChartData 
        }
    }
})

# เมื่อกดปุ่ม Save IMG (เรียก Logic จาก Controller)
$btnSaveImg.Add_Click({
    Start-AdvancedSaveImage
})