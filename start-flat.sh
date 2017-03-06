#!/bin/bash
if [ ! -z "$VIRTUAL_ENV" ]; then
    mkdir $VIRTUAL_ENV/flat.docroot
    foliadocserve -d $VIRTUAL_ENV/flat.docroot --git --expirationtime 120 -p 3030 &
    export PYTHONPATH=$VIRTUAL_ENV/src/LaMachine
    export DJANGO_SETTINGS_MODULE=flat_settings
    django-admin runserver 127.0.0.1:8080
else
    echo "You are not in a LaMachine virtualenv" >&2
fi

