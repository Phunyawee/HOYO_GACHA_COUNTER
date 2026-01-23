function Play-Sound {
    param([string]$EventName)

    # 1. เช็ค Config
    if ($script:AppConfig -and (-not $script:AppConfig.EnableSound)) { return }

    # 2. เตรียมโฟลเดอร์ (แก้ Path ให้ชี้ไปที่ Root หน้าบ้าน)
    # ถ้ามี AppRoot ให้ใช้ ถ้าไม่มีให้ถอยหลัง 1 ขั้น (..)
    $RootBase = if ($script:AppRoot) { $script:AppRoot } else { (Join-Path $PSScriptRoot "..") }
    
    $soundDir = Join-Path $RootBase "Sounds"

    # ถ้าไม่มีโฟลเดอร์ ให้สร้างไว้ที่หน้าบ้าน
    if (-not (Test-Path $soundDir)) {
        New-Item -ItemType Directory -Path $soundDir -Force | Out-Null
    }

    # 3. หาไฟล์เสียง
    $soundFile = Join-Path $soundDir "$EventName.wav"

    if (Test-Path $soundFile) {
        try {
            $player = New-Object System.Media.SoundPlayer $soundFile
            $player.Play()
        } catch {
            if (Get-Command "Write-LogFile" -ErrorAction SilentlyContinue) {
                Write-LogFile -Message "Audio Error: $($_.Exception.Message)" -Level "WARN"
            }
        }
    }
}