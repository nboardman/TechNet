<#
	Author  : Nick Boardman
	E-Mail  : nboardman@hotmail.com
	Date	: June 3, 2013
	File	: Get-DialinStatus.ps1
	Purpose : Get AD User's Dial-in Status
	Version : 2.0
	Notes   : 	
#>

#For Error-handling
$ErrorActionPreference = "Continue"
$elapsedTime = [system.diagnostics.stopwatch]::StartNew()

#Load AD module which contains the Get-ADUser command
write-host "Loading ActiveDirectory Module..." -back black -fore green
Import-Module ActiveDirectory

$ADUser = Read-Host "Enter AD account that you want to check"

$Dialin = Get-Aduser $ADUser -Property *  | Select-object "msNPAllowDialin"

	if ($Dialin.msNPAllowDialin -eq $True) {
	
		Get-Aduser $ADUser -Property *  | Select-object Name,SamAccountName,msNPAllowDialin | fl
	
			Write-Host "Dial-in permission for $ADUser is set to Allow." -back black -fore Green
			Write-Host ""
			$T = Read-Host "Would you like to Disable Dial-in permission for "$ADUser"?  [Y or N]"
		
				if ($T -eq "N") {
					Write-Host ""
					Write-Host "OK.  No changes have been made to $ADUser." -back black -fore Green
					}
		
				elseif ($T -eq "Y") {
					Write-Host ""
					Get-ADUser $ADUser | Set-Aduser -Replace @{msNPAllowDialin = "FALSE"}
					Write-Host "Dial-in permission has been revoked for $ADUser." -back black -fore Green
					}
}


	elseif ($Dialin.msNPAllowDialin -ne $True -or $Null) {
	
		Get-Aduser $ADUser -Property *  | Select-object Name,SamAccountName,msNPAllowDialin | fl
		
			Write-Host "Dial-in permission for $ADUser is set to either Deny [False] or Control access through NPS Policy [Blank]." -back black -fore RED
			Write-Host ""
			$F = Read-Host "Would you like to enable Dial-in permission for "$ADUser"?  [Y or N]"
		
				if ($F -eq "N") {
					Write-Host ""
					Write-Host "OK.  No changes have been made to $ADUser." -back black -fore Green
					}
		
				elseif ($F -eq "Y") {
					Write-Host ""
					Get-ADUser $ADUser | Set-Aduser -Replace @{msNPAllowDialin = "TRUE"}
					Write-Host "Dial-in permission has been granted for $ADUser." -back black -fore Green
					}
		
}	

Write-Host ""
write-host ("Elapsed Time : {0}" -f $($ElapsedTime.Elapsed.ToString())) -back black -fore green