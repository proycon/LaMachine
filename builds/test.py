#!/usr/bin/env python3

import sys
import os
import time
import shutil
import argparse
import socket
from builds import buildmatrix


def buildid(build):
    return build['flavour'] + ':' + build['name']

def clean(build, args):
    print("Destroying " + build['name'] + " ...", file=sys.stderr)
    r2 = 1
    if build['flavour'] == "vagrant":
        r2 = os.system("lamachine-" + build['name'] + "-destroy -f")
    elif build['flavour'] in ("docker", "local"):
        r2 = os.system("docker image rm proycon/lamachine:" + build['name'])
    #remove controller
    shutil.rmtree('lamachine-controller/' + build['name'], ignore_errors=True)
    os.system("rm *" + build['name']+"*.yml")
    os.system("rm lamachine-"+ build['name']+ "*")
    return r2

def test(build, args):
    msg = "[LaMachine Test] Building " + buildid(build)+ " ..."
    print(msg, file=sys.stderr)
    ircprint(msg, args)
    passargs = []
    for key, value in build.items():
        if key != 'context':
            if value is True:
                passargs.append("--" + key)
            else:
                passargs.append("--" + key + " " + value)
    if build['flavour'] == 'vagrant' and os.path.exists('lamachine-'+ build['name'] + '-destroy'):
        print("[LaMachine Test] VM " + build['name'] + " already exists...", file=sys.stderr)
        if args.clean:
            clean(build, args)
        else:
            ircprint(msg, args)
            return (1,0,1)
    begintime = time.time()
    if build['flavour'] == 'local':
        #we build local tests in a docker container (clean environment), the dockerfile invokes the bootstrap:
        cwd = os.getcwd()
        os.chdir("context/" + build['context'])
        cmd = "docker build -t proycon/lamachine:" + build['name'] + " --build-arg NAME=" + build['name'] + " --build-arg VERSION=" + build['version'] + " . 2>> " + cwd + "/logs/" + buildid(build).replace(':','-') + '.log >&2'
        r = os.system(cmd)
        os.chdir(cwd)
    else:
        r = os.system("bash ../bootstrap.sh " + " ".join(passargs) + " --noninteractive --private --verbose --vmmem " + str(args.vmmem) + " 2> logs/" + buildid(build).replace(':','-') + ".log >&2")
    endtime = time.time()
    duration = endtime-begintime
    if args.clean:
        r2 = clean(build, args)
    else:
        r2 = 0
    if r == 0:
        msg = "[LaMachine Test] Build " + buildid(build)+ " passed! (" + str(round(duration/60)) + " mins) :-)"
    else:
        msg = "[LaMachine Test] Build " + buildid(build)+ " FAILED!  (" + str(round(duration/60)) + " mins) :-("
    print(msg, file=sys.stderr)
    ircprint(msg, args)
    return (r, endtime - begintime, r2)

def ircprint(message, args, port=6667):
    nick = b"lmtestbot_" + os.uname()[1].encode('utf-8')
    if args.ircchannel and args.ircserver and message:
        s = socket.socket()
        s.settimeout(60)
        s.connect((args.ircserver.strip(), port))
        s.send(b"NICK " + nick + b"\r\n")
        s.send(b"USER " + nick + b" " + nick + b" bla :LaMachine Test Bot\r\n")
        while True:
            response = s.recv(2049)
            if b'Welcome' in  response:
                s.send(b"PRIVMSG #" + args.ircchannel.strip('#').encode('utf-8') + b" :" + message.encode('utf-8') + b"\r\n")
                s.send(b"QUIT\r\n")
                break
        time.sleep(5)

def main():
    parser = argparse.ArgumentParser(description="", formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('--clean',help="Clean up after tests (otherwise VMs and containers will be kept)", action='store_true',default=False,required=False)
    parser.add_argument('--vmmem', type=int,help="VM Memory", action='store',default=2690,required=False)
    parser.add_argument('--ircserver', type=str,help="IRC server for notifications", action='store',required=False)
    parser.add_argument('--ircchannel', type=str,help="IRC channel for notifications", action='store',required=False)
    parser.add_argument('--irctest', help="Test IRC only", action='store_true',required=False)
    parser.add_argument('selection', nargs='*', help='Selection')
    args = parser.parse_args()


    try:
        os.mkdir("logs")
    except:
        pass

    if args.irctest:
        ircprint("Test", args)
        sys.exit(0)

    results = []
    if not args.selection: #just build everything
        for build in buildmatrix:
            r, duration, r2 = test(build, args)
            results.append( (build, r, duration, r2)  )
    else:
        for build_id in args.selection:
            for build in buildmatrix:
                if buildid(build) == build_id:
                    r, duration, r2 = test(build, args)
                    results.append( (build, r, duration, r2)  )

    for build, returncode, duration, cleanup in results:
        msg = buildid(build) + " , " + ("OK" if returncode == 0 else "FAILED") + ", " + str(round(duration/60))+ " " + ("KEPT" if not args.clean else "CLEANED" if cleanup == 0 else "DIRTY")
        print(msg)

    if not results:
        print("No such build defined. Options:", file=sys.stderr)
        for build in buildmatrix:
            print(" - " + buildid(build) + " ...", file=sys.stderr)
        sys.exit(123)
    elif all( returncode == 0 for _,returncode,_,_ in results):
        sys.exit(0)
    else:
        sys.exit( sum(returncode for _,returncode,_,_ in results) )

if __name__ == '__main__':
    main()
