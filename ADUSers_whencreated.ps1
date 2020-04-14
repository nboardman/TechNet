<#
	Author  : Nick Boardman
	E-Mail  : nboardman@hotmail.com
	Date	: December 21, 2012
	File	: ADUSers_whencreated.ps1
	Purpose : Getting Information about the most recent Active Directory Users created.
	Version : 2.3
	Notes   : *** You need to have the Active Directory module for Powershell installed.  For more information: http://technet.microsoft.com/en-us/library/ee617195.aspx
			  Version 1 - Original fields: "name", "whencreated", "enabled".  Wrote initial data collection file to csv.
			  Version 2 - Added conversion from csv to HTML.  Changed initial collection file to from csv to xml due to formatting issues when converting to HTML.  
			  Version 2.1 - Added "company" field to be able to distinguish employees from consultants.
			  Version 2.2 - Added "description" field.
			  Version 2.3 - Added automatic opening of the HTML page when complete.

#>

#Start timer
$elapsedTime = [system.diagnostics.stopwatch]::StartNew()

#Variables for output files
$OutputXML = "C:\Scripts\Output\ADUSers Whencreated $((get-date).ToString("MM_dd_yyyy")).xml"
$OutputHTML = "C:\Scripts\Output\ADUSers Whencreated $((get-date).ToString("MM_dd_yyyy")).html"

#Variable used to capture who runs the report
$whoami = whoami

#HTML code
$body = "<h2>AD Users sorted by Date created - compiled on $(get-date -format g) by $whoami</h2>"
$format = $format + "<style>"
$format = $format + "BODY {background-color:#FFFFFF;}"
$format = $format + "h2 {padding:0 0 0 1%; color:#00B15A; text-align:center;}"
$format = $format + "TABLE {border-width:1px; border-style:solid; border-color:black; border-collapse:collapse; width:80%; margin:auto;}"
$format = $format + "TH {border-width:1px; padding:0px; border-style:solid; border-color:black; background-color:#00B15A; color:#FFFFFF; text-align:center; width:20%; text-transform:uppercase;}"
$format = $format + "TD {border-width:1px; padding:0px; border-style:solid; border-color:black; background-color:#0081C6; color:#FFFFFF; text-align:center; width:20%; }"
$format = $format + "</style>"

#Load AD module which contains the Get-ADUser command
write-host "Loading ActiveDirectory Module..." -back black -fore green

Import-Module ActiveDirectory

write-host "Querying AD for users and listing by creation date in descending order and writing XML file.  This will only take a moment..." -back black -fore green

#Gets users and writes XML file
Get-ADUser -Filter * -Properties ("whencreated","company","description") |  sort-object -property "whencreated" -descending  | select-object -property ("name","company","description","whencreated","enabled") | Export-cliXML $OutputXML
write-host "The XML file was written to: $OutputXML" -back black -fore green

#Gets XML file and then converts it HTML
write-host "Getting XML file and converting to HTML.  Saving new file." -back black -fore green

$data = Import-clixml $OutputXML
$data | ConvertTo-HTML -title "Active Directory Users" -head $format -body $body | Format-Table -property ("name","company","description","whencreated","enabled") | Out-File $OutputHTML

write-host "The HTML file was written to: $OutputHTML" -back black -fore green

write-host  "Completed this request at $(get-date) " -back black -fore green

write-host ("Elapsed Time : {0}" -f $($ElapsedTime.Elapsed.ToString())) -back black -fore green

#Launches default browser and loads the page
Invoke-Item  $OutputHTML
