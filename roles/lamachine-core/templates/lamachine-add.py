#!/usr/bin/env python3

import sys
import argparse
import os
from collections import defaultdict

MANIFEST = "{{lm_sourcepath}}/LaMachine/install.yml"
ROLEDIR = "{{lm_sourcepath}}/LaMachine/roles"

if __name__ == '__main__':
    descriptions = defaultdict(str)

    parser = argparse.ArgumentParser(description="Add a new package to LaMachine", formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('--list',help="List all installable packages", action='store_true')
    parser.add_argument('packages', nargs='*', help='packages to install')
    args = parser.parse_args()

    package = None
    roles = False
    endline = None
    returncore = 0
    #parse installation manifest and extract packages and descriptions
    with open(MANIFEST,'r',encoding='utf-8') as f:
        for i, line in enumerate(f):
            if line.strip().startswith('roles:'):
                roles = True
            elif roles:
                if line.strip().startswith('-') or line.strip().startswith('# -'):
                    package = line.strip('- #\n').split('##')[0].strip()
                    descriptions[package] += line.split('##')[1].strip() + ' '
                elif line.startswith(' ') and line.strip().startswith('#') and package:
                    #continued description
                    descriptions[package] += line.strip('# \n') + ' '
                else:
                    if endline is None:
                        endline = i
                    package = None

    if args.list or not args.packages:
        for package, description in sorted(descriptions.items()):
            print(package + ": " + description)
        print("Usage: lamachine-add [package] [[package2]] etc..",file=sys.stderr)

    if args.packages:
        appendpackages = []
        for package in args.packages:
            if package in descriptions:
                r = os.system("sed -i 's/# - " + package + "/ - " + package +"/' " + MANIFEST)
                if r == 0:
                    print("Added " + package + " to installation manifest; you can now run lamachine-update to install it",file=sys.stderr)
                else:
                    returncode = 1
                    print("Could not add " + package + " to installation manifest; might be already active?",file=sys.stderr)
            elif os.path.exists(os.path.join(ROLEDIR, package)):
                #deal with packages that are not in the current manifest (because it being based on an older template) but which do exist in LaMachine
                appendpackages.append(package)
                print("Appended " + package + " to installation manifest; you can now run lamachine-update to install it",file=sys.stderr)
            else:
                print("ERROR: No such package: " + package ,file=sys.stderr)
                returncode = 1

        if appendpackages:
            assert endline is not None
            with open(MANIFEST,'r',encoding='utf-8') as f_in:
                with open(MANIFEST + '.tmp','r',encoding='utf-8') as f_out:
                    for i, line in enumerate(f_in):
                        if i == endline:
                            for package in appendpackages:
                                print('      - ' + package + '       ##', file=f_out)
                        f_out.write(line)

    sys.exit(returncode)
