FROM ubuntu:14.04
USER root
MAINTAINER Maarten van Gompel <proycon@anaproy.nl>
RUN apt-get update && apt-get -y install git-core
WORKDIR /usr/src/
RUN git clone https://github.com/proycon/LaMachine
WORKDIR /usr/src/LaMachine
RUN bash bootstrap.sh
