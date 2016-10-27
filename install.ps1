New-Item -path $profile -type file -force
Copy-Item -path '.\Microsoft.PowerShell_profile.ps1' -destination $env:USERPROFILE\Documents\WindowsPowershell\Microsoft.PowerShell_Profile.ps1
pause