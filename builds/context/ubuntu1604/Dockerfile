FROM ubuntu:xenial
ARG NAME=stable-venv-ubuntu1604
ARG VERSION=stable
ARG BRANCH=master
EXPOSE 80
USER root
MAINTAINER Maarten van Gompel <proycon@anaproy.nl>
LABEL Description="LaMachine Local Test"
RUN apt-get update
RUN apt-get install -m -y python sudo apt-utils wget locales
RUN sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen
RUN locale-gen
RUN useradd -ms /bin/bash lamachine
RUN echo "lamachine:lamachine" | chpasswd
RUN adduser lamachine sudo
RUN echo "lamachine ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
USER lamachine
WORKDIR /home/lamachine
RUN wget https://raw.githubusercontent.com/proycon/LaMachine/$BRANCH/bootstrap.sh
RUN chmod a+x bootstrap.sh
RUN ./bootstrap.sh --flavour local --branch $BRANCH --version $VERSION --env virtualenv --noninteractive --private --verbose --name $NAME
CMD /bin/bash -l /home/lamachine/lamachine-$NAME-activate
