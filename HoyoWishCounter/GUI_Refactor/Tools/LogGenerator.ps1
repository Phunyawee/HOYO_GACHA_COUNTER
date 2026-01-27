# ==============================================================================
# GUI LOG GENERATOR (FRONTEND)
# ==============================================================================

function WriteGUI-Log($msg, $color="Lime") { 
    try {
        # --- 1. ส่วนแสดงผลใน Debug Console (PowerShell Window) ---
        if ($script:DebugMode) {
            $consoleColor = "White"
            switch ($color) {
                "Lime"      { $consoleColor = "Green" }
                "Gold"      { $consoleColor = "Yellow" }
                "OrangeRed" { $consoleColor = "Red" }
                "Crimson"   { $consoleColor = "Red" }
                "DimGray"   { $consoleColor = "DarkGray" }
                "Cyan"      { $consoleColor = "Cyan" }
                "Magenta"   { $consoleColor = "Magenta" }
                "Gray"      { $consoleColor = "Gray" }
                "Yellow"    { $consoleColor = "Yellow" }
            }
            
            $timeStamp = Get-Date -Format "HH:mm:ss"
            # [NEW] เติม [App] หน้าข้อความเวลาโชว์ใน Console
            Write-Host "[$timeStamp] [App] $msg" -ForegroundColor $consoleColor
        }

        # --- 2. ส่งไปเก็บลงไฟล์ (Log ปกติ) ---
        if (Get-Command "Write-LogFile" -ErrorAction SilentlyContinue) {
            # [IMPORTANT] ส่ง Source="App" ไปบอกว่าข้อความนี้มาจาก App นะ (ไม่ใช่ System)
            Write-LogFile -Message $msg -Level "USER_ACTION" -Source "App"
        }

        # --- 3. ส่วนแสดงผลใน GUI ---
        if ($script:txtLog) {
            if (-not $script:txtLog.IsDisposed) {
                $script:txtLog.SelectionStart = $script:txtLog.Text.Length
                $script:txtLog.SelectionColor = [System.Drawing.Color]::FromName($color)
                
                # [NEW] เติม [App] หน้าข้อความเวลาโชว์ใน GUI Textbox
                $script:txtLog.AppendText("[App] $msg`n")
                
                $script:txtLog.ScrollToCaret() 
            }
        }
    }
    catch {
        # --- 4. ส่วนจัดการ Error ---
        $errorMessage = $_.Exception.Message
        
        # กรณี Error ให้ส่ง Source="AppError" หรือ "System" ก็ได้ตามสะดวก
        if (Get-Command "Write-LogFile" -ErrorAction SilentlyContinue) {
            Write-LogFile -Message "SYSTEM ERROR in Log Function: $errorMessage | Original Msg: $msg" -Level "ERROR" -Source "System"
        }
        
        Write-Host "Error in Log function: $errorMessage" -ForegroundColor Red
    }
}