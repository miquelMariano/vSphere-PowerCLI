strComputer = "."

Set objWMIService = GetObject("winmgmts:" _
    & "{impersonationLevel=impersonate}!\\" _
    & strComputer & "\root\cimv2")

Set colItems = objWMIService.ExecQuery( _
    "Select * from Win32_Process WHERE name ='svchost.exe'")

Wscript.Echo colItems.Count&":Ok" 

