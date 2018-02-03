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

echo "====================================================================="
echo "           ,              LaMachine - NLP Software distribution"
echo "          ~)                     (http://proycon.github.io/LaMachine)"
echo "           (----í         Language Machines research group"
echo "            /| |\         Centre of Language and Speech Technology"
echo "           / / /|	        Radboud University Nijmegen "
echo "====================================================================="
echo

echo "Looking for construction dependencies ..."

which ansible
ANSIBLE=$?
which ansible_galaxy
ANSIBLE_GALAXY=$?
which vagrant
VAGRANT=$?
which conda
CONDA=$?

#Assume we are on the host system, do not bootstrap directly on this machine, but enable a more interactive mode
#that will invoke either vagrant, docker, or conda
TARGET=""
VERSION="stable"
#get source directory of current script and set as default LaMachine SOURCEDIR
SOURCEDIR="${BASH_SOURCE[0]}"
while [ -h "$SOURCEDIR" ]; do # resolve $SOURCEDIR until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCEDIR" )" && pwd )"
  SOURCEDIR="$(readlink "$SOURCEDIR")"
  [[ $SOURCEDIR != /* ]] && SOURCEDIR="$DIR/$SOURCEDIR" # if $SOURCEDIR was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCEDIR" )" && pwd )"

while [[ $# -gt 0 ]]; do
key="$1"

case $key in
	-t|--target)
    TARGET="$2" #target will be localhost when provisioning inside a docker container or VM
    shift # past argument
    shift # past value
    ;;
    -f|--flavour|--flavor)
    FLAVOUR="$2"
    shift # past argument
    shift # past value
    ;;
    -v|--version) #stable or development
    VERSION="$2"
    shift # past argument
    shift # past value
    ;;
    --source) #LaMachine source path
    SOURCEDIR="$2"
    shift # past argument
    shift # past value
    ;;
    *)    # unknown option
	echo "Unknown option: $1">&2
	exit 2
    ;;
esac
done


if [[ ! -z "$TARGET" ]]; then
	#we have no target, this usually means we have been called directly by a user
    #for the first time and are not inside a VM, container, or conda environment yet
	#present the user with a choice interactively
	echo  "(No target specified yet)">&2
fi


echo "Installing ansible-galaxy requirements...">&2
ansible-galaxy install -r requirements.yml --roles-path roles


#vagrant plugin install vagrant-vbguest
