# Adding new software to LaMachine

## Requirements and guidelines

* Only add relevant NLP software
* LaMachine is only intended for POSIX-compliant systems (i.e. Linux, BSD, Mac OS X).
  Other systems such as Windows are only supported as a host system for a VM.
* All software must be in public version control (we recommend *github*), be *public*, and be fully *open source* with
  an explicitly stated licence.
* LaMachine distinguishes between latest development versions and stable
  releases. If your software is mature enough to be released, please do so
  using the releases mechanism on github. Version numbers should use semantic versioning and start with a **v** (like
  v0.1.2; the ``major.minor.revision`` format is recommended)
* The latest state of the ``master`` branch of your repository will be considered the development version.
* If there is a suitable software repository for your software (such as the [Python Package
  Index](https://pypi.python.org) for Python, [CPAN](https://wwww.cpan.org) for
  Perl, [CRAN](https://www.cran.org) for R, [Maven](https://search.maven.org) for Java); use it to publish stable releases.
  LaMachine can in turn obtain it from these
  repositories.
* Your software should have at some form of documentation, at least a decent README
* Any Python software should support Python 3 (and not just 2.7)
* The software should be maintained and should work on modern linux distributions.
  LaMachine is not intended for legacy or archiving purposes.

## Why use LaMachine?

Why should you want to participate in LaMachine to distribute your software?

* LaMachine comes in many flavours and is not just a containerisation solution (e.g. Docker). We use Ansible to offer
  a good and clear level of abstraction, allowing it to work with multiple technologies (Vagrant, Docker, local installation, global installation).
  It also removes the need to mess with Dockerfile or Vagrantfile yourself, as this is something LaMachine handles for
  you.
* LaMachine already offers a lot of NLP software; this may include software your tool depends on or software people like
  to use independently in combination with your tool.
* LaMachine supports multiple modern Linux distributions, offering flexibility rather than forcing a single one.
* LaMachine aims to provide a Virtual Research Environment
* From a user perspective, LaMachine is easy to install (one command bootstrap).
* LaMachine comes with an extensive test framework.
* LaMachine is extensively documented.
* LaMachine does not replace or reinvent existing technologies, but builds on them: Linux Distributions, Ansible, Vagrant, Docker, pip, virtualenv
    * This means LaMachine remains an optional solution to make things easier, but build on established installation methods that remain usable outside LaMachine.

## How to contribute?

Contributors are expected to be familiar with git and github:

* Fork the LaMachine github repository
* Add a role for your software in ``roles/``  (read the rest of this documentation to learn how)
* When all done, create a pull request on Github

## LaMachine Architecture

LaMachine consists primarily of installation and configuration recipes for [Ansible](https://ansible.org). These recipes
are called *playbooks* by Ansible, or more specifically they are called *roles* when used in a modular fashion as we do.
Roles are defined in a simple [YAML syntax](http://docs.ansible.com/ansible/latest/YAMLSyntax.html) in combination with
a powerful [templating language](http://docs.ansible.com/ansible/latest/playbooks_templating.html).

A role or playbook defines tasks, each task is an installation or configuration
step. A task has a name and references a certain Ansible module based on the
type of work to do, there is for example a ``copy`` module to copy files onto
the destination system, a ``file`` module to create files/directories and set
proper owners ship, an ``include_role`` module that calls another role with
specific parameters (this is heavily used in LaMachine), and hundreds more.
A task may also define [a condition](http://docs.ansible.com/ansible/latest/playbooks_conditionals.html)
for its execution through a ``when`` statement.

LaMachine provides a full framework with various predefined *roles* and preset
*variables*.  The framework allows for installation in various forms (docker, VM, local, global). A single
``bootstrap.sh`` script is used build any desired form; it does the necessary preprocessing and finally invokes Ansible.

First we take a look at the variables defined in LaMachine:

### Variables

The variables are generally set by the end-user in the LaMachine configuration
when building or updating LaMachine. These determine the type of environment to
build, as LaMachine offers quite some flexibility through its different
flavours, versions, and is meant to work on multiple Linux distributions.

We distinguish the following variables, all of which you can read and use in your Ansible roles for LaMachine:

* *Generic:*
  * ``version`` -- The version of LaMachine, is either ``stable``, ``development``, or ``custom``.
  * ``locality`` - Set to either ``local`` or ``global`` and determines whether LaMachine is installed in a local user environment (see ``localenv_type``) or globally on the system. For Virtual Machines and Docker Containers, this value will be set to global.
    * ``localenv_type`` - The type of local environment (only makes sense if ``locality == "local"``), can only be set to ``virtualenv`` for now, meaning we use a Python VirtualEnv.
* *Permissions:*
  * ``root``	 - A boolean indicating whether LaMachine has root permission on the system (necessarily true if ``locality == "global"``)
  * ``unix_user`` - The unix user that owns and runs LaMachine.
* *Paths:*
  * ``lm_prefix`` - The path where LaMachine installs its software. This equals too
    * ``local_prefix`` - The local installation path (i.e., the path of the virtual enviroment)
    * ``global_prefix`` - The global installation path (by default ``/usr/local``)
  * ``homedir`` - The path to the home directory for the user that owns and runs LaMachine
  * ``lamachine_path`` - The path to where the LaMachine repository (with all the ansible roles and templates) is cloned on disk
  * ``source_path`` - The path to where sources for packages will be downloaded
  * ``data_path`` - The path where the end-user can store data (this is typically shared with the host system, if applicable)
* *Network:*
  * ``hostname`` - The hostname of the system
  * ``webserver`` - (boolean) Include a webserver or not
  * ``http_port`` - port the webserver will listen on
  * ``web_user`` - The unix user that runs the webserver and webservices
* *Other:*
  * ``private`` - (boolean) Send basic analytics back to us
  * ``minimal`` - (boolean) A minimal installation is requested (might break some stuff)

### Directory layout

It is important to understand the directory layout used by LaMachine and to adhere to it when adding software yourself.
The variable ``lm_prefix`` is most important here, as it holds the base directory under which all software is installed.
For a global installation (in the Docker and Virtual Machine flavours for instance), this by default corresponds to
``/usr/local`` (don't let the word *local* confuse you here, we are still talking about a global installation). In a
local installation ``lm_prefix`` corresponds to the directory containing the virtual environment, which can be anywhere the user desires.

We try to follow the [Filesystem Hierarchy Standard](https://wiki.linuxfoundation.org/lsb/fhs) as much as possible:

 * ``{{lm_prefix}}/bin`` - Holds executable binaries other executable scripts; this will be added to your
   environment's ``$PATH`` upon activation
   * ``{{lm_prefix}}/bin/activate.d`` - Extra shell scripts for activating the environment for specific software, will be sourced automatically by the main LaMachine activation script
 * ``{{lm_prefix}}/lib`` - Holds shared libraries; this will be added to your environments library path.
   * ``{{lm_prefix}}/lib/python3.*/site-packages`` - Contains installed Python modules.
 * ``{{lm_prefix}}/include`` - Holds development header files
 * ``{{lm_prefix}}/src`` - Holds sources of the software, symlinks to ``{{source_path}}``
 * ``{{lm_prefix}}/opt`` - Holds optional application software, for which each application is stored in a single directory under this path. This is common for software that is not typically distributed in a more unix-like fashion.
 (e.g. Alpino, PICCL, Nextflow), but we also use it to symlink to certain software.
 * ``{{lm_prefix}}/share`` - Shared data files
 * ``{{lm_prefix}}/var`` - Holds variable files.
   * ``{{lm_prefix}}/var/log/nginx`` - Holds log files by the webserver.
   * ``{{lm_prefix}}/var/log/uwsgi`` - Holds log files for the individual uwsgi-powered (e.g. CLAM, Django) webservices/webapplications.
 * ``{{lm_prefix}}/etc`` - Holds configuration files
   * ``{{lm_prefix}}/etc/nginx/nginx.conf`` - Generic webserver configuration (in global installations this will symlink to the system-wide ``/etc/nginx``)
   * ``{{lm_prefix}}/etc/nginx/conf.d/*.conf`` - Configurations per webservice/webapplication.
   * ``{{lm_prefix}}/etc/uwsgi-emperor/vassals/`` - Holds individual uwsgi configuration files for uwsgi-powered webservices/webapplications
   * ``{{lm_prefix}}/etc/*.clam.yml`` - External configuration files for specific CLAM webservices

### Reusable Roles

We supply  *roles* that are built for reuse (they all start with
``lamachine-*``) and are meant to to install software from one or more external
repositories:

* ``lamachine-python-install`` - Install Python software
	* Expects a ``package`` variable that is a dictionary/map with the following fields:
      * ``github_user`` - The user/group that holds the github repository (used by the development version of LaMachine)
      * ``github_repo`` - The name of the github repository (used by the development version of LaMachine)
      * ``pip`` - The name of the package in the Python Package Index (used by the stable version of LaMachine)
* ``lamachine-package-install`` - Install Distribution packages
	* Expects a ``package`` variable that is a dictionary/map with one or more of the following fields:
      * ``debian`` - The package name for APT on debian/ubuntu/mint systems.
      * ``redhat`` - The package name for YUM on fedora/redhat/rhel/centos systems.
      * ``arch`` - The package name for Arch Linux
      * ``homebrew`` - The package name for Homebrew on Mac OS X
* ``lamachine-git-autoconf`` -  Install C++ software hosted in git and which makes use of the GNU autotools (autoconf/automake), i.e. software that follows the classic  ``./configure && make && make install`` paradigm.
	* Expects a ``package`` variable that is a dictionary/map with the following fields:
      * ``user`` - The user/group that holds the github repository (used by the development version of LaMachine)
      * ``repo`` - The name of the github repository (used by the development version of LaMachine)
      * You can also pass any of the variables used by ``lamachine-register``, as this will be called automatically.

Some lower-level roles:
* ``lamachine-git`` - Clone a particular git repository
* ``lamachine-run`` - Run a particular command in the LaMachine environment.
* ``lamachine-register`` -  Registers software metadata manually.
	* Expects a ``package`` variable that is a dictionary/map that can contain the following fields: ``name`` (mandatory!), ``version``, ``license``,``author``,``homepage``,``summary``
    * When using ``lamachine-python-install``, metadata registration is entirely automatic, as the PyPI contains all relevant information already. So you never need ``lamachine-register``
    * When using ``lamachine-git-autoconf``,  ``lamachine-register`` is automatically called and certain variables (name,version) can be pre-filled. Others you will need to provide explicitly if wanted.

The use of specific LaMachine roles is always preferred over the use of comparable generic ansible modules as the
LaMachine roles take care of a lot of specific things for you so it works in all environments. So use
``lamachine-python-install`` rather than Ansible's ``pip`` module, and ``lamachine-git`` rather than ansible's ``git``
or ``github`` module.

To add your own software, you add a *role* yourself which includes one (or more) of the above, with specific parameters, to do the
actual work. Your role, in turn, is referenced by the end-user who has final control over the installation playbook.
Rather than just installing a single piece of software, a role in LaMachine usually installs multiple inter-connected
software components and all their dependencies.

This may sound a bit cryptic still, so let's go through some examples:

## Examples

Learning by example is usually the most efficient. We provide somes examples below, but also want to encourage you to
just browse around in the ``roles/`` directory and see how some of the existing software packages are installed:

### Example: Python software

* For this example, we use a Python software package named *babelente*
* The source code is on github as https://github.com/proycon/babelente
* The software is released on the Python Package Index as *babelente*, meaning a simple ``pip install babelente`` is enough to
  install it and all dependencies.
* Fork the LaMachine github repository
* Git clone your fork
* Create a file  *roles/babelente/tasks/main.yml* (create the necessary directories) with the following contents:

```
 - name: Install Foobar
   include_role:
      name: lamachine-python-install
   vars:
      package:
         github_user: proycon
         github_repo: babelente
         pip: babelente
```

That's it, the ``lamachine-python-install`` role works in such a way that the stable version of LaMachine will use
``pip`` with PyPI, whilst the development version of LaMachine will draw from github directly and run ``python3 setup.py
install``. Note that this automatically covers any Python dependencies the package has declared.

### Example: Distribution packages

If a software package already commonly included in our supported Linux distributions, then we can pull straight from the
distribution's repository. To this end, we use the ``lamachine-package-install`` role. The following example
demonstrates an installation of the Tesseract OCR system, supported on different distributions:

```
 - name: Install Tesseract
   include_role:
      name: lamachine-package-install
   with_items:
      - { debian: tesseract-ocr, redhat: tesseract, arch: tesseract, homebrew: tesseract }
      - { debian: tesseract-ocr-eng, redhat: tesseract-langpack-eng, arch: tesseract-data-eng }
   loop_control:
       loop_var: package
```

Note that ``with_items`` and ``loop_control`` is a standard [Ansible looping construct](http://docs.ansible.com/ansible/latest/playbooks_loops.html). The role is called two times, and the
variable ``package`` is assigned the value provided in ``with_items``.

It is not always feasible to include all distributions and this it not obligatory, if a platform isn't mentioned then
nothing will be installed. This however may break the process, so you if you decide not to support a certain platform,
we encourage you to set up a task that produces an error if the platform is unsupported. This can be done as follows:

```
 - name: Check for unsupported OS
   fail:
     msg: "This software is not supported on Mac OS X or CentOS"
   when: ansible_distribution|lower == "macosx" or ansible_distribution|lower == "centos"
```

## Testing

(todo)
