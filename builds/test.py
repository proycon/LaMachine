#!/usr/bin/env python3

import sys
import os
import time
import shutil
import argparse
try:
    import irc
    IRC=True
except:
    IRC=False
from builds import buildmatrix


def buildid(build):
    return build['flavour'] + ':' + build['name']

def test(build, args, ircbot=None):
    msg = "Building " + buildid(build)+ " ..."
    print(msg, file=sys.stderr)
    if ircbot is not None: ircbot.print(msg)
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
    return (r, endtime - begintime, r2)

class IRCBot(irc.bot.SingleServerIRCBot):
    def __init__(self, channel, server, port=6667):
        irc.bot.SingleServerIRCBot.__init__(self, [(server, port)], "lamachinetestbot", "lamachinetestbot")
        self.channel = channel
        self.joined = False

    def on_nicknameinuse(self, c, e):
        c.nick(c.get_nickname() + "_")

    def on_welcome(self, c, e):
        c.join(self.channel)
        self.joined = True

    def print(self, line):
        self.connection.msg(self.channel, line)


def main():
    parser = argparse.ArgumentParser(description="", formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('--keep',help="Keep VM/container", action='store_true',default=False,required=False)
    parser.add_argument('--vmmem', type=int,help="VM Memory", action='store',default=2690,required=False)
    parser.add_argument('--ircserver', type=str,help="IRC server for notifications", action='store',required=False)
    parser.add_argument('--ircchannel', type=str,help="IRC channel for notifications", action='store',required=False)
    parser.add_argument('selection', nargs='*', help='bar help')
    args = parser.parse_args()

    if IRC and args.ircserver and args.ircchannel:
        ircbot = IRCBot(args.ircchannel, args.ircserver, 6667)
        while not ircbot.joined:
            time.sleep(1)
        ircbot.print("o/")
    else:
        ircbot = None

    results = []
    for build in buildmatrix:
        if not args.selection or buildid(build) in args.selection:
            r, duration, r2 = test(build, args, ircbot)
            results.append( (build, r, duration, r2)  )

    for build, returncode, duration, cleanup in results:
        msg = buildid(build) + " , " + ("OK" if returncode == 0 else "FAILED") + ", " + str(round(duration/60))+ " " + ("KEPT" if args.keep else "CLEANED" if cleanup == 0 else "DIRTY")
        print(msg)
        if ircbot is not None: ircbot.print(msg)

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
