#!/usr/bin/env python3

import sys
import os

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
]



success = {}
for build in buildmatrix:
    print("Building " + build['name'] + " ...", file=sys.stderr)
    args = []
    for key, value in build.items():
        args.append("--" + key + " " + value)
    r = os.system("bash ../bootstrap.sh " + " ".join(args) + " --noninteractive --verbose >&2 2> " + build['name'] + ".log")
    success[build['name']] = r == 0

