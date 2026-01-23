function Get-GachaStatus {
    param(
        [string]$GameName,
        [string]$CharName,
        [string]$BannerCode
    )

    # 1. ถ้าไม่ใช่ตู้ Event (เช่นตู้ถาวร หรือตู้อาวุธ) ไม่ต้องเช็ค 50/50
    # Genshin: 301 = Character Event, 400 = Character Event 2 (Legacy Code)
    # HSR: 11 = Character Warp
    # ZZZ: 2 = Exclusive Channel
    if ($GameName -eq "Genshin" -and $BannerCode -notmatch "301|400") { return "Standard/Weapon" }
    if ($GameName -eq "HSR" -and $BannerCode -ne "11") { return "Standard/Weapon" }
    if ($GameName -eq "ZZZ" -and $BannerCode -ne "2") { return "Standard/Weapon" }

    # 2. รายชื่อตัวหลุดเรท (Standard Pool)
    # หมายเหตุ: หากเกมมีการเพิ่มตัวถาวรใหม่ ต้องมาอัปเดตที่นี่
    $StandardPool = @()
    switch ($GameName) {
        "Genshin" { 
            $StandardPool = @("Diluc", "Jean", "Mona", "Qiqi", "Keqing", "Tighnari", "Dehya") 
        }
        "HSR" { 
            $StandardPool = @("Himeko", "Welt", "Bronya", "Gepard", "Clara", "Yanqing", "Bailu") 
        }
        "ZZZ" { 
            $StandardPool = @("Grace", "Rina", "Koleda", "Nekomata", "Soldier 11", "Lycaon") 
        }
    }

    # 3. เช็คสถานะ
    if ($StandardPool -contains $CharName) {
        return "LOSS" # หลุดเรท
    } else {
        return "WIN"  # ได้หน้าตู้
    }
}