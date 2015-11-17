[CmdletBinding()]
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


switch ($Size)
{ 
"XS"{
$memsize = "512"
$numvcpus = "1"
}
"S"{
$memsize = "768"
$numvcpus = "1"
}
"M"{
$memsize = "1024"
$numvcpus = "1"
}
"L"{
$memsize = "2048"
$numvcpus = "2"
}
"XL"{
$memsize = "4096"
$numvcpus = "2"
}
"TXL"{
$memsize = "6144"
$numvcpus = "2"
}
"XXL"{
$memsize = "8192"
$numvcpus = "4"
}
"XXXL"{
$memsize = "16384"
$numvcpus = "4"
}
}



write-host "Creating Differencing disk from $MasterVHD in $Nodename"
$VHD = New-VHD –Path “$Builddir\$Nodename\$Nodename.vhdx” –ParentPath “$MasterVHD” 
if (!$VHD)
    {
    Write-Warning "Error creating VHD"
    exit
    }
$CloneVM = New-VM -Name $Nodename -Path "$Builddir" -Memory "$memsizeMB"  -VHDPath "$Builddir\$Nodename\$Nodename.vhdx” -SwitchName $HVSwitch -Generation 2
$CloneVM | Set-VMMemory -DynamicMemoryEnabled $true -MinimumBytes 1024MB -StartupBytes 2GB -MaximumBytes 2GB -Priority 80 -Buffer 25
$CloneVM | Add-VMDvdDrive -Path "$Builddir\$Nodename\build.iso"
$CloneVM | Set-VMProcessor -Count $numvcpus
$CloneVM | Get-VMHardDiskDrive | Set-VMHardDiskDrive -MaximumIOPS 2000
$CloneVM | Set-VM –AutomaticStartAction Start
if ($vlanid)
    {
    $CloneVM | Get-VMNetworkAdapter | Set-VMNetworkAdapterVlan -Access -VlanId $vlanid
    }
$CloneVM | start-vm
# return ok