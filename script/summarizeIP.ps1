Import-Module ./script/functions.psm1 -Force

if ($args[2] -eq "--cleanup")
{
    Remove-Item "./data/*.list"
}

if ($args[1] -gt 0)
{
    #with load
    $import = Import-Csv ("./data/"+$args[0])
    $import = Sort-Object -Property 'address'
    #$import = Import-Csv ./sample_ip_list_big_load.txt
    

    $listhash = $null
    $listhash = @{}
    foreach ($line in $import)
    {
        if ($listhash[$line.Address] -eq $null)
        {
            Write-Host "Adding " $line.Address
            $listhash.Add($line.Address,$line)
        }
        else 
        {
            Write-Host "Merging " $line.Address "previous load of " $listhash[$line.Address].load "with load " $line.load
            $lineload = [Int]$listhash[$line.Address].load+[Int]$line.load
            $listhash[$line.Address].load = $lineload
        }
    }

    $in = $listhash.Values
    #$in = $import

    
    #convert list to ips
    [System.Collections.ArrayList]$inputList= @()
    [System.Collections.ArrayList]$invalidList= @()
    foreach ($line in $in)
    {
        if ($line.address -match ".*-.*")
        {
            #convert
            $converted = $line.address | /usr/bin/cidr-convert
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
        [System.Collections.ArrayList]$thisNodeAddressesWithLoad= @()
        $thisNode = New-Object -TypeName PSObject -Property @{
            'load' = 0
            'addresses' = $null
            'nodeName'= "node_"+$i
            'addressesWithLoad' = $null      
        }
        while ($thisNode.load -lt $loadPerNode -and $addList.Count -gt 0)
        {
            $thisNodeAddresses.Add($addList[0].address) > $null
            $thisNodeAddressesWithLoad.Add($addList[0]) > $null
            $thisNode.load = $thisNode.load + $addList[0].pload
            $addList.RemoveAt(0)
        }
        $thisNode.addresses = $thisNodeAddresses
        $thisNode.addressesWithLoad = $thisNodeAddressesWithLoad
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
        $path1 = "/summarize/data/"+$node.nodeName+"_"+$date
        try {
            Remove-Item $path -ErrorAction Stop
            }
        catch {

        }
        $path = $path1+".results.list"
        "node: "+$node.nodeName | Add-Content $path
        "load: "+$node.load | Add-Content $path
        "count of addresses: "+$node.addresses.Count | Add-Content $path
        "count of summarized addresses: "+$node.summarized.Count | Add-Content $path
        " " | Add-Content $path
        $path = $path1+".original.list"
        "ORIGINAL ADDRESSES: " | Add-Content $path
        foreach ($addr in $node.addresses) {
            $addr | Add-Content $path
        }
        " " | Add-Content $path
        $path = $path1+".loads.list"
        "ORIGINAL LOADS: " | Add-Content $path
        "address,initial_load,hosts,weightedLoad" | Add-Content $path
        foreach ($addr in $node.addressesWithLoad) {
            $addr.address+","+$addr.load+","+$addr.hosts+","+$addr.pload | Add-Content $path
        }
        " " | Add-Content $path
        $path = $path1+".summarized"
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
$outPathValid = ("./data/"+$args[0].Split(".")[0]+"_summarized_"+$date+".list")
$outPathInvalid = ("./data/"+$args[0].Split(".")[0]+"_invalid_"+$date+".list")
$invalid | Set-Content $outPathInvalid
cidrConvert -list $valid | Set-Content $outPathValid

}
