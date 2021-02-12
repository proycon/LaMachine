FROM proycon/lamachine:core
MAINTAINER Maarten van Gompel <proycon@anaproy.nl>:
LABEL description="A LaMachine Docker container template"
RUN lamachine-config lm_base_url https://your.domain &&\
    lamachine-config force_https yes &&\
    lamachine-config maintainer_name "Your name here" &&\
    lamachine-config maintainer_mail "your@mail.here" &&\
    lamachine-passwd -p some_secret_password lab flat &&\
    lamachine-add languagemachines-basic languagemachines-python labirinto jupyter
RUN lamachine-update
ENTRYPOINT [ "/usr/local/bin/lamachine-start-webserver", "-f" ]
