# ==============================================================================
# ENGINE: EMAIL MANAGER (Fixed Backgrounds & Encoding)
# ==============================================================================

# 1. Load Modules
$ChartScriptPath = Join-Path $PSScriptRoot "EmailGenerate\ChartGenerator.ps1"
$TableScriptPath = Join-Path $PSScriptRoot "EmailGenerate\TableGenerator.ps1"
$StyleScriptPath = Join-Path $PSScriptRoot "EmailGenerate\StyleGenerator.ps1"


if (Test-Path $ChartScriptPath) { . $ChartScriptPath } else { Write-Error "ChartGenerator missing!" }
if (Test-Path $TableScriptPath) { . $TableScriptPath } else { Write-Error "TableGenerator missing!" }
if (Test-Path $StyleScriptPath) { . $StyleScriptPath } else { Write-Error "StyleGenerator missing!" } 
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
    $htmlBody = Get-EmailStyleHTML -StyleName $SelectedStyle `
                                    -GameTitle $GameTitle `
                                    -SubjectPrefix $SubjectPrefix `
                                    -BodyContent $BodyContent


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