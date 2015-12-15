strComputer = "127.0.0.1"

REM Leave User and Password blank for local machine

strUser = ""
strPassword = ""

strNamespace = "root/cimv2"

Set objLocator = CreateObject("WbemScripting.SWbemLocator")
Set objWMIService = objLocator.ConnectServer(strComputer,strNamespace,strUser,strPassword)
Set colItems = objWMIService.ExecQuery("Select * from Win32_Process WHERE name ='svchost.exe'")


if colItems.Count < 3 then
  wscript.echo colItems.Count&":Ok"
  wscript.quit("0")
Else
  wscript.echo colItems.Count&":Too many processes"
  
  REM This sets the sensor into "Warning" State
  wscript.quit("1")
End if