# Generate IOCs From Florian Roth

This script takes Florian Roth IOC lists and pushes to github cleaned version, ready to be consumed in KQL (Sentinel, Defender ATP, ...)

Link: https://github.com/Neo23x0/signature-base

## Defender ATP example

Hash IOCs lookup for process creation 

```
let ExternalHash =  (externaldata(hash: string) [@"https://raw.githubusercontent.com/lsoumille/IOC_Lists/master/hash_iocs.txt"] with (format="txt"));
let SHA1_Matches = ExternalHash
| distinct ['hash']
| lookup kind=inner (DeviceProcessEvents | distinct SHA1) on $left.['hash'] == $right.SHA1;
let SHA256_Matches = ExternalHash
| distinct ['hash']
| lookup kind=inner (DeviceProcessEvents | distinct SHA256) on $left.['hash'] == $right.SHA256;
let MD5_Matches = ExternalHash
| distinct ['hash']
| lookup kind=inner (DeviceProcessEvents | distinct MD5) on $left.['hash'] == $right.MD5;
let Found_Hashes = union SHA1_Matches, SHA256_Matches, MD5_Matches;
DeviceProcessEvents
| where SHA1 in~ (Found_Hashes)
     or SHA256 in~ (Found_Hashes)
     or MD5 in~ (Found_Hashes)
```