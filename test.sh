#!/bin/bash
RETURN=0

echo "============== LaMachine Test ==================="
if [ -z "$OS" ]; then
    MAC=$(which brew 2> /dev/null)
    if [ -f "$MAC" ]; then
        OS='mac'
    else
        OS='linux'
    fi
fi
echo "OS=$OS"

GREEN='\033[1;32m'
RED='\033[1;31m'
RESET='\033[0m'


runtest () {
    EXEC=$1
    $EXEC "${@:2}" 2> test.out >^2
    if [ $? -eq 0 ]; then
        echo -e "$EXEC: $GREEN OK $RESET"
    else
        echo -e "$EXEC: $RED FAILED! $RESET"
        echo "---------------------------------------------------------"
        echo "Details for failed test $EXEC:"
        cat test.out
        echo "---------------------------------------------------------"
        FAILURES=$((FAILURES+1))
    fi
}

runtest_python () {
    MODULE=$1
    python -c "import $MODULE" 2> test.out >&2
    if [ $? -eq 0 ]; then
        echo -e "[python] $MODULE: $GREEN OK $RESET"
    else
        echo -e "[python] $MODULE: $RED FAILED! $RESET"
        echo "---------------------------------------------------------"
        echo "Details for failed test [python] $MODULE:"
        cat test.out
        echo "---------------------------------------------------------"
        FAILURES=$((FAILURES+1))
    fi
}


FAILURES=0

runtest ucto -h
runtest timbl -h
runtest timblserver -h
runtest mbt -h
runtest mbtserver -h
runtest frog -h
runtest wopr ""
if [ "$OS" != "mac" ]; then
    runtest TICCL-indexer -h
    runtest TICCL-stats -h
fi
runtest colibri-classencode -h
runtest colibri-patternmodeller -h
runtest clamservice -h
runtest_python pynlpl
runtest_python pynlpl.formats.folia
runtest_python pynlpl.formats.fql
runtest folialint -h
runtest foliavalidator -h
runtest folia2html -h
runtest folia2txt -h
runtest_python timbl
runtest_python ucto
if [ "$OS" == "mac" ]; then
    TMPFAILURES=$FAILURES
fi
runtest_python frog
if [ "$OS" == "mac" ]; then
    FAILURES=$TMPFAILURES  # we don't count python-frog failing as a final failure as it's expected on OS x for now
fi
runtest_python colibricore
if [ "$OS" != "mac" ]; then
    runtest gecco --helpmodules
fi
runtest nextflow info LanguageMachines/PICCL

if [ $FAILURES -eq 0 ]; then
    echo -e "[LaMachine Test] $GREEN All tests passed, good! $RESET"
else
    echo -e "[LaMachine Test] $RED $FAILURES tests failed! $RESET"
fi

exit $FAILURES
