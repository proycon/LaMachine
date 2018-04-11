#!/bin/bash

# THIS FILE IS MANAGED BY LAMACHINE, DO NOT EDIT IT! (it will be overwritten on update)

if [[ ! -z "$VIRTUAL_ENV" ]] && [[ "$VIRTUAL_ENV" != "$LM_LOCAL_PREFIX" ]]; then
    #We seem to already be in a virtualenv (possibly the LaMachine controller!) deactivate it first
    if which deactivate >/dev/null; then
        echo "(Deactivating $VIRTUAL_ENV first)">&2
        deactivate
    fi
fi
if [[ ! -z "$CONDA_PREFIX" ]]; then
  echo "You seem to be in an Anaconda environment already (\$CONDA_PREFIX=$CONDA_PREFIX)">&2
  echo "This may interfere with LaMachine. Attempting to deactivate it automatically">&2
  source deactivate || echo "ERROR: DEACTIVATION OF ANACONDA FAILED! Continuing anyway but this may cause unexpected problems!">&2
fi
if [[ "$PATH" == *"lamachine-controller"* ]]; then
    export PATH=${PATH/lamachine-controller/DISABLED} #extra fallback to ensure the controller environment is not active
fi
export LM_NAME="{{conf_name}}"
export LM_LOCALITY="{{locality}}"
export LM_GLOBAL_PREFIX="{{global_prefix}}"
export LM_LOCALENV_TYPE="{{localenv_type}}"
export LM_DATA_PATH="{{data_path}}"
export LM_SOURCEPATH="{{source_path}}"
unset PYTHONPATH #would most likely mess thing up otherwise
if [[ "{{ ansible_distribution|lower }}" == "macosx" ]]; then
export CLANG_CXX_LIBRARY="libc++" #needed for python bindings in lamachine-python-install
   export MACOSX_DEPLOYMENT_TARGET="{{ ansible_distribution_version }}"
fi
if [[ "$LM_LOCALITY" == "local" ]]; then
    export LM_LOCAL_PREFIX={{local_prefix}}
    export LM_PREFIX={{local_prefix}}
    export LM_OLD_PS1="$PS1"
    if [ -d $LM_LOCAL_PREFIX ]; then
        if [[ "$LM_LOCALENV_TYPE" == "conda" ]]; then
            source activate lamachine-{{conf_name}}
            export VIRTUAL_ENV=$LM_LOCAL_PREFIX #backward compatibility
        else
            source "$LM_LOCAL_PREFIX/bin/activate"
        fi
    fi
else
    export LM_PREFIX="{{global_prefix}}"
    for f in "$(find $LM_PREFIX/bin/activate.d -type f -name '*.sh' -print -quit)"; do
        if [ ! -z "$f" ]; then
            source $f
        fi
    done
fi
if [[ "$LAMACHINE_QUIET" != "1" ]]; then
  cat $LM_PREFIX/etc/motd
fi
if [[ "$LM_LOCALITY" == "local" ]] && [[ "$LM_LOCALENV_TYPE" == "virtualenv" ]]; then
    if [ -z "$SOURCED" ]; then #protection against endless recursion
      SOURCED=0
      if [ -n "$ZSH_EVAL_CONTEXT" ]; then
        case $ZSH_EVAL_CONTEXT in *:file) SOURCED=1;; esac
      elif [ -n "$BASH_VERSION" ]; then
        [ "$0" != "$BASH_SOURCE" ] && SOURCED=1
      else # All other shells: examine $0 for known shell binary filenames
        # Detects `sh` and `dash`; add additional shell filenames as needed.
        case ${0##*/} in sh|dash) SOURCED=1;; esac
      fi
      if [[ "$SOURCED" -eq 0 ]]; then
        #not SOURCED, start a subshell
        export PS1="(`basename \"$VIRTUAL_ENV\"`) \u@\h:\W\$ " #set prompt manually cause it somehow gets messed up otherwise
        export SOURCED
        bash --norc --noprofile
      fi
    fi
fi
