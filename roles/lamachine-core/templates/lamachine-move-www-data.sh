#!/bin/bash
if [ "{{www_data_path}}" != "{{lm_prefix}}/var/www-data" ]; then
  rm -rf "{{ lm_prefix }}/var/www-data.bak" >/dev/null 2>/dev/null
  if [ ! -d "{{www_data_path}}" ] && [ -d "{{ lm_prefix }}/var/www-data" ]; then
    echo "Moving www-data to external data volume... ({{data_path}}/www-data)">&2
    mv "{{lm_prefix}}/var/www-data" "{{data_path}}/www-data" 2>/dev/null || mv "{{lm_prefix}}/var/www-data" "{{lm_prefix}}/var/www-data.bak" 2>/dev/null #in case move wasn't entirely succesful (due to permission denied error on removing)
    ln -s "{{www_data_path}}" "{{lm_prefix}}/var/www-data"
  elif [ -d "{{www_data_path}}" ] && [ ! -L "{{ lm_prefix }}/var/www-data" ]; then
    echo "External data volume already contains www-data! Refusing to overwrite, just linking to existing data...">&2
    mv "{{lm_prefix}}/www-data" "{{data_path}}/www-data" 2>/dev/null || mv "{{lm_prefix}}/var/www-data" "{{lm_prefix}}/var/www-data.bak" 2>/dev/null #in case move wasn't entirely succesful (due to permission denied error on removing)
    ln -s "{{www_data_path}}" "{{lm_prefix}}/var/www-data"
  else
    echo "www-data already exists in on external volume and link was already established.. all ok">&2
  fi
fi
