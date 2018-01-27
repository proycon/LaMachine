#!/bin/bash
#should be run inside the LaMachine docker container
lamachine-test.sh
cd /usr/src/LaMachine || exit 1
./startwebservices.sh



