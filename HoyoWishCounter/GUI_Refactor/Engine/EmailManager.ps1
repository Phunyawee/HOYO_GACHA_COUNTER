# ==============================================================================
# ENGINE: EMAIL MANAGER (Fixed Backgrounds & Encoding)
# ==============================================================================

# 1. Load Modules
$ChartScriptPath = Join-Path $PSScriptRoot "EmailGenerate\ChartGenerator.ps1"
$TableScriptPath = Join-Path $PSScriptRoot "EmailGenerate\TableGenerator.ps1"

if (Test-Path $ChartScriptPath) { . $ChartScriptPath } else { Write-Error "ChartGenerator missing!" }
if (Test-Path $TableScriptPath) { . $TableScriptPath } else { Write-Error "TableGenerator missing!" }

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

    if (-not (Test-Path $MainConfPath)) { Write-Host "Config not found!" -ForegroundColor Red; return $false }
    $AppConf = Get-Content $MainConfPath -Raw -Encoding UTF8 | ConvertFrom-Json
    
    # Defaults
    $SelectedStyle = "Universal Card"; $ContentType = "Table List"; $ChartType = "Rate Analysis"; $SubjectPrefix = "Gacha Report"
    
    if (Test-Path $EmailConfPath) {
        try {
            $ES = Get-Content $EmailConfPath -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($ES.Style) { $SelectedStyle = $ES.Style }
            if ($ES.ContentType) { $ContentType = $ES.ContentType }
            if ($ES.ChartType) { $ChartType = $ES.ChartType }
            if ($ES.SubjectPrefix) { $SubjectPrefix = $ES.SubjectPrefix }
        } catch {}
    }

    $RawGameName = if ($script:CurrentGame) { $script:CurrentGame } else { "Gacha" }
    switch ($RawGameName) {
        "Genshin" { $GameTitle = "Genshin Impact" }
        "HSR"     { $GameTitle = "Honkai: Star Rail" }
        "ZZZ"     { $GameTitle = "Zenless Zone Zero" }
        Default   { $GameTitle = $RawGameName } 
    }

    $toEmail = $AppConf.NotificationEmail; $senderEmail = $AppConf.SenderEmail; $senderPass = $AppConf.SenderPassword
    if ([string]::IsNullOrWhiteSpace($toEmail) -or [string]::IsNullOrWhiteSpace($senderEmail)) { return $false }
    $smtpServer = if ($AppConf.SmtpServer) { $AppConf.SmtpServer } else { "smtp.gmail.com" }
    $smtpPort = if ($AppConf.SmtpPort) { $AppConf.SmtpPort } else { 587 }

    # 2. PREPARE CONTENT
    $Attachments = @()
    if ($ContentType -eq "Chart Snapshot") {
        $TempImage = Join-Path $env:TEMP "Hoyo_Chart.png"
         Generate-ChartImage -DataList $HistoryData -ChartType $ChartType -Config $Config -OutPath $TempImage -SortDesc $SortDesc
        if (Test-Path $TempImage) {
            $Attachments += $TempImage
            $BodyContent = "<div style='text-align:center;'><img src='cid:Hoyo_Chart.png' style='max-width:100%;border-radius:8px;border:1px solid #444;'></div>"
        } else {
            $BodyContent = "<p style='color:red;'>Error generating chart.</p>"
        }
    } else {
        $BodyContent = Generate-TableHTML -DataList $HistoryData -Style $SelectedStyle -ShowNoMode $ShowNoMode -SortDesc $SortDesc
    }

    # 3. FINAL HTML WRAPPER (Fixed Layouts)
    $Meta = "<meta charset='utf-8'>"
    
    # Helper for Wrapping: Email clients often strip <body>, so we use a Main Wrapper Div.
    # Structure: <html><body> <div MainWrap> <div CenterCard> Content </div> </div> </body></html>

    switch ($SelectedStyle) {
        "Universal Card" {
            $htmlBody = @"
<!DOCTYPE html><html><head>$Meta<style>
    body{margin:0;padding:0;font-family:'Segoe UI',sans-serif;}
    table {width:100%; border-collapse:collapse;}
    th, td {padding:10px; border-bottom:1px solid #2a2a2a; color:#eee;}
</style></head><body>
<div style='background-color:#121212; padding:20px; width:100%; min-height:100vh;'>
    <div style='max-width:600px; margin:0 auto; background-color:#1e1e1e; border-radius:12px; overflow:hidden; border:1px solid #333; box-shadow:0 4px 15px rgba(0,0,0,0.5);'>
        <div style='background:linear-gradient(180deg, #2a2a2a 0%, #1e1e1e 100%); padding:20px; border-bottom:1px solid #333; text-align:center;'>
            <h2 style='margin:0; font-size:22px; color:#fff; text-transform:uppercase;'>$GameTitle</h2>
            <p style='margin:5px 0 0; font-size:12px; color:#888;'>$SubjectPrefix</p>
        </div>
        <div style='padding:20px;'>$BodyContent</div>
    </div>
</div></body></html>
"@
        }
        "Classic Table" {
            $htmlBody = @"
<!DOCTYPE html><html><head>$Meta<style>body{margin:0;padding:0;font-family:Tahoma;} table{width:100%;border-collapse:collapse;} th,td{border:1px solid #ccc;padding:8px;color:#000;}</style></head><body>
<div style='background-color:#ffffff; padding:20px; color:#000;'>
    <div style='max-width:600px; margin:0 auto;'>
        <h3 style='border-bottom:2px solid #000; padding-bottom:10px;'>$GameTitle - $SubjectPrefix</h3>
        $BodyContent
    </div>
</div></body></html>
"@
        }
        "Terminal Mode" {
            $htmlBody = @"
<!DOCTYPE html><html><head>$Meta<style>body{margin:0;padding:0;font-family:Consolas,monospace;} table{width:100%;}</style></head><body>
<div style='background-color:#000000; color:#00ff00; padding:20px; min-height:500px;'>
    <div style='max-width:700px; margin:0 auto;'>
        <div>&gt; TARGET: $GameTitle</div>
        <div>&gt; SUBJECT: $SubjectPrefix</div>
        <div style='border:1px dashed #00ff00; padding:15px; margin-top:10px;'>$BodyContent</div>
        <br><div>&gt; END_LOG</div>
    </div>
</div></body></html>
"@
        }
        "Modern Dark" {
            # FIX: Added Dark Background Wrapper
            $htmlBody = @"
<!DOCTYPE html><html><head>$Meta<style>body{margin:0;padding:0;font-family:sans-serif;} table{width:100%;border-collapse:collapse;} td{padding:12px;border-bottom:1px solid #444;color:#ddd;}</style></head><body>
<div style='background-color:#222222; padding:30px; min-height:100%;'>
    <div style='max-width:600px; margin:0 auto; background-color:#2b2b2b; padding:20px; border-radius:8px; box-shadow:0 2px 10px rgba(0,0,0,0.3);'>
        <h3 style='border-left:5px solid #4db8ff; padding-left:15px; color:#fff; margin-top:0;'>$GameTitle</h3>
        <p style='color:#888; font-size:12px; margin-bottom:20px;'>$SubjectPrefix</p>
        $BodyContent
    </div>
</div></body></html>
"@
        }
        "Minimalist White" {
            # FIX: Added Gray Background Wrapper & Shadow Card
            $htmlBody = @"
<!DOCTYPE html><html><head>$Meta<style>body{margin:0;padding:0;font-family:'Helvetica Neue',sans-serif;} table{width:100%;border-collapse:collapse;} td{padding:15px 5px;border-bottom:1px solid #eee;color:#333;}</style></head><body>
<div style='background-color:#f4f4f4; padding:30px; min-height:100%;'>
    <div style='max-width:600px; margin:0 auto; background-color:#ffffff; padding:40px; box-shadow:0 1px 3px rgba(0,0,0,0.1); border-radius:4px;'>
        <h2 style='font-weight:300; color:#000; text-align:center; margin-top:0;'>$GameTitle</h2>
        <div style='text-align:center; color:#aaa; font-size:12px; margin-bottom:30px; letter-spacing:1px;'>$SubjectPrefix</div>
        $BodyContent
    </div>
</div></body></html>
"@
        }
        "Cyber Neon" {
            # FIX: Added Black Wrapper
            $ThemeColor = "#ff00de"; $SecColor = "#00eaff"
            $htmlBody = @"
<!DOCTYPE html><html><head>$Meta<style>body{margin:0;padding:0;font-family:Verdana;} table{width:100%;} td{padding:10px;border-bottom:1px solid $SecColor;color:#fff;}</style></head><body>
<div style='background-color:#050505; padding:20px; min-height:100%;'>
    <div style='max-width:600px; margin:0 auto; border:2px solid $ThemeColor; box-shadow:0 0 15px $ThemeColor; padding:20px; border-radius:5px; background-color:#000;'>
        <h3 style='color:$SecColor; text-align:center; text-transform:uppercase; text-shadow:0 0 5px $SecColor; margin-top:0;'>$GameTitle :: $SubjectPrefix</h3>
        $BodyContent
    </div>
</div></body></html>
"@
        }
        "Blueprint" {
            # FIX: Added Blue Wrapper
            $htmlBody = @"
<!DOCTYPE html><html><head>$Meta<style>body{margin:0;padding:0;font-family:'Courier New';} table{width:100%;border:2px solid #fff;margin-top:20px;} td{border:1px solid #88aadd;padding:8px;color:#fff;}</style></head><body>
<div style='background-color:#003366; padding:20px; min-height:100%; color:#fff;'>
    <div style='max-width:650px; margin:0 auto; border:4px solid #fff; padding:20px;'>
        <div style='border:2px solid #fff; display:inline-block; padding:10px; background-color:#004488; font-weight:bold;'>PROJECT: $GameTitle</div>
        <p>DOC: $SubjectPrefix</p>
        $BodyContent
    </div>
</div></body></html>
"@
        }
        "Vintage Log" {
             # FIX: Added Beige Wrapper
            $htmlBody = @"
<!DOCTYPE html><html><head>$Meta<style>body{margin:0;padding:0;font-family:'Georgia',serif;} table{width:100%;border-top:2px double #8B4513;border-bottom:2px double #8B4513;margin-top:20px;} td{padding:12px;font-style:italic;color:#5c4033;}</style></head><body>
<div style='background-color:#FDF5E6; padding:30px; min-height:100%;'>
    <div style='max-width:600px; margin:0 auto;'>
        <h2 style='text-align:center; border-bottom:2px solid #8B4513; padding-bottom:10px; color:#5c4033;'>$GameTitle Adventurer Log</h2>
        <p style='text-align:center; color:#5c4033;'>$SubjectPrefix</p>
        $BodyContent
    </div>
</div></body></html>
"@
        }
        "Excel Sheet" {
            # FIX: Added White Wrapper + Sheet Look
            $htmlBody = @"
<!DOCTYPE html><html><head>$Meta<style>body{margin:0;padding:0;font-family:Arial,sans-serif;} table{border-collapse:collapse;width:100%;border:1px solid #ccc;background:#fff;} td,th{border:1px solid #ccc;padding:5px;font-size:13px;color:#000;} tr:first-child{background:#f3f3f3;font-weight:bold;}</style></head><body>
<div style='background-color:#e6e6e6; padding:30px; min-height:100%;'>
    <div style='max-width:700px; margin:0 auto; background-color:#fff; padding:20px; border:1px solid #ccc; box-shadow:0 2px 5px rgba(0,0,0,0.1);'>
        <div style='background-color:#217346; color:white; padding:8px 15px; font-weight:bold; border-radius:4px 4px 0 0; display:inline-block; margin-bottom:10px;'>$GameTitle - $SubjectPrefix</div>
        $BodyContent
    </div>
</div></body></html>
"@
        }
        "Gacha Pop" {
            # FIX: Star symbol Encoding (&#9733;) and Pink Wrapper
            $htmlBody = @"
<!DOCTYPE html><html><head>$Meta<style>body{margin:0;padding:0;font-family:'Comic Sans MS',sans-serif;} table{width:100%;} td{padding:10px;border-bottom:1px dotted #ff99cc;color:#555;}</style></head><body>
<div style='background-color:#ffe6f2; padding:30px; min-height:100%;'>
    <div style='max-width:600px; margin:0 auto; background-color:#ffffff; border-radius:20px; padding:20px; border:4px dashed #ff66b2;'>
        <h2 style='text-align:center; color:#ff66b2; margin-top:0;'>&#9733; $GameTitle &#9733;</h2>
        <p style='text-align:center; color:#888;'>$SubjectPrefix</p>
        $BodyContent
    </div>
</div></body></html>
"@
        }
    }

    # 5. SEND MAIL
    try {
        $secPass = ConvertTo-SecureString $senderPass -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential($senderEmail, $secPass)
        
        $params = @{
            From = $senderEmail; To = $toEmail; Subject = "[$GameTitle] $SubjectPrefix"; Body = $htmlBody; BodyAsHtml = $true
            SmtpServer = $smtpServer; Port = $smtpPort; UseSsl = $true; Credential = $cred; Encoding = [System.Text.Encoding]::UTF8
        }
        if ($Attachments.Count -gt 0) { $params.Attachments = $Attachments }

        Send-MailMessage @params
        Write-Host "Email Sent Successfully ($ContentType : $SelectedStyle)" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "Email Failed: $_" -ForegroundColor Red
        return $false
    } finally {
        if ($TempImage -and (Test-Path $TempImage)) { Remove-Item $TempImage -Force -ErrorAction SilentlyContinue }
    }
}