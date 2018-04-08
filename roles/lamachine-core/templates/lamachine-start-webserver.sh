#!/bin/bash

# -- THIS SCRIPT IS MAINTAINED BY LAMACHINE; DO NOT EDIT IT -- it will be overwritten on update --

{{lm_prefix}}/bin/lamachine-stop-webserver #first we stop any running instances

{% if locality == "global" and root %}
#global flavour

#kill and restart uwsgi emperor
{% if ansible_distribution|lower == "debian" or ansible_distribution|lower == "ubuntu" or ansible_distribution|lower == "linux mint" %}
 sudo systemctl enable uwsgi-emperor
 sudo systemctl start uwsgi-emperor
{% else %}
 sudo uwsgi --ini "{{lm_prefix}}/etc/uwsgi-emperor/emperor.ini" --die-on-term &
{% endif %}

{% if  webservertype == "nginx" %}
 sudo systemctl enable nginx
 sudo systemctl start nginx
{% endif %}


{% else %}
#local flavour

uwsgi --ini "{{lm_prefix}}/etc/uwsgi-emperor/emperor.ini" --die-on-term &

{% if webservertype == "nginx" %}
nginx -c "{{lm_prefix}}/etc/nginx.conf" -p "{{lm_prefix}}/share/nginx"  -g "pid {{lm_prefix}}/var/run/nginx.pid; worker_processes 2;"
{% endif %}


{% endif %}
