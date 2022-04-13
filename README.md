#ipSummarization


* Docker based summarization of a list of IP addresses
* Based on [CIDR-Convert](https://github.com/flowchartsman/cidr-convert) and [Indented.Net.IP](https://github.com/indented-automation/Indented.Net.IP)

## Simple summarization

* Prepare the list to be summarized:
    - One entry per line
    - Supported formats are:
        - IP Address in CIDR notation (i.e. 192.168.1.1/32). If the network mask is not provided the script will automatically assume it is a /32
        - IP Address Range (i.e. 192.168.1.1-192.168.10.254)
        - IP Address Short-range (i.e. 192.168.1.10-20)

* Run the docker image, mapping the volume where the input/output will be located and the filename. The output will be the `filename_valid_<timestamp>.txt`for summarized addresses and `filename_invalid_<timestamp>.txt` for invalid addresses/entries. Example:
    `docker run -it -v <srcdir>:/summarize/data normannovaes/ipsum sample_ip_list_big.txt`

## Summarize with load distribution

If there's a need for distributing summarized IPs between load balanced nodes (you can't dynamically route traffic), then a summarization with load distribution can be achieved.

* Prepare the list to be summarized:
    - One entry per line
    - First line contains the headers `address,load`
    - Each subsequent line contains a tuple of IP (in one of the supported formats below) and load. i.e. 
        ```
        95.174.66.69/32,62
        95.174.66.71/32,70
        95.174.66.73/32,39
        ```
    - If the list contains duplicates, their loads will be summed. i.e.
    ```
        95.174.66.69/32,60
        95.174.66.69/32,60
    ```

    is the same as

    ```
        95.174.66.69/32,110
    ```


    - Supported formats are:
        - IP Address in CIDR notation (i.e. 192.168.1.1/32). If the network mask is not provided the script will automatically assume it is a /32
        - IP Address Range (i.e. 192.168.1.1-192.168.10.254)
        - IP Address Short-range (i.e. 192.168.1.10-20)



* Run the docker image, mapping the volume where the input/output will be located to `/summarize/data` and provind the filename as an argument, alongside with the load. 

### Sample utilization commands

* `docker run -it -v $PWD/mydata:/summarize/data normannovaes/ipsum sample_ip_list_load.txt 4`
    - Map the input/output dir to `$PWD/mydata`, loads the file `sample_ip_list_load.txt` and set the number of nodes to `4`
*  `docker run -it -v $PWD/mydata:/summarize/data normannovaes/ipsum sample_ip_list_load.txt 4 --cleanup`
    - Same command as before, but cleans the working directory of any .list files
* `docker run -it -v $PWD/examples:/summarize/data -v $PWD/script:/summarize/script normannovaes/ipsum sample_ip_list_load.txt 4 --cleanup`
    - Same as the previous, but now passing a script directory. useful if you want to modify the script
* `docker run -it normannovaes/ipsum sample_ip_list_load.txt 4 --cleanup`
    - Without passing any volume, the files under this repo `examples` directory are available for testing

### Sample results (main files)

Command executed: `docker run -it normannovaes/ipsum sample_ip_list_load.txt 4`

#### Original sample_ip_list_load.txt file

```
address,load
103.120.66.0-103.120.66.155,6
103.120.66.51,3
103.227.255.101,4
103.62.49.208,4
103.62.49.208,3
103.62.49.208,2
103.62.49.208,1
103.60.9.27,10
103.60.9.75,20
103.62.49.193,30
103.62.49.195,40
103.62.49.198,40
103.62.49.203,20
103.62.49.205,30
103.62.49.208,10
103.62.49.208,1
103.62.49.208,2
103.62.49.208,3
104.62.49.0/24,10
104.62.50.0/24,10
104.62.51.0/24,10
104.62.0.0/16,10
106.0.0.0/8,10
300.8.8.8,4
```


#### .summarized.list file output

For each node we generate a `.summarized.list` file with Summarized IP lists per node. 

**NODE_0.summarized.list**

```
103.60.9.27/32
103.60.9.75/32
103.62.49.193/32
103.62.49.195/32
103.62.49.198/32
103.62.49.203/32
103.62.49.205/32
103.62.49.208/32
103.120.66.0/25
103.120.66.128/28
103.120.66.144/29
103.120.66.152/30
103.227.255.101/32
104.62.0.0/18
```


**NODE_1.summarized.list**

```
104.62.49.64/26
104.62.49.128/25
104.62.50.0/23
104.62.64.0/18
```


**NODE_2.summarized.list**

```
104.62.128.0/18
104.62.192.0/19
```


**NODE_3.summarized.list**

```
104.62.224.0/19
```

### Sample results (additional files generated)

#### .original.list file output

```
address,load
103.120.66.0-103.120.66.155,6
103.120.66.51,3
103.227.255.101,4
103.62.49.208,4
103.62.49.208,3
103.62.49.208,2
103.62.49.208,1
103.60.9.27,10
103.60.9.75,20
103.62.49.193,30
103.62.49.195,40
103.62.49.198,40
103.62.49.203,20
103.62.49.205,30
103.62.49.208,10
103.62.49.208,1
103.62.49.208,2
103.62.49.208,3
104.62.49.0/24,10
104.62.50.0/24,10
104.62.51.0/24,10
104.62.0.0/16,10
300.8.8.8,4
```

#### .invalid.list file output

The last line of the input file contained an invalid IP so it is removed and added to this file

```
@{address=300.8.8.8; load=4}
```

#### .addresses.list file output

* For each node we generate a .addresses.list, which contains all addresses assigned for a particular node along with its load information. Here's the sample for node_0

```
address,load,hosts,weightedLoad
103.60.9.27/32,10,1,10
103.60.9.75/32,20,1,20
103.62.49.193/32,30,1,30
103.62.49.195/32,40,1,40
103.62.49.198/32,40,1,40
103.62.49.203/32,20,1,20
103.62.49.205/32,30,1,30
103.62.49.208/32,26,1,26
103.120.66.0/28,1,16,16
103.120.66.16/28,1,16,16
103.120.66.32/28,1,16,16
103.120.66.48/28,1,16,16
103.120.66.51/32,3,1,3
103.120.66.64/28,1,16,16
103.120.66.80/28,1,16,16
103.120.66.96/28,1,16,16
103.120.66.112/28,1,16,16
103.120.66.128/31,1,2,2
103.120.66.130/31,1,2,2
103.120.66.132/31,1,2,2
103.120.66.134/31,1,2,2
103.120.66.136/31,1,2,2
103.120.66.138/31,1,2,2
103.120.66.140/31,1,2,2
103.120.66.142/31,1,2,2
103.120.66.144/29,2,8,16
103.120.66.152/30,2,4,8
103.227.255.101/32,4,1,4
104.62.0.0/19,2,8192,16384
104.62.32.0/19,2,8192,16384
104.62.49.0/27,2,32,64
104.62.49.32/27,2,32,64

```

#### .results.json file output

* `weigthedLoad` is the sum of the products of the original load and the number of hosts in each subnet/address providded

```
[
  {
    "nodeName": "node_0",
    "load": 251.0,
    "weightedLoad": 33287
  },
  {
    "nodeName": "node_3",
    "load": 2.0,
    "weightedLoad": 16384
  },
  {
    "nodeName": "node_2",
    "load": 6.0,
    "weightedLoad": 49152
  },
  {
    "nodeName": "node_1",
    "load": 48.0,
    "weightedLoad": 34176
  }
]


```


#### .json file output

* This file contains all processed data. `sort` contains the decimal value of the IP address in `address`
* `weigthedLoad` is the product of the original load and the number of hosts in each subnet/address providded

```
[
  {
    "load": 251.0,
    "addresses": [
      {
        "load": 10.0,
        "hosts": 1,
        "address": "103.60.9.27/32",
        "sort": 1731987739,
        "weightedLoad": 10
      },
      {
        "load": 20.0,
        "hosts": 1,
        "address": "103.60.9.75/32",
        "sort": 1731987787,
        "weightedLoad": 20
      },
      {
        "load": 30.0,
        "hosts": 1,
        "address": "103.62.49.193/32",
        "sort": 1732129217,
        "weightedLoad": 30
      },
      {
        "load": 40.0,
        "hosts": 1,
        "address": "103.62.49.195/32",
        "sort": 1732129219,
        "weightedLoad": 40
      },
      {
        "load": 40.0,
        "hosts": 1,
        "address": "103.62.49.198/32",
        "sort": 1732129222,
        "weightedLoad": 40
      },
      {
        "load": 20.0,
        "hosts": 1,
        "address": "103.62.49.203/32",
        "sort": 1732129227,
        "weightedLoad": 20
      },
      {
        "load": 30.0,
        "hosts": 1,
        "address": "103.62.49.205/32",
        "sort": 1732129229,
        "weightedLoad": 30
      },
      {
        "load": 26.0,
        "hosts": 1,
        "address": "103.62.49.208/32",
        "sort": 1732129232,
        "weightedLoad": 26
      },
      {
        "load": 1.0,
        "hosts": 16,
        "address": "103.120.66.0/28",
        "sort": 1735934464,
        "weightedLoad": 16
      },
      {
        "load": 1.0,
        "hosts": 16,
        "address": "103.120.66.16/28",
        "sort": 1735934480,
        "weightedLoad": 16
      },
      {
        "load": 1.0,
        "hosts": 16,
        "address": "103.120.66.32/28",
        "sort": 1735934496,
        "weightedLoad": 16
      },
      {
        "load": 1.0,
        "hosts": 16,
        "address": "103.120.66.48/28",
        "sort": 1735934512,
        "weightedLoad": 16
      },
      {
        "load": 3.0,
        "hosts": 1,
        "address": "103.120.66.51/32",
        "sort": 1735934515,
        "weightedLoad": 3
      },
      {
        "load": 1.0,
        "hosts": 16,
        "address": "103.120.66.64/28",
        "sort": 1735934528,
        "weightedLoad": 16
      },
      {
        "load": 1.0,
        "hosts": 16,
        "address": "103.120.66.80/28",
        "sort": 1735934544,
        "weightedLoad": 16
      },
      {
        "load": 1.0,
        "hosts": 16,
        "address": "103.120.66.96/28",
        "sort": 1735934560,
        "weightedLoad": 16
      },
      {
        "load": 1.0,
        "hosts": 16,
        "address": "103.120.66.112/28",
        "sort": 1735934576,
        "weightedLoad": 16
      },
      {
        "load": 1.0,
        "hosts": 2,
        "address": "103.120.66.128/31",
        "sort": 1735934592,
        "weightedLoad": 2
      },
      {
        "load": 1.0,
        "hosts": 2,
        "address": "103.120.66.130/31",
        "sort": 1735934594,
        "weightedLoad": 2
      },
      {
        "load": 1.0,
        "hosts": 2,
        "address": "103.120.66.132/31",
        "sort": 1735934596,
        "weightedLoad": 2
      },
      {
        "load": 1.0,
        "hosts": 2,
        "address": "103.120.66.134/31",
        "sort": 1735934598,
        "weightedLoad": 2
      },
      {
        "load": 1.0,
        "hosts": 2,
        "address": "103.120.66.136/31",
        "sort": 1735934600,
        "weightedLoad": 2
      },
      {
        "load": 1.0,
        "hosts": 2,
        "address": "103.120.66.138/31",
        "sort": 1735934602,
        "weightedLoad": 2
      },
      {
        "load": 1.0,
        "hosts": 2,
        "address": "103.120.66.140/31",
        "sort": 1735934604,
        "weightedLoad": 2
      },
      {
        "load": 1.0,
        "hosts": 2,
        "address": "103.120.66.142/31",
        "sort": 1735934606,
        "weightedLoad": 2
      },
      {
        "load": 2.0,
        "hosts": 8,
        "address": "103.120.66.144/29",
        "sort": 1735934608,
        "weightedLoad": 16
      },
      {
        "load": 2.0,
        "hosts": 4,
        "address": "103.120.66.152/30",
        "sort": 1735934616,
        "weightedLoad": 8
      },
      {
        "load": 4.0,
        "hosts": 1,
        "address": "103.227.255.101/32",
        "sort": 1742995301,
        "weightedLoad": 4
      },
      {
        "load": 2.0,
        "hosts": 8192,
        "address": "104.62.0.0/19",
        "sort": 1748893696,
        "weightedLoad": 16384
      },
      {
        "load": 2.0,
        "hosts": 8192,
        "address": "104.62.32.0/19",
        "sort": 1748901888,
        "weightedLoad": 16384
      },
      {
        "load": 2.0,
        "hosts": 32,
        "address": "104.62.49.0/27",
        "sort": 1748906240,
        "weightedLoad": 64
      },
      {
        "load": 2.0,
        "hosts": 32,
        "address": "104.62.49.32/27",
        "sort": 1748906272,
        "weightedLoad": 64
      }
    ],
    "weightedLoad": 33287,
    "nodeName": "node_0",
    "plain_addresses": [
      "103.60.9.27/32",
      "103.60.9.75/32",
      "103.62.49.193/32",
      "103.62.49.195/32",
      "103.62.49.198/32",
      "103.62.49.203/32",
      "103.62.49.205/32",
      "103.62.49.208/32",
      "103.120.66.0/28",
      "103.120.66.16/28",
      "103.120.66.32/28",
      "103.120.66.48/28",
      "103.120.66.51/32",
      "103.120.66.64/28",
      "103.120.66.80/28",
      "103.120.66.96/28",
      "103.120.66.112/28",
      "103.120.66.128/31",
      "103.120.66.130/31",
      "103.120.66.132/31",
      "103.120.66.134/31",
      "103.120.66.136/31",
      "103.120.66.138/31",
      "103.120.66.140/31",
      "103.120.66.142/31",
      "103.120.66.144/29",
      "103.120.66.152/30",
      "103.227.255.101/32",
      "104.62.0.0/19",
      "104.62.32.0/19",
      "104.62.49.0/27",
      "104.62.49.32/27"
    ],
    "summarized": [
      "103.60.9.27/32",
      "103.60.9.75/32",
      "103.62.49.193/32",
      "103.62.49.195/32",
      "103.62.49.198/32",
      "103.62.49.203/32",
      "103.62.49.205/32",
      "103.62.49.208/32",
      "103.120.66.0/25",
      "103.120.66.128/28",
      "103.120.66.144/29",
      "103.120.66.152/30",
      "103.227.255.101/32",
      "104.62.0.0/18"
    ]
  },
  {
    "load": 2.0,
    "addresses": [
      {
        "load": 2.0,
        "hosts": 8192,
        "address": "104.62.224.0/19",
        "sort": 1748951040,
        "weightedLoad": 16384
      }
    ],
    "weightedLoad": 16384,
    "nodeName": "node_3",
    "plain_addresses": "104.62.224.0/19",
    "summarized": "104.62.224.0/19"
  },
  {
    "load": 6.0,
    "addresses": [
      {
        "load": 2.0,
        "hosts": 8192,
        "address": "104.62.128.0/19",
        "sort": 1748926464,
        "weightedLoad": 16384
      },
      {
        "load": 2.0,
        "hosts": 8192,
        "address": "104.62.160.0/19",
        "sort": 1748934656,
        "weightedLoad": 16384
      },
      {
        "load": 2.0,
        "hosts": 8192,
        "address": "104.62.192.0/19",
        "sort": 1748942848,
        "weightedLoad": 16384
      }
    ],
    "weightedLoad": 49152,
    "nodeName": "node_2",
    "plain_addresses": [
      "104.62.128.0/19",
      "104.62.160.0/19",
      "104.62.192.0/19"
    ],
    "summarized": [
      "104.62.128.0/18",
      "104.62.192.0/19"
    ]
  },
  {
    "load": 48.0,
    "addresses": [
      {
        "load": 2.0,
        "hosts": 32,
        "address": "104.62.49.64/27",
        "sort": 1748906304,
        "weightedLoad": 64
      },
      {
        "load": 2.0,
        "hosts": 32,
        "address": "104.62.49.96/27",
        "sort": 1748906336,
        "weightedLoad": 64
      },
      {
        "load": 2.0,
        "hosts": 32,
        "address": "104.62.49.128/27",
        "sort": 1748906368,
        "weightedLoad": 64
      },
      {
        "load": 2.0,
        "hosts": 32,
        "address": "104.62.49.160/27",
        "sort": 1748906400,
        "weightedLoad": 64
      },
      {
        "load": 2.0,
        "hosts": 32,
        "address": "104.62.49.192/27",
        "sort": 1748906432,
        "weightedLoad": 64
      },
      {
        "load": 2.0,
        "hosts": 32,
        "address": "104.62.49.224/27",
        "sort": 1748906464,
        "weightedLoad": 64
      },
      {
        "load": 2.0,
        "hosts": 32,
        "address": "104.62.50.0/27",
        "sort": 1748906496,
        "weightedLoad": 64
      },
      {
        "load": 2.0,
        "hosts": 32,
        "address": "104.62.50.32/27",
        "sort": 1748906528,
        "weightedLoad": 64
      },
      {
        "load": 2.0,
        "hosts": 32,
        "address": "104.62.50.64/27",
        "sort": 1748906560,
        "weightedLoad": 64
      },
      {
        "load": 2.0,
        "hosts": 32,
        "address": "104.62.50.96/27",
        "sort": 1748906592,
        "weightedLoad": 64
      },
      {
        "load": 2.0,
        "hosts": 32,
        "address": "104.62.50.128/27",
        "sort": 1748906624,
        "weightedLoad": 64
      },
      {
        "load": 2.0,
        "hosts": 32,
        "address": "104.62.50.160/27",
        "sort": 1748906656,
        "weightedLoad": 64
      },
      {
        "load": 2.0,
        "hosts": 32,
        "address": "104.62.50.192/27",
        "sort": 1748906688,
        "weightedLoad": 64
      },
      {
        "load": 2.0,
        "hosts": 32,
        "address": "104.62.50.224/27",
        "sort": 1748906720,
        "weightedLoad": 64
      },
      {
        "load": 2.0,
        "hosts": 32,
        "address": "104.62.51.0/27",
        "sort": 1748906752,
        "weightedLoad": 64
      },
      {
        "load": 2.0,
        "hosts": 32,
        "address": "104.62.51.32/27",
        "sort": 1748906784,
        "weightedLoad": 64
      },
      {
        "load": 2.0,
        "hosts": 32,
        "address": "104.62.51.64/27",
        "sort": 1748906816,
        "weightedLoad": 64
      },
      {
        "load": 2.0,
        "hosts": 32,
        "address": "104.62.51.96/27",
        "sort": 1748906848,
        "weightedLoad": 64
      },
      {
        "load": 2.0,
        "hosts": 32,
        "address": "104.62.51.128/27",
        "sort": 1748906880,
        "weightedLoad": 64
      },
      {
        "load": 2.0,
        "hosts": 32,
        "address": "104.62.51.160/27",
        "sort": 1748906912,
        "weightedLoad": 64
      },
      {
        "load": 2.0,
        "hosts": 32,
        "address": "104.62.51.192/27",
        "sort": 1748906944,
        "weightedLoad": 64
      },
      {
        "load": 2.0,
        "hosts": 32,
        "address": "104.62.51.224/27",
        "sort": 1748906976,
        "weightedLoad": 64
      },
      {
        "load": 2.0,
        "hosts": 8192,
        "address": "104.62.64.0/19",
        "sort": 1748910080,
        "weightedLoad": 16384
      },
      {
        "load": 2.0,
        "hosts": 8192,
        "address": "104.62.96.0/19",
        "sort": 1748918272,
        "weightedLoad": 16384
      }
    ],
    "weightedLoad": 34176,
    "nodeName": "node_1",
    "plain_addresses": [
      "104.62.49.64/27",
      "104.62.49.96/27",
      "104.62.49.128/27",
      "104.62.49.160/27",
      "104.62.49.192/27",
      "104.62.49.224/27",
      "104.62.50.0/27",
      "104.62.50.32/27",
      "104.62.50.64/27",
      "104.62.50.96/27",
      "104.62.50.128/27",
      "104.62.50.160/27",
      "104.62.50.192/27",
      "104.62.50.224/27",
      "104.62.51.0/27",
      "104.62.51.32/27",
      "104.62.51.64/27",
      "104.62.51.96/27",
      "104.62.51.128/27",
      "104.62.51.160/27",
      "104.62.51.192/27",
      "104.62.51.224/27",
      "104.62.64.0/19",
      "104.62.96.0/19"
    ],
    "summarized": [
      "104.62.49.64/26",
      "104.62.49.128/25",
      "104.62.50.0/23",
      "104.62.64.0/18"
    ]
  }
]

```