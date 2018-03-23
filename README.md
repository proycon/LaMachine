[![Language Machines Badge](http://applejack.science.ru.nl/lamabadge.php/LaMachine)](http://applejack.science.ru.nl/languagemachines/)
[![Build Status](https://travis-ci.org/proycon/LaMachine.svg?branch=master)](https://travis-ci.org/proycon/LaMachine)
[![Docker Pulls](https://img.shields.io/docker/pulls/proycon/lamachine.svg)](https://hub.docker.com/r/proycon/lamachine/)

LaMachine
===========

LaMachine is a unified software distribution for Natural Language Processing.  We integrate numerous open-source NLP
tools, programming libraries, web-services, and web-applications in a single Virtual Research Environment that can be
installed on a wide variety of machines.

The software included in LaMachine tends to be highly specialised and generally depends on a lot of other interdependent
software.  Installing all this software can be a daunting task, compiling it from scratch even more so. LaMachine
attempts to make this process easier by offering pre-built recipes for a wide variety of systems, whether it is on your
home computer or whether you are setting up a dedicated production environment, LaMachine will safe you a lot of work.

We address various audiences; the bulk of the software is geared towards data scientists who are not afraid of the
command line and some programming. We give you the instruments and it is up to you to yield them. However, we also
attempt to accommodate researchers that require more high-level interfaces by incorporating webservices and websites
that expose some of the functionality to a larger audience.

Installation
---------------

### Custom build (recommended)

To build your own LaMachine instance, in any of the possible flavours, open a terminal on your Linux, BSD or Mac OS X
system and run the following command:

```
bash <(curl -s https://raw.githubusercontent.com/proycon/LaMachine/lamachine2/bootstrap.sh)
```

This will prompt you for some questions on how you would like your LaMachine build and allows you to include precisely
the software you want or need and ensures that all is up to date.

Are you on Windows 10? Then you need to run this command in a Linux subsystem in Windows 10/2016 or above; to do this you must first
install the Linux Subsystem with a distribution of your choice (we recommend Ubuntu) from the Microsoft Store. Follow
the instructions [here](https://msdn.microsoft.com/en-us/commandline/wsl/install_guide). Are you on an older Windows,
then this won't work you have will to use a pre-built Virtual Machine.

### Pre-built container image for Docker

We regularly build a basic LaMachine image an publish it to [Docker Hub](https://hub.docker.com/r/proycon/lamachine/).
To download and use it, run:

```
docker pull proycon/lamachine:stable
docker run  -p 8080:80 -t -i proycon/lamachine:stable
```

This requires you to already have [Docker](https://www.docker.com/) installed and running on your system.

The pre-built image contains only a basic set of common software rather than the full set, run ``lamachine-stable-update --edit``
inside the container to select extra software to install. Alternatively, other specialised LaMachine builds may be available
on Docker Hub.

### Pre-built Virtual Machine image for Vagrant

We regularly build a basic LaMachine image and publish it to the [Vagrant Cloud](https://app.vagrantup.com/proycon/).
To download and use it, run:

```
vagrant init proycon/lamachine
vagrant up
vagrant ssh
```

This requires you to already have [Vagrant](https://www.vagrantup.com/) and [VirtualBox](https://www.virtualbox.org) installed on your system.

The pre-built image contains only a basic set of common software rather than the full set, run ``lamachine-stable-update --edit``
inside the virtual machine to select extra software to install.

Included Software
---------------------

LaMachine includes a wide variety of open-source NLP software. You can select which software you want to include during
the installation procedure.

* by the Centre of Language and Speech Technology, Radboud University Nijmegen
    * [Timbl](https://languagemachines.github.io/timbl) - Tilburg Memory Based Learner
    * [Ucto](https://languagemachines.github.io/ucto) - Tokenizer
    * [Frog](https://languagemachines.github.io/frog) - Frog is an integration of various memory-based natural language processing (NLP) modules developed for Dutch. It can do Part-of-Speech tagging, lemmatisation, named entity recogniton, shallow parsing, dependency parsing and morphological analysis.
    * [Mbt](https://languagemachines.github.io/mbt) - Memory-based Tagger
    * [Wopr](http://ilk.uvt.nl/wopr) - Memory-based Word Predictor
    * [FoLiA-tools](http://proycon.github.io/folia) - Command line tools for working with the FoLiA format
    * [PyNLPl](https://pypi.python.org/pypi/PyNLPl) - Python Natural Language Processing Library
    * [Colibri Core](http://proycon.github.io/colibri-core/) - Colibri core is an NLP tool as well as a C++ and Python library for working with basic linguistic constructions such as n-grams and skipgrams (i.e patterns with one or more gaps, either of fixed or dynamic size) in a quick and memory-efficient way.
    * *C++ libraries* - [ticcutils](https://github.com/LanguageMachines/ticcutils), [libfolia](https://github.com/LanguageMachines/libfolia)
    * *Python bindings* - [python-ucto](https://github.com/proycon/python-ucto), [python-frog](https://github.com/proycon/python-frog), [python-timbl](https://github.com/proycon/python-timbl)
    * [CLAM](https://proycon.github.io/clam) - Quickly build RESTful webservices
    * [Gecco](https://github.com/proycon/gecco) - Generic Environment for Context-Aware Correction of Orthography
    * [Valkuil](https://github.com/proycon/valkuil-gecco) - A context-aware spelling corrector for Dutch
    * [Toad](https://github.com/LanguageMachines/toad) - Trainer Of All Data, training tools for Frog
    * [foliadocserve](https://github.com/proycon/foliadocserve) - FoLiA Document Server
    * [FLAT](https://github.com/proycon/flat) - FoLiA Linguistic Annotation Tool
    * [TICCLTools](https://github.com/LanguageMachines/ticcltools) - Tools that together constitute the bulk of TICCL: Text Induced Corpus-Cleanup.
    * [PICCL](https://github.com/LanguageMachines/PICCL) - PICCL: A set of workflows for corpus building through OCR, post-correction (using TICCL) and Natural Language Processing.
* by the University of Groningen
    * [Alpino](http://www.let.rug.nl/vannoord/alp/Alpino/), a dependency parser and tagger for Dutch
* by Utrecht University
    * [T-scan](https://github.com/proycon/tscan) - T-scan is a Dutch text analytics tool for readability prediction (initially developed at TiCC, Tilburg University).
* Major third party software (not exhaustive!):
    * [Python](https://python.org)
    * [NumPy](http://www.numpy.org/) and [SciPy](http://www.numpy.org/) - Python libraries for scientific computing
    * [Matplotlib](http://matplotlib.org) - A Python 2D plotting library producing publication quality figures
    * [Scikit-learn](http://matplotlib.org) - Machine learning in Python
    * [Tesseract](https://github.com/tesseract-ocr/tesseract) - Open Source Optical Character Recognition (OCR)
    * [IPython](http://ipython.org/) and [Jupyter](https://jupyter.org/) - A rich architecture for interactive computing.
    * [Pandas](http://pandas.pydata.org/) - Python Data Analysis Library
    * [NLTK](http://www.nltk.org) - Natural Language Toolkit for Python
    * [Hunspell](http://hunspell.github.io) - A spell checker
    * [NextFlow](http://www.nextflow.io) - A system and language for writing parallel and scalable pipelines in a portable manner.
    * [R](https://r-project.org)

Note that some software may not be available on certain platforms/distributions (most notably Mac OS X).

Architecture
-------------------

LaMachine can be installed in multiple *flavours*:

 * **Global installation** - Installs LaMachine globally on a Linux/BSD machine. (only one per machine)
 * **Local installation** - Installs LaMachine locally in a user environment on a Linux/BSD or Mac OS X machine (multiple per machine possible)
 * **Docker container** - Installs LaMachine in a docker container
 * **Virtual Machine** - Installs LaMachine in a Virtual Machine

In all cases, the installation is mediated through [Ansible](https://www.ansible.com). Containerisation uses
[Docker](https://docker.com). Virtualisation is made possible through [Vagrant](https://vagrantup.com) and
[VirtualBox](https://virtualbox.org). The local installation variant uses virtualenv with some custom extensions.

LaMachine uses [Debian](https://www.debian.org) as primary Linux distribution (for virtualisation and containerisation), but
derivatives like Ubuntu and certain other distributions such as RHEL, CentOS, Fedora and Arch Linux are also supported
(though may be unsupported by a minority of participating software).

Initially, the user executes a ``bootstrap.sh`` script that acts as a single point of entry for all flavours. It will
automatically download LaMachine and create the necessary configuration files for your LaMachine build, guiding you
through all the options. It will eventually invoke a so-called ansible playbook that executes installation steps for all
of the individual software projects included in LaMachine, depending on your distribution and flavour.

In addition to a flavour, users can opt for one of three versions of LaMachine:
 * **stable** - Installs the latest official releases of all participating software
 * **development** - Installs the latest development versions of participating software, this often means they are
   installed straight from the latest git version.
 * **custom** - Installs explicitly defined versions for all software (for e.g. scientific reproducibility).


Usage
------------

How to start LaMachine differs a bit depending on your flavour.

### Local Environment

Run the generated activation script to activate the local environment (here we assume your LaMachine VM is called **stable**!):
* Run``lamachine-stable-activate``

### Virtual Machine

If you built your own LaMachine you have various scripts at your disposal (here we assume your LaMachine VM is called **stable**!):
* Run``lamachine-stable-start`` to start the VM
* Run``lamachine-stable-connect`` to connect to a running VM and obtain a command line shell (over ssh)
* Run``lamachine-stable-stop`` to stop the VM
* Run``lamachine-stable-destroy`` to completely delete the VM again
* ``lamachine-stable-activate`` is a shortcut that starts the VM and connects automatically, and stops the VM when you
  disconnect again.

If you used a prebuilt image you have to invoke ``vagrant`` yourself from the proper directory where you did ``vagrant
init proycon/lamachine:stable``:
* Run ``vagrant up`` to start the VM
* Run ``vagrant halt`` to stop the VM
* Run ``vagrant ssh`` to connect to the VM and obtain a command line shell
* Run ``vagrant destroy`` to remove the VM

Command line access to your LaMachine Virtual Machine through vagrant or ``lamachine-*-connect`` should be passwordless, other methods
may require a login; use username ``vagrant`` and password ``vagrant``.  The root password is also ``vagrant``. Change
these in any exposed environments!

If you enabled a webserver in your LaMachine build, you can connect your web browser to http://127.0.0.1:8080 after having started the
VM.

### Docker Container

In this example we assume your LaMachine image has the tag **stable**, run ``docker image ls`` to see all images you have available:

* To start a **new** interactive container, run ``docker run -i -t proycon/lamachine:stable``
* To start a **new** container with a command line tool, just append the command: ``docker run -t proycon/lamachine:stable ucto -L nld /data/input.txt /data/output.folia.xml``
	* Add the ``-i`` flag if the tool is an interactive tool that reads from standard input (i.e. keyboard input).
* To start a **new** container with the server: ``docker run -p 8080:80 -h hostname -t proycon/lamachine:stable lamachine-start-webserver``
	* The numbers values for ``-p`` are the port numbers on the host side and on the container side respectively, the latter must always match with the ``http_port`` setting LaMachine has been built with.
	* Set ``-h`` with the desired hostname, this too must match the setting LaMachine has been built with.
	* If started in this way, you can connect your webbrowser on the host system to http://127.0.0.1:8080 .

If you use LaMachine with docker, we expect you to actually be familiar with
docker and understand the difference between images, containers, how to commit
changes (``docker commit``), and how to reuse existing containers if that is
what you need (``docker start``, ``docker attach``).

### Updating LaMachine

When you are inside LaMachine, you can update it by running ``lamachine-update``, if you first want to edit your LaMachine's settings and/or the packages to be
installed/updated, run ``lamachine-update --edit`` instead.

The update normally only updates what has changed, if you want to force an update of everything instead, run
``lamachine-update force=1``.

For Docker and the Virtual Machine flavours, when a SUDO password is being asked by the update script, you can simply
press ENTER and leave it empty, do not run the entire script with escalated privileges.

### Webservices and web applications

LaMachine comes with several webservices and web applications out of the box
(source: https://github.com/proycon/clamservices). Most are RESTful webservices served
using [CLAM](https://proycon.github.io/clam), which also offer a generic web-interface for human end-users.

To start the webserver and webservices, run ``lamachine-start-webserver`` from within your LaMachine installation. You
can then connect your browser (on the host system) to http://localhost:8080 (the port may differ if you changed the
default value).

Note that there is no currently or poor authentication enabled on the webservices, so do not
expose them to the outside world!

Privacy
============

Unless you explicitly opt-out, LaMachine sends a few details to us regarding your installation of LaMachine whenever you
build a new one or update an existing one. This is to help us keep track of its usage and improve it.

The following information is sent:
* The form in which you run LaMachine (vagrant/local/docker)
* Is it a new LaMachine installation or an update
* Stable or Development?
* The OS you are running on and its version
* Your Python version

Your IP address will only be used to identify your country and not used in any
other way. No personally identifiable information whatsoever will be included
in any reports we generate from this and it will never be used for
advertisement purposes.

To opt-out of this behaviour, set ``private: true`` in your LaMachine settings.

During build and upgrade, LaMachine downloads software from a wide variety of external sources.

Versioning
============

    (this section needs to be (re)written still and is out of date!)

LaMachine outputs a ``VERSION`` file for each installation or upgrade. The
version file contains the exact version numbers of all software installed.  You
can find this file in either in your virtual environment directory or in the
root directory (Vagrant/Docker).

You can use the VERSION file to bootstrap LaMachine with specific versions. For
the virtual environment form of LaMachine, add the argument
``version=/path/to/your/VERSIONfile`` when running ``virtualenv-bootstrap.sh``.
For the Vagrant form, substitute the dummy ``VERSION`` file with one of your
own and adapt ``Vagrantfile`` according to the instructions prior to running
``vagrant up``. For Docker, you'll have to adapt ``Dockerfile`` and build the
image locally, or rely on an earlier published build.

This versioning is intended to facilitate scientific reproducibility and
deployment of production environments. The caveat to always keep in mind is
that the versions you run may be outdated and not have any of the latest
improvements/fixes applied.

Note that only our own software and certain Python dependencies are subject to
this versioning scheme, generic system packages and libraries will always be at
their latest versions.

Alternatives
================

If you have no need for a VM or a self-contained environment, and you have
proper administrative access to the system, then it may be possible to install
our software using the proper package manager, provided we have packages
available.

Details:

 * Arch Linux (up to date) -- https://aur.archlinux.org/packages/?SeB=m&K=proycon , these packages are used as the basis of LaMachine VM and Docker App, and are freshly pulled from git.
 * Debian Linux (up to date for Debian 9 [stretch] or later only) -- ``sudo apt-get install science-linguistics``. Consult the [package state](https://qa.debian.org/developer.php?login=proycon@anaproy.nl).
 * Ubuntu Linux (packages are currently out of date until Ubuntu 18.04)
 * Mac OS X (homebrew), missing some sofware (Colibri Core, Python bindings, PICCL, Gecco)

The final alternative is obtaining all software sources manually (from github or tarballs) and compiling everything yourself, which can be a tedious endeavour.

Frequently Asked Questioned & Troubleshooting
=================================================

#### Q: Do I need LaMachine?

A: This depends on the software you are interested in and the kind of system you are on. LaMachine is offered as a
convenience but draws from other software repositories which you can also access directly.

You may want to first check if our software packages are available for your Linux distribution. For C++ software such as
Frog, ucto and Timbl, we provide packages for:

 * Debian Linux 9 [stretch] or higher -- Consult the [package state](https://qa.debian.org/developer.php?login=proycon@anaproy.nl).
 * Ubuntu Linux 18.04 or higher
 * Arch Linux  -- https://aur.archlinux.org/packages/?SeB=m&K=proycon
 * Mac OS X (homebrew) -- https://github.com/fbkarsdorp/homebrew-lamachine/tree/master/Formula
 * A final alternative is obtaining all software sources manually (from github or tarballs) and compiling everything yourself, which can be a tedious endeavour.

Python software is generally provided through the [Python Package Index](https://pypi.python.org) and can be installed
using ``pip install``.

#### Q: Why is my LaMachine installation so big??

A LaMachine installation quickly reaches 6GB, and even more if you enable software that is not enabled by default.
LaMachine is a research environment that can be used in a wide variety of ways which we can't predict in advance, so we
by default include a lot of popular software for maximum flexibility. When building your LaMachine, you can disable
software groups you don't want and save space.

You can also limit the size somewhat by setting ``minimal: true`` in your LaMachine configuration, but this may mean that
certains tools don't fully work.

Disk space is also, by far, the cheapest resource, in contrast to memory or CPU.

#### Q: Can I run LaMachine in a 32-bit environment?

No

#### Q: Can I run LaMachine with Python 2.7 instead of 3?

No

#### Q: Can I run LaMachine on an old Linux distribution?

No, your Linux distribution needs to be up to date and supported.

#### Q: Can I include my own software in LaMachine?

Yes! See the contribution guidelines!

