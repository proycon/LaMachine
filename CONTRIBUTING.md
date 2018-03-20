# Adding new software to LaMachine

## Requirements and guidelines

* Only add relevant NLP software
* LaMachine is only intended for POSIX-compliant systems (i.e. Linux, BSD, Mac OS X).
  Other systems such as Windows are only supported through a VM.
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

## How to contribute?

Contributors are expected to be familiar with git and github:

* Fork the LaMachine github repository
* Add a role for your software in ``roles/``  (read the rest of this documentation to learn how)
* When all done, create a pull request on Github

## LaMachine Architecture

LaMachine consists of installation and configuration recipes for [Ansible](https://ansible.org). These recipes are
called *playbooks* by Ansible, or more specifically they are called *roles* when used in a modular fashion as we do.
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
build, as LaMachine offers quite some flexibility by coming in different
flavours, versions, and being intended to work on multiple Linux distributions.

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
* ``lamachine-git-autoconf`` -  Install C++ software hosted in git and which makes use of the GNU autotools (autoconf/automake), i.e. software that follows the classic  ``./configure && make && make install`` paradigm.

Some lower-level roles:
* ``lamachine-git`` - Clone a particular git repository
* ``lamachine-run`` - Run a particular command in the LaMachine environment.

The use of specific LaMachine roles is always preferred over the use of comparable generic ansible modules as the
LaMachine roles take care of a lot of specific things for you so it works in all environments. So use
``lamachine-python-install`` rather than Ansible's ``pip`` module, and ``lamachine-git`` rather than ansible's ``git``
or ``github`` module.

To add your own software, you add a *role* yourself which includes one (or more) of the above, with specific parameters, to do the
actual work. Your role, in turn, is referenced by the end-user who has final control over the installation playbook.

This may sound a bit cryptic still, so let's go through some examples:

### Example: Python software

* We assume a fictitious Python software package named *foobar*.
* The source code is on github as *proycon/foobar*.
* The software is released on the Python Package Index as *foobar*, meaning a simple ``pip install foobar`` is enough to
  install it and all dependencies.
* Fork the LaMachine github repository
* Git clone your fork
* Create a file  *roles/foobar/tasks/main.yml* (create the necessary directories) with the following contents:

```
 - name: Install Foobar
   include_role:
      name: lamachine-python-install
   vars:
      package:
         github_user: proycon
         github_repo: foobar
         pip: foobar
```












(todo)

