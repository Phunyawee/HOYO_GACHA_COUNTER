# ------------------------------------------------------------------------------
# GROUP 2: HELP / CREDITS
# ------------------------------------------------------------------------------
$menuHelp = New-Object System.Windows.Forms.ToolStripMenuItem("Help")
[void]$menuStrip.Items.Add($menuHelp)

    
    $itemCredits = New-Object System.Windows.Forms.ToolStripMenuItem("About & Credits")
    $itemCredits.ShortcutKeys = "F1" # กด F1 เพื่อเรียกดูได้ด้วย
    [void]$menuHelp.DropDownItems.Add($itemCredits)
    $itemCredits.Add_Click({
        # 1. เคลียร์หน้าจอ
        $txtLog.Clear()
        $txtLog.SelectionAlignment = "Center"

        # --- PALETTE SETUP (กำหนดชุดสีที่ดูแพง) ---
        # ฟ้าโฮโย (Hoyo Blue): ไม่ฟ้าสด แต่เป็นฟ้าอมเขียวนิดๆ สว่างๆ
        $colTitle  = [System.Drawing.Color]::FromArgb(60, 220, 255) 
        # เทาผู้ดี (Subtle Gray): สำหรับ Version
        $colSub    = [System.Drawing.Color]::FromArgb(150, 150, 160)
        # ทองหรู (Rich Gold): เหลืองอมส้มนิดๆ ไม่ใช่เหลืองมะนาว
        $colGold   = [System.Drawing.Color]::FromArgb(255, 200, 60)
        # เขียวพาสเทล (Mint Green): อ่านง่ายสบายตา
        $colQuote  = [System.Drawing.Color]::FromArgb(140, 255, 170)
        # เทาเข้ม (Dark Footer): จางๆ
        $colFooter = [System.Drawing.Color]::FromArgb(80, 80, 90)

        # --- HEADER ---
        $txtLog.SelectionFont = New-Object System.Drawing.Font("Consolas", 14, [System.Drawing.FontStyle]::Bold)
        $txtLog.SelectionColor = $colTitle
        # ใช้เส้นขีดบางๆ แทนเครื่องหมายเท่ากับ จะดู Modern กว่า
        $txtLog.AppendText("`n________________________________`n`n")
        $txtLog.AppendText(" HOYO WISH COUNTER (ULTIMATE) `n")
        $txtLog.AppendText("________________________________`n`n")

        # --- VERSION ---
        $txtLog.SelectionFont = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
        $txtLog.SelectionColor = $colSub
        # ใช้สัญลักษณ์ • คั่นกลาง
        $txtLog.AppendText("UI v$script:AppVersion  |  Engine v$script:EngineVersion`n`n`n")

        # --- DEVELOPER ---
        $txtLog.SelectionFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
        $txtLog.SelectionColor = "WhiteSmoke" # ขาวควันบุหรี่
        $txtLog.AppendText("Created & Designed by`n")

        $txtLog.SelectionFont = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold)
        $txtLog.SelectionColor = $colGold
        # ใส่ Space รอบชื่อให้ดูโปร่ง
        $txtLog.AppendText(" PHUNYAWEE `n`n") 

        # --- QUOTE ---
        $txtLog.SelectionFont = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Italic)
        $txtLog.SelectionColor = $colQuote
        $txtLog.AppendText("`"May all your pulls be gold...`nand your 50/50s never lost.`"`n`n`n")

        # --- FOOTER ---
        $txtLog.SelectionFont = New-Object System.Drawing.Font("Consolas", 8, [System.Drawing.FontStyle]::Regular)
        $txtLog.SelectionColor = $colFooter
        $txtLog.AppendText("Powered by PowerShell & .NET WinForms`n")
        $txtLog.AppendText("Data Source: Official Game Cache API`n")
        
        # 3. คืนค่า
        $txtLog.SelectionAlignment = "Left"
        $txtLog.SelectionStart = 0 
    })
    # ---------------------------------------------------------
    # MENU: CHECK UPDATE / VERSION STATUS (NEW WINDOW)
    # ---------------------------------------------------------
    $itemUpdate = New-Object System.Windows.Forms.ToolStripMenuItem("Check for Updates")
    [void]$menuHelp.DropDownItems.Add($itemUpdate)
    $itemUpdate.Add_Click({
        # 1. Setup Form
        $fUpd = New-Object System.Windows.Forms.Form
        $fUpd.Text = "System Status"
        $fUpd.Size = New-Object System.Drawing.Size(350, 450)
        $fUpd.StartPosition = "CenterParent"
        $fUpd.FormBorderStyle = "FixedToolWindow" # ไม่มีปุ่มย่อขยาย
        $fUpd.BackColor = [System.Drawing.Color]::FromArgb(25, 25, 30)
        $fUpd.ForeColor = "White"

        # Helper: จัดกึ่งกลางอัตโนมัติ (จะได้ไม่ต้องคำนวณ X เอง)
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
        $lblAppVer.ForeColor = [System.Drawing.Color]::SpringGreen # สีเขียวเด่นๆ
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
        $lblEngVer.ForeColor = [System.Drawing.Color]::Gold # สีทอง
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
        
        # Event: เปิดเว็บ
        $btnGit.Add_Click({
            [System.Diagnostics.Process]::Start("https://github.com/Phunyawee/HOYO_GACHA_COUNTER")
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

        # จัดกึ่งกลางทุกอย่างก่อนโชว์
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
