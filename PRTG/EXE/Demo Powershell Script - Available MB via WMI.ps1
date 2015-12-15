$colItems = get-wmiobject -class "Win32_PerfFormattedData_PerfOS_Memory" -namespace "root\cimv2" -computername "127.0.0.1" | Select-Object name,AvailableMBytes 

foreach ($objItem in $colItems) {
	
	write-host $objItem.AvailableMBytes,":OK" 
}

