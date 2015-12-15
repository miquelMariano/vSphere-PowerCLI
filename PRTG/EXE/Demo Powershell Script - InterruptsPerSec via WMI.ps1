$colItems = get-wmiobject -class "Win32_PerfFormattedData_PerfOS_Processor" -namespace "root\cimv2" -computername "127.0.0.1" | Select-Object name,InterruptsPerSec 

foreach ($objItem in $colItems) {
	
	if ($objItem.Name -eq "_Total") 
	   {write-host $objItem.InterruptsPerSec,":OK"}
}

