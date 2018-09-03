#!/usr/bin/env python3

import sys
import os
import argparse

CONFFILE = "{{source_path}}/LaMachine/host_vars/{{hostname}}.yml"

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Interactive tool to set a password for one or more components of LaMachine", formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('targets', nargs='+', help='Targets, valid are: main (e.g. for ssh), lab (for jupyterlab)')
    args = parser.parse_args()

    for target in args.targets:
        if target == "main":
            print("Enter a password for the current unix user:")
            r = os.system("passwd")
            if r != 0:
                print("Password updated",file=sys.stderr)
            else:
                print("Failure updating password",file=sys.stderr)
        elif target == "lab":
            from notebook.auth import passwd
            print("Enter a password for the JupyterLab environment:")
            lab_passwd_hash = passwd()
            r = os.system("sed -i 's/lab_password_sha1.*/lab_password_sha1: \"" + lab_passwd_hash + "\"/' " + CONFFILE)
            if r != 0:
                #no lab password yet? append
                with open(CONFFILE,'a','utf-8') as f:
                    print('lab_password_sha1: "' + lab_passwd_hash + '"')
            print("Password scheduled to update, please run lamachine-update now",file=sys.stderr)
        else:
            print("No such target: ", target,file=sys.stderr)



