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

# --- 2. FILE OPERATIONS (Privacy Enhanced) ---
function Find-GameCacheFile {
    param([hashtable]$Config, [string]$StagingPath)

    if ($null -eq $Config) { throw "Config is missing." }

    Log-Status "--- Auto-Detect Started ---" "Cyan"
    
    $FinalPath = $null
    $GamePath = $null

    # Helper function เพื่อซ่อน Path ถ้าไม่ได้เปิด Debug
    function Get-SafePath($p) {
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
            $logLocationChina = "%userprofile%\AppData\LocalLow\miHoYo\$([char]0x539f)$([char]0x795e)\output_log.txt"
            $pathChina = [System.Environment]::ExpandEnvironmentVariables($logLocationChina)
            if ([System.IO.File]::Exists($pathChina)) { $path = $pathChina } 
            else { throw "Cannot find 'output_log.txt'." }
        }
        # [PRIVACY CHECK]
        Log-Status "Found Log: $(Get-SafePath $path)" "Gray"

        try {
            $logs = Get-Content -Path $path -Encoding UTF8 -ErrorAction Stop
            $m = $logs -match "(?m).:/.+(GenshinImpact_Data|YuanShen_Data)"
            if ($matches.Length -eq 0) { throw "Pattern not found in log." }
            $null = $m[0] -match "(.:/.+(GenshinImpact_Data|YuanShen_Data))"
            $GamePath = $matches[1]
        } catch { throw "Error parsing Genshin log." }

    # ==========================================
    # LOGIC B: ZZZ
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
        
        # [PRIVACY CHECK]
        Log-Status "Found Log: $(Get-SafePath $LogPath)" "Gray"

        try {
            $LogLines = Get-Content $LogPath -First 20 -ErrorAction Stop
            foreach ($line in $LogLines) {
                if ($line.StartsWith("[Subsystems] Discovering subsystems at path ")) {
                    $GamePath = $line.Replace("[Subsystems] Discovering subsystems at path ", "").Replace("UnitySubsystems", "").Trim()
                    break
                }
            }
        } catch { throw "Error reading ZZZ log." }

    # ==========================================
    # LOGIC C: HSR
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
        
        # [PRIVACY CHECK]
        Log-Status "Found Log: $(Get-SafePath $LogPath)" "Gray"

        try {
            $LogLines = Get-Content $LogPath -First 50 -ErrorAction Stop
            foreach ($line in $LogLines) {
                if ($line -match "Loading player data from (.+?)data.unity3d") {
                    $GamePath = $matches[1]
                    break
                }
            }
        } catch { throw "Error reading HSR log." }
    }

    # ==========================================
    # COMMON PROCESS
    # ==========================================
    if ([string]::IsNullOrWhiteSpace($GamePath)) { throw "Could not extract Game Path from Log." }
    $GamePath = $GamePath -replace "/", "\"
    if ($GamePath.EndsWith("\")) { $GamePath = $GamePath.Substring(0, $GamePath.Length - 1) }
    
    # [PRIVACY CHECK]
    Log-Status "Game Path: $(Get-SafePath $GamePath)" "Lime"

    $PossibleWebCachePaths = @("$GamePath\webCaches", "$GamePath\$($Config.DataFolderName)\webCaches")
    $TargetWebCache = $null
    foreach ($p in $PossibleWebCachePaths) { if (Test-Path $p) { $TargetWebCache = $p; break } }

    if (-not $TargetWebCache) { throw "webCaches folder missing. Open Wish History in-game." }
    
    # [PRIVACY CHECK]
    Log-Status "Cache Dir: $(Get-SafePath $TargetWebCache)" "Gray"
    
    Log-Status "Scanning for latest 'data_2'..." "Cyan"
    $TargetFiles = Get-ChildItem -Path $TargetWebCache -Filter "data_2" -Recurse -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending

    if ($null -eq $TargetFiles -or $TargetFiles.Count -eq 0) { throw "data_2 file not found inside webCaches." }

    $FinalPath = $TargetFiles[0].FullName
    
    # [PRIVACY CHECK]
    Log-Status "Targeting File: $(Get-SafePath $FinalPath)" "Cyan"

    try {
        if ([string]::IsNullOrWhiteSpace($StagingPath)) { $StagingPath = ".\temp_data_2" }
        $DestFullPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($StagingPath)
        Copy-Item -Path $FinalPath -Destination $DestFullPath -Force
        Log-Status "Auto-Detect Success! File copied." "Green"
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
           # ==========================================
            # [FIX] CLEAN DATA (ASCII Safe Mode)
            # ==========================================
            # เราใช้รหัส \uXXXX แทนตัวอักษร เพื่อไม่ให้ไฟล์ Script พัง
            # \u0E2D = อ (ขึ้นต้นคำว่า อาวุธ)
            # \u0E15 = ต (ขึ้นต้นคำว่า ตัวละคร)
            # \u00AD = ตัวขยะที่มักเจอในคำว่าอาวุธ
            # \u0095 = ตัวขยะที่มักเจอในคำว่าตัวละคร
            
            foreach ($item in $list) {
                # 1. Weapon Logic
                # Matches: "Weapon", "Light Cone", "W-Engine", "อาวุธ"(Thai Code), "Mojibake"(Code)
                if ($item.item_type -match "Weapon|Light|Engine|\u0E2D|\u00AD") {
                    $item.item_type = "Weapon"
                }
                # 2. Character Logic
                # Matches: "Character", "ตัวละคร"(Thai Code), "Mojibake"(Code)
                elseif ($item.item_type -match "Character|\u0E15|\u0095") {
                    $item.item_type = "Character"
                }
            }
            # ==========================================

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
            
            $bannerText = if ($h.Banner) { $h.Banner } else { "Unknown" }
            $bNameShort = $bannerText.Split('(')[0].Trim()
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

# --- 6. Exclude List ---
function Get-GachaStatus {
    param(
        [string]$GameName,
        [string]$CharName,
        [string]$BannerCode
    )

    # 1. ถ้าไม่ใช่ตู้ Event (เช่นตู้ถาวร หรือตู้อาวุธ) ไม่ต้องเช็ค 50/50
    # Genshin: 301, 400 | HSR: 11 | ZZZ: 2
    if ($GameName -eq "Genshin" -and $BannerCode -notmatch "301|400") { return "Standard/Weapon" }
    if ($GameName -eq "HSR" -and $BannerCode -ne "11") { return "Standard/Weapon" }
    if ($GameName -eq "ZZZ" -and $BannerCode -ne "2") { return "Standard/Weapon" }

    # 2. รายชื่อตัวหลุดเรท (Standard Pool)
    $StandardPool = @()
    switch ($GameName) {
        "Genshin" { $StandardPool = @("Diluc", "Jean", "Mona", "Qiqi", "Keqing", "Tighnari", "Dehya") }
        "HSR"     { $StandardPool = @("Himeko", "Welt", "Bronya", "Gepard", "Clara", "Yanqing", "Bailu") }
        "ZZZ"     { $StandardPool = @("Grace", "Rina", "Koleda", "Nekomata", "Soldier 11", "Lycaon") }
    }

    # 3. เช็คสถานะ
    if ($StandardPool -contains $CharName) {
        return "LOSS" # หลุดเรท
    } else {
        return "WIN"  # ได้หน้าตู้
    }
}


# --- 7. SIMULATION ENGINE (With Stop Feature) ---
function Invoke-GachaSimulation {
    param(
        [int]$SimCount = 100000, 
        [int]$MyPulls,           
        [int]$StartPity,         
        [bool]$IsGuaranteed,     
        [int]$HardPityCap = 90,  
        [int]$SoftPityStart = 74,
        [scriptblock]$ProgressCallback,
        [ref]$StopFlag # <--- [NEW] ตัวรับคำสั่งหยุด
    )

    $SuccessCount = 0
    $TotalPullsUsed = 0
    $BaseRate = 0.6
    
    $Distribution = @{}

    for ($round = 1; $round -le $SimCount; $round++) {
        
        # [NEW] Check Stop Signal (เช็คทุกๆ 1000 รอบ เพื่อความไว)
        if ($round % 1000 -eq 0) {
            if ($StopFlag.Value) { 
                return @{ IsCancelled = $true } # ส่งสัญญาณกลับว่า "ถูกยกเลิก"
            }
        }

        # Progress Report (ทุก 10%)
        if ($round % ($SimCount / 10) -eq 0) {
            if ($ProgressCallback) { & $ProgressCallback $round }
        }

        $CurrentPity = $StartPity
        $Guaranteed = $IsGuaranteed
        $GotIt = $false
        
        for ($i = 1; $i -le $MyPulls; $i++) {
            $CurrentPity++
            $CurrentRate = $BaseRate
            if ($CurrentPity -ge $SoftPityStart) {
                $CurrentRate = $BaseRate + (($CurrentPity - $SoftPityStart) * 6.0)
            }
            if ($CurrentPity -ge $HardPityCap) { $CurrentRate = 100.0 }

            $Roll = (Get-Random -Minimum 0.0 -Maximum 100.0)

            if ($Roll -le $CurrentRate) {
                if ($Guaranteed -or (Get-Random -Min 0 -Max 2) -eq 0) {
                    $GotIt = $true
                    $TotalPullsUsed += $i
                    $bucket = [math]::Ceiling($i / 10) * 10
                    if (-not $Distribution.ContainsKey($bucket)) { $Distribution[$bucket] = 0 }
                    $Distribution[$bucket]++
                    break
                } else {
                    $Guaranteed = $true
                    $CurrentPity = 0 
                }
            }
        }
        if ($GotIt) { $SuccessCount++ }
    }

    return @{
        IsCancelled = $false
        WinRate = ($SuccessCount / $SimCount) * 100
        AvgCost = if ($SuccessCount -gt 0) { $TotalPullsUsed / $SuccessCount } else { 0 }
        Distribution = $Distribution 
    }
}