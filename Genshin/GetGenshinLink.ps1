
<#
.SYNOPSIS
    Script to extract Gacha AuthKey from local cache file.
    
.DESCRIPTION
    Simplified version: Reads local file instead of auto-scanning.
    Logic for parsing 'webview_gacha' inspired by paimon.moe script.
    
.NOTES
    Original Concept: paimon.moe
    Refactored by: Phunyawee
#>

# 1. Path เดิมของคุณ
$filePath = Read-Host -Prompt "Please enter the path to 'data_2' file (or drag and drop here)"

# ลบเครื่องหมายคำพูดที่อาจติดมาตอนลากไฟล์ (Sanitize input)
$filePath = $filePath -replace '"', ''

if (-not (Test-Path $filePath)) { 
    Write-Host "File not found at: $filePath" -ForegroundColor Red
    return 
}

if (-not (Test-Path $filePath)) { Write-Host "File not found" -ForegroundColor Red; return }

Write-Host "Scanning for the LATEST link..." -ForegroundColor Cyan

$content = Get-Content -Path $filePath -Encoding UTF8 -Raw
$chunks = $content -split "1/0/"
$validLinks = @() # สร้างถุงเก็บลิงก์

# 2. วนลูปหาลิงก์ทั้งหมดมาเก็บไว้ก่อน (ยังไม่เลือก)
foreach ($chunk in $chunks) {
    if ($chunk -match "webview_gacha" -and $chunk -match "authkey=") {
        if ($chunk -match "(https.+?game_biz=)") {
            # เก็บเข้าถุง
            $validLinks += $matches[0]
        }
    }
}

# 3. เลือก "ตัวสุดท้าย" (The Last One) ของถุง
if ($validLinks.Count -gt 0) {
    $latestLink = $validLinks[-1] # [-1] แปลว่าตัวสุดท้ายใน Array

    Write-Host "`n[SUCCESS] Found $($validLinks.Count) links." -ForegroundColor Green
    Write-Host "Picking the LATEST one (Bottom of file):" -ForegroundColor Cyan
    Write-Host "-----------------------------------------------------------" -ForegroundColor Gray
    Write-Host $latestLink -ForegroundColor Yellow
    Write-Host "-----------------------------------------------------------" -ForegroundColor Gray
} else {
    Write-Host "No link found." -ForegroundColor Red
}