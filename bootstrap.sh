#!/bin/bash
#======================================
# LaMachine v2
#  by Maarten van Gompel
#  Centre for Language Studies
#  Radboud University Nijmegen
#
# https://proycon.github.io/LaMachine
# Licensed under GPLv3
#=====================================

export LC_ALL=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8

bold=$(tput bold)
boldred=${bold}$(tput setaf 1) #  red
boldgreen=${bold}$(tput setaf 2) #  green
boldblue=${bold}$(tput setaf 4) #  blue
normal=$(tput sgr0)

echo "${bold}=====================================================================${normal}"
echo "           ,              ${bold}LaMachine v2.4.5${normal} - NLP Software distribution" #NOTE FOR DEVELOPER: also change version number in codemeta.json *AND* roles/lamachine-core/defaults/main.yml -> lamachine_version!
echo "          ~)                     (http://proycon.github.io/LaMachine)"
echo "           (----í         Language Machines research group"
echo "            /| |\         Centre of Language and Speech Technology"
echo "           / / /|	        Radboud University Nijmegen "
echo "${bold}=====================================================================${normal}"
echo

usage () {
    echo "bootstrap.sh [options]"
    echo " ${bold}--flavour${normal} [vagrant|docker|local|global|remote] - Determines the type of LaMachine installation"
    echo "  vagrant = in a Virtual Machine"
    echo "       complete separation from the host OS"
    echo "       (uses Vagrant and VirtualBox)"
    echo "  docker = in a Docker container"
    echo "       (uses Docker and Ansible)"
    echo "  local = in a local user environment"
    echo "       installs as much as possible in a separate directory"
    echo "       for a particular user, can exists alongside existing"
    echo "       installations, allows multiple parallel installations."
    echo "       (uses virtualenv)"
    echo "  global = Globally on this machine"
    echo "       modifies the existing system and may"
    echo "       interact with existing packages"
    echo "       can only be used once per machine"
    echo "  remote = On a remote server"
    echo "       modifies the existing remote system and"
    echo "       interacts with existing packages"
    echo "       can only be used once per remote machine"
    echo "       (uses ansible)"
    echo " ${bold}--version${normal} [stable|development|custom] - Determines the version of software installed"
    echo "  stable = you get the latest releases deemed stable (recommended)"
    echo "  development = you get the very latest development versions for testing, this may not always work as expected!"
    echo "  custom = you decide explicitly what exact versions you want (for reproducibility)."
    echo "           this expects you to provide a LaMachine version file (customversions.yml) with exact version numbers."
    echo " ${bold}--prebuilt${normal} - Download a pre-built image rather than building a new one from scratch (for Docker or Vagrant)"
    echo " ${bold}--name${normal} - A name for your LaMachine installation, will be reflected in hostnames and directory names"
    #echo " ${bold}--env${normal} [virtualenv] - Local user environment type"
    #echo "  virtualenv = A simple virtual environment"
    echo " ${bold}--private${normal} - Do not transmit anonymous analytics on this LaMachine build"
    echo " ${bold}--minimal${normal} - Attempt to install less than normal, leaving out extra options. This may break things."
    echo " ${bold}--prefer_distro${normal} - Prefer distribution packages over other channels (such as pip). This generally installs more conserative versions, and less, but might break things."
    echo " ${bold}--dockerrepo${normal} - Docker repository name (default: proycon/lamachine)"
    echo " ${bold}--install${normal} - Provide an explicit comma separated list of LaMachine roles to install (instead of querying interactively or just taking the default)"
    echo " ${bold}--vmmem${normal} - Memory to reserve for virtual machine"
    echo " ${bold}--external${normal} - Use an external/shared/remote controller for updating LaMachine. This is useful for development/testing purposes and remote production environment"
    echo " ${bold}--hostname${normal} - Hostname (or fully qualified domain name) for the target system"
    echo " ${bold}--username${normal} - Username (or fully qualified domain name) for the target system"
    echo " ${bold}--targetdir${normal} - Set a target directory for local environment creation, this should be an existing path and the local environment will be created under it. Defaults to current working directory."
    echo " ${bold}--services${normal} - Preset enabled services (comma seperated list). Default: all"
    echo " ${bold}--force${normal} - Preset a default force parameter (set to 1 or 2). Note that this will take effect on ANY subsequent update!"
    echo " ${bold}--disksize${normal} - Sets extra disksize for VMs; you'll want to use  this if you plan to include particularly large software and exceed the default 8GB"
}

USER_SET=0 #explicitly set?
USERNAME=$(whoami)
GROUP=$(id -gn $USERNAME)
HOSTNAME=""

fatalerror () {
    echo "${bold}================ FATAL ERROR ==============${normal}" >&2
    echo "An error occurred during installation!!" >&2
    echo "${boldred}$1${normal}" >&2
    echo "${bold}===========================================${normal}" >&2
    echo "$1" > error
    exit 2
}


#The base directory is the directory where the bootstrap is downloaded/executed
#It will be the default directory for data sharing, will host some configuration files
#and will contain a lamachine-controller environment
BASEDIR=$(pwd)
cd $BASEDIR
if [ -d .git ] && [ -e bootstrap.sh ]; then
    #we are in a LaMachine git repository already
    SOURCEDIR=$BASEDIR
fi


if [ ! -z "$LM_NAME" ]; then
    fatalerror "Inception error: Do not run the LaMachine bootstrap from within an existing LaMachine! (deactivate first!)"
fi
if [ ! -z "$VIRTUAL_ENV" ]; then
    fatalerror "Inception error: Do not run the LaMachine bootstrap from within an existing Python Virtual Environment! (deactivate first!)"
fi
if [ ! -z "$CONDA_PREFIX" ]; then
    fatalerror "Inception error: Do not run the LaMachine bootstrap when you are inside an Anaconda environment (run 'source deactivate' first)"
fi

if which python; then
    echo "Checking sanity of your Python installation..."
    python -c "from __future__ import print_function; import sys; print(sys.version)" | grep -i anaconda
    if [ $? -eq 0 ]; then
        fatalerror "Conflict error: The default Python on this system is managed by Anaconda, this is incompatible with LaMachine. Ensure the Python found in your \$PATH corresponds to a regular version as supplied with your OS, editing the order of your \$PATH in ~/.bashrc or ~/.bash_profile should be sufficient to solve this without completely uninstalling anaconda. See also https://stackoverflow.com/a/37377981/3311445"
    fi
else
    fatalerror "No Python found! However, python should be available by default on all supported platforms; please install it yourself through your package manager (and ensure it is in your \$PATH)"
fi
echo ""

####################################################
#               Platform Detection
####################################################
NEED=() #list of needed packages
if [ "${OSTYPE//[0-9.]/}" = "darwin" ]; then
    OS="mac"
    if which xcode-select; then
        if xcode-select --install; then
            echo "${bold}LaMachine requires the XCode Command Line Tools, please follow the instructions in the pop-up dialog and press ENTER here when that installation is completed${normal}"
            read choice
        fi
    fi
else
    OS="unknown"
fi

DISTRIB_ID="unknown"
DISTRIB_RELEASE="unknown"
if [ -e /etc/os-release ]; then
    . /etc/os-release
    DISTRIB_ID="$ID"
    DISTRIB_RELEASE="$VERSION_ID"
elif [ -e /etc/lsb-release ]; then
    . /etc/lsb-release
fi
DISTRIB_ID=$(echo "$DISTRIB_ID" | tr '[:upper:]' '[:lower:]')
if [ "$OS" = "unknown" ]; then
    if [ "$DISTRIB_ID" = "arch" ] || [ "$DISTRIB_ID" = "debian" ] || [ "$DISTRIB_ID" = "redhat" ]; then #first class
        OS=$DISTRIB_ID
    elif [ "$DISTRIB_ID" = "ubuntu" ] || [ "$DISTRIB_ID" = "linuxmint" ]; then
        OS="debian"
    elif [ "$DISTRIB_ID" = "centos" ] || [ "$DISTRIB_ID" = "fedora" ] || [ "$DISTRIB_ID" = "rhel" ]; then
        OS="redhat"
    fi
fi
if grep -q Microsoft /proc/version 2> /dev/null; then
  echo "(Windows Linux Subsystem detected)">&2
  WINDOWS=1 #we are running in the Windows Linux Subsystem
else
  WINDOWS=0
fi
if [ "$OS" = "unknown" ]; then
    echo "(Fallback: Detecting OS by finding installed package manager...)">&2
    ARCH=$(which pacman 2> /dev/null)
    DEBIAN=$(which apt-get 2> /dev/null)
    REDHAT=$(which yum 2> /dev/null)
    if [ -e "$ARCH" ]; then
        OS='arch'
    elif [ -e "$DEBIAN" ]; then
        OS='debian' #ubuntu too
    elif [ -e "$REDHAT" ]; then
        OS='redhat'
    else
        echo "Unable to detect a supported OS! Perhaps your distribution is not yet supported by LaMachine? Please contact us!">&2
        exit 2
    fi
fi
SERVICES="all"
VERSION="undefined" # we set this because it might have been overriden by the distro
INTERACTIVE=1
LOCALITY=""
PRIVATE=0
ANSIBLE_OPTIONS="-v"
MINIMAL=0
FORCE=0
PREFER_DISTRO=0
NOSYSUPDATE=0
VMMEM=4096
DISKSIZE=0 #for extra disk in VM (in GB)
VAGRANTBOX="debian/contrib-stretch64" #base distribution for VM
DOCKERREPO="proycon/lamachine"
CONTROLLER="internal"
BUILD=1

echo "Detected OS: $OS"
echo "Detected distribution ID: $DISTRIB_ID"
echo "Detected distribution release: $DISTRIB_RELEASE"
echo


#Test if we come from LaMachine v1 VM/Docker
if [ "$OS" = "arch" ] && [ -e /usr/src/LaMachine ]; then
    echo "${boldred}Automated upgrade from LaMachine v1 not possible${normal}"
    echo "A new major LaMachine version (v2) has been released in early 2018."
    echo "You are currently on the older v1. Due to many changes a direct upgrade path was not feasible."
    echo "It is easier to simply build a new LaMachine Virtual Machine or Docker Container."
    echo "We recommend you remove this VM or container and "
    echo "obtain the latest version by following the instructions on"
    echo "the LaMachine website at https://proycon.github.io/LaMachine ."
    exit 6
fi

if [[ "$USERNAME" == "root" ]]; then
    fatalerror "Do not run the LaMachine bootstrap process as root!" #we can't do this message earlier because people coming from LaMachine v1 do run as root sometimes
fi



while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -n|--name)
        LM_NAME="$2"
        shift # past argument
        shift # past value
        ;;
        -c|--config)
        STAGEDCONFIG="$2"
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
        -b|--branch) #branch of LaMachine git
        BRANCH="$2"
        shift # past argument
        shift # past value
        ;;
        --gitrepo) #git repository of LaMachine
        GITREPO="$2"
        shift # past argument
        shift # past value
        ;;
        --env) #conda or virtualenv
        LOCALENV_TYPE="$2"
        shift # past argument
        shift # past value
        ;;
        --source) #LaMachine source path
        BASEDIR="$2"
        SOURCEDIR="$2"
        shift # past argument
        shift # past value
        ;;
        --noroot|--noadmin) #Script mode
        LOCALITY=local
        SUDO=0
        shift
        ;;
        --vagrantbox) #LaMachine source path
        VAGRANTBOX="$2"
        shift # past argument
        shift # past value
        ;;
        --dockerrepo) #Docker repo (proycon/lamachine)
        DOCKERREPO="$2"
        shift # past argument
        shift # past value
        ;;
        --install)
        INSTALL="$2"
        shift # past argument
        shift # past value
        ;;
        -B|--prebuilt)
        BUILD=0
        shift
        ;;
        --noninteractive) #Script mode
        INTERACTIVE=0
        shift
        ;;
        --private) #private, do not send LaMachine build analytics
        PRIVATE=1
        shift
        ;;
        --minimal)
        MINIMAL=1
        shift
        ;;
        --external)
        CONTROLLER="external"
        shift
        ;;
        --prefer-distro)
        PREFER_DISTRO=1
        shift
        ;;
        --extra) #extra ansible parameters
        ANSIBLE_OPTIONS="$ANSIBLE_OPTIONS --extra-vars $2"
        shift
        shift
        ;;
        --hostname)
        HOSTNAME="$2"
        shift
        shift
        ;;
        --username)
        USER_SET=1
        USERNAME="$2"
        shift
        shift
        ;;
        --targetdir)
        TARGETDIR="$2"
        shift
        shift
        ;;
        --force)
        FORCE="$2"
        shift
        shift
        ;;
        --nosysupdate)
        NOSYSUPDATE=1
        shift
        ;;
        --services)
        SERVICES="$2"
        shift
        shift
        ;;
        --disksize)
        DISKSIZE="$2"
        shift
        shift
        ;;
        --vmmem) #extra ansible parameters
        VMMEM=$2
        shift
        shift
        ;;
        --quiet)
        ANSIBLE_OPTIONS=""
        shift
        ;;
        --verbose)
        ANSIBLE_OPTIONS="-vv"
        shift
        ;;
        -h|--help)
        usage
        exit 0
        shift
        ;;
        *)    # unknown option
        echo "Unknown option: $1">&2
        exit 2
        ;;
    esac
done

if [ $INTERACTIVE -eq 1 ]; then
    echo
    echo "Welcome to the LaMachine Installation tool, we will ask some questions how"
    echo "you want your LaMachine to be installed and guide you towards the installation"
    echo "of any software that is needed to complete this installation."
    echo
fi


if [ -z "$FLAVOUR" ]; then
    while true; do
        echo "${bold}Where do you want to install LaMachine?${normal}"
        echo "  1) in a local user environment"
        echo "       installs as much as possible in a separate directory"
        echo "       for a particular user; can exists alongside existing"
        echo "       installations. May also be used (limited) by multiple"
        echo "       users/groups if file permissions allow it. Can work without"
        echo "       root but only if all global dependencies are already satisfied."
        echo "       (uses virtualenv)"
        if [ $WINDOWS -eq 0 ]; then
        echo "  2) in a Virtual Machine"
        echo "       complete separation from the host OS"
        echo "       (uses Vagrant and VirtualBox)"
        echo "  3) in a Docker container"
        echo "       (uses Docker and Ansible)"
        fi
        echo "  4) Globally on this machine"
        echo "       dedicates the entire machine to LaMachine and"
        echo "       modifies the existing system and may"
        echo "       interact with existing packages. Usually requires root."
        echo "  5) On a remote server"
        echo "       modifies an existing remote system! Usually requires root."
        echo "       (uses ansible)"
        echo -n "${bold}Your choice?${normal} [12345] "
        read choice
        case $choice in
            [1]* ) FLAVOUR="local"; break;;
            [2]* ) FLAVOUR="vagrant";  break;;
            [3]* ) FLAVOUR="docker";  break;;
            [4]* ) FLAVOUR="global";  break;;
            [5]* ) FLAVOUR="remote"; break;;
            * ) echo "Please answer with the corresponding number of your preference..";;
        esac
    done
fi

if [[ "$FLAVOUR" == "vm" ]]; then #alias
    FLAVOUR="vagrant"
elif [[ "$FLAVOUR" == "remote" ]]; then #alias
    CONTROLLER="external"
fi

if [[ $INTERACTIVE -eq 1 ]] && [[ $WINDOWS -eq 0 ]]; then
  if [[ "$FLAVOUR" == "vagrant" || "$FLAVOUR" == "docker" ]]; then
    while true; do
        echo "${bold}Do you want to build a new personalised LaMachine image or use and download a prebuilt one?${normal}"
        echo "  1) Build a new image"
        echo "       Offers most flexibility and ensures you are on the latest versions."
        echo "       Allows you to choose even for development versions or custom versions."
        echo "       Allows you to choose what software to include from scratch."
        echo "       Best integration with your custom data."
        echo "  2) Download a prebuilt one"
        echo "       Comes with a fixed selection of software, allows you to update with extra software later."
        echo "       Fast & easy but less flexible"
        echo -n "${bold}Your choice?${normal} [12] "
        read choice
        case $choice in
            [1]* ) break;;
            [2]* ) BUILD=0;  break;;
            * ) echo "Please answer with the corresponding number of your preference..";;
        esac
    done

    if [[ "$FLAVOUR" == "vagrant" ]] && [ $BUILD -eq 1 ] && [ $DISKSIZE -eq 0 ]; then
        echo "${bold}Allocate extra diskspace?${normal}"
        echo "  The standard LaMachine disk is limited in size (about 9GB). If you plan to include certain very large software"
        echo "  collections that LaMachine offers (such as kaldi, valkuil) then this is not sufficient and"
        echo "  you need to allocate an extra virtual disk, specify the size below:"
        echo "  Just enter 0 if you do not need this; you don't need this for the default selection of software."
        echo -n "${bold}How much extra diskspace to reserve?${normal} [0 or size in GB] "
        read choice
        case $choice in
            [0-9]* ) DISKSIZE=$choice;;
            * ) echo "Please answer with the corresponding size in GB (use 0 if you don't need an extra disk)";;
        esac
    elif [[ "$FLAVOUR" == "docker" ]] && [ $BUILD -eq 1 ] && [ $DISKSIZE -eq 0 ]; then
        echo "${bold}Container diskspace${normal}"
        echo "  A standard docker container is limited in size (usually 10GB). If you plan to include certain very large optional software"
        echo "  collections that LaMachine offers (such as kaldi, valkuil) then this is not sufficient and"
        echo "  you need to increase the base size of your containers (depending on the storage driver you use for docker)."
        echo "  Consult the docker documentation at https://docs.docker.com/storage/storagedriver/ and do so now if you need this."
        echo "  You don't need this for the default selection of software."
        echo -n "${bold}Press ENTER when ready to continue${normal}"
        read choice
    fi
  fi
fi


if [ -z "$LOCALITY" ]; then
    if [[ "$FLAVOUR" == "local" ]]; then
        LOCALITY="local"
    else
        LOCALITY="global"
    fi
fi


if [[ "$LOCALITY" == "local" ]]; then
    if [ -z "$LOCALENV_TYPE" ]; then
        LOCALENV_TYPE="virtualenv"
        #echo "${bold}We support two forms of local user environments:${normal}"
        #echo "  1) Using virtualenv"
        #echo "       (originally for Python but extended by us)"
        #echo "  2) Using conda"
        #echo "       provided by the Anaconda Distribution, a powerful data science platform (mostly for Python and R)"
        #while true; do
        #    echo -n "${bold}What form of local user environment do you want?${normal} [12] "
        #    read choice
        #    case $choice in
        #        [1]* ) LOCALENV_TYPE=virtualenv; break;;
        #        [2]* ) LOCALENV_TYPE=conda; break;;
        #        * ) echo "Please answer with the corresponding number of your preference..";;
        #    esac
        #done
    fi

    if [ $INTERACTIVE -ne 0 ]; then
        echo "${bold}Where do you want to create the local user environment?${normal}"
        echo " By default, a directory will be created under your current location, which is $(pwd)"
        echo " If this is what you want, just press ENTER, "
        echo " Otherwise, type a new existing path: "
        echo -n "${bold}Where do you want to create the local user environment?${normal} [press ENTER for $(pwd)] "
        read TARGETDIR
        if [ ! -z "$TARGETDIR" ]; then
            mkdir -p $TARGETDIR >/dev/null 2>/dev/null
            cd $TARGETDIR || fatalerror "Specified target directory does not exist"
            BASEDIR="$TARGETDIR"
        fi
    elif [ ! -z "$TARGETDIR" ]; then
        cd $TARGETDIR || fatalerror "Specified target directory does not exist"
        BASEDIR="$TARGETDIR"
    fi
fi

touch x || fatalerror "Directory $(pwd) is not writable for the current user! Run the bootstrap somewhere where you can write!"
rm x

if [ -z "$LOCALENV_TYPE" ]; then
    LOCALENV_TYPE="virtualenv"
fi


if [ $BUILD -eq 1 ]; then
    if [[ "$VERSION" == "undefined" ]]; then
        echo "${bold}LaMachine comes in several versions:${normal}"
        echo " 1) a stable version; you get the latest releases deemed stable (recommended)"
        echo " 2) a development version; you get the very latest development versions for testing, this may not always work as expected!"
        echo " 3) custom version; you decide explicitly what exact versions you want (for reproducibility);"
        echo "    this expects you to provide a LaMachine version file (customversions.yml) with exact version numbers."
        if [[ "$OS" == "mac" ]]; then
            echo "    NOTE: CUSTOM VERSIONING IS NOT SUPPORTED ON MAC OS X!"
        fi
        while true; do
            echo -n "${bold}Which version do you want to install?${normal} [123] "
            read choice
            case $choice in
                [1]* ) VERSION=stable; break;;
                [2]* ) VERSION=development; break;;
                [3]* ) VERSION=custom; break;;
                * ) echo "Please answer with the corresponding number of your preference..";;
            esac
        done
    fi
fi

if [ -z "$BRANCH" ]; then
    if [[ "$VERSION" == "development" ]]; then
        BRANCH="master"
    else
        BRANCH="master"
    fi
fi
if [ -z "$GITREPO" ]; then
    GITREPO="https://github.com/proycon/LaMachine"
fi

if [ -z "$SUDO" ]; then
    if [ $INTERACTIVE -eq 0 ]; then
        SUDO=1 #assume root (use --noadmin option otherwise)
    else
        while true; do
            echo
            echo "The installation relies on certain software to be available on your (host)"
            echo "system. It will be automatically obtained from your distribution's package manager"
            echo "or another official source whenever possible. You need to have sudo permission for this though..."
            echo "${red}Answering 'no' to this question may make installation on your system impossible!${normal}"
            echo
            echo -n "${bold}Do you have administrative access (root/sudo) on the current system?${normal} [yn] "
            read yn
            case $yn in
                [Yy]* ) SUDO=1; break;;
                [Nn]* ) SUDO=0; break;;
                * ) echo "Please answer yes or no.";;
            esac
        done
    fi
fi

echo "Looking for dependencies..."
if [ $BUILD -eq 0 ]; then
    NEED_VIRTUALENV=0 #Do we need a virtualenv with ansible for the controller? Never needed if we are not building ourselves
else
    if ! which git; then
        NEED+=("git")
    fi
    if [ "$FLAVOUR" = "docker" ]; then
        NEED_VIRTUALENV=0 #Do we need a virtualenv with ansible for the controller? Never for docker, all ansible magic happens inside the docker container
    else
        NEED_VIRTUALENV=1 #Do we need a virtualenv with ansible for the controller? (this is a default we will attempt to falsify)
        if which ansible-playbook; then
            NEED_VIRTUALENV=0
        elif [ $SUDO -eq 1 ]; then #we can only install ansible globally if we have root
            if [ "$OS" != "mac" ]; then #pip is preferred on mac
                if [ "$DISTRIB_ID" = "centos" ] || [ "$DISTRIB_ID" = "rhel" ]; then
                    NEED+=("epel") #ansible is in  EPEL
                fi
                NEED+=("ansible")
                NEED_VIRTUALENV=0
            fi
        fi
        if [ $NEED_VIRTUALENV -eq 1 ]; then
            if ! which pip; then
                if [ "$DISTRIB_ID" = "centos" ] || [ "$DISTRIB_ID" = "rhel" ]; then
                    NEED+=("epel") #python-pip is in  EPEL
                fi
                NEED+=("pip")
            fi
            if ! which virtualenv; then
                NEED+=("virtualenv")
            fi
        fi
    fi
fi
if [ -z "$EDITOR" ]; then
    if which nano; then
        EDITOR=nano
    else
        EDITOR=vi
    fi
fi
if [[ "$OS" == "mac" ]]; then
    if ! which brew; then
        NEED+=("brew")
    fi
    NEED+=("brew-cask")
fi
if [ ! -z "$NEED" ]; then
    echo " Missing dependencies: ${NEED[@]}"
fi

if [ "$FLAVOUR" == "vagrant" ]; then
    echo "Looking for vagrant..."
    if ! which vagrant; then
        NEED+=("vagrant")
        NEED+=("vbguest")
        #NEED+=("vagrant-disksize")
    else
        echo "Checking available vagrant plugins"
        if vagrant plugin list | grep vbguest; then
            echo "ok"
        else
            NEED+=("vbguest")
        fi
        #if vagrant plugin list | grep disksize; then
        #    echo "ok"
        #else
        #    NEED+=("vagrant-disksize")
        #fi
    fi
fi

if [ "$FLAVOUR" == "docker" ]; then
    echo "Looking for docker..."
    if ! which docker; then
        if ! which docker.io; then
            NEED+=("docker")
        fi
    fi
fi



NONINTERACTIVEFLAGS=""
if [ "$INTERACTIVE" -eq 0 ]; then
    if [ "$OS" = "debian" ]; then
        NONINTERACTIVEFLAGS="-m -y"
    elif [ "$OS" = "redhat" ]; then
        NONINTERACTIVEFLAGS="-y"
    elif [ "$OS" = "arch" ]; then
        NONINTERACTIVEFLAGS="--noconfirm"
    fi
fi


for package in ${NEED[@]}; do
    if [ "$package" = "vagrant" ]; then
        if [ "$OS" = "debian" ]; then
            cmd="sudo apt-get $NONINTERACTIVEFLAGS install virtualbox vagrant"
        elif [ "$OS" = "redhat" ]; then
            cmd="sudo yum $NONINTERACTIVEFLAGS install virtualbox vagrant"
        elif [ "$OS" = "arch" ]; then
            cmd="sudo pacman $NONINTERACTIVEFLAGS -Sy virtualbox vagrant"
        elif [ "$OS" = "mac" ]; then
            cmd="brew tap caskroom/cask && brew cask install virtualbox vagrant"
        else
            cmd=""
        fi
        echo "Vagrant and Virtualbox are required for your flavour of LaMachine but are not installed yet. ${bold}Install automatically?${normal}"
        if [ ! -z "$cmd" ]; then
            while true; do
                echo -n "${bold}Run:${normal} $cmd ? [yn] "
                if [ "$INTERACTIVE" -eq 1 ]; then
                    read yn
                else
                    yn="y"
                fi
                case $yn in
                    [Yy]* ) eval $cmd; break;;
                    [Nn]* ) echo "Please install vagrant manually from https://www.vagrantup.com/downloads.html and VirtualBox from https://www.virtualbox.org/" && echo " .. press ENTER when done or CTRL-C to abort..." && read; break;;
                    * ) echo "Please answer yes or no.";;
                esac
            done
        else
            echo "No automated installation possible on your OS."
            if [ "$INTERACTIVE" -eq 0 ]; then exit 5; fi
            echo "Please install vagrant manually from https://www.vagrantup.com/downloads.html and VirtualBox from https://www.virtualbox.org/" && echo " .. press ENTER when done or CTRL-C to abort..." && read
        fi
    elif [ "$package" = "vbguest" ]; then
        cmd="vagrant plugin install vagrant-vbguest"
        echo "The vagrant-vbguest plugin is required for building VMs. ${bold}Install automatically?${normal}"
        if [ ! -z "$cmd" ]; then
            while true; do
                echo -n "${bold}Run:${normal} $cmd ? [yn] "
                if [ "$INTERACTIVE" -eq 1 ]; then
                    read yn
                else
                    yn="y"
                fi
                case $yn in
                    [Yy]* ) $cmd; break;;
                    [Nn]* ) break;;
                    * ) echo "Please answer yes or no.";;
                esac
            done
        else
            echo "${boldred}Automated installation of vagrant-vbguest failed!${normal}"
            if [ "$INTERACTIVE" -eq 0 ]; then exit 5; fi
        fi
    #elif [ "$package" = "vagrant-disksize" ]; then
    #    cmd="vagrant plugin install vagrant-disksize"
    #    echo "The vagrant-disksize plugin is required for building VMs. ${bold}Install automatically?${normal}"
    #    if [ ! -z "$cmd" ]; then
    #        while true; do
    #            echo -n "${bold}Run:${normal} $cmd ? [yn] "
    #            if [ "$INTERACTIVE" -eq 1 ]; then
    #                read yn
    #            else
    #                yn="y"
    #            fi
    #            case $yn in
    #                [Yy]* ) $cmd; break;;
    #                [Nn]* ) break;;
    #                * ) echo "Please answer yes or no.";;
    #            esac
    #        done
    #    else
    #        echo "${boldred}Automated installation of vagrant-disksize failed!${normal}"
    #        if [ "$INTERACTIVE" -eq 0 ]; then exit 5; fi
    #    fi
    elif [ "$package" = "docker" ]; then
        echo "We expect users of docker to be able to install docker themselves."
        echo "Docker was not found on your system yet!"
        echo "Please install docker, start the daemon, and press ENTER to continue (or CTRL-C) to abort."
        read
    elif [ "$package" = "brew" ]; then
        echo "Homebrew (https://brew.sh) is required on Mac OS X but was not found yet"
        while true; do
            echo -n "${bold}Download and install homebrew?${normal} [yn] "
            if [ "$INTERACTIVE" -eq 1 ]; then
                read yn
            else
                yn="y"
            fi
            case $yn in
                [Yy]* ) break;;
                [Nn]* ) echo "Unable to continue without homebrew, see https://brew.sh/"; exit 2;;
                * ) echo "Please answer yes or no.";;
            esac
        done
        /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" || fatalerror "Homebrew installation failed!"
        brew tap caskroom/cask || fatalerror "Failed to install brew-cask, ran: brew tap caskroom/cask"
    elif [ "$package" = "brew-cask" ]; then
        echo "Installing brew-cask"
        brew tap caskroom/cask || fatalerror "Failed to install brew-cask, ran: brew tap caskroom/cask"
    elif [ "$package" = "git" ]; then
        if [ "$OS" = "debian" ]; then
            cmd="sudo apt-get $NONINTERACTIVEFLAGS install git-core"
        elif [ "$OS" = "redhat" ]; then
            cmd="sudo yum $NONINTERACTIVEFLAGS install git"
        elif [ "$OS" = "arch" ]; then
            cmd="sudo pacman $NONINTERACTIVEFLAGS -Sy git"
        elif [ "$OS" = "mac" ]; then
            cmd="brew install git"
        else
            cmd=""
        fi
        echo "Git is required for LaMachine but not installed yet. ${bold}Install now?${normal}"
        if [ ! -z "$cmd" ]; then
            while true; do
                echo -n "${bold}Run:${normal} $cmd ? [yn] "
                if [ "$INTERACTIVE" -eq 1 ]; then
                    read yn
                else
                    yn="y"
                fi
                case $yn in
                    [Yy]* ) $cmd || fatalerror "Git installation failed!"; break;;
                    [Nn]* ) echo "Please install git manually" && echo " .. press ENTER when done or CTRL-C to abort..." && read; break;;
                    * ) echo "Please answer yes or no.";;
                esac
            done
        else
            echo "No automated installation possible on your OS."
            if [ "$INTERACTIVE" -eq 0 ]; then exit 5; fi
            echo "Please install git manually" && echo " .. press ENTER when done or CTRL-C to abort..." && read
        fi
    elif [ "$package" = "epel" ]; then
        cmd="sudo yum $NONINTERACTIVEFLAGS install epel-release"
        echo "EPEL is required for LaMachine but not installed yet. ${bold}Install now?${normal}"
        if [ ! -z "$cmd" ]; then
            while true; do
                echo -n "${bold}Run:${normal} $cmd ? [yn] "
                if [ "$INTERACTIVE" -eq 1 ]; then
                    read yn
                else
                    yn="y"
                fi
                case $yn in
                    [Yy]* ) $cmd || fatalerror "EPEL installation failed"; break;;
                    [Nn]* ) echo "Please install EPEL manually" && echo " .. press ENTER when done or CTRL-C to abort..." && read; break;;
                    * ) echo "Please answer yes or no.";;
                esac
            done
        else
            echo "No automated installation possible on your OS."
            if [ "$INTERACTIVE" -eq 0 ]; then exit 5; fi
            echo "Please install pip manually" && echo " .. press ENTER when done or CTRL-C to abort..." && read
        fi
    elif [ "$package" = "ansible" ]; then
        if [ "$OS" = "debian" ]; then
            if [ "$DISTRIB_ID" = "ubuntu" ] || [ "$DISTRIB_ID" = "linuxmint" ]; then
                #add PPA
                cmd="sudo apt-get update && sudo apt-get $NONINTERACTIVEFLAGS install software-properties-common && sudo apt-add-repository -y ppa:ansible/ansible && sudo apt-get update && sudo apt-get $NONINTERACTIVEFLAGS install ansible"
            else
                cmd="echo 'deb http://ppa.launchpad.net/ansible/ansible/ubuntu trusty main' | sudo tee -a /etc/apt/sources.list && sudo apt-get $NONINTERACTIVEFLAGS update && sudo apt-get $NONINTERACTIVEFLAGS install gnupg && sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367 && sudo apt-get $NONINTERACTIVEFLAGS update && sudo apt-get $NONINTERACTIVEFLAGS --allow-unauthenticated install ansible"
            fi
        elif [ "$OS" = "redhat" ]; then
            cmd="sudo yum  $NONINTERACTIVEFLAGS install ansible"
        elif [ "$OS" = "arch" ]; then
            cmd="sudo pacman  $NONINTERACTIVEFLAGS -Sy ansible"
        else
            continue
        fi
        echo "Ansible is required for LaMachine but not installed yet. ${bold}Install now?${normal}"
        if [ ! -z "$cmd" ]; then
            while true; do
                echo -n "${bold}Run:${normal} $cmd ? [yn] "
                if [ "$INTERACTIVE" -eq 1 ]; then
                    read yn
                else
                    yn="y"
                fi
                case $yn in
                    [Yy]* ) eval $cmd || fatalerror "Ansible installation failed"; break;;
                    [Nn]* ) echo "Please install Ansible manually" && echo " .. press ENTER when done or CTRL-C to abort..." && read; break;;
                    * ) echo "Please answer yes or no.";;
                esac
            done
        else
            echo "No automated installation possible on your OS."
            if [ "$INTERACTIVE" -eq 0 ]; then exit 5; fi
            echo "Please install Ansible manually" && echo " .. press ENTER when done or CTRL-C to abort..." && read
        fi
    elif [ "$package" = "pip" ]; then
        if [ "$OS" = "debian" ]; then
            cmd="sudo apt-get  $NONINTERACTIVEFLAGS install python-pip"
        elif [ "$OS" = "redhat" ]; then
            cmd="sudo yum  $NONINTERACTIVEFLAGS install python-pip"
        elif [ "$OS" = "arch" ]; then
            cmd="sudo pacman  $NONINTERACTIVEFLAGS -Sy python-pip"
        elif [ "$OS" = "mac" ]; then
            cmd="sudo easy_install pip"
        fi
        echo "Pip is required for LaMachine but not installed yet. ${bold}Install now?${normal}"
        if [ ! -z "$cmd" ]; then
            while true; do
                echo -n "${bold}Run:${normal} $cmd ? [yn] "
                if [ "$INTERACTIVE" -eq 1 ]; then
                    read yn
                else
                    yn="y"
                fi
                case $yn in
                    [Yy]* ) $cmd || fatalerror "Pip installation failed"; break;;
                    [Nn]* ) echo "Please install pip manually" && echo " .. press ENTER when done or CTRL-C to abort..." && read; break;;
                    * ) echo "Please answer yes or no.";;
                esac
            done
        else
            echo "No automated installation possible on your OS."
            if [ "$INTERACTIVE" -eq 0 ]; then exit 5; fi
            echo "Please install pip manually" && echo " .. press ENTER when done or CTRL-C to abort..." && read
        fi
    elif [ "$package" = "virtualenv" ]; then
        if [ "$OS" = "debian" ]; then
            cmd="sudo apt-get $NONINTERACTIVEFLAGS install python-virtualenv"
            if [ "$DISTRIB_RELEASE" != "14.04" ]; then #except on old ubuntu
                cmd="$cmd virtualenv"
            fi

        elif [ "$OS" = "redhat" ]; then
            cmd="sudo yum  $NONINTERACTIVEFLAGS install python-virtualenv"
        elif [ "$OS" = "arch" ]; then
            cmd="sudo pacman  $NONINTERACTIVEFLAGS -Sy python-virtualenv"
        elif [ "$OS" = "mac" ]; then
            cmd="sudo pip install virtualenv"
        else
            cmd=""
        fi
        echo "Virtualenv is required for LaMachine but not installed yet. ${bold}Install now?${normal}"
        if [ ! -z "$cmd" ]; then
            while true; do
                echo -n "${bold}Run:${normal} $cmd ? [yn] "
                if [ "$INTERACTIVE" -eq 1 ]; then
                    read yn
                else
                    yn="y"
                fi
                case $yn in
                    [Yy]* ) $cmd || fatalerror "Virtualenv installation failed"; break;;
                    [Nn]* ) echo "Please install virtualenv manually" && echo " .. press ENTER when done or CTRL-C to abort..." && read; break;;
                    * ) echo "Please answer yes or no.";;
                esac
            done
        else
            echo "No automated installation possible on your OS."
            if [ "$INTERACTIVE" -eq 0 ]; then exit 5; fi
            echo "Please install virtualenv manually" && echo " .. press ENTER when done or CTRL-C to abort..." && read
        fi
    fi
done

if [ -z "$LM_NAME" ]; then
    echo "Your LaMachine installation is identified by a name (local env name, VM name) etc.."
    echo "(This does not need to match the hostname or domain name, which is a separate configuration setting)"
    echo -n "${bold}Enter a name for your LaMachine installation (no spaces!):${normal} "
    read LM_NAME
    LM_NAME="${LM_NAME%\\n}"
fi



LM_NAME=${LM_NAME/ /} #strip any spaces because users won't listen anyway
if [ -z "$LM_NAME" ]; then
    echo "${boldred}No names provided${normal}" >&2
    exit 2
fi

if [ $BUILD -eq 1 ]; then
    DETECTEDHOSTNAME=$(hostname --fqdn)
    if [ -z "$DETECTEDHOSTNAME" ] || [ "$FLAVOUR" = "vagrant" ] || [ "$FLAVOUR" = "docker" ]; then
        DETECTEDHOSTNAME="$LM_NAME"
    fi

    if [ -z "$HOSTNAME" ] && [ $INTERACTIVE -eq 0 ]; then
        HOSTNAME=$DETECTEDHOSTNAME
    fi

    if [ -z "$HOSTNAME" ]; then
        echo "The hostname or fully qualified domain name (FDQN) determines how your LaMachine installation can be referenced on a network."
        if [ "$FLAVOUR" = "remote" ]; then
            echo "This determines the remote machine LaMachine will be installed on!"
        fi
        echo -n "${bold}Please enter the hostname (or FQDN) of the LaMachine system (just press ENTER if you want to use $DETECTEDHOSTNAME here):${normal} "
        read HOSTNAME
        if [ -z "$HOSTNAME" ]; then
            HOSTNAME=$DETECTEDHOSTNAME
        fi
    fi
fi

if [[ "$FLAVOUR" == "remote" ]]; then
    if [ $USER_SET -eq 0 ] && [ $INTERACTIVE -eq 1 ]; then
        echo "To provision the remote machine, LaMachine needs to be able to connect over ssh as specific user."
        echo "The user must exist and ideally passwordless ssh keypairs should be available. Note that connecting and running"
        echo "as root is explicitly forbidden. The user, on the other hand, does require sudo rights on the remote machine."
        echo -n "${bold}What user should LaMachine use to provision the remote machine?${normal} "
        read USERNAME
    fi
fi

STAGEDCONFIG="$BASEDIR/lamachine-$LM_NAME.yml"
STAGEDMANIFEST="$BASEDIR/install-$LM_NAME.yml"

HOMEDIR=$(echo ~)

if [ $BUILD -eq 1 ]; then
 if [ ! -e "$STAGEDCONFIG" ]; then
    echo "---
###########################################################################
#           LaMachine Host Configuration
#
# INSTRUCTIONS: Here you can check and set any configuration variables
#               for your LaMachine build.
#               Most likely you don't need to change anything
#               at all and can just accept the values by saving
#               and closing your editor.
#
#               Note that most of these variables can not be changed
#               once they have been set.
#
###########################################################################
conf_name: \"$LM_NAME\" #Name of this LaMachine configuration (don't change this once set)
flavour: \"$FLAVOUR\" #LaMachine flavour (don't change this once set)
hostname: \"$HOSTNAME\" #Name of the host (or fully qualified domain name) (changing this won't automatically change the system hostname!)
version: \"$VERSION\" #stable, development or custom
localenv_type: \"$LOCALENV_TYPE\" #Local environment type (virtualenv), only used when locality == local (don't change this once set)
locality: \"$LOCALITY\" #local or global? (don't change this once set)
controller: \"$CONTROLLER\" #internal or external? Is this installation managed inside or outside the environment/host? You can't change this value here, run bootstrap with --external to force this to external.
maintainer_name: \"$USERNAME\" #Enter your name here to let people know who the maintainer of this LaMachine installation is
maintainer_mail: \"$USERNAME@$HOSTNAME\" #Enter your e-mail address here
" > $STAGEDCONFIG
    if [[ $FLAVOUR == "vagrant" ]]; then
        GROUP="vagrant"
        echo "unix_user: \"vagrant\" #(don't change this unless you know what you're doing)" >> $STAGEDCONFIG
        echo "unix_group: \"vagrant\" #(don't change this unless you know what you're doing)" >> $STAGEDCONFIG
        echo "homedir: \"/home/vagrant\"" >> $STAGEDCONFIG
        echo "lamachine_path: \"/vagrant\" #Path where LaMachine source is originally stored/shared" >> $STAGEDCONFIG
        echo "host_data_path: \"$BASEDIR\" #Data path on the host machine that will be shared with LaMachine" >> $STAGEDCONFIG
        echo "data_path: \"/data\" #Shared data path (in LaMachine) that is tied to host_data_path, you can change this" >> $STAGEDCONFIG
        echo "global_prefix: \"/usr/local\" #Path for global installations (only change once on initial installation)" >> $STAGEDCONFIG
        echo "source_path: \"/usr/local/src\" #Path where sources will be stored/compiled (only change once on initial installation)" >> $STAGEDCONFIG
        if [ "$VAGRANTBOX" == "centos/7" ]; then
            echo "ansible_python_interpreter: \"/usr/bin/python\" #Python interpreter for Vagrant to use with Ansible" >> $STAGEDCONFIG
        else
            echo "ansible_python_interpreter: \"/usr/bin/python3\" #Python interpreter for Vagrant to use with Ansible. This interpreter must be already available in vagrant box $VAGRANTBOX, you may want to set it to python2 instead" >> $STAGEDCONFIG
        fi
        echo "extra_disksize: $DISKSIZE #Size in GB of dedicated LaMachine disk in the VM (separated from boot image, needed if you plan to exceed the default 8GB total)" >> $STAGEDCONFIG
    elif [[ $FLAVOUR == "docker" ]]; then
        GROUP="lamachine"
        echo "unix_user: \"lamachine\"" >> $STAGEDCONFIG
        echo "unix_group: \"lamachine\" #must be same as unix_user, changing this is not supported yet" >> $STAGEDCONFIG
        echo "homedir: \"/home/lamachine\"" >> $STAGEDCONFIG
        echo "lamachine_path: \"/lamachine\" #Path where LaMachine source is initially stored/shared" >> $STAGEDCONFIG
        echo "host_data_path: \"$BASEDIR\" #Data path on the host machine that will be shared with LaMachine" >> $STAGEDCONFIG
        echo "data_path: \"/data\" #Shared data path (in LaMachine) that is tied to host_data_path" >> $STAGEDCONFIG
        echo "global_prefix: \"/usr/local\" #Path for global installations (only change once on initial installation)" >> $STAGEDCONFIG
        echo "source_path: \"/usr/local/src\" #Path where sources will be stored/compiled (only change once on initial installation)" >> $STAGEDCONFIG
    else
        echo "unix_user: \"$USERNAME\"" >> $STAGEDCONFIG
        echo "unix_group: \"$GROUP\"" >> $STAGEDCONFIG
        WEBUSER=$USERNAME
        if [[ "$FLAVOUR" == "remote" ]] || [[ "$LOCALITY" == "global" ]]; then
            echo "homedir: \"/home/$USERNAME\" #the home directory of the aforementioned user" >> $STAGEDCONFIG
        else
            echo "homedir: \"$HOMEDIR\" #the home directory of the aforementioned user" >> $STAGEDCONFIG
        fi
        if [ ! -z "$SOURCEDIR" ]; then
            echo "lamachine_path: \"$SOURCEDIR\" #Path where LaMachine source is initially stored/shared (don't change this)." >> $STAGEDCONFIG
        else
            echo "lamachine_path: \"$BASEDIR/lamachine-controller/$LM_NAME/LaMachine\" #Path where LaMachine source is initially stored/shared (don't change this)" >> $STAGEDCONFIG
        fi
        if [[ "$FLAVOUR" == "remote" ]]; then
            echo "data_path: \"/data\" #Shared data path (in LaMachine), you can use this as a mountpoint for a shared volume (but will have to do the mounting yourself)" >> $STAGEDCONFIG
        else
            echo "data_path: \"$BASEDIR\" #Shared data path, change this if needed!" >> $STAGEDCONFIG
        fi
        if [[ "$LOCALITY" == "local" ]]; then
            echo "local_prefix: \"$BASEDIR/$LM_NAME\" #Path to the local environment (virtualenv)" >> $STAGEDCONFIG
            echo "global_prefix: \"/usr/local\" #Path for global installations (not used in your configuration)" >> $STAGEDCONFIG
        else
            echo "global_prefix: \"/usr/local\" #Path for global installations" >> $STAGEDCONFIG
        fi
        if [[ "$LOCALITY" == "global" ]]; then
            echo "source_path: \"/usr/local/src\" #Path where sources will be stored/compiled" >> $STAGEDCONFIG
        else
            echo "source_path: \"$BASEDIR/$LM_NAME/src\" #Path where sources will be stored/compiled" >> $STAGEDCONFIG
        fi
    fi
    if [[ $FLAVOUR == "vagrant" ]] || [[ $FLAVOUR == "docker" ]] || [[ $FLAVOUR == "remote" ]]; then
        echo "root: true #Do you have root on the target system?" >> $STAGEDCONFIG
    elif [ $SUDO -eq 1 ]; then
        echo "root: true #Do you have root on the target system?" >> $STAGEDCONFIG
    elif [ $SUDO -eq 0 ]; then
        echo "root: false #Do you have root on the target system?" >> $STAGEDCONFIG
    fi
    if [[ $FLAVOUR == "vagrant" ]]; then
        echo "vagrant_box: \"$VAGRANTBOX\" #Base box for vagrant (changing this may break things if packages are not compatible!)" >>$STAGEDCONFIG
        echo "vm_memory: $VMMEM #Memory allocated to the VM; in MB (the more the better! but too high and the VM won't start)">> $STAGEDCONFIG
        echo "vm_cpus: 2 #CPU cores allocated to the VM">>$STAGEDCONFIG
    fi
    if [ $PRIVATE -eq 1 ]; then
        echo "private: true #opt-out of sending back anonymous analytics regarding your LaMachine build " >> $STAGEDCONFIG
    else
        echo "private: false #when false, allows sending back anonymous analytics regarding your LaMachine build (recommended)" >> $STAGEDCONFIG
    fi
    if [ $MINIMAL -eq 1 ]; then
        echo "minimal: true #install less than normal for certain categories (this might break things)" >> $STAGEDCONFIG
    else
        echo "minimal: false #install less than normal for certain categories (this might break things)" >> $STAGEDCONFIG
    fi
    if [ $PREFER_DISTRO -eq 1 ]; then
        echo "prefer_distro: true #prefer using the distribution's packages as much as possible rather than distribution channels such as pip (this will install more conservative versions but may break certain things)" >> $STAGEDCONFIG
    else
        echo "prefer_distro: false #prefer using the distribution's packages as much as possible rather than distribution channels such as pip (this will install more conservative versions but may break certain things)" >> $STAGEDCONFIG
    fi
    echo "webserver: true #include a webserver and web-based services/applications. Disabling this turns all web-based functionality off." >> $STAGEDCONFIG
    if [ $SUDO -eq 1 ]; then
        echo "http_port: 80 #webserver port, you may want to change this to a port like 8080 if you don't want to run on a reserved port or already have something running there!" >> $STAGEDCONFIG
    else
        echo "http_port: 8080 #webserver port" >> $STAGEDCONFIG
    fi
echo "mapped_http_port: 8080 #mapped webserver port on host system (for VM or docker only)
services: [ $SERVICES ]  #List of services to provide, if set to [ all ], all possible services from the software categories you install will be provided. You can remove this and list specific services you want to enable. This is especially needed in case of a LaMachine installation that intends to only provide a single service.
webservertype: nginx #If set to anything different, the internal webserver will not be enabled/provided by LaMachine (which allows you to run your own external one), do leave webserver: true set as is though.
" >> $STAGEDCONFIG
if [[ $OS == "mac" ]] || [[ "$FLAVOUR" == "remote" ]]; then
    echo "lab: false #Enable Jupyter Lab environment, note that this opens the system to arbitrary code execution and file system access! (provided the below password is known)" >> $STAGEDCONFIG
else
    echo "lab: true #Enable Jupyter Lab environment, note that this opens the system to arbitrary code execution and file system access! (provided the below password is known)" >> $STAGEDCONFIG
fi
echo "lab_password_sha1: \"sha1:fa40baddab88:c498070b5885ee26ed851104ddef37926459b0c4\" #default password for Jupyter Lab: lamachine, change this with 'lamachine-passwd lab'" >> $STAGEDCONFIG
echo "lab_allow_origin: \"*\" #hosts that may access the lab environment" >> $STAGEDCONFIG
echo "flat_password: \"flat\" #initial password for the FLAT administrator (if installed; username 'flat'), updating this later has no effect (edit in FLAT itself)!" >> $STAGEDCONFIG
if [ $FORCE -ne 0 ]; then
    echo "force: $FORCE #Sets the default force parameter for updates, set to 1 to force updates or 2 to explicitly remove all sources and start from scratch on each update. Remove this line entirely if you don't need it or are in doubt" >> $STAGEDCONFIG
fi
if [ $NOSYSUPDATE -ne 0 ]; then
    echo "nosysupdate: $NOSYSUPDATE #Skips updating the global packages provided by the distribution" >> $STAGEDCONFIG
fi
    if [[ $FLAVOUR == "local" ]] || [[ "$OS" == "mac" ]]; then
        echo "web_user: \"$USERNAME\"" >> $STAGEDCONFIG
        echo "web_group: \"$GROUP\"" >> $STAGEDCONFIG
    else
        echo "web_user: \"www-data\" #The user for the webserver, change this on first install if needed!!!" >> $STAGEDCONFIG
        echo "web_group: \"www-data\" #The group for the webserver, change this on first install if needed!!!" >> $STAGEDCONFIG
    fi
    if [ $OS = "arch" ]; then
        if [[ $FLAVOUR == "local" ]] || [[ $FLAVOUR == "global" ]]; then
            echo "ansible_python_interpreter: \"/bin/python2\" #Python interpreter for Vagrant to use with Ansible" >> $STAGEDCONFIG
        fi
    fi

    if [ $INTERACTIVE -eq 1 ]; then
        echo "${bold}Opening configuration file $STAGEDCONFIG in editor for final configuration...${normal}"
        sleep 3
        if ! "$EDITOR" "$STAGEDCONFIG"; then
            echo "aborted by editor..." >&2
            exit 2
        fi
    fi

 fi
fi #build

if [ ! -d lamachine-controller ]; then
    mkdir lamachine-controller || fatalerror "Unable to create directory for LaMachine control environment"
fi

if [ ! -d lamachine-controller/$LM_NAME ]; then
    echo "Setting up control environment..."
    if [ $NEED_VIRTUALENV -eq 1 ]; then
        echo " (with virtualenv and ansible inside)"
        virtualenv lamachine-controller/$LM_NAME || fatalerror "Unable to create LaMachine control environment"
        cd lamachine-controller/$LM_NAME
        source ./bin/activate || fatalerror "Unable to activate LaMachine controller environment"
        pip install -U setuptools
        pip install ansible || fatalerror "Unable to install Ansible"
        #pip install docker==2.7.0 docker-compose ansible-container[docker]
    else
        echo " (simple)"
        mkdir lamachine-controller/$LM_NAME && cd lamachine-controller/$LM_NAME #no need for a virtualenv
    fi
else
    echo "Reusing existing control environment..."
    cd lamachine-controller/$LM_NAME
    if [ $NEED_VIRTUALENV -eq 1 ]; then
        source ./bin/activate || fatalerror "Unable to activate LaMachine controller environment"
    fi
fi

if [ -z "$SOURCEDIR" ]; then
    echo "Cloning LaMachine git repo ($GITREPO $BRANCH)..."
    if [ ! -d LaMachine ]; then
        git clone $GITREPO -b $BRANCH LaMachine || fatalerror "Unable to clone LaMachine git repository"
    fi
    SOURCEDIR=$BASEDIR/lamachine-controller/$LM_NAME/LaMachine
    cd $SOURCEDIR
else
    echo "Updating LaMachine git..."
    cd $SOURCEDIR
    if [ "$SOURCEDIR" != "$BASEDIR" ]; then
        git checkout $BRANCH #only switch branches if we're not already in a git repo the user cloned himself
    fi
fi
git pull #make sure we're up to date

if [ $BUILD -eq 1 ]; then
    #copying staged configuration to final location
    cp $STAGEDCONFIG "$SOURCEDIR/host_vars/$HOSTNAME.yml" || fatalerror "Unable to copy $STAGEDCONFIG"

    if [ ! -e $STAGEDMANIFEST ]; then
        if [ ! -z "$INSTALL" ]; then
            #use the explicitly provided list
            if [ "$FLAVOUR" = "remote" ]; then
                echo "- hosts: $HOSTNAME" > $STAGEDMANIFEST
            else
                echo "- hosts: all" > $STAGEDMANIFEST
            fi
            if [ "$VERSION" = "custom" ]; then
                echo "  vars_files: [ customversions.yml ]" >> $STAGEDMANIFEST
            fi
            echo "  roles: [ lamachine-core, $INSTALL ]" >> $STAGEDMANIFEST
        else
            #use the template
            cp $SOURCEDIR/install-template.yml $STAGEDMANIFEST || fatalerror "Unable to copy $SOURCEDIR/install-template.yml"
            if [ "$FLAVOUR" = "remote" ]; then
                sed -i.bak "s/hosts: all/hosts: $HOSTNAME/g" $STAGEDMANIFEST || fatalerror "Unable to run sed"
            fi
            if [ "$VERSION" = "custom" ]; then
                sed -i.bak "s/##1##/vars_files: [ customversions.yml ]/" $STAGEDMANIFEST || fatalerror "Unable to run sed"
            fi
        fi
    fi

    if [ $INTERACTIVE -eq 1 ] && [ -z "$INSTALL" ]; then
        echo "${bold}Opening installation file $STAGEDMANIFEST in editor for selection of packages to install...${normal}"
        sleep 3
        if ! "$EDITOR" "$STAGEDMANIFEST"; then
            exit 2
        fi
    fi

    #copy staged install to final location
    cp $STAGEDMANIFEST $SOURCEDIR/install.yml || fatalerror "Unable to copy $STAGEDMANIFEST"
    if [ -e customversions.yml ]; then
        cp customversions.yml $SOURCEDIR/customversions.yml
    fi
fi

HOMEDIR=$(echo ~)
if [[ "$FLAVOUR" == "vagrant" ]] || [[ "$FLAVOUR" == "docker" ]]; then
    if [[ ! -e $HOMEDIR/bin ]]; then
        echo "Creating $HOMEDIR/bin on host machine..."
        mkdir -p $HOMEDIR/bin
    fi
fi

rc=0
if [[ "$FLAVOUR" == "vagrant" ]]; then
    echo "Preparing vagrant..."
    #Copy and adapt the Vagrantfile file; storing it inside the lamachine-controller
    if [ $BUILD -eq 1 ]; then
        if [ ! -f $SOURCEDIR/Vagrantfile ]; then
            cp -f $SOURCEDIR/Vagrantfile.template $SOURCEDIR/Vagrantfile || fatalerror "Unable to copy Vagrantfile"
            sed -i.bak s/lamachine-vm/$HOSTNAME/g $SOURCEDIR/Vagrantfile || fatalerror "Unable to run sed"
            sed -i.bak s/HOSTNAME/$HOSTNAME/g $SOURCEDIR/Vagrantfile || fatalerror "Unable to run sed"
        fi
    else
        cp -f $SOURCEDIR/Vagrantfile.prebuilt $SOURCEDIR/Vagrantfile || fatalerror "Unable to copy Vagrantfile"
        sed -i.bak s/lamachine-vm/$LM_NAME/g $SOURCEDIR/Vagrantfile || fatalerror "Unable to run sed"
        if [ $INTERACTIVE -eq 1 ]; then
            #not needed for BUILD=1 because most interesting parameters inherited from the ansible host configuration
            echo "${bold}Do you want to open the vagrant configuration in an editor for final configuration? (recommended to increase memory/cpu cores) [yn]${normal}"
            read choice
            case $choice in
                [n]* ) break;;
                [y]* ) BUILD=0;  break;;
                * ) echo "Please answer with the y or n..";;
            esac
            if ! "$EDITOR" "$SOURCEDIR/Vagrantfile"; then
                echo "aborted by editor..." >&2
                exit 2
            fi
        fi
    fi
    #add activation script on the host machine:
    echo -e "#!/bin/bash\nexport VAGRANT_CWD=$SOURCEDIR\nif vagrant up && vagrant ssh; then\nvagrant halt\nexit 0\nelse\nexit 1\nfi" > $HOMEDIR/bin/lamachine-$LM_NAME-activate
    echo -e "#!/bin/bash\nexport VAGRANT_CWD=$SOURCEDIR\nvagrant halt \$@; exit \$?" > $HOMEDIR/bin/lamachine-$LM_NAME-stop
    echo -e "#!/bin/bash\nexport VAGRANT_CWD=$SOURCEDIR\nvagrant up; exit \$?" > $HOMEDIR/bin/lamachine-$LM_NAME-start
    echo -e "#!/bin/bash\nexport VAGRANT_CWD=$SOURCEDIR\nvagrant ssh; exit \$?" > $HOMEDIR/bin/lamachine-$LM_NAME-connect
    echo -e "#!/bin/bash\nexport VAGRANT_CWD=$SOURCEDIR\nvagrant ssh -c 'lamachine-update'; exit \$?" > $HOMEDIR/bin/lamachine-$LM_NAME-update
    echo -e "#!/bin/bash\nexport VAGRANT_CWD=$SOURCEDIR\nvagrant destroy \$@; exit \$?" > $HOMEDIR/bin/lamachine-$LM_NAME-destroy
    echo -e "#!/bin/bash\nexport VAGRANT_CWD=$SOURCEDIR\nvagrant package \$@; exit \$?" > $HOMEDIR/bin/lamachine-$LM_NAME-export
    chmod a+x $HOMEDIR/bin/lamachine-$LM_NAME-*
    ln -sf $HOMEDIR/bin/lamachine-$LM_NAME-activate $HOMEDIR/bin/lamachine-activate #shortcut
    #run the activation script (this will do the actual initial provision as well)
    bash $HOMEDIR/bin/lamachine-$LM_NAME-start 2>&1 | tee lamachine-$LM_NAME.log
    rc=${PIPESTATUS[0]}
    hash -r
    echo "======================================================================================"
    if [ $rc -eq 0 ]; then
        if [ $BUILD -eq 0 ]; then
            echo "${boldgreen}Build completed succesfully! Rebooting VM...${normal}."
            bash $HOMEDIR/bin/lamachine-$LM_NAME-stop
            bash $HOMEDIR/bin/lamachine-$LM_NAME-start
        else
            echo "${boldgreen}Build from pre-built image completed succesfully!${normal}."
        fi
        echo "${boldgreen}All done, the LaMachine VM has been built and started succesfully${normal}."
        echo "- ${bold}to connect to a started VM, run: lamachine-$LM_NAME-connect${normal} (or: bash ~/bin/lamachine-$LM_NAME-connect)"
        echo "- to power up the VM, run: lamachine-$LM_NAME-start"
        echo "- to power down the VM, run: lamachine-$LM_NAME-stop"
        echo "- to delete the entire VM again, run: lamachine-$LM_NAME-destroy"
        echo "- to start and immediately connect to your VM, run: lamachine-$LM_NAME-activate${normal}"
        echo "  note that the VM will be stopped as soon as you disconnect again."
    else
        echo "${boldred}The LaMachine VM bootstrap has failed unfortunately.${normal} You have several options:"
        echo " - Retry the bootstrap, possibly tweaking configuration options"
        echo " - Enter the LaMachine VM in its uncompleted state, run: bash ~/bin/lamachine-$LM_NAME-connect"
        echo " - Force the LaMachine VM to update itself, run: bash ~/bin/lamachine-$LM_NAME-update"
        echo " - File a bug report on https://github.com/proycon/LaMachine/issues/"
        echo "   The log file has been written to $(pwd)/lamachine-$LM_NAME.log (include it with any bug report)"
    fi
elif [[ "$FLAVOUR" == "local" ]] || [[ "$FLAVOUR" == "global" ]]; then
    if [ "$SUDO" -eq 1 ] && [ $INTERACTIVE -eq 1 ]; then
        ASKSUDO="--ask-become-pass"
    else
        ASKSUDO=""
    fi
    cmd="ansible-playbook $ASKSUDO -i $SOURCEDIR/hosts.ini $SOURCEDIR/install.yml $ANSIBLE_OPTIONS"
    cwd=$(pwd)
    echo "Running ansible command from $cwd: $cmd" >&2
    echo "$HOSTNAME ansible_connection=local" > $SOURCEDIR/hosts.ini
    $cmd 2>&1 | tee lamachine-$LM_NAME.log
    rc=${PIPESTATUS[0]}
    hash -r
    if [ $rc -eq 0 ]; then
        echo "======================================================================================"
        echo "${boldgreen}All done, a local LaMachine environment has been built!${normal}"
        echo "- ${bold}to activate your environment, run: source lamachine-$LM_NAME-activate${normal}   (or: ~/bin/lamachine-$LM_NAME-activate)"
    else
        echo "======================================================================================"
        echo "${boldred}Building a local LaMachine environment has failed unfortunately.${normal} You have several options:"
        echo " - Retry the bootstrap, possibly tweaking configuration options"
        echo " - Attempt to activate the environment (run: lamachine-$LM_NAME-activate) and debug the problem"
        echo " - Run lamachine-$LM_NAME-update after activating the environment to see if the problem corrects itself"
        echo " - File a bug report on https://github.com/proycon/LaMachine/issues/"
        echo "   The log file has been written to $(pwd)/lamachine-$LM_NAME.log (include it with any bug report)"
        rc=1
    fi
elif [[ "$FLAVOUR" == "docker" ]]; then
    if ! docker info >/dev/null 2>/dev/null; then
        echo "The docker daemon is not running!"
        if [ $INTERACTIVE -eq 1 ]; then
            echo "Please start it (usually using: sudo systemctl start docker) and press ENTER to continue when ready.."
            read
        else
            exit 2
        fi
    fi
    if [ $BUILD -eq 1 ]; then
        echo "Building docker image.."
        sed -i.bak "s/hosts: all/hosts: localhost/g" $SOURCEDIR/install.yml || fatalerror "Unable to run sed"
        #echo "$HOSTNAME ansible_connection=local" > $SOURCEDIR/hosts.ini #not needed
        docker build -t $DOCKERREPO:$LM_NAME --build-arg LM_NAME=$LM_NAME --build-arg HOSTNAME=$HOSTNAME . 2>&1 | tee lamachine-$LM_NAME.log
        rc=${PIPESTATUS[0]}
    else
        echo "Pulling pre-built docker image.."
        docker pull $DOCKERREPO
        rc=$?
    fi
    if [ $rc -eq 0 ]; then
        echo "======================================================================================"
        if [ $BUILD -eq 1 ]; then
            echo "${boldgreen}All done, a docker image has been built!${normal}"
            echo "- to create and run a *new* interactive container using this image, run: docker run -p 8080:80 -h $HOSTNAME -t -i $DOCKERREPO:$LM_NAME"
        else
            echo "${boldgreen}All done, a docker image has been downloaded!${normal}"
            echo "- to create and run a *new* interactive container using this image, run: docker run -p 8080:80 -h latest -t -i $DOCKERREPO"
        fi
    else
        echo "======================================================================================"
        echo "${boldred}The docker build has failed unfortunately.${normal} You have several options:"
        echo " - Retry the bootstrap, possibly tweaking configuration options"
        echo " - File a bug report on https://github.com/proycon/LaMachine/issues/"
        if [ $BUILD -eq 1 ]; then
            echo "   The log file has been written to $(pwd)/lamachine-$LM_NAME.log (include it with any bug report)"
        fi
    fi
elif [ "$FLAVOUR" = "remote" ]; then
    echo "$HOSTNAME ansible_connection=ssh ansible_user=$USERNAME" > $SOURCEDIR/hosts.ini
    git checkout -b $LM_NAME
    git add host_vars/$HOSTNAME.yml
    git add install.yml
    git add hosts.ini
    git commit -a -m "Added configuration for $LM_NAME"
    echo "${boldgreen}The following files for remote provisioning using Ansible have been generated:${normal}"
    echo " - $SOURCEDIR/host_vars/$HOSTNAME.yml - This is contains the LaMachine configuration variables for your specified host"
    echo " - $SOURCEDIR/install.yml - This is the main playbook, aka the LaMachine installation manifest"
    echo " - $SOURCEDIR/hosts.ini - The host inventory file for Ansible, containing only $HOSTNAME"
    echo "These have been added to the git repository in $SOURCEDIR, in a branch named $LM_NAME (checked out now)"
    cmd="ansible-playbook -i $SOURCEDIR/hosts.ini $SOURCEDIR/install.yml"
    echo -e "#!/bin/bash\ncd $SOURCEDIR\ngit fetch origin master && git merge origin/master\n$cmd; exit \$?" > $HOMEDIR/bin/lamachine-$LM_NAME-update
    chmod a+x $HOMEDIR/bin/lamachine-$LM_NAME-update
    echo "To provision the remote machine, run: $cmd"
    echo "or ~/bin/lamachine-$LM_NAME-update, which does this for you."
    while true; do
        echo -n "${bold}Do you want to bootstrap the remote machine now?${normal} [yn] "
        read yn
        case $yn in
            [Yy]* ) eval $cmd; rc=$?; break;;
            [Nn]* ) rc=0; break;;
            * ) echo "Please answer yes or no.";;
        esac
    done
else
    echo "No bootstrap for $FLAVOUR implemented yet at this stage, sorry!!">&2
    rc=1
fi
if [ "$CONTROLLER" = "internal" ] && [ $rc -eq 0 ]; then  #only clean up if everything went well
    cd ../..
    rm -rf "lamachine-controller/$LM_NAME" 2>/dev/null
    rm $STAGEDCONFIG 2>/dev/null
    rm $STAGEDMANIFEST 2>/dev/null
fi
if [ $NEED_VIRTUALENV -eq 1 ]; then
    deactivate #deactivate the controller before quitting
fi
exit $rc
