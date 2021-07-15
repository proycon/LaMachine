FROM ubuntu:focal
ARG UNIX_USER=lamachine
ARG LAMACHINE_PATH=/lamachine
ARG DATA_PATH=/data
ARG LM_NAME=docker
ARG HOSTNAME=lamachine-docker
ARG ANSIBLE_OPTIONS="-vv"
ARG LM_VERSION=unknown
EXPOSE 80
EXPOSE 8080
EXPOSE 8888
EXPOSE 9999
USER root
MAINTAINER Maarten van Gompel <proycon@anaproy.nl>
LABEL description="A unified distribution of NLP software. Developed by the Centre of Language and Speech Technology (Radboud University Nijmegen), the KNAW Humanities Cluster. Funded by CLARIAH" value="$LM_VERSION"
VOLUME $DATA_PATH
ENV DEBIAN_FRONTEND=noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN=true
RUN apt-get update && apt-get install -m -y python3 python3-pip sudo apt-utils locales software-properties-common
RUN apt-add-repository --yes --update ppa:ansible/ansible
RUN apt-get update && apt-get install -m -y ansible
RUN sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen
RUN useradd -ms /bin/bash $UNIX_USER
RUN echo "$UNIX_USER:lamachine" | chpasswd
RUN adduser $UNIX_USER sudo
RUN echo "$UNIX_USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
RUN mkdir $LAMACHINE_PATH
COPY . $LAMACHINE_PATH
COPY host_vars/$HOSTNAME.yml $LAMACHINE_PATH/host_vars/localhost.yml
RUN chown -R $UNIX_USER $LAMACHINE_PATH
USER $UNIX_USER
RUN ansible-playbook $ANSIBLE_OPTIONS $LAMACHINE_PATH/install.yml -c local
RUN sudo ldconfig
WORKDIR /home/$UNIX_USER
CMD /bin/bash -l
