# ------------------------------------------------------------------------------
# GROUP 1: FILE MENU
# ------------------------------------------------------------------------------

# ตัวแปร $menuStrip ต้องถูกสร้างไว้ก่อนหน้านี้ในไฟล์แม่ (Menubar.ps1)
$menuFile = New-Object System.Windows.Forms.ToolStripMenuItem("File")
[void]$menuStrip.Items.Add($menuFile)

    # --- ลูกของ File ---
    # เมนูย่อย Reset
    $itemClear = New-Object System.Windows.Forms.ToolStripMenuItem("Reset / Clear All")
    $itemClear.ShortcutKeys = [System.Windows.Forms.Keys]::F5
    $itemClear.Add_Click({
        # เรียกใช้ Helper บรรทัดเดียวจบ!
        if (Get-Command "Reset-LogWindow" -ErrorAction SilentlyContinue) { Reset-LogWindow }
        
        # 3. เริ่ม Write-GuiLog
        if (Get-Command "WriteGUI-Log" -ErrorAction SilentlyContinue) { 
            WriteGUI-Log ">>> User requested RESET. Clearing all data... <<<" "OrangeRed" 
        }
        
        # 4. Reset ค่าตัวแปรอื่นๆ
        # สังเกต: เรายังเรียก $script: ตัวแปรข้ามไฟล์ได้ เพราะ Dot-Sourcing
        $script:pnlPityFill.Width = 0
        $script:lblPityTitle.Text = "Current Pity Progress: 0 / 90"; $script:lblPityTitle.ForeColor = "White"; $script:pnlPityFill.BackColor = "LimeGreen"
        $script:LastFetchedData = @()
        $script:FilteredData = @()
        
        if ($btnExport) { $btnExport.Enabled = $false; $btnExport.BackColor = "DimGray" }
        if ($txtPath) { $txtPath.Text = "" }

        if ($lblStat1) { $lblStat1.Text = "Total Pulls: 0" }
        if ($script:lblStatAvg) { $script:lblStatAvg.Text = "Avg. Pity: -"; $script:lblStatAvg.ForeColor = "White" }
        if ($script:lblStatCost) { $script:lblStatCost.Text = "Est. Cost: 0" }
        if ($script:lblExtremes) { $script:lblExtremes.Text = "Max: -  Min: -"; $script:lblExtremes.ForeColor = "Silver" }
        
        # 5. Reset Filter Panel
        if ($grpFilter) { $grpFilter.Enabled = $false }
        if ($chkFilterEnable) { $chkFilterEnable.Checked = $false }
        if ($dtpStart) { $dtpStart.Value = Get-Date }
        if ($dtpEnd) { $dtpEnd.Value = Get-Date }
        
        # 6. Clear Graph & Panel
        if ($chart) { 
            $chart.Series.Clear()
            $chart.Visible = $false 
        }
        if ($lblNoData) { $lblNoData.Visible = $true }
        
        # ถ้ากราฟเปิดอยู่ ให้ยุบกลับ
        if ($script:isExpanded) {
            $form.Width = 600
            if ($menuExpand) { $menuExpand.Text = ">> Show Graph" }
            $script:isExpanded = $false
        }

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
    $itemExit.Add_Click({ $form.Close() })
    [void]$menuFile.DropDownItems.Add($itemExit)