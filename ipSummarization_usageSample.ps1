


#This function can be called from powershell scripts by using the Import-Module command

Import-Module $PSScriptRoot\summarize_IP.psm1 -Force

<#the script needs to pass 4 variables
    -workdir [directory path]            ---> the directory where the script will write its temporary files. it needs read-write access into that directory
    -sourceFile [file path]              ---> the file containing a list of ip addresses, ip subnets in CIDR notation, or a list of ip ranges
                                              in the format [rangeStart]-[rangeEnd]. i.e. 10.1.2.1-10.1.2.100
    -batchsize [number]                  ---> to speed up processing the script splits the job into muliple batches. each child-job will contain a number
                                              of elements indicated here. default is 100
    -outputFilePath                      ---> file to write the summarized ip list
#>

#below a sample on running the function
SummarizeIPList -workdir C:\tmp -sourceFile C:\tmp\ipsummary.txt -batchsize 100 -outputFilePath C:\Cargill\tmp\output.txt


<# example of a sourceFile

1.1.2.79
1.8.73.245
1.8.69.113
1.8.75.0/24
1.8.76.1-10.8.76.255

#>

