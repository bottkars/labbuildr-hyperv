﻿<#
.Synopsis
   labbuildr-hyperv allows you to create Virtual Machines with Hyper-V from Predefined Scenarios.
   Scenarios include Exchange 2013, SQL, Hyper-V, SCVMM .. .
   labbuildr-hyperv runs on Windows 8.1 or greater with Hyper-V
.DESCRIPTION
   labbuildr is a Self Installing Lab tool for Building Virtual Machines
      
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
   https://github.com/bottkars/labbuildr-hyperv/wiki/
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
	[Parameter(ParameterSetName = "update",Mandatory = $false, HelpMessage = "select a branch to update from")][ValidateSet('develop','testing','master')]$branch,
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
    <#Exchange 2013   #>
	[Parameter(ParameterSetName = "E15",Mandatory = $true)][switch][alias('ex15')]$Exchange2013,
    <#
    <#Exchange 2016   #>
	[Parameter(ParameterSetName = "E16",Mandatory = $true)][switch][alias('ex16')]$Exchange2016,
    <#
    Determines Exchange CU Version to be Installed
    Valid Versions are:
    'Final
    Default is latest
    CU Location is [Driveletter]:\sources\e2016[cuver], e.g. c:\sources\e2016Preview1
    #>
    #>
	[Parameter(ParameterSetName = "E16", Mandatory = $false)]
    [ValidateSet('final','cu1','cu2','cu3','cu4')]
    $e16_cu,
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
    [ValidateSet('cu1', 'cu2', 'cu3', 'sp1','cu5','cu6','cu7','cu8','cu9','cu10','CU11','cu12','cu12','cu13','cu14','cu15')]
    [alias('ex_cu')]$e15_cu,
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
    [Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)][ValidateRange(1, 12)][alias('bs')][int]$Blankstart = "1",
    <# How many Blank Nodes#>
	[Parameter(ParameterSetName = "Blanknodes", Mandatory = $false)][ValidateRange(1, 12)][alias('bns')][int]$BlankNodes = "1",
    <#
    Selects the EMC ViPR SRM Binary Install
    
    #>
	[Parameter(ParameterSetName = "SRM", Mandatory = $true)][switch][alias('srm')]$ViPRSRM,
    [Parameter(ParameterSetName = "SRM")]
    [ValidateSet('3.7.0.0','3.6.0.3')]
    $SRM_VER='3.7.0.0',
    <# SCOM Scenario
    IP-Addresses: .18#>
	[Parameter(ParameterSetName = "SCOM", Mandatory = $true)][switch][alias('SC_OM')]$SCOM,
    [Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
    [Parameter(ParameterSetName = "SCVMM", Mandatory = $false)]
    [ValidateSet(
    'SC2012_R2',
    'SCTP3','SCTP4','SCTP5')]
    $SC_Version = "SC2012_R2",
    <# IP-Addresses: .19#>
	[Parameter(ParameterSetName = "SCVMM", Mandatory = $true)][switch][alias('SC_VMM')]$SCVMM,
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
    [Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
    [Parameter(ParameterSetName = "SCVMM", Mandatory = $false)]
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
    [Parameter(ParameterSetName = "SCVMM", Mandatory = $false)]
    [Parameter(ParameterSetName = "SRM", Mandatory = $false)]
    [ValidateSet(
    '2016TP5','2016TP4',
    '2012R2FallUpdate')]$Master,
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
    [Parameter(ParameterSetName = "SCOM", Mandatory = $false)]
    [Parameter(ParameterSetName = "SCVMM", Mandatory = $false)]
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
	[ValidateSet(
    'SQL2014SP1slip','SQL2012','SQL2012SP1','SQL2012SP2','SQL2012SP1SLIP','SQL2014','SQL2016','SQL2016_ISO'
    )]$SQLVER,
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
    [ValidateSet(
    'nmm9010',
    'nmm90.DA','nmm9001','nmm9002','nmm9003','nmm9004','nmm9005','nmm9006','nmm9007',
    'nmm8231','nmm8232',  
    'nmm8221','nmm8222','nmm8223','nmm8224','nmm8225',
    'nmm8218','nmm8217','nmm8216','nmm8214','nmm8212','nmm821'
    )]
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
    'nw8222','nw8221','nw822','nw8218','nw8217','nw8216','nw8215','nw8214','nw8213','nw8212','nw8211','nw821','nw8205','nw8204','nw8203','nw8202','nw82','nw8116','nw8115','nw8114', 'nw8113','nw8112', 'nw811',  'nw8105','nw8104','nw8102', 'nw81','nw85','nw85.BR1','nw85.BR2','nw85.BR3','nw85.BR4','nw90.DA','nw9001','nwunknown'
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
    [ValidateSet(
    'nw9010',
    'nw90.DA','nw9001','nw9002','nw9003','nw9004','nw9005','nw9006','nw9007',
    'nw8232','nw8231',
    'nw8226','nw8225','nw8224','nw8223','nw8222','nw8221','nw822',
    'nw8218','nw8217','nw8216','nw8215','nw8214','nw8213','nw8212','nw8211','nw821',
    'nw8206','nw8205','nw8204','nw8203','nw8202','nw82',
    'nw8138','nw8137','nw8136','nw8135','nw8134','nw8133','nw8132','nw8131','nw813',
    'nw8127','nw8126','nw8125','nw8124','nw8123','nw8122','nw8121','nw812',
    'nw8119','nw8118','nw8117','nw8116','nw8115','nw8114', 'nw8113','nw8112', 'nw811',
    'nw8105','nw8104','nw8103','nw8102','nw81',
    'nw8044','nw8043','nw8042','nw8041',
    'nw8037','nw8036','nw8035','nw81034','nw8033','nw8032','nw8031',
    'nw8026','nw8025','nw81024','nw8023','nw8022','nw8021',
    'nw8016','nw8015','nw81014','nw8013','nw8012',
    'nw8007','nw8006','nw8005','nw81004','nw8003','nw8002','nw80',
    'nwunknown'
    )]
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
[string]$Myself_ps1 = $MyInvocation.MyCommand
$myself = $Myself_ps1.TrimEnd(".ps1")
#$AddressFamily = 'IPv4'
$IPv4PrefixLength = '24'
$Builddir = $PSScriptRoot
$local_culture = Get-Culture
$git_Culture = New-Object System.Globalization.CultureInfo 'en-US'
if (Test-Path $env:SystemRoot\system32\ntdll.dll)
	{
	$runonos = "win_x86_64"
	}

If ($ConfirmPreference -match "none")
    {$Confirm = $false}
$Scripts = "labbuildr-scripts"
$Scripts_share_path = Join-Path $Builddir $Scripts
$Scripts_share_name = ((Split-Path -NoQualifier $Scripts_share_path) -replace "\\","_")
#$Sources_share_path = Join-Path $Sourcedir

try
    {
    $Current_labbuildr_branch = Get-Content  (Join-Path $Builddir "labbuildr.branch") -ErrorAction Stop
    }
catch
    {
    Write-Host -ForegroundColor Gray " ==>no prevoius branch"
    If (!$PSCmdlet.MyInvocation.BoundParameters['branch'].IsPresent)
        {
        $Current_labbuildr_branch = "master"
        }
    else
        {
        $Current_labbuildr_branch = $branch
        }
    }
If (!$PSCmdlet.MyInvocation.BoundParameters["branch"].IsPresent)
    {
    $branch = $Current_labbuildr_branch
    }
try
    {
    $Latest_labbuildr_git = Get-Content  (Join-path $Builddir "labbuildr-hyperv-$branch.gitver") -ErrorAction Stop
    }
    catch
    {
    [datetime]$Latest_labbuildr_git = "07/11/2015"
    }
try
    {
    $Latest_labbuildr_scripts_git = Get-Content  (Join-path $Builddir "labbuildr-scripts-$branch.gitver") -ErrorAction Stop
    }
    catch
    {
    [datetime]$Latest_labbuildr_scripts_git = "07/11/2015"
    }
try
    {
    $Latest_labtools_git = Get-Content  (Join-path $Builddir "labtools-$branch.gitver") -ErrorAction Stop
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
$AAGDB = "AWORKS"
$major = "2016"
$Edition = "XMAS"
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
$latest_nmm = 'nmm91002'
$latest_nw = 'nw91002'
$latest_e16_cu = 'cu4'
$latest_e15_cu = 'cu15'
$latest_e14_sp = 'sp3'
$latest_e14_ur = 'ur16'
$latest_sqlver  = 'SQL2016'
$latest_master = '2012R2FallUpdate'
$latest_sql_2012 = 'SQL2012SP2'
$NW85_requiredJava = "jre-7u61-windows-x64"
# $latest_java8 = "jre-8u51-windows-x64.exe"
$latest_java8uri = "http://javadl.sun.com/webapps/download/AutoDL?BundleId=107944"
$HostScriptDir = "$Builddir\$Scripts\"
$Adminuser = "Administrator"
$Adminpassword = "Password123!"
$Isodir = "$Builddir\$Scripts"
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
$Sleep = 10
[string]$Sources = "Sources"
$Sourcedirdefault = "c:\Sources"
$Sourceslink = "https://my.syncplicity.com/share/wmju8cvjzfcg04i/sources"
$Buildname = Split-Path -Leaf $Builddir
$Scenarioname = "default"
$Scenario = 1
$AddonFeatures = ("RSAT-ADDS", "RSAT-ADDS-TOOLS", "AS-HTTP-Activation", "NET-Framework-45-Features")
$Gatewayhost = "11" 
$Host.UI.RawUI.WindowTitle = "$Buildname"
###### labbuildr-hyperv statics
$labbuildr_modules_required = "labtools"
$my_repo = "labbuildr-hyperv"
$IN_Guest_UNC_Sourcepath = "X:"
$IN_Guest_UNC_Scriptroot = "Z:"
$IN_Guest_CD_Scriptroot = "D:"
$IN_Guest_LogDir = "C:\$Scripts"
$IN_Guest_CD_Node_ScriptDir = "$IN_Guest_CD_Scriptroot\Node"
$IN_Guest_UNC_Node_ScriptDir = "$IN_Guest_UNC_Scriptroot\Node"
$Dynamic_Scripts_Name = "Scripts"
$Dynamic_Scripts = Join-Path $Isodir $Dynamic_Scripts_Name
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
            [datetime]$latest_local_Git,
            [string]$Destination,
            [switch]$delete
            )
		$AuthHeaders = @{'Authorization' = "token b64154d0de42396ebd72b9f53ec863f2234f6997"}
		if ($runonos -eq "win_x86_64" )
			{
			$branch =  $branch.ToLower()
			$Isnew = $false
			Write-Verbose "Using update-fromgit function for $repo"
			$Uri = "https://api.github.com/repos/$RepoLocation/$repo/commits/$branch"
			$Zip = ("https://github.com/$RepoLocation/$repo/archive/$branch.zip").ToLower()
			$local_culture = Get-Culture
			$git_Culture = New-Object System.Globalization.CultureInfo 'en-US'
			if ($Global:vmxtoolkit_type -eq "win_x86_64" )
				{
				try
					{
					$request = Invoke-WebRequest -UseBasicParsing -Uri $Uri -Method Head -ErrorAction Stop -Headers $AuthHeaders
					}
				Catch
					{
					Write-Warning "Error connecting to git"
					if ($_.Exception.Response.StatusCode -match "Forbidden")
						{
						Write-Host -ForegroundColor Gray " ==>Status inidicates that Connection Limit is exceeded"
						}
					exit
					}
				
				$latest_OnGit =  $request.Headers.'Last-Modified'
				#Write-Host $latest_OnGit
				}
			##else
		#		{
		#		$request = curl -D - $Uri | grep Last-Modified
	#			$request
	#			[datetime]$latest_OnGit = $request -replace 'Last-Modified: '
	#			}
			Write-Host " ==>we have $repo version "(get-date $latest_local_Git)", "(get-date $latest_OnGit)" is online !"
	#		$latest_local_Git -lt $latest_OnGit
			if ($latest_local_Git -lt $latest_OnGit -or $force.IsPresent )
				{
				$Updatepath = "$Builddir/Update"
				if (!(Get-Item -Path $Updatepath -ErrorAction SilentlyContinue))
						{
						$newDir = New-Item -ItemType Directory -Path "$Updatepath" | out-null
						}
				Write-Host -ForegroundColor Gray " ==>we found a newer Version for $repo on Git Dated $($request.Headers.'Last-Modified')"
				if ($delete.IsPresent)
					{
					Write-Host -ForegroundColor Gray "==>cleaning $Destination"
					Remove-Item -Path $Destination -Recurse -ErrorAction SilentlyContinue
					}
				if ($Global:vmxtoolkit_type -eq "win_x86_64")
					{
					Get-LABHttpFile -SourceURL $Zip -TarGetFile "$Builddir/update/$repo-$branch.zip" -ignoresize
					Expand-LABZip -zipfilename "$Builddir/update/$repo-$branch.zip" -destination $Destination -Folder $repo-$branch
					}
				else
					{
					Receive-LABBitsFile -DownLoadUrl $Zip -destination "$Builddir/update/$repo-$branch.zip"
					Expand-LABpackage -Archive "$Builddir/update/$repo-$branch.zip" -filepattern $Repo-$branch -destination $Destination
					}
				$Isnew = $true
				$latest_OnGit | Set-Content (join-path $Builddir "$repo-$branch.gitver")
				}
			else
				{
				Write-Host -ForegroundColor Gray " ==>no update required for $repo on $branch, already newest version "
				}
			if ($Isnew) 
			{
			return $true
			}
		}

}
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
				write-host -ForegroundColor Gray " ==> $Sourcedir does not contain $Version"
				Write-Warning "Please Download and extraxt $Version to $Sourcedir\$Version"
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
        Write-Warning "No dc installed for $Builddir labbuildr environment, we need to build one first"
        return $False
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
        write-host -NoNewline -ForegroundColor Gray " ==> Checking for task $Task finished "
        do
			{
			$sleep = 1
			foreach ($i in (1..$sleep)) 
				{
				Write-Host -ForegroundColor Yellow "-`b" -NoNewline
				sleep 1
				Write-Host -ForegroundColor Yellow "\`b" -NoNewline
				sleep 1
				Write-Host -ForegroundColor Yellow "|`b" -NoNewline
				sleep 1
				Write-Host -ForegroundColor Yellow "/`b" -NoNewline
				sleep 1
				}
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
                Write-Verbose "Integration Services not running"
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
$IN_Guest_CD_Node_ScriptDir\set-vmguesttask.ps1 -Task $Current_phase -Status started
New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name '99-$next_phase' -Value '$PSHOME\powershell.exe -Command `". $IN_Guest_CD_Scriptroot\$Dynamic_Scripts_Name\run-$next_phase.ps1`"'
$IN_Guest_CD_Node_ScriptDir\set-vmguesttask.ps1 -Task $Current_phase -Status finished
$IN_Guest_CD_Node_ScriptDir\configure-node.ps1 -Scriptdir $IN_Guest_CD_Scriptroot -nodeip $Nodeip -IPv4subnet $IPv4subnet -nodename $Nodename -IPv4PrefixLength $IPv4PrefixLength -IPv6PrefixLength $IPv6PrefixLength -IPv6Prefix $IPv6Prefix -AddressFamily $AddressFamily $AddGateway -AddOnfeatures '$AddonFeatures' -Domain $BuildDomain $CommonParameter
"
Write-Verbose $Content
Write-Verbose ""
Set-Content "$Dynamic_Scripts\$Current_phase.ps1" -Value $Content -Force
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
$Content = "### $Current_phase
"
Write-Verbose ""
Write-Verbose "$Content"
Write-Verbose ""
Set-Content "$Dynamic_Scripts\run-$Current_phase.ps1" -Value $Content -Force


}
function run-phase3
{
param (
[string]$next_phase,
[string]$Current_phase
)
$Content = @()
$Content = "### $Current_phase
`$ScriptName = `$MyInvocation.MyCommand.Name
`$Host.UI.RawUI.WindowTitle = `$ScriptName
`$Logfile = New-Item -ItemType file `"c:\$Scripts\`$ScriptName.log`"
$IN_Guest_CD_Node_ScriptDir\set-vmguesttask.ps1 -Task $current_phase -Status started
New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name '99-$next_phase' -Value '$PSHOME\powershell.exe -Command `". $IN_Guest_CD_Scriptroot\$Dynamic_Scripts_Name\run-$next_phase.ps1`"'
$IN_Guest_CD_Node_ScriptDir\set-vmguesttask.ps1 -Task $previous_phase -Status finished
Set-ExecutionPolicy -ExecutionPolicy bypass -Force
$IN_Guest_CD_Node_ScriptDir\powerconf.ps1 -Scriptdir $IN_Guest_CD_Scriptroot
$IN_Guest_CD_Node_ScriptDir\set-uac.ps1 -Scriptdir $IN_Guest_CD_Scriptroot
$IN_Guest_CD_Node_ScriptDir\set-winrm.ps1 -Scriptdir $IN_Guest_CD_Scriptroot
"

        if ($nw.IsPresent)
            {
            $Content += "$IN_Guest_CD_Node_ScriptDir\install-nwclient.ps1 -Scriptdir $IN_Guest_CD_Scriptroot
"
            }

        $Content += "restart-computer -force
"
    
        Write-Verbose $Content
        Set-Content "$Dynamic_Scripts\run-$Current_phase.ps1" -Value $Content -Force


}
function run-phase4
{
param (
[string]$next_phase,
[string]$Current_phase,
[switch]$next_phase_no_reboot
)
$Content = @()
$Content = "### $Current_phase
`$ScriptName = `$MyInvocation.MyCommand.Name
`$Host.UI.RawUI.WindowTitle = `$ScriptName
`$Logfile = New-Item -ItemType file `"c:\$Scripts\`$ScriptName.log`"
$IN_Guest_CD_Node_ScriptDir\set-vmguesttask.ps1 -Task $current_phase -Status started
$IN_Guest_CD_Node_ScriptDir\set-vmguestshare.ps1 -user $Labbuildr_share_User -password $Labbuildr_share_password -HostIP $HostIP -Scripts_share_name $Scripts_share_name -Sources_share_name $Sources_share_name
$IN_Guest_CD_Node_ScriptDir\set-vmguestshare.ps1 -user $Labbuildr_share_User -password $Labbuildr_share_password -HostIP $HostIP -Scripts_share_name $Scripts_share_name -Sources_share_name $Sources_share_name
$IN_Guest_CD_Node_ScriptDir\create-labshortcut.ps1 -scriptdir $IN_Guest_UNC_Scriptroot
$IN_Guest_CD_Node_ScriptDir\set-vmguesttask.ps1 -Task $previous_phase -Status finished
"
if ($next_phase_no_reboot)
    {
    $Content += "$IN_Guest_CD_Scriptroot\$Dynamic_Scripts_Name\run-$next_phase.ps1
    "
    }
else
    {
    $Content += "New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name '99-$next_phase' -Value '$PSHOME\powershell.exe -Command `". $IN_Guest_CD_Scriptroot\$Dynamic_Scripts_Name\run-$next_phase.ps1`"'
    "
    }
Write-Verbose $Content
Set-Content "$Dynamic_Scripts\run-$Current_phase.ps1" -Value $Content -Force

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
Set-Content "$Dynamic_Scripts\run-$Current_phase.ps1" -Value $Content -Force

}

############################### End Function
switch ($PsCmdlet.ParameterSetName)
{
    "update" 
        {
        $ReloadProfile = $False
        $Repo = $my_repo
        $RepoLocation = "bottkars"
		[datetime]$latest_local_git =  [datetime]::parse($Latest_labbuildr_git, $git_Culture)
        $Destination = "$Builddir"
        $Has_update = update-fromGit -Repo $Repo -RepoLocation $RepoLocation -branch $branch -latest_local_Git $Latest_local_git -Destination $Destination
        if (Test-Path "$Builddir\deletefiles.txt")
		    {
			$deletefiles = get-content "$Builddir\deletefiles.txt"
			foreach ($deletefile in $deletefiles)
			    {
				if (Get-Item $Builddir\$deletefile -ErrorAction SilentlyContinue)
				    {
					Remove-Item -Path $Builddir\$deletefile -Recurse -ErrorAction SilentlyContinue
					Write-Host -ForegroundColor White  " ==>deleted $deletefile"
					write-log "deleted $deletefile"
					}
			    }
            }
        else 
            {
            Write-Host -ForegroundColor Gray " ==>No Deletions required"
            }

        

        ####
        $Repo = "labbuildr-scripts"
        $RepoLocation = "bottkars"
        $Latest_local_git = $Latest_labbuildr_scripts_git
        $Destination = "$Builddir\$Scripts"
        $Has_update = update-fromGit -Repo $Repo -RepoLocation $RepoLocation -branch $branch -latest_local_Git $Latest_local_git -Destination $Destination -delete
        
        foreach ($Repo in $labbuildr_modules_required)
            {
        $RepoLocation = "bottkars"
        $Latest_local_git = $Latest_labtools_git
        $Destination = "$Builddir\$Repo"
        if ($Has_update = update-fromGit -Repo $Repo -RepoLocation $RepoLocation -branch $branch -latest_local_Git $Latest_local_git -Destination $Destination -delete)
            {
            $ReloadProfile = $True
            }
        }
        ####
        if ($ReloadProfile)
            {
            Remove-Item .\Update -Recurse -Confirm:$false
			Write-Host -ForegroundColor White  " ==>Update Done"
            Write-Host -ForegroundColor White  " ==>press any key for reloading Modules"
            pause
            ./profile.ps1
            }
        else
            {
            ."./$Myself_ps1"
            }

    return 
    #$ReloadProfile
    }# end Updatefromgit
    "Shortcut"
        {
				status "Creating Desktop Shortcut for $Buildname"
				createshortcut -Target "$psHome\powershell.exe" -Arguments "-noexit -command $Builddir\profile.ps1"	-IconLocation "powershell.exe,1" -Elevated -OutputDirectory "$home\Desktop" -WorkingDirectory $Builddir -Name $Buildname -Description "Labbuildr Hyper-V" -Verbose
                return
        }# end shortcut
    "Version"
        {
				Write-Host -ForegroundColor Magenta "$my_repo version $major-$verlabbuildr$Edition on branch $Current_labbuildr_branch"
                if ($Latest_labbuildr_git)
                    {
                    Status "Git Release $Latest_labbuildr_git"
                    }
                if ($Latest_labbuildr_scripts_git)
                    {
                    Status "labbuildr-Scripts Git Release $Latest_labbuildr_scripts_git"
                    }
                if ($Latest_labtools_git)
                    {
                    Status "Labtools Git Release $Latest_labtools_git"
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
        Write-Host -ForegroundColor White  "Loading defaults from $Builddir\defaults.xml"
        $LabDefaults = Get-LABDefaults
        }
       if (!($LabDefaults))
            {
            try
                {
                $LabDefaults = Get-labDefaults -Defaultsfile ".\defaults.xml.example"
                }
            catch
                {
            Write-Warning "no  defaults or example defaults found, exiting now"
            exit
                }
            Write-Host -ForegroundColor Magenta "Using generic defaults from $my_repo"
        }
        $DefaultGateway = $LabDefaults.DefaultGateway
        if (!$nmm_ver)
            {
            try
                {
                $nmm_ver = $LabDefaults.nmm_ver
                }
            catch
            [System.Management.Automation.ValidationMetadataException]
                {
                Write-Host -ForegroundColor Gray " ==> defaulting NMM version to $latest_nmm"
                 $nmm_ver = $latest_nmm
                }
            } 
        $nmm_scvmm_ver = $nmm_ver -replace "nmm","scvmm"
        if (!$nw_ver)
            {
            try
                {
                $nw_ver = $LabDefaults.nw_ver
                }
            catch
            [System.Management.Automation.ValidationMetadataException]
                {
                Write-Host -ForegroundColor Gray " ==> defaulting nw version to $latest_nw"
                 $nw_ver = $latest_nw
                }
            } 
        if (!$Masterpath)
            {
            try
                {
                $Masterpath = $LabDefaults.Masterpath
                }
            catch
                {
                Write-Host -ForegroundColor Gray " ==> No Masterpath specified, trying default"
                $Masterpath = $Builddir
                }
            }
       
        if (!$Sourcedir)
            {
            try
                {
                $Sourcedir = $LabDefaults.Sourcedir
                }
            catch [System.Management.Automation.ParameterBindingException]
                {
                Write-Host -ForegroundColor Gray " ==> No sources specified, trying default"
                $Sourcedir = $Sourcedirdefault
                }
            }

        if (!$Master) 
            {
            try
                {
                $master = $LabDefaults.master
                }
            catch 
                {
                Write-Host -ForegroundColor Gray " ==> No Master specified, trying default"
                $Master = $latest_master
                }
            }
        if (!$SQLVER)
            {   
            try
                {
                $sqlver = $LabDefaults.sqlver
                }
            catch 
                {
                Write-Host -ForegroundColor Gray " ==> No sqlver specified, trying default"
                $sqlver = $latest_sqlver
                }
            }
        if (!$e14_sp) 
            {
            try
                {
                $e14_sp = $LabDefaults.e14_sp
                }
            catch 
                {
                Write-Host -ForegroundColor Gray " ==> No Exchange 2010 SP Specified, setting $latest_e14_sp"
                $e14_sp = $latest_e14_sp
                }
            }
        if (!$e14_ur) 
            {
            try
                {
                $e14_ur = $LabDefaults.e14_ur
                }
            catch 
                {
                Write-Host -ForegroundColor Gray " ==> No Exchange 2010 Update Rollup Specified, setting $latest_e14_ur"
                $e14_ur = $latest_e14_ur
                }
            }

        if (!$e15_cu) 
            {
            try
                {
                $e15_cu = $LabDefaults.e15_cu
                }
            catch 
                {
                Write-Host -ForegroundColor Gray " ==> No Exchange 2013 CU Specified, setting $latest_e15_cu"
                $e15_cu = $latest_e15_cu
                }
            }
        if (!$e16_cu) 
            {
            try
                {
                $e16_cu = $LabDefaults.e16_cu
                }
            catch 
                {
                Write-Host -ForegroundColor Gray " ==> No Exchange 2016 CU Specified, setting $latest_e16_cu"
                $e16_cu = $latest_e16_cu
                }
            }
        if (!$ScaleIOVer) 
            {
            try
                {
                $ScaleIOVer = $LabDefaults.ScaleIOVer
                }
            catch 
                {
                Write-Host -ForegroundColor Gray " ==> No ScaleIOVer specified, trying default"
                $ScaleIOVer = $latest_ScaleIOVer
                }
            }
        if (!$vmnet) 
            {
            try
                {
                $vmnet = $LabDefaults.vmnet
                }
            catch 
                {
                Write-Host -ForegroundColor Gray " ==> No vmnet specified, trying default"
                $vmnet = $Default_vmnet
                }
            }
        if (!$BuildDomain) 
            {
            try
                {
                $BuildDomain = $LabDefaults.BuildDomain
                }
            catch 
                {
                Write-Host -ForegroundColor Gray " ==> No BuildDomain specified, trying default"
                $BuildDomain = $Default_BuildDomain
                }
            } 
        if  (!$MySubnet) 
            {
            try
                {
                $MySubnet = $LabDefaults.mysubnet
                }
            catch 
                {
                Write-Host -ForegroundColor Gray " ==> No mysubnet specified, trying default"
                $MySubnet = $Default_Subnet
                }
            }
       if (!$vmnet) 
            {
            try
                {
                $vmnet = $LabDefaults.vmnet
                }
            catch 
                {
                Write-Host -ForegroundColor Gray " ==> No vmnet specified, trying default"
                $vmnet = $Default_vmnet
                }
            }
       if (!$AddressFamily) 
            {
            try
                {
                $AddressFamily = $LabDefaults.AddressFamily
                }
            catch 
                {
                Write-Host -ForegroundColor Gray " ==> No AddressFamily specified, trying default"
                $AddressFamily = $Default_AddressFamily
                }
            }
       if (!$IPv6Prefix) 
            {
            try
                {
                $IPv6Prefix = $LabDefaults.IPv6Prefix
                }
            catch 
                {
                Write-Host -ForegroundColor Gray " ==> No IPv6Prefix specified, trying default"
                $IPv6Prefix = $Default_IPv6Prefix
                }
            }
       if (!$IPv6PrefixLength) 
            {
            try
                {
                $IPv6PrefixLength = $LabDefaults.IPv6PrefixLength
                }
            catch 
                {
                Write-Host -ForegroundColor Gray " ==> No IPv6PrefixLength specified, trying default"
                $IPv6PrefixLength = $Default_IPv6PrefixLength
                }
            }
        if (!($MyInvocation.BoundParameters.Keys.Contains("Gateway")))
            {
            if ($LabDefaults.Gateway -eq "true")
                {
                $Gateway = $true
                [switch]$NW = $True
                $DefaultGateway = "$IPv4Subnet.$Gatewayhost"
                }
            }
        if (!($MyInvocation.BoundParameters.Keys.Contains("NoDomainCheck")))
            {
            if ($LabDefaults.NoDomainCheck -eq "true")
                {
                [switch]$NoDomainCheck = $true
                }
            }
        if (!($MyInvocation.BoundParameters.Keys.Contains("NMM")))
            {
            if ($LabDefaults.NMM -eq "true")
                {
                $nmm = $true
                $nw = $true
                }
            }
		if ($LabDefaults.custom_domainsuffix)
			{
			$custom_domainsuffix = $LabDefaults.custom_domainsuffix
			}
		else
			{
			$custom_domainsuffix = "local"
			}
		if ($LabDefaults.LanguageTag)
			{
			$LanguageTag= $LabDefaults.LanguageTag
			}
		else
			{
			$LanguageTag = "en_US"
			}
        
    }
if (Test-Path "$Builddir\Switchdefaults.xml")
    {
    status "Loading Switchdefaults from $Builddir\Switchdefaults.xml"
    $SwitchDefault = Get-LABSwitchDefaults

    }
$HVSwitch = $SwitchDefault.$($Vmnet)

if ($defaults.IsPresent) 
    {
    try
        {
        $vlanID = $LabDefaults.vlanID
        }
    catch 
        {
        Write-Warning "No VLanID specified, trying default"
        $vlanID = $Default_vlanid
        }
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
    $HostIP_Address = Get-NetIPAddress -InterfaceAlias "vEthernet ($HVSwitch)*" -AddressFamily IPv4 -ErrorAction Stop
    }
catch
    {
    Write-Warning "Could not detect Host IP Address configured for VMSwitch $HVSwitch"
    break
    }
    
$HostIP = $HostIP_Address.IPAddress
Write-Host -ForegroundColor Gray " ==> we use $HostIP for communication with Guest"


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
if (!$vlanID){$vlanID = $Default_vlanid}

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
Write-Host -ForegroundColor White  "saving defaults to $Builddir\defaults.xml"
$config =@()
$config += ("<config>")
$config += ("<nmm_ver>$nmm_ver</nmm_ver>")
$config += ("<nw_ver>$nw_ver</nw_ver>")
$config += ("<master>$Master</master>")
$config += ("<sqlver>$SQLVER</sqlver>")
$config += ("<e14_ur>$e14_ur</e14_ur>")
$config += ("<e14_sp>$e14_sp</e14_sp>")
$config += ("<e15_cu>$e15_cu</e15_cu>")
$config += ("<e16_cu>$e16_cu</e16_cu>")
$config += ("<vmnet>$VMnet</vmnet>")
$config += ("<vlanid>$vlanID</vlanid>")
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
$config += ("<Puppet>$($LabDefaults.Puppet)</Puppet>")
$config += ("<PuppetMaster>$($LabDefaults.PuppetMaster)</PuppetMaster>")
$config += ("<Hostkey>$($LabDefaults.HostKey)</Hostkey>")
$config += ("</config>")
$config | Set-Content $defaultsfile
}
########
#
#
########


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

try 
    {
    $SMBSHARE_Scripts = get-smbshare $Scripts_share_name -erroraction stop
    }
catch
    {
    Write-Warning " Scripts Share $Scripts_share_name not found, creating new"
    $SMBSHARE_Scripts = New-SmbShare -name $Scripts_share_name -path $Scripts_share_path -Temporary
    }
if (!$SMBSHARE_Scripts)
    {
    Write-Warning "Could not create or find Scripts share, exiting now"
    break
    }


<#
$Sources_share_name = ((Split-Path -NoQualifier $Builddir) -replace "\\","_")


#>
$Sources_share_name =  ((split-path -NoQualifier $Builddir) -replace "\\","_")+"_$Sources"
if (!($SMBShare_Sources = get-smbshare -name $Sources_share_name -erroraction SilentlyContinue ))
        {
        Write-Warning "Labbuildr Sources Share not found, creating new"
        $SMBShare_Sources = new-smbshare -name $Sources_share_name -path "$Sourcedir" 
        }
elseif (($SMBShare_Sources.Path -replace "\\","/") -eq ($SMBShare_Sources_path -replace "\\","/" ))
    {
    Write-Verbose "Removing existing Share $Sources_share_name"
    Remove-SmbShare $Sources_share_name
    $SMBShare_Sources = new-smbshare -name $Sources_share_name -path "$Sourcedir" 
    } 
     <#
     
     $Scripts_share_path = Join-Path $Builddir $Scripts
$Scripts_share_name = ((Split-Path -NoQualifier $Scripts_share_path) -replace "\\","_")
#= Join-Path $Sourcedir

     
     
     #>

  #  }

if (!$SMBShare_Sources)
    {
    Write-Warning "Could not create or find Sources share, exiting now"
    break
    }

### setting ACLs
Write-Host "==> Verifying ACL´s for $Sourcedir"
    $Acl = Get-Acl $Sourcedir
	$New_rule = New-Object  system.security.accesscontrol.filesystemaccessrule("$Global:labbuildr_user","FullControl", "ContainerInherit, ObjectInherit", "none", "Allow")
    $Acl.SetAccessRule($New_rule)
    Set-Acl $Sourcedir $Acl

if (!$Master)

    {
    Write-Warning "No Master was specified. See get-help .\labbuildr.ps1 -Parameter Master !!"
    Write-Warning "Load masters from $UpdateUri"
    break
    } # end Master
try
    {
    $MasterVHDX = test-labmaster -Masterpath "$Masterpath" -Master $Master -mastertype hyperv -ErrorAction Stop # -Confirm:$Confirm 
    }
catch
    {
    Write-Warning "Could not receive master $Master"
    return
    }
<#
    Try
    {
    $MyMaster = get-childitem -path "$Masterpath\$Master\$Master.vhdx" -ErrorAction SilentlyContinue
    }
    catch [Exception] 
    {
    Write-Warning "Could not find $Masterpath\$Master\$Master.vhdx"
    Write-Warning "Please download a Master from https://github.com/bottkars//wiki/Master"
    Write-Warning "And extract to $Masterpath"
    # write-verbose $_.Exception
    break
    }
if (!$MyMaster)
    {
    Write-Warning "Could not find $Masterpath\$Master"
    Write-Warning "Please download a Master from https://github.com/bottkars/$my_repo/wiki/Master"
    Write-Warning "And extract to $Masterpath"
    # write-verbose $_.Exception
    break
    }
else
    {
   $MasterVHDX = $MyMaster.Fullname		
   Write-Verbose "We got master $MasterVHDX"
   }
#>
write-verbose "After Masterconfig !!!! "

########

### Common CloneParameters
$CloneParameter = $CommonParameter
If ($vlanID)
    {
    $CloneParameter = "$CloneParameter -vlanid $vlanID"
    }


########


###### requirements check

if (!(test-path $Builddir\bin\mkisofs.exe -ErrorAction SilentlyContinue))
    {
    if (!(test-path $Builddir\bin\ -ErrorAction SilentlyContinue))
        {
        $Bin_Dir = New-Item -ItemType Directory -Path $Builddir\bin\ 
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
$NW_Sourcedir = Join-Path $Sourcedir "Networker"
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
        #$Sourcever += $nw_ver 
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

    if ((Test-Path "$NW_Sourcedir/$nw_ver/win_x64/networkr/networker.msi") -or (Test-Path "$NW_Sourcedir/$nw_ver/win_x64/networkr/lgtoclnt-8.5.0.0.exe"))
        {
        Write-Verbose "Networker $nw_ver found"
        }
    elseif ($nw_ver -lt "nw84")
        {

        Write-Warning "We need to get $NW_ver, trying Automated Download"
        $NW_download_ok  =  receive-LABNetworker -nw_ver $nw_ver -arch win_x64 -Destination $NW_Sourcedir -unzip # $CommonParameter

        if ($NW_download_ok)
            {
            Write-Host -ForegroundColor Magenta "Received $nw_ver"
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


##### echange downloads section
if ($Exchange2016.IsPresent)
    {
    if (!$e16_cu)
        {
        $e16_cu = $Latest_e16_cu
        }
	If ($e16_cu -lt "cu3")
		{
		$NET_VER = "452"
		}
	else
		{
		switch ($e16_cu)
			{
			default
				{
				$NET_VER = "462"
				$E16_REQUIRED_KB = "KB3206632"
				}
			}
		
		}
    If ($Master -gt '2012Z' -and $e16_cu -lt "cu3")
        {
        Write-Warning "Only master up 2012R2Fallupdate supported in this scenario"
        exit
        }
    If (!(Receive-LABExchange -Exchange2016 -e16_cu $e16_cu -Destination $Sourcedir -unzip))
        {
        Write-warning "We could not receive Exchange 2016 $e16_cu"
        return
        }
    $EX_Version = "E2016"
    $Scenarioname = "Exchange"
    $Prereqdir = "Attachments"
    $attachments = (
    "http://www.cisco.com/c/dam/en/us/solutions/collateral/data-center-virtualization/unified-computing/fle_vmware.pdf"
    )
    $Destination = Join-Path $Sourcedir $Prereqdir
    if (!(Test-Path $Destination)){New-Item -ItemType Directory -Path $Destination | Out-Null }
     foreach ($URL in $attachments)
        {
        $FileName = Split-Path -Leaf -Path $Url
        if (!(test-path  "$Destination\$FileName"))
            {
            Write-Verbose "$FileName not found, trying Download"
            if (!(Receive-LABBitsFile -DownLoadUrl $URL -destination $Sourcedir\$Prereqdir\$FileName))
                { write-warning "Error Downloading file $Url, Please check connectivity"
                  Write-Warning "Creating Dummy File"
                  New-Item -ItemType file -Path "$Sourcedir\$Prereqdir\$FileName" | out-null
                }
            }

        
        }
}

if ($Exchange2013.IsPresent)
    {
    if (!$e15_cu)
        {
        $e15_cu = $Latest_e15_cu
        }
	If ($e15_cu -lt "cu99")
		{
		$NET_VER = "452"
		}
	else
		{
		$NET_VER = "462"
		}
    If ($Master -gt '2012Z')
        {
        Write-Warning "Only master up 2012R2Fallupdate supported in this scenario"
        exit
        }
    If (!(Receive-LABExchange -Exchange2013 -e15_cu $e15_cu -Destination $Sourcedir -unzip))
        {
        Write-Host -ForegroundColor Gray " ==>we could not receive Exchange 2013 $e15_cu"
        return
        }
    $EX_Version = "E2013"
    $Scenarioname = "Exchange"
    $Prereqdir = "Attachments"
    $attachments = (
    "http://www.cisco.com/c/dam/en/us/solutions/collateral/data-center-virtualization/unified-computing/fle_vmware.pdf"
    )
    $Destination = Join-Path $Sourcedir $Prereqdir
    if (!(Test-Path $Destination)){New-Item -ItemType Directory -Path $Destination | Out-Null }
     foreach ($URL in $attachments)
        {
        $FileName = Split-Path -Leaf -Path $Url
		$Destination_file = Join-Path $Destination $FileName
        if (!(test-path  $Destination_file))
            {
            Write-Verbose "$FileName not found, trying Download"
            if (!(Receive-LABBitsFile -DownLoadUrl $URL -destination $Destination_file))
                { Write-Host -ForegroundColor Gray " ==>Error Downloading file $Url, Please check connectivity"
                  Write-Host -ForegroundColor Gray " ==>creating dummy File"
                  New-Item -ItemType file -Path $Destination_file | out-null
                }
            }
        }
	    if ($DAG.IsPresent)
	        {
		    $Work_Items +=  " ==>we will form a $EX_Version $EXNodes-Node DAG"
	        }
}


############## SCOM Section
if ($SCOM.IsPresent)
  {
    Write-Warning "Entering SCOM Prereq Section"
    [switch]$SQL=$true
    If (!(Receive-LABSysCtrInstallers -SC_Version $SC_Version -Component SCOM -Destination $Sourcedir -unzip))
        {
        Write-warning "We could not receive scom"
        return
        }

    }# end SCOMPREREQ

#######

############## SCVMM Section
if ($SCVMM.IsPresent)
  {
    Write-Warning "Entering SCVMM Prereq Section"
    [switch]$SQL=$true
    $Prereqdir = "prereq"
    If (!(Receive-LABSysCtrInstallers -SC_Version $SC_Version -Component SCVMM -Destination $Sourcedir -unzip))
        {
        Write-warning "We could not receive scom"
        return
        }

    }# end SCOMPREREQ

#######

##############

if ($SQL.IsPresent -or $AlwaysOn.IsPresent)
    {
    If ($SQLVER -match 'SQL2016')
        {
        $Java8_required = $true
        }
    $AAGURL = "https://community.emc.com/servlet/JiveServlet/download/38-111250/AWORKS.zip"
    $URL = $AAGURL
    $FileName = Split-Path -Leaf -Path $Url
    Write-Verbose "Testing $FileName in $Sourcedir"
    if (!(test-path  "$Sourcedir\Aworks\AdventureWorks2012.bak"))
        {
        Write-Verbose "Trying Download"
        if (!(get-prereq -DownLoadUrl $URL -destination  "$Sourcedir\$FileName"))
            { 
            Write-Warning "Error Downloading file $Url, Please check connectivity"
            exit
            }
        #New-Item -ItemType Directory -Path "$Sourcedir\Aworks" -Force
        Extract-Zip -zipfilename $Sourcedir\$FileName -destination $Sourcedir
        }

    if (!($SQL_OK = receive-labsql -SQLVER $SQLVER -Destination $Sourcedir -Product_Dir "SQL" -extract -WarningAction SilentlyContinue))
        {
        break
        }

}

##end Autodownloaders
##########################################
If ($DAG.IsPresent)
    {
    if (!$EXNodes)
        {
        $EXNodes = 2 
        Write-Host -ForegroundColor Gray " ==> No -EXnodes specified, defaulting to $EXNodes Nodes for DAG Deployment"
        }
	Write-Host -ForegroundColor Magenta " ==>We will form a $EXNodes-Node DAG"

    }
if (!$EXnodes)
    {$EXNodes = 1}

if ($nw.IsPresent -and !$NoDomainCheck.IsPresent) 
    { #workorder "Networker $nw_ver Node will be installed" 
    }
write-host -ForegroundColor Gray " ==> Checking Environment"
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
		write-host -ForegroundColor Gray " ==> Found Adobe $LatestReader"
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
    write-host -ForegroundColor Gray " ==> Checking for Java 8"
    if (!($Java8 = Get-ChildItem -Path $Sourcedir -Filter 'jre-8*x64*'))
        {
	    Write-Warning "Java8 not found, trying download"
        write-host -ForegroundColor Gray " ==> Asking for latest Java8"
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
        write-host -ForegroundColor Gray " ==> Got $LatestJava"
        }
    }



if (!($SourceOK = test-source -SourceVer $Sourcever -SourceDir $Sourcedir))
{
	write-host -ForegroundColor Gray " ==> Sourcecomlete: $SourceOK"
	break
}
if ($DefaultGateway) {$AddGateway  = "-DefaultGateway $DefaultGateway"}
If ($VMnet -ne "VMnet2") { debug "Setting different Network is untested and own Risk !" }

if (!(test-dcrunning) -and (!$NoDomainCheck.IsPresent)) 
        {        
	    ###################################################
	    #
	    # DC Setup
	    #
	    ###################################################
        $DCName =  $BuildDomain+"DC"
        $NodeName = "DCNODE"
        $NodePrefix = "DCNode"
        $ScenarioScriptdir = "$IN_Guest_CD_Scriptroot\$NodePrefix"
        $NodeIP = "$IPv4Subnet.10"
        ####prepare iso
		Write-Verbose $Dynamic_Scripts
		Write-Verbose "Common Parameter = $CommonParameter"
        Remove-Item -Path "$Dynamic_Scripts" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
        New-Item -ItemType Directory "$Dynamic_Scripts" -Force | Out-Null
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
$IN_Guest_CD_Node_ScriptDir\set-vmguesttask.ps1 -Task $Current_phase -Status started
New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name '99-$next_phase' -Value '$PSHOME\powershell.exe -Command `". $IN_Guest_CD_Scriptroot\$Dynamic_Scripts_Name\run-$next_phase.ps1`"'
$ScenarioScriptdir\new-dc.ps1 -dcname $DCName -Domain $BuildDomain -IPv4subnet $IPv4subnet -IPv4Prefixlength $IPv4PrefixLength -IPv6PrefixLength $IPv6PrefixLength -IPv6Prefix $IPv6Prefix -AddressFamily $AddressFamily $CommonParameter
"

Write-Verbose $Content
Set-Content "$Dynamic_Scripts\$Current_phase.ps1" -Value $Content -Force
        
######## Phase 2
       $previous_phase = $current_phase
       $current_phase = $next_phase
       $next_phase = "phase3"
       $Content = @()
       $Content = "###
`$ScriptName = `$MyInvocation.MyCommand.Name
`$Host.UI.RawUI.WindowTitle = `$ScriptName
`$Logfile = New-Item -ItemType file `"c:\$Scripts\`$ScriptName.log`"
$IN_Guest_CD_Node_ScriptDir\set-vmguesttask.ps1 -Task $current_phase -Status started
$IN_Guest_CD_Node_ScriptDir\set-vmguesttask.ps1 -Task $previous_phase -Status finished
New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name '99-$next_phase' -Value '$PSHOME\powershell.exe -Command `". $IN_Guest_CD_Scriptroot\$Dynamic_Scripts_Name\run-$next_phase.ps1`"'
Set-ExecutionPolicy -ExecutionPolicy bypass -Force
$ScenarioScriptdir\finish-domain.ps1 -domain $BuildDomain -domainsuffix $custom_domainsuffix $CommonParameter
"
Write-Verbose $Content
Set-Content "$Dynamic_Scripts\run-$Current_phase.ps1" -Value $Content -Force
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
$IN_Guest_CD_Node_ScriptDir\set-vmguesttask.ps1 -Task $current_phase -Status started
New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name '99-$next_phase' -Value '$PSHOME\powershell.exe -Command `". $IN_Guest_CD_Scriptroot\$Dynamic_Scripts_Name\run-$next_phase.ps1`"'
$IN_Guest_CD_Node_ScriptDir\set-vmguesttask.ps1 -Task $previous_phase -Status finished
Set-ExecutionPolicy -ExecutionPolicy bypass -Force
$ScenarioScriptdir\dns.ps1 -IPv4subnet $IPv4Subnet -IPv4Prefixlength $IPV4PrefixLength -IPv6PrefixLength $IPv6PrefixLength -AddressFamily $AddressFamily  -IPV6Prefix $IPV6Prefix $CommonParameter
$ScenarioScriptdir\add-serviceuser.ps1
$ScenarioScriptdir\pwpolicy.ps1 
#$IN_Guest_CD_Node_ScriptDir\set-winrm.ps1 -Scriptdir $IN_Guest_CD_Scriptroot
restart-computer -force
"
Write-Verbose $Content
Set-Content "$Dynamic_Scripts\run-$Current_phase.ps1" -Value $Content -Force
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
$IN_Guest_CD_Node_ScriptDir\set-vmguesttask.ps1 -Task $current_phase -Status started
New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name '99-$next_phase' -Value '$PSHOME\powershell.exe -Command `". $IN_Guest_CD_Scriptroot\$Dynamic_Scripts_Name\run-$next_phase.ps1`"'
$IN_Guest_CD_Node_ScriptDir\set-vmguesttask.ps1 -Task $previous_phase -Status finished
$IN_Guest_CD_Node_ScriptDir\powerconf.ps1 -Scriptdir $IN_Guest_CD_Scriptroot
$IN_Guest_CD_Node_ScriptDir\set-uac.ps1 -Scriptdir $IN_Guest_CD_Scriptroot
$IN_Guest_CD_Node_ScriptDir\set-winrm.ps1 -Scriptdir $IN_Guest_CD_Scriptroot
restart-computer -force 
"
        Write-Verbose $Content
        Set-Content "$Dynamic_Scripts\run-$Current_phase.ps1" -Value $Content -Force
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
$IN_Guest_CD_Node_ScriptDir\set-vmguesttask.ps1 -Task $previous_phase -Status finished
$IN_Guest_CD_Node_ScriptDir\set-vmguesttask.ps1 -Task $current_phase -Status started
$ScenarioScriptdir\check-domain.ps1 -Scriptdir $IN_Guest_CD_Scriptroot
$IN_Guest_CD_Node_ScriptDir\set-vmguestshare.ps1 -user $Labbuildr_share_User -password $Labbuildr_share_password -HostIP $HostIP -Scripts_share_name $Scripts_share_name -Sources_share_name $Sources_share_name
$IN_Guest_CD_Node_ScriptDir\create-labshortcut.ps1 -scriptdir $IN_Guest_UNC_Scriptroot
$IN_Guest_CD_Node_ScriptDir\set-vmguesttask.ps1 -Task $current_phase -Status finished
#New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name '99-$next_phase' -Value '$PSHOME\powershell.exe -Command `". $Dynamic_Scripts\run-$next_phase.ps1`"'
"
        Write-Verbose $Content
        Set-Content "$Dynamic_Scripts\run-$Current_phase.ps1" -Value $Content -Force
## end Phase5  


        
####### Iso Creation        
        $IsoOK = make-iso -Nodename $NodeName -Builddir $Builddir -isodir $Isodir



####### clone creation
        if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
            {
            write-host -ForegroundColor Gray " ==> Press any Key to continue to Cloning"
            pause
            }
        $CloneOK = Invoke-Expression  "$Builddir\clone-node.ps1 -MasterVHD $MasterVHDX -Nodename $NodeName -Size L -HVSwitch $HVSwitch $CloneParameter"


####### wait progress
        $SecurePassword = $Adminpassword | ConvertTo-SecureString -AsPlainText -Force
        $Credential = New-Object –TypeName System.Management.Automation.PSCredential –ArgumentList $Adminuser, $SecurePassword

check-task -task "start-customize" -nodename $NodeName -sleep $Sleep
foreach ($n in 2..5)
    {

check-task -task "phase$n" -nodename $NodeName -sleep $Sleep 


    }
        }#end dc

##########
switch ($PsCmdlet.ParameterSetName)

    {
	"Blanknodes" {
        test-dcrunning
        $AddonFeatures = "RSAT-ADDS, RSAT-ADDS-TOOLS, AS-HTTP-Activation, NET-Framework-45-Features"

        if ($SpacesDirect.IsPresent )
            {
            $AddonFeatures = "$AddonFeatures, File-Services, Storage-Replica"
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
            [Switch]$Cluster = $true
            [Switch]$BlankHV = $true
            }

        if ($Disks)
            {
		    $cloneparameter = "$CloneParameter -AddDisks -disks $Disks"
            }
        if ($Cluster.IsPresent) 
            {
            $AddonFeatures = "$AddonFeatures, Failover-Clustering"
            if (!$Clustername)
                {
                $Clustername = "GenCluster"
                }
            }
        # if ($BlankHV.IsPresent) {$AddonFeatures = "$AddonFeatures, Hyper-V, RSAT-Hyper-V-Tools, Multipath-IO"}

        $Blank_End = (($Blankstart+$BlankNodes)-1)
        write-host -ForegroundColor Gray " ==> We will deploy $Nodes Nodes from $Blankstart to $Blank_End"
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
        if ($SpacesDirect.IsPresent)
            {
            $NamePrefix = "S2DCL"
            }
        else
            {
            $NamePrefix = "GEN"
            }

		$Nodename = "$NamePrefix$NodePrefix$Node"
        $ScenarioScriptdir = "$IN_Guest_CD_Scriptroot\$NodePrefix"
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
            Remove-Item -Path "$Dynamic_Scripts" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
            New-Item -ItemType Directory "$Dynamic_Scripts" -Force | Out-Null
            New-Item -ItemType Directory "$Builddir\$NodePrefix" -Force | Out-Null
            $Current_phase = "start-customize"
            $next_phase = "phase3"
            run-startcustomize -Current_phase $Current_phase -next_phase $next_phase
<### phase 2
            $previous_phase = $current_phase
            $current_phase = $next_phase
            $next_phase = "phase3"
            run-phase2 -Current_phase $Current_phase -next_phase $next_phase
#>
### phase 3
            $previous_phase = $current_phase
            $current_phase = $next_phase
            $next_phase = "phase4"
            run-phase3 -Current_phase $Current_phase -next_phase $next_phase
        
## Phase 4
            $previous_phase = $current_phase
            $current_phase = $next_phase
            $next_phase = "phase_finish_node"
            $Next_Phase_noreboot = $true
            run-phase4 -Current_phase $Current_phase -next_phase $next_phase -next_phase_no_reboot
## phase_customize
            $previous_phase = $current_phase
            $current_phase = $next_phase
            $next_phase = "phase_Customize"

$Content = "### $Current_phase
`$ScriptName = `$MyInvocation.MyCommand.Name
`$Host.UI.RawUI.WindowTitle = `$ScriptName
`$Logfile = New-Item -ItemType file `"c:\$Scripts\`$ScriptName.log`"
$IN_Guest_CD_Node_ScriptDir\set-vmguesttask.ps1 -Task $current_phase -Status started
$IN_Guest_CD_Node_ScriptDir\set-vmguesttask.ps1 -Task $previous_phase -Status finished
"
$AddContent = @()
        if ($Node -eq $Blank_End)
            {
            if ($Cluster.IsPresent)
                {
                $AddContent += "$IN_Guest_CD_Node_ScriptDir\create-cluster.ps1 -Nodeprefix '$NamePrefix' -ClusterName $ClusterName -IPAddress '$ClusterIP' -IPV6Prefix $IPV6Prefix -IPv6PrefixLength $IPv6PrefixLength -AddressFamily $AddressFamily $CommonParameter -Scriptdir $IN_Guest_CD_Scriptroot 
"
                if ($SpacesDirect.IsPresent)
                    {
                    $AddContent += "$IN_Guest_CD_Node_ScriptDir\new-s2dpool.ps1 -Scriptdir $IN_Guest_CD_Scriptroot 
"
                    }
                }
            }
        $AddContent += "$IN_Guest_CD_Node_ScriptDir\set-vmguesttask.ps1 -Task $Current_phase -Status finished
"
$Content += $AddContent

Write-Verbose $Content
Set-Content "$Dynamic_Scripts\run-$Current_phase.ps1" -Value $Content -Force
####


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
 #       check-task -task "start-customize" -nodename $NodeName -sleep $Sleep

        check-task -task "phase3" -nodename $NodeName -sleep $Sleep
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
        write-host -ForegroundColor Gray " ==> Starting $EX_Version $e16_cu Setup"
        If ($Disks -lt 3)
            {
            $Disks = 3
            }
        if ($Disks)
            {
		    $cloneparameter = "$CloneParameter -AddDisks -disks $Disks"
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
			$ScenarioScriptdir = "$IN_Guest_CD_Scriptroot\$NodePrefix"
		    $Host_ScriptDir = "$Builddir\$Scripts\$EX_Version\"
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
            Remove-Item -Path "$Dynamic_Scripts" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
            New-Item -ItemType Directory "$Dynamic_Scripts" -Force | Out-Null
            New-Item -ItemType Directory "$Builddir\$NodePrefix" -Force | Out-Null
            $Current_phase = "start-customize"
            $next_phase = "phase3"
            run-startcustomize -Current_phase $Current_phase -next_phase $next_phase
        

<### phase 2
            $previous_phase = $current_phase
            $current_phase = $next_phase
            $next_phase = "phase3"
            run-phase2 -Current_phase $Current_phase -next_phase $next_phase
#>
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
$IN_Guest_CD_Node_ScriptDir\set-vmguesttask.ps1 -Task $current_phase -Status started
$IN_Guest_CD_Node_ScriptDir\set-vmguesttask.ps1 -Task $previous_phase -Status finished
New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name '99-$next_phase' -Value '$PSHOME\powershell.exe -Command `". $IN_Guest_CD_Scriptroot\$Dynamic_Scripts_Name\run-$next_phase.ps1`"'
$ScenarioScriptdir\prepare-disks.ps1
$ScenarioScriptdir\install-exchangeprereqs.ps1 -SourcePath $IN_Guest_UNC_Sourcepath -Scriptdir $IN_Guest_CD_Scriptroot -NET_VER $NET_VER
restart-computer -force
"
Write-Verbose $Content
Set-Content "$Dynamic_Scripts\run-$Current_phase.ps1" -Value $Content -Force
   
   
            $previous_phase = $current_phase
            $current_phase = $next_phase
            $next_phase = "phase_EX_RUN"


$Content = "###
`$ScriptName = `$MyInvocation.MyCommand.Name
`$Host.UI.RawUI.WindowTitle = `$ScriptName
`$Logfile = New-Item -ItemType file `"c:\$Scripts\`$ScriptName.log`"
New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name '99-$next_phase' -Value '$PSHOME\powershell.exe -Command `". $IN_Guest_CD_Scriptroot\$Dynamic_Scripts_Name\run-$next_phase.ps1`"'
$IN_Guest_CD_Node_ScriptDir\set-vmguesttask.ps1 -Task $current_phase -Status started
$IN_Guest_CD_Node_ScriptDir\set-vmguesttask.ps1 -Task $previous_phase -Status finished
$ScenarioScriptdir\install-exchange.ps1 -ex_cu $e16_cu -SourcePath $IN_Guest_UNC_Sourcepath -Scriptdir $IN_Guest_CD_Scriptroot
"
Write-Verbose $Content
Set-Content "$Dynamic_Scripts\run-$Current_phase.ps1" -Value $Content -Force


#####
            $previous_phase = $current_phase
            $current_phase = $next_phase
            $next_phase = "phase_EX_POST"


$Content = "###
`$ScriptName = `$MyInvocation.MyCommand.Name
`$Host.UI.RawUI.WindowTitle = `$ScriptName
`$Logfile = New-Item -ItemType file `"c:\$Scripts\`$ScriptName.log`"
$IN_Guest_CD_Node_ScriptDir\set-vmguesttask.ps1 -Task $current_phase -Status started
$IN_Guest_CD_Node_ScriptDir\set-vmguesttask.ps1 -Task $previous_phase -Status finished
$ScenarioScriptdir\configure-exchange.ps1 -EX_Version $EX_Version -SourcePath $IN_Guest_UNC_Sourcepath -Scriptdir $IN_Guest_CD_Scriptroot
"

# dag phase fo last server
    if ($EXNode -eq ($EXNodes+$EXStartNode-1)) #are we last sever in Setup ?!
        {
        if ($DAG.IsPresent) 
            {
			write-host -ForegroundColor Gray " ==> Creating DAG"
            $Content += "$ScenarioScriptdir\create-dag.ps1 -DAGIP $DAGIP -AddressFamily $EXAddressFamiliy -EX_Version $EX_Version -SourcePath $IN_Guest_UNC_Sourcepath -Scriptdir $IN_Guest_CD_Scriptroot
"
			} # end if $DAG
        if (!($nouser.ispresent))
            {
            write-host -ForegroundColor Gray " ==> Creating Accounts and Mailboxes:"
            $Content += "c:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe `". 'C:\Program Files\Microsoft\Exchange Server\V15\bin\RemoteExchange.ps1'; Connect-ExchangeServer -auto; $ScenarioScriptdir\User.ps1 -subnet $IPv4Subnet -AddressFamily $AddressFamily -IPV6Prefix $IPV6Prefix -SourcePath $IN_Guest_UNC_Sourcepath -Scriptdir $IN_Guest_CD_Scriptroot`"
"
            } #end creatuser
    }# end if last server

Write-Verbose $Content
Set-Content "$Dynamic_Scripts\run-$Current_phase.ps1" -Value $Content -Force
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

   	"e15"{
        test-dcrunning
        write-host -ForegroundColor Gray " ==> Starting $EX_Version $e15_cu Setup"
        If ($Disks -lt 3)
            {
            $Disks = 3
            }
        if ($Disks)
            {
		    $cloneparameter = "$CloneParameter -AddDisks -disks $Disks"
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
            Write-Warning "Running e15 Avalanche Install"

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
			# Setup e15 Node
			# Init
			$Nodeip = "$IPv4Subnet.12$EXNODE"
			$Nodename = "$EX_Version"+"N"+"$EXNODE"
            $NodePrefix = $EX_Version
			$ScenarioScriptdir = "$IN_Guest_CD_Scriptroot\$NodePrefix"
		    $Host_ScriptDir = "$Builddir\$Scripts\$EX_Version\"
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
            Remove-Item -Path "$Dynamic_Scripts" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
            New-Item -ItemType Directory "$Dynamic_Scripts" -Force | Out-Null
            New-Item -ItemType Directory "$Builddir\$NodePrefix" -Force | Out-Null
            $Current_phase = "start-customize"
            $next_phase = "phase3"
            run-startcustomize -Current_phase $Current_phase -next_phase $next_phase
        

<### phase 2
            $previous_phase = $current_phase
            $current_phase = $next_phase
            $next_phase = "phase3"
            run-phase2 -Current_phase $Current_phase -next_phase $next_phase
#>
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
$IN_Guest_CD_Node_ScriptDir\set-vmguesttask.ps1 -Task $current_phase -Status started
$IN_Guest_CD_Node_ScriptDir\set-vmguesttask.ps1 -Task $previous_phase -Status finished
New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name '99-$next_phase' -Value '$PSHOME\powershell.exe -Command `". $IN_Guest_CD_Scriptroot\$Dynamic_Scripts_Name\run-$next_phase.ps1`"'
$ScenarioScriptdir\prepare-disks.ps1
$ScenarioScriptdir\install-exchangeprereqs.ps1 -SourcePath $IN_Guest_UNC_Sourcepath -Scriptdir $IN_Guest_CD_Scriptroot -NET_VER $NET_VER
restart-computer -force
"
Write-Verbose $Content
Set-Content "$Dynamic_Scripts\run-$Current_phase.ps1" -Value $Content -Force
   
   
            $previous_phase = $current_phase
            $current_phase = $next_phase
            $next_phase = "phase_EX_RUN"


$Content = "###
`$ScriptName = `$MyInvocation.MyCommand.Name
`$Host.UI.RawUI.WindowTitle = `$ScriptName
`$Logfile = New-Item -ItemType file `"c:\$Scripts\`$ScriptName.log`"
New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name '99-$next_phase' -Value '$PSHOME\powershell.exe -Command `". $IN_Guest_CD_Scriptroot\$Dynamic_Scripts_Name\run-$next_phase.ps1`"'
$IN_Guest_CD_Node_ScriptDir\set-vmguesttask.ps1 -Task $current_phase -Status started
$IN_Guest_CD_Node_ScriptDir\set-vmguesttask.ps1 -Task $previous_phase -Status finished
$ScenarioScriptdir\install-exchange.ps1 -ex_cu $e15_cu -SourcePath $IN_Guest_UNC_Sourcepath -Scriptdir $IN_Guest_CD_Scriptroot
"
Write-Verbose $Content
Set-Content "$Dynamic_Scripts\run-$Current_phase.ps1" -Value $Content -Force


#####
            $previous_phase = $current_phase
            $current_phase = $next_phase
            $next_phase = "phase_EX_POST"


$Content = "###
`$ScriptName = `$MyInvocation.MyCommand.Name
`$Host.UI.RawUI.WindowTitle = `$ScriptName
`$Logfile = New-Item -ItemType file `"c:\$Scripts\`$ScriptName.log`"
$IN_Guest_CD_Node_ScriptDir\set-vmguesttask.ps1 -Task $current_phase -Status started
$IN_Guest_CD_Node_ScriptDir\set-vmguesttask.ps1 -Task $previous_phase -Status finished
$ScenarioScriptdir\configure-exchange.ps1 -EX_Version $EX_Version -SourcePath $IN_Guest_UNC_Sourcepath -Scriptdir $IN_Guest_CD_Scriptroot
"

# dag phase fo last server
    if ($EXNode -eq ($EXNodes+$EXStartNode-1)) #are we last sever in Setup ?!
        {
        if ($DAG.IsPresent) 
            {
			write-host -ForegroundColor Gray " ==> Creating DAG"
            $Content += "$ScenarioScriptdir\create-dag.ps1 -DAGIP $DAGIP -AddressFamily $EXAddressFamiliy -EX_Version $EX_Version -SourcePath $IN_Guest_UNC_Sourcepath -Scriptdir $IN_Guest_CD_Scriptroot
"
			} # end if $DAG
        if (!($nouser.ispresent))
            {
            write-host -ForegroundColor Gray " ==> Creating Accounts and Mailboxes:"
            $Content += "c:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe `". 'C:\Program Files\Microsoft\Exchange Server\V15\bin\RemoteExchange.ps1'; Connect-ExchangeServer -auto; $ScenarioScriptdir\User.ps1 -subnet $IPv4Subnet -AddressFamily $AddressFamily -IPV6Prefix $IPV6Prefix -SourcePath $IN_Guest_UNC_Sourcepath -Scriptdir $IN_Guest_CD_Scriptroot`"
"
            } #end creatuser
    }# end if last server

Write-Verbose $Content
Set-Content "$Dynamic_Scripts\run-$Current_phase.ps1" -Value $Content -Force
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


"SRM"
{
	###################################################
	# SRM Setup
	###################################################
	$Nodeip = "$IPv4Subnet.17"
	$NodePrefix = "ViPRSRM"
    $Nodename = $NodePrefix
    $IN_Guest_UNC_ScenarioScriptDir = "$IN_Guest_UNC_Scriptroot\$NodePrefix"
    [string]$AddonFeatures = "RSAT-ADDS, RSAT-ADDS-TOOLS" 
    $ScenarioScriptDir = "$IN_Guest_CD_Scriptroot\$NodePrefix"
    $Size = "XXL"
	###################################################
	Write-Host -ForegroundColor Magenta "Creating SRM Server $Nodename"
  	Write-Verbose $IPv4Subnet
    write-verbose $Nodename
    write-verbose $Nodeip
	$DC_test_ok = test-dcrunning

#########################
####prepare iso
            Remove-Item -Path "$Dynamic_Scripts" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
            New-Item -ItemType Directory "$Dynamic_Scripts" -Force | Out-Null
            New-Item -ItemType Directory "$Builddir\$NodePrefix" -Force | Out-Null
            $Current_phase = "start-customize"
            $next_phase = "phase3"
            run-startcustomize -Current_phase $Current_phase -next_phase $next_phase
        

<### phase 2
            $previous_phase = $current_phase
            $current_phase = $next_phase
            $next_phase = "phase3"
            run-phase2 -Current_phase $Current_phase -next_phase $next_phase
#>
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
<#
        if ($NW.IsPresent)
            {
            write-verbose "Install NWClient"
		    invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_NodeScriptDir -Script install-nwclient.ps1 -interactive -Parameter $nw_ver
            }
        invoke-postsection -wait
        write-verbose "Building SRM Server"
	    invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script INSTALL-SRM.ps1 -interactive -parameter "-SRM_VER $SRM_VER $CommonParameter"
        Write-Host -ForegroundColor White "You cn now Connect to http://$($Nodeip):58080/APG/ with admin/changeme"
#>

            $previous_phase = $current_phase
            $current_phase = $next_phase
            $next_phase = "phase_install_$($Nodeprefix)_done"
$Content = "###
`$ScriptName = `$MyInvocation.MyCommand.Name
`$Host.UI.RawUI.WindowTitle = `$ScriptName
`$Logfile = New-Item -ItemType file `"c:\$Scripts\`$ScriptName.log`"
$IN_Guest_CD_Node_ScriptDir\set-vmguesttask.ps1 -Task $current_phase -Status started
$IN_Guest_CD_Node_ScriptDir\set-vmguesttask.ps1 -Task $previous_phase -Status finished
$ScenarioScriptdir\INSTALL-SRM.ps1 -SRM_VER $SRM_VER $CommonParameter -SourcePath $IN_Guest_UNC_Sourcepath\$NodePrefix -Scriptdir $IN_Guest_CD_Scriptroot
# $IN_Guest_CD_Node_ScriptDir\set-autologon -user $scenario_admin -SourcePath $IN_Guest_UNC_Sourcepath -Scriptdir $IN_Guest_CD_Scriptroot
#$IN_Guest_CD_Node_ScriptDir\Add-DomainUserToLocalGroup.ps1 -user $scenario_admin -group 'Remote Desktop Users' -SourcePath $IN_Guest_UNC_Sourcepath -Scriptdir $IN_Guest_CD_Scriptroot
New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name '99-$next_phase' -Value '$PSHOME\powershell.exe -Command `". $IN_Guest_CD_Scriptroot\$Dynamic_Scripts_Name\run-$next_phase.ps1`"'
#restart-computer -force
"
Write-Verbose $Content
Set-Content "$Dynamic_Scripts\run-$Current_phase.ps1" -Value $Content -Force
######


## phase install_SRM_done


            $previous_phase = $current_phase
            $current_phase = $next_phase
            $next_phase = "phase_finished"
$Content = "###
`$ScriptName = `$MyInvocation.MyCommand.Name
`$Host.UI.RawUI.WindowTitle = `$ScriptName
`$Logfile = New-Item -ItemType file `"c:\$Scripts\`$ScriptName.log`"
$IN_Guest_CD_Node_ScriptDir\set-vmguesttask.ps1 -Task $current_phase -Status started
$IN_Guest_CD_Node_ScriptDir\set-vmguesttask.ps1 -Task $previous_phase -Status finished
# $IN_Guest_CD_Node_ScriptDir\set-vmguestshare.ps1 -user $Labbuildr_share_User -password $Labbuildr_share_password -HostIP $HostIP -Scripts_share_name $Scripts_share_name -Sources_share_name $Sources_share_name
http://$($Nodeip):58080/APG/
"
Write-Verbose $Content
Set-Content "$Dynamic_Scripts\run-$Current_phase.ps1" -Value $Content -Force

####### Iso Creation        
            $Isocreatio = make-iso -Nodename $NodeName -Builddir $Builddir -isodir $Isodir
####### clone creation
            if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
                {
                Write-Verbose "Press any Key to continue to Cloning"
                pause
                }

            $CloneOK = Invoke-Expression  "$Builddir\clone-node.ps1 -MasterVHD $MasterVHDX -Nodename $NodeName -Size $Size -HVSwitch $HVSwitch $CloneParameter"


		    If ($CloneOK)
            {
            check-task -task "start-customize" -nodename $NodeName -sleep $Sleep
            }

	

} #SRM End#>

"SCVMM"
{
	###################################################
	# scvmm Setup
	###################################################
	$Nodeip = "$IPv4Subnet.19"
	$Nodename = "SCVMM"
    $NodePrefix = "SCVMM"
    [string]$AddonFeatures = "RSAT-ADDS, RSAT-ADDS-TOOLS, NET-Framework-45-Features"
    $ScenarioScriptDir = "$IN_Guest_CD_Scriptroot\$NodePrefix"
    $SQLScriptDir = "$GuestScriptdir\sql\"
    if ($Size -lt "XL")
        {
        $Size = "XL"
        }

	###################################################
	status $Commentline
	status "Creating $scvmm_VER Server $Nodename"
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
            Remove-Item -Path "$Dynamic_Scripts" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
            New-Item -ItemType Directory "$Dynamic_Scripts" -Force | Out-Null
            New-Item -ItemType Directory "$Builddir\$NodePrefix" -Force | Out-Null
            $Current_phase = "start-customize"
            $next_phase = "phase3"
            run-startcustomize -Current_phase $Current_phase -next_phase $next_phase
        

<### phase 2
            $previous_phase = $current_phase
            $current_phase = $next_phase
            $next_phase = "phase3"
            run-phase2 -Current_phase $Current_phase -next_phase $next_phase
#>
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
$IN_Guest_CD_Node_ScriptDir\set-vmguesttask.ps1 -Task $current_phase -Status started
$IN_Guest_CD_Node_ScriptDir\set-vmguesttask.ps1 -Task $previous_phase -Status finished
$IN_Guest_UNC_Scriptroot\SQL\install-sql.ps1 -SQLVER $SQLVER -DefaultDBpath $CommonParameter -SourcePath $IN_Guest_UNC_Sourcepath -Scriptdir $IN_Guest_CD_Scriptroot
$ScenarioScriptdir\install-vmmprereq.ps1 -sc_version $SC_Version $CommonParameter -SourcePath $IN_Guest_UNC_Sourcepath -Scriptdir $IN_Guest_CD_Scriptroot
$ScenarioScriptdir\INSTALL-vmm.ps1 -SC_Version $SC_Version $CommonParameter -SourcePath $IN_Guest_UNC_Sourcepath -Scriptdir $IN_Guest_CD_Scriptroot
#$IN_Guest_CD_Node_ScriptDir\set-autologon -user nwadmin -SourcePath $IN_Guest_UNC_Sourcepath -Scriptdir $IN_Guest_CD_Scriptroot
#$IN_Guest_CD_Node_ScriptDir\Add-DomainUserToLocalGroup.ps1 -user nwadmin -group 'Remote Desktop Users' -SourcePath $IN_Guest_UNC_Sourcepath -Scriptdir $IN_Guest_CD_Scriptroot
#New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name '99-$next_phase' -Value '$PSHOME\powershell.exe -Command `". $IN_Guest_CD_Scriptroot\$Dynamic_Scripts_Name\run-$next_phase.ps1`"'
# restart-computer -force
"
Write-Verbose $Content
Set-Content "$Dynamic_Scripts\run-$Current_phase.ps1" -Value $Content -Force
######




####### Iso Creation        
            $Isocreatio = make-iso -Nodename $NodeName -Builddir $Builddir -isodir $Isodir
####### clone creation
            if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
                {
                Write-Verbose "Press any Key to continue to Cloning"
                pause
                }

            $CloneOK = Invoke-Expression  "$Builddir\clone-node.ps1 -MasterVHD $MasterVHDX -Nodename $NodeName -Size $Size -HVSwitch $HVSwitch $CloneParameter"


		    If ($CloneOK)
            {
            check-task -task "start-customize" -nodename $NodeName -sleep $Sleep
            }


	

<#
			write-verbose "Building SCVMM Setup Configruration"
			invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script set-vmmconfig.ps1 -interactive
			write-verbose "Installing SQL Binaries"
			invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword -ScriptPath $In_Guest_UNC_SQLScriptDir -Script install-sql.ps1 -Parameter "-SQLVER $SQLVER -DefaultDBpath $CommonParameter" -interactive
			write-verbose "Installing SCVMM PREREQS"
			invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword  -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script install-vmmprereq.ps1 -Parameter "-scvmm_ver $scvmm_ver $CommonParameter"  -interactive
            checkpoint-progress -step vmmprereq -reboot -Guestuser $Adminuser -Guestpassword $Adminpassword
			write-verbose "Installing SCVMM"
            Write-Warning "Setup of VMM and Update Rollups in progress, could take up to 20 Minutes"
			invoke-vmxpowershell -config $CloneVMX -Guestuser $Adminuser -Guestpassword $Adminpassword  -ScriptPath $IN_Guest_UNC_ScenarioScriptDir -Script install-vmm.ps1 -Parameter "-scvmm_ver $scvmm_ver $CommonParameter" -interactive
  #>          




}#END SCVMM

 "SCOM"
{
	###################################################
	# SCOM Setup
	###################################################
	$Nodeip = "$IPv4Subnet.18"
	$Nodename = "SCOM"
    $NodePrefix = "SCOM"
    [string]$AddonFeatures = "RSAT-ADDS, RSAT-ADDS-TOOLS, NET-Framework-45-Features"
    $ScenarioScriptDir = "$IN_Guest_CD_Scriptroot\$NodePrefix"
    $SQLScriptDir = "$GuestScriptdir\sql\"
    if ($Size -lt "XL")
        {
        $Size = "XL"
        }

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
            Remove-Item -Path "$Dynamic_Scripts" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
            New-Item -ItemType Directory "$Dynamic_Scripts" -Force | Out-Null
            New-Item -ItemType Directory "$Builddir\$NodePrefix" -Force | Out-Null
            $Current_phase = "start-customize"
            $next_phase = "phase3"
            run-startcustomize -Current_phase $Current_phase -next_phase $next_phase
        

<### phase 2
            $previous_phase = $current_phase
            $current_phase = $next_phase
            $next_phase = "phase3"
            run-phase2 -Current_phase $Current_phase -next_phase $next_phase
#>
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
$IN_Guest_CD_Node_ScriptDir\set-vmguesttask.ps1 -Task $current_phase -Status started
$IN_Guest_CD_Node_ScriptDir\set-vmguesttask.ps1 -Task $previous_phase -Status finished
$IN_Guest_UNC_Scriptroot\SQL\install-sql.ps1 -SQLVER $SQLVER -DefaultDBpath $CommonParameter -SourcePath $IN_Guest_UNC_Sourcepath -Scriptdir $IN_Guest_CD_Scriptroot
$ScenarioScriptdir\INSTALL-Scom.ps1 -SC_Version $SC_Version $CommonParameter -SourcePath $IN_Guest_UNC_Sourcepath -Scriptdir $IN_Guest_CD_Scriptroot
#$IN_Guest_CD_Node_ScriptDir\set-autologon -user nwadmin -SourcePath $IN_Guest_UNC_Sourcepath -Scriptdir $IN_Guest_CD_Scriptroot
#$IN_Guest_CD_Node_ScriptDir\Add-DomainUserToLocalGroup.ps1 -user nwadmin -group 'Remote Desktop Users' -SourcePath $IN_Guest_UNC_Sourcepath -Scriptdir $IN_Guest_CD_Scriptroot
#New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name '99-$next_phase' -Value '$PSHOME\powershell.exe -Command `". $IN_Guest_CD_Scriptroot\$Dynamic_Scripts_Name\run-$next_phase.ps1`"'
# restart-computer -force
"
Write-Verbose $Content
Set-Content "$Dynamic_Scripts\run-$Current_phase.ps1" -Value $Content -Force
######




####### Iso Creation        
            $Isocreatio = make-iso -Nodename $NodeName -Builddir $Builddir -isodir $Isodir
####### clone creation
            if ($PSCmdlet.MyInvocation.BoundParameters["verbose"].IsPresent)
                {
                Write-Verbose "Press any Key to continue to Cloning"
                pause
                }

            $CloneOK = Invoke-Expression  "$Builddir\clone-node.ps1 -MasterVHD $MasterVHDX -Nodename $NodeName -Size $Size -HVSwitch $HVSwitch $CloneParameter"


		    If ($CloneOK)
            {
            check-task -task "start-customize" -nodename $NodeName -sleep $Sleep
            }


	
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
            $ScenarioScriptdir = "$IN_Guest_CD_Scriptroot\$NodePrefix"
	        ###################################################
            if ($nw_ver -ge "nw85")
                {
                $Size = "L"
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
            Remove-Item -Path "$Dynamic_Scripts" -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
            New-Item -ItemType Directory "$Dynamic_Scripts" -Force #| Out-Null
            New-Item -ItemType Directory "$Builddir\$NodePrefix" -Force | Out-Null
            $Current_phase = "start-customize"
            $next_phase = "phase3"
            run-startcustomize -Current_phase $Current_phase -next_phase $next_phase
        

<### phase 2
            $previous_phase = $current_phase
            $current_phase = $next_phase
            $next_phase = "phase3"
            run-phase2 -Current_phase $Current_phase -next_phase $next_phase
#>
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
$IN_Guest_CD_Node_ScriptDir\set-vmguesttask.ps1 -Task $current_phase -Status started
$IN_Guest_CD_Node_ScriptDir\set-vmguesttask.ps1 -Task $previous_phase -Status finished
$IN_Guest_CD_Node_ScriptDir\install-program.ps1 -Program $LatestJava -ArgumentList '/s' -SourcePath $IN_Guest_UNC_Sourcepath -Scriptdir $IN_Guest_CD_Scriptroot
#$IN_Guest_CD_Node_ScriptDir\install-program.ps1 -Program $LatestReader -ArgumentList '/sPB /rs' -SourcePath $IN_Guest_UNC_Sourcepath -Scriptdir $IN_Guest_CD_Scriptroot
$IN_Guest_CD_Node_ScriptDir\set-autologon -user nwadmin -SourcePath $IN_Guest_UNC_Sourcepath -Scriptdir $IN_Guest_CD_Scriptroot
$IN_Guest_CD_Node_ScriptDir\Add-DomainUserToLocalGroup.ps1 -user nwadmin -group 'Remote Desktop Users' -SourcePath $IN_Guest_UNC_Sourcepath -Scriptdir $IN_Guest_CD_Scriptroot
$ScenarioScriptdir\install-nwserver.ps1 -nw_ver $nw_ver -SourcePath $IN_Guest_UNC_Sourcepath\Networker -Scriptdir $IN_Guest_CD_Scriptroot
$ScenarioScriptdir\nsruserlist.ps1 -SourcePath $IN_Guest_UNC_Sourcepath -Scriptdir $IN_Guest_CD_Scriptroot
$ScenarioScriptdir\create-nsrdevice.ps1 -AFTD AFTD1 -SourcePath $IN_Guest_UNC_Sourcepath -Scriptdir $IN_Guest_CD_Scriptroot
#$ScenarioScriptdir\configure-nmc.ps1 -SourcePath $IN_Guest_UNC_Sourcepath -Scriptdir $IN_Guest_CD_Scriptroot
New-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce -Name '99-$next_phase' -Value '!$PSHOME\powershell.exe -Command `". $IN_Guest_CD_Scriptroot\$Dynamic_Scripts_Name\run-$next_phase.ps1`"'
restart-computer -force
"
Write-Verbose $Content
Set-Content "$Dynamic_Scripts\run-$Current_phase.ps1" -Value $Content -Force
######


## phase install_nw_done


            $previous_phase = $current_phase
            $current_phase = $next_phase
            $next_phase = "phase_finished"
$Content = "###
`$ScriptName = `$MyInvocation.MyCommand.Name
`$Host.UI.RawUI.WindowTitle = `$ScriptName
#`$Logfile = New-Item -ItemType file `"c:\$Scripts\`$ScriptName.log`"
# set-vmguesttask disabled for user
# $IN_Guest_CD_Node_ScriptDir\set-vmguesttask.ps1 -Task $current_phase -Status started
# $IN_Guest_CD_Node_ScriptDir\set-vmguesttask.ps1 -Task $previous_phase -Status finished
$IN_Guest_CD_Node_ScriptDir\set-vmguestshare.ps1 -user $Labbuildr_share_User -password $Labbuildr_share_password -HostIP $HostIP -Scripts_share_name $Scripts_share_name -Sources_share_name $Sources_share_name
$ScenarioScriptdir\configure-nmc.ps1 -SourcePath $IN_Guest_UNC_Sourcepath -Scriptdir $IN_Guest_CD_Scriptroot
"
Write-Verbose $Content
Set-Content "$Dynamic_Scripts\run-$Current_phase.ps1" -Value $Content -Force

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
    
    
