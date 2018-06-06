#!/bin/bash

# -- THIS SCRIPT IS MAINTAINED BY LAMACHINE; DO NOT EDIT IT -- it will be overwritten on update --

export LC_ALL=en_US.UTF-8

{{lm_prefix}}/bin/lamachine-stop-webserver #first we stop any running instances

{% if locality == "global" and root %}
#global flavour
if which systemctl >/dev/null 2>/dev/null; then
    HAVE_SYSTEMCTL=1
else
    HAVE_SYSTEMCTL=0 #If there is no systemd, assume init V and 'service' command, this is relevant also in most docker containers where systemd makes less sense
fi

#kill and restart uwsgi emperor
{% if ansible_distribution|lower == "debian" or ansible_distribution|lower == "ubuntu" or ansible_distribution|lower == "linux mint" %}
if [ $HAVE_SYSTEMCTL -eq 1 ]; then
     sudo systemctl enable uwsgi-emperor
     sudo systemctl start uwsgi-emperor
else
     sudo service uwsgi-emperor start
fi
{% else %}
     sudo uwsgi --ini "{{lm_prefix}}/etc/uwsgi-emperor/emperor.ini" --die-on-term &
{% endif %}

{% if  webservertype == "nginx" %}
if [ $HAVE_SYSTEMCTL -eq 1 ]; then
     sudo systemctl enable nginx
     sudo systemctl start nginx
else
     sudo service nginx start
fi
{% else %}
    echo "You are using a non-default webservertype, unable to manage webserver for you...">&2
{% endif %}



{% else %}
#local flavour

uwsgi --ini "{{lm_prefix}}/etc/uwsgi-emperor/emperor.ini" --die-on-term &

{% if webservertype == "nginx" %}
    nginx -c "{{lm_prefix}}/etc/nginx/nginx.conf" -p "{{lm_prefix}}"  -g "pid {{lm_prefix}}/var/run/nginx.pid;"
{% else %}
    echo "You are using a non-default webservertype, unable to manage webserver for you...">&2
{% endif %}


{% endif %}

if [ "$1" = "-f" ]; then
    #run in foreground/keep running (nginx error log)
    tail -F "{{lm_prefix}}/var/log/nginx/error.log"
fi
