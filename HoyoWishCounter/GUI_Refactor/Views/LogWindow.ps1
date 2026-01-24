# views/LogWindow.ps1

# ============================================
#  ROW 6: LOG WINDOW (Moved Down to Y=540)
# ============================================
$txtLog = New-Object System.Windows.Forms.RichTextBox
$txtLog.Location = New-Object System.Drawing.Point(20, 540) 
$txtLog.Size = New-Object System.Drawing.Size(550, 300)      

$txtLog.BackColor = "Black"
$txtLog.ForeColor = "Lime"
$txtLog.BorderStyle = "FixedSingle"

# ต้องมั่นใจว่าประกาศ $script:fontLog ใน App.ps1 แล้ว
$txtLog.Font = $script:fontLog 

$txtLog.ReadOnly = $true
$txtLog.ScrollBars = "Vertical"
$form.Controls.Add($txtLog)