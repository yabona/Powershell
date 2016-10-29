if $allusers {
	if (!(Test-Path -Path $PROFILE.CurrentUserAllHosts)) { 
		New-Item -Type File -Path $PROFILE.CurrentUserAllHosts -Force 
	}
	Copy-Item -path '.\Microsoft.PowerShell_profile.ps1' -destination '$PsHome\Profile.ps1'
} else {
	if (!(test-path -path $profile)	{
		new-item -type file -path $profile -force	
	}	
	Copy-Item -path '.\Microsoft.PowerShell_profile.ps1' -destination $env:USERPROFILE\Documents\WindowsPowershell\Microsoft.PowerShell_Profile.ps1
}

write-host "...Done!"
pause
