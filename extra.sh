#!/bin/bash


WITHTSCAN=0
WITHVALKUIL=0
WITHFOWLT=0
WITHFOLIAENTITY=0
WITHALPINO=0
for OPT in "$@"
do
    if [[ "$OPT" == "tscan" ]] || [[ "$OPT" == "all" ]]; then
        WITHTSCAN=1
        WITHALPINO=1
    fi
    if [[ "$OPT" == "valkuil" ]] || [[ "$OPT" == "all" ]]; then
        WITHVALKUIL=1
    fi
    if [[ "$OPT" == "fowlt" ]] || [[ "$OPT" == "all" ]]; then
        WITHFOWLT=1
    fi
    if [[ "$OPT" == "foliaentity" ]] || [[ "$OPT" == "all" ]]; then
        WITHFOLIAENTITY=1
    fi
    if [[ "$OPT" == "alpino" ]] || [[ "$OPT" == "all" ]]; then
        WITHALPINO=1
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
    if [ ! -z "$VIRTUAL_ENV" ]; then
        echo -n "tscan=" >> "$VIRTUAL_ENV/VERSION"
    else
        echo -n "tscan=" >> "/VERSION"
    fi
    outputgitversion
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
    if [ ! -z "$VIRTUAL_ENV" ]; then
        echo -n "valkuil-gecco=" >> "$VIRTUAL_ENV/VERSION"
    else
        echo -n "valkuil-gecco=" >> "/VERSION"
    fi
    outputgitversion
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
    if [ ! -z "$VIRTUAL_ENV" ]; then
        echo -n "fowlt-gecco=" >> "$VIRTUAL_ENV/VERSION"
    else
        echo -n "fowlt-gecco=" >> "/VERSION"
    fi
    outputgitversion
    if [ $REPOCHANGED -eq 1 ]; then
        ./download-models.sh
    else
        echo "Fowlt is already up to date ... "
    fi
    cd ..
fi


if [ $WITHFOLIAENTITY -eq 1 ] || [ -d ../foliaentity ] || [ -d /opt/foliaentity ]; then
    echo "--------------------------------------------------------"
    echo "Installing FoliaEntity">&2
    echo "--------------------------------------------------------"
    echo " (Note that this is a binary release that might not work on all platforms!)">&2
    srcdir=$(pwd)
    if [ ! -z "$VIRTUAL_ENV" ]; then
        cd ..
    else
        cd /opt
    fi
    if [ ! -d foliaentity ]; then
        mkdir foliaentity
    fi
    cd foliaentity
    rm entity-pack.tar.gz 2>/dev/null >/dev/null
    wget https://www.dropbox.com/s/5rrk7f8wcplchlo/entity-pack.tar.gz #download from Nederlab dropbox (binary!)
    tar -xvzf entity-pack.tar.gz
    cd $srcdir #back to src/ dir
fi

if [ $WITHALPINO -eq 1 ] || [ -d ../Alpino ] || [ -d /opt/Alpino ]; then
    echo "--------------------------------------------------------"
    echo "Installing Alpino">&2
    echo "--------------------------------------------------------"
    echo " (Note that this is a binary release that might not work on all platforms!)">&2
    srcdir=$(pwd)
    if [ ! -z "$VIRTUAL_ENV" ]; then
        cd ..
    else
        cd /opt
    fi
    if [ ! -d Alpino ] || [ $FORCE -eq 1 ]; then
        wget http://www.let.rug.nl/vannoord/alp/Alpino/versions/binary/latest.tar.gz
        tar -xvzf latest.tar.gz
        rm latest.tar.gz
        cd Alpino
        ALPINO_HOME=`realpath .`
        if [ ! -z "$VIRTUAL_ENV" ]; then
            echo "export ALPINO_HOME=\"$ALPINO_HOME\"" > $VIRTUAL_ENV/bin/extraactivate.alpino.sh
            echo "export TCL_LIBRARY=\"\$ALPINO_HOME/create_bin/tcl8.5\"" >> $VIRTUAL_ENV/bin/extraactivate.alpino.sh
            echo "export TCLLIBPATH=\"\$ALPINO_HOME/create_bin/tcl8.5\"" >> $VIRTUAL_ENV/bin/extraactivate.alpino.sh
            chmod a+x $VIRTUAL_ENV/bin/extraactivate.alpino.sh
            BASEDIR=$VIRTUAL_ENV
        else
            BASEDIR=/usr/
        fi
        echo "#!/bin/bash" > $BASEDIR/bin/Alpino
        echo "export ALPINO_HOME=\"$ALPINO_HOME\"" >> $BASEDIR/bin/Alpino
        echo "\$ALPINO_HOME/bin/Alpino $@" >> $BASEDIR/bin/Alpino
        echo "exit \$?" >> $BASEDIR/bin/Alpino
        chmod a+x $BASEDIR/bin/Alpino
    else
        cd Alpino
        ALPINO_HOME=`realpath .`
        echo "--> NOTE: Alpino is already installed and can not be upgraded automatically, if you want to force an update, first delete $ALPINO_HOME or pass the 'force' parameter....">&2
    fi
    cd $srcdir #back to src/ dir
fi
