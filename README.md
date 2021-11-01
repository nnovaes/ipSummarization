#ipSummarization

* Docker based summarization of a list of IP addresses
* Based on [CIDR-Convert](https://github.com/flowchartsman/cidr-convert) and [Indented.Net.IP](https://github.com/indented-automation/Indented.Net.IP)

## Usage

* Prepare the list to be summarized:
    - One enty per line
    - Supported formats are:
        - IP Address in CIDR notation (i.e. 192.168.1.1/32). If the network mask is not provided the script will automatically assume it is a /32
        - IP Address Range (i.e. 192.168.1.1-192.168.10.254)
        - IP Address Short-range (i.e. 192.168.1.10-20)

* Run the docker image, mapping the volume where the input/output will be located and the filename. The output will be the `filename_valid_<timestamp>.txt`for summarized addresses and `filename_invalid_<timestamp>.txt` for invalid addresses/entries. Example:
    
    `docker run -it -v <srcdir>:/summarize normannovaes/ipsum sample_ip_list_big.txt`