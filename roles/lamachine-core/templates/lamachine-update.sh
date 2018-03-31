#!/bin/bash

# THIS FILE IS MANAGED BY LAMACHINE, DO NOT EDIT IT! (it will be overwritten on update)

if [ -e "{{lm_path}}" ]; then
  cd "{{lm_path}}"
else
  echo "The LaMachine control directory was not found.">&2
  echo "this generally means this lamachine installation is externally managed.">&2
  exit 2
fi
if [ ! touch .lastupdate ]; then
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
if [ -e "host_vars/localhost.yml" ]; then
    $EDITOR "host_vars/localhost.yml" && cp -f "host_vars/localhost.yml" "host_vars/lamachine-{{conf_name}}.yml"
else
    $EDITOR "host_vars/lamachine-{{conf_name}}.yml"
fi
$EDITOR "install-{{conf_name}}.yml"
FIRST=2
fi
OPTS=""
if [ {{root|int}} -eq 1 ]; then
 OPTS="--ask-become-pass"
fi
ansible-playbook -i "hosts.{{conf_name}}" "install-{{conf_name}}.yml" -v $OPTS --extra-vars "${*:$FIRST}" 2>&1 | tee "lamachine-{{conf_name}}.log"
