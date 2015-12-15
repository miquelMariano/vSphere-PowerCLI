param (
    [string]$datastore = "datastore"
     )

#Verificamos si tenemos instalado PowerCLI
if (-not (Get-PSSnapin VMware.VimAutomation.Core -ErrorAction SilentlyContinue))
{   Try { Add-PSSnapin VMware.VimAutomation.Core -ErrorAction Stop }
    Catch { Write-Host "Unable to load PowerCLI, is it installed?" -ForegroundColor Red; Exit }
}

$vCenter = "vcenter2014.casatarradellas.local"
$vCenteruser ="administrator@vsphere.local"

#You must change these values to securely save your credential files
$Key = [byte]29,36,18,22,72,33,85,52,73,44,14,21,98,76,18,28


Function Get-Credentials {
    Param (
	    [String]$AuthUser = $env:USERNAME,
        [string]$PathToCred
    )

    #Build the path to the credential file
    $Cred_File = $AuthUser.Replace("\","~")
    $File = $PathToCred + "C:\Creds_PRTG_PowerCLI\Credentials-$Cred_File.crd"
	#And find out if it's there, if not create it
    If (-not (Test-Path $File))
	{	(Get-Credential $AuthUser).Password | ConvertFrom-SecureString -Key $Key | Set-Content $File
    }
	#Load the credential file 
    $Password = Get-Content $File | ConvertTo-SecureString -Key $Key
    $AuthUser = (Split-Path $File -Leaf).Substring(12).Replace("~","\")
    $AuthUser = $AuthUser.Substring(0,$AuthUser.Length - 4)
	$Credential = New-Object System.Management.Automation.PsCredential($AuthUser,$Password)
    Return $Credential
}



$Cred = Get-Credentials $vCenterUser $PathToCredentials

Connect-VIServer $vCenter -Credential $Cred -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null
#-----------------------------------------------------------------------------------------------------------------------------

$query = Get-View -ViewType Datastore | Where-Object {$_.Name -match $datastore} | Select-Object -Property Name, 
  @{N="CapacityGB"; E={[Math]::Round($_.Summary.Capacity/1GB,0)}}, 
  @{N="FreeSpaceGB";E={[Math]::Round($_.Summary.FreeSpace/1GB,0)}},
  @{N="ProvisionedSpaceGB";E={[Math]::Round(($_.Summary.Capacity - $_.Summary.FreeSpace + $_.Summary.Uncommitted)/1GB,0)}},
  @{N="FreeSpace";E={[math]::Round(((100* ($_.Summary.FreeSpace/1GB))/ ($_.Summary.Capacity/1GB)),0)}}
  
$title = $query.name
$CapacityGB = $query.CapacityGB
$FreeSpaceGB = $query.FreeSpaceGB
$ProvisionedSpaceGB = $query.ProvisionedSpaceGB
$FreeSpace = $query.FreeSpace
$ProvisionedSpace =[math]::Round(100 * (($query.ProvisionedSpaceGB) / ($query.CapacityGB)))

$XMLOutput = "<prtg>`n"

$XMLOutput += "<text>$title</text>`n"

$XMLOutput += "<result>`n"
$XMLOutput += "<channel>CapacityGB</channel> `n"
$XMLOutput += "<value>$CapacityGB</value>`n"
$XMLOutput += "</result>`n"

$XMLOutput += "<result>`n"
$XMLOutput += "<channel>FreeSpaceGB</channel> `n"
$XMLOutput += "<value>$FreeSpaceGB</value>`n"
$XMLOutput += "</result>`n"

$XMLOutput += "<result>`n"
$XMLOutput += "<channel>ProvisionedSpace</channel> `n"
$XMLOutput += "<value>$ProvisionedSpace</value>`n"
$XMLOutput += "</result>`n"

$XMLOutput += "<result>`n"
$XMLOutput += "<channel>ProvisionedSpaceGB</channel> `n"
$XMLOutput += "<value>$ProvisionedSpaceGB</value>`n"
$XMLOutput += "</result>`n"

$XMLOutput += "<result>`n"
$XMLOutput += "<channel>FreeSpace</channel> `n"
$XMLOutput += "<value>$FreeSpace</value>`n"
$XMLOutput += "</result>`n"



$XMLOutput += "</prtg>"

write-host $XMLOutput