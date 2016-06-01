#!/bin/bash


WITHTSCAN=0
WITHVALKUIL=0
WITHFOWLT=0
WITHTICCL=0
for OPT in "$@"
do
    if [[ "$OPT" == "tscan" ]]; then
        WITHTSCAN=1
    fi
    if [[ "$OPT" == "valkuil" ]]; then
        WITHVALKUIL=1
    fi
    if [[ "$OPT" == "fowlt" ]]; then
        WITHFOWLT=1
    fi
    if [[ "$OPT" == "ticcl" ]]; then
        WITHTICCL=1
    fi
done

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
    if [ $REPOCHANGED -eq 1 ] || [ $RECOMPILE -eq 1 ]; then
        bash bootstrap.sh || fatalerror "$project bootstrap failed"
        ./configure --prefix="$VIRTUAL_ENV" || fatalerror "$project configure failed"
        make || fatalerror "$project make failed"
        make install || fatalerror "$project make install failed"
    else
        echo "T-scan is already up to date ... "
    fi
    cd ..
fi


if [ $WITHVALKUIL -eq 1 ] || [ -d valkuil-gecco ]; then
    project="valkuil-gecco"
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
        ./download-models.sh
    else
        echo "Valkuil is already up to date ... "
    fi
    cd ..
fi

if [ $WITHFOWLT -eq 1 ] || [ -d fowlt-gecco ]; then
    project="fowlt-gecco"
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
        ./download-models.sh
    else
        echo "Fowlt is already up to date ... "
    fi
    cd ..
fi

if [ $WITHTICCL -eq 1 ] || [ -d TICCL ]; then
    project="TICCL"
    echo 
    echo "--------------------------------------------------------"
    echo "Installing $project">&2
    echo "--------------------------------------------------------"
    if [ ! -d $project ]; then
        git clone https://github.com/martinreynaert/$project
        cd $project
        REPOCHANGED=1
    else
        cd $project
        gitcheck
    fi
    if [ $REPOCHANGED -eq 1 ]; then
        if [ ! -d data ]; then
            wget http://ticclops.uvt.nl/TICCL.languagefiles.ALLavailable.20160421.tar.gz
            tar -xvzf TICCL.languagefiles.*.tar.gz
            rm TICCL.languagefiles.*.tar.gz
        fi
    else
        echo "TICCL is already up to date ... "
    fi
    TICCLDIR=`pwd`
    echo "(Note: TICCL root path is $TICCLDIR)"
    cd ..
    ln -sf $TICCLDIR/TICCLops.PICCL.pl ../bin/TICCLops.PICCL.pl
fi

