function SummarizeIP

{

param (
        #address of file to summarize
        [Parameter(Mandatory = $false)]
        [String]$filepath

      

    )

$summarized = $null
$summarized=@()
$iplist =  New-Object Collections.Generic.List[String]


$iplisttmp = @(Get-Content $filepath)

$iplisttmp = @($iplisttmp | Sort-Object -Unique | ? {$_.trim() -ne "" })

$iplist.Clear()


for ($i=0; $i -lt $iplisttmp.Length; $i++)
{
    $iplist.Add($iplisttmp[$i])
}

for ($i=0; $i -lt $iplisttmp.Length; $i++)
{
 # first we'll examine if the range contains the network and broadcast addresses

               if ($iplist[$i] -match ".*\.0-")
               {
                    #we'll subnet to the master list
                    $split = $iplist[$i].Split("-")[0]
                    $iplist.Add($split)
                    
                    Write-host "added " $split "to the list, from range " $iplist[$i]

               }

               elseif ($iplist[$i] -match ".*-.*255$")
               {
                    #we'll subnet to the master list
                    $split = $iplist[$i].Split("-")[1]
                    $iplist.Add($split)
                    Write-Host "added" $split "to the list, from range " $iplist[$i]

               }

               
}

    

#before starting summarization we need to replace single ip address by their CIDR notation
#$subnet =  ConvertTo-Subnet -IPAddress $iplist[$i] -SubnetMask 32



for ($i=0; $i -lt $iplist.Count; $i++)

{
# echo "pass 1, progress: "($i/$iplist.Length).tostring("P")"converting the list to proper subnets for ingestion. converted " $iplist[$i] "to" $sbnt.ToString()
      
        if ($iplist[$i] -match "-")
                {

               Write-Host "Found range" $iplist[$i]
               #if a range is provided, we'll remove the range and add each ip in the range to the iplist 
               # this is attempt no1. if it doesn't work, will need to change this to ???

               #let's start
               #copy the range to a temporary variable
               $range = @($iplist[$i])
               
               # remove the range from iplist
            
               Write-Host "removing range from list" $iplist[$i]
                             
               $iplist.Remove($iplist[$i])
            
               # now we'll iterate on the range. 
               # i.e. 10.45.142.0-10.45.143.255

              


               # then we'll use the cidr-convert to give its best shot

               #correct should be
               # $tempCidr = $PSScriptRoot+"\cidr-convert\cidr-convert\cidr-convert.exe"
               #but to test we'll use below
               $tempCidr = "$PSScriptRoot\cidr-convert.exe"

               #now we'll throw this range to cidr-convert for its best shot, and receive results on $iplisttempcidr
               
               $iplisttempcidr = @($range | &$tempCidr)


               $myrangestoips =  New-Object Collections.Generic.List[String]
               for ($j=0; $j -lt $iplisttempcidr.Count; $j++)
               {
                 
                 
               #if the resulting subnet is /31 or /32, we don't need to mess with anything, just add the ip to the list

                if (($iplisttempcidr[$j] -like "/32") -or ($iplisttempcidr[$j] -like "/31"))
                {
                   $myrangestoips.Add(($iplisttempcidr[$j] -split "/")[0])
                }

                else
                {
                #else, some processing...

                  $ipaddressRange = ((ConvertTo-Subnet $iplisttempcidr[$i]).NetworkAddress.IPAddressToString)
                  $subnetmask = ((ConvertTo-Subnet $iplisttempcidr[$i]).SubnetMask.IPAddressToString)
                   
               #    (Get-NetworkRange -IPAddress $ipaddressRange -SubnetMask $subnetmask | Select-Object -Property IPAddressToString) | Foreach {"$($_.IPAddressToString)"}

               (Get-NetworkRange -IPAddress $ipaddressRange -SubnetMask $subnetmask | Select-Object -Property IPAddressToString) | Foreach {$myrangestoips.Add("$($_.IPAddressToString)")}

                }
               }

               #now, for each of these, we'll have to get a list of IP addresses



               #we just added all individual ips from that range into the master list

               $myrangestoips | Foreach {$iplist.Add($_)}

                }

        elseif ($iplist[$i] -match "/")
        {
        
        }
        elseif (($iplist[$i] -notmatch ".*\.0/32") -and ($iplist[$i] -notmatch ".*\.255/32"))
        {
        $sbnt = ConvertTo-Subnet -IPAddress $iplist[$i] -SubnetMask 32
        $iplist.Remove($iplist[$i])
        $iplist.Add($sbnt.ToString())
        
        }
}

#still need to strip the mask from any .0 or .255 on the list
<#
for ($i=0; $i -lt $iplist.Count; $i++)
{
    if (($iplist[$i] -match ".*\.0\/32") -or ($iplist[$i] -match ".*\.255\/32"))
    {
        $iplist.Remove($iplist[$i])
        $split = $iplist[$i].Split("/")[0]
        $iplist.Add($split)
        Write-Host "fixing exceptions"
    }
}
#>

Write-Host "Current number of lines is:"  $iplist.Count

#Write-Host $iplist

$cidrConvert = $PSScriptRoot+"\cidr-convert.exe"

$summarized = $iplist | &$cidrConvert

Write-Host "Summarized number of lines is:"  $summarized.Length



$summarized = $summarized | Select-Object -Unique

$summarized



}


