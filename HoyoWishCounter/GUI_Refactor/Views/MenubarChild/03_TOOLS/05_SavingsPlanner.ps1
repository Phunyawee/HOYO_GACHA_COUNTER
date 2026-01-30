# ---------------------------------------------------------------------------
# MODULE: 05_SavingsPlanner.ps1
# DESCRIPTION: Calculator for estimating future resources (Primos/Fates)
# PARENT: 03_TOOLS.ps1
# ---------------------------------------------------------------------------

# 5. เมนู Planner
$script:itemPlanner = New-Object System.Windows.Forms.ToolStripMenuItem("Savings Calculator (Planner)")
$script:itemPlanner.ShortcutKeys = "F10"
$script:itemPlanner.ForeColor = "White"
$script:itemPlanner.Enabled = $true # ใช้ได้ตลอด ไม่ต้องรอ Fetch

# เพิ่มลงใน Menu Tools
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

    # Helper Functions (เฉพาะใน Scope นี้)
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

    # Link to Simulator (เชื่อมกลับไปหาไฟล์ 01)
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