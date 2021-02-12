#!/bin/bash

if [ -e "{{lm_path}}/host_vars/{{hostname}}.yml" ]; then
    #LaMachine v2.1.0+
    CONFFILE="{{lm_path}}/host_vars/{{hostname}}.yml"
elif [ -e "{{lm_path}}/host_vars/localhost.yml" ]; then
    #fallback
    CONFFILE="{{lm_path}}/host_vars/localhost.yml"
fi

if [ -n "$1" ]; then
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        echo "Usage: ">&2
        echo "   lamachine-config key value                - Set a config value">&2
        echo "   lamachine-config key                      - Get a config value">&2
        echo "   lamachine-config --edit                   - Edit configuration interactively">&2
        echo "   lamachine-config --remoteservice name url - Add/edit a remote service">&2
        echo "   lamachine-config                          - Show entire configuration">&2
        exit 0
    elif [ "$1" = "-r" ] || [ "$1" = "--remoteservice" ]; then
        if [ -z "$2" ] || [ -z "$3" ]; then
            echo "Missing parameters: name url" >&2
            exit 2
        fi
        if grep -qe "^    $2:" "$CONFFILE"; then
            if ! sed -i.bak -e "s|^    $2:.*$|    $2: \"$3\"|g" "$CONFFILE"; then
                echo "Failed to update existing remote service $2" >&2
                exit 2
            fi
        else
            if ! sed -i.bak -e "/^remote_services:/a \ \ \ \ $2: \"$3\"" "$CONFFILE"; then
                echo "Failed to add a new remote service $2" >&2
                exit 2
            fi
        fi
    elif [ "$1" = "-e" ] || [ "$1" = "--edit" ]; then
        if [ -n "$EDITOR" ]; then
            $EDITOR "$CONFFILE" || exit $?
            cp -f "$CONFFILE" "{{lm_path}}/host_vars/localhost.yml"
        else
            nano "$CONFFILE" || exit $?
            cp -f "$CONFFILE" "{{lm_path}}/host_vars/localhost.yml"
        fi
    elif [ -n "$2" ]; then
        if echo "$2" | grep -qe "^[\[\{]"; then
            #literal array/dictionary
            VALUE=$2
        elif echo "$2" | grep -qe "[ /\?;'\!']"; then
            #string that needs to be escaped
            VALUE="\"$2\""
        else
            #scalar value
            VALUE=$2
        fi
        if grep -qe "^$1:.*$" "$CONFFILE"; then
            if ! sed -i.bak -e "s|^$1:.*$|$1: $VALUE|g" "$CONFFILE"; then
                echo "Failed to update existing config key $1" >&2
                exit 2
            fi
        else
            if ! echo "$1: $2" >> "$CONFFILE"; then
                echo "Failed to add new config key $1" >&2
                exit 3
            fi
        fi
        cp -f "$CONFFILE" "{{lm_path}}/host_vars/localhost.yml"
    else
        grep -e "^$1:" "$CONFFILE" || exit 1
        cp -f "$CONFFILE" "{{lm_path}}/host_vars/localhost.yml"
    fi
else
    cat "$CONFFILE" || exit 1
fi
