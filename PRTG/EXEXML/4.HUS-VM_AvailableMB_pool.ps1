$random = Get-Random -maximum 100
	 
set-variable -name HORCM_CONF -value C:\HORCM\etc\horcm55.conf 
set-variable -name HORCMINST -value $random

c:\horcm\etc\horcmstart.exe > $NULL

$availableMB = (c:\horcm\etc\raidcom.exe get pool | select -index 1).split(" ")

$out_availableMB = $availableMB[13]

c:\horcm\etc\horcmshutdown.exe  > $NULL

$XMLOutput = "<prtg>`n"

$XMLOutput += "<text>HUS-VM AvailableMB pool</text>`n"

$XMLOutput += "<result>`n"
$XMLOutput += "<channel> Pool00 </channel> `n"
$XMLOutput += "<value>$out_availableMB</value>`n"
$XMLOutput += "</result>`n"

$XMLOutput += "</prtg>"

write-host $XMLOutput
