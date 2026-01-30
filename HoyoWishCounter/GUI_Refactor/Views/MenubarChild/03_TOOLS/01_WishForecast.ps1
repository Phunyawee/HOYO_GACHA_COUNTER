# ---------------------------------------------------------------------------
# MODULE: 01_WishForecast.ps1
# DESCRIPTION: Gacha Simulator & Wish Counter Logic
# PARENT: 03_TOOLS.ps1 (Requires $menuTools, $script:CurrentGame context)
# ---------------------------------------------------------------------------

# สร้างเมนูย่อย Simulator
$script:itemForecast = New-Object System.Windows.Forms.ToolStripMenuItem("Wish Forecast (Simulator)")
$script:itemForecast.ShortcutKeys = "F8"  # คีย์ลัดกด F8 ได้เลย เท่ๆ
$script:itemForecast.Enabled = $false     # ปิดไว้ก่อน รอ Fetch เสร็จ
$script:itemForecast.ForeColor = "White"

# เพิ่มลงใน Menu Tools (ตัวแปร $menuTools ต้องถูกประกาศไว้ในไฟล์แม่แล้ว)
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
        
        try {
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
        }
        finally {
            $fSim.Cursor="Default"; 
            $btnSim.Enabled=$true; 
            $btnSim.Text="RUN SIMULATION"; 
            $btnStopSim.Enabled=$false
        }
    })

    $fSim.ShowDialog() | Out-Null
})