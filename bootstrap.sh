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
echo "           ,              LaMachine v2 - NLP Software distribution"
echo "          ~)                     (http://proycon.github.io/LaMachine)"
echo "           (----í         Language Machines research group"
echo "            /| |\         Centre of Language and Speech Technology"
echo "           / / /|	        Radboud University Nijmegen "
echo "====================================================================="
echo

####################################################
#               Platform Detection
####################################################
ARCH=$(which pacman 2> /dev/null)
DEBIAN=$(which apt 2> /dev/null)
REDHAT=$(which yum 2> /dev/null)
if [ -f "$ARCH" ]; then
    OS='arch'
elif [ -f "$DEBIAN" ]; then
    OS='debian' #ubuntu too
elif [ -f "$REDHAT" ]; then
    OS='redhat'
else
    if [ ${OSTYPE//[0-9.]/} = "darwin" ]; then
        OS="mac"
        which brew 2>/dev/null
        if [ $? -ne 0 ]; then
            NEED+=("brew")
        fi
        if brew info brew-cask | grep "brew-cask" >/dev/null 2>&1 ; then
            echo
        else
            NEED+=("brew-cask")
        fi

    else
        OS="unknown"
    fi
fi

DISTRIB_ID="unknown"
DISTRIB_RELEASE="unknown"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRIB_ID="$ID"
    DISTRIB_RELEASE="$VERSION_ID"
elif [ -f /etc/lsb-release ]; then
    . /etc/lsb-release
fi

echo "Detected OS: $OS"
echo "Detected distribution ID: $DISTRIB_ID"
echo "Detected distribution release: $DISTRIB_RELEASE"
echo

NEED=() #list of needed packages

#get source directory of current script and set as default LaMachine SOURCEDIR
SOURCEDIR="${BASH_SOURCE[0]}"
while [ -h "$SOURCEDIR" ]; do # resolve $SOURCEDIR until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCEDIR" )" && pwd )"
  SOURCEDIR="$(readlink "$SOURCEDIR")"
  [[ $SOURCEDIR != /* ]] && SOURCEDIR="$DIR/$SOURCEDIR" # if $SOURCEDIR was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
cd $SOURCEDIR


while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -n|--name)
        NAME="$2"
        shift # past argument
        shift # past value
        ;;
        -c|--config)
        CONFIGFILE="$2"
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
        --env) #conda or virtualenv
        LOCALENV_TYPE="$2"
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

echo "Welcome to the LaMachine Installation tool, we will ask some questions how"
echo "you want your LaMachine to be installed."
echo

which wget 2>/dev/null
if [ $? -eq 0 ]; then
    DL=wget
else
    which curl 2>/dev/null
    if [ $? -eq 0 ]; then
        DL=curl
    else
        echo "No download tool was found on your system! Please install wget or curl first...">&2
        exit 2
    fi
fi

if [ -z "$FLAVOUR" ]; then
    while true; do
        echo "Where do you want to install LaMachine?"
        echo "  1) in a Virtual Machine"
        echo "       complete separation from the host OS"
        echo "       (uses Vagrant and VirtualBox)"
        echo "  2) in a Docker container"
        echo "       (uses Docker and Ansible)"
        echo "  3) in a local user environment"
        echo "       installs as much as possible in a separate directory"
        echo "       for a particular user, can exists alongside existing"
        echo "       installations"
        echo "       (uses conda or virtualenv)"
        echo "  4) Globally on this machine"
        echo "       modifies the existing system and may"
        echo "       interact with existing packages"
        echo "  5) On a remote server"
        echo "       modifies the existing remote system!"
        echo "       (uses ansible)"
        echo -n "Your choice [12345]? "
        read choice
        case $choice in
            [1]* ) FLAVOUR=vagrant; break;;
            [2]* ) FLAVOUR=docker; break;;
            [3]* ) FLAVOUR=env; break;;
            [4]* ) FLAVOUR=global; break;;
            [5]* ) FLAVOUR=server; break;;
            * ) echo "Please answer with the corresponding number of your preference..";;
        esac
    done
fi

PREFER_GLOBAL=0
if [[ "$FLAVOUR" == "env" ]] || [[ "$FLAVOUR" == "global" ]]; then
    if [ -z "$LOCALENV_TYPE" ]; then
        echo "We support two forms of local user environments:"
        echo "  1) Using conda"
        echo "       provided by the Anaconda Distribution, a powerful data science platform (mostly for Python and R)"
        echo "  2) Using virtualenv"
        echo "       A simpler solution (originally for Python but extended by us)"
        if [ "$FLAVOUR" != "env" ]; then
            echo "  0) Use none at all - Install everything globally"
        fi
        while true; do
            echo -n "What form of local user environment do you want [12]? "
            read choice
            case $choice in
                [1]* ) LOCALENV_TYPE=conda; break;;
                [2]* ) LOCALENV_TYPE=virtualenv; break;;
                [0]* ) LOCALENV_TYPE=conda; PREFER_GLOBAL=1; break;;
                * ) echo "Please answer with the corresponding number of your preference..";;
            esac
        done
    fi
fi

if [ -z "$VERSION" ]; then
    echo "LaMachine comes in several versions:"
    echo " 1) a stable version, you get the latest releases deemed stable (recommended)"
    echo " 2) a development version, you get the very latest development versions for testing, this may not always work as expected!"
    echo " 3) custom version, you decide explicitly what exact versions you want (for reproducibility)."
    echo "    this expects you to provide a LaMachine version file with exact version numbers."
    while true; do
        echo -n "Which version do you want to install?"
        read choice
        case $choice in
            [1]* ) VERSION=stable; break;;
            [2]* ) VERSION=development; break;;
            [3]* ) VERSION=custom; break;;
            * ) echo "Please answer with the corresponding number of your preference..";;
        esac
    done
fi

if [ "$FLAVOUR" == "vagrant" ]; then
    which vagrant 2>/dev/null
    if [ $? -eq 1 ]; then
        NEED+=("vagrant")
    fi
fi

if [ "$FLAVOUR" == "docker" ]; then
    which docker 2>/dev/null
    NEED=()
    if [ $? -eq 1 ]; then
        NEED+=("docker")
    fi
    which ansible 2>/dev/null
    if [ $? -eq 1 ]; then
        NEED+=("ansible")
    fi
fi

SUDO=0
while true; do
    echo
    echo "The installation relies on certain software to be available on your (host)"
    echo "system. It will be automatically obtained from your distribution's package manager"
    echo "or another official source whenever possible. You need to have sudo permission for this though..."
    echo
    echo -n "Do you have administrative access (root/sudo) on the current system? [yn]"
    read yn
    case $yn in
        [Yy]* ) SUDO=1; break;;
        [Nn]* ) SUDO=0 exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

if [ $SUDO -eq 0 ]; then
    PREFER_LOCAL=1
fi



for package in $NEED; do
    if [ "$package" = "vagrant" ]; then
        if [ "$OS" = "debian" ]; then
            cmd="sudo apt install virtualbox vagrant"
        elif [ "$OS" = "redhat" ]; then
            cmd="sudo yum install virtualbox vagrant"
        elif [ "$OS" = "arch" ]; then
            cmd="sudo pacman -Sy virtualbox vagrant"
        elif [ "$OS" = "mac" ]; then
            cmd="brew install brew-cask && brew cask install virtualbox vagrant"
        else
            cmd=""
        fi
        echo "Vagrant and Virtualbox are required for your flavour of LaMachine but are not installed yet. Install automatically?"
        if [ ! -z "$cmd" ]; then
            while true; do
                echo -n "Run: $cmd ? [yn]"
                read yn
                case $yn in
                    [Yy]* ) $cmd; break;;
                    [Nn]* ) echo "Please install vagrant manually from https://www.vagrantup.com/downloads.html and VirtualBox from https://www.virtualbox.org/" && echo " .. press ENTER when done or CTRL-C to abort..." && read; break;;
                    * ) echo "Please answer yes or no.";;
                esac
            done
        else
            echo "No automated installation possible on your OS."
            echo "Please install vagrant manually from https://www.vagrantup.com/downloads.html and VirtualBox from https://www.virtualbox.org/" && echo " .. press ENTER when done or CTRL-C to abort..." && read
        fi
    elif [ "$package" = "docker" ]; then
        echo "We expect users of docker to be able to install docker themselves."
        echo "Docker was not found on your system yet."
        echo "Please install docker and press ENTER to continue (or CTRL-C) to abort."
        read
    elif [ "$package" = "brew" ]; then
        echo "Homebrew (https://brew.sh) is required on Mac OS X but was not found yet"
        while true; do
            echo -n "Download and install homebrew? [yn]"
            read yn
            case $yn in
                [Yy]* ) break;;
                [Nn]* ) echo "Unable to continue without homebrew, see https://brew.sh/"; exit 2;;
                * ) echo "Please answer yes or no.";;
            esac
        done
        /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
        brew install brew-cask
    elif [ "$package" = "brew-cask" ]; then
        echo "Installing brew-cask"
        brew install brew-cask
    fi
done

if [ -z "$NAME" ]; then
    echo "Your LaMachine installation is identified by a name (used as hostname, local env name, VM name) etc.."
    echo -n "Enter a name for your LaMachine installation: "
    read NAME
    NAME="${NAME%\\n}"
fi

CONFIGFILE="host-vars/$NAME.yml"

if [ ! -f "$CONFIGFILE" ]; then
    echo "---
hostname: \"$NAME\" #(for VM or docker, doesn't change hostname on existing systems)
env_name: \"$NAME\" #(for local user environment)
version: \"$VERSION\" #stable, development or custom
lamachine_path: \"$SOURCEDIR\" #LaMachine source path (on host machine)
localenv_type: \"$LOCALENV_TYPE\" #Local environment type (conda or virtualenv), not used when prefer_global is true
" > $CONFIGFILE
    if [ $PREFER_GLOBAL -eq 1 ]; then
        echo "prefer_global: true #Install everything globally" >> $CONFIGFILE
    else
        echo "prefer_global: false #Install everything globally" >> $CONFIGFILE
    fi
    if [[ $FLAVOUR == "vagrant" ]] || [[ $FLAVOUR == "docker" ]]; then
        echo "prefer_local: false #Install everything in a local user environment" >> $CONFIGFILE
        echo "root: true #Do you have root on the target system?" >> $CONFIGFILE
    elif [ $SUDO -eq 0 ]; then
        echo "prefer_local: true #Install everything in a local user environment" >> $CONFIGFILE
        echo "root: false #Do you have root on the target system?" >> $CONFIGFILE
    else
        echo "prefer_local: false #Install everything globally" >> $CONFIGFILE
        echo "root: true #Do you have root on the target system?" >> $CONFIGFILE
    fi
    if [[ $FLAVOUR == "vagrant" ]]; then
        echo "vm_memory: 6096 #Reserved memory for VM">> $CONFIGFILE
        echo "vm_cpus: 2 #Reserved number of CPU cores for VM">>$CONFIGFILE
    fi
echo "webserver: true #include a webserver
port: 80 #webserver port (for VM or docker)
mapped_port: 8080 #mapped webserver port on host system (for VM or docker)
#Adapt install.yml to select the packages you want to install" >> $CONFIGFILE
fi



if [[ "$FLAVOUR" == "vagrant" ]]; then
    echo "Building VM"
    vagrant up
else
    if [ ! -d lamachine.control.env ]; then
        echo "Setting up control environment..."
        virtualenv --python=python2.7 lamachine.control.env
        source lamachine.control.env/bin/activate
        pip install ansible
    fi
fi


