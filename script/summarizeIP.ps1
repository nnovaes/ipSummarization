Import-Module ./script/functions.psm1 -Force

if ($args[1] -gt 0)
{
    #with load
    $in = Import-Csv ("./data/"+$args[0])
    #$in = Import-Csv ./sample_ip_list_big_load.txt
    $in = $in | Sort-Object -Property "address" -Unique
    
    #convert list to ips
    [System.Collections.ArrayList]$inputList= @()
    [System.Collections.ArrayList]$invalidList= @()
    foreach ($line in $in)
    {
        if ($line.address -match ".*-.*")
        {
            #convert
            $converted = $line.address | cidr-convert
            foreach ($item in $converted) {
                $newitem = New-Object -TypeName PSObject -Property @{
                    address = (Get-NetworkSummary $item).CIDRNotation
                    load = $line.load/$converted.Count
                    hosts = (Get-NetworkSummary $item).NumberOfAddresses
                }
                $inputList.Add($newitem) > $null
            }
        }
        else {
            #add
            try {
            $newitem = New-Object -TypeName PSObject -Property @{
                address = (Get-NetworkSummary $line.address).CIDRNotation
                load = $line.load
                hosts = (Get-NetworkSummary $line.address).NumberOfAddresses
            }
                $inputList.Add($newitem) > $null
        
            }

            catch {
                $invalidList.Add($line) > $null
            }
            
        }
    }

    #calc load x hosts
    foreach ($address in $inputList)
    {
        $address | Add-Member -NotePropertyName "pload" -NotePropertyValue ($address.load*$address.hosts) -Force
    }




    $nodeCount = $args[1]
    $totalLoad = ($inputList | Measure-Object -Property pload -Sum).Sum
    $loadPerNode = [math]::floor($totalLoad / $nodeCount)
    if ($loadPerNode -lt ($inputList | Measure-Object -Property pload -Maximum).Maximum)
    {
        $loadPerNode = ($inputList | Measure-Object -Property pload -Maximum).Maximum
    }

        #copy input list, need to copy item by item otherwise inputlist is emptied
        [System.Collections.ArrayList]$addList= @()
        foreach($ilitem in $inputList)
        {
            $addList.add($ilitem) > $null
        }

    [System.Collections.ArrayList]$nodeList= @()
    #buildNewNodes
    for ($i=0; $i -lt $nodeCount; $i++)
    {

        [System.Collections.ArrayList]$thisNodeAddresses= @()
        $thisNode = New-Object -TypeName PSObject -Property @{
            'load' = 0
            'addresses' = $null
            'nodeName'= "node_"+$i      
        }
        while ($thisNode.load -lt $loadPerNode -and $addList.Count -gt 0)
        {
            $thisNodeAddresses.Add($addList[0].address) > $null
            $thisNode.load = $thisNode.load + $addList[0].pload
            $addList.RemoveAt(0)
        }
        $thisNode.addresses = $thisNodeAddresses
        $nodeList.Add($thisNode) > $null
    }

    #summarize
    foreach ($node in $nodeList)
    {
        $node | Add-Member -NotePropertyName summarized -NotePropertyValue (cidrConvert -list $node.addresses) -Force
    }

    #export
    $date = (Get-Date -Format "MM-dd-yy_hhmmss").ToString()
    foreach ($node in $nodeList)
    {
        $path = "/summarize/"+$node.nodeName+"_"+$date+".txt"
        try {rm $path}
        catch {}
        "node: "+$node.nodeName | Add-Content $path
        "load: "+$node.load | Add-Content $path
        "count of addresses: "+$node.addresses.Count | Add-Content $path
        "count of summarized addresses: "+$node.summarized.Count | Add-Content $path
        " " | Add-Content $path
        "ORIGINAL ADDRESSES: " | Add-Content $path
        foreach ($addr in $node.addresses) {
            $addr | Add-Content $path
        }
        " " | Add-Content $path
        "SUMMARIZED: " | Add-Content $path
        foreach ($summ in $node.summarized) {
            $summ | Add-Content $path
        }
    }
    
}

elseif ($args[1] -eq 0)
{
    Write-Host "number of nodes can't be zero"
}
else {
#without load
$in = Get-Content ("./data/"+$args[0])
$list = (processIPList -list $in)
$valid = $list[1]
$invalid = $list[0]
$date = (Get-Date -Format "MM-dd-yy_hhmmss").ToString()
$outPathValid = ("./data/"+$args[0].Split(".")[0]+"_summarized_"+$date+".txt")
$outPathInvalid = ("./data/"+$args[0].Split(".")[0]+"_invalid_"+$date+".txt")
$invalid | Set-Content $outPathInvalid
cidrConvert -list $valid | Set-Content $outPathValid

}
