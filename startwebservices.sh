#!/bin/bash

#This script should be launched only from within the LaMachine VM or Docker app
if [ ! -z "$1" ]; then
    PORT=$1
else
    PORT=8080
fi



CLAMFORCEURL=http://127.0.0.1:$PORT/ucto/ uwsgi --plugins python --socket :3031 --chdir /usr/src/_clamservices/wsgi --mount /ucto=/usr/src/_clamservices/wsgi/ucto.wsgi --manage-script-name --master --processes 1 --threads 2 &
CLAMFORCEURL=http://127.0.0.1:$PORT/frog/ uwsgi --plugins python --socket :3032 --chdir /usr/src/_clamservices/wsgi --mount /frog=/usr/src/_clamservices/wsgi/frog.wsgi  --manage-script-name --master --processes 1 --threads 2 &
CLAMFORCEURL=http://127.0.0.1:$PORT/timbl/ uwsgi --plugins python --socket :3033 --chdir /usr/src/_clamservices/wsgi --mount /timbl=/usr/src/_clamservices/wsgi/timbl.wsgi  --manage-script-name --master --processes 1 --threads 2 &
CLAMFORCEURL=http://127.0.0.1:$PORT/colibricore/ uwsgi --plugins python --socket :3034 --chdir /usr/src/_clamservices/wsgi --mount /colibricore=/usr/src/_clamservices/wsgi/colibricore.wsgi  --manage-script-name --master --processes 1 --threads 2 &
pkill -9 foliadocserve
cd #change path so the log file can be written
foliadocserve -d /var/flat.docroot --git --expirationtime 120 -p 3030 &
cd -
export PYTHONPATH=/usr/src/LaMachine
uwsgi --plugins python --socket :3035 --chdir /usr/src/LaMachine --mount /flat=/usr/src/LaMachine/flat.wsgi  --manage-script-name --master --processes 1 --threads 2 &

if [ -d /vagrant ]; then
    sudo systemctl restart nginx
else
    nginx
fi
