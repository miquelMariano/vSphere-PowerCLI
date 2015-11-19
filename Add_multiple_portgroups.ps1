

$InputFile = "C:\vlans.csv"


$MyVLANFile = Import-CSV $InputFile

ForEach ($VLAN in $MyVLANFile) {
$MyCluster = $VLAN.cluster
$MyvSwitch = $VLAN.vSwitch
$MyVLANname = $VLAN.VLANname
$MyVLANid = $VLAN.VLANid
}

echo $MyCluster

$MyVMHosts = Get-Cluster $MyCluster | Get-VMHost


ForEach ($VMHost in $MyVMHosts) {
Get-VirtualSwitch -VMHost $VMHost -Name $MyvSwitch | New-VirtualPortGroup -Name $MyVLANname -VLanId $MyVLANid
}