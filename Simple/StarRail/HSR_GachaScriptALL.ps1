# --- Star Rail All-In-One Calculator (Fixed & Stable) ---
$ErrorActionPreference = "Stop"
# Load necessary assembly for proper URL handling
Add-Type -AssemblyName System.Web

try {
    Write-Host "--- Star Rail All-In-One Calculator (Universal) ---" -ForegroundColor Cyan
    
    # 1. Get URL from Clipboard
    $rawClipboard = Get-Clipboard
    if ($null -eq $rawClipboard) { throw "Clipboard is empty!" }
    
    $inputUrl = $rawClipboard.ToString().Trim()
    $inputUrl = $inputUrl -replace '"', '' -replace "'", '' 
    
    if ($inputUrl -notmatch "authkey") {
        throw "Invalid URL (No authkey found). Please copy the URL again."
    }

    # 2. Parse URL safely using System.Uri (Prevents encoding errors)
    try {
        $uriObj = [System.Uri]$inputUrl
    } catch {
        throw "URL format error."
    }

    # Reconstruct Base URL
    # $baseUrl = "{0}://{1}{2}" -f $uriObj.Scheme, $uriObj.Host, $uriObj.AbsolutePath\
	# FIX: บังคับชี้ไปที่ API ของ Star Rail โดยตรง
	$baseUrl = "{0}://{1}/common/gacha_record/api/getGachaLog" -f $uriObj.Scheme, $uriObj.Host

    # 3. Parse Parameters safely
    $queryCollection = [System.Web.HttpUtility]::ParseQueryString($uriObj.Query)

    # Function to Fetch Data
    function Get-GachaData {
        param ($gachaType, $page, $endId)
        
        # Update parameters without breaking the Authkey
        $queryCollection["gacha_type"] = "$gachaType"
        $queryCollection["size"]       = "20"
        $queryCollection["page"]       = "$page"
        $queryCollection["end_id"]     = "$endId"
        
        # Optional: Force English if server demands it, otherwise leave as default
        # $queryCollection["lang"] = "en-us" 

        $builder = New-Object System.UriBuilder($baseUrl)
        $builder.Query = $queryCollection.ToString()
        
        return Invoke-RestMethod -Uri $builder.Uri.AbsoluteUri -Method Get -TimeoutSec 20
    }

    # Define Banners
    $bannerTypes = @(
        @{ Code="2";  Name="Departure" },
        @{ Code="1";  Name="Stellar" },
        @{ Code="11"; Name="Character" },
        @{ Code="12"; Name="Light Cone" }
    )

    $allHistory = @()

    # 4. Main Loop
    foreach ($banner in $bannerTypes) {
        Write-Host "`nFetching: $($banner.Name)..." -ForegroundColor Magenta
        
        $page = 1
        $lastEndId = "0"
        $isFinished = $false
        $retryCount = 0

        while (-not $isFinished) {
            Write-Host "." -NoNewline -ForegroundColor Gray
            
            $data = Get-GachaData -gachaType $banner.Code -page $page -endId $lastEndId
            
            # Error Handling
            if ($data.retcode -ne 0) {
                # Handle "Visit too frequently"
                if ($data.message -match "frequently") {
                    Write-Host "`nServer Busy! Waiting 15s..." -ForegroundColor Red
                    Start-Sleep -Seconds 15
                    $retryCount++
                    if ($retryCount -gt 5) { throw "Too many retries. Try again later." }
                    continue
                } else {
                    Write-Host "Skip $($banner.Name) (API Error: $($data.message))" -ForegroundColor Red
                    break
                }
            }

            $list = $data.data.list
            if ($null -eq $list -or $list.Count -eq 0) {
                $isFinished = $true
                break
            }

            # Tag Data
            foreach ($item in $list) {
                $item | Add-Member -MemberType NoteProperty -Name "BannerName" -Value $banner.Name
                $item | Add-Member -MemberType NoteProperty -Name "BannerCode" -Value $banner.Code
            }

            $allHistory += $list
            $lastEndId = $list[$list.Count - 1].id
            $page++
            
            Start-Sleep -Seconds 1 # Safety Delay
        }
        
        Start-Sleep -Seconds 2 # Banner Switch Delay
    }

    Write-Host "`n`nProcessing Data..." -ForegroundColor Green

    # 5. Calculate Pity
    $sortedItems = $allHistory | Sort-Object id 
    
    $pityTrackers = @{
        "2"  = 0
        "1"  = 0
        "11" = 0
        "12" = 0
    }

    $goldHistory = @()

    foreach ($item in $sortedItems) {
        $code = [string]$item.gacha_type
        
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
            $pityTrackers[$code] = 0
        }
    }

    # 6. Display Results
    Write-Host "`n================================================" -ForegroundColor Cyan
    Write-Host "   WARP TIMELINE (ALL BANNERS) " -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan

    if ($goldHistory.Count -gt 0) {
        for ($i = $goldHistory.Count - 1; $i -ge 0; $i--) {
            $g = $goldHistory[$i]
            
            $pityColor = "Green"
            if ($g.Pity -gt 75) { $pityColor = "Red" }
            elseif ($g.Pity -gt 50) { $pityColor = "Yellow" }
            
            $bannerColor = "White"
            if ($g.Banner -match "Character") { $bannerColor = "Cyan" }
            if ($g.Banner -match "Light Cone") { $bannerColor = "Magenta" }

            Write-Host "$($g.Time) | " -NoNewline -ForegroundColor Gray
            Write-Host "[$($g.Banner.Split(' ')[0])] " -NoNewline -ForegroundColor $bannerColor
            Write-Host "$($g.Name.PadRight(18)) " -NoNewline -ForegroundColor Yellow
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
             $displayColor = "White"
             if ($bName -match "Character") { $displayColor = "Cyan" }
             if ($bName -match "Light Cone") { $displayColor = "Magenta" }
             
             Write-Host "$($bName.PadRight(22)): " -NoNewline -ForegroundColor $displayColor
             Write-Host "$($pityTrackers[$key])" -ForegroundColor Green
        }
    }

} catch {
    Write-Host "`n!!! ERROR !!!" -ForegroundColor Red
    Write-Host "$($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Message -match "authkey") {
        Write-Host "Tip: Your URL might be expired. Please get a new one." -ForegroundColor Yellow
    }
}

Write-Host ""