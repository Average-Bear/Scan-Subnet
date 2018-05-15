  <#
.SYNOPSIS
    Detect all available hosts within a given subnet.

.DESCRIPTION
    Detect all available hosts within a given subnet.

.PARAMETER SubnetIP
    IP within desired subnet or, first three octets (i.e. 192.168.0, 192.168.0.122).

.PARAMETER IPRangeStart
    Starting IP address.
    Default 0.

.PARAMETER IPRangeEnd
    Ending IP address.
    Default 255.

.NOTES
    Author: JBear
    Date: 10/29/2017
#>

param(

    [Parameter(Mandatory=$true,HelpMessage="Enter an IP within desired subnet or, first three octets (i.e. 192.168.0, 192.168.0.122)")]
    [ValidateNotNullOrEmpty()] 
    [String[]]$SubnetIP,

    [Parameter(ValueFromPipeline=$true,HelpMessage="Enter starting IP range (fourth octet)")]
    [ValidateRange(0,255)] 
    [Int]$IPRangeStart = "0",

    [Parameter(ValueFromPipeline=$true,HelpMessage="Enter ending IP range (fourth octet)")]
    [ValidateRange(0,255)] 
    [Int]$IPRangeEnd = "255"
)

function Scan-IPRange {

    foreach($Sub in $SubnetIP) {

        [String[]]$SplitIP = $Sub.Split(".")
        [String]$OctetOne = $SplitIP[0]
        [String]$OctetTwo = $SplitIP[1]
        [String]$OctetThree = $SplitIP[2]
        [String]$Subnet = "$OctetOne.$OctetTwo.$OctetThree"
        $Range = $IPRangeStart..$IPRangeEnd 

        Start-Job { param($Subnet, $Range)

            foreach($R in $Range) {

                $IP = "$Subnet.$R"
                $DNS = @(

                    Try {
             
                        [Net.Dns]::GetHostEntry($IP) 
                    }

                    Catch {
            
                        $null
                    }
                )

                if($DNS) {

                    $Hostname = @(
         
                        if($DNS.HostName) {
                
                            $DNS.HostName
                        }
                                          
                        elseif(!($DNS.HostName)) {
                
                            $IP
                        }             
                    )          

                    [PSCustomObject] @{
                    
                        IP="$IP"
                        Hostname="$Hostname".Split(".")[0]
                        FQDN="$Hostname"
                    }         
                }          
            }
        } -ArgumentList $Subnet, $Range
    }

    $Jobs = Get-Job | Where { $_.State -eq "Running"}
    $Total = $Jobs.Count
    $Running = $Jobs.Count

    While($Running -gt 0) {
    
        Write-Progress -Activity "Scanning IP Ranges (Awaiting Results: $(($Running)))..." -Status ("Percent Complete:" + "{0:N0}" -f ((($Total - $Running) / $Total) * 100) + "%") -PercentComplete ((($Total - $Running) / $Total) * 100) -ErrorAction SilentlyContinue

        $Running = (Get-Job | Where { $_.State -eq "Running"}).Count
    }

}

#Call function 
Scan-IPRange | Receive-Job -Wait -AutoRemoveJob | Select IP, Hostname, FQDN  
