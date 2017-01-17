#!/bin/bash
#======================================
# LaMachine
#  by Maarten van Gompel
#  Centre for Language Studies
#  Radboud University Nijmegen
#
# https://proycon.github.io/LaMachine
# Licensed under GPLv3
#=====================================


#NOTE: Do not run this script directly!

echo "====================================================================="
echo "           ,              LaMachine - NLP Software distribution" 
echo "          ~)                     (http://proycon.github.io/LaMachine)"
echo "           (----í         Language Machines research group"
echo "            /| |\         & Centre of Language and Speech Technology"
echo "           / / /|	        Radboud University Nijmegen "
echo "====================================================================="
echo
echo "Bootstrapping Virtual Machine or Docker image...."
echo
sleep 1

fatalerror () {
    echo "================ FATAL ERROR ==============" >&2
    echo "An error occured during installation!!" >&2
    echo $1 >&2
    echo "===========================================" >&2
    echo $1 > error
    exit 2
}

error () {
    echo "================= ERROR ===================" >&2
    echo $1 >&2
    echo "===========================================" >&2
    echo $1 > error
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

outputgitversion () {
    git describe --tags >> "/VERSION"
    if [ $? -ne 0 ]; then
        git rev-parse HEAD >> "/VERSION"
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
    if [ ! -z ${INSTALLVERSION[$project]} ]; then
        #we were asked to install a very specific release
        if [ -f .version.lamachine ]; then
            CURRENTVERSION=$(cat .version.lamachine)
        fi
        ver=${INSTALLVERSION[$project]}
        if [[ "$CURRENTVERSION" == "$ver" ]]; then
            echo "   Already up to date on requested release: $ver"
            REPOCHANGED=0
        else
            echo "   Installing specific version for $project: $ver (this may likely be an older release!)"
            if [[ "${ver:0:1}" == "v" ]] || [[ $ver == *"."* ]]; then
                git checkout "tags/$ver" #will put us in detached head state
                if [ $? -ne 0 ]; then
                    gitstash 
                    git checkout "tags/$ver"
                    if [ $? -ne 0 ]; then
                        echo "   Unable to check out desired version, expected git tag $ver does not exist!"
                        exit 2
                    fi
                fi
            else
                #assuming this is a commit hash instead of a version
                git checkout "$ver" #will put us in detached head state
            fi
            echo "$ver" > .version.lamachine 
            REPOCHANGED=1
        fi
    else
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
    fi
}


switchaurversion () {
    if [ ! -z ${INSTALLVERSION[$project]} ]; then
        ver=${INSTALLVERSION[$project]}
        #find the commit hash for the specified version:
        if [[ "${ver:0:1}" == "v" ]]; then
            ver=${ver:1}
            reply=$(git grep "pkgver=$ver" $(git rev-list --all -- PKGBUILD) | head -n 1)
            if [ ! -z $reply ]; then
                commithash=${reply%%:*}
                git checkout $commithash || fatalerror "Unable to check out version $ver (commit $commithash) of package $package"
            else
                fatalerror "Unable to find version $ver of package $package"
            fi
        fi
    else
        git checkout master
        git pull
    fi
}

generaterequirements () {
    if [ ! -z ${INSTALLVERSION[$project]} ]; then
        echo -n "$project" >> requirements.txt
        ver=${INSTALLVERSION[$project]}
        if [ ${ver:0:1} == 'v' ]; then
            echo "==${ver:1}" >> requirements.txt
        else
            echo "==${ver}" >> requirements.txt
        fi
    else
        echo "$project" >> requirements.txt
    fi
}

umask u=rwx,g=rwx,o=rx

#arch linux image has a restrictive umask
sed -i 's/umask 027/umask 022/' /root/.profile
if [ -d /home/vagrant ]; then
    sed -i 's/umask 027/umask 022/' /home/vagrant/.profile
fi

sed -i s/lecture=once/lecture=never/ /etc/sudoers
echo "ALL            ALL = (ALL) NOPASSWD: ALL" >> /etc/sudoers

cd /usr/src/
SRCDIR=`pwd`

FORCE=0
DEV=0 #prefer stable releases
BRANCH="master"
if [ -f .dev ]; then
    DEV=1 #install development versions
else
    DEV=0 #install development versions
fi
if [ -f .private ]; then
    PRIVATE=1 #no not send simple analytics to Nijmegen
else
    PRIVATE=0 #send simple analytics to Nijmegen
fi
for OPT in "$@"
do
    if [[ "$OPT" == "force" ]]; then
        FORCE=1
    fi
    if [[ "$OPT" == "dev" ]]; then
        touch .dev
        DEV=1
    fi
    if [[ "$OPT" == "stable" ]]; then
        rm -f .dev
        DEV=0
    fi
    if [[ "$OPT" == "private" ]]; then
        touch .private
        PRIVATE=1
    fi
    if [[ "$OPT" == "sendinfo" ]]; then
        rm -f .private
        PRIVATE=0
    fi
    if [[ "${OPT:0:8}" == "version=" ]]; then
        VERSIONFILE=`realpath ${OPT:8}`
        DEV=0
    fi
    if [[ "${OPT:0:7}" == "branch=" ]]; then
        BRANCH=${OPT:7}
    fi
    if [[ "$OPT" == "help" ]] || [[ "$OPT" == "-h" ]]; then
        echo "Options (no hyphen preceeding any):"
        echo "  noadmin          - Skip global installation step for which administrative privileges are requires; presupposes that global dependencies are already installed by a system administrator"
        echo "  force            - Force recompilation/reinstallation of everything"
        echo "  nopythondeps     - Do not install/update 3rd party python packages (except those absolutely necessary)"
        echo "  stable           - Install latest stable releases of all software (default)"
        echo "  dev              - Install latest development releases of all software (this may break things)"
        echo "  version=<file>   - Install specific versions of all software, versions are in the specified file. LaMachine's generates a VERSION file on each installation/update that is valid input for this option."
        echo "  private          - Do not send anonymous statistics about this copy of LaMachine to Radboud University (opt-out)"
        echo "  branch=<branch>  - Use the following branch of the LaMachine git repository (default: master)"
        exit 0
    fi
done

if [ -d /vagrant ]; then
    VAGRANT=1
    cp /vagrant/motd /etc/motd
    FORM="vagrant"
else
    VAGRANT=0
    FORM="docker"
fi


echo "--------------------------------------------------------"
echo "[LaMachine] Installing global dependencies"
echo "--------------------------------------------------------"
#will run as root
echo "Conflict prevention..."
pacman --noconfirm -R virtualbox-guest-dkms
echo "Installing base-devel...."
pacman -Syu --noconfirm --needed base-devel || fatalerror "Unable to install global dependencies"
PKGS="pkg-config git autoconf-archive icu xml2 zlib libtar boost boost-libs cython python python-pip python-requests python-lxml python-pycurl python-virtualenv python-numpy python-scipy python-matplotlib python-pandas python-nltk python-scikit-learn python-psutil ipython jupyter-notebook wget curl libexttextcat python-flask python-requests python-requests-oauthlib python-requests-toolbelt python-crypto nginx uwsgi uwsgi-plugin-python hunspell aspell hunspell-en aspell-en perl perl-sort-naturally"
echo "Installing global packages: $PKGS"
pacman --noconfirm --needed -Syu $PKGS ||  fatalerror "Unable to install global dependencies"

if [ $PRIVATE -eq 0 ]; then
    #Sending some statistics to us so we know how often and on what systems LaMachine is used
    #recipient: Language Machines, Centre for Language Studies, Radboud University Nijmegen
    #
    #Transmitted are:
    # - The form in which you run LaMachine (vagrant/virtualenv/docker)
    # - Is it a new LaMachine installation or an update
    # - Stable or Development?
    #
    #This information will never be used for any form of advertising
    #Your IP will only be used to compute country of origin, resulting reports will never contain personally identifiable information

    if [ $DEV -eq 0 ]; then
        STABLEDEV="stable"
    else
        STABLEDEV="dev"
    fi
    if [ ! -d LaMachine ]; then
        MODE="new"
    else
        MODE="update"
    fi
    PYTHONVERSION=`python -c 'import sys; print(".".join(map(str, sys.version_info[:3])))'`
    wget -O - -q "http://applejack.science.ru.nl/lamachinetracker.php/$FORM/$MODE/$STABLEDEV/$PYTHONVERSION" >/dev/null
fi


useradd build 

chgrp build /usr/src
chmod g+ws /usr/src


echo "--------------------------------------------------------"
echo "Updating LaMachine itself (branch: $BRANCH)"
echo "--------------------------------------------------------"
if [ ! -d LaMachine ]; then
    git clone https://github.com/proycon/LaMachine --branch $BRANCH || fatalerror "Unable to clone git repo for LaMachine"
    cd LaMachine || fatalerror "No LaMachine dir?, git clone failed?"
else
    cd LaMachine
    OLDSUM=`sum bootstrap.sh`
    git pull
    NEWSUM=`sum bootstrap.sh`
    cp bootstrap.sh /usr/bin/lamachine-update.sh
    cp test.sh /usr/bin/lamachine-test.sh
    if [ "$OLDSUM" != "$NEWSUM" ]; then
        echo "----------------------------------------------------------------"
        echo "LaMachine has been updated with a newer version, restarting..."
        echo "----------------------------------------------------------------"
        sleep 3
        ./bootstrap.sh $@ 
        exit $?
    else
        echo "LaMachine is up to date..."
    fi
fi
cp bootstrap.sh /usr/bin/lamachine-update.sh
cp test.sh /usr/bin/lamachine-test.sh
cp nginx.mime.types /etc/nginx/
cp nginx.conf /etc/nginx/
cp webservices.service /usr/lib/systemd/system/
if [ ! -z "$VERSIONFILE" ]; then
    source ./loadversionfile.sh
fi
cd ..
chmod a+rx LaMachine

if [ ! -z "$VERSIONFILE" ]; then
    VERSIONFILE_BASENAME=`basename $VERSIONFILE`
    echo "================================================================================">&2
    echo "      LaMachine will install specific older versions ($VERSIONFILE_BASENAME)">&2
    echo "================================================================================">&2
    echo $VERSIONFILE_BASENAME > "/VERSION"
else
    if [ $DEV -eq 0 ]; then
        echo "================================================================================">&2
        echo "      LaMachine will install the latest stable releases">&2
        echo "================================================================================">&2
    else
        echo "================================================================================">&2
        echo "      LaMachine will install the very latest development versions">&2
        echo "================================================================================">&2
    fi
    date -u +%Y%m%d%H%M > "/VERSION"
fi


#development packages should end in -git , releases should not
if [ $DEV -eq 0 ]; then
    #Packages to install in stable mode:
    PACKAGES="ticcutils libfolia foliautils uctodata ucto timbl timblserver mbt mbtserver wopr-git frogdata frog ticcltools-git toad" #not everything is available as releases yet
else
    #Packages to install in development mode:
    PACKAGES="ticcutils-git libfolia-git foliautils-git uctodata-git ucto-git timbl-git timblserver-git mbt-git wopr-git frogdata-git frog-git toad-git ticcltools-git"
fi

for package in $PACKAGES; do
    project="${package%-git}"
    if [ ! -d $package ]; then
        echo "--------------------------------------------------------"
        echo "[LaMachine] Obtaining package $package (AUR) ..."
        echo "--------------------------------------------------------"
        git clone https://aur.archlinux.org/${package}.git
        cd $package || fatalerror "No such package, git clone $package failed?"
        if [ ! -z "$VERSIONFILE" ]; then
            if [[ "$package" == "${project}-git" ]]; then
                echo "Installing specific versions is not supported for $project, installing latest git release instead"
            else
                switchaurversion
            fi
        fi
    else
        cd $package
        cp -f PKGBUILD PKGBUILD.old
        if [ ! -z "$VERSIONFILE" ]; then
            switchaurversion
        else
            git checkout master
            git pull
        fi
        sudo -u build makepkg --nobuild #to get proper version
        diff PKGBUILD PKGBUILD.old >/dev/null
        DIFF=$?
        if [ $DIFF -eq 0 ]; then
            echo "--------------------------------------------------------"
            echo "[LaMachine] $project is already up to date..."
            echo "--------------------------------------------------------"
            if [ $FORCE -eq 0 ]; then
                continue
            fi
        fi
    fi 
    echo "--------------------------------------------------------"
    echo "[LaMachine] Installing $project ..."
    echo "--------------------------------------------------------"
    sudo -u build makepkg -s -f --noconfirm --needed --noprogressbar
    pacman -U --noconfirm --needed ${project}*.pkg.tar.xz || error "Installation of ${project} failed !!"
    echo -n "$project=" >> /VERSION
    cat PKGBUILD | grep "pkgver=" | sed 's/pkgver=/v/' >> /VERSION
    rm ${project}*.pkg.tar.xz
    cd ..
done

#echo "--------------------------------------------------------"
#echo "[LaMachine] Installing Python 2 packages"
#echo "--------------------------------------------------------"
#pip2 install pynlpl FoLiA-tools clam || error "Installation of one or more Python 2 packages failed !!"

PYPIPROJECTS="pynlpl FoLiA-tools python-ucto foliadocserve clam python3-timbl python-frog colibricore"

if [ ! -z "$PYPIPROJECTS" ]; then
    if [ -z "$VERSIONFILE" ]; then
        echo "--------------------------------------------------------"
        echo "Installing Python packages from PyPI (latest releases)"
        echo "--------------------------------------------------------"
        pip install -U $PYPIPROJECTS || error "Installation of one or more Python packages failed !!"
    else
        echo "--------------------------------------------------------"
        echo "Installing Python packages from PyPI (specific versions)"
        echo "--------------------------------------------------------"
        echo -n "" > requirements.txt
        for project in $PYPIPROJECTS; do
            generaterequirements
        done
        pip install -r requirements.txt || error "Installation of one or more Python packages failed !!"
    fi

    echo "--------------------------------------------------------"
    echo "Extracting version information for packages from PyPI"
    echo "--------------------------------------------------------"
    for project in $PYPIPROJECTS; do
        echo -n "$project=" >> "/VERSION"
        pip show $project | grep -e "^Version:" | sed 's/Version: /v/g' >> "/VERSION" 
    done
fi

echo "--------------------------------------------------------"
echo "[LaMachine] Installing CLAM webservices"
echo "--------------------------------------------------------"
project="clamservices"
if [ ! -d $project ]; then
    git clone https://github.com/proycon/$project
    chmod a+rx $project
    cd $project 
    gitcheck
else
    cd $project
    pwd
    gitcheck
fi
echo -n "$project=" >> /VERSION
outputgitversion
if [ $REPOCHANGED -eq 1 ]; then
    python setup.py install #extra run since python-daemon may will
    python setup.py install || error "setup.py install clamservices failed"
fi
cd ..

CLAMSERVICEDIR=`python -c 'import clamservices; print(clam.__path__[0])'`
if [ ! -z "$CLAMSERVICEDIR" ]; then
    ln -s $CLAMSERVICEDIR _clamservices #referenced from startwebservices.sh
fi


echo "--------------------------------------------------------"
echo "[LaMachine] Installing Gecco dependencies (3rd party)"
echo "--------------------------------------------------------"
pip install -U hunspell python-Levenshtein aspell-python-py3 || error "Installation of one or more Python 3 packages failed !!"


echo "--------------------------------------------------------"
echo "[LaMachine] Installing Gecco"
echo "--------------------------------------------------------"
project="gecco"
if [ ! -d $project ]; then
    git clone https://github.com/proycon/$project
    chmod a+rx $project
    cd $project 
    gitcheck
else
    cd $project
    pwd
    gitcheck
fi
if [ $REPOCHANGED -eq 1 ]; then
    python setup.py install || error "setup.py install gecco failed"
fi
cd ..

echo "--------------------------------------------------------"
echo "[LaMachine] Installing LuigiNLP"
echo "--------------------------------------------------------"
project="LuigiNLP"
if [ ! -d $project ]; then
    git clone https://github.com/LanguageMachines/$project
    chmod a+rx $project
    cd $project 
    gitcheck
else
    cd $project
    pwd
    gitcheck
fi
if [ $REPOCHANGED -eq 1 ]; then
    python setup.py install #extra run since python-daemon may will
    python setup.py install || error "setup.py install LuigiNLP failed"
fi
cd ..

cd $SRCDIR || fatalerror "Unable to go back to sourcedir"
. LaMachine/extra.sh $@ 

echo "--------------------------------------------------------"
echo "Outputting version information of all installed packages"
echo "--------------------------------------------------------"
cat /VERSION

lamachine-test.sh
if [ $VAGRANT -eq 1 ]; then
    echo "[LaMachine] Starting webserver and webservices"
    systemctl enable nginx #enable nginx on bootup for vagrant
    systemctl enable webservices #enable webservices on bootup for vagrant
    systemctl start nginx #start nginx
    systemctl start webservices #start webservices
fi
if [ $? -eq 0 ]; then
    echo "--------------------------------------------------------"
    echo "[LaMachine] All done!  "
    if [ $VAGRANT -eq 1 ]; then
        echo " .. Issue $ vagrant ssh to connect to your VM!"
        echo " or connect your browser to http://127.0.0.1:8080 for the webservices"
    else
        echo "IMPORTANT NOTE: You are most likely using docker, do not forget to commit the container state if you want to preserve this update !!"
    fi
    exit 0
else
    echo "--------------------------------------------------------"
    echo "LaMachine bootstrap FAILED because of failed tests!!!!"
    echo "--------------------------------------------------------"
    exit 1
fi
