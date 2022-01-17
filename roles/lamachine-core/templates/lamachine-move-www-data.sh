#!/bin/bash
if [ -d "{{data_path}}" ]; then
  rm -rf {{ www_data_path }}.bak >/dev/null 2>/dev/null
  if [ "{{www_data_path}}" != "{{data_path}}/www-data" ]; then
      if [ ! -e "{{data_path}}/www-data" ]; then
        echo "Moving www-data to external data volume... ({{data_path}}/www-data)">&2
        mv {{www_data_path}} {{data_path}}/www-data 2>/dev/null || mv {{www_data_path}} {{www_data_path}}.bak 2>/dev/null #in case move wasn't entirely succesful (due to permission denied error on removing)
        ln -sf {{data_path}}/www-data {{www_data_path}}
      else
        echo "External data volume already contains www-data! Refusing to overwrite, just linking to existing data...">&2
        mv {{www_data_path}} {{www_data_path}}.bak 2>/dev/null
        ln -sf {{data_path}}/www-data $LM_WWW_DATA_PATH
      fi
  fi
else
  echo "Data path {{data_path}} does not exist. Not moving www-data anywhere.">&2
fi
