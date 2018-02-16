FROM debian:stable
ARG UNIX_USER=lamachine
ARG LAMACHINE_PATH=/lamachine
ARG DATA_PATH=/data
ARG LM_NAME=docker
ARG ANSIBLE_OPTIONS="-vv"
EXPOSE 80
USER root
MAINTAINER Maarten van Gompel <proycon@anaproy.nl>
LABEL Description="A distribution containing NLP software developed by the Language Machines Research Group and the Centre of Language and Speech Technology (both Radboud University Nijmegen) and the Tilburg Centre for Cognition and Communication (Tilburg University)"
VOLUME $LAMACHINE_PATH
VOLUME $DATA_PATH
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367
RUN apt-get update
RUN apt-get install ansible
RUN useradd -ms /bin/bash $UNIX_USER
WORKDIR /home/$UNIX_USER
rUN echo "$UNIX_USER:lamachine" | chpasswd
RUN adduser $UNIX_USER sudo
RUN echo "$UNIX_USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
USER $UNIX_USER
WORKDIR $LAMACHINE_PATH
RUN ansible-playbook $ANSIBLE_OPTIONS -i $LAMACHINE_PATH/hosts.$LM_NAME install-$LM_NAME.yml
CMD /bin/bash
