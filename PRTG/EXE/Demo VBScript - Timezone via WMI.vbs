' Uses Win32_TimeZone to determine the current bias for local time translation. 
' The bias is the difference between Coordinated Universal Time (UTC) and local time. 
' All translations between UTC and local time are based on the following formula: UTC = local time REM - bias. 

strComputer = "127.0.0.1"

' Leave User and Password blank for local machine

strUser = ""
strPassword = ""

strNamespace = "root/cimv2"

Set objLocator = CreateObject("WbemScripting.SWbemLocator")
Set objWMIService = objLocator.ConnectServer(strComputer,strNamespace,strUser,strPassword)
Set objTimeZone = objWMIService.ExecQuery ("SELECT * FROM Win32_TimeZone")

For Each colTimeZone in objTimeZone
  strBias = colTimeZone.Bias
  strStandardname = colTimeZone.Standardname
Next

wscript.echo strBias & ":" & strStandardname
wscript.quit("0")


