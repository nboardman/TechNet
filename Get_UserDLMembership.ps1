<#
	Author  : Nick Boardman
	E-Mail  : nboardman@hotmail.com
	Date	: March 4, 2013
	File	: Get_UserDLMembership.ps1
	Purpose : Get all Distribution Lists that a particular user is a member of.
	Version : 1.4
	Notes   : Version 1.1 Added the the cumulative number of DL's a user is in.
			  Version 1.2 Added error-handling for invalid user input, the Script will now stop running.
			  Version 1.3 Added user information to be displayed before calculating if user belongs to any DL's.
			  Version 1.4 Changed the results of $VerifyADUser from being displayed as a table, to now being displayed as a list.
	Colors  : Black,Blue,Cyan,DarkBlue,DarkCyan,DarkGray,DarkGreen,DarkMagenta,DarkRed,DarkYellow,Gray,Green,Magenta,Red,White,Yellow	
#>

#Start Timer
$elapsedTime = [system.diagnostics.stopwatch]::StartNew()

#For Error-handling, will stop if username is not in Active Directory
$ErrorActionPreference = "Stop"

Write-Host "Loading Active Directory Module for Powershell, unless already loaded..." -back Black -fore Cyan
Import-Module ActiveDirectory

#Prompt for user, format for input is SamAccountName
$ADUser = Read-Host -Prompt "Enter Active Directory User account you want checked"

$VerifyADUSer = Get-ADUser -Identity $ADUser -Properties * | fl DisplayName, Department, Title, TelephoneNumber, MobilePhone, Enabled

$VerifyADUSer

Write-Host "$ADUser is a member of the following Distribution Lists:" -back Black -fore Cyan
Write-Output ‘ ‘
 
$AllDGs = Get-DistributionGroup -ResultSize Unlimited

#Baseline for counting groups
$count = 0

foreach ($group in $AllDGs)
{
$member = Get-DistributionGroupMember -ResultSize Unlimited -Identity "$group" | where {$_.PrimarySmtpAddress -eq "$ADUser@YOURDOMAINGOESHERE.com"}

If ($member) 
{
#How the count increments upward for each DL the user is a member of
$count += 1
Write-Host "Distribution List: $group " -back Black -fore Green
} 
}
Write-Output ‘ ‘
Write-Host "$ADUser is a member of $count Distribution Lists." -back Black -fore Yellow
Write-Output ‘ ‘

#End of timer
Write-Host ("Elapsed Time : {0}" -f $($ElapsedTime.Elapsed.ToString())) -back Black -fore Red