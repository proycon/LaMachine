buildmatrix = [
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
        "name": 'development',
        "flavour": 'docker',
        "version": 'development'
    },
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
        "name": 'stable-fedora27',
        "flavour": 'vagrant',
        "version": 'stable',
        "vagrantbox": "fedora/27-cloud-base"
    },
    {
        "name": 'piccl-stable',
        "flavour": 'docker',
        "version": 'stable',
        "minimal": True,
        "install": "python-core,languagemachines-basic,languagemachines-python,piccl"
    },
    {
        "name": 'tscan-stable',
        "flavour": 'docker',
        "version": 'stable',
        "minimal": True,
        "install": "python-core,languagemachines-basic,languagemachines-python,alpino,tscan"
    }
]
