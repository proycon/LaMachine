#!/bin/bash
#======================================
# LaMachine
#  by Maarten van Gompel
#  Centre for Language Studies
#  Radboud University Nijmegen
#
# https://proycon.github.io/LaMachine
# Licensed under GPLv3
#=====================================


#NOTE: Do not run this script directly!

echo "====================================================================="
echo "           ,              LaMachine - NLP Software distribution" 
echo "          ~)                     (http://proycon.github.io/LaMachine)"
echo "           (----í         Language Machines research group"
echo "            /| |\         & Centre of Language and Speech Technology"
echo "           / / /|	        Radboud University Nijmegen "
echo "====================================================================="
echo
echo "Bootstrapping Virtual Machine or Docker image...."
echo
sleep 1

fatalerror () {
    echo "================ FATAL ERROR ==============" >&2
    echo "An error occured during installation!!" >&2
    echo $1 >&2
    echo "===========================================" >&2
    echo $1 > error
    exit 2
}

error () {
    echo "================= ERROR ===================" >&2
    echo $1 >&2
    echo "===========================================" >&2
    echo $1 > error
    sleep 3
}

umask u=rwx,g=rwx,o=rx

sed -i s/lecture=once/lecture=never/ /etc/sudoers
echo "ALL            ALL = (ALL) NOPASSWD: ALL" >> /etc/sudoers

cd /usr/src/
SRCDIR=`pwd`

FORCE=0
DEV=0 #prefer stable releases
if [ -f .dev ]; then
    DEV=1 #install development versions
else
    DEV=0 #install development versions
fi
if [ -f .private ]; then
    PRIVATE=1 #no not send simple analytics to Nijmegen
else
    PRIVATE=0 #send simple analytics to Nijmegen
fi
for OPT in "$@"
do
    if [[ "$OPT" == "force" ]]; then
        FORCE=1
    fi
    if [[ "$OPT" == "dev" ]]; then
        touch .dev
        DEV=1
    fi
    if [[ "$OPT" == "stable" ]]; then
        rm -f .dev
        DEV=0
    fi
    if [[ "$OPT" == "private" ]]; then
        touch .private
        PRIVATE=1
    fi
    if [[ "$OPT" == "sendinfo" ]]; then
        rm -f .private
        PRIVATE=0
    fi
done

if [ -d /vagrant ]; then
    VAGRANT=1
    cp /vagrant/motd /etc/motd
    FORM="vagrant"
else
    VAGRANT=0
    FORM="docker"
fi


echo "--------------------------------------------------------"
echo "[LaMachine] Installing global dependencies"
echo "--------------------------------------------------------"
#will run as root
echo "Conflict prevention..."
pacman --noconfirm -R virtualbox-guest-dkms
echo "Installing base-devel...."
pacman -Syu --noconfirm --needed base-devel || fatalerror "Unable to install global dependencies"
PKGS="pkg-config git autoconf-archive icu xml2 zlib libtar boost boost-libs cython python python-pip python-requests python-lxml python-pycurl python-virtualenv python-numpy python-scipy python-matplotlib python-pandas python-nltk python-scikit-learn python-psutil ipython wget curl libexttextcat python-flask python-requests python-requests-oauthlib python-requests-toolbelt python-crypto nginx uwsgi uwsgi-plugin-python hunspell aspell hunspell-en aspell-en perl perl-sort-naturally"
echo "Installing global packages: $PKGS"
pacman --noconfirm --needed -Syu $PKGS ||  fatalerror "Unable to install global dependencies"

if [ $PRIVATE -eq 0 ]; then
    #Sending some statistics to us so we know how often and on what systems LaMachine is used
    #recipient: Language Machines, Centre for Language Studies, Radboud University Nijmegen
    #
    #Transmitted are:
    # - The form in which you run LaMachine (vagrant/virtualenv/docker)
    # - Is it a new LaMachine installation or an update
    # - Stable or Development?
    #
    #This information will never be used for any form of advertising
    #Your IP will only be used to compute country of origin, resulting reports will never contain personally identifiable information

    if [ $DEV -eq 0 ]; then
        STABLEDEV="stable"
    else
        STABLEDEV="dev"
    fi
    if [ ! -d LaMachine ]; then
        MODE="new"
    else
        MODE="update"
    fi
    PYTHONVERSION=`python -c 'import sys; print(".".join(map(str, sys.version_info[:3])))'`
    wget -O - -q "http://applejack.science.ru.nl/lamachinetracker.php/$FORM/$MODE/$STABLEDEV/$PYTHONVERSION" >/dev/null
fi


useradd build 

chgrp build /usr/src
chmod g+ws /usr/src


echo "--------------------------------------------------------"
echo "Updating LaMachine itself"
echo "--------------------------------------------------------"
if [ ! -d LaMachine ]; then
    git clone https://github.com/proycon/LaMachine || fatalerror "Unable to clone git repo for LaMachine"
    cd LaMachine || fatalerror "No LaMachine dir?, git clone failed?"
else
    cd LaMachine
    OLDSUM=`sum bootstrap.sh`
    git pull
    NEWSUM=`sum bootstrap.sh`
    cp bootstrap.sh /usr/bin/lamachine-update.sh
    cp test.sh /usr/bin/lamachine-test.sh
    if [ "$OLDSUM" != "$NEWSUM" ]; then
        echo "----------------------------------------------------------------"
        echo "LaMachine has been updated with a newer version, restarting..."
        echo "----------------------------------------------------------------"
        sleep 3
        ./bootstrap.sh $@ 
        exit $?
    else
        echo "LaMachine is up to date..."
    fi
fi
cp bootstrap.sh /usr/bin/lamachine-update.sh
cp test.sh /usr/bin/lamachine-test.sh
cp nginx.mime.types /etc/nginx/
cp nginx.conf /etc/nginx/
cd ..
chmod a+rx LaMachine

#development packages should end in -git , releases should not
if [ $DEV -eq 0 ]; then
    #Packages to install in stable mode:
    PACKAGES="ticcutils libfolia foliautils-git ucto timbl timblserver mbt mbtserver wopr-git frogdata frog ticcltools-git toad-git" #not everything is available as releases yet
else
    #Packages to install in development mode:
    PACKAGES="ticcutils-git libfolia-git foliautils-git ucto-git timbl-git timblserver-git mbt-git wopr-git frogdata-git frog-git toad-git ticcltools-git"
fi

for package in $PACKAGES; do
    project="${package%-git}"
    if [ ! -d $package ]; then
        echo "--------------------------------------------------------"
        echo "[LaMachine] Obtaining package $package ..."
        echo "--------------------------------------------------------"
        git clone https://aur.archlinux.org/${package}.git
        cd $package || fatalerror "No such package, git clone $package failed?"
    else
        cd $package
        cp -f PKGBUILD PKGBUILD.old
        git pull
        sudo -u build makepkg --nobuild #to get proper version
        diff PKGBUILD PKGBUILD.old >/dev/null
        DIFF=$?
        if [ $DIFF -eq 0 ]; then
            echo "--------------------------------------------------------"
            echo "[LaMachine] $project is already up to date..."
            echo "--------------------------------------------------------"
            if [ $FORCE -eq 0 ]; then
                continue
            fi
        fi
    fi 
    echo "--------------------------------------------------------"
    echo "[LaMachine] Installing $project ..."
    echo "--------------------------------------------------------"
    sudo -u build makepkg -s -f --noconfirm --needed --noprogressbar
    pacman -U --noconfirm --needed ${project}*.pkg.tar.xz || error "Installation of ${project} failed !!"
    rm ${project}*.pkg.tar.xz
    cd ..
done

#echo "--------------------------------------------------------"
#echo "[LaMachine] Installing Python 2 packages"
#echo "--------------------------------------------------------"
#pip2 install pynlpl FoLiA-tools clam || error "Installation of one or more Python 2 packages failed !!"

echo "--------------------------------------------------------"
echo "[LaMachine] Installing Python 3 packages"
echo "--------------------------------------------------------"
pip install -U pynlpl FoLiA-tools python-ucto foliadocserve clam || error "Installation of one or more Python 3 packages failed !!"

if [ -f clam ]; then
    rm clam
fi
CLAMDIR=`python -c 'import clam; print(clam.__path__[0])'`
if [ ! -z "$CLAMDIR" ]; then
    ln -s $CLAMDIR clam
fi

echo "--------------------------------------------------------"
echo "[LaMachine] Installing python-timbl"
echo "--------------------------------------------------------"
#pip2 install python-timbl || error "Installation of python2-timbl failed !!"
pip install -U python3-timbl || error "Installation of python3-timbl failed !!"

echo "--------------------------------------------------------"
echo "[LaMachine] Installing python-frog"
echo "--------------------------------------------------------"
pip install -U python-frog
#git clone https://github.com/proycon/python-frog
#cd python-frog || fatalerror "No python-frog dir, git clone failed?"
#python setup.py install || error "Installation of python-frog failed !!"
#cd ..

echo "--------------------------------------------------------"
echo "[LaMachine] Installing colibri-core"
echo "--------------------------------------------------------"
pip install -U colibricore || error "Installation of colibri-core failed !!"

echo "--------------------------------------------------------"
echo "[LaMachine] Installing Gecco dependencies (3rd party)"
echo "--------------------------------------------------------"
pip install -U hunspell python-Levenshtein aspell-python-py3 || error "Installation of one or more Python 3 packages failed !!"


echo "--------------------------------------------------------"
echo "[LaMachine] Installing Gecco (latest development release) "
echo "--------------------------------------------------------"
if [ ! -d gecco ]; then
    git clone https://github.com/proycon/gecco
    chmod a+rx gecco
    cd gecco || fatalerror "No gecco dir, git clone failed?"
else
    cd gecco
    git pull
fi
python setup.py install || error "setup.py install gecco failed"
cd ..

cd $SRCDIR || fatalerror "Unable to go back to sourcedir"
. LaMachine/extra.sh $@ 

lamachine-test.sh
if [ $? -eq 0 ]; then
    echo "--------------------------------------------------------"
    echo "[LaMachine] All done!  "
    if [ $VAGRANT -eq 1 ]; then
        echo " .. Issue $ vagrant ssh to connect to your VM!"
    else
        echo "IMPORTANT NOTE: You are most likely using docker, do not forget to commit the container state if you want to preserve this update !!"
    fi
    exit 0
else
    echo "--------------------------------------------------------"
    echo "LaMachine bootstrap FAILED because of failed tests!!!!"
    echo "--------------------------------------------------------"
    exit 1
fi
