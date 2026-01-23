# โหลด Assembly สำหรับจัดการ URL Parameter (ถ้ายังไม่ได้โหลด)
if ($PSVersionTable.PSVersion.Major -le 5) {
    Add-Type -AssemblyName System.Web
}

function Fetch-GachaPages {
    param(
        $Url, 
        $HostUrl, 
        $Endpoint, 
        $BannerCode, 
        $PageCallback # รับ ScriptBlock เพื่อทำ Progress Bar หรือ Log
    )
    
    $page = 1
    $endId = "0"
    $isFinished = $false
    $History = @()

    while (-not $isFinished) {
        # แจ้งสถานะกลับไปที่ Main Engine (ถ้ามี Callback)
        if ($PageCallback) { & $PageCallback $page }
        
        # หน่วงเวลาเล็กน้อยเพื่อป้องกัน Spam API
        Start-Sleep -Milliseconds 600

        $uriObj = [System.Uri]$Url
        $qs = [System.Web.HttpUtility]::ParseQueryString($uriObj.Query)
        
        # ตั้งค่า Parameter สำหรับ Pagination
        $qs["gacha_type"] = "$BannerCode"
        $qs["size"] = "20"
        $qs["page"] = "$page"
        $qs["end_id"] = "$endId"
        
        # Logic พิเศษสำหรับ ZZZ (Zenless Zone Zero)
        if ($qs["game_biz"] -match "nap") { 
            $qs["real_gacha_type"] = "$BannerCode" 
        }

        # สร้าง URL พร้อมยิง
        $builder = New-Object System.UriBuilder("https://$HostUrl$Endpoint")
        $builder.Query = $qs.ToString()
        
        try {
            $resp = Invoke-RestMethod -Uri $builder.Uri.AbsoluteUri -Method Get -TimeoutSec 10
        } catch {
            throw "Network Error: $($_.Exception.Message)"
        }
        
        if ($resp.retcode -ne 0) { throw "API Error: $($resp.message)" }
        
        $list = $resp.data.list

        if ($null -eq $list -or $list.Count -eq 0) { 
            $isFinished = $true 
        } else {
            # ==========================================
            # [FIX] CLEAN DATA (ASCII Safe Mode)
            # ==========================================
            # เราใช้รหัส \uXXXX แทนตัวอักษร เพื่อไม่ให้ไฟล์ Script พังเรื่อง Encoding
            # \u0E2D = อ (ขึ้นต้นคำว่า อาวุธ)
            # \u0E15 = ต (ขึ้นต้นคำว่า ตัวละคร)
            # \u00AD = ตัวขยะที่มักเจอในคำว่าอาวุธ
            # \u0095 = ตัวขยะที่มักเจอในคำว่าตัวละคร
            
            foreach ($item in $list) {
                # 1. Weapon Logic
                # Matches: "Weapon", "Light Cone", "W-Engine", "อาวุธ"(Thai Code), "Mojibake"(Code)
                if ($item.item_type -match "Weapon|Light|Engine|\u0E2D|\u00AD") {
                    $item.item_type = "Weapon"
                }
                # 2. Character Logic
                # Matches: "Character", "ตัวละคร"(Thai Code), "Mojibake"(Code)
                elseif ($item.item_type -match "Character|\u0E15|\u0095") {
                    $item.item_type = "Character"
                }
            }
            # ==========================================

            $History += $list
            
            # เตรียม end_id สำหรับหน้าถัดไป
            $endId = $list[$list.Count - 1].id
            $page++
        }
    }
    return $History
}