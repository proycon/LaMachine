#!/usr/bin/env python3

import sys
import os
import argparse

CONFFILE = "{{source_path}}/LaMachine/host_vars/{{hostname}}.yml"

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Interactive tool to set a password for one or more components of LaMachine", formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('--password','-p',type=str, help="Provide password as parameter (this is considered unsafe in most environments!)", action='store', required=False)
    parser.add_argument('targets', nargs='+', help='Targets, valid are: main (e.g. for ssh), lab (for jupyterlab), flat')
    args = parser.parse_args()

    for target in args.targets:
        if target == "main":
            if args.password:
                print("Unable to use the password passed as paramter, querying interactively",file=sys.stderr)
            print("Enter a password for the current unix user:")
            r = os.system("passwd")
            if r == 0:
                print("Password updated",file=sys.stderr)
            else:
                print("Failure updating password",file=sys.stderr)
        elif target == "lab":
            from notebook.auth import passwd
            if args.password:
                lab_passwd_hash = passwd(args.password)
            else:
                print("Enter a password for the JupyterLab environment:")
                lab_passwd_hash = passwd()
            r = os.system("lamachine-config lab_password_sha1 \""+ lab_passwd_hash + "\"")
            if r == 0:
                print("Password scheduled to update, please run lamachine-update now",file=sys.stderr)
            else:
                print("Failured to set password", sys.stderr)
        elif target == "flat":
            if args.password:
                pw = args.password
            else:
                pw = input("Enter a password for FLAT:").strip()
            r = os.system("lamachine-config flat_password \""+ pw + "\"")
            if r == 0:
                print("Password scheduled to update, please run lamachine-update now",file=sys.stderr)
            else:
                print("Failured to set password", sys.stderr)
            sys.exit(r)
        else:
            print("No such target: ", target,file=sys.stderr)



