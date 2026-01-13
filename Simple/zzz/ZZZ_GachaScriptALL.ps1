# --- ZZZ FINAL CALCULATOR (PARAM OVERRIDE VERSION) ---
# Logic: Mimic Browser by forcing 'real_gacha_type' to match the request
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Web

try {
    Write-Host "--- ZZZ CALCULATOR (PARAM OVERRIDE) ---" -ForegroundColor Cyan
    Write-Host "Status: Overriding 'real_gacha_type' to force correct banner data." -ForegroundColor DarkGray
    
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
    
    # Ensure game_biz exists
    if (-not $queryParams["game_biz"]) { $queryParams["game_biz"] = "nap_global" }

    # Banner Config
    $bannerTypes = @(
        @{ Code="1"; Name="Standard" },
        @{ Code="2"; Name="Limited Char" },
        @{ Code="3"; Name="Limited Weapon" },
        @{ Code="5"; Name="Bangboo" }
    )

    function Get-GachaData {
        param ($code, $page, $endId)
        
        # --- THE FIX: MIMIC BROWSER REQUEST ---
        # เราต้องส่งทั้ง gacha_type และ real_gacha_type ให้เป็นเลขเดียวกัน
        # เพื่อบังคับให้ Server เปลี่ยนตู้ตามที่เราขอ
        $queryParams["gacha_type"]      = "$code"
        $queryParams["real_gacha_type"] = "$code"  # <--- บรรทัดสำคัญที่เพิ่มมา
        
        $queryParams["size"]   = "20"
        $queryParams["page"]   = "$page"
        $queryParams["end_id"] = "$endId"
        
        # สร้าง URL ใหม่
        $builder = New-Object System.UriBuilder($baseUrl)
        $builder.Query = $queryParams.ToString()
        
        return Invoke-RestMethod -Uri $builder.Uri.AbsoluteUri -Method Get -TimeoutSec 20
    }

    $allHistory = @()

    # 2. Main Loop
    foreach ($banner in $bannerTypes) {
        Write-Host "`nFetching: $($banner.Name) (Code: $($banner.Code))..." -ForegroundColor Magenta
        $page = 1
        $lastEndId = "0"
        $isFinished = $false
        $retryCount = 0

        while (-not $isFinished) {
            Start-Sleep -Milliseconds 200 # Delay นิดหน่อย
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

    Write-Host "`n`n[SYSTEM] Cleaning & Calculation..." -ForegroundColor Green

    # 3. Clean Duplicates & Sort
    # ใช้ Group-Object id เพื่อฆ่าตัวซ้ำทิ้ง (กันพลาดกรณี API ยังส่งซ้ำมาบ้าง)
    $uniqueHistory = $allHistory | Group-Object id | ForEach-Object { $_.Group[0] }
    
    # เรียงจาก อดีต -> ปัจจุบัน (สำคัญมาก)
    $sortedItems = $uniqueHistory | Sort-Object { [decimal]$_.id }

    # 4. Pity Logic
    $pityTrackers = @{ "1"=0; "2"=0; "3"=0; "5"=0 }
    $sRankHistory = @()

    foreach ($item in $sortedItems) {
        # ใช้ gacha_type จาก Item ที่ได้มาจริงในการนับ
        $code = "$($item.gacha_type)"
        
        if (-not $pityTrackers.ContainsKey($code)) { $pityTrackers[$code] = 0 }
        $pityTrackers[$code]++

        # Rank 4 = S-Rank
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

    # 5. Display History
    Write-Host "`n================================================" -ForegroundColor Cyan
    Write-Host "   ZZZ S-RANK HISTORY " -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan

    if ($sRankHistory.Count -gt 0) {
        # Show Newest First
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
        Write-Host "No S-Rank found." -ForegroundColor DarkGray
    }

    # 6. Current Pity
    Write-Host "`n------------------------------------------------" -ForegroundColor Gray
    Write-Host " CURRENT PITY " -ForegroundColor Cyan
    Write-Host "------------------------------------------------" -ForegroundColor Gray
    
    $displayOrder = @("2", "3", "5", "1")
    foreach ($k in $displayOrder) {
        $val = if ($pityTrackers.ContainsKey($k)) { $pityTrackers[$k] } else { 0 }
        
        $label = switch ($k) {
            "2" { "Limited Character" }
            "3" { "Limited W-Engine" }
            "5" { "Bangboo" }
            "1" { "Standard" }
        }

        $cColor = "Green"
        if ($val -gt 70) { $cColor = "Red" } elseif ($val -gt 50) { $cColor = "Yellow" }
        
        Write-Host "$($label.PadRight(20)): " -NoNewline -ForegroundColor White
        Write-Host "$val" -ForegroundColor $cColor
    }

} catch {
    Write-Host "`nERROR: $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""
pause