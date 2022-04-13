

function loadList {
    param (
        $path
    )

    $list = Get-Content $path
    [System.Collections.ArrayList]$loadedList = @()
    foreach ($line in $list)
    {
        if (($line.Split(",").Count) -eq 1)
        {
            #add with basic load
            $address = New-Object -TypeName PSObject -Property @{
                address = (Get-NetworkSummary $line).CIDRNotation
                load = 1
            }
        }
        else {
            #add with load
            $address = New-Object -TypeName PSObject -Property @{
                address = (Get-NetworkSummary ($line.split(",")[0])).CIDRNotation
                load = ($line.split(",")[1])
            }
        }
        $loadedList.Add($address) > $null
    }
    return $loadedList
}

function cidrConvert {
    param (
        [Parameter(Mandatory = $true)]
        $list
    )
    $list | Set-Content ./temp
    $summarized = (cat ./temp | /usr/bin/cidr-convert)
    try {rm ./temp}
    catch {}
    return $summarized
}





function convertRange {
    param (
        $ip
    )
    
    if ($ip.Split("-").Count -eq 0)
    {
        #not a range
        $convertedRange = $ip
    }
    elseif ($ip.Split("-")[1].Length -eq 3)
    {
        #short range
        $ip = convertShortRange $ip
        $convertedRange = Get-NetworkSummary (ConvertTo-Subnet -Start $ip.Split(",")[0] -End $ip.Split(",")[1]).NetworkAddress.IPAddressToString -SubnetMask (ConvertTo-Subnet -Start $ip.Split(",")[0] -End $ip.Split(",")[1]).SubnetMask.IPAddressToString
    }
    else {
        #long range
        $convertedRange = Get-NetworkSummary (ConvertTo-Subnet -Start $ip.Split(",")[0] -End $ip.Split(",")[1]).NetworkAddress.IPAddressToString -SubnetMask (ConvertTo-Subnet -Start $ip.Split(",")[0] -End $ip.Split(",")[1]).SubnetMask.IPAddressToString
    }
    return $convertedRange
}





function convertListRanges {
    param (
        $path
    )
}




# convert a short range format like 1.1.1.100-200 to 1.1.1.100-1.1.1.200
function convertShortRange {

    
    param (
        [Parameter(Mandatory = $true)]
        [String]$range
    )

    $range = $range.ToString().Trim()
    $rangeStart = $range.Split("-")[0]
    $rangeEnd = $range.Split("-")[0].Split(".")
    $rangeEnd = $rangeEnd[0]+"."+$rangeEnd[1]+"."+$rangeEnd[2]+"."+$range.Split("-")[1]
    Return $rangeStart+"-"+$rangeEnd
}




#validate if a given IP or range is an actual IP address
function validateIP {
    param (
        [Parameter(Mandatory = $true)]
        [String] $ip
    )

    try {
        $result = (Get-NetworkSummary $ip).CIDRNotation
        $rTest = $true
    }
    catch {
        $result = $ip
        $rTest = $false
    }
    return $rTest, $result
}



function validateRange {
    param (
        [Parameter(Mandatory = $true)]
        [String] $range
    )

    $rangeIPs = $range -split "-"
    $result1 = (validateIP -ip $rangeIPs[0])
    $result2 = (validateIP -ip $rangeIPs[1])
    $rTest = $result1[0] -and $result2[0]
    return $rTest,$range
}



#deduplicate list
function dedupList {
    
    param (
        [Parameter(Mandatory = $true)]
        $list
    )
    [System.Collections.ArrayList]$loadedList = @()
    foreach ($line in $list)
    {
        
            #add with basic load
            $address = New-Object -TypeName PSObject -Property @{
                address = (Get-NetworkSummary $line).CIDRNotation
                load = 1
            }
            $loadedList.Add($address) > $null
    }

    $loadedList = $loadedList | Sort-Object -Unique -Property address
    return $loadedList | foreach {$_.address}
}




function processIPList {
    param (
        [Parameter(Mandatory = $true)]
        $list
    )
    [System.Collections.ArrayList]$ipList= @()
    [System.Collections.ArrayList]$ipListInvalid= @()

    # start by deduplicating the list
    $deduList = dedupList -list $list

    #if address is a range, convert short ranges
    foreach ($address in $deduList) {
        if ($address -match ".*-.*")
        {
            $address = (convertShortRange -range $address)
        }
    }

    foreach ($ip in $deduList)
    {
        if ($ip -match ".*-.*")
        {
            $test = validateRange $ip
        }
        else {
            $test = validateIP -ip $ip
        }
        
        if ($test[0] -eq $false) {
            $ipList.Add($ip) > $null
        }
        else {
            $ipListInvalid.Add($ip) > $null
        }
    }

    foreach ($ipa in $dedulist)
    {
        $ipa = (Get-NetworkSummary $address).CIDRNotation
    }

    return $ipList,$ipListInvalid
}

function extractIPs {

    param (
        $subject,
        $object,
        $list
    )
    $list = processIPList $list
    [System.Collections.ArrayList]$originalList = @()

    $subject = (Get-NetworkSummary $subject).CIDRNotation
    $object = (Get-NetworkSummary $object).CIDRNotation

    foreach ($line in $list)
    {
        $originalList.Add($line) > $null
    }

    [System.Collections.ArrayList]$finalList = @()
    $test = Test-SubnetMember -SubjectIPAddress $subject -ObjectIPAddress $object


    if ($test -eq $True)
        {
        #list all hosts of subjectIP
        $list_subjHosts = Get-NetworkRange $subject | Select-Object -Property IPAddressToString
        $list_objHosts = Get-NetworkRange $object | Select-Object -Property IPAddressToString

        #rebuild lists as new array
        [System.Collections.ArrayList]$subjHosts= @()
        foreach ($sub in $list_subjHosts)
        {
            $subjHosts.Add($sub.IPAddressToString) > $null
        }
        [System.Collections.ArrayList]$objHosts= @()
        foreach ($obj in $list_objHosts)
        {
            $objHosts.Add($obj.IPAddressToString) > $null
        }

        #remove #subj from #obj
        foreach ($sub in $subjHosts)
        {
        $objHosts.RemoveAt($objHosts.IndexOf($sub))
        }

        $objHosts = $objHosts | ./cidr-convert/cidr-convert

        $finalList = $objHosts
        $finalList.Add($subject) > $null
        $originalList.RemoveAt($originalList.IndexOf($subject))
        $originalList.RemoveAt($originalList.IndexOf($object))
        foreach ($line in $finalList)
        {
            $originalList.Add($line) > $null
        }

    }

    else {
        $originalList = $list
    }

    return $originalList

}

function scanExtraction {
    param (
        $list
    )
    [System.Collections.ArrayList]$longList= @()
    foreach ($subj in $list)
    {
        Write-Host "checking" $line
        foreach ($obj in $list)
        {
            if ($obj -ne $subj) {
            Write-Host "against" $obj
            $extractedList = extractIPs -subject $subj -object $obj -list $list
                foreach ($extracted in $extractedList)
                {
                    $longList.Add($extracted) > $null
                }
            }
            
        }
    }
}



function splitSubnetEvenly {
    param (
        $cidr,
        $nodes,
        $load,
        $sort
            )

   
    $currentMask = [Int]($cidr -split "\/")[1]
    $subnet = ($cidr -split "\/")[0]
    $masks = @($currentMask..32)

    $subnetList = @{}
    foreach ($mask in $masks)
    {
        if ($mask -ge $currentMask)
        {
            $hosts = [Int]((Get-NetworkSummary ($subnet+"/"+$mask)).NumberOfHosts)
            $summary = Get-NetworkSummary ($subnet+"/"+$mask)
            try {
                $subnetList.Add($hosts,$summary)
            }
            catch {}
        }
    }

    $totalHosts = (Get-NetworkSummary $cidr).NumberOfHosts
    $hostsPerNode = [math]::floor($totalHosts/$nodes)

    $newMask = $currentMask
   
   for ($i=0; $i -lt $masks.Count; $i++)
   {
       $analyze = Get-NetworkSummary ($subnet+"/"+$masks[$i])
       #Write-Host ($analyze.NumberOfHosts+2) "vs" ($hostsPerNode) "for " $masks[$i]
       if ($analyze.NumberOfHosts+2 -lt $hostsPerNode )
       {
           $newMask = $masks[$i]
           break
       }
       
   }

   $newSubnets = Get-Subnet $cidr -NewSubnetMask $newMask
   $newLoad = [math]::ceiling($load/$newSubnets.Count)
    [System.Collections.ArrayList]$splitSubnets= @()
   foreach ($item in $newSubnets) {
                $newitem = New-Object -TypeName PSObject -Property @{
                    address = (Get-NetworkSummary $item).CIDRNotation
                    load = $newLoad
                    hosts = (Get-NetworkSummary $item).NumberOfAddresses
                    sort = (Get-NetworkSummary $item).NetworkDecimal
                }
                $splitSubnets.Add($newitem) > $null
            }
    return $splitSubnets

}


function findIndex {
    param (
        $weightedLoad,
        $limit,
        $currentLoad
    )


    for ($i=0; $i -lt $weightedLoad.count; $i++)
    {
        if ($currentLoad+$weightedLoad[$i] -le $limit)
        {
            $result = $i
            break;
        }
        elseif ($i -eq $weightedLoad.count-1)
        {
            $result = $i
            break;
        }
        else {
        }
    }
    return $result
}

function splitNodes {
    param (
        $addList,
        $nodes
    )

 
    [System.Collections.ArrayList]$localList= @()

    foreach ($entry in $addList)
    {
        $localList.Add($entry) > $null
    }
   
#    $nodes = $nodeCount

    $totalLoad = ($localList | Measure-Object -Property weightedLoad -Sum).Sum
    $loadPerNode = [math]::ceiling($totalLoad/$nodes)
  

   
    $nodeList = @{}
    for ($i=0; $i -lt $nodes; $i++)
    {
    Write-Host "working on node_"+$i
    $thisNode = New-Object -TypeName PSObject -Property @{
            'load' = 0
            'weightedLoad' = 0
            'addresses' =  New-Object -TypeName 'System.Collections.ArrayList'
            'nodeName'= "node_"+$i
             
        }

        while ($thisNode.weightedLoad -le $loadPerNode -and $localList.count -gt 0)
        {
          
            if (($thisNode.weightedLoad+$localList.Item(0).load) -lt $loadPerNode)
            {
                $thisNode.addresses.Add($localList.Item(0)) > $null
                $thisNode.weightedLoad = $thisNode.weightedLoad+$localList.Item(0).weightedLoad
                $thisNode.load = $thisNode.load+$localList.Item(0).load
                $localList.Remove($localList.Item(0))
            }
            else
            {
            Write-Host "current load is" $thisNode.load "and " $localList.Item(0).address "of weightedLoad " $localList.Item(0).weightedLoad "would go beyond the " $loadPerNode "limit. Finding alternative"
            $index = findIndex -weightedLoad ($localList | foreach {$_.weightedLoad}) -limit $loadPerNode -currentLoad $thisNode.weightedLoad
            Write-Host "alternative found: "$localList.Item($index).address "with weightedLoad of " $localList.Item($index).weightedLoad
            $thisNode.addresses.Add($localList.Item($index)) > $null
            $thisNode.weightedLoad = $thisNode.weightedLoad+$localList.Item($index).weightedLoad
            $thisNode.load = $thisNode.load+$localList.Item($index).load
            $localList.Remove($localList.Item($index))
            }
        
        }
    
    

   
    $nodeList.add($thisNode.nodename,$thisNode)    
    }

    foreach ($nodeKey in $nodeList.Keys)
    {
       $nodeList[$nodeKey] | Add-Member -NotePropertyName "plain_addresses" -NotePropertyValue ($nodeList[$nodeKey].addresses | Select-Object address | foreach {$_.address}) -Force
       Write-Host "summarizing subnets for" $nodeKey
       $nodeList[$nodeKey] | Add-Member -NotePropertyName "summarized" -NotePropertyValue (cidrConvert -list ($nodeList[$nodeKey].plain_addresses))
    }

    return $nodeList

}
