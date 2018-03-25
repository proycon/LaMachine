FROM debian:stretch
ARG NAME=stable-venv-debian9
ARG VERSION=stable
EXPOSE 80
USER root
MAINTAINER Maarten van Gompel <proycon@anaproy.nl>
LABEL Description="LaMachine Local Test"
RUN useradd -ms /bin/bash lamachine
RUN echo "lamachine:lamachine" | chpasswd
RUN adduser -m lamachine sudo
RUN echo "lamachine ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
USER $UNIX_USER
WORKDIR /home/lamachine
RUN /bin/bash <(curl -s https://raw.githubusercontent.com/proycon/LaMachine/lamachine2/bootstrap.sh) --flavour local --version $VERSION --env virtualenv --noninteractive --private --verbose --name $NAME
CMD /bin/bash -l /home/lamachine/lamachine-$NAME-activate
