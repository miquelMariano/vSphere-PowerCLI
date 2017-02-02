<# 
.DESCRIPTION
   vAutodeployVM_GUI.ps1 is an script that help to admins. to deploy automatically many virtual machines easyly
 
.NOTES 
   File Name  : vAutodeployVM_GUI.ps1 
   Author     : Miquel Mariano | miquelMariano.github.io | @miquelMariano
   Version    : 4

.REQUIREMENTS
   VMWare PowerCLI 5.5 or latest is required
   
.USAGE
  Execute vAutodeployVM_GUI.ps1 from Vmware PowerCLI shell
 
.CHANGELOG
   v1	27/03/2015	Script creation
   v2	22/04/2015	Add modifications on VLAN, IP, CPU & MemGB resources
   v2.1	30/04/2015	Add $Is_template variable to deploy VM from temblate or cloned from another VM
   v3	01/06/2015	Add GUI
   v4	26/01/2017	Add default vars definition | Add control version from github
   v4	27/01/2017	Translate script to english | Part1
   v4	30/01/2017	Modify default value of vars.
   v4	02/02/2017	Send deployment log with telegram
    
#>

#-------------DEFAULT VARS--------------------
$currentversion = 4
$currentbuild = 40202
$FileCurrentversion = "$env:userprofile\currentversion"
#-------------DEFAULT VARS--------------------



#-------------DECLARATION OF FUNCTIONS--------------------

function connectServer{

    try {
	 
    $connect = Connect-VIServer -Server $TextBoxIPorFQDN.Text -User $TextBoxUsername.Text -Password $TextBoxPass.Text

    $ButtonConnect.Enabled = $false #Disable controls once connected
    $TextBoxIPorFQDN.Enabled = $false
    $TextBoxUsername.Enabled = $false
    $TextBoxPass.Enabled = $false
    $ButtonDisconnect.Enabled = $true #Enable Disconnect button

	$RadioButtonTemplate.Enabled=$true
	$RadioButtonVM.Enabled=$true
	$TextBoxVMIncrementelNum.Enabled = $true
    $TextBoxBaseName.Enabled = $true
    $TextBoxNumVMs.Enabled = $true
	$TextBoxNumCPU.Enabled = $true
	$TextBoxNumRAM.Enabled = $true
		
	$ButtonResetForm.Enabled = $true
	
	$main_form.ControlBox = $false

    $now = Get-Date -format "dd-MM-yy HH:mm | "
    $outputTextBox.text = "`r`n$now Conectado correctamente a $($TextBoxIPorFQDN.Text)" + $outputTextBox.text
	$outputTextBox.text = "`r`n$now Rellana los campos iniciales y que base vamos a tomar para el despliegue" + $outputTextBox.text
	
    }

    catch {
	
    $now = Get-Date -format "dd-MM-yy HH:mm | "
    $outputTextBox.text = "`r`n$now Something went wrong!!" + $outputTextBox.text
    
    }

}

function disconnectServer{

    try {

    $disconnect = Disconnect-VIServer -Confirm:$false -Force:$true

    $ButtonConnect.Enabled = $true #Enable login controls once disconnected
    $TextBoxIPorFQDN.Enabled = $true
    $TextBoxUsername.Enabled = $true
    $TextBoxPass.Enabled = $true
    $ButtonDisconnect.Enabled = $false #Disable Disconnect button
	
	$RadioButtonTemplate.Enabled=$false
	$RadioButtonVM.Enabled=$false
	$buttonValidateTemplateVM.Enabled = $false
	$TextBoxVMIncrementelNum.Enabled = $false	
    $TextBoxBaseName.Enabled = $false
    $TextBoxNumVMs.Enabled = $false
	$DropDownBoxTemplates.Enabled=$false
	$DropDownBoxVLAN.Enabled = $false
	$DropDownBoxCustomSpec.Enabled=$false
	$ButtonResetForm.Enabled = $false
	$ButtonValidateAll.Enabled = $false
	$TextBoxNumCPU.Enabled = $false
	$TextBoxNumRAM.Enabled = $false
	$TextBoxNetwork.Enabled = $false
	
	
	$RadioButtonTemplate.Checked = $false
	$RadioButtonVM.Checked = $false
	
	$main_form.ControlBox = $true
    
    $now = Get-Date -format "dd-MM-yy HH:mm | "
    $outputTextBox.text = "`r`n$now Desconectado correctamente de $($TextBoxIPorFQDN.Text)" + $outputTextBox.text
    $outputTextBox.text | Out-File c:\tmp\vAutodeployVM-debug.log
    
	#Send deployment log with telegram
	$bot_token = "304017237:AAHpKXZBaw_wOF3H-ryhWl3F3wqIVP_Zqf8" 
    $uri = "https://api.telegram.org/bot$bot_token/sendMessage" 
    $chat_id = "6343788" 
    Invoke-WebRequest -Method Post -Uri $uri -ContentType "application/json;charset=utf-8" ` -Body (ConvertTo-Json -Compress -InputObject @{chat_id=$chat_id; text=$outputTextBox.text})
	#Send deployment log with telegram
	
	} catch {
    
    $outputTextBox.text = "`r`n$now Something went wrong!!" + $outputTextBox.text
    
    }

}

function RadioButtonTemplateVMAction {
$DropDownBoxTemplates.Items.Clear()

if ($RadioButtonTemplate.Checked -eq $true) {
$templates = Get-Template | sort-object name
$now = Get-Date -format "dd-MM-yy HH:mm | "
$outputTextBox.text = "`r`n$now Cargadas plantillas" + $outputTextBox.text
foreach ($template in $templates) {
            $DropDownBoxTemplates.Items.Add($template.Name) #Add templates to DropDown List
        } 
		}
if ($RadioButtonVM.Checked -eq $true) {
$vms = get-vm | sort-object name
$now = Get-Date -format "dd-MM-yy HH:mm | "
$outputTextBox.text = "`r`n$now Cargadas VMs" + $outputTextBox.text
foreach ($vm in $vms) {
            $DropDownBoxTemplates.Items.Add($vm.Name) #Add templates to DropDown List
        }
}

   $DropDownBoxTemplates.Enabled=$true
   $DropDownBoxTemplates.Refresh()
   $buttonValidateTemplateVM.Enabled = $true
   $DropDownBoxCustomSpec.Enabled=$false
   
      
}

function ButtonValidateTemplateVMAction{
   
    try {
	
	if ($DropDownBoxTemplates.SelectedItem -eq $null){
	$now = Get-Date -format "dd-MM-yy HH:mm | "
    $outputTextBox.text = "`r`n$now Selecciona primero una opcion del desplegable de plantillas o VMs" + $outputTextBox.text
	} else {
	$DropDownBoxCustomSpec.Enabled=$true
    $buttonValidateTemplateVM.Enabled = $false
	$buttonValidateCustomSpecs.Enabled = $true
	$DropDownBoxTemplates.Enabled = $false
	$DropDownBoxCustomSpec.Items.Clear()
	
	$OSCustomizationSpec = Get-OSCustomizationSpec | sort-object name
	$now = Get-Date -format "dd-MM-yy HH:mm | "
	$outputTextBox.text = "`r`n$now Seleccionada $($DropDownBoxTemplates.SelectedItem.ToString())" + $outputTextBox.text
	$outputTextBox.text = "`r`n$now Cargadas Custom Specifications" + $outputTextBox.text
	
	foreach ($specs in $OSCustomizationSpec) {
            $DropDownBoxCustomSpec.Items.Add($specs.Name) #Add templates to DropDown List
        } 
    }
}
    catch {
    
    $outputTextBox.text = "`nError carga desplegable!!"
    
    }

}

function ButtonValidateCustomSpecsAction {

 try {
	
	if ($DropDownBoxCustomSpec.SelectedItem -eq $null){
	$now = Get-Date -format "dd-MM-yy HH:mm | "
    $outputTextBox.text = "`r`n$now Selecciona primero una opcion del desplegable CustomSpec" + $outputTextBox.text
	} else {
	$DropDownBoxCluster.Enabled=$true
    $buttonValidateCustomSpecs.Enabled = $false
	$buttonValidateCluster.Enabled = $true
	$DropDownBoxCustomSpec.Enabled = $false
	$DropDownBoxCluster.Items.Clear()
	
	$clusters = Get-cluster | sort-object name
	$now = Get-Date -format "dd-MM-yy HH:mm | "
	$outputTextBox.text = "`r`n$now Seleccionada CustomSpec $($DropDownBoxCustomSpec.SelectedItem.ToString())" + $outputTextBox.text
	$outputTextBox.text = "`r`n$now Cargada lista de clusters" + $outputTextBox.text
	 
		foreach ($cluster in $clusters) {
            $DropDownBoxCluster.Items.Add($cluster.Name) #Add templates to DropDown List
        }   
#		foreach ($datastore in $datastores) {
#           $DropDownBoxDatastore.Items.Add($datastore.Name) #Add templates to DropDown List
#        }   
    }
}
    catch {
    
    $outputTextBox.text = "`nError carga desplegable!!"
    
    }
}

function ButtonValidateClusterAction {

 try {
	
	if ($DropDownBoxCluster.SelectedItem -eq $null){
	$now = Get-Date -format "dd-MM-yy HH:mm | "
    $outputTextBox.text = "`r`n$now Selecciona primero una opcion del desplegable Cluster" + $outputTextBox.text
	} else {
	$DropDownBoxDatastore.Enabled=$true
    $buttonValidateCluster.Enabled = $false
	$buttonValidateDatastore.Enabled = $true
	$DropDownBoxCluster.Enabled = $false
	$DropDownBoxDatastore.Items.Clear()
	
	$datastores = get-cluster $DropDownBoxCluster.SelectedItem.ToString() | Get-datastore | sort-object name
	$now = Get-Date -format "dd-MM-yy HH:mm | "
	$outputTextBox.text = "`r`n$now Seleccionado cluster $($DropDownBoxCluster.SelectedItem.ToString())" + $outputTextBox.text
	$outputTextBox.text = "`r`n$now Cargada lista de datastores" + $outputTextBox.text
		
		foreach ($datastore in $datastores) {
           $DropDownBoxDatastore.Items.Add($datastore.Name) #Add templates to DropDown List
        }   
    }
}
    catch {
    
    $outputTextBox.text = "`nError carga desplegable!!"
    
    }
}

function ButtonValidateDatastoreAction {

 try {
	
	if ($DropDownBoxCluster.SelectedItem -eq $null){
	$now = Get-Date -format "dd-MM-yy HH:mm | "
    $outputTextBox.text = "`r`n$now Selecciona primero una opcion del desplegable Datastore" + $outputTextBox.text
	} else {
	$DropDownBoxVLAN.Enabled=$true
    $ButtonValidateDatastore.Enabled = $false
	$ButtonValidateVLAN.Enabled = $true
	$DropDownBoxDatastore.Enabled = $false
	$DropDownBoxVLAN.Items.Clear()
	

##	$VirtualPortGroups = get-cluster $DropDownBoxCluster.SelectedItem.ToString() | get-vmhost | Get-VirtualPortGroup -name vlan* | select name
    $VirtualPortGroups = get-cluster $DropDownBoxCluster.SelectedItem.ToString() | get-vmhost | Get-VirtualPortGroup | select name | sort-object name
	$now = Get-Date -format "dd-MM-yy HH:mm | "
	$outputTextBox.text = "`r`n$now Seleccionado datastore $($DropDownBoxDatastore.SelectedItem.ToString())" + $outputTextBox.text
	$outputTextBox.text = "`r`n$now Cargada lista de port groups del cluster $($DropDownBoxCluster.SelectedItem.ToString())" + $outputTextBox.text
		
		foreach ($vpg in $VirtualPortGroups) {
           $DropDownBoxVLAN.Items.Add($vpg.Name) #Add templates to DropDown List
        }   
    }
}
    catch {
    
    $outputTextBox.text = "`nError carga desplegable!!"
    
    }
}

function ButtonValidateVLANAction {

if ($DropDownBoxVLAN.SelectedItem -eq $null){
	$now = Get-Date -format "dd-MM-yy HH:mm | "
    $outputTextBox.text = "`r`n$now Selecciona primero una opcion del desplegable VLAN" + $outputTextBox.text
	} else {
$TextBoxNetwork.Enabled = $true
#$ButtonValidateNetwork.Enabled = $true
$DropDownBoxVLAN.Enabled = $false
$ButtonValidateVLAN.Enabled = $false

$now = Get-Date -format "dd-MM-yy HH:mm | "
$outputTextBox.text = "`r`n$now Seleccionado port group $($DropDownBoxVLAN.SelectedItem.ToString())" + $outputTextBox.text

$TextBoxFirstIP.Enabled = $true
$TextBoxMask.Enabled = $false
$TextBoxGW.Enabled = $false
$TextBoxDNS1.Enabled = $false
$TextBoxDNS2.Enabled = $false
$ButtonValidateAll.Enabled = $true
$TextBoxMask.Enabled = $true
$TextBoxGW.Enabled = $true
$TextBoxDNS1.Enabled = $true
$TextBoxDNS2.Enabled = $true

$now = Get-Date -format "dd-MM-yy HH:mm | "
$outputTextBox.text = "`r`n$now Selecciona una mascara, puerta de enlace y DNSs correctos para la VLAN -> $($DropDownBoxVLAN.SelectedItem.ToString())" + $outputTextBox.text


}
}

function ButtonValidateNetworkAction {
if ($TextBoxNetwork.Text -eq $null){
	$now = Get-Date -format "dd-MM-yy HH:mm | "
    $outputTextBox.text = "`r`n$now Intruduce una red valida para calcula las IPs (xxx.xxx.xxx.)" + $outputTextBox.text
	} else {
$TextBoxNetwork.Enabled = $false
$ButtonValidateNetwork.Enabled = $false
$TextBoxFirstIP.Enabled = $true


$ButtonValidateFirstIP.Enabled = $true

}
}

function ButtonValidateFirstIPAction {
$TextBoxFirstIP.Enabled = $false
$TextBoxMask.Enabled = $false
$TextBoxGW.Enabled = $false
$TextBoxDNS1.Enabled = $false
$TextBoxDNS2.Enabled = $false
$ButtonValidateAll.Enabled = $true
$TextBoxMask.Enabled = $true
$TextBoxGW.Enabled = $true
$TextBoxDNS1.Enabled = $true
$TextBoxDNS2.Enabled = $true

$now = Get-Date -format "dd-MM-yy HH:mm | "
$outputTextBox.text = "`r`n$now Selecciona una mascara, puerta de enlace y DNSs correctos para la VLAN -> $($DropDownBoxVLAN.SelectedItem.ToString())" + $outputTextBox.text

$ButtonValidateFirstIP.Enabled = $false
}

function ButtonValidateALLAction {
$now = Get-Date -format "dd-MM-yy HH:mm | "
$outputTextBox.text = "`r`n$now Verificados todos los parametros, listo para empezar con el despliegue" + $outputTextBox.text

$TextBoxNumVMs.Enabled = $false
$TextBoxBaseName.Enabled = $false
$TextBoxVMIncrementelNum.Enabled = $false
$RadioButtonTemplate.Enabled = $false
$RadioButtonVM.Enabled=$false
$TextBoxNumCPU.Enabled = $false
$TextBoxNumRAM.Enabled = $false
$TextBoxMask.Enabled = $false
$TextBoxGW.Enabled = $false
$TextBoxDNS1.Enabled = $false
$TextBoxDNS2.Enabled = $false
$TextBoxNetwork.Enabled = $false
$TextBoxFirstIP.Enabled = $false

$LabelResume.Text = "Se van a crear $($TextBoxNumVMs.Text) VMs con las siguientes caracteristicas:"
$LabelResume.Text += "`r`n"
$LabelResume.Text += "`r`n $($LabelBaseName.Text) $($TextBoxBaseName.Text)"
$LabelResume.Text += "`r`n $($LabelVMIncrementalNum.Text) $($TextBoxVMIncrementelNum.Text)"
$LabelResume.Text += "`r`n VM o plantilla base: $($DropDownBoxTemplates.SelectedItem.ToString())"
$LabelResume.Text += "`r`n $($LabelCustomSpec.Text) $($DropDownBoxCustomSpec.SelectedItem.ToString())"
$LabelResume.Text += "`r`n $($LabelCluster.Text) $($DropDownBoxCluster.SelectedItem.ToString())"
$LabelResume.Text += "`r`n $($LabelNumCPU.Text) $($TextBoxNumCPU.Text)"
$LabelResume.Text += "`r`n $($LabelNumRAM.Text) $($TextBoxNumRAM.Text)"
$LabelResume.Text += "`r`n $($LabelVLAN.Text) $($DropDownBoxVLAN.SelectedItem.ToString())"
$LabelResume.Text += "`r`n $($LabelNetwork.Text) $($TextBoxNetwork.Text)"
$LabelResume.Text += "`r`n $($LabelFirstIP.Text) $($TextBoxNetwork.Text)$($TextBoxFirstIP.Text)"
$LabelResume.Text += "`r`n $($LabelMask.Text) $($TextBoxMask.Text)"
$LabelResume.Text += "`r`n $($LabelGW.Text) $($TextBoxGW.Text)"
$LabelResume.Text += "`r`n $($LabelDNS1.Text) $($TextBoxDNS1.Text)"
$LabelResume.Text += "`r`n $($LabelDNS2.Text) $($TextBoxDNS2.Text)"

$PopUpValidateAll.Add_Shown({$PopUpValidateAll.Activate()})
    [void] $PopUpValidateAll.ShowDialog()
}

function ButtonResetAction {

$TextBoxNumVMs.Enabled = $true
$TextBoxBaseName.Enabled = $true
$TextBoxVMIncrementelNum.Enabled = $true
$RadioButtonTemplate.Enabled = $true
$RadioButtonTemplate.Checked = $false
$RadioButtonVM.Checked = $false
$RadioButtonVM.Enabled=$true
$TextBoxNumCPU.Enabled = $true
$TextBoxNumRAM.Enabled = $true
$TextBoxMask.Enabled = $true
$TextBoxGW.Enabled = $true
$TextBoxDNS1.Enabled = $true
$TextBoxDNS2.Enabled = $true
$TextBoxNetwork.Enabled = $true
$TextBoxFirstIP.Enabled = $true

}

function ButtonYESAction{
$PopUpValidateAll.Close()
$now = Get-Date -format "dd-MM-yy HH:mm | "
$outputTextBox.text = "`r`n$now Empezando con el despliegue de VMs..." + $outputTextBox.text
$ButtonValidateAll.Enabled = $false
deployVMs
}

function ButtonNOAction {

ButtonResetAction
$PopUpValidateAll.Close()


}

function deployVMs{

#----------BUCLE PARA DESPLEGAR N MAQUINAS-------------
[int]$NumVMs = [convert]::toint32($TextBoxNumVMs.Text)
[int]$NumVMAutoincremental = [convert]::toint32($TextBoxVMIncrementelNum.Text)
[int]$FirstIP = [convert]::toint32($TextBoxFirstIP.Text)
for ($n=1;$n -le $NumVMs; $n++) {
#$vmname = $TextBoxBaseName.Text+$NumVMAutoincremental+"V"
$vmname = $TextBoxBaseName.Text+$NumVMAutoincremental

$now = Get-Date -format "dd-MM-yy HH:mm | "
$outputTextBox.text = "`r`n$now Desplegando $n de $($NumVMs) servers" + $outputTextBox.text


$ip = $TextBoxNetwork.Text+$FirstIP
write-host Deploying $vmname with IP $ip of $NumVMs servers -foregroundcolor green

#Add an static IP of custom spec.
Get-OSCustomizationSpec $DropDownBoxCustomSpec.SelectedItem.ToString() | Get-OSCustomizationNicMapping | Set-OSCustomizationNicMapping -IpMode UseStaticIp -IpAddress $ip -SubnetMask $TextBoxMask.Text -DefaultGateway $TextBoxGW.Text -DNS $TextBoxDNS1.Text,$TextBoxDNS2.Text

if ($RadioButtonTemplate.Checked -eq $true){
	New-VM -Name $vmname -OSCustomizationSpec $DropDownBoxCustomSpec.SelectedItem.ToString() -ResourcePool $DropDownBoxCluster.SelectedItem.ToString() -Template $DropDownBoxTemplates.SelectedItem.ToString() -Datastore $DropDownBoxDatastore.SelectedItem.ToString()						
}

if ($RadioButtonVM.Checked -eq $true){
	New-VM -Name $vmname -OSCustomizationSpec $DropDownBoxCustomSpec.SelectedItem.ToString() -ResourcePool $DropDownBoxCluster.SelectedItem.ToString() -VM $DropDownBoxTemplates.SelectedItem.ToString() -Datastore $DropDownBoxDatastore.SelectedItem.ToString()						
}

Get-VM -Name $vmname | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $DropDownBoxVLAN.SelectedItem.ToString() -Confirm:$false
Get-VM -Name $vmname | Set-VM -MemoryGB $TextBoxNumRAM.Text -NumCPU $TextBoxNumCPU.Text -Confirm:$false
Start-VM -VM $vmname
$FirstIP++
$NumVMAutoincremental++

}

#Config custom spec. to that IP can be assigned across assistant
Get-OSCustomizationSpec $DropDownBoxCustomSpec.SelectedItem.ToString() | Get-OSCustomizationNicMapping | Set-OSCustomizationNicMapping -IpMode PromptUser -SubnetMask $TextBoxMask.Text -DefaultGateway $TextBoxGW.Text -DNS $TextBoxDNS1.Text,$TextBoxDNS2.Text

$now = Get-Date -format "dd-MM-yy HH:mm | "
$outputTextBox.text = "`r`n$now Despliegue finalizado" + $outputTextBox.text

}

#-------------DECLARATION OF FUNCTIONS--------------------

#Verificamos si tenemos instalado PowerCLI
if (-not (Get-PSSnapin VMware.VimAutomation.Core -ErrorAction SilentlyContinue))
{   Try { Add-PSSnapin VMware.VimAutomation.Core -ErrorAction Stop }
    Catch { Write-Host "Unable to load PowerCLI, is it installed?" -ForegroundColor Red; Exit }
}


[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 

#-------------DEFINICIÓN PRINCIPAL DEL FORMULARIO--------------------
    
    $main_form = New-Object System.Windows.Forms.Form 
    $main_form.Text = "vAutoDeploy Virtual Machines BETA v$currentversion build $currentbuild" #Form Title
    $main_form.Size = New-Object System.Drawing.Size(765,580) 
    $main_form.StartPosition = "CenterScreen"
	    
    $main_form.KeyPreview = $true
#    $main_form.Add_KeyDown({if ($_.KeyCode -eq "Escape") {$main_form.Close()}})

	Invoke-WebRequest -Uri https://raw.githubusercontent.com/miquelMariano/vSphere-PowerCLI/master/vAutodeploy/currentversion -OutFile $FileCurrentversion
	$githubversion = Get-Content -path $FileCurrentversion

    $LabelControlVersion = New-Object System.Windows.Forms.Label
    $LabelControlVersion.Location = New-Object System.Drawing.Point(10, 520)
    $LabelControlVersion.Size = New-Object System.Drawing.Size(300, 220)
	$LabelControlVersion.ForeColor = "red"
    If ($githubversion -eq $currentbuild) {
		$LabelControlVersion.Text = ""
		} 
    Else {
		$LabelControlVersion.Text = "Build $githubversion available on GitHub!! -->"
		}
    $main_form.Controls.Add($LabelControlVersion)
	
#	If (Test-Path $FileCurrentversion){
#		Remove-Item $FileCurrentversion
#		}
	
	$LinkLabel = New-Object System.Windows.Forms.LinkLabel
	$LinkLabel.Location = New-Object System.Drawing.Size(700,520)
	$LinkLabel.Size = New-Object System.Drawing.Size(150,20)
	$LinkLabel.LinkColor = "BLUE"
	$LinkLabel.ActiveLinkColor = "RED"
	$LinkLabel.Text = "GitHub"
	$LinkLabel.add_Click({[system.Diagnostics.Process]::start("https://github.com/miquelMariano/vSphere-PowerCLI/tree/master/vAutodeploy")})
	$main_form.Controls.Add($LinkLabel)

#-------------DEFINICIÓN PRINCIPAL DEL FORMULARIO--------------------

#-------------POPUP VALIDACIÓN--------------------
    
    $PopUpValidateAll = New-Object System.Windows.Forms.Form 
    $PopUpValidateAll.Text = "Validation" #Form Title
    $PopUpValidateAll.Size = New-Object System.Drawing.Size(400,340) 
    $PopUpValidateAll.StartPosition = "CenterScreen"
	$PopUpValidateAll.ControlBox = $false
    $PopUpValidateAll.KeyPreview = $true
	
	$LabelResume = New-Object System.Windows.Forms.Label
    $LabelResume.Location = New-Object System.Drawing.Point(10, 20)
    $LabelResume.Size = New-Object System.Drawing.Size(300, 220)
    $LabelResume.Text = "blank"
    $PopUpValidateAll.Controls.Add($LabelResume)
	
	$ButtonYES = New-Object System.Windows.Forms.button
    $ButtonYES.add_click({ButtonYESAction})
	$ButtonYES.Size = New-Object System.Drawing.Size(100,40) 
    $ButtonYES.Text = "Aceptar"
    $ButtonYES.Location = New-Object System.Drawing.Size(10,245)
    $ButtonYES.Enabled = $true
    $PopUpValidateAll.Controls.Add($ButtonYES) #Member of GroupBoxConnection

	$ButtonNO = New-Object System.Windows.Forms.button
    $ButtonNO.add_click({ButtonNOAction})
	$ButtonNO.Size = New-Object System.Drawing.Size(100,40) 
    $ButtonNO.Text = "Cancelar"
    $ButtonNO.Location = New-Object System.Drawing.Size(120,245)
    $ButtonNO.Enabled = $true
    $PopUpValidateAll.Controls.Add($ButtonNO) #Member of GroupBoxConnection
	
#-------------POPUP VALIDACIÓN--------------------

#-------------GROUP BOX DATOS DE CONEXIÓN-----------------------------

	$GroupBoxConnection = New-Object System.Windows.Forms.GroupBox
    $GroupBoxConnection.Location = New-Object System.Drawing.Size(10,5) 
    $GroupBoxConnection.size = New-Object System.Drawing.Size(185,200) #Ancho, Alto
    $GroupBoxConnection.text = "vCenter connection" 
    $main_form.Controls.Add($GroupBoxConnection) 

	$LabelIPorFQDN = New-Object System.Windows.Forms.Label
    $LabelIPorFQDN.Location = New-Object System.Drawing.Point(10, 20)
    $LabelIPorFQDN.Size = New-Object System.Drawing.Size(120, 14)
    $LabelIPorFQDN.Text = "IP Address o FQDN:"
    $GroupBoxConnection.Controls.Add($LabelIPorFQDN)
	
	$TextBoxIPorFQDN = New-Object System.Windows.Forms.TextBox 
	$TextBoxIPorFQDN.Text = "vcenter.ncora.corp"
    $TextBoxIPorFQDN.Location = New-Object System.Drawing.Size(10,40) #Left, Top, Right, Bottom
    $TextBoxIPorFQDN.Size = New-Object System.Drawing.Size(165,20) 
    $GroupBoxConnection.Controls.Add($TextBoxIPorFQDN)

    $LabelUser = New-Object System.Windows.Forms.Label
    $LabelUser.Location = New-Object System.Drawing.Point(10, 70)
    $LabelUser.Size = New-Object System.Drawing.Size(120, 14)
    $LabelUser.Text = "Username:"
    $GroupBoxConnection.Controls.Add($LabelUser)
	
	$TextBoxUsername = New-Object System.Windows.Forms.TextBox 
	$TextBoxUsername.Text = "ncora\username"
    $TextBoxUsername.Location = New-Object System.Drawing.Size(10,90)
    $TextBoxUsername.Size = New-Object System.Drawing.Size(165,20) 
    $GroupBoxConnection.Controls.Add($TextBoxUsername)

    $LabelPass = New-Object System.Windows.Forms.Label
    $LabelPass.Location = New-Object System.Drawing.Point(10, 120)
    $LabelPass.Size = New-Object System.Drawing.Size(120, 14)
    $LabelPass.Text = "Password:"
    $GroupBoxConnection.Controls.Add($LabelPass)
	  
    $TextBoxPass = New-Object System.Windows.Forms.MaskedTextBox #Password TextBox
    $TextBoxPass.PasswordChar = '*'
    $TextBoxPass.Location = New-Object System.Drawing.Size(10,140)
    $TextBoxPass.Size = New-Object System.Drawing.Size(165,20)
    $GroupBoxConnection.Controls.Add($TextBoxPass) 
	
	$ButtonConnect = New-Object System.Windows.Forms.Button
    $ButtonConnect.add_click({connectServer})
    $ButtonConnect.Text = "Connect"
    $ButtonConnect.Top=170
    $ButtonConnect.Left=10
    $GroupBoxConnection.Controls.Add($ButtonConnect) 

    $ButtonDisconnect = New-Object System.Windows.Forms.Button
    $ButtonDisconnect.add_click({disconnectServer})
    $ButtonDisconnect.Text = "Disconnect"
    $ButtonDisconnect.Top=170
    $ButtonDisconnect.Left=100
    $ButtonDisconnect.Enabled = $false #Disabled by default
    $GroupBoxConnection.Controls.Add($ButtonDisconnect) #Member of GroupBoxConnection
	
#-------------GROUP BOX DATOS DE CONEXIÓN-----------------------------

    
#-------------GROUP BOX DEFINICIÓN DE VARIABLES-----------------------------

	$groupBox2 = New-Object System.Windows.Forms.GroupBox
    $groupBox2.Location = New-Object System.Drawing.Size(10,215) 
    $groupBox2.size = New-Object System.Drawing.Size(730,300) #Width, Heigth
    $groupBox2.text = "Variables" 
    $main_form.Controls.Add($groupBox2) 
	
	$LabelNumVMs = New-Object System.Windows.Forms.Label
    $LabelNumVMs.Location = New-Object System.Drawing.Point(10, 20)
    $LabelNumVMs.Size = New-Object System.Drawing.Size(120, 20)
    $LabelNumVMs.Text = "Number of VMs:"
    $groupBox2.Controls.Add($LabelNumVMs) #Member of GroupBox2
	
	$TextBoxNumVMs = New-Object System.Windows.Forms.TextBox 
	$TextBoxNumVMs.Text = "1"
    $TextBoxNumVMs.Location = New-Object System.Drawing.Size(170,20)
    $TextBoxNumVMs.Size = New-Object System.Drawing.Size(185,20) 
	$TextBoxNumVMs.Enabled = $false
    $groupBox2.Controls.Add($TextBoxNumVMs) #Member of GroupBox2
	
	$LabelBaseName = New-Object System.Windows.Forms.Label
    $LabelBaseName.Location = New-Object System.Drawing.Point(10, 45)
    $LabelBaseName.Size = New-Object System.Drawing.Size(120, 20)
    $LabelBaseName.Text = "Basename:"
    $groupBox2.Controls.Add($LabelBaseName) #Member of GroupBox2
	
	$TextBoxBaseName = New-Object System.Windows.Forms.TextBox 
	$TextBoxBaseName.Text = "vAutodeployVM"
    $TextBoxBaseName.Location = New-Object System.Drawing.Size(170,45)
    $TextBoxBaseName.Size = New-Object System.Drawing.Size(185,20) 
	$TextBoxBaseName.Enabled = $false
    $groupBox2.Controls.Add($TextBoxBaseName) #Member of GroupBox2
	
	$LabelVMIncrementalNum = New-Object System.Windows.Forms.Label
    $LabelVMIncrementalNum.Location = New-Object System.Drawing.Point(10, 70)
    $LabelVMIncrementalNum.Size = New-Object System.Drawing.Size(160, 20)
    $LabelVMIncrementalNum.Text = "First sufix value:"
    $groupBox2.Controls.Add($LabelVMIncrementalNum) #Member of GroupBox2
	
	$TextBoxVMIncrementelNum = New-Object System.Windows.Forms.TextBox 
	$TextBoxVMIncrementelNum.Text = "1"
    $TextBoxVMIncrementelNum.Location = New-Object System.Drawing.Size(170,70)
    $TextBoxVMIncrementelNum.Size = New-Object System.Drawing.Size(185,20)
    $TextBoxVMIncrementelNum.Enabled = $false	
    $groupBox2.Controls.Add($TextBoxVMIncrementelNum) #Member of GroupBox2
	
	$RadioButtonTemplate = New-Object System.Windows.Forms.RadioButton
	$RadioButtonTemplate.Location = new-object System.Drawing.Point(10,145) #location of the radio button(px) in relation to the group box's edges (length, height)
#   $RadioButtonTemplate.Location = new-object System.Drawing.Point(10,95) #location of the radio button(px) in relation to the group box's edges (length, height)
	$RadioButtonTemplate.size = New-Object System.Drawing.Size(70,20) #the size in px of the radio button (length, height)
#	$RadioButtonTemplate.Checked = $true #is checked by default
	$RadioButtonTemplate.Text = "Template" #labeling the radio button
	$RadioButtonTemplate.Add_Click({RadioButtonTemplateVMAction})
	$RadioButtonTemplate.Enabled=$false
	$groupBox2.Controls.Add($RadioButtonTemplate) #activate the inside the grou
	
	$RadioButtonVM = New-Object System.Windows.Forms.RadioButton
	$RadioButtonVM.Location = new-object System.Drawing.Point(100,145) #location of the radio button(px) in relation to the group box's edges (length, height)
#   $RadioButtonVM.Location = new-object System.Drawing.Point(100,95) #location of the radio button(px) in relation to the group box's edges
	$RadioButtonVM.size = New-Object System.Drawing.Size(70,20) #the size in px of the radio button (length, height)
	$RadioButtonVM.Text = "VM" #labeling the radio button
	$RadioButtonVM.Add_Click({RadioButtonTemplateVMAction})
	$RadioButtonVM.Enabled=$false
	$groupBox2.Controls.Add($RadioButtonVM) #activate the inside the grou
	
	$DropDownBoxTemplates = New-Object System.Windows.Forms.ComboBox
    $DropDownBoxTemplates.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList #Disable user input in ComboBox
    $DropDownBoxTemplates.Location = New-Object System.Drawing.Size(170,145)
#   $DropDownBoxTemplates.Location = New-Object System.Drawing.Size(170,95) 	
    $DropDownBoxTemplates.Size = New-Object System.Drawing.Size(185,20) 
    $DropDownBoxTemplates.DropDownHeight = 200
    $DropDownBoxTemplates.Enabled=$false
    $groupBox2.Controls.Add($DropDownBoxTemplates)
	
	$buttonValidateTemplateVM = New-Object System.Windows.Forms.Button
    $buttonValidateTemplateVM.add_click({ButtonValidateTemplateVMAction})
	$buttonValidateTemplateVM.Size = New-Object System.Drawing.Size(30,20) 
    $buttonValidateTemplateVM.Text = "OK"
	$buttonValidateTemplateVM.Location = New-Object System.Drawing.Size(360,145) 
#	$buttonValidateTemplateVM.Location = New-Object System.Drawing.Size(360,95)
    $buttonValidateTemplateVM.Enabled = $false #Disabled by default
    $groupBox2.Controls.Add($buttonValidateTemplateVM) #Member of GroupBoxConnection
	
	$LabelCustomSpec = New-Object System.Windows.Forms.Label
    $LabelCustomSpec.Location = New-Object System.Drawing.Point(10, 170)
#   $LabelCustomSpec.Location = New-Object System.Drawing.Point(10, 120)
    $LabelCustomSpec.Size = New-Object System.Drawing.Size(160, 20)
    $LabelCustomSpec.Text = "CustomSpec:"
    $groupBox2.Controls.Add($LabelCustomSpec) #Member of GroupBox2
	
	$DropDownBoxCustomSpec = New-Object System.Windows.Forms.ComboBox
    $DropDownBoxCustomSpec.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList #Disable user input in ComboBox
    $DropDownBoxCustomSpec.Location = New-Object System.Drawing.Size(170,170) 
#	$DropDownBoxCustomSpec.Location = New-Object System.Drawing.Size(170,120) 
    $DropDownBoxCustomSpec.Size = New-Object System.Drawing.Size(185,20) 
    $DropDownBoxCustomSpec.DropDownHeight = 200
    $DropDownBoxCustomSpec.Enabled=$false
    $groupBox2.Controls.Add($DropDownBoxCustomSpec)
	
	$buttonValidateCustomSpecs = New-Object System.Windows.Forms.button
    $buttonValidateCustomSpecs.add_click({ButtonValidateCustomSpecsAction})
	$buttonValidateCustomSpecs.Size = New-Object System.Drawing.Size(30,20) 
    $buttonValidateCustomSpecs.Text = "OK"
    $buttonValidateCustomSpecs.Location = New-Object System.Drawing.Size(360,170)
#	$buttonValidateCustomSpecs.Location = New-Object System.Drawing.Size(360,120)
    $buttonValidateCustomSpecs.Enabled = $false #Disabled by default
    $groupBox2.Controls.Add($buttonValidateCustomSpecs) #Member of GroupBoxConnection
	
	$LabelCluster = New-Object System.Windows.Forms.Label
    $LabelCluster.Location = New-Object System.Drawing.Point(10, 195)
#	$LabelCluster.Location = New-Object System.Drawing.Point(10, 145)
    $LabelCluster.Size = New-Object System.Drawing.Size(160, 20)
    $LabelCluster.Text = "Cluster:"
    $groupBox2.Controls.Add($LabelCluster) #Member of GroupBox2
	
	$DropDownBoxCluster = New-Object System.Windows.Forms.ComboBox
    $DropDownBoxCluster.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList #Disable user input in ComboBox
    $DropDownBoxCluster.Location = New-Object System.Drawing.Size(170,195) 
#   $DropDownBoxCluster.Location = New-Object System.Drawing.Size(170,145)
    $DropDownBoxCluster.Size = New-Object System.Drawing.Size(185,20) 
    $DropDownBoxCluster.DropDownHeight = 200
    $DropDownBoxCluster.Enabled=$false
    $groupBox2.Controls.Add($DropDownBoxCluster)
	
	$buttonValidateCluster = New-Object System.Windows.Forms.button
    $buttonValidateCluster.add_click({ButtonValidateClusterAction})
	$buttonValidateCluster.Size = New-Object System.Drawing.Size(30,20) 
    $buttonValidateCluster.Text = "OK"
    $buttonValidateCluster.Location = New-Object System.Drawing.Size(360,195)
#   $buttonValidateCluster.Location = New-Object System.Drawing.Size(360,145)
    $buttonValidateCluster.Enabled = $false #Disabled by default
    $groupBox2.Controls.Add($buttonValidateCluster) #Member of GroupBoxConnection
	
	$LabelDatastore = New-Object System.Windows.Forms.Label
#   $LabelDatastore.Location = New-Object System.Drawing.Point(10, 170)
	$LabelDatastore.Location = New-Object System.Drawing.Point(10, 220)
    $LabelDatastore.Size = New-Object System.Drawing.Size(160, 20)
    $LabelDatastore.Text = "Datastore:"
    $groupBox2.Controls.Add($LabelDatastore) #Member of GroupBox2
	
	$DropDownBoxDatastore = New-Object System.Windows.Forms.ComboBox
    $DropDownBoxDatastore.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList #Disable user input in ComboBox
    $DropDownBoxDatastore.Location = New-Object System.Drawing.Size(170,220) 
#   $DropDownBoxDatastore.Location = New-Object System.Drawing.Size(170,170) 
    $DropDownBoxDatastore.Size = New-Object System.Drawing.Size(185,20) 
    $DropDownBoxDatastore.DropDownHeight = 200
    $DropDownBoxDatastore.Enabled=$false
    $groupBox2.Controls.Add($DropDownBoxDatastore)
	
	$ButtonValidateDatastore = New-Object System.Windows.Forms.button
    $ButtonValidateDatastore.add_click({ButtonValidateDatastoreAction})
	$ButtonValidateDatastore.Size = New-Object System.Drawing.Size(30,20) 
    $ButtonValidateDatastore.Text = "OK"
    $ButtonValidateDatastore.Location = New-Object System.Drawing.Size(360,220)
#	$ButtonValidateDatastore.Location = New-Object System.Drawing.Size(360,170)
    $ButtonValidateDatastore.Enabled = $false #Disabled by default
    $groupBox2.Controls.Add($ButtonValidateDatastore) #Member of GroupBoxConnection
	
  	$LabelNumCPU = New-Object System.Windows.Forms.Label
#    $LabelNumCPU.Location = New-Object System.Drawing.Point(10, 195)
    $LabelNumCPU.Location = New-Object System.Drawing.Point(10, 95)
    $LabelNumCPU.Size = New-Object System.Drawing.Size(120, 20)
    $LabelNumCPU.Text = "CPUs:"
    $groupBox2.Controls.Add($LabelNumCPU) #Member of GroupBox2
	
	$TextBoxNumCPU = New-Object System.Windows.Forms.TextBox 
	$TextBoxNumCPU.Text = "1"
#    $TextBoxNumCPU.Location = New-Object System.Drawing.Size(170,195)
    $TextBoxNumCPU.Location = New-Object System.Drawing.Size(170,95)
    $TextBoxNumCPU.Size = New-Object System.Drawing.Size(185,20) 
	$TextBoxNumCPU.Enabled = $false
    $groupBox2.Controls.Add($TextBoxNumCPU) #Member of GroupBox2
	
	$LabelNumRAM = New-Object System.Windows.Forms.Label
#    $LabelNumRAM.Location = New-Object System.Drawing.Point(10, 220)
    $LabelNumRAM.Location = New-Object System.Drawing.Point(10, 120)
    $LabelNumRAM.Size = New-Object System.Drawing.Size(120, 20)
    $LabelNumRAM.Text = "RAM (GB):"
    $groupBox2.Controls.Add($LabelNumRAM) #Member of GroupBox2
	
	$TextBoxNumRAM = New-Object System.Windows.Forms.TextBox 
	$TextBoxNumRAM.Text = "1"
#    $TextBoxNumRAM.Location = New-Object System.Drawing.Size(170,220)
    $TextBoxNumRAM.Location = New-Object System.Drawing.Size(170,120)
	$TextBoxNumRAM.Size = New-Object System.Drawing.Size(185,20) 
	$TextBoxNumRAM.Enabled = $false
    $groupBox2.Controls.Add($TextBoxNumRAM) #Member of GroupBox2
	
	$LabelVLAN = New-Object System.Windows.Forms.Label
    $LabelVLAN.Location = New-Object System.Drawing.Point(395,20)
    $LabelVLAN.Size = New-Object System.Drawing.Size(100, 20)
    $LabelVLAN.Text = "VLAN:"
    $groupBox2.Controls.Add($LabelVLAN) #Member of GroupBox2
	
	$DropDownBoxVLAN = New-Object System.Windows.Forms.ComboBox
    $DropDownBoxVLAN.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList #Disable user input in ComboBox
    $DropDownBoxVLAN.Location = New-Object System.Drawing.Size(500,20) 
    $DropDownBoxVLAN.Size = New-Object System.Drawing.Size(185,20) 
    $DropDownBoxVLAN.DropDownHeight = 200
    $DropDownBoxVLAN.Enabled=$false
    $groupBox2.Controls.Add($DropDownBoxVLAN)
	
	$ButtonValidateVLAN = New-Object System.Windows.Forms.button
    $ButtonValidateVLAN.add_click({ButtonValidateVLANAction})
	$ButtonValidateVLAN.Size = New-Object System.Drawing.Size(30,20) 
    $ButtonValidateVLAN.Text = "OK"
    $ButtonValidateVLAN.Location = New-Object System.Drawing.Size(690,20)
    $ButtonValidateVLAN.Enabled = $false #Disabled by default
    $groupBox2.Controls.Add($ButtonValidateVLAN) #Member of GroupBoxConnection
	
	$LabelNetwork = New-Object System.Windows.Forms.Label
    $LabelNetwork.Location = New-Object System.Drawing.Point(395,45)
    $LabelNetwork.Size = New-Object System.Drawing.Size(100, 20)
    $LabelNetwork.Text = "Network:"
    $groupBox2.Controls.Add($LabelNetwork) #Member of GroupBox2
		
	$TextBoxNetwork = New-Object System.Windows.Forms.TextBox 
	$TextBoxNetwork.Text = "10.0.0."
    $TextBoxNetwork.Location = New-Object System.Drawing.Size(500,45)
    $TextBoxNetwork.Size = New-Object System.Drawing.Size(185,20) 
	$TextBoxNetwork.Enabled = $false
    $groupBox2.Controls.Add($TextBoxNetwork) #Member of GroupBox2
	
#	$ButtonValidateNetwork = New-Object System.Windows.Forms.button
#    $ButtonValidateNetwork.add_click({ButtonValidateNetworkAction})
#	$ButtonValidateNetwork.Size = New-Object System.Drawing.Size(30,20) 
#    $ButtonValidateNetwork.Text = "OK"
#    $ButtonValidateNetwork.Location = New-Object System.Drawing.Size(690,45)
#    $ButtonValidateNetwork.Enabled = $false #Disabled by default
#    $groupBox2.Controls.Add($ButtonValidateNetwork) #Member of GroupBoxConnection
	
	$LabelFirstIP = New-Object System.Windows.Forms.Label
    $LabelFirstIP.Location = New-Object System.Drawing.Point(395,70)
    $LabelFirstIP.Size = New-Object System.Drawing.Size(100, 20)
    $LabelFirstIP.Text = "First IP:"
    $groupBox2.Controls.Add($LabelFirstIP) #Member of GroupBox2
	
	$TextBoxFirstIP = New-Object System.Windows.Forms.TextBox
    $TextBoxFirstIP.Text = "100"
    $TextBoxFirstIP.Location = New-Object System.Drawing.Size(500,70) 
    $TextBoxFirstIP.Size = New-Object System.Drawing.Size(185,20) 
    $TextBoxFirstIP.Enabled=$false
    $groupBox2.Controls.Add($TextBoxFirstIP)
	
#	$ButtonValidateFirstIP = New-Object System.Windows.Forms.button
#    $ButtonValidateFirstIP.add_click({ButtonValidateFirstIPAction})
#	$ButtonValidateFirstIP.Size = New-Object System.Drawing.Size(30,20) 
#    $ButtonValidateFirstIP.Text = "OK"
#    $ButtonValidateFirstIP.Location = New-Object System.Drawing.Size(690,70)
#    $ButtonValidateFirstIP.Enabled = $false #Disabled by default
#    $groupBox2.Controls.Add($ButtonValidateFirstIP) #Member of GroupBoxConnection
	
	$LabelMask = New-Object System.Windows.Forms.Label
    $LabelMask.Location = New-Object System.Drawing.Point(395,95)
    $LabelMask.Size = New-Object System.Drawing.Size(100, 20)
    $LabelMask.Text = "Netmask:"
    $groupBox2.Controls.Add($LabelMask) #Member of GroupBox2
	
	$TextBoxMask = New-Object System.Windows.Forms.TextBox 
	$TextBoxMask.Text = "255.255.255.0"
    $TextBoxMask.Location = New-Object System.Drawing.Size(500,95)
    $TextBoxMask.Size = New-Object System.Drawing.Size(185,20) 
	$TextBoxMask.Enabled = $false
    $groupBox2.Controls.Add($TextBoxMask) #Member of GroupBox2
	
	$LabelGW = New-Object System.Windows.Forms.Label
    $LabelGW.Location = New-Object System.Drawing.Point(395,120)
    $LabelGW.Size = New-Object System.Drawing.Size(100, 20)
    $LabelGW.Text = "Gateway:"
    $groupBox2.Controls.Add($LabelGW) #Member of GroupBox2
	
	$TextBoxGW = New-Object System.Windows.Forms.TextBox 
	$TextBoxGW.Text = "10.0.0.1"
    $TextBoxGW.Location = New-Object System.Drawing.Size(500,120)
    $TextBoxGW.Size = New-Object System.Drawing.Size(185,20) 
	$TextBoxGW.Enabled = $false
    $groupBox2.Controls.Add($TextBoxGW) #Member of GroupBox2
	
	$LabelDNS1 = New-Object System.Windows.Forms.Label
    $LabelDNS1.Location = New-Object System.Drawing.Point(395,145)
    $LabelDNS1.Size = New-Object System.Drawing.Size(100, 20)
    $LabelDNS1.Text = "Primary DNS:"
    $groupBox2.Controls.Add($LabelDNS1) #Member of GroupBox2
	
	$TextBoxDNS1 = New-Object System.Windows.Forms.TextBox 
	$TextBoxDNS1.Text = "8.8.8.8"
    $TextBoxDNS1.Location = New-Object System.Drawing.Size(500,145)
    $TextBoxDNS1.Size = New-Object System.Drawing.Size(185,20) 
	$TextBoxDNS1.Enabled = $false
    $groupBox2.Controls.Add($TextBoxDNS1) #Member of GroupBox2
	
	$LabelDNS2 = New-Object System.Windows.Forms.Label
    $LabelDNS2.Location = New-Object System.Drawing.Point(395,170)
    $LabelDNS2.Size = New-Object System.Drawing.Size(100, 20)
    $LabelDNS2.Text = "Secondary DNS:"
    $groupBox2.Controls.Add($LabelDNS2) #Member of GroupBox2
	
	$TextBoxDNS2 = New-Object System.Windows.Forms.TextBox 
	$TextBoxDNS2.Text = "4.4.4.4"
    $TextBoxDNS2.Location = New-Object System.Drawing.Size(500,170)
    $TextBoxDNS2.Size = New-Object System.Drawing.Size(185,20) 
	$TextBoxDNS2.Enabled = $false
    $groupBox2.Controls.Add($TextBoxDNS2) #Member of GroupBox2
	
	$ButtonValidateAll = New-Object System.Windows.Forms.button
    $ButtonValidateAll.add_click({ButtonValidateALLAction})
	$ButtonValidateAll.Size = New-Object System.Drawing.Size(600,40) 
    $ButtonValidateAll.Text = "Validate deploy"
    $ButtonValidateAll.Location = New-Object System.Drawing.Size(10,245)
    $ButtonValidateAll.Enabled = $false #Disabled by default
    $groupBox2.Controls.Add($ButtonValidateAll) #Member of GroupBoxConnection

	$ButtonResetForm = New-Object System.Windows.Forms.button
    $ButtonResetForm.add_click({ButtonResetAction})
	$ButtonResetForm.Size = New-Object System.Drawing.Size(100,40) 
    $ButtonResetForm.Text = "Reset"
    $ButtonResetForm.Location = New-Object System.Drawing.Size(615,245)
    $ButtonResetForm.Enabled = $false #Disabled by default
    $groupBox2.Controls.Add($ButtonResetForm) #Member of GroupBoxConnection
	
#-------------GROUP BOX DEFINICIÓN DE VARIABLES-----------------------------	
	
#-------------GROUP BOX LOG----------------------------	

	$groupBox4 = New-Object System.Windows.Forms.GroupBox
    $groupBox4.Location = New-Object System.Drawing.Size(200,5) 
    $groupBox4.size = New-Object System.Drawing.Size(540,200) #Width, Heigth
    $groupBox4.text = "Log:" 
    $main_form.Controls.Add($groupBox4)
	
	$outputTextBox = New-Object System.Windows.Forms.TextBox 
    $outputTextBox.Location = New-Object System.Drawing.Size(10,20)
    $outputTextBox.Size = New-Object System.Drawing.Size(520,170)
    $outputTextBox.MultiLine = $True 
    $outputTextBox.ReadOnly = $True
    $outputTextBox.ScrollBars = "Vertical" 
	$outputTextBox.ScrollToCaret()
	$now = Get-Date -format "dd-MM-yy HH:mm | "
    $outputTextBox.text = "`r`n$now vAutoDeploy v$currentversion build $currentbuild by miquelMariano.github.io" + $outputTextBox.text
	$outputTextBox.text = "`r`n$now Introduce los datos de conexion para empezar..." + $outputTextBox.text
    $groupBox4.Controls.Add($outputTextBox) #Member of groupBox4

#-------------GROUP BOX LOG----------------------------	

#-------------PINTA FORMULARIO----------------------------	
$main_form.Add_Shown({$main_form.Activate()})
    [void] $main_form.ShowDialog()
#-------------PINTA FORMULARIO----------------------------	
	
	

    