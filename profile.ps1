﻿set-location $PSScriptRoot

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
import-module .\labtools -Force
$Defaults = Get-labdefaults

.\Build-hypervlab.ps1
if (!(Test-Connection community.emc.com -Quiet -Count 2 -ErrorAction SilentlyContinue))
    {
    Write-Warning "no Internet Connection detected, Download of Sources may not work"
    }
else
    {
    Write-host "latest updates on vmxtoolkit and labbuildr"
    $Url = "https://community.emc.com/blogs/bottk/feeds/posts"
    $blog = [xml](new-object System.Net.WebClient).DownloadString($Url)
    $blog.rss.channel.item |  where {$_.title -match "vmxtoolkit" -or $_.title -Match "labbuildr"} |select Link | ft
    }
$Defaults
