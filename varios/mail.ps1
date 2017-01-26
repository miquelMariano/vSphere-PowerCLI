
$From = "YourEmail@gmail.com"
$To = "miquel.mariano@ncora.com"
$Cc = "miquel.mariano0@gmail.com"
$Attachment = "C:\tmp\test.txt"
$Subject = "Email Subject"
$Body = "Insert body text here"
$SMTPServer = "smtp.gmail.com"
$SMTPPort = "587"

Send-MailMessage -From $From -to $To -Cc $Cc -Subject $Subject `
-Body $Body -SmtpServer $SMTPServer -port $SMTPPort -UseSsl `
-Credential (Get-Credential) -Attachments $Attachment

