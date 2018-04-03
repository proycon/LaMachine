#!/bin/bash

# THIS FILE IS MANAGED BY LAMACHINE, DO NOT EDIT IT! (it will be overwritten on update)

if [ -e "{{lm_path}}" ]; then
  cd "{{lm_path}}"
else
  echo "The LaMachine control directory was not found.">&2
  echo "this generally means this lamachine installation is externally managed.">&2
  exit 2
fi
if ! touch .lastupdate; then
  echo "Insufficient permission to update">&2
  exit 2
fi
if [ -d .git ]; then
    git pull
fi
FIRST=1
if [ "$1" = "--edit" ]; then
if [ -z "$EDITOR" ]; then
  export EDITOR=nano
fi
if [ -e "host_vars/{{hostname}}.yml" ]; then
    #LaMachine v2.1.0+
    $EDITOR "host_vars/{{hostname}}.yml"
elif [ -e "host_vars/localhost.yml" ]; then
    #fallback
    $EDITOR "host_vars/localhost.yml"
elif [ -e "host_vars/lamachine-$LM_NAME.yml" ]; then
    #LaMachine v2.0.0
    $EDITOR "host_vars/lamachine-$LM_NAME.yml"
fi
if [ -e "hosts.{{conf_name}}" ]; then
    #LaMachine v2.0.0
    $EDITOR "install-{{conf_name}}.yml"
else
    #LaMachine v2.1.0+
    $EDITOR "install.yml"
fi
FIRST=2
fi
OPTS=""
if [ {{root|int}} -eq 1 ]; then
 OPTS="--ask-become-pass"
fi
if [ -e "hosts.{{conf_name}}" ]; then
    #LaMachine v2.0.0
    ansible-playbook -i "hosts.{{conf_name}}" "install-{{conf_name}}.yml" -v $OPTS --extra-vars "${*:$FIRST}" 2>&1 | tee "lamachine-{{conf_name}}.log"
else
    #LaMachine v2.1.0+
    ansible-playbook -i "hosts.ini" "install.yml" -v $OPTS --extra-vars "${*:$FIRST}" 2>&1 | tee "lamachine-{{conf_name}}.log"
fi
