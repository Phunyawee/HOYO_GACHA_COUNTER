# FILE: SettingChild\TabEmailChild\01_Config.ps1
# DESCRIPTION: Load Configuration

$EmailJsonPath = Join-Path $AppRoot "Settings\EmailForm.json"

# Default Config
$EmailConf = @{ 
    Style = "Universal Card"; 
    SubjectPrefix = "Gacha Report"; 
    ContentType = "Table List"; 
    ChartType = "Rate Analysis" 
}

# Try Load JSON
if (Test-Path $EmailJsonPath) {
    try {
        $loaded = Get-Content $EmailJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($loaded.Style) { $EmailConf.Style = $loaded.Style }
        if ($loaded.SubjectPrefix) { $EmailConf.SubjectPrefix = $loaded.SubjectPrefix }
        if ($loaded.ContentType) { $EmailConf.ContentType = $loaded.ContentType }
        if ($loaded.ChartType) { $EmailConf.ChartType = $loaded.ChartType }
    } catch {}
}

# Export Variables for Main Script
$script:EmailJsonPath = $EmailJsonPath