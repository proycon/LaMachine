#!/bin/bash

echo "[LaMachine] BOOTSTRAPPING -- (This script is run automatically when first starting the virtual machine"

fatalerror () {
    echo "================ FATAL ERROR ==============" >&2
    echo "A error occured during installation!!" >&2
    echo $1 >&2
    echo "===========================================" >&2
    exit 2
}

error () {
    echo "================= ERROR ===================" >&2
    echo $1 >&2
    echo "===========================================" >&2
    sleep 3
}

echo "--------------------------------------------------------"
echo "[LaMachine] Installing global dependencies"
echo "--------------------------------------------------------"
#will run as root
pacman -Syu --noconfirm --needed base-devel || fatalerror "Unable to install global dependencies"
PKGS="pkg-config git autoconf-archive icu xml2 zlib libtar boost boost-libs python2 cython cython2 python python2 python-pip python2-pip python-requests python-lxml python2-lxml python-pycurl python-virtualenv python-numpy python2-numpy python-scipy python2-scipy python-matplotlib python2-matplotlib python-pandas python2-pandas python-nltk wget"
pacman --noconfirm --needed -Syu $PKGS ||  fatalerror "Unable to install global dependencies"

umask u=rwx,g=rwx,o=r

sed -i s/lecture=once/lecture=never/ /etc/sudoers
echo "ALL            ALL = (ALL) NOPASSWD: ALL" >> /etc/sudoers

if [ -d /vagrant ]; then
    cp /vagrant/motd /etc/motd
fi

cd /usr/src/

useradd build || fatalerror "Unable to create user"

chgrp build /usr/src
chmod g+ws /usr/src

PACKAGES="ticcutils-git libfolia-git ucto-git timbl-git timblserver-git mbt-git frogdata-git frog-git"

for package in $PACKAGES; do
    project="${package%-git}"
    if [ ! -d $package ]; then
        echo "--------------------------------------------------------"
        echo "[LaMachine] Obtaining package $package ..."
        echo "--------------------------------------------------------"
        URL="https://aur.archlinux.org/packages/${package:0:2}/${package}/${package}.tar.gz"
        sudo -u build wget $URL
        sudo -u build tar -xvzf ${package}.tar.gz
        rm ${package}.tar.gz
    fi 
    cd $package
    echo "--------------------------------------------------------"
    echo "[LaMachine] Installing $project ..."
    echo "--------------------------------------------------------"
    sudo -u build makepkg -s  --noconfirm --needed --noprogressbar
    pacman -U --noconfirm --needed ${project}*.pkg.tar.xz || error "Installation of ${project} failed !!"
    cd ..
done

echo "--------------------------------------------------------"
echo "[LaMachine] Installing Python 2 packages"
echo "--------------------------------------------------------"
pip2 install pynlpl FoLiA-tools clam || error "Installation of one or more Python 2 packages failed !!"

echo "--------------------------------------------------------"
echo "[LaMachine] Installing Python 3 packages"
echo "--------------------------------------------------------"
pip install pynlpl FoLiA-tools python-ucto foliadocserve || error "Installation of one or more Python 3 packages failed !!"


echo "--------------------------------------------------------"
echo "[LaMachine] Installing python-timbl"
echo "--------------------------------------------------------"
pip2 install python-timbl || error "Installation of python2-timbl failed !!"
pip install python3-timbl || error "Installation of python3-timbl failed !!"

echo "--------------------------------------------------------"
echo "[LaMachine] Installing python-frog"
echo "--------------------------------------------------------"
git clone https://github.com/proycon/python-frog
cd python-frog
python setup.py install || error "Installation of python-frog failed !!"
cd ..

echo "--------------------------------------------------------"
echo "[LaMachine] Installing colibri-core"
echo "--------------------------------------------------------"
pip install --root / colibricore || error "Installation of colibri-core failed !!"

echo "--------------------------------------------------------"
echo "[LaMachine] All done!  "
echo " .. Issue $ vagrant ssh to connect to your VM!"
