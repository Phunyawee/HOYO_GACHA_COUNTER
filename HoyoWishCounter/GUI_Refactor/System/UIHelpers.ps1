

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

# 3. [สำคัญ] สร้าง Theme Palette
# เราจะใช้ตัวแปรพวกนี้แทนการพิมพ์ชื่อสีตรงๆ
$MainColor = Get-ColorFromHex $script:AppConfig.AccentColor

$script:Theme = @{
    # Accent: สีหลักของธีม (ใช้กับ Input, Active items, Highlight)
    Accent     = $MainColor
    
    # Text: สีตัวหนังสือทั่วไป
    TextMain   = [System.Drawing.Color]::White
    TextSub    = [System.Drawing.Color]::Silver
    TextDim    = [System.Drawing.Color]::Gray
    
    # Functional: สีสถานะ (ไม่ควรเปลี่ยนตามธีม)
    Success    = [System.Drawing.Color]::Lime
    Warning    = [System.Drawing.Color]::Gold
    Error      = [System.Drawing.Color]::Crimson
    
    # Background: สีพื้นหลัง
    BgMain     = [System.Drawing.Color]::FromArgb(30, 30, 30)
    BgControl  = [System.Drawing.Color]::FromArgb(45, 45, 45)
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