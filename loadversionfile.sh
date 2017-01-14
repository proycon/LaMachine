#!/bin/bash
declare -A INSTALLVERSION
if [ -f "$VERSIONFILE" ]; then
    firstline=1
    while read -r line
    do
        if [ $firstline -eq 1 ]; then
            firstline=0
        else
            project=${line%=*}
            INSTALLVERSION[$project]=${line#=*}
        fi
    done < "$VERSIONFILE"
else
    echo "Specified version file $VERSIONFILE does not exist!">&2
    exit 2 
fi

