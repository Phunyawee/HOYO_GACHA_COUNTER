# ---------------------------------------------------------------------------
# MODULE: 01_AboutCredits.ps1
# DESCRIPTION: Shows "About" info in the main log window
# PARENT: 02_HELP.ps1
# ---------------------------------------------------------------------------

$itemCredits = New-Object System.Windows.Forms.ToolStripMenuItem("About & Credits")
$itemCredits.ShortcutKeys = "F1" 

# เพิ่มลงใน Menu Help (ตัวแปร $menuHelp ถูกสร้างจากไฟล์แม่)
[void]$menuHelp.DropDownItems.Add($itemCredits)

$itemCredits.Add_Click({
    # ใช้ $script:txtLog เพื่อความชัวร์เรื่อง Scope
    $script:txtLog.Clear()
    $script:txtLog.SelectionAlignment = "Center"

    # --- PALETTE SETUP ---
    $colTitle  = [System.Drawing.Color]::FromArgb(60, 220, 255) 
    $colSub    = [System.Drawing.Color]::FromArgb(150, 150, 160)
    $colGold   = [System.Drawing.Color]::FromArgb(255, 200, 60)
    $colQuote  = [System.Drawing.Color]::FromArgb(140, 255, 170)
    $colFooter = [System.Drawing.Color]::FromArgb(80, 80, 90)

    # --- HEADER ---
    $script:txtLog.SelectionFont = New-Object System.Drawing.Font("Consolas", 14, [System.Drawing.FontStyle]::Bold)
    $script:txtLog.SelectionColor = $colTitle
    $script:txtLog.AppendText("`n________________________________`n`n")
    $script:txtLog.AppendText(" HOYO WISH COUNTER (ULTIMATE) `n")
    $script:txtLog.AppendText("________________________________`n`n")

    # --- VERSION ---
    $script:txtLog.SelectionFont = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
    $script:txtLog.SelectionColor = $colSub
    $script:txtLog.AppendText("UI v$script:AppVersion  |  Engine v$script:EngineVersion`n`n`n")

    # --- DEVELOPER ---
    $script:txtLog.SelectionFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
    $script:txtLog.SelectionColor = "WhiteSmoke"
    $script:txtLog.AppendText("Created & Designed by`n")

    $script:txtLog.SelectionFont = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold)
    $script:txtLog.SelectionColor = $colGold
    $script:txtLog.AppendText(" PHUNYAWEE `n`n") 

    # --- QUOTE ---
    $script:txtLog.SelectionFont = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Italic)
    $script:txtLog.SelectionColor = $colQuote
    $script:txtLog.AppendText("`"May all your pulls be gold...`nand your 50/50s never lost.`"`n`n`n")

    # --- FOOTER ---
    $script:txtLog.SelectionFont = New-Object System.Drawing.Font("Consolas", 8, [System.Drawing.FontStyle]::Regular)
    $script:txtLog.SelectionColor = $colFooter
    $script:txtLog.AppendText("Powered by PowerShell & .NET WinForms`n")
    $script:txtLog.AppendText("Data Source: Official Game Cache API`n")
    
    # คืนค่า Alignment
    $script:txtLog.SelectionAlignment = "Left"
    $script:txtLog.SelectionStart = 0 
})