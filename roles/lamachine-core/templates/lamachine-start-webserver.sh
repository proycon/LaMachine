#!/bin/bash

# -- THIS SCRIPT IS MAINTAINED BY LAMACHINE; DO NOT EDIT IT -- it will be overwritten on update --

export LC_ALL=en_US.UTF-8

{{lm_prefix}}/bin/lamachine-stop-webserver #first we stop any running instances

{% if locality == "global" and root %}
#### global flavour ##############################################################################################################
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
     sudo uwsgi --ini "{{lm_prefix}}/etc/uwsgi-emperor/emperor.ini" --die-on-term 2> "{{lm_prefix}}/var/log/uwsgi/uwsgi.log" >&2 &
     echo "Note: UWSGI emperor log can be found in {{lm_prefix}}/var/log/uwsgi/uwsgi.log"
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
#### local flavour ##############################################################################################################

if [ -z "$LM_PREFIX" ]; then
    echo "ERROR: First activate your LaMachine environment before running this script!">&2
    exit 2
fi

echo "Starting uwsgi..."
uwsgi --ini "{{lm_prefix}}/etc/uwsgi-emperor/emperor.ini" --die-on-term 2> "{{lm_prefix}}/var/log/uwsgi/uwsgi.log" >&2 &

{% if webservertype == "nginx" %}
 NGINX=$(which nginx)
 if [ -z "$NGINX" ]; then
    echo "ERROR: Nginx not found! This should not happen unless you explicitly opted out of installing a webserver.">&2
    exit 2
 fi
 echo "Starting nginx..."
 {% if http_port|int < 1024 %}
    echo "You are using a running the webserver on a privileged port {{http_port}}, sudo required to start">&2
    sudo $NGINX -c "{{lm_prefix}}/etc/nginx/nginx.conf" -p "{{lm_prefix}}"  -g "pid {{lm_prefix}}/var/run/nginx.pid;" #we pass the full NGINX binary as sudoing causes us to lose our virtualenv!
 {% else %}
    $NGINX -c "{{lm_prefix}}/etc/nginx/nginx.conf" -p "{{lm_prefix}}"  -g "pid {{lm_prefix}}/var/run/nginx.pid;"
 {% endif %}
{% else %}
    echo "You are using a non-default webservertype, unable to manage webserver for you...">&2
{% endif %}



echo "Note: UWSGI emperor log can be found in {{lm_prefix}}/var/log/uwsgi/uwsgi.log"
echo "      Nginx logs can be found in {{lm_prefix}}/var/log/nginx/"
{% endif %}

{% if lab %}
echo "Starting Jupyter Lab..."
killall jupyter-lab 2> /dev/null
cd "{{data_path}}"
jupyter lab --no-browser --config={{lm_prefix}}/etc/jupyter_notebook_config.py >/dev/null 2>{{lm_prefix}}/var/log/jupyterlab.log &
echo "Note:     Jupyter Lab logs can be found in {{lm_prefix}}/var/log/jupyterlab.log"
cd -
{% endif %}


if [ -d {{lm_prefix}}/opt/spotlight ]; then
    echo "Note: The DBPedia Spotlight service is installed but never started automatically, if you want to use it you will need to start it manually using 'spotlight \$langcode' where \$langcode corresponds to the language you want to serve."
fi


if [ "$1" = "-f" ]; then
    #run in foreground/keep running (nginx error log)
    tail -F "{{lm_prefix}}/var/log/nginx/error.log"
fi
