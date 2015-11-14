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
$Latest_e16_cu = "final"

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

################## Statics
$LogFile = "$Builddir\$(Get-Content env:computername).log"
$WAIKVER = "WAIK"
$domainsuffix = ".local"
$AAGDB = "AWORKS"
$major = "5.0"
$Default_vmnet = "vmnet2"
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
$GuestScriptdir = "\\vmware-host\Shared Folders\Scripts"
$GuestSourcePath = "\\vmware-host\Shared Folders\Sources"
$GuestLogDir = "C:\Scripts"
$NodeScriptDir = "$GuestScriptdir\Node"
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
                    Status "No update required for labbuildr, already newest version "
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


function CreateShortcut
{
	$wshell = New-Object -comObject WScript.Shell
	$Deskpath = $wshell.SpecialFolders.Item('Desktop')
	# $path2 = $wshell.SpecialFolders.Item('Programs')
	# $path1, $path2 | ForEach-Object {
	$link = $wshell.CreateShortcut("$Deskpath\$Buildname.lnk")
	$link.TargetPath = "$psHome\powershell.exe"
	$link.Arguments = "-noexit -command $Builddir\profile.ps1"
	$link.Description = "$Buildname"
	$link.WorkingDirectory = "$Builddir"
	$link.IconLocation = 'powershell.exe'
	$link.Save()
	# }
	
}
##


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
        $Repo = "labbuildr-scripts"
        $RepoLocation = "bottkars"
        $Latest_local_git = $Latest_labbuildr_scripts_git
        $Destination = "$Builddir\Scripts"
        update-fromGit -Repo $Repo -RepoLocation $RepoLocation -branch $branch -latest_local_Git $Latest_local_git -Destination $Destination -delete

            return
    }# end Updatefromgit
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



switch ($PsCmdlet.ParameterSetName)
    {

    
    
        "Shortcut"
        {
				status "Creating Desktop Shortcut for $Buildname"
				createshortcut
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
    $MyMaster = get-childitem -path "$Masterpath\$Master\$Master.vhdx"
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
   $MasterVHDX = $MyMaster.Dullname		
   Write-Verbose "We got master $MasterVHDX"
   }

write-verbose "After Masterconfig !!!! "

########

########


###### requirements check

if (!(test-path $Builddir\bin\mkisofs.exe -ErrorAction SilentlyContinue))
    {
    Get-LABHttpFile -SourceURL "http://osspack32.googlecode.com/files/mkisofs.exe" -TarGetFile "$Builddir\bin\mkisofs.exe"
    Unblock-File -Path "$Builddir\bin\mkisofs.exe"
    }


        "E16"
        {
        $EXnode1 = "HV01"
        }
    
    

