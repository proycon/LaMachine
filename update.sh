#!/bin/bash

echo "UPDATING LAMACHINE -- (This script should be run as root within the virtual machine)">&2

apt-get update && apt-get upgrade

cd /usr/src

AUTOPROJECTS="ticcutils libfolia ucto timbl timblserver mbt"

for project in $AUTOPROJECTS; do
    echo "Upgrading $project">&2
    cd $project
    git pull
    . bootstrap.sh && ./configure && make && make install
    cd ..
done


echo "Upgrading Python 2 packages">&2
pip install -U pynlpl FoLiA-tools clam 

echo "Upgrading Python 3 packages">&2
pip3 install -U pynlpl FoLiA-tools python-ucto foliadocserve 

cd python-timbl
rm -Rf build
git pull
python setup2.py build_ext --boost-library-dir=/usr/lib/x86_64-linux-gnu install
python3 setup3.py build_ext --boost-library-dir=/usr/lib/x86_64-linux-gnu install
cd ..

cd python-frog
rm -Rf *cpp build/
git pull
python setup.py install
cd ..

echo "Upgrading Colibri Core">&2
pip3 install -U --root / colibricore


