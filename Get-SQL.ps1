<#
	Author  : Nick Boardman
	E-Mail  : nboardman@hotmail.com
	Date	: April 11, 2016
	File	: Get-SQL.ps1
	Purpose : Uses a list of Servers and checks each one for an installed instance of MS SQL
	Version : 2.0
	Notes   : Removed corporate identifying info to upload to TechNet
	Colors	: Green #00B15A, Blue #0081C6
	
	
	class Win32_Service : Win32_BaseService
{
  boolean  AcceptPause;
  boolean  AcceptStop;
  string   Caption;
  uint32   CheckPoint;
  string   CreationClassName;
  string   Description;
  boolean  DesktopInteract;
  string   DisplayName;
  string   ErrorControl;
  uint32   ExitCode;
  datetime InstallDate;
  string   Name;
  string   PathName;
  uint32   ProcessId;
  uint32   ServiceSpecificExitCode;
  string   ServiceType;
  boolean  Started;
  string   StartMode;
  string   StartName;
  string   State;
  string   Status;
  string   SystemCreationClassName;
  string   SystemName;
  uint32   TagId;
  uint32   WaitHint;
};

#>

#Start Timer
$elapsedTime = [system.diagnostics.stopwatch]::StartNew()
#To eliminate truncation of returned data -1 = unlimited
$FormatEnumerationLimit =-1
$Results = @()

Write-Host "Getting list of Servers..." -fore green
$Servers = Get-Content \\server\share\servers.txt
Write-Host "Complete."  -fore green

	foreach ($Server in $Servers) {
	
	$Results += gwmi -query "select * from win32_service where Name LIKE 'MSSQL%' and Description LIKE '%transaction%'" -computername $Server | select-object SystemName, Name, State, StartMode, Status
		
	}
	
$Results | Export-CSV C:\Scripts\Reports\SQL.csv -NoTypeInformation
ii C:\Scripts\Reports\SQL.csv
Write-Host ("Elapsed Time : {0}" -f $($ElapsedTime.Elapsed.ToString())) -back black -fore White