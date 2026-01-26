# =============================================================================
# FILE: SettingChild\07_TabEmail.ps1
# DESCRIPTION: UI Email Settings (Loader Wrapper - Fixed Path)
# =============================================================================

# Load Charting Assembly
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms.DataVisualization")

# 1. Create Tab
$script:tEmail = New-Tab "Email Report"

# 2. Define Child Path
# ใช้ $PSScriptRoot คือ "โฟลเดอร์ปัจจุบันที่ไฟล์ 07 นี้อยู่" 
# ดังนั้นมันจะชี้ไปที่ ...\System\SettingChild\TabEmailChild ได้ถูกต้องทันที
$ChildFolder = Join-Path $PSScriptRoot "TabEmailChild"

# Debug: ปริ้นท์บอกหน่อยว่ากำลังโหลดจากไหน (เช็คใน Console ได้ถ้า Error)
Write-Host "[TabEmail] Loading modules from: $ChildFolder" -ForegroundColor DarkGray

# 3. Execute Modules (Safe Loop)
$ModuleFiles = @("01_Config.ps1", "02_Styles.ps1", "03_UI.ps1")

foreach ($file in $ModuleFiles) {
    $fullPath = Join-Path $ChildFolder $file
    
    # ใช้ -LiteralPath เพื่อรองรับ Path ที่มีช่องว่างหรือตัวอักษรพิเศษ
    if (Test-Path -LiteralPath $fullPath) {
        try {
            . $fullPath
        } catch {
            Write-Error "[TabEmail] Error running $file : $_"
        }
    } else {
        # ถ้าหาไม่เจอ จะแจ้ง Path เต็มๆ ให้เรารู้ตัว
        Write-Error "[TabEmail] FATAL: File Not Found at -> $fullPath"
    }
}