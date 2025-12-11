param (
    [string]$Game = "Genshin"
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Web

# ==========================================
# 1. SETUP & CONFIGURATION
# ==========================================
Write-Host "--- HOYO UNIVERSAL WISH COUNTER ($Game) ---" -ForegroundColor Cyan

if (Test-Path "config.json") {
    $ConfigFile = Get-Content "config.json" -Raw | ConvertFrom-Json
    $WebhookUrl = $ConfigFile.webhook_url
} else {
    $WebhookUrl = ""
    Write-Host "[WARN] config.json not found. Discord feature disabled." -ForegroundColor Yellow
}

$IconUrl = ""
switch ($Game) {
    "Genshin" {
        $HostUrl = "public-operation-hk4e-sg.hoyoverse.com"
        $ApiEndpoint = "/gacha_info/api/getGachaLog"
        $GameBiz = "hk4e_global"
        $SRankCode = "5" 
        $ThemeColor = 16766720
        $IconUrl = "https://fastcdn.hoyoverse.com/static-resource-v2/2023/10/18/d193354b3c9594b2938a920241b777a8.png"
        $Banners = @(
            @{ Code="301"; Name="Character Event" },
            @{ Code="302"; Name="Weapon Event" },
            @{ Code="200"; Name="Standard" },
            @{ Code="100"; Name="Novice" }
        )
    }
    "HSR" {
        $HostUrl = "public-operation-hkrpg.hoyoverse.com" # Updated Host
        $ApiEndpoint = "/common/gacha_record/api/getGachaLog"
        $GameBiz = "hkrpg_global"
        $SRankCode = "5" 
        $ThemeColor = 3447003
        $IconUrl = "https://fastcdn.hoyoverse.com/static-resource-v2/2024/04/11/4a98a0d0d867c2685955018659d4c205.png"
        $Banners = @(
            @{ Code="11"; Name="Character Warp" },
            @{ Code="12"; Name="Light Cone Warp" },
            @{ Code="1";  Name="Stellar Warp" },
            @{ Code="2";  Name="Departure Warp" }
        )
    }
    "ZZZ" {
        $HostUrl = "public-operation-nap-sg.hoyoverse.com"
        $ApiEndpoint = "/common/gacha_record/api/getGachaLog"
        $GameBiz = "nap_global"
        $SRankCode = "4"
        $ThemeColor = 16738816
        $IconUrl = "https://fastcdn.hoyoverse.com/static-resource-v2/2024/07/04/00713833076c70387467615965413344.png"
        $Banners = @(
            @{ Code="2"; Name="Exclusive (Char)" },
            @{ Code="3"; Name="W-Engine (Weap)" },
            @{ Code="5"; Name="Bangboo" },
            @{ Code="1"; Name="Standard" }
        )
    }
    Default { throw "Unknown Game: $Game" }
}

# ==========================================
# 2. UNIVERSAL LINK EXTRACTOR
# ==========================================
function Get-AuthLink {
    Write-Host "`n[STEP 1] Please drag & drop the cache file 'data_2' here:" -ForegroundColor Gray
    $filePath = Read-Host ">"
    $filePath = $filePath -replace '"', ''

    if (-not (Test-Path $filePath)) { throw "File not found!" }

    Write-Host "Scanning file..." -ForegroundColor Cyan
    
    $content = Get-Content -Path $filePath -Encoding UTF8 -Raw
    $chunks = $content -split "1/0/"
    
    for ($i = $chunks.Length - 1; $i -ge 0; $i--) {
        $chunk = $chunks[$i]
        if ($chunk -match "https" -and $chunk -match "authkey=") {
            $cleanStr = ($chunk -split "`0")[0]
            $rawUrl = $null

            # Hybrid Regex Check
            if ($cleanStr -match "(https.+?game_biz=[\w_]+)") {
                $rawUrl = $matches[0]
            } elseif ($cleanStr -match "(https.+?authkey=[^`" ]+)") {
                $rawUrl = $matches[0]
            }

            if ($rawUrl) {
                try {
                    $uri = [System.Uri]$rawUrl
                    $qs = [System.Web.HttpUtility]::ParseQueryString($uri.Query)
                    if (-not $qs["game_biz"]) { $qs["game_biz"] = $GameBiz }
                    $qs["size"] = "1" 
                    $qs["gacha_type"] = $Banners[0].Code 
                    if ($Game -eq "ZZZ") { $qs["real_gacha_type"] = $Banners[0].Code }
                    
                    # Use Host from Link (Fix for HSR/ZZZ variants)
                    $testHost = $uri.Host
                    $builder = New-Object System.UriBuilder("https://$testHost$ApiEndpoint")
                    $builder.Query = $qs.ToString()
                    $testUrl = $builder.Uri.AbsoluteUri

                    Write-Host "." -NoNewline -ForegroundColor Gray
                    $response = Invoke-RestMethod -Uri $testUrl -Method Get -TimeoutSec 3
                    if ($response.retcode -eq 0) {
                        Write-Host "`n[OK] Valid AuthKey Found!" -ForegroundColor Green
                        $global:HostUrl = $testHost 
                        return $testUrl
                    }
                } catch {}
            }
        }
    }
    throw "No valid link found or AuthKey expired."
}

# ==========================================
# 3. API FETCHER
# ==========================================
function Get-GachaData {
    param ($Url, $GachaType, $Page, $EndId)
    $uriObj = [System.Uri]$Url
    $qs = [System.Web.HttpUtility]::ParseQueryString($uriObj.Query)
    $qs["gacha_type"] = "$GachaType"
    $qs["size"] = "20"
    $qs["page"] = "$Page"
    $qs["end_id"] = "$EndId"
    if ($Game -eq "ZZZ") { $qs["real_gacha_type"] = "$GachaType" }
    
    $builder = New-Object System.UriBuilder("https://$HostUrl$ApiEndpoint")
    $builder.Query = $qs.ToString()
    return Invoke-RestMethod -Uri $builder.Uri.AbsoluteUri -Method Get -TimeoutSec 20
}

# ==========================================
# 4. MAIN PROCESS
# ==========================================
try {
    $workingUrl = Get-AuthLink
    
    # --- DYNAMIC MENU SELECTION ---
    Write-Host "`n[ SELECT BANNER TO FETCH ]" -ForegroundColor Yellow
    $i = 1
    foreach ($b in $Banners) {
        Write-Host " $i : $($b.Name)" -ForegroundColor White
        $i++
    }
    Write-Host " 0 : FETCH ALL (Recommended)" -ForegroundColor Green

    $selection = Read-Host "`nEnter Number (0 - $($Banners.Count))"
    
    $TargetBanners = @()
    if ($selection -match "^[1-9]\d*$" -and [int]$selection -le $Banners.Count) {
        # เลือกแบบเจาะจง (Array Index = selection - 1)
        $selectedIdx = [int]$selection - 1
        $TargetBanners = @($Banners[$selectedIdx])
        Write-Host "Selected: $($TargetBanners[0].Name)" -ForegroundColor Cyan
    } else {
        # ถ้ากด 0 หรือกดมั่ว -> เอาหมดเลย
        $TargetBanners = $Banners
        Write-Host "Selected: ALL Banners" -ForegroundColor Green
    }
    # -------------------------------

    $allHistory = @()

    foreach ($banner in $TargetBanners) {
        Write-Host "`nFetching: $($banner.Name)..." -ForegroundColor Magenta
        $page = 1
        $endId = "0"
        $isFinished = $false
        
        while (-not $isFinished) {
            Write-Host "." -NoNewline -ForegroundColor Gray
            Start-Sleep -Milliseconds 500 
            
            $resp = Get-GachaData -Url $workingUrl -GachaType $banner.Code -Page $page -EndId $endId
            if ($resp.retcode -ne 0) { Write-Host " Error: $($resp.message)" -ForegroundColor Red; break }
            
            $list = $resp.data.list
            if ($null -eq $list -or $list.Count -eq 0) { $isFinished = $true; break }
            
            foreach ($item in $list) {
                $item | Add-Member -MemberType NoteProperty -Name "_BannerName" -Value $banner.Name
            }
            $allHistory += $list
            $endId = $list[$list.Count - 1].id
            $page++
        }
        Start-Sleep -Seconds 1
    }

    Write-Host "`n`n[PROCESSING] Calculating Pity..." -ForegroundColor Green
    $sortedItems = $allHistory | Sort-Object { [decimal]$_.id }
    
    # Initialize Tracker (สร้างให้ครบทุกตู้ แม้จะเลือกโหลดแค่ตู้เดียว เพื่อให้ Report ไม่พัง)
    $pityTrackers = @{}
    foreach ($b in $Banners) { $pityTrackers[$b.Code] = 0 }
    
    $highRankHistory = @()

    foreach ($item in $sortedItems) {
        $code = [string]$item.gacha_type
        if ($Game -eq "Genshin" -and $code -eq "400") { $code = "301" }

        if (-not $pityTrackers.ContainsKey($code)) { $pityTrackers[$code] = 0 }
        $pityTrackers[$code]++

        if ($item.rank_type -eq $SRankCode) {
            $highRankHistory += [PSCustomObject]@{
                Time   = $item.time
                Name   = $item.name
                Banner = $item._BannerName
                Pity   = $pityTrackers[$code]
            }
            $pityTrackers[$code] = 0
        }
    }

    # ==========================================
    # 5. CONSOLE OUTPUT
    # ==========================================
    Write-Host "`n================================================" -ForegroundColor Cyan
    Write-Host "   $Game HIGH RANK HISTORY (LOG) " -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    
    if ($highRankHistory.Count -gt 0) {
        for ($i = $highRankHistory.Count - 1; $i -ge 0; $i--) {
            $h = $highRankHistory[$i]
            $pColor = "Green"
            if ($h.Pity -gt 75) { $pColor = "Red" } elseif ($h.Pity -gt 50) { $pColor = "Yellow" }
            Write-Host "[$($h.Time)] " -NoNewline -ForegroundColor Gray
            Write-Host "$($h.Name.PadRight(18)) " -NoNewline -ForegroundColor Yellow
            Write-Host "Pity: $($h.Pity)" -ForegroundColor $pColor
        }
    }

    # ==========================================
    # 6. DISCORD WEBHOOK
    # ==========================================
    if (-not [string]::IsNullOrWhiteSpace($WebhookUrl)) {
        Write-Host "`nPreparing Discord Report..." -ForegroundColor Magenta
        
        # Show Pity for ALL banners (even if not fetched, shows 0 or previous value if logic adapted)
        # Note: Since we only fetched current history, un-fetched banners will effectively start from 0 in this run context.
        $fields = @()
        foreach ($b in $Banners) {
            # Filter output: Show pity only for Fetched Banners OR All Banners?
            # Decision: Show ALL defined banners for the game structure, even if 0.
            $val = $pityTrackers[$b.Code]
            if ($null -eq $val) { $val = 0 }
            
            $fields += @{ name = "$($b.Name) Pity"; value = "**$val**"; inline = $true }
        }

        $DiscordLimit = 15 
        $MaxChars = 3800
        
        function Build-Description ($UseFullTime) {
            $txt = ""
            $count = 0
            if ($highRankHistory.Count -gt 0) {
                $txt = "**Recent History (Last $DiscordLimit):**`n"
                for ($i = $highRankHistory.Count - 1; $i -ge 0; $i--) {
                    if ($count -ge $DiscordLimit) { break }
                    $h = $highRankHistory[$i]
                    
                    $icon = ":green_circle:"
                    if ($h.Pity -gt 75) { $icon = ":red_circle:" } elseif ($h.Pity -gt 50) { $icon = ":yellow_circle:" }
                    
                    if ($UseFullTime) { $timeStr = $h.Time } else { $timeStr = $h.Time.Split(' ')[0] }
                    $bNameShort = $h.Banner.Split('(')[0].Trim().Split(' ')[0]
                    
                    $txt += "`[$timeStr`] $icon **$($h.Name)** (Pity: **$($h.Pity)**) - *$bNameShort*`n"
                    $count++
                }
            } else {
                $txt = "No history found for selected banners."
            }
            return $txt
        }

        Write-Host "Checking message length..." -NoNewline -ForegroundColor Gray
        $finalDesc = Build-Description -UseFullTime $true
        
        if ($finalDesc.Length -gt $MaxChars) {
            Write-Host "`n[WARN] Too long. Using short date." -ForegroundColor Yellow
            $finalDesc = Build-Description -UseFullTime $false
        } else {
            Write-Host " OK." -ForegroundColor Green
        }

        $payload = @{
            username = "$Game Tracker"
            embeds = @(
                @{
                    title = "$Game Wish Report"
                    description = $finalDesc
                    color = $ThemeColor
                    fields = @($fields)
                    footer = @{ text = "Generated by Universal Hoyo Counter" }
                    thumbnail = @{ url = $IconUrl } 
                }
            )
        }

        try {
            $json = $payload | ConvertTo-Json -Depth 10 -Compress
            Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $json -ContentType 'application/json'
            Write-Host "[OK] Sent to Discord!" -ForegroundColor Green
        } catch {
            Write-Host "[ERROR] Discord: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

} catch {
    Write-Host "`n[FATAL ERROR] $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nDone."
pause