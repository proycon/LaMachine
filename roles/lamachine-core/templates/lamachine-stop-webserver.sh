#!/bin/bash

# -- THIS SCRIPT IS MAINTAINED BY LAMACHINE; DO NOT EDIT IT -- it will be overwritten on update --

{% if locality == "global" and root %}
#global flavour

#kill and restart uwsgi emperor
{% if ansible_distribution|lower == "debian" or ansible_distribution|lower == "ubuntu" or ansible_distribution|lower == "linux mint" %}
 sudo systemctl stop uwsgi-emperor
{% else %}
 sudo killall -w uwsgi
{% endif %}

{% if  webservertype == "nginx" %}
 sudo systemctl stop nginx
{% endif %}


{% else %}
#local flavour

#kill and restart uwsgi emperor
killall -w uwsgi

{% if webservertype == "nginx" %}
killall -w nginx
{% endif %}

{% endif %}
