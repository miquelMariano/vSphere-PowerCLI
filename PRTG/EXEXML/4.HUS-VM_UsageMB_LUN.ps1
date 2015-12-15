param (
    [string]$ldev = "Ningun LDEV introducido por parametro"
     )

	 
$random = Get-Random -maximum 100
	 
set-variable -name HORCM_CONF -value C:\HORCM\etc\horcm55.conf 
set-variable -name HORCMINST -value $random

c:\horcm\etc\horcmstart.exe > $NULL

$ldev_name = (c:\horcm\etc\raidcom.exe get ldev -ldev_id $ldev | select -index 11).split(" ")
$tier1 = (c:\horcm\etc\raidcom.exe get ldev -ldev_id $ldev | select -index 20).split(" ")
$tier2 = (c:\horcm\etc\raidcom.exe get ldev -ldev_id $ldev | select -index 21).split(" ")
$tier3 = (c:\horcm\etc\raidcom.exe get ldev -ldev_id $ldev | select -index 22).split(" ")

$out_ldev_name = $ldev_name[2]
$out_tier1 = $tier1[2]
$out_tier2 = $tier2[2]
$out_tier3 = $tier3[2]

c:\horcm\etc\horcmshutdown.exe  > $NULL

$XMLOutput = "<prtg>`n"

$XMLOutput += "<text>$ldev $out_ldev_name</text>`n"

$XMLOutput += "<result>`n"
$XMLOutput += "<channel> TIER1(MB) </channel> `n"
$XMLOutput += "<value>$out_tier1</value>`n"
$XMLOutput += "</result>`n"

$XMLOutput += "<result>`n"
$XMLOutput += "<channel> TIER2(MB) </channel> `n"
$XMLOutput += "<value>$out_tier2</value>`n"
$XMLOutput += "</result>`n"

$XMLOutput += "<result>`n"
$XMLOutput += "<channel> TIER3(MB) </channel> `n"
$XMLOutput += "<value>$out_tier3</value>`n"
$XMLOutput += "</result>`n"

$XMLOutput += "</prtg>"

write-host $XMLOutput



