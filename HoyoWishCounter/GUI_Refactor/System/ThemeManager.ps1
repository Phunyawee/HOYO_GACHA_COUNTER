function Apply-Theme {
    param($NewHex, $NewOpacity)
    
    # อัปเดตตัวแปร
    # เรียกใช้ฟังก์ชันจาก UIHelpers.ps1
    $NewColorObj = Get-ColorFromHex $NewHex
    
    # อัปเดตค่าใน Object Theme หลัก
    if ($script:Theme) {
        $script:Theme.Accent = $NewColorObj
    }

    # ปรับ Opacity ของฟอร์มหลัก
    if ($script:form) {
        $script:form.Opacity = $NewOpacity
    }
    
    # --- เลือกเปลี่ยนเฉพาะจุดที่เป็น Accent ---
    # ใช้ $script: นำหน้าเพื่อให้แน่ใจว่าอ้างถึงตัวแปร UI ที่สร้างใน App.ps1
    
    # 1. Textbox Input
    if ($script:txtPath) { $script:txtPath.ForeColor = $NewColorObj }
    
    # 2. Checkbox ที่สำคัญ
    if ($script:chkFilterEnable) { $script:chkFilterEnable.ForeColor = $NewColorObj }
    
    # 3. กลุ่ม Menu Expand
    if ($script:menuExpand) { $script:menuExpand.ForeColor = $NewColorObj }
}