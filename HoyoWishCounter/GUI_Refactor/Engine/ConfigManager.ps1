# กำหนด path ของ config
# เช็คว่ามี AppRoot ส่งมาไหม ถ้าไม่มี (รันแยก) ให้ใช้ path ตัวเอง แล้วถอยกลับ 1 ขั้น (..)
$RootBase = if ($script:AppRoot) { $script:AppRoot } else { (Join-Path $PSScriptRoot "..") }

# --- [เริ่มส่วนที่แก้] ---
# 1. กำหนด Path โฟลเดอร์ Settings
$SettingsDir = Join-Path $RootBase "Settings"

# 2. ถ้าไม่มีโฟลเดอร์ ให้สร้างใหม่ทันที
if (-not (Test-Path $SettingsDir)) {
    New-Item -ItemType Directory -Path $SettingsDir -Force | Out-Null
}

# 3. ชี้ไฟล์ Config เข้าไปในโฟลเดอร์ Settings
$script:ConfigFile = Join-Path $SettingsDir "config.json"

function Get-AppConfig {
    # 1. ตั้งค่า Default ให้ครบ
    $defaultConfig = @{
        WebhookUrl = ""
        AutoSendDiscord = $true
        LastGame = "Genshin"
        Paths = @{ Genshin=""; HSR=""; ZZZ="" }
        
        # General
        DebugConsole = $false
        Opacity = 1.0
        AccentColor = "#00FFFF" # ใส่เป็น Hex เลยชัวร์กว่า "Cyan"
        BackupPath = ""
        CsvSeparator = "," 
        EnableFileLog = $true
        EnableSound = $false
        EnableAutoBackup = $true

        # Notification (Receiver)
        NotificationEmail = ""
        AutoSendEmail = $false

        # [NEW] SMTP Settings (Sender) -- ต้องเพิ่มตรงนี้!
        SmtpServer = "smtp.gmail.com"
        SmtpPort = 587
        SenderEmail = ""
        SenderPassword = ""
    }

    if (Test-Path $script:ConfigFile) {
        try {
            $json = Get-Content $script:ConfigFile -Raw -Encoding UTF8 | ConvertFrom-Json
            
            # 2. Logic Merge: เอาค่าจาก JSON ทับลง Default
            foreach ($key in $json.PSObject.Properties.Name) {
                if ($defaultConfig.ContainsKey($key)) {
                    if ($key -eq "Paths") {
                        foreach ($gKey in $json.Paths.PSObject.Properties.Name) {
                            $defaultConfig.Paths[$gKey] = $json.Paths.$gKey
                        }
                    } else {
                        $defaultConfig[$key] = $json.$key
                    }
                }
            }
        } catch {
            # ใช้ Write-LogFile แทน Log-Status เพราะ ConfigManager โหลดก่อน Engine
            if (Get-Command "Write-LogFile" -ErrorAction SilentlyContinue) {
                Write-LogFile -Message "Config Read Error. Using Defaults." -Level "WARN"
            }
        }
    }
    return [PSCustomObject]$defaultConfig
}

function Save-AppConfig {
    param($ConfigObj)
    try {
        $jsonStr = $ConfigObj | ConvertTo-Json -Depth 2
        $jsonStr | Set-Content -Path $script:ConfigFile -Encoding UTF8
        
        # แจ้งลงไฟล์ Log
        if (Get-Command "Write-LogFile" -ErrorAction SilentlyContinue) {
            Write-LogFile -Message "Configuration Saved." -Level "INFO"
        }
        
        # แจ้งหน้าจอ (ถ้ามีฟังก์ชัน Log-Status หรือ Write-GuiLogของ UI อยู่แล้ว)
        if (Get-Command "Log" -ErrorAction SilentlyContinue) {
            WriteGUI-Log "Configuration Saved." "Lime"
        }
    } catch {
        if (Get-Command "Write-LogFile" -ErrorAction SilentlyContinue) {
            Write-LogFile -Message "Error saving config: $($_.Exception.Message)" -Level "ERROR"
        }
        [System.Windows.Forms.MessageBox]::Show("Could not save settings!", "Error", 0, 16)
    }
}

function Get-GameConfig {
    param([string]$GameName)
    
    $BaseRepoUrl = "https://raw.githubusercontent.com/Phunyawee/HOYO_GACHA_COUNTER/main/HoyoWishCounter/BotIcon"

    switch ($GameName) {
        "Genshin" {
            return @{
                Name = "Genshin Impact"
                # LogPath: ที่อยู่ของไฟล์ Write-LogFile(Genshin มี 2 ค่าย miHoYo กับ Cognosphere)
                LogFolders = @("miHoYo\Genshin Impact", "Cognosphere\Genshin Impact") 
                DataFolderName = "GenshinImpact_Data"
                HostUrl = "public-operation-hk4e-sg.hoyoverse.com"
                ApiEndpoint = "/gacha_info/api/getGachaLog"
                GameBiz = "hk4e_global"
                SRank = "5"; ThemeColor = 16766720
                IconUrl = "$BaseRepoUrl/Paimon.png"
                Banners = @(@{ Code="301"; Name="Character Event" },@{ Code="302"; Name="Weapon Event" },@{ Code="200"; Name="Standard" },@{ Code="100"; Name="Novice" })
            }
        }
        "HSR" {
            return @{
                Name = "Honkai: Star Rail"
                LogFolders = @("Cognosphere\Star Rail")
                DataFolderName = "StarRail_Data"
                HostUrl = "public-operation-hkrpg.hoyoverse.com"
                ApiEndpoint = "/common/gacha_record/api/getGachaLog"
                GameBiz = "hkrpg_global"
                SRank = "5"; ThemeColor = 3447003
                IconUrl = "$BaseRepoUrl/Pompom.png"
                Banners = @(@{ Code="11"; Name="Character Warp" },@{ Code="12"; Name="Light Cone Warp" },@{ Code="1";  Name="Stellar Warp" },@{ Code="2";  Name="Departure Warp" })
            }
        }
        "ZZZ" {
            return @{
                Name = "Zenless Zone Zero"
                LogFolders = @("miHoYo\ZenlessZoneZero", "Cognosphere\ZenlessZoneZero")
                DataFolderName = "ZenlessZoneZero_Data"
                HostUrl = "public-operation-nap-sg.hoyoverse.com"
                ApiEndpoint = "/common/gacha_record/api/getGachaLog"
                GameBiz = "nap_global"
                SRank = "4"; ThemeColor = 16738816
                IconUrl = "$BaseRepoUrl/Bangboo.png"
                Banners = @(@{ Code="2"; Name="Exclusive (Char)" },@{ Code="3"; Name="W-Engine (Weap)" },@{ Code="5"; Name="Bangboo" },@{ Code="1"; Name="Standard" })
            }
        }
    }
    return $null
}