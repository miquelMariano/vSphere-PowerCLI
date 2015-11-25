<# 
.DESCRIPTION
   Script que nos permite fijar los servidores Windows 2012 alojados en un clúster vSphere en un grupo determinado de ESXi
   y asi poder ajustar la compra de licencias Windows 2012 Datacenter

.NOTES 
   File Name  : Update_vSphereDRS_rule.ps1 
   Author     : Miquel Mariano - @miquelMariano
   Version    : 3
      
.CHANGELOG
   v1	27/02/2015	Creación del script
   v2	30/03/2015	Securizar script con function get-credential
   v3	25/11/2015	Adecuar para http://blog.ncora.com/
#>

#Verificamos si tenemos instalado PowerCLI
if (-not (Get-PSSnapin VMware.VimAutomation.Core -ErrorAction SilentlyContinue))
{   Try { Add-PSSnapin VMware.VimAutomation.Core -ErrorAction Stop }
    Catch { Write-Host "Unable to load PowerCLI, is it installed?" -ForegroundColor Red; Exit }
}

#--------------VARIABLES GLOBALES----------------------
$Date = get-date -uformat "%d/%m/%Y - %T"

$vCenter = "vcenter.ncora.local"
$vCenteruser ="scriptsuser"
$cluster1="FORMACION"
$Cluster1Rule="Srv_W2012"

$sendFrom = "vCenter@ncora.local"
$sendTo = "miquel.mariano@ncora.com"
$smtp = "172.29.106.36"

$PathToCredentials = "."


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



$Cred = Get-Credentials $vCenterUser $PathToCredentials

Connect-VIServer $vCenter -Credential $Cred -ErrorAction Stop | Out-Null

# Define the Update DRS rule function
#
function DRSrule {
param (
    $cluster,
    $VMs,
    $groupVMName)
    $cluster = Get-Cluster $cluster
    $spec = New-Object VMware.Vim.ClusterConfigSpecEx
    $groupVM = New-Object VMware.Vim.ClusterGroupSpec
    $groupVM.operation = "edit"
    $groupVM.Info = New-Object VMware.Vim.ClusterVmGroup
    $groupVM.Info.Name = $groupVMName
    Get-VM $VMs | %{
$groupVM.Info.VM += $_.Extensiondata.MoRef
                                 }
                                 $spec.GroupSpec += $groupVM
                                 #Apply the settings to the cluster
                                 $cluster.ExtensionData.ReconfigureComputeResource($spec,$true)
                             }
#————————————————————————————————————————————————————————————————————
# INICIO FILTRO SELECCIÓN DE VMs
# Filtramos todas las VM que las VMTools reporta un SO que contenta Server 2012*
# Es sumamente importante que todas las VM dispongan de las VMTools instaladas y actualizadas 
#————————————————————————————————————————————————————————————————————
#
$VMcluster1=Get-Cluster $cluster1 |Get-vm | where {($_.extensiondata.guest.Guestfullname  -like "*Server 2012*")}
$VMcluster1Count=(Get-Cluster $cluster1 |Get-vm | where {($_.extensiondata.guest.Guestfullname  -like "*Server 2012*")}).count
#
#————————————————————————————————————————————————————————————————————
# FIN FILTRO SELECCIÓN DE VMs
#————————————————————————————————————————————————————————————————————
#
# Actualizamos las reglas DRS 
DRSrule -cluster $cluster1 -VMs $VMcluster1 -groupVMName $Cluster1Rule
#
#
#————————————————————————————————————————————————————————————————————
# Generamos un correo informativo sobre las VMs que se han incluido en las reglas DRS
#————————————————————————————————————————————————————————————————————
# 
$VMbody1=$VMcluster1 | select -ExpandProperty name | out-string
$s1 = "El Virtual Machine DRS Group $Cluster1Rule ubicado en el vSphere Cluster $Cluster1 contiene $VMcluster1Count VM:`n `n"
$s1 += "$VMbody1`n`n"
$s1 += "Report date: $date`n`n"
#
send-mailmessage -to $sendTo -from $sendFrom -Subject "DRS rule report: $VMcluster1Count VMs" -smtpserver $smtp -body $s1
#
#————————————————————————————————————————————————————————————————————
# Generamos un correo informativo sobre las VMs que se han incluido en las reglas DRS
#————————————————————————————————————————————————————————————————————

Disconnect-VIServer $vCenter -Confirm:$False
