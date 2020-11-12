FROM proycon/lamachine:latest
MAINTAINER Maarten van Gompel <proycon@anaproy.nl>
LABEL description="A LaMachine Docker container template"
RUN lamachine-passwd -p some_secret_password lab flat
RUN lamachine-config lm_base_url https://your.domain
RUN lamachine-config force_https yes
RUN lamachine-config maintainer_name "Your name here"
RUN lamachine-config maintainer_mail "your@mail.here"
RUN lamachine-update
ENTRYPOINT [ "/usr/local/bin/lamachine-start-webserver", "-f" ]
