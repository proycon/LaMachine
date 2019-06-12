#!/bin/bash
cd "$LM_PREFIX/opt/spotlight"
if [ ! -z "$1" ]; then
    lang=$1
else
    lang="en"
fi
java -jar dbpedia-spotlight.jar $lang http://localhost:2222/rest
ret=$?
cd -
exit $ret
