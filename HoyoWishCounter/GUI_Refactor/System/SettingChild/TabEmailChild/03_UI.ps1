# FILE: SettingChild\TabEmailChild\03_UI.ps1
# DESCRIPTION: UI Construction & Event Binding (With Full Chart Logic)

# --- LEFT PANEL (Settings) ---
$grpStyle = New-Object System.Windows.Forms.GroupBox
$grpStyle.Text = " Report Settings "; $grpStyle.Location = "15, 15"; $grpStyle.Size = "200, 410"; $grpStyle.ForeColor = "Silver"
$script:tEmail.Controls.Add($grpStyle)

# Helper for Components
function Add-Ctrl ($Type, $Target, $Text, $Loc, $W, $DefVal) {
    if ($Type -eq "Label") {
        $l = New-Object System.Windows.Forms.Label; $l.Text=$Text; $l.Location=$Loc; $l.AutoSize=$true; $l.ForeColor="White"
        $Target.Controls.Add($l); return $l
    } elseif ($Type -eq "TextBox") {
        $t = New-Object System.Windows.Forms.TextBox; $t.Location=$Loc; $t.Width=$W; $t.BorderStyle="FixedSingle"; $t.BackColor=[System.Drawing.Color]::FromArgb(60,60,60); $t.ForeColor="White"; $t.Text=$DefVal
        $Target.Controls.Add($t); return $t
    } elseif ($Type -eq "Combo") {
        $c = New-Object System.Windows.Forms.ComboBox; $c.Location=$Loc; $c.Width=$W; $c.DropDownStyle="DropDownList"; $c.BackColor=[System.Drawing.Color]::FromArgb(60,60,60); $c.ForeColor="Cyan"; $c.FlatStyle="Flat"
        foreach($i in $DefVal) { [void]$c.Items.Add($i) }
        $Target.Controls.Add($c); return $c
    }
}

# 1. Subject
Add-Ctrl "Label" $grpStyle "Subject Prefix:" "15, 30" $null $null
$script:txtEmailSubj = Add-Ctrl "TextBox" $grpStyle $null "15, 50" 170 $EmailConf.SubjectPrefix

# 2. Content Type
$lblType = Add-Ctrl "Label" $grpStyle "Content Mode:" "15, 85" $null $null
$script:cmbContentType = Add-Ctrl "Combo" $grpStyle $null "15, 105" 170 @("Table List", "Chart Snapshot")
if ($EmailConf.ContentType -eq "Chart Snapshot") { $script:cmbContentType.SelectedIndex = 1 } else { $script:cmbContentType.SelectedIndex = 0 }
$script:cmbContentType.ForeColor = "Lime"

# 3. Style (List)
$lblStyle = Add-Ctrl "Label" $grpStyle "Theme Style (10 Types):" "15, 140" $null $null
$styles = @("Universal Card","Classic Table","Terminal Mode","Modern Dark","Minimalist White","Cyber Neon","Blueprint","Vintage Log","Excel Sheet","Gacha Pop")
$script:cmbEmailStyle = Add-Ctrl "Combo" $grpStyle $null "15, 160" 170 $styles
if ($styles -contains $EmailConf.Style) { $script:cmbEmailStyle.SelectedItem = $EmailConf.Style } else { $script:cmbEmailStyle.SelectedIndex = 0 }

# 4. Chart Type
$lblChart = Add-Ctrl "Label" $grpStyle "Chart Type (Chart Only):" "15, 195" $null $null
$chartTypes = @("Column", "Bar", "Spline", "Line", "Area", "StepLine", "Rate Analysis")
$script:cmbChartOption = Add-Ctrl "Combo" $grpStyle $null "15, 215" 170 $chartTypes
if ($chartTypes -contains $EmailConf.ChartType) { $script:cmbChartOption.SelectedItem = $EmailConf.ChartType } else { $script:cmbChartOption.SelectedIndex = 6 }
$script:cmbChartOption.ForeColor = "White"

# --- RIGHT PANEL (Preview) ---
$grpPreview = New-Object System.Windows.Forms.GroupBox
$grpPreview.Text = " Live Preview "; $grpPreview.Location = "230, 15"; $grpPreview.Size = "290, 410"; $grpPreview.ForeColor = "Silver"
$script:tEmail.Controls.Add($grpPreview)

# WebBrowser (For HTML)
$wbPreview = New-Object System.Windows.Forms.WebBrowser
$wbPreview.Location = "10, 20"; $wbPreview.Size = "270, 380"; $wbPreview.ScrollBarsEnabled = $true; $wbPreview.ScriptErrorsSuppressed = $true
$grpPreview.Controls.Add($wbPreview)

# Chart (For Graphs)
$chartPreview = New-Object System.Windows.Forms.DataVisualization.Charting.Chart
$chartPreview.Location = "10, 20"; $chartPreview.Size = "270, 380"; $chartPreview.BackColor = [System.Drawing.Color]::FromArgb(30,30,30)
$chartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
$chartArea.BackColor = "Transparent"
$chartArea.AxisX.LabelStyle.ForeColor = "Silver"; $chartArea.AxisY.LabelStyle.ForeColor = "Silver"
$chartArea.AxisX.LineColor = "Gray"; $chartArea.AxisY.LineColor = "Gray"
$chartArea.AxisX.MajorGrid.LineColor = "#444"; $chartArea.AxisY.MajorGrid.LineColor = "#444"
$chartPreview.ChartAreas.Add($chartArea)
$grpPreview.Controls.Add($chartPreview)

# --- LOGIC: UPDATE PREVIEW ---
$UpdatePreview = {
    $selStyle = $script:cmbEmailStyle.SelectedItem
    $contentType = $script:cmbContentType.SelectedItem
    $chartType = $script:cmbChartOption.SelectedItem
    
    if ($contentType -eq "Table List") {
        # === MODE 1: HTML TABLE ===
        $chartPreview.Visible = $false; $wbPreview.Visible = $true
        $script:cmbEmailStyle.Enabled = $true; $lblStyle.ForeColor = "White"
        $script:cmbChartOption.Enabled = $false; $lblChart.ForeColor = "Gray"
        
        $tRows = "<tr><td class='c1' style='padding:5px;'>10:05</td><td class='c2' style='color:#FFD700;'>5* Raiden</td><td class='c3' style='color:#0f0;'>76</td></tr>" +
                 "<tr><td class='c1' style='padding:5px;'>10:04</td><td class='c2' style='color:#aaa;'>3* Bow</td><td class='c3' style='color:#aaa;'>08</td></tr>" + 
                 "<tr><td class='c1' style='padding:5px;'>10:03</td><td class='c2' style='color:#bd8eff;'>4* Kuki</td><td class='c3' style='color:#bd8eff;'>02</td></tr>"

        # Call HTML Generator from 02_Styles.ps1 (Refactoring Benefit: Clean Code Here)
        $BodyHTML = Get-EmailHtmlBody -StyleName $selStyle -RowsHTML $tRows
        
        if ($wbPreview.Document) { $wbPreview.Document.OpenNew($true); $wbPreview.Document.Write($BodyHTML) }
        else { $wbPreview.Navigate("about:blank"); $wbPreview.Document.Write($BodyHTML) }

    } else {
        # === MODE 2: NATIVE CHART (FULL LOGIC) ===
        $wbPreview.Visible = $false; $chartPreview.Visible = $true
        $script:cmbEmailStyle.Enabled = $false; $lblStyle.ForeColor = "Gray"
        $script:cmbChartOption.Enabled = $true; $lblChart.ForeColor = "White"
        
        $chartPreview.Series.Clear(); $chartPreview.Titles.Clear(); $chartPreview.Legends.Clear()
        
        # Dummy Data for Full Logic
        $DummyData = @(
            @{Name="Raiden"; Pity=76; Time="10/05"},
            @{Name="Mona"; Pity=12; Time="05/04"},
            @{Name="Keqing"; Pity=80; Time="20/03"},
            @{Name="Qiqi"; Pity=45; Time="15/02"},
            @{Name="Diluc"; Pity=65; Time="01/01"}
        )

        if ($chartType -eq "Rate Analysis") {
            # --- RATE ANALYSIS ---
            $chartPreview.ChartAreas[0].AxisX.Enabled = "False"; $chartPreview.ChartAreas[0].AxisY.Enabled = "False"
            $series = New-Object System.Windows.Forms.DataVisualization.Charting.Series
            $series.ChartType = "Doughnut"; $series["DoughnutRadius"] = "60"; $series["PieLineColor"] = "Gray"
            $series["PieLabelStyle"] = "Outside"

            $p1 = $series.Points.Add(15); $p1.Color = "Gold"; $p1.Label = "5* (15%)"; $p1.LegendText = "5-Star"
            $p2 = $series.Points.Add(25); $p2.Color = "MediumPurple"; $p2.Label = "4* (25%)"; $p2.LegendText = "4-Star"
            $p3 = $series.Points.Add(60); $p3.Color = "DodgerBlue"; $p3.Label = "3* (60%)"; $p3.LegendText = "3-Star"
            $chartPreview.Series.Add($series)
            
            $t = New-Object System.Windows.Forms.DataVisualization.Charting.Title
            $t.Text = "Drop Rate Analysis (Preview)"; $t.ForeColor = "Silver"; $chartPreview.Titles.Add($t)

            $leg = New-Object System.Windows.Forms.DataVisualization.Charting.Legend
            $leg.Docking = "Bottom"; $leg.Alignment = "Center"; $leg.BackColor = "Transparent"; $leg.ForeColor = "Silver"
            $chartPreview.Legends.Add($leg)

        } else {
            # --- HISTORY CHART ---
            $chartPreview.ChartAreas[0].AxisX.Enabled = "True"; $chartPreview.ChartAreas[0].AxisY.Enabled = "True"
            $chartPreview.ChartAreas[0].AxisY.Title = "Pity Count"
            
            $series = New-Object System.Windows.Forms.DataVisualization.Charting.Series
            $series.ChartType = $chartType
            $series.IsValueShownAsLabel = $true; $series.LabelForeColor = "White"

            if ($chartType -match "Line|Spline") { 
                $series.BorderWidth = 3; $series.MarkerStyle = "Circle"; $series.MarkerSize = 8 
            }

            foreach ($d in $DummyData) {
                $idx = $series.Points.AddXY($d.Name, $d.Pity)
                $pt = $series.Points[$idx]
                
                # COLOR LOGIC (Gradient & Pity Check)
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
            $t.Text = "Pity History (Preview)"; $t.ForeColor = "Gold"; $chartPreview.Titles.Add($t)
        }
    }
}

# EVENTS
$script:cmbContentType.Add_SelectedIndexChanged($UpdatePreview)
$script:cmbChartOption.Add_SelectedIndexChanged($UpdatePreview)
$script:cmbEmailStyle.Add_SelectedIndexChanged($UpdatePreview)

# Init
$wbPreview.Navigate("about:blank")
while ($wbPreview.ReadyState -ne "Complete") { [System.Windows.Forms.Application]::DoEvents() }
& $UpdatePreview

# EXPORTS
$script:EmailStyleCmb = $script:cmbEmailStyle
$script:EmailSubjTxt = $script:txtEmailSubj
$script:EmailTypeCmb = $script:cmbContentType
$script:EmailChartCmb = $script:cmbChartOption