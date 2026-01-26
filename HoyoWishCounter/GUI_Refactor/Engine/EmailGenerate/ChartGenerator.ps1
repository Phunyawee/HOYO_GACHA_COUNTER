# File: EmailGenerate/ChartGenerator.ps1

function Generate-ChartImage {
    param($DataList, $ChartType, $Config, $OutPath, [bool]$SortDesc)

    Add-Type -AssemblyName System.Windows.Forms.DataVisualization
    Add-Type -AssemblyName System.Drawing

    # 1. SETUP CHART & AREA (พื้นฐาน)
    $chart = New-Object System.Windows.Forms.DataVisualization.Charting.Chart
    $chart.Width = 900 
    $chart.Height = 500
    $chart.BackColor = [System.Drawing.Color]::FromArgb(30,30,30)
    
    $area = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea "Main"
    $area.BackColor = "Transparent"
    
    # Axis Styling (Default)
    $area.AxisX.LabelStyle.ForeColor = "Silver"
    $area.AxisX.LineColor = "#555"
    $area.AxisX.MajorGrid.LineColor = "#333"
    $area.AxisX.Interval = 1 
    $area.AxisX.LabelStyle.Angle = -45 
    $area.AxisX.LabelStyle.IsEndLabelVisible = $true
    
    $area.AxisY.LabelStyle.ForeColor = "Silver"
    $area.AxisY.LineColor = "#555"
    $area.AxisY.MajorGrid.LineColor = "#333"
    
    $chart.ChartAreas.Add($area)

    # =========================================================
    # TYPE A: RATE ANALYSIS (Doughnut) - PRO DESIGN
    # =========================================================
    if ($ChartType -eq "Rate Analysis") {
        # ปิดแกนเพราะเป็นกราฟวงกลม
        $area.AxisX.Enabled = "False"
        $area.AxisY.Enabled = "False"

        # คำนวณ
        $sRank = if ($Config.SRank) { $Config.SRank } else { "5" }
        $count5 = ($DataList | Where-Object { $_.rank_type -eq $sRank }).Count
        $count4 = ($DataList | Where-Object { $_.rank_type -eq "4" }).Count
        $count3 = $DataList.Count - $count5 - $count4

        # สร้าง Series ใหม่
        $series = New-Object System.Windows.Forms.DataVisualization.Charting.Series
        $series.Name = "Rates"
        $series.ChartType = "Doughnut" 
        $series.IsValueShownAsLabel = $true
        
        # Style
        $series["DoughnutRadius"] = "60" 
        $series["PieLabelStyle"] = "Outside" 
        $series["PieLineColor"] = "Gray"
        
        # --- 1. 5-Star (Gold) ---
        if ($count5 -gt 0) {
            $dp5 = New-Object System.Windows.Forms.DataVisualization.Charting.DataPoint(0, $count5)
            $dp5.Label = "#VALY" 
            $dp5.LegendText = "5-Star :  #VALY  (#PERCENT{P2})" 
            $dp5.Color = "Gold"
            $dp5.LabelForeColor = "Gold"
            $dp5.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
            $series.Points.Add($dp5) > $null
        }

        # --- 2. 4-Star (Purple) ---
        if ($count4 -gt 0) {
            $dp4 = New-Object System.Windows.Forms.DataVisualization.Charting.DataPoint(0, $count4)
            $dp4.Label = "#VALY"
            $dp4.LegendText = "4-Star :  #VALY  (#PERCENT{P2})"
            $dp4.Color = "MediumPurple"
            $dp4.LabelForeColor = "MediumPurple"
            $dp4.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
            $series.Points.Add($dp4) > $null
        }

        # --- 3. 3-Star (Blue) ---
        if ($count3 -gt 0) {
            $dp3 = New-Object System.Windows.Forms.DataVisualization.Charting.DataPoint(0, $count3)
            $dp3.Label = "#VALY"
            $dp3.LegendText = "3-Star :  #VALY  (#PERCENT{P2})"
            $dp3.Color = "DodgerBlue"
            $dp3.LabelForeColor = "DodgerBlue"
            $dp3.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
            $series.Points.Add($dp3) > $null
        }

        $chart.Series.Add($series)

        # Legend Styling (แบบ Pro Design)
        $leg = New-Object System.Windows.Forms.DataVisualization.Charting.Legend
        $leg.Name = "MainLegend"
        $leg.Docking = "Bottom"
        $leg.Alignment = "Center"
        $leg.BackColor = "Transparent"
        $leg.ForeColor = "Silver"
        $leg.Font = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Regular) 
        $chart.Legends.Add($leg)

        # Title
        $t = New-Object System.Windows.Forms.DataVisualization.Charting.Title
        $t.Text = "Drop Rate Analysis (Total: $($DataList.Count))"
        $t.ForeColor = "Silver"
        $t.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
        $t.Alignment = "TopLeft"
        $chart.Titles.Add($t)

    } else {
        # =========================================================
        # TYPE B: HISTORY (Bar/Line)
        # =========================================================
        $series = New-Object System.Windows.Forms.DataVisualization.Charting.Series "Data"
        $series.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)

        $series.ChartType = $ChartType 
        $series.IsValueShownAsLabel = $true
        $series.LabelForeColor = "White"
        
        if ($ChartType -match "Line|Spline") {
            $series.BorderWidth = 3; $series.Color = "White"; $series.MarkerStyle = "Circle"; $series.MarkerSize = 8
        } else {
            $series["PixelPointWidth"] = "30"
        }

        # Sort Logic
        $RawData = $DataList | Sort-Object Time | Select-Object -Last 15
        if ($SortDesc) {
            $DisplayData = $RawData | Sort-Object Time -Descending
        } else {
            $DisplayData = $RawData
        }
        
        foreach ($item in $DisplayData) {
            $labelName = "$($item.Name)"
            $ptIdx = $series.Points.AddXY($labelName, $item.Pity)
            $pt = $series.Points[$ptIdx]
            $pt.AxisLabel = $labelName
            
            $col = "LimeGreen"
            if ($item.Pity -ge 75) { $col = "Crimson" } elseif ($item.Pity -ge 50) { $col = "Gold" }
            
            if ($ChartType -match "Bar|Column") { $pt.Color = $col } else { $pt.MarkerColor = $col }
        }

        $chart.Series.Add($series)

        # Legend (History Style)
        $leg = New-Object System.Windows.Forms.DataVisualization.Charting.Legend
        $leg.Docking = "Bottom"; $leg.BackColor = "Transparent"; $leg.ForeColor = "Silver"
        $chart.Legends.Add($leg)

        # Title (History Style)
        $title = New-Object System.Windows.Forms.DataVisualization.Charting.Title
        $title.Text = "$ChartType Report"
        $title.ForeColor = "White"
        $title.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
        $chart.Titles.Add($title)
    }

    # Save
    $chart.SaveImage($OutPath, "Png")
    $chart.Dispose()
}