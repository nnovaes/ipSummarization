Import-Module /script/functions.psm1
$in = Get-Content ("/summarize/"+$args[0])
$list = (processIPList -list $in)
$valid = $list[1]
$invalid = $list[0]
$date = (Get-Date -Format "MM-dd-yy_hhmmss").ToString()
$outPathValid = ("/summarize/"+$args[0].Split(".")[0]+"_summarized_"+$date+".txt")
$outPathInvalid = ("/summarize/"+$args[0].Split(".")[0]+"_invalid_"+$date+".txt")
$invalid | Set-Content $outPathInvalid
$valid | Set-Content ./temp
$valid = cat ./temp | cidr-convert
rm ./temp
$valid | Set-Content $outPathValid