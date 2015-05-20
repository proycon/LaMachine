Language Machines VM
=====================

A virtual machine based on Ubuntu Linux 14.04 (64-bit only) with bleeding-edge versions of
NLP software developed by the Language Machines research group,  CLST (Radboud University
Nijmegen), as well as TiCC (Tilburg University).

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

Installation & Usage
======================

1. Obtain Vagrant from https://www.vagrantup.com/downloads.html or your package manager.
2. Obtain Virtual Box from https://www.virtualbox.org/ or your package manager.

On most Linux distributions, steps one and two may be combined with a simple command:
* Ubuntu: ``sudo apt-get install virtualbox vagrant``
* Arch: ``sudo pacman -Syu virtualbox vagrant``

3. Clone this repository and navigate to the directory in the terminal
4. Power up the VM: ``vagrant up`` (this will download and install everything
the first time)
5. SSH into your VM: ``vagrant ssh``










 
