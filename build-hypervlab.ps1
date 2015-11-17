<#
.Synopsis
   labbuildr-flex allows you to create Virtual Machines with VMware Workstation from Predefined Scenarios.
   Scenarios include Exchange 2013, SQL, Hyper-V, SCVMM .. .
   labbuildr-flex runs on EMC VLAB Flex Environment
.DESCRIPTION
   labbuildr is a Self Installing Lab tool for Building VMware Virtual Machines on VMware Workstation
      
      Copyright 2015 Karsten Bott

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
.LINK
   https://github.com/bottkars/labbuildr-flex
#>
[CmdletBinding(DefaultParametersetName = "version",
    SupportsShouldProcess=$true,
    ConfirmImpact="Medium")]
	[OutputType([psobject])]
param (
    <#run build-lab version    #>
	[Parameter(ParameterSetName = "version",Mandatory = $false, HelpMessage = "this will display the current version")][switch]$version,

    <#run build-lab update    #>
	[Parameter(ParameterSetName = "update",Mandatory = $false, HelpMessage = "this will update labbuildr from latest git commit")][switch]$Update,
    <#
    run build-lab update    #>
	[Parameter(ParameterSetName = "update",Mandatory = $false, HelpMessage = "select a branch to update from")][ValidateSet('master','testing','develop')]$branch  = "develop",
    [Parameter(ParameterSetName = "update",Mandatory = $false, HelpMessage = "this will force update labbuildr")]
    [switch]$force,
        <# 
    create deskop shortcut
    #>	
    [Parameter(ParameterSetName = "shortcut", Mandatory = $false)][switch]$createshortcut,
    <#
    Installs only a Domain Controller. Domaincontroller normally is installed automatically durin a Scenario Setup
    IP-Addresses: .10
    #>	
	[Parameter(ParameterSetName = "DConly")][switch][alias('dc')]$DConly,	
    <#
    Selects the Blank Nodes Scenario
    IP-Addresses: .180 - .189
    #>
	[Parameter(ParameterSetName = "Blanknodes")][switch][alias('bn')]$Blanknode,
    <#Exchange 2016   #>
	[Parameter(ParameterSetName = "E16",Mandatory = $true)][switch][alias('ex16')]$Exchange2016,
    <#
    Determines Exchange CU Version to be Installed
    Valid Versions are:
    'Final
    Default is latest
    CU Location is [Driveletter]:\sources\e2016[cuver], e.g. c:\sources\e2016Preview1
    #>
	[Parameter(ParameterSetName = "E16", Mandatory = $false)]
    [ValidateSet('final')]$e16_cu,


    <# Starting Node for Blank Nodes#>
    [Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)][ValidateRange(1, 9)][alias('bs')]$Blankstart = "1",
    <# How many Blank Nodes#>
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)][ValidateRange(1, 10)][alias('bns')]$BlankNodes = "1",

    <# Do we want Additional Disks / of additional 100GB Disks for ScaleIO. The disk will be made ready for ScaleIO usage in Guest OS#>	
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
    [Parameter(ParameterSetName = "Hyperv", Mandatory = $false)][ValidateRange(1, 6)][int][alias('ScaleioDisks')]$Disks,
<# select vmnet, number from 1 to 19#>                                        	
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "DConly", Mandatory = $false)]
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
    [Parameter(ParameterSetName = "SOFS", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint",Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [Parameter(ParameterSetName = "SRM", Mandatory = $false)]
    [ValidateSet('vmnet2','vmnet3','vmnet4','vmnet5','vmnet6','vmnet7','vmnet9','vmnet10','vmnet11','vmnet12','vmnet13','vmnet14','vmnet15','vmnet16','vmnet17','vmnet18','vmnet19')]$VMnet,
<# Specify if Machines should be Clustered, valid for Hyper-V and Blanknodes Scenario  #>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[switch]$Cluster,


        <# Wich version of OS Master should be installed
    '2012R2FallUpdate','2016TP3'
    #>
    [Parameter(ParameterSetName = "Sharepoint",Mandatory = $false)]
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "DConly", Mandatory = $false)]
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
    [Parameter(ParameterSetName = "SOFS", Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
    [Parameter(ParameterSetName = "SRM", Mandatory = $false)]
    [ValidateSet('2016TP3','2012R2FallUpdate')]$Master,

    <#do we want a special path to the Masters ? #>
    [Parameter(ParameterSetName = "Sharepoint",Mandatory = $false)]
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "DConly", Mandatory = $false)]
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
    [Parameter(ParameterSetName = "SOFS", Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [Parameter(ParameterSetName = "SRM", Mandatory = $false)]
    [ValidateScript({ Test-Path -Path $_ })]$Masterpath,
      <#
    Enable the default gateway 
    .103 will be set as default gateway, NWserver will have 2 Nics, NIC2 Pointing to NAT serving as Gateway
    #>
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
    [Parameter(ParameterSetName = "DConly", Mandatory = $false)]
    [switch][alias('gw')]$Gateway,

 #   [Parameter(Mandatory = $false, HelpMessage = "Enter a valid VMware network Number vmnet between 1 and 19 ")]
<# This stores the defaul config in defaults.xml#>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
    [Parameter(ParameterSetName = "DConly", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [Parameter(ParameterSetName = "SRM", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint", Mandatory = $false)]
	[switch]$savedefaults,

<# reads the Default Config from defaults.xml
<config>
<nmm_ver>nmm82</nmm_ver>
<nw_ver>nw82</nw_ver>
<master>2012R2UEFIMASTER</master>
<sqlver>SQL2014</sqlver>
<ex_cu>cu6</ex_cu>
<vmnet>2</vmnet>
<BuildDomain>labbuildr</BuildDomain>
<MySubnet>10.10.0.0</MySubnet>
<AddressFamily>IPv4</AddressFamily>
<IPV6Prefix>FD00::</IPV6Prefix>
<IPv6PrefixLength>8</IPv6PrefixLength>
<NoAutomount>False</NoAutomount>
</config>
#>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
    [Parameter(ParameterSetName = "DConly", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
   	[Parameter(ParameterSetName = "Isilon")]
    [Parameter(ParameterSetName = "SOFS", Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [Parameter(ParameterSetName = "SRM", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint", Mandatory = $false)]
	[switch]$defaults,

<#
Machine Sizes
'XS'  = 1vCPU, 512MB
'S'   = 1vCPU, 768MB
'M'   = 1vCPU, 1024MB
'L'   = 2vCPU, 2048MB
'XL'  = 2vCPU, 4096MB 
'TXL' = 2vCPU, 6144MB
'XXL' = 4vCPU, 6144MB
'XXXL' = 4vCPU, 8192MB
#>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "DConly", Mandatory = $false)]
	[Parameter(ParameterSetName = "Spaces", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
    [Parameter(ParameterSetName = "SOFS", Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [Parameter(ParameterSetName = "SRM", Mandatory = $false)]
	[ValidateSet('XS', 'S', 'M', 'L', 'XL', 'TXL', 'XXL', 'XXXL')]$Size = "M",
	
<# Specify your own Domain name#>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "DConly", Mandatory = $false)]
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "SOFS", Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [Parameter(ParameterSetName = "SRM", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint", Mandatory = $false)]
	[ValidateLength(1,15)][ValidatePattern("^[a-zA-Z\s]+$")][string]$BuildDomain,
	
<# Turn this one on if you would like to install a Hypervisor inside a VM #>
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[switch]$VTbit,
		
####networker 	
    <# install Networker Modules for Microsoft #>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "SOFS", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint", Mandatory = $false)]
	[switch]$NMM,
    <#
Version Of Networker Modules
'nmm300','nmm301','nmm2012','nmm3012','nmm82'
#>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "SOFS", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint", Mandatory = $false)]
	[ValidateSet('nmm8211','nmm8212','nmm8214','nmm8216','nmm8217','nmm8218','nmm822','nmm821','nmm300', 'nmm301', 'nmm2012', 'nmm3012', 'nmm82','nmm85','nmm85.BR1','nmm85.BR2','nmm85.BR3','nmm85.BR4','nmm90.DA')]
$nmm_ver,
	
<# Indicates to install Networker Server with Scenario #>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "DConly", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "SOFS", Mandatory = $false)]
	[Parameter(ParameterSetName = "Isilon")]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [Parameter(ParameterSetName = "SRM", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint", Mandatory = $false)]
	[switch]$NW,
    <#
Version Of Networker Server / Client to be installed
    'nw8216','nw8215','nw8214','nw8213','nw8212','nw8211','nw821','nw8205','nw8204','nw8203','nw8202','nw82','nw8116','nw8115','nw8114', 'nw8113','nw8112', 'nw811',  'nw8105','nw8104','nw8102', 'nw81','nw85','nw85.BR1','nw85.BR2','nw85.BR3','nw85.BR4','nw90.DA','nwunknown'
mus be extracted to [sourcesdir]\[nw_ver], ex. c:\sources\nw82
#>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
	[Parameter(ParameterSetName = "DConly", Mandatory = $false)]
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
    [Parameter(ParameterSetName = "SOFS", Mandatory = $false)]
    [Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint", Mandatory = $false)]
    [Parameter(ParameterSetName = "SRM", Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [ValidateSet('nw822','nw8218','nw8217','nw8216','nw8215','nw8214','nw8213','nw8212','nw8211','nw821','nw8205','nw8204','nw8203','nw8202','nw82','nw8116','nw8115','nw8114', 'nw8113','nw8112', 'nw811',  'nw8105','nw8104','nw8102', 'nw81','nw85','nw85.BR1','nw85.BR2','nw85.BR3','nw85.BR4','nw90.DA','nwunknown')]
    $nw_ver,

### network Parameters ######

<# Disable Domainchecks for running DC
This should be used in Distributed scenario´s
 #>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "DConly", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
	[Parameter(ParameterSetName = "Isilon", Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [Parameter(ParameterSetName = "SRM", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint", Mandatory = $false)]
    [switch]$NoDomainCheck,
<# Specify your own Class-C Subnet in format xxx.xxx.xxx.xxx #>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "DConly", Mandatory = $false)]
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [Parameter(ParameterSetName = "SRM", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint",Mandatory = $false)]
	[Validatepattern(‘(?<Address>((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?))’)]$MySubnet,

<# Specify your IP Addressfamilie/s
Valid values 'IPv4','IPv6','IPv4IPv6'
#>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "DConly", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
	[Parameter(ParameterSetName = "Isilon", Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint",Mandatory = $false)]
    [Parameter(ParameterSetName = "SRM", Mandatory = $false)]
    [Validateset('IPv4','IPv6','IPv4IPv6')]$AddressFamily, 

<# Specify your IPv6 ULA Prefix, consider https://www.sixxs.net/tools/grh/ula/  #>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "DConly", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
	[Parameter(ParameterSetName = "Isilon", Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint",Mandatory = $false)]
    [Parameter(ParameterSetName = "SRM", Mandatory = $false)]
    [ValidateScript({$_ -match [IPAddress]$_ })]$IPV6Prefix,

<# Specify your IPv6 ULA Prefix Length, #>
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)]
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)]
	[Parameter(ParameterSetName = "DConly", Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
	[Parameter(ParameterSetName = "Isilon", Mandatory = $false)]
    [Parameter(ParameterSetName = "SOFS", Mandatory = $false)]
    [Parameter(ParameterSetName = "Panorama", Mandatory = $false)]
    [Parameter(ParameterSetName = "SRM", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint",Mandatory = $false)]
    $IPv6PrefixLength,
    [String]$Sourcedir

)
#requires -version 3.0
#requires -module labtools 
###################################################
## COnstants to be moved to Params


###################################################
[string]$Myself = $MyInvocation.MyCommand
#$AddressFamily = 'IPv4'
$IPv4PrefixLength = '24'
$myself = $Myself.TrimEnd(".ps1")
$Starttime = Get-Date
$Builddir = $PSScriptRoot

if ($Sourcedir)
    {
    if (!(Test-Path $Sourcedir))
        {
        New-Item -ItemType Directory -Path $Sourcedir | out-null
        }
    if (!(get-smbshare -name "Scripts" -erroraction SilentlyContinue ))
        {
    new-smbshare -name "Scripts" -path "$Builddir\Scripts"
        }
    }
##

try
    {
    [datetime]$Latest_labbuildr_hyperv_git = Get-Content  ($Builddir + "\labbuildr-hyperv-$branch.gitver") -ErrorAction Stop
    }
    catch
    {
    [datetime]$Latest_labbuildr_hyperv_git = "07/11/2015"
    }
try
    {
    [datetime]$Latest_labbuildr_scripts_git = Get-Content  ($Builddir + "\labbuildr-scripts-$branch.gitver") -ErrorAction Stop
    }
    catch
    {
    [datetime]$Latest_labbuildr_scripts_git = "07/11/2015"
    }
try
    {
    [datetime]$Latest_labtools_git = Get-Content  ($Builddir + "\labtools-$branch.gitver") -ErrorAction Stop
    }
    catch
    {
    [datetime]$Latest_labtools_git = "07/11/2015"
    }


################## Statics
$LogFile = "$Builddir\$(Get-Content env:computername).log"
$Labbuildr_share_User = "_labbuildr_"
$Labbuildr_share_password = "Password123!"
$WAIKVER = "WAIK"
$domainsuffix = ".local"
$AAGDB = "AWORKS"
$major = "5.0"
$Default_vmnet = "vmnet2"
$Default_vlanid = 0
$Default_BuildDomain = "labbuildr"
$Default_Subnet = "192.168.2.0"
$Default_IPv6Prefix = "FD00::"
$Default_IPv6PrefixLength = '8'
$Default_AddressFamily = "IPv4"
$latest_ScaleIOVer = '1.32-2451.4'
$ScaleIO_OS = "Windows"
$ScaleIO_Path = "ScaleIO_$($ScaleIO_OS)_SW_Download"
$latest_nmm = 'nmm90.DA'
$latest_nw = 'nw90.DA'
$latest_e16_cu = 'final'
$latest_ex_cu = 'cu10'
$latest_sqlver  = 'SQL2014SP1slip'
$latest_master = '2012R2FallUpdate'
$latest_sql_2012 = 'SQL2012SP2'
$SIOToolKit_Branch = "master"
$NW85_requiredJava = "jre-7u61-windows-x64"
# $latest_java8 = "jre-8u51-windows-x64.exe"
$latest_java8uri = "http://javadl.sun.com/webapps/download/AutoDL?BundleId=107944"
$SourceScriptDir = "$Builddir\Scripts\"
$Adminuser = "Administrator"
$Adminpassword = "Password123!"
$GuestScriptdir = "D:"
$GuestSourcePath = "\\vmware-host\Shared Folders\Sources"
$GuestLogDir = "C:\Scripts"
$NodeScriptDir = "$GuestScriptdir\Node"
$Isodir = "$Builddir\scripts"
$Dots = [char]58
[string]$Commentline = "#######################################################################################################################"
#$SCVMM_VER = "SCVMM2012R2"
$WAIKVER = "WAIK"
# $SCOMVER = "SC2012_R2_SCOM"
#$SQLVER = "SQL2012SP1"
$DCNODE = "DCNODE"
$NWNODE = "NWSERVER"
$SPver = "SP2013SP1fndtn"
$SPPrefix = "SP2013"
$Edition = "Piranha"
$Sleep = 10
[string]$Sources = "Sources"
$Sourcedirdefault = "c:\Sources"
$Script_dir = "Scripts"
$Sourceslink = "https://my.syncplicity.com/share/wmju8cvjzfcg04i/sources"
$Buildname = Split-Path -Leaf $Builddir
$Scenarioname = "default"
$Scenario = 1
$AddonFeatures = ("RSAT-ADDS", "RSAT-ADDS-TOOLS", "AS-HTTP-Activation", "NET-Framework-45-Features")
$Gatewayhost = "11" 
$Host.UI.RawUI.WindowTitle = "$Buildname"

##################
###################################################
# main function go here
###################################################

####
####
function convert-iptosubnet
{
	param ($Subnet)
	$subnet = [System.Version][String]([System.Net.IPAddress]$Subnet)
	$Subnet = $Subnet.major.ToString() + "." + $Subnet.Minor + "." + $Subnet.Build
	return, $Subnet
} #enc convert iptosubnet


function update-fromGit
{


	param (
            [string]$Repo,
            [string]$RepoLocation,
            [string]$branch,
            [string]$latest_local_Git,
            [string]$Destination,
            [switch]$delete
            )
        Write-Verbose "Using update-fromgit function for $repo"
        $Uri = "https://api.github.com/repos/$RepoLocation/$repo/commits/$branch"
        $Zip = ("https://github.com/$RepoLocation/$repo/archive/$branch.zip").ToLower()
        $request = Invoke-WebRequest -UseBasicParsing -Uri $Uri -Method Head
        [datetime]$latest_OnGit = $request.Headers.'Last-Modified'
                Write-Verbose "We have $repo version $latest_local_Git, $latest_OnGit is online !"
                if ($latest_local_Git -lt $latest_OnGit -or $force.IsPresent )
                    {
                    $Updatepath = "$Builddir\Update"
					if (!(Get-Item -Path $Updatepath -ErrorAction SilentlyContinue))
					        {
						    $newDir = New-Item -ItemType Directory -Path "$Updatepath"
                            }
                    Write-Output "We found a newer Version for $repo on Git Dated $($request.Headers.'Last-Modified')"
                    if ($delete.IsPresent)
                        {
                        Write-Verbose "Cleaning $Destination"
                        Remove-Item -Path $Destination -Recurse -ErrorAction SilentlyContinue
                        }
                    Get-LABHttpFile -SourceURL $Zip -TarGetFile "$Builddir\update\$repo-$branch.zip" -ignoresize
                    Expand-LABZip -zipfilename "$Builddir\update\$repo-$branch.zip" -destination $Destination -Folder $repo-$branch
                    $Isnew = $true
                    $request.Headers.'Last-Modified' | Set-Content ($Builddir+"\$repo-$branch.gitver") 
                    }
                else 
                    {
                    Status "No update required for $repo on $branch, already newest version "                    
                    }

}
#####

function Extract-Zip
{
	param ([string]$zipfilename, [string] $destination)
	$copyFlag = 16 # overwrite = yes
	$Origin = $MyInvocation.MyCommand
	if (test-path($zipfilename))
	{		
        if (!(Test-Path $destination))
            {New-Item -ItemType Directory -Path $destination -Force | Out-Null }
        Write-Verbose "extracting $zipfilename"
        $shellApplication = new-object -com shell.application
		$zipPackage = $shellApplication.NameSpace($zipfilename)
		$destinationFolder = $shellApplication.NameSpace($destination)
		$destinationFolder.CopyHere($zipPackage.Items(), $copyFlag)
	}
}

function get-prereq
{ 
param ([string]$DownLoadUrl,
        [string]$destination )
$ReturnCode = $True
if (!(Test-Path $Destination))
    {
        Try 
        {
        if (!(Test-Path (Split-Path $destination)))
            {
            New-Item -ItemType Directory  -Path (Split-Path $destination) -Force
            }
        Write-verbose "Starting Download of $DownLoadUrl"
        Start-BitsTransfer -Source $DownLoadUrl -Destination $destination -DisplayName "Getting $destination" -Priority Foreground -Description "From $DownLoadUrl..." -ErrorVariable err 
                If ($err) {Throw ""} 

        } 
        Catch 
        { 
            $ReturnCode = $False 
            Write-Warning " - An error occurred downloading `'$FileName`'" 
            Write-Error $_ 
        }
    }
    else
    {
    write-Warning "No download needed, file exists" 
    }
    return $ReturnCode 
}

function status
{
	param ([string]$message)
	write-host -ForegroundColor Yellow $message
}


<#function CreateShortcut
{
	$wshell = New-Object -comObject WScript.Shell
	$Deskpath = $wshell.SpecialFolders.Item('Desktop')
	# $path2 = $wshell.SpecialFolders.Item('Programs')
	# $path1, $path2 | ForEach-Object {
	$link = $wshell.CreateShortcut("$Deskpath\$Buildname.lnk")
	$link.TargetPath = "$psHome\powershell.exe"
	$link.Arguments = "-noexit -command $Builddir\profile.ps1 -verb 'RunAs'"
	$link.Description = "$Buildname"
	$link.WorkingDirectory = "$Builddir"
	$link.IconLocation = 'powershell.exe,1'
	$link.Save()
	# }
#>
Function CreateShortcut
{
    [CmdletBinding()]
    param (	
	    [parameter(Mandatory=$true)]
	    [ValidateScript( {[IO.File]::Exists($_)} )]
	    [System.IO.FileInfo] $Target,
	
	    [ValidateScript( {[IO.Directory]::Exists($_)} )]
	    [System.IO.DirectoryInfo] $OutputDirectory,
	
	    [string] $Name,
	    [string] $Description,
	
	    [string] $Arguments,
	    [System.IO.DirectoryInfo] $WorkingDirectory,
	
	    [string] $HotKey,
	    [int] $WindowStyle = 1,
	    [string] $IconLocation,
	    [switch] $Elevated
    )

    try {
	    #region Create Shortcut
	    if ($Name) {
		    [System.IO.FileInfo] $LinkFileName = [System.IO.Path]::ChangeExtension($Name, "lnk")
	    } else {
		    [System.IO.FileInfo] $LinkFileName = [System.IO.Path]::ChangeExtension($Target.Name, "lnk")
	    }
	
	    if ($OutputDirectory) {
		    [System.IO.FileInfo] $LinkFile = [IO.Path]::Combine($OutputDirectory, $LinkFileName)
	    } else {
		    [System.IO.FileInfo] $LinkFile = [IO.Path]::Combine($Target.Directory, $LinkFileName)
	    }

       
	    $wshshell = New-Object -ComObject WScript.Shell
	    $shortCut = $wshShell.CreateShortCut($LinkFile) 
	    $shortCut.TargetPath = $Target
	    $shortCut.WindowStyle = $WindowStyle
	    $shortCut.Description = $Description
	    $shortCut.WorkingDirectory = $WorkingDirectory
	    $shortCut.HotKey = $HotKey
	    $shortCut.Arguments = $Arguments
	    if ($IconLocation) {
		    $shortCut.IconLocation = $IconLocation
	    }
	    $shortCut.Save()
	    #endregion

	    #region Elevation Flag
	    if ($Elevated) {
		    $tempFileName = [IO.Path]::GetRandomFileName()
		    $tempFile = [IO.FileInfo][IO.Path]::Combine($LinkFile.Directory, $tempFileName)
		
		    $writer = new-object System.IO.FileStream $tempFile, ([System.IO.FileMode]::Create)
		    $reader = $LinkFile.OpenRead()
		
		    while ($reader.Position -lt $reader.Length)
		    {		
			    $byte = $reader.ReadByte()
			    if ($reader.Position -eq 22) {
				    $byte = 34
			    }
			    $writer.WriteByte($byte)
		    }
		
		    $reader.Close()
		    $writer.Close()
		
		    $LinkFile.Delete()
		
		    Rename-Item -Path $tempFile -NewName $LinkFile.Name
	    }
	    #endregion
    } catch {
	    Write-Error "Failed to create shortcut. The error was '$_'."
	    exit
    }
   #  return $LinkFile
}
##
function make-iso
{ 
param ([string]$Nodename,
        [string]$Builddir,
        [string]$isodir)
    IF (!(Test-Path $Builddir\bin\mkisofs.exe))
        {
        Write-Warning "mkisofs tool not found, exiting"
        }

        Write-Verbose "Building iso from $isodir"
    .$Builddir\bin\mkisofs.exe -J -V build -o "$Builddir\$Nodename\build.iso"  "$Isodir"  2>&1| Out-Null
    $LASTEXITCODE
    switch ($LASTEXITCODE)
        {
            0
                {
                Write-Verbose "Iso Created for $Builddir\$Nodename\build.iso "
                }
            1
                {
                Write-Warning "could not create CD"
                Break
                }
            2
                {
                Write-Warning "could not create CD"
                Break
                }
        }
}
function invoke-postsection
    {
    param (
    [switch]$wait,
    [switch]$Reboot
    )
    write-host "Running Post Section"
    $Task = "postsection"
    <#
	invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath "$NodeScriptDir" -Script powerconf.ps1 -interactive # $CommonParameter
	write-verbose "Configuring UAC"
    invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath "$NodeScriptDir" -Script set-uac.ps1 -interactive # $CommonParameter
    #>
    $SecurePassword = $Adminpassword | ConvertTo-SecureString -AsPlainText -Force
    $Credential = New-Object –TypeName System.Management.Automation.PSCredential –ArgumentList "$BuildDomain\$Adminuser", $SecurePassword
    do {sleep 1} until (Test-WSMan -ComputerName $NodeIP -Credential $Credential -Verbose -Authentication Default)
    Invoke-Command -ComputerName $NodeIP -Credential $Credential -ScriptBlock  {
        Set-ExecutionPolicy -ExecutionPolicy Bypass -Force
        $HKitem = New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name "$using:task" -Value "$PSHOME\powershell.exe -Command `". $Using:NodeScriptDir\set-vmguesttask.ps1 -Task $task -Status finished`""
        ."$Using:NodeScriptDir\powerconf.ps1" -Scriptdir $Using:GuestScriptdir
        ."$Using:NodeScriptDir\set-uac.ps1" -Scriptdir $Using:GuestScriptdir
        ."$Using:NodeScriptDir\set-winrm.ps1" -Scriptdir $Using:GuestScriptdir
     }

     if ($Reboot.IsPresent)
        {
        Restart-Computer -ComputerName $NodeIP -Credential $Credential -Force
            if ($wait.IsPresent)
            {
            Write-Host "Checking for task $Task finished"
            do
                {
                Write-Host -NoNewline "."
                Sleep $Sleep
                }
            until ((get-vmguesttask -Task $task -Node $NodeIP) -match "finished")
            }
        }
    <#
    if ($Default.Puppet)
        {
        invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath "$GuestScriptDir\Node" -Script install-puppetagent.ps1 -Parameter "-Puppetmaster $Puppetmaster" -interactive # $CommonParameter
        }
    if ($wait.IsPresent)
        {
        checkpoint-progress -step UAC -reboot -Guestuser $Adminuser -Guestpassword $Adminpassword
        }
    else
        {
        checkpoint-progress step UAC -reboot -Nowait -Guestuser $Adminuser -Guestpassword $Adminpassword

        }
    #>
    }

function check-task
    {
    param (
    $task,
    $nodename,
    $sleep)
    <#
        Write-Host "Checking for task $Task started"
        do
            {
            Write-Host -NoNewline "."
            Sleep $Sleep
            }
        until ((get-vmguesttask -Task $task -Node $NodeName) -match "started")
        Write-Host
        #>
        Write-Host "Checking for task $Task finished"
        do
            {
            Write-Host -NoNewline "."
            Sleep $Sleep
            }
        until ((get-vmguesttask -Task $task -Node $nodename) -match "finished")
        Write-Host

}

###########Hyper-V Specific Funcions
function get-vmguesttask
{
        param (	
	    [parameter(Mandatory=$true)]$Node,
        [parameter(Mandatory=$true)]$Task
        )
    $vm = Get-WmiObject -Namespace 'root\virtualization\v2' -Class 'Msvm_ComputerSystem' -Filter "ElementName = '$Node'"
    if ($vm)
        {
        $taskstatus = $vm.GetRelated("Msvm_KvpExchangeComponent").GuestExchangeItems | ForEach-Object {
            try
                {
                $GuestExchangeItemXml = ([XML]$_).SelectSingleNode("/INSTANCE/PROPERTY[@NAME='Name']/VALUE[child::text() = '$Task']")
                }
            catch
                {
                Write-Verbose " Integration Services not running"
                }
            
            if ($GuestExchangeItemXml -ne $null) 
                { 
                $GuestExchangeItemXml.SelectSingleNode(` 
                "/INSTANCE/PROPERTY[@NAME='Data']/VALUE/child::text()").Value 
                } 
            }
        }
    Return $taskstatus
}
############################### End Function
switch ($PsCmdlet.ParameterSetName)
{
    "update" 
        {
        $Repo = "labbuildr-hyperv"
        $RepoLocation = "bottkars"
        $Latest_local_git = $Latest_labbuildr_hyperv_git
        $Destination = "$Builddir"
        update-fromGit -Repo $Repo -RepoLocation $RepoLocation -branch $branch -latest_local_Git $Latest_local_git -Destination $Destination
        if (Test-Path "$Builddir\deletefiles.txt")
		    {
			$deletefiles = get-content "$Builddir\deletefiles.txt"
			foreach ($deletefile in $deletefiles)
			    {
				if (Get-Item $Builddir\$deletefile -ErrorAction SilentlyContinue)
				    {
					Remove-Item -Path $Builddir\$deletefile -Recurse -ErrorAction SilentlyContinue
					status "deleted $deletefile"
					write-log "deleted $deletefile"
					}
			    }
            }
        else 
            {
            Write-Host "No Deletions required"
            }
        ####
        $Repo = "labbuildr-scripts"
        $RepoLocation = "bottkars"
        $Latest_local_git = $Latest_labbuildr_scripts_git
        $Destination = "$Builddir\Scripts"
        update-fromGit -Repo $Repo -RepoLocation $RepoLocation -branch $branch -latest_local_Git $Latest_local_git -Destination $Destination -delete
        ####
        $Repo = "labtools"
        $RepoLocation = "bottkars"
        $Latest_local_git = $Latest_labtools_git
        $Destination = "$Builddir\labtools"
        update-fromGit -Repo $Repo -RepoLocation $RepoLocation -branch $branch -latest_local_Git $Latest_local_git -Destination $Destination -delete

        return
    }# end Updatefromgit
    "Shortcut"
        {
				status "Creating Desktop Shortcut for $Buildname"
				createshortcut -Target "$psHome\powershell.exe" -Arguments "-noexit -command $Builddir\profile.ps1"	-IconLocation "powershell.exe,1" -Elevated -OutputDirectory "$home\Desktop" -WorkingDirectory $Builddir -Name $Buildname -Description "Labbuildr Hyper-V" -Verbose
                return
        }# end shortcut
    "Version"
        {
				Status "labbuildr HyperV version $major-$verlabbuildr_HyperV $Edition on $branch"
                if ($Latest_labbuildr_hyperv_git)
                    {
                    Status "Git Release $Latest_labbuildr_hyperv_git"
                    }
                Status "scripts version $major-$verscipts $Edition"
                if ($Latest_labbuildr_scripts_git)
                    {
                    Status "Git Release $Latest_labbuildr_scripts_git"
                    }
                Write-Output '   Copyright 2014 Karsten Bott

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.'
                 
				return
			} #end Version
}
##########
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    $CommonParameter = ' -verbose'
    }
if ($PSCmdlet.MyInvocation.BoundParameters["debug"].IsPresent)
    {
    $CommonParameter = ' -debug'
    }


if ($Exchange2016.IsPresent)
{
    if (!$e16_cu)
        {
        $e16_cu = $Latest_e16_cu
        }
    $EX_Version = "E2016"
    $Scenarioname = "Exchange"
    $Prereqdir = "Attachments"
    $attachments = (
    "http://www.cisco.com/c/dam/en/us/solutions/collateral/data-center-virtualization/unified-computing/fle_vmware.pdf"
   # "http://www.emc.com/collateral/white-papers/h12234-emc-integration-for-microsoft-private-cloud-wp.pdf",
   # "http://www.emc.com/collateral/software/data-sheet/h2257-networker-ds.pdf",
   # "http://www.emc.com/collateral/software/data-sheet/h2479-networker-app-modules-ds.pdf",
   # "http://www.emc.com/collateral/software/data-sheet/h4525-networker-ms-apps-ds.pdf",
   # "http://www.emc.com/collateral/handouts/h14152-cloudboost-handout.pdf",
   # "http://www.emc.com/collateral/software/data-sheet/h2257-networker-ds.pdf",
   # "http://www.emc.com/collateral/software/data-sheet/h3979-networker-dedupe-ds.pdf"
    )
    
    if (!(Test-Path $Sourcedir\$Prereqdir)){New-Item -ItemType Directory -Path $Sourcedir\$Prereqdir | Out-Null }
     foreach ($URL in $attachments)
        {
        $FileName = Split-Path -Leaf -Path $Url
        if (!(test-path  $Sourcedir\$Prereqdir\$FileName))
            {
            Write-Verbose "$FileName not found, trying Download"
            if (!(get-prereq -DownLoadUrl $URL -destination $Sourcedir\$Prereqdir\$FileName))
                { write-warning "Error Downloading file $Url, Please check connectivity"
                  Write-Warning "Creating Dummy File"
                  New-Item -ItemType file -Path "$Sourcedir\$Prereqdir\$FileName"
                }
            }

        
        }
    
    $Prereqdir = $EX_Version+"prereq"

    Write-Verbose "We are now going to Test $EX_Version Prereqs"
    $DownloadUrls = (
		        "http://download.microsoft.com/download/E/2/1/E21644B5-2DF2-47C2-91BD-63C560427900/NDP452-KB2901907-x86-x64-AllOS-ENU.exe",
#                "http://download.microsoft.com/download/A/A/3/AA345161-18B8-45AE-8DC8-DA6387264CB9/filterpack2010sp1-kb2460041-x64-fullfile-en-us.exe",
#                "http://download.microsoft.com/download/0/A/2/0A28BBFA-CBFA-4C03-A739-30CCA5E21659/FilterPack64bit.exe",
                "http://download.microsoft.com/download/2/C/4/2C47A5C1-A1F3-4843-B9FE-84C0032C61EC/UcmaRuntimeSetup.exe"
 #               "http://download.microsoft.com/download/6/2/D/62DFA722-A628-4CF7-A789-D93E17653111/ExchangeMapiCdo.EXE"
                
                ) 
    if (Test-Path -Path "$Sourcedir\$Prereqdir")
        {
        Write-Verbose "$EX_Version Sourcedir Found"
        }
        else
        {
        Write-Verbose "Creating Sourcedir for $EX_Version Prereqs"
        New-Item -ItemType Directory -Path $Sourcedir\$Prereqdir | Out-Null
        }


    foreach ($URL in $DownloadUrls)
        {
        $FileName = Split-Path -Leaf -Path $Url
        if (!(test-path  $Sourcedir\$Prereqdir\$FileName))
            {
            Write-Verbose "$FileName not found, trying Download"
            if (!(get-prereq -DownLoadUrl $URL -destination $Sourcedir\$Prereqdir\$FileName))
                { write-warning "Error Downloading file $Url, Please check connectivity"
                exit
                }
            }
        }

    write-verbose "Testing $Sourcedir/$EX_Version$e16_cu/setup.exe"
    if (Test-Path "$Sourcedir/$EX_Version$e16_cu/setup.exe")
        {
        Write-Verbose "E16 $e16_cu Found"
        }
        else
        {
        Write-Warning "We need to Extract $EX_Version $e16_cu, this may take a while"
        # New-Item -ItemType Directory -Path $Sourcedir\$EX_Version$ex_cu | Out-Null
        # }
        Switch ($e16_cu)

            {
                "final"
                {
                $URL = "http://download.microsoft.com/download/3/9/B/39B8DDA8-509C-4B9E-BCE9-4CD8CDC9A7DA/Exchange2016-x64.exe"
                }

            }

        $FileName = Split-Path -Leaf -Path $Url
        if (!(test-path  $Sourcedir\$FileName))
            {
            "We need to Download $EX_Version $e16_cu from $url, this may take a while"
            if (!(get-prereq -DownLoadUrl $URL -destination $Sourcedir\$FileName))
                { write-warning "Error Downloading file $Url, Please check connectivity"
                exit
            }
        }
        Write-Verbose "Extracting $FileName"
        Start-Process -FilePath "$Sourcedir\$FileName" -ArgumentList "/extract:$Sourcedir\$EX_Version$e16_cu /passive" -Wait
            
    } #end else
    if (!(Test-Path $Sourcedir\attachments))
        {
         Write-Warning "attachments Directory not found. Please Create $Sourcedir\attachments and copy some Documents for Mail and Public Folder Deployment"
            }
        else
            {
            Write-Verbose "Found attachments"
            }
	    if ($DAG.IsPresent)
	        {
		    Write-Host -ForegroundColor Yellow "We will form a $EXNodes-Node DAG"
	        }

}
#################### default Parameter Section Start
write-verbose "Config pre defaults"
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    write-output $PSCmdlet.MyInvocation.BoundParameters
    }
###################################################
## do we want defaults ?
if ($defaults.IsPresent)
    {
    if (Test-Path $Builddir\defaults.xml)
        {
        status "Loading defaults from $Builddir\defaults.xml"
        $Default = Get-LABDefaults
        }
        $DefaultGateway = $Default.DefaultGateway
        if (!$nmm_ver)
            {
            try
                {
                $nmm_ver = $Default.nmm_ver
                }
            catch
            [System.Management.Automation.ValidationMetadataException]
                {
                Write-Warning "defaulting NMM version to $latest_nmm"
                 $nmm_ver = $latest_nmm
                }
            } 
        $nmm_scvmm_ver = $nmm_ver -replace "nmm","scvmm"
        if (!$nw_ver)
            {
            try
                {
                $nw_ver = $Default.nw_ver
                }
            catch
            [System.Management.Automation.ValidationMetadataException]
                {
                Write-Warning "defaulting nw version to $latest_nw"
                 $nw_ver = $latest_nw
                }
            } 
        if (!$Masterpath)
            {
            try
                {
                $Masterpath = $Default.Masterpath
                }
            catch
                {
                Write-Warning "No Masterpath specified, trying default"
                $Masterpath = $Builddir
                }
            }
        if (!$Sourcedir)
            {
            try
                {
                $Sourcedir = $Default.Sourcedir
                }
            catch [System.Management.Automation.ParameterBindingException]
                {
                Write-Warning "No sources specified, trying default"
                $Sourcedir = $Sourcedirdefault
                }
            }
        if (!$Master) 
            {
            try
                {
                $master = $Default.master
                }
            catch 
                {
                Write-Warning "No Master specified, trying default"
                $Master = $latest_master
                }
            }
        if (!$SQLVER)
            {   
            try
                {
                $sqlver = $Default.sqlver
                }
            catch 
                {
                Write-Warning "No sqlver specified, trying default"
                $sqlver = $latest_sqlver
                }
            }
        if (!$ex_cu) 
            {
            try
                {
                $ex_cu = $Default.ex_cu
                }
            catch 
                {
                Write-Warning "No Master specified, trying default"
                $ex_cu = $latest_ex_cu
                }
            }
        if (!$e16_cu) 
            {
            try
                {
                $e16_cu = $Default.e16_cu
                }
            catch 
                {
                Write-Warning "No e16_cu specified, trying default"
                $e16_cu = $latest_e16_cu
                }
            }
        if (!$ScaleIOVer) 
            {
            try
                {
                $ScaleIOVer = $Default.ScaleIOVer
                }
            catch 
                {
                Write-Warning "No ScaleIOVer specified, trying default"
                $ScaleIOVer = $latest_ScaleIOVer
                }
            }
        if (!$vmnet) 
            {
            try
                {
                $vmnet = $Default.vmnet
                }
            catch 
                {
                Write-Warning "No vmnet specified, trying default"
                $vmnet = $Default_vmnet
                }
            }
        if (!$BuildDomain) 
            {
            try
                {
                $BuildDomain = $Default.BuildDomain
                }
            catch 
                {
                Write-Warning "No BuildDomain specified, trying default"
                $BuildDomain = $Default_BuildDomain
                }
            } 
        if  (!$MySubnet) 
            {
            try
                {
                $MySubnet = $Default.mysubnet
                }
            catch 
                {
                Write-Warning "No mysubnet specified, trying default"
                $MySubnet = $Default_Subnet
                }
            }
       if (!$vmnet) 
            {
            try
                {
                $vmnet = $Default.vmnet
                }
            catch 
                {
                Write-Warning "No vmnet specified, trying default"
                $vmnet = $Default_vmnet
                }
            }

       if (!$vlanID) 
            {
            try
                {
                $vlanID = $Default.vlanID
                }
            catch 
                {
                Write-Warning "No VLanIDt specified, trying default"
                $vlanID = $Default_vlanid
                }
            }


       if (!$AddressFamily) 
            {
            try
                {
                $AddressFamily = $Default.AddressFamily
                }
            catch 
                {
                Write-Warning "No AddressFamily specified, trying default"
                $AddressFamily = $Default_AddressFamily
                }
            }
       if (!$IPv6Prefix) 
            {
            try
                {
                $IPv6Prefix = $Default.IPv6Prefix
                }
            catch 
                {
                Write-Warning "No IPv6Prefix specified, trying default"
                $IPv6Prefix = $Default_IPv6Prefix
                }
            }
       if (!$IPv6PrefixLength) 
            {
            try
                {
                $IPv6PrefixLength = $Default.IPv6PrefixLength
                }
            catch 
                {
                Write-Warning "No IPv6PrefixLength specified, trying default"
                $IPv6PrefixLength = $Default_IPv6PrefixLength
                }
            }
        if (!($MyInvocation.BoundParameters.Keys.Contains("Gateway")))
            {
            if ($Default.Gateway -eq "true")
                {
                $Gateway = $true
                [switch]$NW = $True
                $DefaultGateway = "$IPv4Subnet.$Gatewayhost"
                }
            }
        if (!($MyInvocation.BoundParameters.Keys.Contains("NoDomainCheck")))
            {
            if ($Default.NoDomainCheck -eq "true")
                {
                [switch]$NoDomainCheck = $true
                }
            }
        if (!($MyInvocation.BoundParameters.Keys.Contains("NMM")))
            {
            if ($Default.NMM -eq "true")
                {
                $nmm = $true
                $nw = $true
                }
            }
    
    if (Test-Path "$Builddir\Switchdefaults.xml")
        {
        status "Loading Switchdefaults from $Builddir\Switchdefaults.xml"
        $SwitchDefault = Get-LABSwitchDefaults

        }
    $HVSwitch = $SwitchDefault.$($Vmnet)
    }

if (!$MySubnet) {$MySubnet = "192.168.2.0"}
$IPv4Subnet = convert-iptosubnet $MySubnet
if (!$BuildDomain) { $BuildDomain = $Default_BuildDomain }
if (!$ScaleIOVer) {$ScaleIOVer = $latest_ScaleIOVer}
if (!$SQLVER) {$SQLVER = $latest_sqlver}
if (!$ex_cu) {$ex_cu = $latest_ex_cu}
if (!$e16_cu) {$e16_cu = $latest_e16_cu}
if (!$Master) {$Master = $latest_master}
if (!$vmnet) {$vmnet = $Default_vmnet}
if (!$IPv6PrefixLength){$IPv6PrefixLength = $Default_IPv6PrefixLength}
if (!$IPv6Prefix){$IPv6Prefix = $Default_IPv6Prefix}

if (!$Default.DNS1)
    {
    $DNS1 = "$IPv4Subnet.10"
    } 
else 
    {
    $DNS1 = $Default.DNS1
    }
write-verbose "After defaults !!!! "
Write-Verbose "Sourcedir : $Sourcedir"
Write-Verbose "NWVER : $nw_ver"
Write-Verbose "Gateway : $($Gateway.IsPresent)"
Write-Verbose "NMM : $($nmm.IsPresent)"
Write-Verbose "MySubnet : $MySubnet"
Write-Verbose "ScaleIOVer : $ScaleIOVer"
Write-Verbose "Masterpath : $Masterpath"
Write-Verbose "Master : $Master"
Write-Verbose "VLanID : $vlanID"
Write-Verbose "Switch : $HVswitch"
Write-Verbose "Defaults before Safe:"

If ($DefaultGateway -match "$IPv4Subnet.$Gatewayhost")
    {
    $gateway = $true
    }
If ($Gateway.IsPresent)
            {
            $DefaultGateway = "$IPv4Subnet.$Gatewayhost"
            }
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
    {
    if (Test-Path $Builddir\defaults.xml)
        {
        Get-Content $Builddir\defaults.xml | Write-Host -ForegroundColor Gray
        }
    }

#### do we have unset parameters ?
if (!$AddressFamily){$AddressFamily = "IPv4" }

###################################################

if ($savedefaults.IsPresent)
{
$defaultsfile = New-Item -ItemType file $Builddir\defaults.xml -Force
Status "saving defaults to $Builddir\defaults.xml"
$config =@()
$config += ("<config>")
$config += ("<nmm_ver>$nmm_ver</nmm_ver>")
$config += ("<nw_ver>$nw_ver</nw_ver>")
$config += ("<master>$Master</master>")
$config += ("<sqlver>$SQLVER</sqlver>")
$config += ("<ex_cu>$ex_cu</ex_cu>")
$config += ("<e16_cu>$e16_cu</e16_cu>")
$config += ("<vmnet>$VMnet</vmnet>")
$config += ("<vlanID>$vlanID</vlanID>")
$config += ("<BuildDomain>$BuildDomain</BuildDomain>")
$config += ("<MySubnet>$MySubnet</MySubnet>")
$config += ("<AddressFamily>$AddressFamily</AddressFamily>")
$config += ("<IPV6Prefix>$IPV6Prefix</IPV6Prefix>")
$config += ("<IPv6PrefixLength>$IPv6PrefixLength</IPv6PrefixLength>")
$config += ("<Gateway>$($Gateway.IsPresent)</Gateway>")
$config += ("<DefaultGateway>$($DefaultGateway)</DefaultGateway>")
$config += ("<Sourcedir>$($Sourcedir)</Sourcedir>")
$config += ("<ScaleIOVer>$($ScaleIOVer)</ScaleIOVer>")
$config += ("<DNS1>$($DNS1)</DNS1>")
$config += ("<NMM>$($NMM.IsPresent)</NMM>")
$config += ("<Masterpath>$Masterpath</Masterpath>")
$config += ("<NoDomainCheck>$NoDomainCheck</NoDomainCheck>")
$config += ("<Puppet>$($Default.Puppet)</Puppet>")
$config += ("<PuppetMaster>$($Default.PuppetMaster)</PuppetMaster>")
$config += ("<Hostkey>$($Default.HostKey)</Hostkey>")
$config += ("</config>")
$config | Set-Content $defaultsfile
}
if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent -and $savedefaults.IsPresent )
    {
    Write-Verbose  "Defaults after Save"
    Get-Content $Builddir\defaults.xml | Write-Host -ForegroundColor Magenta
    }
if ($vlanID -eq 0)
    {
    $vlanID = ""
    }
####### Master Check
if (!$Sourcedir)
    {
    Write-Warning "no Sourcedir specified, will exit now"
    exit
    }
else
    {
    try
        {
        Get-Item -Path $Sourcedir -ErrorAction Stop | Out-Null 
        }
        catch
        [System.Management.Automation.DriveNotFoundException] 
        {
        Write-Warning "Drive not found, make sure to have your Source Stick connected"
        exit
        }
        catch [System.Management.Automation.ItemNotFoundException]
        {
        write-warning "no sources directory found named $Sourcedir"
        exit
        }
     }
if (!$Master)

    {
    Write-Warning "No Master was specified. See get-help .\labbuildr.ps1 -Parameter Master !!"
    Write-Warning "Load masters from $UpdateUri"
    break
    } # end Master

    Try
    {
    $MyMaster = get-childitem -path "$Masterpath\$Master\$Master.vhdx" -ErrorAction SilentlyContinue
    }
    catch [Exception] 
    {
    Write-Warning "Could not find $Masterpath\$Master\$Master.vhdx"
    Write-Warning "Please download a Master from https://github.com/bottkars/labbuildr-hyperv/wiki/Master"
    Write-Warning "And extract to $Masterpath"
    # write-verbose $_.Exception
    break
    }
if (!$MyMaster)
    {
    Write-Warning "Could not find $Masterpath\$Master"
    Write-Warning "Please download a Master from https://github.com/bottkars/labbuildr-hyperv/wiki/Master"
    Write-Warning "And extract to $Masterpath"
    # write-verbose $_.Exception
    break
    }
else
    {
   $MasterVHDX = $MyMaster.Fullname		
   Write-Verbose "We got master $MasterVHDX"
   }

write-verbose "After Masterconfig !!!! "

########

########


###### requirements check

if (!(test-path $Builddir\bin\mkisofs.exe -ErrorAction SilentlyContinue))
    {
    if (!(test-path $Builddir\bin\ -ErrorAction SilentlyContinue))
        {
        New-Item -ItemType Directory -Path $Builddir\bin\ 
        }
    Get-LABHttpFile -SourceURL "https://osspack32.googlecode.com/files/mkisofs.exe" -TarGetFile "$Builddir\bin\mkisofs.exe "
    Unblock-File -Path "$Builddir\bin\mkisofs.exe"
    }

switch ($PsCmdlet.ParameterSetName)

    {
    
    "DCOnly"
        {        
	    ###################################################
	    #
	    # DC Setup
	    #
	    ###################################################
        $DCName =  $BuildDomain+"DC"
        $NodeName = "DCNODE"
        $NodePrefix = "DCNode"
        $ScenarioScriptdir = "$GuestScriptdir\$NodePrefix"
        $NodeIP = "$IPv4Subnet.10"
        ####prepare iso
        Remove-Item -Path "$Isodir\scripts" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
        New-Item -ItemType Directory "$Isodir\scripts" -Force | Out-Null
        New-Item -ItemType Directory "$Builddir\$NodePrefix" -Force | Out-Null
        $Current_phase = "start-customize"
        $next_phase = "phase2"
        $Content = @()
        $Content = "###
`$logpath = `"c:\Scripts`"
if (!(Test-Path `$logpath))
    {
    New-Item -ItemType Directory -Path `$logpath -Force
    }

`$ScriptName = `$MyInvocation.MyCommand.Name
`$Host.UI.RawUI.WindowTitle = `$ScriptName
`$Logfile = New-Item -ItemType file `"c:\scripts\`$ScriptName.log`"
$NodeScriptDir\set-vmguesttask.ps1 -Task $Current_phase -Status started
#New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name '1-$Current_phase' -Value '$PSHOME\powershell.exe -Command `". $NodeScriptDir\set-vmguesttask.ps1 -Task $Current_phase -Status finished`"'
#New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name '2-Share' -Value '$PSHOME\powershell.exe -Command `". $NodeScriptDir\set-vmguestshare.ps1 -user $Labbuildr_share_User -password $Labbuildr_share_password`"'
New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name '99-$next_phase' -Value '$PSHOME\powershell.exe -Command `". $GuestScriptdir\scripts\run-$next_phase.ps1`"'
$ScenarioScriptdir\new-dc.ps1 -dcname $DCName -Domain $BuildDomain -IPv4subnet $IPv4subnet -IPv4Prefixlength $IPv4PrefixLength -IPv6PrefixLength $IPv6PrefixLength -IPv6Prefix $IPv6Prefix -AddressFamily $AddressFamily
"
# $ScenarioScriptdir\new-dc.ps1 -dcname $DCName -Domain $BuildDomain -IPv4subnet $IPv4subnet -IPv4Prefixlength $IPv4PrefixLength -IPv6PrefixLength $IPv6PrefixLength -IPv6Prefix $IPv6Prefix -AddressFamily $AddressFamily #-setwsman $CommonParameter

Write-Verbose $Content
Set-Content "$Isodir\Scripts\$Current_phase.ps1" -Value $Content -Force
        
######## Phase 2
       $previous_phase = $current_phase
       $current_phase = $next_phase
       $next_phase = "phase3"
       $Content = @()
       $Content = "###
`$ScriptName = `$MyInvocation.MyCommand.Name
`$Host.UI.RawUI.WindowTitle = `$ScriptName
`$Logfile = New-Item -ItemType file `"c:\scripts\`$ScriptName.log`"
$NodeScriptDir\set-vmguesttask.ps1 -Task $current_phase -Status started
$NodeScriptDir\set-vmguesttask.ps1 -Task $previous_phase -Status finished
New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name '99-$next_phase' -Value '$PSHOME\powershell.exe -Command `". $GuestScriptdir\scripts\run-$next_phase.ps1`"'
Set-ExecutionPolicy -ExecutionPolicy bypass -Force
$NodeScriptDir\set-vmguestshare.ps1 -user $Labbuildr_share_User -password $Labbuildr_share_password
$ScenarioScriptdir\finish-domain.ps1 -domain $BuildDomain -domainsuffix $domainsuffix
"
Write-Verbose $Content
Set-Content "$Isodir\Scripts\run-$Current_phase.ps1" -Value $Content -Force
## end Phase2 


### phase 3
       $previous_phase = $current_phase
       $current_phase = $next_phase
       $next_phase = "phase4"
       $Content = @()
       $Content = "###
`$ScriptName = `$MyInvocation.MyCommand.Name
`$Host.UI.RawUI.WindowTitle = `$ScriptName
`$Logfile = New-Item -ItemType file `"c:\scripts\`$ScriptName.log`"
$NodeScriptDir\set-vmguesttask.ps1 -Task $current_phase -Status started
New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name '99-$next_phase' -Value '$PSHOME\powershell.exe -Command `". $GuestScriptdir\scripts\run-$next_phase.ps1`"'
$NodeScriptDir\set-vmguesttask.ps1 -Task $previous_phase -Status finished
Set-ExecutionPolicy -ExecutionPolicy bypass -Force
$ScenarioScriptdir\dns.ps1 -IPv4subnet $IPv4Subnet -IPv4Prefixlength $IPV4PrefixLength -IPv6PrefixLength $IPv6PrefixLength -AddressFamily $AddressFamily  -IPV6Prefix $IPV6Prefix
$ScenarioScriptdir\add-serviceuser.ps1
$ScenarioScriptdir\pwpolicy.ps1 
#$NodeScriptDir\set-winrm.ps1 -Scriptdir $GuestScriptdir
restart-computer -force
"
Write-Verbose $Content
Set-Content "$Isodir\Scripts\run-$Current_phase.ps1" -Value $Content -Force
###end phase 3
## Phase 4
       $previous_phase = $current_phase
       $current_phase = $next_phase
       $next_phase = "phase5"
       $Content = @()
       $Content = "###
`$ScriptName = `$MyInvocation.MyCommand.Name
`$Host.UI.RawUI.WindowTitle = `$ScriptName
`$Logfile = New-Item -ItemType file `"c:\scripts\`$ScriptName.log`"
$NodeScriptDir\set-vmguesttask.ps1 -Task $current_phase -Status started
New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name '99-$next_phase' -Value '$PSHOME\powershell.exe -Command `". $GuestScriptdir\scripts\run-$next_phase.ps1`"'
$NodeScriptDir\set-vmguesttask.ps1 -Task $previous_phase -Status finished
$NodeScriptDir\powerconf.ps1 -Scriptdir $GuestScriptdir
$NodeScriptDir\set-uac.ps1 -Scriptdir $GuestScriptdir
$NodeScriptDir\set-winrm.ps1 -Scriptdir $GuestScriptdir
restart-computer -force
"
        Write-Verbose $Content
        Set-Content "$Isodir\Scripts\run-$Current_phase.ps1" -Value $Content -Force
## end Phase4       
        
### phase 5
       $previous_phase = $current_phase
       $current_phase = $next_phase
       #$next_phase = "finished"
       $Content = @()
       $Content = "###
`$ScriptName = `$MyInvocation.MyCommand.Name
`$Host.UI.RawUI.WindowTitle = `$ScriptName
`$Logfile = New-Item -ItemType file `"c:\scripts\`$ScriptName.log`"
$NodeScriptDir\set-vmguesttask.ps1 -Task $previous_phase -Status finished
$NodeScriptDir\set-vmguesttask.ps1 -Task $current_phase -Status started
$NodeScriptDir\set-vmguestshare.ps1 -user $Labbuildr_share_User -password $Labbuildr_share_password
$NodeScriptDir\set-vmguesttask.ps1 -Task $current_phase -Status finished
#New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name '99-$next_phase' -Value '$PSHOME\powershell.exe -Command `". $Isodir\scripts\run-$next_phase.ps1`"'
"
        Write-Verbose $Content
        Set-Content "$Isodir\Scripts\run-$Current_phase.ps1" -Value $Content -Force
## end Phase5  


        
####### Iso Creation        
        $Isocreatio = make-iso -Nodename $NodeName -Builddir $Builddir -isodir $Isodir



####### clone creation
        if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
            {
            Write-Verbose "Press any Key to continue to Cloning"
            pause
            }
        If ($vlanID)
            {
            Invoke-Expression  "$Builddir\clone-node.ps1 -MasterVHD $MasterVHDX -Nodename $NodeName -Size L -HVSwitch $HVSwitch -vlanid $vlanID $CommonParameter"
            }
        else
            {
            Invoke-Expression  "$Builddir\clone-node.ps1 -MasterVHD $MasterVHDX -Nodename $NodeName -Size L -HVSwitch $HVSwitch $CommonParameter"
            }

####### wait progress
        $SecurePassword = $Adminpassword | ConvertTo-SecureString -AsPlainText -Force
        $Credential = New-Object –TypeName System.Management.Automation.PSCredential –ArgumentList $Adminuser, $SecurePassword

check-task -task "start-customize" -nodename $NodeName -sleep $Sleep
foreach ($n in 2..5)
    {

check-task -task "phase$n" -nodename $NodeName -sleep $Sleep 


    }
        }#end dconly

	"Blanknodes" {
        if ($Disks)
            {
		    $cloneparm = " -AddDisks -disks $Disks"
            }
        $AddonFeatures = "RSAT-ADDS, RSAT-ADDS-TOOLS, AS-HTTP-Activation, NET-Framework-45-Features"
        if ($Cluster.IsPresent) {$AddonFeatures = "$AddonFeatures, Failover-Clustering, RSAT-Clustering, WVR"}

		foreach ($Node in ($Blankstart..$BlankNodes))
		{
			
	    ###################################################
	    #
	    # BlanknodeSetup
	    #			test-dcrunning
	    ###################################################
        $Nodeip = "$IPv4Subnet.18$Node"
        $Nodeprefix = "Node"
		$Nodename = "Node$Node"
        $ScenarioScriptdir = "$GuestScriptdir\$NodePrefix"
        Write-Verbose $IPv4Subnet
        write-verbose $Nodename
        write-verbose $Nodeip
        ####prepare iso
        Remove-Item -Path "$Isodir\scripts" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
        New-Item -ItemType Directory "$Isodir\scripts" -Force | Out-Null
        New-Item -ItemType Directory "$Builddir\$NodePrefix" -Force | Out-Null
        $Current_phase = "start-customize"
        $next_phase = "phase2"
        $Content = @()
        $Content = "###
`$logpath = `"c:\Scripts`"
if (!(Test-Path `$logpath))
    {
    New-Item -ItemType Directory -Path `$logpath -Force
    }

`$ScriptName = `$MyInvocation.MyCommand.Name
`$Host.UI.RawUI.WindowTitle = `$ScriptName
`$Logfile = New-Item -ItemType file `"c:\scripts\`$ScriptName.log`"
$NodeScriptDir\set-vmguesttask.ps1 -Task $Current_phase -Status started
New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name '99-$next_phase' -Value '$PSHOME\powershell.exe -Command `". $GuestScriptdir\scripts\run-$next_phase.ps1`"'
$ScenarioScriptdir\configurenode.ps1 -nodeip $Nodeip -IPv4subnet $IPv4subnet -nodename $Nodename -IPv4PrefixLength $IPv4PrefixLength -IPv6PrefixLength $IPv6PrefixLength -IPv6Prefix $IPv6Prefix -AddressFamily $AddressFamily $AddGateway -AddOnfeatures $AddonFeatures -Domain $BuildDomain $CommonParameter
"
# $ScenarioScriptdir\new-dc.ps1 -dcname $DCName -Domain $BuildDomain -IPv4subnet $IPv4subnet -IPv4Prefixlength $IPv4PrefixLength -IPv6PrefixLength $IPv6PrefixLength -IPv6Prefix $IPv6Prefix -AddressFamily $AddressFamily #-setwsman $CommonParameter

        Write-Verbose $Content
        Write-Verbose ""
        Set-Content "$Isodir\Scripts\$Current_phase.ps1" -Value $Content -Force
        

######## Phase 2
       $previous_phase = $current_phase
       $current_phase = $next_phase
       $next_phase = "phase3"
       $Content = @()
       $Content = "###
`$ScriptName = `$MyInvocation.MyCommand.Name
`$Host.UI.RawUI.WindowTitle = `$ScriptName
`$Logfile = New-Item -ItemType file `"c:\scripts\`$ScriptName.log`"
$NodeScriptDir\set-vmguesttask.ps1 -Task $current_phase -Status started
$NodeScriptDir\set-vmguesttask.ps1 -Task $previous_phase -Status finished
New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name '99-$next_phase' -Value '$PSHOME\powershell.exe -Command `". $GuestScriptdir\scripts\run-$next_phase.ps1`"'
Set-ExecutionPolicy -ExecutionPolicy bypass -Force
$NodeScriptDir\set-vmguestshare.ps1 -user $Labbuildr_share_User -password $Labbuildr_share_password
$ScenarioScriptdir\addtodomain.ps1 -Domain $BuildDomain -domainsuffix $domainsuffix -subnet $IPv4subnet -IPV6Subnet $IPv6Prefix -AddressFamily $AddressFamily
"
        Write-Verbose $Content
        Write-Verbose ""
        Set-Content "$Isodir\Scripts\run-$Current_phase.ps1" -Value $Content -Force
## end Phase2 
       if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
            { 
            Write-verbose "Now Pausing"
            pause
            }


####### Iso Creation        
        $Isocreatio = make-iso -Nodename $NodeName -Builddir $Builddir -isodir $Isodir



####### clone creation
        if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
            {
            Write-Verbose "Press any Key to continue to Cloning"
            pause
            }
        If ($vlanID)
            {
            Invoke-Expression  "$Builddir\clone-node.ps1 -MasterVHD $MasterVHDX -Nodename $NodeName -Size L -HVSwitch $HVSwitch -vlanid $vlanID $CommonParameter"
            }
        else
            {
            Invoke-Expression  "$Builddir\clone-node.ps1 -MasterVHD $MasterVHDX -Nodename $NodeName -Size L -HVSwitch $HVSwitch $CommonParameter"
            }

####### wait progress
        check-task -task "start-customize" -nodename $NodeName -sleep $Sleep
        foreach ($n in 2..2)
            {

            check-task -task "phase$n" -nodename $NodeName -sleep $Sleep 

            }
			<# Clone Base Machine
			status $Commentline
			status "Creating Blank Node Host $Nodename with IP $Nodeip"
			if ($VTbit)
			{
				$CloneOK = Invoke-expression "$Builddir\$Script_dir\clone-node.ps1 -Scenario $Scenario -Scenarioname $Scenarioname -Activationpreference $Node -Builddir $Builddir -Mastervmx $MasterVMX -Nodename $Nodename -Clonevmx $CloneVMX -vmnet $VMnet -Domainname $BuildDomain -Hyperv -size $size -Sourcedir $Sourcedir $cloneparm"
			}
			else
			{
				$CloneOK = Invoke-expression "$Builddir\$Script_dir\clone-node.ps1 -Scenario $Scenario -Scenarioname $Scenarioname -Activationpreference $Node -Builddir $Builddir -Mastervmx $MasterVMX -Nodename $Nodename -Clonevmx $CloneVMX -vmnet $VMnet -Domainname $BuildDomain -size $Size -Sourcedir $Sourcedir $cloneparm"
			}
			###################################################
			If ($CloneOK)
			{
				write-verbose "Copy Configuration files, please be patient"
				copy-tovmx -Sourcedir $NodeScriptDir
				write-verbose "Waiting System Ready"
				test-user -whois Administrator
				write-Verbose "Starting Customization"
				domainjoin -Nodename $Nodename -Nodeip $Nodeip -BuildDomain $BuildDomain -AddressFamily $AddressFamily -AddOnfeatures $AddonFeatures
                if ($NW.IsPresent)
                    {
                    write-verbose "Install NWClient"
		            invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script install-nwclient.ps1 -interactive -Parameter $nw_ver
                    }
				invoke-postsection
			}# end Cloneok
			
		} # end foreach

    	if ($Cluster.IsPresent)
		    {
			write-host
			write-verbose "Forming Blanknode Cluster"
			invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script createcluster.ps1 -Parameter "-Nodeprefix 'NODE' -IPAddress '$IPv4Subnet.180' -IPV6Prefix $IPV6Prefix -IPv6PrefixLength $IPv6PrefixLength -AddressFamily $AddressFamily $CommonParameter" -interactive
		    }
#>
	} 

}## End Switchblock Blanknode 

<#
   	"E16"{
        Write-Verbose "Starting $EX_Version $e16_cu Setup"
        # we need ipv4
        if ($AddressFamily -notmatch 'ipv4')
            { 
            $EXAddressFamiliy = 'IPv4IPv6'
            }
        else
        {
        $EXAddressFamiliy = $AddressFamily
        }
        if ($DAG.IsPresent)
            {
            Write-Warning "Running e16 Avalanche Install"

            if ($DAGNOIP.IsPresent)
			    {
				$DAGIP = ([System.Net.IPAddress])::None
			    }
			else
                {
                $DAGIP = "$IPv4subnet.110"
                }
        }
                $DCName =  $BuildDomain+"DC"

		foreach ($EXNODE in ($EXStartNode..($EXNodes+$EXStartNode-1)))
            {
			###################################################
			# Setup e16 Node
			# Init
			$Nodeip = "$IPv4Subnet.12$EXNODE"
			$Nodename = "$EX_Version"+"N"+"$EXNODE"
            $NodePrefix = $EX_Version
			$ScenarioScriptdir = "$GuestScriptdir\$NodePrefix"
		    $SourceScriptDir = "$Builddir\$Script_dir\$EX_Version\"
		    # $Exprereqdir = "$Sourcedir\EXPREREQ\"
            $AddonFeatures = "RSAT-ADDS, RSAT-ADDS-TOOLS, AS-HTTP-Activation, NET-Framework-45-Features"
            # $AddonFeatures = "$AddonFeatures, RSAT-DNS-SERVER, Desktop-Experience, RPC-over-HTTP-proxy, RSAT-Clustering, RSAT-Clustering-CmdInterface, Web-Mgmt-Console, WAS-Process-Model, Web-Asp-Net45, Web-Basic-Auth, Web-Client-Auth, Web-Digest-Auth, Web-Dir-Browsing, Web-Dyn-Compression, Web-Http-Errors, Web-Http-Logging, Web-Http-Redirect, Web-Http-Tracing, Web-ISAPI-Ext, Web-ISAPI-Filter, Web-Lgcy-Mgmt-Console, Web-Metabase, Web-Mgmt-Console, Web-Mgmt-Service, Web-Net-Ext45, Web-Request-Monitor, Web-Server, Web-Stat-Compression, Web-Static-Content, Web-Windows-Auth, Web-WMI, Windows-Identity-Foundation" 
            $AddonFeatures = "$AddonFeatures, AS-HTTP-Activation, Desktop-Experience, NET-Framework-45-Features, RPC-over-HTTP-proxy, RSAT-Clustering, RSAT-Clustering-CmdInterface, RSAT-Clustering-Mgmt, RSAT-Clustering-PowerShell, Web-Mgmt-Console, WAS-Process-Model, Web-Asp-Net45, Web-Basic-Auth, Web-Client-Auth, Web-Digest-Auth, Web-Dir-Browsing, Web-Dyn-Compression, Web-Http-Errors, Web-Http-Logging, Web-Http-Redirect, Web-Http-Tracing, Web-ISAPI-Ext, Web-ISAPI-Filter, Web-Lgcy-Mgmt-Console, Web-Metabase, Web-Mgmt-Console, Web-Mgmt-Service, Web-Net-Ext45, Web-Request-Monitor, Web-Server, Web-Stat-Compression, Web-Static-Content, Web-Windows-Auth, Web-WMI, Windows-Identity-Foundation"


			###################################################
	    	
            Write-Verbose $IPv4Subnet
            Write-Verbose "IPv4PrefixLength = $IPv4PrefixLength"
            write-verbose $Nodename
            write-verbose $Nodeip
            Write-Verbose "IPv6Prefix = $IPV6Prefix"
            Write-Verbose "IPv6PrefixLength = $IPv6PrefixLength"
            Write-Verbose "Addressfamily = $AddressFamily"
            Write-Verbose "EXAddressFamiliy = $EXAddressFamiliy"
            if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
                { 
                Write-verbose "Now Pausing"
                pause
                }
            $Exchangesize = "XXL"
		    # test-dcrunning
		    







		    ###################################################
		    If ($CloneOK)
            {
            $EXnew = $True
			write-verbose "Copy Configuration files, please be patient"
			copy-tovmx -Sourcedir $NodeScriptDir
			copy-tovmx -Sourcedir $SourceScriptDir
			# copy-tovmx -Sourcedir $Exprereqdir
			write-verbose "Waiting System Ready"
			test-user -whois Administrator
			write-Verbose "Starting Customization"
			domainjoin -Nodename $Nodename -Nodeip $Nodeip -BuildDomain $BuildDomain -AddressFamily $EXAddressFamiliy -AddOnfeatures $AddonFeatures
			write-verbose "Setup Database Drives"
			invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script prepare-disks.ps1
			write-verbose "Setup e16 Prereqs"
			invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script install-exchangeprereqs.ps1 -interactive
            checkpoint-progress -step exprereq -reboot -Guestuser $Adminuser -Guestpassword $Adminpassword
			write-verbose "Setting Power Scheme"
			invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script powerconf.ps1 -interactive
			write-verbose "Installing e16, this may take up to 60 Minutes ...."
			invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script install-exchange.ps1 -interactive -nowait -Parameter "$CommonParameter -ex_cu $e16_cu"
            }
            }
        if ($EXnew)
        {
        foreach ($EXNODE in ($EXStartNode..($EXNodes+$EXStartNode-1)))
            {
            $Nodename = "$EX_Version"+"N"+"$EXNODE"
            $CloneVMX = (get-vmx $Nodename).config
            # 
			test-user -whois Administrator
            status "Waiting for Pass 4 (e16 Installed) for $Nodename"
            #$EXSetupStart = Get-Date
			    While ($FileOK = (&$vmrun -gu $BuildDomain\Administrator -gp Password123! fileExistsInGuest $CloneVMX c:\$Script_dir\exchange.pass) -ne "The file exists.")
			    {
				    sleep $Sleep
				    #runtime $EXSetupStart "Exchange"
			    } #end while
			    Write-Host
                    do {
                        $ToolState = Get-VMXToolsState -config $CloneVMX
                         Write-Verbose $ToolState.State
                        }
                    until ($ToolState.state -match "running")
            write-Verbose "Performing e16 Post Install Tasks:"
    		invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script configure-exchange.ps1 -interactive
     
    
    #  -nowait
            if ($EXNode -eq ($EXNodes+$EXStartNode-1)) #are we last sever in Setup ?!
                {
                if ($DAG.IsPresent) 
                    {
				    write-verbose "Creating DAG"
				    invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -activeWindow -interactive -Script create-dag.ps1 -Parameter "-DAGIP $DAGIP -AddressFamily $EXAddressFamiliy -EX_Version $EX_Version $CommonParameter"
				    } # end if $DAG
                if (!($nouser.ispresent))
                    {
                    write-verbose "Creating Accounts and Mailboxes:"
	                do
				        {
					    ($cmdresult = &$vmrun -gu "$BuildDomain\Administrator" -gp Password123! runPrograminGuest  $CloneVMX -activeWindow -interactive c:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe ". 'C:\Program Files\Microsoft\Exchange Server\V15\bin\RemoteExchange.ps1'; Connect-ExchangeServer -auto; C:\$Script_dir\User.ps1 -subnet $IPv4Subnet -AddressFamily $AddressFamily -IPV6Prefix $IPV6Prefix $CommonParameter") 
					    if ($BugTest) { debug $Cmdresult }
				        }
				    until ($VMrunErrorCondition -notcontains $cmdresult)
                    } #end creatuser
            }# end if last server
       }      
		
        foreach ($EXNODE in ($EXStartNode..($EXNodes+$EXStartNode-1)))
            {
            $Nodename = "$EX_Version"+"N"+"$EXNODE"
            $CloneVMX = (get-vmx $Nodename).config				
			write-verbose "Setting Local Security Policies"
			invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script create-security.ps1 -interactive
			########### Entering networker Section ##############
			if ($NMM.IsPresent)
			{
				write-verbose "Install NWClient"
				invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script install-nwclient.ps1 -interactive -Parameter $nw_ver
				write-verbose "Install NMM"
				invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script install-nmm.ps1 -interactive -Parameter $nmm_ver
			    write-verbose "Performin NMM Post Install Tasks"
			    invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $Targetscriptdir -Script finish-nmm.ps1 -interactive
            }# end nmm
			########### leaving NMM Section ###################
		    invoke-postsection
    }#end foreach exnode
        }
} #End Switchblock Exchange

#>    
    
    
}
