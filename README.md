LaMachine
===========

This is a virtual machine based on Ubuntu Linux 14.04 (64-bit only)
with the latest development versions of NLP software developed by the Language
Machines research group,  CLST (Radboud University Nijmegen), as well as TiCC
(Tilburg University). It can also serve as a docker.io application rather than
a VM.

Pre-installed software:
- *Timbl* - Tilburg Memory Based Learner
- *Ucto* - Tokenizer
- *Frog* - Frog is an integration of memory-based natural language processing (NLP) modules developed for Dutch.
- *FoLiA-tools* - Command line tools for working with the FoLiA format
- *PyNLPl* - Python Natural Language Processing Library (Python 2 & 3)
- *Colibri Core* - Colibri core is an NLP tool as well as a C++ and Python library for working
  with basic linguistic constructions such as n-grams and skipgrams (i.e patterns
  with one or more gaps, either of fixed or dynamic size) in a quick and
  memory-efficient way. At the core is the tool colibri-patternmodeller which
  allows you to build, view, manipulate and query pattern models.
- *Python bindings* - python-ucto, python-frog, python-timbl (for Python 3)
- *CLAM* - Quickly build RESTful webservices (Python 2)

Some third-party NLP software is also installed out of the box.

Installation & Usage as Virtual Machine
=========================================

1. Obtain Vagrant from https://www.vagrantup.com/downloads.html or your package manager.
2. Obtain Virtual Box from https://www.virtualbox.org/ or your package manager.

On most Linux distributions, steps one and two may be combined with a simple command such as
``sudo apt-get install virtualbox vagrant`` on Ubuntu, or ``sudo pacman -Syu virtualbox vagrant`` on Arch Linux.

3. Clone this repository and navigate to the directory in the terminal
4. Power up the VM: ``vagrant up`` (this will download and install everything
the first time)
5. SSH into your VM: ``vagrant ssh``
6. When done, power down the VM with: ``vagrant halt`` (and you can delete it entirely with ``vagrant destroy``)

You may want to adapt Vagrantfile to change the number of CPUs and Memory
available to the VM (2 CPUs and 3GB RAM by default).


Installation & Usage with Docker
=========================================

1. Obtain Docker from http://www.docker.com or your package manager (``sudo apt-get install docker`` on Ubuntu).
2. Pull the LaMachine image: ``docker pull proycon/lamachine``
3. Start an interactive prompt to LaMachine: ``docker run  -t -i proycon/lamachine /bin/bash``, or run stuff: ``docker run proycon/lamachine <program>``  (use ``run -i`` if the program has an interactive mode; set up a mounted volume to pass file from host OS to docker, see: https://docs.docker.com/userguide/dockervolumes/)






 
