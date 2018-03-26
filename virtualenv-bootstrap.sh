#!/usr/bin/env bash
#This script is only here for backward-compatibility reasons to provide LaMachine v1 users an upgrade notice

boldred=${bold}$(tput setaf 1) #  red
normal=$(tput sgr0)

echo "${boldred}Automated upgrade from LaMachine v1 not possible${normal}"
echo "A new major LaMachine version (v2) has been released in early 2018."
echo "You are currently on the older v1. Due to many changes a direct upgrade path was not feasible."
echo "It is easier to simply build a new LaMachine Virtual Environment."
echo "We recommend you to remove this virtual environment (rm -Rf $VIRTUAL_ENV)"
echo "and obtain the latest version by following the instructions on"
echo "the LaMachine website at https://proycon.github.io/LaMachine ."
exit 6
