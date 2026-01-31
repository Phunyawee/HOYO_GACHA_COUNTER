# ==============================================================================
#  MODULE: 03_LogAnalyzer.ps1
#  DESCRIPTION: Log Dashboard (Final Layout: FlowLayoutPanel for Filters)
#  PARENT: 02_HELP.ps1
# ==============================================================================

$menuLog = New-Object System.Windows.Forms.ToolStripMenuItem("Log Analysis")
$menuLog.ForeColor = "Cyan"
[void]$menuHelp.DropDownItems.Add($menuLog)

$menuLog.Add_Click({
    # --- 1. MAIN WINDOW SETUP ---
    $frmLog = New-Object System.Windows.Forms.Form
    $frmLog.Text = "Log Dashboard & Inspector"
    $frmLog.Size = New-Object System.Drawing.Size(1400, 800)
    $frmLog.StartPosition = "CenterParent"
    $frmLog.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
    $frmLog.ForeColor = "White"

    # ==========================================================================
    #  LAYOUT: Docking System (Right -> Left -> Center)
    # ==========================================================================

    # --- 1. RIGHT PANEL (DETAILS) ---
    $pnlRight = New-Object System.Windows.Forms.Panel
    $pnlRight.Dock = "Right"
    $pnlRight.Width = 450
    $pnlRight.Padding = New-Object System.Windows.Forms.Padding(5)
    $pnlRight.BackColor = [System.Drawing.Color]::FromArgb(35, 35, 35)
    $frmLog.Controls.Add($pnlRight)

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
    $pnlRight.Controls.Add($grpDetail)

    # --- 2. LEFT PANEL (FILTERS - FLOW LAYOUT) ---
    $pnlLeft = New-Object System.Windows.Forms.Panel
    $pnlLeft.Dock = "Left"
    $pnlLeft.Width = 300  # ให้กว้างหน่อย
    $pnlLeft.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
    $frmLog.Controls.Add($pnlLeft)

    # ใช้ FlowLayoutPanel เพื่อเรียงของจากบนลงล่างอัตโนมัติ (แก้ปัญหาของกองกัน)
    $flowLeft = New-Object System.Windows.Forms.FlowLayoutPanel
    $flowLeft.Dock = "Fill"
    $flowLeft.FlowDirection = "TopDown"   # เรียงจากบนลงล่าง
    $flowLeft.WrapContents = $false       # ห้ามปัดไปคอลัมน์ใหม่
    $flowLeft.AutoScroll = $true          # ถ้าจอมันเตี้ย ให้มี Scrollbar ได้
    $flowLeft.Padding = New-Object System.Windows.Forms.Padding(15) # ระยะห่างจากขอบ
    $pnlLeft.Controls.Add($flowLeft)

    # Helper function: เพิ่ม Control เข้า Flow พร้อมกำหนด Margin ล่าง
    $AddToFlow = { param($ctrl, $marginBottom)
        $ctrl.Width = 250 # ความกว้าง Control
        $ctrl.Margin = New-Object System.Windows.Forms.Padding(0, 0, 0, $marginBottom) # เว้นระยะล่าง
        $flowLeft.Controls.Add($ctrl)
    }

    # --- SECTION 1: DATE ---
    $lblDate = New-Object System.Windows.Forms.Label
    $lblDate.Text = "Log Date:"; $lblDate.AutoSize = $true; $lblDate.ForeColor = "Cyan"
    & $AddToFlow $lblDate 5

    $cbDates = New-Object System.Windows.Forms.ComboBox
    $cbDates.DropDownStyle = "DropDownList"
    & $AddToFlow $cbDates 15 # เว้น 15px ก่อนถึงปุ่ม

    $btnRefresh = New-Object System.Windows.Forms.Button
    $btnRefresh.Text = "Reload / Refresh"
    $btnRefresh.BackColor = "DimGray"; $btnRefresh.ForeColor = "White"
    $btnRefresh.Height = 40 # ปุ่มใหญ่หน่อย
    & $AddToFlow $btnRefresh 30 # เว้นเยอะหน่อย 30px เพื่อแบ่งโซน

    # --- SECTION 2: SEARCH ---
    $lblSearch = New-Object System.Windows.Forms.Label
    $lblSearch.Text = "Search Message:"; $lblSearch.AutoSize = $true; $lblSearch.ForeColor = "Cyan"
    & $AddToFlow $lblSearch 5

    $txtSearch = New-Object System.Windows.Forms.TextBox
    & $AddToFlow $txtSearch 30 # เว้นเยอะหน่อย 30px เพื่อแบ่งโซน

    # --- SECTION 3: FILTERS ---
    $lblLvl = New-Object System.Windows.Forms.Label
    $lblLvl.Text = "Filter Level:"; $lblLvl.AutoSize = $true; $lblLvl.ForeColor = "Cyan"
    & $AddToFlow $lblLvl 5

    $cbLevel = New-Object System.Windows.Forms.ComboBox
    $cbLevel.DropDownStyle = "DropDownList"
    & $AddToFlow $cbLevel 20

    $lblSrc = New-Object System.Windows.Forms.Label
    $lblSrc.Text = "Filter Source:"; $lblSrc.AutoSize = $true; $lblSrc.ForeColor = "Cyan"
    & $AddToFlow $lblSrc 5

    $cbSource = New-Object System.Windows.Forms.ComboBox
    $cbSource.DropDownStyle = "DropDownList"
    & $AddToFlow $cbSource 20

    # --- 3. CENTER PANEL (GRID) ---
    $pnlCenter = New-Object System.Windows.Forms.Panel
    $pnlCenter.Dock = "Fill"
    $pnlCenter.Padding = New-Object System.Windows.Forms.Padding(0, 0, 5, 0)
    $frmLog.Controls.Add($pnlCenter)
    $pnlCenter.BringToFront()

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
    $pnlCenter.Controls.Add($grid)

    # --- STATUS STRIP ---
    $statusStrip = New-Object System.Windows.Forms.StatusStrip
    $statusStrip.BackColor = [System.Drawing.Color]::FromArgb(50, 50, 50)
    $statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
    $statusLabel.Text = "Ready"
    $statusLabel.ForeColor = "WhiteSmoke"
    $statusStrip.Items.Add($statusLabel)
    $frmLog.Controls.Add($statusStrip)

    # ==========================================================================
    #  LOGIC SECTION (UNCHANGED)
    # ==========================================================================
    $GlobalLogCache = New-Object System.Collections.ArrayList

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
                $grid.Columns["Level"].Width = 120
                $grid.Columns["Source"].Width = 120
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

    $cbDates.add_SelectedIndexChanged($ReadFileAndParse)
    $btnRefresh.add_Click($ReadFileAndParse)
    $txtSearch.add_TextChanged($UpdateGridDisplay)
    $cbLevel.add_SelectedIndexChanged($UpdateGridDisplay)
    $cbSource.add_SelectedIndexChanged($UpdateGridDisplay)
    $grid.add_SelectionChanged($ShowRowDetails)

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