#System/SettingWindow.ps1

function Show-SettingsWindow {
    Write-Host "--- [Settings] Initializing Settings Window ---" -ForegroundColor Cyan
    
    # 1. SETUP ENVIRONMENT
    # ---------------------------------------------------------
    # กำหนด Root ของโปรแกรม (ถอยจาก System/ViewLoader ออกมา 1 ขั้น)
    $AppRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    
    # Load Config ล่าสุด
    $conf = Get-AppConfig 

    # 2. CREATE MAIN CONTAINER (SKELETON)
    # ---------------------------------------------------------
    $fSet = New-Object System.Windows.Forms.Form
    $fSet.Text = "Preferences & Settings"
    $fSet.Size = New-Object System.Drawing.Size(550, 600)
    $fSet.StartPosition = "CenterParent"
    $fSet.BackColor = [System.Drawing.Color]::FromArgb(35, 35, 35)
    $fSet.ForeColor = "White"
    $fSet.FormBorderStyle = "FixedToolWindow"

    # Tab Control หลัก
    $tabs = New-Object System.Windows.Forms.TabControl
    $tabs.Dock = "Top" 
    $tabs.Height = 480 
    $tabs.Appearance = "FlatButtons"
    $fSet.Controls.Add($tabs)

    # Helper Function: ต้องประกาศไว้ตรงนี้เพื่อให้ไฟล์ลูกเรียกใช้ได้
    function New-Tab($title) { 
        $page = New-Object System.Windows.Forms.TabPage
        $page.Text = "  $title  "
        $page.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 45)
        $tabs.TabPages.Add($page)
        return $page 
    }

    # 3. DEFINE COMPONENT LIST
    # ---------------------------------------------------------
    # เรียงลำดับไฟล์ตาม Logic (Tab 1-5 -> Footer)
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

    # 4. ORCHESTRATOR LOOP (THE LOADER)
    # ---------------------------------------------------------
    foreach ($ItemName in $SettingComponents) {
        $FullPath = Join-Path $SettingChildPath $ItemName

        if (Test-Path $FullPath) {
            try {
                # [Dot-Source] โหลดไฟล์เข้า Scope ของ Function นี้
                . $FullPath
                
                $SetLoadedCount++
                # Optional: Log แบบ Console (ปิดได้ถ้ารก)
                # Write-Host "  + [Settings] Loaded: $ItemName" -ForegroundColor Gray

            } catch {
                Write-Host "  ! [Settings] ERROR loading $ItemName : $_" -ForegroundColor Red
                
                if (Get-Command "Write-LogFile" -ErrorAction SilentlyContinue) {
                    # [FIXED] ใส่ $() ครอบ $ItemName และ $_ เพื่อกัน Error เรื่อง Syntax
                    Write-LogFile -Message "[Settings] Fatal Error loading $($ItemName): $($_)" -Level "ERROR"
                }
            }
        } else {
            Write-Host "  ! [Settings] MISSING FILE: $ItemName" -ForegroundColor Yellow
        }
    }

    # 5. FINALIZE & SHOW
    # ---------------------------------------------------------
    Write-Host "[Settings] Assembly Complete ($SetLoadedCount / $($SettingComponents.Count) tabs)." -ForegroundColor Green
    
    if (Get-Command "Write-LogFile" -ErrorAction SilentlyContinue) {
        Write-LogFile -Message "[Settings] Window Opened. Components loaded: $SetLoadedCount" -Level "INFO"
    }

    # แสดงผล
    $fSet.ShowDialog()
    
    # Cleanup
    $fSet.Dispose()
}