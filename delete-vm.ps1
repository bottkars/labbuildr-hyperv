param (
$vmname)
try
    {
    get-vm $vmname -ErrorAction Stop 
    }
catch
    {
    write-host "VM Not Found"
    exit
    }  
get-vm $vmname -ErrorAction Stop | Stop-VM -Force -TurnOff
get-vm $vmname | Remove-VM -Force
Remove-Item ".\$vmname" -Force -Recurse