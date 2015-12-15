$random = Get-Random -maximum 100
	 
set-variable -name HORCMINST -value $random

c:\horcm\etc\horcmstart.exe > $NULL

#Añadimos toda la linea de la salida del comando a la variable
$string_stadistics = c:\horcm\etc\raidcom.exe get pool | select -index 1

#Quitamos todos los espacios dobles por un solo espacio
$stadistics=$string_stadistics -replace '\s+',' '

#Ordenamos cada valor separado por un espacio en una columna y seleccionamos la fila que nos interese
$usage=$stadistics.split(" ")

$usageMB=$usage[4] #AvailableMB
$usagePercent=100 - $usage[2] #UsagePercent

c:\horcm\etc\horcmshutdown.exe  > $NULL

$XMLOutput = "<prtg>`n"

$XMLOutput += "<text>Usage Pool Stadistics</text>`n"

$XMLOutput += "<result>`n"
$XMLOutput += "<channel> Free MB </channel> `n"
$XMLOutput += "<value>$usageMB</value>`n"
$XMLOutput += "</result>`n"

$XMLOutput += "<result>`n"
$XMLOutput += "<channel> Free % </channel> `n"
$XMLOutput += "<value>$usagePercent</value>`n"
$XMLOutput += "</result>`n"

$XMLOutput += "</prtg>"

write-host $XMLOutput