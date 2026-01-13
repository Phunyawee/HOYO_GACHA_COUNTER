$ErrorActionPreference = "Stop"

# Helper function
function Parse-QueryString($url) {
    $qs = @{}
    if ($url -match '\?(.*)') {
        $matches[1].Split('&') | ForEach-Object {
            $parts = $_.Split('=')
            if ($parts.Count -eq 2) {
                $qs[$parts[0].Trim()] = $parts[1].Trim()
            }
        }
    }
    return $qs
}

try {
    Write-Host "--- Genshin All-In-One Calculator (Safe Mode) ---" -ForegroundColor Cyan
    
    # 1. Get URL
    $rawClipboard = Get-Clipboard
    if ($null -eq $rawClipboard) { throw "Clipboard is empty!" }
    
    $inputUrl = $rawClipboard.ToString().Trim()
    $inputUrl = $inputUrl -replace '"', '' -replace "'", ''
    
    if ($inputUrl -notmatch "^http") { throw "Clipboard does not contain a valid URL." }

    $queryParams = Parse-QueryString $inputUrl
    if (-not $queryParams.ContainsKey("authkey")) { throw "Invalid URL (Missing authkey)." }

    $targetHost = "public-operation-hk4e-sg.hoyoverse.com"
    if ($inputUrl -match "mihoyo.com") { $targetHost = "public-operation-hk4e.mihoyo.com" }

    # 2. Fetch Function
    function Get-GachaData {
        param ($gachaType, $page, $endId)
        $builder = New-Object System.UriBuilder("https://$targetHost/gacha_info/api/getGachaLog")
        $queryParams["gacha_type"] = "$gachaType"
        $queryParams["size"] = "20"
        $queryParams["page"] = "$page"
        $queryParams["end_id"] = "$endId"
        $newQuery = ($queryParams.Keys | ForEach-Object { "$_=$($queryParams[$_])" }) -join "&"
        $builder.Query = $newQuery
        return Invoke-RestMethod -Uri $builder.Uri.AbsoluteUri -Method Get -TimeoutSec 20
    }

    # Define Banners to fetch
    $bannerTypes = @(
        @{ Code="100"; Name="Novice" },
        @{ Code="200"; Name="Standard" },
        @{ Code="301"; Name="Character" },
        @{ Code="302"; Name="Weapon" }
    )

    $allHistory = @()

    # 3. Main Loop (Fetch Each Banner)
    foreach ($banner in $bannerTypes) {
        Write-Host "`nFetching: $($banner.Name)..." -ForegroundColor Magenta
        
        $page = 1
        $lastEndId = "0"
        $isFinished = $false
        $retryCount = 0

        while (-not $isFinished) {
            Write-Host "." -NoNewline -ForegroundColor Gray
            
            $data = Get-GachaData -gachaType $banner.Code -page $page -endId $lastEndId
            
            if ($data.retcode -ne 0) {
                if ($data.message -match "frequently") {
                    Write-Host "`nToo Fast! Waiting 15s..." -ForegroundColor Red
                    Start-Sleep -Seconds 15
                    $retryCount++
                    if ($retryCount -gt 5) { throw "Too many retries." }
                    continue
                } else {
                    Write-Host "Skip $($banner.Name) due to error: $($data.message)" -ForegroundColor Red
                    break
                }
            }

            $retryCount = 0
            $list = $data.data.list
            if ($null -eq $list -or $list.Count -eq 0) {
                $isFinished = $true
                break
            }

            # Add Banner Type Info to Item
            foreach ($item in $list) {
                $item | Add-Member -MemberType NoteProperty -Name "BannerName" -Value $banner.Name
                $item | Add-Member -MemberType NoteProperty -Name "BannerCode" -Value $banner.Code
            }

            $allHistory += $list
            $lastEndId = $list[$list.Count - 1].id
            $page++
            
            Start-Sleep -Seconds 1 # Safe delay per page
        }
        
        # Extra delay between banners to be safe
        Start-Sleep -Seconds 2 
    }

    Write-Host "`n`nProcessing Data..." -ForegroundColor Green

    # 4. Calculation (Sort & Pity Tracking)
    # Sort by ID (Time)
    $sortedItems = $allHistory | Sort-Object id 
    
    # Track Pity separately for each banner type
    $pityTrackers = @{
        "100" = 0
        "200" = 0
        "301" = 0
        "302" = 0
    }

    $goldHistory = @()

    # Re-calculate pity chronologically
    foreach ($item in $sortedItems) {
        $code = [string]$item.gacha_type
        # Group Character-2 (400) into Character (301) logic usually handled by API returning 301, 
        # but just in case:
        if ($code -eq "400") { $code = "301" }

        if ($pityTrackers.ContainsKey($code)) {
            $pityTrackers[$code]++
        }

        if ($item.rank_type -eq "5") {
            $currentPity = $pityTrackers[$code]
            
            $goldHistory += [PSCustomObject]@{
                Time   = $item.time
                Banner = $item.BannerName
                Name   = $item.name
                Pity   = $currentPity
            }
            # Reset pity for this banner type
            $pityTrackers[$code] = 0
        }
    }

    # 5. Result Display
    Write-Host "`n================================================" -ForegroundColor Cyan
    Write-Host "   5-STAR TIMELINE (ALL BANNERS) " -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan

    # Show from newest to oldest
    if ($goldHistory.Count -gt 0) {
        for ($i = $goldHistory.Count - 1; $i -ge 0; $i--) {
            $g = $goldHistory[$i]
            
            # Color logic
            $pityColor = "Green"
            if ($g.Pity -gt 75) { $pityColor = "Red" }
            elseif ($g.Pity -gt 50) { $pityColor = "Yellow" }
            
            # Banner Tag Color
            $bannerColor = "White"
            if ($g.Banner -match "Character") { $bannerColor = "Cyan" }
            if ($g.Banner -match "Weapon") { $bannerColor = "Magenta" }

            Write-Host "$($g.Time) | " -NoNewline -ForegroundColor Gray
            Write-Host "[$($g.Banner.Split(' ')[0])] " -NoNewline -ForegroundColor $bannerColor
            Write-Host "$($g.Name.PadRight(15)) " -NoNewline -ForegroundColor Yellow
            Write-Host "[Pity: $($g.Pity)]" -ForegroundColor $pityColor
        }
    } else {
        Write-Host "No 5-star items found." -ForegroundColor DarkGray
    }

    Write-Host "`n------------------------------------------------" -ForegroundColor Gray
    Write-Host " CURRENT PITY STATUS " -ForegroundColor Cyan
    Write-Host "------------------------------------------------" -ForegroundColor Gray
    
    foreach ($key in $pityTrackers.Keys) {
        $bName = ($bannerTypes | Where-Object { $_.Code -eq $key }).Name
        if ($null -ne $bName) {
             Write-Host "$($bName.PadRight(20)): " -NoNewline -ForegroundColor White
             Write-Host "$($pityTrackers[$key])" -ForegroundColor Green
        }
    }

} catch {
    Write-Host "`n!!! ERROR !!!" -ForegroundColor Red
    Write-Host "$($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""