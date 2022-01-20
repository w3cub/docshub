#!/bin/sh
###
 # Synchronized with github pages
### 

githubsource=https://github.com/w3cub/w3cub-release-202011


echo "::Add a job lock file::"

if ! mkdir /tmp/dsync.lock 2>/dev/null; then
    echo "job is already running." >&2
    exit 1
fi


echo "::Downloading w3cub-release-202011::"


cd /opt

if [ -f www.tar.gz ]; then
    echo "file exists, remove it."
    rm -rf www.tar.gz
fi
wget $githubsource/tarball/master -O www.tar.gz

if [ ! -d wwwtmp ]; then
   mkdir wwwtmp
fi
tar -xvf www.tar.gz -C wwwtmp --strip-components=1
mv wwwtmp/* /opt/www/
rm -rf wwwtmp


echo "::Job complete, remove lock file::"
rm -rf /tmp/dsync.lock
