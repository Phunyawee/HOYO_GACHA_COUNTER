# =============================================================================
# FILE: SettingChild\07_TabEmail.ps1
# DESCRIPTION: UI Email Settings (Hybrid Preview: HTML + Native .NET Chart)
# =============================================================================

# Load Charting Assembly ให้มั่นใจว่าใช้ได้
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms.DataVisualization")

$script:tEmail = New-Tab "Email Report"
$EmailJsonPath = Join-Path $AppRoot "Settings\EmailForm.json"

# 1. LOAD CONFIG
$EmailConf = @{ 
    Style = "Premium Card"; SubjectPrefix = "Gacha Report"; 
    ContentType = "Table List"; ChartType = "Rate Analysis" 
}
if (Test-Path $EmailJsonPath) {
    try {
        $loaded = Get-Content $EmailJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($loaded.Style) { $EmailConf.Style = $loaded.Style }
        if ($loaded.SubjectPrefix) { $EmailConf.SubjectPrefix = $loaded.SubjectPrefix }
        if ($loaded.ContentType) { $EmailConf.ContentType = $loaded.ContentType }
        if ($loaded.ChartType) { $EmailConf.ChartType = $loaded.ChartType }
    } catch {}
}

# --- LEFT PANEL (Settings) ---
$grpStyle = New-Object System.Windows.Forms.GroupBox
$grpStyle.Text = " Report Settings "; $grpStyle.Location = "15, 15"; $grpStyle.Size = "200, 410"; $grpStyle.ForeColor = "Silver"
$script:tEmail.Controls.Add($grpStyle)

# Subject
$lblSubj = New-Object System.Windows.Forms.Label
$lblSubj.Text = "Subject Prefix:"; $lblSubj.Location = "15, 30"; $lblSubj.AutoSize = $true; $lblSubj.ForeColor = "White"
$grpStyle.Controls.Add($lblSubj)
$script:txtEmailSubj = New-Object System.Windows.Forms.TextBox
$script:txtEmailSubj.Location = "15, 50"; $script:txtEmailSubj.Width = 170; $script:txtEmailSubj.BorderStyle = "FixedSingle"
$script:txtEmailSubj.BackColor = [System.Drawing.Color]::FromArgb(60,60,60); $script:txtEmailSubj.ForeColor = "White"
$script:txtEmailSubj.Text = $EmailConf.SubjectPrefix
$grpStyle.Controls.Add($script:txtEmailSubj)

# Content Type
$lblType = New-Object System.Windows.Forms.Label
$lblType.Text = "Content Mode:"; $lblType.Location = "15, 85"; $lblType.AutoSize = $true; $lblType.ForeColor = "White"
$grpStyle.Controls.Add($lblType)
$script:cmbContentType = New-Object System.Windows.Forms.ComboBox
$script:cmbContentType.Location = "15, 105"; $script:cmbContentType.Width = 170; $script:cmbContentType.DropDownStyle = "DropDownList"
$script:cmbContentType.BackColor = [System.Drawing.Color]::FromArgb(60,60,60); $script:cmbContentType.ForeColor = "Lime"; $script:cmbContentType.FlatStyle = "Flat"
[void]$script:cmbContentType.Items.Add("Table List")
[void]$script:cmbContentType.Items.Add("Chart Snapshot")
if ($EmailConf.ContentType -eq "Chart Snapshot") { $script:cmbContentType.SelectedIndex = 1 } else { $script:cmbContentType.SelectedIndex = 0 }
$grpStyle.Controls.Add($script:cmbContentType)

# Theme Style
$lblStyle = New-Object System.Windows.Forms.Label
$lblStyle.Text = "Theme Style (Table Only):"; $lblStyle.Location = "15, 140"; $lblStyle.AutoSize = $true; $lblStyle.ForeColor = "White"
$grpStyle.Controls.Add($lblStyle)
$script:cmbEmailStyle = New-Object System.Windows.Forms.ComboBox
$script:cmbEmailStyle.Location = "15, 160"; $script:cmbEmailStyle.Width = 170; $script:cmbEmailStyle.DropDownStyle = "DropDownList"
$script:cmbEmailStyle.BackColor = [System.Drawing.Color]::FromArgb(60,60,60); $script:cmbEmailStyle.ForeColor = "Cyan"; $script:cmbEmailStyle.FlatStyle = "Flat"
$styles = @("Premium Card", "Classic Table", "Terminal Mode")
foreach ($s in $styles) { [void]$script:cmbEmailStyle.Items.Add($s) }
if ($styles -contains $EmailConf.Style) { $script:cmbEmailStyle.SelectedItem = $EmailConf.Style } else { $script:cmbEmailStyle.SelectedIndex = 0 }
$grpStyle.Controls.Add($script:cmbEmailStyle)

# Chart Type
$lblChart = New-Object System.Windows.Forms.Label
$lblChart.Text = "Chart Type (Chart Only):"; $lblChart.Location = "15, 195"; $lblChart.AutoSize = $true; $lblChart.ForeColor = "Gray"
$grpStyle.Controls.Add($lblChart)
$script:cmbChartOption = New-Object System.Windows.Forms.ComboBox
$script:cmbChartOption.Location = "15, 215"; $script:cmbChartOption.Width = 170; $script:cmbChartOption.DropDownStyle = "DropDownList"
$script:cmbChartOption.BackColor = [System.Drawing.Color]::FromArgb(60,60,60); $script:cmbChartOption.ForeColor = "White"; $script:cmbChartOption.FlatStyle = "Flat"
$chartTypes = @("Column", "Bar", "Spline", "Line", "Area", "StepLine", "Rate Analysis")
foreach ($c in $chartTypes) { [void]$script:cmbChartOption.Items.Add($c) }
if ($chartTypes -contains $EmailConf.ChartType) { $script:cmbChartOption.SelectedItem = $EmailConf.ChartType } else { $script:cmbChartOption.SelectedIndex = 6 }
$grpStyle.Controls.Add($script:cmbChartOption)


# --- RIGHT PANEL (PREVIEW CONTAINER) ---
$grpPreview = New-Object System.Windows.Forms.GroupBox
$grpPreview.Text = " Live Preview "; $grpPreview.Location = "230, 15"; $grpPreview.Size = "290, 410"; $grpPreview.ForeColor = "Silver"
$script:tEmail.Controls.Add($grpPreview)

# 1. WebBrowser Control (สำหรับ Table)
$wbPreview = New-Object System.Windows.Forms.WebBrowser
$wbPreview.Location = "10, 20"; $wbPreview.Size = "270, 380"; $wbPreview.ScrollBarsEnabled = $true; $wbPreview.ScriptErrorsSuppressed = $true
$grpPreview.Controls.Add($wbPreview)

# 2. Native Chart Control (สำหรับ Chart - ทับตำแหน่งเดียวกัน)
$chartPreview = New-Object System.Windows.Forms.DataVisualization.Charting.Chart
$chartPreview.Location = "10, 20"; $chartPreview.Size = "270, 380"
$chartPreview.BackColor = [System.Drawing.Color]::FromArgb(30,30,30)
$chartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
$chartArea.BackColor = "Transparent"
$chartArea.AxisX.LabelStyle.ForeColor = "Silver"
$chartArea.AxisY.LabelStyle.ForeColor = "Silver"
$chartArea.AxisX.LineColor = "Gray"; $chartArea.AxisY.LineColor = "Gray"
$chartArea.AxisX.MajorGrid.LineColor = "#444"; $chartArea.AxisY.MajorGrid.LineColor = "#444"
$chartPreview.ChartAreas.Add($chartArea)
$grpPreview.Controls.Add($chartPreview)


# =============================================================================
# LOGIC: HYBRID RENDERER
# =============================================================================
$UpdatePreview = {
    $selStyle = $script:cmbEmailStyle.SelectedItem
    $contentType = $script:cmbContentType.SelectedItem
    $chartType = $script:cmbChartOption.SelectedItem
    
    if ($contentType -eq "Table List") {
        # === MODE 1: HTML TABLE ===
        $chartPreview.Visible = $false
        $wbPreview.Visible = $true
        
        # HTML Rendering Logic
        $Meta = "<meta charset='utf-8'>"
        $tBody = "<tr><td style='padding:5px;'>10:05</td><td style='color:#FFD700;'>5* Raiden</td><td style='color:#0f0;'>76</td></tr>" +
                 "<tr><td style='padding:5px;'>10:04</td><td style='color:#aaa;'>3* Bow</td><td style='color:#aaa;'>08</td></tr>"
        
        $FinalHtml = ""
        switch ($selStyle) {
            "Premium Card" {
                $FinalHtml = "<html><head>$Meta<style>body{background:#1e1e1e;color:#eee;font-family:Segoe UI;padding:10px;}.card{background:#2d2d2d;border:1px solid #444;border-radius:4px;overflow:hidden;}</style></head>" +
                             "<body><div class='card'><div style='background:linear-gradient(90deg,#555,#222);padding:10px;'>Gacha Report</div>" +
                             "<table width='100%' style='border-collapse:collapse;margin:10px;'>$tBody</table></div></body></html>"
            }
            "Classic Table" {
                $FinalHtml = "<html><head>$Meta<style>body{background:#fff;color:#000;font-family:Tahoma;padding:10px;} table,th,td{border:1px solid #ccc;border-collapse:collapse;}</style></head>" +
                             "<body><h3>Report</h3><table width='100%'>$tBody</table></body></html>"
            }
            "Terminal Mode" {
                $FinalHtml = "<html><head>$Meta<style>body{background:#000;color:#0f0;font-family:Consolas;padding:10px;}</style></head>" +
                             "<body><div>> SYSTEM_READY</div><br><table width='100%' style='border:1px dashed #0f0;'>$tBody</table></body></html>"
            }
        }
        
        if ($wbPreview.Document) { $wbPreview.Document.OpenNew($true); $wbPreview.Document.Write($FinalHtml) }
        else { $wbPreview.Navigate("about:blank"); $wbPreview.Document.Write($FinalHtml) }

    } else {
        # === MODE 2: NATIVE CHART (REAL RENDERING) ===
        $wbPreview.Visible = $false
        $chartPreview.Visible = $true
        
        # Clear Old
        $chartPreview.Series.Clear()
        $chartPreview.Titles.Clear()
        $chartPreview.Legends.Clear()

        # Dummy Data for Preview
        $DummyData = @(
            @{Name="Raiden"; Pity=76; Time="10/05"},
            @{Name="Mona"; Pity=12; Time="05/04"},
            @{Name="Keqing"; Pity=80; Time="20/03"},
            @{Name="Qiqi"; Pity=45; Time="15/02"},
            @{Name="Diluc"; Pity=65; Time="01/01"}
        )

        # >>>>>> Copy Logic from User's Update-Chart <<<<<<

        if ($chartType -eq "Rate Analysis") {
            # --- DOUGHNUT / RATE ---
            $chartPreview.ChartAreas[0].AxisX.Enabled = "False"
            $chartPreview.ChartAreas[0].AxisY.Enabled = "False"
            
            $series = New-Object System.Windows.Forms.DataVisualization.Charting.Series
            $series.ChartType = "Doughnut"
            $series["DoughnutRadius"] = "60"
            $series["PieLabelStyle"] = "Outside"
            $series["PieLineColor"] = "Gray"
            
            # Mock Data Points
            $dp1 = $series.Points.Add(15); $dp1.Color = "Gold"; $dp1.Label = "5* (15%)"; $dp1.LegendText = "5-Star"
            $dp2 = $series.Points.Add(25); $dp2.Color = "MediumPurple"; $dp2.Label = "4* (25%)"; $dp2.LegendText = "4-Star"
            $dp3 = $series.Points.Add(60); $dp3.Color = "DodgerBlue"; $dp3.Label = "3* (60%)"; $dp3.LegendText = "3-Star"
            
            $chartPreview.Series.Add($series)

            # Title
            $t = New-Object System.Windows.Forms.DataVisualization.Charting.Title
            $t.Text = "Drop Rate Analysis (Preview)"; $t.ForeColor = "Silver"
            $chartPreview.Titles.Add($t)

            # Legend
            $leg = New-Object System.Windows.Forms.DataVisualization.Charting.Legend
            $leg.Docking = "Bottom"; $leg.Alignment = "Center"; $leg.BackColor = "Transparent"; $leg.ForeColor = "Silver"
            $chartPreview.Legends.Add($leg)

        } else {
            # --- NORMAL GRAPH ---
            $chartPreview.ChartAreas[0].AxisX.Enabled = "True"
            $chartPreview.ChartAreas[0].AxisY.Enabled = "True"
            $chartPreview.ChartAreas[0].AxisY.Title = "Pity Count"
            $chartPreview.ChartAreas[0].AxisX.LabelStyle.Enabled = $true # Show labels

            $series = New-Object System.Windows.Forms.DataVisualization.Charting.Series
            $series.ChartType = $chartType
            $series.IsValueShownAsLabel = $true
            $series.LabelForeColor = "White"

            if ($chartType -match "Line|Spline") {
                $series.BorderWidth = 3; $series.MarkerStyle = "Circle"; $series.MarkerSize = 8
            }

            foreach ($d in $DummyData) {
                $ptIdx = $series.Points.AddXY($d.Name, $d.Pity)
                $pt = $series.Points[$ptIdx]
                
                # Gradient Logic (Same as User's Code)
                if ($chartType -match "Column|Bar") {
                    $pt.BackGradientStyle = "TopBottom"
                    if ($d.Pity -gt 75) { $pt.Color = "Crimson"; $pt.BackSecondaryColor = "Maroon" }
                    elseif ($d.Pity -gt 50) { $pt.Color = "Gold"; $pt.BackSecondaryColor = "DarkGoldenrod" }
                    else { $pt.Color = "LimeGreen"; $pt.BackSecondaryColor = "DarkGreen" }
                } else {
                     $series.Color = "White"
                     if ($d.Pity -gt 75) { $pt.MarkerColor = "Red" } else { $pt.MarkerColor = "LimeGreen" }
                }
            }
            $chartPreview.Series.Add($series)
            
            $t = New-Object System.Windows.Forms.DataVisualization.Charting.Title
            $t.Text = "Pity History (Preview)"; $t.ForeColor = "Gold"
            $chartPreview.Titles.Add($t)
        }
    }
}

# --- CONTROL LOGIC ---
$script:cmbContentType.Add_SelectedIndexChanged({
    if ($script:cmbContentType.SelectedItem -eq "Table List") {
        $script:cmbEmailStyle.Enabled = $true; $lblStyle.ForeColor = "White"
        $script:cmbChartOption.Enabled = $false; $lblChart.ForeColor = "Gray"
    } else {
        $script:cmbEmailStyle.Enabled = $false; $lblStyle.ForeColor = "Gray"
        $script:cmbChartOption.Enabled = $true; $lblChart.ForeColor = "White"
    }
    & $UpdatePreview
})
$script:cmbChartOption.Add_SelectedIndexChanged($UpdatePreview)
$script:cmbEmailStyle.Add_SelectedIndexChanged($UpdatePreview)

# Init
$wbPreview.Navigate("about:blank")
while ($wbPreview.ReadyState -ne "Complete") { [System.Windows.Forms.Application]::DoEvents() }
$script:cmbContentType.SelectedIndex = $script:cmbContentType.SelectedIndex 

# Exports
$script:EmailStyleCmb = $script:cmbEmailStyle; $script:EmailSubjTxt = $script:txtEmailSubj
$script:EmailTypeCmb = $script:cmbContentType; $script:EmailChartCmb = $script:cmbChartOption
$script:EmailJsonPath = $EmailJsonPath