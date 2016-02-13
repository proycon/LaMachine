#!/bin/bash


WITHTSCAN=0
WITHVALKUIL=0
WITHFOWLT=0
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
        ./configure --prefix=$VIRTUAL_ENV || fatalerror "$project configure failed"
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
