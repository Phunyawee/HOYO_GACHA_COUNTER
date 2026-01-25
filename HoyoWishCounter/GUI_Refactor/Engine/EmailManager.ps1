function Send-EmailReport {
    param (
        [Parameter(Mandatory=$true)] $HistoryData,
        [Parameter(Mandatory=$true)] $Config, # Config เกม (Color/Name)
        [string]$SubjectPrefix = "Gacha Report"
    )

    # =========================================================
    # 1. LOAD APP CONFIG & VERSION
    # =========================================================
    $RootPath = Split-Path $PSScriptRoot -Parent
    $JsonPath = Join-Path $RootPath "Settings\config.json"

    if (-not (Test-Path $JsonPath)) {
        Write-Host "[EmailManager] Error: Config file not found" -ForegroundColor Red
        return $false
    }

    try {
        $AppConf = Get-Content $JsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
        
        # [NEW] ดึง Version จาก Config ถ้าไม่มีให้ใช้ Default
        $CurrentVersion = if ($AppConf.AppVersion) { $AppConf.AppVersion } else { "7.0.0" }
    } catch {
        Write-Host "[EmailManager] Error reading config" -ForegroundColor Red
        return $false
    }

    # =========================================================
    # 2. VALIDATE SETTINGS
    # =========================================================
    $toEmail = $AppConf.NotificationEmail
    $senderEmail = $AppConf.SenderEmail
    $senderPass  = $AppConf.SenderPassword

    if ([string]::IsNullOrWhiteSpace($toEmail)) { return } # ไม่มีคนรับ ก็จบงาน

    if ([string]::IsNullOrWhiteSpace($senderEmail) -or [string]::IsNullOrWhiteSpace($senderPass)) {
        if (Get-Command "WriteGUI-Log" -ErrorAction SilentlyContinue) {
            WriteGUI-Log "Email Error: Sender Config Missing" "Red"
        }
        return $false
    }

    $smtpServer = if ($AppConf.SmtpServer) { $AppConf.SmtpServer } else { "smtp.gmail.com" }
    $smtpPort   = if ($AppConf.SmtpPort)   { $AppConf.SmtpPort }   else { 587 }

    # =========================================================
    # 3. GENERATE HTML (PREMIUM GACHA STYLE)
    # =========================================================
    
    # ใช้สีจาก Config เกม หรือ Default เป็นสีม่วงถ้าไม่มี
    $ThemeColor = if ($Config.AccentColor) { $Config.AccentColor } else { "#A370F0" }
    $GameTitle  = if ($script:CurrentGame) { $script:CurrentGame } else { "Gacha Game" }
    $DateStr    = Get-Date -Format "dd MMM yyyy, HH:mm"

    # สร้างแถวตาราง (Table Rows)
    $rows = ""
    foreach ($item in $HistoryData) {
        # เช็ค Pity เพื่อเปลี่ยนสี Badge (ถ้าสูงให้แดง ถ้าต่ำให้เขียว)
        $pityVal = [int]$item.Pity
        $pityColor = if ($pityVal -ge 75) { "#ff4d4d" } elseif ($pityVal -lt 20) { "#00e676" } else { "#ffb74d" }

        # เช็คความแรร์ (สมมติถ้าชื่อมีคำว่า 5-Star หรือดูจาก Logic อื่น ในที่นี้เน้นใส่ class)
        # แต่เพื่อความง่าย ผมใส่ Style ให้คอลัมน์ชื่อดูเด่นขึ้น
        
        $rows += "
        <tr>
            <td style='color:#888; font-size:12px;'>$($item.Time)</td>
            <td style='font-weight:600; color:#fff; font-size:14px;'>
                <span style='text-shadow: 0 0 10px $($ThemeColor)40;'>$($item.Name)</span>
            </td>
            <td>
                <span style='background-color: $($pityColor)20; color:$pityColor; padding: 2px 8px; border-radius: 12px; font-weight:bold; font-size:12px; border:1px solid $($pityColor)40;'>
                    $($item.Pity)
                </span>
            </td>
            <td style='color:#ccc; font-size:13px;'>$($item.Banner)</td>
        </tr>"
    }

    $htmlBody = @"
    <!DOCTYPE html>
    <html>
    <head>
    <style>
        body { background-color: #121212; font-family: 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; margin: 0; padding: 20px; color: #e0e0e0; }
        .main-card {
            max-width: 650px; margin: 0 auto; background-color: #1e1e1e; 
            border-radius: 12px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.5);
            border: 1px solid #333;
        }
        .header {
            background: linear-gradient(135deg, $ThemeColor 0%, #1a1a1a 100%);
            padding: 30px 20px; text-align: center; position: relative;
        }
        .header h1 { margin: 0; color: #fff; font-size: 24px; text-transform: uppercase; letter-spacing: 2px; text-shadow: 0 2px 4px rgba(0,0,0,0.3); }
        .header p { margin: 5px 0 0; color: rgba(255,255,255,0.7); font-size: 14px; }
        
        .stats-grid {
            display: flex; justify-content: space-around; background-color: #252525;
            padding: 15px; border-bottom: 1px solid #333;
        }
        .stat-item { text-align: center; }
        .stat-val { display: block; font-size: 18px; font-weight: bold; color: #fff; }
        .stat-label { font-size: 11px; color: #888; text-transform: uppercase; letter-spacing: 1px; }

        .content { padding: 20px; }
        table { width: 100%; border-collapse: separate; border-spacing: 0 8px; }
        th { text-align: left; color: #666; font-size: 11px; text-transform: uppercase; padding: 0 10px; letter-spacing: 1px; }
        td { background-color: #2a2a2a; padding: 12px 10px; border-top: 1px solid #333; border-bottom: 1px solid #333; }
        td:first-child { border-top-left-radius: 6px; border-bottom-left-radius: 6px; border-left: 1px solid #333; }
        td:last-child { border-top-right-radius: 6px; border-bottom-right-radius: 6px; border-right: 1px solid #333; }
        
        .footer {
            background-color: #181818; padding: 15px; text-align: center;
            font-size: 11px; color: #555; border-top: 1px solid #333;
        }
        .version-badge {
            background-color: #333; color: #888; padding: 2px 6px; border-radius: 4px; margin-left: 5px;
        }
    </style>
    </head>
    <body>
        <div class="main-card">
            <div class="header">
                <h1>$GameTitle</h1>
                <p>New Items Acquired</p>
            </div>
            
            <div class="stats-grid">
                <div class="stat-item">
                    <span class="stat-val">$($HistoryData.Count)</span>
                    <span class="stat-label">Total Items</span>
                </div>
                <div class="stat-item">
                    <span class="stat-val">$DateStr</span>
                    <span class="stat-label">Sync Time</span>
                </div>
            </div>

            <div class="content">
                <table cellspacing="0" cellpadding="0">
                    <tr>
                        <th width="20%">Time</th>
                        <th width="40%">Item Name</th>
                        <th width="15%">Pity</th>
                        <th width="25%">Banner</th>
                    </tr>
                    $rows
                </table>
            </div>

            <div class="footer">
                Powered by <strong>HoyoEngine</strong> <span class="version-badge">v$CurrentVersion</span>
                <br><br>
                This is an automated report. Good luck on your pulls!
            </div>
        </div>
    </body>
    </html>
"@

    # =========================================================
    # 4. SEND MAIL
    # =========================================================
    try {
        $secPass = ConvertTo-SecureString $senderPass -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential($senderEmail, $secPass)

        Send-MailMessage -From $senderEmail `
                         -To $toEmail `
                         -Subject "[$GameTitle] $SubjectPrefix ($($HistoryData.Count) Drops)" `
                         -Body $htmlBody `
                         -BodyAsHtml `
                         -SmtpServer $smtpServer `
                         -Port $smtpPort `
                         -UseSsl `
                         -Credential $cred

        if (Get-Command "WriteGUI-Log" -ErrorAction SilentlyContinue) {
            WriteGUI-Log "Email Report v$CurrentVersion Sent to $toEmail" "Lime"
        }
        return $true

    } catch {
        $errMsg = $_.Exception.Message
        if (Get-Command "WriteGUI-Log" -ErrorAction SilentlyContinue) {
            WriteGUI-Log "Email Failed: $errMsg" "Red"
        } else {
            Write-Host "Email Failed: $errMsg" -ForegroundColor Red
        }
        return $false
    }
}