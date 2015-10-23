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

gitcheck () {
    git remote update
    LOCAL=$(git rev-parse @)
    REMOTE=$(git rev-parse @{u})
    BASE=$(git merge-base @ @{u})

    if [ -f error ]; then
        echo "Encountered an error last time, need to recompile"
        rm error
        REPOCHANGED=1
    elif [ $LOCAL = $REMOTE ]; then
        echo "Git: up-to-date"
        REPOCHANGED=0
    elif [ $LOCAL = $BASE ]; then
        echo "Git: Pulling..."
        git pull || fatalerror "Unable to git pull $project"
        REPOCHANGED=1
    elif [ $REMOTE = $BASE ]; then
        echo "Git: Need to push"
        REPOCHANGED=1
    else
        echo "Git: Diverged"
        REPOCHANGED=1
    fi
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

useradd build 

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
    OLDSUM=`sum bootstrap.sh`
    git pull
    NEWSUM=`sum bootstrap.sh`
    cp bootstrap.sh /usr/bin/lamachine-update.sh
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
cp nginx.mime.types /etc/nginx/
cp nginx.conf /etc/nginx/
cd ..
chmod a+rx LaMachine

PACKAGES="ticcutils-git libfolia-git foliatools-git ucto-git timbl-git timblserver-git mbt-git wopr-git frogdata-git frog-git"

for package in $PACKAGES; do
    project="${package%-git}"
    if [ ! -d $package ]; then
        echo "--------------------------------------------------------"
        echo "[LaMachine] Obtaining package $package ..."
        echo "--------------------------------------------------------"
        git clone https://aur.archlinux.org/${package}.git
        cd $package
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
            continue
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
if [ ! -z $CLAMDIR ]; then
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
git clone https://github.com/proycon/python-frog
cd python-frog
python setup.py install || error "Installation of python-frog failed !!"
cd ..

echo "--------------------------------------------------------"
echo "[LaMachine] Installing colibri-core"
echo "--------------------------------------------------------"
pip install -U colibricore || error "Installation of colibri-core failed !!"

echo "--------------------------------------------------------"
echo "[LaMachine] Installing Gecco dependencies"
echo "--------------------------------------------------------"
pip install -U hunspell python-Levenshtein aspell-python-py3 || error "Installation of one or more Python 3 packages failed !!"


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

LaMachine/extra.sh $@ 

echo "--------------------------------------------------------"
echo "[LaMachine] All done!  "
if [ -d /vagrant ]; then
    echo " .. Issue $ vagrant ssh to connect to your VM!"
fi
