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

def test(build, args):
    msg = "[LaMachine Test] Building " + buildid(build)+ " ..."
    print(msg, file=sys.stderr)
    ircprint(msg, args)
    passargs = []
    for key, value in build.items():
        if value is True:
            passargs.append("--" + key)
        else:
            passargs.append("--" + key + " " + value)
    begintime = time.time()
    r = os.system("bash ../bootstrap.sh " + " ".join(passargs) + " --noninteractive --private --verbose --vmmem " + str(args.vmmem) + " 2> logs/" + buildid(build).replace(':','-') + ".log >&2")
    endtime = time.time()
    duration = endtime-begintime
    if not args.keep:
        print("Destroying " + build['name'] + " ...", file=sys.stderr)
        if build['flavour'] == "vagrant":
            r2 = os.system("lamachine-" + build['name'] + "-destroy -f")
        elif build['flavour'] == "docker":
            r2 = os.system("docker image rm proycon/lamachine:" + build['name'])
    else:
        r2 = 0
    #remove controller
    shutil.rmtree('lamachine-controller', ignore_errors=True)
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
        s.connect((args.ircserver.strip(), port))
        s.send(b"NICK " + nick + b"\r\n")
        s.send(b"USER " + nick + b" " + nick + b" bla :LaMachine Test Bot\r\n")
        while True:
            response = s.recv(2049)
            if b'Welcome' in  response:
                s.send(b"PRIVMSG #" + args.ircchannel.strip('#').encode('utf-8') + b" :" + message.encode('utf-8') + b"\r\n")
                s.send(b"QUIT\r\n")
                break

def main():
    parser = argparse.ArgumentParser(description="", formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('--keep',help="Keep VM/container", action='store_true',default=False,required=False)
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
    for build in buildmatrix:
        if not args.selection or buildid(build) in args.selection:
            r, duration, r2 = test(build, args)
            results.append( (build, r, duration, r2)  )

    for build, returncode, duration, cleanup in results:
        msg = buildid(build) + " , " + ("OK" if returncode == 0 else "FAILED") + ", " + str(round(duration/60))+ " " + ("KEPT" if args.keep else "CLEANED" if cleanup == 0 else "DIRTY")
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
