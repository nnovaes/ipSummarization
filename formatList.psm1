
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

}

#convert .0 addresses to their subnet addresses
function zeroToSubnet {
    param (
        [Parameter(Mandatory = $true)]
        [String]$cidr
    )
    $cidr = $cidr.ToString().Trim()
    $cidr = $cidr.Split("/")[0]
    $cidr = $cidr -Split "\." 
    $cidr.Length
    $cidr
    $sub = 32
    if ($cidr[3] -eq "0") {
   
        $sub = $sub - 8
        if ($cidr[2] -eq "0") {
            
            $sub = $sub - 8
            if ($cidr[1] -eq "0") {
          
                $sub = $sub -8
            }
        }
    }
    return ($cidr -join ".")+"/"+$sub

}

#convert .255 addresses to their subnet addresses
function 255ToSubnet {

}

#deduplicate list
function dedupIP {

}

#sort list
function sortIP {

}