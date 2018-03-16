# Adding new software to LaMachine

## Requirements and guidelines

* Only add relevant NLP software that fits with the rest
* All software must be in public version control (we recommend *github*), be *public*, and be fully *open source*
* LaMachine distinguishes between latest development versions and stable
  releases. If your software is mature enough to be released, please do so
  using the releases mechanism on github. Version numbers should use semantic versioning and start with a **v** (like
  v0.1.2; the ``major.minor.revision`` format is recommended)
* The latest state of the ``master`` branch of your repository will be considered the development version.
* If there is a suitable software repository for your software (such as the [Python Package
  Index](https://pypi.python.org) for Python, [CPAN](https://wwww.cpan.org) for
  Perl, [CRAN](https://www.cran.org) for R, [Maven](https://search.maven.org) for Java); use it to publish stable releases. LaMachine can in turn obtain it from these
  repositories.
* Your software should have at least some form of documentation, at the least a decent README
* Any Python software should support Python 3 (and not just 2.7)

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
*variables*. Let's first look at the latter:

### Variables

The variables are generally set by the end-user in the LaMachine configuration
when building or updating LaMachine. These determine the type of environment to
build, as LaMachine offers quite some flexibility by coming in different
flavours, versions, and being intended to work on multiple Linux distributions.

We distinguish the following variables:

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
* *Other:*
  * ``private`` - (boolean) Send basic analytics back to us
  * ``minimal`` - (boolean) A minimal installation is requested (might break some stuff)

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
LaMachines

To add your own software, you add a *role* yourself which includes one (or more) of the above, with specific parameters, to do the
actual work.


Your role, in turn, is referenced by the end-user who has final control over the installation playbook.

This may sound a bit cryptic still, so let's go through an example step by step:


(todo)

