#!/usr/bin/env python3

import sys
import os
import time
import shutil
import argparse
from builds import buildmatrix

parser = argparse.ArgumentParser(description="", formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('--keep',help="Keep VM/container", action='store_true',default=False,required=False)
parser.add_argument('--vmmem', type=int,help="VM Memory", action='store',default=2690,required=False)
parser.add_argument('selection', nargs='*', help='bar help')
args = parser.parse_args()


def buildid(build):
    return build['flavour'] + ':' + build['name']


results = []
for build in buildmatrix:
    if not args.selection or buildid(build) in args.selection:
        print("Building " + buildid(build)+ " ...", file=sys.stderr)
        passargs = []
        for key, value in build.items():
            if value is True:
                passargs.append("--" + key)
            else:
                passargs.append("--" + key + " " + value)
        begintime = time.time()
        r = os.system("bash ../bootstrap.sh " + " ".join(passargs) + " --noninteractive --private --verbose --vmmem " + str(args.vmmem) + " 2> " + buildid(build).replace(':','-') + ".log >&2")
        endtime = time.time()
        if not args.keep:
            print("Destroying " + build['name'] + " ...", file=sys.stderr)
            if build['flavour'] == "vagrant":
                r2 = os.system("lamachine-" + build['name'] + "-destroy -f")
            elif build['flavour'] == "docker":
                r2 = os.system("docker image rm proycon/lamachine:" + build['name'])
        #remove controller
        shutil.rmtree('lamachine-controller', ignore_errors=True)
        results.append( (build, r, endtime - begintime, r2) )

for build, returncode, duration, cleanup in results:
    print(buildid(build) + " , " + ("OK" if returncode == 0 else "FAILED") + ", " + str(round(duration/60))+ " " + ("KEPT" if args.keep else "CLEANED" if cleanup == 0 else "DIRTY") )

if not results:
    print("No such build defined. Options:", file=sys.stderr)
    for build in buildmatrix:
        print(" - " + buildid(build) + " ...", file=sys.stderr)
    sys.exit(123)
elif all( returncode == 0 for _,returncode,_,_ in results):
    sys.exit(0)
else:
    sys.exit( sum(returncode for _,returncode,_,_ in results) )
