#!/bin/sh
###
 # Synchronized with github pages
### 

if [ ! -z $WWW_SOURCE ]; then
   WWW_SOURCE=https://github.com/w3cub/w3cub-release-202011
fi

if [ ! -z $WORKDIR ]; then
    WORKDIR=/opt
fi
if [ ! -d $WORKDIR ]; then
    mkdir -p $WORKDIR
fi

# define www dirname
if [ ! -z $WWWDIR ]; then
    WWWDIR=www
fi



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


if [ ! -d wwwtmp ]; then
   mkdir wwwtmp
fi
# long time to unzip
tar -zxf www.tar.gz -C wwwtmp --strip-components=1

if [ -d $WORKDIR/$WWWDIR ]; then
   mv $WWWDIR ${WWWDIR}_backup$(date +%Y%m%d%H%M%S)
fi

mv wwwtmp $WWWDIR


echo "::Job complete, remove lock file::"
rm -rf /tmp/dsync.lock
