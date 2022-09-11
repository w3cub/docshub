#!/bin/sh

###
 # DNS load balancing with new server
### 

set -x

DOMAIN=docs.w3cub.com


apt update

apt-get -y install --no-install-recommends wget gnupg ca-certificates


wget -O - https://openresty.org/package/pubkey.gpg | sudo apt-key add -

# ubuntu 16 ~ 20
echo "deb http://openresty.org/package/ubuntu $(lsb_release -sc) main" \
| sudo tee /etc/apt/sources.list.d/openresty.list

apt-get update

apt-get -y install openresty