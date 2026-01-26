# File: EmailGenerate/TableGenerator.ps1

function Generate-TableHTML {
    param(
        $DataList,
        $Style,
        [bool]$ShowNoMode,
        [bool]$SortDesc
    )

    $rows = ""
    # $HeadCol1 จริงๆ ในโค้ดเก่าไม่ได้ถูกเอาไปใช้ใน HTML (Hardcode เป็น Time ไว้) แต่ผมคงไว้เผื่อๆ
    $HeadCol1 = if ($ShowNoMode) { "Index [No.]" } else { "Time" }

    $TotalCount = $DataList.Count
    $LoopIndex = 0 

    # Loop 20 items logic เดิม
    foreach ($item in ($DataList | Select-Object -First 20)) {
            $pityVal = [int]$item.Pity
            $col = if ($pityVal -ge 75) { "#ff4d4d" } elseif ($pityVal -lt 20) { "#00e676" } else { "#ffb74d" }
            
            if ($ShowNoMode) {
            if ($SortDesc) {
                # เรียง ใหม่ -> เก่า
                $RealNumber = $TotalCount - $LoopIndex
            } else {
                # เรียง เก่า -> ใหม่
                $RealNumber = $LoopIndex + 1
            }
            $displayCol1 = "No. $RealNumber"
            } else {
            $displayCol1 = $item.Time
            }

            # Row Styling
            if ($Style -eq "Classic Table") {
            $rows += "<tr><td style='padding:5px;border:1px solid #ccc;'>$displayCol1</td><td style='padding:5px;border:1px solid #ccc;'>$($item.Name)</td><td style='padding:5px;border:1px solid #ccc;color:$col;'>$($item.Pity)</td></tr>"
            } elseif ($Style -eq "Terminal Mode") {
            $rows += "<tr><td style='padding:5px;border-bottom:1px dashed #0f0;'>$displayCol1</td><td style='padding:5px;border-bottom:1px dashed #0f0;'>$($item.Name)</td><td style='padding:5px;border-bottom:1px dashed #0f0;'>$($item.Pity)</td></tr>"
            } else {
            # Premium
            $rows += "<tr><td style='color:#aaa;padding:8px;border-bottom:1px solid #333;'>$displayCol1</td><td style='color:#eee;font-weight:bold;padding:8px;border-bottom:1px solid #333;'>$($item.Name)</td><td style='padding:8px;border-bottom:1px solid #333;'><span style='color:$col;'>$($item.Pity)</span></td></tr>"
            }
            
            $LoopIndex++
    }

    # Table Wrapper Styling
    if ($Style -eq "Classic Table") {
        return "<table width='100%' style='border-collapse:collapse;color:black;'><tr><th style='text-align:left;background:#eee;padding:5px;'>Time</th><th style='text-align:left;background:#eee;padding:5px;'>Item</th><th style='text-align:left;background:#eee;padding:5px;'>Pity</th></tr>$rows</table>"
    } elseif ($Style -eq "Terminal Mode") {
        return "<table width='100%' style='border-collapse:collapse;color:#0f0;font-family:Consolas;'><tr><th style='text-align:left;border-bottom:1px double #0f0;'>TIME</th><th style='text-align:left;border-bottom:1px double #0f0;'>ITEM</th><th style='text-align:left;border-bottom:1px double #0f0;'>PITY</th></tr>$rows</table>"
    } else {
        return "<table width='100%' cellspacing='0'><tr><th style='text-align:left;color:#666;'>Time</th><th style='text-align:left;color:#666;'>Item</th><th style='text-align:left;color:#666;'>Pity</th></tr>$rows</table>"
    }
}