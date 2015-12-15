$random = Get-Random -maximum 100
	 
set-variable -name HORCMINST -value $random

c:\horcm\etc\horcmstart.exe > $NULL

#Añadimos toda la linea de la salida del comando a la variable
$string_tier1 = c:\horcm\etc\raidcom.exe get dp_pool -key opt | select -index 1
$string_tier2 = c:\horcm\etc\raidcom.exe get dp_pool -key opt | select -index 2
$string_tier3 = c:\horcm\etc\raidcom.exe get dp_pool -key opt | select -index 3

#Quitamos todos los espacios dobles por un solo espacio
$tier1=$string_tier1 -replace '\s+',' '
$tier2=$string_tier2 -replace '\s+',' '
$tier3=$string_tier3 -replace '\s+',' '

#Ordenamos cada valor separado por un espacio en una columna y seleccionamos la fila que nos interese
$perf_tier1 = $tier1.split(" ")
$perf_tier2 = $tier2.split(" ")
$perf_tier3 = $tier3.split(" ")


$out_perfTier1 = $perf_tier1[11]
$out_perfTier2 = $perf_tier2[11]
$out_perfTier3 = $perf_tier3[11]

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




