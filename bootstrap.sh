#!/bin/bash

echo "BOOTSTRAPPING LAMACHINE -- (This script is run automatically when first starting the virtual machine)">&2

error () {
    echo "A error occured during installation!!" >&2
    echo $1 >&2
}

#will run as root
PKGS="pkg-config git-core make gcc g++ autoconf-archive libtool autotools-dev libicu-dev libxml2-dev libbz2-dev zlib1g-dev libtar-dev libboost-all-dev python-dev cython python3 python-pip python3-pip cython cython3 python3-requests python-lxml python3-lxml python3-pycurl python-virtualenv python-numpy python3-numpy python-scipy python3-scipy python-matplotlib python3-matplotlib python-pandas python3-pandas python-requests python3-requests python-nltk"
apt-get update
apt-get -y install $PKGS 

cp /vagrant/motd /etc/motd

cd /usr/src/

AUTOPROJECTS="ticcutils libfolia ucto timbl timblserver mbt frogdata frog"

for project in $AUTOPROJECTS; do
    echo "Installing $project">&2
    git clone https://github.com/proycon/$project
    cd ticcutils
    . bootstrap.sh || error "$project bootstrap failed"
    ./configure --prefix=/usr/ --sysconfdir=/etc --localstatedir=/var|| error "$project configure failed"
    make || error "$project make failed"
    make install || error "$project make install failed"
    cd ..
done

echo "Installing Python 2 packages">&2
pip install pynlpl FoLiA-tools clam 

echo "Installing Python 3 packages">&2
pip3 install pynlpl FoLiA-tools python-ucto foliadocserve 

echo "Installing python-timbl">&2
git clone https://github.com/proycon/python-timbl
cd python-timbl
python setup2.py build_ext --boost-library-dir=/usr/lib/x86_64-linux-gnu install
python3 setup3.py build_ext --boost-library-dir=/usr/lib/x86_64-linux-gnu install
cd ..

echo "Installing python-frog">&2
git clone https://github.com/proycon/python-frog
cd python-frog
python3 setup.py install
cd ..

echo "Installing colibri-core">&2
pip3 install --root / colibricore

echo "All done!">&2

