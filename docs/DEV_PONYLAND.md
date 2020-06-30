# Setting up your own LaMachine Development Environment on Ponyland

## Introductions

These instructions explain how to set-up and use your own LaMachine Development
Environment on ponyland, the computing cluster at CLST, Radboud University, Nijmegen.

In many instances, you won't need this and can simply use the existing
LaMachine environment that is preinstalled for you (simply type ``lm`` to
activate it). If you require, say extra Python packages, or other software, you
can simply request so by mailing ``admin AT cls.ru.nl``.

You need your own development environment if you yourself want to have full
control over the environment, for instance to install Python packages yourself,
or if you want to be ensured that version upgrades happen only under your own
control. If you develop complex software solutions with many interconnected
components, such as CLAM webservices, kaldi ASR systems, then you will likely
want your own development environment.

## Preparation

In order not to duplicate any instructions, the reader is assumed to be familiar with the general [LaMachine documentation](https://github.com/proycon/LaMachine/blob/master/README.md) and understand what LaMachine is and does.

## First Installation (Bootstrap)

Change directory to the place where you want to install LaMachine, we recommmend one of the tensusers partitions as we will need a considerable amount of diskspace:

```
$ cd /vol/tensusers/$USER
```

We will be using Installation Option A, as explained in the documentation:

```
bash <(curl -s https://raw.githubusercontent.com/proycon/LaMachine/master/bootstrap.sh)
```

Opt for a local installation in a user environment (option 1), when asked. You
can opt for either the stable version of LaMachine or the development version,
the latter will choose unreleased development versions of included software,
which may be want you want for development purposes, especially if the sofware
you develop is already a part of LaMachine.

If the script asks you if you have root privileges, you should answer no, as
you do not have any on the servers. The script will warn you that this may pose
a problem, but all global dependencies for LaMachine should already be
installed on the ponies anyway, allowing you to proceed without root
permissions.

During the bootstrap process, you will be asked

1. whether you want to adapt the configuration
2. which packages included in LaMachine you want to install

You will only need to adapt the configuration (point 1) in case you use any resources that are
not publicly available but are password-protected, the username and password
can be entered as parameters in configuration (e.g. ``fame_user``,``fame_password``, ``eng_ASR_user``, ``eng_ASR_password``).

If you plan to use kaldi, you will need to add the option:
``kaldi_configure_options: --shared``, otherwise it won't compile properly on
ponyland.

It's best to leave the other parameters untouched unless you know what you are doing.

For point 2, you can select which packages you want to install, LaMachine can
figure out dependencies itself so you don't need to be too explicit, make sure
they all line up precisely otherwise you get a syntax error.

Some of the packages again draw from non-public sources (such as private gitlab
instances). This complicates installation somewhat, because if you make use of
any such closed repositories you will need to make sure that you have a
(passwordless) SSH keys set-up and configured that has access the repositories.
Our general recommendation, as a matter of good open source development
practise, is to work in the open as much as possible and not to close down
source repositories.

Once you're happy with configuration and the installation manifest,
installation will begin, and depending on your selection, may take quite some
time as a lot of things are compiled from source. After thirty minutes to an
hour, you should hopefully be presented with the message that all went well. If
not, reconsider some of the things we said above, and take a look at the
troubleshooting section of the
[documentation](https://github.com/proycon/LaMachine/blob/master/README.md), or
at the [issue tracker](https://github.com/proycon/LaMachine/issues), to report the problem if it has not already been reported
by someone else.

## Usage

Make sure to activate your LaMachine environment each time you want to use it.
Follow the instructions in the general documentation.

## Updating

See the instructions in the general documentation. Do be aware that if you are
working directly on sources in ``$LM_PREFIX/src``, the LaMachine update will overwrite
them and discard (stash) any uncommited changes! So always git commit your work before updating.

## Development

### Best-practise guidelines

Make sure to always follow certain best-practise guidelines for your development:

* Always use version control, preferably public
* Provide a proper setup/install script with your software, following the best-practises of the software ecosystem you are using.
* Add some form of documentation, at least a README
* Do never encode system-specific absolute paths in your software! Make sure it is always configurable
* Use a semantic versioning scheme.
* If you intend for your software to be included in LaMachine: make sure to follow the guidelines mentioned [here](https://github.com/proycon/LaMachine/blob/master/CONTRIBUTING.md)

### Development of software that is already included in LaMachine

If the software package you are doing development on is already part of
LaMachine, you will find its sources in ``$LM_PREFIX/src`` and can develop
directly from there. For any other software projects, it doesn't really matter
where you keep the sources.

### Python

For Python-based development, we strongly recommend including a ``setup.py`` to
make your project properly installable.  During the development process within
LaMachine, to make your package available, you can run ``pip install -e .`` (or ``python setup.py develop``)
from within the directory that holds your ``setup.py`` (instead of ``pip
install .`` or ``python setup.py install``), this will do an *editable*
development installation, rather than a normal one. This means you can keep
editing the sources without needing to install it every time.

When your software is done we recommend publishing it with the Python Package
Index, making it installable through ``pip`` for everyone.

### CLAM

If you are developing a CLAM webservice, clamnewproject should have several
files for you, along with instructions on how to use them. You should have a
``*.$HOST.yml`` file specific to the system you are running on, where you can
set system-specific configuration values. Running the included
``startserver_development.sh`` script will subsequently start the development
server. The service will subsequently be accessible directly on a certain port,
however, if you are on ponyland this port is not directly accessible from the
outside word. You will have to dig an ssh tunnel to reach it:

Say you are running the webservice on port 8080 on mlp09 (blossomforth) and
want to access it from your local system outside the RU network, then dig a
double-SSH tunnel as follows:

```
$ ssh -L 8080:localhost:9999 mlp01.science.ru.nl ssh -L 9999:localhost:8080 -N mlp09.science.ru.nl
```

After this, you can point your local webbrowser to your local IP
``http://127.0.0.1:8080`` and have your connection forwarded to the webservice
in development that you ran on mlp09. The development service will
automatically reload on any code changes you make.

### Kaldi

Do not set an absolute path to ``$KALDI_ROOT`` in your ``path.sh`` (or anywhere
else). The ``$KALDI_ROOT`` should already be set by LaMachine for you (``$LM_PREFIX/opt/kaldi``).

Do not store anything in the ``$KALDI_ROOT`` yourself (it may get overwritten on update), keep your own stuff neatly
separated from the rest of kaldi.

Ideally your models should be kept separated from your scripts as well, with the latter stored in a version-controlled
repository. The models themselves are likely too big for git. So keep them in a single directory for development
purposes and provide a tar.gz or zip file or this directory for distribution. This latter point is of concern
especially when you intend to include your kaldi-based system in LaMachine. The downloadable archive of the models can
then be put in (a directory) in ``mlp01:/var/www/applejack/live/htdocs/downloads/`` (mail ``admin AT cls.ru.nl`` if you need
permission to write there), so LaMachine can download it.

The Kaldi_NL scripts and models are available in ``$LM_PREFIX/opt/kaldi_nl``, if you opted for their
installation. The scripts are all in a git repository, whereas the models are downloaded by a script, in the manner
described above.

### C/C++ with GNU Autotools

If you build and install your proejct, you will want to use ``./configure --prefix=$LM_PREFIX`` prior to ``make
&& make install`` so it is installed in the proper place in the LaMachine environment. For other build systems, set a
similar target directory.


