# File: EmailGenerate/TableGenerator.ps1

function Generate-TableHTML {
    param(
        $DataList,
        $Style,
        [bool]$ShowNoMode,
        [bool]$SortDesc
    )

    # --- 1. กำหนดสีตามโทน (Dynamic Contrast) ---
    # แยกแยะว่าธีมที่เลือก เป็น "พื้นขาว" หรือ "พื้นมืด"
    if ($Style -match "Minimalist|Classic|Excel|Vintage|Gacha") {
        # === กลุ่มธีมสว่าง (พื้นขาว/ครีม) ===
        $ColorTime = "#555555"   # สีเทาเข้ม (สำหรับเวลา)
        $ColorName = "#000000"   # สีดำสนิท (สำหรับชื่อ)
        $BorderCol = "#dddddd"   # สีขอบจางๆ
    } 
    elseif ($Style -eq "Terminal Mode") {
        # === กลุ่มธีม Terminal (พื้นดำ) ===
        $ColorTime = "#00ff00"   # เขียว
        $ColorName = "#00ff00"   # เขียว
        $BorderCol = "#00ff00"   # เขียว
    } 
    else {
        # === กลุ่มธีมมืด (Universal, Modern, Cyber, Blueprint) ===
        $ColorTime = "#aaaaaa"   # สีเทาอ่อน (สำหรับเวลา)
        $ColorName = "#ffffff"   # สีขาว (สำหรับชื่อ)
        $BorderCol = "#444444"   # สีขอบเข้มๆ
    }

    $rows = ""
    $TotalCount = $DataList.Count
    $LoopIndex = 0 

    foreach ($item in ($DataList | Select-Object -First 20)) {
            # Logic สี Pity (ตัวเลข) อันนี้เก็บไว้ เพราะดูง่ายดี
            $pityVal = [int]$item.Pity
            $pityCol = if ($pityVal -ge 75) { "#ff4d4d" } elseif ($pityVal -lt 20) { "#00e676" } else { "#ffb74d" }
            
            # คำนวณเลขลำดับ (No.)
            if ($ShowNoMode) {
                if ($SortDesc) { $RealNumber = $TotalCount - $LoopIndex } else { $RealNumber = $LoopIndex + 1 }
                $displayCol1 = "No. $RealNumber"
            } else {
                $displayCol1 = $item.Time
            }

            # --- สร้าง HTML Row โดยใช้ตัวแปรสีที่ตั้งไว้ข้างบน ---
            if ($Style -eq "Terminal Mode") {
                # แบบ Terminal (เส้นประ)
                $rows += "<tr>
                            <td style='padding:5px; border-bottom:1px dashed $BorderCol; color:$ColorTime;'>$displayCol1</td>
                            <td style='padding:5px; border-bottom:1px dashed $BorderCol; color:$ColorName;'>$($item.Name)</td>
                            <td style='padding:5px; border-bottom:1px dashed $BorderCol; color:$pityCol;'>$($item.Pity)</td>
                          </tr>"
            } else {
                # แบบทั่วไป (ใช้ตัวแปร $ColorTime และ $ColorName รับรองไม่กลืนพื้นหลัง)
                $rows += "<tr>
                            <td style='padding:8px; border-bottom:1px solid $BorderCol; color:$ColorTime;'>$displayCol1</td>
                            <td style='padding:8px; border-bottom:1px solid $BorderCol; color:$ColorName; font-weight:bold;'>$($item.Name)</td>
                            <td style='padding:8px; border-bottom:1px solid $BorderCol;'><span style='color:$pityCol;'>$($item.Pity)</span></td>
                          </tr>"
            }
            
            $LoopIndex++
    }

    # --- ส่วนหัวตาราง (Wrapper) ปรับให้สีเข้ากัน ---
    if ($Style -eq "Classic Table") {
        return "<table width='100%' style='border-collapse:collapse;'><tr><th style='text-align:left;background:#eee;padding:5px;color:#000;'>Time</th><th style='text-align:left;background:#eee;padding:5px;color:#000;'>Item</th><th style='text-align:left;background:#eee;padding:5px;color:#000;'>Pity</th></tr>$rows</table>"
    } elseif ($Style -eq "Terminal Mode") {
        return "<table width='100%' style='border-collapse:collapse;font-family:Consolas;'><tr><th style='text-align:left;border-bottom:1px double #0f0;color:#0f0;'>TIME</th><th style='text-align:left;border-bottom:1px double #0f0;color:#0f0;'>ITEM</th><th style='text-align:left;border-bottom:1px double #0f0;color:#0f0;'>PITY</th></tr>$rows</table>"
    } else {
        # Header ของโหมดทั่วไป ให้สี Header จางกว่าเนื้อหานิดหน่อย
        return "<table width='100%' cellspacing='0'><tr><th style='text-align:left;color:$ColorTime;opacity:0.7;'>Time</th><th style='text-align:left;color:$ColorTime;opacity:0.7;'>Item</th><th style='text-align:left;color:$ColorTime;opacity:0.7;'>Pity</th></tr>$rows</table>"
    }
}