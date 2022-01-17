#!/bin/bash

# -- THIS SCRIPT IS MAINTAINED BY LAMACHINE; DO NOT EDIT IT -- it will be overwritten on update --

for arg in "$@"; do
    if [ "$arg" = "-h" ] || [ "$arg" == "--help" ]; then
        echo "Usage: lamachine-start-webserver [options]" >&2
        echo "Options:" >&2
        echo " -f     Start in foreground, do not exit. In a docker context" >&2
        echo "        this also makes this a valid process to use as the entrypoint," >&2
        echo "        i.e. to run as PID 1">&2
        exit 0
    fi
done

export LC_ALL=en_US.UTF-8

if [ -f /.dockerenv ] || grep -q 'devices:/docker' /proc/1/cgroup >/dev/null 2>/dev/null; then
    IS_DOCKER=1
else
    IS_DOCKER=0
fi

bold=$(tput bold 2>/dev/null)
boldred=${bold}$(tput setaf 1 2>/dev/null) #  red
boldgreen=${bold}$(tput setaf 2 2>/dev/null) #  green
green=${normal}$(tput setaf 2 2>/dev/null) #  green
yellow=${normal}$(tput setaf 3 2>/dev/null) #  yellow
blue=${normal}$(tput setaf 4 2>/dev/null) #  blue
boldblue=${bold}$(tput setaf 4 2>/dev/null) #  blue
boldyellow=${bold}$(tput setaf 3 2>/dev/null) #  yellow
normal=$(tput sgr0 2>/dev/null)


if [ -z "$LM_PREFIX" ]; then
    if [ -e /etc/profile.d/lamachine-activate.sh ]; then
        #will work for docker and other global installations
        source /etc/profile.d/lamachine-activate.sh
    elif [ -e "{{lm_prefix}}/bin/activate" ]; then
        source "{{lm_prefix}}/bin/activate"
    else
        echo "${boldred}ERROR: First activate your LaMachine environment before running this script! Automatic activation failed${normal}">&2
        exit 2
    fi
fi

{{lm_prefix}}/bin/lamachine-stop-webserver #first we stop any running instances

{% if locality == "global" and root %}
#### global flavour ##############################################################################################################

{% if move_share_www_data|bool %}
{{lm_prefix}}/bin/lamachine-move-www-data
{% endif %}

if [ ! -d "{{www_data_path}}" ]; then
    echo "${boldred}ERROR: www-data path {{www_data_path}} was not found, did you perhaps forget to mount an external data volume at {{data_path}}?${normal}" >&2
    exit 3
fi

if systemctl is-system-running >/dev/null 2>/dev/null; then
    echo "(systemd is available and running)">&2
    HAVE_SYSTEMCTL=1
else
    echo "(systemd is not available, falling back to alternatives)">&2
    HAVE_SYSTEMCTL=0 #If there is no systemd, assume init V and 'service' command, this is relevant also in most docker containers where systemd makes less sense
fi

#kill and restart uwsgi emperor
{% if ansible_distribution|lower == "debian" or ansible_distribution|lower == "ubuntu" or ansible_distribution|lower == "linux mint" %}
if [ $HAVE_SYSTEMCTL -eq 1 ]; then
     sudo systemctl enable uwsgi-emperor
     sudo systemctl start uwsgi-emperor
     sudo systemctl start cron
else
     sudo service uwsgi-emperor start
     sudo service cron start
fi
{% else %}
     sudo uwsgi --ini "{{lm_prefix}}/etc/uwsgi-emperor/emperor.ini" --die-on-term 2> "{{lm_prefix}}/var/log/uwsgi/uwsgi.log" >&2 &
     echo "Note: UWSGI emperor log can be found in {{lm_prefix}}/var/log/uwsgi/uwsgi.log"
{% endif %}

{% if  webservertype == "nginx" %}
if [ $HAVE_SYSTEMCTL -eq 1 ]; then
     sudo systemctl enable nginx
     sudo systemctl start nginx
     sudo systemctl start cron
else
     sudo service nginx start
     sudo service cron start
fi
{% else %}
    echo "${boldred}WARNNG: You are using a non-default webservertype, unable to manage webserver for you...${normal}">&2
{% endif %}



{% else %}
#### local flavour ##############################################################################################################


echo "${bold}Starting uwsgi applications${normal}..."
uwsgi --ini "{{lm_prefix}}/etc/uwsgi-emperor/emperor.ini" --die-on-term 2> "{{lm_prefix}}/var/log/uwsgi/uwsgi.log" >&2 &

{% if webservertype == "nginx" %}
 NGINX=$(which nginx)
 if [ -z "$NGINX" ]; then
    echo "${boldred}ERROR: Nginx not found! This should not happen unless you explicitly opted out of installing a webserver.${normal}">&2
    exit 2
 fi
 echo "${bold}Starting nginx webserver${normal}..."
 {% if http_port|int < 1024 %}
    echo "${boldyellow}You are using a running the webserver on a privileged port {{http_port}}, sudo required to start${normal}">&2
    sudo $NGINX -c "{{lm_prefix}}/etc/nginx/nginx.conf" -p "{{lm_prefix}}"  -g "pid {{lm_prefix}}/var/run/nginx.pid;" #we pass the full NGINX binary as sudoing causes us to lose our virtualenv!
 {% else %}
    $NGINX -c "{{lm_prefix}}/etc/nginx/nginx.conf" -p "{{lm_prefix}}"  -g "pid {{lm_prefix}}/var/run/nginx.pid;"
 {% endif %}
{% else %}
    echo "${boldred}WARNING: You are using a non-default webservertype, unable to manage webserver for you...${normal}">&2
{% endif %}



echo "Note: UWSGI emperor log can be found in {{lm_prefix}}/var/log/uwsgi/uwsgi.log"
echo "      Nginx logs can be found in {{lm_prefix}}/var/log/nginx/"
echo
{% endif %}

{% if lab %}
 echo "${bold}Starting Jupyter Hub...${normal}"
 killall jupyterhub 2> /dev/null
 cd "{{www_data_path}}"
 jupyterhub -f {{lm_prefix}}/etc/jupyterhub_config.py >/dev/null 2>"{{lm_prefix}}/var/log/jupyterhub.log" &
 echo "Note:     Jupyter Hub logs can be found in {{lm_prefix}}/var/log/jupyterhub.log"
 cd -
{% endif %}


if [ -d "{{lm_prefix}}/opt/spotlight" ]; then
    echo "${bold}Note:${normal} The DBPedia Spotlight service is installed but never started automatically,"
    echo " if you want to use it you will need to start it manually using"
    echo " 'spotlight \$langcode' where \$langcode corresponds to the language you want to serve."
fi

echo "${boldyellow}Note: It is not recommended to expose this server directly to the public internet due to there not being proper authentication on all services (unless you explicitly provided it).${normal}"

echo

echo "${boldgreen}If no errors were reported above, the webserver should now be started"
echo "and accessible on port {{http_port}}.${normal}"
echo "If you have LaMachine running in a Virtual Machine or container,"
echo "you can use the mapped port ({{mapped_http_port}}) directly from your host system ( http://127.0.0.1:{{mapped_http_port}} )."

FOREGROUND=0
for arg in "$@"; do
    if [ "$arg" = "-f" ]; then
        FOREGROUND=1
    fi
done

if [ $FOREGROUND -eq 1 ]; then
    if [ $IS_DOCKER -eq 1 ]; then
        #we are a docker container, replace current pid (should be 1) with the container init script that will reap children when we exit
        tail -F "{{lm_prefix}}/var/log/nginx/error.log" & #background
        exec $LM_PREFIX/bin/docker-container-init
    else
        #run in foreground/keep running (nginx error log)
        tail -F "{{lm_prefix}}/var/log/nginx/error.log"
    fi
fi
