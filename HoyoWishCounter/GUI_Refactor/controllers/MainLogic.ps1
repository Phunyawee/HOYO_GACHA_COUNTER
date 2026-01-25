# controllers/MainLogic.ps1

function Start-MainProcess {
    Reset-LogWindow

    $conf = Get-GameConfig $script:CurrentGame
    $targetFile = $txtPath.Text

    # ==========================================
    # [NEW] VALIDATION CHECK (ดักจับ Error)
    # ==========================================
    
    # 1. เช็คว่าช่องว่างไหม? (User ลืมเลือก)
    if ([string]::IsNullOrWhiteSpace($targetFile)) {
        WriteGUI-Log "[WARNING] User attempted to fetch without selecting a file." "Orange"
        Play-Sound "error"
        [System.Windows.Forms.MessageBox]::Show("Please select a 'data_2' file first!`nOr click 'Auto Find' to detect it automatically.", "Missing File", 0, 48) # 48 = Icon ตกใจ
        return # <--- สำคัญ! สั่งหยุดตรงนี้ ไม่ทำต่อ
    }

    # 2. เช็คว่าไฟล์มีตัวตนจริงไหม? (User อาจพิมพ์มั่ว หรือไฟล์หาย)
    if (-not (Test-Path $targetFile)) {
        WriteGUI-Log "[WARNING] File not found at path: $targetFile" "OrangeRed"
        
        [System.Windows.Forms.MessageBox]::Show("The selected file does not exist!`nPlease check the path again.", "Invalid Path", 0, 16) # 16 = Icon Error
        return # <--- สำคัญ! สั่งหยุดตรงนี้
    }

    $ShowNo = $chkShowNo.Checked
    $SendDiscord = $chkSendDiscord.Checked
    
    if (-not (Test-Path $targetFile)) {
        [System.Windows.Forms.MessageBox]::Show("Please select a valid data_2 file!", "Error", 0, 16)
        return
    }

    $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
    $btnRun.Enabled = $false; $btnExport.Enabled = $false
    $btnStop.Enabled = $true
    $script:StopRequested = $false
    $script:LastFetchedData = @() # Reset Data

    # Reset UI Pity Meter
    $script:pnlPityFill.Width = 0
    $script:lblPityTitle.Text = "Fetching Data..."
    $script:lblPityTitle.ForeColor = "Cyan"

    if ($script:cmbBanner.SelectedIndex -le 0) {
        $TargetBanners = $conf.Banners 
    } else {
        $TargetBanners = @($conf.Banners[$script:cmbBanner.SelectedIndex - 1]) 
    }

    try {
        WriteGUI-Log "Extracting AuthKey..." "Yellow"
        $auth = Get-AuthLinkFromFile -FilePath $targetFile -Config $conf
        WriteGUI-Log "AuthKey Found!" "Lime"
        
        $allHistory = @()

        # --- FETCH LOOP ---
        foreach ($banner in $TargetBanners) {
            if ($script:StopRequested) { throw "STOPPED" }

            WriteGUI-Log "Fetching: $($banner.Name)..." "Magenta"

            $items = Fetch-GachaPages -Url $auth.Url -HostUrl $auth.Host -Endpoint $conf.ApiEndpoint -BannerCode $banner.Code -PageCallback { 
                param($p) 
                # Update GUI Text
                $form.Text = "Fetching $($banner.Name) - Page $p..." 
                [System.Windows.Forms.Application]::DoEvents()
                if ($script:StopRequested) { throw "STOPPED" }
            }
            
            if ($script:DebugMode) { Write-Host "" } 
            
            foreach ($item in $items) { 
                $item | Add-Member -MemberType NoteProperty -Name "_BannerName" -Value $banner.Name -Force
            }
            $allHistory += $items
            WriteGUI-Log "  > Found $($items.Count) items." "Gray"
        }
        
        # Save to memory
        WriteGUI-Log "  > Found $($allHistory.Count) items from server." "Gray"
        
        # ==========================================
        # [UPDATE] SMART MERGE SYSTEM
        # ==========================================
        WriteGUI-Log "Synchronizing with Infinity Database..." "Cyan"
        
        # เรียกใช้ฟังก์ชันที่เราเพิ่งสร้าง
        # มันจะคืนค่า "ข้อมูลทั้งหมด (เก่า+ใหม่)" กลับมา
        $mergedHistory = Update-InfinityDatabase -FreshData $allHistory -GameName $script:CurrentGame
        
        # อัปเดตตัวแปรหลักของโปรแกรม ให้ใช้ข้อมูลชุดใหญ่ (Infinity) แทนข้อมูลชุดเล็ก
        $script:LastFetchedData = $mergedHistory
        
        WriteGUI-Log "Database Synced! Total History: $($script:LastFetchedData.Count) records." "Lime"
        
         # [NEW] AUDIO LOGIC: เช็คว่าในก้อนใหม่ ($allHistory) มี 5 ดาวไหม?
        $hasGold = $false
        foreach ($item in $allHistory) {
            if ($item.rank_type -eq $conf.SRank) { $hasGold = $true; break }
        }

        if ($hasGold) {
            WriteGUI-Log "GOLDEN GLOW DETECTED!" "Gold"
            Play-Sound "legendary"  # เสียงวิ้งๆ ทองแตก
        } else {
            Play-Sound "success"    # เสียงติ๊ดธรรมดา
        }
        
        # --- CALCULATION ---
        if ($script:StopRequested) { throw "STOPPED" }
        WriteGUI-Log "`nCalculating Pity..." "Green"
        
        $sortedItems = $allHistory | Sort-Object { [decimal]$_.id }
        $pityTrackers = @{}
        foreach ($b in $conf.Banners) { $pityTrackers[$b.Code] = 0 }
        
        $highRankHistory = @()

        foreach ($item in $sortedItems) {
            $code = [string]$item.gacha_type
            if ($script:CurrentGame -eq "Genshin" -and $code -eq "400") { $code = "301" }

            if (-not $pityTrackers.ContainsKey($code)) { $pityTrackers[$code] = 0 }
            $pityTrackers[$code]++

            if ($item.rank_type -eq $conf.SRank) {
                $highRankHistory += [PSCustomObject]@{
                    Time   = $item.time
                    Name   = $item.name
                    Banner = $item._BannerName
                    Pity   = $pityTrackers[$code]
                }
                $pityTrackers[$code] = 0 
            }
        }

        # --- DISPLAY ---
        $grpFilter.Enabled = $true
        Update-FilteredView

        # --- [NEW] UPDATE PITY GAUGE UI (Dynamic Max Pity 80/90) ---
        
        # 1. คำนวณ Pity ปัจจุบัน
        $currentPity = 0
        $latestGachaType = "" 

        if ($allHistory.Count -gt 0) {
            # $allHistory[0] คือตัวใหม่ล่าสุด (เพราะตอน Fetch มันเรียง Newest มา)
            $latestGachaType = $allHistory[0].gacha_type 
            foreach ($item in $allHistory) {
                if ($item.rank_type -eq $conf.SRank) { 
                    break 
                }
                $currentPity++
            }
        }

        # 2. Logic ตรวจสอบ Max Pity (90 หรือ 80)
        $maxPity = 90
        $typeLabel = "Character"
        
        # รหัสตู้: 302=Genshin Weapon, 12=HSR LC, 3=ZZZ W-Engine, 5=ZZZ Bangboo
        if ($latestGachaType -match "^(302|12|3|5)$") {
            $maxPity = 80
            $typeLabel = "Weapon/LC"
        }

        # 3. คำนวณความยาวหลอด (เต็มหลอด 550px)
        $percent = 0
        if ($maxPity -gt 0) { $percent = $currentPity / $maxPity }
        if ($percent -gt 1) { $percent = 1 }
        
        $newWidth = [int](550 * $percent)
        
        # อัปเดต UI
        $script:pnlPityFill.Width = $newWidth
        $script:lblPityTitle.Text = "Current Pity ($typeLabel): $currentPity / $maxPity"

        # 4. Logic สีหลอด
        if ($percent -ge 0.82) { # Soft Pity zone
            $script:pnlPityFill.BackColor = "Crimson" 
            $script:lblPityTitle.ForeColor = "Red"    
        } elseif ($percent -ge 0.55) { 
            $script:pnlPityFill.BackColor = "Gold"    
            $script:lblPityTitle.ForeColor = "Gold"
        } else { 
            $script:pnlPityFill.BackColor = "DodgerBlue" 
            $script:lblPityTitle.ForeColor = "White"
        }

        # --- STATS CALCULATION ---
        $totalPulls = $allHistory.Count
        $total5Star = $highRankHistory.Count
        $avgPity = 0
        
        $lblStat1.Text = "Total Pulls: $totalPulls"

        if ($total5Star -gt 0) {
            $avgPity = "{0:N2}" -f ($totalPulls / $total5Star)
            $script:lblStatAvg.Text = "Avg. Pity: $avgPity"
            
            if ([double]$avgPity -le 55) { $script:lblStatAvg.ForeColor = "Lime" }   
            elseif ([double]$avgPity -le 73) { $script:lblStatAvg.ForeColor = "Gold" } 
            else { $script:lblStatAvg.ForeColor = "OrangeRed" }                       
        } else {
            $script:lblStatAvg.Text = "Avg. Pity: N/A"
            $script:lblStatAvg.ForeColor = "Gray"
        }

        # Cost
        $cost = $totalPulls * 160
        $currencyName = "Primos"
        if ($script:CurrentGame -eq "HSR") { $currencyName = "Jades" }
        elseif ($script:CurrentGame -eq "ZZZ") { $currencyName = "Polychromes" }
        
        $costStr = "{0:N0}" -f $cost
        $script:lblStatCost.Text = "Est. Cost: $costStr $currencyName"
        
        # === DISCORD ===
        if ($SendDiscord) {
            WriteGUI-Log "`nSending report to Discord..." "Magenta"
            $discordMsg = Send-DiscordReport -HistoryData $highRankHistory -PityTrackers $pityTrackers -Config $conf -ShowNoMode $ShowNo
            WriteGUI-Log "Discord: $discordMsg" "Lime"
        }
        
        if ($allHistory.Count -gt 0) {
            $btnExport.Enabled = $true
            Apply-ButtonStyle -Button $btnExport -BaseColorName "RoyalBlue" -HoverColorName "CornflowerBlue" -CustomFont $script:fontBold
            $script:itemForecast.Enabled = $true
            $script:itemTable.Enabled = $true
            $script:itemJson.Enabled = $true
        }

        # ==========================================
        # [ADD] AUTO BACKUP LOGIC
        # ==========================================
        if (-not $script:AppConfig.EnableAutoBackup) {
            WriteGUI-Log "Auto-Backup is disabled." "Gray"
        } 
        else {
            $bkPath = $script:AppConfig.BackupPath
            
            # 1. เช็คว่า User ตั้งค่า Path ไว้ไหม และ Path นั้นมีอยู่จริงไหม
            if (-not [string]::IsNullOrWhiteSpace($bkPath) -and (Test-Path $bkPath)) {
                
                if ($null -eq $script:LastFetchedData) {
                    Log "No data to backup." "Gray"
                    return # หรือข้ามไป
                }
                
                WriteGUI-Log "Performing Auto-Backup..." "Magenta"
                
                try {
                    # สร้างชื่อไฟล์ตามวันที่ (เช่น Genshin_Backup_20240118.json)
                    $dateStr = Get-Date -Format "yyyyMMdd_HHmm"
                    $bkFileName = "$($script:CurrentGame)_Backup_$dateStr.json"
                    $bkFull = Join-Path $bkPath $bkFileName
                    
                    # แปลงข้อมูลล่าสุดเป็น JSON แล้วบันทึก
                    $jsonStr = $script:LastFetchedData | ConvertTo-Json -Depth 5 -Compress
                    [System.IO.File]::WriteAllText($bkFull, $jsonStr, [System.Text.Encoding]::UTF8)
                    
                    WriteGUI-Log "Backup saved to: $bkFileName" "Lime"
                } catch {
                    WriteGUI-Log "Auto-Backup Failed: $($_.Exception.Message)" "Red"
                }
            }
        }
        # ==========================================

        
    } catch {
        if ($_.Exception.Message -match "STOPPED") {
             WriteGUI-Log "`n!!! PROCESS STOPPED BY USER !!!" "Red"
        } else {
             WriteGUI-Log "ERROR: $($_.Exception.Message)" "Red"
             [System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "Error", 0, 16)
        }
    } finally {
        $form.Cursor = [System.Windows.Forms.Cursors]::Default
        $btnRun.Enabled = $true
        $btnStop.Enabled = $false
        $form.Text = "Universal Hoyo Wish Counter (Final)"
        
        if ($script:LastFetchedData.Count -gt 0) { $grpFilter.Enabled = $true }
    }
}

# เพิ่มฟังก์ชันสำหรับปุ่ม Stop ด้วยเลย
function Stop-MainProcess {
    $script:StopRequested = $true
    WriteGUI-Log ">>> STOP COMMAND RECEIVED! <<<" "Red"
}




# controllers/MainLogic.ps1 (ต่อจากของเดิม)

# ==============================================================================
#  FILTER & SCOPE LOGIC
# ==============================================================================

function Start-SmartSnap {
    if ($null -eq $script:LastFetchedData) { return }
    $conf = Get-GameConfig $script:CurrentGame
    
    # อ้างอิง UI Control ผ่าน Scope Global (เพราะ Dot-Source มา)
    $targetDate = $dtpStart.Value
    
    # เรียงจาก ใหม่ -> เก่า
    $allDesc = $script:LastFetchedData | Sort-Object { [decimal]$_.id } -Descending
    $found = $false
    
    for ($i = 0; $i -lt $allDesc.Count; $i++) {
        $item = $allDesc[$i]
        $itemDate = [DateTime]$item.time
        
        # หา 5 ดาว ที่เก่ากว่าวันที่เลือก
        if ($itemDate -lt $targetDate -and $item.rank_type -eq $conf.SRank) {
            if ($i -gt 0) {
                # ตัวถัดไปคือจุดเริ่มนับ 1
                $snapItem = $allDesc[$i - 1]
                $dtpStart.Value = [DateTime]$snapItem.time
                WriteGUI-Log "Snapped Start Date to: $($snapItem.time)" "Lime"
                $found = $true
            }
            break
        }
    }
    if (-not $found) { WriteGUI-Log "Could not find a reset point in the past." "Red" }
}

# =========================================================================
#  SHARED LOGIC: คำนวณ Pity, Filter และ Sort ในที่เดียว (แก้บั๊กเรียงผิดด้วย)
# =========================================================================
function Get-FilteredScopeData {
    if ($null -eq $script:LastFetchedData) { return $null }

    # 1. กำหนด Scope วันที่
    $startDate = [DateTime]::MinValue
    $endDate   = [DateTime]::MaxValue
    if ($chkFilterEnable.Checked) {
        $startDate = $dtpStart.Value.Date
        $endDate   = $dtpEnd.Value.Date.AddDays(1).AddSeconds(-1)
    }

    $conf = Get-GameConfig $script:CurrentGame
    
    # 2. Banner Scope
    $targetBannerCode = $null
    if ($script:cmbBanner.SelectedIndex -gt 0) {
        $selIndex = $script:cmbBanner.SelectedIndex - 1
        $targetBannerCode = $conf.Banners[$selIndex].Code
    }

    # 3. Pity Calculation
    $pityTrackers = @{}
    foreach ($b in $conf.Banners) { $pityTrackers[$b.Code] = 0 }
    
    $allSorted = $script:LastFetchedData | Sort-Object { [decimal]$_.id } 
    $tempList = @()

    foreach ($item in $allSorted) {
        $code = [string]$item.gacha_type
        if ($script:CurrentGame -eq "Genshin" -and $code -eq "400") { $code = "301" }
        
        if (-not $pityTrackers.ContainsKey($code)) { $pityTrackers[$code] = 0 }
        $pityTrackers[$code]++
        
        if ($item.rank_type -eq $conf.SRank) {
            
            # --- [FIXED HERE] แก้ตรงนี้ครับ ลบ $ หน้า [DateTime] ออก ---
            $t = [DateTime]$item.time
            $isDateOk = ($t -ge $startDate -and $t -le $endDate)
            # --------------------------------------------------------

            $isBannerOk = ($null -eq $targetBannerCode) -or ($code -eq $targetBannerCode)

            if ($isDateOk -and $isBannerOk) {
                $tempList += [PSCustomObject]@{
                    Time   = $item.time
                    Name   = $item.name
                    Banner = $item._BannerName
                    Pity   = $pityTrackers[$code]
                }
            }
            $pityTrackers[$code] = 0 
        }
    }

    # 4. Sorting Logic (เหมือนเดิม)
    $finalList = @()
    if ($chkSortDesc.Checked) {
        if ($tempList.Count -gt 0) {
            for ($i = $tempList.Count - 1; $i -ge 0; $i--) {
                $finalList += $tempList[$i]
            }
        }
    } else {
        $finalList = $tempList
    }

    return @{
        Data = $finalList
        PityTrackers = $pityTrackers
        Config = $conf
    }
}
# =========================================================================
#  DISCORD FUNCTION (สั้นลงเยอะ)
# =========================================================================
function Start-DiscordScopeReport {
    WriteGUI-Log "Preparing Discord Report..." "Magenta"
    
    # เรียกใช้ฟังก์ชันกลาง
    $result = Get-FilteredScopeData
    if ($null -eq $result) { return }

    if ($result.Data.Count -gt 0) {
        # ส่งข้อมูลที่ Sort มาแล้วไปให้ Discord
        $res = Send-DiscordReport -HistoryData $result.Data -PityTrackers $result.PityTrackers -Config $result.Config -ShowNoMode $chkShowNo.Checked -SortDesc $chkSortDesc.Checked
        WriteGUI-Log "Discord Report Sent: $res" "Lime"
    } else {
        WriteGUI-Log "No 5-Star data found in selected scope." "Orange"
        [System.Windows.Forms.MessageBox]::Show("No 5-Star records found matching filter.", "Empty", 0, 48)
    }
}

# =========================================================================
#  EMAIL FUNCTION (สั้นลงเยอะ)
# =========================================================================
function Start-EmailScopeReport {
    WriteGUI-Log "Preparing Email Report..." "Cyan"

    # เรียกใช้ฟังก์ชันกลาง (ได้ข้อมูลชุดเดียวกับ Discord เป๊ะๆ 100%)
    $result = Get-FilteredScopeData
    if ($null -eq $result) { return }

    if ($result.Data.Count -gt 0) {
        # ส่งข้อมูลไปให้ Email
        Send-EmailReport -HistoryData $result.Data -Config $result.Config -ShowNoMode $chkShowNo.Checked -SortDesc $chkSortDesc.Checked
        WriteGUI-Log "Email Report Sent!..." "Green"
        [System.Windows.Forms.MessageBox]::Show("Email sent to $($script:AppConfig.NotificationEmail)", "Success", 0, 64)
    } else {
        WriteGUI-Log "No records found for Email." "Orange"
        [System.Windows.Forms.MessageBox]::Show("No records found to email.", "Empty", 0, 48)
    }
}

# controllers/MainLogic.ps1 (ส่วนท้ายสุด)

# ==============================================================================
#  EXPORT LOGIC
# ==============================================================================
function Start-ExportCsv {
    # 1. ตรวจสอบว่าจะเอาข้อมูลชุดไหน (เหมือนเดิม)
    $dataToExport = $script:LastFetchedData
    
    if ($chkFilterEnable.Checked) {
        if ($null -ne $script:FilteredData) {
            $dataToExport = $script:FilteredData
        }
    }

    if ($null -eq $dataToExport -or $dataToExport.Count -eq 0) { 
        WriteGUI-Log "[Info] No data to export." "Gray"
        return 
    }
    
    # ========================================================
    # [EDITED] ส่วนจัดการ Path และ Folder
    # ========================================================
    try {
        # 1. ถอยหลัง 1 ขั้นจาก $PSScriptRoot (ที่อยู่ใน controllers) ไปหา Root Project
        $rootPath = Split-Path -Parent $PSScriptRoot
        
        # 2. กำหนดว่าโฟลเดอร์ export ควรอยู่ตรงไหน
        $exportFolder = Join-Path $rootPath "export"

        # 3. เช็คว่ามีโฟลเดอร์นี้ยัง? ถ้ายังไม่มีให้สร้าง
        if (-not (Test-Path $exportFolder)) {
            New-Item -ItemType Directory -Path $exportFolder -Force | Out-Null
            WriteGUI-Log "Created new 'export' folder." "Gray"
        }

        # 4. ตั้งชื่อไฟล์และรวม Path ให้สมบูรณ์
        $fileName = "$($script:CurrentGame)_WishHistory_$(Get-Date -Format 'yyyyMMdd_HHmm').csv"
        $exportPath = Join-Path $exportFolder $fileName

    } catch {
        WriteGUI-Log "Error preparing path: $($_.Exception.Message)" "Red"
        return
    }
    # ========================================================

    try {
        # 5. ดึงค่าตัวคั่นจาก Config
        $sep = if ($script:AppConfig.CsvSeparator) { $script:AppConfig.CsvSeparator } else { "," }

        # 6. สั่ง Export
        $dataToExport | Select-Object time, name, item_type, rank_type, _BannerName, id | 
            Export-Csv -Path $exportPath -NoTypeInformation -Encoding UTF8 -Delimiter $sep

        WriteGUI-Log "Saved to: export\$fileName" "Lime"
        
        # แสดงผลสำเร็จ (Optional: จะเปิดโฟลเดอร์ให้เลยก็ได้นะ ถ้า User ชอบ)
        [System.Windows.Forms.MessageBox]::Show("Saved successfully to:`n$exportPath", "Export Done", 0, 64) 
    } catch {
        WriteGUI-Log "Export Failed: $_" "Red"
        [System.Windows.Forms.MessageBox]::Show("Export Failed: $_", "Error", 0, 16)
    }
}



# controllers/MainLogic.ps1

function Initialize-AppState {
    Write-Host "Applying Config to UI..." -ForegroundColor Cyan

    # ========================================================
    # LOGIC: DISCORD CHECKBOX
    # ========================================================
    
    # 1. เช็คก่อนว่ามี URL Webhook ไหม?
    $hasWebhook = -not [string]::IsNullOrWhiteSpace($script:AppConfig.WebhookUrl)

    if ($hasWebhook) {
        # A. ถ้ามี Webhook -> ให้ทำตามใจ User ว่าตั้ง AutoSend ไว้ไหม
        if ($script:AppConfig.AutoSendDiscord) {
            $chkSendDiscord.Checked = $true
            # ทริก: สั่ง false แล้ว true เพื่อกระตุ้น Event เปลี่ยนสีปุ่ม
            $chkSendDiscord.Checked = $false
            $chkSendDiscord.Checked = $true
        } else {
            $chkSendDiscord.Checked = $false
        }
        $chkSendDiscord.Enabled = $true
    } else {
        # B. ถ้าไม่มี Webhook -> บังคับปิด และห้ามกด
        $chkSendDiscord.Checked = $false
        $chkSendDiscord.Enabled = $false
        $chkSendDiscord.Text = "Discord (No Webhook)"
        $chkSendDiscord.ForeColor = "DimGray"
    }

    # ========================================================
    # LOGIC: OTHER SETTINGS
    # ========================================================
    
    # คืนค่า Path ล่าสุดของเกมนั้นๆ
    if ($script:AppConfig.Paths) {
        $lastPath = $script:AppConfig.Paths.$script:CurrentGame
        if (-not [string]::IsNullOrWhiteSpace($lastPath)) {
            $txtPath.Text = $lastPath
        }
    }
}