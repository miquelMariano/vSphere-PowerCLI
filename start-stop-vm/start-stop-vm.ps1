<# 
.DESCRIPTION
   Start / stop virtual machines

.NOTES 
   File Name  : start-stop-vm.ps1 
   Author     : Miquel Mariano - @miquelMariano | https://miquelmariano.github.io
   Version    : 1

   v1 07/09/2022  Script creation

.EXAMPLE
   .\start-stop-vm.ps1 -vCenter "vcenter.lab.local" -vCenteruser "MyUsername" -vm "VM1"  -status "on|off" 
#>

#--------------GLOBAL VARS----------------------

param(
    [string]$vCenter = "ip",
    [string]$vCenteruser = "administrator@vsphere.local",
    [string]$vm = "VM1",
    [string]$status = "on|off"
)

$PathToCredentials = "C:\scripts" #It is important not to put the last \

#--------------GLOBAL VARS----------------------

#--------------ENCRYPT CREDENTIALS---------
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
  { (Get-Credential $AuthUser).Password | ConvertFrom-SecureString -Key $Key | Set-Content $File
    }
  #Load the credential file 
    $Password = Get-Content $File | ConvertTo-SecureString -Key $Key
    $AuthUser = (Split-Path $File -Leaf).Substring(12).Replace("~","\")
    $AuthUser = $AuthUser.Substring(0,$AuthUser.Length - 4)
  $Credential = New-Object System.Management.Automation.PsCredential($AuthUser,$Password)
    Return $Credential
}
#--------------ENCRYPT CREDENTIALS---------

$Cred = Get-Credentials $vCenterUser $PathToCredentials

Connect-VIServer $vCenter -Credential $Cred -ErrorAction Stop | Out-Null

if($status -eq "on")
    {
        start-vm $vm
        exit 0
    }

if($status -eq "off")
    {
        stop-vm $vm -confirm:$false
        exit 0
    }

Disconnect-VIServer $vCenter -Confirm:$False