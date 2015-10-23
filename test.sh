#!/bin/bash
RETURN=0

testerror () {
    echo "================ TEST ERROR ==============" >&2
    echo $1 >&2
    echo "===========================================" >&2
    RETURN=2
}

which ucto || testerror "Ucto not found"
which frog || testerror "Frog not found"
which timbl || testerror "Timbl not found"
which mbt || testerror "Mbt not found"
which wopr || testerror "Wopr not found"
which foliavalidator || testerror "FoLiA validator not found"
which gecco || testerror "Gecco not found"
python -c "import pynlpl" || testerror "PyNLPl not found"
python -c "import timbl" || testerror "python-timbl not found"
python -c "import ucto" || testerror "python-ucto not found"
which colibri-patternmodeller || testerror "Colibri Core not found"
python -c "import colibricore" || testerror "colibricore not found for python"
python -c "import frog" || testerror "python-frog not found"

if [ "$RETURN" != "0" ]; then
    testerror "Test failure... One or more errors occured!"
fi

exit $RETURN
