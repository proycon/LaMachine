FROM ubuntu:14.04
RUN sudo apt-get upgrade && sudo apt-get install git-core
RUN cd /usr/src
RUN git clone https://github.com/proycon/LaMachine
RUN cd LaMachine
RUN sudo bash bootstrap.sh
