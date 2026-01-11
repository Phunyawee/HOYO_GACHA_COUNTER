# HoyoEngine.ps1 - Core Logic Library
# SRS Logic Implementation

Add-Type -AssemblyName System.Web

# ฟังก์ชัน Wrapper สำหรับส่งข้อความไปที่หน้าจอ GUI (App.ps1)
function Log-Status {
    param($msg, $color="Yellow")
    # ตรวจสอบว่าฟังก์ชัน Log มีอยู่จริงไหม (จาก App.ps1)
    if (Get-Command "Log" -ErrorAction SilentlyContinue) {
        Log $msg $color
    } else {
        Write-Host $msg -ForegroundColor $color
    }
}

# --- 1. CONFIGURATION ---
function Get-GameConfig {
    param([string]$GameName)
    
    $BaseRepoUrl = "https://raw.githubusercontent.com/Phunyawee/HOYO_GACHA_COUNTER/main/HoyoWishCounter/BotIcon"

    switch ($GameName) {
        "Genshin" {
            return @{
                Name = "Genshin Impact"
                # LogPath: ที่อยู่ของไฟล์ Log (Genshin มี 2 ค่าย miHoYo กับ Cognosphere)
                LogFolders = @("miHoYo\Genshin Impact", "Cognosphere\Genshin Impact") 
                DataFolderName = "GenshinImpact_Data"
                HostUrl = "public-operation-hk4e-sg.hoyoverse.com"
                ApiEndpoint = "/gacha_info/api/getGachaLog"
                GameBiz = "hk4e_global"
                SRank = "5"; ThemeColor = 16766720
                IconUrl = "$BaseRepoUrl/Paimon.png"
                Banners = @(@{ Code="301"; Name="Character Event" },@{ Code="302"; Name="Weapon Event" },@{ Code="200"; Name="Standard" },@{ Code="100"; Name="Novice" })
            }
        }
        "HSR" {
            return @{
                Name = "Honkai: Star Rail"
                LogFolders = @("Cognosphere\Star Rail")
                DataFolderName = "StarRail_Data"
                HostUrl = "public-operation-hkrpg.hoyoverse.com"
                ApiEndpoint = "/common/gacha_record/api/getGachaLog"
                GameBiz = "hkrpg_global"
                SRank = "5"; ThemeColor = 3447003
                IconUrl = "$BaseRepoUrl/Pompom.png"
                Banners = @(@{ Code="11"; Name="Character Warp" },@{ Code="12"; Name="Light Cone Warp" },@{ Code="1";  Name="Stellar Warp" },@{ Code="2";  Name="Departure Warp" })
            }
        }
        "ZZZ" {
            return @{
                Name = "Zenless Zone Zero"
                LogFolders = @("miHoYo\ZenlessZoneZero", "Cognosphere\ZenlessZoneZero")
                DataFolderName = "ZenlessZoneZero_Data"
                HostUrl = "public-operation-nap-sg.hoyoverse.com"
                ApiEndpoint = "/common/gacha_record/api/getGachaLog"
                GameBiz = "nap_global"
                SRank = "4"; ThemeColor = 16738816
                IconUrl = "$BaseRepoUrl/Bangboo.png"
                Banners = @(@{ Code="2"; Name="Exclusive (Char)" },@{ Code="3"; Name="W-Engine (Weap)" },@{ Code="5"; Name="Bangboo" },@{ Code="1"; Name="Standard" })
            }
        }
    }
    return $null
}

# --- 2. FILE OPERATIONS (SRS Logic + Fix Empty Path Error) ---
# --- 2. FILE OPERATIONS (Final Fix: Copy Path Logic) ---
function Find-GameCacheFile {
    param([hashtable]$Config, [string]$StagingPath)

    if ($null -eq $Config) { throw "Config is missing." }

    Log-Status "--- Auto-Detect Started (SRS Method) ---" "Cyan"
    
    # 1. หาไฟล์ Player.log
    $AppData = [Environment]::GetFolderPath('ApplicationData')
    $LocalLow = Join-Path $AppData "..\LocalLow"
    $LogPath = $null
    
    foreach ($subFolder in $Config.LogFolders) {
        $TryPath = Join-Path $LocalLow "$subFolder\Player.log"
        if (Test-Path $TryPath) {
            $LogPath = $TryPath
            Log-Status "Found Log File: $TryPath" "Gray"
            break
        }
    }

    if (-not $LogPath) { throw "Could not find Player.log! Please open the game at least once." }

    # 2. อ่าน Log หา Path เกม
    Log-Status "Reading Player.log..." "Yellow"
    $GamePath = $null
    
    try {
        $LogLines = Get-Content $LogPath -First 50 -ErrorAction Stop
        foreach ($line in $LogLines) {
            if ($line -match "Loading player data from (.+?)data.unity3d") {
                $GamePath = $matches[1]
                break
            }
        }
    } catch { throw "Error reading log file." }

    if ([string]::IsNullOrWhiteSpace($GamePath)) { throw "Could not extract Game Path from Log." }
    $GamePath = $GamePath -replace "/", "\"
    Log-Status "Game installed at: $GamePath" "Lime"

    # 3. หา webCaches
    $PossibleWebCachePaths = @(
        "$GamePath\webCaches",
        "$GamePath\$($Config.DataFolderName)\webCaches"
    )
    $TargetWebCache = $null
    foreach ($p in $PossibleWebCachePaths) {
        if (Test-Path $p) { $TargetWebCache = $p; break }
    }
    if (-not $TargetWebCache) { throw "webCaches folder missing. Open Wish History in-game to generate it." }
    Log-Status "Found webCaches at: $TargetWebCache" "Gray"

    # 4. หา Version ล่าสุด
    $CacheFolders = Get-ChildItem $TargetWebCache -Directory
    $MaxVersion = 0
    $FinalPath = "$TargetWebCache\Cache\Cache_Data\data_2" 

    foreach ($folder in $CacheFolders) {
        if ($folder.Name -match '^\d+\.\d+\.\d+\.\d+$') {
            try {
                $VerNum = [int64]($folder.Name -replace '\.', '')
                if ($VerNum -ge $MaxVersion) {
                    $MaxVersion = $VerNum
                    $FinalPath = "$($folder.FullName)\Cache\Cache_Data\data_2"
                }
            } catch {}
        }
    }
    Log-Status "Targeting Cache File: $FinalPath" "Cyan"

    if (-not (Test-Path $FinalPath)) { throw "File 'data_2' not found inside cache folder." }

    # 5. [FIXED] ขั้นตอนก๊อปปี้ (ปลอดภัย 100% ไม่ใช้ .NET Constructor)
    try {
        # ถ้า Path ปลายทางว่าง ให้ตั้งค่า Default เป็นโฟลเดอร์ปัจจุบัน
        if ([string]::IsNullOrWhiteSpace($StagingPath)) {
            $StagingPath = ".\temp_data_2"
        }
        
        # แปลงเป็น Full Path มาตรฐาน Windows (แก้ปัญหา Path ผิดรูปแบบ)
        $DestFullPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($StagingPath)
        
        # หาโฟลเดอร์แม่
        $DestDir = Split-Path -Parent $DestFullPath
        if ([string]::IsNullOrWhiteSpace($DestDir)) { $DestDir = "." }

        # สร้างโฟลเดอร์ถ้าไม่มี
        if (-not (Test-Path $DestDir)) {
            New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
        }

        # ก๊อปปี้
        Copy-Item -Path $FinalPath -Destination $DestFullPath -Force
        
        Log-Status "Auto-Detect Success! File copied." "Green"
        
        # ส่งค่า Path เต็มกลับไป
        return $DestFullPath
    } catch {
        throw "Copy Failed: $($_.Exception.Message)"
    }
}

# --- 3. URL EXTRACTION ---
function Get-AuthLinkFromFile {
    param([string]$FilePath, [hashtable]$Config)

    if (-not (Test-Path $FilePath)) { throw "File not found!" }
    
    $content = Get-Content -Path $FilePath -Encoding UTF8 -Raw
    $chunks = $content -split "1/0/"
    
    for ($i = $chunks.Length - 1; $i -ge 0; $i--) {
        $chunk = $chunks[$i]
        if ($chunk -match "https" -and $chunk -match "authkey=") {
            $cleanStr = ($chunk -split "`0")[0]
            $rawUrl = $null

            if ($cleanStr -match "(https.+?game_biz=[\w_]+)") { $rawUrl = $matches[0] } 
            elseif ($cleanStr -match "(https.+?authkey=[^`" ]+)") { $rawUrl = $matches[0] }

            if ($rawUrl) {
                try {
                    $uri = [System.Uri]$rawUrl
                    $qs = [System.Web.HttpUtility]::ParseQueryString($uri.Query)
                    if (-not $qs["game_biz"]) { $qs["game_biz"] = $Config.GameBiz }
                    $qs["size"] = "1"
                    $qs["gacha_type"] = $Config.Banners[0].Code
                    if ($Config.Name -match "Zenless") { $qs["real_gacha_type"] = $Config.Banners[0].Code } 
                    
                    $builder = New-Object System.UriBuilder("https://$($uri.Host)$($Config.ApiEndpoint)")
                    $builder.Query = $qs.ToString()
                    $TestLink = $builder.Uri.AbsoluteUri

                    $test = Invoke-RestMethod -Uri $TestLink -Method Get -TimeoutSec 3
                    if ($test.retcode -eq 0) {
                        return @{ Url = $TestLink; Host = $uri.Host }
                    }
                } catch {}
            }
        }
    }
    throw "No valid AuthKey found. Please open Wish History in-game to refresh."
}

# --- 4. API FETCHING ---
function Fetch-GachaPages {
    param($Url, $HostUrl, $Endpoint, $BannerCode, $PageCallback)
    
    $page = 1; $endId = "0"; $isFinished = $false
    $History = @()

    while (-not $isFinished) {
        if ($PageCallback) { & $PageCallback $page }
        Start-Sleep -Milliseconds 600

        $uriObj = [System.Uri]$Url
        $qs = [System.Web.HttpUtility]::ParseQueryString($uriObj.Query)
        $qs["gacha_type"] = "$BannerCode"
        $qs["size"] = "20"
        $qs["page"] = "$page"
        $qs["end_id"] = "$endId"
        if ($qs["game_biz"] -match "nap") { $qs["real_gacha_type"] = "$BannerCode" }

        $builder = New-Object System.UriBuilder("https://$HostUrl$Endpoint")
        $builder.Query = $qs.ToString()
        
        $resp = Invoke-RestMethod -Uri $builder.Uri.AbsoluteUri -Method Get -TimeoutSec 10
        if ($resp.retcode -ne 0) { throw "API Error: $($resp.message)" }
        
        $list = $resp.data.list
        if ($null -eq $list -or $list.Count -eq 0) { 
            $isFinished = $true 
        } else {
            $History += $list
            $endId = $list[$list.Count - 1].id
            $page++
        }
    }
    return $History
}

# --- 5. DISCORD ---
function Send-DiscordReport {
    param($HistoryData, $PityTrackers, $Config, [bool]$ShowNoMode)
    
    if (-not (Test-Path "config.json")) { return "Skipped (No Config)" }
    $jsonConfig = Get-Content "config.json" -Raw | ConvertFrom-Json
    $WebhookUrl = $jsonConfig.webhook_url
    if ([string]::IsNullOrWhiteSpace($WebhookUrl)) { return "Skipped (Empty URL)" }

    $fields = @()
    foreach ($b in $Config.Banners) {
        $val = $PityTrackers[$b.Code]
        if ($null -eq $val) { $val = 0 }
        $fields += @{ name = "$($b.Name) Pity"; value = "**$val**"; inline = $true }
    }

    $descTxt = ""
    $count = 0
    $limit = 30
    
    if ($HistoryData.Count -gt 0) {
        $descTxt = "**Recent History (Last $limit):**`n"
        for ($i = $HistoryData.Count - 1; $i -ge 0; $i--) {
            if ($count -ge $limit) { break }
            $h = $HistoryData[$i]
            
            $icon = ":green_circle:"
            if ($h.Pity -gt 75) { $icon = ":red_circle:" } elseif ($h.Pity -gt 50) { $icon = ":yellow_circle:" }
            
            if ($ShowNoMode) {
                $prefix = "[No.$($i+1)]"
            } else {
                $prefix = "`[$($h.Time)`]"
            }
            
            $bNameShort = $h.Banner.Split('(')[0].Trim().Split(' ')[0]
            $descTxt += "$prefix $icon **$($h.Name)** (Pity: **$($h.Pity)**) - *$bNameShort*`n"
            $count++
        }
    } else {
        $descTxt = "No history found."
    }

    $payload = @{
        username = "$($Config.Name) Tracker"
        avatar_url = $Config.IconUrl
        embeds = @(
            @{
                title = "$($Config.Name) Wish Report"
                description = $descTxt
                color = $Config.ThemeColor
                fields = @($fields)
                footer = @{ text = "Generated by Universal Hoyo Counter" }
                thumbnail = @{ url = $Config.IconUrl } 
            }
        )
    }

    try {
        Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body ($payload | ConvertTo-Json -Depth 10 -Compress) -ContentType 'application/json'
        return "Sent Successfully!"
    } catch {
        return "Failed: $($_.Exception.Message)"
    }
}