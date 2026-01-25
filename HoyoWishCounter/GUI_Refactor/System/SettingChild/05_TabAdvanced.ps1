# =============================================================================
# FILE: SettingChild\05_TabAdvanced.ps1
# DESCRIPTION: หน้า Advanced Editor สำหรับแก้ JSON ดิบ และระบบ Hot Reload
# DEPENDENCIES: $conf, $AppRoot, $script:fontNormal, $script:fontBold
# =============================================================================

# Fallback $AppRoot
if (-not $AppRoot) { $AppRoot = $PSScriptRoot }

$script:tAdv = New-Tab "Advanced"

# 1. Warning Label
$lblAdvInfo = New-Object System.Windows.Forms.Label
$lblAdvInfo.Text = "CAUTION: Direct JSON Editing Mode. Syntax errors may reset config."
$lblAdvInfo.Location = "15, 15"; $lblAdvInfo.AutoSize = $true
$lblAdvInfo.ForeColor = "Orange"
$lblAdvInfo.Font = New-Object System.Drawing.Font("Consolas", 8)
$script:tAdv.Controls.Add($lblAdvInfo)

# 2. JSON Text Area
$script:txtJson = New-Object System.Windows.Forms.TextBox
$script:txtJson.Multiline = $true
$script:txtJson.ScrollBars = "Vertical"
$script:txtJson.Location = "15, 40"
$script:txtJson.Size = "505, 360"
$script:txtJson.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 20)
$script:txtJson.ForeColor = "LimeGreen"
$script:txtJson.Font = New-Object System.Drawing.Font("Consolas", 10)
$script:txtJson.BorderStyle = "FixedSingle"
$script:txtJson.Text = $conf | ConvertTo-Json -Depth 5
$script:tAdv.Controls.Add($script:txtJson)

# 3. Button Bar
$pnlAdvBtns = New-Object System.Windows.Forms.Panel
$pnlAdvBtns.Location = "15, 410"; $pnlAdvBtns.Size = "505, 35"
$script:tAdv.Controls.Add($pnlAdvBtns)

# [Button] Open Folder
$btnAdvOpen = New-Object System.Windows.Forms.Button
$btnAdvOpen.Text = "Open Folder"
$btnAdvOpen.Location = "0, 0"; $btnAdvOpen.Size = "100, 30"
Apply-ButtonStyle -Button $btnAdvOpen -BaseColorName "DimGray" -HoverColorName "Gray" -CustomFont $script:fontNormal
$btnAdvOpen.Add_Click({ Invoke-Item (Join-Path $AppRoot "Settings") })
$pnlAdvBtns.Controls.Add($btnAdvOpen)

# [Button] Revert
$btnAdvReload = New-Object System.Windows.Forms.Button
$btnAdvReload.Text = "Revert Changes"
$btnAdvReload.Location = "110, 0"; $btnAdvReload.Size = "120, 30"
Apply-ButtonStyle -Button $btnAdvReload -BaseColorName "IndianRed" -HoverColorName "Red" -CustomFont $script:fontNormal
$btnAdvReload.Add_Click({
    $script:txtJson.Text = $conf | ConvertTo-Json -Depth 5
    if (Get-Command WriteGUI-Log -ErrorAction SilentlyContinue) { WriteGUI-Log "Reverted JSON editor changes." "Yellow" }
})
$pnlAdvBtns.Controls.Add($btnAdvReload)

# [Button] SAVE & HOT RELOAD
$btnAdvSave = New-Object System.Windows.Forms.Button
$btnAdvSave.Text = "SAVE & APPLY (HOT RELOAD)"
$btnAdvSave.Location = "285, 0"; $btnAdvSave.Size = "220, 30"
Apply-ButtonStyle -Button $btnAdvSave -BaseColorName "SeaGreen" -HoverColorName "Lime" -CustomFont $script:fontBold

$btnAdvSave.Add_Click({
    try {
        # 1. Convert Text -> Object
        $newRawObj = $script:txtJson.Text | ConvertFrom-Json
        
        # 2. Save to File
        $setDir = Join-Path $AppRoot "Settings"
        if (-not (Test-Path $setDir)) { New-Item -ItemType Directory -Path $setDir -Force | Out-Null }
        $script:txtJson.Text | Out-File (Join-Path $setDir "config.json") -Encoding UTF8

        # 3. Update Global Config
        $script:AppConfig = $newRawObj
        
        # 4. Update UI Elements via Function (Apply Theme)
        Apply-Theme -NewHex $newRawObj.AccentColor -NewOpacity $newRawObj.Opacity
        
        # Sync back to Main Config Variable & UI Controls
        $Global:conf = $newRawObj  # ใช้ Global หรือ Scope ใหญ่เพื่อให้ค่าเปลี่ยนจริง
        $script:TempHexColor = $newRawObj.AccentColor
        
        # Update Controls in other tabs (สำคัญมากต้อง update ไม่งั้นกด tab อื่นค่าจะเพี้ยน)
        $script:trackOp.Value = [int]($newRawObj.Opacity * 100)
        
        if (Get-Command WriteGUI-Log -ErrorAction SilentlyContinue) { WriteGUI-Log "Advanced Config Saved & Hot-Reloaded!" "Lime" }
        [System.Windows.Forms.MessageBox]::Show("Configuration updated and applied live!", "Success", 0, 64)
        
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Invalid JSON Syntax!`nCheck your commas and brackets.`n`nError: $($_.Exception.Message)", "JSON Error", 0, 16)
    }
})
$pnlAdvBtns.Controls.Add($btnAdvSave)