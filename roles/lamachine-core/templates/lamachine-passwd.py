#!/usr/bin/env python3

import argparse

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Interactive tool to set a password for one or more components of LaMachine", formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('targets', nargs='+', help='Targets, valid are: main (e.g. for ssh), lab (for jupyterlab)')
    args = parser.parse_args()

    for target in args.targets:
        if target == "lab":
            from notebook.auth import passwd


        else:
            print("No such target: ", target,file=sys.stderr)



