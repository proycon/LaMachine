#!/bin/bash

echo "=== LaMachine Virtualenv Bootstrap ===">&2

fatalerror () {
    echo "================ FATAL ERROR ==============" >&2
    echo "An error occured during installation!!" >&2
    echo $1 >&2
    echo "===========================================" >&2
    exit 2
}

error () {
    echo "================= ERROR ===================" >&2
    echo $1 >&2
    echo "===========================================" >&2
    sleep 3
}

CONDA=0
#if [ ! -z "$CONDA_DEFAULT_ENV" ]; then
#    echo "Running in Anaconda environment... THIS IS UNTESTED!" >&2
#    if [ ! -d conda-meta ]; then
#        echo "Make sure your current working directory is in the root of the anaconda environment ($CONDA_DEFAULT_ENV)" >&2
#        exit 2
#    fi
#    CONDA=1

ARCH=`which pacman`
DEBIAN=`which apt-get`
MAC=`which brew`
REDHAT=`which yum`
FREEBSD=`which pkg`
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
    OS=""
fi

if [ "$1" != "noadmin" ]; then
    echo "Detecting package manager..."
    INSTALL=""
    if [ "$OS" == "arch" ]; then
        INSTALL="sudo pacman -Syu --needed --noconfirm base-devel pkg-config git autoconf-archive icu xml2 zlib libtar boost boost-libs python2 cython cython2 python python2 python-pip python2-pip python-requests python-lxml python2-lxml python-pycurl python-virtualenv python-numpy python2-numpy python-scipy python2-scipy python-matplotlib python2-matplotlib python-pandas python2-pandas python-nltk ipython ipython-notebook wget curl libexttextcat"
    elif [ "$OS" == "debian" ]; then
        INSTALL="sudo apt-get install pkg-config git-core make gcc g++ autoconf-archive libtool autotools-dev libicu-dev libxml2-dev libbz2-dev zlib1g-dev libtar-dev libboost-all-dev python-dev cython python3 python3-dev python-pip python3-pip cython cython3 python3-requests python-lxml python3-lxml python3-pycurl python-virtualenv python-numpy python3-numpy python-scipy python3-scipy python-matplotlib python3-matplotlib python-pandas python3-pandas python-requests python3-requests libcurl4-gnutls-dev libcurl4-gnutls wget libexttextcat-dev" 
    elif [ "$OS" == "redhat" ]; then
        INSTALL="sudo yum install pkgconfig git icu icu-devel libtool autoconf automake autoconf-archive make gcc gcc-c++ libxml2 libxml2-devel libtar libtar-devel boost boost-devel python python-devel python3 python3-devel python-lxml python3-lxml Cython zlib zlib-devel python-numpy python3-numpy scipy python3-scipy python-matplotlib python3-matplotlib python3-virtualenv python-pip python3-pip bzip2 bzip2-devel libcurl libcurl-devel wget libexttextcat libexttextcat-devel"
    elif [ "$OS" == "freebsd" ]; then
        INSTALL="sudo pkg install git gcc libtool autoconf automake autoconf-archive gmake libxml2 icu libtar boost-all lzlib python2 python3 cython bzip2 py27-virtualenv curl wget"
    elif [ "$OS" == "mac" ]; then
        INSTALL="brew install python3 autoconf automake libtool autoconf-archive boost xml2 icu4c libtextcat"
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
        echo " (this step, and only this step, may require root access, skip it with CTRL-C if you don't have it and ask your system administrator to install the mentioned dependencies instead)"
        echo "Command: $INSTALL"
        $INSTALL
    fi

    if [ "$OS" == "redhat" ]; then
        if [ ! -f /usr/bin/virtualenv ]; then
            echo "Linking /usr/bin/virtualenv to version-specific virtualenv, this is done globally on the host system!!! (requires root)"
            sudo ln -s /usr/bin/virtualenv* /usr/bin/virtualenv
        fi
    fi

fi



if [ -z "$VIRTUAL_ENV" ]; then
    VENV=`which virtualenv`
    if [ ! -f "$VENV" ]; then
        error "virtualenv not found"
        PIP3=`which pip3`
        if [ ! -f "$PIP3" ]; then
            fatalerror "pip3 not found"
        fi
        echo "Attempting to install virtualenv"
        pip3 install virtualenv
        if [ "$?" != "0" ]; then
            echo "Retrying as root:"
            sudo pip3 install virtualenv || fatalerror "Unable to install virtualenv :( .. Giving up, ask your system administrator to install the necessary dependencies first or try the LaMachine VM instead"
        fi
    fi
    echo
    echo "-----------------------------------------"
    echo "Creating virtual environment"
    echo "-----------------------------------------"
    virtualenv --python=python3 lamachine || fatalerror "Unable to create virtual environment"
    . lamachine/bin/activate || fatalerror "Unable to activate virtual environment"
else
    echo "Existing virtual environment detected... good.."
fi

if [ "$OS" == "mac" ]; then
    echo
    echo "-------------------------------------"
    echo "Copying ICU to virtual environment"
    echo "-------------------------------------"
    cp -R /usr/local/opt/icu4c/* $VIRTUAL_ENV/ 2> /dev/null
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

echo
echo "--------------------------------------------------------"
echo "Modifying environment"
echo "--------------------------------------------------------"
if [ "$CONDA" == "1" ]; then
    VIRTUAL_ENV=`pwd`
    mkdir $VIRTUAL_ENV/activate.d/
    printf "$activate_conda" > $VIRTUAL_ENV/activate.d/lamachine.sh
    chmod a+x $VIRTUAL_ENV/activate.d/lamachine.sh
    VIRTUAL_ENV_ESCAPED=${VIRTUAL_ENV//\//\\/}
    sed -i -e "s/_VIRTUAL_ENV_/${VIRTUAL_ENV_ESCAPED}/" $VIRTUAL_ENV/activate.d/lamachine.sh || fatalerror "Error modifying environment"
else
    printf "$activate" > $VIRTUAL_ENV/bin/activate  
    VIRTUAL_ENV_ESCAPED=${VIRTUAL_ENV//\//\\/}
    sed -i -e "s/_VIRTUAL_ENV_/${VIRTUAL_ENV_ESCAPED}/" $VIRTUAL_ENV/bin/activate || fatalerror "Error modifying environment"
fi

if [ ! -d $VIRTUAL_ENV/src ]; then
    mkdir $VIRTUAL_ENV/src
fi
cd $VIRTUAL_ENV/src

echo
echo "--------------------------------------------------------"
echo "Updating LaMachine itself"
echo "--------------------------------------------------------"
if [ ! -d LaMachine ]; then
    git clone https://github.com/proycon/LaMachine || fatalerror "Unable to clone git repo for LaMachine"
    cd LaMachine
else
    cd LaMachine
    git pull
fi
cp virtualenv-bootstrap.sh $VIRTUAL_ENV/bin/lamachine-update.sh
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



if [ "$OS" == "mac" ]; then
    PROJECTS="ticcutils libfolia ucto timbl timblserver mbt wopr frogdata" #no foliatools on mac yet
else
    PROJECTS="ticcutils libfolia foliatools ucto timbl timblserver mbt wopr frogdata"
fi

for project in $PROJECTS; do
    echo 
    echo "--------------------------------------------------------"
    echo "Installing/updating $project"
    echo "--------------------------------------------------------"
    if [ ! -d $project ]; then
        git clone https://github.com/proycon/$project || fatalerror "Unable to clone git repo for $project"
        cd $project
    else
        cd $project
        pwd
        if [ -d .svn ]; then
            svn update || fatalerror "Unable to svn update $project" #a cheat for versions with Tilburg's SVN as primary source rather than github
        else
            git pull || fatalerror "Unable to git pull $project"
        fi
    fi
    bash bootstrap.sh || fatalerror "$project bootstrap failed"
    EXTRA=""
    if [ "$OS" == "mac" ]; then
        if [ "$PROJECT" == "libfolia" ] || [ $PROJECT == "ucto" ]; then
            EXTRA="--with-icu=/usr/local/opt/icu4c"
        fi
    fi
    ./configure --prefix=$VIRTUAL_ENV $EXTRA || fatalerror "$project configure failed"
    make || fatalerror "$project make failed"
    make install || fatalerror "$project make install failed"
    cd ..
done

if [ -f /usr/bin/python2.7 ]; then
    echo 
    echo "--------------------------------------------------------"
    echo "Installing frog"
    echo "--------------------------------------------------------"
    if [ ! -d frog ]; then
        git clone https://github.com/proycon/frog
        cd frog
    else
        cd frog
        if [ -d .svn ]; then
            svn update
        else
            git pull
        fi
    fi
    bash bootstrap.sh || fatalerror "frog bootstrap failed"
    ./configure --prefix=$VIRTUAL_ENV --with-python=/usr/bin/python2.7 || fatalerror "frog configure failed"
    make || fatalerror "frog make failed"
    make install || fatalerror "frog make install failed"
    cd ..
else
    echo "Skipping installation of Frog because Python 2.7 was not found in /usr/bin/python2.7 (needed for the parser)">&2
fi

echo 
echo "--------------------------------------------------------"
echo "Installing Python dependencies from the Python Package Index"
echo "--------------------------------------------------------"
pip install -U cython ipython numpy scipy matplotlib lxml django


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
    else
        cd $project
        git pull
    fi
    python setup.py install --prefix=$VIRTUAL_ENV || fatalerror "setup.py install $project failed"
    cd ..
done

echo
echo "--------------------------------------------------------"
echo "Installing python-ucto"
echo "--------------------------------------------------------"
if [ ! -d python-ucto ]; then
    git clone https://github.com/proycon/python-ucto
    cd python-ucto
else
    cd python-ucto 
    git pull
    rm *_wrapper.cpp >/dev/null 2>/dev/null #forcing recompilation of cython stuff
fi
python setup.py build_ext --include-dirs=$VIRTUAL_ENV/include --library-dirs=$VIRTUAL_ENV/lib install --prefix=$VIRTUAL_ENV
cd ..


echo
echo "--------------------------------------------------------"
echo "Installing python-timbl"
echo "--------------------------------------------------------"
if [ ! -d python-timbl ]; then
    git clone https://github.com/proycon/python-timbl
    cd python-timbl
else
    cd python-timbl
    git pull
fi
if [ -d /usr/lib/x86_64-linux-gnu ]; then
    python setup3.py build_ext --boost-library-dir=/usr/lib/x86_64-linux-gnu install
else
    python setup3.py build_ext install
fi
cd ..

if [ -f /usr/bin/python2.7 ]; then
    echo
    echo "--------------------------------------------------------"
    echo "Installing python-frog"
    echo "--------------------------------------------------------"
    if [ ! -d python-frog ]; then
        git clone https://github.com/proycon/python-frog
        cd python-frog
    else
        cd python-frog
        git pull
        rm *_wrapper.cpp >/dev/null 2>/dev/null #forcing recompilation of cython stuff
    fi
    python setup.py install
    cd ..
fi

echo
echo "--------------------------------------------------------"
echo "Installing colibri-core"
echo "--------------------------------------------------------"
if [ ! -d colibri-core ]; then
    git clone https://github.com/proycon/colibri-core
    cd colibri-core
else
    cd colibri-core 
    git pull
    rm *_wrapper.cpp >/dev/null 2>/dev/null #forcing recompilation of cython stuff
fi
python setup.py build_ext --include-dirs=$VIRTUAL_ENV/include/colibri-core --library-dirs=$VIRTUAL_ENV/lib install --prefix=$VIRTUAL_ENV
cd ..

echo "--------------------------------------------------------"
echo "All done!">&2
echo "  From now on, activate your virtual environment as follows: . $VIRTUAL_ENV/bin/activate">&2
