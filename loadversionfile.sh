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
            ver=${line#*=}
            INSTALLVERSION[$project]=$ver
            echo "Requested version for $project: $ver"
        fi
    done < "$VERSIONFILE"
else
    echo "Specified version file $VERSIONFILE does not exist!">&2
    exit 2 
fi

