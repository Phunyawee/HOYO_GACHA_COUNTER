# ==============================================================================
#  MODULE: 03_LogAnalyzer.ps1
#  DESCRIPTION: Log Dashboard (2 Rows Layout + Spacing Fix)
#  PARENT: 02_HELP.ps1
# ==============================================================================

$menuLog = New-Object System.Windows.Forms.ToolStripMenuItem("Log Analysis")
$menuLog.ForeColor = "Cyan"
[void]$menuHelp.DropDownItems.Add($menuLog)

$menuLog.Add_Click({
    # --- 1. MAIN WINDOW SETUP ---
    $frmLog = New-Object System.Windows.Forms.Form
    $frmLog.Text = "Log Dashboard & Inspector"
    $frmLog.Size = New-Object System.Drawing.Size(1100, 700)
    $frmLog.StartPosition = "CenterParent"
    $frmLog.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
    $frmLog.ForeColor = "White"

    # --- TOP PANEL (CONTROLS - 2 ROWS) ---
    $pnlTop = New-Object System.Windows.Forms.Panel
    $pnlTop.Dock = "Top"
    # [จุดแก้ 1] เพิ่มความสูงจาก 80 เป็น 100 ให้มีที่หายใจ และดันตารางลง
    $pnlTop.Height = 100 
    $pnlTop.Padding = New-Object System.Windows.Forms.Padding(10)
    $pnlTop.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
    $frmLog.Controls.Add($pnlTop)

    # --- Row 1: Date & Search ---
    $lblDate = New-Object System.Windows.Forms.Label
    $lblDate.Text = "Log Date:"; $lblDate.AutoSize = $true
    $lblDate.Location = New-Object System.Drawing.Point(15, 15)
    $pnlTop.Controls.Add($lblDate)

    $cbDates = New-Object System.Windows.Forms.ComboBox
    $cbDates.Location = New-Object System.Drawing.Point(85, 12); $cbDates.Width = 150
    $cbDates.DropDownStyle = "DropDownList"
    $pnlTop.Controls.Add($cbDates)

    $lblSearch = New-Object System.Windows.Forms.Label
    $lblSearch.Text = "Search:"; $lblSearch.AutoSize = $true
    $lblSearch.Location = New-Object System.Drawing.Point(260, 15)
    $pnlTop.Controls.Add($lblSearch)

    $txtSearch = New-Object System.Windows.Forms.TextBox
    $txtSearch.Location = New-Object System.Drawing.Point(315, 12); $txtSearch.Width = 300
    $pnlTop.Controls.Add($txtSearch)

    $btnRefresh = New-Object System.Windows.Forms.Button
    $btnRefresh.Text = "Reload File"
    $btnRefresh.Location = New-Object System.Drawing.Point(640, 10); $btnRefresh.Width = 100
    $btnRefresh.BackColor = "DimGray"; $btnRefresh.ForeColor = "White"
    $pnlTop.Controls.Add($btnRefresh)

    # --- Row 2: Dynamic Filters ---
    $lblLvl = New-Object System.Windows.Forms.Label
    $lblLvl.Text = "Filter Level:"; $lblLvl.AutoSize = $true
    $lblLvl.Location = New-Object System.Drawing.Point(15, 55) # ขยับ Y ลงมา
    $pnlTop.Controls.Add($lblLvl)

    $cbLevel = New-Object System.Windows.Forms.ComboBox
    $cbLevel.Location = New-Object System.Drawing.Point(95, 52); $cbLevel.Width = 140
    $cbLevel.DropDownStyle = "DropDownList"
    $pnlTop.Controls.Add($cbLevel)

    $lblSrc = New-Object System.Windows.Forms.Label
    $lblSrc.Text = "Filter Source:"; $lblSrc.AutoSize = $true
    $lblSrc.Location = New-Object System.Drawing.Point(260, 55) # ขยับ Y ลงมา
    $pnlTop.Controls.Add($lblSrc)

    $cbSource = New-Object System.Windows.Forms.ComboBox
    $cbSource.Location = New-Object System.Drawing.Point(340, 52); $cbSource.Width = 150
    $cbSource.DropDownStyle = "DropDownList"
    $pnlTop.Controls.Add($cbSource)

    # --- SPLIT CONTAINER ---
    $split = New-Object System.Windows.Forms.SplitContainer
    $split.Dock = "Fill"
    $split.Orientation = "Horizontal"
    $split.SplitterDistance = 400
    $split.SplitterWidth = 5
    $frmLog.Controls.Add($split)

    # [จุดแก้ 2] ใส่ Padding ให้ Panel1 เพื่อดันตารางลงมาจากขอบบนอีก 10px
    $split.Panel1.Padding = New-Object System.Windows.Forms.Padding(0, 10, 0, 0)

    # --- GRID VIEW (TOP) ---
    $grid = New-Object System.Windows.Forms.DataGridView
    $grid.Dock = "Fill"
    $grid.BackgroundColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
    $grid.ForeColor = "Black"
    $grid.AllowUserToAddRows = $false
    $grid.ReadOnly = $true
    $grid.RowHeadersVisible = $false
    $grid.SelectionMode = "FullRowSelect"
    $grid.MultiSelect = $false
    $grid.AutoSizeColumnsMode = "Fill"
    $grid.BorderStyle = "None"
    $grid.DefaultCellStyle.Font = New-Object System.Drawing.Font("Consolas", 9)
    $split.Panel1.Controls.Add($grid)

    # --- DETAIL BOX (BOTTOM) ---
    $grpDetail = New-Object System.Windows.Forms.GroupBox
    $grpDetail.Text = " Row Details "
    $grpDetail.Dock = "Fill"
    $grpDetail.ForeColor = "LightGray"
    
    $txtDetail = New-Object System.Windows.Forms.RichTextBox
    $txtDetail.Dock = "Fill"
    $txtDetail.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 20)
    $txtDetail.ForeColor = "Lime"
    $txtDetail.Font = New-Object System.Drawing.Font("Consolas", 10)
    $txtDetail.ReadOnly = $true
    $txtDetail.BorderStyle = "None"
    
    $grpDetail.Controls.Add($txtDetail)
    $split.Panel2.Controls.Add($grpDetail)
    $split.Panel2.Padding = New-Object System.Windows.Forms.Padding(5)

    # --- STATUS STRIP ---
    $statusStrip = New-Object System.Windows.Forms.StatusStrip
    $statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
    $statusLabel.Text = "Ready"
    $statusLabel.ForeColor = "Black"
    $statusStrip.Items.Add($statusLabel)
    $frmLog.Controls.Add($statusStrip)

    # ตัวแปรเก็บข้อมูล
    $GlobalLogCache = New-Object System.Collections.ArrayList

    # --- FUNCTION: UPDATE GRID ---
    $UpdateGridDisplay = {
        $searchText = $txtSearch.Text.ToLower()
        $filterLvl  = $cbLevel.SelectedItem
        $filterSrc  = $cbSource.SelectedItem

        $filteredList = New-Object System.Collections.ArrayList
        
        foreach ($item in $GlobalLogCache) {
            $isMatch = $true
            if ($filterLvl -ne $null -and $filterLvl -ne "All Levels" -and $item.Level -ne $filterLvl) { $isMatch = $false }
            if ($isMatch -and $filterSrc -ne $null -and $filterSrc -ne "All Sources" -and $item.Source -ne $filterSrc) { $isMatch = $false }
            if ($isMatch -and $searchText.Length -gt 0) {
                if (-not ($item.Message.ToLower().Contains($searchText) -or $item.Source.ToLower().Contains($searchText))) {
                    $isMatch = $false
                }
            }
            if ($isMatch) { [void]$filteredList.Add($item) }
        }

        $grid.DataSource = $null
        $grid.DataSource = $filteredList
        $statusLabel.Text = "Showing " + $filteredList.Count + " / " + $GlobalLogCache.Count + " records."

        if ($grid.Columns.Count -gt 0) {
            if ($grid.Columns["Original"]) { $grid.Columns["Original"].Visible = $false }
            try {
                $grid.Columns["Time"].Width = 140
                $grid.Columns["Level"].Width = 80
                $grid.Columns["Source"].Width = 100
            } catch {}
        }

        foreach ($row in $grid.Rows) {
            $lvl = $row.DataBoundItem.Level
            if ($lvl -in @("ERROR", "FATAL", "CRASH")) {
                $row.DefaultCellStyle.BackColor = "LightPink"; $row.DefaultCellStyle.ForeColor = "DarkRed"
            } elseif ($lvl -eq "WARN") {
                $row.DefaultCellStyle.BackColor = "LemonChiffon"
            } elseif ($lvl -eq "USER_ACTION") {
                $row.DefaultCellStyle.BackColor = "LightCyan"; $row.DefaultCellStyle.ForeColor = "DarkSlateGray"
            } elseif ($lvl -eq "STOP") {
                $row.DefaultCellStyle.BackColor = "PeachPuff"; $row.DefaultCellStyle.ForeColor = "Red"
            } elseif ($lvl -eq "RAW") {
                $row.DefaultCellStyle.ForeColor = "Gray"; $row.DefaultCellStyle.Font = New-Object System.Drawing.Font("Consolas", 8, [System.Drawing.FontStyle]::Italic)
            }
        }
    }

    # --- FUNCTION: SHOW DETAILS ---
    $ShowRowDetails = {
        if ($grid.SelectedRows.Count -gt 0) {
            $item = $grid.SelectedRows[0].DataBoundItem
            $txtDetail.Clear()
            
            $append = { param($t, $c) 
                $txtDetail.SelectionColor = $c
                $txtDetail.AppendText($t) 
            }
            & $append "TIMESTAMP : " "Gray"; & $append "$($item.Time)`n" "White"
            & $append "LEVEL     : " "Gray"
            $lvlColor = "Lime"
            if ($item.Level -in @("ERROR", "FATAL", "CRASH", "STOP")) { $lvlColor = "Red" }
            elseif ($item.Level -eq "WARN") { $lvlColor = "Yellow" }
            elseif ($item.Level -eq "USER_ACTION") { $lvlColor = "Cyan" }
            & $append "$($item.Level)`n" $lvlColor
            & $append "SOURCE    : " "Gray"; & $append "$($item.Source)`n" "White"
            & $append ("-"*50 + "`n") "DimGray"
            & $append "$($item.Message)" "White"
            if ($item.Level -eq "RAW") {
                 & $append "`n`n[RAW DATA DUMP]`n" "Orange"; & $append "$($item.Original)" "Gray"
            }
        }
    }

    # --- FUNCTION: READ FILE ---
    $ReadFileAndParse = {
        $selectedDate = $cbDates.SelectedItem
        if (-not $selectedDate) { return }

        $GlobalLogCache.Clear()
        $txtDetail.Clear()
        
        $TargetDir = if ($Global:LogRoot) { $Global:LogRoot } else { "$PSScriptRoot\..\Logs" }
        $FullPath = Join-Path $TargetDir "debug_$selectedDate.log"

        if (Test-Path $FullPath) {
            $rawContent = Get-Content $FullPath -Encoding UTF8
            foreach ($line in $rawContent) {
                if ($line -match "^\[(?<time>[^\]]*)\]\s*\[(?<level>[^\]]*)\]\s*\[(?<src>[^\]]*)\]\s*(?<msg>.*)$") {
                    [void]$GlobalLogCache.Add([PSCustomObject]@{ Time = $matches['time']; Level = $matches['level'].Trim(); Source = $matches['src'].Trim(); Message = $matches['msg']; Original = $line })
                } else {
                    if (-not [string]::IsNullOrWhiteSpace($line)) {
                        [void]$GlobalLogCache.Add([PSCustomObject]@{ Time = ""; Level = "RAW"; Source = "Unknown"; Message = $line; Original = $line })
                    }
                }
            }
            $cbLevel.Items.Clear(); [void]$cbLevel.Items.Add("All Levels")
            $GlobalLogCache | Select-Object -ExpandProperty Level -Unique | Sort-Object | ForEach-Object { [void]$cbLevel.Items.Add($_) }
            $cbLevel.SelectedIndex = 0
            $cbSource.Items.Clear(); [void]$cbSource.Items.Add("All Sources")
            $GlobalLogCache | Select-Object -ExpandProperty Source -Unique | Sort-Object | ForEach-Object { [void]$cbSource.Items.Add($_) }
            $cbSource.SelectedIndex = 0
        } else { $statusLabel.Text = "File not found: $FullPath" }
        & $UpdateGridDisplay
    }

    # --- EVENTS ---
    $cbDates.add_SelectedIndexChanged($ReadFileAndParse)
    $btnRefresh.add_Click($ReadFileAndParse)
    $txtSearch.add_TextChanged($UpdateGridDisplay)
    $cbLevel.add_SelectedIndexChanged($UpdateGridDisplay)
    $cbSource.add_SelectedIndexChanged($UpdateGridDisplay)
    $grid.add_SelectionChanged($ShowRowDetails)

    # --- INIT ---
    $cbDates.Items.Clear()
    $TargetDir = if ($Global:LogRoot) { $Global:LogRoot } else { "$PSScriptRoot\..\Logs" }
    if (Test-Path $TargetDir) {
        Get-ChildItem -Path $TargetDir -Filter "debug_*.log" | Sort-Object LastWriteTime -Descending | ForEach-Object {
            if ($_.Name -match "debug_(.+)\.log") { [void]$cbDates.Items.Add($matches[1]) }
        }
    }
    if ($cbDates.Items.Count -gt 0) { $cbDates.SelectedIndex = 0 }
    
    $frmLog.ShowDialog()
})