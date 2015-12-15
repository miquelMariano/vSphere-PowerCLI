set-variable -name HORCM_CONF -value C:\HORCM\etc\horcm55.conf 
set-variable -name HORCMINST -value 55

c:\horcm\etc\horcmstart.exe > $NULL

$perf_tier1 = (c:\horcm\etc\raidcom.exe get dp_pool -key opt | select -index 1).split(" ")
$perf_tier2 = (c:\horcm\etc\raidcom.exe get dp_pool -key opt | select -index 2).split(" ")
$perf_tier3 = (c:\horcm\etc\raidcom.exe get dp_pool -key opt | select -index 3).split(" ")

$out_perfTier1 = $perf_tier1[42]
$out_perfTier2 = $perf_tier2[42]
$out_perfTier3 = $perf_tier3[42]

c:\horcm\etc\horcmshutdown.exe  > $NULL

$XMLOutput = "<prtg>`n"

$XMLOutput += "<text>Performance tiers HUS-VM</text>`n"

$XMLOutput += "<result>`n"
$XMLOutput += "<channel> TIER1 </channel> `n"
$XMLOutput += "<value>$out_perfTier1</value>`n"
$XMLOutput += "</result>`n"

$XMLOutput += "<result>`n"
$XMLOutput += "<channel> TIER2 </channel> `n"
$XMLOutput += "<value>$out_perfTier2</value>`n"
$XMLOutput += "</result>`n"

$XMLOutput += "<result>`n"
$XMLOutput += "<channel> TIER3 </channel> `n"
$XMLOutput += "<value>$out_perfTier3</value>`n"
$XMLOutput += "</result>`n"

$XMLOutput += "</prtg>"

write-host $XMLOutput




