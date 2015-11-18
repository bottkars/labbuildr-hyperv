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
$start_memsize = 512MB
$min_memsize = 512MB
$max_memsize = 512MB
$numvcpus = "1"
}
"S"{
$start_memsize = 68MB
$min_memsize = 512MB
$max_memsize = 768MB

$numvcpus = "1"
}
"M"{
[int64]$start_memsize = 1GB
[int64]$min_memsize = 512MB
[int64]$max_memsize = 1GB

$numvcpus = "1"
}
"L"{
[int64]$start_memsize = 2GB
[int64]$min_memsize = 1GB
[int64]$max_memsize = 2GB

$numvcpus = "2"
}
"XL"{
[int64]$start_memsize = 4GB
[int64]$min_memsize = 2GB
[int64]$max_memsize = 4GB

$numvcpus = "2"
}
"TXL"{
[int64]$start_memsize = 6GB
[int64]$min_memsize = 4GB
[int64]$max_memsize = 6GB

$numvcpus = "2"
}
"XXL"{
[int64]$start_memsize = 8GB
[int64]$min_memsize = 4GB
[int64]$max_memsize = 8GB

$numvcpus = "4"
}
"XXXL"{
[int64]$start_memsize = 8GB
[int64]$min_memsize = 4GB
[int64]$max_memsize = 16GB

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
$CloneVM = New-VM -Name $Nodename -Path "$Builddir" -Memory $start_memsize  -VHDPath $vhd.path -SwitchName $HVSwitch -Generation 2
$CloneVM | Set-VMMemory -DynamicMemoryEnabled $true -MinimumBytes $min_memsize -StartupBytes $start_memsize -MaximumBytes $max_memsize -Priority 80 -Buffer 25
$CloneVM | Add-VMDvdDrive -Path "$Builddir\$Nodename\build.iso"
$CloneVM | Set-VMProcessor -Count $numvcpus
$CloneVM | Get-VMHardDiskDrive | Set-VMHardDiskDrive -MaximumIOPS 2000
if ($AddDisks)
    {
    Write-Verbose "Adding Disks"
    foreach ($disk in (1..$Disks+1))
        {
        $VHD = New-VHD -Dynamic -SizeBytes $Disksize -Path "$Builddir\$Nodename\Disk$Disk.vhdx"        
        $CloneVM | Add-VMHardDiskDrive -path $vhd.path -ControllerType SCSI -ControllerNumber 0 -DiskNumber $disk 
        }
    }
$CloneVM | Set-VM –AutomaticStartAction Start
if ($vlanid)
    {
    $CloneVM | Get-VMNetworkAdapter | Set-VMNetworkAdapterVlan -Access -VlanId $vlanid
    }
$CloneVM | start-vm
# return ok