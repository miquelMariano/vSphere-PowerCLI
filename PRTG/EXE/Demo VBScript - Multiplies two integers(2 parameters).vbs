Dim ArgObj, arg1,arg2, i
Set ArgObj = WScript.Arguments 
arg1 = ArgObj(0) 
arg2 = ArgObj(1) 

i = arg1 * arg2

WScript.echo i&":OK"