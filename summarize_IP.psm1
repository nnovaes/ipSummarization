Import-Module $PSScriptRoot\ipSummarization.psm1 -Force

function SummarizeIPList {

param (
        #workdir (temp folder to read/write files. if none are provided the script will use C:\Cargill\tmp)
        [Parameter(Mandatory = $true)]
        [String]$workdirectory,

       #address of file to summarize. if no file is provided the script will use the test array and create a file called ipsummary.pip at C:\Cargill\tmp
        [Parameter(Mandatory = $true)]
        [String]$sourceFile,
        
        [Parameter(Mandatory = $true)]
        [String]$batchsize,

         [Parameter(Mandatory = $true)]
        [String]$outputFilePath
        

    )


$workdir = $workdirectory

$file = $sourceFile

rm $workdir\*.tip #cleanup workdir of temporary files

#import work file
$workarray.Clear()
$workarray = Get-Content $file
$workarray = $workarray |  ? {$_.trim() -ne "" }
$initcount = $workarray.Count

#we'll spend a little time sorting and deduplicating this list since we want the batches to be with close ip addreses
#Write-Host "start list contains " $workarray.Count " elements"
Write-Host "sorting list"
$workarray = $workarray | Sort-Object
Write-Host "finished sorting"
Write-Host "started deduplication"
$workarray | Get-Unique |   Set-Content -Path $workdir\workarray.tip
Write-Host "finished deduplication"
#echo "deduplicated list contains " $workarray.Count " elements"

#this variable will tell how many elements per batch should be processed

$elementsPerBatch = 10 #this also needs to change to 100 after testing
if (($batchsize -as [int]) -gt $elementsPerBatch)

{
    $elementsPerBatch = $batchsize -as [int]
}

else
{
}




#calculate how many batches we'll need. change this to 100 when done
$nA = ($workarray.Length/$elementsPerBatch)-($workarray.Length%$elementsPerBatch)/$elementsPerBatch 
if (($workarray.Length%$elementsPerBatch)/$elementsPerBatch -gt 0)
{
$nA = $nA+1
}

Write-Host $nA "jobs to process"

#now we'll write the temporary files
$ipmasterlist = New-Object Collections.Generic.List[String]


for ($i=0; $i -lt ($workarray.Length); $i++)

{
    $ipmasterlist.Add($workarray[$i])
}


for ($i=0; $i -lt ($nA); $i++)

{

    $ipmasterlist | Select-Object -First $elementsPerBatch | Set-Content -Path $workdir\iplist_"$i".tip
   # echo "created " $workdir\iplist_"$i".tip
    $ipmasterlist.RemoveRange(0,$elementsPerBatch)
   # echo "removed elements"

}


#now we know we'll run $nA jobs... indexes ranging from 0 to $nA-1

#time the jobs started
$jobStart = Get-Date #this marks the time these jobs started

Write-Host "Starting intermediate jobs"

for ($i=0; $i -lt ($nA); $i++)

{

 Start-Job { param($f,$module) Import-Module $module -Force; SummarizeIP -filepath $f; Start-Sleep 1  } -Arg ("$workdir\iplist_$i.tip","$PSScriptRoot\ipSummarization.psm1") | Wait-Job

}


#remove the include child job later...
Get-Job -After $jobStart -IncludeChildJob
Get-Job -After $jobStart | Wait-Job





$jobresults = Get-Job -After $jobStart | Wait-Job


#new list for final summarize
$prefinalList = New-Object Collections.Generic.List[String]

foreach ($job in $jobresults)
{
    $receivedJob = Receive-Job -Id $job.Id  | Where-Object {$_ -Like "*.*/*"}
  #  echo "received:"
  #  echo $receivedJob
    foreach ($rjob in $receivedJob)
    {
 #   echo "adding to final list: " $rjob
    $prefinalList.Add($rjob)
    }

}

Get-Job -After $jobStart | Remove-Job

 $prefinalList | Sort | Unique  | Set-Content -Path $workdir\prefinalList.tip

Write-Host "intermediary list contains " ($prefinalList | Sort | Unique).Count


Write-Host "Finished intermediate jobs. Starting to work on final list"

$filestamp = (Get-Date -Format "MMMddyyyy_hhmmss")
SummarizeIP -filepath $workdir\prefinalList.tip | Where-Object {$_ -Like "*.*/*"} | Set-Content $workdir\finallist_"$filestamp".pip

$finalsummary = Get-Content $workdir\finallist_"$filestamp".pip

rm $outputFilePath
cp $workdir\finallist_"$filestamp".pip $outputFilePath

$fincount = $finalsummary.Count

Write-Host "started with " $initcount ", finished with " $fincount ", reduction of " (1-($fincount/$initcount)).ToString(“P”)

    if ((1-($fincount/$initcount) -lt 0))

    {
        Write-Host "hit known issue to calculate summarization % when ranges (i.e. 10.22.88.0-10.22.88.255)  are provided. list still good and summarized"
    

    }

}