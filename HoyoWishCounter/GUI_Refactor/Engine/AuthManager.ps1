# โหลด Assembly ที่จำเป็นสำหรับการจัดการ URL Query String
if ($PSVersionTable.PSVersion.Major -le 5) {
    Add-Type -AssemblyName System.Web
}

function Get-AuthLinkFromFile {
    param(
        [string]$FilePath, 
        [hashtable]$Config
    )

    if (-not (Test-Path $FilePath)) { throw "File not found!" }
    
    # อ่านไฟล์แบบ Raw และแบ่ง Chunk เพื่อหา URL ล่าสุด
    $content = Get-Content -Path $FilePath -Encoding UTF8 -Raw
    $chunks = $content -split "1/0/"
    
    # วนลูปย้อนกลับ (หาอันล่าสุดที่อยู่ท้ายไฟล์)
    for ($i = $chunks.Length - 1; $i -ge 0; $i--) {
        $chunk = $chunks[$i]
        
        # กรองเฉพาะท่อนที่มี https และ authkey
        if ($chunk -match "https" -and $chunk -match "authkey=") {
            $cleanStr = ($chunk -split "`0")[0]
            $rawUrl = $null

            # Regex ดึง URL ออกมา
            if ($cleanStr -match "(https.+?game_biz=[\w_]+)") { 
                $rawUrl = $matches[0] 
            } elseif ($cleanStr -match "(https.+?authkey=[^`" ]+)") { 
                $rawUrl = $matches[0] 
            }

            if ($rawUrl) {
                try {
                    $uri = [System.Uri]$rawUrl
                    
                    # Parse Query String เพื่อแก้ไข Parameter
                    if ($PSVersionTable.PSVersion.Major -le 5) {
                        $qs = [System.Web.HttpUtility]::ParseQueryString($uri.Query)
                    } else {
                        # Support PowerShell Core (เบื้องต้นใช้ logic เดิมแต่อาจต้องปรับถ้า environment ต่าง)
                        $qs = [System.Web.HttpUtility]::ParseQueryString($uri.Query)
                    }

                    # [Auto-Fix] ใส่ game_biz ถ้าไม่มี
                    if (-not $qs["game_biz"]) { $qs["game_biz"] = $Config.GameBiz }
                    
                    # [Auto-Fix] บังคับโหลดแค่ 1 แถวเพื่อ Test และตั้งประเภทตู้
                    $qs["size"] = "1"
                    $qs["gacha_type"] = $Config.Banners[0].Code
                    
                    # กรณี ZZZ ต้องใช้ real_gacha_type
                    if ($Config.Name -match "Zenless") { 
                        $qs["real_gacha_type"] = $Config.Banners[0].Code 
                    } 
                    
                    # สร้าง URL ใหม่สำหรับยิง API
                    $builder = New-Object System.UriBuilder("https://$($uri.Host)$($Config.ApiEndpoint)")
                    $builder.Query = $qs.ToString()
                    $TestLink = $builder.Uri.AbsoluteUri

                    # ยิงทดสอบ (Validation)
                    $test = Invoke-RestMethod -Uri $TestLink -Method Get -TimeoutSec 3
                    
                    if ($test.retcode -eq 0) {
                        # ถ้าผ่าน ส่งค่ากลับเป็น Hashtable
                        return @{ 
                            Url = $TestLink
                            Host = $uri.Host 
                        }
                    }
                } catch {
                    # ถ้า Error ในลูปนี้ ให้ข้ามไปหา Chunk ถัดไปแทน
                    continue 
                }
            }
        }
    }
    
    # ถ้าวนจนหมดแล้วยังไม่เจอที่ใช้ได้
    throw "No valid AuthKey found. Please open Wish History in-game to refresh."
}