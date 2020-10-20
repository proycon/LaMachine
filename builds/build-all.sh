#!/bin/bash
python build.py --cleanfirst --ircserver irc.uvt.nl --ircchannel "#gitlama" vagrant:stable
python build.py --cleanfirst --ircserver irc.uvt.nl --ircchannel "#gitlama" docker:core
python build.py --cleanfirst --ircserver irc.uvt.nl --ircchannel "#gitlama" docker:latest
python build.py --cleanfirst --ircserver irc.uvt.nl --ircchannel "#gitlama" docker:develop
