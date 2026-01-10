param (
    [string]$Game = "" 
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Web

# ==========================================
# 1. SETUP & CONFIGURATION
# ==========================================
$CurrentGame = $null
$IsFirstRunAuto = $false
# ใช้ $script: นำหน้าเพื่อล็อคค่าตัวแปรให้จำตลอดการทำงาน
$script:ShowNoMode = $false  
$script:RepeatGame = $false

if ($Game -ne "") {
    $CurrentGame = $Game
    $IsFirstRunAuto = $true
}

if (Test-Path "config.json") {
    $ConfigFile = Get-Content "config.json" -Raw | ConvertFrom-Json
    $WebhookUrl = $ConfigFile.webhook_url
} else {
    $WebhookUrl = ""
    Write-Host "[WARN] config.json not found. Discord feature disabled." -ForegroundColor Yellow
}

# ==========================================
# 2. FUNCTIONS
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

            if ($cleanStr -match "(https.+?game_biz=[\w_]+)") {
                $rawUrl = $matches[0]
            } elseif ($cleanStr -match "(https.+?authkey=[^`" ]+)") {
                $rawUrl = $matches[0]
            }

            if ($rawUrl) {
                try {
                    $uri = [System.Uri]$rawUrl
                    $qs = [System.Web.HttpUtility]::ParseQueryString($uri.Query)
                    if (-not $qs["game_biz"]) { $qs["game_biz"] = $global:GameBiz }
                    $qs["size"] = "1" 
                    $qs["gacha_type"] = $global:Banners[0].Code 
                    if ($global:GameName -eq "ZZZ") { $qs["real_gacha_type"] = $global:Banners[0].Code }
                    
                    $testHost = $uri.Host
                    $builder = New-Object System.UriBuilder("https://$testHost$global:ApiEndpoint")
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

function Get-GachaData {
    param ($Url, $GachaType, $Page, $EndId)
    $uriObj = [System.Uri]$Url
    $qs = [System.Web.HttpUtility]::ParseQueryString($uriObj.Query)
    $qs["gacha_type"] = "$GachaType"
    $qs["size"] = "20"
    $qs["page"] = "$Page"
    $qs["end_id"] = "$EndId"
    if ($global:GameName -eq "ZZZ") { $qs["real_gacha_type"] = "$GachaType" }
    
    $builder = New-Object System.UriBuilder("https://$global:HostUrl$global:ApiEndpoint")
    $builder.Query = $qs.ToString()
    return Invoke-RestMethod -Uri $builder.Uri.AbsoluteUri -Method Get -TimeoutSec 20
}

# ==========================================
# 3. MAIN PROCESS LOOP
# ==========================================
do {
    Clear-Host
    Write-Host "--- HOYO UNIVERSAL WISH COUNTER ---" -ForegroundColor Cyan
    
    # --- GAME SELECTION LOGIC ---
    if ($IsFirstRunAuto) {
        Write-Host "Auto-starting from BAT: $CurrentGame" -ForegroundColor Green
        $GameToRun = $CurrentGame
        $IsFirstRunAuto = $false 
    }
    elseif ($script:RepeatGame) {
        Write-Host "Resuming Game: $GameToRun" -ForegroundColor Green
        $script:RepeatGame = $false 
    }
    else {
        # MENU DISPLAY
        Write-Host "`n[ SELECT GAME ]" -ForegroundColor Yellow
        Write-Host " 1 : Genshin Impact"
        Write-Host " 2 : Honkai: Star Rail"
        Write-Host " 3 : Zenless Zone Zero"
        
        # Toggle Option
        $modeTxt = if ($script:ShowNoMode) { "Number (No.)" } else { "Date/Time" }
        Write-Host " T : Toggle Display Mode (Current: $modeTxt)" -ForegroundColor Cyan
        Write-Host " Q : Quit" -ForegroundColor Red
        
        $choice = Read-Host "`nSelect (1-3, T, Q)"
        
        if ($choice -match "^[qQ]") { break }
        
        if ($choice -match "^[tT]") {
            $script:ShowNoMode = -not $script:ShowNoMode
            continue 
        }

        switch ($choice) {
            "1" { $GameToRun = "Genshin" }
            "2" { $GameToRun = "HSR" }
            "3" { $GameToRun = "ZZZ" }
            Default { 
                Write-Host "Invalid. Defaulting to Genshin." -ForegroundColor Gray
                $GameToRun = "Genshin" 
            }
        }
    }

    # --- SET CONFIG PER GAME ---
    $global:GameName = $GameToRun 

    $BaseRepoUrl = "https://raw.githubusercontent.com/Phunyawee/HOYO_GACHA_COUNTER/main/HoyoWishCounter/BotIcon"
    switch ($GameToRun) {
        "Genshin" {
            $global:HostUrl = "public-operation-hk4e-sg.hoyoverse.com"
            $global:ApiEndpoint = "/gacha_info/api/getGachaLog"
            $global:GameBiz = "hk4e_global"
            $SRankCode = "5"; $ThemeColor = 16766720
            $IconUrl = "$BaseRepoUrl/Paimon.png" 
            $global:Banners = @(@{ Code="301"; Name="Character Event" },@{ Code="302"; Name="Weapon Event" },@{ Code="200"; Name="Standard" },@{ Code="100"; Name="Novice" })
        }
        "HSR" {
            $global:HostUrl = "public-operation-hkrpg.hoyoverse.com"
            $global:ApiEndpoint = "/common/gacha_record/api/getGachaLog"
            $global:GameBiz = "hkrpg_global"
            $SRankCode = "5"; $ThemeColor = 3447003
            $IconUrl = "$BaseRepoUrl/PomPom.png"
            $global:Banners = @(@{ Code="11"; Name="Character Warp" },@{ Code="12"; Name="Light Cone Warp" },@{ Code="1";  Name="Stellar Warp" },@{ Code="2";  Name="Departure Warp" })
        }
        "ZZZ" {
            $global:HostUrl = "public-operation-nap-sg.hoyoverse.com"
            $global:ApiEndpoint = "/common/gacha_record/api/getGachaLog"
            $global:GameBiz = "nap_global"
            $SRankCode = "4"; $ThemeColor = 16738816
            $IconUrl = "$BaseRepoUrl/Bangboo.png"
            $global:Banners = @(@{ Code="2"; Name="Exclusive (Char)" },@{ Code="3"; Name="W-Engine (Weap)" },@{ Code="5"; Name="Bangboo" },@{ Code="1"; Name="Standard" })
        }
    }

    try {
        # --- FETCHING PROCESS ---
        $workingUrl = Get-AuthLink
        
        Write-Host "`n[ SELECT BANNER TO FETCH ]" -ForegroundColor Yellow
        $i = 1
        foreach ($b in $global:Banners) { Write-Host " $i : $($b.Name)"; $i++ }
        Write-Host " 0 : FETCH ALL (Recommended)" -ForegroundColor Green

        $sel = Read-Host "`nEnter Number (0 - $($global:Banners.Count))"
        if ($sel -match "^[1-9]\d*$" -and [int]$sel -le $global:Banners.Count) {
            $TargetBanners = @($global:Banners[[int]$sel - 1])
        } else {
            $TargetBanners = $global:Banners
        }

        $allHistory = @()
        foreach ($banner in $TargetBanners) {
            Write-Host "`nFetching: $($banner.Name)..." -ForegroundColor Magenta
            $page = 1; $endId = "0"; $isFinished = $false
            while (-not $isFinished) {
                Write-Host "." -NoNewline -ForegroundColor Gray
                
                Start-Sleep -Milliseconds 600 
                
                $resp = Get-GachaData -Url $workingUrl -GachaType $banner.Code -Page $page -EndId $endId
                if ($resp.retcode -ne 0) { Write-Host " Error: $($resp.message)" -ForegroundColor Red; break }
                $list = $resp.data.list
                if ($null -eq $list -or $list.Count -eq 0) { $isFinished = $true; break }
                foreach ($item in $list) { $item | Add-Member -MemberType NoteProperty -Name "_BannerName" -Value $banner.Name }
                $allHistory += $list
                $endId = $list[$list.Count - 1].id
                $page++
            }
            Start-Sleep -Seconds 1
        }

        # --- CALC PITY ---
        Write-Host "`n`n[PROCESSING] Calculating Pity..." -ForegroundColor Green
        $sortedItems = $allHistory | Sort-Object { [decimal]$_.id }
        $pityTrackers = @{}; foreach ($b in $global:Banners) { $pityTrackers[$b.Code] = 0 }
        $highRankHistory = @()

        foreach ($item in $sortedItems) {
            $code = [string]$item.gacha_type
            if ($GameToRun -eq "Genshin" -and $code -eq "400") { $code = "301" }
            if (-not $pityTrackers.ContainsKey($code)) { $pityTrackers[$code] = 0 }
            $pityTrackers[$code]++
            if ($item.rank_type -eq $SRankCode) {
                $highRankHistory += [PSCustomObject]@{ Time=$item.time; Name=$item.name; Banner=$item._BannerName; Pity=$pityTrackers[$code] }
                $pityTrackers[$code] = 0
            }
        }

        # --- OUTPUT CONSOLE ---
        Write-Host "`n================================================" -ForegroundColor Cyan
        Write-Host "   $GameToRun HIGH RANK HISTORY" -ForegroundColor Cyan
        Write-Host "================================================" -ForegroundColor Cyan
        if ($highRankHistory.Count -gt 0) {
            for ($i = $highRankHistory.Count - 1; $i -ge 0; $i--) {
                $h = $highRankHistory[$i]
                $pColor = "Green"; if ($h.Pity -gt 75) { $pColor = "Red" } elseif ($h.Pity -gt 50) { $pColor = "Yellow" }
                
                if ($script:ShowNoMode) {
                     Write-Host "[No.$($i+1)]".PadRight(18) -NoNewline -ForegroundColor Cyan
                } else {
                     Write-Host "[$($h.Time)] " -NoNewline -ForegroundColor Gray
                }
                
                Write-Host "$($h.Name.PadRight(18)) " -NoNewline -ForegroundColor Yellow
                Write-Host "Pity: $($h.Pity)" -ForegroundColor $pColor
            }
        }

        # --- DISCORD ---
        if (-not [string]::IsNullOrWhiteSpace($WebhookUrl)) {
            Write-Host "`nSend to Discord? (Y/N)" -ForegroundColor Magenta -NoNewline
            $confirm = Read-Host " "
            if ($confirm -match "^[yY]") {
                Write-Host "Sending..." -ForegroundColor Magenta
                $fields = @()
                foreach ($b in $global:Banners) {
                    $val = $pityTrackers[$b.Code]; if ($null -eq $val) { $val = 0 }
                    $fields += @{ name = "$($b.Name) Pity"; value = "**$val**"; inline = $true }
                }
                
                $descTxt = ""; $count = 0; $limit = 30
                if ($highRankHistory.Count -gt 0) {
                    $descTxt = "**Recent History (Last $limit):**`n"
                    for ($i = $highRankHistory.Count - 1; $i -ge 0; $i--) {
                        if ($count -ge $limit) { break }
                        $h = $highRankHistory[$i]
                        $icon = ":green_circle:"
                        if ($h.Pity -gt 75) { $icon = ":red_circle:" } elseif ($h.Pity -gt 50) { $icon = ":yellow_circle:" }
                        
                        # >>> DISCORD DISPLAY LOGIC (ตรวจสอบ Scope แล้ว) <<<
                        if ($script:ShowNoMode) {
                            $prefix = "[No.$($i+1)]"
                        } else {
                            $prefix = "`[$($h.Time)`]" # เวลาเต็มๆ
                        }
                        
                        $bNameShort = $h.Banner.Split('(')[0].Trim().Split(' ')[0]
                        $descTxt += "$prefix $icon **$($h.Name)** (Pity: **$($h.Pity)**) - *$bNameShort*`n"
                        $count++
                    }
                } else { $descTxt = "No history found." }

                $payload = @{
                    username = "$GameToRun Tracker"
                    avatar_url = $IconUrl 
                    embeds = @(@{ title = "$GameToRun Wish Report"; description = $descTxt; color = $ThemeColor; fields = @($fields); footer = @{ text = "Generated by Universal Hoyo Counter" }; thumbnail = @{ url = $IconUrl } })
                }
                try {
                    $json = $payload | ConvertTo-Json -Depth 10 -Compress
                    Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $json -ContentType 'application/json'
                    Write-Host "[OK] Discord Sent!" -ForegroundColor Green
                } catch { Write-Host "Discord Error" -ForegroundColor Red }
            }
        }

    } catch {
        Write-Host "`n[ERROR] $($_.Exception.Message)" -ForegroundColor Red
    }

    Write-Host "`n--------------------------------"
    Write-Host "[ENTER] Check Same Game Again ($GameToRun)" -ForegroundColor Green
    Write-Host "[M]     Back to Main Menu" -ForegroundColor Yellow
    Write-Host "[Q]     Quit" -ForegroundColor Red
    
    $retry = Read-Host
    if ($retry -match "^[qQ]") { break }
    
    if ($retry -match "^[mM]") { 
        $script:RepeatGame = $false 
    } else {
        $script:RepeatGame = $true 
    }

} while ($true)

Write-Host "Bye Bye!"