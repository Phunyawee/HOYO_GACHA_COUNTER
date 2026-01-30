# ---------------------------------------------------------------------------
# MODULE: 04_JsonImport.ps1
# DESCRIPTION: Import History from JSON file (Offline Viewer Mode)
# PARENT: 03_TOOLS.ps1
# ---------------------------------------------------------------------------

$script:itemImportJson = New-Object System.Windows.Forms.ToolStripMenuItem("Import History from JSON")
$script:itemImportJson.ShortcutKeys = "Ctrl+O" # คีย์ลัดเท่ๆ
$script:itemImportJson.ForeColor = "Gold"      # สีทองให้ดูเด่นว่าเป็นฟีเจอร์พิเศษ

# เพิ่มลงใน Menu Tools
$menuTools.DropDownItems.Add($script:itemImportJson) | Out-Null

# ==========================================
# EVENT: IMPORT JSON (OFFLINE VIEWER)
# ==========================================
$script:itemImportJson.Add_Click({
    WriteGUI-Log "Action: Import JSON File..." "Cyan"
    
    # 1. เลือกไฟล์
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = "JSON Files (*.json)|*.json|All Files (*.*)|*.*"
    $ofd.Title = "Select Wish History JSON"
    
    # เช็คผลลัพธ์ของการเลือกไฟล์
    if ($ofd.ShowDialog() -eq "OK") {
        # --- กรณี User เลือกไฟล์ (กด OK) ---
        try {
            $jsonContent = Get-Content -Path $ofd.FileName -Raw -Encoding UTF8
            $importedData = $jsonContent | ConvertFrom-Json
            
            if ($null -eq $importedData -or $importedData.Count -eq 0) {
                WriteGUI-Log "Error: Selected JSON is empty." "Red"
                [System.Windows.Forms.MessageBox]::Show("JSON file is empty or invalid.", "Error", 0, 48)
                return
            }

            # Update Global Data
            $script:LastFetchedData = @($importedData)
            
            # Reset & Update UI
            Reset-LogWindow

            if ($script:chart) { 
                $script:chart.Series.Clear()
                $script:chart.Visible = $false 
            }

            WriteGUI-Log "Successfully loaded: $($ofd.SafeFileName)" "Lime"
            WriteGUI-Log "Total Items: $($script:LastFetchedData.Count)" "Gray"
            
            # เปิดใช้งานปุ่มและเมนูต่างๆ
            $grpFilter.Enabled = $true
            $btnExport.Enabled = $true
            Apply-ButtonStyle -Button $btnExport -BaseColorName "RoyalBlue" -HoverColorName "CornflowerBlue" -CustomFont $script:fontBold
            
            # เปิดเมนูย่อย (ตัวแปรเหล่านี้ถูกสร้างจากไฟล์ 01, 02, 03)
            if ($script:itemForecast) { $script:itemForecast.Enabled = $true }
            if ($script:itemTable)    { $script:itemTable.Enabled = $true }
            if ($script:itemJson)     { $script:itemJson.Enabled = $true }
            
            # เปลี่ยน Title Bar
            $form.Text = "Universal Hoyo Wish Counter v$script:AppVersion [OFFLINE VIEW: $($ofd.SafeFileName)]"
            
            # Reset Pity Meter Visual
            if ($script:pnlPityFill) { $script:pnlPityFill.Width = 0 }
            if ($script:lblPityTitle) {
                $script:lblPityTitle.Text = "Mode: Offline Viewer (Pity calculation depends on Filter)"
                $script:lblPityTitle.ForeColor = "Gold"
            }
            
            # สั่งคำนวณใหม่
            Update-FilteredView
            [System.Windows.Forms.MessageBox]::Show("Data Loaded Successfully!", "Import Complete", 0, 64)

        } catch {
            WriteGUI-Log "Import Error: $($_.Exception.Message)" "Red"
            [System.Windows.Forms.MessageBox]::Show("Failed to read JSON: $($_.Exception.Message)", "Error", 0, 16)
        }
    } else {
        # --- กรณี User กด Cancel หรือปิดหน้าต่าง ---
        WriteGUI-Log "Import cancelled by user." "DimGray"
    }
})