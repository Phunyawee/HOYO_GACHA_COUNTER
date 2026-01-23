function Invoke-GachaSimulation {
    param(
        [int]$SimCount = 100000, 
        [int]$MyPulls,           
        [int]$StartPity,         
        [bool]$IsGuaranteed,     
        [int]$HardPityCap = 90,  
        [int]$SoftPityStart = 74,
        [scriptblock]$ProgressCallback,
        [ref]$StopFlag # <--- ตัวรับคำสั่งหยุด (Pass by Reference)
    )

    $SuccessCount = 0
    $TotalPullsUsed = 0
    $BaseRate = 0.6
    
    $Distribution = @{}

    for ($round = 1; $round -le $SimCount; $round++) {
        
        # [NEW] Check Stop Signal (เช็คทุกๆ 1000 รอบ เพื่อความไวและไม่กิน Spec)
        if ($round % 1000 -eq 0) {
            if ($StopFlag.Value) { 
                return @{ IsCancelled = $true } # ส่งสัญญาณกลับว่า "ถูกยกเลิก"
            }
        }

        # Progress Report (แจ้งทุกๆ 10% ของจำนวนรอบ)
        if ($round % ($SimCount / 10) -eq 0) {
            if ($ProgressCallback) { & $ProgressCallback $round }
        }

        $CurrentPity = $StartPity
        $Guaranteed = $IsGuaranteed
        $GotIt = $false
        
        # เริ่มจำลองการเปิดกาชาทีละโรล
        for ($i = 1; $i -le $MyPulls; $i++) {
            $CurrentPity++
            $CurrentRate = $BaseRate
            
            # คำนวณเรทตาม Soft Pity
            if ($CurrentPity -ge $SoftPityStart) {
                $CurrentRate = $BaseRate + (($CurrentPity - $SoftPityStart) * 6.0)
            }
            # Hard Pity
            if ($CurrentPity -ge $HardPityCap) { $CurrentRate = 100.0 }

            # สุ่มตัวเลข 0.0 - 100.0
            $Roll = (Get-Random -Minimum 0.0 -Maximum 100.0)

            if ($Roll -le $CurrentRate) {
                # ถ้าออก 5 ดาว เช็ค 50/50
                if ($Guaranteed -or (Get-Random -Min 0 -Max 2) -eq 0) {
                    $GotIt = $true
                    $TotalPullsUsed += $i
                    
                    # เก็บสถิติว่าได้ตอนโรลที่เท่าไหร่ (จัดกลุ่มทีละ 10)
                    $bucket = [math]::Ceiling($i / 10) * 10
                    if (-not $Distribution.ContainsKey($bucket)) { $Distribution[$bucket] = 0 }
                    $Distribution[$bucket]++
                    break
                } else {
                    # หลุดเรท -> รอบหน้าการันตี -> Pity รีเซ็ต
                    $Guaranteed = $true
                    $CurrentPity = 0 
                }
            }
        }
        
        if ($GotIt) { $SuccessCount++ }
    }

    return @{
        IsCancelled = $false
        WinRate = ($SuccessCount / $SimCount) * 100
        AvgCost = if ($SuccessCount -gt 0) { $TotalPullsUsed / $SuccessCount } else { 0 }
        Distribution = $Distribution 
    }
}