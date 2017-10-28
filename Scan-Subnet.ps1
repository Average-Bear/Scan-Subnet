 <#
.SYNOPSIS
    Detect all available hosts within a given subnet.

.DESCRIPTION
    Detect all available hosts within a given subnet.

.PARAMETER SubnetIP
    IP within desired subnet or, first three octets (i.e. 192.168.0, 192.168.0.122).

.PARAMETER IPRangeStart
    Starting IP address; default 0.

.PARAMETER IPRangeEnd
    Ending IP address; default 255.

.NOTES
    Author: JBear
    Date: 10/29/2017
#>

param(

    [Parameter(Mandatory=$true,HelpMessage="Enter an IP within desired subnet or, first three octets (i.e. 192.168.0, 192.168.0.122)")]
    [String]$SubnetIP,

    [Parameter(ValueFromPipeline=$true,HelpMessage="Enter starting IP range; fourth octet")]
    [String]$IPRangeStart = "0",

    [Parameter(ValueFromPipeline=$true,HelpMessage="Enter ending IP range; fourth octet")]
    [String]$IPRangeEnd = "255"
)

$i=0
$j=0

[String[]]$SplitIP = $SubnetIP.Split(".")
[String]$OctetOne = $SplitIP[0]
[String]$OctetTwo = $SplitIP[1]
[String]$OctetThree = $SplitIP[2]
[String]$Subnet = "$OctetOne.$OctetTwo.$OctetThree"
$Range = $IPRangeStart..$IPRangeEnd 

function Scan-IPRange { 

    foreach($R in $Range) {

        Write-Progress -Activity "Scanning IP Range ($IPRangeStart - $IPRangeEnd)..." -Status ("Percent Complete:" + "{0:N0}" -f ((($i++) / $Range.count) * 100) + "%") -CurrentOperation "Processing $("$Subnet.$R")..." -PercentComplete ((($j++) / $Range.count) * 100)

        Start-Job { param($IP, $Subnet, $R)

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
        } -ArgumentList $IP, $Subnet, $R
    }
}

#Call function 
Scan-IPRange | Receive-Job -Wait | Sort IP | Select IP, Hostname, FQDN 
