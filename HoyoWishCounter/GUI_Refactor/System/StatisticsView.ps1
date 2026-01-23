# ==========================================
#  CORE LOGIC: UPDATE VIEW (GUI & LOG)
# ==========================================
# ตัวแปร Global (ประกาศไว้นอกฟังก์ชันเพื่อให้แน่ใจว่ามีอยู่จริง)
$script:FilteredData = @()
$script:CurrentChartData = @()

function Update-FilteredView {
    # ถ้ายังไม่มีข้อมูลดิบ ให้จบไป
    if ($null -eq $script:LastFetchedData -or $script:LastFetchedData.Count -eq 0) { return }

    $conf = Get-GameConfig $script:CurrentGame
    
    # [MOVED] ย้าย Reset มาไว้บนสุดเลย เพื่อเคลียร์หน้าจอรอก่อน
    Reset-LogWindow 

    # =========================================================
    # 1. PREPARE DATA & HEADER MESSAGE
    # =========================================================
    
    $headerMsg = "" # ตัวแปรเก็บข้อความหัวเรื่อง
    
    # 1.1 กรองวันที่ (Date Filter)
    if ($script:chkFilterEnable.Checked) {
        $startDate = $script:dtpStart.Value.Date
        $endDate = $script:dtpEnd.Value.Date.AddDays(1).AddSeconds(-1)
        
        $tempData = $script:LastFetchedData | Where-Object { 
            [DateTime]$_.time -ge $startDate -and [DateTime]$_.time -le $endDate 
        }
        # เก็บข้อความไว้ก่อน (ยังไม่พิมพ์)
        $headerMsg = "--- FILTERED VIEW ($($startDate.ToString('yyyy-MM-dd')) to $($endDate.ToString('yyyy-MM-dd'))) ---"
    } else {
        $tempData = $script:LastFetchedData
        # เก็บข้อความไว้ก่อน
        $headerMsg = "--- FULL HISTORY VIEW ---"
    }

    # 1.2 [NEW] กรองประเภทตู้ (Banner Type Filter)
    $selectedBanner = $script:cmbBanner.SelectedItem

    if ($selectedBanner -ne "* FETCH ALL (Recommended)" -and $null -ne $selectedBanner) {
        $targetBannerObj = $conf.Banners | Where-Object { $_.Name -eq $selectedBanner }
        
        if ($targetBannerObj) {
            $targetCode = $targetBannerObj.Code
            
            # GENSHIN SPECIAL: 301 ต้องรวม 400
            if ($script:CurrentGame -eq "Genshin" -and $targetCode -eq "301") {
                $tempData = $tempData | Where-Object { $_.gacha_type -eq "301" -or $_.gacha_type -eq "400" }
                Log "View Scope: Character Event Only" "Gray"
            } 
            else {
                # ZZZ/HSR/Weapon
                $tempData = $tempData | Where-Object { 
                    "$($_.gacha_type)" -eq "$targetCode"
                }
                Log "View Scope: $selectedBanner Only" "Gray"
            }

            # [FIXED] ย้ายมาไว้ตรงนี้! (ทำงานกับทุกตู้ ไม่ว่าจะ Genshin Char หรือตู้ไหนๆ)
            $headerMsg += " [$selectedBanner Only]"
        }
    }

    $script:FilteredData = $tempData

    # =========================================================
    # 2. STATS (เหมือนเดิม)
    # =========================================================
    $totalPulls = $script:FilteredData.Count
    $script:lblStat1.Text = "Total Pulls: $totalPulls"
    
    $cost = $totalPulls * 160
    $currencyName = if ($script:CurrentGame -eq "HSR") { "Jades" } elseif ($script:CurrentGame -eq "ZZZ") { "Polychromes" } else { "Primos" }
    $script:lblStatCost.Text = "Est. Cost: $(" {0:N0}" -f $cost) $currencyName"

    # =========================================================
    # 3. PREPARE PITY (เหมือนเดิม)
    # =========================================================
    $sortedItems = $script:FilteredData | Sort-Object { [decimal]$_.id } 
    $pityTrackers = @{} 
    foreach ($b in $conf.Banners) { $pityTrackers[$b.Code] = 0 }

    if ($script:chkFilterEnable.Checked -and $script:radModeAbs.Checked) {
        if ($sortedItems.Count -gt 0) {
            $firstItemInScope = $sortedItems[0]
            $allHistorySorted = $script:LastFetchedData | Sort-Object { [decimal]$_.id }
            foreach ($item in $allHistorySorted) {
                if ($item.id -eq $firstItemInScope.id) { break }
                $code = "$($item.gacha_type)".Trim()
                if ($script:CurrentGame -eq "Genshin" -and $code -eq "400") { $code = "301" }
                if (-not $pityTrackers.ContainsKey($code)) { $pityTrackers[$code] = 0 }
                $pityTrackers[$code]++
                if ($item.rank_type -eq $conf.SRank) { $pityTrackers[$code] = 0 }
            }
        }
    }

    # =========================================================
    # 4. CALCULATION LOOP (เหมือนเดิม)
    # =========================================================
    $highRankCount = 0
    $pitySum = 0
    $displayList = @()
    $localMax = 0
    $localMin = 100
    
    foreach ($item in $sortedItems) {
        $code = "$($item.gacha_type)".Trim()
        
        if ($script:CurrentGame -eq "Genshin" -and $code -eq "400") { $code = "301" }
        if (-not $pityTrackers.ContainsKey($code)) { $pityTrackers[$code] = 0 }

        $pityTrackers[$code]++
        
        if ($item.rank_type -eq $conf.SRank) {
            $highRankCount++
            $currentVal = $pityTrackers[$code]
            $pitySum += $currentVal
            
            if ($currentVal -gt $localMax) { $localMax = $currentVal }
            if ($currentVal -lt $localMin) { $localMin = $currentVal }
            
            $displayList += [PSCustomObject]@{
                Time = $item.time
                Name = $item.name
                Banner = $item._BannerName
                Pity = $currentVal
            }
            $pityTrackers[$code] = 0 
        }
    }

    # =========================================================
    # 5. STATS DISPLAY (เหมือนเดิม)
    # =========================================================
    if ($highRankCount -gt 0) {
        $avg = $pitySum / $highRankCount
        $script:lblStatAvg.Text = "Avg: $(" {0:N2}" -f $avg)"
        
        if ($avg -le 55) { $script:lblStatAvg.ForeColor = "Lime" }
        elseif ($avg -le 73) { $script:lblStatAvg.ForeColor = "Gold" }
        else { $script:lblStatAvg.ForeColor = "OrangeRed" }

        $script:lblExtremes.Text = "Max: $localMax  Min: $localMin"
        if ($localMax -ge 80) { $script:lblExtremes.ForeColor = "Salmon" } else { $script:lblExtremes.ForeColor = "Silver" }

        $grade = ""; $gColor = "White"
        if ($avg -lt 50)     { $grade = "SS"; $gColor = "Cyan" }
        elseif ($avg -le 60) { $grade = "A";  $gColor = "Lime" }
        elseif ($avg -le 73) { $grade = "B";  $gColor = "Gold" }
        elseif ($avg -le 76) { $grade = "C";  $gColor = "Orange" }
        else                 { $grade = "F";  $gColor = "Red" }
        
        $script:lblLuckGrade.Text = "Grade: $grade"
        $script:lblLuckGrade.ForeColor = $gColor

    } else {
        $script:lblStatAvg.Text = "Avg: -"
        $script:lblStatAvg.ForeColor = "White"
        $script:lblExtremes.Text = "Max: -  Min: -"
        $script:lblExtremes.ForeColor = "DimGray"
        $script:lblLuckGrade.Text = "Grade: -"
        $script:lblLuckGrade.ForeColor = "DimGray"
    }

    # =========================================================
    # [FIXED] 6. RENDERING PHASE (Freeze -> Header -> Content)
    # =========================================================
    
    # ล้างอีกทีเพื่อความชัวร์ (เพราะบางที Write-GuiLogข้างบนอาจจะพ่นอะไรออกมา)
    Reset-LogWindow 
    
    if ($displayList.Count -gt 0) {
        
        $script:txtLog.SuspendLayout()
        
        # [NEW] พิมพ์ Header ที่เราเก็บไว้ตอนแรก
        $script:txtLog.SelectionColor = "Cyan"
        $script:txtLog.AppendText("$headerMsg`n")
        
        # Helper: Print Line
        function Print-Line($h, $idx) {
            $pColor = "Lime"
            if ($h.Pity -gt 75) { $pColor = "Red" } elseif ($h.Pity -gt 50) { $pColor = "Yellow" }
            
            $nameColor = "Gold"
            $isStandardChar = $false
            switch ($script:CurrentGame) {
                "Genshin" { if ($h.Name -match "^(Diluc|Jean|Mona|Qiqi|Keqing|Tighnari|Dehya)$") { $isStandardChar = $true } }
                "HSR"     { if ($h.Name -match "^(Himeko|Welt|Bronya|Gepard|Clara|Yanqing|Bailu)$") { $isStandardChar = $true } }
                "ZZZ"     { if ($h.Name -match "^(Grace|Rina|Koleda|Nekomata|Soldier 11|Lycaon)$") { $isStandardChar = $true } }
            }
            $isNotEventBanner = ($h.Banner -match "Standard|Novice|Weapon|Light Cone|W-Engine|Bangboo")
            if ($isStandardChar -and (-not $isNotEventBanner)) { $nameColor = "Crimson" }

            $prefix = if ($script:chkShowNo.Checked) { "[No.$idx] ".PadRight(12) } else { "[$($h.Time)] " }
            
            $script:txtLog.SelectionColor = "Gray"; $script:txtLog.AppendText($prefix)
            $script:txtLog.SelectionColor = $nameColor; $script:txtLog.AppendText("$($h.Name.PadRight(18)) ")
            $script:txtLog.SelectionColor = $pColor; $script:txtLog.AppendText("Pity: $($h.Pity)`n")
        }

        $chartData = @()
        if ($script:chkSortDesc.Checked) {
            for ($i = $displayList.Count - 1; $i -ge 0; $i--) {
                Print-Line -h $displayList[$i] -idx ($i+1)
                $chartData += $displayList[$i]
            }
        } else {
            for ($i = 0; $i -lt $displayList.Count; $i++) {
                Print-Line -h $displayList[$i] -idx ($i+1)
                $chartData += $displayList[$i]
            }
        }
        
        $script:txtLog.ResumeLayout()
        $script:txtLog.SelectionStart = 0
        $script:txtLog.ScrollToCaret()
        
        Update-Chart -DataList $chartData

    } else {
        # กรณีไม่มี 5 ดาวเลย
        $script:txtLog.SelectionColor = "Cyan"
        $script:txtLog.AppendText("$headerMsg`n")
        $script:txtLog.SelectionColor = "Gray"
        $script:txtLog.AppendText("No 5-Star items found in this range/banner.`n")
        
        Update-Chart -DataList @()
    }
    
    # 7. Update Window Title & Dynamic Pity Meter
    # ... (ส่วน Pity Meter และ Window Title คงเดิม) ...
    $pitySource = $script:FilteredData | Sort-Object { [decimal]$_.id } -Descending
    $currentPity = 0
    $latestType = "301"
    if ($pitySource.Count -gt 0) {
        $latestType = "$($pitySource[0].gacha_type)".Trim()
        foreach ($row in $pitySource) {
            if ($row.rank_type -eq $conf.SRank) { break }
            $currentPity++
        }
    }
    
    $maxPity = 90
    $typeLabel = "Character"
    if ($latestType -match "^(302|12|3|5)$") { $maxPity = 80; $typeLabel = "Weapon/LC" }
    
    $percent = 0
    if ($maxPity -gt 0) { $percent = $currentPity / $maxPity }
    if ($percent -gt 1) { $percent = 1 }
    $newWidth = [int](550 * $percent)
    
    $script:pnlPityFill.Width = $newWidth
    $script:lblPityTitle.Text = "Current Pity ($typeLabel): $currentPity / $maxPity"
    
    if ($percent -ge 0.82) { $script:pnlPityFill.BackColor = "Crimson"; $script:lblPityTitle.ForeColor = "Red" }
    elseif ($percent -ge 0.55) { $script:pnlPityFill.BackColor = "Gold"; $script:lblPityTitle.ForeColor = "Gold" }
    else { $script:pnlPityFill.BackColor = "DodgerBlue"; $script:lblPityTitle.ForeColor = "White" }

    $dbStatus = "Infinity DB"
    if ($script:chkFilterEnable.Checked) { $dbStatus = "Filtered View" }
    $totalRecords = $script:LastFetchedData.Count
    $viewRecords = 0
    if ($script:FilteredData) { $viewRecords = $script:FilteredData.Count }
    
    $script:form.Text = "Universal Hoyo Wish Counter v$script:AppVersion | $dbStatus | Showing: $viewRecords / $totalRecords pulls"
    
    $script:form.Refresh()
}

function Update-Chart {
    param($DataList)

    # 0. Caching Data
    if ($null -ne $DataList) { $script:CurrentChartData = $DataList }
    else { $DataList = $script:CurrentChartData }

    # 1. Clear กราฟเก่า
    $script:chart.Series.Clear()
    $script:chart.Titles.Clear()
    $script:chart.Legends.Clear() # [สำคัญ] ลบ Legend เก่าทิ้งด้วย
    
    $typeStr = $script:cmbChartType.SelectedItem
    if ($null -eq $typeStr) { $typeStr = "Column" }

    # ==================================================
    # CASE A: RATE ANALYSIS (Doughnut Chart) - PRO DESIGN
    # ==================================================
    if ($typeStr -eq "Rate Analysis") {
        $script:chart.Visible = $true; $script:lblNoData.Visible = $false

        $sourceData = $script:FilteredData
        if ($null -eq $sourceData -or $sourceData.Count -eq 0) { return }

        $conf = Get-GameConfig $script:CurrentGame
        $count5 = ($sourceData | Where-Object { $_.rank_type -eq $conf.SRank }).Count
        $count4 = ($sourceData | Where-Object { $_.rank_type -eq "4" }).Count
        $count3 = $sourceData.Count - $count5 - $count4

        $series = New-Object System.Windows.Forms.DataVisualization.Charting.Series
        $series.Name = "Rates"
        $series.ChartType = "Doughnut" # <--- เปลี่ยนเป็นโดนัท ดูแพงกว่า
        $series.IsValueShownAsLabel = $true
        
        # ตั้งค่าโดนัท
        $series["DoughnutRadius"] = "60" # ความหนาของวง
        $series["PieLabelStyle"] = "Outside" # ให้ป้ายชื่ออยู่ข้างนอก มีเส้นชี้ (ดู Pro)
        $series["PieLineColor"] = "Gray"     # สีเส้นชี้
        
        # --- Data Points ---
        # Label บนกราฟ: #VALY (แสดงแค่จำนวนตัวเลข)
        # Legend: ชื่อ - #VALY (#PERCENT{P2}) (แสดงครบ)

        # 1. 5-Star (Gold)
        $dp5 = New-Object System.Windows.Forms.DataVisualization.Charting.DataPoint(0, $count5)
        $dp5.Label = "#VALY" 
        $dp5.LegendText = "5-Star :  #VALY  (#PERCENT{P2})" 
        $dp5.Color = "Gold"
        $dp5.LabelForeColor = "Gold" # ตัวเลขสีทองตามสีแท่ง
        $dp5.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $series.Points.Add($dp5)

        # 2. 4-Star (Purple)
        $dp4 = New-Object System.Windows.Forms.DataVisualization.Charting.DataPoint(0, $count4)
        $dp4.Label = "#VALY"
        $dp4.LegendText = "4-Star :  #VALY  (#PERCENT{P2})"
        $dp4.Color = "MediumPurple"
        $dp4.LabelForeColor = "MediumPurple"
        $dp4.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $series.Points.Add($dp4)

        # 3. 3-Star (Blue)
        $dp3 = New-Object System.Windows.Forms.DataVisualization.Charting.DataPoint(0, $count3)
        $dp3.Label = "#VALY"
        $dp3.LegendText = "3-Star :  #VALY  (#PERCENT{P2})"
        $dp3.Color = "DodgerBlue"
        $dp3.LabelForeColor = "DodgerBlue"
        $dp3.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $series.Points.Add($dp3)

        $script:chart.Series.Add($series)

        # Legend Styling (สำคัญมากสำหรับความ Pro)
        $leg = New-Object System.Windows.Forms.DataVisualization.Charting.Legend
        $leg.Name = "MainLegend"
        $leg.Docking = "Bottom"
        $leg.Alignment = "Center"
        $leg.BackColor = "Transparent"
        $leg.ForeColor = "Silver"
        $leg.Font = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Regular) # ใช้ Font monospace เพื่อให้ตัวเลขตรงกัน
        $script:chart.Legends.Add($leg)

        # Title
        $t = New-Object System.Windows.Forms.DataVisualization.Charting.Title
        $t.Text = "Drop Rate Analysis (Total: $($sourceData.Count))"
        $t.ForeColor = "Silver"
        $t.Font = $script:fontHeader
        $t.Alignment = "TopLeft"
        $script:chart.Titles.Add($t)

        $script:chart.ChartAreas[0].AxisX.Enabled = "False"
        $script:chart.ChartAreas[0].AxisY.Enabled = "False"
        $script:chart.ChartAreas[0].BackColor = "Transparent"
        $script:chart.Update()
        return 
    }


    # ==================================================
    # CASE B: PITY HISTORY (Normal Graph)
    # ==================================================
    if ($null -eq $DataList -or $DataList.Count -eq 0) {
        $script:chart.Visible = $false; $script:lblNoData.Visible = $true; return
    }

    $script:chart.Visible = $true; $script:lblNoData.Visible = $false
    $script:chart.ChartAreas[0].AxisX.Enabled = "True"
    $script:chart.ChartAreas[0].AxisY.Enabled = "True"
    $script:chart.ChartAreas[0].AxisY.Title = "Pity Count"

    # Title (ย้ายไปซ้ายบน เช่นกัน)
    $t = New-Object System.Windows.Forms.DataVisualization.Charting.Title
    $t.Text = "5-Star Pity History"
    $t.ForeColor = "Gold"
    $t.Font = $script:fontHeader
    $t.Alignment = "TopLeft" # <--- ชิดซ้ายบน
    $script:chart.Titles.Add($t)

    $series = New-Object System.Windows.Forms.DataVisualization.Charting.Series
    $series.Name = "Pity"
    $series.ChartType = $typeStr
    $series.IsValueShownAsLabel = $true 
    $series.LabelForeColor = "White"
    
    if ($typeStr -match "Line|Spline") {
        $series.BorderWidth = 3
        $series.MarkerStyle = "Circle"; $series.MarkerSize = 8
    } else { $series["PixelPointWidth"] = "30" }

    $idx = 1
    foreach ($item in $DataList) {
        $label = if ($script:chkShowNo.Checked) { "$($item.Name)`n(#$idx)" } else { "$($item.Name)`n($([DateTime]::Parse($item.Time).ToString("dd/MM")))" }
        
        $ptIndex = $series.Points.AddXY($label, $item.Pity)
        $pt = $series.Points[$ptIndex]
        $pt.ToolTip = "Name: $($item.Name)`nDate: $($item.Time)`nPity: $($item.Pity)`nBanner: $($item.Banner)"

        if ($typeStr -eq "Column" -or $typeStr -eq "Bar") {
            $pt.BackGradientStyle = "TopBottom"
            if ($item.Pity -gt 75) { $pt.Color = "Crimson"; $pt.BackSecondaryColor = "Maroon" } 
            elseif ($item.Pity -gt 50) { $pt.Color = "Gold"; $pt.BackSecondaryColor = "DarkGoldenrod" } 
            else { $pt.Color = "LimeGreen"; $pt.BackSecondaryColor = "DarkGreen" }
        } else {
            $series.Color = "White"
            if ($item.Pity -gt 75) { $pt.MarkerColor = "Red" } 
            elseif ($item.Pity -gt 50) { $pt.MarkerColor = "Gold" } 
            else { $pt.MarkerColor = "LimeGreen" }
        }
        $idx++
    }
    $script:chart.Series.Add($series)
    $script:chart.ChartAreas[0].AxisX.Interval = 1
    if ($typeStr -eq "Bar") { $script:chart.ChartAreas[0].AxisY.Title = "Pity Count" }
    $script:chart.Update()
}