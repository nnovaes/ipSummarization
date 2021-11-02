#ipSummarization

* Docker based summarization of a list of IP addresses
* Based on [CIDR-Convert](https://github.com/flowchartsman/cidr-convert) and [Indented.Net.IP](https://github.com/indented-automation/Indented.Net.IP)

## Summarize

* Prepare the list to be summarized:
    - One entry per line
    - Supported formats are:
        - IP Address in CIDR notation (i.e. 192.168.1.1/32). If the network mask is not provided the script will automatically assume it is a /32
        - IP Address Range (i.e. 192.168.1.1-192.168.10.254)
        - IP Address Short-range (i.e. 192.168.1.10-20)

* Run the docker image, mapping the volume where the input/output will be located and the filename. The output will be the `filename_valid_<timestamp>.txt`for summarized addresses and `filename_invalid_<timestamp>.txt` for invalid addresses/entries. Example:
    `docker run -it -v <srcdir>:/summarize normannovaes/ipsum sample_ip_list_big.txt`

## Summarize with load distribution

If there's a need for distributing summarized IPs between load balanced nodes (you can't dynamically route traffic), then a summarization with load distribution can be achieved.

* Prepare the list to be summarized:
    - One entry per line
    - Each line contains a tuple of IP (in one of the supported formats below) and load. i.e. 
        ```
        95.174.66.69/32,62
        95.174.66.71/32,70
        95.174.66.73/32,39
        ```
    - Supported formats are:
        - IP Address in CIDR notation (i.e. 192.168.1.1/32). If the network mask is not provided the script will automatically assume it is a /32
        - IP Address Range (i.e. 192.168.1.1-192.168.10.254)
        - IP Address Short-range (i.e. 192.168.1.10-20)


* Run the docker image, mapping the volume where the input/output will be located and the filename. The output will be the `filename_valid_<timestamp>.txt`for summarized addresses and `filename_invalid_<timestamp>.txt` for invalid addresses/entries. You must past the number of nodes as an additional parameter (4 nodes in the example below). Example:
    `docker run -it -v <srcdir>:/summarize normannovaes/ipsum sample_ip_list_big_load.txt 4`