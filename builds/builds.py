buildmatrix = [
    {
        "name": 'stable',
        "flavour": 'vagrant',
        "version": 'stable'
    },
    {
        "name": 'dev',
        "flavour": 'vagrant',
        "version": 'development'
    },
    {
        "name": 'stable',
        "flavour": 'docker',
        "version": 'stable'
    },
    {
        "name": 'dev',
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
