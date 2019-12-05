#!/bin/bash

# -- THIS SCRIPT IS MAINTAINED BY LAMACHINE; DO NOT EDIT IT -- it will be overwritten on update --

{% if locality == "global" and root %}
#global flavour
if systemctl is-system-running >/dev/null 2>/dev/null; then
    HAVE_SYSTEMCTL=1
else
    HAVE_SYSTEMCTL=0 #If there is no systemd, assume init V, this is relevant also in most docker containers where systemd makes less sense
fi

#kill and restart uwsgi emperor
{% if ansible_distribution|lower == "debian" or ansible_distribution|lower == "ubuntu" or ansible_distribution|lower == "linux mint" %}
if [ $HAVE_SYSTEMCTL -eq 1 ]; then
     sudo systemctl stop uwsgi-emperor
else
     sudo service uwsgi-emperor stop
fi
{% else %}
 sudo killall -w uwsgi 2>/dev/null
{% endif %}

{% if  webservertype == "nginx" %}
if [ $HAVE_SYSTEMCTL -eq 1 ]; then
     sudo systemctl stop nginx
else
     sudo service nginx stop
fi
{% endif %}


{% else %}
#local flavour

#kill and restart uwsgi emperor
killall -w uwsgi 2>/dev/null

{% if webservertype == "nginx" %}
killall -w nginx 2>/dev/null
{% endif %}

{% if lab %}
killall jupyter-lab 2> /dev/null
{% endif %}


{% endif %}
