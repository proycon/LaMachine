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

echo "====================================================================="
echo "           ,              LaMachine v2 - NLP Software distribution"
echo "          ~)                     (http://proycon.github.io/LaMachine)"
echo "           (----í         Language Machines research group"
echo "            /| |\         Centre of Language and Speech Technology"
echo "           / / /|	        Radboud University Nijmegen "
echo "====================================================================="
echo

fatalerror () {
    echo "================ FATAL ERROR ==============" >&2
    echo "An error occurred during installation!!" >&2
    echo "$1" >&2
    echo "===========================================" >&2
    echo "$1" > error
    exit 2
}

BASEDIR=$(pwd)


####################################################
#               Platform Detection
####################################################
NEED=() #list of needed packages
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


echo "Looking for dependencies..."
if ! which git; then
    NEED+=("git")
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
        shift # past argument
        shift # past value
        ;;
        *)    # unknown option
        echo "Unknown option: $1">&2
        exit 2
        ;;
    esac
done

echo
echo "Welcome to the LaMachine Installation tool, we will ask some questions how"
echo "you want your LaMachine to be installed."
echo


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
            [1]* ) FLAVOUR="vagrant"; break;;
            [2]* ) FLAVOUR="docker"; break;;
            [3]* ) FLAVOUR="local"; break;;
            [4]* ) FLAVOUR="global"; break;;
            [5]* ) FLAVOUR="server"; break;;
            * ) echo "Please answer with the corresponding number of your preference..";;
        esac
    done
fi

echo

PREFER_GLOBAL=0
if [[ "$FLAVOUR" == "local" ]] || [[ "$FLAVOUR" == "global" ]]; then
    if [ -z "$LOCALENV_TYPE" ]; then
        echo "We support two forms of local user environments:"
        echo "  1) Using conda"
        echo "       provided by the Anaconda Distribution, a powerful data science platform (mostly for Python and R)"
        echo "  2) Using virtualenv"
        echo "       A simpler solution (originally for Python but extended by us)"
        if [ "$FLAVOUR" != "local" ]; then
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
if [ -z "$LOCALENV_TYPE" ]; then
    LOCALENV_TYPE="conda"
fi

if [ -z "$VERSION" ]; then
    echo "LaMachine comes in several versions:"
    echo " 1) a stable version, you get the latest releases deemed stable (recommended)"
    echo " 2) a development version, you get the very latest development versions for testing, this may not always work as expected!"
    echo " 3) custom version, you decide explicitly what exact versions you want (for reproducibility)."
    echo "    this expects you to provide a LaMachine version file with exact version numbers."
    while true; do
        echo -n "Which version do you want to install? "
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
        [Nn]* ) SUDO=0; break;;
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
        echo "Git is required for LaMachine but not installed yet. Install now?"
        if [ ! -z "$cmd" ]; then
            while true; do
                echo -n "Run: $cmd ? [yn]"
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
    elif [ "$package" = "virtualenv" ]; then
        if [ "$OS" = "debian" ]; then
            cmd="sudo apt install python-virtualenv"
        elif [ "$OS" = "redhat" ]; then
            cmd="sudo yum install python-virtualenv"
        elif [ "$OS" = "arch" ]; then
            cmd="sudo pacman -Sy python-virtualenv"
        elif [ "$OS" = "mac" ]; then
            cmd="sudo easy_install pip && sudo pip install virtualenv"
        else
            cmd=""
        fi
        echo "Virtualenv is required for LaMachine but not installed yet. Install now?"
        if [ ! -z "$cmd" ]; then
            while true; do
                echo -n "Run: $cmd ? [yn]"
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
    echo -n "Enter a name for your LaMachine installation (no spaces!): "
    read LM_NAME
    LM_NAME="${LM_NAME%\\n}"
fi

LM_NAME=${LM_NAME/ /} #strip any spaces because users won't listen anyway

CONFIGFILE="$BASEDIR/lamachine-$LM_NAME.yml"
INSTALLFILE="$BASEDIR/install-$LM_NAME.yml"

if [ ! -f "$CONFIGFILE" ]; then
    echo "---
conf_name: \"$LM_NAME\" #Name of this LaMachine configuration
hostname: \"lamachine-$LM_NAME\" #Name of the host (for VM or docker), does not change existing hostnames
version: \"$VERSION\" #stable, development or custom
localenv_type: \"$LOCALENV_TYPE\" #Local environment type (conda or virtualenv), not used when prefer_global is true
" > $CONFIGFILE
    if [ $PREFER_GLOBAL -eq 1 ]; then
        echo "prefer_global: true #Install everything globally" >> $CONFIGFILE
    else
        echo "prefer_global: false #Install everything globally" >> $CONFIGFILE
    fi
    if [[ $FLAVOUR == "vagrant" ]]; then
        echo "unix_user: \"vagrant\"" >> $CONFIGFILE
        echo "source_path: \"/home/vagrant/src/\" #Path where sources will be stored/compiled" >> $CONFIGFILE
        echo "lamachine_path: \"/vagrant\" #Path where LaMachine source is stored/shared" >> $CONFIGFILE
        echo "host_data_path: \"$BASEDIR\" #Data path on the host machine that will be shared with LaMachine" >> $CONFIGFILE
        echo "data_path: \"/data\" #Data path (in LaMachine) that is tied to host_data_path" >> $CONFIGFILE
    elif [[ $FLAVOUR == "docker" ]]; then
        echo "unix_user: \"lamachine\"" >> $CONFIGFILE
        #TODO lamachine_path + source_path
    else
        echo "lamachine_path: \"$SOURCEDIR\" #Path where LaMachine source is stored/shared" >> $CONFIGFILE
        echo "source_path: \"$SOURCEDIR/src/\" #Path where sources will be stored/compiled" >> $CONFIGFILE
        echo "data_path: \"$BASEDIR\" #Data path (in LaMachine) that is tied to host_data_path" >> $CONFIGFILE
    fi
    if [[ $FLAVOUR == "vagrant" ]] || [[ $FLAVOUR == "docker" ]]; then
        echo "prefer_local: false #Install everything in a local user environment" >> $CONFIGFILE
        echo "root: true #Do you have root on the target system?" >> $CONFIGFILE
        echo "shared: false #Is the target machine a shared machine with non-LaMachine applications?" >> $CONFIGFILE
    elif [ $SUDO -eq 0 ]; then
        echo "prefer_local: true #Install everything in a local user environment" >> $CONFIGFILE
        echo "root: false #Do you have root on the target system?" >> $CONFIGFILE
        echo "shared: true #Is the target machine a shared machine with non-LaMachine applications?" >> $CONFIGFILE
    else
        echo "prefer_local: false #Install everything in a local user environment" >> $CONFIGFILE
        echo "root: true #Do you have root on the target system?" >> $CONFIGFILE
        if [ $SHARED -eq 0 ]; then
            echo "shared: false #Is the target machine a shared machine with non-LaMachine applications?" >> $CONFIGFILE
        else
            echo "shared: true #Is the target machine a shared machine with non-LaMachine applications?" >> $CONFIGFILE
        fi
    fi
    if [[ $FLAVOUR == "vagrant" ]]; then
        echo "vagrant_box: \"debian/contrib-stretch64\" #Base box for vagrant (changing this may break things if packages are not compatible!)" >>$CONFIGFILE
        echo "vm_memory: 6096 #Reserved memory for VM">> $CONFIGFILE
        echo "vm_cpus: 2 #Reserved number of CPU cores for VM">>$CONFIGFILE
    fi
echo "
webserver: true #include a webserver
port: 80 #webserver port (for VM or docker)
mapped_port: 8080 #mapped webserver port on host system (for VM or docker)
" >> $CONFIGFILE

echo "Opening configuration file $CONFIGFILE in editor for final configuration..."
sleep 3
if ! "$EDITOR" "$CONFIGFILE"; then
    echo "aborted by editor..." >&2
    exit 2
fi
fi


cd $BASEDIR
if [ -d .git ]; then
    #we are in a LaMachine git repository already
    SOURCEDIR=$BASEDIR
fi

if [ ! -d lamachine-controller ]; then
    echo "Setting up control environment..."
    virtualenv --python=python2.7 lamachine-controller || "Unable to create LaMachine control environment"
    cd lamachine-controller
    source ./bin/activate || fatalerror "Unable to activate LaMachine controller environment"
    pip install ansible || fatalerror "Unable to install Ansible"
else
    echo "Reusing existing control environment..."
    cd lamachine-controller
    source ./bin/activate || fatalerror "Unable to activate LaMachine controller environment"
fi

if [ -z "$SOURCEDIR" ]; then
    echo "Cloning LaMachine git repo ($GITREPO $BRANCH)..."
    git clone $GITREPO -b $BRANCH LaMachine || fatalerror "Unable to clone LaMachine git repository"
    SOURCEDIR=$BASEDIR/lamachine-controller/LaMachine
    cd $SOURCEDIR
else
    echo "Updating LaMachine git..."
    cd $SOURCEDIR
    if [ "$SOURCEDIR" != "$BASEDIR" ]; then
        git checkout $BRANCH #only switch branches if we're not already in a git repo the user cloned himself
    fi
    git pull #make sure we're up to date
fi
if [ ! -f $SOURCEDIR/host_vars/$(basename $CONFIGFILE) ]; then
    ln -s $CONFIGFILE $SOURCEDIR/host_vars/$(basename $CONFIGFILE) || fatalerror "Unable to link $CONFIGFILE"
fi
if [ ! -f $INSTALLFILE ]; then
    cp $SOURCEDIR/install.yml $INSTALLFILE || fatalerror "Unable to copy $SOURCE/install.yml"
fi
echo "Opening installation file $INSTALLFILE in editor for selection of packages to install..."
sleep 3
if ! "$EDITOR" "$INSTALLFILE"; then
    exit 2
fi
ln -s $INSTALLFILE $SOURCEDIR/$(basename $INSTALLFILE)

if [[ "$FLAVOUR" == "vagrant" ]]; then
    echo "Preparing vagrant..."
    if [ ! -f $SOURCEDIR/Vagrantfile.$LM_NAME ]; then
        cp $SOURCEDIR/Vagrantfile $SOURCEDIR/Vagrantfile.$LM_NAME || fatalerror "Unable to copy Vagrantfile"
        sed -i s/lamachine-vm/lamachine-$LM_NAME/g $SOURCEDIR/Vagrantfile.$LM_NAME
        sed -i s/install.yml/install-$LM_NAME.yml/g $SOURCEDIR/Vagrantfile.$LM_NAME
    fi
    echo "Running vagrant..."
    VAGRANT_CWD=$SOURCEDIR  VAGRANT_VAGRANTFILE=Vagrantfile.$LM_NAME vagrant up
    echo -e "#!/bin/bash\nexport VAGRANT_CWD=$SOURCEDIR VAGRANT_VAGRANTFILE=Vagrantfile.$LM_NAME\nvagrant up && vagrant ssh\nvagrant halt" > $BASEDIR/lamachine-$LM_NAME.activate
    chmod a+x $BASEDIR/lamachine-$LM_NAME.activate
elif [[ "$FLAVOUR" == "local" ]]; then
    echo "TODO"
fi
echo "All done!"
