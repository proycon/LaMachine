buildmatrix = [
    ##### DEBIAN 9 (stretch) [default] ######
    {
        "name": 'stable',
        "flavour": 'vagrant',
        "version": 'stable'
    },
    {
        "name": 'development',
        "flavour": 'vagrant',
        "version": 'development'
    },
    {
        "name": 'latest', #'latest' is the default docker tag
        "flavour": 'docker',
        "version": 'stable'
    },
    {
        "name": 'develop', #tag compatible with LaMachine v1
        "flavour": 'docker',
        "version": 'development'
    },
    ##### OTHER DISTRIBUTIONS ######
    {
        "name": 'stable-centos7',
        "flavour": 'vagrant',
        "version": 'stable',
        "vagrantbox": "centos/7"
    },
    {
        "name": 'stable-ubuntu1604',
        "flavour": 'vagrant',
        "version": 'stable',
        "vagrantbox": "ubuntu/xenial64"
    },
    {
        "name": 'stable-ubuntu1804',
        "flavour": 'vagrant',
        "version": 'stable',
        "vagrantbox": "ubuntu/bionic64"
    },
    {
        "name": 'stable-fedora27',
        "flavour": 'vagrant',
        "version": 'stable',
        "vagrantbox": "fedora/27-cloud-base"
    },
    ##### SPECIALISED BUILDS WITH OPTIONAL SOFTWARE ######
    {
        "name": 'piccl',
        "flavour": 'docker',
        "version": 'stable',
        "minimal": True,
        "install": "piccl"
    },
    {
        "name": 'tscan',
        "flavour": 'docker',
        "version": 'stable',
        "minimal": True,
        "install": "tscan"
    }
]
