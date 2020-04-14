<#
	Author  : Nick Boardman
	E-Mail  : nboardman@hotmail.com
	Date	: December 28, 2012
	File	: Get-ActiveSyncDeviceStatistics.ps1
	Purpose : Getting Information about Active Directory Users and their ActiveSync Devices.
	Version : 1.0
	Notes   : 
#>

#Start timer
$elapsedTime = [system.diagnostics.stopwatch]::StartNew()

#Some variables
$OutputHTML = "C:\Scripts\Output\activesync_users.html"
$OutputXML = "C:\Scripts\Output\activesync_users.xml"
$whoami = whoami

#HTML code
$body = "<h2>Get-ActiveSyncDeviceStatistics - compiled on $(get-date -format g) by $whoami</h2>"
$format = $format + "<style>"
$format = $format + "BODY {background-color:#FFFFFF;}"
$format = $format + "h2 {padding:0 0 0 1%; color:#00B15A; text-align:center;}"
$format = $format + "TABLE {border-width:1px; border-style:solid; border-color:black; border-collapse:collapse; width:80%; margin:auto;}"
$format = $format + "TH {border-width:1px; padding:0px; border-style:solid; border-color:black; background-color:#00B15A; color:#FFFFFF; text-align:center; width:20%; text-transform:uppercase;}"
$format = $format + "TD {border-width:1px; padding:0px; border-style:solid; border-color:black; background-color:#0081C6; color:#FFFFFF; text-align:center; width:20%; }"
$format = $format + "</style>"


#Gathering information - writing XML file
write-host "Getting Users, this will take a few moments..." -back black -fore green 
$UserList = Get-CASMailbox -Filter {hasactivesyncdevicepartnership -eq $true -and -not displayname -like "CAS_{*"} | Get-Mailbox
write-host "Compiling and writing XML file, this will take a few moments..." -back black -fore green 
$UserList | foreach { Get-ActiveSyncDeviceStatistics -Mailbox $_} | sort-object -property "Identity" | select-object ("Identity","DeviceType","DeviceModel","FirstSyncTime","LastSuccessSync","LastPolicyUpdateTime","IsRemoteWipeSupported","Status") | Export-cliXML $OutputXML


write-host "Importing contents of XML file..." -back black -fore green

$users = Import-clixml $OutputXML

write-host "Creating and writing HTML file..." -back black -fore green

$users | Select-Object -property ("Identity","DeviceType","DeviceModel","FirstSyncTime","LastSuccessSync","LastPolicyUpdateTime","IsRemoteWipeSupported","Status") | sort-object -property "Identity" | ConvertTo-HTML -title "Active Sync Users" -head $format -body $body | Format-Table -property ("Identity","DeviceType","DeviceModel","FirstSyncTime","LastSuccessSync","LastPolicyUpdateTime","IsRemoteWipeSupported","Status") | Out-File $OutputHTML

			
write-host "The HTML file was written to: $OutputHTML" -back black -fore green

write-host  "Completed this request at $(get-date) " -back black -fore green

write-host ("Elapsed Time : {0}" -f $($ElapsedTime.Elapsed.ToString())) -back black -fore green
			
#Launches default browser and loads the page
Invoke-Item  $OutputHTML



