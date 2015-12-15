#set-executionpolicy Unrestricted -Force

#if(-not (Get-PSSnapin VMware.VimAutomation.Core -ErrorAction SilentlyContinue))
#{
#   Add-PSSnapin VMware.VimAutomation.Core 
#}
#Connect-VIServer -Server vcenter.logitravelzone.local -Protocol https -User scriptsuser -Password a5187444109f1b48966e6b54194f32ad.

get-vm | select @{N="NumDisks";E={@($_.harddisks.count)}} | measure-object  numdisks -max | select-object -expand Maximum