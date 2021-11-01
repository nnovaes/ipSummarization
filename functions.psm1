

function cidrConvert {
    param (
        [Parameter(Mandatory = $true)]
        $list
    )
    $list | Set-Content ./temp
    $summarized = (cat ./temp | cidr-convert)
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