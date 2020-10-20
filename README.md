[![Language Machines Badge](http://applejack.science.ru.nl/lamabadge.php/LaMachine)](http://applejack.science.ru.nl/languagemachines/)
[![Build Status](https://travis-ci.org/proycon/LaMachine.svg?branch=master)](https://travis-ci.org/proycon/LaMachine)
[![Docker Pulls](https://img.shields.io/docker/pulls/proycon/lamachine.svg)](https://hub.docker.com/r/proycon/lamachine/)
[![Project Status: Active – The project has reached a stable, usable state and is being actively developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)

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
on your Linux, BSD or MacOS system and run the following command:

```
bash <(curl -s https://raw.githubusercontent.com/proycon/LaMachine/master/bootstrap.sh)
```

This will prompt you for some questions on how you would like your LaMachine installation and allows you to include precisely
the software you want or need and ensures that all is up to date. A screenshot is shown at the end of this subsection.

Are you on Windows 10 or 2016? Then you need to run this command in the Windows Linux subsystem, we do not support
Windows natively. To do this you must first install the Linux Subsystem with a distribution of your choice (we recommend
Ubuntu) from the Microsoft Store. Follow the instructions
[here](https://msdn.microsoft.com/en-us/commandline/wsl/install_guide). Alternatively, you may want to choose for a pre-built Virtual Machine image as explained in installation path C.

Building LaMachine can take quite some time, depending also on your computer's resources, internet connection, and the
amount of software you selected to install. Half an hour to an hour is a normal build time. The bootstrap script
alternatively also offers the option to download pre-built images (installation path B & C).

![LaMachine bootstrap](/docs/screenshot_bootstrap.jpg?raw=true "LaMachine Bootstrap")

### B) Pre-built container image for Docker

We regularly build a basic LaMachine image and publish it to [Docker Hub](https://hub.docker.com/r/proycon/lamachine/).
The above installation path A also offers access to this, but you may opt to do it directly:

To download and use it, run:

```
docker pull proycon/lamachine
docker run  -p 8080:80 -h latest -t -i proycon/lamachine
```

This requires you to already have [Docker](https://www.docker.com/) installed and running on your system.

The pre-built image contains the stable version with only a basic set of common software rather than the full set, run ``lamachine-add``
inside the container to select extra software to install. Alternatively, other specialised LaMachine builds may be available
on Docker Hub.

If you want another release, specify its tag explicitly:

```
docker pull proycon/lamachine:develop
docker run  -p 8080:80 -h develop -t -i proycon/lamachine:develop
```

### C) Pre-built Virtual Machine image for Vagrant (recommended for Windows users)

We regularly build a basic LaMachine image and publish it to the [Vagrant Cloud](https://app.vagrantup.com/proycon/).
The above installation path A also offers (simplified) access to this (except on Windows), but you may opt to do it directly.

To download and use a LaMachine prebuilt image:

* Ensure you have  [Vagrant](https://www.vagrantup.com/) and [VirtualBox](https://www.virtualbox.org) installed on your system. Windows users also have to make sure that Hyper-V is *disabled* in *Control Panel → Programs → Turn Windows features on or off → Hyper-V*
* Open a terminal or command prompt
* Navigate to a folder of your choice (using ``cd``); this will be the base folder, files inside will be shared within the VM under
    ``/vagrant``
* Download [this example vagrant file](https://github.com/proycon/LaMachine/blob/master/Vagrantfile.prebuilt.erb) into
    that same folder. If you are on linux or macOS you can download directly from command line like this: ``wget https://raw.githubusercontent.com/proycon/LaMachine/master/Vagrantfile.prebuilt.erb``
* Run ``vagrant init --template Vagrantfile.prebuilt.erb proycon/lamachine`` from the terminal.
* Open ``Vagrantfile`` in a text editor and change the memory and CPU options to suit your system (the more resources
  the better!).
   * On an up-to-date windows 10 installation (at least version 1809), you can use Notepad as a text editor, but on older Windows versions this won't work and you need a better text editor!
* Run ``vagrant up`` from the terminal to boot your VM
* Run ``vagrant ssh`` from the terminal to connect to the VM

The pre-built image contains only a basic set of common software rather than the full set, run ``lamachine-stable-update --edit``
inside the virtual machine to select extra software to install.

To stop the VM when you're done, run: ``vagrant halt``. Next time, navigate to the same base folder in your terminal and run ``vagrant
up`` and ``vagrant ssh`` again.

## Included Software

LaMachine includes a wide variety of open-source NLP software. You can select which software you want to include during
the installation procedure (or any subsequent update).

* by the Centre of Language and Speech Technology, Radboud University Nijmegen (CLST, RU)
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
* by the Vrije Universiteit Amsterdam (VU)
    * [KafNafParserPy](https://github.com/cltl/KafNafParserPy) - A python module to parse NAF files
* by Utrecht University (UU)
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
      * [Spacy](https://spacy.io) - Industrial-Strength NLP in Python
      * [FLAIR](https://github.com/zalandoresearch/flair) - Framework for state-of-the-art sequence modelling through
          word embeddings
    * [fastText](https://fasttext.cc/) - Library for efficient text classification and representation learning (has a Python binding)
    * [R](https://r-project.org)
    * [Java](http://openjdk.java.net/)
      * [NextFlow](http://www.nextflow.io) - A system and language for writing parallel and scalable pipelines in a portable manner.
      * [Stanford CoreNLP](https://stanfordnlp.github.io/CoreNLP/) - Various types of linguistic enrichment
    * [Hunspell](https://hunspell.github.io) - A spell checker
    * [Tesseract](https://github.com/tesseract-ocr/tesseract) - Open Source Optical Character Recognition (OCR)
    * [Tensorflow](https://tensorflow.org) - Open-source machine learning framework
    * [Kaldi](http://kaldi-asr.org) - Speech Recognition Framework (ASR)
    * [Moses](http://www.statmt.org/moses) - Statistical Machine Translation system

Note that some software may not be available on certain platforms/distributions (most notably macOS).

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

 * **Local installation** - Installs LaMachine locally (natively) in a user environment on Linux or macOS machine (multiple per machine possible)
 * **Global installation** - Installs LaMachine globally (natively) on a Linux machine. (only one per machine)
 * **Docker container** - Installs LaMachine in a docker container
 * **Virtual Machine** - Installs LaMachine in a Virtual Machine
 * **LXC container** - Installs LaMachine in an LXC/LXD container.
 * **Remote installation** - Installs LaMachine globally (natively) on another Linux machine. (only one per machine)

In all cases, the installation is mediated through [Ansible](https://www.ansible.com), providing a level of abstraction
over whatever underlying technology is employed. Containerisation uses [Docker](https://docker.com) or
[LXD](https://linuxcontainers.org/lxd/introduction/). Virtualisation is
made possible through [Vagrant](https://vagrantup.com) and [VirtualBox](https://virtualbox.org). The local installation
variant uses virtualenv with some custom extensions.

Initially, the user executes a ``bootstrap.sh`` script that acts as a single point of entry for all flavours. It will
automatically download LaMachine and create the necessary configuration files for your LaMachine build, guiding you
through all the options. It will eventually invoke a so-called ansible playbook that executes installation steps for all
of the individual software projects included in LaMachine, depending on your distribution and flavour.

LaMachine uses [Debian](https://www.debian.org) as primary Linux distribution (for virtualisation and containerisation),
we support the distributions/platforms listed below for a native installation of LaMachine (i.e. compiled against the libraries
of that distribution). We distinguish three categories of support (and for all we only support the x86-64 architecture):

* **Gold support** - All participating software should work on these platforms and things are tested frequently. The
    pre-built LaMachine containers and VMs we offer always use one of these.
  * Debian 10 (buster)  (next: Debian 11)
  * Ubuntu 20.04 LTS (next: Ubuntu 22.04 LTS)

* **Silver support** - Most software should work.
  * Debian 9 (stretch) - The previous stable release
  * Ubuntu 18.04 LTS - The previous LTS release
  * CentOS 8 / RedHat Enterprise Linux 8 - This is offered because it is a popular choice in enterprise environments.
    Testing is less frequent though.

* **Bronze support** - Certain software is known not to work and/or things are more prone to breakage and have not been
    tested.
  * Debian testing (bullseye) and debian unstable (sid) - Should work but not tested.
  * Ubuntu (a non-LTS version) - Should work as long as it's newer than the one mentioned under silver support, but not tested.
  * macOS (a recent version) - Not all software is supported on macOS by definition, but a considerable portion does
      work. Things are a bit more prone to break if the user's environment has been heavily tweaked and differs from the
      stock experience.
  * Arch Linux (rolling release; things tend to work fine for most software but the nature of a rolling release makes breakages more common, e.g. on each major Python upgrade)
  * Linux Mint (recent version) - Supported in principle due to being an Ubuntu derivative, but not really tested so there could be surprises
  * Fedora (latest version); supported in principle but not really tested.

* **Deprecated**:
  * Ubuntu 14.04 LTS
  * Ubuntu 16.04 LTS
  * CentOS 7 / RedHat Enterprise Linux 7

* **Unsupported (not exhaustive!)** - We can not support these because our effort reached its limits:
  * FreeBSD and other BSDs
  * openSuSE / SuSE
  * Alpine
  * Gentoo
  * Void Linux
  * nixOS
  * Solaris
  * Windows

Note that this concerns the platforms LaMachine runs on natively or on which you can bootstrap your own build
(installation path A). The options for host platforms for simply running a pre-built LaMachine Virtual Machine or Docker
container, are much larger, and also include Windows (see installation paths B & C).

In addition to a flavour, users can opt for one of three versions of LaMachine:
 * **stable** - Installs the latest official releases of all participating software
 * **development** - Installs the latest development versions of participating software, this often means they are
   installed straight from the latest git version.
 * **custom** - Installs explicitly defined versions for all software (for e.g. scientific reproducibility).

Read more about the technical details in [the contributor documentation](https://github.com/proycon/LaMachine/blob/develop/CONTRIBUTING.md).

## Usage

How to start LaMachine differs a bit depending on your flavour.

### Local Environment

Run the generated activation script to activate the local environment (here we assume your LaMachine VM is called **stable**!):
* Run ``source lamachine-stable-activate`` or ``lamachine-stable-activate``, this script should be located in your
  ``~/bin`` directory.

![LaMachine terminal screenshot](/docs/screenshot_venv_activate.jpg?raw=true "Activating the LaMachine local environment")

### Virtual Machine

If you built your own LaMachine you have various scripts at your disposal (here we assume your LaMachine VM is called **stable**! The script names will be different for other names, replace as needed):
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

#### Port Mapping to the Virtual Machine

If you want to connect to a particular special-purpose server (not a
webservice) inside the VM from your host system, then you often need to forward
a port from your host system into the LaMachine VM, as for all intents and
purposes, they should be considered two separated systems. This applies for
instance when you want to use the server mode offered by software such as Frog
or Alpino (again, this is completely different and independent from the
**web**services that LaMachine also offers).

From LaMachine 2.6.2 onward, the
port 9999 is forwarded by default for the VM, meaning that if you connect to
port 9999 on your local machine (IP 127.0.0.1), it will be forwarded to port
9999 in the LaMachine VM.

If you want to open any additional ports, you need to
do so in Virtualbox for your LaMachine VM. Consult [this
guide](https://www.simplified.guide/virtualbox/port-forwarding) for easy and
illustrated instructions on how to set this up in the VirtualBox interface, or
alternatively consult the relevant chapter in the [Virtualbox
Manual](https://www.virtualbox.org/manual/ch06.html#natforward) itself.

### Docker Container

If you used the LaMachine bootstrap script, you will have several scripts at your disposition (we assume that your
LaMachine VM is called stable, adapt the script names to your own situation). If you instead issued a ``docker pull
proycon/lamachine`` manually you will need to run the docker commands yourself:

* Run ``lamachine-stable-activate`` to start a **new** interactive container
    * This corresponds to ``docker run -i -t proycon/lamachine``
* Run ``lamachine-stable-run`` to start the command specified as a parameter in a **new** container (e.g.  ``lamachine-stable-run frog``)
    * This corresponds to : ``docker run -i -t proycon/lamachine:latest frog``
        * You can omit the ``-i`` flag if the tool is not an interactive tool that reads from standard input (i.e. keyboard input).
* Run ``lamachine-stable-start`` to start a webserver and all enabled webservices in a **new** LaMachine container:
    * This corresponds to: ``docker run -p 8080:80 -h hostname -t proycon/lamachine:latest lamachine-start-webserver -f ``
        * The numbers values for ``-p`` are the port numbers on the host side and on the container side respectively, the latter must always match with the ``http_port`` setting LaMachine has been built with (defaults to 80).
        * Set ``-h`` with the desired hostname, this too must match the setting LaMachine has been built with!
        * The ``-f`` argument to ``lamachine-start-webserver`` ensures the script waits in the foreground and doesn't exit after starting. In a docker context,
          this also makes the script a valid entrypoint (PID 1).
	* If started in this way, you can connect your webbrowser on the host system to http://127.0.0.1:8080 .

The scripts will automatically share your designated data directory (your home directory by default) with the container, mounted at ``/data`` by default. To manually make persistent storage available in the container, e.g. for sharing data, use docker parameters like: ``--mount type=bind,source=/path/on/host,target=/data``

If you use LaMachine with docker, we expect you to actually be familiar with docker and understand the non-persistent
nature of containers, understand the difference between images and containers. Be aware that new containers are created
every time you run any of the above commands. If you want a more VM-like container experience, you can consider LXD
instead of Docker.

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

Updating everything can be a time-consuming endeavour. If you know what you are doing then you can limit your update to
certain packages, you can specify these packages (as a comma separated list) to the ``--only`` parameter, e.g:
``lamachine-update --only python-core,java-core``. Do be aware that this could result in your LaMachine ending up in an
unusable state (in which case a normal update should remedy the problem again).

### Webservices and web applications

LaMachine comes with several webservices and web applications out of the box.
Most are RESTful webservices served using [CLAM](https://proycon.github.io/clam), which also offer a generic
web-interface for human end-users. The webserver provides a generic portal to all available services, powered by
[Labirinto](https://github.com/proycon/labirinto), as shown in the screenshot below:

![portal_screenshot](/docs/screenshot_portal.jpg?raw=true "Screenshot of the portal in LaMachine")

To start (or restart) the webserver and webservices, run ``lamachine-start-webserver`` from within your LaMachine
installation. You can then connect your browser (on the host system) to http://localhost:8080 (the port may differ if
you changed the default value). On virtual machines, the webserver will be automatically started at boot. For
docker you can do: ``docker run -p 8080:80 -h hostname -t proycon/lamachine:latest lamachine-start-webserver -f ``

**Warning: There is currently no or poor authentication enabled on the webservices, so do not
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

* Our recommended bootstrap procedure downloads a script and immediately executes it. This is offered
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
If things fail, most software providers, us included, will not deliver support on older software versions.

The purpose of this custom versioning feature of LaMachine is to aid scientific reproducibility, with it you can build
an environment consisting of older software, corresponding to the versions at the time you ran your experiments. In such
cases you should publish a version of ``customversions.yml`` along with your data (and a copy of the installation
manifest ideally).

This custom versioning is limited, it only pertains to software that is 1) not provided by the linux distribution
itself, and 2) explicitly installed by LaMachine, rather than dependencies that are pulled in automatically by package
managers. Even then, certain sofware is excluded from this scheme as the upstream provider does not provide the
necessary facilities for obtaining older versions, LaMachine should output a warning in the log if that is the case. It
is also not supported on MacOS.

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
 * macOS (homebrew) -- https://github.com/fbkarsdorp/homebrew-lamachine/tree/master/Formula
 * A final alternative is obtaining all software sources manually (from github or tarballs) and compiling everything yourself, which can be a tedious endeavour.

Python software is generally provided through the [Python Package Index](https://pypi.python.org) and can be installed
using ``pip install``.

LaMachine shines as it combines a lot of software, includes complex set-ups, and handles some default configuration.

#### Q: Why is my LaMachine installation so big??

A LaMachine installation quickly reaches 6GB, and even more if you enable software that is not enabled by default.
LaMachine is a research environment that can be used in a wide variety of ways which we can't predict in advance, so we
by default include a lot of popular software for maximum flexibility. When building your LaMachine, you can disable
software groups you don't want and save space, or opt for extra dikspace (see the next question).

You can also limit the size somewhat by setting ``minimal: true`` in your LaMachine configuration, but this may mean that
certains tools don't fully work.

Disk space is also, by far, the cheapest resource, in contrast to memory or CPU.

#### Q: I get an error "no space left on device" in the VM or Docker flavour of LaMachine ([Issue #152](https://github.com/proycon/LaMachine/issues/152))

This means the virtual disk used by the virtual machine or container is full. This may especially occur if you select
some of the larger optional software packages. There is only limited space available in the VM or Docker container
(roughly 9GB). For the VM, when you bootstrap your own LaMachine image from scratch (an option currently not available
for Windows users though), you can opt to create extra diskspace (an extra volume).

For Docker, you may need to increase the base size of
your containers (depending on the storage driver you use for docker). Consult the docker documentation at
https://docs.docker.com/storage/storagedriver/ and do so now if you need this.

Advanced VM users can resolve the problem on their existing LaMachine VM by adding another virtual disk and moving some of the
data, but this requires a fair amount of Linux administration expertise on their part. The procedure is roughly as follows:
* Create an extra disk for the LaMachine VM in the VirtualBox interface (see for instance [this
    tutorial](https://www.zachpfeffer.com/single-post/Add-a-disk-to-an-Ubuntu-VirtualBox-VM) up to step 11).
* From within the LaMachine VM:
    * Partition the new disk (with ``fdisk`` or ``parted``)
    * Format the new disk (with ``mkfs.ext4``)
    * Add the new disk to ``/etc/fstab``
    * Move ``/usr/local`` (which is where most of LaMachine is installed) to the new disk
    * Symlink the old ``/usr/local`` to the new path on the new disk

#### Q: Can I run LaMachine in a 32-bit environment?

No

#### Q: Can I run LaMachine with Python 2.7 instead of 3?

No

#### Q: Can I run LaMachine on an old Linux distribution?

No, your Linux distribution needs to be up to date and supported.

#### Q: Can I include my own software in LaMachine?

Yes! [See the contribution guidelines](https://github.com/proycon/LaMachine/blob/develop/CONTRIBUTING.md)

#### Q: Can I run a graphical desktop environment in the LaMachine Virtual Machine? (X.org)

Though LaMachine does not provide this out-of-the-box, you can easily install a fully fledged desktop environment as
follows (do make sure you opted for extra diskspace during the bootstrap):

``apt-get install task-gnome-desktop`` (See https://wiki.debian.org/DesktopEnvironment)

To access the graphical desktop you will want to start LaMachine from the VirtualBox interface.

#### Q: Docker gives an error: "flag provided but not defined: --build-arg"

Your Docker is too old, upgrade to at least 1.9

#### Q: lamachine-update gives an error: error 'fragment_class is None' ([Issue #144](https://github.com/proycon/LaMachine/issues/144))

This error may appear when LaMachine updates from ansible 2.7 to 2.8, if this occurs, simply rerun the update.

#### Q: Someone provided me with a pre-build LaMachine VM image in the form of a *.box file, how do I use it?

This is a Vagrant box file. You will need to follow the instruction as specified in Installation section **C**, with the
following differences:

* **Prior** to running ``vagrant init``, you will need to run ``vagrant box add --name custom-lamachine /path/to/your/image.box`` (adapt the path to
    point to the box file you were given). You may change the name ``custom-lamachine`` to anything you like to identify
    this LaMachine image.
* Instead of ``vagrant init --template Vagrantbox.prebuilt.erb proycon/lamachine``, do ``vagrant init --template Vagrantbox.prebuilt.erb custom-lamachine`` (or another name if you changed it in the first step)

#### Q: I have another problem, can I report it?

Yes! Please report it in our [Issue Tracker](https://github.com/proycon/LaMachine/issues) after checking that the problem has
not already been reported (and solved perhaps) by someone else. Note that this is only for problems relating to the
installation and availability of the software; for bugs or feature requests on any of the participating software
(including our own), you should use the issue trackers pertaining to those software projects.

