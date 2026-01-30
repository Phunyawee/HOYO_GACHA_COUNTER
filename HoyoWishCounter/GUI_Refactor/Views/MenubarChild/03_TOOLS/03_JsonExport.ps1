# ---------------------------------------------------------------------------
# MODULE: 03_JsonExport.ps1
# DESCRIPTION: Export Raw Gacha Data to JSON file
# PARENT: 03_TOOLS.ps1
# ---------------------------------------------------------------------------

# 3. เมนู JSON Export
$script:itemJson = New-Object System.Windows.Forms.ToolStripMenuItem("Export Raw JSON")
$script:itemJson.ForeColor = "White"
$script:itemJson.Enabled = $false # รอ Fetch ก่อน (จะถูกเปิดโดย Logic ส่วนกลาง)

# เพิ่มลงใน Menu Tools
$menuTools.DropDownItems.Add($script:itemJson) | Out-Null

# ==========================================
#  EVENT: JSON EXPORT
# ==========================================
$script:itemJson.Add_Click({
    WriteGUI-Log "Action: Export Raw JSON" "Cyan"

    # เอาข้อมูลดิบทั้งหมด (ไม่สน Filter)
    $dataToExport = $script:LastFetchedData

    if ($null -eq $dataToExport -or $dataToExport.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("No data available. Please Fetch first.", "Error", 0, 16)
        return
    }

    $sfd = New-Object System.Windows.Forms.SaveFileDialog
    $sfd.Filter = "JSON File|*.json"
    
    # ตั้งชื่อไฟล์ Default
    $gName = if ($script:CurrentGame) { $script:CurrentGame } else { "UnknownGame" }
    $dateStr = Get-Date -Format 'yyyyMMdd_HHmm'
    $sfd.FileName = "${gName}_RawHistory_${dateStr}.json"

    if ($sfd.ShowDialog() -eq "OK") {
        try {
            # แปลงเป็น JSON และบันทึก
            # -Depth 5 เพื่อให้แน่ใจว่า Object ซ้อนกันไม่หาย
            # -Compress เพื่อให้ไฟล์เล็ก (ถ้าอยากให้อ่านง่ายให้เอาออก แต่ไฟล์จะใหญ่ขึ้น)
            $jsonStr = $dataToExport | ConvertTo-Json -Depth 5 -Compress
            
            [System.IO.File]::WriteAllText($sfd.FileName, $jsonStr, [System.Text.Encoding]::UTF8)
            
            WriteGUI-Log "Saved JSON to: $($sfd.FileName)" "Lime"
            [System.Windows.Forms.MessageBox]::Show("Export Successful!", "Success", 0, 64)
        } catch {
            WriteGUI-Log "Export Error: $($_.Exception.Message)" "Red"
            [System.Windows.Forms.MessageBox]::Show("Error saving file: $($_.Exception.Message)", "Error", 0, 16)
        }
    }
})