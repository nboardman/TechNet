<#
	Author  : Nick Boardman
	E-Mail  : nboardman@hotmail.com
	Date	: January 2, 2013
	File	: Get-ActiveSyncDevices.ps1
	Purpose : Getting Information about Active Directory Users and their ActiveSync Devices.
	Version : 1.0
	Notes   : Used Get-ActiveSyncDevice cmdlet, instead of the Get-ActiveSyncDeviceStatistics 
	
#>

#Start timer
$elapsedTime = [system.diagnostics.stopwatch]::StartNew()

#Some variables
$OutputHTML = "C:\Scripts\Output\activesync_users1.html"
$OutputXML = "C:\Scripts\Output\activesync_users1.xml"
$whoami = whoami

#HTML code
$body = "<h2>Get-ActiveSyncDevices - compiled on $(get-date -format g) by $whoami</h2>"
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
$UserList | foreach { Get-ActiveSyncDevice -Mailbox $_} | sort-object -property "UserDisplayName" | select-object ("UserDisplayName","DeviceId","DeviceType","DeviceModel","DeviceOS","FirstSyncTime") | Export-cliXML $OutputXML


write-host "Importing contents of XML file..." -back black -fore green

$users = Import-clixml $OutputXML

write-host "Creating and writing HTML file..." -back black -fore green

$users | Select-Object -property ("UserDisplayName","DeviceId","DeviceType","DeviceModel","DeviceOS","FirstSyncTime") | sort-object -property "UserDisplayName" | ConvertTo-HTML -title "Active Sync Users" -head $format -body $body | Format-Table -property ("UserDisplayName","DeviceId","DeviceType","DeviceModel","DeviceOS","FirstSyncTime") | Out-File $OutputHTML

			
write-host "The HTML file was written to: $OutputHTML" -back black -fore green

write-host  "Completed this request at $(get-date) " -back black -fore green

write-host ("Elapsed Time : {0}" -f $($ElapsedTime.Elapsed.ToString())) -back black -fore green
			
#Launches default browser and loads the page
Invoke-Item  $OutputHTML
