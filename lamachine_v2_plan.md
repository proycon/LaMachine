# LaMachine v2 VRE Plan

     Maarten van Gompel
     Centre for Language and Speech Technology
     Radboud University Nijmegen

     revision 1.1

## Abstract

LaMachine v2 is to be a redesigned, improved and more modular version of LaMachine. The redesign is motivated in the
scope of the CLARIAH WP3 Virtual Research Environment (VRE) project. LaMachine is first and foremost a software
distribution; a way to disseminate NLP software to end-users and hosters (e.g. CLARIN centres) alike. In a way, it
already acts as a kind of low-level Virtual Research Environment for technologically capable researchers, though not in
the sense intended in the CLARIAH WP3 VRE plan. It has been very successful and heavily used by third parties, now
setting a firm foundation for its next stage of evolution, as proposed in this plan.

## Introduction

The primary goal of LaMachine is to make our software installable and usable on a variety of platforms. Currently, this
takes shape in the three different flavours in which LaMachine exists, sorted in order of separation from the host OS:

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

LaMachine is in its core implemented as a long bootstrap shell script, of which there is one version for Vagrant and Docker, and
another version for the local environment. The possible software to install and dependencies are hard-coded in this
single script, for multiple linux distributions in case of the local compilation script. We want to redesign this to be
less ad-hoc and use other more established technologies.

These bootstrap shell scripts do not perform everything from scratch. We attempt not to reinvent the wheel so the
bootstrap process makes extensive use of the distribution's native package manager, and established repositories such as
github, the Python Package Index and the Arch User Repository. For the VM and Docker flavour, we currently build on Arch
Linux, meaning software needs to be deposited in the AUR for LaMachine to install it, unless there is a more suitable
repository given the software's ecosystem such as for example the Python Package Index. All Python software needs to be
deposited in the Python Package Index and is pulled from there. This ensures that:

 * Well established software deployment practice is followed, i.e. the software explicitly made installable and deposited in proper repositories;
 * LaMachine remains just an option for convenience and nobody is forced to use it, people can pull straight from the source if they so desire;
 * We build on existing work and do not do unnecessary duplicate work.

We again remain committed this, but will shake up the underlying technologies in LaMachine v2.

## Objectives

### Objective #1. Modularity & Outside participation

* LaMachine grows larger, it already includes 'default' software and 'optional' software, but the user should be given more choice/freedom in the matter.
  We want to greatly expand the flexibility for administrators and users to make a more fine-tuned selection and lower
  the threshold to third party participation in LaMachine;
* The maintainability of the two rather monolithic shell scripts grows more complicated as more software participates;
* We want to try to reduce redundancy in LaMachine and have as much overlap as possible between different flavours and branches;
* It should be made easier for third-party participants to participate in LaMachine without relying on a central party (aka me). It need not be a Nijmegen-only endeavour.
* LaMachine builds on common and well-established software distribution channels and repositories, leverages their power and does not seek to replace them, but merely to combine them to make things easier and more
accessible for the user.

### Objective #2. Improved user experience for researchers (the less technical end-users aka the 80%)

* Even in the current LaMachine, there are facilities for the less technically inclined users, in the form of pre-configured webservices. In the VM and Docker flavours, a simple webserver is available, serving a very minimalistic portal to some webservices (Frog, Ucto, and even FLAT). This is one of the areas in which major improvement is possible. A more user friendly portal environment should be developed.
* We want to lower the threshold for installation of LaMachine itself; everything should start from a single command and an automated wizard to guide you through.
* Although LaMachine is initially more geared towards the technically capable 20%, by decreasing the threshold of installation, we can do more to accommodate the '80%' (with a limit) by providing higher-level interfaces.
* A huge and important corollary of this goal is **improved interoperability** between the tools in LaMachine:
    * User interface options connecting available web-applications/webservices where possible
    * Connections to external online services NOT in LaMachine
    * Interoperability demands for switchboard-like functionality
        * We can investigate whether the CLARIN Switchboard can fulfill this role and be incorporated in LaMachine
    * Better data import/export facilities into LaMachine (VM & Docker) and clear documentation on the matter
    * Ways to make available existing data collections on the host system

### Objective #3: Production deployment & Integration

* The LaMachine everybody can install at home is in principle the same LaMachine as goes to official hosters of production environments, such as CLARIAH centres. We want to make LaMachine more suitable for the demands of production environments, provisioning through ansible facilitates more complex demands as hosters can more easily add their own tools and dependencies.
* We should investigate what we can include in LaMachine for better integration in a CLARIAH production environment, with respect to authentication (single sign-on)
* In the development of a larger CLARIAH WP3 VRE, LaMachine will play a central role as tool environment anyway. Special facilities may need to be implemented for incorporation in a larger VRE framework; LaMachine can take part of this integration burden away from the tools.

## Relations with other projects

### Relation with a CLARIAH WP3 VRE

There is a certain intersection between LaMachine v2 and the WP3 VRE plans, but I'm well aware that the latter goes much
further and has much higher ambitions than this current plan. This LaMachine v2 plan is motivated by the technologies we
already have in place and attempts to sketch how LaMachine can 1) act as a kind of much simpler VRE in its own right and
2) lay the groundwork for integration in a larger VRE, in which LaMachine can act as a deployment platform for NLP tools
as well as for the VRE components themselves. This plan is an attempt to close the gap in a bottom-up fashion, to keep
things relatively simple and practical, and to get to demonstrable results in an as time and resource efficient manner
as possible. I project this all to be realisable within the time that could be allocated for me in the CLARIAH WP3 VRE.

It is also good to stress the main difference between LaMachine and the WP3 VRE. LaMachine is all about distribution,
deployment and access to software tools in any form it is available; from low-level interfaces to high-level interfaces.
The WP3 VRE plan is more about building a high-level (i.e. higher degree of abstraction) infrastructure for serving
various tools (without necessarily providing the actual software), providing interfaces to and around these tools, as
well as providing access to data and search facilities for both.

In this LaMachine v2 plan, we start with what we have, collaborate with CLARIAH partners, and attempt to work towards higher
interoperability within a single distribution. I believe this lays a good foundation for further work as envisioned in the VRE plan.

### Relation with PICCL (CLARIAH WP2/3)

The vision for PICCL was to constitute a complete workflow for corpus building, mainly focussing on OCR, OCR-post
correction and spelling normalisation. The project proposed a pipeline of interconnected tools and a single encompassing
webservice with user interface for end-users.

PICCL's current implementation (which is a reimplementation of a prior prototype by Martin Reynaert) consists of a series
of pipelines to accomplish a certain NLP goal, you could consider these pipelines recipes. The pipeline logic is
implemented in NextFlow; but the actual work is done by a wide variety of tools. PICCL is intimately tied to LaMachine
as it relies on tools included in LaMachine to be properly installed and available. In other words; LaMachine provides the
environment with all the tools, and PICCL provides the recipes specifying how these tools are invoked, as well as a
simple user interface.

### Relation with Nederlab

The pipeline for Linguistic enrichment of historical text in Nederlab is implemented in PICCL, and by extension, again
intimately tied with LaMachine to provide all the necessary tools (including Frog). This LaMachine v2 plan will be very
beneficial for sustainability of this pipeline towards the future and for making it more readily available to general
researchers.

### Relation with Debian

I participate in the Debian Science project, which is a team in which I take care of packaging some of our software for
inclusion in the Debian distribution. This is however a notoriously slow process. Eventually, debian derivatives like
Ubuntu will also have these packages. I recently obtained official Debian Maintainer status to more independently manage our
packages.

This is currently a side-track not directly related to LaMachine, but for LaMachine v2 this may play a role as I intend
to migrate the base distribution from Arch Linux to Debian Linux.

## New Architecture

### Provisioning & Deployment Technologies

We plan several major technology changes for LaMachine v2, in part to shift the burden of solutions we implemented
ourselves to more established solutions and to find better cohesion with what various audiences expect:

1) Make the docker and vagrant flavours less dependent on the host Linux distribution.
    * Switch the base Linux distribution from Arch Linux to **Debian Linux** (stable/stretch), as this makes more sense in production environments (e.g wrt security) and is what more users are accustomed too.
    * Allow for easy expansion to other distributions, allowing to accomodate production environments that run on e.g. CentOS.
2) Use **Ansible** as the primary provisioning engine instead of custom shell scripts
    * Supported by Vagrant for provisioning of Virtual Machines
    * Supports Docker for provisioning containers
    * Makes deployment in production environments easier; allows setting up multiple hosts/containers/vms at once (cf. Docker Compose)
    * Relates to objective #1
3) Use **conda** as a package and environment manager instead of the simpler python virualenv and pip; Anaconda has become a good distribution and an established platform in data science.
    * Highly geared towards data science and very popular, people come to expect it nowadays (relates to objective #2)
    * Good facilities for Jupyter Notebooks
    * Tied to a larger ecosystem that facilitates sharing (relates to objective #2)
    * Though Anaconda was initially geared at Python, conda is itself language-independent and there is a good R ecosystem too.
    * Still compatible with the Python Package Index and pip
    * We intend to use this environment manager also in docker/vagrant flavours; offering a more unified experience, less redundancy, and less dependency on the base Linux distribution.
    * Virtualenv still remains a supported option as well!
4) Single bootstrap command as an entry point to all possible installations
    * Users will be able to bootstrap LaMachine v2 entirely through one command (``curl ... | bash``), which will start an automated wizard asking the user for his choices for his LaMachine build. The script will provide a single entry point and will install necessary initial dependencies (e.g. Vagrant, Ansible). It is geared for a wide variety of unix-like platforms (including Windows 10 with the Linux Subsystem).

LaMachine will become more modular allowing users/hosters themselves to select what software they want. This results in
the ability to build many different LaMachine instances (containers/VMs/environments) with different sets of software.
This will be specified in the ansible inventory.

Some common defaults will be provided and made available in the appropriate repositories such as Docker Hub.

### Collaboration

To include software in LaMachine (by CLARIAH partners and others), a small Ansible playbook (called a *role*) will have
to be contributed to LaMachine. These are in essence installation recipe, and can in turn invoke other installation
recipes already included in LaMachine. Participants may contribute by committing their installation recipes to the
LaMachine github repository, through for instance a pull request. The playbook in turn references a package in one or
more of the supported repositories (github/pypi/cran/debian/anaconda/maven). Clear and extensive documentation needs to
be provided on how to contribute.

LaMachine shifts the burden away from tool providers to provide isolated Docker containers or virtual machines for their
own tools, and delegates this part of the work to LaMachine, and providing shared containers/VMs instead. Users will
have the freedom to install only the parts of LaMachine they actually need and are able to instantiate LaMachine
installations for different purposes on multiple machines/containers.

A major focus in this plan is to spend time to collaborate more closely with CLARIAH partners (VU, INT, UU, Meertens) to
integrate their tools (with initial emphasis on low-level tools, i.e. CLI tools and programming libraries). This means
extensive support will be provided to upstream developers so they can write the necessary recipes and for us to adapt
and extend the LaMachine framework where necessary. We will not, however, adapt any upstream software ourselves.

These collaboration efforts would constitute a logical continuation of the stalled CLARIAH interoperability task between
the RU & VU (FoLiA-NAF) and of the, similarly stalled, task on software quality and sustainability, as certain quality
demands are a technological prerequisite for inclusion in LaMachine.

### User interface & Data

LaMachine v2 will include a webserver with a portal page, this portal page should provide access to *all* web-based
services and applications installed in LaMachine. Initially it will be a fairly simple page, but this is where there is
a lot of room for expansion to accomplish the aforementioned objective #2. This portal page and the services it exposes
are still not a substitute for the command line or the various programming interfaces, it does not intend to expose all
such low-level functionality, but it is an access point for the high-level interfaces which will have more appeal to the
less-technical researcher.

The virtual machine and docker flavour will mount a data directory that is shared with the host system. This data
directory can also be made accessible from the webserver front-end, along with upload/download facilities. It provides a
simple and possibly shared workspace. Special provisions will be added to also make it suitable for multiuser production
environments.

Note that most webservices/web-applications included in LaMachine (e.g. CLAM, FLAT) necessarily provide their own
upload/download and workspace facilities (they need to be able to do their own data validation, conversion, bookkeeping
etc). A LaMachine shared data space will need to be made explicitly interoperable with the various tools. This
could be done in two ways (push vs pull):
1) by uploading input from the shared workspace to the tool-specific workspace and downloading output from the tool
2) by having the tool download its input from the shared workspace and upload its output to the shared workspace

One of my recommendations for the larger VRE plan was that the burden of integration should rest mostly on the VRE, and
not the upstream tools, so adhering to this principle, option one is generally preferred.

The CLARIAH Switchboard provides this kind of functionality, whether it is suitable for this role in LaMachine v2
or whether a new solution has to be implemented remains to be investigated.

The WP3 VRE plan envisions an OwnCloud component for file transfer, this is something that could be integrated and
tested at this level already. Note that many of the other WP3 VRE (meta)data components are well beyond the scope of the
LaMachine v2 plan and not included, but as the VRE project progresses these could be integrated.

## Planning

(This is all still preliminary)

**Phase 0: Preparation** [2 Weeks]

 * Write initial plan (this document) and brainstorm
 * Investigate and experiment with proposed technologies

**Phase 1: Redesign**  [2 Months]

 * Rewrite entire provisioning infrastructure through Ansible
    * Integrate with vagrant
    * Integrate docker
    * Integrate conda
 * Write the necessary ansible integration scripts for our software:
    * Integrate our C++ software stack (Frog, ucto, etc)
    * Integrate Python-based software (easy)
    * Integrate CLAM webservices and web applications (FLAT)
       * Use UWSGI Emperor + apache
    * Integrate NextFlow (java) + PICCL
 * Provide a new interactive ``bootstrap.sh`` script as an initial entry point

**Phase 2: Initial Release** [3 Weeks]

 * Set up automated builds
 * Provide documentation for both end-users, contributors, and hosters
     * Launch a new and simplified LaMachine website for end-users
 * Provide a new portal site inside LaMachine
 * *At this point, we will have a new LaMachine that is functionally at least as capable as LaMachine v1 and can replace it*

**Phase 3: Third party integration**

* Help integrate tools by CLARIAH partners (VU, INT, UU, Meertens)
* This will be an ongoing effort that can run in parallel with the any of next phases
    * Initial focus will be on low-level tools (CLI & Libraries)
    * Higher-level tools may require more progression in phase 4 first

**Phase 4: Interoperability within LaMachine**

* Work on a (web) interface with shared dataspace
    * Enhances/replaces the simple portal site from phase 2.
    * the proposed WP3 VRE OwnCloud module could play a role here as an upload mechanism.
    * Might be based on/derived from/inspired by CLARIN Switchboard (to be investigated) or CLAMopener
    * This will live as a separate project from LaMachine
    * Implement file transfer support for CLAM and FLAT
    * Make OAuth2 compatible for production environments

**Phase 5: External Interoperability & VRE Interoperability**

* This phase is still pretty much a tabula rasa as it depends a lot on the direction and progress of the larger WP3 VRE
  project, which itself is in early stages of planning.
    * Integration of various VRE components as they become available

