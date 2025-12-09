<#
.SYNOPSIS
    Script to extract Star Rail AuthKey from local cache file.
    
.DESCRIPTION
    Improved logic: Targets 'getGachaLog' directly and ensures 'game_biz' is captured.
    Fixes "Game Name Error" by cleaning binary data.
#>

# 1. รับ Path ไฟล์ (แบบลากวางหรือพิมพ์)
$filePath = Read-Host -Prompt "Please enter the path to 'data_2' file (or drag and drop here)"

# Sanitize input (ลบเครื่องหมายคำพูด)
$filePath = $filePath -replace '"', ''

if (-not (Test-Path $filePath)) { 
    Write-Host "File not found at: $filePath" -ForegroundColor Red
    return 
}

Write-Host "Scanning 'data_2' for the LATEST link..." -ForegroundColor Cyan

# 2. อ่านไฟล์และแยก Chunk
$content = Get-Content -Path $filePath -Encoding UTF8 -Raw
$chunks = $content -split "1/0/"
$foundLink = $null

# 3. วนลูปจาก "ล่างขึ้นบน" (หาตัวล่าสุดก่อน)
for ($i = $chunks.Length - 1; $i -ge 0; $i--) {
    $chunk = $chunks[$i]
    
    # Logic ใหม่ของคุณ: หา getGachaLog และ authkey
    if ($chunk -match "getGachaLog" -and $chunk -match "authkey=") {
        
        # ล้างขยะ Binary (Null characters)
        $rawUrl = ($chunk -split "`0")[0]
        
        # Regex จับลิงก์จนจบ game_biz (สำคัญมากสำหรับ HSR)
        if ($rawUrl -match "(https.+?game_biz=[\w_]+)") {
            $foundLink = $matches[0]
            break # เจอแล้วหยุดเลย
        }
    }
}

# 4. แสดงผลและ Copy
if ($foundLink) {
    Write-Host "`n[SUCCESS] Latest Link Found!" -ForegroundColor Green
    Write-Host "-----------------------------------------------------------" -ForegroundColor Gray
    Write-Host $foundLink -ForegroundColor Yellow
    Write-Host "-----------------------------------------------------------" -ForegroundColor Gray
    
    Set-Clipboard -Value $foundLink
    Write-Host "Link copied to clipboard! Ready to calculate." -ForegroundColor Green
} else {
    Write-Host "`n[FAILED] No link found." -ForegroundColor Red
    Write-Host "Please open 'Warp History' in Star Rail again." -ForegroundColor Gray
}