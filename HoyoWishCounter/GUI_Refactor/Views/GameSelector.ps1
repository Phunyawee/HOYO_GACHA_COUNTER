# views/GameSelector.ps1

# --- ROW 1: GAME BUTTONS (Y=40) ---
# ปุ่ม Genshin
$btnGenshin = New-Object System.Windows.Forms.Button
$btnGenshin.Text = "Genshin"
$btnGenshin.Location = New-Object System.Drawing.Point(20, 40)
$btnGenshin.Size = New-Object System.Drawing.Size(170, 45)
$btnGenshin.FlatStyle = "Flat"
$btnGenshin.BackColor = "Gold"
$btnGenshin.ForeColor = "Black"
$btnGenshin.FlatAppearance.BorderSize = 0
# ต้องมั่นใจว่า $script:fontHeader ถูกประกาศใน App.ps1 ก่อนเรียกไฟล์นี้นะ
$btnGenshin.Font = $script:fontHeader  
$form.Controls.Add($btnGenshin)

# ปุ่ม Star Rail
$btnHSR = New-Object System.Windows.Forms.Button
$btnHSR.Text = "Star Rail"
$btnHSR.Location = New-Object System.Drawing.Point(210, 40)
$btnHSR.Size = New-Object System.Drawing.Size(170, 45)
$btnHSR.FlatStyle = "Flat"
$btnHSR.BackColor = "Gray"
$btnHSR.FlatAppearance.BorderSize = 0
$btnHSR.Font = $script:fontHeader      
$form.Controls.Add($btnHSR)

# ปุ่ม ZZZ
$btnZZZ = New-Object System.Windows.Forms.Button
$btnZZZ.Text = "ZZZ"
$btnZZZ.Location = New-Object System.Drawing.Point(400, 40)
$btnZZZ.Size = New-Object System.Drawing.Size(170, 45)
$btnZZZ.FlatStyle = "Flat"
$btnZZZ.BackColor = "Gray"
$btnZZZ.FlatAppearance.BorderSize = 0
$btnZZZ.Font = $script:fontHeader      
$form.Controls.Add($btnZZZ)


# ============================
#  EVENTS
# ============================

# 1. Switch Game
# 1. Switch Game: Genshin
$btnGenshin.Add_Click({ 
    $btnGenshin.BackColor="Gold"; $btnGenshin.ForeColor="Black"
    $btnHSR.BackColor="Gray"; $btnZZZ.BackColor="Gray"
    $script:CurrentGame = "Genshin"
    
    WriteGUI-Log "Switched to Genshin Impact" "Cyan"
    Update-BannerList
    
    # [ADD THIS] โหลดข้อมูลทันที
    Load-LocalHistory -GameName "Genshin"
})

# 2. Switch Game: HSR
$btnHSR.Add_Click({ 
    $btnHSR.BackColor="MediumPurple"; $btnHSR.ForeColor="White"
    $btnGenshin.BackColor="Gray"; $btnZZZ.BackColor="Gray"
    $script:CurrentGame = "HSR"
    
    WriteGUI-Log "Switched to Honkai: Star Rail" "Cyan"
    Update-BannerList
    
    # [ADD THIS] โหลดข้อมูลทันที
    Load-LocalHistory -GameName "HSR"
})

# 3. Switch Game: ZZZ
$btnZZZ.Add_Click({ 
    $btnZZZ.BackColor="OrangeRed"; $btnZZZ.ForeColor="White"
    $btnGenshin.BackColor="Gray"; $btnHSR.BackColor="Gray"
    $script:CurrentGame = "ZZZ"
    
    WriteGUI-Log "Switched to Zenless Zone Zero" "Cyan"
    Update-BannerList
    
    # [ADD THIS] โหลดข้อมูลทันที
    Load-LocalHistory -GameName "ZZZ"
})




# 3. [สำคัญมาก] ยัดค่าลงตัวแปรระบบตรงๆ เลย (ไม่ต้องรอ Click)
$script:CurrentGame = $targetGame

# 4. สั่งอัปเดตหน้าตา UI (เปลี่ยนสีปุ่ม) ให้ตรงกับค่าที่ยัดไป
switch ($targetGame) {
    "HSR" { 
        # เปลี่ยนสีปุ่ม HSR
        $btnHSR.BackColor="MediumPurple"; $btnHSR.ForeColor="White"
        $btnGenshin.BackColor="Gray"; $btnZZZ.BackColor="Gray"
    }
    "ZZZ" { 
        # เปลี่ยนสีปุ่ม ZZZ
        $btnZZZ.BackColor="OrangeRed"; $btnZZZ.ForeColor="White"
        $btnGenshin.BackColor="Gray"; $btnHSR.BackColor="Gray"
    }
    Default { 
        # เปลี่ยนสีปุ่ม Genshin
        $btnGenshin.BackColor="Gold"; $btnGenshin.ForeColor="Black"
        $btnHSR.BackColor="Gray"; $btnZZZ.BackColor="Gray"
        $script:CurrentGame = "Genshin" # กันเหนียว
    }
}
