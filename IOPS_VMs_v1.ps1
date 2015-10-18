<# 
.DESCRIPTION
   Script para listar las VMs con sus IOPS de W/R a disco
   Adaptación de http://www.lucd.info/2011/04/22/get-the-maximum-iops/

.NOTES 
   File Name  : IOPS_VMs_v1.ps1 
   Author     : Miquel Mariano - @miquelMariano
   Version    : 1

.USAGE
	Ejecutar directamente 
   
.CHANGELOG
   v1	18/10/2015	Creación del script
   
#>

#Verificamos si tenemos instalado PowerCLI
if (-not (Get-PSSnapin VMware.VimAutomation.Core -ErrorAction SilentlyContinue))
{   Try { Add-PSSnapin VMware.VimAutomation.Core -ErrorAction Stop }
    Catch { Write-Host "Unable to load PowerCLI, is it installed?" -ForegroundColor Red; Exit }
}

#--------------VARIABLES GLOBALES---------
$now= get-date -uformat "%d%m%Y-%H%M"
$vCenter = "vcenter.logitravelzone.local"
$vCenteruser ="administrator@vsphere.local"
$PathToCredentials = "."
#--------------VARIABLES GLOBALES---------


#--------------ENCRIPTAR CREDENCIALES---------
#You must change these values to securely save your credential files
$Key = [byte]29,36,18,22,72,33,85,52,73,44,14,21,98,76,18,28

Function Get-Credentials {
    Param (
	    [String]$AuthUser = $env:USERNAME,
        [string]$PathToCred
    )

    #Build the path to the credential file
    $Cred_File = $AuthUser.Replace("\","~")
    $File = $PathToCred + "\Credentials-$Cred_File.crd"
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
#--------------ENCRIPTAR CREDENCIALES---------

$Cred = Get-Credentials $vCenterUser $PathToCredentials
Connect-VIServer $vCenter -Credential $Cred -ErrorAction Stop | Out-Null

$metrics = "disk.numberwrite.summation","disk.numberread.summation"
$start = (Get-Date).AddMinutes(-5)
$report = @()
 
$vms = Get-VM | where {$_.PowerState -eq "PoweredOn"}
$stats = Get-Stat -Realtime -Stat $metrics -Entity $vms -Start $start
$interval = $stats[0].IntervalSecs
 
$lunTab = @{}
foreach($ds in (Get-Datastore -VM $vms | where {$_.Type -eq "VMFS"})){
  $ds.ExtensionData.Info.Vmfs.Extent | %{
    $lunTab[$_.DiskName] = $ds.Name
  }
}
 
$report = $stats | Group-Object -Property {$_.Entity.Name},Instance | %{
  New-Object PSObject -Property @{
	VM = $_.Values[0]
    Disk = $_.Values[1]
    IOPSWriteAvg = ($_.Group | `
      where{$_.MetricId -eq "disk.numberwrite.summation"} | `
      Measure-Object -Property Value -Average).Average / $interval
    IOPSReadAvg = ($_.Group | `
      where{$_.MetricId -eq "disk.numberread.summation"} | `
      Measure-Object -Property Value -Average).Average / $interval
    Datastore = $lunTab[$_.Values[1]]
  }
}

Disconnect-VIServer $vCenter -Confirm:$false

$csvfile = "IOPS-VMs_"+$now+".csv"

$report | sort-object IOPSWriteAvg | select-object VM, Disk, Datastore, IOPSWriteAvg, IOPSReadAVG | Export-Csv $csvfile
$report | sort-object IOPSWriteAvg | select-object VM, Disk, Datastore, IOPSWriteAvg, IOPSReadAVG | ft -autosize
#$report | sort-object IOPSWriteAvg | select-object VM, Disk, Datastore, IOPSWriteAvg, IOPSReadAVG | out-gridview
