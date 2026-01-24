# ==============================================================================
# HOYO ENGINE - Core Logic Library & Bootstrapper
# ==============================================================================
$script:EngineVersion = "7.0.0"
Add-Type -AssemblyName System.Web

# รายชื่อ Module ที่ต้องการโหลด (เรียงตามลำดับความสำคัญ)
$EngineModules = @(
    "ConfigManager.ps1",      # สำคัญสุด ต้องมาก่อน
    "GameFileManager.ps1",
    "AuthManager.ps1",
    "ApiManager.ps1",
    "GachaStatsManager.ps1",
    "SimManager.ps1",
    "DiscordManager.ps1",
    "EmailManager.ps1"
)

# ตัวแปรนับจำนวน
$LoadedCount = 0
$TotalCount = $EngineModules.Count

# วนลูปโหลดทีละไฟล์ (และ Write-GuiLogบอกทีละบรรทัดเหมือนเดิม)
foreach ($moduleName in $EngineModules) {
    $fullPath = Join-Path $PSScriptRoot $moduleName
    
    if (Test-Path $fullPath) {
        try {
            # โหลดไฟล์เข้าสู่ Scope ปัจจุบัน
            . $fullPath
            
            # นับเพิ่มเมื่อโหลดสำเร็จ
            $LoadedCount++
            
            # แจ้ง Write-GuiLogทันทีที่โหลดเสร็จ (ตามสไตล์เดิม)
            if (Get-Command "Write-LogFile" -ErrorAction SilentlyContinue) {
                Write-LogFile -Message "[Engine] Loaded module: $moduleName" -Level "INFO"
            } else {
                Write-Host "[Engine] Loaded module: $moduleName" -ForegroundColor DarkGray
            }
        } catch {
            Write-Host "[CRITICAL ERROR] Failed to load $moduleName : $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "[MISSING] Module not found: $moduleName" -ForegroundColor Red
    }
}

# --- SHARED UTILITIES ---

# ฟังก์ชัน Wrapper สำหรับส่งข้อความ (รองรับทั้ง GUI และ Console Mode)
function Log-Status {
    param($msg, $color="Yellow")

    # 1. ส่งลงไฟล์ Log
    if (Get-Command "Write-LogFile" -ErrorAction SilentlyContinue) {
        Write-LogFile -Message "[ENGINE] $msg" -Level "INFO"
    }

    # 2. ส่งเข้าหน้าจอ GUI
    if (Get-Command "WriteGUI-Log" -ErrorAction SilentlyContinue) {
        WriteGUI-Log $msg $color
    } else {
        # 3. Fallback
        try {
            Write-Host ">> $msg" -ForegroundColor $color
        } catch {
            Write-Host ">> $msg"
        }
    }
}

# --- FINAL REPORT ---
# แจ้งสถานะสรุปบรรทัดสุดท้าย

if ($LoadedCount -eq $TotalCount) {
    # สีเขียว ถ้าครบ
    Log-Status "HoyoEngine v$script:EngineVersion initialized. ($LoadedCount/$TotalCount modules loaded)" "Green"
} else {
    # สีแดง ถ้ามาไม่ครบ
    Log-Status "HoyoEngine initialized with WARNINGS. ($LoadedCount/$TotalCount modules loaded)" "Red"
}