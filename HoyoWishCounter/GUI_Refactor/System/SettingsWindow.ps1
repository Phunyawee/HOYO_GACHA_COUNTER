function Show-SettingsWindow {
    # 1. [FIX] กำหนด Root ของโปรแกรม (ถอยจาก System ออกมา 1 ขั้น)
    $AppRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

    # 2. Load Config
    $conf = Get-AppConfig 

    # --- FORM SETUP ---
    $fSet = New-Object System.Windows.Forms.Form
    $fSet.Text = "Preferences & Settings"
    $fSet.Size = New-Object System.Drawing.Size(550, 600)
    $fSet.StartPosition = "CenterParent"
    $fSet.BackColor = [System.Drawing.Color]::FromArgb(35, 35, 35)
    $fSet.ForeColor = "White"
    $fSet.FormBorderStyle = "FixedToolWindow"

    # --- TABS ---
    $tabs = New-Object System.Windows.Forms.TabControl; $tabs.Dock = "Top"; $tabs.Height = 480; $tabs.Appearance = "FlatButtons"; $fSet.Controls.Add($tabs)
    function New-Tab($title) { $page = New-Object System.Windows.Forms.TabPage; $page.Text = "  $title  "; $page.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 45); $tabs.TabPages.Add($page); return $page }

    # ================= TAB 1: GENERAL =================
    . "$PSScriptRoot\SettingChild\01_TabGeneral.ps1"
    # ================= TAB 2: APPEARANCE =================
    . "$PSScriptRoot\SettingChild\02_TabAppearance.ps1"
    # ================= TAB 3: INTEGRATIONS =================
    . "$PSScriptRoot\SettingChild\03_TabIntegrations.ps1"
    # ================= TAB 4: DATA & MAINTENANCE =================
    . "$PSScriptRoot\SettingChild\04_TabDataMaintenance.ps1"
    # ==================================================
    # TAB 5: ADVANCED (RAW JSON EDITOR)
    # ==================================================
    . "$PSScriptRoot\SettingChild\05_TabAdvanced.ps1"

    # 6. Footer Buttons & Logic
    . "$PSScriptRoot\SettingChild\06_SettingsFooter.ps1"
    
    $fSet.ShowDialog()
}