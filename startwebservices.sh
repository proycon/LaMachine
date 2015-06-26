#!/bin/bash

#This script should be launched only from within the LaMachine VM or Docker app

uwsgi --socket :3031 --chdir /usr/src/clam/config --wsgi-file /usr/src/clam/config/ucto.wsgi --master --processes 1 --threads 2
uwsgi --socket :3032 --chdir /usr/src/clam/config --wsgi-file /usr/src/clam/config/frog.wsgi --master --processes 1 --threads 2
uwsgi --socket :3033 --chdir /usr/src/clam/config --wsgi-file /usr/src/clam/config/timbl.wsgi --master --processes 1 --threads 2
uwsgi --socket :3034 --chdir /usr/src/clam/config --wsgi-file /usr/src/clam/config/colibicore.wsgi --master --processes 1 --threads 2

sudo systemctl restart nginx
