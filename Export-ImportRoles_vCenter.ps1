<# 
.DESCRIPTION
   Script que nos permite exporar/importar roles e vCenter Server

.NOTES 
   File Name  : Export-ImportRoles_vCenter.ps1 
   Author     : Miquel Mariano - @miquelMariano
   Version    : 1

.USAGE
	bla bla bla bla bla bla
 
.CHANGELOG
   v1	26/11/2015	Creación del script
   v2	30/03/2015	Securizar script con function get-credential
   v3	25/11/2015	Adecuar para http://blog.ncora.com/
#>



“” > “C:\roles.txt”
$arrCustomRoles = Get-VIRole | Where-Object {-not $_.IsSystem}
ForEach ($objRole in $arrCustomRoles)
{
$arrRolePermissions = Get-VIPrivilege -Role $objRole
“Role`t” + $objRole.Name >> “C:\roles.txt”
ForEach ($objPermission in $arrRolePermissions)
{
“Priv`t” + $objPermission.ID >> “C:\roles.txt”
}
}


$arrFileContents = Get-Content -path “C:\roles.txt”
ForEach ($strLine in $arrFileContents)
{
If ($strLine.contains(“Role`t”))
{
$strRoleName = $strLine.Split(“`t”)[1]
$objRole = New-VIRole -Privilege $readOnlyPrivileges -Name $strRoleName
}
If ($strLine.contains(“Priv`t”))
{
$strPrivName = $strline.Split(“`t”)[1]
$objPriv = Get-VIPrivilege -ID $strPrivName
$objToNull = Set-VIRole –Role $strRoleName –AddPrivilege $objPriv
}
}

