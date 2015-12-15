Dim objNet
Set objNet = CreateObject("WScript.NetWork") 
	
WScript.echo "0:" & objNet.ComputerName & "\" & objNet.UserName
	
Set objNet = Nothing  