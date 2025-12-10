<#
.SYNOPSIS
    Script to extract Zenless Zone Zero AuthKey from local cache file.
    
.DESCRIPTION
    Advanced Logic: Scans EVERY potential link in the file and actively tests them against the API.
    This "Brute Force" method ensures 100% accuracy even if the file contains expired or garbage links.
#>

$ErrorActionPreference = "SilentlyContinue"
Add-Type -AssemblyName System.Web

# 1. รับไฟล์
$filePath = Read-Host -Prompt "Please enter the path to 'data_2' file (or drag and drop here)"
$filePath = $filePath -replace '"', ''

if (-not (Test-Path $filePath)) { 
    Write-Host "File not found at: $filePath" -ForegroundColor Red
    return 
}

Write-Host "Scanning & Testing links... (This might take a few seconds)" -ForegroundColor Cyan

# 2. อ่านไฟล์และแยก Chunk
$content = Get-Content -Path $filePath -Encoding UTF8 -Raw
$chunks = $content -split "1/0/"
$workingLink = $null

# 3. วนลูปเช็ค "ทุกท่อน"
# เราวนจากล่างขึ้นบน (Last to First) เพราะโอกาสเจอลิงก์ใหม่สุดมีมากกว่า
for ($i = $chunks.Length - 1; $i -ge 0; $i--) {
    $chunk = $chunks[$i]
    
    if ($chunk -match "authkey=") {
        # Clean Data
        $cleanStr = ($chunk -split "`0")[0]
        
        # Regex จับ URL
        if ($cleanStr -match "(https.+?authkey=.+)") {
            $testUrl = $matches[0]
            $testUrl = $testUrl.Split(" ")[0] # ตัดส่วนเกินออก
            
            # แปลง Host เป็น API เสมอ (สำคัญสำหรับ ZZZ)
            $uri = [System.Uri]$testUrl
            $apiHost = "public-operation-nap-sg.hoyoverse.com"
            
            # เช็คว่า URL เดิมมี game_biz ไหม (ถ้าไม่มี เติม nap_global)
            $qs = [System.Web.HttpUtility]::ParseQueryString($uri.Query)
            if (-not $qs["game_biz"]) { $qs["game_biz"] = "nap_global" }
            $qs["size"] = "1" # ขอแค่ 1 ตัวพอ เพื่อเทส
            
            # สร้าง URL สำหรับยิงเทส
            $builder = New-Object System.UriBuilder("https://$apiHost/common/gacha_record/api/getGachaLog")
            $builder.Query = $qs.ToString()
            $finalTestUrl = $builder.Uri.AbsoluteUri
            
            Write-Host "." -NoNewline -ForegroundColor Gray
            
            # --- ยิงเทสของจริง ---
            try {
                $response = Invoke-RestMethod -Uri $finalTestUrl -Method Get -TimeoutSec 3
                
                # ถ้า Retcode 0 แปลว่า Key นี้ใช้ได้จริง!
                if ($response.retcode -eq 0) {
                    Write-Host "`n[SUCCESS] Found working AuthKey!" -ForegroundColor Green
                    $workingLink = $finalTestUrl
                    break # เจอแล้วหยุดเลย
                }
            } catch {
                # เงียบไว้ ถ้า error ก็แค่ข้ามไปตัวถัดไป
            }
        }
    }
}

# 4. แสดงผล
if ($workingLink) {
    Write-Host "`n------------------------------------------------" -ForegroundColor Gray
    Write-Host $workingLink -ForegroundColor Yellow
    Write-Host "------------------------------------------------" -ForegroundColor Gray
    
    Set-Clipboard -Value $workingLink
    Write-Host "Link copied to clipboard! Ready to calculate." -ForegroundColor Green
} else {
    Write-Host "`n[FAILED] Valid link not found." -ForegroundColor Red
    Write-Host "Please open 'Signal Search History' in ZZZ again." -ForegroundColor Gray
}