# ==============================================================================
# ENGINE: EMAIL MANAGER (Full Chart Support + Debug Logging)
# ==============================================================================

function Generate-ChartImage {
    param($DataList, $ChartType, $Config, $OutPath)

    Add-Type -AssemblyName System.Windows.Forms.DataVisualization
    Add-Type -AssemblyName System.Drawing

    $chart = New-Object System.Windows.Forms.DataVisualization.Charting.Chart
    $chart.Width = 900  # เพิ่มความกว้างอีกนิดให้ชื่อไม่เบียด
    $chart.Height = 500
    $chart.BackColor = [System.Drawing.Color]::FromArgb(30,30,30)
    
    $area = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea "Main"
    $area.BackColor = "Transparent"
    
    # -------------------------------------------------------
    # [จุดแก้สำคัญ] ตั้งค่าแกน X ให้โชว์ชื่อครบ
    # -------------------------------------------------------
    $area.AxisX.LabelStyle.ForeColor = "Silver"
    $area.AxisX.LineColor = "#555"
    $area.AxisX.MajorGrid.LineColor = "#333"
    
    # 1. บังคับโชว์ทุกขีด (ไม่ให้ข้ามชื่อ)
    $area.AxisX.Interval = 1 
    
    # 2. ถ้าชื่อยาว ให้เอียงตัวหนังสือ -45 องศา จะได้ไม่ทับกัน
    $area.AxisX.LabelStyle.Angle = -45 
    
    # 3. กันไม่ให้ตัดคำท้ายๆ ทิ้ง
    $area.AxisX.LabelStyle.IsEndLabelVisible = $true
    
    $area.AxisY.LabelStyle.ForeColor = "Silver"
    $area.AxisY.LineColor = "#555"
    $area.AxisY.MajorGrid.LineColor = "#333"
    
    $chart.ChartAreas.Add($area)

    $series = New-Object System.Windows.Forms.DataVisualization.Charting.Series "Data"
    $series.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)

    # =========================================================
    # TYPE A: RATE ANALYSIS (Doughnut)
    # =========================================================
    if ($ChartType -eq "Rate Analysis") {
        $area.AxisX.Enabled = "False"; $area.AxisY.Enabled = "False"
        
        $sRank = if ($Config.SRank) { $Config.SRank } else { "5" }
        $count5 = ($DataList | Where-Object { $_.rank_type -eq $sRank }).Count
        $count4 = ($DataList | Where-Object { $_.rank_type -eq "4" }).Count
        $count3 = $DataList.Count - $count5 - $count4

        $series.ChartType = "Doughnut"
        $series["DoughnutRadius"] = "60"
        $series["PieLabelStyle"] = "Outside"
        $series["PieLineColor"] = "Silver"
        $series.LabelForeColor = "White"

        if ($count5 -gt 0) {
            $p = $series.Points.Add($count5); $series.Points[$p].Color = "Gold"
            $series.Points[$p].LegendText = "5-Star"; $series.Points[$p].Label = "#VALY (#PERCENT{P1})"
            $series.Points[$p].LabelForeColor = "Gold"
        }
        if ($count4 -gt 0) {
            $p = $series.Points.Add($count4); $series.Points[$p].Color = "MediumPurple"
            $series.Points[$p].LegendText = "4-Star"; $series.Points[$p].Label = "#VALY (#PERCENT{P1})"
            $series.Points[$p].LabelForeColor = "MediumPurple"
        }
        if ($count3 -gt 0) {
            $p = $series.Points.Add($count3); $series.Points[$p].Color = "DodgerBlue"
            $series.Points[$p].LegendText = "3-Star"; $series.Points[$p].Label = "" 
        }

    } else {
        # =========================================================
        # TYPE B: HISTORY (Bar/Line)
        # =========================================================
        $series.ChartType = $ChartType 
        $series.IsValueShownAsLabel = $true
        $series.LabelForeColor = "White"
        
        if ($ChartType -match "Line|Spline") {
            $series.BorderWidth = 3; $series.Color = "White"; $series.MarkerStyle = "Circle"; $series.MarkerSize = 8
        } else {
            $series["PixelPointWidth"] = "30"
        }

        # Sort ตามเวลา: เก่า -> ใหม่
        $DisplayData = $DataList | Sort-Object Time | Select-Object -Last 15
        
        foreach ($item in $DisplayData) {
            # สร้าง Label
            $labelName = "$($item.Name)"
            
            # AddXY: แกน X เป็น String, แกน Y เป็นตัวเลข
            $ptIdx = $series.Points.AddXY($labelName, $item.Pity)
            $pt = $series.Points[$ptIdx]
            
            # [Fix เพิ่มเติม] บังคับใส่ AxisLabel อีกรอบเพื่อความชัวร์
            $pt.AxisLabel = $labelName
            
            # สี Pity
            $col = "LimeGreen"
            if ($item.Pity -ge 75) { $col = "Crimson" } elseif ($item.Pity -ge 50) { $col = "Gold" }
            
            if ($ChartType -match "Bar|Column") { $pt.Color = $col } else { $pt.MarkerColor = $col }
        }
    }
    
    $chart.Series.Add($series)

    # ปรับ Legend ให้สวยงาม
    $leg = New-Object System.Windows.Forms.DataVisualization.Charting.Legend
    $leg.Docking = "Bottom"; $leg.BackColor = "Transparent"; $leg.ForeColor = "Silver"
    $chart.Legends.Add($leg)

    # Title
    $title = New-Object System.Windows.Forms.DataVisualization.Charting.Title
    $title.Text = "$ChartType Report"
    $title.ForeColor = "White"
    $title.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
    $chart.Titles.Add($title)

    # Save
    $chart.SaveImage($OutPath, "Png")
    $chart.Dispose()
}


function Send-EmailReport {
    param (
        [Parameter(Mandatory=$true)] $HistoryData,
        [Parameter(Mandatory=$true)] $Config,
        [bool]$ShowNoMode,
        [bool]$SortDesc 
    )

    # 1. LOAD CONFIGS
    $RootPath = Split-Path $PSScriptRoot -Parent
    $MainConfPath = Join-Path $RootPath "Settings\config.json"
    $EmailConfPath = Join-Path $RootPath "Settings\EmailForm.json"

    # [DEBUG LOG]
    Write-Host "[EmailMgr] Root Path: $RootPath" -ForegroundColor DarkGray
    Write-Host "[EmailMgr] Loading EmailForm.json from: $EmailConfPath" -ForegroundColor DarkGray

    if (-not (Test-Path $MainConfPath)) { Write-Host "Config not found!" -ForegroundColor Red; return $false }
    $AppConf = Get-Content $MainConfPath -Raw -Encoding UTF8 | ConvertFrom-Json
    
    # Defaults
    $SelectedStyle = "Premium Card"; $ContentType = "Table List"; $ChartType = "Rate Analysis"; $SubjectPrefix = "Gacha Report"
    
    if (Test-Path $EmailConfPath) {
        try {
            $ES = Get-Content $EmailConfPath -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($ES.Style) { $SelectedStyle = $ES.Style }
            if ($ES.ContentType) { $ContentType = $ES.ContentType }
            if ($ES.ChartType) { $ChartType = $ES.ChartType }
            if ($ES.SubjectPrefix) { $SubjectPrefix = $ES.SubjectPrefix }
            
            # [DEBUG LOG] ยืนยันว่าอ่านค่าได้จริง
            Write-Host "[EmailMgr] Config Loaded -> Style: $SelectedStyle | Mode: $ContentType | Chart: $ChartType" -ForegroundColor Yellow
        } catch {
            Write-Host "[EmailMgr] Error reading EmailForm.json" -ForegroundColor Red
        }
    } else {
        Write-Host "[EmailMgr] EmailForm.json not found. Using Defaults." -ForegroundColor Yellow
    }

    $RawGameName = if ($script:CurrentGame) { $script:CurrentGame } else { "Gacha" }
    
    switch ($RawGameName) {
        "Genshin" { $GameTitle = "Genshin Impact" }
        "HSR"     { $GameTitle = "Honkai: Star Rail" }
        "ZZZ"     { $GameTitle = "Zenless Zone Zero" }
        "WuWa"    { $GameTitle = "Wuthering Waves" }
        Default   { $GameTitle = $RawGameName } # ถ้าไม่ตรงเงื่อนไข ให้ใช้ชื่อเดิม
    }

    # Creds Check
    $toEmail = $AppConf.NotificationEmail; $senderEmail = $AppConf.SenderEmail; $senderPass = $AppConf.SenderPassword
    if ([string]::IsNullOrWhiteSpace($toEmail) -or [string]::IsNullOrWhiteSpace($senderEmail)) { return $false }
    $smtpServer = if ($AppConf.SmtpServer) { $AppConf.SmtpServer } else { "smtp.gmail.com" }
    $smtpPort = if ($AppConf.SmtpPort) { $AppConf.SmtpPort } else { 587 }

    # 2. PREPARE CONTENT
    $ThemeColor = if ($Config.AccentColor) { $Config.AccentColor } else { "#A370F0" }
    #$GameTitle = if ($script:CurrentGame) { $script:CurrentGame } else { "Gacha Game" }
    $Attachments = @()

    if ($ContentType -eq "Chart Snapshot") {
        # --- GRAPH MODE ---
        $TempImage = Join-Path $env:TEMP "Hoyo_Chart.png"
        Generate-ChartImage -DataList $HistoryData -ChartType $ChartType -Config $Config -OutPath $TempImage
        
        if (Test-Path $TempImage) {
            $Attachments += $TempImage
            $BodyContent = "<div style='text-align:center;'><img src='cid:Hoyo_Chart.png' style='max-width:100%;border-radius:8px;border:1px solid #444;'></div>"
        } else {
            $BodyContent = "<p style='color:red;'>Error generating chart.</p>"
        }
    } else {
        # --- TABLE MODE ---
        $rows = ""
        $HeadCol1 = if ($ShowNoMode) { "Index [No.]" } else { "Time" }

        # [สำคัญ] เก็บจำนวนทั้งหมดไว้คำนวณ
        $TotalCount = $HistoryData.Count
        $LoopIndex = 0 # ตัวนับรอบ loop (เริ่มที่ 0)

        foreach ($item in ($HistoryData | Select-Object -First 20)) {
             $pityVal = [int]$item.Pity
             $col = if ($pityVal -ge 75) { "#ff4d4d" } elseif ($pityVal -lt 20) { "#00e676" } else { "#ffb74d" }
             
             # [สูตรคำนวณเลข No.]
             if ($ShowNoMode) {
                if ($SortDesc) {
                    # กรณีเรียง ใหม่ -> เก่า (เช่น มี 50 ตัว: ตัวแรกโชว์ 50, ตัวถัดไป 49...)
                    $RealNumber = $TotalCount - $LoopIndex
                } else {
                    # กรณีเรียง เก่า -> ใหม่ (ตัวแรกโชว์ 1, ตัวถัดไป 2...)
                    $RealNumber = $LoopIndex + 1
                }
                $displayCol1 = "No. $RealNumber"
             } else {
                $displayCol1 = $item.Time
             }

             # Table Row Styling
             if ($SelectedStyle -eq "Classic Table") {
                $rows += "<tr><td style='padding:5px;border:1px solid #ccc;'>$displayCol1</td><td style='padding:5px;border:1px solid #ccc;'>$($item.Name)</td><td style='padding:5px;border:1px solid #ccc;color:$col;'>$($item.Pity)</td></tr>"
             } elseif ($SelectedStyle -eq "Terminal Mode") {
                $rows += "<tr><td style='padding:5px;border-bottom:1px dashed #0f0;'>$displayCol1</td><td style='padding:5px;border-bottom:1px dashed #0f0;'>$($item.Name)</td><td style='padding:5px;border-bottom:1px dashed #0f0;'>$($item.Pity)</td></tr>"
             } else {
                # Premium
                $rows += "<tr><td style='color:#aaa;padding:8px;border-bottom:1px solid #333;'>$displayCol1</td><td style='color:#eee;font-weight:bold;padding:8px;border-bottom:1px solid #333;'>$($item.Name)</td><td style='padding:8px;border-bottom:1px solid #333;'><span style='color:$col;'>$($item.Pity)</span></td></tr>"
             }
             
             $LoopIndex++ # บวกตัวนับรอบ
        }

        # Table Wrapper Styling
        if ($SelectedStyle -eq "Classic Table") {
            $BodyContent = "<table width='100%' style='border-collapse:collapse;color:black;'><tr><th style='text-align:left;background:#eee;padding:5px;'>Time</th><th style='text-align:left;background:#eee;padding:5px;'>Item</th><th style='text-align:left;background:#eee;padding:5px;'>Pity</th></tr>$rows</table>"
        } elseif ($SelectedStyle -eq "Terminal Mode") {
            $BodyContent = "<table width='100%' style='border-collapse:collapse;color:#0f0;font-family:Consolas;'><tr><th style='text-align:left;border-bottom:1px double #0f0;'>TIME</th><th style='text-align:left;border-bottom:1px double #0f0;'>ITEM</th><th style='text-align:left;border-bottom:1px double #0f0;'>PITY</th></tr>$rows</table>"
        } else {
            $BodyContent = "<table width='100%' cellspacing='0'><tr><th style='text-align:left;color:#666;'>Time</th><th style='text-align:left;color:#666;'>Item</th><th style='text-align:left;color:#666;'>Pity</th></tr>$rows</table>"
        }
    }

    # 3. FINAL HTML WRAPPER (Theme Based)
    $Meta = "<meta charset='utf-8'>"
    switch ($SelectedStyle) {
        "Classic Table" {
            $htmlBody = "<html><head>$Meta<style>body{background:white;color:black;font-family:sans-serif;}</style></head><body><h3>$GameTitle - $SubjectPrefix</h3><hr>$BodyContent</body></html>"
        }
        "Terminal Mode" {
             # [แก้ไข] ย้าย background-color:black มาใส่ใน style ของ <body> โดยตรง
             $htmlBody = "<html><head>$Meta</head><body style='background-color:black; color:#0f0; font-family:Consolas,monospace; padding:20px;'><div>> TARGET: $GameTitle</div><div>> SUBJECT: $SubjectPrefix</div><div style='border:1px dashed #0f0;margin:10px 0;'></div>$BodyContent<br><div>> END_LOG</div></body></html>"
        }
        Default {
            # Premium Card
            $htmlBody = @"
<!DOCTYPE html><html><head>$Meta<style>body{background:#121212;color:#eee;font-family:'Segoe UI';} .card{max-width:600px;margin:0 auto;background:#1e1e1e;border-radius:12px;overflow:hidden;border:1px solid #333;} .head{background:linear-gradient(135deg,$ThemeColor 0%,#111 100%);padding:20px;text-align:center;} h2{margin:0;color:white;} .cont{padding:20px;}</style></head><body>
<div class='card'><div class='head'><h2>$GameTitle</h2><p>$SubjectPrefix</p></div><div class='cont'>$BodyContent</div></div></body></html>
"@
        }
    }

    # 4. SEND MAIL
    try {
        $secPass = ConvertTo-SecureString $senderPass -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential($senderEmail, $secPass)
        
        $params = @{
            From = $senderEmail; To = $toEmail; Subject = "[$GameTitle] $SubjectPrefix"; Body = $htmlBody; BodyAsHtml = $true
            SmtpServer = $smtpServer; Port = $smtpPort; UseSsl = $true; Credential = $cred; Encoding = [System.Text.Encoding]::UTF8
        }
        if ($Attachments.Count -gt 0) { $params.Attachments = $Attachments }

        Send-MailMessage @params
        Write-Host "Email Sent Successfully ($ContentType - $ChartType)" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "Email Failed: $_" -ForegroundColor Red
        return $false
    } finally {
        if ($TempImage -and (Test-Path $TempImage)) { Remove-Item $TempImage -Force -ErrorAction SilentlyContinue }
    }
}