#!/bin/bash

error () {
    echo "An error occured during installation!" >&2
    echo $1 >&2
    exit 2
}

#will run as root
PKGS="pkg-config git-core make gcc g++ autoconf-archive libtool autotools-dev libicu-dev libxml2-dev libbz2-dev zlib1g-dev libtar-dev libboost-all-dev python-dev cython python3 python-pip python3-pip cython python3-requests python-lxml python3-lxml python3-pycurl python-virtualenv python-numpy python3-numpy python-scipy python3-scipy python-matplotlib python3-matplotlib python-pandas python3-pandas python-requests python3-requests python-nltk"
apt-get update
apt-get install $PKGS 

cp /vagrant/motd /etc/motd

cd /usr/src/

echo "Installing ticcutils">&2
git clone https://github.com/proycon/ticcutils
cd ticcutils
. bootstrap.sh || error "ticcutils bootstrap failed"
./configure --prefix=/usr/ --sysconfdir=/etc --localstatedir=/var|| error "ticcutils configure failed"
make || error "ticcutils make failed"
make install || error "ticcutils make install failed"
cd ..

echo "Installing libfolia">&2
git clone https://github.com/proycon/libfolia
cd libfolia
. bootstrap.sh || error "libfolia bootstrap failed"
./configure --prefix=/usr/ --sysconfdir=/etc --localstatedir=/var|| error "libfolia configure failed"
make || error "libfolia make failed"
make install || error "libfolia make install failed"
cd ..

echo "Installing ucto">&2
git clone https://github.com/proycon/ucto
cd ucto
. bootstrap.sh || error "ucto bootstrap failed"
./configure --prefix=/usr/ --sysconfdir=/etc --localstatedir=/var|| error "ucto configure failed"
make || error "ucto make failed"
make install || error "ucto make install failed"
cd ..

echo "Installing timbl">&2
git clone https://github.com/proycon/timbl
cd timbl
. bootstrap.sh || error "timbl bootstrap failed"
./configure --prefix=/usr/ --sysconfdir=/etc --localstatedir=/var|| error "timbl configure failed"
make || error "timbl make failed"
make install || error "timbl make install failed"
cd ..

echo "Installing timblserver">&2
git clone https://github.com/proycon/timblserver
cd timbl
. bootstrap.sh || error "timblserver bootstrap failed"
./configure --prefix=/usr/ --sysconfdir=/etc --localstatedir=/var|| error "timblserver configure failed"
make || error "timblserver make failed"
make install || error "timblserver make install failed"
cd ..

echo "Installing mbt">&2
git clone https://github.com/proycon/mbt
cd timbl
. bootstrap.sh || error "mbt bootstrap failed"
./configure --prefix=/usr/ --sysconfdir=/etc --localstatedir=/var|| error "mbt configure failed"
make || error "mbt make failed"
make install || error "mbt make install failed"
cd ..

echo "Installing frogdata">&2
git clone https://github.com/proycon/frogdata
cd timbl
. bootstrap.sh || error "frogdata bootstrap failed"
./configure --prefix=/usr/ --sysconfdir=/etc --localstatedir=/var || error "frog configure failed"
make || error "frogdata make failed"
make install || error "frogdata make install failed"

echo "Installing frog">&2
git clone https://github.com/proycon/frog
cd timbl
. bootstrap.sh || error "frog bootstrap failed"
./configure --prefix=/usr/ --sysconfdir=/etc --localstatedir=/var|| error "frog configure failed"
make || error "frog make failed"
make install || error "frog make install failed"

cd ..

echo "Installing Python 2 packages">&2
pip install pynlpl FoLiA-tools || error "error installing python 2 packages"

echo "Installing Python 3 packages">&2
pip3 install pynlpl FoLiA-tools colibri-core python3-timbl python-ucto || "error installing python 3 packages"

