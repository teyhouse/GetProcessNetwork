# GetProcessNetwork
This will let you capture all network connections established by a process over a chosen amount of time. Due to the usage of NetTCPIP (default Powershell-Modul), this will work without any external dependencies out of the box.

This is meant as a quick way to find out which process made which connections in order to identify them or make quick firewall exceptions. GetProcessNetwork is aware of the user-session and will therefore work without any extra privileges and within Remote Desktop Services.

![screenshot](example.jpg?raw=true)

# Parameters
```GetProcessNetwork.ps1 [-ProcessName] <string> [-RunTimeSeconds] <int> [[-ShowDuplicate] <bool>]```
  
```-ProcessName```  
Name of the process you want to capture
  
```-RunTimeSeconds```  
How many seconds should the capture run
  
```-ShowDuplicate```  
Shows duplicate connections, hidden by default
  
Example usage:  
``` .\GetProcessNetwork.ps1 -ProcessName firefox -RunTimeSeconds 5```

# GetProcessNetworkThread  
The second version of this script (GetProcessNetworkThread.ps1) supports multiple threads. This is useful for scenarios in which you need to capture a high amount of connections in a very short timeframe. This will introduce a new Parameter called CheckRate, defined in millisecond. 
  
**Please be careful**: Check-Rates less than 100 Milliseconds are not supported and can lead to unexpected results and high CPU usage!
