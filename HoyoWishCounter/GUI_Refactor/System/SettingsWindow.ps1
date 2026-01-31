#System/SettingWindow.ps1

function Show-SettingsWindow {
    Write-LogFile -Message "[Settings] Initializing Settings Window" -Level "INFO"
    
    # 1. SETUP ENVIRONMENT
    $AppRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    $conf = Get-AppConfig 

    # 2. CREATE MAIN CONTAINER
    $fSet = New-Object System.Windows.Forms.Form
    $fSet.Text = "Preferences & Settings"
    $fSet.Size = New-Object System.Drawing.Size(750, 600) # ขยายกว้างขึ้นอีกนิด
    $fSet.StartPosition = "CenterParent"
    $fSet.BackColor = [System.Drawing.Color]::FromArgb(35, 35, 35)
    $fSet.ForeColor = "White"
    $fSet.FormBorderStyle = "FixedToolWindow"

    # ---------------------------------------------------------
    # [FIXED] Tab Control (Left Side) + แก้ Error DrawString
    # ---------------------------------------------------------
    $tabs = New-Object System.Windows.Forms.TabControl
    $tabs.Dock = "Fill" 
    $tabs.Alignment = "Left"  
    $tabs.SizeMode = "Fixed"  
    
    # Width=ความสูงของปุ่ม, Height=ความกว้างของปุ่ม (เมื่ออยู่ด้านซ้าย)
    $tabs.ItemSize = New-Object System.Drawing.Size(45, 180) 
    $tabs.DrawMode = "OwnerDrawFixed"
    
    $tabs.add_DrawItem({
        param($sender, $e)
        $g = $e.Graphics
        $rect = $e.Bounds
        $text = $sender.TabPages[$e.Index].Text

        # [แก้ Error ตรงนี้] แปลง Rectangle ธรรมดา เป็น RectangleF เพื่อให้ DrawString รู้จัก
        $rectF = New-Object System.Drawing.RectangleF($rect.X, $rect.Y, $rect.Width, $rect.Height)

        # ตรวจสอบสถานะการเลือก (Selected)
        if ($e.State -band [System.Windows.Forms.DrawItemState]::Selected) {
            # สีตอนเลือก
            $bgBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(65, 65, 65))
            $textBrush = [System.Drawing.Brushes]::White
            $fontStyle = [System.Drawing.FontStyle]::Bold
        } else {
            # สีปกติ
            $bgBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(35, 35, 35))
            $textBrush = [System.Drawing.Brushes]::LightGray
            $fontStyle = [System.Drawing.FontStyle]::Bold
        }

        # วาดพื้นหลัง
        $g.FillRectangle($bgBrush, $rect)

        # ตั้งค่าจัดกึ่งกลางตัวหนังสือ
        $stringFormat = New-Object System.Drawing.StringFormat
        $stringFormat.Alignment = "Center"      # กลางแนวนอน
        $stringFormat.LineAlignment = "Center"  # กลางแนวตั้ง
        
        # สร้าง Font ใหม่ตามสถานะ
        $font = New-Object System.Drawing.Font($sender.Font, $fontStyle)
        
        # วาดตัวหนังสือ (ใช้ $rectF ที่แปลงแล้ว)
        $g.DrawString($text, $font, $textBrush, $rectF, $stringFormat)
        
        # คืนหน่วยความจำ Brush ที่สร้างใหม่
        $bgBrush.Dispose()
        $font.Dispose()
    })

    $fSet.Controls.Add($tabs)
    # ---------------------------------------------------------

    # Helper Function
    function New-Tab($title) { 
        $page = New-Object System.Windows.Forms.TabPage
        $page.Text = "$title"
        $page.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 45)
        $tabs.TabPages.Add($page)
        return $page 
    }

    # 3. DEFINE COMPONENT LIST
    $SettingComponents = @(
        "01_TabGeneral.ps1",
        "02_TabAppearance.ps1",
        "03_TabIntegrations.ps1",
        "04_TabDataMaintenance.ps1",
        "07_TabEmail.ps1",
        "05_TabAdvanced.ps1",
        "06_SettingsFooter.ps1"
    )

    $SettingChildPath = Join-Path $PSScriptRoot "SettingChild"
    $SetLoadedCount = 0

    # 4. ORCHESTRATOR LOOP
    foreach ($ItemName in $SettingComponents) {
        $FullPath = Join-Path $SettingChildPath $ItemName

        if (Test-Path $FullPath) {
            try {
                . $FullPath
                $SetLoadedCount++
            } catch {
                Write-Host "  ! [Settings] ERROR loading $ItemName : $_" -ForegroundColor Red
                if (Get-Command "Write-LogFile" -ErrorAction SilentlyContinue) {
                    Write-LogFile -Message "[Settings] Fatal Error loading $($ItemName): $($_)" -Level "ERROR"
                }
            }
        } else {
            Write-Host "  ! [Settings] MISSING FILE: $ItemName" -ForegroundColor Yellow
        }
    }

    # 5. FINALIZE & SHOW
    Write-LogFile -Message "[Settings] Assembly Complete ($SetLoadedCount / $($SettingComponents.Count) tabs)." -Level "INFO"
    
    $fSet.ShowDialog()
    $fSet.Dispose()
}