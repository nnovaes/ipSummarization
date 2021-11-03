

function cidrConvert {
    param (
        [Parameter(Mandatory = $true)]
        $list
    )
    $list | Set-Content ./temp
    $summarized = (cat ./temp | ./cidr-convert/cidr-convert)
    try {rm ./temp}
    catch {}
    return $summarized
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
    $list = $list | Sort-Object -Unique
    return $list
}

function processIPList {
    param (
        [Parameter(Mandatory = $true)]
        $list
    )
    [System.Collections.ArrayList]$ipList= @()
    [System.Collections.ArrayList]$ipListInvalid= @()
    $deduList = dedupList -list $list
    foreach ($address in $deduList) {
        if ($address -match ".*-.*")
        {
            $address = (convertShortRange -range $address)
        }
        else {
            if ($address -notmatch ".*/[0-9][0-9]")
            {
                $address = $address + "/32"
            }
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

    return $ipList,$ipListInvalid
}

#extract address from range
function extractIP {
    param (
        [Parameter(Mandatory = $true)]
        [String] $extract,

        [Parameter(Mandatory = $true)]
        [String] $network
    )


    $extractLoad = $extract.Split(",")[1]
    $networkLoad = $network.Split(",")[1]

    $extract = $extract.Split(",")[0]
    $network = $network.Split(",")[0]

    $extract = Get-NetworkSummary $extract
    $network = Get-NetworkSummary $network

    $extract = Get-NetworkRange $extract.CIDRNotation # this will hold all hosts to be removed from the network
    $network = Get-NetworkRange $network.CIDRNotation # this will hold all hosts in the network
    

    foreach ($address in $network)
    {
        if ($extract -contains $address)
        {
            $address | Add-Member -NotePropertyName exclude -NotePropertyValue $true -Force
        }
        else {
            $address | Add-Member -NotePropertyName exclude -NotePropertyValue $false -Force
        }
    }

    $newNetwork = $network | Where-Object {$_.exclude -eq $false}
    $newNetwork = $newNetwork | Select-Object -Property "IPAddressToString" 
    $newNetwork = $newNetwork | Select-Object -First 100
    rm ./temp
    foreach ($item in $newNetwork) {
        $item.IPAddressToString | Add-Content ./temp
    }
    $newNetwork = Get-Content ./temp
    rm ./temp
    
    $newNetwork = cidrConvert $newNetwork

    #addBackLoad
    for ($i=0; $i -lt $newNetwork.Count; $i++)
    {
        $newNetwork[$i] = $newNetwork[$i]+","+$networkLoad
    }

    return $newNetwork

}

function extractionNeeded {
    # determine if extraction is neded
    param (
        [Parameter(Mandatory = $true)]
        $list
    )
    $list = Get-Content ./examples/sample_ip_list_extract.txt
   
    for ($i=0; $i -lt $list.Count; $i++)
    {
        for ($j=0; $j -lt $list.Count; $j++)
        {
            $compare = ($list[$i].extraction -or (Test-SubnetMember -SubjectIPAddress $list[$i] -ObjectIPAddress $list[$j])) -and ($list[$i] -ne $list[$j])
            Write-Host $compare , $list[$i], $list[$j]
            $list[$i] | Add-Member -NotePropertyName "extraction" -NotePropertyValue ($compare) -Force
        }
        
    }
}