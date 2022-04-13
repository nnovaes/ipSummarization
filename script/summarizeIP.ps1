Import-Module ./script/functions.psm1 -Force

if ($args[2] -eq "--cleanup")
{
    Remove-Item "./data/*.list"
}

if ($args[1] -gt 0)
{
    #with load
    Write-Host "import original list"
    $import = Import-Csv ("./data/"+$args[0]) #| sort address 
    $nodeCount = $args[1]
   # $import = Import-Csv ./data/sample_ip_list_load.txt
   # $nodeCount = 4
   
    #$import = Sort-Object -Property 'address'
    
    

    # $listhash = $null
    # $listhash = @{}
    # foreach ($line in $import)
    # {
    #     if ($listhash[$line.Address] -eq $null)
    #     {
    #        # Write-Host "Adding " $line.Address
    #         $listhash.Add($line.Address,$line)
    #     }
    #     else 
    #     {
    #        # Write-Host "Merging " $line.Address "previous load of " $listhash[$line.Address].load "with load " $line.load
    #         $lineload = [Int]$listhash[$line.Address].load+[Int]$line.load
    #         $listhash[$line.Address].load = $lineload
    #     }
    # }

    #$in = $listhash.Values
    $in = $import

    
    #convert list to ips
    Write-Host "Converting to IPs"
    [System.Collections.ArrayList]$inputList= @()
    [System.Collections.ArrayList]$invalidList= @()
    foreach ($line in $in)
    {
        Write-Host "Converting " $line
        if ($line.address -match ".*-.*")
        {
            #convert
            $converted = $line.address | /usr/bin/cidr-convert
            foreach ($item in $converted) {
                $newitem = New-Object -TypeName PSObject -Property @{
                    address = (Get-NetworkSummary $item).CIDRNotation
                    load = [Int]($line.load/$converted.Count)
                    hosts = (Get-NetworkSummary $item).NumberOfAddresses
                    sort = (Get-NetworkSummary $item).NetworkDecimal
                }
                $inputList.Add($newitem) > $null
            }
        }
        else {
            #add
            try {
            $newitem = New-Object -TypeName PSObject -Property @{
                address = (Get-NetworkSummary $line.address).CIDRNotation
                load = [Int]($line.load)
                hosts = (Get-NetworkSummary $line.address).NumberOfAddresses
                sort = (Get-NetworkSummary $line.address).NetworkDecimal
            }
                $inputList.Add($newitem) > $null
        
            }

            catch {
                $invalidList.Add($line) > $null
                Write-Host "invalid ip found: " $line
            }
            
        }
    }
    $inputList = $inputList | Sort-Object -Property 'sort'
 

    [System.Collections.ArrayList]$splitList= @()
    
    foreach ($address in $inputList)
    {
        Write-Host "splitting " $address "evenly among nodes"
        $splitSubnets = splitSubnetEvenly -cidr $address.Address -nodes $nodeCount -load $address.load 
        $splitList = $splitList + $splitSubnets
    }

    $inputList = $splitList | Sort-Object -Property 'sort'

    #calc load x hosts
    foreach ($address in $inputList)
    {
        Write-Host "calculating weighted loads for" $address
        $address | Add-Member -NotePropertyName "weightedLoad" -NotePropertyValue ([Int]$address.load*[Int]$address.hosts) -Force
    }






    #copy input list, need to copy item by item otherwise inputlist is emptied
    [System.Collections.ArrayList]$addList= @()
    $addIndex = @{}
    foreach($ilitem in $inputList)
    {
            Write-Host "adding" $ilitem.address "to master list"
        if ($addIndex[$ilitem.address] -eq $null)
        {
        $addList.add($ilitem) > $null
        $addIndex.Add($ilitem.address,($addList.Count-1))
        }
        else {

            Write-Host $ilitem.address "duplicate found, searching index"
            $index = $addIndex[$ilitem.address]
            Write-Host "duplicate found, updating index for" $ilitem.address
            $addList[$index].load = $addList[$index].load+$ilitem.load
            $addList[$index].weightedLoad = $addList[$index].weightedLoad+$ilitem.weightedLoad

            # for ($i=0; $i -lt $addList.count; $i++)
            # {
            #     if ($ilitem.address -eq $addList[$i].address)
            #     {
            #             $addList[$i].load = $addList[$i].load+$ilitem.load
            #             $addList[$i].weightedLoad = $addList[$i].weightedLoad+$ilitem.weightedLoad
            #     }
            #     else 
            #     {

            #     }
            # }

      
        }
        
    }

    $addList = $addList | Sort-Object -Property 'sort'

    $nodeList = splitNodes -addList $addList -nodes $nodeCount


    #exports
    $date = (Get-Date -Format "MM-dd-yy_hhmmss").ToString()
    
    ## original

    $path = "./data/"+$date+".original.list"
    $import | Export-Csv -Path ($path)
    (gc ($path)) | % {$_ -replace '"', ''} | out-file ($path) -Fo -En ascii

    # node summary
    $path = "./data/"+$date
    $nodeList.Values | Select-Object -Property nodeName,load,weightedLoad | ConvertTo-Json | Set-Content ($path+".results.json")

    # node summary
    $path = "./data/"+$date
    $nodeList.Values  | ConvertTo-Json -Depth 10 | Set-Content ($path+".json")


    foreach ($key in $nodeList.Keys)
    {
        $path = "./data/"+$date+"."+$nodeList[$key].nodeName
        $nodeList[$key].addresses | Select-Object -Property address,load,hosts,weightedLoad | Export-Csv tmp.txt
         (gc ("tmp.txt")) | % {$_ -replace '"', ''} | Add-Content ($path+".addresses.list")
        rm tmp.txt
    }


    foreach ($key in $nodeList.Keys)
    {
        $path = "./data/"+$date+"."+$nodeList[$key].nodeName
        foreach ($addr in $nodeList[$key].summarized)
        {
            $addr | Add-Content ($path+".summarized.list")
        }
    }

    $outPathInvalid = ("./data/"+$date+".invalid.list")
    $invalidList | Set-Content $outPathInvalid

    
    
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
