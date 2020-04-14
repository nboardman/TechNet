<#
	Author  : Nick Boardman
	E-Mail  : nboardman@hotmail.com
	Date	: April 11, 2016
	File	: ADHealthCheck.ps1
	Purpose : Query DC's for AD Health
	Version : 3.0 - Removed identifying corporate info to submit to TechNet 
	Notes   : text-transform:uppercase;
	Colors  : Black,Blue,Cyan,DarkBlue,DarkCyan,DarkGray,DarkGreen,DarkMagenta,DarkRed,DarkYellow,Gray,Green,Magenta,Red,White,Yellow	
#>

#Start timer
$elapsedTime = [system.diagnostics.stopwatch]::StartNew()
#For Error-handling
$ErrorActionPreference = "SilentlyContinue"
#To eliminate truncation of returned data -1 = unlimited
$FormatEnumerationLimit = -1

$Date = get-date -format g

Write-Host "Importing ActiveDirectory Module if not previously loaded."
Import-Module ActiveDirectory

$reportpath = ".\ADReport.htm" 
if((test-path $reportpath) -like $false)
{
new-item $reportpath -type file
}

$Hostname = @{
	 'DC1.YOURDOMAIN.COM' = 'DC1'
	 'DC2.YOURDOMAIN.COM' = 'DC2'
	 'DC3.YOURDOMAIN.COM' = 'DC3'
	 'DC4.YOURDOMAIN.COM' = 'DC4'

}

$DCs = @("DC1","DC2","DC3","DC4")
$FSMO = @()
$Mode = @()
$Site = @()
$Tests = @()

# You need to have Repadmin installed/available
$workfile = repadmin.exe /showrepl * /csv 
$results = ConvertFrom-Csv -InputObject $workfile | where {$_.'Number of Failures' -ge 1}

Write-Host "Querying Active Directory Forest Information"  -Fore Green
Write-Host ''
$F = Get-ADForest | Select-Object -Property SchemaMaster, DomainNamingMaster, RootDomain, ForestMode
Write-Host "Querying Active Directory Sites and Global Catalog Server Information" -Fore Green
Write-Host ''
$SGC = Get-ADForest YOURDOMAIN.com | Select-Object -Property @{N='Sites';E={$_.Sites -join ', '}},@{N='Global Catalog Servers';E={$_.GlobalCatalogs -join ', '}}
Write-Host "Querying Active Directory Domain Information"  -Fore Green
Write-Host ''
$D = Get-ADDomain -Identity YOURDOMAIN.com | Select-Object -Property PDCEmulator, RIDMaster, InfrastructureMaster, DomainMode

$Roles = @{
		'Schema Master' = $F.SchemaMaster
 'Domain Naming Master' = $F.DomainNamingMaster
         'PDC Emulator' = $D.PDCEmulator
           'RID Master' = $D.RIDMaster
'Infrastructure Master' = $D.InfrastructureMaster
 }
 
$Info = @{
		'Root Domain' = $F.RootDomain
		'AD Forest Mode' = $F.ForestMode
		'AD Domain Mode' = $D.DomainMode
}

$Mode += New-Object psobject -Property $Info
$FSMO += New-Object psobject -Property $Roles
$Site += $SGC

# You can search for DC's instead of adding them manually by using the code below.  You can comment out or remove the variables $DCs & $Hostname from above.
# I wanted them to show up in the report by Hostname, not FQDN.
# $DCS += Get-ADComputer -Filter * -SearchBase "OU=Domain Controllers,DC=YOURDOMAIN,DC=com" | Select-Object $_.Name | Sort-Object Name

if ($results -eq $null) {
    
		$results = "There are currently no Active Directory Replication Errors."
}
	else {
		$results = $results | Select-Object "Source DSA", "Naming Context", "Destination DSA" ,"Number of Failures", "Last Failure Time", "Last Success Time", "Last Failure Status" | ConvertTo-Html -fragment -As Table | Out-String
}

Write-Host "Checking Domain Controllers..."
# You need to have DCdiag installed/available
foreach ($DC in $DCS) {
	
	Write-Host "$DC"
		$Q1 = get-service -ComputerName $DC -Name "Netlogon" | Select-Object Status
		$Q2 = get-service -ComputerName $DC -Name "NTDS" | Select-Object Status
		$Q3 = get-service -ComputerName $DC -Name "DNS" | Select-Object Status
		$Q4 = dcdiag /test:netlogons /s:$DC /q
			if ($Q4 -eq $null){
				$Q4 = "Pass"
			}
				else {
				$Q4 = "FAILED!"	
			}
		$Q5 = dcdiag /test:Replications /s:$DC /q
			if ($Q5 -eq $null){
				$Q5 = "Pass"
			}
				else {
				$Q5 = "FAILED!"	
			}
		$Q6 = dcdiag /test:Advertising /s:$DC /q
			if ($Q6 -eq $null){
				$Q6 = "Pass"
			}
				else {
				$Q6 = "FAILED!"	
			}
		$Q7 = dcdiag /test:Services /s:$DC /q
			if ($Q7 -eq $null){
				$Q7 = "Pass"
			}
				else {
				$Q7 = "FAILED!"	
			}
					
	$Properties = @{
		'Domain Controller' = $DC
		 'NetLogon Service' = $Q1.Status
		     'NTDS Service' = $Q2.Status
			  'DNS Service' = $Q3.Status
		   'Netlogons Test' = $Q4
		 'Replication Test' = $Q5
		 'Advertising Test' = $Q6
		    'Services Test' = $Q7
			}
	
	$Tests += New-Object psobject -Property $Properties	
	}

$H1 = "<h1>AD Information &amp; Health Check</h1>"
$H2 = "<p>$Date</p>"
$A = "<h2>Domain &amp; Modes</h2>"
$B = $Mode | Select-Object 'Root Domain','AD Forest Mode','AD Domain Mode' | ConvertTo-Html -fragment -As Table | Out-String
$C = "<h2>FSMO Roles</h2>"
$D = $FSMO | Select-Object @{N='Schema Master';E={$Hostname[$F.SchemaMaster]}},@{N='Domain Naming Master';E={$Hostname[$F.DomainNamingMaster]}},@{N='PDC Emulator';E={$Hostname[$D.PDCEmulator]}},@{N='RID Master';E={$Hostname[$D.RIDMaster]}},@{N='Infrastructure Master';E={$Hostname[$D.InfrastructureMaster]}} | ConvertTo-Html -fragment -As Table | Out-String
$E = "<h2>AD Sites &amp; Domain Controllers</h2>"
$F = $Site | Select-Object Sites,@{N='Global Catalog Servers';E={$DCs -join ', '}} | ConvertTo-Html -fragment -As Table | Out-String
$G = "<h2>Replication Status (repadmin)</h2>"
$H = "<p>$Results</p>"
$I = "<h2>Domain Controller Checks (Powershell &amp; dcdiag)</h2>"
$J = $Tests | Select-Object 'Domain Controller','NetLogon Service','NTDS Service','DNS Service','Netlogons Test','Replication Test','Advertising Test','Services Test' | ConvertTo-HTML -fragment -As Table | Out-String
$BR = "<br />"

$head = @'
<style>
body {
background-color:#FFFFFF; padding: 0 0 0 2%;
}
h1 {
color:#0081C6;
}
h2 {
color:#0081C6;
}
h3 {
color:#00B15A;
}
table {
border-width:1px; border-style:solid; border-color:#FFFFFF; border-collapse:collapse; width:60%; background-color:#FFFFFF;
}
th {
border-width:4px; padding:.5% .5% .5% 1%; border-style:solid; border-color:#FFFFFF; background-color:#00B15A; color:#FFFFFF; width:auto; text-align:center; text-transform:uppercase;
}
td {
border-width:4px; padding:.5% .5% .5% 1%; border-style:solid; border-color:#FFFFFF; background-color:#d8dcd6; color:#0081C6; width:auto; text-align:center; vertical-align: top;
}
p {
color:#000000; font-size:large;
}
</style>
'@

$Body = ConvertTo-Html -head $head -body "$H1 $H2 $G $H $A $B $BR $C $D $BR $E $F $BR $I $J $BR $BR $BR $BR"  | Out-String

$email = @{
From = "ADHealth@yourdomain.com"
To = "admins@yourdomain.com"
Cc = "helpdesk@yourdomain.com"
Subject = "AD Health Check"
SmtpServer = "autodiscover.yourdomain.com"
Body = $Body
BodyAsHtml = $True
Attachment = $reportpath
}

$Body | Out-file $reportpath
Write-Host "Sending Report."  -Fore Green
Send-MailMessage @email
ii $reportpath
#End of timer
Write-Host ("Elapsed Time : {0}" -f $($ElapsedTime.Elapsed.ToString())) -fore Green