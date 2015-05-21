FROM ubuntu:14.04
MAINTAINER Maarten van Gompel <proycon@anaproy.nl>
RUN sudo apt-get upgrade && sudo apt-get -y install git-core
RUN cd /usr/src
RUN git clone https://github.com/proycon/LaMachine
RUN cd LaMachine
RUN sudo bash bootstrap.sh
