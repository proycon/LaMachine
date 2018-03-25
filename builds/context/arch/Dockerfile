FROM nfnty/arch-devel:latest
ARG NAME=stable-venv-arch
ARG VERSION=stable
EXPOSE 80
USER root
MAINTAINER Maarten van Gompel <proycon@anaproy.nl>
LABEL Description="LaMachine Local Test"
RUN pacman --noconfirm -Su wget
RUN useradd -ms /bin/bash lamachine
RUN echo "lamachine:lamachine" | chpasswd
RUN echo "lamachine ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
USER lamachine
WORKDIR /home/lamachine
RUN wget https://raw.githubusercontent.com/proycon/LaMachine/lamachine2/bootstrap.sh
RUN chmod a+x bootstrap.sh
RUN ./bootstrap.sh --flavour local --version $VERSION --env virtualenv --noninteractive --private --verbose --name $NAME
CMD /bin/bash -l /home/lamachine/lamachine-$NAME-activate
