function Apply-ButtonStyle {
    param($Button, $BaseColorName, $HoverColorName, $CustomFont)

    $Button.FlatStyle = "Flat"
    $Button.FlatAppearance.BorderSize = 0
    $Button.BackColor = [System.Drawing.Color]::FromName($BaseColorName)
    $Button.ForeColor = "White"
    $Button.Cursor = [System.Windows.Forms.Cursors]::Hand 
    
    if ($CustomFont) { $Button.Font = $CustomFont } 
    else { $Button.Font = $script:fontBold }

    # 1. ใช้ $this แทน $Button (เพื่อให้มันรู้ว่าคือปุ่มตัวเอง)
    # 2. ใช้ .GetNewClosure() เพื่อล็อคค่าสีไว้ในหน่วยความจำ
    $enterEvent = { 
        $this.BackColor = [System.Drawing.Color]::FromName($HoverColorName) 
    }.GetNewClosure()

    $leaveEvent = { 
        if ($this.Enabled) {
            $this.BackColor = [System.Drawing.Color]::FromName($BaseColorName) 
        }
    }.GetNewClosure()

    $Button.Add_MouseEnter($enterEvent)
    $Button.Add_MouseLeave($leaveEvent)
}

function Get-ColorFromHex {
    param($Hex)
    try {
        return [System.Drawing.ColorTranslator]::FromHtml($Hex)
    } catch {
        return [System.Drawing.Color]::Cyan # Fallback กรณีโค้ดสีผิด
    }
}


function Reset-LogWindow {
    # 1. ล้างข้อความ
    # (ใช้ $script:txtLog เพื่อความชัวร์ว่าอ้างถึงตัวแปร Global จาก App.ps1)
    if ($script:txtLog) {
        $script:txtLog.Clear()
        
        # 2. บังคับคืนค่า Style
        $script:txtLog.SelectionAlignment = "Left"       # ชิดซ้าย
        
        # เช็คว่ามี Font Log ให้ใช้ไหม ถ้าไม่มีใช้ Default
        if ($script:fontLog) { 
            $script:txtLog.SelectionFont = $script:fontLog 
        } else {
            $script:txtLog.SelectionFont = New-Object System.Drawing.Font("Consolas", 10)
        }
        
        $script:txtLog.SelectionColor = "Lime"           # สีเขียว
    }
}

function WriteGUI-Log($msg, $color="Lime") { 
    try {
        # --- 1. ส่วนแสดงผลใน Debug Console (PowerShell Window) ---
        if ($script:DebugMode) {
            $consoleColor = "White" # Default
            switch ($color) {
                "Lime"      { $consoleColor = "Green" }
                "Gold"      { $consoleColor = "Yellow" }
                "OrangeRed" { $consoleColor = "Red" }
                "Crimson"   { $consoleColor = "Red" }
                "DimGray"   { $consoleColor = "DarkGray" }
                "Cyan"      { $consoleColor = "Cyan" }
                "Magenta"   { $consoleColor = "Magenta" }
                "Gray"      { $consoleColor = "Gray" }
                "Yellow"    { $consoleColor = "Yellow" }
            }
            
            $timeStamp = Get-Date -Format "HH:mm:ss"
            Write-Host "[$timeStamp] $msg" -ForegroundColor $consoleColor
        }

        # --- 2. ส่งไปเก็บลงไฟล์ (Log ปกติ) ---
        if (Get-Command "Write-LogFile" -ErrorAction SilentlyContinue) {
            Write-LogFile -Message $msg -Level "USER_ACTION"
        }

        # --- 3. ส่วนแสดงผลใน GUI ---
        if ($script:txtLog) {
            # ตรวจสอบว่า Control ยังไม่ถูก Dispose (ป้องกัน Error กรณีปิดหน้าต่างไปแล้วแต่ Script ยังรัน)
            if (-not $script:txtLog.IsDisposed) {
                $script:txtLog.SelectionStart = $script:txtLog.Text.Length
                $script:txtLog.SelectionColor = [System.Drawing.Color]::FromName($color)
                $script:txtLog.AppendText("$msg`n")
                $script:txtLog.ScrollToCaret() 
            }
        }
    }
    catch {
        # --- 4. ส่วนจัดการ Error (Catch Block) ---
        # ดึงข้อความ Error ออกมา
        $errorMessage = $_.Exception.Message
        
        # เขียน Error ลงไฟล์ Log ทันที
        if (Get-Command "Write-LogFile" -ErrorAction SilentlyContinue) {
            Write-LogFile -Message "SYSTEM ERROR in Log Function: $errorMessage | Original Msg: $msg" -Level "ERROR"
        }
        
        # (Optional) แสดง Error ใน Console ด้วยเผื่อ DebugMode เปิดอยู่
        Write-Host "Error in Log function: $errorMessage" -ForegroundColor Red
    }
}


function Update-BannerList {
    # เรียกใช้ Config (ตามที่คุณแจ้งว่ามีอยู่แล้ว)
    $conf = Get-GameConfig $script:CurrentGame
    
    # อ้างถึงตัวแปร UI ผ่าน $script:
    if ($script:cmbBanner) {
        $script:cmbBanner.Items.Clear()
        
        # เติม [void] ข้างหน้า เพื่อปิดปากไม่ให้มันคืนค่าตัวเลขออกมาทาง Pipeline
        [void]$script:cmbBanner.Items.Add("* FETCH ALL (Recommended)") 
        
        # ตรวจสอบว่า Config มีค่า Banners ส่งมาจริงไหมก่อน Loop
        if ($conf -and $conf.Banners) {
            foreach ($b in $conf.Banners) {
                [void]$script:cmbBanner.Items.Add("$($b.Name)")
            }
        }
        
        # เลือกตัวเลือกแรก (FETCH ALL) เป็นค่าเริ่มต้น
        if ($script:cmbBanner.Items.Count -gt 0) {
            $script:cmbBanner.SelectedIndex = 0
        }
    }
}