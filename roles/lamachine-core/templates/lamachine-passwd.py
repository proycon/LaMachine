#!/usr/bin/env python3

import sys
import os
import argparse
import hashlib
import random

CONFFILE = "{{source_path}}/LaMachine/host_vars/{{hostname}}.yml"


#copied from jupyter source because we don't want a dependency at this tsage
def jupyter_passwd(passphrase):
    salt_len = 12
    h = hashlib.new('sha1')
    salt = ('%0' + str(salt_len) + 'x') % random.getrandbits(4 * salt_len)
    h.update(bytes(passphrase, 'utf-8') + bytes(salt, 'ascii'))
    return ':'.join(('sha1', salt, h.hexdigest()))

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
            if args.password:
                lab_passwd_hash = jupyter_passwd(args.password)
            else:
                print("Enter a password for the JupyterLab environment:")
                pw = input("Enter a password for Jupyter Lab:").strip()
                lab_passwd_hash = jupyter_passwd(pw)
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



