param (
    [string]$vm = "Ninguna VM introducida por parametro"
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

[int] $value = get-stat -entity $vm -stat cpu.ready.summation -start (Get-Date).AddDays(-1) | select-object -first 1 | select value | ft -HideTableHeaders

$XMLOutput = "<prtg>`n"

$XMLOutput += "<text>CPU Ready de $vm</text>`n"

$XMLOutput += "<result>`n"
$XMLOutput += "<channel> %rdy </channel> `n"
$XMLOutput += "<value>$value</value>`n"
$XMLOutput += "</result>`n"



$XMLOutput += "</prtg>"

write-host $XMLOutput