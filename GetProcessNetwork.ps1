#Capture binary based Network Connections
#Version 1.3

Param(
    #ProcessName = name without .exe!
    [parameter(position=0,mandatory=$true)]
    [string]$ProcessName,
    [parameter(position=1,mandatory=$true)]
    [int]$RunTimeSeconds = 10,
    [parameter(position=2,mandatory=$false)]
    [bool]$ShowDuplicate = $False
)

$currentUserSessionID = (Get-Process -PID $pid).SessionID
$ConnectionList = New-Object System.Collections.ArrayList
$FilterConnectionList = New-Object System.Collections.ArrayList

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
    if( ($matchpro.SI -eq $currentUserSessionID) -and ($matchpro.ProcessName -eq $ProcessName) ){
        return $True
    } 
    return $False
}

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

function dummy([IPAddress]$ipaddr){
    Write-Host "Got: $ipaddr"
}

$timeout = new-timespan -Seconds $RunTimeSeconds
$sw = [diagnostics.stopwatch]::StartNew()
while ($sw.elapsed -lt $timeout){
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
    start-sleep -Milliseconds 500
}

foreach($tConnection in $ConnectionList){
    if($tConnection.RemoteAddress -eq "::"){
        continue
    }

    if (-Not (MatchConnectionList($tConnection.RemoteAddress)) ){
        $FilterConnectionList.Add($tConnection) | Out-Null
    }   
}

if($ShowDuplicate){
    $ConnectionList | Format-Table -AutoSize
}else{
    $FilterConnectionList | Format-Table -AutoSize
}

