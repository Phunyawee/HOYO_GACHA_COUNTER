# ------------------------------------------------------------------------------
# GROUP 1: FILE MENU
# ------------------------------------------------------------------------------

# ตัวแปร $menuStrip ต้องถูกสร้างไว้ก่อนหน้านี้ในไฟล์แม่ (Menubar.ps1)
# $menuFile สร้างในหน้านี้ใช้ scope ปกติได้ เพราะเรา add ใส่ Parent ทันที
$menuFile = New-Object System.Windows.Forms.ToolStripMenuItem("File")
[void]$menuStrip.Items.Add($menuFile)

    # --- ลูกของ File ---
    # เมนูย่อย Reset
    $itemClear = New-Object System.Windows.Forms.ToolStripMenuItem("Reset / Clear All")
    $itemClear.ShortcutKeys = [System.Windows.Forms.Keys]::F5
    $itemClear.Add_Click({
        # เรียกใช้ Helper
        if (Get-Command "Reset-LogWindow" -ErrorAction SilentlyContinue) { Reset-LogWindow }
        
        # 3. เริ่ม Write-GuiLog
        if (Get-Command "WriteGUI-Log" -ErrorAction SilentlyContinue) { 
            WriteGUI-Log ">>> User requested RESET. Clearing all data... <<<" "OrangeRed" 
        }
        
        # 4. Reset ค่าตัวแปรอื่นๆ
        # [FIX] ใส่ $script: ให้ครบทุกตัวแปรที่เป็น UI จากหน้าหลัก
        $script:pnlPityFill.Width = 0
        $script:lblPityTitle.Text = "Current Pity Progress: 0 / 90"
        $script:lblPityTitle.ForeColor = "White"
        $script:pnlPityFill.BackColor = "LimeGreen"
        
        # Data Variables
        $script:LastFetchedData = @()
        $script:FilteredData = @()
        
        # UI Controls (เติม $script: เพื่อความปลอดภัย)
        if ($script:btnExport) { $script:btnExport.Enabled = $false; $script:btnExport.BackColor = "DimGray" }
        if ($script:txtPath) { $script:txtPath.Text = "" }

        if ($script:lblStat1) { $script:lblStat1.Text = "Total Pulls: 0" }
        if ($script:lblStatAvg) { $script:lblStatAvg.Text = "Avg. Pity: -"; $script:lblStatAvg.ForeColor = "White" }
        if ($script:lblStatCost) { $script:lblStatCost.Text = "Est. Cost: 0" }
        if ($script:lblExtremes) { $script:lblExtremes.Text = "Max: -  Min: -"; $script:lblExtremes.ForeColor = "Silver" }
        
        # 5. Reset Filter Panel
        if ($script:grpFilter) { $script:grpFilter.Enabled = $false }
        if ($script:chkFilterEnable) { $script:chkFilterEnable.Checked = $false }
        if ($script:dtpStart) { $script:dtpStart.Value = Get-Date }
        if ($script:dtpEnd) { $script:dtpEnd.Value = Get-Date }
        
        # 6. Clear Graph & Panel
        if ($script:chart) { 
            $script:chart.Series.Clear()
            $script:chart.Visible = $false 
        }
        if ($script:lblNoData) { $script:lblNoData.Visible = $true }
        
        # ถ้ากราฟเปิดอยู่ ให้ยุบกลับ
        if ($script:isExpanded) {
            $script:form.Width = 600  # [FIX] ใช้ $script:form
            if ($script:menuExpand) { $script:menuExpand.Text = ">> Show Graph" }
            $script:isExpanded = $false
        }

        # Disable Items
        if ($script:itemForecast) { $script:itemForecast.Enabled = $false }
        if ($script:itemTable) { $script:itemTable.Enabled = $false }
        if ($script:itemJson) { $script:itemJson.Enabled = $false }

        if ($script:lblLuckGrade) { $script:lblLuckGrade.Text = "Grade: -"; $script:lblLuckGrade.ForeColor = "DimGray" }

        if (Get-Command "WriteGUI-Log" -ErrorAction SilentlyContinue) { 
            WriteGUI-Log "--- System Reset Complete. Ready. ---" "Gray" 
        }
    })
    [void]$menuFile.DropDownItems.Add($itemClear)

   
    $itemSettings = New-Object System.Windows.Forms.ToolStripMenuItem("Preferences / Settings")
    $itemSettings.ShortcutKeys = "F2"
    [void]$menuFile.DropDownItems.Add($itemSettings)
    $itemSettings.Add_Click({
        if (Get-Command "Show-SettingsWindow" -ErrorAction SilentlyContinue) { Show-SettingsWindow }
    })

    # เมนูย่อย Exit
    $itemExit = New-Object System.Windows.Forms.ToolStripMenuItem("Exit")
    $itemExit.Add_Click({ $script:form.Close() }) # [FIX] ใช้ $script:form
    [void]$menuFile.DropDownItems.Add($itemExit)