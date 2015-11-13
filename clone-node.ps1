
[CmdletBinding()]
Param(
[Parameter(Mandatory=$false)][string]$Builddir = $PSScriptRoot,
[Parameter(Mandatory=$true)][string]$MasterVHD,
[Parameter(Mandatory=$false)][string]$Domainname,
[Parameter(Mandatory=$true)][string]$Nodename,
# [Parameter(Mandatory=$false)][string]$CloneVMPath = "$Builddir\$Nodename\$Nodename.vmx",
[Parameter(Mandatory=$false)][string]$vmnet ="vmnet2",
[Parameter(Mandatory=$false)][switch]$Isilon,
[Parameter(Mandatory=$false)][string]$scenarioname = "Default",
[Parameter(Mandatory=$false)][int]$Scenario = 1,
[Parameter(Mandatory=$false)][int]$ActivationPreference = 1,
[Parameter(Mandatory=$false)][switch]$AddDisks,
[Parameter(Mandatory=$false)][uint64]$Disksize = 200GB,
[Parameter(Mandatory=$false)][ValidateRange(1, 6)][int]$Disks = 1,
[Parameter(Mandatory=$false)][ValidateSet('XS','S','M','L','XL','TXL','XXL','XXXL')]$Size = "M",
[switch]$Exchange,
[switch]$HyperV,
[switch]$NW,
[switch]$Bridge,
[switch]$Gateway,
[switch]$sql,
$Sourcedir
)

##size eval
$vlanid = 2

###disks eval




New-VHD –Path “$Builddir\$Nodename\$Nodename.vhdx” –ParentPath “$MasterVHD” 
$CloneVM = New-VM -Name $Nodename -Path "$Builddir\$Nodename" -Memory 512MB  -VHDPath "$Builddir\$Nodename\$Nodename.vhdx” -SwitchName VMnet -Generation 2
$CloneVM | Set-VMMemory -DynamicMemoryEnabled $true -MinimumBytes 128MB -StartupBytes 512MB -MaximumBytes 2GB -Priority 80 -Buffer 25
$CloneVM | Get-VMHardDiskDrive | Set-VMHardDiskDrive -MaximumIOPS 2000
$CloneVM | Set-VM –AutomaticStartAction Start
if ($vlanid)
    {
    $CloneVM | Get-VMNetworkAdapter | Set-VMNetworkAdapterVlan -Access -VlanId $vlanid
    }
$CloneVM | start-vm
$CloneVM | Get-VM 

# return ok