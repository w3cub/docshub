#!/bin/sh
###
 # Synchronized with github pages
### 

WORKDIR=/opt
WWW_SOURCE=https://github.com/w3cub/w3cub-release-202011



echo "::Add a job lock file::"

if ! mkdir /tmp/dsync.lock 2>/dev/null; then
    echo "job is already running." >&2
    exit
fi


echo "::Downloading w3cub-release::"


cd $WORKDIR

if [ -f $WORKDIR/www.tar.gz ]; then
    echo "file exists, remove it."
    rm -rf www.tar.gz
fi
wget $WWW_SOURCE/tarball/gh-pages -O www.tar.gz


cd $WORKDIR

if [ -d $WORKDIR/www ]; then
   mv www www_backup$(date +%Y%m%d%H%M%S)
fi
tar -zxvf www.tar.gz -C www --strip-components=1



echo "::Job complete, remove lock file::"
rm -rf /tmp/dsync.lock
