# ==============================================================================
#  COMPONENT: HELP MENU ORCHESTRATOR
#  Parent: Menubar Orchestrator
# ==============================================================================

WriteGUI-Log "--- [Help] Initializing Help Modules ---" -ForegroundColor Cyan

# ------------------------------------------------------------------------------
# 1. สร้าง Parent Menu (Help)
# ------------------------------------------------------------------------------
$menuHelp = New-Object System.Windows.Forms.ToolStripMenuItem("Help")
$menuHelp.ForeColor = "White"
[void]$menuStrip.Items.Add($menuHelp)

# ------------------------------------------------------------------------------
# 2. กำหนดรายชื่อ Sub-Modules
# ------------------------------------------------------------------------------
$HelpComponents = @(
    "01_AboutCredits.ps1",   # F1 About
    "03_LogAnalyzer.ps1",
    "02_CheckUpdate.ps1"     # Update Checker
)

# กำหนด Path ไปยังโฟลเดอร์ลูก (02_HELP)
$HelpChildPath = Join-Path $PSScriptRoot "02_HELP"
$HelpLoadedCount = 0

# ------------------------------------------------------------------------------
# 3. เริ่ม Loop โหลด
# ------------------------------------------------------------------------------
foreach ($ItemName in $HelpComponents) {
    
    $FullPath = Join-Path $HelpChildPath $ItemName

    if (Test-Path $FullPath) {
        try {
            # --- Dot-Sourcing ---
            . $FullPath
            
            $HelpLoadedCount++
            WriteGUI-Log "    + [Help] Loaded: $ItemName" -ForegroundColor DarkGray

        } catch {
            WriteGUI-Log "    ! [Help] ERROR loading $ItemName : $_" -ForegroundColor Red
            if (Get-Command "WriteGUI-Log" -ErrorAction SilentlyContinue) {
                WriteGUI-Log "Error loading help module: $ItemName" "Red"
            }
        }
    } else {
        WriteGUI-Log "    ! [Help] MISSING: $ItemName" -ForegroundColor Yellow
    }
}

WriteGUI-Log "[Help] Assembly Complete ($HelpLoadedCount modules loaded)." -ForegroundColor Green