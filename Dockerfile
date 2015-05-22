FROM nfnty/arch-devel:latest
USER root
MAINTAINER Maarten van Gompel <proycon@anaproy.nl>
WORKDIR /usr/src/
RUN git clone https://github.com/proycon/LaMachine
WORKDIR /usr/src/LaMachine
RUN bash bootstrap.sh
