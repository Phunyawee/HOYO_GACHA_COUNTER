# File: System/LogCreate.ps1

# คำนวณ Path ทิ้งไว้เลยครั้งเดียว
if ($script:AppRoot) { 
    $Global:LogRoot = Join-Path $script:AppRoot "Logs" 
} else { 
    $Global:LogRoot = Join-Path $PSScriptRoot "..\Logs" 
}

# สร้างโฟลเดอร์รอไว้เลย
if (-not (Test-Path $Global:LogRoot)) { New-Item -ItemType Directory -Path $Global:LogRoot -Force | Out-Null }

function Write-LogFile {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [string]$Level="INFO"
    )

    # --- Config ความกว้างของ Label ---
    # ตั้งเผื่อไว้สำหรับคำยาวสุด เช่น "USER_ACTION" (11 ตัว) -> ตั้งเผื่อเป็น 12 หรือ 14
    $MaxLabelWidth = $Level.Length

    # 1. เช็ค Config (Refactored Logic)
    
    # ถ้าเป็นเรื่องคอขาดบาดตาย (CRASH/FATAL) ให้เขียนเสมอ ไม่ต้องสน Config
    $IsCritical = ($Level -in @("CRASH", "FATAL"))
    if (-not $IsCritical) {
        # ถ้าไม่มี Config (ยังโหลดไม่เสร็จ) -> ให้ถือว่าปิดไว้ก่อน (Return เลย)
        if (-not $script:AppConfig) { return }

        # ถ้ามี Config แต่ค่าเป็น False (หรือ "False") -> ให้ถือว่าปิด (Return)
        # ใช้ [bool] บังคับแปลงค่าเผื่อ JSON ส่งมาเป็น String
        if (-not ([bool]$script:AppConfig.EnableFileLog)) { return }
    }

    # 2. เตรียม Path
    if (-not $Global:LogRoot) { $Global:LogRoot = "$PSScriptRoot\Logs" }
    if (-not (Test-Path -Path $Global:LogRoot)) { New-Item -ItemType Directory -Path $Global:LogRoot -Force | Out-Null }
    $dateStr = Get-Date -Format "yyyy-MM-dd"
    $logFile = Join-Path $Global:LogRoot "debug_$dateStr.log"

    # 3. Format ข้อความ (Logic จัดความสวยงาม)
    $upperLevel = $Level.ToUpper()
    
    # ถ้าข้อความยาวกว่ากรอบที่ตั้งไว้ ให้ตัดคำ (หรือจะเลือกปล่อยยาวก็ได้ แต่แบบนี้ปีกกาจะตรงกว่า)
    if ($upperLevel.Length -gt $MaxLabelWidth) {
        $cleanLevel = $upperLevel.Substring(0, $MaxLabelWidth)
    } else {
        # คำนวณ Padding เพื่อจัดกึ่งกลาง (Center Alignment)
        $padTotal = $MaxLabelWidth - $upperLevel.Length
        $padLeft  = [math]::Floor($padTotal / 2) # ปัดเศษลง
        $padRight = $padTotal - $padLeft

        # สร้าง string ที่มีช่องว่างซ้ายขวา
        $cleanLevel = (" " * $padLeft) + $upperLevel + (" " * $padRight)
    }

    $timestamp = Get-Date -Format "HH:mm:ss"
    
    # ผลลัพธ์ปีกกาจะตรงกันเป๊ะ ไม่ว่าคำข้างในจะสั้นหรือยาว (ตราบที่ไม่เกิน MaxWidth)
    $logLine = "[$timestamp] [$cleanLevel] $Message"

    # 4. เขียนไฟล์
    $retryCount = 0
    while ($retryCount -lt 3) {
        try {
            Add-Content -Path $logFile -Value $logLine -Encoding UTF8 -ErrorAction Stop
            break
        } catch {
            Start-Sleep -Milliseconds 50; $retryCount++
        }
    }
}

# แจ้ง Boot Trace ว่า Log หลักพร้อมแล้ว
if (Get-Command "Write-BootTrace" -ErrorAction SilentlyContinue) {
    Write-BootTrace "Main Logger Initialized (Restriction Removed)."
}