# views/ExportPanel.ps1

# ============================================
#  ROW 7: EXPORT BUTTON
# ============================================
$btnExport = New-Object System.Windows.Forms.Button
$btnExport.Text = ">> Export History to CSV (Excel)"
$btnExport.Location = New-Object System.Drawing.Point(20, 850) 
$btnExport.Size = New-Object System.Drawing.Size(550, 35)

# (ต้องมีฟังก์ชัน Apply-ButtonStyle ใน App.ps1 แล้ว)
Apply-ButtonStyle -Button $btnExport -BaseColorName "DimGray" -HoverColorName "Gray"

$btnExport.Enabled = $false # เริ่มต้นปิดไว้ก่อน จนกว่าจะมีข้อมูล
$form.Controls.Add($btnExport)

# ============================================
#  EVENT HANDLER
# ============================================
$btnExport.Add_Click({
    Start-ExportCsv
})