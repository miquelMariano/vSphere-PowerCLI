wmiQuery = "SELECT * FROM Win32_PerfFormattedData_PerfOS_Processor WHERE Name='_Total'"

set objWMIService = GetObject("winmgmts:\\127.0.0.1\root\cimv2")


Set colitems = objWMIService.ExecQuery(wmiQuery)

for each objitem in colitems
	WScript.echo objItem.Interruptspersec&":OK"
next