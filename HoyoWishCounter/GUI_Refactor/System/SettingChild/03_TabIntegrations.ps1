# =============================================================================
# FILE: SettingChild\03_TabIntegrations.ps1
# DESCRIPTION: ตั้งค่าการเชื่อมต่อภายนอก (Discord Webhook, Email Notification, SMTP)
# =============================================================================

$script:tDis = New-Tab "Integrations"
$script:tDis.AutoScroll = $true 

# -----------------------------------------------------------
# Section 1: Discord Webhook
# -----------------------------------------------------------
$grpDisc = New-Object System.Windows.Forms.GroupBox
$grpDisc.Text = " Discord Webhook "
$grpDisc.Location = "15, 15"
$grpDisc.Size = "500, 100"
$grpDisc.ForeColor = "Silver"
$script:tDis.Controls.Add($grpDisc)

$lblUrl = New-Object System.Windows.Forms.Label
$lblUrl.Text = "Webhook URL:"
$lblUrl.Location = "20, 25"
$lblUrl.AutoSize = $true
$lblUrl.ForeColor = "White"
$grpDisc.Controls.Add($lblUrl)

$script:txtWebhook = New-Object System.Windows.Forms.TextBox
$script:txtWebhook.Location = "20, 45"
$script:txtWebhook.Width = 460
$script:txtWebhook.BackColor = [System.Drawing.Color]::FromArgb(60,60,60)
$script:txtWebhook.ForeColor = "Cyan"
$script:txtWebhook.BorderStyle = "FixedSingle"
$script:txtWebhook.Text = $conf.WebhookUrl
$grpDisc.Controls.Add($script:txtWebhook)

$script:chkAutoSend = New-Object System.Windows.Forms.CheckBox
$script:chkAutoSend.Text = "Auto-Send Report to Discord"
$script:chkAutoSend.Location = "20, 75"
$script:chkAutoSend.AutoSize = $true
$script:chkAutoSend.ForeColor = "White"
$script:chkAutoSend.Checked = $conf.AutoSendDiscord
$grpDisc.Controls.Add($script:chkAutoSend)


# -----------------------------------------------------------
# Section 2: Email Recipient
# -----------------------------------------------------------
$grpMail = New-Object System.Windows.Forms.GroupBox
$grpMail.Text = " Email Notification (To) "
$grpMail.Location = "15, 125"
$grpMail.Size = "500, 80"
$grpMail.ForeColor = "Silver"
$script:tDis.Controls.Add($grpMail)

$lblMail = New-Object System.Windows.Forms.Label
$lblMail.Text = "Receiver Email:"
$lblMail.Location = "20, 25"
$lblMail.AutoSize = $true
$lblMail.ForeColor = "White"
$grpMail.Controls.Add($lblMail)

$script:txtEmail = New-Object System.Windows.Forms.TextBox
$script:txtEmail.Location = "20, 45"
$script:txtEmail.Width = 300
$script:txtEmail.BackColor = [System.Drawing.Color]::FromArgb(60,60,60)
$script:txtEmail.ForeColor = "Yellow"
$script:txtEmail.BorderStyle = "FixedSingle"

if ($conf.PSObject.Properties["NotificationEmail"]) { 
    $script:txtEmail.Text = $conf.NotificationEmail 
}
$grpMail.Controls.Add($script:txtEmail)

$script:chkAutoEmail = New-Object System.Windows.Forms.CheckBox
$script:chkAutoEmail.Text = "Auto-Send"
$script:chkAutoEmail.Location = "340, 45" # ปรับตำแหน่งให้ตรงกับช่องกรอก
$script:chkAutoEmail.AutoSize = $true
$script:chkAutoEmail.ForeColor = "White"

if ($conf.PSObject.Properties["AutoSendEmail"]) { 
    $script:chkAutoEmail.Checked = $conf.AutoSendEmail 
}
$grpMail.Controls.Add($script:chkAutoEmail)


# -----------------------------------------------------------
# Section 3: SMTP Sender Config (Advanced)
# -----------------------------------------------------------
$grpSmtp = New-Object System.Windows.Forms.GroupBox
$grpSmtp.Text = " SMTP Sender Config (Advanced) "
$grpSmtp.Location = "15, 215"
$grpSmtp.Size = "500, 160"
$grpSmtp.ForeColor = "Orange"
$script:tDis.Controls.Add($grpSmtp)

# [Host]
$lblSmtpHost = New-Object System.Windows.Forms.Label
$lblSmtpHost.Text = "SMTP Host (e.g. smtp.gmail.com):"
$lblSmtpHost.Location = "20, 25"
$lblSmtpHost.AutoSize = $true
$grpSmtp.Controls.Add($lblSmtpHost)

$script:txtSmtpHost = New-Object System.Windows.Forms.TextBox
$script:txtSmtpHost.Location = "20, 45"
$script:txtSmtpHost.Width = 300
$script:txtSmtpHost.BackColor = [System.Drawing.Color]::FromArgb(50,50,50)
$script:txtSmtpHost.ForeColor = "White"
$script:txtSmtpHost.BorderStyle = "FixedSingle"
if ($conf.PSObject.Properties["SmtpServer"]) { $script:txtSmtpHost.Text = $conf.SmtpServer } else { $script:txtSmtpHost.Text = "smtp.gmail.com" }
$grpSmtp.Controls.Add($script:txtSmtpHost)

# [Port]
$lblPort = New-Object System.Windows.Forms.Label
$lblPort.Text = "Port:"
$lblPort.Location = "340, 25"
$lblPort.AutoSize = $true
$grpSmtp.Controls.Add($lblPort)

$script:txtPort = New-Object System.Windows.Forms.TextBox
$script:txtPort.Location = "340, 45"
$script:txtPort.Width = 60
$script:txtPort.BackColor = [System.Drawing.Color]::FromArgb(50,50,50)
$script:txtPort.ForeColor = "White"
$script:txtPort.BorderStyle = "FixedSingle"
if ($conf.PSObject.Properties["SmtpPort"]) { $script:txtPort.Text = $conf.SmtpPort } else { $script:txtPort.Text = "587" }
$grpSmtp.Controls.Add($script:txtPort)

# [Sender Email]
$lblSender = New-Object System.Windows.Forms.Label
$lblSender.Text = "Sender Email (Bot):"
$lblSender.Location = "20, 80"
$lblSender.AutoSize = $true
$grpSmtp.Controls.Add($lblSender)

$script:txtSender = New-Object System.Windows.Forms.TextBox
$script:txtSender.Location = "20, 100"
$script:txtSender.Width = 220
$script:txtSender.BackColor = [System.Drawing.Color]::FromArgb(50,50,50)
$script:txtSender.ForeColor = "White"
$script:txtSender.BorderStyle = "FixedSingle"
if ($conf.PSObject.Properties["SenderEmail"]) { $script:txtSender.Text = $conf.SenderEmail }
$grpSmtp.Controls.Add($script:txtSender)

# [App Password]
$lblPass = New-Object System.Windows.Forms.Label
$lblPass.Text = "App Password:"
$lblPass.Location = "260, 80"
$lblPass.AutoSize = $true
$grpSmtp.Controls.Add($lblPass)

# [FIXED] ลดความกว้างช่อง Password ลง เพื่อให้มีที่เหลือใส่ปุ่ม Show
$script:txtPass = New-Object System.Windows.Forms.TextBox
$script:txtPass.Location = "260, 100"
$script:txtPass.Width = 165  # ลดจาก 200 เหลือ 165
$script:txtPass.BackColor = [System.Drawing.Color]::FromArgb(50,50,50)
$script:txtPass.ForeColor = "White"
$script:txtPass.BorderStyle = "FixedSingle"
$script:txtPass.UseSystemPasswordChar = $true

if ($conf.PSObject.Properties["SenderPassword"]) { 
    $script:txtPass.Text = $conf.SenderPassword 
}
$grpSmtp.Controls.Add($script:txtPass)

# [FIXED] ขยับ Checkbox เข้ามาซ้ายสุดเท่าที่ทำได้ (เริ่มที่ 435)
$chkShowPass = New-Object System.Windows.Forms.CheckBox
$chkShowPass.Text = "Show"
$chkShowPass.Location = "435, 100" # ขยับจาก 470 มา 435
$chkShowPass.AutoSize = $true
$chkShowPass.ForeColor = "DimGray"
$chkShowPass.Add_CheckedChanged({ 
    $script:txtPass.UseSystemPasswordChar = -not $chkShowPass.Checked 
})
$grpSmtp.Controls.Add($chkShowPass)