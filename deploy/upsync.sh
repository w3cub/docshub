#!/bin/bash

set -a; 
source .env; 
set +a;

export http_proxy=http://127.0.0.1:1080;
export https_proxy=http://127.0.0.1:1080;

# split the ips from variables as array, delimiter by comma
ips=(${IPs//,/ })

echo "ips: ${ips[@]}"

for ip in "${ips[@]}"
do
    echo "curl http://${ip}/sync"
    # curl -m 3 http://${ip}/sync > /dev/null 2>&1
    curl -m 3 http://${ip}/sync -o /dev/null -s -w "%{http_code}\n"
done

unset http_proxy
unset https_proxy