# views/MainLayout.ps1

# ============================
#  UI SECTION (FIXED LAYOUT)
# ============================

# สร้าง Form หลัก
$form = New-Object System.Windows.Forms.Form

# กำหนดชื่อ Title (ต้องประกาศ $script:AppVersion ใน App.ps1 มาก่อนนะ)
$form.Text = "Universal Hoyo Wish Counter v$script:AppVersion"

# กำหนดขนาด (เอา 900 ตาม snippet ล่าง เพื่อให้พอดีกับปุ่ม Export ที่เพิ่มมา)
$form.Size = New-Object System.Drawing.Size(600, 900)

# ตำแหน่งและสี
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$form.ForeColor = "White"

# ล็อคขนาดหน้าต่าง ไม่ให้ User ยืดหด (เดี๋ยว Layout พัง)
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false

# (Optional) ถ้ามี Icon
# $iconPath = Join-Path $PSScriptRoot "app.ico"
# if (Test-Path $iconPath) { $form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($iconPath) }

# --- TOOLTIP MANAGER ---
$toolTip = New-Object System.Windows.Forms.ToolTip
$toolTip.AutoPopDelay = 5000    # โชว์นาน 5 วิ
$toolTip.InitialDelay = 500     # รอ 0.5 วิค่อยขึ้น
$toolTip.ReshowDelay = 500      # ถ้าขยับเมาส์ไปตัวอื่นก็รอ 0.5 วิ
$toolTip.ShowAlways = $true
$toolTip.IsBalloon = $false     # เอาแบบสี่เหลี่ยมเรียบๆ (ถ้าอยากได้บอลลูนแก้เป็น $true)



# ============================
#  CLOSING SPLASH LOGIC
# ============================

# [FIX] จับ Path ปัจจุบัน (views) แล้วถอยออก 1 ขั้นเพื่อไปหา Root
$currentDir = if ($PSScriptRoot) { $PSScriptRoot } else { $script:PSScriptRoot }
$projectRoot = Split-Path $currentDir -Parent  # ถอยจาก views -> Project Root

$form.Add_FormClosing({
    try {
        $this.Hide()

        # Save & Log
        if ($script:AppConfig) {
            $script:AppConfig.LastGame = $script:CurrentGame
            Save-AppConfig -ConfigObj $script:AppConfig
        }
        if (Get-Command "Write-LogFile" -ErrorAction SilentlyContinue) {
            Write-LogFile -Message "Application Shutdown Sequence Initiated." -Level "STOP"
        }

        # Config
        $WaitSeconds = 2.0      
        $FadeSpeed   = 30
        $script:SkipClosing = $false 

        # [FIXED PATH] ใช้ $projectRoot แทน (ชี้ไปที่โฟลเดอร์หลัก)
        $exitPath = Join-Path $projectRoot "Image\splash_exit.gif"
        
        # Fallback เช็คเผื่อไม่เจอ
        if (-not (Test-Path $exitPath)) { $exitPath = Join-Path $projectRoot "Image\splash_exit.png" }
        if (-not (Test-Path $exitPath)) { $exitPath = Join-Path $projectRoot "Image\splash.png" }

        if (Test-Path $exitPath) {
            $closeSplash = New-Object System.Windows.Forms.Form
            $closeSplash.FormBorderStyle = "None"
            $closeSplash.StartPosition = "CenterScreen"
            $closeSplash.ShowInTaskbar = $false
            $closeSplash.TopMost = $true
            
            $img = [System.Drawing.Image]::FromFile($exitPath)
            $closeSplash.Size = $img.Size

            # PictureBox
            $picBox = New-Object System.Windows.Forms.PictureBox
            $picBox.Dock = "Fill"
            $picBox.Image = $img
            $picBox.SizeMode = "StretchImage"
            $closeSplash.Controls.Add($picBox)

            # ปุ่ม X
            $lblExit = New-Object System.Windows.Forms.Label
            $lblExit.Text = "X"
            $lblExit.Font = New-Object System.Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Bold)
            $lblExit.Size = New-Object System.Drawing.Size(40, 40)
            $lblExit.TextAlign = "MiddleCenter"
            $lblExit.Cursor = [System.Windows.Forms.Cursors]::Hand
            $lblExit.ForeColor = "Red"       
            $lblExit.BackColor = "Transparent"
            $lblExit.Parent = $picBox        
            $lblExit.Location = New-Object System.Drawing.Point(($img.Width - 40), 0)

            # Events
            $lblExit.Add_MouseEnter({ $this.BackColor = "Crimson"; $this.ForeColor = "White" })
            $lblExit.Add_MouseLeave({ $this.BackColor = "Transparent"; $this.ForeColor = "Red" })
            $lblExit.Add_Click({ $script:SkipClosing = $true })

            # Text
            $lblBye = New-Object System.Windows.Forms.Label
            $lblBye.Text = "Saving Data..."
            if ($script:fontBold) { $lblBye.Font = $script:fontBold } else { $lblBye.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold) }
            $lblBye.ForeColor = "White"
            $lblBye.BackColor = "Transparent"
            $lblBye.Parent = $picBox
            $lblBye.AutoSize = $true
            $yPos = [int]$closeSplash.Height - 30
            $lblBye.Location = New-Object System.Drawing.Point(10, $yPos)

            $closeSplash.Show()
            $closeSplash.Refresh()

            # Loop 1: Wait & DoEvents (เพื่อให้ GIF ขยับ)
            $steps = $WaitSeconds * 20 
            for ($i=0; $i -lt $steps; $i++) {
                if ($script:SkipClosing) { break }
                Start-Sleep -Milliseconds 50
                [System.Windows.Forms.Application]::DoEvents()
            }

            # Loop 2: Fade Out
            if (-not $script:SkipClosing) {
                for ($op = 1; $op -ge 0; $op -= 0.05) {
                    if ($script:SkipClosing) { break }
                    $closeSplash.Opacity = $op
                    Start-Sleep -Milliseconds $FadeSpeed
                    [System.Windows.Forms.Application]::DoEvents()
                }
            }

            $closeSplash.Close()
            $closeSplash.Dispose()
            $img.Dispose()
        }
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Splash Error: $($_.Exception.Message)")
    }
})