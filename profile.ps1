set-location $PSScriptRoot
<#
$Userinterface = (Get-Host).UI.RawUI
$Userinterface.BackgroundColor = "Black"
$Userinterface.ForegroundColor = "Green"
$size = $Userinterface.BufferSize
$size.width=130
$size.height=5000
$Userinterface.BufferSize = $size
$size = $Userinterface.WindowSize
$size.width=120
$size.height=48
$Userinterface.WindowSize = $size
clear-host
#>
import-module .\labtools -Force
$labbuildr_home = $env:USERPROFILE
clear-host
$self  = Get-Location
import-module (Join-Path $self "labtools") -Force
try
    {
    Get-ChildItem labbuildr-scripts -ErrorAction Stop | Out-Null
    }
catch
    [System.Management.Automation.ItemNotFoundException]
    {
    Write-Warning -InformationAction Stop "labbuildr-scripts not found, need to move scripts folder"
	try
        {
		Write-Host -ForegroundColor Gray " ==> moving Scripts to labbuildr-scripts"
        Move-Item -Path Scripts -Destination labbuildr-scripts -ErrorAction Stop
        }
    catch
        {
        Write-Warning "could not move old scripts folder, incomlete installation ?"
        exit
        }
    }

try
    {
    Get-ChildItem .\defaults.xml -ErrorAction Stop | Out-Null
    }
catch
    [System.Management.Automation.ItemNotFoundException]
    {
    Write-Host -ForegroundColor Yellow "no defaults.xml found, using labbuildr default settings"
    Copy-Item .\defaults.xml.example .\defaults.xml
	$Master_path = Join-Path $labbuildr_home "Master.labbuildr"
    Set-LABMasterpath -Masterpath (Join-Path $labbuildr_home "Master.labbuildr").tostring()
	Set-LABSources -Sourcedir (Join-Path $labbuildr_home "Sources.labbuildr").tostring()
    }
if ((Get-LABDefaults).SQLVER -notmatch 'ISO')
	{
	Set-LABSQLver -SQLVER SQL2014SP2_ISO
	}
$buildlab = (join-path $self "build-hypervlab.ps1")
.$buildlab

$Defaults = Get-labdefaults
$Global:vmxtoolkit_type = "win_x86_64"

$Defaults
