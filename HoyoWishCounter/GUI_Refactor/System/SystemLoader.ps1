# File: System/SystemLoader.ps1

# ==============================================================================
# SYSTEM LOADER & COMPONENT MANAGER
# ==============================================================================

# 1. รายชื่อไฟล์ในโฟลเดอร์ System
$SystemComponents = @(
     "..\Tools\LogFileGenerator.ps1",
     "..\Tools\LogGenerator.ps1", 
    "UIHelpers.ps1",
    "UIStyle.ps1",
    "ThemeManager.ps1",
    "DataManager.ps1",
    "SoundPlayer.ps1",
    "SettingsWindow.ps1",
    "StatisticsView.ps1"
)

$SysLoadedCount = 0
$SysTotalCount = $SystemComponents.Count

# 2. วนลูปโหลดทีละไฟล์
foreach ($FileName in $SystemComponents) {
    
    # --- [NEW] เช็คว่าถ้าเป็น LogCreate แล้วโหลดไปแล้ว ให้ข้ามเลย ---
    if ($FileName -eq "LogFileGenerator.ps1" -and (Get-Command "Write-LogFile" -ErrorAction SilentlyContinue)) {
        # ถือว่าโหลดแล้ว (จาก App.ps1) นับจำนวนแล้วข้ามไปไฟล์ถัดไปเลย
        $SysLoadedCount++
        continue
    }

    # --- Logic หาไฟล์ ---
    $FullPath = Join-Path $PSScriptRoot $FileName
    if (-not (Test-Path $FullPath)) {
        $FullPath = Join-Path $PSScriptRoot "System\$FileName"
    }

    if (Test-Path $FullPath) {
        try {
            # โหลดไฟล์เข้า Scope หลัก
            . $FullPath
            
            # --- Logging ---
            if (Get-Command "Write-LogFile" -ErrorAction SilentlyContinue) {
                Write-LogFile -Message "[System] Loaded component: $FileName" -Level "INFO"
            } else {
                # Fallback กรณี LogCreate บรรทัดแรกยังไม่มา
                $Time = Get-Date -Format "HH:mm:ss"
                Write-Host "[$Time] [INFO] [System] Loaded component: $FileName" -ForegroundColor DarkGray
            }
            $SysLoadedCount++

        } catch {
            Write-Host "[CRITICAL] Failed to load $FileName : $_" -ForegroundColor Red
            if (Get-Command "Write-LogFile" -ErrorAction SilentlyContinue) {
                Write-LogFile -Message "[System] Failed to load $FileName : $_" -Level "FATAL"
            }
        }
    } else {
        Write-Host "[MISSING] System component not found: $FileName" -ForegroundColor Red
    }
}

# ==============================================================================
# FINAL REPORT
# ==============================================================================

$ResultMsg = "System Components initialized. ($SysLoadedCount/$SysTotalCount components loaded)"

if ($SysLoadedCount -eq $SysTotalCount) {
    if (Get-Command "Write-LogFile" -ErrorAction SilentlyContinue) {
        Write-LogFile -Message "[System] $ResultMsg" -Level "INFO"
    }
} else {
    $WarnMsg = "System Components initialized with WARNINGS. ($SysLoadedCount/$SysTotalCount loaded)"
    if (Get-Command "Write-LogFile" -ErrorAction SilentlyContinue) {
        Write-LogFile -Message "[System] $WarnMsg" -Level "WARN"
    }
    Write-Host ">> $WarnMsg" -ForegroundColor Red
}