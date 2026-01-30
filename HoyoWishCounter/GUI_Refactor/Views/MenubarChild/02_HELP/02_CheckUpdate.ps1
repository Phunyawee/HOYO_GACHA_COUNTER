# ---------------------------------------------------------------------------
# MODULE: 02_CheckUpdate.ps1
# DESCRIPTION: Check for Updates / Version Control Window
# PARENT: 02_HELP.ps1
# ---------------------------------------------------------------------------

$itemUpdate = New-Object System.Windows.Forms.ToolStripMenuItem("Check for Updates")
[void]$menuHelp.DropDownItems.Add($itemUpdate)

$itemUpdate.Add_Click({
    # 1. Setup Form
    $fUpd = New-Object System.Windows.Forms.Form
    $fUpd.Text = "System Status"
    $fUpd.Size = New-Object System.Drawing.Size(350, 450)
    $fUpd.StartPosition = "CenterParent"
    $fUpd.FormBorderStyle = "FixedToolWindow"
    $fUpd.BackColor = [System.Drawing.Color]::FromArgb(25, 25, 30)
    $fUpd.ForeColor = "White"

    # Helper: จัดกึ่งกลางอัตโนมัติ (Scope นี้เท่านั้น)
    function Center-Control($ctrl) {
        $ctrl.Left = ($fUpd.ClientSize.Width - $ctrl.Width) / 2
    }

    # --- TITLE ---
    $lblHead = New-Object System.Windows.Forms.Label
    $lblHead.Text = "VERSION CONTROL"
    $lblHead.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $lblHead.ForeColor = "DimGray"
    $lblHead.AutoSize = $true
    $lblHead.Top = 25
    $fUpd.Controls.Add($lblHead)
    
    # --- 1. APP VERSION (UI) ---
    $lblAppTitle = New-Object System.Windows.Forms.Label
    $lblAppTitle.Text = "Interface Version"
    $lblAppTitle.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
    $lblAppTitle.ForeColor = "Silver"
    $lblAppTitle.AutoSize = $true
    $lblAppTitle.Top = 60
    $fUpd.Controls.Add($lblAppTitle)

    $lblAppVer = New-Object System.Windows.Forms.Label
    $lblAppVer.Text = "$script:AppVersion"
    $lblAppVer.Font = New-Object System.Drawing.Font("Segoe UI", 26, [System.Drawing.FontStyle]::Bold)
    $lblAppVer.ForeColor = [System.Drawing.Color]::SpringGreen
    $lblAppVer.AutoSize = $true
    $lblAppVer.Top = 80
    $fUpd.Controls.Add($lblAppVer)

    # --- SEPARATOR LINE ---
    $pnlLine = New-Object System.Windows.Forms.Panel
    $pnlLine.Size = New-Object System.Drawing.Size(200, 1)
    $pnlLine.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
    $pnlLine.Top = 145
    $fUpd.Controls.Add($pnlLine)

    # --- 2. ENGINE VERSION (Backend) ---
    $lblEngTitle = New-Object System.Windows.Forms.Label
    $lblEngTitle.Text = "Core Engine Version"
    $lblEngTitle.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
    $lblEngTitle.ForeColor = "Silver"
    $lblEngTitle.AutoSize = $true
    $lblEngTitle.Top = 165
    $fUpd.Controls.Add($lblEngTitle)

    $lblEngVer = New-Object System.Windows.Forms.Label
    $lblEngVer.Text = "$script:EngineVersion"
    $lblEngVer.Font = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold)
    $lblEngVer.ForeColor = [System.Drawing.Color]::Gold
    $lblEngVer.AutoSize = $true
    $lblEngVer.Top = 185
    $fUpd.Controls.Add($lblEngVer)

    # --- GITHUB BUTTON ---
    $btnGit = New-Object System.Windows.Forms.Button
    $btnGit.Text = "Check GitHub for Updates"
    $btnGit.Size = New-Object System.Drawing.Size(220, 40)
    $btnGit.Top = 260
    $btnGit.BackColor = [System.Drawing.Color]::FromArgb(50, 50, 70)
    $btnGit.ForeColor = "White"
    $btnGit.FlatStyle = "Flat"
    $btnGit.FlatAppearance.BorderSize = 0
    $btnGit.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
    $btnGit.Cursor = [System.Windows.Forms.Cursors]::Hand
    
    $btnGit.Add_Click({
        try {
            [System.Diagnostics.Process]::Start("https://github.com/Phunyawee/HOYO_GACHA_COUNTER")
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Could not open browser. Please visit GitHub manually.", "Error")
        }
    })
    $fUpd.Controls.Add($btnGit)

    # --- CLOSE BUTTON ---
    $btnClose = New-Object System.Windows.Forms.Button
    $btnClose.Text = "Close Window"
    $btnClose.Size = New-Object System.Drawing.Size(120, 30)
    $btnClose.Top = 360
    $btnClose.ForeColor = "Gray"
    $btnClose.FlatStyle = "Flat"
    $btnClose.FlatAppearance.BorderSize = 0
    $btnClose.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btnClose.Add_Click({ $fUpd.Close() })
    $fUpd.Controls.Add($btnClose)

    # จัดกึ่งกลาง
    Center-Control $lblHead
    Center-Control $lblAppTitle
    Center-Control $lblAppVer
    Center-Control $pnlLine
    Center-Control $lblEngTitle
    Center-Control $lblEngVer
    Center-Control $btnGit
    Center-Control $btnClose

    $fUpd.ShowDialog()
})