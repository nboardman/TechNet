<#
	Author  : Nick Boardman
	E-Mail  : nboardman@hotmail.com
	Date	: June 25, 2013
	File	: Disable_user.ps1
	Purpose : Disable AD account(s), move to Disabled OU, and put all pertinent information in the Account's description field.
	Version : 2.0
	Notes   : Version 1.2 adds the following: Hides user from GAL
			  Version 2 changed the HomeDir to be renamed
	!*!*!*!	: Must be run from Exchange Management Shell in order for Exchange tasks to Execute
#>

#Start timer
$elapsedTime = [system.diagnostics.stopwatch]::StartNew()

Write-Host "Loading Active Directory Module for Powershell, unless already loaded..." -back black -fore Green
Import-Module ActiveDirectory

$date = Get-Date -format g
$whoami = whoami
$ADUser = Read-Host "Enter AD account that you want disabled"
$NewHome = $ADUser + "-DISABLED"

#Start timer
$elapsedTime = [system.diagnostics.stopwatch]::StartNew()

Write-Host "Disabling YOURDOMAIN\$ADUser" -back black -fore Green
Disable-ADAccount -Identity $ADUser

Get-ADUser -Identity $ADUser -Properties * |
  
	ForEach-Object {
  
      Set-ADUser $_ -Description "Disabled on $date, by $whoami"
	  }
	  
Write-Host "Renaming Home Folder for YOURDOMAIN\$ADUser if it exists..." -back black -fore Green

Get-ADUser -Identity $ADUser -Properties homeDirectory |

	ForEach-Object {

		if ($_.homeDirectory) 
		{
		Rename-Item $_.homeDirectory $NewHome
		}
} 

Write-Host "Moving YOURDOMAIN\$ADUser to Disabled OU" -back black -fore Green
Get-ADUser -Identity $ADUser | Move-ADObject -TargetPath "OU=Disabled,DC=YOURDOMAIN,DC=com"

Write-Host "Hiding YOURDOMAIN\$ADUser from Global Address List" -back black -fore Green
Set-Mailbox -Identity $ADUser -HiddenFromAddressListsEnabled $true

Write-Host "Updating Global Address List"
Update-GlobalAddressList "Default Global Address List"

Write-Host ("Elapsed Time : {0}" -f $($ElapsedTime.Elapsed.ToString())) -back black -fore White