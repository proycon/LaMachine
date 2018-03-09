#!/usr/bin/env python3

import os

buildmatrix = [
    {
        "name": 'lmtest-stable-vm-debian',
        "flavour": 'vagrant',
        "version": 'stable'
    },
    {
        "name": 'lmtest-dev-vm-debian',
        "flavour": 'vagrant',
        "version": 'development'
    },
    {
        "name": 'lmtest-stable-docker-debian',
        "flavour": 'docker',
        "version": 'stable'
    },
    {
        "name": 'lmtest-stable-docker-debian',
        "flavour": 'docker',
        "version": 'development'
    },
]



success = {}
for build in buildmatrix:
    args = []
    for key, value in build.items():
        args.append("--" + key + " " + value)
    r = os.system("bash ../bootstrap.sh " + " ".join(args) + " --noninteractive --verbose >&2 2> " + build['name'] + ".log")
    success[build['name']] = r == 0

