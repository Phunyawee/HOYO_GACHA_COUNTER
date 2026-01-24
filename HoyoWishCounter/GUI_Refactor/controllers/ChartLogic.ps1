# controllers/ChartLogic.ps1

function Start-AdvancedSaveImage {
    WriteGUI-Log "User clicked [Save Image] button." "Magenta"
    
    # 1. เช็คก่อนว่ามีกราฟให้เซฟไหม
    # (เข้าถึง $chart ผ่าน Scope Global เพราะ Dot-Source มา)
    if (-not $chart.Visible) { 
        [System.Windows.Forms.MessageBox]::Show("No graph to save!", "Error", 0, 16)
        return 
    }

    # ใช้ตัวแปรเก็บนอก Loop (จำค่าชื่อ/UID ไว้)
    $memName = ""
    $memUID = ""
    $loop = $true 

    while ($loop) {
        # ==========================================
        # STEP 1: INPUT POPUP
        # ==========================================
        $inputForm = New-Object System.Windows.Forms.Form
        $inputForm.Text = "Add Watermark"
        $inputForm.Size = New-Object System.Drawing.Size(350, 180)
        $inputForm.StartPosition = "CenterParent"
        $inputForm.FormBorderStyle = "FixedDialog"
        $inputForm.MaximizeBox = $false; $inputForm.MinimizeBox = $false
        $inputForm.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40); $inputForm.ForeColor = "White"

        $lbl1 = New-Object System.Windows.Forms.Label; $lbl1.Text = "Player Name:"; $lbl1.Location = "20,20"; $lbl1.AutoSize=$true
        $txtName = New-Object System.Windows.Forms.TextBox; $txtName.Location = "120,18"; $txtName.Width = 180; $txtName.BackColor="60,60,60"; $txtName.ForeColor="Cyan"
        
        $txtName.Text = $memName # ดึงค่าเดิม

        $lbl2 = New-Object System.Windows.Forms.Label; $lbl2.Text = "UID (Game):"; $lbl2.Location = "20,55"; $lbl2.AutoSize=$true
        $txtUID = New-Object System.Windows.Forms.TextBox; $txtUID.Location = "120,53"; $txtUID.Width = 180; $txtUID.BackColor="60,60,60"; $txtUID.ForeColor="Gold"
        
        $txtUID.Text = $memUID # ดึงค่าเดิม

        $btnOK = New-Object System.Windows.Forms.Button; $btnOK.Text = "Preview >"; $btnOK.DialogResult = "OK"; $btnOK.Location = "130,100"; $btnOK.BackColor="RoyalBlue"; $btnOK.ForeColor="White"; $btnOK.FlatStyle="Flat"
        $btnCancel = New-Object System.Windows.Forms.Button; $btnCancel.Text = "Close"; $btnCancel.DialogResult = "Cancel"; $btnCancel.Location = "220,100"; $btnCancel.BackColor="DimGray"; $btnCancel.ForeColor="White"; $btnCancel.FlatStyle="Flat"

        $inputForm.Controls.AddRange(@($lbl1, $txtName, $lbl2, $txtUID, $btnOK, $btnCancel))
        $inputForm.AcceptButton = $btnOK

        # ถ้ากด Cancel -> ออกเลย
        if ($inputForm.ShowDialog() -ne "OK") { 
            $loop = $false 
            $inputForm.Dispose()
            break 
        }
        
        $memName = $txtName.Text.Trim()
        $memUID  = $txtUID.Text.Trim()
        $inputForm.Dispose()

        # ==========================================
        # STEP 2: GENERATE BITMAP & DRAWING
        # ==========================================
        try {
            $footerHeight = 70
            $finalWidth = $chart.Width
            $finalHeight = $chart.Height + $footerHeight
            
            $previewBmp = New-Object System.Drawing.Bitmap($finalWidth, $finalHeight)
            $g = [System.Drawing.Graphics]::FromImage($previewBmp)
            $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias
            $g.Clear([System.Drawing.Color]::FromArgb(25,25,25)) 

            # วาด Chart ลงไป
            $chartBmp = New-Object System.Drawing.Bitmap($chart.Width, $chart.Height)
            $chart.DrawToBitmap($chartBmp, $chart.ClientRectangle)
            $g.DrawImage($chartBmp, 0, 0)
            $chartBmp.Dispose()

            # วาด Footer พื้นหลัง & เส้น
            $footerRect = New-Object System.Drawing.Rectangle(0, $chart.Height, $finalWidth, $footerHeight)
            $brushFooter = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(40,40,40))
            $g.FillRectangle($brushFooter, $footerRect)
            $penLine = New-Object System.Drawing.Pen([System.Drawing.Color]::Gold, 2)
            $g.DrawLine($penLine, 0, $chart.Height, $finalWidth, $chart.Height)

            # วาด Logo Text (ซ้าย)
            $fontBrand = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
            $brandText = "Universal Hoyo Wish Counter"
            $g.DrawString($brandText, $fontBrand, [System.Drawing.Brushes]::Gray, 20, ($chart.Height + 22))
            
            # คำนวณพื้นที่ (Text Trimming)
            $brandSize = $g.MeasureString($brandText, $fontBrand)
            $safeZoneLeft = 20 + $brandSize.Width + 30 
            
            $fontInfo = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
            $fontDate = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Regular)
            
            $rawName = if ($memName -ne "") { "Player: $memName" } else { "Player: Traveler" }
            $rawUID  = if ($memUID -ne "")  { "  |  UID: $memUID" } else { "" }
            
            $maxAvailableWidth = $finalWidth - 20 - $safeZoneLeft 
            $fullText = $rawName + $rawUID
            
            # ตัดคำถ้าชื่อยาวเกิน
            if ($g.MeasureString($fullText, $fontInfo).Width -gt $maxAvailableWidth) {
                $tempName = $memName
                while ($true) {
                    if ($tempName.Length -eq 0) { break }
                    $tempName = $tempName.Substring(0, $tempName.Length - 1)
                    $tryText = "Player: $tempName..." + $rawUID
                    if ($g.MeasureString($tryText, $fontInfo).Width -le $maxAvailableWidth) {
                        $fullText = $tryText; break
                    }
                }
            }
            
            $dateText = "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
            $formatRight = New-Object System.Drawing.StringFormat; $formatRight.Alignment = "Far"
            
            # วาดข้อความ Player Info (ขวา)
            $g.DrawString($fullText, $fontInfo, [System.Drawing.Brushes]::White, ($finalWidth - 20), ($chart.Height + 12), $formatRight)
            $g.DrawString($dateText, $fontDate, [System.Drawing.Brushes]::LightGray, ($finalWidth - 20), ($chart.Height + 38), $formatRight)
            $g.Dispose()

            # ==========================================
            # STEP 3: PREVIEW WINDOW UI
            # ==========================================
            $previewForm = New-Object System.Windows.Forms.Form
            $previewForm.Text = "Preview Image"
            $previewForm.Size = New-Object System.Drawing.Size(800, 600)
            $previewForm.StartPosition = "CenterParent"
            $previewForm.BackColor = [System.Drawing.Color]::FromArgb(30,30,30)

            $pnlBottom = New-Object System.Windows.Forms.Panel
            $pnlBottom.Dock = "Bottom"
            $pnlBottom.Height = 60
            $pnlBottom.BackColor = [System.Drawing.Color]::FromArgb(50,50,50)

            $picPreview = New-Object System.Windows.Forms.PictureBox
            $picPreview.Dock = "Fill"
            $picPreview.Image = $previewBmp
            $picPreview.SizeMode = "Zoom"
            $picPreview.BackColor = "Black"
            
            # ปุ่ม Confirm
            $btnConfirm = New-Object System.Windows.Forms.Button
            $btnConfirm.Text = "Confirm & Save"
            $btnConfirm.Size = New-Object System.Drawing.Size(140, 35)
            $btnConfirm.Anchor = "Top, Right" 
            $btnConfirm.Location = New-Object System.Drawing.Point(($pnlBottom.Width - 160), 12)
            # (ต้องมั่นใจว่า Apply-ButtonStyle เข้าถึงได้)
            if (Get-Command "Apply-ButtonStyle" -ErrorAction SilentlyContinue) {
                Apply-ButtonStyle -Button $btnConfirm -BaseColorName "ForestGreen" -HoverColorName "LimeGreen" -CustomFont $script:fontBold
            } else {
                $btnConfirm.BackColor = "Green"; $btnConfirm.ForeColor = "White"
            }
            
            # ปุ่ม Back
            $btnBack = New-Object System.Windows.Forms.Button
            $btnBack.Text = "< Back to Edit"
            $btnBack.Size = New-Object System.Drawing.Size(120, 35)
            $btnBack.Anchor = "Top, Right"
            $btnBack.Location = New-Object System.Drawing.Point(($pnlBottom.Width - 300), 12)
            if (Get-Command "Apply-ButtonStyle" -ErrorAction SilentlyContinue) {
                Apply-ButtonStyle -Button $btnBack -BaseColorName "DimGray" -HoverColorName "Gray" -CustomFont $script:fontBold
            } else {
                $btnBack.BackColor = "Gray"; $btnBack.ForeColor = "White"
            }

            $state = @{ Action = "None" }

            $btnConfirm.Add_Click({
                $sfd = New-Object System.Windows.Forms.SaveFileDialog
                $sfd.Filter = "PNG Image|*.png|JPEG Image|*.jpg"
                $gName = $script:CurrentGame
                $dateStr = Get-Date -Format 'yyyyMMdd_HHmm'
                $sfd.FileName = "${gName}_LuckChart_${dateStr}"

                if ($sfd.ShowDialog() -eq "OK") {
                    try {
                        $format = [System.Drawing.Imaging.ImageFormat]::Png
                        if ($sfd.FileName.EndsWith(".jpg") -or $sfd.FileName.EndsWith(".jpeg")) { 
                            $format = [System.Drawing.Imaging.ImageFormat]::Jpeg 
                        }
                        $previewBmp.Save($sfd.FileName, $format)
                        WriteGUI-Log "Image saved to: $($sfd.FileName)" "Lime"
                        [System.Windows.Forms.MessageBox]::Show("Saved!", "Success", 0, 64)
                        
                        $state.Action = "Save"
                        $previewForm.Close()
                    } catch {
                        [System.Windows.Forms.MessageBox]::Show("Error: $($_.Exception.Message)", "Error", 0, 16)
                    }
                }
            })

            $btnBack.Add_Click({
                $state.Action = "Back"
                $previewForm.Close()
            })

            $pnlBottom.Controls.Add($btnConfirm)
            $pnlBottom.Controls.Add($btnBack)
            $previewForm.Controls.Add($pnlBottom) 
            $previewForm.Controls.Add($picPreview)
            $pnlBottom.SendToBack()

            $previewForm.ShowDialog()
            
            $previewBmp.Dispose()
            $previewForm.Dispose()

            # Logic วนลูป
            if ($state.Action -eq "Save") {
                $loop = $false 
            } elseif ($state.Action -eq "Back") {
                WriteGUI-Log "User requested Back to Edit." "DimGray"
            } else {
                $loop = $false
            }

        } catch {
            WriteGUI-Log "Error: $($_.Exception.Message)" "Red"
            $loop = $false
        }
    } # End Loop
}