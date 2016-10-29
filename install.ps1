if (!(Test-Path -Path $PROFILE.CurrentUserAllHosts)) 
{ New-Item -Type File -Path $PROFILE.CurrentUserAllHosts -Force }
	$PsHome\Profile.ps1

Copy-Item -path '.\Microsoft.PowerShell_profile.ps1' -destination '$PsHome\Profile.ps1'
pause
