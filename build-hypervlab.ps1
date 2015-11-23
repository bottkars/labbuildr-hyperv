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
	[Parameter(ParameterSetName = "update",Mandatory = $false, HelpMessage = "select a branch to update from")][ValidateSet('develop','testing','master')]$branch  = "develop",
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
	[Parameter(ParameterSetName = "Blanknodes")][switch][alias('bnhv')]$BlankHV,
	[Parameter(ParameterSetName = "Blanknodes")][switch][alias('S2D')]$SpacesDirect,
	[Parameter(ParameterSetName = "Blanknodes")][string][alias('CLN')]$ClusterName,
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
    <#
    Determines if Exchange should be installed in a DAG
    #>
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)][switch]$DAG,
    <# Specify the Number of Exchange Nodes#>
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
    [Parameter(ParameterSetName = "E15", Mandatory = $false)][ValidateRange(1, 10)][int][alias('exn')]$EXNodes,
    <# Specify the Starting exchange Node#>
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)][ValidateRange(1, 9)][int][alias('exs')]$EXStartNode = "1",
<#
    Determines Exchange CU Version to be Installed
    Valid Versions are:
    'cu1','cu2','cu3','cu4','sp1','cu6','cu7'
    Default is latest
    CU Location is [Driveletter]:\sources\e2013[cuver], e.g. c:\sources\e2013cu7
    #>
	[Parameter(ParameterSetName = "E15", Mandatory = $false)]
    [ValidateSet('cu1', 'cu2', 'cu3', 'sp1','cu5','cu6','cu7','cu8','cu9','cu10')]$ex_cu,
    <# schould we prestage users ? #>	
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
    [Parameter(ParameterSetName = "E15", Mandatory = $false)][switch]$nouser,
    <# Install a DAG without Management IP Address ? #>
    [Parameter(ParameterSetName = "E16", Mandatory = $false)]
	[Parameter(ParameterSetName = "E15", Mandatory = $false)][switch]$DAGNOIP,
    <#
    Specify if Networker Scenario sould be installed
    IP-Addresses: .11
    #>
    [Parameter(ParameterSetName = "NWserver", Mandatory = $false)]
	[switch][alias('nsr')]$NWServer,

    <# Starting Node for Blank Nodes#>
    [Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)][ValidateRange(1, 12)][alias('bs')]$Blankstart = "1",
    <# How many Blank Nodes#>
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)][ValidateRange(1, 12)][alias('bns')]$BlankNodes = "1",

    #>
	[Parameter(ParameterSetName = "SCOM", Mandatory = $true)][switch][alias('SC_OM')]$SCOM,
    [Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
    [ValidateSet('SC2012_R2_SCOM','SCTP3_SCOM','SCTP4_SCOM')]$SCOM_VER = "SC2012_R2_SCOM",
    <#


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
    '2012R2FallUpdate','2016TP3','2016TP4'
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
    [ValidateSet('2016TP4','2016TP3','2012R2FallUpdate')]$Master,

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
    <#
    'SQL2012SP1',SQL2012SP2,SQL2012SP1SLIP, 'SQL2014'
    SQL version to be installed
    Needs to have:
    [sources]\SQL2012SP1 or
    [sources]\SQL2014
    #>
    [Parameter(ParameterSetName = "Sharepoint",Mandatory = $false)]
	[Parameter(ParameterSetName = "SQL", Mandatory = $false)]
	[Parameter(ParameterSetName = "AAG", Mandatory = $false)]
	[Parameter(ParameterSetName = "Hyperv", Mandatory = $false)]
	[Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
	[Parameter(ParameterSetName = "SCVMM", Mandatory = $false)]
	[ValidateSet('SQL2014SP1slip','SQL2012','SQL2012SP1','SQL2012SP2','SQL2012SP1SLIP','SQL2014')]$SQLVER,


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
    [Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
	[Parameter(ParameterSetName = "SCVMM", Mandatory = $false)]
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
	[Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
	[Parameter(ParameterSetName = "SCVMM", Mandatory = $false)]
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
	[Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
	[Parameter(ParameterSetName = "SCVMM", Mandatory = $false)]
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
	[Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
	[Parameter(ParameterSetName = "SCVMM", Mandatory = $false)]
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
	[Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
	[Parameter(ParameterSetName = "SCVMM", Mandatory = $false)]
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
	[Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
	[Parameter(ParameterSetName = "SCVMM", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint", Mandatory = $false)]
	[ValidateSet('nmm8211','nmm8212','nmm8214','nmm8216','nmm8217','nmm8218','nmm822','nmm821','nmm300', 'nmm301', 'nmm2012', 'nmm3012', 'nmm82','nmm85','nmm85.BR1','nmm85.BR2','nmm85.BR3','nmm85.BR4','nmm90.DA','nmm9001')]
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
	[Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
	[Parameter(ParameterSetName = "SCVMM", Mandatory = $false)]
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
	[Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
	[Parameter(ParameterSetName = "SCVMM", Mandatory = $false)]
    [ValidateSet('nw822','nw8218','nw8217','nw8216','nw8215','nw8214','nw8213','nw8212','nw8211','nw821','nw8205','nw8204','nw8203','nw8202','nw82','nw8116','nw8115','nw8114', 'nw8113','nw8112', 'nw811',  'nw8105','nw8104','nw8102', 'nw81','nw85','nw85.BR1','nw85.BR2','nw85.BR3','nw85.BR4','nw90.DA','nw9001','nwunknown')]
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
	[Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
	[Parameter(ParameterSetName = "SCVMM", Mandatory = $false)]
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
	[Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
	[Parameter(ParameterSetName = "SCVMM", Mandatory = $false)]
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
	[Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
	[Parameter(ParameterSetName = "SCVMM", Mandatory = $false)]
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
	[Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
	[Parameter(ParameterSetName = "SCVMM", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint",Mandatory = $false)]
    $IPv6PrefixLength,
    <# wait for deployment phases to finish befor next clone#>
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
	[Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
	[Parameter(ParameterSetName = "SCVMM", Mandatory = $false)]
    [Parameter(ParameterSetName = "Sharepoint", Mandatory = $false)]
	[switch]$wait,

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
$latest_nmm = 'nmm9001'
$latest_nw = 'nw9001'
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
$Scripts = "Scripts"
$Sourceslink = "https://my.syncplicity.com/share/wmju8cvjzfcg04i/sources"
$Buildname = Split-Path -Leaf $Builddir
$Scenarioname = "default"
$Scenario = 1
$AddonFeatures = ("RSAT-ADDS", "RSAT-ADDS-TOOLS", "AS-HTTP-Activation", "NET-Framework-45-Features")
$Gatewayhost = "11" 
$Host.UI.RawUI.WindowTitle = "$Buildname"
$IN_Guest_Sourcepath = "X:"
$IN_Guest_Scriptpath = "Y:"
$IN_Guest_CD_Scriptdir = "D:"
$IN_Guest_LogDir = "C:\$Scripts"
$IN_Node_ScriptDir = "$IN_Guest_CD_Scriptdir\Node"

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
						    $newDir = New-Item -ItemType Directory -Path "$Updatepath" | out-null
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

function test-source
{
	param ($SourceVer, $SourceDir)
	
	
	$SourceFiles = (Get-ChildItem $SourceDir -ErrorAction SilentlyContinue).Name
	#####
	
	foreach ($Version in ($Sourcever))
	{
		if ($Version -ne "")
		{
			write-verbose "Checking $Version"
			if (!($SourceFiles -contains $Version))
			{
				write-Host "$Sourcedir does not contain $Version"
				debug "Please Download and extraxt $Version to $Sourcedir\$Version"
				$Sourceerror = $true
			}
			else { write-verbose "found $Version, good..." }
		}
		
	}
	If ($Sourceerror) { return, $false }
	else { return, $true }
}

function get-prereq
{ 
param ([string]$DownLoadUrl,
        [string]$destination)
$ReturnCode = $True
if (!(Test-Path $Destination))
    {
        Try 
        {
        if (!(Test-Path (Split-Path $destination)))
            {
            New-Item -ItemType Directory  -Path (Split-Path $destination) -Force | out-null
            }
        Write-verbose "Starting Download of $DownLoadUrl to $destination"
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

function test-dcrunning
{
	$Origin = $MyInvocation.MyCommand
    
    try
        {
        $dcnode_status = get-vm DCNODE  -ErrorAction stop | where {$_.path -eq "$Builddir\dcnode"} -ErrorAction stop
        }
    catch 
        {
        Write-Warning "No dc installed for $Builddir labbuildr environment"
        break
        }
    $Running_Domain = get-vmguesttask -Node DCNode -Task Domain
    $Running_IP = get-vmguesttask -Node dcnode -Task IPAddress
    if ($dcnode_status.state -ne "running")
        {
        write-warning "DCNode not running, we need to start it first"
        $dcnode_status | Start-VM
        # Break
        }
  <#  if (!$NoDomainCheck.IsPresent)
	}#end if
	else
# } end nodomaincheck#>
return $True
} #end test-dcrunning

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
    if (!(test-path "$Builddir\$Nodename\"))
        {
        New-Item -ItemType Directory "$Builddir\$Nodename\" | out-null
        }
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
############################### phase fuctions
function run-startcustomize
{
param (
[string]$next_phase,
[string]$Current_phase
)    
$Content = @()
$Content = "###
`$logpath = `"c:\$Scripts`"
if (!(Test-Path `$logpath))
    {
    New-Item -ItemType Directory -Path `$logpath -Force
    }

`$ScriptName = `$MyInvocation.MyCommand.Name
`$Host.UI.RawUI.WindowTitle = `$ScriptName
`$Logfile = New-Item -ItemType file `"c:\$Scripts\`$ScriptName.log`"
$IN_Node_ScriptDir\set-vmguesttask.ps1 -Task $Current_phase -Status started
New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name '99-$next_phase' -Value '$PSHOME\powershell.exe -Command `". $IN_Guest_CD_Scriptdir\$Scripts\run-$next_phase.ps1`"'
$IN_Node_ScriptDir\configure-node.ps1 -nodeip $Nodeip -IPv4subnet $IPv4subnet -nodename $Nodename -IPv4PrefixLength $IPv4PrefixLength -IPv6PrefixLength $IPv6PrefixLength -IPv6Prefix $IPv6Prefix -AddressFamily $AddressFamily $AddGateway -AddOnfeatures '$AddonFeatures' -Domain $BuildDomain $CommonParameter
"
Write-Verbose $Content
Write-Verbose ""
Set-Content "$Isodir\$Scripts\$Current_phase.ps1" -Value $Content -Force
}
function run-phase1
{
param (
[string]$next_phase,
[string]$Current_phase
)


}
function run-phase2
{
param (
[string]$next_phase,
[string]$Current_phase
)
$Content = @()
$Content = "###
`$ScriptName = `$MyInvocation.MyCommand.Name
`$Host.UI.RawUI.WindowTitle = `$ScriptName
`$Logfile = New-Item -ItemType file `"c:\$Scripts\`$ScriptName.log`"
$IN_Node_ScriptDir\set-vmguesttask.ps1 -Task $current_phase -Status started
$IN_Node_ScriptDir\set-vmguesttask.ps1 -Task $previous_phase -Status finished
New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name '99-$next_phase' -Value '$PSHOME\powershell.exe -Command `". $IN_Guest_CD_Scriptdir\$Scripts\run-$next_phase.ps1`"'
Set-ExecutionPolicy -ExecutionPolicy bypass -Force
$IN_Node_ScriptDir\add-todomain.ps1 -Domain $BuildDomain -domainsuffix $domainsuffix -subnet $IPv4subnet -IPV6Subnet $IPv6Prefix -AddressFamily $AddressFamily -scriptdir $IN_Guest_CD_Scriptdir
"
Write-Verbose ""
Write-Verbose "$Content"
Write-Verbose ""
Set-Content "$Isodir\$Scripts\run-$Current_phase.ps1" -Value $Content -Force


}
function run-phase3
{
param (
[string]$next_phase,
[string]$Current_phase
)
$Content = @()
$Content = "###
`$ScriptName = `$MyInvocation.MyCommand.Name
`$Host.UI.RawUI.WindowTitle = `$ScriptName
`$Logfile = New-Item -ItemType file `"c:\$Scripts\`$ScriptName.log`"
$IN_Node_ScriptDir\set-vmguesttask.ps1 -Task $current_phase -Status started
New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name '99-$next_phase' -Value '$PSHOME\powershell.exe -Command `". $IN_Guest_CD_Scriptdir\$Scripts\run-$next_phase.ps1`"'
$IN_Node_ScriptDir\set-vmguesttask.ps1 -Task $previous_phase -Status finished
Set-ExecutionPolicy -ExecutionPolicy bypass -Force
$IN_Node_ScriptDir\powerconf.ps1 -Scriptdir $IN_Guest_CD_Scriptdir
$IN_Node_ScriptDir\set-uac.ps1 -Scriptdir $IN_Guest_CD_Scriptdir
$IN_Node_ScriptDir\set-winrm.ps1 -Scriptdir $IN_Guest_CD_Scriptdir
"

        if ($nw.IsPresent)
            {
            $Content += "$IN_Node_ScriptDir\install-nwclient.ps1 -Scriptdir $IN_Guest_CD_Scriptdir"
            }

        $Content += "restart-computer"
    
        Write-Verbose $Content
        Set-Content "$Isodir\$Scripts\run-$Current_phase.ps1" -Value $Content -Force


}
function run-phase4
{
param (
[string]$next_phase,
[string]$Current_phase,
[switch]$next_phase_no_reboot
)
$Content = @()
$Content = "###
`$ScriptName = `$MyInvocation.MyCommand.Name
`$Host.UI.RawUI.WindowTitle = `$ScriptName
`$Logfile = New-Item -ItemType file `"c:\$Scripts\`$ScriptName.log`"
$IN_Node_ScriptDir\set-vmguesttask.ps1 -Task $current_phase -Status started
$IN_Node_ScriptDir\set-vmguestshare.ps1 -user $Labbuildr_share_User -password $Labbuildr_share_password -HostIP $HostIP
$IN_Node_ScriptDir\set-vmguesttask.ps1 -Task $previous_phase -Status finished
"
if ($next_phase_no_reboot)
    {
    $Content += "$IN_Guest_CD_Scriptdir\$Scripts\run-$next_phase.ps1
    "
    }
else
    {
    $Content += "New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name '99-$next_phase' -Value '$PSHOME\powershell.exe -Command `". $IN_Guest_CD_Scriptdir\$Scripts\run-$next_phase.ps1`"'
    "
    }
Write-Verbose $Content
Set-Content "$Isodir\$Scripts\run-$Current_phase.ps1" -Value $Content -Force

}
function run-phase5
{
param (
[string]$next_phase,
[string]$Current_phase
)
$Content = @()
$Content = "###
"
Write-Verbose $Content
Set-Content "$Isodir\$Scripts\run-$Current_phase.ps1" -Value $Content -Force

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
        $Destination = "$Builddir\$Scripts"
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


try
   {
   $vmswitch = Get-VMSwitch $hvswitch
   }
catch
    {
    Write-Warning "No vmSwitch with name $HVSwitch found, please check setup !"
    break
    }

try
    {
    $HostIP_Address = Get-NetIPAddress -InterfaceAlias "vEthernet ($HVSwitch)" -AddressFamily IPv4
    $HostIP = $HostIP_Address.IPAddress
    }
catch
    {
    Write-Warning "Could not detect Host IP Address configured for VMSwitch $HVSwitch"
    }

Write-Verbose " We have Switch $HVSwitch and Host IP $HostIP"
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

if (!(get-smbshare -name "$Scripts" -erroraction SilentlyContinue))
        {
        new-smbshare -name "$Scripts" -path "$Builddir\$Scripts"
        }
if (!(get-smbshare -name "Sources" -erroraction SilentlyContinue ))
        {
        new-smbshare -name "Sources" -path "$Sourcedir" 
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
    $url = "ftp://ftp.heise.de/pub/ct/listings/0603-202.zip"
    Write-Warning "Downloading mkisofs from $URL, plese be patient"
    $Zipfile = Split-Path -Leaf $URL
   if (!(Get-LABFTPFile -Source $url -Defaultcredentials -TarGet "$Builddir\$Zipfile"))
        {
        write-warning "Error downloading mkisofs from $URL, please check location and try manually. mkisofs need to be in $Builddir\bin"
        break
        }

    Expand-LABZip -zipfilename "$Builddir\$Zipfile" -destination "$Builddir\bin"
    }


####### Building required Software Versions Tabs

$Sourcever = @()

# $Sourcever = @("$nw_ver","$nmm_ver","E2013$ex_cu","$WAIKVER","$SQL2012R2")
if (!($DConly.IsPresent))
{
	if ($Exchange2013.IsPresent) 
        {
        $EX_Version = "E2013"
        $Scenarioname = "Exchange"
        $Scenario = 1
        }
    if ($Exchange2016.IsPresent) 
        {
        $EX_Version = "E2016"
        $Scenarioname = "Exchange"
        $Scenario = 1
        }
	if (($NMM.IsPresent) -and ($Blanknode -eq $false)) { $Sourcever += $nmm_ver }
	if ($NWServer.IsPresent -or $NW.IsPresent -or $NMM.IsPresent ) 
        { 
        $Sourcever += $nw_ver 
        }
	if ($SQL.IsPresent -or $AlwaysOn.IsPresent) 
        {
        $Sourcever +=  $AAGDB #$SQLVER,
        $Scenarioname = "SQL"
        $SQL = $true
        $Scenario = 2
        }
	if ($HyperV.IsPresent)
	{
		
        $Scenarioname = "Hyper-V"
        $Scenario = 3
        if ($ScaleIO.IsPresent) 
            { 
            $Sourcever += "ScaleIO"
            }
	}
	if ($Sharepoint.IsPresent)
	{
		
        $Scenarioname = "Sharepoint"
        $Scenario = 4
	}
} # end not dconly
if ($NWServer.IsPresent -or $NW.IsPresent)
    {
    $url = "ftp://ftp.adobe.com/pub/adobe/reader/win/Acrobat2015/1500630033/AcroRdr20151500630033_MUI.exe"
    $FileName = Split-Path -Leaf -Path $Url
    if (!(test-path  $Sourcedir\$FileName))
        {
        Write-Verbose "$FileName not found, trying Download"
        if (!( Get-LABFTPFile -Source $URL -Target $Sourcedir\$FileName -verbose -UserName Anonymous -Password "Admin@labbuildr.local"))
            { 
            write-warning "Error Downloading file $Url, Please check connectivity"
            }
        }

    }

if ($NWServer.IsPresent -or $NMM.IsPresent -or $NW.IsPresent)
    {

    if ((Test-Path "$Sourcedir/$nw_ver/win_x64/networkr/networker.msi") -or (Test-Path "$Sourcedir/$nw_ver/win_x64/networkr/lgtoclnt-8.5.0.0.exe"))
        {
        Write-Verbose "Networker $nw_ver found"
        }
    elseif ($nw_ver -lt "nw84")
        {

        Write-Warning "We need to get $NW_ver, trying Automated Download"
        if ($nw_ver -notin ('nw822','nw821','nw82'))
            {
            $nwdotver = $nw_ver -replace "nw",""
            $nwdotver = $nwdotver.insert(1,'.')
            $nwdotver = $nwdotver.insert(3,'.')
            $nwdotver = $nwdotver.insert(5,'.')
            $nwzip = $nw_ver -replace ".$"
            $nwzip = $nwzip+'_win_x64.zip'
            $url = "ftp://ftp.legato.com/pub/NetWorker/Cumulative_Hotfixes/$($nwdotver.Substring(0,3))/$nwdotver/$nwzip"
            if ($url)
            {
            # $FileName = Split-Path -Leaf -Path $Url
            $FileName = "$nw_ver.zip"
            $Zipfilename = Join-Path $Sourcedir $FileName
            $Destinationdir = Join-Path $Sourcedir $nw_ver
            if (!(test-path  $Zipfilename ))
                {
                Write-Verbose "$FileName not found, trying Download"
                if (!( Get-LABFTPFile -Source $URL -Target $Zipfilename -verbose -Defaultcredentials))
                    { 
                    write-warning "Error Downloading file $Url, 
                    $url might not exist.
                    Please check connectivity or download manually"
                    break
                    }
                }
            Write-Verbose $Zipfilename     
            Expand-LABZip -zipfilename "$Zipfilename" -destination "$Destinationdir" -verbose
            }
            }
        else
            {
            Write-Warning "We can only autodownload Cumulative Updates from ftp, please get $nw_ver from support.emc.com"
            break
            }

      } #end elseif
}

if ($NMM.IsPresent)
    {
    <#
    if ($nmm_ver -ge "nmm85")
        { 
        write-verbose "we need .Net Framework 4.51 or later"
        $Prereqdir = "NMMPrereq"
        $Url =  "http://download.microsoft.com/download/E/2/1/E21644B5-2DF2-47C2-91BD-63C560427900/NDP452-KB2901907-x86-x64-AllOS-ENU.exe"
        $FileName = Split-Path -Leaf -Path $Url
        Write-Verbose "Testing $FileName in $Prereqdir"
        if (!(test-path  "$Sourcedir\$Prereqdir\$FileName"))
        {
        Write-Verbose "Trying Download"
        if (!(get-prereq -DownLoadUrl $URL -destination  "$Sourcedir\$Prereqdir\$FileName"))
            { 
            write-warning "Error Downloading file $Url, Please check connectivity"
            exit
            }
        }
    }
    #>   
         

    if ((Test-Path "$Sourcedir/$nmm_ver/win_x64/networkr/NetWorker Module for Microsoft.msi") -or (Test-Path "$Sourcedir/$nmm_ver/win_x64/networkr/NWVSS.exe"))
        {
        Write-Verbose "Networker NMM $nmm_ver found"
        }
    else
        {
        Write-Warning "We need to get $NMM_ver, trying Automated Download"
        # New-Item -ItemType Directory -Path $Sourcedir\$EX_Version$ex_cu | Out-Null
        # }
        $URLS = ""
        if ($nmm_ver -notin ('nmm822','nmm821','nmm82') -and $nmm_ver -gt 'nmm_82')
            {
            $nmmdotver = $nmm_ver -replace "nmm",""
            $nmmdotver = $nmmdotver.insert(1,'.')
            $nmmdotver = $nmmdotver.insert(3,'.')
            $nmmdotver = $nmmdotver.insert(5,'.')
            $nmmzip = $nmm_ver -replace ".$"
            $nmmzip = $nmmzip+'_win_x64.zip'
            $scvmmzip = $nmmzip -replace "nmm","scvmm"
            Write-Verbose "$scvmmzip"
            $urls = ("ftp://ftp.legato.com/pub/NetWorker/NMM/Cumulative_Hotfixes/$($nmmdotver.Substring(0,5))/$nmmdotver/$nmmzip",
                     "ftp://ftp.legato.com/pub/NetWorker/NMM/Cumulative_Hotfixes/$($nmmdotver.Substring(0,5))/$nmmdotver/$scvmmzip")
            }

        if ($urls)
            {
            foreach ($url in $urls)
                {
                $FileName = Split-Path -Leaf -Path $Url
                if ($FileName -match "nmm")
                    {
                    $Zipfilename = "$nmm_ver.zip"
                    }
                if ($FileName -match "scvmm")
                    {
                    $Zipfilename = "$NMM_scvmm_ver.zip"
                    }
                $Zipfile = Join-Path $Sourcedir $Zipfilename
                if (!(test-path  $Zipfile))
                    {
                    Write-Verbose "$Zipfilename not found, trying Download"
                    if (!( Get-LABFTPFile -Source $URL -Target $Zipfile -verbose -Defaultcredentials))
                        { 
                        write-warning "Error Downloading file $Url, Please check connectivity"
                        }
                    }
                $Destinationdir =  "$($Zipfile.replace(".zip"," "))"
                Write-Verbose $Destinationdir
                Expand-LABZip -zipfilename $Zipfile -destination $Destinationdir
                }
            }
      }
}




if ($Exchange2016.IsPresent)
{
    if (!$e16_cu)
        {
        $e16_cu = $Latest_e16_cu
        }

    If ($Master -gt '2012Z')
        {
        Write-Warning "Only master up 2012R2Fallupdate supported in this scenario"
        exit
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
    $Destination = Join-Path $Sourcedir $Prereqdir
    if (!(Test-Path $Destination)){New-Item -ItemType Directory -Path $Destination | Out-Null }
     foreach ($URL in $attachments)
        {
        $FileName = Split-Path -Leaf -Path $Url
        if (!(test-path  "$Destination\$FileName"))
            {
            Write-Verbose "$FileName not found, trying Download"
            if (!(get-prereq -DownLoadUrl $URL -destination $Sourcedir\$Prereqdir\$FileName))
                { write-warning "Error Downloading file $Url, Please check connectivity"
                  Write-Warning "Creating Dummy File"
                  New-Item -ItemType file -Path "$Sourcedir\$Prereqdir\$FileName" | out-null
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
    $Destination = Join-Path $Sourcedir $Prereqdir             
    if (Test-Path -Path "$Destination")
        {
        Write-Verbose "$EX_Version Sourcedir Found"
        }
        else
        {
        Write-Verbose "Creating Sourcedir for $EX_Version Prereqs"
        New-Item -ItemType Directory -Path $Destination | Out-Null
        }


    foreach ($URL in $DownloadUrls)
        {
        $FileName = Split-Path -Leaf -Path $Url
        if (!(test-path  "$Destination\$FileName"))
            {
            Write-Verbose "$FileName not found, trying Download"
            if (!(get-prereq -DownLoadUrl $URL -destination "$Destination\$FileName"))
                { write-warning "Error Downloading file $Url, Please check connectivity"
                exit
                }
            }
        }
    $Destination =  Join-Path "$Sourcedir" "$EX_Version$e16_cu"
    write-verbose "Testing $Destination/setup.exe"
    if (Test-Path "$Destination/setup.exe")
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
        $Downloadfile = Join-Path $Sourcedir $FileName
        if (!(test-path  ( Join-Path $Downloadfile)))
            {
            "We need to Download $EX_Version $e16_cu from $url, this may take a while"
            if (!(get-prereq -DownLoadUrl $URL -destination $Downloadfile))
                { write-warning "Error Downloading file $Url, Please check connectivity"
                exit
            }
        }
        Write-Verbose "Extracting $FileName"
        Start-Process -FilePath "$Downloadfile" -ArgumentList "/extract:$Destination /passive" -Wait
            
    } #end else

	    if ($DAG.IsPresent)
	        {
		    Write-Host -ForegroundColor Yellow "We will form a $EXNodes-Node DAG"
	        }

}

############## SCOM Section
if ($SCOM.IsPresent)
  {
    Write-Warning "Entering SCOM Prereq Section"
    [switch]$SQL=$true
    $Prereqdir = "$SCOM_VER"+"prereq"
    Write-Verbose "We are now going to Test SCOM Prereqs"
    
            $DownloadUrls= (
            'http://download.microsoft.com/download/F/B/7/FB728406-A1EE-4AB5-9C56-74EB8BDDF2FF/ReportViewer.msi',
            "http://download.microsoft.com/download/F/E/D/FEDB200F-DE2A-46D8-B661-D019DFE9D470/ENU/x64/SQLSysClrTypes.msi"
            )
    
            Foreach ($URL in $DownloadUrls)
                {
                $FileName = Split-Path -Leaf -Path $Url
                Write-Verbose "Testing $FileName in $Prereqdir"
                if (!(test-path  "$Sourcedir\$Prereqdir\$FileName"))
                    {
                    Write-Verbose "Trying Download"
                    if (!(get-prereq -DownLoadUrl $URL -destination  "$Sourcedir\$Prereqdir\$FileName"))
                        { 
                        write-warning "Error Downloading file $Url, Please check connectivity"
                        exit
                        }
                    }
                }
    
    switch ($SCOM_VER)
    {
        "SC2012_R2_SCOM"
            {
            if ($SQLVER -gt "SQL2012SP1")
                {
                Write-Warning "SCOM can only be installed on SQL2012, Setting to SQL2012SP1"
                $SQLVER = "SQL2012SP1"
                }# end sqlver

            
            $URL = "http://care.dlservice.microsoft.com/dl/download/evalx/sc2012r2/$SCOM_VER.exe"
            }
        
        "SCTP3_SCOM"
            {
            $URL = "http://care.dlservice.microsoft.com/dl/download/B/0/7/B07BF90E-2CC8-4538-A7D2-83BB074C49F5/SCTP3_SCOM_EN.exe"
            }

        "SCTP4_SCOM"
            {
            <#
            see gist tp4 for url´s
            #>
            $URL = "http://care.dlservice.microsoft.com/dl/download/3/3/3/333022FC-3BB1-4406-8572-ED07950151D4/SCTP4_SCOM_EN.exe"
            }

    }# end switch
    $FileName = Split-Path -Leaf -Path $Url
    Write-Verbose "Testing $SCOM_VER\"
    if (!(test-path  "$Sourcedir\$SCOM_VER"))
                {
                Write-Verbose "Trying Download"
                if (!(get-prereq -DownLoadUrl $URL -destination  "$Sourcedir\$FileName"))
                    { 
                    write-warning "Error Downloading file $Url, Please check connectivity"
                    exit
                    }
                write-Warning "We are going to Extract $FileName, this may take a while"
                Start-Process "$Sourcedir\$FileName" -ArgumentList "/SP- /dir=$Sourcedir\$SCOM_VER /SILENT" -Wait
                }

    workorder "We are going to Install SCOM with $SCOM_VER in Domain $BuildDomain with Subnet $MySubnet using VMnet$VMnet and $SQLVER"
    # exit
    }# end SCOMPREREQ
#######

##############

if ($SQL.IsPresent -or $AlwaysOn.IsPresent)
    {

    $SQL2012_inst = "http://download.microsoft.com/download/4/C/7/4C7D40B9-BCF8-4F8A-9E76-06E9B92FE5AE/ENU/x64/SQLFULL_x64_ENU_Install.exe"
    $SQL2012_lang = "http://download.microsoft.com/download/4/C/7/4C7D40B9-BCF8-4F8A-9E76-06E9B92FE5AE/ENU/x64/SQLFULL_x64_ENU_Lang.box"
    $SQL2012_core = "http://download.microsoft.com/download/4/C/7/4C7D40B9-BCF8-4F8A-9E76-06E9B92FE5AE/ENU/x64/SQLFULL_x64_ENU_Core.box"
    $SQL2012_box = "http://download.microsoft.com/download/3/B/D/3BD9DD65-D3E3-43C3-BB50-0ED850A82AD5/SQLServer2012SP1-FullSlipstream-x64-ENU.box"
    $SQL2012SP1SLIP_INST = "http://download.microsoft.com/download/3/B/D/3BD9DD65-D3E3-43C3-BB50-0ED850A82AD5/SQLServer2012SP1-FullSlipstream-x64-ENU.exe"
    $SQL2012SP1SLIP_box= "http://download.microsoft.com/download/3/B/D/3BD9DD65-D3E3-43C3-BB50-0ED850A82AD5/SQLServer2012SP1-FullSlipstream-x64-ENU.box"
    $SQL2012_SP1 = "http://download.microsoft.com/download/3/B/D/3BD9DD65-D3E3-43C3-BB50-0ED850A82AD5/SQLServer2012SP1-KB2674319-x64-ENU.exe"
    $SQL2012_SP2 = "http://download.microsoft.com/download/D/F/7/DF7BEBF9-AA4D-4CFE-B5AE-5C9129D37EFD/SQLServer2012SP2-KB2958429-x64-ENU.exe"
    $SQL2014_ZIP = "http://care.dlservice.microsoft.com/dl/download/evalx/sqlserver2014/x64/SQLServer2014_x64_enus.zip"
    $SQL2014SP1SLIP_INST = "http://care.dlservice.microsoft.com/dl/download/2/F/8/2F8F7165-BB21-4D1E-B5D8-3BD3CE73C77D/SQLServer2014SP1-FullSlipstream-x64-ENU.exe"
    $SQL2014SP1SLIP_box= "http://care.dlservice.microsoft.com/dl/download/2/F/8/2F8F7165-BB21-4D1E-B5D8-3BD3CE73C77D/SQLServer2014SP1-FullSlipstream-x64-ENU.box"

    $AAGURL = "https://community.emc.com/servlet/JiveServlet/download/38-111250/AWORKS.zip"
    $URL = $AAGURL
    $FileName = Split-Path -Leaf -Path $Url
    Write-Verbose "Testing $FileName in $Sourcedir"
    if (!(test-path  "$Sourcedir\Aworks\AdventureWorks2012.bak"))
        {
        Write-Verbose "Trying Download"
        if (!(get-prereq -DownLoadUrl $URL -destination  "$Sourcedir\$FileName"))
            { 
            write-warning "Error Downloading file $Url, Please check connectivity"
            exit
            }
        #New-Item -ItemType Directory -Path "$Sourcedir\Aworks" -Force
        Extract-Zip -zipfilename $Sourcedir\$FileName -destination $Sourcedir
        }
    Write-Verbose "We are now going to Test $SQLVER"
    Switch ($SQLVER)
        {
            "SQL2012"
            {
            if (!(Test-Path "$Sourcedir\SQLFULL_x64_ENU\SETUP.EXE"))
                {
                foreach ($url in ($SQL2012_inst,$SQL2012_lang,$SQL2012_core))
                    {
                    $FileName = Split-Path -Leaf -Path $Url
                    Write-Verbose "Testing $FileName in $Sourcedir"
                    if (!(test-path  "$Sourcedir\$FileName"))
                        {
                        Write-Verbose "Trying Download"
                        if (!(get-prereq -DownLoadUrl $URL -destination  "$Sourcedir\$FileName"))
                            { 
                            write-warning "Error Downloading file $Url, Please check connectivity"
                            exit
                            }
                        }
                    }
                Write-Warning "Creating $SQLVER Installtree, this might take a while"
                $FileName = Split-Path -Leaf $SQL2012_inst
                Start-Process $Sourcedir\$FileName -ArgumentList "/X /q" -Wait    
                }

            }
            "SQL2012SP1"
            {
            #Getting SP1
            $url = $SQL2012_SP1
            $FileName = Split-Path -Leaf -Path $Url
            $Destination = "$Sourcedir\$SQLVER\$FileName"
            Write-Verbose "Testing $Destination"
                if (!(test-path  "$Destination"))
                    {
                    Write-Verbose "Trying Download"
                    if (!(get-prereq -DownLoadUrl $URL -destination $Destination))
                        { 
                            write-warning "Error Downloading file $Url, Please check connectivity"
                            exit
                            }
                        }
            #first check for 2012
            if (!(Test-Path "$Sourcedir\SQLFULL_x64_ENU\SETUP.EXE"))
                {
                foreach ($url in ($SQL2012_inst,$SQL2012_lang,$SQL2012_core))
                    {
                    $FileName = Split-Path -Leaf -Path $Url
                    Write-Verbose "Testing $FileName in $Sourcedir"
                    if (!(test-path  "$Sourcedir\$FileName"))
                        {
                        Write-Verbose "Trying Download"
                        if (!(get-prereq -DownLoadUrl $URL -destination  "$Sourcedir\$FileName"))
                            { 
                            write-warning "Error Downloading file $Url, Please check connectivity"
                            exit
                            }
                        }
                    }
                Write-Warning "Creating $SQLVER Installtree, this might take a while"
                $FileName = Split-Path -Leaf $SQL2012_inst
                Start-Process $Sourcedir\$FileName -ArgumentList "/X /q" -Wait    
                }

            # end 2012

            }
            "SQL2012SP2"
            {
            #first check for 2012
            if (!(Test-Path "$Sourcedir\SQLFULL_x64_ENU\SETUP.EXE"))
                {
                foreach ($url in ($SQL2012_inst,$SQL2012_lang,$SQL2012_core))
                    {
                    $FileName = Split-Path -Leaf -Path $Url
                    Write-Verbose "Testing $FileName in $Sourcedir"
                    if (!(test-path  "$Sourcedir\$FileName"))
                        {
                        Write-Verbose "Trying Download"
                        if (!(get-prereq -DownLoadUrl $URL -destination  "$Sourcedir\$FileName"))
                            { 
                            write-warning "Error Downloading file $Url, Please check connectivity"
                            exit
                            }
                        }
                    }
                Write-Warning "Creating $SQLVER Installtree, this might take a while"
                $FileName = Split-Path -Leaf $SQL2012_inst
                Start-Process $Sourcedir\$FileName -ArgumentList "/X /q" -Wait    
                }

            # end 2012

            #### Getting Sp2
            $url = $SQL2012_SP2
            $FileName = Split-Path -Leaf -Path $Url
            $Destination = "$Sourcedir\$SQLVER\$FileName"
            Write-Verbose "Testing $Destination"
            if (!(test-path  "$Destination"))
                {
                Write-Verbose "Trying Download"
                if (!(get-prereq -DownLoadUrl $URL -destination $Destination))
                    { 
                    write-warning "Error Downloading file $Url, Please check connectivity"
                    exit
                    }
                }

            }
            "SQL2012SP1Slip"
            {
            if (!(Test-Path $Sourcedir\$SQLVER\setup.exe))
                {
                foreach ($url in ($SQL2012SP1SLIP_box,$SQL2012SP1SLIP_INST))
                    {
                    $FileName = Split-Path -Leaf -Path $Url
                    Write-Verbose "Testing $FileName in $Sourcedir"
                    if (!(test-path  "$Sourcedir\$FileName"))
                        {
                        Write-Verbose "Trying Download"
                        if (!(get-prereq -DownLoadUrl $URL -destination  "$Sourcedir\$FileName"))
                            {  
                            write-warning "Error Downloading file $Url, Please check connectivity"
                            exit
                            }
                        }
                    }
                    Write-Warning "Creating $SQLVER Installtree, this might take a while"
                    Start-Process $Sourcedir\$FileName -ArgumentList "/X:$Sourcedir\$SQLVER /q" -Wait
                }
            }

            "SQL2014"
            {
            if (!(Test-Path $Sourcedir\$SQLVER\setup.exe))
            {
            foreach ($url in ($SQL2014_ZIP))
                {
                $FileName = Split-Path -Leaf -Path $Url
                Write-Verbose "Testing $FileName in $Prereqdir"
                ### Test if the 2014 ENU´s are there
                if (!(test-path  "$Sourcedir\SQLServer2014-x64-ENU.exe"))
                    {
                    ## Test if we already have the ZIP
                    if (!(test-path  "$Sourcedir\$FileName"))
                        {
                        Write-Verbose "Trying Download"
                        if (!(get-prereq -DownLoadUrl $URL -destination  "$Sourcedir\$FileName"))
                            { 
                            write-warning "Error Downloading file $Url, Please check connectivity"
                            exit
                            }
                    }
                 Extract-Zip -zipfilename $Sourcedir\$FileName -destination $Sourcedir
                 Remove-Item $Sourcedir\$FileName 
                 Move-Item $Sourcedir\enus\* $Sourcedir\
                 Remove-Item $Sourcedir\enus
                 }
                # New-Item -ItemType Directory $Sourcedir\$SQLVER
                Write-Warning "Creating $SQLVER Installtree, this might take a while"
                Start-Process "$Sourcedir\SQLServer2014-x64-ENU.exe" -ArgumentList "/X:$Sourcedir\$SQLVER /q" -Wait 
                }
            
            }
            }
            "SQL2014SP1slip"
            {
            if (!(Test-Path $Sourcedir\$SQLVER\setup.exe))
                {
                foreach ($url in ($SQL2014SP1SLIP_box,$SQL2014SP1SLIP_INST))
                    {
                    $FileName = Split-Path -Leaf -Path $Url
                    Write-Verbose "Testing $FileName in $Sourcedir"
                    if (!(test-path  "$Sourcedir\$FileName"))
                        {
                        Write-Verbose "Trying Download"
                        if (!(get-prereq -DownLoadUrl $URL -destination  "$Sourcedir\$FileName"))
                            {  
                            write-warning "Error Downloading file $Url, Please check connectivity"
                            exit
                            }
                        }
                    }
                    Write-Warning "Creating $SQLVER Installtree, this might take a while"
                    Start-Process $Sourcedir\$FileName -ArgumentList "/X:$Sourcedir\$SQLVER /q" -Wait
                }
            }
          } #end switch
    }#end $SQLEXPRESS

##end Autodownloaders
##########################################
if ($nw.IsPresent -and !$NoDomainCheck.IsPresent) { workorder "Networker $nw_ver Node will be installed" }
write-verbose "Checking Environment"
if ($NW.IsPresent -or $NWServer.IsPresent)
{
    if (!$Scenarioname) 
        {
        $Scenarioname = "nwserver"
        $Scenario = 8
        }
	if (!($Acroread = Get-ChildItem -Path $Sourcedir -Filter 'a*rdr*.exe'))
	    {
		status "Adobe reader not found ...."
	    }
	else
	    {
		$Acroread = $Acroread | Sort-Object -Property Name -Descending
		$LatestReader = $Acroread[0].Name
		write-verbose "Found Adobe $LatestReader"
	    }
	
	##### 
    $Java7_required = $True
    #####
If ($nw_ver -gt "nw85.BR1")
            {
            $Java8_required = $true
            $Java7_required = $false
            if ($LatestJava7)
                {
                $LatestJava = $LatestJava7
                }
            
            if ($LatestJava8)
                {
                $LatestJava = $LatestJava8
                }
            }
}

#end $nw


if ($Java7_required)
    {
    Write-Verbose "Checking for Java 7"
    if (!($Java7 = Get-ChildItem -Path $Sourcedir -Filter 'jre-7*x64*'))
	    {
		write-warning "Java7 not found, please download from www.java.com"
	    break
        }
    else
        {
	    $Java7 = $Java7 | Sort-Object -Property Name -Descending
	    $LatestJava = $Java7[0].Name
        }
    }


If ($Java8_required)
    {
    Write-Verbose "Checking for Java 8"
    if (!($Java8 = Get-ChildItem -Path $Sourcedir -Filter 'jre-8*x64*'))
        {
	    Write-Warning "Java8 not found, trying download"
        Write-Verbose "Asking for latest Java8"
        $LatestJava = (get-labJava64 -DownloadDir $Sourcedir).LatestJava8
        if (!$LatestJava)
            {
            break
            }
	    }
    else
        {
        $Java8 = $Java8 | Sort-Object -Property Name -Descending
	    $LatestJava = $Java8[0].Name
        Write-Verbose "Got $LatestJava"
        }
    }



if (!($SourceOK = test-source -SourceVer $Sourcever -SourceDir $Sourcedir))
{
	Write-Verbose "Sourcecomlete: $SourceOK"
	break
}
if ($DefaultGateway) {$AddGateway  = "-DefaultGateway $DefaultGateway"}
If ($VMnet -ne "VMnet2") { debug "Setting different Network is untested and own Risk !" }


##########
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
        $ScenarioScriptdir = "$IN_Guest_CD_Scriptdir\$NodePrefix"
        $NodeIP = "$IPv4Subnet.10"
        ####prepare iso
        Remove-Item -Path "$Isodir\$Scripts" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
        New-Item -ItemType Directory "$Isodir\$Scripts" -Force | Out-Null
        New-Item -ItemType Directory "$Builddir\$NodePrefix" -Force | Out-Null
        $Current_phase = "start-customize"
        $next_phase = "phase2"
        $Content = @()
        $Content = "###
`$logpath = `"c:\$Scripts`"
if (!(Test-Path `$logpath))
    {
    New-Item -ItemType Directory -Path `$logpath -Force
    }

`$ScriptName = `$MyInvocation.MyCommand.Name
`$Host.UI.RawUI.WindowTitle = `$ScriptName
`$Logfile = New-Item -ItemType file `"c:\$Scripts\`$ScriptName.log`"
$IN_Node_ScriptDir\set-vmguesttask.ps1 -Task $Current_phase -Status started
New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name '99-$next_phase' -Value '$PSHOME\powershell.exe -Command `". $IN_Guest_CD_Scriptdir\$Scripts\run-$next_phase.ps1`"'
$ScenarioScriptdir\new-dc.ps1 -dcname $DCName -Domain $BuildDomain -IPv4subnet $IPv4subnet -IPv4Prefixlength $IPv4PrefixLength -IPv6PrefixLength $IPv6PrefixLength -IPv6Prefix $IPv6Prefix -AddressFamily $AddressFamily
"
# $ScenarioScriptdir\new-dc.ps1 -dcname $DCName -Domain $BuildDomain -IPv4subnet $IPv4subnet -IPv4Prefixlength $IPv4PrefixLength -IPv6PrefixLength $IPv6PrefixLength -IPv6Prefix $IPv6Prefix -AddressFamily $AddressFamily #-setwsman $CommonParameter

Write-Verbose $Content
Set-Content "$Isodir\$Scripts\$Current_phase.ps1" -Value $Content -Force
        
######## Phase 2
       $previous_phase = $current_phase
       $current_phase = $next_phase
       $next_phase = "phase3"
       $Content = @()
       $Content = "###
`$ScriptName = `$MyInvocation.MyCommand.Name
`$Host.UI.RawUI.WindowTitle = `$ScriptName
`$Logfile = New-Item -ItemType file `"c:\$Scripts\`$ScriptName.log`"
$IN_Node_ScriptDir\set-vmguesttask.ps1 -Task $current_phase -Status started
$IN_Node_ScriptDir\set-vmguesttask.ps1 -Task $previous_phase -Status finished
New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name '99-$next_phase' -Value '$PSHOME\powershell.exe -Command `". $IN_Guest_CD_Scriptdir\$Scripts\run-$next_phase.ps1`"'
Set-ExecutionPolicy -ExecutionPolicy bypass -Force
$ScenarioScriptdir\finish-domain.ps1 -domain $BuildDomain -domainsuffix $domainsuffix
"
Write-Verbose $Content
Set-Content "$Isodir\$Scripts\run-$Current_phase.ps1" -Value $Content -Force
## end Phase2 


### phase 3
       $previous_phase = $current_phase
       $current_phase = $next_phase
       $next_phase = "phase4"
       $Content = @()
       $Content = "###
`$ScriptName = `$MyInvocation.MyCommand.Name
`$Host.UI.RawUI.WindowTitle = `$ScriptName
`$Logfile = New-Item -ItemType file `"c:\$Scripts\`$ScriptName.log`"
$IN_Node_ScriptDir\set-vmguesttask.ps1 -Task $current_phase -Status started
New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name '99-$next_phase' -Value '$PSHOME\powershell.exe -Command `". $IN_Guest_CD_Scriptdir\$Scripts\run-$next_phase.ps1`"'
$IN_Node_ScriptDir\set-vmguesttask.ps1 -Task $previous_phase -Status finished
Set-ExecutionPolicy -ExecutionPolicy bypass -Force
$ScenarioScriptdir\dns.ps1 -IPv4subnet $IPv4Subnet -IPv4Prefixlength $IPV4PrefixLength -IPv6PrefixLength $IPv6PrefixLength -AddressFamily $AddressFamily  -IPV6Prefix $IPV6Prefix
$ScenarioScriptdir\add-serviceuser.ps1
$ScenarioScriptdir\pwpolicy.ps1 
#$IN_Node_ScriptDir\set-winrm.ps1 -Scriptdir $IN_Guest_CD_Scriptdir
restart-computer
"
Write-Verbose $Content
Set-Content "$Isodir\$Scripts\run-$Current_phase.ps1" -Value $Content -Force
###end phase 3
## Phase 4
       $previous_phase = $current_phase
       $current_phase = $next_phase
       $next_phase = "phase5"
       $Content = @()
       $Content = "###
`$ScriptName = `$MyInvocation.MyCommand.Name
`$Host.UI.RawUI.WindowTitle = `$ScriptName
`$Logfile = New-Item -ItemType file `"c:\$Scripts\`$ScriptName.log`"
$IN_Node_ScriptDir\set-vmguesttask.ps1 -Task $current_phase -Status started
New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name '99-$next_phase' -Value '$PSHOME\powershell.exe -Command `". $IN_Guest_CD_Scriptdir\$Scripts\run-$next_phase.ps1`"'
$IN_Node_ScriptDir\set-vmguesttask.ps1 -Task $previous_phase -Status finished
$IN_Node_ScriptDir\powerconf.ps1 -Scriptdir $IN_Guest_CD_Scriptdir
$IN_Node_ScriptDir\set-uac.ps1 -Scriptdir $IN_Guest_CD_Scriptdir
$IN_Node_ScriptDir\set-winrm.ps1 -Scriptdir $IN_Guest_CD_Scriptdir
restart-computer 
"
        Write-Verbose $Content
        Set-Content "$Isodir\$Scripts\run-$Current_phase.ps1" -Value $Content -Force
## end Phase4       
        
### phase 5
       $previous_phase = $current_phase
       $current_phase = $next_phase
       #$next_phase = "finished"
       $Content = @()
       $Content = "###
`$ScriptName = `$MyInvocation.MyCommand.Name
`$Host.UI.RawUI.WindowTitle = `$ScriptName
`$Logfile = New-Item -ItemType file `"c:\$Scripts\`$ScriptName.log`"
$IN_Node_ScriptDir\set-vmguesttask.ps1 -Task $previous_phase -Status finished
$IN_Node_ScriptDir\set-vmguesttask.ps1 -Task $current_phase -Status started
$ScenarioScriptdir\check-domain.ps1 -Scriptdir $IN_Guest_CD_Scriptdir
$IN_Node_ScriptDir\set-vmguestshare.ps1 -user $Labbuildr_share_User -password $Labbuildr_share_password -HostIP $HostIP
$IN_Node_ScriptDir\set-vmguesttask.ps1 -Task $current_phase -Status finished
#New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name '99-$next_phase' -Value '$PSHOME\powershell.exe -Command `". $Isodir\$Scripts\run-$next_phase.ps1`"'
"
        Write-Verbose $Content
        Set-Content "$Isodir\$Scripts\run-$Current_phase.ps1" -Value $Content -Force
## end Phase5  


        
####### Iso Creation        
        make-iso -Nodename $NodeName -Builddir $Builddir -isodir $Isodir



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
        test-dcrunning
        $CloneParameter = $CommonParameter
        if ($SpacesDirect.IsPresent )
            {
            If ($Master -lt "2016")
                {
                Write-Warning "Master 2016TP3 or Later is required for Spaces Direct"
                exit
                }
            if ($Disks -lt 2)
                {
                $Disks = 2
                }
            if ($BlankNodes -lt 4)
                {
                $BlankNodes = 4
                }
            $Cluster = $true
            $BlankHV = $true
            }

        if ($Disks)
            {
		    $cloneparameter = "$CloneParameter -AddDisks -disks $Disks"
            }
        If ($vlanID)
            {
            $CloneParameter = "$CloneParameter -vlanid $vlanID"
            }
        $AddonFeatures = "RSAT-ADDS, RSAT-ADDS-TOOLS, AS-HTTP-Activation, NET-Framework-45-Features"
        if ($Cluster.IsPresent) 
            {
            $AddonFeatures = "$AddonFeatures, Failover-Clustering, RSAT-Clustering, RSAT-Clustering-AutomationServer, RSAT-Clustering-CmdInterface, WVR"
            }
        # if ($BlankHV.IsPresent) {$AddonFeatures = "$AddonFeatures, Hyper-V, RSAT-Hyper-V-Tools, Multipath-IO"}

        if ($Cluster.IsPresent) 
            {
            $AddonFeatures = "$AddonFeatures, Failover-Clustering, RSAT-Clustering, WVR"
            if (!$Clustername)
                {
                $Clustername = "GenCluster"
                }
            }
        $Blank_End = ($Blankstart+$BlankNodes-1)
        Write-Verbose "We will deplo $Nodes Nodes from $Blankstart to $Blank_End"
		foreach ($Node in ($Blankstart..$Blank_End))
		{
			
	    ###################################################
	    #
	    # BlanknodeSetup
	    #			test-dcrunning
	    ###################################################
        $Node_range = 200
        $Node_byte = $Node_range+$node
        $Nodeip = "$IPv4Subnet.$Node_byte"
        $Nodeprefix = "Node"
        $NamePrefix = "GEN"
		$Nodename = "$NamePrefix$NodePrefix$Node"
        $ScenarioScriptdir = "$IN_Guest_CD_Scriptdir\$NodePrefix"
        $ClusterIP = "$IPv4Subnet.$Node_range"
	    Write-Verbose $IPv4Subnet
        write-verbose $Nodename
        write-verbose $Nodeip
        Write-Verbose "Disks: $Disks"
        Write-Verbose "Blanknodes: $BlankNodes"
        Write-Verbose "Cluster: $($Cluster.IsPresent)"
        Write-Verbose "Pre Clustername: $ClusterName"
        Write-Verbose "Pre ClusterIP: $ClusterIP"
        Write-Verbose "Cloneparameter $CloneParameter"
        ####prepare iso
        Remove-Item -Path "$Isodir\$Scripts" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
        New-Item -ItemType Directory "$Isodir\$Scripts" -Force | Out-Null
        New-Item -ItemType Directory "$Builddir\$NodePrefix" -Force | Out-Null
        $Current_phase = "start-customize"
        $next_phase = "phase2"
        run-startcustomize -Current_phase $Current_phase -next_phase $next_phase
        

### phase 2
       $previous_phase = $current_phase
       $current_phase = $next_phase
       $next_phase = "phase3"
       run-phase2 -Current_phase $Current_phase -next_phase $next_phase

### phase 3
       $previous_phase = $current_phase
       $current_phase = $next_phase
       $next_phase = "phase4"
       run-phase4 -Current_phase $Current_phase -next_phase $next_phase
        
## Phase 4
       $previous_phase = $current_phase
       $current_phase = $next_phase
       $next_phase = "phase5"
       run-phase5 -Current_phase $Current_phase -next_phase $next_phase


$AddContent = @()
        if ($Node -eq $Blank_End)
            {
            if ($Cluster.IsPresent)
                {
                $AddContent += "$IN_Node_ScriptDir\create-cluster.ps1 -Nodeprefix '$NamePrefix' -ClusterName $ClusterName -IPAddress '$ClusterIP' -IPV6Prefix $IPV6Prefix -IPv6PrefixLength $IPv6PrefixLength -AddressFamily $AddressFamily $CommonParameter -Scriptdir $IN_Guest_CD_Scriptdir 
"
                if ($SpacesDirect.IsPresent)
                    {
                    $AddContent += "$IN_Node_ScriptDir\new-s2dpool.ps1 -Scriptdir $IN_Guest_CD_Scriptdir 
"
                    }
                }
            }
        $AddContent += "$IN_Node_ScriptDir\set-vmguesttask.ps1 -Task $Current_phase -Status finished
"
        # Write-Verbose $AddContent
        Add-Content "$Isodir\$Scripts\run-$Current_phase.ps1" -Value $AddContent -Force
## end Phase4          
        
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

        Invoke-Expression  "$Builddir\clone-node.ps1 -MasterVHD $MasterVHDX -Nodename $NodeName -Size $Size -HVSwitch $HVSwitch $CloneParameter"

####### wait progress

        check-task -task "start-customize" -nodename $NodeName -sleep $Sleep
    if ($wait)
        {
        foreach ($n in 2..4)
            {

            check-task -task "phase$n" -nodename $NodeName -sleep $Sleep 

            }#end foreach
        } 
    }
}## End Switchblock Blanknode 


   	"E16"{
        test-dcrunning
        Write-Verbose "Starting $EX_Version $e16_cu Setup"
        $CloneParameter = $CommonParameter
        If ($Disks -lt 3)
            {
            $Disks = 3
            }
        if ($Disks)
            {
		    $cloneparameter = "$CloneParameter -AddDisks -disks $Disks"
            }
        If ($vlanID)
            {
            $CloneParameter = "$CloneParameter -vlanid $vlanID"
            }

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
                $DAGIP = "$IPv4subnet.120"
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
			$ScenarioScriptdir = "$IN_Guest_CD_Scriptdir\$NodePrefix"
		    $SourceScriptDir = "$Builddir\$Scripts\$EX_Version\"
            $AddonFeatures = "RSAT-ADDS, RSAT-ADDS-TOOLS, AS-HTTP-Activation, NET-Framework-45-Features"
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
####prepare iso
            Remove-Item -Path "$Isodir\$Scripts" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
            New-Item -ItemType Directory "$Isodir\$Scripts" -Force | Out-Null
            New-Item -ItemType Directory "$Builddir\$NodePrefix" -Force | Out-Null
            $Current_phase = "start-customize"
            $next_phase = "phase2"
            run-startcustomize -Current_phase $Current_phase -next_phase $next_phase
        

### phase 2
            $previous_phase = $current_phase
            $current_phase = $next_phase
            $next_phase = "phase3"
            run-phase2 -Current_phase $Current_phase -next_phase $next_phase

### phase 3
            $previous_phase = $current_phase
            $current_phase = $next_phase
            $next_phase = "phase4"
            run-phase3 -Current_phase $Current_phase -next_phase $next_phase
        
## Phase 4
            $previous_phase = $current_phase
            $current_phase = $next_phase
            $next_phase = "phase_EX_PRE"
            $Next_Phase_noreboot = $true
            run-phase4 -Current_phase $Current_phase -next_phase $next_phase -next_phase_no_reboot


             
## phase_EX_PRE


            $previous_phase = $current_phase
            $current_phase = $next_phase
            $next_phase = "phase_EX_SETUP"
$Content = "###
`$ScriptName = `$MyInvocation.MyCommand.Name
`$Host.UI.RawUI.WindowTitle = `$ScriptName
`$Logfile = New-Item -ItemType file `"c:\$Scripts\`$ScriptName.log`"
$IN_Node_ScriptDir\set-vmguesttask.ps1 -Task $current_phase -Status started
$IN_Node_ScriptDir\set-vmguesttask.ps1 -Task $previous_phase -Status finished
$ScenarioScriptdir\prepare-disks.ps1
$ScenarioScriptdir\install-exchangeprereqs.ps1 -SourcePath $IN_Guest_Sourcepath -Scriptdir $IN_Guest_CD_Scriptdir
New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name '99-$next_phase' -Value '$PSHOME\powershell.exe -Command `". $IN_Guest_CD_Scriptdir\$Scripts\run-$next_phase.ps1`"'
restart-computer
"
Write-Verbose $Content
Set-Content "$Isodir\$Scripts\run-$Current_phase.ps1" -Value $Content -Force
   
   
            $previous_phase = $current_phase
            $current_phase = $next_phase
            $next_phase = "phase_EX_RUN"


$Content = "###
`$ScriptName = `$MyInvocation.MyCommand.Name
`$Host.UI.RawUI.WindowTitle = `$ScriptName
`$Logfile = New-Item -ItemType file `"c:\$Scripts\`$ScriptName.log`"
New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name '99-$next_phase' -Value '$PSHOME\powershell.exe -Command `". $IN_Guest_CD_Scriptdir\$Scripts\run-$next_phase.ps1`"'
$IN_Node_ScriptDir\set-vmguesttask.ps1 -Task $current_phase -Status started
$IN_Node_ScriptDir\set-vmguesttask.ps1 -Task $previous_phase -Status finished
$ScenarioScriptdir\install-exchange.ps1 -ex_cu $e16_cu -SourcePath $IN_Guest_Sourcepath -Scriptdir $IN_Guest_CD_Scriptdir
"
Write-Verbose $Content
Set-Content "$Isodir\$Scripts\run-$Current_phase.ps1" -Value $Content -Force


#####
            $previous_phase = $current_phase
            $current_phase = $next_phase
            $next_phase = "phase_EX_POST"


$Content = "###
`$ScriptName = `$MyInvocation.MyCommand.Name
`$Host.UI.RawUI.WindowTitle = `$ScriptName
`$Logfile = New-Item -ItemType file `"c:\$Scripts\`$ScriptName.log`"
$IN_Node_ScriptDir\set-vmguesttask.ps1 -Task $current_phase -Status started
$IN_Node_ScriptDir\set-vmguesttask.ps1 -Task $previous_phase -Status finished
$ScenarioScriptdir\configure-exchange.ps1 -EX_Version $EX_Version -SourcePath $IN_Guest_Sourcepath -Scriptdir $IN_Guest_CD_Scriptdir
"

# dag phase fo last server
    if ($EXNode -eq ($EXNodes+$EXStartNode-1)) #are we last sever in Setup ?!
        {
        if ($DAG.IsPresent) 
            {
			write-verbose "Creating DAG"
            $Content += "$ScenarioScriptdir\create-dag.ps1 -DAGIP $DAGIP -AddressFamily $EXAddressFamiliy -EX_Version $EX_Version -SourcePath $IN_Guest_Sourcepath -Scriptdir $IN_Guest_CD_Scriptdir
"
			} # end if $DAG
        if (!($nouser.ispresent))
            {
            write-verbose "Creating Accounts and Mailboxes:"
            $Content += "c:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe `". 'C:\Program Files\Microsoft\Exchange Server\V15\bin\RemoteExchange.ps1'; Connect-ExchangeServer -auto; $ScenarioScriptdir\User.ps1 -subnet $IPv4Subnet -AddressFamily $AddressFamily -IPV6Prefix $IPV6Prefix -SourcePath $IN_Guest_Sourcepath -Scriptdir $IN_Guest_CD_Scriptdir`"
"
            } #end creatuser
    }# end if last server

Write-Verbose $Content
Set-Content "$Isodir\$Scripts\run-$Current_phase.ps1" -Value $Content -Force
####


            if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
                { 
                Write-verbose "Now Pausing"
                pause
                    }
            $Size = "XXL"
		    # test-dcrunning
		    ###################################################

####### Iso Creation        
            $Isocreatio = make-iso -Nodename $NodeName -Builddir $Builddir -isodir $Isodir
####### clone creation
            if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
                {
                Write-Verbose "Press any Key to continue to Cloning"
                pause
                }

            $CloneOK = Invoke-Expression  "$Builddir\clone-node.ps1 -MasterVHD $MasterVHDX -Nodename $NodeName -Size $Size -HVSwitch $HVSwitch $CloneParameter"

####### wait progress


		    If ($CloneOK)
            {
            check-task -task "start-customize" -nodename $NodeName -sleep $Sleep
            }
            <##
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
    #>
                
           }#end foreach exnode
       }#End Switchblock Exchange


"SCOM"
{
	###################################################
	# SCOM Setup
	###################################################
	$Nodeip = "$IPv4Subnet.18"
	$Nodename = "SCOM"
    $NodePrefix = "SCOM"
    [string]$AddonFeatures = "RSAT-ADDS, RSAT-ADDS-TOOLS"
    $ScenarioScriptDir = "$GuestScriptdir\$Scenarioname"
    $SQLScriptDir = "$GuestScriptdir\sql\"

	###################################################
	status $Commentline
	status "Creating $SCOM_VER Server $Nodename"
  	Write-Verbose $IPv4Subnet
    write-verbose $Nodename
    write-verbose $Nodeip
    if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
        { 
        Write-verbose "Now Pausing, Clone Process will start after keypress"
        pause
        }

	$DC_test_ok = test-dcrunning

#########################
####prepare iso
            Remove-Item -Path "$Isodir\$Scripts" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
            New-Item -ItemType Directory "$Isodir\$Scripts" -Force | Out-Null
            New-Item -ItemType Directory "$Builddir\$NodePrefix" -Force | Out-Null
            $Current_phase = "start-customize"
            $next_phase = "phase2"
            run-startcustomize -Current_phase $Current_phase -next_phase $next_phase
        

### phase 2
            $previous_phase = $current_phase
            $current_phase = $next_phase
            $next_phase = "phase3"
            run-phase2 -Current_phase $Current_phase -next_phase $next_phase

### phase 3
            $previous_phase = $current_phase
            $current_phase = $next_phase
            $next_phase = "phase4"
            run-phase3 -Current_phase $Current_phase -next_phase $next_phase
        
## Phase 4
            $previous_phase = $current_phase
            $current_phase = $next_phase
            $next_phase = "phase_install_$($Nodeprefix)"
            $Next_Phase_noreboot = $true
            run-phase4 -Current_phase $Current_phase -next_phase $next_phase -next_phase_no_reboot

## phase install


            $previous_phase = $current_phase
            $current_phase = $next_phase
            $next_phase = "phase_install_$($Nodeprefix)_done"
$Content = "###
`$ScriptName = `$MyInvocation.MyCommand.Name
`$Host.UI.RawUI.WindowTitle = `$ScriptName
`$Logfile = New-Item -ItemType file `"c:\$Scripts\`$ScriptName.log`"
$IN_Node_ScriptDir\set-vmguesttask.ps1 -Task $current_phase -Status started
$IN_Node_ScriptDir\set-vmguesttask.ps1 -Task $previous_phase -Status finished
$ScenarioScriptdir\install-sql.ps1 -SQLVER $SQLVER -DefaultDBpath $CommonParameter -SourcePath $IN_Guest_Sourcepath -Scriptdir $IN_Guest_CD_Scriptdir
$ScenarioScriptdir\INSTALL-Scom.ps1 -SCOM_VER $SCOM_VER $CommonParameter -SourcePath $IN_Guest_Sourcepath -Scriptdir $IN_Guest_CD_Scriptdir
#$IN_Node_ScriptDir\install-program.ps1 -Program $LatestJava -ArgumentList '/s' -SourcePath $IN_Guest_Sourcepath -Scriptdir $IN_Guest_CD_Scriptdir
#$IN_Node_ScriptDir\install-program.ps1 -Program $LatestReader -ArgumentList '/sPB /rs' -SourcePath $IN_Guest_Sourcepath -Scriptdir $IN_Guest_CD_Scriptdir
#$IN_Node_ScriptDir\set-autologon -user nwadmin -SourcePath $IN_Guest_Sourcepath -Scriptdir $IN_Guest_CD_Scriptdir
#$IN_Node_ScriptDir\Add-DomainUserToLocalGroup.ps1 -user nwadmin -group 'Remote Desktop Users' -SourcePath $IN_Guest_Sourcepath -Scriptdir $IN_Guest_CD_Scriptdir
#New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name '99-$next_phase' -Value '$PSHOME\powershell.exe -Command `". $IN_Guest_CD_Scriptdir\$Scripts\run-$next_phase.ps1`"'
# restart-computer
"
Write-Verbose $Content
Set-Content "$Isodir\$Scripts\run-$Current_phase.ps1" -Value $Content -Force
######


## phase install_nw_done


            $previous_phase = $current_phase
            $current_phase = $next_phase
            $next_phase = "phase_finished"
$Content = "###
`$ScriptName = `$MyInvocation.MyCommand.Name
`$Host.UI.RawUI.WindowTitle = `$ScriptName
`$Logfile = New-Item -ItemType file `"c:\$Scripts\`$ScriptName.log`"
$IN_Node_ScriptDir\set-vmguesttask.ps1 -Task $current_phase -Status started
$IN_Node_ScriptDir\set-vmguesttask.ps1 -Task $previous_phase -Status finished
$IN_Node_ScriptDir\set-vmguestshare.ps1 -user $Labbuildr_share_User -password $Labbuildr_share_password -HostIP $HostIP
$ScenarioScriptdir\configure-nmc.ps1 -SourcePath $IN_Guest_Sourcepath -Scriptdir $IN_Guest_CD_Scriptdir
"
Write-Verbose $Content
Set-Content "$Isodir\$Scripts\run-$Current_phase.ps1" -Value $Content -Force


####### Iso Creation        
            $Isocreatio = make-iso -Nodename $NodeName -Builddir $Builddir -isodir $Isodir
####### clone creation
            if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
                {
                Write-Verbose "Press any Key to continue to Cloning"
                pause
                }

            $CloneOK = Invoke-Expression  "$Builddir\clone-node.ps1 -MasterVHD $MasterVHDX -Nodename $NodeName -Size $Size -HVSwitch $HVSwitch $CloneParameter"



	
}#SCOM

} 

if (($NW.IsPresent -and !$NoDomainCheck.IsPresent) -or $NWServer.IsPresent)
{
	        ###################################################
	        # Networker Setup
	        ###################################################
	        $Nodeip = "$IPv4Subnet.$Gatewayhost"
	        $Nodename = $NWNODE
            $NodePrefix = $NWNODE
            [string]$AddonFeatures = "RSAT-ADDS, RSAT-ADDS-TOOLS, AS-HTTP-Activation, NET-Framework-45-Features"
            $ScenarioScriptdir = "$IN_Guest_CD_Scriptdir\$NodePrefix"
	        ###################################################
            if ($nw_ver -ge "nw85")
                {
                $Size = "L"
                }
            $CloneParameter = $CommonParameter
            If ($vlanID)
                {
                $CloneParameter = "$CloneParameter -vlanid $vlanID"
                }


	        $DC_test_ok =  test-dcrunning
            If ($DefaultGateway -match $Nodeip){$SetGateway = "-Gateway"}
	        ###################################################
	        status "Creating Networker Server $Nodename"
            write-verbose $Nodename
            write-verbose "Node has ip: $Nodeip"
            Write-Verbose $IPv4Subnet
            Write-Verbose "IPv4PrefixLength = $IPv4PrefixLength"
            Write-Verbose "IPv6Prefix = $IPV6Prefix"
            Write-Verbose "IPv6PrefixLength = $IPv6PrefixLength"
            Write-Verbose "Addressfamily = $AddressFamily"
####prepare iso
            Remove-Item -Path "$Isodir\$Scripts" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
            New-Item -ItemType Directory "$Isodir\$Scripts" -Force | Out-Null
            New-Item -ItemType Directory "$Builddir\$NodePrefix" -Force | Out-Null
            $Current_phase = "start-customize"
            $next_phase = "phase2"
            run-startcustomize -Current_phase $Current_phase -next_phase $next_phase
        

### phase 2
            $previous_phase = $current_phase
            $current_phase = $next_phase
            $next_phase = "phase3"
            run-phase2 -Current_phase $Current_phase -next_phase $next_phase

### phase 3
            $previous_phase = $current_phase
            $current_phase = $next_phase
            $next_phase = "phase4"
            run-phase3 -Current_phase $Current_phase -next_phase $next_phase
        
## Phase 4
            $previous_phase = $current_phase
            $current_phase = $next_phase
            $next_phase = "phase_install_$($Nodeprefix)"
            $Next_Phase_noreboot = $true
            run-phase4 -Current_phase $Current_phase -next_phase $next_phase -next_phase_no_reboot

## phase install_nw


            $previous_phase = $current_phase
            $current_phase = $next_phase
            $next_phase = "phase_$($Nodeprefix)_done"
$Content = "###
`$ScriptName = `$MyInvocation.MyCommand.Name
`$Host.UI.RawUI.WindowTitle = `$ScriptName
`$Logfile = New-Item -ItemType file `"c:\$Scripts\`$ScriptName.log`"
$IN_Node_ScriptDir\set-vmguesttask.ps1 -Task $current_phase -Status started
$IN_Node_ScriptDir\set-vmguesttask.ps1 -Task $previous_phase -Status finished
$IN_Node_ScriptDir\install-program.ps1 -Program $LatestJava -ArgumentList '/s' -SourcePath $IN_Guest_Sourcepath -Scriptdir $IN_Guest_CD_Scriptdir
#$IN_Node_ScriptDir\install-program.ps1 -Program $LatestReader -ArgumentList '/sPB /rs' -SourcePath $IN_Guest_Sourcepath -Scriptdir $IN_Guest_CD_Scriptdir
$IN_Node_ScriptDir\set-autologon -user nwadmin -SourcePath $IN_Guest_Sourcepath -Scriptdir $IN_Guest_CD_Scriptdir
$IN_Node_ScriptDir\Add-DomainUserToLocalGroup.ps1 -user nwadmin -group 'Remote Desktop Users' -SourcePath $IN_Guest_Sourcepath -Scriptdir $IN_Guest_CD_Scriptdir
$ScenarioScriptdir\install-nwserver.ps1 -nw_ver $nw_ver -SourcePath $IN_Guest_Sourcepath -Scriptdir $IN_Guest_CD_Scriptdir
$ScenarioScriptdir\nsruserlist.ps1 -SourcePath $IN_Guest_Sourcepath -Scriptdir $IN_Guest_CD_Scriptdir
$ScenarioScriptdir\create-nsrdevice.ps1 -AFTD AFTD1 -SourcePath $IN_Guest_Sourcepath -Scriptdir $IN_Guest_CD_Scriptdir
#$ScenarioScriptdir\configure-nmc.ps1 -SourcePath $IN_Guest_Sourcepath -Scriptdir $IN_Guest_CD_Scriptdir
New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name '99-$next_phase' -Value '$PSHOME\powershell.exe -Command `". $IN_Guest_CD_Scriptdir\$Scripts\run-$next_phase.ps1`"'
restart-computer
"
Write-Verbose $Content
Set-Content "$Isodir\$Scripts\run-$Current_phase.ps1" -Value $Content -Force
######


## phase install_nw_done


            $previous_phase = $current_phase
            $current_phase = $next_phase
            $next_phase = "phase_finished"
$Content = "###
`$ScriptName = `$MyInvocation.MyCommand.Name
`$Host.UI.RawUI.WindowTitle = `$ScriptName
`$Logfile = New-Item -ItemType file `"c:\$Scripts\`$ScriptName.log`"
# set-vmguesttask disabled for user
# $IN_Node_ScriptDir\set-vmguesttask.ps1 -Task $current_phase -Status started
# $IN_Node_ScriptDir\set-vmguesttask.ps1 -Task $previous_phase -Status finished
$IN_Node_ScriptDir\set-vmguestshare.ps1 -user $Labbuildr_share_User -password $Labbuildr_share_password -HostIP $HostIP
$ScenarioScriptdir\configure-nmc.ps1 -SourcePath $IN_Guest_Sourcepath -Scriptdir $IN_Guest_CD_Scriptdir
"
Write-Verbose $Content
Set-Content "$Isodir\$Scripts\run-$Current_phase.ps1" -Value $Content -Force
   ######



#################
<#
		# Setup Networker
		invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $ScenarioScriptDir -Script install-nwserver.ps1 -Parameter "-nw_ver $nw_ver $CommonParameter"-interactive
		if (!$Gateway.IsPresent)
            {
            checkpoint-progress -step networker -reboot
            }
        write-verbose "Waiting for NSR Media Daemon to start"
		While (([string]$UserLoggedOn = (&$vmrun -gu Administrator -gp Password123! listProcessesInGuest $CloneVMX)) -notmatch "nsrd.exe") { write-host -NoNewline "." }
		write-verbose "Creating Networker users"
		invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $ScenarioScriptDir -Script nsruserlist.ps1 -interactive
		status "Creating AFT Device"
        If ($DefaultGateway -match $Nodeip){
                write-verbose "Opening Firewall on Networker Server for your Client"
                invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $ScenarioScriptDir -Script firewall.ps1 -interactive
        		invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $ScenarioScriptDir -Script add-rras.ps1 -interactive -Parameter "-IPv4Subnet $IPv4Subnet"
                checkpoint-progress -step rras -reboot

        }
        invoke-postsection -wait
        invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $ScenarioScriptDir -Script configure-nmc.ps1 -interactive
		progress "Please finish NMC Setup by Double-Clicking Networker Management Console from Desktop on $NWNODE.$builddomain.local"
	    
#>


####### Iso Creation        
            $Isocreatio = make-iso -Nodename $NodeName -Builddir $Builddir -isodir $Isodir
####### clone creation
            if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
                {
                Write-Verbose "Press any Key to continue to Cloning"
                pause
                }

            $CloneOK = Invoke-Expression  "$Builddir\clone-node.ps1 -MasterVHD $MasterVHDX -Nodename $NodeName -Size $Size -HVSwitch $HVSwitch $CloneParameter"

####### wait progress


		    If ($CloneOK)
            {
            check-task -task "start-customize" -nodename $NodeName -sleep $Sleep
            }



} #Networker End
    
    
