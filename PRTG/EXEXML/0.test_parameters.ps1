
param (
    [string]$lun = "test"
     )


$XMLOutput = "<prtg>`n"

$XMLOutput += "<text>$lun</text>`n"

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