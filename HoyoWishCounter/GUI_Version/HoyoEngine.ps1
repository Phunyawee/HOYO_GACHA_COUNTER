# HoyoEngine.ps1 - Core Logic Library
# ห้ามรันไฟล์นี้ตรงๆ ให้รันผ่าน App.ps1

Add-Type -AssemblyName System.Web

# --- 1. CONFIGURATION ---
function Get-GameConfig {
    param([string]$GameName)
    
    # Github URL สำหรับรูป Icon
    $BaseRepoUrl = "https://raw.githubusercontent.com/Phunyawee/HOYO_GACHA_COUNTER/main/HoyoWishCounter/BotIcon"

    switch ($GameName) {
        "Genshin" {
            return @{
                Name = "Genshin Impact"
                DefaultPaths = @("C:\Program Files\Genshin Impact", "C:\Program Files\HoYoverse\Genshin Impact")
                CachePattern = "*GenshinImpact_Data*\webCaches"
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
                DefaultPaths = @("C:\Program Files\Star Rail", "C:\Program Files\HoYoverse\Star Rail")
                CachePattern = "*StarRail_Data*\webCaches"
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
                DefaultPaths = @("C:\Program Files\ZenlessZoneZero", "C:\Program Files\HoYoverse\ZenlessZoneZero")
                CachePattern = "*ZenlessZoneZero_Data*\webCaches"
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

# --- 2. FILE OPERATIONS (Auto-Find & Staging) ---
function Find-GameCacheFile {
    param([hashtable]$Config, [string]$StagingPath)

    # Smart Search: หา Drive ที่ใช้งานได้ทั้งหมด
    $Drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -gt 0 } 
    $FoundFile = $null

    foreach ($Drive in $Drives) {
        $RootPath = $Drive.Root
        $PossibleParentFolders = @(
            "$RootPath", "$RootPath\Program Files", "$RootPath\Program Files (x86)", "$RootPath\HoYoverse", "$RootPath\Games"
        )

        foreach ($Parent in $PossibleParentFolders) {
            if (-not (Test-Path $Parent)) { continue }
            
            # หา webCaches ตาม Pattern ของแต่ละเกม
            $GameDataFolder = Get-ChildItem -Path $Parent -Filter $Config.CachePattern -Directory -Recurse -Depth 2 -ErrorAction SilentlyContinue
            
            if ($GameDataFolder) {
                $TargetFiles = Get-ChildItem -Path $GameDataFolder.FullName -Filter "data_2" -Recurse -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
                if ($TargetFiles) {
                    $FoundFile = $TargetFiles[0].FullName
                    break
                }
            }
        }
        if ($FoundFile) { break }
    }

    if (-not $FoundFile) { throw "Could not auto-detect 'data_2'. Please browse manually." }

    # Copy to Staging
    $StagingDir = Split-Path $StagingPath -Parent
    if (-not (Test-Path $StagingDir)) { New-Item -ItemType Directory -Path $StagingDir | Out-Null }
    Copy-Item -Path $FoundFile -Destination $StagingPath -Force
    return $StagingPath
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

            # Regex ตามต้นฉบับ HoyoWish.ps1
            if ($cleanStr -match "(https.+?game_biz=[\w_]+)") { $rawUrl = $matches[0] } 
            elseif ($cleanStr -match "(https.+?authkey=[^`" ]+)") { $rawUrl = $matches[0] }

            if ($rawUrl) {
                try {
                    $uri = [System.Uri]$rawUrl
                    $qs = [System.Web.HttpUtility]::ParseQueryString($uri.Query)
                    if (-not $qs["game_biz"]) { $qs["game_biz"] = $Config.GameBiz }
                    $qs["size"] = "1"
                    $qs["gacha_type"] = $Config.Banners[0].Code
                    if ($Config.Name -match "Zenless") { $qs["real_gacha_type"] = $Config.Banners[0].Code } # ZZZ Fix
                    
                    $builder = New-Object System.UriBuilder("https://$($uri.Host)$($Config.ApiEndpoint)")
                    $builder.Query = $qs.ToString()
                    $TestLink = $builder.Uri.AbsoluteUri

                    # Test Connection
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
        Start-Sleep -Milliseconds 600 # Safety delay

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
    param($HistoryData, $PityTrackers, $Config, [bool]$ShowNoMode) # เพิ่ม ShowNoMode
    
    if (-not (Test-Path "config.json")) { return "Skipped (No Config)" }
    $jsonConfig = Get-Content "config.json" -Raw | ConvertFrom-Json
    $WebhookUrl = $jsonConfig.webhook_url
    if ([string]::IsNullOrWhiteSpace($WebhookUrl)) { return "Skipped (Empty URL)" }

    # Fields (Pity Summary)
    $fields = @()
    foreach ($b in $Config.Banners) {
        $val = $PityTrackers[$b.Code]
        if ($null -eq $val) { $val = 0 }
        $fields += @{ name = "$($b.Name) Pity"; value = "**$val**"; inline = $true }
    }

    # Description (List Logic ตามต้นฉบับ)
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
            
            # Logic: Show No vs Date
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