# LaMachine v2 VRE Plan
    Maarten van Gompel, Centre for Speech and Technology, Radboud University Nijmegen

## Abstract

LaMachine v2 is to be a redesigned, improved and more modular version of LaMachine. The redesign is motivated in the
scope of the CLARIAH WP3 Virtual Research Environment (VRE) project. LaMachine is first and foremost a software
distribution, a way to disseminate NLP software to end-users and hosters (e.g. CLARIN centres) alike. In a way, it
already acts as a kind of low-level Virtual Research Environment for technologically capable researchers, though not in
the sense intended in the CLARIAH WP3 VRE plan. It has been very successful and heavily used by third parties, now
setting a firm foundation for its next stage of evolution.

## Introduction

The primary goal of LaMachine is to make our software installable and usable on a variety of platforms. This takes shape
in the three different flavours in which LaMachine exists, sorted in order of binding with the host OS:

* As a virtual machine, the whole OS (linux) is virtualised (built with Vagrant)
    * Good for running on otherwise unsupported OSes like Windows
* As a docker container, only linux kernel is shared
    * Good for production environments
    * Docker container builds are automated, automatically tested, and directly available from Docker Central
* As a local environment, e.g. software is directly compiled for the host OS
    * Only runs on (a specific selection of modern) Linux distributions (and to certain degree also on Mac OS X, or on Windows 10 with Linux subsystem)
    * Ideal for low-level development; deployment on HPC clusters
    * local environment builds are automatically tested in Travis-CI (but not for all distributions)

The three flavours serve different audiences whilst providing the same functionality, a command line environment in
which all tools are available. We remain committed to all three flavours, though we plan to change the underlying
technologies to a certain degree.

In addition to the three flavours, LaMachine currently comes in two branches, a stable branch and a development branch.
The stable branch will install the latest stable releases of all participating software, whereas the development branch
will pull and install the latest git versions directly. There is also the option to return to very specific versions
(for scientific reproducibility).

LaMachine is in its core implemented as a long bootstrap shell script, there is one version for Vagrant and Docker, and
another version for the local environment. The possible software to install and dependencies are hard-coded in this
single script, for multiple linux distributions in case of the local compilation script. We want to redesign this to be
less ad-hoc and use other more established technologies.

These bootstrap shell scripts do not perform everything from scratch, we attempt not to reinvent the wheel so the
bootstrap process makes extensive use the distribution's native package manager, and established repositories such as
github, the Python Package Index and the Arch User Repository. For the VM and Docker flavour, we currently build on Arch
Linux, meaning software need to be deposited in the AUR for LaMachine to install it unless there is a more suitable
repository given the software's ecosystem, such as for example the Python Package Index. All Python software needs to be
deposited in the Python Package Index and is pulled from there. This ensures that:

    * Well established software deployment practice is followed, i.e. the software explicitly made installable and deposited in proper repositories
    * LaMachine remains just an option for convenience and nobody is forced to use it, people can pull straight from the source if they so desire.
    * We build on existing work and do not do unnecessary duplicate work

We again remain committed this, but will shake up the underlying technologies.

## Objectives

### Objective #1. Modularity & Outside participation

* LaMachine grows larger and larger, it already includes 'default' software and 'optional' software, but the user should be given more choice/freedom in the matter.
* The maintainability of the two rather monolithic shell scripts grows more complicated as more software participates.
* We want to try to reduce redundancy in LaMachine and have as much overlap as possible between different flavours and branches
* It should be made easier for third-party participants to participate in LaMachine without relying on a central party (aka me). It need not be a Nijmegen-only endeavour

### Objective #2. Improved user experience for researchers (the less technical end-user aka the 80%)

* Even in the current LaMachine, there are facilities for the less technically inclined users, in the form of pre-configured webservices. In the VM and Docker flavours, a simple webserver is available, serving a very minimalistic portal to some webservices (Frog, Ucto, and even FLAT). This is one of the areas in which major improvement is possible. A more user friendly portal environment should be deliver.
* Although LaMachine is initially more geared towards the 20%, and tries to decrease the threshold of installation, we can do more to accommodate the '80%' (with a limit).
* A huge and important corollary of this goal is **improved interoperability** between the tools in LaMachine:
    * User interface options connecting available web-applications/webservices where possible
    * Connections to external online services NOT in LaMachine
    * Interoperability demands for switchboard-like functionality
        * We can investigate whether the CLARIN Switchboard can fulfill this role and be incorporated in LaMachine
    * Better data import/export facilities into LaMachine (VM & Docker) and clear documentation on the matter
    * Ways to make available existing data collections on the host system

### Objective #3: Production deployment & Integration

* The LaMachine everybody can install at home is in principle the same LaMachine as goes to official hosters of production environments, such as CLARIAH centres.
* We should investigate what we can include in LaMachine for better integration in a CLARIAH production environment, with respect to authentication (single sign-on)
* In the development of a larger CLARIAH WP3 VRE, LaMachine will play an important role as tool provider anyway, special facilities may need to be implemented for incorporation in a larger VRE framework

## Relations with other projects

### Relation with a CLARIAH WP3 VRE

There is a certain intersection between LaMachine and the WP3 VRE plans, but I'm well aware that latter goes much
further and has much higher ambitions than this current plan. This LaMachine v2 plan is motivated by the technologies we
already have in place and attempts to sketch how LaMachine can 1) act as a kind of much simpler VRE in its own right and
2) lay the groundwork for integration in a larger VRE, in which it can act as a deployment platform for tools. In other
words, this plan is an attempt to close the gap in a bottom-up fashion, to keep things relatively simple and practical,
and to get to demonstrable results in an as time- and resource- efficient manner as possible. I project this all to be
realisable well within the time that could be allocated for me in the CLARIAH WP3 VRE.

It is also good to stress the main difference between LaMachine and the WP3 VRE. LaMachine is all about distribution,
deployment and access to software. It is not, and will never be, an infrastructure deployed online in one static
location (but may be made to interact with such larger infrastructure as per goals #2 and #3). LaMachine requires the
underlying software to be open, publicly available, and adhere to certain common good-practices with regard to in what
repositories software is deposited.

### Relation with PICCL (CLARIAH WP2/3)

The vision for PICCL was to be constitute a complete workflow for corpus building, mainly focussing on OCR, OCR-post
correction and spelling normalisation. The project proposed a pipeline of interconnected tools and a single encompassing
webservice with user interface for end-users.

PICCL's current implementation (which is a reimplementation of prior prototype by Martin Reynaert) consists of a series
of pipelines to accomplishe a certain NLP goal, you could consider these pipelines recipes. The pipeline logic is
implemented in NextFlow; but the actual work is done by a wide variety of tools. PICCL is intimately tied to LaMachine
as it relies on these tools which need to be properly installed and available. In other words; LaMachine provides the
environment with all the tools, and PICCL provides the recipes specifying how these tools are invoked, as well as a
simple user interface.

### Relation with Nederlab

The pipeline for Linguistic enrichment of historical text in Nederlab is implemented in PICCL, and by extension, again
intimately tied with LaMachine to provide all the necessary tools (including Frog). This LaMachine v2 plan will be very
beneficial for sustainability of this pipeline towards the future and for making it more readily available to general
researchers.

### Relation with Debian

I participate in the Debian Science project, which is a team in which I take care of packaging some of our software for
inclusion in the Debian distribution. This is however a notoriously slow process. Eventually, debian derivates like
Ubuntu will also have these packages. I recently applied for Debian Maintainer status to more independently manage our
packages.

This is currently a side-track not directly related to LaMachine, but for LaMachine v2 this may play a role as I intend
to migrate the base distribution from Arch Linux to Debian Linux.

## New Architecture

### Provisioning & Deployment Technologies

We plan several major technology changes for LaMachine v2, in part to shift the burden of solutions we implemented
ourselves to more established solutions and to find better cohesion with what various audiences expect:

1) Make the docker and vagrant flavours less dependent on the host Linux distribution.
    * Switch the base Linux distribution from Arch Linux to **Debian Linux** (stable/stretch), as this makes more sense in production environments (e.g wrt security) and is what more users are accustomed too.
2) Use **Ansible** as the primary provisioning engine instead of custom shell scripts
    * Supported by Vagrant for provisioning of Virtual Machines
    * Supports Docker (through ansible-container) for provisioning containers
    * Makes deployment in production environments easier; allows setting up multiple hosts/containers/vms at once (cf. Docker Compose)
    * Relates to objective #1
3) Use **conda** as a package and environment manager instead of the simpler python virualenv and pip; Anaconda has become a good distribution and an established platform in data science.
    * Highly geared towards data science and very popular, people come to expect it nowadays (relates to objective #2)
    * Good facilities for Jupyter Notebooks
    * Tied to a larger ecosystem that facilitates sharing (relates to objective #2)
    * Though Anaconda was initially geared at Python, conda is itself language-independent and there is a good R ecosystem too.
    * Still compatible with the Python Package Index and pip
    * We intend to use this environment manager also in docker/vagrant flavours; offering a more unified experience, less redundancy, and less dependency on the base Linux distribution.

LaMachine will become more modular allowing users/hosters themselves to select what software they want. This results in
the ability to build many different LaMachine instances (containers/VMs/environments) with different sets of software.
This will be specified in the ansible inventory.

Some common defaults will be provided and made available in the appropriate repositories such as Docker Hub.

### Collaboration

To include software in LaMachine (by CLARIAH partners and others), a small Ansible playbook (called a *role*) will have
to be contributed to LaMachine. This is accomplished by simply committing it to the LaMachine github repository, through
for instance a pull request. The playbook in turn references a package in one or more of the supported repositories
(github/pypi/cran/debian/anaconda/maven). Clear and extensive documentation needs to be provided on how to contribute.

LaMachine shifts the burden away from tool providers to provide isolated Docker containers or virtual machines of their own
tools, and delegates this part of the work to LaMachine, and providing shared containers/VMs instead.

A major focus in this plan is to spend time to collaborate more closely with CLARIAH partners (VU, INT, UU) to integrate
their tools (with emphasis on low-level, i.e. CLI tools). Such efforts are also a continuation of the stalled CLARIAH
interoperability task between the RU & VU (FoLiA-NAF) and of the, similarly stalled, task on software quality and
sustainability, as certain quality demands are a technological prerequisite for inclusion in LaMachine.

### Front-end

(TODO)

## Planning

**Phase 0: Preparation** [2 Weeks?]
* Write initial plan (this document) and brainstorm
* Investigate and experiment with proposed technologies

**Phase 1: Redesign**  [2 Months * 0.3 fte]
* Rewrite entire provisioning infrastructure through Ansible
    * Integrate with vagrant
    * Integrate docker
    * Integrate conda
* Write the necessary ansible integration scripts for our software:
    * Integrate our C++ software stack (Frog, ucto, etc)
        * Build conda packages
    * Integrate Python-based software (easy)
    * Integrate CLAM webservices and web applications (FLAT)
        * Use UWSGI Emperor + nginx
    * Integrate NextFlow (java) + PICCL
* Provide a new interactive ``bootstrap.sh`` script as an initial entry point

**Phase 2: Initial Release** [2 Weeks * 0.3 fte]
* Set up automated builds
* Provide documentation for both end-users, contributors, and hosters
    * Launch a new and simplified LaMachine website for end-users
* Provide a new portal site inside LaMachine
* *At this point, we will have a new LaMachine that is functionally at least as capable as LaMachine v1 and can replace it*

**Phase 3a: Third party integration**
* Help integrate low-level third party tools (CLI) and libraries by CLARIAH partners (VU, INT)
* This will be an ongoing effort that can run in parallel with the any of next phases

**Phase 3b: Interoperability within LaMachine**
* (TODO)

**Phase 3c: External Interoperability**
* (TODO)


































