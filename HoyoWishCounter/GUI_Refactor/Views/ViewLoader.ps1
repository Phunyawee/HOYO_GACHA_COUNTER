# views/ViewLoader.ps1

# ==============================================================================
#  UI COMPONENT LOADER (VIEW MANAGER)
# ==============================================================================

# 1. กำหนดลำดับการโหลด (สำคัญมาก! ห้ามสลับ)
# ไฟล์ทั้งหมดนี้ต้องอยู่ในโฟลเดอร์ views/
$ViewComponents = @(
    "MainLayout.ps1",       # 1. สร้าง Form หลัก (ต้องมาก่อนเพื่อน)
    "MenuBar.ps1",          # 2. เมนูด้านบน
    "GameSelector.ps1",     # 3. ปุ่มเลือกเกม
    "SettingsPanel.ps1",    # 4. แผงตั้งค่า
    "PityMeter.ps1",        # 5. หลอด Pity
    "ActionAndStats.ps1",   # 6. ปุ่มกดและ Stat ย่อ
    "FilterPanel.ps1",      # 7. ตัวกรอง
    "LogWindow.ps1",        # 8. หน้าต่าง Log
    "ExportPanel.ps1",      # 9. ปุ่ม Export (ล่างสุด)
    "AnalyticsPanel.ps1"    # 10. กราฟ (ซ่อนอยู่)
)

$ViewLoadedCount = 0
$ViewTotalCount = $ViewComponents.Count

Write-LogFile -Message "--- [UI] Starting View Assembly ---" -Level "INFO"

# 2. วนลูปโหลดทีละไฟล์
foreach ($FileName in $ViewComponents) {
    
    # Logic หาไฟล์ (สมมติว่าไฟล์นี้อยู่ใน views/ และไฟล์ย่อยก็อยู่ใน views/)
    $FullPath = Join-Path $PSScriptRoot $FileName

    if (Test-Path $FullPath) {
        try {
            # โหลดไฟล์เข้า Scope หลัก
            . $FullPath
            
            # บันทึก Log
            if (Get-Command "Write-LogFile" -ErrorAction SilentlyContinue) {
                Write-LogFile -Message "[UI] Loaded component: $FileName" -Level "INFO"
            }
            $ViewLoadedCount++

        } catch {
            # ถ้าโหลดไม่ขึ้น (โดยเฉพาะ MainLayout) ถือเป็นเรื่องใหญ่
            Write-Host "[CRITICAL UI ERROR] Failed to load $FileName : $_" -ForegroundColor Red
            if (Get-Command "Write-LogFile" -ErrorAction SilentlyContinue) {
                Write-LogFile -Message "[UI] Failed to load $FileName : $_" -Level "FATAL"
            }
            
            # ถ้า MainLayout พัง โปรแกรมไปต่อไม่ได้
            if ($FileName -eq "MainLayout.ps1") {
                throw "Critical UI Failure: MainLayout missing or corrupt."
            }
        }
    } else {
        # ไฟล์หาย
        Write-Host "[MISSING UI] Component not found: $FileName" -ForegroundColor Red
        if (Get-Command "Write-LogFile" -ErrorAction SilentlyContinue) {
            Write-LogFile -Message "[UI] Component not found: $FullPath" -Level "ERROR"
        }
    }
}

# ==============================================================================
# FINAL UI REPORT
# ==============================================================================

if ($ViewLoadedCount -eq $ViewTotalCount) {
    Write-LogFile -Message "[UI] View Assembly Complete. All components loaded ($ViewLoadedCount/$ViewTotalCount)." -Level "INFO"
} else {
    $WarnMsg = "UI Assembly completed with ERRORS. ($ViewLoadedCount/$ViewTotalCount loaded)"
    Write-LogFile -Message "[UI] $WarnMsg" -Level "WARN"
    Write-Host ">> $WarnMsg" -ForegroundColor Red
}