$horcmgr = get-process -processname horcmgr* | measure-object 
$horcmstart = get-process -processname horcmstart* | measure-object
$horcmshutdown = get-process -processname horcmshutdown* | measure-object

[int]$a = [convert]::toint32($horcmgr.count)
[int]$b = [convert]::toint32($horcmstart.count)
[int]$c = [convert]::toint32($horcmshutdown.count)

$XMLOutput = "<prtg>`n"

$XMLOutput += "<text>HORCM Stadistics</text>`n"

$XMLOutput += "<result>`n"
$XMLOutput += "<channel>horcmgr</channel> `n"
$XMLOutput += "<value>$a</value>`n"
$XMLOutput += "</result>`n"

$XMLOutput += "<result>`n"
$XMLOutput += "<channel>horcmstart</channel> `n"
$XMLOutput += "<value>$b</value>`n"
$XMLOutput += "</result>`n"

$XMLOutput += "<result>`n"
$XMLOutput += "<channel>horcmshutdown</channel> `n"
$XMLOutput += "<value>$c</value>`n"
$XMLOutput += "</result>`n"

$XMLOutput += "</prtg>"

write-host $XMLOutput



