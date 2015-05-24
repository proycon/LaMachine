LaMachine
===========

This is a virtual machine or installer for the latest development versions of
NLP software developed by the Language Machines research group and CLST (Radboud
University Nijmegen), as well as TiCC (Tilburg University). 

LaMachine can be used in several forms:
 * As a **Virtual Machine** - Easiest, allows you to run our software on any host OS. 
 * As a **Docker application**
 * As a compilation/installation script in a **virtual environment**

Pre-installed software:
- [Timbl](http://ilk.uvt.nl/timbl) - Tilburg Memory Based Learner
- [Ucto](http://ilk.uvt.nl/ucto) - Tokenizer
- [Frog](http://ilk.uvt.nl/frog) - Frog is an integration of memory-based natural language processing (NLP) modules developed for Dutch.
- [Mbt](http://ilk.uvt.nl/mbt) - Memory-based Tagger
- [Wopr](http://ilk.uvt.nl/wopr) - Memory-based Word Predictor
- [FoLiA-tools](http://proycon.github.io/folia) - Command line tools for working with the FoLiA format
- [PyNLPl](https://pypi.python.org/pypi/PyNLPl) - Python Natural Language Processing Library (Python 2 & 3)
- [Colibri Core](http://proycon.github.io/colibri-core/) - Colibri core is an NLP tool as well as a C++ and Python library for working
  with basic linguistic constructions such as n-grams and skipgrams (i.e patterns
  with one or more gaps, either of fixed or dynamic size) in a quick and
  memory-efficient way. At the core is the tool colibri-patternmodeller which
  allows you to build, view, manipulate and query pattern models.
- *C++ libraries* - [ticcutils](http://ilk.uvt.nl/ticcutils), [libfolia](http://proycon.github.io/folia)
- *Python bindings* - [python-ucto](https://github.com/proycon/python-ucto), [python-frog](https://github.com/proycon/python-frog), [python-timbl](https://github.com/proycon/python-timbl) 
- [CLAM](https://proycon.github.io/clam) - Quickly build RESTful webservices 

In the VM, some third-party NLP software is also installed out of the box. Both
the VM image as well as the docker image are based on Arch Linux.

Installation & Usage as Virtual Machine (for Linux, BSD, MacOS X, Windows)
=========================================================================

1. Obtain **Vagrant** from https://www.vagrantup.com/downloads.html or your package manager.
2. Obtain **VirtualBox** from https://www.virtualbox.org/ or your package manager.

On most Linux distributions, steps one and two may be combined with a simple command such as
``sudo apt-get install virtualbox vagrant`` on Ubuntu, or ``sudo pacman -Syu virtualbox vagrant`` on Arch Linux.

3. Clone this repository and navigate to the directory in the terminal: ``$ git clone https://github.com/proycon/LaMachine && cd LaMachine`` 
4. Power up the VM: ``vagrant up`` (this will download and install everything the first time)
5. SSH into your VM: ``vagrant ssh``
6. When done, power down the VM with: ``vagrant halt`` (and you can delete it entirely with ``vagrant destroy``)

You may want to adapt Vagrantfile to change the number of CPUs and Memory
available to the VM (2 CPUs and 3GB RAM by default).


Installation & Usage with Docker (for Linux only)
===================================================

1. Obtain **Docker** from http://www.docker.com or your package manager (``sudo apt-get install docker`` on Ubuntu).
2. Pull the (LaMachine image)[https://registry.hub.docker.com/u/proycon/lamachine/]: ``docker pull proycon/lamachine``
3. Start an interactive prompt to LaMachine: ``docker run  -t -i proycon/lamachine /bin/bash``, or run stuff: ``docker run proycon/lamachine <program>``  (use ``run -i`` if the program has an interactive mode; set up a mounted volume to pass file from host OS to docker, see: https://docs.docker.com/userguide/dockervolumes/)

There is no need to clone this git repository at all for this method.

Installation & Usage locally (for Linux/BSD/Mac OS X)
=======================================================

LaMachine can also be used on a Linux/BSD/Mac OS X system without root access
(provided a set of prerequisites is available on the system). This is done
through an extension for Python VirtualEnv (using Python 3), as we provide a lot of Python
bindings anyhow. This offers a local environment, ideal for development, that
binds against the software globally available on your system. All sources are
pulled from git and compiled for you.

1. Clone this repository and navigate to the directory in the terminal: ``$ git clone https://github.com/proycon/LaMachine && cd LaMachine``  (or download it manually from github)
2. In a terminal, navigate to the directory where you want to create the
   virtual environment, or alternatively pre-create and activate one with ``virtualenv --python=python3
   lamachine && . lamachine/bin/activate``
3. Bootstrap the virtual environment by calling: ``/path/to/LaMachine/virtualenv-bootstrap.sh``

Note that you will always have to activate your virtual environment with ``.
lamachine/bin/activate`` (don't forget the dot!) if you open a new terminal. This requires you use bash
or zsh.

Tested to work on:
* Arch Linux
* Fedora Core 21
* Mac OS X Yosemite
* Ubuntu 14.04 LTS - Trusty Tahr
* Ubuntu 12.04 LTS - Precise Pangolin


Updating
===========

Once you have a LaMachine running, in any form, just run ``lamachine-update.sh`` to update
everything again.
 
Alternatives
====================

If you have no need for a VM or a self-contained environment, and you have proper
administrative access to the system, then install our software using the proper
package manager, provided we have packages available.

* Arch Linux (up to date) -- https://aur.archlinux.org/packages/?SeB=m&K=proycon , these packages are used as the basis of LaMachine
* Debian/Ubuntu Linux (packages are currently out of date) -- https://qa.debian.org/developer.php?login=ko.vandersloot@uvt.nl
* Mac OS X (homebrew), missing some sofware (most notably Frog, Colibri Core, and Python bindings)
* CentOS/Fedora (packages are outdated completely)

The final alternative is obtaining all software manually (from github or
tarballs) and compiling everything yourself.
