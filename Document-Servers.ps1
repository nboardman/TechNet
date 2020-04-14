<#
	Author  : Nick Boardman
	E-Mail  : nboardman@hotmail.com
	Date	: August 10,2015
	File	: Document-Servers.ps1
	Purpose : Generate Server HW & SW Inventory from a list of servers.
	Version : 2.0
	Notes   : Inspired by Audit v3 - by Alan Renouf.  I added different information that made sense for my environment
#>

$FD = get-date -uformat %m-%d-%Y
$TSL = "C:\Scripts\Transcripts\Transcript-$FD.txt"
Start-Transcript -Path $TSL -Append

#This section allows for the name of the script to be written in the Transcript Log as well as the other normal data.
$PWD = pwd 
$Script = 'Document-Servers.ps1'
Write-Host "$PWD\$Script"

#Start Timer
$ElapsedTime = [system.diagnostics.stopwatch]::StartNew()

#Error-handling
$ErrorActionPreference = "SilentlyContinue"

#Eliminate truncation of returned data -1 = unlimited  4 = default
$FormatEnumerationLimit =-1

Write-Host "Loading Active Directory PoSH Module if not present..." -Fore Cyan
Import-Module ActiveDirectory

$Servers = gc \\Server\Share\Servers.txt
	foreach ($Server in $Servers) {
		$ElapsedTime1 = [system.diagnostics.stopwatch]::StartNew()
		Write-Host "Gathering Information for $Server..."
			$TD = get-date -format g
		  $GADC = Get-ADComputer $Server -Properties * | Select-Object Name, OperatingSystem, OperatingSystemServicePack, IPv4Address, whenCreated
		    $HW = gwmi Win32_ComputerSystem -ComputerName $Server -Property * | Select-Object Manufacturer, Model, NumberOfProcessors, NumberOfLogicalProcessors, TotalPhysicalMemory
		    $OS = gwmi Win32_OperatingSystem -ComputerName $Server | Select-Object InstallDate, LastBootUpTime, OSArchitecture, RegisteredUser, Organization
		    $SW = gwmi Win32_Product -ComputerName $Server | Select-Object Name, Version, Vendor, InstallDate, HelpLink | Sort-Object Name
		  $BIOS = gwmi Win32_Bios -ComputerName $Server | Select-Object Name, Manufacturer, ReleaseDate, SerialNumber 
	  $Services = gwmi Win32_Service -ComputerName $Server | Select-Object DisplayName, Name, StartMode, State, @{N='Running As';E={$_.StartName}} | Sort-Object DisplayName
		    $HD = gwmi Win32_LogicalDisk -ComputerName $Server | Select-Object *
		  $NETS = gwmi Win32_NetworkAdapterConfiguration -ComputerName $Server | ? {$_.IPEnabled} | Select-Object *
		$Shares = gwmi Win32_Share -ComputerName $Server | Select-Object Name, Path, Caption
	  $LogFiles = gwmi Win32_NTEventLogFile -ComputerName $Server
	       $GHF = Get-Hotfix -ComputerName $Server | Select-Object Description, @{N='Hotfix ID';E={$_.HotFixID}}, @{N='Installed By';E={$_.InstalledBy}}, @{N='Installed On';E={$_.InstalledOn}} | Sort-Object Description
													
			$General = @()
				$Info = "" | Select "Server","Operating System","Service Pack","Architecture","Manufacturer","Model","Processors","Cores","Memory(GB)","Created","Serial Number"
				$Info."Server" = $GADC.Name
				$Info."Operating System" = $GADC.OperatingSystem
				$Info."Service Pack" = $GADC.OperatingSystemServicePack
				$Info."Architecture" = $OS.OSArchitecture
				$Info."Manufacturer"= $HW.Manufacturer
				$Info."Model" = $HW.Model
				$Info."Processors" = $HW.NumberOfProcessors
				$Info."Cores" = $HW.NumberOfLogicalProcessors
				$Info."Memory(GB)" = [math]::round($HW.TotalPhysicalMemory/1024/1024/1024, 0)
				$Info."Created" = $GADC.whenCreated
				$Info."Serial Number" = $BIOS.SerialNumber
				$General += $Info

			$LDS = @()
				Foreach ($LD in ($HD | Where {$_.DriveType -eq 3})){
					$Details = "" | Select "Drive", "Label", "Disk Size (GB)", "Free Space (GB)", "% Free Space", "Compressed", "Serial Number", "File System", "Dirty"
					$Details."Drive" = $LD.DeviceID
					$Details."Label" = $LD.VolumeName
					$Details."Disk Size (GB)" = [math]::round(($LD.size / 1GB))
					$Details."Free Space (GB)" = [math]::round(($LD.FreeSpace / 1GB))
					$Details."% Free Space" = [math]::Round(($LD.FreeSpace /1GB) / ($LD.Size / 1GB) * 100)
					$Details."Compressed" = $LD.Compressed
					$Details."Serial Number" = $LD.VolumeSerialNumber
					$Details."File System" = $LD.FileSystem
					$Details."Dirty" = $LD.VolumeDirty
					$LDS += $Details
}

			$NetConfig = @()
				Foreach ($NET in $NETS) {
					$Config = "" | Select "Description", "IP Address", "Subnet Mask", "Gateway", "DNS Servers", "MAC Address"
					$Config."Description" = $NET.Description
					$Config."IP Address" = $NET.IPAddress[0]
					$Config."Subnet Mask" = $NET.IPSubnet[0]
					$Config."Gateway" = $NET.DefaultIPGateway[0]
					$Config."DNS Servers" = $NET.DNSServerSearchOrder[0]
					$Config."MAC Address" = $NET.MACAddress
					$NetConfig += $Config
				
}
   
			$LogSettings = @()
				Foreach ($Log in $LogFiles){
					$Events = "" | Select "Log Name","Location", "Overwrite Records", "Maximum Size(MB)", "Current Size(MB)","Log Entries"
					$Events."Log Name" = $Log.LogFileName
					$Events."Location" = $Log.Name
					If ($Log.OverWriteOutdated -lt 0)
						{$Events."Overwrite Records" = "Never"}
						if ($Log.OverWriteOutdated -eq 0)
							{$Events."Overwrite Records" = "As needed"}
							Else
								{$Events."Overwrite Records" = "After $($Log.OverWriteOutdated) days"}
					$MaxFileSize = [math]::Round(($Log.MaxFileSize / 1024 / 1024))
					$FileSize = [math]::Round(($Log.FileSize / 1024	/ 1024))			
					$Events."Maximum Size(MB)" = $MaxFileSize
					$Events."Current Size(MB)" = $FileSize
					$Events."Log Entries" = $Log.NumberOfRecords
					$LogSettings += $Events
				
			$Errors = @()
				$Errors += get-winevent -LogName * -ComputerName NETMGR -MaxEvents 100 | where {$_.LevelDisplayName -eq "Error"} | Select-Object @{N='Error Type';E={$_.LevelDisplayName}},@{N='Log Name';E={$_.LogName}}, Message, @{N='Error ID';E={$_.Id}}, @{N='Time Stamp';E={$_.TimeCreated}}
				$Errors += get-winevent -LogName * -ComputerName NETMGR -MaxEvents 50 | where {$_.LevelDisplayName -eq "Warning"} | Select-Object @{N='Error Type';E={$_.LevelDisplayName}},@{N='Log Name';E={$_.LogName}}, Message, @{N='Error ID';E={$_.Id}}, @{N='Time Stamp';E={$_.TimeCreated}}
			}
			
			$LocalU = @()
			$Users = @()
				$computerName = $Server
				$computer = [ADSI]"WinNT://$computerName,computer" 
				$Users += $computer.psbase.Children | Where-Object { $_.psbase.schemaclassname -eq 'user' } | Select-Object Name,Description,LastLogin
				Foreach ($User in $Users) {
					$LU = "" | Select "Name","Description","LastLogin"
					$LU."Name" = $User.Name[0]
					$LU."Description" = $User.Description[0]
					$LU."Last Login" = $User.LastLogin[0]
					$LocalU += $LU
			}
# I found this function on the web but don't remember the source.
	function Get-LocalGroupMember {
			[CmdletBinding()]
			param(
			[parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
			[string[]]$computername = $env:COMPUTERNAME
			)
			BEGIN {
			Add-Type -AssemblyName System.DirectoryServices.AccountManagement
			$ctype = [System.DirectoryServices.AccountManagement.ContextType]::Machine
			}
			PROCESS{
			foreach ($computer in $computername) {
			$context = New-Object -TypeName System.DirectoryServices.AccountManagement.PrincipalContext -ArgumentList $ctype, $computer
			$idtype = [System.DirectoryServices.AccountManagement.IdentityType]::SamAccountName
			$group = [System.DirectoryServices.AccountManagement.GroupPrincipal]::FindByIdentity($context, $idtype, 'Administrators')
			$group.Members | select @{N='Server'; E={$computer}}, @{N='Domain'; E={$_.Context.Name}}, samaccountName
			} # end foreach
} # end PROCESS
}

$Admins = Get-LocalGroupMember -computername $Server
$Bio = gc \\Server\Share\BIO\$Server.txt
<# 
*** Create a separate text file for each server with the following Static Information.***
*** This is for the important information that you cannot obtain programatically.***

<h3>Summary</h3>
<p>This server is a utility server for ...</p>  
<table>
<tr><td>System Owner:</td><td>OWNER</td></tr>
<tr><td>Phone:</td><td>(757) 555-1212</td></tr>
<tr><td>Roles:</td><td>Web Server</td></tr>
<tr><td>Physical location:</td><td>UCS enclosure, Main Data Center</td></tr>
<tr><td>Logical location:</td><td>Server VLAN xxx</td></tr>
<tr><td>Date Purchased:</td><td>01/12/2014</td></tr>
<tr><td>Support Contract:</td><td>N/A</td></tr>
<tr><td>Startup/Shutdown:</td><td>No special provisions.  This server may be rebooted at any time.</td></tr>
<tr><td>Notes:</td><td>NOTES Go here</td></tr>
<tr><td>URL:</td><td><a href="https://intranet/Servers/index.html" target="_blank">$Server</a></td></tr>
</table>
#>

$a = $General | ConvertTo-HTML -Fragment -As List | Out-String
$b = $LocalU | ConvertTo-HTML -Fragment | Out-String
$c = $Admins | ConvertTo-HTML -Fragment | Out-String
$d = $LDS | ConvertTo-HTML -Fragment | Out-String
$e = $NetConfig | ConvertTo-HTML -Fragment | Out-String
$f = $Services | ConvertTo-HTML -Fragment | Out-String
$g = $SW | ConvertTo-HTML -Fragment | Out-String
$h = $Shares | ConvertTo-HTML -Fragment | Out-String
$i = $LogSettings | ConvertTo-HTML -Fragment | Out-String
if ($Errors -eq $Null) {$j = "<p>There are no recent Errors or Warnings.</p>"}
	else {$j = $Errors | ConvertTo-HTML -Fragment | Out-String -width 100}
$k = $GHF | ConvertTo-HTML -Fragment | Out-String

Write-Host "Writing Report for $Server..." -Fore Green

$HTML = "<html>

<head>
<meta http-equiv='Content-Type' content='text/html; charset=iso-8859-1'>
<title>$Server Inventory</title>
<style type='text/css'> 
h1 {color:#000000; text-align:left; padding-left:2%;}
h2, h3, h4, h5 {color:#0081C6; text-align:left; padding-left:2%;}
table {width:80%; padding-left:2%;}
p {width:80%; color:#000000; text-align:left; padding-left:2%;}
body {margin-left:2%; width:90%; font-family:'Trebuchet MS',Arial,Helvetica,sans-serif;}
th {width:auto; font-weight:bold; font-size:11px; text-align:left; text-transform: uppercase; background-color:#0081C6; color: #FFFFFF; padding:.5% .5% .5% .5%;}  
td {width:auto; font-weight:normal; font-size:11px; text-align:left; padding:.5% .5% .5% .5%;}
tr:nth-child(odd) {background: #DDDDDD;}
</style>
</head>

<body>
<br />
<h1>$Server Inventory</h1>
<h2>Generated on $TD</h2>
<br />
$Bio
<br />
<h3>General</h3>
$a
<br />
<h3>Local Users</h3>
$b
<br />
<h3>Local Admins</h3>
$c
<br />
<h3>Local Disk</h3>
$d
<br />
<h3>Network Configuration</h3>
$e
<br />
<h3>Services</h3>
$f
<br />
<h3>Software</h3>
$g
<br />
<h3>Shares</h3>
$h
<br />
<h3>Log Settings</h3>
$i
<br />
<h3>Log Errors</h3>
$j
<br />
<h3>Hotfix Information</h3>
$k
<br />
</body>

</html>"

$OutputFile = "\\Server\C$\wwwroot\Intranet\Servers\$Server.html"
$HTML | Out-File $OutputFile
Write-Host "Clearing variables from loop" -Fore Green
Write-Host ("Elapsed Time : {0}" -f $($ElapsedTime1.Elapsed.ToString())) -fore Yellow
Write-Host ""
clear-variable -name $TD
clear-variable -name $GADC
clear-variable -name $HW
clear-variable -name $OS
clear-variable -name $SW
clear-variable -name $BIOS
clear-variable -name $Services
clear-variable -name $HD
clear-variable -name $NETS
clear-variable -name $Shares
clear-variable -name $LogFiles
clear-variable -name $GHF
clear-variable -name $General
clear-variable -name $Info
clear-variable -name $LDS
clear-variable -name $Details
clear-variable -name $NetConfig
clear-variable -name $NET
clear-variable -name $LogSettings
clear-variable -name $Log
clear-variable -name $Events
clear-variable -name $Errors
clear-variable -name $LocalU
clear-variable -name $Users
clear-variable -name $User
clear-variable -name $LU
clear-variable -name $computer
clear-variable -name $computername
clear-variable -name $context
clear-variable -name $idtype
clear-variable -name $group
clear-variable -name $Admins
clear-variable -name $a
clear-variable -name $b
clear-variable -name $c
clear-variable -name $d
clear-variable -name $e
clear-variable -name $f
clear-variable -name $g
clear-variable -name $h
clear-variable -name $i
clear-variable -name $j
clear-variable -name $k
clear-variable -name $Bio
clear-variable -name $OutputFile
clear-variable -name $HTML
clear-variable -name $ElapsedTime1
}

Write-Host ("Elapsed Time : {0}" -f $($ElapsedTime.Elapsed.ToString())) -fore Cyan
Stop-Transcript