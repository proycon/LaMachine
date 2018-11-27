bootstrap: debootstrap
MirrorURL: http://httpredir.debian.org/debian
OSVersion: stable

%files
    host_vars/$HOSTNAME.yml host_vars/localhost.yml

%labels
    Maintainer Maarten van Gompel
    Version $LM_VERSION

%post
    apt-get update
    apt-get install -m -y python python-pip sudo apt-utils locales
    sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen
    locale-gen
    pip install ansible
    useradd -ms /bin/bash lamachine
    echo "lamachine:lamachine" | chpasswd
    adduser lamachine sudo
    echo "lamachine ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    mkdir /data /lamachine /usr/src/LaMachine
    cp -Rpd /lamachine/* /usr/src/LaMachine
    cp /lamachine/host_vars/$HOSTNAME.yml /usr/src/LaMachine/host_vars/localhost.yml
    chown -R lamachine /usr/src/LaMachine
    sudo -u lamachine ansible-playbook $ANSIBLE_OPTIONS /usr/src/LaMachine/install.yml -c local

%runscript
    /bin/bash -l
