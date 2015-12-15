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



