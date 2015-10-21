#!/bin/bash

echo "[LaMachine] BOOTSTRAPPING -- (This script is run automatically when first starting the virtual machine)"

fatalerror () {
    echo "================ FATAL ERROR ==============" >&2
    echo "An error occured during installation!!" >&2
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
PKGS="pkg-config git autoconf-archive icu xml2 zlib libtar boost boost-libs cython python python-pip python-requests python-lxml python-pycurl python-virtualenv python-numpy python-scipy python-matplotlib python-pandas python-nltk python-scikit-learn python-psutil ipython ipython-notebook wget curl libexttextcat python-flask python-requests python-requests-oauthlib python-requests-toolbelt python-crypto nginx uwsgi uwsgi-plugin-python hunspell aspell hunspell-en aspell-en"
pacman --noconfirm --needed -Syu $PKGS ||  fatalerror "Unable to install global dependencies"

umask u=rwx,g=rwx,o=rx

sed -i s/lecture=once/lecture=never/ /etc/sudoers
echo "ALL            ALL = (ALL) NOPASSWD: ALL" >> /etc/sudoers

if [ -d /vagrant ]; then
    cp /vagrant/motd /etc/motd
fi

cd /usr/src/

useradd build || fatalerror "Unable to create user"

chgrp build /usr/src
chmod g+ws /usr/src


echo "--------------------------------------------------------"
echo "Updating LaMachine itself"
echo "--------------------------------------------------------"
if [ ! -d LaMachine ]; then
    git clone https://github.com/proycon/LaMachine || fatalerror "Unable to clone git repo for LaMachine"
    cd LaMachine
else
    cd LaMachine
    git pull
fi
cp bootstrap.sh /usr/bin/lamachine-update.sh
cp nginx.mime.types /etc/nginx/
cp nginx.conf /etc/nginx/
cd ..
chmod a+rx LaMachine

PACKAGES="ticcutils-git libfolia-git foliatools-git ucto-git timbl-git timblserver-git mbt-git wopr-git frogdata-git frog-git python-gensim"

for package in $PACKAGES; do
    project="${package%-git}"
    if [ ! -d $package ]; then
        echo "--------------------------------------------------------"
        echo "[LaMachine] Obtaining package $package ..."
        echo "--------------------------------------------------------"
        git clone https://aur.archlinux.org/${package}.git
    fi 
    cd $package
    echo "--------------------------------------------------------"
    echo "[LaMachine] Installing $project ..."
    echo "--------------------------------------------------------"
    sudo -u build makepkg -s  --noconfirm --needed --noprogressbar
    pacman -U --noconfirm --needed ${project}*.pkg.tar.xz || error "Installation of ${project} failed !!"
    cd ..
done

#echo "--------------------------------------------------------"
#echo "[LaMachine] Installing Python 2 packages"
#echo "--------------------------------------------------------"
#pip2 install pynlpl FoLiA-tools clam || error "Installation of one or more Python 2 packages failed !!"

echo "--------------------------------------------------------"
echo "[LaMachine] Installing Python 3 packages"
echo "--------------------------------------------------------"
pip install pynlpl FoLiA-tools python-ucto foliadocserve clam || error "Installation of one or more Python 3 packages failed !!"


echo "--------------------------------------------------------"
echo "[LaMachine] Installing python-timbl"
echo "--------------------------------------------------------"
#pip2 install python-timbl || error "Installation of python2-timbl failed !!"
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
pip install colibricore || error "Installation of colibri-core failed !!"


echo "--------------------------------------------------------"
echo "[LaMachine] Installing CLAM  (Python 3 beta)"
echo "--------------------------------------------------------"
if [ ! -d clam ]; then
    git clone https://github.com/proycon/clam
    chmod a+rx clam
    cd clam
    git checkout python3flask
else
    cd clam
    git checkout python3flask
    git pull
fi
python setup.py install || error "setup.py install clam failed"
cd ..

echo "--------------------------------------------------------"
echo "[LaMachine] Installing Gecco dependencies"
echo "--------------------------------------------------------"
pip install hunspell python-Levenshtein aspell-python-py3 || error "Installation of one or more Python 3 packages failed !!"


echo "--------------------------------------------------------"
echo "[LaMachine] Installing Gecco"
echo "--------------------------------------------------------"
if [ ! -d gecco ]; then
    git clone https://github.com/proycon/gecco
    chmod a+rx gecco
    cd gecco
else
    cd gecco
    git pull
fi
python setup.py install || error "setup.py install gecco failed"
cd ..

echo "--------------------------------------------------------"
echo "[LaMachine] All done!  "
echo " .. Issue $ vagrant ssh to connect to your VM!"
