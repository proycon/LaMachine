#!/bin/bash
#======================================
# LaMachine v2
#  by Maarten van Gompel
#  Centre for Language and Speech Technology, Radboud University Nijmegen
#  & KNAW Humanities Cluster
#
# https://proycon.github.io/LaMachine
# Licensed under GPLv3
#=====================================

export LC_ALL=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export ANSIBLE_FORCE_COLOR=true

bold=$(tput bold)
boldred=${bold}$(tput setaf 1) #  red
boldgreen=${bold}$(tput setaf 2) #  green
green=${normal}$(tput setaf 2) #  green
yellow=${normal}$(tput setaf 3) #  yellow
blue=${normal}$(tput setaf 4) #  blue
boldblue=${bold}$(tput setaf 4) #  blue
boldyellow=${bold}$(tput setaf 3) #  yellow
normal=$(tput sgr0)

export LM_VERSION="v2.28" #NOTE FOR DEVELOPER: also change version number in codemeta.json *AND* roles/lamachine-core/defaults/main.yml -> lamachine_version!
echo "${bold}=========================================================================${normal}"
echo "           ,              ${bold}LaMachine $LM_VERSION${normal} - NLP Software distribution"
echo "          ~)                     (http://proycon.github.io/LaMachine)"
echo "           (----í"
echo "            /| |\         CLST, Radboud University Nijmegen &"
echo "           / / /|	        KNAW Humanities Cluster            (funded by CLARIAH)"
echo "${bold}=========================================================================${normal}"
echo

usage () {
    echo "bootstrap.sh [options]"
    echo " ${bold}--flavour${normal} [vagrant|docker|local|global|remote] - Determines the type of LaMachine installation"
    echo "  vagrant = in a Virtual Machine"
    echo "       complete separation from the host OS"
    echo "       (uses Vagrant and VirtualBox)"
    echo "  docker = in a Docker container"
    echo "       (uses Docker and Ansible)"
    echo "  lxc = in an LXC container"
    echo "       (uses LXD, LXC and Ansible)"
    echo "  singularity = in a Singularity container (EXPERIMENTAL!)"
    echo "       (uses Singularity and Ansible)"
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
    echo " ${bold}--globalansible${normal} - Install ansible globally or reuse the version that is already present on the system"
    echo " ${bold}--disksize${normal} - Sets extra disksize for VMs; you'll want to use  this if you plan to include particularly large software and exceed the default 8GB"
    echo " ${bold}--datapath${normal} - The data path on the host machine that will be shared with the container/VM"
    echo " ${bold}--port${normal} - The port for HTTP traffic to forward from the host machine to the container/VM"
    echo " ${bold}--sharewwwdata${normal} - Put the data for the web services on the shared volume (for container/VM)"
    echo " ${bold}--lxcprofile${normal} - Name of the LXC profile to use"
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
    elif [ "$DISTRIB_ID" = "manjaro" ]; then
        OS="arch"
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
GLOBAL_ANSIBLE=0
PREFER_DISTRO=0
NOSYSUPDATE=0
VMMEM=4096
DISKSIZE=0 #for extra disk in VM (in GB)
VAGRANTBOX="ubuntu/focal64" #base distribution for VM
LXCBASE="ubuntu:20.04"
DOCKERREPO="proycon/lamachine"
CONTROLLER="internal"
LXCPROFILE="default"
BUILD=1
SHARED_WWW_DATA="no"


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


OUTDATED=0
if [ "$OS" != "mac" ]; then
    if [ "$DISTRIB_ID" = "ubuntu" ]; then
        if [ "${DISTRIB_RELEASE%\.*}" -lt 16 ]; then
            echo "WARNING: Your Ubuntu distribution is out of date and not supported, we recommend an upgrade to the latest LTS release!"
            OUTDATED=1
        fi
    elif [ "$DISTRIB_ID" = "debian" ]; then
        if [ "${DISTRIB_RELEASE%\.*}" -lt 9 ]; then
            echo "WARNING: Your Debian distribution is out of date and not supported, we recommend an upgrade to the latest stable release!"
            OUTDATED=1
        fi
    elif [ "$DISTRIB_ID" = "linuxmint" ]; then
        if [ "${DISTRIB_RELEASE%\.*}" -lt 18 ]; then # https://www.linuxmint.com/download_all.php
            echo "WARNING: Your Linux Mint distribution is out of date and not supported, we recommend an upgrade to the latest LTS release!"
            OUTDATED=1
        fi
    elif [ "$DISTRIB_ID" = "centos" ] || [ "$DISTRIB_ID" = "rhel" ]; then
        if [ "${DISTRIB_RELEASE%\.*}" -lt 7 ]; then
            echo "WARNING: Your CentOS/RHEL distribution is out of date and not supported, we recommend an upgrade to the latest release!"
            OUTDATED=1
        fi
    elif [ "$DISTRIB_ID" = "fedora" ]; then
        if [ "${DISTRIB_RELEASE%\.*}" -lt 29 ]; then # https://en.wikipedia.org/wiki/Fedora_version_history
            echo "WARNING: Your Fedora Linux distribution is out of date and not supported, we recommend an upgrade to the latest release!"
            OUTDATED=1
        fi
    elif [ "$DISTRIB_ID" = "arch" ] || [ "$DISTRIB_ID" = "manjaro" ]; then
        echo "(You are on a rolling release distribution, that's okay but be aware that it makes local LaMachine environments more prone to breakage)"
    else
        echo "WARNING: Your Linux distribution was not properly recognized and may be unsupported!"
        OUTDATED=1
    fi
    if [ $OUTDATED -eq 1 ] && [ $INTERACTIVE -eq 1 ]; then
        echo "Running an older or unsupported Linux distribution usually prevents you from doing a successful local or global installation."
        echo "You *might*, however, still be able to do a proper VM or Docker installation."
        echo -n "${bold}Try to continue anyway?${normal} [yn] "
        read yn
        case $yn in
            [Yy]* ) break;;
            * ) exit 1; break;;
        esac
    fi
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
        --datapath)
        HOSTDATAPATH="$2"
        shift
        shift
        ;;
        --port)
        HOSTPORT="$2"
        shift
        shift
        ;;
        --sharewwwdata)
        SHARED_WWW_DATA="yes"
        shift
        shift
        ;;
        --lxcprofile)
        LXCPROFILE="$2"
        shift
        shift
        ;;
        --globalansible)
        GLOBAL_ANSIBLE=1
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

SUPPORT=unknown

if [ -z "$FLAVOUR" ]; then
    while true; do
        echo "${boldblue}Where do you want to install LaMachine?${normal}"
        echo "  ${bold}1)${normal} in a ${bold}local user environment${normal} (native for your machine)"
        echo "       installs as much as possible in a separate directory"
        echo "       for a particular (the current) user; can exists alongside existing"
        echo "       installations. May also be used (limited) by multiple"
        echo "       users/groups if file permissions allow it."
        echo "       (uses virtualenv)"
        if [[ $OS == "mac" ]]; then
            SUPPORT=bronze
        elif [[ $DISTRIB_ID == "ubuntu" ]] && [[ $DISTRIB_RELEASE == "20.04" ]]; then
            SUPPORT=gold
        elif [[ $DISTRIB_ID == "ubuntu" ]] && [[ $DISTRIB_RELEASE == "18.04" ]]; then
            SUPPORT=silver
        elif [[ $DISTRIB_ID == "debian" ]] && [[ $DISTRIB_RELEASE == "10" ]]; then
            SUPPORT=gold
        elif [[ $DISTRIB_ID == "debian" ]] && [[ $DISTRIB_RELEASE == "9" ]]; then
            SUPPORT=silver
        elif [[ $DISTRIB_ID == "debian" ]]; then
            if [ "${DISTRIB_RELEASE%\.*}" -lt 9 ]; then
                SUPPORT=deprecated
            else
                SUPPORT=bronze
            fi
        elif [[ $DISTRIB_ID == "ubuntu" ]]; then
            if [ "${DISTRIB_RELEASE%\.*}" -lt 18 ]; then
                SUPPORT=deprecated
            else
                SUPPORT=bronze
            fi
        elif [[ $DISTRIB_ID == "centos" ]] && [[ $DISTRIB_RELEASE == "8" ]]; then
            SUPPORT=silver
        elif [[ $DISTRIB_ID == "centos" ]]; then
            SUPPORT=deprecated
        elif [[ $DISTRIB_ID == "rhel" ]] && [[ $DISTRIB_RELEASE == "8" ]]; then
            SUPPORT=silver
        elif [[ $DISTRIB_ID == "rhel" ]]; then
            SUPPORT=deprecated
        elif [[ $DISTRIB_ID == "fedora" ]]; then
            if [ "${DISTRIB_RELEASE%\.*}" -lt 30 ]; then
                SUPPORT=deprecated
            else
                SUPPORT=bronze
            fi
        elif [[ $DISTRIB_ID == "linuxmint" ]]; then
                SUPPORT=bronze
        elif [[ $DISTRIB_ID == "arch" ]]; then
                SUPPORT=bronze
        fi
        if [[ "$SUPPORT" == "gold" ]]; then
            echo "       [${boldgreen}fully supported on your machine${normal}] (GOLD support level! Everything should work)"
        elif [[ "$SUPPORT" == "silver" ]]; then
            echo "       [${boldgreen}mostly supported on your machine${normal}] (SILVER support level: Almost everything should work)"
        elif [[ "$SUPPORT" == "bronze" ]]; then
            echo "       [${boldyellow}partially supported on your machine${normal}] (BRONZE support level: Certain software is known not to work and/or things are more prone to breakage. Testing has not been as extensive)"
        elif [[ "$SUPPORT" == "unknown" ]]; then
            echo "       [${boldred}support unknown${normal}] (you can try but things will likely fail)"
        elif [[ "$SUPPORT" == "deprecated" ]]; then
            echo "       [${boldred}not supported, your machine's distribution is deprecated${normal}] (upgrade to a more recent version)"
        fi
        if [ $WINDOWS -eq 0 ]; then
        echo "  ${bold}2)${normal} in a ${bold}Virtual Machine${normal}"
        echo "       complete separation from the host OS"
        echo "       (uses Vagrant and VirtualBox)"
        echo "       [${boldgreen}supported on your machine${normal}]"
        echo "  ${bold}3)${normal} in a ${bold}Docker container${normal}"
        echo "       (uses Docker and Ansible)"
        if which docker > /dev/null 2> /dev/null; then
            echo "       [${boldgreen}supported on your machine${normal}]"
        else
            echo "       [${boldred}not supported on your machine, docker not found, install docker first${normal}]"
        fi
        fi
        echo "  ${bold}4)${normal} Globally on this machine (native for your machine)"
        echo "       dedicates the entire machine to LaMachine and"
        echo "       modifies the existing system and may"
        echo "       interact with existing packages."
        echo "       [${boldyellow}advanced users only!${normal}]"
        echo "  ${bold}5)${normal} On a ${bold}remote server${normal}"
        echo "       Direct provisioning of a remote system, modifies an existing remote system"
        echo "       (uses ansible)"
        echo "       [${boldyellow}advanced users only!${normal}]"
        if [ $WINDOWS -eq 0 ]; then
        echo "  6) in an LXC/LXD container"
        echo "       Provides a more persistent and VM-like container experience than Docker"
        echo "       (uses LXD, LXC and Ansible)"
        if which lxd > /dev/null 2> /dev/null; then
            echo "       [${boldgreen}supported on your machine${normal}]"
        else
            echo "       [${boldred}not supported on your machine, lxd not found, install lxd first${normal}]"
        fi
        echo "  7) in a Singularity container"
        echo "       (uses Singularity and Ansible)"
        echo "       [${boldyellow}experimental, not supported yet${normal}]"
        fi
        echo -n "${bold}Your choice?${normal} [12345] "
        read choice
        case $choice in
            [1]* ) FLAVOUR="local"; break;;
            [2]* ) FLAVOUR="vagrant";  break;;
            [3]* ) FLAVOUR="docker";  break;;
            [4]* ) FLAVOUR="global";  break;;
            [5]* ) FLAVOUR="remote"; break;;
            [6]* ) FLAVOUR="lxc"; break;;
            [7]* ) FLAVOUR="singularity"; break;;
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
  if [[ "$FLAVOUR" == "vagrant" || "$FLAVOUR" == "docker" || "$FLAVOUR" == "singularity" ]]; then
    while true; do
        echo "${boldblue}Do you want to build a new personalised LaMachine image or use and download a prebuilt one?${normal}"
        echo "  ${bold}1)${normal} Build a new image"
        echo "       Offers most flexibility and ensures you are on the latest versions."
        echo "       Allows you to choose even for development versions or custom versions."
        echo "       Allows you to choose what software to include from scratch."
        echo "       Best integration with your custom data."
        echo "  ${bold}2)${normal} Download a prebuilt one"
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
        echo "${boldblue}Allocate extra diskspace?${normal}"
        echo "  The standard LaMachine disk is limited in size (about 9GB). If you plan to include certain very large software"
        echo "  collections that LaMachine offers (such as kaldi, valkuil) then this is not sufficient and"
        echo "  you need to allocate an extra virtual disk, specify the size below:"
        echo "  Just enter 0 if you do not need this; you don't need this for the default selection of software."
        echo -n "${bold}How much extra diskspace to reserve?${normal} [0 or size in GB] "
        while true; do
            read choice
            case $choice in
                [0-9]* ) DISKSIZE=$choice; break;;
                * ) echo "Please answer with the corresponding size in GB (use 0 if you don't need an extra disk)";;
            esac
        done
    elif [[ "$FLAVOUR" == "docker" ]] && [ $BUILD -eq 1 ] && [ $DISKSIZE -eq 0 ]; then
        echo "${boldblue}Container diskspace${normal}"
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
    fi

    if [ $INTERACTIVE -ne 0 ]; then
        echo "${bold}Where do you want to create the local user environment?${normal}"
        echo " By default, a new directory will be created *under* your current location, which is $(pwd)"
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
        echo " 1) a stable version; you get the latest releases deemed stable ${boldgreen}(recommended)${normal}"
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
            echo "${red}Answering 'no' to this question may make automated installation on your system impossible!${normal}"
            echo
            echo -n "${boldblue}Do you have administrative access (root/sudo) on the current system?${normal} [yn] "
            read yn
            case $yn in
                [Yy]* ) SUDO=1; break;;
                [Nn]* ) SUDO=0; break;;
                * ) echo "Please answer yes or no.";;
            esac
        done
    fi
fi

if [ $SUDO -eq 1 ]; then
    which sudo || fatalerror "Sudo is not installed on this system, install it manually first..."
fi

echo "Looking for dependencies..."
if [[ "$OS" == "mac" ]]; then
    if ! which brew; then
        NEED+=("brew")
    fi
    #NEED+=("brew-cask")
fi
if [ "$DISTRIB_ID" = "centos" ] || [ "$DISTRIB_ID" = "rhel" ]; then
    yum list installed | grep -q epel-release
    if [ $? -ne 0 ]; then
        NEED+=("epel")
    fi
fi

if which python3; then
    echo "Checking sanity of your Python 3 installation..."
    python3 -c "from __future__ import print_function; import sys; print(sys.version)" | grep -i anaconda
    if [ $? -eq 0 ]; then
        fatalerror "Conflict error: The default Python on this system is managed by Anaconda, this is incompatible with LaMachine. Ensure the Python found in your \$PATH corresponds to a regular version as supplied with your OS, editing the order of your \$PATH in ~/.bashrc or ~/.bash_profile should be sufficient to solve this without completely uninstalling anaconda. See also https://stackoverflow.com/a/37377981/3311445"
    fi
else
    NEED+=("python3")
fi
echo ""

if [ $BUILD -eq 0 ]; then
    NEED_VIRTUALENV=0 #Do we need a virtualenv with ansible for the controller? Never needed if we are not building ourselves
else
    if ! which git; then
        NEED+=("git")
    fi
    if [ "$FLAVOUR" = "docker" ] || [ "$FLAVOUR" = "singularity" ] || [ "$FLAVOUR" = "lxc" ]; then
        NEED_VIRTUALENV=0 #Do we need a virtualenv with ansible for the controller? Never for containers, all ansible magic happens inside the container
    else
        NEED_VIRTUALENV=1 #Do we need a virtualenv with ansible for the controller? (this is a default we will attempt to falsify)
        if [ $GLOBAL_ANSIBLE -eq 1 ]; then
            if which ansible-playbook; then
                NEED_VIRTUALENV=0
            elif [ $SUDO -eq 1 ]; then #we can only install ansible globally if we have root
                NEED+=("ansible")
                NEED_VIRTUALENV=0
            fi
        fi
        if [ $NEED_VIRTUALENV -eq 1 ]; then
            if which python3; then
                #if we don't have python3 then we already flagged that
                # and pip and virtualenv will be included in its installation
                if ! python3 -m pip --version > /dev/null; then
                    NEED+=("pip")
                fi
                if ! python3 -m venv .venvtest > /dev/null; then
                    NEED+=("virtualenv")
                fi
                rm -Rf .venvtest
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
if [ "$FLAVOUR" == "lxc" ]; then
    echo "Looking for LXD..."
    if ! which lxc; then #not a typo
        NEED+=("lxd")
    fi
fi
if [ "$FLAVOUR" == "singularity" ]; then
    echo "Looking for singularity..."
    if ! which singularity; then
        NEED+=("singularity")
    fi
    if ! which debootstrap; then
        NEED+=("debootstrap")
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
            cmd="brew update; brew tap caskroom/cask && brew cask install virtualbox vagrant"
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
    elif [ "$package" = "singularity" ]; then
        echo "We expect users of singularity to be able to install singularity themselves."
        echo "Singularity was not found on your system yet!"
        echo "Please install singularity, start the daemon, and press ENTER to continue (or CTRL-C) to abort."
        read
    elif [ "$package" = "lxd" ]; then
        cmd=""
        if [ "$OS" = "debian" ]; then
            if [ "$DISTRIB_ID" = "ubuntu" ] || [ "$DISTRIB_ID" = "linuxmint" ]; then
                cmd="sudo apt-get $NONINTERACTIVEFLAGS install lxd"
            else
                echo "LXD is not packaged for debian yet, please follow the instructions on https://stgraber.org/2017/01/18/lxd-on-debian/ to install it through snapd"
            fi
        elif [ "$OS" = "redhat" ]; then
                echo "LXD is not packaged for CentOS/RHEL yet, please follow the instructions on https://discuss.linuxcontainers.org/t/lxd-on-centos-7/1250 to install it through snapd"
        elif [ "$OS" = "arch" ]; then
                echo "LXD is not packaged for Arch Linux but it is in the Arch User Repository (AUR), please install the lxd AUR package and install the lxc package through pacman."
            cmd=""
        else
            cmd=""
        fi
        if [ ! -z "$cmd" ]; then
            echo "LXD is required for LaMachine with LXD but not installed yet. ${bold}Install now?${normal}"
            while true; do
                echo -n "${bold}Run:${normal} $cmd ? [yn] "
                if [ "$INTERACTIVE" -eq 1 ]; then
                    read yn
                else
                    yn="y"
                fi
                case $yn in
                    [Yy]* ) $cmd || fatalerror "LXD installation failed!"; break;;
                    [Nn]* ) echo "Please install LXD manually, see https://linuxcontainers.org/lxd/getting-started-cli/" && echo " .. press ENTER when done or CTRL-C to abort..." && read; break;;
                    * ) echo "Please answer yes or no.";;
                esac
            done
        else
            echo "No automated installation possible on your OS."
            if [ "$INTERACTIVE" -eq 0 ]; then exit 5; fi
            echo "Please install LXD manually" && echo " .. press ENTER when done or CTRL-C to abort..." && read
        fi
    elif [ "$package" = "debootstrap" ]; then
        if [ "$OS" = "debian" ]; then
            cmd="sudo apt-get $NONINTERACTIVEFLAGS install debootstrap"
        elif [ "$OS" = "redhat" ]; then
            cmd="sudo yum $NONINTERACTIVEFLAGS install debootstrap"
        elif [ "$OS" = "arch" ]; then
            cmd="sudo pacman $NONINTERACTIVEFLAGS -Sy debootstrap"
        elif [ "$OS" = "mac" ]; then
            cmd="brew install debootstrap" #not sure if this works
        else
            cmd=""
        fi
        echo "Debootstrap is required for LaMachine with Singularity but not installed yet. ${bold}Install now?${normal}"
        if [ ! -z "$cmd" ]; then
            while true; do
                echo -n "${bold}Run:${normal} $cmd ? [yn] "
                if [ "$INTERACTIVE" -eq 1 ]; then
                    read yn
                else
                    yn="y"
                fi
                case $yn in
                    [Yy]* ) $cmd || fatalerror "Debootstrap installation failed!"; break;;
                    [Nn]* ) echo "Please install debootstrap manually" && echo " .. press ENTER when done or CTRL-C to abort..." && read; break;;
                    * ) echo "Please answer yes or no.";;
                esac
            done
        else
            echo "No automated installation possible on your OS."
            if [ "$INTERACTIVE" -eq 0 ]; then exit 5; fi
            echo "Please install debootstrap manually" && echo " .. press ENTER when done or CTRL-C to abort..." && read
        fi
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
        #brew tap caskroom/cask-cask || brew tap caskroom/cask-cask || fatalerror "Failed to install brew-cask, ran: brew tap caskroom/cask"
        #                      ^-- command is repeated in case of failure because homebrew may update and fail once and work the 2nd time
    elif [ "$package" = "brew-cask" ]; then
        #(NO LONGER USED!)
        echo "Installing brew-cask"
        brew tap caskroom/cask || brew tap caskroom/cask || fatalerror "Failed to install brew-cask, ran: brew tap caskroom/cask"
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
            echo "Please install epel manually" && echo " .. press ENTER when done or CTRL-C to abort..." && read
        fi
    elif [ "$package" = "python3" ]; then
        if [ "$OS" = "debian" ]; then
            cmd="sudo apt-get $NONINTERACTIVEFLAGS install python3 python3-pip python3-venv"
        elif [ "$OS" = "redhat" ]; then
            cmd="sudo yum $NONINTERACTIVEFLAGS install python3 python3-pip"
        elif [ "$OS" = "arch" ]; then
            cmd="sudo pacman $NONINTERACTIVEFLAGS -Sy python python-pip"
        elif [ "$OS" = "mac" ]; then
            cmd="brew update; brew install python"
        else
            cmd=""
        fi
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
                    [Nn]* ) echo "Please install python 3 manually" && echo " .. press ENTER when done or CTRL-C to abort..." && read; break;;
                    * ) echo "Please answer yes or no.";;
                esac
            done
        else
            echo "No automated installation possible on your OS."
            if [ "$INTERACTIVE" -eq 0 ]; then exit 5; fi
            echo "Please install python 3 manually" && echo " .. press ENTER when done or CTRL-C to abort..." && read
        fi
    elif [ "$package" = "ansible" ]; then
        if [ "$OS" = "debian" ]; then
            if [ "$DISTRIB_ID" = "ubuntu" ] || [ "$DISTRIB_ID" = "linuxmint" ]; then
                if [ "$DISTRIB_ID" = "ubuntu" ] && [ "${DISTRIB_RELEASE%\.*}" -lt 20 ]; then
                    #add PPA
                    cmd="sudo apt-get update && sudo apt-get $NONINTERACTIVEFLAGS install software-properties-common && sudo apt-add-repository -y ppa:ansible/ansible && sudo apt-get update && sudo apt-get $NONINTERACTIVEFLAGS install ansible"
                else
                    cmd="sudo apt-get update && sudo apt-get $NONINTERACTIVEFLAGS install ansible"
                fi
            else
                #for debian
                cmd="echo 'deb http://ppa.launchpad.net/ansible/ansible/ubuntu trusty main' | sudo tee -a /etc/apt/sources.list && sudo apt-get $NONINTERACTIVEFLAGS update && sudo apt-get $NONINTERACTIVEFLAGS install gnupg && sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367 && sudo apt-get $NONINTERACTIVEFLAGS update && sudo apt-get $NONINTERACTIVEFLAGS --allow-unauthenticated install ansible"
            fi
        elif [ "$OS" = "redhat" ]; then
            cmd="sudo yum  $NONINTERACTIVEFLAGS install ansible"
        elif [ "$OS" = "arch" ]; then
            cmd="sudo pacman  $NONINTERACTIVEFLAGS -Sy ansible"
        elif [ "$OS" = "mac" ]; then
            cmd="brew install ansible"
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
            cmd="sudo apt-get  $NONINTERACTIVEFLAGS install python3-pip"
        elif [ "$OS" = "redhat" ]; then
            cmd="sudo yum  $NONINTERACTIVEFLAGS install python3-pip"
        elif [ "$OS" = "arch" ]; then
            cmd="sudo pacman  $NONINTERACTIVEFLAGS -Sy python-pip"
        elif [ "$OS" = "mac" ]; then
            fatalerror "no pip was found? This should not happen, it should have been installed through brew install python"
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
        #this doesn't really do much anymore for most distros as most already include this by default
        if [ "$OS" = "debian" ]; then
            cmd="sudo apt-get $NONINTERACTIVEFLAGS install python3-venv"
        else
            cmd=""
        fi
        echo "python3 -m venv is required for LaMachine but not installed yet. ${bold}Install now?${normal}"
        if [ ! -z "$cmd" ]; then
            while true; do
                echo -n "${bold}Run:${normal} $cmd ? [yn] "
                if [ "$INTERACTIVE" -eq 1 ]; then
                    read yn
                else
                    yn="y"
                fi
                case $yn in
                    [Yy]* ) $cmd || fatalerror "Venv installation failed"; break;;
                    [Nn]* ) echo "Please install venv manually" && echo " .. press ENTER when done or CTRL-C to abort..." && read; break;;
                    * ) echo "Please answer yes or no.";;
                esac
            done
        else
            echo "No automated installation of venv possible on your OS."
            if [ "$INTERACTIVE" -eq 0 ]; then exit 5; fi
            echo "Please install venv manually" && echo " .. press ENTER when done or CTRL-C to abort..." && read
        fi
    fi
done

if [ -z "$LM_NAME" ]; then
    echo "Your LaMachine installation is identified by a name (local env name, VM name) etc.."
    echo "(This does not need to match the hostname or domain name, which is a separate configuration setting)"
    echo -n "${boldblue}Enter a name for your LaMachine installation (no spaces!):${normal} "
    read LM_NAME
    LM_NAME="${LM_NAME%\\n}"
fi



LM_NAME=${LM_NAME/ /} #strip any spaces because users won't listen anyway
if [ -z "$LM_NAME" ]; then
    echo "${boldred}No names provided${normal}" >&2
    exit 2
fi

if [ $BUILD -eq 1 ] && [[ "$FLAVOUR" != "lxc" ]]; then
    DETECTEDHOSTNAME=$(hostname --fqdn)
    if [ -z "$DETECTEDHOSTNAME" ] || [ "$FLAVOUR" = "vagrant" ] || [ "$FLAVOUR" = "docker" ] || [ "$FLAVOUR" = "singularity" ]; then
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
        echo -n "${boldblue}Please enter the hostname (or FQDN) of the LaMachine system (just press ENTER if you want to use $DETECTEDHOSTNAME here):${normal} "
        read HOSTNAME
        HOSTNAME="${HOSTNAME%\\n}"
        if [ -z "$HOSTNAME" ]; then
            HOSTNAME=$DETECTEDHOSTNAME
        fi
    fi
fi

if [[ "$FLAVOUR" == "remote" ]]; then
    if [ $USER_SET -eq 0 ] && [ $INTERACTIVE -eq 1 ]; then
        echo
        echo
        echo "To provision the remote machine, LaMachine needs to be able to connect over ssh as specific user."
        echo "The user must exist and ideally passwordless ssh keypairs should be available. Note that connecting and running"
        echo "as root is explicitly forbidden. The user, on the other hand, does require sudo rights on the remote machine."
        echo -n "${boldblue}What user should LaMachine use to provision the remote machine?${normal} "
        read USERNAME
        USERNAME="${USERNAME%\\n}"
    fi
fi

STAGEDCONFIG="$BASEDIR/lamachine-$LM_NAME.yml"
STAGEDMANIFEST="$BASEDIR/install-$LM_NAME.yml"

HOMEDIR=$(echo ~)


if [ $INTERACTIVE -eq 1 ]; then
    if [[ $FLAVOUR == "vagrant" ]] || [[ $FLAVOUR == "docker" ]] || [[ $FLAVOUR == "lxc" ]]; then
        echo
        echo
        echo "In order to share data files, LaMachine shares a directory from your actual host machine"
        echo "with the VM/container, which will be mounted at /data by default."
        echo "${boldblue}What directory do you want to share?${normal} (if left empty, your home directory $HOMEDIR will be shared by default)"
        read HOSTDATAPATH
        HOSTDATAPATH="${HOSTDATAPATH%\\n}"

        echo "${boldblue}Do you want to put data from the web services and web applications on the shared data volume as well?${normal}  [yn]"
        while true; do
            read yn
            case $yn in
                [Yy]* ) SHARED_WWW_DATA="yes"; break;;
                [Nn]* ) SHARED_WWW_DATA="no"; break;;
                * ) echo "Please answer yes or no.";;
            esac
        done
    fi

    if [[ $FLAVOUR == "vagrant" ]] || [[ $FLAVOUR == "docker" ]] || [[ $FLAVOUR == "lxc" ]]; then
        echo
        echo
        echo "To offer convenient access to the HTTP webserver in your VM/container, a port will be forwarded from your host system"
        echo "${boldblue}What port do you want to forward for HTTP?${normal} (if left empty, 8080 will be the default)"
        read HOSTPORT
        HOSTPORT="${HOSTPORT%\\n}"
    fi
fi

if [ -z "$HOSTDATAPATH" ]; then
    HOSTDATAPATH=$HOMEDIR
fi
if [ -z "$HOSTPORT" ]; then
    HOSTPORT="8080"
fi

if [ $BUILD -eq 1 ] && [[ "$FLAVOUR" != "lxc" ]]; then
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
        echo "host_data_path: \"$HOSTDATAPATH\" #Data path on the host machine that will be shared with LaMachine" >> $STAGEDCONFIG
        echo "data_path: \"/data\" #Shared data path (in LaMachine) that is tied to host_data_path, you can change this" >> $STAGEDCONFIG
        echo "shared_www_data: $SHARED_WWW_DATA #Put web data in the shared data path (rather than inside the container)" >> $STAGEDCONFIG
        echo "global_prefix: \"/usr/local\" #Path for global installations (only change once on initial installation)" >> $STAGEDCONFIG
        echo "source_path: \"/usr/local/src\" #Path where sources will be stored/compiled (only change once on initial installation)" >> $STAGEDCONFIG
        if [ "$VAGRANTBOX" == "centos/7" ] || [ "$VAGRANTBOX" == "centos/8" ]; then
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
        echo "host_data_path: \"$HOSTDATAPATH\" #Data path on the host machine that will be shared with LaMachine" >> $STAGEDCONFIG
        echo "data_path: \"/data\" #Shared data path (in LaMachine) that is tied to host_data_path" >> $STAGEDCONFIG
        echo "move_share_www_data: $SHARED_WWW_DATA #Move www-data to the shared volume" >> $STAGEDCONFIG
        echo "global_prefix: \"/usr/local\" #Path for global installations (only change once on initial installation)" >> $STAGEDCONFIG
        echo "source_path: \"/usr/local/src\" #Path where sources will be stored/compiled (only change once on initial installation)" >> $STAGEDCONFIG
    elif [[ $FLAVOUR == "singularity" ]] || [[ $FLAVOUR == "lxc" ]]; then
        GROUP="lamachine"
        echo "unix_user: \"lamachine\" #do not change this!" >> $STAGEDCONFIG #TODO: not sure about this yet for singularity
        echo "unix_group: \"lamachine\" #must be same as unix_user, changing this is not supported yet" >> $STAGEDCONFIG
        echo "homedir: \"/home/lamachine\"" >> $STAGEDCONFIG
        echo "lamachine_path: \"/lamachine\" #Path where LaMachine source is initially stored/shared (do not change this for singularity!" >> $STAGEDCONFIG
        echo "host_data_path: \"$HOSTDATAPATH\" #Data path on the host machine that will be shared with LaMachine" >> $STAGEDCONFIG
        echo "data_path: \"/data\" #Shared data path (in LaMachine) that is tied to host_data_path (do not change this for singularity)" >> $STAGEDCONFIG
        echo "shared_www_data: $SHARED_WWW_DATA #Put web data in the shared data path (rather than inside the container)" >> $STAGEDCONFIG
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
    if [[ $FLAVOUR == "vagrant" ]] || [[ $FLAVOUR == "docker" ]] || [[ $FLAVOUR == "singularity" ]] || [[ $FLAVOUR == "lxc" ]] || [[ $FLAVOUR == "remote" ]]; then
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
    echo "force_https: no #Should be enabled when behind a reverse proxy that handles https for you, ensures all internal links are https and uses X-Forwarded-Host" >> $STAGEDCONFIG
    echo "reverse_proxy_ip: \"172.17.0.1\" #IP address of the reverse proxy, as seen from LaMachine. The default here works for certain docker setups. This setting is currently needed only for Jupyter Hub" >> $STAGEDCONFIG
echo "mapped_http_port: $HOSTPORT #mapped webserver port on host system (for VM/docker only)
webservertype: nginx #If set to anything different, the internal webserver will not be enabled/provided by LaMachine (which allows you to run your own external one), do leave webserver: true set as is though.
services: [ $SERVICES ]  #List of services to provide, if set to [ all ], all possible services from the software categories you install will be provided. You can remove this and list specific services you want to enable. This is especially needed in case of a LaMachine installation that intends to only provide a single service.
remote_services: #Remote services you would like to tie to this LaMachine installation, remote services take precendence over local ones (please use exactly 4 spaces as indentation here)
    switchboard: \"https://switchboard.clarin.eu\"
    autosearch: \"https://portal.clarin.inl.nl/autocorp\"" >> $STAGEDCONFIG
echo "portal_remote_registries: [] #Remote LaMachine instances that should be incorported into the portal" >> $STAGEDCONFIG
if [[ $FLAVOUR == "vagrant" ]] || [[ $FLAVOUR == "docker" ]] || [[ $FLAVOUR == "singularity" ]] || [[ $FLAVOUR == "lxc" ]] || [[ $FLAVOUR == "remote" ]]; then
    echo "clam_include: \"/usr/local/etc/clam_base.config.yml\" #You can set this to a CLAM base configuration file that will be included from all the webservices, it allows you to do configure common traits like authentication" >> $STAGEDCONFIG
else
    echo "clam_include: \"$BASEDIR/$LM_NAME/etc/clam_base.config.yml\" #You can set this to a CLAM base configuration file that will be included from all the webservices, it allows you to do configure common traits like authentication" >> $STAGEDCONFIG
fi
echo "clam_base_config: {} #extra clam base configuration keys" >>$STAGEDCONFIG
echo "oauth_client_id: \"\" #shared oauth client ID
oauth_client_secret: \"\" #shared oauth client secret
oauth_auth_url: \"\" #something like https://your-identity-provider/oauth/authenticate
oauth_token_url: \"\" #something like https://your-identity-provider/oauth/token
oauth_userinfo_url: \"\" #something like https://your-identity-provider/oauth/userinfo
oauth_revoke_url: \"\" #(optional) something like https://your-identity-provider/oauth/revoke
oauth_scope: [] #Set this to [ \"openid\", \"email\" ] if you want to use OpenID Connect
oauth_sign_algo: \"\" #(optional) You can set this to RS256 or HS256, for OpenID Connect
oauth_jwks_url: \"\" #(optional) something like https://your-identity-provider/oauth/jwks , used by OpenID Connect to obtain a signing key autoamtically (usually in combination with RS256 algorithm)
oauth_sign_key: {} #(optional) provide a sign key manually (should be a dict that has fields like kty, use,alg,n and e), used by OpenID Connect (usually in combination with RS256 algorithm)
" >> $STAGEDCONFIG
if [[ $OS == "mac" ]] || [[ "$FLAVOUR" == "remote" ]]; then
    echo "lab: false #Enable Jupyter Lab environment, note that this opens the system to arbitrary code execution and file system access! (provided the below password is known)" >> $STAGEDCONFIG
else
    echo "lab: true #Enable Jupyter Lab environment, note that this opens the system to arbitrary code execution and file system access! (provided the below password is known)" >> $STAGEDCONFIG
fi
echo "lab_password_sha1: \"sha1:fa40baddab88:c498070b5885ee26ed851104ddef37926459b0c4\" #default password for Jupyter Lab: lamachine, change this with 'lamachine-passwd lab'" >> $STAGEDCONFIG
echo "lab_allow_origin: \"*\" #hosts that may access the lab environment" >> $STAGEDCONFIG
echo "flat_password: \"flat\" #password for the FLAT administrator (username 'flat'). You can change this with lamachine-passwd flat" >> $STAGEDCONFIG
echo "custom_flat_settings: false  #set this to true if you customized your flat settings and want to prevent LaMachine from overwriting it again on update" >> $STAGEDCONFIG
echo "ssh_public_key: \"\" #ssh public key (the actual contents of id_rsa.pub) to allow the container/VM to connect to restricted outside services" >> $STAGEDCONFIG
echo "ssh_private_key: \"\" #ssh private key (the actual contents of id_rsa) to allow the container/VM to connect to restricted outside services" >> $STAGEDCONFIG
echo "ssh_key_filename: \"id_rsa\" #the prefix used to store the above ssh keys (if provided) (.pub will be automatically appended for public key)" >> $STAGEDCONFIG
DJANGO_SECRET_KEY=$(LC_ALL=C tr -dc 'A-Za-z0-9_' </dev/urandom | head -c 50 ; echo)
echo "django_secret_key: \"$DJANGO_SECRET_KEY\" #secret key for django-based applications (for internal use only)" >> $STAGEDCONFIG
if [ $FORCE -ne 0 ]; then
    echo "force: $FORCE #Sets the default force parameter for updates, set to 1 to force updates or 2 to explicitly remove all sources and start from scratch on each update. Remove this line entirely if you don't need it or are in doubt" >> $STAGEDCONFIG
fi
if [ $NOSYSUPDATE -ne 0 ]; then
    echo "nosysupdate: $NOSYSUPDATE #Skips updating the global packages provided by the distribution" >> $STAGEDCONFIG
fi
    if [[ $FLAVOUR == "local" ]] || [[ "$OS" == "mac" ]]; then
        echo "python_bin: python3 #The Python interpreter to use to set up the virtual environment, may be an absolute path" >> $STAGEDCONFIG
        echo "pip_bin: pip3 #The pip tool belonging to the above interpreter, may be an absolute path" >> $STAGEDCONFIG
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
      while true; do
        echo "${bold}Your LaMachine configuration is now as follows:${normal}${yellow}"
        cat $STAGEDCONFIG
        echo "${normal}"
        echo "${bold}Do you want to make any changes to the above configuration? This will open a text editor for you to make changes. [yn]${normal}"
        read choice
        case $choice in
            [n]* ) break;;
            [y]* )
                echo "(opening configuration $STAGEDCONFIG in editor $EDITOR)"
                if ! "$EDITOR" "$STAGEDCONFIG"; then
                    echo "ERROR: aborted by editor..." >&2
                    exit 2
                fi
                break;;
            * ) echo "Please answer with y or n..";;
        esac
        sleep 2
      done
    fi

 fi
fi #build

if [ ! -d lamachine-controller ]; then
    mkdir lamachine-controller || fatalerror "Unable to create directory for LaMachine bootstrap control environment"
fi

if [ ! -d lamachine-controller/$LM_NAME ]; then
    echo "Setting up bootstrap control environment..."
    if [ $NEED_VIRTUALENV -eq 1 ]; then
        echo " (with virtualenv and ansible inside)"
        python3 -m venv lamachine-controller/$LM_NAME || fatalerror "Unable to create LaMachine bootstrap control environment"
        cd lamachine-controller/$LM_NAME
        source ./bin/activate || fatalerror "Unable to activate LaMachine bootstrap controller environment"
        pip install -U pip wheel setuptools || fatalerror "Failed to update pip"
        pip install ansible || fatalerror "Unable to install Ansible"
        #pip install docker==2.7.0 docker-compose ansible-container[docker]
    else
        echo " (simple)"
        mkdir lamachine-controller/$LM_NAME && cd lamachine-controller/$LM_NAME #no need for a virtualenv
    fi
else
    echo "Reusing existing bootstrap control environment..."
    cd lamachine-controller/$LM_NAME
    if [ $NEED_VIRTUALENV -eq 1 ]; then
        source ./bin/activate || fatalerror "Unable to activate LaMachine bootstrap controller environment"
    fi
fi

if [[ "$FLAVOUR" != "lxc" ]]; then

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
            if [ "$INSTALL" = "lamachine-core" ]; then
                echo "  roles: [ $INSTALL ]" >> $STAGEDMANIFEST
            else
                echo "  roles: [ lamachine-core, $INSTALL ]" >> $STAGEDMANIFEST
            fi
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
        while true; do
            echo "${bold}The following packages are marked to be installed in the installation manifest:${normal}${green}"
            grep --color=never -e '^\s*-.*##' $STAGEDMANIFEST
            echo "${normal}"
            echo "${bold}The following additional packages are available but NOT marked for installation yet:${normal}${yellow}"
            grep --color=never -e '^\s*# -.*##' $STAGEDMANIFEST
            echo "${normal}"
            echo "Note that you can at any later stage also add packages using lamachine-add"
            echo
            echo "${bold}Do you want to adapt the list of to-be-installed packages by opening the installation manifest in a text editor? [yn]${normal}"
            read choice
            case $choice in
                [n]* ) break;;
                [y]* )
                    echo "(opening installation manifest $STAGEDMANIFEST in editor $EDITOR)"
                    if ! "$EDITOR" "$STAGEDMANIFEST"; then
                        echo "ERROR: aborted by editor..." >&2
                        exit 2
                    fi
                    break;;
                * ) echo "Please answer with y or n..";;
            esac
            sleep 2
        done
    fi

    #copy staged install to final location
    cp $STAGEDMANIFEST $SOURCEDIR/install.yml || fatalerror "Unable to copy $STAGEDMANIFEST"
    if [ -e customversions.yml ]; then
        cp customversions.yml $SOURCEDIR/customversions.yml
    fi
fi

fi #!= lxc

HOMEDIR=$(echo ~)
if [[ "$FLAVOUR" == "vagrant" ]] || [[ "$FLAVOUR" == "docker" ]] || [[ "$FLAVOUR" == "singularity" ]] || [[ "$FLAVOUR" == "lxc" ]]; then
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
        cp -f $SOURCEDIR/Vagrantfile.prebuilt.erb $SOURCEDIR/Vagrantfile || fatalerror "Unable to copy Vagrantfile"
        sed -i.bak "s/<%= box_name %>/proycon\/lamachine/g" $SOURCEDIR/Vagrantfile || fatalerror "Unable to run sed"
        sed -i.bak "s/lamachine-vm/$LM_NAME/g" $SOURCEDIR/Vagrantfile || fatalerror "Unable to run sed"
        export HOSTDATAPATH_TMP="${HOSTDATAPATH//\//\\/}"
        sed -i.bak "s/Dir.home/\\\"$HOSTDATAPATH_TMP\\\"/g" $SOURCEDIR/Vagrantfile || fatalerror "Unable to run sed"
        sed -i.bak "s/8080/$HOSTPORT/g" $SOURCEDIR/Vagrantfile || fatalerror "Unable to run sed"
        if [ $INTERACTIVE -eq 1 ]; then
            #not needed for BUILD=1 because most interesting parameters inherited from the ansible host configuration
            echo "${bold}Do you want to open the vagrant configuration in an editor for final configuration? (recommended to increase memory/cpu cores!) [yn]${normal}"
            EDIT=0
            while true; do
                read choice
                case $choice in
                    [n]* ) break;;
                    [y]* ) EDIT=1;  break;;
                    * ) echo "Please answer with y or n..";;
                esac
            done
            if [ $EDIT -eq 1  ]; then
                if ! "$EDITOR" "$SOURCEDIR/Vagrantfile"; then
                    echo "ERROR: aborted by editor..." >&2
                    exit 2
                fi
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
    export VAGRANT_CWD=$SOURCEDIR
    echo "Ensuring LaMachine base box is the latest version" >&2
    vagrant box update
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
        echo "${bold}The installation will now begin and will ask you for a BECOME password, "
        echo "here you need to fill in your sudo password as this is needed to install certain"
        echo "global packages from your distribution, it will only be used for limited parts of"
        echo "the installation. The installation process may take quite some time and produce a"
        echo "lot of output (most of which you can safely ignore)."
        echo "Press ENTER to continue and feel free to get yourself a tea or coffee while you wait!${normal}"
        read
        ASKSUDO="--ask-become-pass"
    else
        if [ $INTERACTIVE -eq 1 ]; then
            echo "${bold}The  installation will now begin. The installation process may take quite some time and produce a lot of output (most of which you can safely ignore). Press ENTER to continue and feel free to get yourself a tea or coffee while you wait!${normal}"
            read
        fi
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
        echo "  ${bold}you will need to do this each time you open a new terminal / start a new shell${normal}"
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
        docker build -t $DOCKERREPO:$LM_NAME --build-arg LM_NAME=$LM_NAME --build-arg LM_VERSION=$LM_VERSION --build-arg HOSTNAME=$HOSTNAME . 2>&1 | tee lamachine-$LM_NAME.log
        rc=${PIPESTATUS[0]}
        #add activation script on the host machine:
    else
        echo "Pulling pre-built docker image.."
        docker pull $DOCKERREPO
        rc=$?
    fi
    if [ $rc -eq 0 ]; then
        echo "======================================================================================"
        if [ $BUILD -eq 1 ]; then
            echo "${boldgreen}All done, a docker image has been built!${normal}"
            echo "- to run a *new* interactive container using this image, run: lamachine-$LM_NAME-activate or: docker run -t -i $DOCKERREPO:$LM_NAME"
            echo "- to run a non-interactive container: lamachine-$LM_NAME-run nameofyourtoolhere or: docker run -t $DOCKERREPO:$LM_NAME nameofyourtoolhere"
            echo "- to start a new container with a webserver run lamachine-$LM_NAME-start or docker run -p 8080:80 -h $HOSTNAME -t $DOCKERREPO:$LM_NAME lamachine-start-webserver ,  and then connect on http://localhost:8080"
        else
            echo "${boldgreen}All done, a docker image has been downloaded!${normal}"
            echo "- to run a *new* interactive container using this image, run: docker run -t -i $DOCKERREPO"
            echo "- to run a non-interactive container: docker run -t $DOCKERREPO nameofyourtoolhere"
            echo "- to start a new container with a webserver: docker run -p 8080:80 -h latest -t $DOCKERREPO lamachine-start-webserver ,  and then connect on http://localhost:8080"
        fi
        echo -e "#!/bin/bash\necho \"Instantiating a **new** interactive Docker container with LaMachine...\"; docker run -i -t -h $HOSTNAME --mount type=bind,source=$HOSTDATAPATH,target=/data $DOCKERREPO:$LM_NAME" > $HOMEDIR/bin/lamachine-$LM_NAME-activate
        echo -e "#!/bin/bash\necho \"Instantiating a **new** interactive Docker container with LaMachine...\"; docker run -i -t -h $HOSTNAME --mount type=bind,source=$HOSTDATAPATH,target=/data $DOCKERREPO:$LM_NAME \$@" > $HOMEDIR/bin/lamachine-$LM_NAME-run
        echo -e "#!/bin/bash\necho \"Instantiating a **new** Docker container with the LaMachine webserver; connect on http://127.0.0.1:$HOSTPORT\"; docker run -t -p $HOSTPORT:80 -h $HOSTNAME --mount type=bind,source=$HOSTDATAPATH,target=/data $DOCKERREPO:$LM_NAME lamachine-start-webserver -f" > $HOMEDIR/bin/lamachine-$LM_NAME-start
        chmod a+x $HOMEDIR/bin/lamachine-$LM_NAME-*
        ln -sf $HOMEDIR/bin/lamachine-$LM_NAME-activate $HOMEDIR/bin/lamachine-activate #shortcut
    else
        echo "======================================================================================"
        echo "${boldred}The docker build has failed unfortunately.${normal} You have several options:"
        echo " - Retry the bootstrap, possibly tweaking configuration options"
        echo " - File a bug report on https://github.com/proycon/LaMachine/issues/"
        if [ $BUILD -eq 1 ]; then
            echo "   The log file has been written to $(pwd)/lamachine-$LM_NAME.log (include it with any bug report)"
        fi
    fi
elif [[ "$FLAVOUR" == "lxc" ]]; then
        echo "Building LXC container (unprivileged!), using the profile: $LXCPROFILE"
        lxc launch $LXCBASE $LM_NAME --profile $LXCPROFILE || fatalerror "Unable to create new container. Ensure LXD is installed, the current user is in the lxd group, and the container $LM_NAME does not already exist"
        echo "${boldblue}Launching LaMachine bootstrap inside the new container${normal}"
        echo "${boldblue}------------------------------------------------------${normal}"
        echo "${boldyellow}Important note: anything below this point will be executed in the container rather than on the host system!${normal}"
        echo "${boldyellow}                The sudo/become password can be left empty when asked for and will work${normal}"
        if [ $INTERACTIVE -eq 1 ]; then
            echo "(Press ENTER to continue)"
            read
        fi
        OPTS=""
        if [ ! -z "$INSTALL" ]; then
            OPTS="$OPTS --install \"$INSTALL\""
        fi
        if [[ "$VERSION" != "undefined" ]]; then
            OPTS="$OPTS --version $VERSION"
        fi
        if [[ "$HOSTNAME" != "" ]]; then
            OPTS="$OPTS --hostname $HOSTNAME"
        fi
        if [ $INTERACTIVE -eq 0 ]; then
            OPTS="$OPTS --noninteractive"
        fi
        CMD="lxc exec $LM_NAME -- apt $NONINTERACTIVEFLAGS install python3"
        $CMD || fatalerror "Failure when preparing to bootstrap (command was $CMD)"
        echo -e "#!/bin/bash\nlxc start $LM_NAME; lxc exec $LM_NAME -- su ubuntu -l" > $HOMEDIR/bin/lamachine-$LM_NAME-activate
        echo -e "#!/bin/bash\nlxc stop $LM_NAME; exit \$?" > $HOMEDIR/bin/lamachine-$LM_NAME-stop
        echo -e "#!/bin/bash\nlxc start $LM_NAME; exit \$?" > $HOMEDIR/bin/lamachine-$LM_NAME-start
        echo -e "#!/bin/bash\nlxc exec $LM_NAME -- bash" > $HOMEDIR/bin/lamachine-$LM_NAME-connect
        echo -e "#!/bin/bash\nlxc exec $LM_NAME -- lamachine-update" > $HOMEDIR/bin/lamachine-$LM_NAME-update
        echo -e "#!/bin/bash\nlxc delete $LM_NAME; exit \$?" > $HOMEDIR/bin/lamachine-$LM_NAME-destroy
        chmod a+x $HOMEDIR/bin/lamachine-$LM_NAME-*
        ln -sf $HOMEDIR/bin/lamachine-$LM_NAME-activate $HOMEDIR/bin/lamachine-activate #shortcut
        CMD="lxc exec $LM_NAME -- su ubuntu -l -c \"bash <(curl -s https://raw.githubusercontent.com/proycon/LaMachine/$BRANCH/bootstrap.sh) --name $LM_NAME --flavour global $OPTS\"" #NOTE: command is duplicated below, update that one too!
        echo $CMD
        lxc exec $LM_NAME -- su ubuntu -l -c "bash <(curl -s https://raw.githubusercontent.com/proycon/LaMachine/$BRANCH/bootstrap.sh) --name $LM_NAME --flavour global $OPTS"  || fatalerror "Unable to bootstrap (command was $CMD)"
        if [ $rc -eq 0 ]; then
            echo "======================================================================================"
            echo "${boldgreen}All done, your LXD container has been built!${normal}"
            echo "- to enter your container, run lamachine-$LM_NAME-activate"
        fi
elif [[ "$FLAVOUR" == "singularity" ]]; then
    if [ $BUILD -eq 1 ]; then
        echo "Building singularity image (requires sudo).."
        echo "${boldyellow}(sorry, this is not implemented yet! Use the download a pre-built container option instead!)${normal}"
        #sed -i.bak "s/hosts: all/hosts: localhost/g" $SOURCEDIR/install.yml || fatalerror "Unable to run sed"
        #cp $SOURCEDIR/Singularity $SOURCEDIR/Singularity.def
        #sed -i.bak "s/\$HOSTNAME/$HOSTNAME/g" $SOURCEDIR/Singularity.def || fatalerror "Unable to run sed"
        #sed -i.bak "s/\$ANSIBLE_OPTIONS/$ANSIBLE_OPTIONS/g" $SOURCEDIR/Singularity.def || fatalerror "Unable to run sed"
        #sed -i.bak "s/\$LM_VERSION/$LM_VERSION/g" $SOURCEDIR/Singularity.def || fatalerror "Unable to run sed"
        ##echo "$HOSTNAME ansible_connection=local" > $SOURCEDIR/hosts.ini #not needed
        #sudo singularity build $LM_NAME.sif $SOURCEDIR/Singularity.def 2>&1 | tee lamachine-$LM_NAME.log
        #rc=${PIPESTATUS[0]}
        rc=1
    else
        echo "Pulling pre-built docker image.."
        singularity pull docker://proycon/lamachine
        rc=$?
        ls lamachine_latest.sif
    fi
    if [ $rc -eq 0 ]; then
        echo "======================================================================================"
        if [ $BUILD -eq 1 ]; then
            echo "${boldgreen}All done, a singularity image has been built!${normal}"
            echo "- to create and run a *new* interactive container using this image, run: singularity run -u lamachine_latest.sif"
        else
            echo "${boldgreen}All done, a singularity image has been downloaded!${normal}"
            echo "- to create and run a *new* interactive container using this image, run: singularity run -u lamachine_latest.sif"
        fi
    else
        echo "======================================================================================"
        echo "${boldred}The singularity build has failed unfortunately.${normal} You have several options:"
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
export PATH=~/bin:$PATH
if [ "$CONTROLLER" = "internal" ] && [ $rc -eq 0 ]; then  #only clean up if everything went well
    cd ../..
    rm -rf "lamachine-controller/$LM_NAME" 2>/dev/null
    rm $STAGEDCONFIG 2>/dev/null
    rm $STAGEDMANIFEST 2>/dev/null
fi
if [ $NEED_VIRTUALENV -eq 1 ]; then
    deactivate #deactivate the controller before quitcustomized your flat settings and want to prevent LaMachine from overwriting it again on update
fi
exit $rc
