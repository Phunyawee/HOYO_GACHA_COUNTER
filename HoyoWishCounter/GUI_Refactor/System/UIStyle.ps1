function Get-GuiFont ($Family, $Size, $Style="Regular") {
    try {
        return New-Object System.Drawing.Font($Family, $Size, [System.Drawing.FontStyle]::$Style)
    } catch {
        # Fallback กรณี Font ไม่มี ให้ไปใช้ Arial/Courier แทน
        $Fallback = if ($Family -match "Consolas|Code") { "Courier New" } else { "Arial" }
        return New-Object System.Drawing.Font($Fallback, $Size, [System.Drawing.FontStyle]::$Style)
    }
}

# กำหนดตัวแปรแบบ Global ($script:) เพื่อให้ Function อื่น (เช่น Apply-ButtonStyle) มองเห็น
$script:fontNormal = Get-GuiFont "Segoe UI" 9
$script:fontBold   = Get-GuiFont "Segoe UI" 9 "Bold"
$script:fontHeader = Get-GuiFont "Segoe UI" 12 "Bold"
$script:fontLog    = Get-GuiFont "Consolas" 10