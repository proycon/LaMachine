FROM nfnty/arch-devel:latest
EXPOSE 80
USER root
MAINTAINER Maarten van Gompel <proycon@anaproy.nl>
LABEL Description="A distribution containing NLP software developed by the Language Machines Research Group and the Centre of Language and Speech Technology (both Radboud University Nijmegen) and the Tilburg Centre for Cognition and Communication (Tilburg University)"
VOLUME /clamdata
WORKDIR /usr/src/
RUN cp /etc/hosts .
RUN sed -i '/::/d' hosts
RUN cp hosts /etc/hosts
RUN git clone https://github.com/proycon/LaMachine --branch develop
WORKDIR /usr/src/LaMachine
RUN bash bootstrap.sh dev
CMD /bin/bash
