#!/usr/bin/env bash
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
echo "            /| |\         & Centre for Language and Speech Technology"
echo "           / / /|	        Radboud University Nijmegen "
echo "====================================================================="
echo
echo "Bootstrapping VirtualEnv...."
echo
sleep 1

fatalerror () {
    echo "================ FATAL ERROR ==============" >&2
    echo "An error occured during installation!!" >&2
    echo "$1" >&2
    echo "===========================================" >&2
    echo "$1" > error
    exit 2
}

error () {
    echo "================= ERROR ===================" >&2
    echo "$1" >&2
    echo "===========================================" >&2
    echo "$1" > error
    sleep 3
}

gitstash () {
        echo "WARNING: Unable to switch branches, there must be uncommited changes. Do you want to stash them away and continue? (y/n)"
        read -r yn
        if [[ "$yn" == "y" ]]; then
            git stash
        else 
            exit 8
        fi
}


gitcheckmaster() {
    git checkout master
    if [ $? -ne 0 ]; then
        gitstash 
        git checkout master
    fi
    git remote update
    LOCAL=$(git rev-parse @)
    REMOTE=$(git rev-parse @{u})
    BASE=$(git merge-base @ @{u})

    if [ "$LOCAL" = "$REMOTE" ]; then
        echo "Git: up-to-date"
        REPOCHANGED=0
    elif [ "$LOCAL" = "$BASE" ]; then
        echo "Git: Pulling..."
        git pull || fatalerror "Unable to git pull $project"
        REPOCHANGED=1
    elif [ "$REMOTE" = "$BASE" ]; then
        echo "Git: Need to push"
        REPOCHANGED=1
    else
        echo "Git: Diverged"
        REPOCHANGED=1
    fi

    if [ -f error ]; then
        echo "Encountered an error last time, need to recompile"
        rm error
        REPOCHANGED=1
    fi
}

gitcheck () {
    git remote update
    if [ $DEV -eq 0 ]; then
        #use github releases, upgrade to latest one
        if [ -f .version.lamachine ]; then
            CURRENTVERSION=$(cat .version.lamachine)
        fi
        LATESTVERSION=$(git tag | grep -e "^v" | sort -t. -k 1.2,1n -k 2,2n -k 3,3n -k 4,4n | tail -n 1)
        if [ ! -z $LATESTVERSION ]; then
            if [[ "$LATESTVERSION" == "$CURRENTVERSION" ]]; then
                echo "   Already up to date on latest stable release: $LATESTVERSION"
                REPOCHANGED=0
            else
                LATESTVERSION=$(echo $LATESTVERSION|tr -d '\n')
                echo "   Upgrading from $CURRENTVERSION to latest stable release $LATESTVERSION ..."
                git checkout "tags/$LATESTVERSION" #will put us in detached head state
                if [ $? -ne 0 ]; then
                    gitstash 
                    git checkout "tags/$LATESTVERSION"
                fi
                echo "$LATESTVERSION" > .version.lamachine 
                REPOCHANGED=1
            fi
        else
            #no tags/releases, use master
            gitcheckmaster
        fi
    else
        #use master branch
        gitcheckmaster
    fi
}

gitcheckout () {
    if [ $DEV -eq 0 ]; then
        LATESTVERSION=`git tag --sort="v:refname" | tail -n 1`
        if [ ! -z "$LATESTVERSION" ]; then
            LATESTVERSION=$(echo $LATESTVERSION|tr -d '\n')
            echo "   Using latest stable release: $LATESTVERSION"
            git checkout "tags/$LATESTVERSION" #will put us in detached head state
            if [ $? -ne 0 ]; then
                gitstash 
                git checkout "tags/$LATESTVERSION"
            fi
            echo "$LATESTVERSION" > .version.lamachine 
        fi
    else
        echo "       Using newest development version"
        git checkout master
        if [ $? -ne 0 ]; then
            gitstash 
            git checkout master
        fi
        rm .version.lamachine 2> /dev/null
    fi
}


NOADMIN=0
FORCE=0
NOPYTHONDEPS=0
DEV=0
PRIVATE=0
if [ ! -z "$VIRTUAL_ENV" ]; then
    #already in a virtual env
    if [ -f "$VIRTUAL_ENV/src/LaMachine/.dev" ]; then
        DEV=1 #install development versions
    fi
    if [ -f "$VIRTUAL_ENV/src/LaMachine/.private" ]; then
        PRIVATE=1 #no not send simple analytics to Nijmegen
    fi
fi
PYTHON="python3"
for OPT in "$@"
do
    if [[ "$OPT" == "noadmin" ]]; then
        NOADMIN=1
    fi
    if [[ "$OPT" == "nopythondeps" ]]; then
        NOPYTHONDEPS=1
    fi
    if [[ "$OPT" == "force" ]]; then
        FORCE=1
    fi
    if [[ "$OPT" == "python2" ]]; then
        PYTHON="python2.7"
    fi
    if [[ "$OPT" == "dev" ]]; then
        DEV=1
    fi
    if [[ "$OPT" == "stable" ]]; then
        DEV=0
    fi
    if [[ "$OPT" == "private" ]]; then
        PRIVATE=1
    fi
    if [[ "$OPT" == "sendinfo" ]]; then
        PRIVATE=0
    fi
done

if [ $DEV -eq 0 ]; then
    echo "================================================================================">&2
    echo "      LaMachine will install the latest stable releases where possible">&2
    echo "================================================================================">&2
else
    echo "================================================================================">&2
    echo "      LaMachine will install the very latest development versions">&2
    echo "================================================================================">&2
fi


CONDA=0
#if [ ! -z "$CONDA_DEFAULT_ENV" ]; then
#    echo "Running in Anaconda environment... THIS IS UNTESTED!" >&2
#    if [ ! -d conda-meta ]; then
#        echo "Make sure your current working directory is in the root of the anaconda environment ($CONDA_DEFAULT_ENV)" >&2
#        exit 2
#    fi
#    CONDA=1

####################################################
#               Platform Detection
####################################################
echo "Detecting package manager..."
ARCH=$(which pacman 2> /dev/null)
DEBIAN=$(which apt-get 2> /dev/null)
MAC=$(which brew 2> /dev/null)
REDHAT=$(which yum 2> /dev/null)
FREEBSD=$(which pkg 2> /dev/null)
if [ -f "$ARCH" ]; then
    OS='arch'
elif [ -f "$DEBIAN" ]; then
    OS='debian' #ubuntu too
elif [ -f "$MAC" ]; then
    OS='mac'
elif [ -f "$REDHAT" ]; then
    OS='redhat'
elif [ -f "$FREEBSD" ]; then
    OS='freebsd'
else
    OS="unknown"
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


#################################################################
#           Global package installation (distribition-specific)
#################################################################
if [ "$NOADMIN" == "0" ]; then
    INSTALL=""
    if [ "$OS" == "arch" ]; then
        INSTALL="sudo pacman -Syu --needed --noconfirm base-devel pkg-config git autoconf-archive gcc-fortran icu xml2 libxslt zlib libtar boost boost-libs python python-pip python-virtualenv wget gnutls curl libexttextcat aspell hunspell blas lapack suitesparse"
        if [ "$PYTHON" == "python2" ]; then
            INSTALL="$INSTALL python2 python2-pip python2-virtualenv"
        fi
    elif [ "$OS" == "debian" ]; then
        PIPPACKAGE="python3-pip"
        if [ "$DISTRIB_ID" == "Ubuntu" ]; then
            if [ "$DISTRIB_RELEASE" == "12.04" ]; then
                echo "===========================================================================================================================================================">&2
                echo "WARNING: Ubuntu 12.04 detected, make sure you manually upgrade Python 3 to at least Python 3.3 first or things may fail later in the installation process!">&2
                echo "============================================================================================================================================================">&2
                sleep 3
                PIPPACKAGE="python-pip"
            elif [ "$DISTRIB_RELEASE" == "10.04" ] || [ "$DISTRIB_RELEASE" == "10.10" ] || [ "$DISTRIB_RELEASE" == "9.10" ] || [ "$DISTRIB_RELEASE" == "9.04" ] || [ "$DISTRIB_RELEASE" == "8.04" ]; then
                fatalerror "Your Ubuntu version ($DISTRIB_RELEASE) is way too old for LaMachine, upgrade to the latest LTS release"
            fi
        fi
        INSTALL="sudo apt-get -m install pkg-config git-core make gcc g++ autoconf automake autoconf-archive libtool autotools-dev libicu-dev libxml2-dev libxslt1-dev libbz2-dev zlib1g-dev libtar-dev libaspell-dev libhunspell-dev libboost-all-dev python3 python3-dev $PIPPACKAGE python-virtualenv libgnutls-dev libcurl4-gnutls-dev wget libexttextcat-dev libatlas-dev libblas-dev gfortran libsuitesparse-dev libfreetype6-dev myspell-nl"  #python-virtualenv will still pull in python2 unfortunately, no separate 3 package but 2 version is good enough
        if [ "$PYTHON" == "python2" ]; then
            INSTALL="$INSTALL python python-dev python-pip"
        fi
    elif [ "$OS" == "redhat" ]; then
        INSTALL="sudo yum install pkgconfig git icu icu-devel libtool autoconf automake autoconf-archive make gcc gcc-c++ libxml2 libxml2-devel libxslt libxslt-devel libtar libtar-devel boost boost-devel python3 python3-devel zlib zlib-devel python3-virtualenv python3-pip bzip2 bzip2-devel libcurl gnutls-devel libcurl-devel wget libexttextcat libexttextcat-devel aspell aspell-devel hunspell-devel atlas-devel blas-devel lapack-devel libgfortran suitesparse suitesparse-devel"
        if [ "$PYTHON" == "python2" ]; then
            INSTALL="$INSTALL python python-devel python-pip"
        fi
    elif [ "$OS" == "freebsd" ]; then
        INSTALL="sudo pkg install git libtool pkgconf autoconf automake autoconf-archive gmake libxml2 libxslt icu libtar boost-all lzlib python3 bzip2 py27-virtualenv curl wget gnutls aspell hunspell libtextcat"
        if [ "$PYTHON" == "python2" ]; then
            INSTALL="$INSTALL python"
        fi
    elif [ "$OS" == "mac" ]; then
        MACPYTHON3=$(which python3)
        if [ "$?" != 0 ]; then
            BREWEXTRA="python3"
        else
            BREWEXTRA=""
        fi
        INSTALL="brew install pkg-config autoconf automake libtool autoconf-archive boost --with-python3 boost-python xml2 libxslt icu4c libtextcat aspell hunspell wget $BREWEXTRA"

        DISTRIB_ID="OSX"
        DISTRIB_RELEASE=$(sw_vers -productVersion | tr -d '\n')
    else
        error "No suitable package manage detected! Unable to verify and install the necessary global dependencies"
        if [ -d "/Users" ]; then
            echo "HINT: It seems you are on Mac OS X? Please install homebrew first from http://brew.sh"
        fi
        echo " (will attempt to continue anyway but it will most probably fail)"
        sleep 5
    fi

    if [ ! -z "$INSTALL" ]; then
        echo
        echo "-------------------------------"
        echo "Updating global dependencies "
        echo "-------------------------------"
        echo " (this step, and only this step, may require root access, skip it with CTRL-C if you do not have it)"
        echo "Command: $INSTALL"
        if [ "$OS" == "debian" ]; then
            sudo apt-get update
        fi
        if [ "$OS" == "mac" ]; then
            $INSTALL || error "An error occurred during installation of global dependencies. If you only got 'already installed' messages, however, you can ignore this. Attempting to continue installation in 15s... If a later error occurs, this is likely the cause."
        else 
            $INSTALL || error "Global dependencies could not be installed, possibly due to you not having root-access. In which case you may need to ask your system administrator to install the above-mentioned dependencies. Installation will continue as normal in 15s, but if a later error occurs, then a missing global dependency is likely the cause."
        fi
        sleep 15
    fi

    if [ "$OS" == "redhat" ]; then
        if [ ! -f /usr/bin/virtualenv ]; then
            echo "Linking /usr/bin/virtualenv to version-specific virtualenv, this is done globally on the host system!!! (requires root)"
            sudo ln -s /usr/bin/virtualenv* /usr/bin/virtualenv
        fi
    fi

fi




if [ -z "$VIRTUAL_ENV" ]; then
    VENV=$(which virtualenv)
    if [ ! -f "$VENV" ]; then
        error "virtualenv not found"
        if [[ "$PYTHON" == "python2.7" ]]; then
            PIP=$(which pip)
        else
            PIP=$(which pip3)
        fi
        if [ ! -f "$PIP" ]; then
            PIP=$(which pip)
            if [ ! -f "$PIP" ]; then
                fatalerror "pip3 or pip not found"
            fi
        fi
        echo "Attempting to install virtualenv"
        $PIP install virtualenv
        if [ "$?" != "0" ]; then
            echo "Retrying as root:"
            sudo $PIP install virtualenv || fatalerror "Unable to install virtualenv :( .. Giving up, ask your system administrator to install the necessary dependencies first or try the LaMachine VM instead"
        fi
    fi
    echo
    echo "-----------------------------------------"
    echo "Creating virtual environment"
    echo "-----------------------------------------"
    virtualenv --python=$PYTHON lamachine || fatalerror "Unable to create virtual environment"
    . lamachine/bin/activate || fatalerror "Unable to activate virtual environment"
    MODE='new'
else
    echo "Existing virtual environment detected... good.."
    MODE='update'
fi


if [ $DEV -eq 0 ]; then
    rm -f "$VIRTUAL_ENV/src/LaMachine/.dev" 2>/dev/null
else
    touch "$VIRTUAL_ENV/src/LaMachine/.dev"
fi

if [ $PRIVATE -eq 0 ]; then
    rm -f "$VIRTUAL_ENV/src/LaMachine/.private" 2>/dev/null
    #Sending some statistics to us so we know how often and on what systems LaMachine is used
    #recipient: Language Machines, Centre for Language Studies, Radboud University Nijmegen
    #
    #Transmitted are:
    # - The form in which you run LaMachine (vagrant/virtualenv/docker)
    # - Is it a new LaMachine installation or an update
    # - Stable or Development?
    # - The OS you are running on and its version
    # - Your Python version
    #
    #This information will never be used for any form of advertising
    #Your IP will only be used to compute country of origin, resulting reports will never contain personally identifiable information

    if [ $DEV -eq 0 ]; then
        STABLEDEV="stable"
    else
        STABLEDEV="dev"
    fi
    PYTHONVERSION=`python -c 'import sys; print(".".join(map(str, sys.version_info[:3])))'`
    wget -O - -q "http://applejack.science.ru.nl/lamachinetracker.php/virtualenv/$MODE/$STABLEDEV/$PYTHONVERSION/$OS/$DISTRIB_ID/$DISTRIB_RELEASE"  >/dev/null
else
    touch "$VIRTUAL_ENV/src/LaMachine/.private"
fi

if [ "$OS" == "mac" ]; then
    echo
    echo "-------------------------------------"
    echo "Copying ICU to virtual environment"
    echo "-------------------------------------"
    cp -R /usr/local/opt/icu4c/* "$VIRTUAL_ENV/" 2> /dev/null

    echo
    echo "-------------------------------------"
    echo "Testing whether libxml2 is sane"
    echo "-------------------------------------"
    XMLPATH=`pkg-config --cflags libxml-2.0`
    if [ "$?" != "0" ] || [ ! -d ${XMLPATH:2} ]; then
        echo "xml2 is not sane, attempting to compensate"
        export PKG_CONFIG_PATH=`ls -d /usr/local/Cellar/libxml2/*/lib/pkgconfig`
        echo "PKG_CONFIG_PATH is now $PKG_CONFIG_PATH"
    fi

fi


activate='
# This file must be used with "source bin/activate" *from bash or zsh*
# you cannot run it directly
# EDITED by LaMachine

deactivate () {
    unset PYTHONPATH

    unset pydoc

    # reset old environment variables
    if [ -n "$_OLD_VIRTUAL_PATH" ] ; then
        PATH="$_OLD_VIRTUAL_PATH"
        export PATH
        unset _OLD_VIRTUAL_PATH
    fi
    if [ -n "$_OLD_VIRTUAL_PYTHONHOME" ] ; then
        PYTHONHOME="$_OLD_VIRTUAL_PYTHONHOME"
        export PYTHONHOME
        unset _OLD_VIRTUAL_PYTHONHOME
    fi
    if [ -n "$_OLD_VIRTUAL_LD_LIBRARY_PATH" ] ; then
        LD_LIBRARY_PATH="$_OLD_VIRTUAL_LD_LIBRARY_PATH"
        export LD_LIBRARY_PATH
        unset _OLD_VIRTUAL_LD_LIBRARY_PATH
    fi
    if [ -n "$_OLD_VIRTUAL_LD_RUN_PATH" ] ; then
        LD_RUN_PATH="$_OLD_VIRTUAL_LD_RUN_PATH"
        export LD_RUN_PATH
        unset _OLD_VIRTUAL_LD_RUN_PATH
    fi
    if [ -n "$_OLD_VIRTUAL_CPATH" ] ; then
        CPATH="$_OLD_VIRTUAL_CPATH"
        export CPATH
        unset _OLD_VIRTUAL_CPATH
    fi

    # This should detect bash and zsh, which have a hash command that must
    # be called to get it to forget past commands.  Without forgetting
    # past commands the $PATH changes we made may not be respected
    if [ -n "$BASH" -o -n "$ZSH_VERSION" ] ; then
        hash -r 2>/dev/null
    fi

    if [ -n "$_OLD_VIRTUAL_PS1" ] ; then
        PS1="$_OLD_VIRTUAL_PS1"
        export PS1
        unset _OLD_VIRTUAL_PS1
    fi

    unset VIRTUAL_ENV
    if [ ! "$1" = "nondestructive" ] ; then
    # Self destruct!
        unset -f deactivate
    fi
}

# unset irrelevant variables
deactivate nondestructive


VIRTUAL_ENV="_VIRTUAL_ENV_"
export VIRTUAL_ENV

_OLD_VIRTUAL_PATH="$PATH"
PATH="$VIRTUAL_ENV/bin:$PATH"
export PATH

_OLD_VIRTUAL_LD_LIBRARY_PATH="$LD_LIBRARY_PATH"
case ":$LD_LIBRARY_PATH:" in
      *":$VIRTUAL_ENV/lib:"*) :;; # already there
      *) export LD_LIBRARY_PATH="$VIRTUAL_ENV/lib:$LD_LIBRARY_PATH";; 
esac

_OLD_VIRTUAL_LD_RUN_PATH="$LD_RUN_PATH"
case ":$LD_RUN_PATH:" in
      *":$VIRTUAL_ENV/lib:"*) :;; # already there
      *) export LD_RUN_PATH="$VIRTUAL_ENV/lib:$LD_RUN_PATH";; 
esac

export _OLD_VIRTUAL_CPATH="$CPATH"
case ":$CPATH:" in
      *":$VIRTUAL_ENV/include:"*) :;; # already there
      *) export CPATH="$VIRTUAL_ENV/include:$CPATH";; 
esac

# unset PYTHONHOME if set
# this will fail if PYTHONHOME is set to the empty string (which is bad anyway)
# could use `if (set -u; : $PYTHONHOME) ;` in bash
if [ -n "$PYTHONHOME" ] ; then
    _OLD_VIRTUAL_PYTHONHOME="$PYTHONHOME"
    unset PYTHONHOME
fi

if [ -z "$VIRTUAL_ENV_DISABLE_PROMPT" ] ; then
    _OLD_VIRTUAL_PS1="$PS1"
    if [ "x" != x ] ; then
        PS1="$PS1"
    else
    if [ "`basename \"$VIRTUAL_ENV\"`" = "__" ] ; then
        # special case for Aspen magic directories
        # see http://www.zetadev.com/software/aspen/
        PS1="[`basename \`dirname \"$VIRTUAL_ENV\"\``] $PS1"
    else
        PS1="(`basename \"$VIRTUAL_ENV\"`)$PS1"
    fi
    fi
    export PS1
fi

alias pydoc="python -m pydoc"

# This should detect bash and zsh, which have a hash command that must
# be called to get it to forget past commands.  Without forgetting
# past commands the $PATH changes we made may not be respected
if [ -n "$BASH" -o -n "$ZSH_VERSION" ] ; then
    hash -r 2>/dev/null
fi'

activate_conda='
VIRTUAL_ENV="_VIRTUAL_ENV_"

_OLD_VIRTUAL_LD_LIBRARY_PATH="$LD_LIBRARY_PATH"
case ":$LD_LIBRARY_PATH:" in
      *":$VIRTUAL_ENV/lib:"*) :;; # already there
      *) export LD_LIBRARY_PATH="$VIRTUAL_ENV/lib:$LD_LIBRARY_PATH";; 
esac

_OLD_VIRTUAL_LD_RUN_PATH="$LD_RUN_PATH"
case ":$LD_RUN_PATH:" in
      *":$VIRTUAL_ENV/lib:"*) :;; # already there
      *) export LD_RUN_PATH="$VIRTUAL_ENV/lib:$LD_RUN_PATH";; 
esac

export _OLD_VIRTUAL_CPATH="$CPATH"
case ":$CPATH:" in
      *":$VIRTUAL_ENV/include:"*) :;; # already there
      *) export CPATH="$VIRTUAL_ENV/include:$CPATH";; 
esac'


activate_this_py='
"""By using execfile(this_file, dict(__file__=this_file)) you will
activate this virtualenv environment.

This can be used when you must use an existing Python interpreter, not
the virtualenv bin/python
"""

try:
    __file__
except NameError:
    raise AssertionError("You must run this like execfile(\\"_VIRTUAL_ENV_/bin/activate_this.py\\", dict(__file__=\\"_VIRTUAL_ENV_/bin/activate_this.py\\"))")
import sys
import os

old_os_path = os.environ.get("PATH", "")
os.environ["PATH"] = os.path.dirname(os.path.abspath(__file__)) + os.pathsep + old_os_path
old_os_libpath = os.environ.get("LD_LIBRARY_PATH", "")
os.environ["LD_LIBRARY_PATH"] = "_VIRTUAL_ENV_/lib" + os.pathsep + old_os_libpath
base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if sys.platform == "win32":
    site_packages = os.path.join(base, "Lib", "site-packages")
else:
    site_packages = os.path.join(base, "lib", "python" + str(sys.version[:3]), "site-packages")
prev_sys_path = list(sys.path)
import site
site.addsitedir(site_packages)
sys.real_prefix = sys.prefix
sys.prefix = base
# Move the added items to the front of the path:
new_sys_path = []
for item in list(sys.path):
    if item not in prev_sys_path:
        new_sys_path.append(item)
        sys.path.remove(item)
sys.path[:0] = new_sys_path'

echo
echo "--------------------------------------------------------"
echo "Modifying environment"
echo "--------------------------------------------------------"
if [ "$CONDA" == "1" ]; then
    VIRTUAL_ENV=$(pwd)
    mkdir "$VIRTUAL_ENV/activate.d/"
    printf "$activate_conda" > "$VIRTUAL_ENV/activate.d/lamachine.sh"
    chmod a+x "$VIRTUAL_ENV/activate.d/lamachine.sh"
    VIRTUAL_ENV_ESCAPED=${VIRTUAL_ENV//\//\\/}
    sed -i -e "s/_VIRTUAL_ENV_/${VIRTUAL_ENV_ESCAPED}/" "$VIRTUAL_ENV/activate.d/lamachine.sh" || fatalerror "Error modifying environment"
else
    printf "$activate" > $VIRTUAL_ENV/bin/activate  
    VIRTUAL_ENV_ESCAPED=${VIRTUAL_ENV//\//\\/}
    sed -i -e "s/_VIRTUAL_ENV_/${VIRTUAL_ENV_ESCAPED}/" "$VIRTUAL_ENV/bin/activate" || fatalerror "Error modifying environment"
    printf "${activate_this_py}" > "$VIRTUAL_ENV/bin/activate_this.py"
    VIRTUAL_ENV_ESCAPED=${VIRTUAL_ENV//\//\\/}
    sed -i -e "s/_VIRTUAL_ENV_/${VIRTUAL_ENV_ESCAPED}/" "$VIRTUAL_ENV/bin/activate_this.py" || fatalerror "Error modifying environment"
fi

if [ ! -d "$VIRTUAL_ENV/src" ]; then
    mkdir "$VIRTUAL_ENV/src"
fi
cd "$VIRTUAL_ENV/src"

echo
echo "--------------------------------------------------------"
echo "Updating LaMachine itself"
echo "--------------------------------------------------------"
if [ ! -d LaMachine ]; then
    git clone https://github.com/proycon/LaMachine || fatalerror "Unable to clone git repo for LaMachine"
    cd LaMachine
    cp virtualenv-bootstrap.sh "$VIRTUAL_ENV/bin/lamachine-update.sh"
else
    cd LaMachine
    OLDSUM=`sum virtualenv-bootstrap.sh`
    git pull
    NEWSUM=`sum virtualenv-bootstrap.sh`
    cp virtualenv-bootstrap.sh "$VIRTUAL_ENV/bin/lamachine-update.sh"
    if [ "$OLDSUM" != "$NEWSUM" ]; then
        echo "----------------------------------------------------------------"
        echo "LaMachine has been updated with a newer version, restarting..."
        echo "----------------------------------------------------------------"
        sleep 3
        ./virtualenv-bootstrap.sh $@ 
        exit $?
    fi
fi
cd ..


if [ -z "$_OLD_VIRTUAL_LD_LIBRARY_PATH" ] ; then
    export _OLD_VIRTUAL_LD_LIBRARY_PATH="$LD_LIBRARY_PATH"
fi
case ":$LD_LIBRARY_PATH:" in
      *":$VIRTUAL_ENV/lib:"*) :;; # already there
      *) export LD_LIBRARY_PATH="$VIRTUAL_ENV/lib:$LD_LIBRARY_PATH";; 
esac

if [ -z "$_OLD_VIRTUAL_LD_RUN_PATH" ] ; then
    export _OLD_VIRTUAL_LD_RUN_PATH="$LD_RUN_PATH"
fi
case ":$LD_RUN_PATH:" in
      *":$VIRTUAL_ENV/lib:"*) :;; # already there
      *) export LD_RUN_PATH="$VIRTUAL_ENV/lib:$LD_RUN_PATH";; 
esac

if [ -z "$_OLD_VIRTUAL_CPATH" ] ; then
    export _OLD_VIRTUAL_CPATH="$CPATH"
fi
case ":$CPATH:" in
      *":$VIRTUAL_ENV/include:"*) :;; # already there
      *) export CPATH="$VIRTUAL_ENV/include:$CPATH";; 
esac

if [ "$FORCE" == "1" ]; then
    RECOMPILE=1
    echo "Forcing recompilation of everything"
else
    RECOMPILE=0
fi




if [ "$OS" == "mac" ]; then
    #C++ projects on Mac OS X 
    PROJECTS="ticcutils libfolia ucto timbl timblserver mbt mbtserver wopr frogdata frog toad" #no foliautils on mac yet, not daring to try ticcltools yet
else
    #C++ projects on normal Linux/BSD systems
    PROJECTS="ticcutils libfolia foliautils ucto timbl timblserver mbt mbtserver wopr frogdata frog toad ticcltools"
fi


for project in $PROJECTS; do
    echo 
    echo "--------------------------------------------------------"
    echo "Installing/updating $project"
    echo "--------------------------------------------------------"
    if [ ! -d $project ]; then
        git clone https://github.com/LanguageMachines/$project || fatalerror "Unable to clone git repo for $project"
        cd $project
        gitcheck
        RECOMPILE=1
    else
        cd $project
        pwd
        gitcheck
        if [ $REPOCHANGED -eq 1 ]; then
            RECOMPILE=1
        fi
    fi
    if [ $RECOMPILE -eq 1 ]; then
        bash bootstrap.sh || fatalerror "$project bootstrap failed"
        EXTRA=""
        if [ "$OS" == "mac" ]; then
            if [ "$project" == "libfolia" ] || [ $PROJECT == "ucto" ]; then
                EXTRA="--with-icu=/usr/local/opt/icu4c"
            fi
        fi
        if [[ "$project" == "wopr" ]]; then
            #Wopr fails on FreeBSD, allow process to continue
            ./configure --prefix=$VIRTUAL_ENV $EXTRA || error "$project configure failed"
            make || error "$project make failed"
            make install || error "$project make install failed"
        else
            ./configure --prefix=$VIRTUAL_ENV $EXTRA || fatalerror "$project configure failed"
            make || fatalerror "$project make failed"
            make install || fatalerror "$project make install failed"
        fi
    else
        echo "$project is up-to-date, no need to recompile ..."
    fi 
    cd ..
done


echo 
echo "--------------------------------------------------------------"
echo "Installing Python dependencies from the Python Package Index"
echo "--------------------------------------------------------------"
if [ $NOPYTHONDEPS -eq 0 ]; then
    PYTHONDEPS="cython numpy ipython scipy matplotlib lxml scikit-learn django pycrypto pandas textblob nltk psutil flask requests requests_toolbelt requests_oauthlib"
    for PYTHONDEP in $PYTHONDEPS; do
        pip install -U $PYTHONDEP || fatalerror "Unable to install required dependency $PYTHONDEP from Python Package Index"
    done
else
    echo "Skipping...."
fi

PYTHONMAJOR=$(python -c "import sys; print(sys.version_info.major,end='')")
PYTHONMINOR=$(python -c "import sys; print(sys.version_info.minor,end='')")

PYTHONPROJECTS="pynlpl folia foliadocserve flat"


echo 
echo "--------------------------------------------------------"
echo "Installing Python packages"
echo "--------------------------------------------------------"
for project in $PYTHONPROJECTS; do
    echo 
    echo "--------------------------------------------------------"
    echo "Installing $project">&2
    echo "--------------------------------------------------------"
    if [ ! -d $project ]; then
        git clone https://github.com/proycon/$project
        cd $project
        gitcheck
        REPOCHANGED=1
    else
        cd $project
        gitcheck
    fi
    if [ $REPOCHANGED -eq 1 ]; then
        #cleanup previous installations (bit of a hack to prevent a bug when reinstalling)
        if [ "$project" == "pynlpl" ]; then
            rm -Rf $VIRTUAL_ENV/lib/python${PYTHONMAJOR}.${PYTHONMINOR}/site-packages/PyNLPl*egg
        elif [ "$project" == "folia" ]; then
            rm -Rf $VIRTUAL_ENV/lib/python${PYTHONMAJOR}.${PYTHONMINOR}/site-packages/*FoLiA*egg
        elif [ "$project" == "foliadocserve" ]; then
            rm -Rf $VIRTUAL_ENV/lib/python${PYTHONMAJOR}.${PYTHONMINOR}/site-packages/*foliadocserve*egg
        fi
        python setup.py install --prefix="$VIRTUAL_ENV" || fatalerror "setup.py install $project failed"
    else
        echo "$project is up-to-date, no need to recompile ..."
    fi
    cd ..
done

echo
echo "--------------------------------------------------------"
echo "Installing python-ucto"
echo "--------------------------------------------------------"
if [ ! -d python-ucto ]; then
    git clone https://github.com/proycon/python-ucto
    cd python-ucto
    gitcheck
    REPOCHANGED=1
else
    cd python-ucto 
    gitcheck 
fi
if [ $REPOCHANGED -eq 1 ] || [ $RECOMPILE -eq 1 ]; then
    rm *_wrapper.cpp >/dev/null 2>/dev/null #forcing recompilation of cython stuff
    python setup.py build_ext --include-dirs="$VIRTUAL_ENV/include" --library-dirs="$VIRTUAL_ENV/lib" install --prefix="$VIRTUAL_ENV" || error "Python-ucto installation failed"
else 
    echo "Python-ucto is already up to date ... "
fi
cd ..


echo
echo "--------------------------------------------------------"
echo "Installing python-timbl"
echo "--------------------------------------------------------"
if [ ! -d python-timbl ]; then
    git clone https://github.com/proycon/python-timbl
    cd python-timbl
    gitcheck
    REPOCHANGED=1
else
    cd python-timbl
    gitcheck
fi
if [ $REPOCHANGED -eq 1 ] || [ $RECOMPILE -eq 1 ]; then
    rm -Rf build
    if [ -f "$VIRTUAL_ENV/lib/libboost_python.so" ]; then
        python setup3.py build_ext --boost-library-dir="$VIRTUAL_ENV/lib" install
    elif [ -f /usr/lib/x86_64-linux-gnu/libboost_python.so ]; then
        python setup3.py build_ext --boost-library-dir=/usr/lib/x86_64-linux-gnu install
    elif [ -f /usr/lib/i386-linux-gnu/libboost_python.so ]; then
        python setup3.py build_ext --boost-library-dir=/usr/lib/i386-linux-gnu install
    elif [ -d /usr/local/Cellar/boost-python/ ]; then
        BOOSTVERSION=$(ls /usr/local/Cellar/boost-python/ | head -n 1 | tr -d '\n')
        BOOSTLIBDIR=/usr/local/Cellar/boost-python/$BOOSTVERSION/lib/
        BOOSTINCDIR=/usr/local/Cellar/boost/$BOOSTVERSION/include/
        echo "Boost $BOOSTVERSION found in $BOOSTLIBDIR  , $BOOSTINCDIR"
        python setup3.py build_ext --boost-library-dir=$BOOSTLIBDIR --boost-include-dir=$BOOSTINCDIR install
    else
        python setup3.py build_ext install
    fi
    if [ "$?" == 65 ]; then
        #boost not found
        echo "boost-python not found for this version of Python, we are gonna attempt to compile it manually"
        TS=$(date +%s)
        if [ ! -f boost.tar.bz2 ]; then
            wget "http://downloads.sourceforge.net/project/boost/boost/1.58.0/boost_1_58_0.tar.bz2?r=http%3A%2F%2Fsourceforge.net%2Fprojects%2Fboost%2Ffiles%2Fboost%2F1.58.0%2F&ts=$TS&use_mirror=garr" -O boost.tar.bz2
            tar -xjf boost.tar.bz2 2>/dev/null
        fi
        cd boost*
        PYTHONINCLUDE=`find -L $VIRTUAL_ENV/include -name pyconfig.h | head -n 1`
        if [ "$?" != "0" ]; then
            error "pyconfig.h not found!"
        fi
        echo $PYTHONINCLUDE
        PYTHONINCLUDE=`dirname $PYTHONINCLUDE`
        export CPLUS_INCLUDE_PATH="$PYTHONINCLUDE:$CPLUS_INCLUDE_PATH"
        ./bootstrap.sh --with-libraries=python --prefix="$VIRTUAL_ENV" --with-python-root="$VIRTUAL_ENV" --with-python="$VIRTUAL_ENV/bin/python"
        ./b2 || error "Manual boost compilation failed"
        ./b2 install || error "Manual boost installation failed"
        cd ..
        python setup3.py build_ext --boost-library-dir="$VIRTUAL_ENV/lib" install || error "python-timbl installation failed"
    fi
else
    echo "Python-timbl is already up to date ... "
fi
cd ..

if [ -f /usr/bin/python2.7 ] || [ -f /usr/local/bin/python2.7 ]; then
    echo
    echo "--------------------------------------------------------"
    echo "Installing python-frog"
    echo "--------------------------------------------------------"
    if [ ! -d python-frog ]; then
        git clone https://github.com/proycon/python-frog
        cd python-frog
        gitcheck
        REPOCHANGED=1
    else
        cd python-frog
        gitcheck
    fi
    if [ $REPOCHANGED -eq 1 ] || [ $RECOMPILE -eq 1 ]; then
        rm *_wrapper.cpp >/dev/null 2>/dev/null #forcing recompilation of cython stuff
        python setup.py install || error "python-frog failed"
    else
        echo "Python-frog is already up to date ... "
    fi
    cd ..
else
    echo "No Python 2.7 available, skipping python-frog"
fi

echo
echo "--------------------------------------------------------"
echo "Installing colibri-core"
echo "--------------------------------------------------------"
if [ ! -d colibri-core ]; then
    git clone https://github.com/proycon/colibri-core
    cd colibri-core
    gitcheck
    REPOCHANGED=1
else
    cd colibri-core 
    gitcheck
fi
if [ $REPOCHANGED -eq 1 ] || [ $RECOMPILE -eq 1 ]; then
    rm *_wrapper.cpp >/dev/null 2>/dev/null #forcing recompilation of cython stuff
    python setup.py install || error "colibri core failed"
fi
cd ..

echo 
echo "--------------------------------------------------------"
echo "Installing clam">&2
echo "--------------------------------------------------------"
if [ ! -d clam ]; then
    git clone https://github.com/proycon/clam
    cd clam
    gitcheck
    REPOCHANGED=1
else
    rm -Rf $VIRTUAL_ENV/lib/python${PYTHONMAJOR}.${PYTHONMINOR}/site-packages/CLAM*egg
    cd clam
    gitcheck
fi
if [ $REPOCHANGED -eq 1 ]; then
    python setup.py install --prefix="$VIRTUAL_ENV" || fatalerror "setup.py install clam failed"
fi
cd ..

if [[ "$PYTHON" != "python2.7" ]]; then
    if [ "$OS" != "mac" ]; then
        echo "--------------------------------------------------------"
        echo "Installing extra optional dependencies for Gecco">&2
        echo "--------------------------------------------------------"
        pip install -U aspell-python-py3 hunspell
    fi
    project="gecco"
    echo 
    echo "--------------------------------------------------------"
    echo "Installing $project">&2
    echo "--------------------------------------------------------"
    if [ ! -d $project ]; then
        git clone https://github.com/proycon/$project
        cd $project
        gitcheck
        REPOCHANGED=1
    else
        cd $project
        gitcheck
    fi
    if [ $REPOCHANGED -eq 1 ]; then
        rm -Rf $VIRTUAL_ENV/lib/python${PYTHONMAJOR}.${PYTHONMINOR}/site-packages/${project}*egg
        python setup.py install --prefix="$VIRTUAL_ENV" || error "setup.py install $project failed"
    else
        echo "Gecco is already up to date ... "
    fi
    cd ..
fi

. LaMachine/extra.sh $@ 

echo "--------------------------------------------------------"
echo "All done!">&2
echo "  From now on, activate your virtual environment as follows: . $VIRTUAL_ENV/bin/activate">&2
echo "  To facilitate activation, add an alias to your ~/.bashrc: alias lm=\". $VIRTUAL_ENV/bin/activate\"">&2
