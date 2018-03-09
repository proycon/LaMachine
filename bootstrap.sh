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

bold=$(tput bold)
boldred=${bold}$(tput setaf 1) #  red
boldgreen=${bold}$(tput setaf 2) #  green
boldblue=${bold}$(tput setaf 4) #  blue
normal=$(tput sgr0)

echo "${bold}=====================================================================${normal}"
echo "           ,              ${bold}LaMachine v2${normal} - NLP Software distribution"
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
    echo "           this expects you to provide a LaMachine version file with exact version numbers."
    echo " ${bold}--env${normal} [virtualenv|conda] - Local user environment type"
    echo "  virtualenv = A simple virtual environment"
    echo "  conda = provided by the Anaconda Distribution, a powerful data science platform (mostly for Python and R). EXPERIMENTAL!!"
    echo " ${bold}--private${normal} - Do not transmit anonymous analytics on this LaMachine build"
    echo " ${bold}--minimal${normal} - Attempt to install less than normal, leaving out extra options. This may break things."
    echo " ${bold}--prefer_distro${normal} - Prefer distribution packages over other channels (such as pip). This generally installs more conserative versions, and less, but might break things."
    echo " ${bold}--dockerrepo${normal} - Docker repository name (default: proycon/lamachine)"
    echo " ${bold}--install${normal} - Provide an explicit comma separated list of LaMachine roles to install (instead of querying interactively or just taking the default)"
}

USERNAME=$(whoami)

fatalerror () {
    echo "${bold}================ FATAL ERROR ==============${normal}" >&2
    echo "An error occurred during installation!!" >&2
    echo "${boldred}$1${normal}" >&2
    echo "${bold}===========================================${normal}" >&2
    echo "$1" > error
    exit 2
}

if [[ "$USERNAME" == "root" ]]; then
    fatalerror "Do not run the LaMachine bootstrap process as root!"
fi

#The base directory is the directory where the bootstrap is downloaded/executed
#It will be the default directory for data sharing, will host some configuration files
#and will contain a lamachine-controller environment
BASEDIR=$(pwd)
cd $BASEDIR
if [ -d .git ]; then
    #we are in a LaMachine git repository already
    SOURCEDIR=$BASEDIR
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
    fi
fi
if [ "$OS" = "unknown" ]; then
    echo "(Fallback: Detecting OS by finding installed package manager...)">&2
    ARCH=$(which pacman 2> /dev/null)
    DEBIAN=$(which apt 2> /dev/null)
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
INTERACTIVE=1
LOCALITY=""
PRIVATE=0
ANSIBLE_OPTIONS="-v"
MINIMAL=0
PREFER_DISTRO=0
VAGRANTBOX="debian/contrib-stretch64" #base distribution for VM
DOCKERREPO="proycon/lamachine"

echo "Detected OS: $OS"
echo "Detected distribution ID: $DISTRIB_ID"
echo "Detected distribution release: $DISTRIB_RELEASE"
echo


echo "Looking for dependencies..."
if ! which git; then
    NEED+=("git")
fi
if ! which pip; then
    NEED+=("pip")
fi
if ! which virtualenv; then
    NEED+=("virtualenv")
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
    if brew info brew-cask | grep "brew-cask" >/dev/null 2>&1 ; then
        echo "brew-cask found"
    else
        NEED+=("brew-cask")
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
        --prefer-distro)
        PREFER_DISTRO=1
        shift
        ;;
        --extra) #extra ansible parameters
        ANSIBLE_OPTIONS="$ANSIBLE_OPTIONS --extra-vars $2"
        shift
        shift
        ;;
        --quiet)
        ANSIBLE_OPTIONS=""
        shift
        ;;
        --verbose)
        ANSIBLE_OPTIONS="$ANSIBLE_OPTIONS -v"
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
    echo "you want your LaMachine to be installed."
    echo
fi


if [ -z "$FLAVOUR" ]; then
    while true; do
        echo "${bold}Where do you want to install LaMachine?${normal}"
        echo "  1) in a local user environment"
        echo "       installs as much as possible in a separate directory"
        echo "       for a particular user; can exists alongside existing"
        echo "       installations"
        echo "       (uses conda or virtualenv)"
        echo "  2) in a Virtual Machine"
        echo "       complete separation from the host OS"
        echo "       (uses Vagrant and VirtualBox)"
        echo "  3) in a Docker container"
        echo "       (uses Docker and Ansible)"
        echo "  4) Globally on this machine"
        echo "       modifies the existing system and may"
        echo "       interact with existing packages"
        echo "  5) On a remote server"
        echo "       modifies the existing remote system!"
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

if [[ "$FLAVOUR" == "vm" ]]; then
    FLAVOUR="vagrant"
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
fi
if [ -z "$LOCALENV_TYPE" ]; then
    LOCALENV_TYPE="virtualenv"
fi

if [ -z "$VERSION" ]; then
    echo "${bold}LaMachine comes in several versions:${normal}"
    echo " 1) a stable version, you get the latest releases deemed stable (recommended)"
    echo " 2) a development version, you get the very latest development versions for testing, this may not always work as expected!"
    echo " 3) custom version, you decide explicitly what exact versions you want (for reproducibility)."
    echo "    this expects you to provide a LaMachine version file with exact version numbers."
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

if [ -z "$BRANCH" ]; then
    if [[ "$VERSION" == "development" ]]; then
        BRANCH="lamachine2" #TODO: change to develop
    else
        BRANCH="lamachine2" #TODO: change to master
    fi
fi
if [ -z "$GITREPO" ]; then
    GITREPO="https://github.com/proycon/LaMachine"
fi

if [ "$FLAVOUR" == "vagrant" ]; then
    echo "Looking for vagrant..."
    if ! which vagrant; then
        NEED+=("vagrant")
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

if [ -z "$SUDO" ]; then
    if [ $INTERACTIVE -eq 0 ]; then
        SUDO=1 #assume root (use --noadmin option otherwise)
    else
        while true; do
            echo
            echo "The installation relies on certain software to be available on your (host)"
            echo "system. It will be automatically obtained from your distribution's package manager"
            echo "or another official source whenever possible. You need to have sudo permission for this though..."
            echo "Answering 'no' to this question may make installation on your system impossible!"
            echo
            echo -n "${bold}Do you have administrative access (root/sudo) on the current system?${normal} [yn]"
            read yn
            case $yn in
                [Yy]* ) SUDO=1; break;;
                [Nn]* ) SUDO=0; break;;
                * ) echo "Please answer yes or no.";;
            esac
        done
    fi
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
        echo "Vagrant and Virtualbox are required for your flavour of LaMachine but are not installed yet. ${bold}Install automatically?${normal}"
        if [ ! -z "$cmd" ]; then
            while true; do
                echo -n "${bold}Run:${normal} $cmd ? [yn]"
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
            echo -n "${bold}Download and install homebrew?${normal} [yn]"
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
    elif [ "$package" = "git" ]; then
        if [ "$OS" = "debian" ]; then
            cmd="sudo apt install git-core"
        elif [ "$OS" = "redhat" ]; then
            cmd="sudo yum install git"
        elif [ "$OS" = "arch" ]; then
            cmd="sudo pacman -Sy git"
        elif [ "$OS" = "mac" ]; then
            cmd="brew install git"
        else
            cmd=""
        fi
        echo "Git is required for LaMachine but not installed yet. ${bold}Install now?${normal}"
        if [ ! -z "$cmd" ]; then
            while true; do
                echo -n "${bold}Run:${normal} $cmd ? [yn]"
                read yn
                case $yn in
                    [Yy]* ) $cmd || fatalerror "Git installation failed!"; break;;
                    [Nn]* ) echo "Please install git manually" && echo " .. press ENTER when done or CTRL-C to abort..." && read; break;;
                    * ) echo "Please answer yes or no.";;
                esac
            done
        else
            echo "No automated installation possible on your OS."
            echo "Please install git manually" && echo " .. press ENTER when done or CTRL-C to abort..." && read
        fi
    elif [ "$package" = "pip" ]; then
        if [ "$OS" = "debian" ]; then
            cmd="sudo apt install python-pip"
        elif [ "$OS" = "redhat" ]; then
            cmd="sudo yum install python-pip"
        elif [ "$OS" = "arch" ]; then
            cmd="sudo pacman -Sy python-pip"
        elif [ "$OS" = "mac" ]; then
            cmd="sudo easy_install pip"
        fi
        echo "Pip is required for LaMachine but not installed yet. ${bold}Install now?${normal}"
        if [ ! -z "$cmd" ]; then
            while true; do
                echo -n "${bold}Run:${normal} $cmd ? [yn]"
                read yn
                case $yn in
                    [Yy]* ) $cmd || fatalerror "Pip installation failed"; break;;
                    [Nn]* ) echo "Please install pip manually" && echo " .. press ENTER when done or CTRL-C to abort..." && read; break;;
                    * ) echo "Please answer yes or no.";;
                esac
            done
        else
            echo "No automated installation possible on your OS."
            echo "Please install pip manually" && echo " .. press ENTER when done or CTRL-C to abort..." && read
        fi
    elif [ "$package" = "virtualenv" ]; then
        if [ "$OS" = "debian" ]; then
            cmd="sudo apt install python-virtualenv"
        elif [ "$OS" = "redhat" ]; then
            cmd="sudo yum install python-virtualenv"
        elif [ "$OS" = "arch" ]; then
            cmd="sudo pacman -Sy python-virtualenv"
        elif [ "$OS" = "mac" ]; then
            cmd="sudo pip install virtualenv"
        else
            cmd=""
        fi
        echo "Virtualenv is required for LaMachine but not installed yet. ${bold}Install now?${normal}"
        if [ ! -z "$cmd" ]; then
            while true; do
                echo -n "${bold}Run:${normal} $cmd ? [yn]"
                read yn
                case $yn in
                    [Yy]* ) $cmd || fatalerror "Virtualenv installation failed"; break;;
                    [Nn]* ) echo "Please install virtualenv manually" && echo " .. press ENTER when done or CTRL-C to abort..." && read; break;;
                    * ) echo "Please answer yes or no.";;
                esac
            done
        else
            echo "No automated installation possible on your OS."
            echo "Please install virtualenv manually" && echo " .. press ENTER when done or CTRL-C to abort..." && read
        fi
    fi
done

if [ -z "$LM_NAME" ]; then
    echo "Your LaMachine installation is identified by a name (used as hostname, local env name, VM name) etc.."
    echo -n "${bold}Enter a name for your LaMachine installation (no spaces!):${normal} "
    read LM_NAME
    LM_NAME="${LM_NAME%\\n}"
fi

LM_NAME=${LM_NAME/ /} #strip any spaces because users won't listen anyway

CONFIGFILE="$BASEDIR/lamachine-$LM_NAME.yml"
INSTALLFILE="$BASEDIR/install-$LM_NAME.yml"


if [ ! -e "$CONFIGFILE" ]; then
    echo "---
conf_name: \"$LM_NAME\" #Name of this LaMachine configuration
flavour: \"$FLAVOUR\" #LaMachine flavour
hostname: \"lamachine-$LM_NAME\" #Name of the host (for VM or docker), changing this is not supported yet at this stage
version: \"$VERSION\" #stable, development or custom
localenv_type: \"$LOCALENV_TYPE\" #Local environment type (conda or virtualenv), only used when locality == local
locality: \"$LOCALITY\" #local or global?
" > $CONFIGFILE
    if [[ $FLAVOUR == "vagrant" ]]; then
        echo "unix_user: \"vagrant\" #(don't change this)" >> $CONFIGFILE
        echo "homedir: \"/home/vagrant\"" >> $CONFIGFILE
        echo "source_path: \"/home/vagrant/src/\" #Path where sources will be stored/compiled" >> $CONFIGFILE
        echo "lamachine_path: \"/vagrant\" #Path where LaMachine source is stored/shared" >> $CONFIGFILE
        echo "host_data_path: \"$BASEDIR\" #Data path on the host machine that will be shared with LaMachine" >> $CONFIGFILE
        echo "data_path: \"/data\" #Data path (in LaMachine) that is tied to host_data_path" >> $CONFIGFILE
        echo "global_prefix: \"/usr/local/\" #Path for global installations" >> $CONFIGFILE
    elif [[ $FLAVOUR == "docker" ]]; then
        echo "unix_user: \"lamachine\"" >> $CONFIGFILE
        echo "homedir: \"/home/lamachine\"" >> $CONFIGFILE
        echo "lamachine_path: \"/lamachine\" #Path where LaMachine source is stored/shared" >> $CONFIGFILE
        echo "host_data_path: \"$BASEDIR\" #Data path on the host machine that will be shared with LaMachine" >> $CONFIGFILE
        echo "data_path: \"/data\" #Data path (in LaMachine) that is tied to host_data_path" >> $CONFIGFILE
        echo "source_path: \"/lamachine/src/\" #Path where sources will be stored/compiled" >> $CONFIGFILE
        echo "global_prefix: \"/usr/local/\" #Path for global installations" >> $CONFIGFILE
    else
        echo "unix_user: \"$USERNAME\"" >> $CONFIGFILE
        HOMEDIR=$(echo ~)
        echo "homedir: \"$HOMEDIR\"" >> $CONFIGFILE
        if [ ! -z "$SOURCEDIR" ]; then
            echo "lamachine_path: \"$SOURCEDIR\" #Path where LaMachine source is stored/shared (don't change this)" >> $CONFIGFILE
            echo "source_path: \"$SOURCEDIR/src\" #Path where sources will be stored/compiled" >> $CONFIGFILE
        else
            echo "lamachine_path: \"$BASEDIR/lamachine-controller/$LM_NAME/LaMachine\" #Path where LaMachine source is stored/shared (don't change this)" >> $CONFIGFILE
            echo "source_path: \"$BASEDIR/lamachine-controller/$LM_NAME/LaMachine/src\" #Path where sources will be stored/compiled" >> $CONFIGFILE
        fi
        echo "data_path: \"$BASEDIR\" #Data path (in LaMachine) that is tied to host_data_path" >> $CONFIGFILE
        echo "local_prefix: \"$HOMEDIR/lamachine-$LM_NAME\" #Path to the local environment (conda/virtualenv)" >> $CONFIGFILE
        echo "global_prefix: \"/usr/local/\" #Path for global installations" >> $CONFIGFILE
    fi
    if [[ $FLAVOUR == "vagrant" ]] || [[ $FLAVOUR == "docker" ]]; then
        echo "root: true #Do you have root on the target system?" >> $CONFIGFILE
    elif [ $SUDO -eq 1 ]; then
        echo "root: true #Do you have root on the target system?" >> $CONFIGFILE
    elif [ $SUDO -eq 0 ]; then
        echo "root: false #Do you have root on the target system?" >> $CONFIGFILE
    fi
    if [[ $FLAVOUR == "vagrant" ]]; then
        echo "vagrant_box: \"$VAGRANTBOX\" #Base box for vagrant (changing this may break things if packages are not compatible!)" >>$CONFIGFILE
        echo "vm_memory: 6096 #Memory allocated to the VM; in MB (the more the better! but too high and the VM won't start)">> $CONFIGFILE
        echo "vm_cpus: 2 #CPU cores allocated to the VM">>$CONFIGFILE
    fi
    if [ $PRIVATE -eq 1 ]; then
        echo "private: true #opt-out of sending back anonymous analytics regarding your LaMachine build " >> $CONFIGFILE
    else
        echo "private: false #when false, allows sending back anonymous analytics regarding your LaMachine build (recommended)" >> $CONFIGFILE
    fi
    if [ $MINIMAL -eq 1 ]; then
        echo "minimal: true #install less than normal for certain categories (this might break things)" >> $CONFIGFILE
    else
        echo "minimal: false #install less than normal for certain categories (this might break things)" >> $CONFIGFILE
    fi
    if [ $PREFER_DISTRO -eq 1 ]; then
        echo "prefer_distro: true #prefer using the distribution's packages as much as possible rather than distribution channels such as pip (this will install more conservative versions but may break certain things)" >> $CONFIGFILE
    else
        echo "prefer_distro: false #prefer using the distribution's packages as much as possible rather than distribution channels such as pip (this will install more conservative versions but may break certain things)" >> $CONFIGFILE
    fi
echo "
webserver: true #include a webserver
http_port: 80 #webserver port (for VM or docker)
mapped_http_port: 8080 #mapped webserver port on host system (for VM or docker)
" >> $CONFIGFILE

if [ $INTERACTIVE -eq 1 ]; then
    echo "${bold}Opening configuration file $CONFIGFILE in editor for final configuration...${normal}"
    sleep 3
    if ! "$EDITOR" "$CONFIGFILE"; then
        echo "aborted by editor..." >&2
        exit 2
    fi
fi

fi


if [ ! -d lamachine-controller ]; then
    mkdir lamachine-controller || fatalerror "Unable to create directory for LaMachine control environment"
fi

if [ ! -d lamachine-controller/$LM_NAME ]; then
    echo "Setting up control environment..."
    if [[ "$FLAVOUR" != "docker" ]]; then
        virtualenv --python=python2.7 lamachine-controller/$LM_NAME || fatalerror "Unable to create LaMachine control environment"
        cd lamachine-controller/$LM_NAME
        source ./bin/activate || fatalerror "Unable to activate LaMachine controller environment"
        pip install ansible || fatalerror "Unable to install Ansible"
        #pip install docker==2.7.0 docker-compose ansible-container[docker]
    else
        mkdir lamachine-controller/$LM_NAME && cd lamachine-controller/$LM_NAME #no need for a virtualenv
    fi
else
    echo "Reusing existing control environment..."
    cd lamachine-controller/$LM_NAME
    if [[ "$FLAVOUR" != "docker" ]]; then
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
if [ ! -e $SOURCEDIR/host_vars/$(basename $CONFIGFILE) ]; then
    mv $CONFIGFILE $SOURCEDIR/host_vars/$(basename $CONFIGFILE) || fatalerror "Unable to copy $CONFIGFILE"
    if [ "$SOURCEDIR" != "$BASEDIR" ]; then
        ln -sf $SOURCEDIR/host_vars/$(basename $CONFIGFILE) $CONFIGFILE || fatalerror "Unable to link $CONFIGFILE"
    fi
fi
if [ ! -e $INSTALLFILE ]; then
    if [ ! -z "$INSTALL" ]; then
        #use the explicitly provided list
        echo "- hosts: all" > $SOURCEDIR/install-$LM_NAME.yml
        echo "  roles: [ lamachine-core, $INSTALL ]" >> $SOURCEDIR/install-$LM_NAME.yml
    else
        #use the template
        cp $SOURCEDIR/install.yml $SOURCEDIR/install-$LM_NAME.yml || fatalerror "Unable to copy $SOURCEDIR/install.yml"
    fi
    if [ "$SOURCEDIR" != "$BASEDIR" ]; then
        ln -sf $SOURCEDIR/install-$LM_NAME.yml $INSTALLFILE || fatalerror "Unable to link $CONFIGFILE"
    fi
fi

if [ $INTERACTIVE -eq 1 ] && [ -z "$INSTALL" ]; then
    echo "${bold}Opening installation file $INSTALLFILE in editor for selection of packages to install...${normal}"
    sleep 3
    if ! "$EDITOR" "$INSTALLFILE"; then
        exit 2
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
    if [ ! -f $SOURCEDIR/Vagrantfile.$LM_NAME ]; then
        cp -f $SOURCEDIR/Vagrantfile $SOURCEDIR/Vagrantfile.$LM_NAME || fatalerror "Unable to copy Vagrantfile"
        sed -i s/lamachine-vm/lamachine-$LM_NAME/g $SOURCEDIR/Vagrantfile.$LM_NAME || fatalerror "Unable to run sed"
        sed -i s/install.yml/install-$LM_NAME.yml/g $SOURCEDIR/Vagrantfile.$LM_NAME || fatalerror "Unable to run sed"
    fi
    #add activation script on the host machine:
    echo -e "#!/bin/bash\nexport VAGRANT_CWD=$SOURCEDIR VAGRANT_VAGRANTFILE=Vagrantfile.$LM_NAME\nif vagrant up && vagrant ssh; then\nvagrant halt\nexit 0\nelse\nexit 1\nfi" > $BASEDIR/lamachine-$LM_NAME-activate
    echo -e "#!/bin/bash\nexport VAGRANT_CWD=$SOURCEDIR VAGRANT_VAGRANTFILE=Vagrantfile.$LM_NAME\nvagrant halt \$@; exit \$?" > $BASEDIR/lamachine-$LM_NAME-stop
    echo -e "#!/bin/bash\nexport VAGRANT_CWD=$SOURCEDIR VAGRANT_VAGRANTFILE=Vagrantfile.$LM_NAME\nvagrant up; exit \$?" > $BASEDIR/lamachine-$LM_NAME-start
    echo -e "#!/bin/bash\nexport VAGRANT_CWD=$SOURCEDIR VAGRANT_VAGRANTFILE=Vagrantfile.$LM_NAME\nvagrant ssh; exit \$?" > $BASEDIR/lamachine-$LM_NAME-connect
    echo -e "#!/bin/bash\nexport VAGRANT_CWD=$SOURCEDIR VAGRANT_VAGRANTFILE=Vagrantfile.$LM_NAME\nvagrant ssh -c 'lamachine-update'; exit \$?" > $BASEDIR/lamachine-$LM_NAME-update
    echo -e "#!/bin/bash\nexport VAGRANT_CWD=$SOURCEDIR VAGRANT_VAGRANTFILE=Vagrantfile.$LM_NAME\nvagrant destroy \$@; exit \$?" > $BASEDIR/lamachine-$LM_NAME-destroy
    chmod a+x $BASEDIR/lamachine-$LM_NAME-*
    ln -sf $BASEDIR/lamachine-$LM_NAME-activate $HOMEDIR/bin/
    ln -sf $BASEDIR/lamachine-$LM_NAME-start $HOMEDIR/bin/
    ln -sf $BASEDIR/lamachine-$LM_NAME-stop $HOMEDIR/bin/
    ln -sf $BASEDIR/lamachine-$LM_NAME-connect $HOMEDIR/bin/
    ln -sf $BASEDIR/lamachine-$LM_NAME-update $HOMEDIR/bin/
    ln -sf $BASEDIR/lamachine-$LM_NAME-destroy $HOMEDIR/bin/
    ln -sf $BASEDIR/lamachine-$LM_NAME-activate $HOMEDIR/bin/lamachine-activate #shortcut
    #run the activation script (this will do the actual initial provision as well)
    bash $BASEDIR/lamachine-$LM_NAME-activate
    rc=$?
    echo "======================================================================================"
    if [ $rc -eq 0 ]; then
        echo "${boldgreen}All done, the LaMachine VM has been built succesfully${normal}."
        echo "- ${bold}to start and enter your VM, run: lamachine-$LM_NAME-activate${normal}   (or: bash ~/bin/lamachine-$LM_NAME-activate)"
        echo "  note that the VM will be stopped as soon as you disconnect again."
        echo "- to power up the VM, run: lamachine-$LM_NAME-start"
        echo "- to power down the VM, run: lamachine-$LM_NAME-stop"
        echo "- to connect to a started VM, run: lamachine-$LM_NAME-connect"
        echo "- to delete the entire VM again, run: lamachine-$LM_NAME-destroy"
    else
        echo "${boldred}The LaMachine VM bootstrap has failed unfortunately.${normal} You have several options:"
        echo " - Start from scratch again with a new bootstrap, possibly tweaking configuration options"
        echo " - Enter the LaMachine VM in its uncompleted state, run: bash ~/bin/lamachine-$LM_NAME-activate"
        echo " - Force the LaMachine VM to update itself, run: bash ~/bin/lamachine-$LM_NAME-update"
        echo " - File a bug report on https://github.com/proycon/LaMachine/issues/"
    fi
elif [[ "$FLAVOUR" == "local" ]] || [[ "$FLAVOUR" == "global" ]]; then
    if [ "$SUDO" -eq 1 ] && [ $INTERACTIVE -eq 1 ]; then
        ASKSUDO="--ask-become-pass"
    else
        ASKSUDO=""
    fi
    cmd="ansible-playbook $ASKSUDO -i $SOURCEDIR/hosts.$LM_NAME install-$LM_NAME.yml $ANSIBLE_OPTIONS"
    cwd=$(pwd)
    echo "Running ansible command from $cwd: $cmd" >&2
    echo "lamachine-$LM_NAME ansible_connection=local" > $SOURCEDIR/hosts.$LM_NAME
    if $cmd; then
        rc=0
        echo "======================================================================================"
        echo "${boldgreen}All done, a local LaMachine environment has been built!${normal}"
        echo "- ${bold}to activate your environment, run: lamachine-$LM_NAME-activate${normal}   (or: bash ~/bin/lamachine-$LM_NAME-activate)"
    else
        echo "======================================================================================"
        echo "${boldred}Building a local LaMachine environment has failed unfortunately.${normal} You have several options:"
        echo " - Start from scratch again with a new bootstrap, possibly tweaking configuration options"
        echo "-  Attempt to activate the environment (run: lamachine-$LM_NAME-activate) and debug the problem"
        echo "-  Run lamachine-$LM_NAME-update after activating the environment to see if the problem corrects itself"
        echo " - File a bug report on https://github.com/proycon/LaMachine/issues/"
        rc=1
    fi
elif [[ "$FLAVOUR" == "docker" ]]; then
    echo "Building docker"
    sed -i "s/hosts: all/hosts: localhost/g" $SOURCEDIR/install-$LM_NAME.yml || fatalerror "Unable to run sed"
    #echo "lamachine-$LM_NAME ansible_connection=local" > $SOURCEDIR/hosts.$LM_NAME
    docker build -t $DOCKERREPO:$LM_NAME --build-arg LM_NAME=$LM_NAME .
    rc=$?
    if [ $rc -eq 0 ]; then
        echo "======================================================================================"
        echo "${boldgreen}All done, a docker image has been built!${normal}"
        echo "- to create and run a *new* interactive container using this image, run: docker run -p 8080:80 -t -i $DOCKERREPO:$LM_NAME"
    else
        echo "======================================================================================"
        echo "${boldred}The docker build has failed unfortunately.${normal} You have several options:"
        echo " - Start from scratch again with a new bootstrap, possibly tweaking configuration options"
        echo " - File a bug report on https://github.com/proycon/LaMachine/issues/"
    fi
else
    echo "No bootstrap for $FLAVOUR implemented yet at this stage, sorry!!">&2
    rc=1
fi
if [[ "$FLAVOUR" != "docker" ]]; then
    deactivate #deactivate the controller before quitting
fi
exit $rc
