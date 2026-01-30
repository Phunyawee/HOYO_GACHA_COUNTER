# ==============================================================================
#  COMPONENT: TOOLS MENU ORCHESTRATOR
#  Parent: Menubar Orchestrator
# ==============================================================================

WriteGUI-Log "--- [Tools] Initializing Tool Modules ---" -ForegroundColor Cyan

# ------------------------------------------------------------------------------
# 1. สร้าง Parent Menu (ปุ่ม Tools บนแถบเมนูหลัก)
# ------------------------------------------------------------------------------
$menuTools = New-Object System.Windows.Forms.ToolStripMenuItem("Tools")
# กำหนด Style ให้เหมือนเพื่อนๆ
$menuTools.ForeColor = "White" 
[void]$menuStrip.Items.Add($menuTools)

# ------------------------------------------------------------------------------
# 2. กำหนดรายชื่อ Sub-Modules (ลำดับใน Array = ลำดับเมนู บน->ล่าง)
#    อยากสลับอันไหนขึ้นก่อน แก้ตรงนี้ได้เลย!
# ------------------------------------------------------------------------------
$ToolComponents = @(
    "01_WishForecast.ps1",    # Wish Simulator (F8)
    "02_HistoryTable.ps1",    # Table Viewer (F9)
    "05_SavingsPlanner.ps1",  # Savings Planner (F10) -> ย้ายมาไว้ตรงกลางให้น่ากด
    "-SEPARATOR-",            # คั่นบรรทัด (Logic พิเศษ)
    "03_JsonExport.ps1",      # Export JSON
    "04_JsonImport.ps1"       # Import JSON (Ctrl+O)
)

# กำหนด Path ไปยังโฟลเดอร์ลูก (03_TOOLS)
$ToolChildPath = Join-Path $PSScriptRoot "03_TOOLS"
$ToolLoadedCount = 0

# ------------------------------------------------------------------------------
# 3. เริ่ม Loop โหลด (Loader Logic)
# ------------------------------------------------------------------------------
foreach ($ItemName in $ToolComponents) {
    
    # 3.1 กรณีต้องการเส้นคั่น (Separator)
    if ($ItemName -eq "-SEPARATOR-") {
        $sep = New-Object System.Windows.Forms.ToolStripSeparator
        $menuTools.DropDownItems.Add($sep) | Out-Null
        continue
    }

    # 3.2 โหลดไฟล์ปกติ
    $FullPath = Join-Path $ToolChildPath $ItemName

    if (Test-Path $FullPath) {
        try {
            # --- Dot-Sourcing (.) โหลดไฟล์เข้า Scope นี้ ---
            . $FullPath
            
            $ToolLoadedCount++
            WriteGUI-Log "    + [Tools] Loaded: $ItemName" -ForegroundColor DarkGray

        } catch {
            WriteGUI-Log "    ! [Tools] ERROR loading $ItemName : $_" -ForegroundColor Red
            # แจ้งเตือนลง Log ถ้ามีฟังก์ชัน WriteGUI-Log
            if (Get-Command "WriteGUI-Log" -ErrorAction SilentlyContinue) {
                WriteGUI-Log "Error loading tool: $ItemName" "Red"
            }
        }
    } else {
        WriteGUI-Log "    ! [Tools] MISSING: $ItemName" -ForegroundColor Yellow
    }
}

# สรุปผล
WriteGUI-Log "[Tools] Assembly Complete ($ToolLoadedCount modules loaded)." -ForegroundColor Green