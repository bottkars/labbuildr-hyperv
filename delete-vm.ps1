[CmdletBinding(SupportsShouldProcess=$true,
    ConfirmImpact="Medium")]
param (
$vmname)
$Builddir = $PSScriptRoot
$vmname  = $vmname -replace "\."
$vmname  = $vmname -replace "\\"

try
    {
    $VM = get-vm $vmname -ErrorAction Stop 
    }
catch
    {
    write-host "VM Not Found"
    exit
    }

####are we in labbuildr path and not force ?

if ((($VM.Path -replace "\\","/") -match (($Builddir.path) -replace "\\","/")) -or ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent))
    {
    $vm | Stop-VM -Force -TurnOff
    $vm | Remove-VM -Force
    Remove-Item $VM.Path -Force -Recurse 
    }
      
