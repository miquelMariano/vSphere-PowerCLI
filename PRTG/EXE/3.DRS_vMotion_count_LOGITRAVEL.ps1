#Verificamos si tenemos instalado PowerCLI
if (-not (Get-PSSnapin VMware.VimAutomation.Core -ErrorAction SilentlyContinue))
{   Try { Add-PSSnapin VMware.VimAutomation.Core -ErrorAction Stop }
    Catch { Write-Host "Unable to load PowerCLI, is it installed?" -ForegroundColor Red; Exit }
}

$vCenter = "vcenter.logitravelzone.local"
$vCenteruser ="scriptsuser"

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

Connect-VIServer $vCenter -Credential $Cred -ErrorAction Stop -WarningAction SilentlyContinue | Out-Null
#-----------------------------------------------------------------------------------------------------------------------------

#Mira la última hora
$vMotionAge = 1

$EventFilterSpec = New-Object VMware.Vim.EventFilterSpec
$EventFilterSpec.Category = "info"
$EventFilterSpec.Time = New-Object VMware.Vim.EventFilterSpecByTime
$EventFilterSpec.Time.beginTime = (get-date).addhours(-$vMotionAge)
$EventFilterSpec.Type = "VmMigratedEvent", "DrsVmMigratedEvent", "VmBeingHotMigratedEvent", "VmBeingMigratedEvent"
$vmotions = @((get-view (get-view ServiceInstance -Property Content.EventManager).Content.EventManager).QueryEvents($EventFilterSpec)) 

$value = $vmotions | where-object FullFormattedMessage -like "*in cluster LOGITRAVEL*" | measure-object | select count
#$vmotions | where-object FullFormattedMessage -like "*in cluster LOGITRAVEL*" | out-gridview
#$vmotions | select CreatedTime, UserName, FullFormattedMessage | out-gridview


$x=[string]$value.count+":DRS migrations in cluster LOGITRAVEL"
write-host $x


