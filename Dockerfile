FROM debian:stable
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
LABEL description="A unified distribution of NLP software. Developed by the Centre of Language and Speech Technology (Radboud University Nijmegen) and partners" value="$LM_VERSION"
VOLUME $DATA_PATH
RUN apt-get update
RUN apt-get install -m -y python python-pip sudo apt-utils locales
RUN sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen
RUN locale-gen
RUN pip install ansible
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
WORKDIR /home/$UNIX_USER
CMD /bin/bash -l
