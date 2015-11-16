﻿[CmdletBinding()]
Param(
[Parameter(Mandatory=$false)][string]$Builddir = $PSScriptRoot,
[Parameter(Mandatory=$true)][string]$MasterVHD,
[Parameter(Mandatory=$false)][string]$Domainname,
[Parameter(Mandatory=$true)][string]$Nodename,
[Parameter(Mandatory=$false)][string]$CloneVMPath = "$Builddir\$Nodename\",
[Parameter(Mandatory=$false)][string]$HVSwitch,
[Parameter(Mandatory=$false)][switch]$Isilon,
[Parameter(Mandatory=$false)][string]$scenarioname = "Default",
[Parameter(Mandatory=$false)][int]$Scenario = 1,
[Parameter(Mandatory=$false)][int]$ActivationPreference = 1,
[Parameter(Mandatory=$false)][switch]$AddDisks,
[Parameter(Mandatory=$false)][uint64]$Disksize = 200GB,
[Parameter(Mandatory=$false)][ValidateRange(1, 6)][int]$Disks = 1,
[Parameter(Mandatory=$false)][ValidateSet('XS','S','M','L','XL','TXL','XXL','XXXL')]$Size = "M",
$vlanid,
[switch]$Exchange,
[switch]$HyperV,
[switch]$NW,
[switch]$Bridge,
[switch]$Gateway,
[switch]$sql,
$Sourcedir
)

write-host "Creating Differencing disk from $MasterVHD in $Nodename"
$VHD = New-VHD –Path “$Builddir\$Nodename\$Nodename.vhdx” –ParentPath “$MasterVHD” 
if (!$VHD)
    {
    Write-Warning "Error creating VHD"
    exit
    }
$CloneVM = New-VM -Name $Nodename -Path "$Builddir" -Memory 512MB  -VHDPath "$Builddir\$Nodename\$Nodename.vhdx” -SwitchName $HVSwitch -Generation 2
$CloneVM | Set-VMMemory -DynamicMemoryEnabled $true -MinimumBytes 128MB -StartupBytes 1024MB -MaximumBytes 2GB -Priority 80 -Buffer 25
$CloneVM | Add-VMDvdDrive -Path "$Builddir\$Nodename\build.iso"
$CloneVM | Set-VMProcessor -Count 2
$CloneVM | Get-VMHardDiskDrive | Set-VMHardDiskDrive -MaximumIOPS 2000
$CloneVM | Set-VM –AutomaticStartAction Start
if ($vlanid)
    {
    $CloneVM | Get-VMNetworkAdapter | Set-VMNetworkAdapterVlan -Access -VlanId $vlanid
    }
$CloneVM | start-vm
# return ok