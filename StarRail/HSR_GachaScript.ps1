# --- SCRIPT 3: Star Rail Pity Calculator (Universal Fix) ---

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Web

try {
    Write-Host "--- Honkai: Star Rail Pity Calculator (Universal) ---" -ForegroundColor Cyan
    
    # 1. รับ URL
    $rawClipboard = Get-Clipboard
    if ($null -eq $rawClipboard) { throw "Clipboard is empty!" }
    
    $inputUrl = $rawClipboard.ToString().Trim()
    $inputUrl = $inputUrl -replace '"', '' -replace "'", '' 
    
    if ($inputUrl -notmatch "authkey") {
        throw "Invalid URL (No authkey found)"
    }

    # 2. แกะ URL (ใช้ค่าเดิมจากลิงก์ 100% เพื่อป้องกัน Error -502)
    try {
        $uriObj = [System.Uri]$inputUrl
    } catch {
        throw "URL format error."
    }

    # ดึง Base URL เดิม (เพื่อรองรับเซิร์ฟ CN หรือ Global อัตโนมัติ)
    # $baseUrl = "{0}://{1}{2}" -f $uriObj.Scheme, $uriObj.Host, $uriObj.AbsolutePath
	$baseUrl = "{0}://{1}/common/gacha_record/api/getGachaLog" -f $uriObj.Scheme, $uriObj.Host

    # 3. เตรียม Parameter
    $queryCollection = [System.Web.HttpUtility]::ParseQueryString($uriObj.Query)

    # --- แก้ไขเฉพาะที่จำเป็นจริงๆ ---
    $queryCollection["gacha_type"] = "11"   # บังคับดูตู้ตัวละคร
    $queryCollection["size"]       = "20"   # โหลดทีละ 20
    # เราลบการบังคับ game_biz และ lang ออก เพื่อให้ใช้ค่าเดิมจากไอดีคุณ

    # 4. ฟังก์ชันดึงข้อมูล
    function Get-GachaData {
        param ($page, $endId)
        
        # อัปเดตค่าหน้าปัจจุบัน
        $queryCollection["page"]   = "$page"
        $queryCollection["end_id"] = "$endId"
        
        $builder = New-Object System.UriBuilder($baseUrl)
        $builder.Query = $queryCollection.ToString()
        
        return Invoke-RestMethod -Uri $builder.Uri.AbsoluteUri -Method Get -TimeoutSec 20
    }

    # 5. เริ่มโหลด
    $allItems = @()
    $page = 1
    $lastEndId = "0"
    $isFinished = $false
    $retryCount = 0

    Write-Host "Detecting Server: $($uriObj.Host)" -ForegroundColor DarkGray
    Write-Host "Downloading Data..." -ForegroundColor Yellow
    
    while (-not $isFinished) {
        Write-Host "." -NoNewline -ForegroundColor Gray
        
        $data = Get-GachaData -page $page -endId $lastEndId
        
        # เช็ค Error
        if ($data.retcode -ne 0) {
            # ถ้ายัง Error อีก แสดงข้อความดิบๆ มาดูเลย
            throw "API Error: $($data.message) (Code: $($data.retcode)) `nURL Debug: $($uriObj.Host)"
        }

        $list = $data.data.list
        
        if ($null -eq $list -or $list.Count -eq 0) {
            $isFinished = $true
            break
        }

        $allItems += $list
        $lastEndId = $list[$list.Count - 1].id
        $page++
        
        Start-Sleep -Seconds 1 
    }

    Write-Host "`nProcessing..." -ForegroundColor Green

    # 6. คำนวณ Pity
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

    # 7. แสดงผล
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "   STAR RAIL 5-STAR HISTORY " -ForegroundColor Cyan
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