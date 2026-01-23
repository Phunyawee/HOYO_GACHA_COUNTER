function Write-LogFile {
    param($Message, $Level="INFO")

    # 1. เช็ค Config
    if ($script:AppConfig -and (-not $script:AppConfig.EnableFileLog)) { return }

    # 2. กำหนดโฟลเดอร์ Logs (แยกเป็นสัดส่วน)
    $RootBase = if ($script:AppRoot) { $script:AppRoot } else { (Join-Path $PSScriptRoot "..") }
    $LogDir = Join-Path $RootBase "logs"
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    # 3. กำหนดชื่อไฟล์ตาม "วันที่ปัจจุบัน" (Daily Rotation)
    $dateStr = Get-Date -Format "yyyy-MM-dd"
    $logPath = Join-Path $logDir "debug_$dateStr.log"

    # 4. Format ข้อความ
    $timestamp = Get-Date -Format "HH:mm:ss"
    $logLine = "[$timestamp] [$Level] $Message"

    # 5. เขียนไฟล์
    try {
        Add-Content -Path $logPath -Value $logLine -ErrorAction SilentlyContinue
    } catch {}
}