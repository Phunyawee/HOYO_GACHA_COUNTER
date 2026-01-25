# ==============================================================================
#  COMPONENT: MENUBAR ORCHESTRATOR
#  Parent: ViewLoader.ps1
# ==============================================================================

Write-Host "--- [MenuBar] Initializing Menu System ---" -ForegroundColor Cyan

# ------------------------------------------------------------------------------
# 1. สร้าง Main Container (โครงสร้างหลัก)
# ------------------------------------------------------------------------------
$menuStrip = New-Object System.Windows.Forms.MenuStrip

# เช็ค Class DarkMenuRenderer (ถ้ามี)
if ($null -ne $DarkMenuRenderer) {
    $menuStrip.Renderer = New-Object System.Windows.Forms.ToolStripProfessionalRenderer((New-Object DarkMenuRenderer))
}

$menuStrip.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 48)
$menuStrip.ForeColor = "White"

# เอาแถบเมนูแปะเข้า Form หลัก
$form.Controls.Add($menuStrip)
$form.MainMenuStrip = $menuStrip

# ------------------------------------------------------------------------------
# 2. กำหนดรายชื่อ Component (ลำดับใน Array = ลำดับปุ่ม ซ้าย->ขวา)
# ------------------------------------------------------------------------------
$MenuComponents = @(
    "01_Menu_File.ps1",     # File (ซ้ายสุด)
    "03_TOOLS.ps1",         # Tools (แทรกกลาง ตาม code เก่านาย)
    "02_HELP.ps1",          # Help
    "04_SPECIAL.ps1"        # Special Button (ขวาสุด)
)

$MenuChildPath = Join-Path $PSScriptRoot "MenubarChild"
$MenuLoadedCount = 0
$MenuTotalCount = $MenuComponents.Count

# ------------------------------------------------------------------------------
# 3. เริ่ม Loop โหลด (Loader Logic)
# ------------------------------------------------------------------------------
foreach ($ItemName in $MenuComponents) {
    $FullPath = Join-Path $MenuChildPath $ItemName

    if (Test-Path $FullPath) {
        try {
            # --- Dot-Sourcing (.) โหลดไฟล์เข้า Scope นี้ ---
            . $FullPath
            
            $MenuLoadedCount++
            if (Get-Command "Write-LogFile" -ErrorAction SilentlyContinue) {
                Write-LogFile -Message "[UI] Loaded component: $ItemName" -Level "INFO"
            }

        } catch {
            Write-Host "  ! [MenuBar] ERROR loading $ItemName : $_" -ForegroundColor Red
            if (Get-Command "Write-LogFile" -ErrorAction SilentlyContinue) {
                Write-LogFile -Message "[MenuBar] Failed to load $ItemName : $_" -Level "ERROR"
            }
        }
    } else {
        Write-Host "  ! [MenuBar] MISSING: $ItemName" -ForegroundColor Yellow
    }
}

# สรุปผลการโหลด Menu
Write-Host "[MenuBar] Assembly Complete ($MenuLoadedCount / $MenuTotalCount components)." -ForegroundColor Green
Write-LogFile -Message "[MenuBar] View Assembly Complete. All components loaded ($MenuLoadedCount/$MenuTotalCount)." -Level "INFO"

# ------------------------------------------------------------------------------
# 4. Styling Loop (Post-Process)
# ------------------------------------------------------------------------------
# ทำงานหลังจากปุ่มทุกตัวถูก Add เข้า $menuStrip แล้ว
if ($menuStrip.Items.Count -gt 0) {
    foreach ($topItem in $menuStrip.Items) {
        # Logic: ถ้าเป็นปุ่ม Expand ($menuExpand) ให้ใช้สีฟ้า, นอกนั้นสีขาว
        # (เราใช้ try/catch เผื่อตัวแปร $menuExpand ยังไม่เกิดถ้าไฟล์ 04 โหลดไม่ติด)
        try {
            if ($menuExpand -and ($topItem -eq $menuExpand)) {
                $topItem.ForeColor = $script:Theme.Accent
            } else {
                $topItem.ForeColor = "White"
            }
        } catch {
            $topItem.ForeColor = "White"
        }
        
        # บังคับลูกๆ (Dropdown Items) ให้ขาวและพื้นหลังดำ
        foreach ($subItem in $topItem.DropDownItems) {
            $subItem.ForeColor = "White"
            $subItem.BackColor = [System.Drawing.Color]::Black 
        }
    }
}