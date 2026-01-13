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
    Write-Host "--- Genshin Pity Calculator (Safe Mode) ---" -ForegroundColor Cyan
    
    # 1. Get URL
    $rawClipboard = Get-Clipboard
    if ($null -eq $rawClipboard) { throw "Clipboard is empty!" }
    
    $inputUrl = $rawClipboard.ToString().Trim()
    $inputUrl = $inputUrl -replace '"', '' -replace "'", ''
    
    if ($inputUrl -notmatch "^http") {
        throw "Clipboard does not contain a valid URL."
    }

    $queryParams = Parse-QueryString $inputUrl
    if (-not $queryParams.ContainsKey("authkey")) {
        throw "Invalid URL (Missing authkey)."
    }

    $targetHost = "public-operation-hk4e-sg.hoyoverse.com"
    if ($inputUrl -match "mihoyo.com") { $targetHost = "public-operation-hk4e.mihoyo.com" }

    # 2. Fetch Function
    function Get-GachaData {
        param ($page, $endId)
        $builder = New-Object System.UriBuilder("https://$targetHost/gacha_info/api/getGachaLog")
        $queryParams["gacha_type"] = "301"
        $queryParams["size"] = "20"
        $queryParams["page"] = "$page"
        $queryParams["end_id"] = "$endId"
        $newQuery = ($queryParams.Keys | ForEach-Object { "$_=$($queryParams[$_])" }) -join "&"
        $builder.Query = $newQuery
        return Invoke-RestMethod -Uri $builder.Uri.AbsoluteUri -Method Get -TimeoutSec 20
    }

    # 3. Download with Retry Logic
    $allItems = @()
    $page = 1
    $lastEndId = "0"
    $isFinished = $false
    $retryCount = 0

    Write-Host "Downloading... (Slow speed to prevent errors)" -ForegroundColor Yellow
    
    while (-not $isFinished) {
        Write-Host "." -NoNewline -ForegroundColor Gray
        
        # Try to get data
        $data = Get-GachaData -page $page -endId $lastEndId
        
        # Check for API errors
        if ($data.retcode -ne 0) {
            # Special handling for "visit too frequently"
            if ($data.message -match "frequently") {
                Write-Host "`nServer said: Too fast! Waiting 15 seconds..." -ForegroundColor Red
                Start-Sleep -Seconds 15
                $retryCount++
                
                if ($retryCount -gt 5) { throw "Too many retries. Please wait 30 mins." }
                continue # Try the same page again
            } else {
                throw "API Error: $($data.message)"
            }
        }

        # Reset retry count if successful
        $retryCount = 0

        $list = $data.data.list
        if ($null -eq $list -or $list.Count -eq 0) {
            $isFinished = $true
            break
        }

        $allItems += $list
        $lastEndId = $list[$list.Count - 1].id
        $page++
        
        # WAIT 1 SECOND (Safe Mode)
        Start-Sleep -Seconds 1 
    }

    Write-Host "`nProcessing..." -ForegroundColor Green

    # 4. Calculation
    $sortedItems = $allItems | Sort-Object id 
    $pityCounter = 0
    $goldHistory = @()

    foreach ($item in $sortedItems) {
        $pityCounter++
        if ($item.rank_type -eq "5") {
            $goldHistory += [PSCustomObject]@{
                Time = $item.time
                Name = $item.name
                Pity = $pityCounter
            }
            $pityCounter = 0
        }
    }

    # 5. Result
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "   5-STAR HISTORY " -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan

    if ($goldHistory.Count -gt 0) {
        for ($i = $goldHistory.Count - 1; $i -ge 0; $i--) {
            $g = $goldHistory[$i]
            $pityColor = "Green"
            if ($g.Pity -gt 75) { $pityColor = "Red" }
            elseif ($g.Pity -gt 50) { $pityColor = "Yellow" }

            Write-Host "$($g.Time) | " -NoNewline -ForegroundColor Gray
            Write-Host "$($g.Name.PadRight(15)) " -NoNewline -ForegroundColor Yellow
            Write-Host "[Pity: $($g.Pity)]" -ForegroundColor $pityColor
        }
    } else {
        Write-Host "No 5-star items found in last 6 months." -ForegroundColor DarkGray
    }

    Write-Host "----------------------------------------" -ForegroundColor Gray
    Write-Host "Current Pity: " -NoNewline -ForegroundColor Cyan
    Write-Host "$pityCounter" -ForegroundColor White
    Write-Host "Total Pulls:  " -NoNewline -ForegroundColor Cyan
    Write-Host "$($sortedItems.Count)" -ForegroundColor White

} catch {
    Write-Host "`n!!! ERROR !!!" -ForegroundColor Red
    Write-Host "$($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""