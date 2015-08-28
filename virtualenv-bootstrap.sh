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

gitcheck () {
    git remote update
    LOCAL=$(git rev-parse @)
    REMOTE=$(git rev-parse @{u})
    BASE=$(git merge-base @ @{u})

    if [ $LOCAL = $REMOTE ]; then
        echo "Git: up-to-date"
        REPOCHANGED=0
    elif [ $LOCAL = $BASE ]; then
        echo "Git: Pulling..."
        git pull || fatalerror "Unable to git pull $project"
        REPOCHANGED=1
    elif [ $REMOTE = $BASE ]; then
        echo "Git: Need to push"
        REPOCHANGED=1
    else
        echo "Git: Diverged"
        REPOCHANGED=1
    fi
}

svncheck () {
    LOCAL=$(svn info HEAD | grep -i "Last Changed Rev")
    LOCAL=${LOCAL#"Last Changed Rev: "}
    REMOTE=$(svn info -r HEAD | grep -i "Last Changed Rev")
    REMOTE=${REMOTE#"Last Changed Rev: "}
    if [ $LOCAL = $REMOTE ]; then
        REPOCHANGED=0
    else 
        svn update || fatalerror "Unable to svn update $project"
        REPOCHANGED=1
    fi
}

NOADMIN=0
FORCE=0
WITHTSCAN=0
for OPT in "$@"
do
    if [[ "$OPT" == "noadmin" ]]; then
        NOADMIN=1
    fi
    if [[ "$OPT" == "force" ]]; then
        FORCE=1
    fi
    if [[ "$OPT" == "tscan" ]]; then
        WITHTSCAN=1
    fi
done


CONDA=0
#if [ ! -z "$CONDA_DEFAULT_ENV" ]; then
#    echo "Running in Anaconda environment... THIS IS UNTESTED!" >&2
#    if [ ! -d conda-meta ]; then
#        echo "Make sure your current working directory is in the root of the anaconda environment ($CONDA_DEFAULT_ENV)" >&2
#        exit 2
#    fi
#    CONDA=1

ARCH=`which pacman 2> /dev/null`
DEBIAN=`which apt-get 2> /dev/null`
MAC=`which brew 2> /dev/null`
REDHAT=`which yum 2> /dev/null`
FREEBSD=`which pkg 2> /dev/null`
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

if [ "$NOADMIN" == "0" ]; then
    echo "Detecting package manager..."
    INSTALL=""
    if [ "$OS" == "arch" ]; then
        INSTALL="sudo pacman -Syu --needed --noconfirm base-devel pkg-config git autoconf-archive icu xml2 libxslt zlib libtar boost boost-libs python2 python python-pip python-virtualenv wget gnutls curl libexttextcat aspell hunspell blas lapack suitesparse"
    elif [ "$OS" == "debian" ]; then
        INSTALL="sudo apt-get -m install pkg-config git-core make gcc g++ autoconf-archive libtool autotools-dev libicu-dev libxml2-dev libxslt1-dev libbz2-dev zlib1g-dev libtar-dev libaspell-dev libhunspell-dev libboost-all-dev python-dev python3 python3-dev python-pip python-virtualenv libgnutls-dev libcurl4-gnutls-dev wget libexttextcat-dev libatlas-dev libblas-dev gfortran libsuitesparse-dev" 
    elif [ "$OS" == "redhat" ]; then
        INSTALL="sudo yum install pkgconfig git icu icu-devel libtool autoconf automake autoconf-archive make gcc gcc-c++ libxml2 libxml2-devel libxslt libxslt-devel libtar libtar-devel boost boost-devel python python-devel python3 python3-devel zlib zlib-devel python3-virtualenv python-pip python3-pip bzip2 bzip2-devel libcurl gnutls-devel libcurl-devel wget libexttextcat libexttextcat-devel aspell aspell-devel hunspell-devel atlas-devel blas-devel lapack-devel libgfortran suitesparse suitesparse-devel"
    elif [ "$OS" == "freebsd" ]; then
        INSTALL="sudo pkg install git gcc libtool autoconf automake autoconf-archive gmake libxml2 libxslt icu libtar boost-all lzlib python2 python3 cython bzip2 py27-virtualenv curl wget gnutls aspell hunspell"
    elif [ "$OS" == "mac" ]; then
        MACPYTHON3=`which python3` 
        if [ "$?" != 0 ]; then
            BREWEXTRA="python3"
        else
            BREWEXTRA=""
        fi
        INSTALL="brew install autoconf automake libtool autoconf-archive boost --with-python  boost-python xml2 libxslt icu4c libtextcat aspell hunspell wget $BREWEXTRA"
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
        $INSTALL || error "Global dependencies could not be updated, possibly due to you not having root-access. In which case you may need to ask your system administrator to install the above-mentioned dependencies. Installation will continue as normal, but if a later error occurs, then a missing global dependency is likely the cause."
        sleep 3
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
        PIP=`which pip3`
        if [ ! -f "$PIP" ]; then
            PIP=`which pip`
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
    cp virtualenv-bootstrap.sh $VIRTUAL_ENV/bin/lamachine-update.sh
else
    cd LaMachine
    OLDSUM=`sum virtualenv-bootstrap.sh`
    git pull
    NEWSUM=`sum virtualenv-bootstrap.sh`
    cp virtualenv-bootstrap.sh $VIRTUAL_ENV/bin/lamachine-update.sh
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
        RECOMPILE=1
    else
        cd $project
        pwd
        if [ -d .svn ]; then
            #a cheat for versions with Tilburg's SVN as primary source rather than github, privileged access only
            svncheck
        else
            gitcheck
        fi
        if [ $REPOCHANGED -eq 1 ]; then
            RECOMPILE=1
        fi
    fi
    if [ $RECOMPILE -eq 1 ]; then
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
    else
        echo "$project is up-to-date, no need to recompile ..."
    fi 
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
        RECOMPILE=1
    else
        cd frog
        if [ -d .svn ]; then
            svncheck
        else
            gitcheck
        fi
        if [ $REPOCHANGED -eq 1 ]; then
            RECOMPILE=1
        fi
    fi
    if [ $RECOMPILE -eq 1 ]; then
        bash bootstrap.sh || fatalerror "frog bootstrap failed"
        ./configure --prefix=$VIRTUAL_ENV --with-python=/usr/bin/python2.7 || fatalerror "frog configure failed"
        make || fatalerror "frog make failed"
        make install || fatalerror "frog make install failed"
    fi
    cd ..
else
    echo "Skipping installation of Frog because Python 2.7 was not found in /usr/bin/python2.7 (needed for the parser)">&2
fi

echo 
echo "--------------------------------------------------------------"
echo "Installing Python dependencies from the Python Package Index"
echo "--------------------------------------------------------------"
PYTHONDEPS="cython numpy ipython scipy matplotlib lxml scikit-learn django pycrypto pandas textblob nltk psutil flask requests requests_toolbelt requests_oauthlib"
for PYTHONDEP in $PYTHONDEPS; do
    pip install -U $PYTHONDEP || fatalerror "Unable to install required dependency $PYTHONDEP from Python Package Index"
done

PYTHONMAJOR=`python -c "import sys; print(sys.version_info.major,end='')"`
PYTHONMINOR=`python -c "import sys; print(sys.version_info.minor,end='')"`

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
        python setup.py install --prefix=$VIRTUAL_ENV || fatalerror "setup.py install $project failed"
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
    REPOCHANGED=1
else
    cd python-ucto 
    gitcheck 
fi
if [ $REPOCHANGED -eq 1 ] || [ $RECOMPILE -eq 1 ]; then
    rm *_wrapper.cpp >/dev/null 2>/dev/null #forcing recompilation of cython stuff
    python setup.py build_ext --include-dirs=$VIRTUAL_ENV/include --library-dirs=$VIRTUAL_ENV/lib install --prefix=$VIRTUAL_ENV || error "Python-ucto installation failed"
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
    REPOCHANGED=1
else
    cd python-timbl
    gitcheck
fi
if [ $REPOCHANGED -eq 1 ] || [ $RECOMPILE -eq 1 ]; then
    if [ -f "$VIRTUAL_ENV/lib/libboost_python.so" ]; then
        python setup3.py build_ext --boost-library-dir=$VIRTUAL_ENV/lib install
    elif [ -f /usr/lib/x86_64-linux-gnu/libboost_python.so ]; then
        python setup3.py build_ext --boost-library-dir=/usr/lib/x86_64-linux-gnu install
    elif [ -f /usr/lib/i386-linux-gnu/libboost_python.so ]; then
        python setup3.py build_ext --boost-library-dir=/usr/lib/i386-linux-gnu install
    elif [ -f /usr/local/Cellar/boost-python/*/lib/libboost_python.dylib ]; then
        python setup3.py build_ext --boost-library-dir=/usr/local/Cellar/boost-python/*/lib/ install
    else
        python setup3.py build_ext install
    fi
    if [ "$?" == 65 ]; then
        #boost not found
        echo "boost-python not found for this version of Python, we are gonna attempt to compile it manually"
        TS=`date +%s`
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
        ./bootstrap.sh --with-libraries=python --prefix=$VIRTUAL_ENV --with-python-root=$VIRTUAL_ENV --with-python="$VIRTUAL_ENV/bin/python"
        ./b2 || error "Manual boost compilation failed"
        ./b2 install || error "Manual boost installation failed"
        cd ..
        python setup3.py build_ext --boost-library-dir=$VIRTUAL_ENV/lib install || error "python-timbl installation failed"
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
    REPOCHANGED=1
else
    cd colibri-core 
    gitcheck
fi
if [ $REPOCHANGED -eq 1 ] || [ $RECOMPILE -eq 1 ]; then
    rm *_wrapper.cpp >/dev/null 2>/dev/null #forcing recompilation of cython stuff
    python setup.py build_ext --include-dirs=$VIRTUAL_ENV/include/colibri-core --library-dirs=$VIRTUAL_ENV/lib install --prefix=$VIRTUAL_ENV 
    if [ $? -ne 0 ]; then
        error "colibri core failed, attempting to compensate and trying..."
        #ugly patch, something wrong in cython?
        echo "Attempting to compensate for colibri-core cython failure and retrying (some architectures such as Mac seem to require this"
        sed -i -e 's/unsigned long/unsigned long long/' colibricore_classes.pxd
        rm *_wrapper.cpp >/dev/null 2>/dev/null #forcing recompilation of cython stuff
        python setup.py build_ext --include-dirs=$VIRTUAL_ENV/include/colibri-core --library-dirs=$VIRTUAL_ENV/lib install --prefix=$VIRTUAL_ENV || error "colibri core failed"
        git stash #don't make it permanent
    fi
fi
cd ..

echo 
echo "--------------------------------------------------------"
echo "Installing clam">&2
echo "--------------------------------------------------------"
if [ ! -d clam ]; then
    git clone https://github.com/proycon/clam
    cd clam
    git checkout python3flask
else
    rm -Rf $VIRTUAL_ENV/lib/python${PYTHONMAJOR}.${PYTHONMINOR}/site-packages/CLAM*egg
    cd clam
    git checkout python3flask
    git pull
fi
python setup.py install --prefix=$VIRTUAL_ENV || fatalerror "setup.py install clam failed"
cd ..

project="gecco"
echo 
echo "--------------------------------------------------------"
echo "Installing $project">&2
echo "--------------------------------------------------------"
if [ ! -d $project ]; then
    git clone https://github.com/proycon/$project
    cd $project
    REPOCHANGED=1
else
    cd $project
    gitcheck
fi
if [ $REPOCHANGED -eq 1 ]; then
    rm -Rf $VIRTUAL_ENV/lib/python${PYTHONMAJOR}.${PYTHONMINOR}/site-packages/${project}*egg
    python setup.py install --prefix=$VIRTUAL_ENV || error "setup.py install $project failed"
else
    echo "Gecco is already up to date ... "
fi
cd ..

if [ $WITHTSCAN -eq 1 ] || [ -d tscan ]; then
    project="tscan"
    echo 
    echo "--------------------------------------------------------"
    echo "Installing $project">&2
    echo "--------------------------------------------------------"
    if [ ! -d $project ]; then
        git clone https://github.com/proycon/$project
        cd $project
        REPOCHANGED=1
    else
        cd $project
        gitcheck
    fi
    if [ $REPOCHANGED -eq 1 ]; then
        bash bootstrap.sh || fatalerror "$project bootstrap failed"
        ./configure --prefix=$VIRTUAL_ENV || fatalerror "$project configure failed"
        make || fatalerror "$project make failed"
        make install || fatalerror "$project make install failed"
    else
        echo "T-scan is already up to date ... "
    fi
    cd ..
fi

echo "--------------------------------------------------------"
echo "All done!">&2
echo "  From now on, activate your virtual environment as follows: . $VIRTUAL_ENV/bin/activate">&2
echo "  To facilitate activation, add an alias to your ~/.bashrc: alias lm=\". $VIRTUAL_ENV/bin/activate\"">&2
