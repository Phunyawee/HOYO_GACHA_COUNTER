function Find-GameCacheFile {
    param(
        [hashtable]$Config, 
        [string]$StagingPath
    )

    if ($null -eq $Config) { throw "Config is missing." }

    # ตรวจสอบว่ามีฟังก์ชัน Log-Status หรือไม่ ถ้าไม่มีให้สร้าง Mock ขึ้นมากัน Error
    if (-not (Get-Command "Log-Status" -ErrorAction SilentlyContinue)) {
        function Log-Status ($msg, $color) { Write-Host "[$color] $msg" }
    }

    Log-Status "--- Auto-Detect Started ---" "Cyan"
    
    $FinalPath = $null
    $GamePath = $null

    # Helper function เพื่อซ่อน Path ถ้าไม่ได้เปิด Debug (Defined inside to keep scope clean)
    function Get-SafePath($p) {
        # เช็คตัวแปร Global DebugMode จาก Main Engine
        if ($script:DebugMode) { return $p }
        return "[PATH HIDDEN]"
    }

    # ==========================================
    # LOGIC A: GENSHIN IMPACT
    # ==========================================
    if ($Config.Name -match "Genshin") {
        Log-Status "Mode: Genshin Legacy" "Yellow"
        $logLocation = "%userprofile%\AppData\LocalLow\miHoYo\Genshin Impact\output_log.txt"
        $path = [System.Environment]::ExpandEnvironmentVariables($logLocation)
        
        if (-not [System.IO.File]::Exists($path)) {
            # กรณีเซิร์ฟจีน
            $logLocationChina = "%userprofile%\AppData\LocalLow\miHoYo\$([char]0x539f)$([char]0x795e)\output_log.txt"
            $pathChina = [System.Environment]::ExpandEnvironmentVariables($logLocationChina)
            if ([System.IO.File]::Exists($pathChina)) { 
                $path = $pathChina 
            } else { 
                throw "Cannot find 'output_log.txt'." 
            }
        }
        
        Log-Status "Found Log: $(Get-SafePath $path)" "Gray"

        try {
            $logs = Get-Content -Path $path -Encoding UTF8 -ErrorAction Stop
            # Regex หา Path เกมจาก Write-GuiLogของ Genshin
            $m = $logs -match "(?m).:/.+(GenshinImpact_Data|YuanShen_Data)"
            if ($matches.Length -eq 0) { throw "Pattern not found in log." }
            $null = $m[0] -match "(.:/.+(GenshinImpact_Data|YuanShen_Data))"
            $GamePath = $matches[1]
        } catch { 
            throw "Error parsing Genshin log." 
        }

    # ==========================================
    # LOGIC B: ZZZ (Zenless Zone Zero)
    # ==========================================
    } elseif ($Config.Name -match "Zenless") {
        Log-Status "Mode: ZZZ Subsystems" "Yellow"
        $AppData = [Environment]::GetFolderPath('ApplicationData')
        $LocalLow = Join-Path $AppData "..\LocalLow"
        $LogPath = $null
        
        foreach ($subFolder in $Config.LogFolders) {
            $TryPath = Join-Path $LocalLow "$subFolder\Player.log"
            if (Test-Path $TryPath) { $LogPath = $TryPath; break }
        }
        if (-not $LogPath) { throw "Player.log not found." }
        
        Log-Status "Found Log: $(Get-SafePath $LogPath)" "Gray"

        try {
            $LogLines = Get-Content $LogPath -First 20 -ErrorAction Stop
            foreach ($line in $LogLines) {
                if ($line.StartsWith("[Subsystems] Discovering subsystems at path ")) {
                    $GamePath = $line.Replace("[Subsystems] Discovering subsystems at path ", "").Replace("UnitySubsystems", "").Trim()
                    break
                }
            }
        } catch { 
            throw "Error reading ZZZ log." 
        }

    # ==========================================
    # LOGIC C: HSR (Honkai: Star Rail)
    # ==========================================
    } else {
        Log-Status "Mode: HSR Standard" "Yellow"
        $AppData = [Environment]::GetFolderPath('ApplicationData')
        $LocalLow = Join-Path $AppData "..\LocalLow"
        $LogPath = $null
        
        foreach ($subFolder in $Config.LogFolders) {
            $TryPath = Join-Path $LocalLow "$subFolder\Player.log"
            if (Test-Path $TryPath) { $LogPath = $TryPath; break }
        }
        if (-not $LogPath) { throw "Player.log not found." }
        
        Log-Status "Found Log: $(Get-SafePath $LogPath)" "Gray"

        try {
            $LogLines = Get-Content $LogPath -First 50 -ErrorAction Stop
            foreach ($line in $LogLines) {
                if ($line -match "Loading player data from (.+?)data.unity3d") {
                    $GamePath = $matches[1]
                    break
                }
            }
        } catch { 
            throw "Error reading HSR log." 
        }
    }

    # ==========================================
    # COMMON PROCESS (Find & Copy Cache)
    # ==========================================
    if ([string]::IsNullOrWhiteSpace($GamePath)) { throw "Could not extract Game Path from Log." }
    
    # Fix Slash
    $GamePath = $GamePath -replace "/", "\"
    if ($GamePath.EndsWith("\")) { $GamePath = $GamePath.Substring(0, $GamePath.Length - 1) }
    
    Log-Status "Game Path: $(Get-SafePath $GamePath)" "Lime"

    # ลองหาทั้ง Root และใน Data Folder
    $PossibleWebCachePaths = @("$GamePath\webCaches", "$GamePath\$($Config.DataFolderName)\webCaches")
    $TargetWebCache = $null
    foreach ($p in $PossibleWebCachePaths) { 
        if (Test-Path $p) { $TargetWebCache = $p; break } 
    }

    if (-not $TargetWebCache) { throw "webCaches folder missing. Open Wish History in-game." }
    
    Log-Status "Cache Dir: $(Get-SafePath $TargetWebCache)" "Gray"
    
    Log-Status "Scanning for latest 'data_2'..." "Cyan"
    
    # ค้นหาไฟล์ data_2 ที่ใหม่ที่สุด
    $TargetFiles = Get-ChildItem -Path $TargetWebCache -Filter "data_2" -Recurse -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending

    if ($null -eq $TargetFiles -or $TargetFiles.Count -eq 0) { throw "data_2 file not found inside webCaches." }

    $FinalPath = $TargetFiles[0].FullName
    
    Log-Status "Targeting File: $(Get-SafePath $FinalPath)" "Cyan"

    try {
        if ([string]::IsNullOrWhiteSpace($StagingPath)) { $StagingPath = ".\temp_data_2" }
        # Resolve Path ให้เป็น Absolute Path ป้องกันปัญหา Relative Path
        $DestFullPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($StagingPath)
        
        Copy-Item -Path $FinalPath -Destination $DestFullPath -Force
        Log-Status "Auto-Detect Success! File copied." "Green"
        
        return $DestFullPath
    } catch {
        throw "Copy Failed: $($_.Exception.Message)"
    }
}