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



# not exist the www directory
if [ ! -d $WORKDIR/www ]; then
    git clone --depth 1 -b gh-pages --single-branch $WWW_SOURCE.git www
fi


if [ -d $WORKDIR/www/.git ]; then
    cd $WORKDIR/www
    git pull
fi


echo "::Job complete, remove lock file::"
rm -rf /tmp/dsync.lock
