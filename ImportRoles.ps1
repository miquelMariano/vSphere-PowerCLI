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

