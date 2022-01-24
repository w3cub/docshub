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


cd $WORKDIR

if [ -d $WORKDIR/www/.git ]; then
    cd $WORKDIR/www
    git pull
fi

# not exist the www directory
if [ ! -d $WORKDIR/www]; then
    git clone --depth 1 -b gh-pages --single-branch $WWW_SOURCE.git www
fi

cd $WORKDIR

# exist the www directory
if [ -d $WORKDIR/www && ! -d $WORKDIR/www/.git ]; then

    wget $WWW_SOURCE/tarball/gh-pages -O www.tar.gz
    
    if [ ! -d wwwtmp ]; then
        mkdir wwwtmp
    fi
    # long time to unzip
    tar -zxf www.tar.gz -C wwwtmp --strip-components=1

    if [ -d $WORKDIR/www ]; then
        mv www www_backup_$(date +%Y%m%d%H%M%S)
    fi
    mv wwwtmp www
fi



echo "::Job complete, remove lock file::"
rm -rf /tmp/dsync.lock
