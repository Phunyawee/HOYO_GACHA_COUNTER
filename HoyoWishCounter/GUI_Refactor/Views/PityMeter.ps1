# views/PityMeter.ps1

# ============================================
#  --- ROW 3: PITY METER ---
# ============================================

# Title Label
$script:lblPityTitle = New-Object System.Windows.Forms.Label
$script:lblPityTitle.Text = "Current Pity Status"
$script:lblPityTitle.Location = New-Object System.Drawing.Point(20, 250) # ตำแหน่ง Y ปรับตามความเหมาะสม
$script:lblPityTitle.AutoSize = $true
$script:lblPityTitle.Font = $script:fontBold
$script:lblPityTitle.ForeColor = "Silver"
$form.Controls.Add($script:lblPityTitle)

# Meter Background (Panel สำหรับเป็นขอบ)
$pnlPityBack = New-Object System.Windows.Forms.Panel
$pnlPityBack.Location = New-Object System.Drawing.Point(20, 275) # ตำแหน่ง Y ปรับตามความเหมาะสม
$pnlPityBack.Size = New-Object System.Drawing.Size(550, 15) 
$pnlPityBack.BackColor = [System.Drawing.Color]::FromArgb(40,40,40) # สีเทาเข้ม
$pnlPityBack.BorderStyle = "None"
$form.Controls.Add($pnlPityBack)

# Meter Fill (Panel ที่จะแสดงความกว้างตาม % Pity)
$script:pnlPityFill = New-Object System.Windows.Forms.Panel
$script:pnlPityFill.Location = New-Object System.Drawing.Point(0, 0) 
$script:pnlPityFill.Size = New-Object System.Drawing.Size(0, 15) # กว้าง 0 ตอนแรก
$script:pnlPityFill.BackColor = "DodgerBlue" # สีเริ่มต้น
$pnlPityBack.Controls.Add($script:pnlPityFill)

# หมายเหตุ:
# - ตำแหน่ง Y (250, 275) อาจจะต้องปรับเล็กน้อยเมื่อรวมกับส่วนอื่นๆ แล้ว
# - ตัวแปร $script:lblPityTitle และ $script:pnlPityFill จะยังคงเป็น Global scope
#   เพราะเราใช้ $script: นำหน้า ทำให้ไฟล์อื่นสามารถเข้าถึงและแก้ไขค่าได้