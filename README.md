LaMachine
===========

LaMachine is a software distribution of NLP software developed by the Language
Machines research group and CLST (Radboud University Nijmegen), as well as TiCC
(Tilburg University). 

Our software is highly specialised and generally depends on a lot of other
software. Installing all this software can be a daunting task, compiling it
from scratch even more so.  Ideally software is installed through your
distribution's package manager, but we do not always have packages available
for all platforms, or they may be out of date. LaMachine ensures you can always
use all of our software at the very latest (development) versions by bundling
them all and offering them in three distinct forms:

 * As a **Virtual Machine** - Easiest, allows you to run our software on any host OS. 
 * As a **Docker application**
 * As a compilation/installation script in a **virtual environment**

LaMachine is suitable for both end-users and developers. It has to be noted,
however, that running the latest development versions always comes with the
risk of decreased stability due to undiscovered bugs.

Pre-installed software:
- [Timbl](http://ilk.uvt.nl/timbl) - Tilburg Memory Based Learner
- [Ucto](http://ilk.uvt.nl/ucto) - Tokenizer
- [Frog](http://ilk.uvt.nl/frog) - Frog is an integration of memory-based natural language processing (NLP) modules developed for Dutch.
- [Mbt](http://ilk.uvt.nl/mbt) - Memory-based Tagger
- [Wopr](http://ilk.uvt.nl/wopr) - Memory-based Word Predictor
- [FoLiA-tools](http://proycon.github.io/folia) - Command line tools for working with the FoLiA format
- [PyNLPl](https://pypi.python.org/pypi/PyNLPl) - Python Natural Language Processing Library
- [Colibri Core](http://proycon.github.io/colibri-core/) - Colibri core is an NLP tool as well as a C++ and Python library for working
  with basic linguistic constructions such as n-grams and skipgrams (i.e patterns
  with one or more gaps, either of fixed or dynamic size) in a quick and
  memory-efficient way. At the core is the tool colibri-patternmodeller which
  allows you to build, view, manipulate and query pattern models.
- *C++ libraries* - [ticcutils](http://ilk.uvt.nl/ticcutils), [libfolia](http://proycon.github.io/folia)
- *Python bindings* - [python-ucto](https://github.com/proycon/python-ucto), [python-frog](https://github.com/proycon/python-frog), [python-timbl](https://github.com/proycon/python-timbl) 
- [CLAM](https://proycon.github.io/clam) - Quickly build RESTful webservices 
- [Gecco](https://github.com/proycon/gecco) - Generic Environment for Context-Aware Correction of Orthography

Optional additional software in **virtual environment** form only:
- [T-scan](https://github.com/proycon/tscan) - T-scan is a Dutch text analytics tool for readability prediction. 

The Python bindings and libraries all use Python 3. Both the VM image as well as the docker image are based on Arch Linux.

Installation & Usage as Virtual Machine (for Linux, BSD, MacOS X, Windows)
=========================================================================

1. Obtain **Vagrant** from https://www.vagrantup.com/downloads.html or your package manager.
2. Obtain **VirtualBox** from https://www.virtualbox.org/ or your package manager.
3. Clone this repository and navigate to the directory in the terminal: ``$ git clone https://github.com/proycon/LaMachine && cd LaMachine``  (or [download the ZIP](https://github.com/proycon/LaMachine/archive/master.zip) manually from github)
4. Power up the VM: ``vagrant up`` (this will download and install everything the first time)
5. SSH into your VM: ``vagrant ssh``
6. When done, power down the VM with: ``vagrant halt`` (and you can delete it entirely with ``vagrant destroy``)

You may want to adapt Vagrantfile to change the number of CPUs and Memory
available to the VM (2 CPUs and 3GB RAM by default).

On most Linux distributions, steps one and two may be combined with a simple command such as
``sudo apt-get install virtualbox vagrant`` on Ubuntu, or ``sudo pacman -Syu virtualbox vagrant`` on Arch Linux.


Installation & Usage with Docker (for Linux only)
===================================================

1. Obtain **Docker** from http://www.docker.com or your package manager (``sudo apt-get install docker`` on Ubuntu).
2. Pull the [LaMachine image](https://registry.hub.docker.com/u/proycon/lamachine/): ``docker pull proycon/lamachine``
3. Start an interactive prompt to LaMachine: ``docker run -p 8080:80 -t -i proycon/lamachine /bin/bash``, or run stuff: ``docker run proycon/lamachine <program>``  (use ``run -i`` if the program has an interactive mode; set up a mounted volume to pass file from host OS to docker, see: https://docs.docker.com/userguide/dockervolumes/)

There is no need to clone this git repository at all for this method.

Installation & Usage locally (for Linux/BSD/Mac OS X)
=======================================================

LaMachine can also be used on a Linux/BSD/Mac OS X system without root access
(provided a set of prerequisites is available on the system!). This is done
through an extension for Python VirtualEnv (using Python 3.3 or later), as we
provide a lot of Python bindings anyhow. This offers a local environment, ideal
for development, that binds against the software globally available on your
system. The virtual environment will be contained under a single directory and contains
everything. All sources are pulled from git and compiled for you.

1. **Clone this repository** and navigate to the directory in the terminal: ``$ git clone https://github.com/proycon/LaMachine && cd LaMachine``  (or [download the ZIP](https://github.com/proycon/LaMachine/archive/master.zip) manually from github)
   You will only need this cloned repository once and can safely remote it afterwards.
2. In a terminal, **navigate to the directory** under which to create the
   virtual environment (a ``lamachine`` directory will be created), or alternatively pre-create and activate one with ``virtualenv --python=python3
   lamachine && . lamachine/bin/activate``
3. **Bootstrap the virtual environment** by calling: ``/path/to/LaMachine/virtualenv-bootstrap.sh``

Note that you will always have to activate your virtual environment with 
``. lamachine/bin/activate`` (*don't forget the dot!*) if you open a new terminal.
This also requires you use bash or zsh. To facilitate activation, we recommend
you add an alias ``alias lm=". /path/to/lamachine/bin/activate"`` in your
``~/.bashrc`` or ``~/.zshrc``.

You can add the following optional arguments to ``virtualenv-bootstrap.sh`` (and ``lamachine-update.sh``):

 * ``noadmin`` - Do not attempt to install global dependencies (but if they are missing, compilation will fail)
 * ``force`` - Force recompilation of everything, even if it's not updated
 * ``tscan`` - Compile and install tscan (will download about 1GB in data), t-scan also suggests you install [Alpino](http://www.let.rug.nl/vannoord/alp/Alpino/) (another 1GB), which is not included in LaMachine. 
 * ``python2`` - Use python 2.7 instead of Python 3 (some software may be not be available for Python 2)

Tested to work on:
* Arch Linux
* Debian 8
* Fedora Core 21
* Ubuntu 15.04 - Vivid Vervet
* Ubuntu 14.04 LTS - Trusty Tahr
* Ubuntu 12.04 LTS - Precise Pangolin

Partially works on::
* Mac OS X Yosemite   (python-ucto, python-frog and python-timbl do not work yet)


Updating
===========

Once you have a LaMachine running, *in any form*, just run ``lamachine-update.sh`` to update
everything again.

CLAM Webservices
==================

LaMachine comes with several CLAM webservices ready out of the box. These are
RESTful webservices, but also offer a web-interface for human end-users.  You
will need to explicitly start them before being able to make use of them.

For the LaMachine VM or Docker App, this is done using:

``sudo /usr/src/LaMachine/startwebservices.sh``

All webservices are then accessible through http://127.0.0.1:8080 (ensure that
this port is free) *on your host system* rather than within the VM or Docker
Application stack. This page will provide a listing of all available services.

For the LaMachine Virtual Environment, you have to start and access each
service individually using CLAM's built-in development server:

* ``clamservice start clam.config.ucto``
* ``clamservice start clam.config.frog``
* ``clamservice start clam.config.timbl``
* ``clamservice start clam.config.colibricore``

Each webservice will advertise on what port it has been launched and how to
access it. There is no authentication enabled on these webservices, so do not
expose them to the world!
 
Alternatives
====================

If you have no need for a VM or a self-contained environment, and you have
proper administrative access to the system, then it may be possible to install
our software using the proper package manager, provided we have packages
available:

* Arch Linux (up to date) -- https://aur.archlinux.org/packages/?SeB=m&K=proycon , these packages are used as the basis of LaMachine VM and Docker App, and are freshly pulled from git.
* Debian/Ubuntu Linux (packages are currently out of date)-- Some of our packages are included in the ``science-linguistics`` meta-package, they are however fairly out of date for the moment: ``sudo apt-get install science-linguistics`` , [package state](https://qa.debian.org/developer.php?login=ko.vandersloot@uvt.nl)
* Mac OS X (homebrew), missing some sofware (most notably Frog, Colibri Core, and Python bindings)
* CentOS/Fedora (packages are outdated completely)

The final alternative is obtaining all software sources manually (from github or tarballs) and compiling everything yourself.
