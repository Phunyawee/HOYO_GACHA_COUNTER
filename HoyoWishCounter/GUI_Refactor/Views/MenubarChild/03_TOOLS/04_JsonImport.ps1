# ---------------------------------------------------------------------------
# MODULE: 04_JsonImport.ps1
# DESCRIPTION: Smart Import & Merge System (With Deep Validation)
# PARENT: 03_TOOLS.ps1
# ---------------------------------------------------------------------------

$script:itemImportJson = New-Object System.Windows.Forms.ToolStripMenuItem("Import History from JSON")
$script:itemImportJson.ShortcutKeys = "Ctrl+O"
$script:itemImportJson.ForeColor = "Gold"

$menuTools.DropDownItems.Add($script:itemImportJson) | Out-Null

$script:itemImportJson.Add_Click({
    WriteGUI-Log "Action: Initiating Smart Import..." "Cyan"
    
    # 1. เลือกไฟล์
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = "JSON Files (*.json)|*.json|All Files (*.*)|*.*"
    $ofd.Title = "Select Wish History JSON to Import/Merge"
    
    if ($ofd.ShowDialog() -ne "OK") { return }

    try {
        # 2. อ่านไฟล์และแปลงเป็น JSON Object
        $jsonRaw = Get-Content -Path $ofd.FileName -Raw -Encoding UTF8
        $importedData = $jsonRaw | ConvertFrom-Json
        
        if ($null -eq $importedData -or $importedData.Count -eq 0) {
            throw "The selected JSON file is empty or invalid structure."
        }
        
        if ($importedData -isnot [System.Array]) { $importedData = @($importedData) }

        # =======================================================
        # [FIXED] DEEP GAME DETECTION (แยก HSR/ZZZ ให้ออก)
        # =======================================================
        # เราจะสุ่มตรวจ 50 ตัวแรก เพื่อหา Keyword เฉพาะของแต่ละเกม
        # เพราะดูแค่ ID (gacha_type) ไม่ได้แล้ว HSR กับ ZZZ ใช้เลข 1,2 เหมือนกัน
        
        $sampleSet = $importedData | Select-Object -First 50
        $detectedGame = "Unknown"
        
        # 1. เช็ค Genshin (Gacha Type เกิน 100 หรือมี Weapon)
        $hasGenshinSign = $sampleSet | Where-Object { [int]$_.gacha_type -gt 90 -or $_.item_type -eq "Weapon" }
        if ($hasGenshinSign) { $detectedGame = "Genshin" }

        # 2. เช็ค HSR (ต้องมี Light Cone)
        # HSR จะไม่มี Gacha Type หลักร้อย และต้องมี Light Cone
        $hasHSRSign = $sampleSet | Where-Object { $_.item_type -eq "Light Cone" }
        if ($hasHSRSign) { $detectedGame = "HSR" }

        # 3. เช็ค ZZZ (ต้องมี W-Engine, Bangboo หรือ Agent)
        $hasZZZSign = $sampleSet | Where-Object { $_.item_type -match "W-Engine|Bangboo|Agent" }
        if ($hasZZZSign) { $detectedGame = "ZZZ" }

        # --- VALIDATION RESULT ---
        if ($detectedGame -ne "Unknown" -and $detectedGame -ne $script:CurrentGame) {
            
            # เล่นเสียง Error
            Play-Sound "error" 

            [System.Windows.Forms.MessageBox]::Show(
                "CRITICAL MISMATCH`n`n" +
                "You are currently in mode:  [$($script:CurrentGame)]`n" +
                "But the file belongs to:    [$detectedGame]`n`n" +
                "Import BLOCKED to prevent database corruption.`n" +
                "Please switch to the correct game tab first!", 
                "Import Rejected", 0, 16
            )
            return # <--- หยุดตรงนี้ทันที ห้ามไปต่อ!
        }
        # =======================================================

        # -----------------------------------------------------------
        # UID SECURITY GUARD (เหมือนเดิม)
        # -----------------------------------------------------------
        $importUID = "Unknown"
        if ($importedData[0].uid) { $importUID = "$($importedData[0].uid)" }

        $currentUID = "Empty"
        if ($script:LastFetchedData -and $script:LastFetchedData.Count -gt 0) {
            if ($script:LastFetchedData[0].uid) { $currentUID = "$($script:LastFetchedData[0].uid)" }
        }

        # Logic ตัดสินใจ (Mode Selection)
        $mode = "VIEW" 
        $msgTitle = "Import Options"
        $msgIcon = 32 # Question
        $msgButtons = 3 # YesNoCancel
        
        $msgBody = "File Loaded: $($ofd.SafeFileName)`n" +
                   "Detected Game: $detectedGame`n" + # โชว์ให้ User อุ่นใจว่าเรา detect ถูก
                   "Records: $($importedData.Count)`n" +
                   "UID in File: $importUID`n`n"

        if ($currentUID -ne "Empty" -and $importUID -ne "Unknown" -and $importUID -ne $currentUID) {
            $msgBody += "WARNING: UID MISMATCH!`n" +
                        "Current DB belongs to: $currentUID`n" +
                        "Import File belongs to: $importUID`n`n" +
                        "Click 'Yes' to FORCE MERGE (Risky)`n" +
                        "Click 'No' to VIEW ONLY (Safe)`n"
            $msgIcon = 48 # Warning
        } else {
            $msgBody += "Do you want to MERGE this data into your main database?`n`n" +
                        "Click 'Yes' to MERGE (Save to DB)`n" +
                        "Click 'No' to VIEW ONLY (Temporary)"
        }

        $response = [System.Windows.Forms.MessageBox]::Show($msgBody, $msgTitle, $msgButtons, $msgIcon)

        if ($response -eq "Cancel") { return }

        # -----------------------------------------------------------
        # EXECUTION PHASE
        # -----------------------------------------------------------
        if ($response -eq "Yes") {
            # MERGE MODE
            WriteGUI-Log "Merging data..." "Magenta"
            Update-InfinityDatabase -FreshData $importedData -GameName $script:CurrentGame
            Load-LocalHistory -GameName $script:CurrentGame
            [System.Windows.Forms.MessageBox]::Show("Data merged successfully!", "Complete", 0, 64)

        } else {
            # VIEW ONLY MODE
            WriteGUI-Log "View Only Mode Activated." "Cyan"
            $script:LastFetchedData = $importedData
            Reset-LogWindow
            if ($script:chart) { $script:chart.Series.Clear(); $script:chart.Visible = $false }

            WriteGUI-Log "Loaded [View Only]: $($ofd.SafeFileName)" "Lime"
            WriteGUI-Log "Total Items: $($script:LastFetchedData.Count)" "Gray"
            
            $grpFilter.Enabled = $true
            $btnExport.Enabled = $true
            Apply-ButtonStyle -Button $btnExport -BaseColorName "RoyalBlue" -HoverColorName "CornflowerBlue" -CustomFont $script:fontBold
            
            if ($script:itemForecast) { $script:itemForecast.Enabled = $true }
            if ($script:itemTable)    { $script:itemTable.Enabled = $true }
            if ($script:itemJson)     { $script:itemJson.Enabled = $true }

            $form.Text = "Universal Hoyo Wish Counter v$script:AppVersion [OFFLINE VIEW: $importUID]"
            $script:pnlPityFill.Width = 0
            $script:lblPityTitle.Text = "Mode: Offline Viewer (UID: $importUID)"
            $script:lblPityTitle.ForeColor = "Gold"
            
            Update-FilteredView
        }

    } catch {
        WriteGUI-Log "Import Error: $($_.Exception.Message)" "Red"
        [System.Windows.Forms.MessageBox]::Show("Failed to process JSON: $($_.Exception.Message)", "Error", 0, 16)
    }
})