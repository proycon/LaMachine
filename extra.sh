#!/bin/bash

gitcheck () {
    git remote update
    LOCAL=$(git rev-parse @)
    REMOTE=$(git rev-parse @{u})
    BASE=$(git merge-base @ @{u})

    if [ -f error ]; then
        echo "Encountered an error last time, need to recompile"
        rm error
        REPOCHANGED=1
    elif [ $LOCAL = $REMOTE ]; then
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
