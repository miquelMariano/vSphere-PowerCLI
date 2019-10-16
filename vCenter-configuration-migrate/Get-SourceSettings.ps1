#Get Data from Source vCenter
#Get the DRSRule Module from https://github.com/PowerCLIGoodies/DRSRule
#Requires -modules DRSRule
param
(
        $directory = $(read-host "Enter local output directory"),
        $datacenter = $(read-host "Enter datacenter"),
        [switch]$getTemplates
)
#Takes a VI Folder object and returns an array of strings that represents that folder's absolute path in the inventory
function get-folderpath
{
        param
        (
                $thisFolder
        )
        #Creates an array of folders back to the root folder
        if ($thisFolder.id -like "Folder*")
        {
                $folderArray = @()
                $folderArray += $thisFolder
                while ($folderArray[-1].parent.parent.id -match "Folder")
                {
                        $folderArray += $folderArray[-1].parent
                }
                [array]::Reverse($folderArray)
                #convert the array of folders to an array of strings with just the folder names
                $folderStrArray = @()
                $folderArray | %{$folderStrArray += $_.name}
                $folderStrArray
        }
        else
        {
                write-error "Unexpected input provided; does not appear to be a Folder."
        }
}
$directory = $directory.trim("\") #" This comment is to fix the gistit syntax highlighting.
new-item $directory -type directory -erroraction silentlycontinue
#Get Roles
get-virole | ? {$_.issystem -eq $false} | export-clixml $directory\$($datacenter)-roles.xml
#Get Permissions
$allPermissions = @()
$foundPermissions = get-vipermission
$i = 0
foreach ($thisPermission in $foundPermissions)
{
        write-progress -Activity "Getting permissions" -percentComplete ($i / $foundPermissions.count * 100)
        $objPerm = "" | select entity,type,Role,Principal,Propagate,folderType
        $objPerm.type = $thisPermission.entityid.split("-")[0]
        #$objPerm.type = $thisPermission.entity.type
        $objPerm.Role = $thisPermission.role
        $objPerm.Principal = $thisPermission.Principal
        $objPerm.Propagate = $thisPermission.propagate
        #Create an absolute path for a folder, otherwise store the name of the entity
        if ($objPerm.type -eq "Folder")
        {
                $objPerm.entity = get-folderpath $thisPermission.entity
                $objPerm.folderType = $thisPermission.entity.type.tostring()
        }
        else
        {
                $objPerm.entity = $thisPermission.entity.name
                $objPerm.folderType = ""
        }
        $allPermissions += $objPerm
        $i++
}
$allPermissions | export-clixml $directory\$($datacenter)-permissions.xml
#Get VM Folder Structure
$outFolders = @()
$i = 0
$foundFolders = get-datacenter $datacenter | get-folder | ? {$_.type.tostring() -eq "VM" -and $_.parent.id -notLike "Datacenter*"}
foreach ($thisFolder in $foundFolders)
{
        write-progress -Activity "Getting VM folder structure" -percentComplete ($i / $foundFolders.count * 100)
        $myFolder = "" | select path
        $myFolder.path = get-folderpath $thisFolder
        $outFolders += $myFolder
        $i++
}
$outFolders | export-clixml $directory\$($datacenter)-folders.xml
#Convert Templates to VMs (so that they can transition vCenters)
get-template | select name | export-clixml $directory\$($datacenter)-Templates.xml
if ($getTemplates){get-datacenter $datacenter | get-template | set-template -ToVM -confirm:$false}
#Get VM Locations
$outVMs = @()
$allVApps = get-datacenter $datacenter | get-vapp
$vAppVMs = @()
$vAppVMs += $allVApps | get-vm
if ($vAppVMs)
{
        $allVMs = Get-VM | ? {!($vAppVMs.contains($_))}
        #Deal with vApps... maybe try this guy's technique to capture settings and make a best effort at recreating the vApp?
        # http://www.lukaslundell.com/2013/06/modifying-vapp-properties-with-powershell-and-powercli/
        $outVApps = @()
        foreach ($thisVApp in $allVApps)
        {
                write-error "Discovered VAPP: $($thisVApp.name) - vAPPs must be recreated manually."
                $myVApp = "" | select name,VMs
                $myVApp.name = $thisVApp.name
                $myVApp.VMs = ($thisVApp | get-vm).name
                $outVApps += $myVApp
        }
        $outVApps | export-clixml $directory\$($datacenter)-vApps.xml
}
else
{
        $allVMs = get-datacenter $datacenter | get-VM
}
$i = 0
foreach ($thisVM in $allVMs)
{
        write-progress -Activity "Getting VM locations" -percentComplete ($i / $allVMs.count * 100)
        $myVM = "" | select name,folderPath
        $myVM.name = $thisVM.name
        if ($thisVM.folder.name -eq "VM")
        {
                $myVM.folderPath = $NULL
        }
        else
        {
                $myVM.folderPath = get-folderpath $thisVM.folder
        }
        $outVMs += $myVM
        $i++
}
$outVMs | export-clixml $directory\$($datacenter)-VMs.xml
#Get DRS Rules
get-drsvmgroup | export-clixml $directory\$($datacenter)-DRSVMGroups.xml
get-drsvmhostgroup | export-clixml $directory\$($datacenter)-DRSVMHostGroups.xml
get-DrsVMToVMHostRule | export-clixml $directory\$($datacenter)-DRSVMtoVMHostRules.xml
Get-DrsVMToVMRule | export-clixml $directory\$($datacenter)-DRSVMtoVMRules.xml
#Get Cluster EVC Mode
$allClusters = @()
$i = 1
$clusters = get-cluster
$clusters | foreach {
        write-progress -Activity "Getting Cluster Details" -percentComplete ($i / $clusters.count * 100)
        $outObj = "" | select ClusterName,VMHosts,EVCMode
        $outObj.VMHosts = ($_ | get-vmhost).name
        $outObj.ClusterName = $_.name
        $outObj.EVCMode = $_.evcmode
        $allClusters += $outObj
        $i++
}
$allClusters | export-clixml $directory\$($datacenter)-Cluster-Description.xml
```

### Set-SourceSettings.ps1

```
#Recreates the settings saved by Get-SourceSettings.ps1 in the new vCenter
#Get the DRSRule Module from https://github.com/PowerCLIGoodies/DRSRule
#Requires -modules DRSRule
param
(
        $directory = $(read-host "Enter local input directory"),
        $datacenter = $(read-host "Enter datacenter"),
        [switch]$roles,
        [switch]$permissions,
        [switch]$folders,
        [switch]$vms,
        [switch]$drs
)
function make-ParentFolder
{
        Param
        (
                $inFolderArray,
                $folderType
        )
        switch ($folderType)
        {
                "HostAndCluster"{$folderString = "Host"}
                "VM"{$folderString = "VM"}
                "Datastore"{$folderString = "Datastore"}
                "Network"{$folderString = "Network"}
                "Datacenter"{$folderString = "Datacenter"}
                default {write-error "Unknown folder type: $folderType";exit 23}
        }
        $parentFolder = get-datacenter $datacenter | get-folder $folderString
        foreach ($thisSubFolder in $inFolderArray)
        {
                if (!($parentFolder | get-folder $thisSubFolder -noRecursion -erroraction silentlycontinue))
                {
                        $ParentFolder = $parentFolder | new-folder $thisSubFolder
                }
                else
                {
                        $ParentFolder = $ParentFolder | get-folder $thisSubFolder -noRecursion
                }
        }
        $ParentFolder
}
$directory = $directory.trim("\") #" fix the gistit syntax highlighting
#Rebuild Folder Structure
if ($folders)
{
        $folderArray = import-clixml $directory\$($datacenter)-folders.xml
        $i = 0
        foreach ($thisFolder in $folderArray)
        {
                write-progress -Activity "Creating Folders" -percentComplete ($i / $folderArray.count * 100)
                make-ParentFolder -inFolderArray $thisFolder.path -folderType "VM"
                $i++
        }
}
#Rebuild Roles
if ($roles)
{
        $allRoles = import-clixml $directory\$($datacenter)-roles.xml
        $i = 0
        foreach ($thisRole in $allRoles)
        {
                write-progress -Activity "Creating Roles" -percentComplete ($i / $allRoles.count * 100)
                if (!(get-virole $thisRole.name -erroraction silentlycontinue))
                {
                        new-virole -name $thisRole.name -privilege (get-viprivilege -id $thisRole.PrivilegeList) -erroraction silentlycontinue
                }
                $i++
        }
}
#Rebuild Permissions
if ($permissions)
{
        $allPermissions = import-clixml $directory\$($datacenter)-permissions.xml
        $i = 0
        foreach ($thisPermission in $allPermissions)
        {
                write-progress -Activity "Creating Permissions" -percentComplete ($i / $allPermissions.count * 100)
                $target = ""
                $thisPermission.type
                switch ($thisPermission.type)
                {
                        "Folder" {
                                if ($thisPermission.entity -eq "Datacenters") {$target = get-folder Datacenters}
                                else {$target = make-Parentfolder -inFolderArray $thisPermission.entity -folderType $thisPermission.folderType}
                                }
                        "VirtualMachine" {$target = get-datacenter $datacenter | get-vm $thisPermission.entity}
                        "VM" {$target = get-datacenter $datacenter | get-vm $thisPermission.entity}
                        "Datacenter" {$target = get-datacenter $thisPermission.entity}
                        "ClusterComputeResource" {$target = get-cluster $thisPermission.entity}
                        Default {write-error "Unexpected permission target, $($thisPermission.type)"}
                }
                
                if ($target)
                {
                        $target | new-vipermission -role $thisPermission.role -principal $thisPermission.principal -propagate $thisPermission.propagate
                }
                else
                {
                        write-error "Unable to find permission object $($thisPermission.entity)"
                }
                $i++
        }
}
#Replace VMs
if ($VMs)
{
        $allVMs = import-clixml $directory\$($datacenter)-VMs.xml
        $allVApps = $NULL
        $i = 0
        if (test-path $directory\vApps.xml){$allVApps = import-clixml $directory\$($datacenter)-vApps.xml}
        foreach ($thisVM in $allVMs)
        {
                write-progress -Activity "Placing VMs" -percentComplete ($i / $allVMs.count * 100)
                if ($foundVM = get-vm $thisVM.name -erroraction silentlycontinue)
                {
                        $ParentFolder = make-ParentFolder -inFolderArray $thisVM.folderPath -folderType "VM"
                        $foundVM | move-vm -location $ParentFolder      
                }
                $i++
        }
        foreach ($thisVApp in $allVApps)
        {
                echo "===$($thisVApp.name)==="
                $thisvApp.VMs
        }
        #Convert Template VMs back to Templates
}
#Recreate DRS Rules
if ($DRS)
{
        #Import the data from the Get script
        [array]$DRSVMGroups = import-clixml $directory\$($datacenter)-DRSVMGroups.xml
        [array]$DRSVMHostGroups = import-clixml $directory\$($datacenter)-DRSVMHostGroups.xml
        [array]$DRSVMtoVMHostRules = import-clixml $directory\$($datacenter)-DRSVMtoVMHostRules.xml
        [array]$DRSVMtoVMRules = import-clixml $directory\$($datacenter)-DRSVMtoVMRules.xml
        
        #Create the VM Groups
        $i = 0
        foreach ($thisGroup in $DRSVMGroups)
        {
                $i++
                write-progress -Activity "Making VM Group: $($thisGroup.name)" -percentComplete ($i / $DRSVMGroups.count * 100)
                if ($thisCluster = get-cluster $thisGroup.cluster)
                {
                        $vmArray = @()
                        foreach ($thisVM in $thisGroup.vm)
                        {
                                if ($thisVMObj = get-vm $thisVM)
                                {
                                        $vmArray += $thisVMObj
                                }
                                else
                                {
                                        write-error "Virtual Machine $thisVM was not found and could not be added to the DRS Group."
                                }
                        }
                        #Overwrite an existing group or create a new one, as per the current specifications
                        if ($thisDRSVMGroup = $thisCluster | get-drsVMGroup $thisGroup.name)
                        {
                                #Adds the VMs to the existing group
                                $thisDRSVMGroup | Set-DrsVMGroup -vm $vmArray -append > $null
                        }
                        else
                        {
                                #Make a new group
                                new-drsvmgroup -cluster $thisCluster -name $thisGroup.name -vm $vmArray > $null
                        }
                }
                else
                {
                        write-error "DRS Rules cannot be created for cluster $($thisGroup.cluster), as it does not exist."
                }
        }
        
        #Create VMHost Groups
        $i = 0
        foreach ($thisGroup in $DRSVMHostGroups)
        {
                $i++
                write-progress -Activity "Making VMHost Group: $($thisGroup.name)" -percentComplete ($i / $DRSVMHostGroups.count * 100)
                if ($thisCluster = get-cluster $thisGroup.cluster)
                {
                        $vmHostArray = @()
                        foreach ($thisVMHost in $thisGroup.vmhost)
                        {
                                if ($thisVMHostObj = get-vmhost $thisVMHost)
                                {
                                        $vmHostArray += $thisVMHostObj
                                }
                                else
                                {
                                        write-error "VMHost $thisVMHost was not found and could not be added to the DRS Group."
                                }
                        }
                        #Overwrite an existing group or create a new one, as per the current specifications
                        if ($thisDRSVMHostGroup = $thisCluster | get-drsVMHostGroup $thisGroup.name)
                        {
                                $thisDRSVMHostGroup | Set-DrsVMHostGroup -vm $vmHostArray > $null
                        }
                        else
                        {
                                #Make a new group
                                new-drsvmhostgroup -cluster $thisCluster -name $thisGroup.name -vm $vmHostArray > $null
                        }
                }
                else
                {
                        write-error "DRS Rules cannot be created for cluster $($thisGroup.cluster), as it does not exist."
                }
        }
        #Create VM to VMHost Rules
        $i = 0
        foreach ($thisRule in $DRSVMtoVMHostRules)
        {
                $i++
                write-progress -Activity "Making VM to VMHost rule: $($thisRule.name)" -percentComplete ($i / $DRSVMtoVMHostRules.count * 100)
                if ($thisCluster = get-cluster $thisRule.cluster)
                {
                        #Prepare the hash table with all required arguments
                        $arguments = @("AffineHostGroupName","VMGroupName","Name","AntiAffineHostGroupName")
                        $h = @{}
                        $thisRule.psobject.properties | foreach {
                                if (($_.value) -and ($arguments -contains $_.name)) {$h.add("$($_.name)","$($_.value)")}
                                if (($_.value -eq "true") -and (@("Mandatory","Enabled") -contains $_.name)) {$h.add("$($_.name)",$true)}
                        }
                        #Remove an existing rule, then create the new rule as per the Hash Table
                        if ($thisRule = $thisCluster | get-DrsVMtoVMHostRule $thisRule.name)
                        {
                                $thisRule | remove-DrsVMToVMHostRule -confirm:$false > $null
                        }
                        new-DrsVMtoVMHostRule -cluster $thisCluster @h > $null
                }
                else
                {
                        write-error "Unable to find the $($thisRule.cluster) cluster."
                }
        }
        
        #Create VM to VM Rules
        $i = 0
        foreach ($thisRule in $DRSVMtoVMRules)
        {
                $i++
                write-progress -Activity "Making VM to VM rule: $($thisRule.name)" -percentComplete ($i / $DRSVMtoVMRules.count * 100)
                if ($thisCluster = get-cluster $thisRule.cluster)
                {
                        #Prepare the hash table to capture if the rule is Mandatory, Affinity, and/or Enabled
                        $arguments = @("Mandatory","KeepTogether","Enabled")
                        $h = @{}
                        $thisRule.psobject.properties | foreach {
                                if (($_.value -eq "True") -and ($arguments -contains $_.name)){$h.add("$($_.name)",$true)}
                        }
                        #Prepare the list of VMs for the Rule
                        $vmArray = @()
                        foreach ($thisVM in $thisRule.VM)
                        {
                                if ($thisVMObj = get-vm $thisVM)
                                {
                                        $vmArray += $thisVMObj
                                }
                                else
                                {
                                        write-error "Unable to find $thisVM in $($thisCluster.name); unable to add it to DRS Rule $($thisRule.name)"
                                }
                        }
                        #Remove an existing rule, then create the new rule as per the Hash Table
                        if ($foundRule = $thisCluster | get-DrsVMtoVMRule $thisRule.name)
                        {
                                $foundRule | remove-DrsVMToVMRule -confirm:$false > $null
                        }
                        new-DrsVMtoVMRule -cluster $thisCluster -VM $vmArray -name $thisRule.name @h > $null
                }
                else
                {
                        write-error "Unable to find the $($thisRule.cluster) cluster."
                }
        }
}
#Check Cluster Configuration
$allClusters = import-clixml $directory\$($datacenter)-Cluster-Description.xml
foreach ($thisCluster in $allClusters)
{
        if ($newCluster = get-cluster $thisCluster.ClusterName)
        {
                if ($newCluster.evcmode -ne $thisCluster.evcmode) {Write-host -foreground red "$($newCluster.name) does not use $($thisCluster.evcmode) EVC Mode."}
                if (($theseHosts = $newCluster | get-vmhost).count -gt 0)
                {
                        if ($outComp = compare-object ($theseHosts).name $thisCluster.vmhosts) {Write-host -foreground yellow "Cluster ""$($newCluster.name)"" does not have all of the expected ESXi hosts.";$outComp} 
                }
        }
        else
        {
                write-host -foreground red "Cluster $($thisCluster.clustername) does not exist."
        }
}
#Help a user who doesn't tell the script to do anything.
if (!($VMs -or $folders -or $permissions -or $roles -or $drs))
{
        echo "Please use one or more of the -VMs, -Folders, -Permissions, -DRS or -Roles switches to do something"
}
```

