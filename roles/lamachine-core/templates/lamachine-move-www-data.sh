#!/bin/bash
if [ "{{www_data_path}}" != "{{www_data_staging_path}}" ]; then
  rm -rf "{{www_data_staging_path}}.bak" >/dev/null 2>/dev/null
  if [ ! -d "{{www_data_path}}" ] && [ -d "{{www_data_staging_path}}" ]; then
      echo "Moving www-data to final location (e.g. external data volume, {{www_data_path}})">&2
    mv "{{www_data_staging_path}}" "{{www_data_path}}" 2>/dev/null || mv "{{www_data_staging_path}}" "{{www_data_staging_path}}.bak" 2>/dev/null #in case move wasn't entirely succesful (due to permission denied error on removing)
    ln -s "{{www_data_path}}" "{{www_data_staging_path}}"
  elif [ -d "{{www_data_path}}" ] && [ ! -L "{{www_data_staging_path}}" ]; then
    echo "Final location {{www_data_path}} already contains has www-data! Refusing to overwrite, just linking to existing data...">&2
    mv "{{www_data_staging_path}}" "{{www_data_path}}" 2>/dev/null || mv "{{www_data_staging_path}}" "{{www_data_staging_path}}.bak" 2>/dev/null #in case move wasn't entirely succesful (due to permission denied error on removing)
    ln -s "{{www_data_path}}" "{{www_data_staging_path}}"
  else
      echo "www-data already exists in final location {{www_data_path}} (e.g external volume) and link was already established.. all ok">&2
  fi
else
    echo "www-data path is ok (staging location == final location)">&2
fi
