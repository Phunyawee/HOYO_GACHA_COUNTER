# --- ZZZ CALCULATOR (SELECT MODE) ---
# Feature: Choose specific banner + Auto-Fix Real Gacha Type
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Web

try {
    Write-Host "--- ZZZ SIGNAL SEARCH (SELECT MODE) ---" -ForegroundColor Cyan
    
    # 1. URL Setup
    $rawClipboard = Get-Clipboard
    if ($null -eq $rawClipboard) { throw "Clipboard is empty!" }
    $inputUrl = $rawClipboard.ToString().Trim() -replace '"', '' -replace "'", '' 
    if ($inputUrl -notmatch "authkey") { throw "Invalid URL." }

    $uriObj = [System.Uri]$inputUrl
    $queryParams = [System.Web.HttpUtility]::ParseQueryString($uriObj.Query)
    $apiHost = "public-operation-nap-sg.hoyoverse.com" 
    if ($inputUrl -match "mihoyo.com") { $apiHost = "public-operation-nap.mihoyo.com" }
    $baseUrl = "https://$apiHost/common/gacha_record/api/getGachaLog"
    if (-not $queryParams["game_biz"]) { $queryParams["game_biz"] = "nap_global" }

    # Banner Config
    $bannerList = @(
        @{ Code="1"; Name="Standard Channel" },
        @{ Code="2"; Name="Exclusive Channel (Char)" },
        @{ Code="3"; Name="W-Engine Channel (Weapon)" },
        @{ Code="5"; Name="Bangboo Channel" }
    )

    # --- 2. MENU SELECTION ---
    Write-Host "`n[ SELECT BANNER TO FETCH ]" -ForegroundColor Yellow
    Write-Host " 1 : Standard" -ForegroundColor White
    Write-Host " 2 : Limited Character" -ForegroundColor Cyan
    Write-Host " 3 : Limited Weapon" -ForegroundColor Magenta
    Write-Host " 5 : Bangboo" -ForegroundColor Green
    Write-Host " 0 : FETCH ALL (Recommended)" -ForegroundColor Gray
    
    $selection = Read-Host "`nEnter Number (0-5)"
    
    # Determine what to fetch
    $targetBanners = @()
    switch ($selection) {
        "1" { $targetBanners = @($bannerList | Where-Object {$_.Code -eq "1"}) }
        "2" { $targetBanners = @($bannerList | Where-Object {$_.Code -eq "2"}) }
        "3" { $targetBanners = @($bannerList | Where-Object {$_.Code -eq "3"}) }
        "5" { $targetBanners = @($bannerList | Where-Object {$_.Code -eq "5"}) }
        "0" { $targetBanners = $bannerList }
        Default { 
            Write-Host "Invalid selection, defaulting to ALL." -ForegroundColor Red
            $targetBanners = $bannerList 
        }
    }

    function Get-GachaData {
        param ($code, $page, $endId)
        
        # --- THE FIX (Override Params) ---
        $queryParams["gacha_type"]      = "$code"
        $queryParams["real_gacha_type"] = "$code" # FORCE SERVER TO SWITCH BANNER
        $queryParams["size"]   = "20"
        $queryParams["page"]   = "$page"
        $queryParams["end_id"] = "$endId"
        
        $builder = New-Object System.UriBuilder($baseUrl)
        $builder.Query = $queryParams.ToString()
        return Invoke-RestMethod -Uri $builder.Uri.AbsoluteUri -Method Get -TimeoutSec 20
    }

    $allHistory = @()

    # 3. Fetching Loop
    foreach ($banner in $targetBanners) {
        Write-Host "`nFetching: $($banner.Name)..." -ForegroundColor Magenta
        $page = 1
        $lastEndId = "0"
        $isFinished = $false

        while (-not $isFinished) {
            Start-Sleep -Milliseconds 200 
            Write-Host "." -NoNewline -ForegroundColor Gray
            
            $data = Get-GachaData -code $banner.Code -page $page -endId $lastEndId
            
            if ($data.retcode -ne 0) {
                 Write-Host " Skip (API: $($data.message))" -ForegroundColor Red
                 break
            }
            $list = $data.data.list
            if ($null -eq $list -or $list.Count -eq 0) {
                $isFinished = $true
                break
            }
            
            $allHistory += $list
            $lastEndId = $list[$list.Count - 1].id
            $page++
        }
    }

    Write-Host "`n`n[SYSTEM] Processing..." -ForegroundColor Green

    # 4. Clean & Sort
    $uniqueHistory = $allHistory | Group-Object id | ForEach-Object { $_.Group[0] }
    $sortedItems = $uniqueHistory | Sort-Object { [decimal]$_.id }

    # 5. Calculation
    $pityTrackers = @{ "1"=0; "2"=0; "3"=0; "5"=0 }
    $sRankHistory = @()

    foreach ($item in $sortedItems) {
        $code = "$($item.gacha_type)"
        if (-not $pityTrackers.ContainsKey($code)) { $pityTrackers[$code] = 0 }
        $pityTrackers[$code]++

        if ($item.rank_type -eq "4") {
            $bName = switch ($code) {
                "1" { "Standard" }
                "2" { "Exclusive (Char)" }
                "3" { "W-Engine (Weap)" }
                "5" { "Bangboo" }
                Default { "Unknown($code)" }
            }

            $sRankHistory += [PSCustomObject]@{
                Time   = $item.time
                Name   = $item.name
                Banner = $bName
                Pity   = $pityTrackers[$code]
            }
            $pityTrackers[$code] = 0
        }
    }

    # 6. Output S-Rank
    Write-Host "`n================================================" -ForegroundColor Cyan
    Write-Host "   ZZZ S-RANK HISTORY (Selected) " -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan

    if ($sRankHistory.Count -gt 0) {
        for ($i = $sRankHistory.Count - 1; $i -ge 0; $i--) {
            $s = $sRankHistory[$i]
            $color = "Green"
            if ($s.Pity -gt 75) { $color = "Red" } elseif ($s.Pity -gt 50) { $color = "Yellow" }
            
            $bColor = "White"
            if ($s.Banner -match "Exclusive") { $bColor = "Cyan" }
            if ($s.Banner -match "W-Engine") { $bColor = "Magenta" }

            Write-Host "$($s.Time) | " -NoNewline -ForegroundColor Gray
            Write-Host "$($s.Name.PadRight(18)) " -NoNewline -ForegroundColor Yellow
            Write-Host "[$($s.Banner)] " -NoNewline -ForegroundColor $bColor
            Write-Host "Pity: $($s.Pity)" -ForegroundColor $color
        }
    } else {
        Write-Host "No S-Rank found in fetched data." -ForegroundColor DarkGray
    }

    # 7. Output Pity (Only show what we fetched)
    Write-Host "`n------------------------------------------------" -ForegroundColor Gray
    Write-Host " CURRENT PITY (For Fetched Banners) " -ForegroundColor Cyan
    Write-Host "------------------------------------------------" -ForegroundColor Gray
    
    foreach ($banner in $targetBanners) {
        $k = $banner.Code
        $val = if ($pityTrackers.ContainsKey($k)) { $pityTrackers[$k] } else { 0 }
        
        $cColor = "Green"
        if ($val -gt 70) { $cColor = "Red" } elseif ($val -gt 50) { $cColor = "Yellow" }
        
        Write-Host "$($banner.Name.PadRight(25)): " -NoNewline -ForegroundColor White
        Write-Host "$val" -ForegroundColor $cColor
    }

} catch {
    Write-Host "`nERROR: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""
pause