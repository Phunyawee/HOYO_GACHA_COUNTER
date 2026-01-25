# ------------------------------------------------------------------------------
# GROUP 4: SPECIAL BUTTON (Toggle Expand)
# ------------------------------------------------------------------------------
# 2. [NEW] ปุ่ม Toggle Expand (ขวาสุด)
$menuExpand = New-Object System.Windows.Forms.ToolStripMenuItem(">> Show Graph")
$menuExpand.Alignment = "Right" # สั่งชิดขวา

# [FIX] Safe Color Assignment
if ($script:Theme -and $script:Theme.Accent) {
    $menuExpand.ForeColor = $script:Theme.Accent
} else {
    $menuExpand.ForeColor = "Cyan" # Fallback color
}

$menuExpand.Font = $script:fontBold
[void]$menuStrip.Items.Add($menuExpand)

# ตัวแปรสถานะ
$script:isExpanded = $false

# Event คลิกปุ่มนี้
$menuExpand.Add_Click({
    # [FIX] ใช้ $script:form ให้ชัวร์ (เผื่อไฟล์นี้ถูกเรียกใน scope ย่อย)
    $TargetForm = if ($script:form) { $script:form } else { $form }

    if ($script:isExpanded) {
        if (Get-Command WriteGUI-Log -ErrorAction SilentlyContinue) { WriteGUI-Log "Action: Collapse Graph Panel (Hide)" "DimGray" }
        
        # ยุบกลับ
        $TargetForm.Width = 600
        $menuExpand.Text = ">> Show Graph"
        $script:isExpanded = $false
    } else {
        if (Get-Command WriteGUI-Log -ErrorAction SilentlyContinue) { WriteGUI-Log "Action: Expand Graph Panel (Show)" "Cyan" }
        
        # ขยายออก
        $TargetForm.Width = 1200
        $menuExpand.Text = "<< Hide Graph"
        $script:isExpanded = $true
        
        # [FIX] เช็ค $script:pnlChart ด้วย
        if ($script:pnlChart) { $script:pnlChart.Size = New-Object System.Drawing.Size(580, 880) }

        # สั่งวาดกราฟ (ถ้ามีข้อมูล)
        # เช็ค $script:grpFilter แทน
        if ($script:grpFilter -and $script:grpFilter.Enabled) { 
            if (Get-Command Update-FilteredView -ErrorAction SilentlyContinue) { Update-FilteredView }
        }
    }
})