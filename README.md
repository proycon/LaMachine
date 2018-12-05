[![Language Machines Badge](http://applejack.science.ru.nl/lamabadge.php/LaMachine)](http://applejack.science.ru.nl/languagemachines/)
[![Build Status](https://travis-ci.org/proycon/LaMachine.svg?branch=master)](https://travis-ci.org/proycon/LaMachine)
[![Docker Pulls](https://img.shields.io/docker/pulls/proycon/lamachine.svg)](https://hub.docker.com/r/proycon/lamachine/)

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

## Installation

### A) Guided installation with custom build option (recommended)

To build your own LaMachine instance, in any of the possible flavours, or to download a pre-built image, open a terminal
on your Linux, BSD or Mac OS X system and run the following command:

```
bash <(curl -s https://raw.githubusercontent.com/proycon/LaMachine/master/bootstrap.sh)
```

This will prompt you for some questions on how you would like your LaMachine installation and allows you to include precisely
the software you want or need and ensures that all is up to date. A screenshot is shown at the end of this subsection.

Are you on Windows 10 or 2016? Then you need to run this command in a Linux subsystem; to do this you must first install
the Linux Subsystem with a distribution of your choice (we recommend Ubuntu) from the Microsoft Store. Follow the
instructions [here](https://msdn.microsoft.com/en-us/commandline/wsl/install_guide). Are you on an older Windows or you
are on Windows and want a VM and not a custom build? Then this won't work you have will to use a pre-built Virtual
Machine as explained in installation path C.

Building LaMachine can take quite some time, depending also on your computer's resources, internet connection, and the
amount of software you selected to install. Half an hour to an hour is a normal build time. The bootstrap script
alternatively also offers the option to download pre-built images (installation path B & C).

![LaMachine bootstrap](/docs/screenshot_bootstrap.jpg?raw=true "LaMachine Bootstrap")

### B) Pre-built container image for Docker

We regularly build a basic LaMachine image an publish it to [Docker Hub](https://hub.docker.com/r/proycon/lamachine/).
The above installation path A also offers access to this, but you may opt to do it directly:

To download and use it, run:

```
docker pull proycon/lamachine
docker run  -p 8080:80 -h latest -t -i proycon/lamachine
```

This requires you to already have [Docker](https://www.docker.com/) installed and running on your system.

The pre-built image contains the stable version with only a basic set of common software rather than the full set, run ``lamachine-stable-update --edit``
inside the container to select extra software to install. Alternatively, other specialised LaMachine builds may be available
on Docker Hub.

If you want another release, specify its tag explicitly:

```
docker pull proycon/lamachine:develop
docker run  -p 8080:80 -h develop -t -i proycon/lamachine:develop
```

### C) Pre-built Virtual Machine image for Vagrant (recommended for Windows users)

We regularly build a basic LaMachine image and publish it to the [Vagrant Cloud](https://app.vagrantup.com/proycon/).
The above installation path A also offers access to this (except on Windows), but you may opt to do it directly.

To download and use it:

* Ensure you have  [Vagrant](https://www.vagrantup.com/) and [VirtualBox](https://www.virtualbox.org) installed on your system. Windows users also have to make sure that Hyper-V is *disabled* in *Control Panel → Programs → Turn Windows features on or off → Hyper-V*
* Open a terminal or command prompt
* Navigate to a folder of your choice (this will the the base folder, files inside will be shared with the VM)
* Run ``vagrant init proycon/lamachine`` from the terminal, this creates a file named ``Vagrantfile``
* Open ``Vagrantfile`` in a text editor and change the memory and CPU options to suit your system (the more resources
  the better!).
   * If you are on Windows and don't have a decent text editor, just use wordpad (not Notepad nor MS Word!)
* Run ``vagrant up`` from the terminal to boot your VM
* Run ``vagrant ssh`` from the terminal to connect to the VM

The pre-built image contains only a basic set of common software rather than the full set, run ``lamachine-stable-update --edit``
inside the virtual machine to select extra software to install.

To stop the VM when you're done, run: ``vagrant halt``. Next time, navigate to the same base folder and run ``vagrant
up`` and ``vagrant ssh`` again.

## Included Software

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
    * [Labirinto](https://github.com/proycon/labirinto) - A web-based portal listing all available tools in LaMachine, an ideal starting point for LaMachine
    * [Oersetter](https://github.com/proycon/oersetter-webservice) - A Frisian<->Dutch Machine Translation system in
        collaboration with the Fryske Akademy
* by the University of Groningen
    * [Alpino](http://www.let.rug.nl/vannoord/alp/Alpino/) - a dependency parser and tagger for Dutch
* by the Vrije Universiteit Amsterdam
    * [KafNafParserPy](https://github.com/cltl/KafNafParserPy) - A python module to parse NAF files
* by Utrecht University
    * [T-scan](https://github.com/proycon/tscan) - T-scan is a Dutch text analytics tool for readability prediction (initially developed at TiCC, Tilburg University).
* by Meertens Instituut
    * [Python Course for the Humanities](http://www.karsdorp.io/python-course/) - Interactive tutorial and introduction into programming with Python for the humanities by Folgert Karsdorp & Maarten van Gompel (CLST, Nijmegen)
* Major third party software (not exhaustive!):
    * [Python](https://python.org)
      * [NumPy](http://www.numpy.org/) and [SciPy](http://www.numpy.org/) - Python libraries for scientific computing
      * [Matplotlib](http://matplotlib.org) - A Python 2D plotting library producing publication quality figures
      * [Scikit-learn](http://matplotlib.org) - Machine learning in Python
      * [IPython](http://ipython.org/) and [Jupyter](https://jupyter.org/) - A rich architecture for interactive computing.
        * **[Jupyter Lab](https://jupyterlab.readthedocs.io/en/stable/)** - The successor of the popular Jupyter Notebooks, offers notebooks, a web-based IDE, terminals. An ideal entry point to get started with LaMachine and all it contains!
      * [Pandas](http://pandas.pydata.org/) - Python Data Analysis Library
      * [NLTK](http://www.nltk.org) - Natural Language Toolkit for Python
      * [PyTorch](https://pytorch.org) - Deep-learning library for Python
    * [R](https://r-project.org)
    * [Java](http://openjdk.java.net/)
      * [NextFlow](http://www.nextflow.io) - A system and language for writing parallel and scalable pipelines in a portable manner.
      * [Stanford CoreNLP](https://stanfordnlp.github.io/CoreNLP/) - Various types of linguistic enrichment
    * [Hunspell](http://hunspell.github.io) - A spell checker
    * [Tesseract](https://github.com/tesseract-ocr/tesseract) - Open Source Optical Character Recognition (OCR)
    * [Tensorflow](https://tensorflow.org) - Open-source machine learning framework
    * [Kaldi](http://kaldi-asr.org) - Speech Recognition Framework (ASR)
    * [Moses](http://www.statmt.org/moses) - Statistical Machine Translation system

Note that some software may not be available on certain platforms/distributions (most notably Mac OS X).

For a verbose list of installed software and its metadata, run ``lamachine-list`` once you are inside your LaMachine
installation. For more information regarding software metadata, check the corresponding section in the [the contributor
documentation](https://github.com/proycon/LaMachine/blob/develop/CONTRIBUTING.md).

If you enabled and started the webserver in LaMachine, then you have access to a rich portal page giving an overview of
all installed software and providing access to any software with a web-based interface. This portal is powered by
[Labirinto](https://github.com/proycon/labirinto).

## Contribute

LaMachine is open for contributions by other software projects, please read [the contributor
documentation](https://github.com/proycon/LaMachine/blob/develop/CONTRIBUTING.md).

## Architecture

LaMachine can be installed in multiple *flavours*:

 * **Local installation** - Installs LaMachine locally in a user environment on a Linux/BSD or Mac OS X machine (multiple per machine possible)
 * **Global installation** - Installs LaMachine globally on a Linux/BSD machine. (only one per machine)
 * **Docker container** - Installs LaMachine in a docker container
 * **Virtual Machine** - Installs LaMachine in a Virtual Machine
 * **Remote installation** - Installs LaMachine globally on another Linux/BSD machine. (only one per machine)

In all cases, the installation is mediated through [Ansible](https://www.ansible.com), providing a level of abstraction
over whatever underlying technology is employed. Containerisation uses [Docker](https://docker.com). Virtualisation is
made possible through [Vagrant](https://vagrantup.com) and [VirtualBox](https://virtualbox.org). The local installation
variant uses virtualenv with some custom extensions.

Initially, the user executes a ``bootstrap.sh`` script that acts as a single point of entry for all flavours. It will
automatically download LaMachine and create the necessary configuration files for your LaMachine build, guiding you
through all the options. It will eventually invoke a so-called ansible playbook that executes installation steps for all
of the individual software projects included in LaMachine, depending on your distribution and flavour.

LaMachine uses [Debian](https://www.debian.org) as primary Linux distribution (for virtualisation and containerisation),
we generally support the following platforms (but certain participating software may not support all!):

 * Debian 9 (stretch) - *This is the primary platform and the only one for which ALL participating software is
   guaranteed to work*
 * Ubuntu 18.04 LTS
 * Ubuntu 16.04 LTS
 * Ubuntu 14.04 LTS - *Being phased out and not recommended*
 * CentOS 7 / RedHat Enterprise Linux 7
 * Fedora 27
 * Arch Linux
 * Mac OS X 10.13 (High Sierra) - *Limited functionality only! No webservices/applications. Various optional software will not support Mac OS X either*

This concerns the platforms LaMachine runs on natively or on which you can bootstrap your own build (installation path A). The options for host platforms
for simply running a pre-built LaMachine Virtual Machine or Docker container, are much larger, and also include Windows
(see installation paths B & C).

In addition to a flavour, users can opt for one of three versions of LaMachine:
 * **stable** - Installs the latest official releases of all participating software
 * **development** - Installs the latest development versions of participating software, this often means they are
   installed straight from the latest git version.
 * **custom** - Installs explicitly defined versions for all software (for e.g. scientific reproducibility).

Read more about the technical details in the [the contributor documentation](https://github.com/proycon/LaMachine/blob/develop/CONTRIBUTING.md).

## Usage

How to start LaMachine differs a bit depending on your flavour.

### Local Environment

Run the generated activation script to activate the local environment (here we assume your LaMachine VM is called **stable**!):
* Run ``source lamachine-stable-activate`` or ``lamachine-stable-activate``, this script should be located in your
  ``~/bin`` directory.

![LaMachine terminal screenshot](/docs/screenshot_venv_activate.jpg?raw=true "Activating the LaMachine local environment")

### Virtual Machine

If you built your own LaMachine you have various scripts at your disposal (here we assume your LaMachine VM is called **stable**!):
* Run ``lamachine-stable-start`` to start the VM
* Run ``lamachine-stable-connect`` to connect to a running VM and obtain a command line shell (over ssh)
* Run ``lamachine-stable-stop`` to stop the VM
* Run ``lamachine-stable-destroy`` to completely delete the VM again
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

In this example we assume your LaMachine image has the tag **latest**, which corresponds to the latest stable LaMachine release
(and can technically be omitted as it is the default), run ``docker image ls`` to see all images you have available:

* To start a **new** interactive container, run ``docker run -i -t proycon/lamachine:latest``
* To start a **new** container with a command line tool, just append the command: ``docker run -t proycon/lamachine:latest ucto -L nld /data/input.txt /data/output.folia.xml``
	* Add the ``-i`` flag if the tool is an interactive tool that reads from standard input (i.e. keyboard input).
* To start a **new** container with the webserver: ``docker run -p 8080:80 -h hostname -t proycon/lamachine:latest lamachine-start-webserver -f ``
	* The numbers values for ``-p`` are the port numbers on the host side and on the container side respectively, the latter must always match with the ``http_port`` setting LaMachine has been built with.
	* Set ``-h`` with the desired hostname, this too must match the setting LaMachine has been built with!
    * The ``-f`` argument ensures the script waits in the foreground and doesn't exit after starting.
	* If started in this way, you can connect your webbrowser on the host system to http://127.0.0.1:8080 .

If you use LaMachine with docker, we expect you to actually be familiar with
docker and understand the difference between images, containers, how to commit
changes (``docker commit``), and how to reuse existing containers if that is
what you need (``docker start``, ``docker attach``).

### Updating LaMachine

When you are inside LaMachine, you can update it by running ``lamachine-update``, if you want to add
extra software packages to your installation, run ``lamachine-add`` first (add ``--list`` for a list of installable packages).
You can also edit LaMachine's settings and/or directly edit the list of packages to be installed/updated with ``lamachine-update --edit``. Do note that
this can't be used to uninstall software.

The update normally only updates what has changed, if you want to force an update of everything instead, run
``lamachine-update force=1``. You can also use the even stronger ``force=2``, which will forcibly remove all downloaded sources
and start from scratch.

For Docker and the Virtual Machine flavours, when a SUDO password is being asked by the update script, you can simply
press ENTER and leave it empty, do not run the entire script with escalated privileges.

### Webservices and web applications

LaMachine comes with several webservices and web applications out of the box
Most are RESTful webservices served using [CLAM](https://proycon.github.io/clam), which also offer a generic
web-interface for human end-users. The webserver provides a generic portal to all available services, powered by
[Labirinto](https://github.com/proycon/labirinto), as shown in the screenshot below:

![portal_screenshot](/docs/screenshot_portal.jpg?raw=true "Screenshot of the portal in LaMachine")

To start (or restart) the webserver and webservices, run ``lamachine-start-webserver`` from within your LaMachine
installation. You can then connect your browser (on the host system) to http://localhost:8080 (the port may differ if
you changed the default value). On virtual machines, the webserver will be automatically started at boot. For
docker you can do: ``docker run -p 8080:80 -h hostname -t proycon/lamachine:latest lamachine-start-webserver -f ``

**Warning: There is no currently or poor authentication enabled on the webservices, so do not
expose them to the outside world!**

### Jupyter Lab

LaMachine comes with an installation of [Jupyter Lab](https://jupyterlab.readthedocs.io/en/latest/), which provides an excellent entry-point to LaMachine as it provides
a web-based scripting environment or IDE (for Python and R), web-based terminal access, and especially access to the
ubiquitous Jupyter Notebooks that enjoy great popularity in data science and beyond.

You can access your Jupyter Lab installation from the portal website of your LaMachine installation. By default
LaMachine also preinstalls the interactive [Python Course for the Humanities](http://www.karsdorp.io/python-course/) for you, so you can get started right
away.

![Jupyter Lab in LaMachine](/docs/screenshot_lab.jpg?raw=true "Jupyter Lab in LaMachine screenshot")

The default password for the Lab environment is *lamachine*, you can change this with ``lamachine-passwd lab``.

**Warning: Do not expose this service to the world without a strong customised password as it allows arbitrary code execution and full
access to your system!**

## Privacy

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

## Security

For a secure experience using LaMachine, take all of the following into account:

* Our recommended bootstrap procedures downloads a script and immediately executes it. This is offered
  as a convenience but carries some inherent risks and is generally not a secure practice. It implies a trust relation
  between you and us, as well as the hoster (github). Prudent users are encouraged to download the script,
  inspect it, and only then execute it. We may provide PGP-signed releases in the future.
* The bootstrap script asks for and requires root privileges for certain installation steps, this will always be asked and the user may confirm. The Ansible provisioning scripts also generally required a sudo, this will only be asked once, but the privileges will only be used when needed.
* Running either the bootstrap procedure or the subsequent ansible provisioning entirely as root is forbidden for
  security reasons.
* The current webserver configuration does not yet enable authentication for any of the webservices, so do *NOT* expose it directly to the internet without setting up authentication yourself.
* If you are sure you don't need a webserver/webservices, disable it in the configuration upon first build.
* The virtual machines tend to come with a preset username and password ``(vagrant:vagrant)``, the lamachine user in Docker containers has
  the password ``lamachine``, you will need to change this.
* Do not run development versions in a production environment, always use the stable release.
* Do not run an outdated LaMachine installation, ensure you regularly run ``lamachine-update`` for updates! Bugs and
  potential vulnerabilities may have been patched in the meantime.
* Only if your setup is otherwise secure (i.e. authentication on webservices), then make sure to always open only the necessary ports (80/443) to the internet, do not expose any of the UWSGI services to the world (this would allow arbitrary code execution).
* As per the GNU General Public Licence, we do not offer any warranty despite doing our best.

## Versioning

LaMachine comes in three versions, *stable* installs the latest stable releases of all software, *development* installs
the latest development releases and *custom* installs explicitly specified versions. This section is about the latter
and is for advanced users.

LaMachine itself also carries a version number, this number corresponds to the version of all the installation scripts
that make up LaMachine. It is not tied to the versions of any underlying software.

In any LaMachine installation (v2.3.0 and above), you can do ``lamachine-list -v`` to obtain a ``customversions.yml``
file that explicitly states what software versions are installed. When bootstrapping a new LaMachine
installation, you can place this ``customversions.yml`` file in the directory where you run the bootstrap, and opt for
the *custom* version. LaMachine will then install the exact versions specified.

You can edit this ``customversions.yml`` file if you have good reason to opt for very specific versions of certain
packages. Instead of an appropriate version number, you can also use the strings. Do be be aware that choosing version
numbers that do not exist or combining versions of different packages that are not compatible will surely break things.
If things fails, most software providers, us included, will not deliver support on older software versions.

The purpose of this custom versioning feature of LaMachine is to aid scientific reproducibility, with it you can build
an environment consisting of older software, corresponding to the versions at the time you ran your experiments. In such
cases you should publish a version of ``customversions.yml`` along with your data (and a copy of the installation
manifest ideally).

This custom versioning is limited, it only pertains to software that is 1) not provided by the linux distribution
itself, and 2) explicitly installed by LaMachine, rather than dependencies that are pulled in automatically by package
managers. Even then, certain sofware is excluded from this scheme as the upstream provider does not provide the
necessary facilities for obtaining older versions, LaMachine should output a warning in the log if that is the case.

If a strict reproduction environment is desired, we strongly recommend to use the docker or virtual machine flavour of LaMachine and
archive the entire resulting image.

## Frequently Asked Questioned & Troubleshooting

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

LaMachine shines as it combines a lot of software, includes complex set-ups, and handles some default configuration.

#### Q: Why is my LaMachine installation so big??

A LaMachine installation quickly reaches 6GB, and even more if you enable software that is not enabled by default.
LaMachine is a research environment that can be used in a wide variety of ways which we can't predict in advance, so we
by default include a lot of popular software for maximum flexibility. When building your LaMachine, you can disable
software groups you don't want and save space.

You can also limit the size somewhat by setting ``minimal: true`` in your LaMachine configuration, but this may mean that
certains tools don't fully work.

Disk space is also, by far, the cheapest resource, in contrast to memory or CPU.

If you use docker, be aware that you may need to increase the size limit if you build a custom LaMachine container and
run into size issues!

#### Q: Can I run LaMachine in a 32-bit environment?

No

#### Q: Can I run LaMachine with Python 2.7 instead of 3?

No

#### Q: Can I run LaMachine on an old Linux distribution?

No, your Linux distribution needs to be up to date and supported.

#### Q: Can I include my own software in LaMachine?

Yes! [See the contribution guidelines](https://github.com/proycon/LaMachine/blob/develop/CONTRIBUTING.md)

#### Q: Docker gives an error: "flag provided but not defined: --build-arg"

Your Docker is too old, upgrade to at least 1.9

#### Q: I have another problem, can I report it?

Yes! Please report it in our [Issue Tracker](https://github.com/proycon/LaMachine/issues) after checking that the problem has
not already been reported (and solved perhaps) by someone else. Note that this is only for problems relating to the
installation and availability of the software; for bugs or feature requests on any of the participating software
(including our own), you should use the issue trackers pertaining to those software projects.

