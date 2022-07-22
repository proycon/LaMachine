---
cover: true
slogan: An easily installable distribution of Natural Language Processing software
extracredit: Machine photo by Japhen Simpson, Llama photo by S1ghtly
---

{::options parse_block_html="true" /}
<section>

What is LaMachine?
=====================

**IMPORTANT NOTE: LaMachine is end-of-life and being deprecated. See this post for reasons and alternative solutions**

LaMachine is a software distribution of NLP software developed by the Language
Machines research group and CLST (Radboud University Nijmegen), as well as TiCC
(Tilburg University).

Our software is highly specialised and generally depends on a lot of other
software. Installing all this software can be a daunting task, compiling it
from scratch even more so.  Ideally software is installed through your
distribution's package manager, but we do not always have packages available
for all platforms, or they may be out of date. LaMachine ensures you can always
use all of our software at the very latest stable versions by bundling
them all and offering them in three distinct forms:

 * As a **Virtual Machine** - Easiest, allows you to run our software on any host OS.
 * As a **Docker application**
 * As a compilation/installation script in a **virtual environment**

LaMachine is suitable for both end-users and developers. It has to be noted,
however, that running the latest development versions always comes with the
risk of decreased stability due to undiscovered bugs.

</section>

{::options parse_block_html="true" /}
<section>
Pre-installed software
========================

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
- [Gecco](https://github.com/proycon/gecco) - Generic Environment for Context-Aware Correction of Orthography
- [Toad](https://github.com/LanguageMachines/toad) - Trainer Of All Data, training tools for Frog
- [foliadocserve](https://github.com/proycon/foliadocserve) - FoLiA Document Server
- [FLAT](https://github.com/proycon/flat) - FoLiA Linguistic Annotation Tool

Optional additional software:
- [T-scan](https://github.com/proycon/tscan) - T-scan is a Dutch text analytics tool for readability prediction.
- [Valkuil](https://github.com/proycon/valkuil-gecco) - A context-aware spelling corrector for Dutch
- [TICCL](https://github.com/martinreynaert/TICCL) - A spelling correction and OCR post-correction system
- [Alpino](http://www.let.rug.nl/vannoord/alp/Alpino/), a dependency parser and tagger for Dutch (about 1GB)

Both the VM image as well as the docker image are based on Arch Linux.

</section>

{::options parse_block_html="true" /}
<section>

Installation & Usage as Virtual Machine (for Linux, BSD, MacOS X, Windows)
=========================================================================

1. Obtain **Vagrant** from [their site](https://www.vagrantup.com/downloads.html) or your package manager.
2. Obtain **VirtualBox** from [their site](https://www.virtualbox.org/) or your package manager.
3. Clone this repository and navigate to the directory in the terminal: ``$ git clone https://github.com/proycon/LaMachine && cd LaMachine``  (or [download the ZIP](https://github.com/proycon/LaMachine/archive/master.zip) manually from github)
4. Power up the VM: ``vagrant up`` (this will download and install everything the first time)
5. SSH into your VM: ``vagrant ssh``
6. When done, power down the VM with: ``vagrant halt`` (and you can delete it entirely with ``vagrant destroy``)

You may want to adapt Vagrantfile to change the number of CPUs and Memory
available to the VM (2 CPUs and 3GB RAM by default).

On most Linux distributions, steps one and two may be combined with a simple command such as
``sudo apt-get install virtualbox vagrant`` on Ubuntu, or ``sudo pacman -Syu virtualbox vagrant`` on Arch Linux.

Entering your LaMachine Virtual Machine as per step 5 should be password-less,
other methods may require a login; use username ``vagrant`` and password
``vagrant``.  The root password is also ``vagrant``.

Various webservices in the Virtual Machine will be automatically accessible through https://127.0.0.1:8080 .

Note that LaMachine by default is running on a 64-bit architecture, if you have
a 32-bit host OS and really want to run LaMachine despite likely memory shortage;
checkout the ``32bit`` branch after step 3 and before step 4 by issuing the
following command: ``git checkout 32bit``.

Make sure to also read our privacy section below.

</section>

{::options parse_block_html="true" /}
<section>

Installation & Usage with Docker (for Linux only)
===================================================

1. Obtain **Docker** from the [Docker site](http://www.docker.com or your package manager) (``sudo apt-get install docker.io`` on Debian/Ubuntu).
2. Pull the [LaMachine image](https://registry.hub.docker.com/u/proycon/lamachine/): ``docker pull proycon/lamachine`` (or the executable may be named ``docker.io`` on Debian/Ubuntu)
3. Start an interactive prompt to LaMachine: ``docker run -p 8080:80 -t -i proycon/lamachine``, or run stuff: ``docker run proycon/lamachine <program>``  (use ``run -i`` if the program has an interactive mode; set up a mounted volume to pass file from host OS to docker, see [here](https://docs.docker.com/userguide/dockervolumes/))

There is no need to clone this git repository at all for this method.

</section>

{::options parse_block_html="true" /}
<section>
Installation & Usage locally (for Linux/BSD/Mac OS X/Windows 10)
==================================================================

LaMachine can be used on a Linux/BSD/Mac OS X systems without root access (provided a set of prerequisites is available
on the system or installed by a system administrator!) and even on Windows 10 systems, provided the latter has the
Windows Subsystem for Linux and Ubuntu on Windows installed (so if you use Windows, see
[here](https://msdn.microsoft.com/en-us/commandline/wsl/install_guide) for instructions first).

This local flavour of LaMachine runs in an extended Python Virtual Environment (using Python 3.3 or later) and is the option with
least overhead (i.e. the most performant). This offers a local environment (not a virtual machine!), ideal for development, that binds against
the software globally available on your system. The virtual environment will be contained under a single directory and
contains everything.  All sources are pulled from git and compiled for you.


Installation
--------------

0. Open a command line terminal
1. **Obtain a copy of LaMachine** in a temporary location (it will only be needed once).
   * A copy is best obtained through git: ``$ cd /tmp && git clone https://github.com/proycon/LaMachine``, provided you have git installed already (``sudo apt-get install git`` installs it on Ubuntu/Debian systems)
   * Alternatively, you can [download the ZIP](https://github.com/proycon/LaMachine/archive/master.zip) from github and extract it: ``$ cd /tmp && wget https://github.com/proycon/LaMachine/archive/master.zip && unzip master.zip``
2. In a terminal, **navigate to the directory** where you want to install
   LaMachine, for instance your home directory:  ``$ cd ~``.
   A ``lamachine/`` directory that contains everything will be automatically created in the next step.
   (Advanced users can also pre-create and activate an existing virtual environment that LaMachine will then reuse.)
3. **Bootstrap the virtual environment** by calling: ``/tmp/LaMachine/virtualenv-bootstrap.sh``
   * Do not run this as root, you will be queried for ``sudo`` for specific parts pertaining to the installation of
   required global packages.

Usage
--------------

Note that you will always have to activate your virtual environment before you can use any of the applications installed
in it.

1. Navigate to the directory where you installed LaMachine (e.g. ``cd ~/lamachine``)
   * Note that this is not the same as the temporary ``/tmp/LaMachine`` we created during installation
2. Run ``. bin/activate`` (don't forget the dot and the space!)

In most configurations, your prompt will change to indicate LaMachine is activated.

To facilitate activation, we recommend you add an alias ``alias lm=". /path/to/lamachine/bin/activate"`` to your
``~/.bashrc`` (or ``~/.zshrc`` or whatever shell you prefer), allowing you to simply activate LaMachine by typing
``lm``.

Parameters
---------------

You can add the following optional arguments to ``virtualenv-bootstrap.sh`` (and ``lamachine-update.sh``):

 * ``noadmin`` - Do not attempt to install global dependencies (but if they are missing, compilation will fail)
 * ``adminonly`` - Only install global dependencies, do not actually set up the virtual environment. Requires a user
   with sudo rights. Allows for seperation of the bootstrap process for privileged and non-privileged user.
 * ``nopythondeps`` - Do not update 3rd party Python dependencies (such as numpy and scipy), may save time.
 * ``force`` - Force recompilation of everything, even if it's not updated
 * ``python2`` - Use python 2.7 instead of Python 3 *(note that some software may be not be available for Python 2!)*
 * ``stable`` - Use stable releases  *(this is the new default since February 2016)*
 * ``dev`` - Use cutting-edge development versions *(this may sometimes breaks things)*
 * ``version=`` - Use the specified version file *(see the versioning section below)*
 * ``private`` - Do not send information to us regarding your LaMachine installation *(see the privacy section below)*
 * ``branch=`` - Use the specified git branch of LaMachine *(default: master)*

The latter five parameters are persistent, if you specify them once during
installation or upgrade you won't need to the next time you upgrade your LaMachine.

Compatibility
---------------

Tested to work on:

 * Arch Linux
 * Debian 8
 * Debian 9
 * Fedora Core 21
 * CentOS 7
 * Ubuntu 16.04 LTS - Xenial Xerus
 * Ubuntu 15.10 - Wily Werewolf
 * Ubuntu 15.04 - Vivid Vervet
 * Ubuntu 14.04 LTS - Trusty Tahr
 * Windows 10 with Ubuntu Linux 14.04 Subsystem

Partially works on:
 * Mac OS X Yosemite/El Capitán/and later  *(wopr does not work yet, python-frog breaks, gecco and toad are not available; optional software valkuil and tscan are not supported)*

Deprecated:
 * Ubuntu 12.04 LTS - Precise Pangolin
 * CentOS 6
 * Debian 7

Updating & Extra Software
===========================

Once you have a LaMachine running in whatever form, just run ``lamachine-update.sh`` to update
everything again.

The ``lamachine-update.sh`` script is also used to install additional *optional* software, pass the optional software as a parameter (multiple are allowed, or just used the ``all`` parameter to install all optional software):

 * ``tscan`` - Compile and install tscan (will download about 1GB in data), t-scan also suggests you install [Alpino](http://www.let.rug.nl/vannoord/alp/Alpino/) (another 1GB), which is not included in LaMachine.
 * ``valkuil`` - Valkuil Spelling Corrector (for Dutch)
 * ``foliaentity`` - Named entity linker
 * ``alpino`` - [Alpino](http://www.let.rug.nl/vannoord/alp/Alpino/), a dependency parser and tagger for Dutch (about 1GB)

Note that for the docker version, you can pull a new docker image using ``docker pull proycon/lamachine`` instead. If you do use ``lamachine-update.sh`` with docker, you most likely will want to ``docker commit`` your container afterwards to preserve the update!

</section>

{::options parse_block_html="true" /}
<section>
Updating & Extra Software
=============================

Once you have a LaMachine running in whatever form, just run ``lamachine-update.sh`` to update
everything again.

The ``lamachine-update.sh`` script is also used to install additional *optional* software, pass the optional software as a parameter:

 * ``tscan`` - Compile and install tscan (will download about 1GB in data), t-scan also suggests you install [Alpino](http://www.let.rug.nl/vannoord/alp/Alpino/) (another 1GB), which is not included in LaMachine.
 * ``valkuil`` - Valkuil Spelling Corrector (for Dutch)
 * ``ticcl`` - Text-induced Corpus Clean-up: a spelling correction and OCR post-correction system  (the TICCL root directory will be in ``src/TICCL`` in your LaMachine environment)

Note that for the docker version, you can pull a new docker image using ``docker pull proycon/lamachine`` instead. If you do use ``lamachine-update.sh`` with docker, you most likely will want to ``docker commit`` your container afterwards to preserve the update!
</section>


{::options parse_block_html="true" /}
<section>
Privacy
============

Unless you explicitly opt-out, LaMachine send a few details to us regarding
your installation of LaMachine whenever you install or update it. This is to
help us keep track of its usage and improve it.

The following information is sent:
* The form in which you run LaMachine (vagrant/virtualenv/docker)
* Is it a new LaMachine installation or an update
* Stable or Development?
* The OS you are running on and its version (only for the virtualenv form)
* Your Python version

Your IP address will only be used to identify your country and not used in any
other way. No personally identifiable information whatsoever will be included
in any reports we generate from this and it will never be used for
advertisement purposes.

To opt-out of this behaviour, For the ``virtualenv-boostrap.sh`` and
``lamachine-update.sh`` scripts, add the parameter ``private``. For the VM
method, prior to building the VM, edit ``Vagrantfile`` and add the ``private``
parameter after ``bootstrap.sh``. Due to the nature of Docker, installation of
Docker images are not tracked by us (but may be by Docker itself).

LaMachine downloads software from a number of external sources, depending on the form you choose,
which may or may not collect your IP:

 * [Github](https://github.com)
 * [The Python Package Index](https://pypi.python.org)
 * [The Arch Linux User Repository](https://aur.archlinux.org)
 * [Docker](https://docker.io)
</section>


{::options parse_block_html="true" /}
<section>
Versioning
============

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
</section>

{::options parse_block_html="true" /}
<section>
Webservices
==================

LaMachine comes with several webservices ready out of the box
(source: https://github.com/proycon/clamservices). These are RESTful webservices served
using CLAM, but also offer a web-interface for human end-users.

In the Virtual Machine variant of LaMachine, these are all running and available out-of-the
box. In the docker variant, you will need to explicitly start the services
first, this is done using the following command *from within* the container:

``sudo /usr/src/LaMachine/startwebservices.sh``

All webservices are then accessible through http://127.0.0.1:8080 (ensure that
this port is free) *from your host system*. For Docker you have to run the
container with the ``-p 8080:80`` for the port forward to be active.

Webservices/webapplications are currently available for the following software:

 * ucto
 * Frog
 * timbl
 * Colibri Core
 * PICCL
 * FoLiA Document Server
 * FLAT: FoLiA Linguistic Annotation Tool

For the LaMachine Virtual Environment, however, you have to start and access each service individually using CLAM's
built-in development server, only one is set up to run at a time:

 * ``clamservice clamservices.config.ucto``
 * ``clamservice clamservices.config.frog``
 * ``clamservice clamservices.config.timbl``
 * ``clamservice clamservices.config.colibricore``
 * ``clamservice picclservice.picclservice``

For FLAT in the virtual environment, run the following:
 * ``start-flat.sh``

Each webservice/webapplication will itself advertise on what port it has been launched and how to
access it.

Note that there is no or poor authentication enabled on the webservices, so do not
expose them to the outside world!
</section>

{::options parse_block_html="true" /}
<section>
Alternatives
====================

If you have no need for a VM or a self-contained environment, and you have
proper administrative access to the system, then it may be possible to install
our software using the proper package manager, provided we have packages
available. Our sofware release procedure and channels are visualised below:

![Sofware release scheme](https://raw.githubusercontent.com/proycon/LaMachine/master/softwarereleasescheme.png)


Details:

 * Arch Linux (up to date) -- https://aur.archlinux.org/packages/?SeB=m&K=proycon , these packages are used as the basis of LaMachine VM and Docker App, and are freshly pulled from git.
 * Debian Linux (up to date for Debian 9 [stretch] or later only) -- ``sudo apt-get install science-linguistics``. Consult the [package state](https://qa.debian.org/developer.php?login=proycon@anaproy.nl).
 * Ubuntu Linux (packages are currently out of date until Ubuntu 17.04 Zesty Zapus)
 * Mac OS X (homebrew), missing most sofware (most notably Frog, Colibri Core, and Python bindings)
 * CentOS/Fedora (packages are outdated completely, do not use)

The final alternative is obtaining all software sources manually (from github or tarballs) and compiling everything yourself, which can be a tedious endeavour.

Troubleshooting
====================

If you use the Python virtual environment and come across the error ``undefined
symbol: _PyTraceback_Add`` upon updating LaMachine. Then some dependencies are
still making a reference to the global Python interpreter, which has a newer
version than the one in the virtual environment. You can fix this issue by
copying the newer global version of the Python interpreter into your virtual
environment as follows: ``cp /usr/bin/python3.4 $VIRTUAL_ENV/bin/python3``.
Then run ``lamachine-update.sh`` again.

On some older version you may run into a syntax error error similar to the following when running ``lamachine-update.sh``:
 ``/home/proycon/lamachine/bin/lamachine-update.sh: line 775: syntax error near unexpected token `fi'``
 ``/home/proycon/lamachine/bin/lamachine-update.sh: line 775: `fi'``
In this case, simply run ``lamachine-update.sh`` again and the problem will correct itself.
</section>

<a href="http://applejack.science.ru.nl/languagemachines" style="display: block"><img src="http://applejack.science.ru.nl/lamabadge.php/LaMachine" alt="badge" /></a>
