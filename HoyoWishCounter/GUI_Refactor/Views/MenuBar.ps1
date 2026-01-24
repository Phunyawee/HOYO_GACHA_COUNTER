# ==============================================================================
# views/MenuBar.ps1
# ==============================================================================

# 1. สร้างตัวแถบเมนูหลัก (Main Container)
$menuStrip = New-Object System.Windows.Forms.MenuStrip
# เช็คก่อนว่า Class DarkMenuRenderer ถูกประกาศไว้ใน App.ps1 แล้วหรือยัง
if ($null -ne $DarkMenuRenderer) {
    $menuStrip.Renderer = New-Object System.Windows.Forms.ToolStripProfessionalRenderer((New-Object DarkMenuRenderer))
}
$menuStrip.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
$menuStrip.ForeColor = "White"

# เอาแถบเมนูแปะเข้า Form หลัก (ตัวแปร $form มาจาก App.ps1)
$form.Controls.Add($menuStrip)
$form.MainMenuStrip = $menuStrip

# ------------------------------------------------------------------------------
# GROUP 1: FILE MENU
# ------------------------------------------------------------------------------
$menuFile = New-Object System.Windows.Forms.ToolStripMenuItem("File")
[void]$menuStrip.Items.Add($menuFile)

    # --- ลูกของ File (ใส่ตรงนี้เลย) ---
    # เมนูย่อย Reset
    $itemClear = New-Object System.Windows.Forms.ToolStripMenuItem("Reset / Clear All")
    $itemClear.ShortcutKeys = [System.Windows.Forms.Keys]::F5
    $itemClear.Add_Click({
        # เรียกใช้ Helper บรรทัดเดียวจบ!
        Reset-LogWindow
        
        # 3. เริ่ม Write-GuiLogข้อความ Reset
        WriteGUI-Log ">>> User requested RESET. Clearing all data... <<<" "OrangeRed"
        
        # 4. Reset ค่าตัวแปรอื่นๆ ตามเดิม
        $script:pnlPityFill.Width = 0
        $script:lblPityTitle.Text = "Current Pity Progress: 0 / 90"; $script:lblPityTitle.ForeColor = "White"; $script:pnlPityFill.BackColor = "LimeGreen"
        $script:LastFetchedData = @()
        $script:FilteredData = @()
        $btnExport.Enabled = $false; 
        $btnExport.BackColor = "DimGray"

        # ==========================================
        # [NEW] Clear Path Input (กัน Fetch ผิดไฟล์)
        # ==========================================
        $txtPath.Text = "" 
        # ==========================================

        $lblStat1.Text = "Total Pulls: 0"; $script:lblStatAvg.Text = "Avg. Pity: -"; $script:lblStatAvg.ForeColor = "White"
        $script:lblStatCost.Text = "Est. Cost: 0"

        $script:lblExtremes.Text = "Max: -  Min: -"
        $script:lblExtremes.ForeColor = "Silver"
        
        # 5. Reset Filter Panel
        $grpFilter.Enabled = $false
        $chkFilterEnable.Checked = $false
        $dtpStart.Value = Get-Date
        $dtpEnd.Value = Get-Date
        
        # 6. Clear Graph & Panel
        $chart.Series.Clear()
        $chart.Visible = $false
        $lblNoData.Visible = $true
        
        # ถ้ากราฟเปิดอยู่ ให้ยุบกลับ
        if ($script:isExpanded) {
            $form.Width = 600
            $menuExpand.Text = ">> Show Graph"
            $script:isExpanded = $false
        }

        $script:itemForecast.Enabled = $false
        $script:itemTable.Enabled = $false
        $script:itemJson.Enabled = $false

        # เพิ่มบรรทัดนี้เข้าไปใน Reset Logic (ใน $itemClear.Add_Click)
        $script:lblLuckGrade.Text = "Grade: -"; $script:lblLuckGrade.ForeColor = "DimGray"

        WriteGUI-Log "--- System Reset Complete. Ready. ---" "Gray"
    })
    [void]$menuFile.DropDownItems.Add($itemClear)

   
    $itemSettings = New-Object System.Windows.Forms.ToolStripMenuItem("Preferences / Settings")
    $itemSettings.ShortcutKeys = "F2"
    [void]$menuFile.DropDownItems.Add($itemSettings)
    $itemSettings.Add_Click({
        Show-SettingsWindow
    })

    # เมนูย่อย Exit
    $itemExit = New-Object System.Windows.Forms.ToolStripMenuItem("Exit")
    $itemExit.Add_Click({ $form.Close() })
    [void]$menuFile.DropDownItems.Add($itemExit)

    
# ------------------------------------------------------------------------------
# GROUP 3: TOOLS (Forecast)
# ------------------------------------------------------------------------------
$menuTools = New-Object System.Windows.Forms.ToolStripMenuItem("Tools")
[void]$menuStrip.Items.Add($menuTools)

    # --- ลูกของ Tools ---
    # สร้างเมนูย่อย Simulator
    $script:itemForecast = New-Object System.Windows.Forms.ToolStripMenuItem("Wish Forecast (Simulator)")
    $script:itemForecast.ShortcutKeys = "F8"  # คีย์ลัดกด F8 ได้เลย เท่ๆ
    $script:itemForecast.Enabled = $false     # ปิดไว้ก่อน รอ Fetch เสร็จ
    $script:itemForecast.ForeColor = "White"
    $menuTools.DropDownItems.Add($script:itemForecast) | Out-Null
    # ==========================================
    #  EVENT: MENU FORECAST CLICK
    # ==========================================
    $script:itemForecast.Add_Click({
        WriteGUI-Log "Action: Open Forecast Simulator Window" "Cyan"

        # 1. AUTO-DETECT DATA
        $currentPity = 0; $isGuaranteed = $false; $mode = "Character (90)"; $hardCap = 90; $softCap = 74
        if ($null -ne $script:LastFetchedData -and $script:LastFetchedData.Count -gt 0) {
            $conf = Get-GameConfig $script:CurrentGame
            foreach ($item in $script:LastFetchedData) {
                if ($item.rank_type -eq $conf.SRank) { 
                    $status = Get-GachaStatus -GameName $script:CurrentGame -CharName $item.name -BannerCode $item.gacha_type
                    if ($status -eq "LOSS") { $isGuaranteed = $true }
                    break 
                }
                $currentPity++
            }
            $lastType = $script:LastFetchedData[0].gacha_type
            if ($lastType -match "^(302|12|3|5)$") { $mode = "Weapon/LC (80)"; $hardCap = 80; $softCap = 64 }
            WriteGUI-Log "[Forecast] Auto-Detected: Pity=$currentPity, Guaranteed=$isGuaranteed, Mode=$mode" "Gray"
        }

        # 2. UI SETUP
        $fSim = New-Object System.Windows.Forms.Form
        $fSim.Text = "Hoyo Wish Forecast (v$script:AppVersion)"
        $fSim.Size = New-Object System.Drawing.Size(900, 580)
        $fSim.StartPosition = "CenterParent"
        $fSim.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 40)
        $fSim.ForeColor = "White"
        $fSim.FormBorderStyle = "FixedDialog"
        $fSim.MaximizeBox = $false

        # Init Stop Flag
        $script:SimStopRequested = $false

        # --- LEFT PANEL: INPUTS ---
        $pnlLeft = New-Object System.Windows.Forms.Panel; $pnlLeft.Location="0,0"; $pnlLeft.Size="380,550"; $pnlLeft.BackColor="Transparent"; $fSim.Controls.Add($pnlLeft)

        $l1 = New-Object System.Windows.Forms.Label; $l1.Text="CURRENT STATUS"; $l1.Location="20,20"; $l1.AutoSize=$true; $l1.Font=$script:fontBold; $l1.ForeColor="Gold"; $pnlLeft.Controls.Add($l1)
        
        $l2 = New-Object System.Windows.Forms.Label; $l2.Text="Current Pity:"; $l2.Location="30,50"; $l2.AutoSize=$true; $l2.ForeColor="Silver"; $pnlLeft.Controls.Add($l2)
        $txtPity = New-Object System.Windows.Forms.TextBox; $txtPity.Text="$currentPity"; $txtPity.Location="120,48"; $txtPity.Width=50; $txtPity.BackColor="30,30,50"; $txtPity.ForeColor="Cyan"; $txtPity.BorderStyle="FixedSingle"; $txtPity.TextAlign="Center"; $pnlLeft.Controls.Add($txtPity)

        $l3 = New-Object System.Windows.Forms.Label; $l3.Text="Guaranteed?"; $l3.Location="200,50"; $l3.AutoSize=$true; $l3.ForeColor="Silver"; $pnlLeft.Controls.Add($l3)
        $chkG = New-Object System.Windows.Forms.CheckBox; $chkG.Location="290,46"; $chkG.Text="YES"; $chkG.Checked=$isGuaranteed; $chkG.ForeColor="Lime"; $chkG.AutoSize=$true; $pnlLeft.Controls.Add($chkG)
        $chkG.Add_CheckedChanged({ if($chkG.Checked){$chkG.Text="YES";$chkG.ForeColor="Lime"}else{$chkG.Text="NO";$chkG.ForeColor="Gray"} })

        $l4 = New-Object System.Windows.Forms.Label; $l4.Text="Mode: $mode"; $l4.Location="30,80"; $l4.AutoSize=$true; $l4.ForeColor="DimGray"; $pnlLeft.Controls.Add($l4)

        $l5 = New-Object System.Windows.Forms.Label; $l5.Text="RESOURCES"; $l5.Location="20,120"; $l5.AutoSize=$true; $l5.Font=$script:fontBold; $l5.ForeColor="Gold"; $pnlLeft.Controls.Add($l5)
        $l6 = New-Object System.Windows.Forms.Label; $l6.Text="Primos / Jades:"; $l6.Location="30,150"; $l6.AutoSize=$true; $l6.ForeColor="Silver"; $pnlLeft.Controls.Add($l6)
        $txtPrimos = New-Object System.Windows.Forms.TextBox; $txtPrimos.Text="0"; $txtPrimos.Location="140,148"; $txtPrimos.Width=100; $txtPrimos.BackColor="30,30,50"; $txtPrimos.ForeColor="Cyan"; $txtPrimos.BorderStyle="FixedSingle"; $txtPrimos.TextAlign="Center"; $pnlLeft.Controls.Add($txtPrimos)
        $l7 = New-Object System.Windows.Forms.Label; $l7.Text="Fates / Tickets:"; $l7.Location="30,180"; $l7.AutoSize=$true; $l7.ForeColor="Silver"; $pnlLeft.Controls.Add($l7)
        $txtFates = New-Object System.Windows.Forms.TextBox; $txtFates.Text="0"; $txtFates.Location="140,178"; $txtFates.Width=100; $txtFates.BackColor="30,30,50"; $txtFates.ForeColor="Cyan"; $txtFates.BorderStyle="FixedSingle"; $txtFates.TextAlign="Center"; $pnlLeft.Controls.Add($txtFates)

        $l8 = New-Object System.Windows.Forms.Label; $l8.Text="Total Pulls:"; $l8.Location="30,215"; $l8.AutoSize=$true; $l8.Font=$script:fontBold; $l8.ForeColor="White"; $pnlLeft.Controls.Add($l8)
        $lblTotalPulls = New-Object System.Windows.Forms.Label; 
        $lblTotalPulls.Text="0"; $lblTotalPulls.Location="140,215"; 
        $lblTotalPulls.AutoSize=$true; 
        $lblTotalPulls.Font=$script:fontBold; 
        $lblTotalPulls.ForeColor=  $lblTotalPulls.ForeColor="Cyan"; 
        $pnlLeft.Controls.Add($lblTotalPulls)

        $calcAction = { try { $lblTotalPulls.Text = "$([math]::Floor([int]$txtPrimos.Text / 160) + [int]$txtFates.Text)" } catch { $lblTotalPulls.Text="0" } }
        $txtPrimos.Add_TextChanged($calcAction); $txtFates.Add_TextChanged($calcAction)

        # --- [NEW] BUTTON LAYOUT (Run & Stop) ---
        $btnSim = New-Object System.Windows.Forms.Button; $btnSim.Text="RUN SIMULATION"; $btnSim.Location="40, 260"; $btnSim.Size="220, 45" # ลดขนาดลง
        Apply-ButtonStyle -Button $btnSim -BaseColorName "MediumSlateBlue" -HoverColorName "SlateBlue" -CustomFont $script:fontHeader
        $pnlLeft.Controls.Add($btnSim)

        $btnStopSim = New-Object System.Windows.Forms.Button; $btnStopSim.Text="STOP"; $btnStopSim.Location="270, 260"; $btnStopSim.Size="80, 45"
        $btnStopSim.BackColor = "Firebrick"; $btnStopSim.ForeColor = "White"; $btnStopSim.FlatStyle = "Flat"; $btnStopSim.FlatAppearance.BorderSize = 0; $btnStopSim.Font = $script:fontBold
        $btnStopSim.Enabled = $false
        $pnlLeft.Controls.Add($btnStopSim)

        # RESULT BOX
        $pnlRes = New-Object System.Windows.Forms.Panel; $pnlRes.Location="20,320"; $pnlRes.Size="345,180"; $pnlRes.BackColor="25,25,45"; $pnlRes.BorderStyle="FixedSingle"; $pnlLeft.Controls.Add($pnlRes)
        $lResTitle = New-Object System.Windows.Forms.Label; $lResTitle.Text="SIMULATION RESULT"; $lResTitle.Location="10,10"; $lResTitle.AutoSize=$true; $lResTitle.ForeColor="Silver"; $lResTitle.Font=$script:fontBold; $pnlRes.Controls.Add($lResTitle)
        
        $btnHelp = New-Object System.Windows.Forms.Button; $btnHelp.Text="?"; $btnHelp.Size="25,25"; $btnHelp.Location="310,5"; $btnHelp.FlatStyle="Flat"; $btnHelp.FlatAppearance.BorderSize=0; $btnHelp.BackColor="Transparent"; $btnHelp.ForeColor="Cyan"; $btnHelp.Font=$script:fontBold; $btnHelp.Cursor="Hand"; $pnlRes.Controls.Add($btnHelp)
        $btnHelp.Add_Click({ [System.Windows.Forms.MessageBox]::Show("Shows how many simulations succeeded at each pull count.", "Histogram Info", 0, 64) })

        $lblChance = New-Object System.Windows.Forms.Label; $lblChance.Text="Win Rate: -"; $lblChance.Location="10,40"; $lblChance.AutoSize=$true; $lblChance.ForeColor="White"; $lblChance.Font=$script:fontHeader; $pnlRes.Controls.Add($lblChance)
        $lblCost = New-Object System.Windows.Forms.Label; $lblCost.Text="Avg. Cost: -"; $lblCost.Location="10,80"; $lblCost.AutoSize=$true; $lblCost.ForeColor="Gray"; $pnlRes.Controls.Add($lblCost)
        
        $pbBack = New-Object System.Windows.Forms.Panel; $pbBack.Location="10,120"; $pbBack.Size="320,10"; $pbBack.BackColor="40,40,60"; $pnlRes.Controls.Add($pbBack)
        $pbFill = New-Object System.Windows.Forms.Panel; $pbFill.Location="0,0"; $pbFill.Size="0,10"; $pbFill.BackColor="Lime"; $pbBack.Controls.Add($pbFill)

        # --- RIGHT PANEL: CHART ---
        $pnlRight = New-Object System.Windows.Forms.Panel; $pnlRight.Location="380,20"; $pnlRight.Size="480,480"; $pnlRight.BackColor="Transparent"; $fSim.Controls.Add($pnlRight)
        $chartSim = New-Object System.Windows.Forms.DataVisualization.Charting.Chart; $chartSim.Dock="Fill"; $chartSim.BackColor="Transparent"; $pnlRight.Controls.Add($chartSim)
        $caSim = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea; $caSim.Name="SimArea"; $caSim.BackColor="Transparent"
        $caSim.AxisX.LabelStyle.ForeColor="Silver"; 
        $caSim.AxisX.LineColor="Gray"; 
        $caSim.AxisX.MajorGrid.LineColor=[System.Drawing.Color]::FromArgb(20,255,255,255); 
        $caSim.AxisX.Title="Pulls Used"; $caSim.AxisX.TitleForeColor="Gray"; 
        $caSim.AxisX.Interval=20

        $caSim.AxisY.LabelStyle.ForeColor="DimGray"; 
        $caSim.AxisY.LineColor="Gray"; 
        $caSim.AxisY.MajorGrid.LineColor=[System.Drawing.Color]::FromArgb(20,255,255,255); 

        $caSim.AxisY.Title = "Frequency (Simulations)" # ชื่อป้าย
        $caSim.AxisY.TitleForeColor = "Silver"
        $caSim.AxisY.TextOrientation = "Rotated270"      # หมุนแนวตั้ง
        $caSim.AxisY.TitleFont = $script:fontNormal      # ใช้ฟอนต์ปกติ

        $caSim.AxisY.LabelStyle.Enabled=$false
        
        
        $chartSim.ChartAreas.Add($caSim)
        $titleSim = New-Object System.Windows.Forms.DataVisualization.Charting.Title; $titleSim.Text="Probability Distribution"; $titleSim.ForeColor="Gold"; $titleSim.Font=$script:fontBold; $chartSim.Titles.Add($titleSim)

        # --- [NEW] STOP BUTTON LOGIC ---
        $btnStopSim.Add_Click({
            $script:SimStopRequested = $true
            WriteGUI-Log "----------------------------------------" "DimGray"
            WriteGUI-Log "[Action] Simulation CANCELLED by User!" "Red"
        })

        # [NEW] Check Global Prefill (รับค่าจาก Planner)
        if ($null -ne $script:PlannerBudget) {
            $lblTotalPulls.Text = "$script:PlannerBudget"
            $txtPrimos.Text = "0"
            $txtFates.Text = "$script:PlannerBudget"
            $script:PlannerBudget = $null # Clear ค่าทิ้ง
        }

        # --- RUN LOGIC ---
        $btnSim.Add_Click({
            $budget = [int]$lblTotalPulls.Text
            if ($budget -le 0) { [System.Windows.Forms.MessageBox]::Show("Please enter resources!", "No Budget", 0, 48); return }
            
            $fSim.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
            $btnSim.Enabled = $false; $btnStopSim.Enabled = $true # เปิดปุ่ม Stop
            $script:SimStopRequested = $false # Reset Flag
            
            WriteGUI-Log "----------------------------------------" "DimGray"
            WriteGUI-Log "[Action] Initializing Simulation ($budget Pulls)..." "Cyan"
            [System.Windows.Forms.Application]::DoEvents()
            
            # Call Engine (Pass ref Flag)
            $res = Invoke-GachaSimulation -SimCount 100000 `
                                        -MyPulls $budget `
                                        -StartPity ([int]$txtPity.Text) `
                                        -IsGuaranteed ($chkG.Checked) `
                                        -HardPityCap $hardCap `
                                        -SoftPityStart $softCap `
                                        -StopFlag ([ref]$script:SimStopRequested) `
                                        -ProgressCallback { 
                                            param($r)
                                            $pct=($r/100000)*100
                                            $btnSim.Text="Running... $pct%"
                                            WriteGUI-Log "[Forecast] Simulating: $pct%" "Gray"
                                            [System.Windows.Forms.Application]::DoEvents()
                                        }
            
            # Check if Cancelled
            if ($res.IsCancelled) {
                WriteGUI-Log "[Forecast] Process Aborted." "Red"
                $lblChance.Text = "Cancelled"
                $lblCost.Text = "-"
                $pbFill.Width = 0
                $btnSim.Text = "RUN SIMULATION"
                $btnSim.Enabled = $true
                $btnStopSim.Enabled = $false
                $fSim.Cursor = "Default"
                return
            }

            # Update UI Results (Normal)
            $winRate = "{0:N1}" -f $res.WinRate
            $lblChance.Text = "Success Chance: $winRate%"
            $lblCost.Text = "Avg. Cost: ~$('{0:N0}' -f $res.AvgCost) pulls"
            
            WriteGUI-Log "[Forecast] COMPLETE! WinRate=$winRate%, AvgCost=$('{0:N0}' -f $res.AvgCost)" "Lime"
            
            if ($res.WinRate -ge 80) { $lblChance.ForeColor="Lime"; $pbFill.BackColor="Lime" }
            elseif ($res.WinRate -ge 50) { $lblChance.ForeColor="Gold"; $pbFill.BackColor="Gold" }
            else { $lblChance.ForeColor="Crimson"; $pbFill.BackColor="Crimson" }
            $pbFill.Width = [int](320 * ($res.WinRate / 100))

            # --- UPDATE CHART ---
            $chartSim.Series.Clear(); 
            $caSim.AxisX.StripLines.Clear(); 
            $chartSim.Legends.Clear()
            $caSim.AxisX.Minimum = 0; 
            if ($budget -gt 100) { 
                $caSim.AxisX.Maximum = $NaN 
            } 
            else 
            { 
                $caSim.AxisX.Maximum = 100 
            }

            $leg = New-Object System.Windows.Forms.DataVisualization.Charting.Legend; $leg.Name="Legend1"; $leg.Docking="Bottom"; $leg.Alignment="Center"; $leg.BackColor="Transparent"; $leg.ForeColor="Silver"; $chartSim.Legends.Add($leg)

            if ($null -ne $res.Distribution -and $res.Distribution.Count -gt 0) {
                $s = New-Object System.Windows.Forms.DataVisualization.Charting.Series; $s.Name="Simulation"; $s.ChartType="Column"; $s.IsVisibleInLegend=$false; $s["PixelPointWidth"]="40"
                $startP = [int]$txtPity.Text
                $keys = $res.Distribution.Keys | Sort-Object { [int]$_ }
                foreach ($k in $keys) {
                    $val = $res.Distribution[$k]
                    if ($val -gt 0) {
                        $ptIdx = $s.Points.AddXY([int]$k, [int]$val)
                        $pt = $s.Points[$ptIdx]
                        $totalPityReached = $startP + $k
                        if ($totalPityReached -lt 74) { $pt.Color = "LimeGreen" } elseif ($totalPityReached -le 85) { $pt.Color = "Gold" } else { $pt.Color = "Crimson" }
                        $pct = "{0:N2}" -f (($val / 100000) * 100)
                        $pt.ToolTip = "Used: ~$k Pulls (Total Pity: $totalPityReached)`nChance: $pct%"
                    }
                }
                $chartSim.Series.Add($s)

                function Add-LegendItem($name, $color) { $dum=New-Object System.Windows.Forms.DataVisualization.Charting.Series; $dum.Name=$name; $dum.Color=$color; $dum.ChartType="Column"; $chartSim.Series.Add($dum); [void]$dum.Points.AddXY(-1000,0) }
                Add-LegendItem "Lucky (<74)" "LimeGreen"; Add-LegendItem "Soft Pity (74-85)" "Gold"; Add-LegendItem "Hard Pity (>85)" "Crimson"

                $markerSoft = 74 - $startP; $markerHard = 90 - $startP
                if ($markerSoft -gt 0) { $slSoft = New-Object System.Windows.Forms.DataVisualization.Charting.StripLine; $slSoft.IntervalOffset=$markerSoft; $slSoft.StripWidth=0.5; $slSoft.BackColor="Gold"; $slSoft.BorderDashStyle="Dash"; $slSoft.Text="Soft Pity Start"; $slSoft.TextOrientation="Rotated270"; $slSoft.TextAlignment="Far"; $slSoft.ForeColor="Gold"; $caSim.AxisX.StripLines.Add($slSoft) }
                if ($markerHard -gt 0) { $slHard = New-Object System.Windows.Forms.DataVisualization.Charting.StripLine; $slHard.IntervalOffset=$markerHard; $slHard.StripWidth=0.5; $slHard.BackColor="Red"; $slHard.Text="Hard Pity (90)"; $slHard.TextOrientation="Rotated270"; $slHard.TextAlignment="Far"; $slHard.ForeColor="Red"; $caSim.AxisX.StripLines.Add($slHard) }
                $chartSim.Update()
            }

            $fSim.Cursor="Default"; $btnSim.Enabled=$true; $btnSim.Text="RUN SIMULATION"; $btnStopSim.Enabled=$false
        })

        $fSim.ShowDialog() | Out-Null
    })
    # 2. เมนู Table Viewer
    $script:itemTable = New-Object System.Windows.Forms.ToolStripMenuItem("History Table Viewer")
    $script:itemTable.ShortcutKeys = "F9"
    $script:itemTable.ForeColor = "White"
    $script:itemTable.Enabled = $false # รอ Fetch ก่อน
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
        
        # Style: จัดสี 5 ดาวให้เด่น
        $grid.Add_CellFormatting({
            param($sender, $e)
            if ($e.RowIndex -ge 0 -and $grid.Columns[$e.ColumnIndex].Name -eq "Rank") {
                if ($e.Value -eq "5") {
                    $grid.Rows[$e.RowIndex].DefaultCellStyle.BackColor = "Gold"
                    $grid.Rows[$e.RowIndex].DefaultCellStyle.ForeColor = "Black"
                } elseif ($e.Value -eq "4") {
                    $grid.Rows[$e.RowIndex].DefaultCellStyle.BackColor = "MediumPurple"
                    $grid.Rows[$e.RowIndex].DefaultCellStyle.ForeColor = "White"
                }
            }
        })

        $fTable.ShowDialog() | Out-Null
    })
    # 3. เมนู JSON Export
    $script:itemJson = New-Object System.Windows.Forms.ToolStripMenuItem("Export Raw JSON")
    $script:itemJson.ForeColor = "White"
    $script:itemJson.Enabled = $false # รอ Fetch ก่อน
    $menuTools.DropDownItems.Add($script:itemJson) | Out-Null
    # ==========================================
    #  EVENT: JSON EXPORT
    # ==========================================
    $script:itemJson.Add_Click({
        WriteGUI-Log "Action: Export Raw JSON" "Cyan"

        # เอาข้อมูลดิบทั้งหมด (ไม่สน Filter)
        $dataToExport = $script:LastFetchedData

        if ($null -eq $dataToExport -or $dataToExport.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("No data available. Please Fetch first.", "Error", 0, 16)
            return
        }

        $sfd = New-Object System.Windows.Forms.SaveFileDialog
        $sfd.Filter = "JSON File|*.json"
        $gName = $script:CurrentGame
        $dateStr = Get-Date -Format 'yyyyMMdd_HHmm'
        $sfd.FileName = "${gName}_RawHistory_${dateStr}.json"

        if ($sfd.ShowDialog() -eq "OK") {
            try {
                # แปลงเป็น JSON และบันทึก
                $jsonStr = $dataToExport | ConvertTo-Json -Depth 5 -Compress
                [System.IO.File]::WriteAllText($sfd.FileName, $jsonStr, [System.Text.Encoding]::UTF8)
                
                WriteGUI-Log "Saved JSON to: $($sfd.FileName)" "Lime"
                [System.Windows.Forms.MessageBox]::Show("Export Successful!", "Success", 0, 64)
            } catch {
                WriteGUI-Log "Export Error: $($_.Exception.Message)" "Red"
                [System.Windows.Forms.MessageBox]::Show("Error saving file: $($_.Exception.Message)", "Error", 0, 16)
            }
        }
    })
   
    $script:itemImportJson = New-Object System.Windows.Forms.ToolStripMenuItem("Import History from JSON")
    $script:itemImportJson.ShortcutKeys = "Ctrl+O" # คีย์ลัดเท่ๆ
    $script:itemImportJson.ForeColor = "Gold"      # สีทองให้ดูเด่นว่าเป็นฟีเจอร์พิเศษ
    $menuTools.DropDownItems.Add($script:itemImportJson) | Out-Null
     # ==========================================
    # [NEW] IMPORT JSON (OFFLINE VIEWER)
    # ==========================================
    $script:itemImportJson.Add_Click({
        WriteGUI-Log "Action: Import JSON File..." "Cyan"
        
        # 1. เลือกไฟล์
        $ofd = New-Object System.Windows.Forms.OpenFileDialog
        $ofd.Filter = "JSON Files (*.json)|*.json|All Files (*.*)|*.*"
        $ofd.Title = "Select Wish History JSON"
        
        # [จุดที่แก้] เช็คผลลัพธ์ของการเลือกไฟล์
        if ($ofd.ShowDialog() -eq "OK") {
            # --- กรณี User เลือกไฟล์ (กด OK) ---
            try {
                $jsonContent = Get-Content -Path $ofd.FileName -Raw -Encoding UTF8
                $importedData = $jsonContent | ConvertFrom-Json
                
                if ($null -eq $importedData -or $importedData.Count -eq 0) {
                    WriteGUI-Log "Error: Selected JSON is empty." "Red"
                    [System.Windows.Forms.MessageBox]::Show("JSON file is empty or invalid.", "Error", 0, 48)
                    return
                }

                $script:LastFetchedData = @($importedData)
                
                # Reset & Update UI
                Reset-LogWindow
                WriteGUI-Log "Successfully loaded: $($ofd.SafeFileName)" "Lime"
                WriteGUI-Log "Total Items: $($script:LastFetchedData.Count)" "Gray"
                
                $grpFilter.Enabled = $true
                $btnExport.Enabled = $true
                Apply-ButtonStyle -Button $btnExport -BaseColorName "RoyalBlue" -HoverColorName "CornflowerBlue" -CustomFont $script:fontBold
                
                $script:itemForecast.Enabled = $true
                $script:itemTable.Enabled = $true
                $script:itemJson.Enabled = $true
                
                $form.Text = "Universal Hoyo Wish Counter v$script:AppVersion [OFFLINE VIEW: $($ofd.SafeFileName)]"
                
                # Reset Pity Meter Visual
                $script:pnlPityFill.Width = 0
                $script:lblPityTitle.Text = "Mode: Offline Viewer (Pity calculation depends on Filter)"
                $script:lblPityTitle.ForeColor = "Gold"
                
                Update-FilteredView
                [System.Windows.Forms.MessageBox]::Show("Data Loaded Successfully!", "Import Complete", 0, 64)

            } catch {
                WriteGUI-Log "Import Error: $($_.Exception.Message)" "Red"
                [System.Windows.Forms.MessageBox]::Show("Failed to read JSON: $($_.Exception.Message)", "Error", 0, 16)
            }
        } else {
            # --- [NEW] กรณี User กด Cancel หรือปิดหน้าต่าง ---
            WriteGUI-Log "Import cancelled by user." "DimGray"
        }
    })
    # 4. เมนู Planner
    $script:itemPlanner = New-Object System.Windows.Forms.ToolStripMenuItem("Savings Calculator (Planner)")
    $script:itemPlanner.ShortcutKeys = "F10"
    $script:itemPlanner.ForeColor = "White"
    $script:itemPlanner.Enabled = $true # ใช้ได้ตลอด ไม่ต้องรอ Fetch
    $menuTools.DropDownItems.Add($script:itemPlanner) | Out-Null
    # ==========================================
    #  EVENT: SAVINGS CALCULATOR (Flexible Version)
    # ==========================================
    $script:itemPlanner.Add_Click({
        WriteGUI-Log "Action: Open Savings Calculator" "Cyan"

        # 1. UI SETUP
        $fPlan = New-Object System.Windows.Forms.Form
        $fPlan.Text = "Resource Planner (Flexible Mode)"
        $fPlan.Size = New-Object System.Drawing.Size(500, 680)
        $fPlan.StartPosition = "CenterParent"
        $fPlan.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
        $fPlan.ForeColor = "White"
        $fPlan.FormBorderStyle = "FixedDialog"
        $fPlan.MaximizeBox = $false

        # Helper Functions
        function Add-Title($txt, $y) {
            $l = New-Object System.Windows.Forms.Label; $l.Text=$txt; $l.Location="20,$y"; $l.AutoSize=$true; $l.Font=$script:fontBold; $l.ForeColor="Gold"
            $fPlan.Controls.Add($l)
        }
        function Add-Label($txt, $x, $y, $color="Silver") {
            $l = New-Object System.Windows.Forms.Label; $l.Text=$txt; $l.Location="$x,$y"; $l.AutoSize=$true; $l.ForeColor=$color
            $fPlan.Controls.Add($l)
        }
        function Add-Input($val, $x, $y, $w=80) {
            $t = New-Object System.Windows.Forms.TextBox; $t.Text="$val"; $t.Location="$x,$y"; $t.Width=$w; $t.BackColor="50,50,50"; $t.ForeColor="Cyan"; $t.BorderStyle="FixedSingle"; $t.TextAlign="Center"
            $fPlan.Controls.Add($t); return $t
        }

        # --- SECTION 1: TARGET DATE ---
        Add-Title "1. TIME PERIOD" 20
        $lTarg = New-Object System.Windows.Forms.Label; $lTarg.Text="Target Date:"; $lTarg.Location="30, 50"; $lTarg.AutoSize=$true; $lTarg.ForeColor="Silver"; $fPlan.Controls.Add($lTarg)
        
        $dtpTarget = New-Object System.Windows.Forms.DateTimePicker
        $dtpTarget.Location = "120, 48"; $dtpTarget.Width = 200
        $dtpTarget.Format = "Long"
        $dtpTarget.Value = (Get-Date).AddDays(21) # Default 3 Weeks (1 Banner)
        $fPlan.Controls.Add($dtpTarget)

        $lblDays = New-Object System.Windows.Forms.Label; $lblDays.Text="Days Remaining: 21"; $lblDays.Location="330, 50"; $lblDays.AutoSize=$true; $lblDays.ForeColor="Lime"
        $fPlan.Controls.Add($lblDays)

        # --- SECTION 2: DAILY ROUTINE ---
        Add-Title "2. DAILY ROUTINE" 90
        
        Add-Label "Avg. Daily Primos:" 30 120
        $txtDailyRate = Add-Input "60" 150 118 60 
        
        Add-Label "(60 = F2P, 150 = Welkin)" 220 120 "Gray"
        
        $lblDailyTotal = New-Object System.Windows.Forms.Label; $lblDailyTotal.Text="Total: 1260"; $lblDailyTotal.Location="30, 150"; $lblDailyTotal.AutoSize=$true; $lblDailyTotal.ForeColor="Cyan"
        $fPlan.Controls.Add($lblDailyTotal)

        # --- SECTION 3: ESTIMATED LUMPSUMS ---
        Add-Title "3. ESTIMATED REWARDS" 180
        Add-Label "Manual input for Abyss, Events, Shop, Maintenance, etc." 30 205 "Gray"

        Add-Label "Est. Primos:" 30 235
        $txtEstPrimos = Add-Input "0" 150 233 100
        Add-Label "(Events / Abyss / Codes)" 260 235 "DimGray"

        Add-Label "Est. Fates:" 30 265
        $txtEstFates = Add-Input "0" 150 263 100
        Add-Label "(Shop / BP / Tree)" 260 265 "DimGray"

        # --- SECTION 4: CURRENT STASH ---
        Add-Title "4. CURRENT STASH" 310
        
        Add-Label "Current Primos:" 30 340
        $txtCurPrimos = Add-Input "0" 150 338 100

        Add-Label "Current Fates:" 30 370
        $txtCurFates = Add-Input "0" 150 368 100

        # --- SECTION 5: RESULT ---
        $pnlRes = New-Object System.Windows.Forms.Panel; $pnlRes.Location="20,410"; $pnlRes.Size="440,150"; $pnlRes.BackColor="25,25,45"; $pnlRes.BorderStyle="FixedSingle"; $fPlan.Controls.Add($pnlRes)
        
        $lRes1 = New-Object System.Windows.Forms.Label; $lRes1.Text="CALCULATION RESULT"; $lRes1.Location="10,10"; $lRes1.AutoSize=$true; $lRes1.Font=$script:fontBold; $lRes1.ForeColor="Silver"; $pnlRes.Controls.Add($lRes1)

        $lblResPrimos = New-Object System.Windows.Forms.Label; $lblResPrimos.Text="Total Primos: 0"; $lblResPrimos.Location="20,40"; $lblResPrimos.AutoSize=$true; $lblResPrimos.ForeColor="Cyan"; $pnlRes.Controls.Add($lblResPrimos)
        $lblResFates = New-Object System.Windows.Forms.Label; $lblResFates.Text="Total Fates: 0"; $lblResFates.Location="250,40"; $lblResFates.AutoSize=$true; $lblResFates.ForeColor="Cyan"; $pnlRes.Controls.Add($lblResFates)

        $lblFinalPulls = New-Object System.Windows.Forms.Label; $lblFinalPulls.Text="= 0 Pulls"; $lblFinalPulls.Location="20,80"; $lblFinalPulls.AutoSize=$true; $lblFinalPulls.Font=$script:fontHeader; $lblFinalPulls.ForeColor="Lime"; $pnlRes.Controls.Add($lblFinalPulls)

        # --- BUTTONS ---
        $btnCalc = New-Object System.Windows.Forms.Button; $btnCalc.Text="CALCULATE"; $btnCalc.Location="20, 580"; $btnCalc.Size="200, 45"
        Apply-ButtonStyle -Button $btnCalc -BaseColorName "RoyalBlue" -HoverColorName "CornflowerBlue" -CustomFont $script:fontBold
        $fPlan.Controls.Add($btnCalc)

        $btnToSim = New-Object System.Windows.Forms.Button; $btnToSim.Text="Open Simulator >"; $btnToSim.Location="240, 580"; $btnToSim.Size="220, 45"
        Apply-ButtonStyle -Button $btnToSim -BaseColorName "Indigo" -HoverColorName "SlateBlue" -CustomFont $script:fontBold
        $btnToSim.Enabled = $false
        $fPlan.Controls.Add($btnToSim)

        # --- CALCULATION LOGIC ---
        $doCalc = {
            try {
                # 1. Days Diff
                $today = Get-Date
                $target = $dtpTarget.Value
                $diff = ($target - $today).Days
                if ($diff -lt 0) { $diff = 0 }
                $lblDays.Text = "Days Remaining: $diff"

                # 2. Daily Calculation
                $rate = [int]$txtDailyRate.Text
                $dailyTotal = $diff * $rate
                $lblDailyTotal.Text = "Total: $dailyTotal"

                # 3. Summation
                $curPrimos = [int]$txtCurPrimos.Text
                $estPrimos = [int]$txtEstPrimos.Text
                
                $curFates = [int]$txtCurFates.Text
                $estFates = [int]$txtEstFates.Text

                $totalPrimos = $curPrimos + $dailyTotal + $estPrimos
                $totalFates = $curFates + $estFates
                
                $grandTotal = [math]::Floor($totalPrimos / 160) + $totalFates

                # Display
                $lblResPrimos.Text = "Total Primos: $('{0:N0}' -f $totalPrimos)"
                $lblResFates.Text = "Total Fates: $totalFates"
                $lblFinalPulls.Text = "= $grandTotal Pulls"

                # Store & Enable
                $script:tempTotalPulls = $grandTotal
                $btnToSim.Enabled = $true
            } catch {
                $lblFinalPulls.Text = "Error"
            }
        }

        # Auto-Calc Triggers (เปลี่ยนค่าปุ๊บ คำนวณปั๊บ)
        $dtpTarget.Add_ValueChanged($doCalc)
        $txtDailyRate.Add_TextChanged($doCalc)
        $txtEstPrimos.Add_TextChanged($doCalc)
        $txtEstFates.Add_TextChanged($doCalc)
        $txtCurPrimos.Add_TextChanged($doCalc)
        $txtCurFates.Add_TextChanged($doCalc)
        
        # Manual Calc Button
        $btnCalc.Add_Click($doCalc)

        # Link to Simulator
        $btnToSim.Add_Click({
            $script:PlannerBudget = $script:tempTotalPulls
            $fPlan.Close()
            
            if ($script:itemForecast.Enabled) {
                $script:itemForecast.PerformClick()
            } else {
                [System.Windows.Forms.MessageBox]::Show("Please Fetch data first to enable Simulator.", "Info", 0, 64)
            }
        })

        # Initial Run
        & $doCalc

        $fPlan.ShowDialog() | Out-Null
    })

# ------------------------------------------------------------------------------
# GROUP 2: HELP / CREDITS
# ------------------------------------------------------------------------------
$menuHelp = New-Object System.Windows.Forms.ToolStripMenuItem("Help")
[void]$menuStrip.Items.Add($menuHelp)

    
    $itemCredits = New-Object System.Windows.Forms.ToolStripMenuItem("About & Credits")
    $itemCredits.ShortcutKeys = "F1" # กด F1 เพื่อเรียกดูได้ด้วย
    [void]$menuHelp.DropDownItems.Add($itemCredits)
    $itemCredits.Add_Click({
        # 1. เคลียร์หน้าจอ
        $txtLog.Clear()
        $txtLog.SelectionAlignment = "Center"

        # --- PALETTE SETUP (กำหนดชุดสีที่ดูแพง) ---
        # ฟ้าโฮโย (Hoyo Blue): ไม่ฟ้าสด แต่เป็นฟ้าอมเขียวนิดๆ สว่างๆ
        $colTitle  = [System.Drawing.Color]::FromArgb(60, 220, 255) 
        # เทาผู้ดี (Subtle Gray): สำหรับ Version
        $colSub    = [System.Drawing.Color]::FromArgb(150, 150, 160)
        # ทองหรู (Rich Gold): เหลืองอมส้มนิดๆ ไม่ใช่เหลืองมะนาว
        $colGold   = [System.Drawing.Color]::FromArgb(255, 200, 60)
        # เขียวพาสเทล (Mint Green): อ่านง่ายสบายตา
        $colQuote  = [System.Drawing.Color]::FromArgb(140, 255, 170)
        # เทาเข้ม (Dark Footer): จางๆ
        $colFooter = [System.Drawing.Color]::FromArgb(80, 80, 90)

        # --- HEADER ---
        $txtLog.SelectionFont = New-Object System.Drawing.Font("Consolas", 14, [System.Drawing.FontStyle]::Bold)
        $txtLog.SelectionColor = $colTitle
        # ใช้เส้นขีดบางๆ แทนเครื่องหมายเท่ากับ จะดู Modern กว่า
        $txtLog.AppendText("`n________________________________`n`n")
        $txtLog.AppendText(" HOYO WISH COUNTER (ULTIMATE) `n")
        $txtLog.AppendText("________________________________`n`n")

        # --- VERSION ---
        $txtLog.SelectionFont = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
        $txtLog.SelectionColor = $colSub
        # ใช้สัญลักษณ์ • คั่นกลาง
        $txtLog.AppendText("UI v$script:AppVersion  |  Engine v$script:EngineVersion`n`n`n")

        # --- DEVELOPER ---
        $txtLog.SelectionFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
        $txtLog.SelectionColor = "WhiteSmoke" # ขาวควันบุหรี่
        $txtLog.AppendText("Created & Designed by`n")

        $txtLog.SelectionFont = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold)
        $txtLog.SelectionColor = $colGold
        # ใส่ Space รอบชื่อให้ดูโปร่ง
        $txtLog.AppendText(" PHUNYAWEE `n`n") 

        # --- QUOTE ---
        $txtLog.SelectionFont = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Italic)
        $txtLog.SelectionColor = $colQuote
        $txtLog.AppendText("`"May all your pulls be gold...`nand your 50/50s never lost.`"`n`n`n")

        # --- FOOTER ---
        $txtLog.SelectionFont = New-Object System.Drawing.Font("Consolas", 8, [System.Drawing.FontStyle]::Regular)
        $txtLog.SelectionColor = $colFooter
        $txtLog.AppendText("Powered by PowerShell & .NET WinForms`n")
        $txtLog.AppendText("Data Source: Official Game Cache API`n")
        
        # 3. คืนค่า
        $txtLog.SelectionAlignment = "Left"
        $txtLog.SelectionStart = 0 
    })
    # ---------------------------------------------------------
    # MENU: CHECK UPDATE / VERSION STATUS (NEW WINDOW)
    # ---------------------------------------------------------
    $itemUpdate = New-Object System.Windows.Forms.ToolStripMenuItem("Check for Updates")
    [void]$menuHelp.DropDownItems.Add($itemUpdate)
    $itemUpdate.Add_Click({
        # 1. Setup Form
        $fUpd = New-Object System.Windows.Forms.Form
        $fUpd.Text = "System Status"
        $fUpd.Size = New-Object System.Drawing.Size(350, 450)
        $fUpd.StartPosition = "CenterParent"
        $fUpd.FormBorderStyle = "FixedToolWindow" # ไม่มีปุ่มย่อขยาย
        $fUpd.BackColor = [System.Drawing.Color]::FromArgb(25, 25, 30)
        $fUpd.ForeColor = "White"

        # Helper: จัดกึ่งกลางอัตโนมัติ (จะได้ไม่ต้องคำนวณ X เอง)
        function Center-Control($ctrl) {
            $ctrl.Left = ($fUpd.ClientSize.Width - $ctrl.Width) / 2
        }

        # --- TITLE ---
        $lblHead = New-Object System.Windows.Forms.Label
        $lblHead.Text = "VERSION CONTROL"
        $lblHead.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $lblHead.ForeColor = "DimGray"
        $lblHead.AutoSize = $true
        $lblHead.Top = 25
        $fUpd.Controls.Add($lblHead)
        
        # --- 1. APP VERSION (UI) ---
        $lblAppTitle = New-Object System.Windows.Forms.Label
        $lblAppTitle.Text = "Interface Version"
        $lblAppTitle.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
        $lblAppTitle.ForeColor = "Silver"
        $lblAppTitle.AutoSize = $true
        $lblAppTitle.Top = 60
        $fUpd.Controls.Add($lblAppTitle)

        $lblAppVer = New-Object System.Windows.Forms.Label
        $lblAppVer.Text = "$script:AppVersion"
        $lblAppVer.Font = New-Object System.Drawing.Font("Segoe UI", 26, [System.Drawing.FontStyle]::Bold)
        $lblAppVer.ForeColor = [System.Drawing.Color]::SpringGreen # สีเขียวเด่นๆ
        $lblAppVer.AutoSize = $true
        $lblAppVer.Top = 80
        $fUpd.Controls.Add($lblAppVer)

        # --- SEPARATOR LINE ---
        $pnlLine = New-Object System.Windows.Forms.Panel
        $pnlLine.Size = New-Object System.Drawing.Size(200, 1)
        $pnlLine.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
        $pnlLine.Top = 145
        $fUpd.Controls.Add($pnlLine)

        # --- 2. ENGINE VERSION (Backend) ---
        $lblEngTitle = New-Object System.Windows.Forms.Label
        $lblEngTitle.Text = "Core Engine Version"
        $lblEngTitle.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
        $lblEngTitle.ForeColor = "Silver"
        $lblEngTitle.AutoSize = $true
        $lblEngTitle.Top = 165
        $fUpd.Controls.Add($lblEngTitle)

        $lblEngVer = New-Object System.Windows.Forms.Label
        $lblEngVer.Text = "$script:EngineVersion"
        $lblEngVer.Font = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold)
        $lblEngVer.ForeColor = [System.Drawing.Color]::Gold # สีทอง
        $lblEngVer.AutoSize = $true
        $lblEngVer.Top = 185
        $fUpd.Controls.Add($lblEngVer)

        # --- GITHUB BUTTON ---
        $btnGit = New-Object System.Windows.Forms.Button
        $btnGit.Text = "Check GitHub for Updates"
        $btnGit.Size = New-Object System.Drawing.Size(220, 40)
        $btnGit.Top = 260
        $btnGit.BackColor = [System.Drawing.Color]::FromArgb(50, 50, 70)
        $btnGit.ForeColor = "White"
        $btnGit.FlatStyle = "Flat"
        $btnGit.FlatAppearance.BorderSize = 0
        $btnGit.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
        $btnGit.Cursor = [System.Windows.Forms.Cursors]::Hand
        
        # Event: เปิดเว็บ
        $btnGit.Add_Click({
            [System.Diagnostics.Process]::Start("https://github.com/Phunyawee/HOYO_GACHA_COUNTER")
        })
        $fUpd.Controls.Add($btnGit)

        # --- CLOSE BUTTON ---
        $btnClose = New-Object System.Windows.Forms.Button
        $btnClose.Text = "Close Window"
        $btnClose.Size = New-Object System.Drawing.Size(120, 30)
        $btnClose.Top = 360
        $btnClose.ForeColor = "Gray"
        $btnClose.FlatStyle = "Flat"
        $btnClose.FlatAppearance.BorderSize = 0
        $btnClose.Cursor = [System.Windows.Forms.Cursors]::Hand
        $btnClose.Add_Click({ $fUpd.Close() })
        $fUpd.Controls.Add($btnClose)

        # จัดกึ่งกลางทุกอย่างก่อนโชว์
        Center-Control $lblHead
        Center-Control $lblAppTitle
        Center-Control $lblAppVer
        Center-Control $pnlLine
        Center-Control $lblEngTitle
        Center-Control $lblEngVer
        Center-Control $btnGit
        Center-Control $btnClose

        $fUpd.ShowDialog()
    })



# ------------------------------------------------------------------------------
# GROUP 4: SPECIAL BUTTON (Toggle Expand)
# ------------------------------------------------------------------------------
# 2. [NEW] ปุ่ม Toggle Expand (ขวาสุด)
$menuExpand = New-Object System.Windows.Forms.ToolStripMenuItem(">> Show Graph")
$menuExpand.Alignment = "Right" # สั่งชิดขวา
$menuExpand.ForeColor = $script:Theme.Accent  # สีฟ้าเด่นๆ
$menuExpand.Font = $script:fontBold
[void]$menuStrip.Items.Add($menuExpand)

# ตัวแปรสถานะ
$script:isExpanded = $false

# Event คลิกปุ่มนี้
$menuExpand.Add_Click({
    if ($script:isExpanded) {
        WriteGUI-Log "Action: Collapse Graph Panel (Hide)" "DimGray"
        # ยุบกลับ
        $form.Width = 600
        $menuExpand.Text = ">> Show Graph"
        $script:isExpanded = $false
    } else {
        WriteGUI-Log "Action: Expand Graph Panel (Show)" "Cyan"  
        # ขยายออก
        $form.Width = 1200
        $menuExpand.Text = "<< Hide Graph"
        $script:isExpanded = $true
        
        $pnlChart.Size = New-Object System.Drawing.Size(580, 880)

        # สั่งวาดกราฟ (ถ้ามีข้อมูล)
        if ($grpFilter.Enabled) { Update-FilteredView }
    }
})



# ==============================================================
# 4. Styling Loop (วางไว้ล่างสุดตรงนี้!)
# ==============================================================
# วนลูปเพื่อบังคับให้ทุกปุ่มเป็นสีขาว (จะได้ไม่หลุด Theme)
foreach ($topItem in $menuStrip.Items) {
    # ยกเว้นปุ่ม Expand ให้ใช้สี Accent (ฟ้า)
    if ($topItem -eq $menuExpand) {
        $topItem.ForeColor = $script:Theme.Accent
    } else {
        $topItem.ForeColor = "White"
    }
    
    # บังคับลูกๆ (Sub-items) ให้ขาวด้วย
    foreach ($subItem in $topItem.DropDownItems) {
        $subItem.ForeColor = "White"
        $subItem.BackColor = [System.Drawing.Color]::Black 
    }
}
