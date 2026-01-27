# ==============================================================================
# LOG FILE GENERATOR (BACKEND)
# ==============================================================================

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
        
        [string]$Level="INFO",

        # [NEW] ตัวระบุที่มา ถ้าไม่ใส่มา จะถือว่าเป็น System (โค้ดเก่าจะได้ไม่พัง)
        [string]$Source="System"
    )

    # --- Config ความกว้างของ Label (จัดสวยงาม) ---
    $MaxLabelWidth = $Level.Length

    # 1. เช็ค Config
    $IsCritical = ($Level -in @("CRASH", "FATAL"))
    if (-not $IsCritical) {
        if (-not $script:AppConfig) { return }
        if (-not ([bool]$script:AppConfig.EnableFileLog)) { return }
    }

    # 2. เตรียม Path
    if (-not $Global:LogRoot) { $Global:LogRoot = "$PSScriptRoot\Logs" }
    if (-not (Test-Path -Path $Global:LogRoot)) { New-Item -ItemType Directory -Path $Global:LogRoot -Force | Out-Null }
    
    $dateStr = Get-Date -Format "yyyy-MM-dd"
    $logFile = Join-Path $Global:LogRoot "debug_$dateStr.log"

    # 3. Format ข้อความ
    $upperLevel = $Level.ToUpper()
    
    # จัด Alignment ของ Level (INFO, WARN, etc.)
    if ($upperLevel.Length -gt $MaxLabelWidth) {
        $cleanLevel = $upperLevel.Substring(0, $MaxLabelWidth)
    } else {
        $padTotal = $MaxLabelWidth - $upperLevel.Length
        $padLeft  = [math]::Floor($padTotal / 2)
        $padRight = $padTotal - $padLeft
        $cleanLevel = (" " * $padLeft) + $upperLevel + (" " * $padRight)
    }

    $timestamp = Get-Date -Format "HH:mm:ss"
    
    # [IMPORTANT] รวม Source เข้าไปในข้อความก่อนเขียน
    # ผลลัพธ์: [12:00:00] [INFO] [System] ข้อความ...
    # หรือ:    [12:00:00] [USER] [App] ข้อความ...
    $finalLogLine = "[$timestamp] [$cleanLevel] [$Source] $Message"

    # 4. เขียนไฟล์ (Retry Logic)
    $retryCount = 0
    while ($retryCount -lt 3) {
        try {
            Add-Content -Path $logFile -Value $finalLogLine -Encoding UTF8 -ErrorAction Stop
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