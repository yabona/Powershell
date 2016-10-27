#       ___  ____  ___________  ______ ________   __ 
#      / _ \/ __ \/ __/ __/ _ \/ __/ // / __/ /  / / 
#     / ___/ /_/ /\ \/ _// , _/\ \/ _  / _// /__/ /__
#    /_/   \____/___/___/_/|_/___/_//_/___/____/____/                                                
#
#                ###################
#                ## Elijah Yabona ##
#                ###################



#Globals, ui options
$host.ui.RawUI.WindowTitle = “PoserShell"
$user = whoami
$fullname = Get-WmiObject win32_UserAccount | where {$_.caption -eq $user} | Select-Object Fullname | ft -Hidetableheaders | Out-String
$fullname = $fullname.TrimStart()
$fullname = $fullname.TrimEnd()

#query current user to detect "admin" credentials
function isAdmin {
    if ([bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544") ) {
        return $true
    }
}

#shell cheatsheet
function cheat {
    Write-host "`n# Yabona's PoserShell V0.7`n" -ForegroundColor DarkMagenta
    write-host "Test-Internet`nGet-Hardware`nGet-MemStats`nGet-ProcStats`nGet-DiskStats`nGet-IP`nGet-Staus`nGet-infoBrief"
}

#logic to setup and print a statusbar of any given decimal percent value
function StatusBar ($per) {
    #convert percentage to /10
    $bars = [math]::round($($per / 10),2)

    #logic to determine the color of the statusBar
    if($bars -lt 2){
        $color = 'green'
    } elseif ($bars -lt 4) {
        $color = 'cyan'
    } elseif ($bars -lt 6) {
        $color = 'yellow'
    } elseif ($bars -lt 8) {
        $color = 'darkred'
    } elseif ($bars -lt 10) {
        $color = 'red'
    }
    
    #Write the statusbar to console with selected color
    Write-Host "`n [" -NoNewline -ForegroundColor $color
    for($i=0; $i -le $bars; $i++) {
        write-host "=" -NoNewline -ForegroundColor $color
    }
    for ($i=10; $i -ge $bars; $i--) {
        write-host " " -NoNewline 
    }
    Write-host "]" -NoNewline -ForegroundColor $color
}

# connection test phase
function Test-Internet {
    if (Test-Connection 208.67.222.222 -Quiet -count 1 ) {
        write-host " [CONNECTION ACTIVE]" -ForegroundColor Green 
        return $true
    } else {
        write-host " [CONNECTION OFFLINE]" -ForegroundColor Red 
        return $false
    } 
}

# Retrieve hardware info and BIOS data
function Get-Hardware {
    $vendor = wmic csproduct get vendor 
    $vendor = ($vendor -replace ("vendor"),('') )
    $vendor = $vendor.TrimStart()
    $model = wmic csproduct get name
    $model = ($model -replace "name",'').TrimStart()
    $model = $model.TrimEnd()
    $serial = wmic bios get serialnumber
    $serial = ($serial -replace ("serialnumber"),('') ).TrimStart()
    $bios = wmic bios get Name
    $bios = ($Bios-replace ("Name"),('') ).TrimStart()
    $user = whoami
    write-host "`nCURRENT MACHINE:" -NoNewline 
    Write-host "`n$vendor $model`n`nSerial Number: $serial`nBIOS/UEFI Revision: $bios"

    $CPUname = Get-WmiObject -class win32_processor | select Name | ft -HideTableHeaders | out-string
    $cpuname = $cpuname.trimStart()
    $cpuname = $cpuname.trimEnd()
    Write-host "`nProcessor: `n$cpuName`n"
    $ram = (Get-WMIObject -class Win32_PhysicalMemory | Measure-Object -Property capacity -Sum | % { [Math]::Round(($_.sum / 1GB),2) } )
    $mem = get-wmiobject -class win32_physicalmemory
    $memorySys = Get-WmiObject -Class win32_physicalMemoryArray
    Write-host "Memory: `n$ram GB $($mem.speed[0])MHz memory installed"
    Write-host "$($memorySys.maxcapacity / 1048576) GB possible on $($memorysys.memorydevices) DIMM slots"
    
    $gpus = Get-WmiObject -class Win32_VideoController
    Write-host "`nGraphics Hardware:`n$($gpus.name | Out-String)"
    
    $disks = Get-Disk | Select-Object -property Model | ft -HideTableHeaders | Out-String
    $disks = $disks.trimStart()
    $disks = $disks.TrimEnd()
    
    Write-host "Attached Drives: `n$disks`n`n"
}

# Retrieve memory objects
function Get-MemStats {
    write-host "`n### Memory Statistics ###" -NoNewline
    
    $memAvailable = ( (get-counter -counter "\memory\Available Mbytes").CounterSamples[0].CookedValue ) /1024
    $memAvailable = [math]::round($memAvailable,2)
    $memUsed = ((get-counter -counter "\memory\Committed Bytes").CounterSamples[0].CookedValue) /1073741824
    $memUsed = [math]::round($memUsed,2)
    $memPer = Get-WmiObject win32_operatingsystem | Foreach {"{0:N2}" -f ((($_.TotalVisibleMemorySize - $_.FreePhysicalMemory)/ $_.TotalVisibleMemorySize) * 100) }

    StatusBar($memPer)
    Write-Host "  $memper% MEMORY IN USE`n`t$memUsed GB IN USE`n`t$memAvailable GB AVAILABLE`n"
}

# Retrieve processor use
function Get-ProcStats {
    write-host "`n### Processor Statistics ###" -NoNewline
    $proc = ( (Get-Counter -counter "\Processor(_Total)\% Processor Time").CounterSamples[0].CookedValue ) 
    $proc = [math]::round($proc,2)
    StatusBar($proc)
    Write-host "  $proc% CPU IN USE`n"
}

#Get disk info and usage, rather proud of this one..
function Get-diskStats {
    Write-host "`n### Disk Statistics ###" -NoNewline
    $disk = Get-WmiObject Win32_LogicalDisk |Select-Object
    $i = 0

    while ($i -lt $disk.length) {
        $id = $disk.deviceID[$i]
        $freePer = ((($disk.size[$i]-$disk.freespace[$i]) /$disk.size[$i]) *100 )
        $freePer = [math]::round($freePer,2)
    
        statusbar($freePer)
        write-host $freePer "% $id $($disk.volumename[$i]) `n`t$([math]::round(($disk.freespace[$i] / 1073741824),2)) GB USED `n`t$([math]::round(($disk.size[$i] / 1073741824),2)) GB TOTAL"
        $i++
    }
    write-host
}

#Similar to the algo used in basic setup script
function Get-IP {
    write-host
    $connectionState = Test-Internet 
    $net = Get-NetIPAddress
    if($connectionState) 
    {
        $publicIP = (resolve-dnsname -name myip.opendns.com -server 208.67.222.220).ipaddress
        Write-Host "$PublicIP`t- Public IPv4" -ForegroundColor darkgreen
    }
    $i = 0
    while ($i -lt $net.length) 
    {
        if(($net.AddressFamily[$i] -eq "IPv4") -and ($net.IPAddress[$i] -notmatch '169.254' )) 
        {
            write-host "$($net.IPaddress[$i]) `t- $($net.InterfaceAlias[$i]) " 
        }
        $i++
    }
    write-host
}

#full status: network, memory, CPU, disk, etc.
function Get-Status {
    #actual start to this druginduced shit program...
    Get-IP
    Get-ProcStats
    Get-MemStats
    Get-diskStats

    write-host "`n`n"
}

#mainly used for shell setup
function Get-infoBrief {
    #show windows version
    $ver = ([system.environment]::OSVersion.Version | select Build | ft -HideTableHeaders | Out-String)
    $ver = $ver.TrimStart()
    $ver = $ver.TrimEnd()
    Write-host "`n [OS REVISION $ver]" -ForegroundColor Gray

    #show date 
    write-host " [TODAY IS $([datetime]::now.ToShortDateString())]" -ForegroundColor Blue

    $connectionState = test-Internet

    # administrator check phase
    if (isAdmin) {
        write-host " [ELEVATED USER RIGHTS]" -ForegroundColor green -NoNewline
    } else {
        write-host " [LIMITED USER RIGHTS]" -ForegroundColor Yellow -NoNewline
    }

    #memory statistics phase
    $mem = Get-WmiObject win32_operatingsystem | Foreach {"{0:N2}" -f ((($_.TotalVisibleMemorySize - $_.FreePhysicalMemory)*100)/ $_.TotalVisibleMemorySize) } 
    StatusBar($mem)
    Write-host " $mem% MEMORY USED " -NoNewline

    Write-Host "`n`nWelcome, $fullname. "
}

#Prompt setup
clear-host
Get-infoBrief

#setup function for recurring prompt
function prompt {
    write-host "[$user]" -ForegroundColor Magenta -NoNewline
    if(IsAdmin) {
        write-host "[A]" -ForegroundColor DarkRed -NoNewline
    } else {
        write-host "[U]" -ForegroundColor Green -NoNewline
    }
    write-host " :: " -NoNewline
    write-host "[$([datetime]::Now.ToShortTimeString())]" -ForegroundColor blue -NoNewline
     "`n[$(get-location)] >> "
}

function Remove-Kebab {
Write-host "


                                      `.:////-..``                              
                                 .:/smNMMMMMMMMMNNNmy+-`                        
                            -/sdNMMNmMMMMMMMMMMMMMMMMMMNmdyso+:.`               
                       .:+ymMMMMMMm--mMNyNMMMMMMMMMMMMMMMMMMMMMMMmho-           
                    -/hMMMMMMMMMMMm: -NM/-mMMMMMMMMMMMMMMMMMMMMMMMMMN:          
                 `/dMMMMMMMMMMMMMy+h..dMh`oMMMMMMMMMMMMMMMMMMMMMMMMMN/          
                /mMMMMMMMMMMMMMMMy-hy`-NMymMMMMMMMMMMMMMMMMMMMMMMMMd:           
             `+hMMMMMMMMMMMMMMMMMMh++`:hMMMMMMMMMMMMMMMMMMMMMMMMMm/             
          `:omMMMMMMMMMMMMMMMMMMMMMhohMMMMMMMMMMMMMMMMMMMMMMMMMMy`              
        -omMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNNNMMMMMMMMN/                
      `:mMMMMMMMMMMMMMMMMMMMMMMMMMMMNmdyo+:.`          `.:/oNMMN/               
     -dMMMMMMMMMMMMMMMMMMMMMMmhso/:.`                       hMMMNo`             
    :hMMMMMMMMMMMMMMMMMMMMh:`                              `dMMMNs.             
  .dNhMMMMMMMMMMMMMMMMMMMMm/`       `                      -dMMMNd-             
   +MMMMMMMMMMMMMMMMMMMMhsho:`      /      `.`             :NMMMMd`             
   /myNNmyosyyysNMMMMMMMMNMMMdhddm- -` -MMMMMd-`  ``      .yMMMMN+              
    .-.`        sMMMMMMMMMMNhydMMM:    +MMMMNNMh/hdy.     /NMMNs` :.            
                +MMMNhMMMMh/` :MMM:    sMMMMyyo`-hhh/     .mMM+  ``//           
                sMMMmdMMMMm+./NMMM:    `+hdmNd:  ``       `mMh:::` `.           
                :MMMmmMNNMNsyNMMMM:        `-:`           :m/  -Nh` `           
                `NMMMMMmsysdMMMMMd.              ``       :+   /s:  /           
                 dMMMMMMMdNMMMMMm:             ....      `/:      `+/           
                 -NMMMMMMMMMMMMMMs    `/.     `...`      .:`     :hy.           
                  /MMNMMMMMMMMMMMMmh` `+:                -/sh:   `/s            
                   sd.hMMMMMMMMMMNyy+                    `/s/:-`:-``            
                    `.dMMMMMMMMNN: -m:`     `            `y/                    
                      -MMMMMMMMMMMmhdmNmh+.`.`           `+h/`                  
                       mMMMMMMMMMMNsyyo/oso-..`            /MNdh/`              
           .:++/::///odMMMMMMMMMMMMNNNNh:`   ..            oMMMMMNy/`           
      `+sysmMMMMMMMMMMMMMMMMMMMMMMNmhy/-`   `..`     `.   .mMMMMMMMMNs-         
     .dMMMMMMMMMMMMMMMMMMMMMMMMMMMo.``     ``.-.`  `-.    :NMMMMMMMMMMd         
    /NMMMMMMMMMMMMMMMMMMMMMMMMMMMM:        ``.osyyys.    `yMMMMMMMMMMMd `./`    
    yMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNs:...```.-yNNmo-     /dNMMMMMMMMMMMs .hso--` 
+h/ -NMMMMmmMMMMMMMMMMMMMMMMMMMMMMMMMMNmmmdhsoo/.   `:ohmhNMMMMMMMMMMNs.    `dd:
hMy :NMMMMy.-hMMMMMMMMMMMMMMMMMMMMMMMMMMdo/`    `:shmNNh+oNMMMMMMMMMhsmh.  -y+-+
MNsdMmhMMmNNy:.+mMMMMMMMMMMMMMMMMMMMMN-` .:`  -yNmmmmds/hMMMMMMMMNy-/mMNsodhoMMd
MMMMy`hMs/mNMMd/`oNMMMMMMMMMMMMMMMMMMN.  ..:yso+hNMNhsdNMMMMMMMMh//smMMNMMMMMMMM
MMNMs`mm::hNNoomNs/dMMMMNNMMMMMMMMMMMMs+sdhds-:sssdmMMMMMMMMMMh-`-omMMMMMMMMMMMM
Mo-y`.NN/`yMMNo :mMMMMMMddMMMMMMM/+NMMMMMh/NMy`/ymMMMMMMMMMNdo.`-yNMMMMMMMMMMMMM
N`.o+dMds.:hmMNshMMMMMMNoNMMMMNdMmdMMMMMsNMMMh/NMMMMMMMMMMd:ddydNMMMMMMMMMNmmMMM

   ===================================================================
   +     ~=@=~     THIS SERVER IS CERTIFIED KEBAB FREE     ~=@=~     +
   ===================================================================
" -ForegroundColor DarkRed
}