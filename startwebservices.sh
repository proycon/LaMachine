#!/bin/bash

#This script should be launched only from within the LaMachine VM or Docker app

CLAMFORCEURL=http://127.0.0.1:8080/ucto/ uwsgi --plugins python --socket :3031 --chdir /usr/src/clam/config --mount /ucto=/usr/src/clam/config/ucto.wsgi --manage-script-name --master --processes 1 --threads 2 &
CLAMFORCEURL=http://127.0.0.1:8080/frog/ uwsgi --plugins python --socket :3032 --chdir /usr/src/clam/config --mount /frog=/usr/src/clam/config/frog.wsgi  --manage-script-name --master --processes 1 --threads 2 &
CLAMFORCEURL=http://127.0.0.1:8080/timbl/ uwsgi --plugins python --socket :3033 --chdir /usr/src/clam/config --mount /timbl=/usr/src/clam/config/timbl.wsgi  --manage-script-name --master --processes 1 --threads 2 &
CLAMFORCEURL=http://127.0.0.1:8080/colibricore/ uwsgi --plugins python --socket :3034 --chdir /usr/src/clam/config --mount /colibricore=/usr/src/clam/config/colibricore.wsgi  --manage-script-name --master --processes 1 --threads 2 &

sudo systemctl restart nginx
