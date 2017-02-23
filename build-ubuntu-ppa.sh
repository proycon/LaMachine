#!/bin/bash

#Build packages for Ubuntu LaMachine PPA from the packages in debian git
#Does not require packages to be uploaded to debian yet


PACKAGES="python-pynlpl"

mkdir ubuntu-ppa
cd ubuntu-ppa

for package in $PACKAGES; do
    echo 
    echo "--------------------------------------------------------"
    echo "Building package for $package"
    echo "--------------------------------------------------------"
    if [ ! -d $package ]; then
        git clone https://anonscm.debian.org/git/debian-science/packages/$package.git || fatalerror "Unable to clone git repo for $package"
        cd $package
    else
        cd $package
        git pull
    fi
    echo "Previously packaged versions: " 
    ls $package*source.changes
    sed -i 's/debhelper (>= 10)/debhelper (>= 9)/' $package/debian/control #debhelper 10 is too new for 16.04
    dch -i && debcommit -a -m "Rebuilding for ubuntu" && gbp buildpackage -S -k1A31555C
    if [ $? -eq 0 ]; then
        changefile=$(ls -t $package*source.changes | head -n 1)
        if [ ! -z "$changefile" ]; then
            echo "Uploading $changefile"
            dput lamachine $changefile
        fi
    fi
    #wget -r -nc --no-parent --reject "index.html*" http://cdn-fastly.deb.debian.org/debian/pool/main/${package:0:1}/$package/ 
    #dget -ux 
done

