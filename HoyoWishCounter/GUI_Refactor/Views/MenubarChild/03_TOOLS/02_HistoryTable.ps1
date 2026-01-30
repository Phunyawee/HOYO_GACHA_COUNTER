# ---------------------------------------------------------------------------
# MODULE: 02_HistoryTable.ps1
# DESCRIPTION: View Gacha History in DataGridView with Search & Filter
# PARENT: 03_TOOLS.ps1
# ---------------------------------------------------------------------------

# 1. เมนู Table Viewer
$script:itemTable = New-Object System.Windows.Forms.ToolStripMenuItem("History Table Viewer")
$script:itemTable.ShortcutKeys = "F9"
$script:itemTable.ForeColor = "White"
$script:itemTable.Enabled = $false # รอ Fetch ก่อน (จะถูกเปิดโดย Logic ส่วนกลางเมื่อมีข้อมูล)

# เพิ่มลงใน Menu Tools
$menuTools.DropDownItems.Add($script:itemTable) | Out-Null

# ==========================================
#  EVENT: TABLE VIEWER (F9)
# ==========================================
$script:itemTable.Add_Click({
    WriteGUI-Log "Action: Open Table Viewer" "Cyan"

    # 1. เช็คข้อมูล (เอาเฉพาะที่ผ่าน Filter หน้าหลักมาแล้ว)
    $dataSource = $script:FilteredData
    if ($null -eq $dataSource -or $dataSource.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("No data to display. Please Fetch or adjust your Date Filter.", "No Data", 0, 48)
        return
    }

    # 2. สร้างหน้าต่าง
    $fTable = New-Object System.Windows.Forms.Form
    $fTable.Text = "History Table Viewer (Rows: $($dataSource.Count))"
    $fTable.Size = New-Object System.Drawing.Size(900, 600)
    $fTable.StartPosition = "CenterParent"
    $fTable.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
    $fTable.ForeColor = "Black" # Text ใน Grid จะเป็นสีดำ (อ่านง่ายกว่าบนตารางขาว)

    # 3. Search Box Panel (ด้านบน)
    $pnlTop = New-Object System.Windows.Forms.Panel; $pnlTop.Dock="Top"; $pnlTop.Height=40; $pnlTop.BackColor=[System.Drawing.Color]::FromArgb(50,50,50)
    $fTable.Controls.Add($pnlTop)

    $lblSearch = New-Object System.Windows.Forms.Label; $lblSearch.Text="Search Name:"; $lblSearch.ForeColor="White"; $lblSearch.Location="10,12"; $lblSearch.AutoSize=$true
    $pnlTop.Controls.Add($lblSearch)

    $txtSearch = New-Object System.Windows.Forms.TextBox; $txtSearch.Location="100,10"; $txtSearch.Width=250; $txtSearch.BackColor="White"
    $pnlTop.Controls.Add($txtSearch)
    
    $lblHint = New-Object System.Windows.Forms.Label; $lblHint.Text="(Filter applies to this table only)"; $lblHint.ForeColor="Gray"; $lblHint.Location="360,12"; $lblHint.AutoSize=$true
    $pnlTop.Controls.Add($lblHint)

    # 4. DataGridView (ตาราง)
    $grid = New-Object System.Windows.Forms.DataGridView
    $grid.Dock = "Fill"
    $grid.BackgroundColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
    $grid.ForeColor = "Black" 
    $grid.AutoSizeColumnsMode = "Fill"
    $grid.ReadOnly = $true
    $grid.AllowUserToAddRows = $false
    $grid.RowHeadersVisible = $false
    $grid.SelectionMode = "FullRowSelect"
    
    # แปลง Data เป็น DataTable (เพื่อให้ Search ได้)
    $dt = New-Object System.Data.DataTable
    [void]$dt.Columns.Add("Time")
    [void]$dt.Columns.Add("Name")
    [void]$dt.Columns.Add("Type")
    [void]$dt.Columns.Add("Rank")
    [void]$dt.Columns.Add("Banner")

    foreach ($item in $dataSource) {
        $row = $dt.NewRow()
        $row["Time"] = $item.time
        $row["Name"] = $item.name
        $row["Type"] = $item.item_type
        $row["Rank"] = $item.rank_type
        $row["Banner"] = if ($item._BannerName) { $item._BannerName } else { "-" }
        [void]$dt.Rows.Add($row)
    }

    $grid.DataSource = $dt
    $fTable.Controls.Add($grid)
    $grid.BringToFront()

    # 5. Logic Search (พิมพ์ปุ๊บ กรองปั๊บ)
    $txtSearch.Add_TextChanged({
        $val = $txtSearch.Text.Replace("'", "''") # กัน error อักขระพิเศษ
        try {
            if ([string]::IsNullOrWhiteSpace($val)) {
                $dt.DefaultView.RowFilter = ""
            } else {
                # กรองเฉพาะชื่อ (Name)
                $dt.DefaultView.RowFilter = "Name LIKE '%$val%'"
            }
            $fTable.Text = "History Table Viewer (Rows: $($dt.DefaultView.Count))"
        } catch {}
    })
    
    # Style: จัดสี 5 ดาวให้เด่น (รองรับ ZZZ)
    $grid.Add_CellFormatting({
        param($sender, $e)
        
        # ตรวจสอบว่าคอลัมน์นี้ใช่ "Rank" ไหม
        if ($e.RowIndex -ge 0 -and $grid.Columns[$e.ColumnIndex].Name -eq "Rank") {
            
            $rankVal = try { [int]$e.Value } catch { 0 }
            
            # [FIX] Safe Check for CurrentGame
            $curGame = if ($script:CurrentGame) { $script:CurrentGame } else { "" }
            $isZZZ = $curGame -match "ZZZ"
            
            $target5 = if ($isZZZ) { 4 } else { 5 }
            $target4 = if ($isZZZ) { 3 } else { 4 }

            if ($rankVal -eq $target5) {
                $grid.Rows[$e.RowIndex].DefaultCellStyle.BackColor = "Gold"
                $grid.Rows[$e.RowIndex].DefaultCellStyle.ForeColor = "Black"
            } elseif ($rankVal -eq $target4) {
                $grid.Rows[$e.RowIndex].DefaultCellStyle.BackColor = "MediumPurple"
                $grid.Rows[$e.RowIndex].DefaultCellStyle.ForeColor = "White"
            }
        }
    })

    $fTable.ShowDialog() | Out-Null
})