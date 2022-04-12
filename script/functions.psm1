

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

