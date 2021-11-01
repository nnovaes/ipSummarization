Import-Module /script/functions.psm1

if ($args[1] -gt 0)
{
#with load
#$in = Import-Csv ("/summarize/"+$args[0])
$in = Import-Csv ./sample_ip_list_load.txt
$in = $in | Sort-Object -Property "address"
#$nodes = $args[1]
$nodeCount = 4
$totalLoad = ($in | Measure-Object -Property load -Sum).Sum
$loadPerNode = [math]::floor($totalLoad / $nodeCount)
[System.Collections.ArrayList]$nodeList= @()
$item = 0
for ($i=0; $i -lt $nodesCount; $i++)
    {
        $nodeList.Add("node_"+$i) > $null
    }
for ($i=0; $i -lt $nodeList.Count; $i++) 
    {
        $thisNodeLoad = 0
        [System.Collections.ArrayList]$thisNode = @()
        while ($thisNodeLoad -lt $loadPerNode)
        {
            $thisNode.Add($in[$item].address) > $null
            $thisNodeLoad = $thisNodeLoad + $in[$item].load
            
        }
        Write-Host $thisNode
        
    }


}
elseif ($args[1] -eq 0)
{
    Write-Host "number of nodes can't be zero"
}
else {
#without load
$in = Get-Content ("/summarize/"+$args[0])
$list = (processIPList -list $in)
$valid = $list[1]
$invalid = $list[0]
$date = (Get-Date -Format "MM-dd-yy_hhmmss").ToString()
$outPathValid = ("/summarize/"+$args[0].Split(".")[0]+"_summarized_"+$date+".txt")
$outPathInvalid = ("/summarize/"+$args[0].Split(".")[0]+"_invalid_"+$date+".txt")
$invalid | Set-Content $outPathInvalid
cidrConvert -list $valid | Set-Content $outPathValid

}
