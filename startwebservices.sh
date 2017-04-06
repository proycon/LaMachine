#!/bin/bash

#This script should be launched only from within the LaMachine VM or Docker app
if [ ! -z "$1" ]; then
    BASEURL=$1
else
    BASEURL="http://127.0.0.1:8080"
fi

if [ ! -z "$VIRTUAL_ENV" ]; then
    echo "--------------------------------------- IMPORTANT NOTICE ---------------------------------------------------------------------------------------"
    echo "You are running startwebservices from within a LaMachine virtual environment, this is probably not what you want. ">&2
    echo "Start individual webservices on a per-webservice basis *for testing only* with: clamservice yourwebservice  (see LaMachine documentation) ">&2
    echo "For production environments, you will have to manually set up the webservices by starting the relevant uwsgi process and setting">&2
    echo "up an uwsgi_proxy from your webservice configuration (See the CLAM documentation for CLAM webservices)">&2
    echo "------------------------------------------------------------------------------------------------------------------------------------------------"
    BASEDIR="$VIRTUAL_ENV"
    VARDIR="$VIRTUAL_ENV"
else
    BASEDIR="/usr/src"
    VARDIR="/var"
fi


CLAMFORCEURL=$BASEURL/ucto/ uwsgi --plugins python --socket :3031 --chdir $BASEDIR/_clamservices/wsgi --mount /ucto=$BASEDIR/_clamservices/wsgi/ucto.wsgi --manage-script-name --master --processes 1 --threads 2 &
CLAMFORCEURL=$BASEURL/frog/ uwsgi --plugins python --socket :3032 --chdir $BASEDIR/_clamservices/wsgi --mount /frog=$BASEDIR/_clamservices/wsgi/frog.wsgi  --manage-script-name --master --processes 1 --threads 2 &
CLAMFORCEURL=$BASEURL/timbl/ uwsgi --plugins python --socket :3033 --chdir $BASEDIR/_clamservices/wsgi --mount /timbl=$BASEDIR/_clamservices/wsgi/timbl.wsgi  --manage-script-name --master --processes 1 --threads 2 &
CLAMFORCEURL=$BASEURL/colibricore/ uwsgi --plugins python --socket :3034 --chdir $BASEDIR/_clamservices/wsgi --mount /colibricore=$BASEDIR/_clamservices/wsgi/colibricore.wsgi  --manage-script-name --master --processes 1 --threads 2 &
if [ -d $VARDIR/piccldata ]; then
    #we only do PICCL if the data for it has been initialised
    CLAMFORCEURL=$BASEURL/piccl/ uwsgi --plugins python --socket :3036 --chdir $BASEDIR/PICCL/webservice --mount /PICCL=$BASEDIR/PICCL/webservice/picclservice/picclservice.wsgi  --manage-script-name --master --processes 1 --threads 2 &
fi
pkill -9 foliadocserve
cd #change path so the log file can be written
foliadocserve -d $VARDIR/flat.docroot --expirationtime 120 -p 3030 &
cd -
export PYTHONPATH=$BASEDIR/LaMachine
uwsgi --plugins python --socket :3035 --chdir $BASEDIR/LaMachine --mount /flat=$BASEDIR/LaMachine/flat.wsgi  --manage-script-name --master --processes 1 --threads 2 &

if [ -d /vagrant ]; then
    sudo systemctl restart nginx
elif [ -z "$VIRTUAL_ENV" ]; then
    nginx
else
    echo "The webservices have been started but you still need to configure your webservice to actually access them! See $BASEDIR/LaMachine/nginx.conf for an example using nginx">&2
fi
