function Update-InfinityDatabase {
    param(
        [array]$FreshData,       # ข้อมูลสด 6 เดือนที่เพิ่งดึงมา
        [string]$GameName        # ชื่อเกม (เพื่อแยกไฟล์)
    )

    Write-LogFile -Message "--- [AUDIT] STARTING DATABASE MERGE PROCESS ---" -Level "AUDIT_START"

    # 1. เตรียม Folder
    $RootBase = if ($script:AppRoot) { $script:AppRoot } else { (Join-Path $PSScriptRoot "..") }
    $dbDir = Join-Path $RootBase "UserData"
    if (-not (Test-Path $dbDir)) { 
        New-Item -ItemType Directory -Path $dbDir -Force | Out-Null 
        Write-LogFile -Message "Created new UserData directory." -Level "SYS_INFO"
    }

    # 2. กำหนดไฟล์เป้าหมาย
    $dbPath = Join-Path $dbDir "MasterDB_$($GameName).json"
    $existingData = @()

    # 3. โหลดข้อมูลเก่า (ถ้ามี)
    if (Test-Path $dbPath) {
        try {
            $jsonRaw = Get-Content $dbPath -Raw -Encoding UTF8
            $existingData = $jsonRaw | ConvertFrom-Json
            if ($null -eq $existingData) { $existingData = @() }
            # แปลงเป็น Array เสมอ กันเหนียว
            if ($existingData -isnot [System.Array]) { $existingData = @($existingData) }
            
            Write-LogFile -Message "Existing DB Loaded: Contains $($existingData.Count) records." -Level "DB_LOAD"
        } catch {
            Write-LogFile -Message "CRITICAL: Failed to load existing DB. Starting fresh. Error: $($_.Exception.Message)" -Level "DB_ERROR"
        }
    } else {
        Write-LogFile -Message "No existing database found. Creating new Master DB." -Level "DB_INIT"
    }

    # 4. [AUDIT CORE] ขั้นตอนการเทียบข้อมูล (Deduplication)
    # เราจะใช้ Hashtable เพื่อความเร็วในการเช็ค ID (O(1))
    $idMap = @{}
    foreach ($oldItem in $existingData) {
        $idMap[$oldItem.id] = $true
    }

    $newItemsToAdd = @()
    $duplicateCount = 0

    foreach ($newItem in $FreshData) {
        if ($idMap.ContainsKey($newItem.id)) {
            # เจอ ID ซ้ำ -> ข้าม
            $duplicateCount++
        } else {
            # ไม่เจอ -> เป็นข้อมูลใหม่จริง -> เพิ่ม
            $newItemsToAdd += $newItem
            $idMap[$newItem.id] = $true # อัปเดต Map กันซ้ำใน Loop ตัวเอง
        }
    }

    # 5. บันทึก Audit Write-GuiLogแบบยับๆ
    Write-LogFile -Message "Analysis Complete:" -Level "AUDIT_ANALYSIS"
    Write-LogFile -Message " > Input Fresh Data: $($FreshData.Count) records" -Level "AUDIT_DETAIL"
    Write-LogFile -Message " > Existing DB Data: $($existingData.Count) records" -Level "AUDIT_DETAIL"
    Write-LogFile -Message " > Duplicates Found: $duplicateCount (Ignored)" -Level "AUDIT_DETAIL"
    Write-LogFile -Message " > New Unique Items: $($newItemsToAdd.Count) (To be added)" -Level "AUDIT_DETAIL"

    # 6. ถ้ารวมร่างแล้วไม่มีอะไรใหม่ ก็ไม่ต้อง Save ให้เปลือง Write Cycle
    if ($newItemsToAdd.Count -eq 0) {
        Write-LogFile -Message "Database is already up-to-date. No write operation performed." -Level "DB_SKIP"
        Write-LogFile -Message "--- [AUDIT] PROCESS END (NO CHANGE) ---" -Level "AUDIT_END"
        
        # คืนค่าข้อมูลทั้งหมดกลับไปให้โปรแกรมแสดงผล
        return ($existingData + $newItemsToAdd) | Sort-Object { [decimal]$_.id } -Descending
    }

    # 7. รวมร่างจริง (Merge & Save)
    $finalList = $existingData + $newItemsToAdd
    
    # เรียงลำดับใหม่จาก (ใหม่ -> เก่า) ตาม ID
    $finalList = $finalList | Sort-Object { [decimal]$_.id } -Descending

    try {
        $jsonStr = $finalList | ConvertTo-Json -Depth 5 -Compress
        [System.IO.File]::WriteAllText($dbPath, $jsonStr, [System.Text.Encoding]::UTF8)
        
        Write-LogFile -Message "Database Update Successful. Total Records: $($finalList.Count)" -Level "DB_COMMIT"
        
        # [AUDIT] บันทึก ID ช่วงของข้อมูลใหม่ที่เพิ่มเข้ามา (เพื่อการ Trace)
        if ($newItemsToAdd.Count -gt 0) {
            $firstID = $newItemsToAdd[0].id
            $lastID  = $newItemsToAdd[-1].id
            Write-LogFile -Message "Added ID Range: $lastID ... $firstID" -Level "AUDIT_TRACE"
        }

    } catch {
        Write-LogFile -Message "CRITICAL: Failed to save Master DB! Error: $($_.Exception.Message)" -Level "DB_FATAL"
        [System.Windows.Forms.MessageBox]::Show("Database Save Failed! Check logs.", "Critical Error", 0, 16)
    }

    Write-LogFile -Message "--- [AUDIT] PROCESS END (SUCCESS) ---" -Level "AUDIT_END"

    return $finalList
}

function Load-LocalHistory {
    param([string]$GameName)

    # 1. Reset ค่าเก่าทิ้งก่อนเสมอ (กันข้อมูลตีกัน)
    $script:LastFetchedData = @()
    $script:FilteredData = @()
    $chart.Series.Clear()
    $script:pnlPityFill.Width = 0
    $script:lblPityTitle.Text = "No Data Loaded"
    $script:lblPityTitle.ForeColor = "Gray"
    
    # ปิดปุ่มต่างๆ ก่อน
    $grpFilter.Enabled = $false
    $btnExport.Enabled = $false
    $btnExport.BackColor = "DimGray"
    $script:itemForecast.Enabled = $false
    $script:itemTable.Enabled = $false
    
    # หา path หลักของโปรแกรมก่อน (ถ้า App.ps1 ส่งมาให้ก็ใช้ ถ้าไม่ก็ถอยหลังไป 1 ขั้น)
    $RootBase = if ($script:AppRoot) { $script:AppRoot } else { (Join-Path $PSScriptRoot "..") }

    # 2. หาไฟล์ Database จาก RootBase ที่ถูกต้อง
    $dbPath = Join-Path $RootBase "UserData\MasterDB_$($GameName).json"
    
    # [CASE 1] ไฟล์ไม่มีอยู่จริง (เพิ่งลงโปรแกรม หรือไม่เคยดึงเกมนี้)
    if (-not (Test-Path $dbPath)) {
        Log "No local history found for $GameName. Please Fetch data first." "DimGray"
        # อัปเดต Title Bar ให้รู้ว่าว่างเปล่า
        $form.Text = "Universal Hoyo Wish Counter v$script:AppVersion | No Data"
        return
    }

    # [CASE 2] ไฟล์มีอยู่จริง -> ลองอ่าน
    try {
        $jsonContent = Get-Content -Path $dbPath -Raw -Encoding UTF8
        
        # [CASE 3] ไฟล์ว่างเปล่า (0 bytes)
        if ([string]::IsNullOrWhiteSpace($jsonContent)) {
            Log "Local DB found but empty." "Orange"
            return
        }

        $loadedData = $jsonContent | ConvertFrom-Json
        
        # [CASE 4] JSON ถูกต้อง แต่ข้างในเป็น Array ว่าง []
        if ($null -eq $loadedData -or $loadedData.Count -eq 0) {
            Log "Local DB is valid but contains 0 records." "Orange"
            return
        }
        
        foreach ($row in $loadedData) {
            $row.gacha_type = "$($row.gacha_type)".Trim()
            $row.id = "$($row.id)".Trim()
            
            # (กันเหนียว) ถ้า ZZZ ชอบส่งมาเป็น int ก็จะถูกแก้ตรงนี้
        }

        # --- ถ้าผ่านมาถึงตรงนี้ แปลว่าข้อมูลสมบูรณ์ ---
        
        # บังคับเป็น Array เสมอ
        $script:LastFetchedData = @($loadedData)
        
        Log "Loaded local history for $GameName ($($script:LastFetchedData.Count) records)." "Lime"
        
        # เปิดใช้งาน UI
        $grpFilter.Enabled = $true
        $btnExport.Enabled = $true
        Apply-ButtonStyle -Button $btnExport -BaseColorName "RoyalBlue" -HoverColorName "CornflowerBlue" -CustomFont $script:fontBold
        
        $script:itemForecast.Enabled = $true
        $script:itemTable.Enabled = $true
        $script:itemJson.Enabled = $true
        
        # สั่งวาดกราฟทันที!
        Update-FilteredView
        $form.Refresh()

    } catch {
        # [CASE 5] ไฟล์พัง (Corrupted JSON)
        Log "Error loading local DB: $($_.Exception.Message)" "Red"
        Log "The file might be corrupted. Try Fetching again to repair." "Orange"
    }
}