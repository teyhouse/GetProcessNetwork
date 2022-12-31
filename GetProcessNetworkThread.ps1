#Capture binary based Network Connections
#Version 1.3


Param(
    #ProcessName = name without .exe!
    [parameter(position=0,mandatory=$true)]
    [string]$ProcessName,
    [parameter(position=1,mandatory=$true)]
    [int]$RunTimeSeconds = 10,
    [parameter(position=2,mandatory=$false)]
    [int]$CheckRate = 100,
    [parameter(position=3,mandatory=$false)]
    [bool]$ShowDuplicate = $False
)

$currentUserSessionID = (Get-Process -PID $pid).SessionID
$ConnectionList = New-Object System.Collections.ArrayList
$FilterConnectionList = New-Object System.Collections.ArrayList

Write-Output "Starting Packet-Capture..."
if($CheckRate -lt 100){
    Write-Warning "Check-Rates less than 100 Milliseconds are not supported and can lead to unexpected results and high CPU usage!"
}

Class RemoteConnection
{
    [String]$LocalAddress
    [String]$LocalPort
    [String]$RemoteAddress
    [String]$RemotePort
    [String]$State
    [String]$ProcessName
}

#Thread Functions / Data-Structure
$data = {
    Class RemoteConnection
    {
        [String]$LocalAddress
        [String]$LocalPort
        [String]$RemoteAddress
        [String]$RemotePort
        [String]$State
        [String]$ProcessName
    }

    function CheckPidCurrentUser($processpid){
        $matchpro = Get-Process -Id $processpid -ErrorAction SilentlyContinue
        if( ($matchpro.SI -eq $currentUserSessionID) -and ($matchpro.ProcessName -eq $pName) ){
            return $True
        } 
        return $False
    }
}

#Filter Double-Entries in ConnectionList
function MatchConnectionList([IPAddress]$ipaddr){
    foreach($rcon in $FilterConnectionList){
        if($rcon.RemoteAddress -ne "::"){
            if([IPAddress]$rcon.RemoteAddress -eq $ipaddr){
                Return $True
            }
        }        
    }
    return $False
}

#Spawn Threads
$timeout = new-timespan -Seconds $RunTimeSeconds
$sw = [diagnostics.stopwatch]::StartNew()
while ($sw.elapsed -lt $timeout){
        Start-Job -InitializationScript $data -ArgumentList $ProcessName,$currentUserSessionID,$test -Scriptblock {
            $ConnectionList = New-Object System.Collections.ArrayList
            $pName = $args[0]
            $currentUserSessionID = $args[1]
            foreach($connection in Get-NetTCPConnection){
                if(CheckPidCurrentUser($connection.OwningProcess)){
                    if( ($connection.State -ne "Bound") -and ($connection.LocalAddress -ne "0.0.0.0") -and ($connection.LocalAddress -ne "127.0.0.1") ){
                        $obj = New-Object RemoteConnection
                        $obj.LocalAddress = $connection.LocalAddress
                        $obj.LocalPort = $connection.LocalPort
                        $obj.RemoteAddress = $connection.RemoteAddress
                        $obj.RemotePort = $connection.RemotePort
                        $obj.State = $connection.State
                        $obj.ProcessName = $ProcessName
                        $ConnectionList.Add($obj) | Out-Null
                    }          
                }
            }
            return $ConnectionList
        } | Out-Null        
    start-sleep -Milliseconds $CheckRate
}

#Wait for Jobs to finish
Clear-Host
Write-Output "Waiting for Threads to finish..."
$count = 0

while($true){
    $check = $True
    foreach($job in Get-Job){
        if($job.State -ne "Completed"){
            $check = $False
        }
        $count++
    }
    if($check){
        break
    }
}
Write-Output "Finished $count Jobs, merging Results..."

#Merge ConnectionLists
foreach($worker in Get-Job){
    foreach($connection in $worker | Receive-Job){
        $obj = New-Object RemoteConnection
        $obj.LocalAddress = $connection.LocalAddress
        $obj.LocalPort = $connection.LocalPort
        $obj.RemoteAddress = $connection.RemoteAddress
        $obj.RemotePort = $connection.RemotePort
        $obj.State = $connection.State
        $obj.ProcessName = $ProcessName
        $ConnectionList.Add($obj) | Out-Null
    }
}



#Sort Lists
foreach($tConnection in $ConnectionList){
    if($tConnection.RemoteAddress -eq "::"){
        continue
    }

    if (-Not (MatchConnectionList($tConnection.RemoteAddress)) ){
        $FilterConnectionList.Add($tConnection) | Out-Null
    }   
}

#Show Results
if($ShowDuplicate){
    $ConnectionList | Format-Table -AutoSize | Out-String -Width 4096
}else{
    $FilterConnectionList | Format-Table -AutoSize | Out-String -Width 4096
}

