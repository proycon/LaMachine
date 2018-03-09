#!/usr/bin/env python3

import sys
import os
import time

buildmatrix = [
    {
        "name": 'lmtest-stable-vm',
        "flavour": 'vagrant',
        "version": 'stable'
    },
    {
        "name": 'lmtest-dev-vm',
        "flavour": 'vagrant',
        "version": 'development'
    },
    {
        "name": 'lmtest-stable-docker',
        "flavour": 'docker',
        "version": 'stable'
    },
    {
        "name": 'lmtest-dev-docker',
        "flavour": 'docker',
        "version": 'development'
    },
    {
        "name": 'lmtest-stable-vm-centos7',
        "flavour": 'vagrant',
        "version": 'stable',
        "vagrantbox": "centos/7"
    },
    {
        "name": 'lmtest-stable-vm-ubuntu1604',
        "flavour": 'vagrant',
        "version": 'stable',
        "vagrantbox": "ubuntu/xenial64"
    },
    {
        "name": 'lmtest-piccl-stable-docker',
        "flavour": 'docker',
        "version": 'stable',
        "minimal": True,
        "install": "python-core,languagemachines-basic,languagemachines-python,piccl"
    },
    {
        "name": 'lmtest-tscan-stable-docker',
        "flavour": 'docker',
        "version": 'stable',
        "minimal": True,
        "install": "python-core,languagemachines-basic,languagemachines-python,alpino,tscan"
    }
]



results = []
for build in buildmatrix:
    print("Building " + build['name'] + " ...", file=sys.stderr)
    args = []
    for key, value in build.items():
        if value is True:
            args.append("--" + key)
        else:
            args.append("--" + key + " " + value)
    begintime = time.time()
    r = os.system("bash ../bootstrap.sh " + " ".join(args) + " --noninteractive --private --verbose >&2 2> " + build['name'] + ".log")
    endtime = time.time() - begintime
    if build['flavour'] == "vagrant":
        r2 = os.system("lamachine-" + build['name'] + "-destroy -f")
    elif build['flavour'] == "docker":
        r2 = os.system("docker image rm proycon/lamachine:" + build['name'])
    results.append( (build, r, endtime - begintime), r2 )

for build, returncode, duration, cleanup in results:
    print(build['name'] + " , " + ("OK" if returncode == 0 else "FAILED") + ", " + str(round(duration/60))+ ("CLEANED" if cleanup == 0 else "DIRTY") )

if all( returncode == 0 for _,returncode,_,_ in results):
    sys.exit(0)
else:
    sys.exit( sum(returncode for _,returncode,_,_ in results) )
