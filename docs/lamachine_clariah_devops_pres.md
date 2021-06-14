# CLARIAH DevOps & LaMachine

## Part I: Alice, Bob and software distribution problems

### The core problem

* *Alice made a software application*
* *Bob wants to run Alice's software*

* How can Alice make her software available to Bob?
* How can Bob run Alice's software?

### Solving the problem?

* Alice gives Bob an executable
* Bob runs the executable

**Problem solved?**

### The real problems begin...

* Is Alice's executable suited for Bob's OS and architecture?
    * No? Alice must provide multiple executables for different systems
    * No? Bob must use *virtualisation* to emulate another OS/architecture.
    * Not compiled but interpreted? Bob must have the necessary interpreter (e.g. Python, JS, Java)
    * Give Bob the source code and let him build the program himself?
        * requires a lot of technical expertise from Bob
* Does Alice's program make use of any (dynamically) linked shared libraries Bob also needs?
    * Alice must either provide or make explicit all her dependencies
        * static linking vs dynamic linking
        * .. and these in turn may have dependencies too: welcome to **dependency Hell**
    * Bob must ensure he has all the necessary dependencies before the program can run
* Alice's program may want to interact with other applications on the system?
    * Bob must ensure they're installed and set up properly


### Traditional solution: packaging and distributions

* Distributions host packages for common software in a *package repository*
* Packages in a distribution are carefully tuned to interoperate with one-another (ABI/API compatibility etc)
* A package manager handles packages and all their dependencies  (apt, yum, apk, pacman, brew)
* Alice can now build a package (deb, rpm, apk) and add it to a repository
* FAIR avant la lettre...

**Problem solved?**

* There are many different distributions -> many packages needed
* Maintaining packages takes time and effort (for Alice)
* Packages have to be kept up to date (for both Bob and Alice)

### Language ecosystems

* Language-ecosystems provide their own package repositories:
    * Python - Python Package Index - pip
    * NodeJS - npm
    * Rust - crates.io - cargo
    * Java - Maven Central - maven
    * perl - CPAN
    * R - CRAN
    * Ruby - Rubygems - gem
* If Alice's software fits into one of the ecosystems well, she can provide a package there

**Problem solved?**

### Software complexity: layers upon layers

* Alice's software application may be an integration of an interconnected set of diverse software components.
    * Various languages, doesn't fit a single language ecosystem
    * Various audiences, doesn't fit a single distribution
* Though maybe captured in multiple more traditional packages, configuring the integration is often not trivial

### Software-as-a-Service (SaaS)

* Instead of giving Bob the actual program, Alice makes her software available *as a service*.
* Bob can simply access it as a **web application** through his browser (or programatically interact with it as a **web service**)
* Alice now gives her program to Charlie instead of Bob, to **deploy** on a server, Bob accesses Charlie's server.

**Problem solved?**

* The burden shifts from Alice and Bob to Alice and Charlie (who has more technical expertise)
* **Service-as-a-Software Substitute**: having access to a service is a convenience but is **NOT** a substitute for having the actual software.
    * Privacy, data ownership and trust concerns
    * Increased latency, requires network connection
    * Business model vs technical solution
    * Can be a loophole to not provide the source code anymore (GPL vs AGPL)
    * Not suited for everybody

### Virtualisation

* Bob: *"your program doesn't run"*
* Alice: *"But it works on my machine"*
* **Solution:** Alice just gives Bob a copy of her machine and Bob's machine emulates Alice's machine: a **virtual machine**

* Takes us back to scenario 1, *"Alice gives Bob an executable"*, but in the broadest possible sense of executable.
* Bob now only requires a **hypervisor** to run the VM.
* **Advantages**: Bridges OS differences, isolation (security)
* **Disadvantages**: Performance penalty, resource overhead, isolation (integration)

### Containerisation

![Containerisation vs Virtualisation]()

* Alice again gives Bob a copy of her machine: a **container**.
* Share the (Linux) kernel; isolate the rest, no virtualisation needed
* Takes advantage of facilities in the (Linux) kernel
* Significantly reduces resource overhead & performance penalty
* *Caveat:* container engines may resort to virtualisation anyway on non-Linux platforms (e.g. Docker on Windows or
    macOS)

### Container platforms and paradigms

**Docker**:
    * Application containers, lightweight containers serving ideally single applications
    * Non-persistant storage
    * Layered images
    * Containers are stateless (spun upon anew), all persistant data on externally mounted volumes
    * Docker Hub for images
    * Great for applications containers, deployment of services in cloud infrastructure
    * Most known and widely used
    * Less suitable for High Performance Clusters (security)
**LXC**:
    * System containers: acts like a lightweight VM, more traditional environment
    * Single-layer image
    * File-system neutral, easy persistant storage
    * Fat containers that may serve multiple applications, have a full init system.
**Singularity**:
    * Specifically designed for High Performance Clusters and multi-user environments
    * Can use docker images
    * No elevated permissions required (security)

### Provisioning a container (or VM)


* *"Alice gives Bob a copy of her machine"*

* Alice builds a (container/VM) image
* using an automated recipe for provisioning (e.g. Dockerfile, shell script, Ansible)
* Alice publishes the container image in a registry
* Bob obtains the container image from the registry

### Container Orchestration

* Alice decided on Software-as-a-Service
* Alice gives Charlie a copy of her machine: a **container**, to offer as a service for Bob and others.

**Problem solved?**

* Alice's service may comprise multiple containers that need to interact.
    * L'histoire se répète?
* Alice's service may be so popular that running it on a single system is not sufficient (scalability)
* What if Alice's program fails and the service goes down?

* **Distributed Computing**: containers can easily be deployed on multiple systems
    * Schedule when a container runs and where it runs (load balancing etc)
    * Spin up multiple containers at once (e.g. docker compose)
    * Spin them up over multiple machines (e.g. docker swarm, kubernetes)
    * Restart a container when it fails (kubernetes)
    * Abstract over the hardware (kubernetes)

### Recap

* Distribution
* Packaging
* SaaS
* Virtualisation
* Containerisation
* Orchestration

### Recommendations for the CLARIAH infrastructure

* Containers and orchestration are good solutions for software-as-a-service
* Package and distribute individual all software components whenever possible, through proper channels:
    * Containers/VMs are not an excuse not to properly package and distribute individual software components
    * Services are not a substitute for the actual software
* Overt software complexity (layers upon layers) is often an indication of a fundamental design flaw

## Part II: LaMachine

### Context

* Increasingly complex software stack: Timbl, Frog, ucto, libfolia...
* Mostly developed in CLARIN/CLARIAH WP3
* C++ code with dependencies that was non-trivial to compile for most people
* Multiple interfaces and users on each level:
    * command-line interface
    * C++ library / Python bindings
    * RESTful webservice (via CLAM)
    * web-application (via CLAM)

### What is LaMachine

A **meta-distribution**:

* Deploys software and software services
* Installation and configuration recipes
* For a limited set of (often interconnected) NLP software
* WP3 software stack from Radboud University
* No new repository; relies on established software repositories
* Builds on existing technologies

### Different "flavours"

Offer a similar environment in different flavours:

- A local user environment (virtualenv)
- Globally on dedicated system
    - Linux (or WSL; limited)
    - macOS (limited)
- As a virtual machine
- As a container:
    - Docker
    - LXC
    - Singularity

### Technologies

- **Provisioning**  (Installation and configuration recipes):** Ansible
    - all flavours
- **Virtualisation:** Vagrant and Virtualbox
- **Containerisation:**
    1. Docker
        - No need to write your own Dockerfile
        - "Fat" container may be at odds with Docker's paradigm
    2. LXC
    3. Singularity

### Target audience

- data scientists / researchers
- developers
- hosting providers (e.g. CLARIAH centres)

### Target interfaces

- Command-line shell (possibly over ssh)
- Web applications (through the browser)
- Web services (REST)
- Web-based IDE and Notebooks (Jupyter Lab)

### Target platforms

* Gold support
    - Debian 10 (buster, stable) *(Docker default)*
    - Ubuntu 20.04 LTS *(VM default)*
* Silver support
    - Debian 9 (stretch, oldstable)
    - Ubuntu 18.04 LTS
    - CentOS 8 / RedHat Enterprise Linux 8 -
* Bronze support
    - Debian testing / Debian unstable
    - Ubuntu non-LTS after last LTS
    - macOS (latest version)
    - Arch Linux
    - Linux Mint
    - Fedora Linux

### Bootstrap

* Start from a single executable (shell script) and build a LaMachine environment from scratch (any flavour):
   ``bash <(curl -s https://raw.githubusercontent.com/proycon/LaMachine/master/bootstrap.sh)``
* Start from the latest Docker base image (Dockerfile)
* Start from the latest VM image (Vagrant)

### Development vs Production

Two versions:
* Development - Will pull in the latest development versions of all software (from git), may break
* Stable - Will pull in the latest releases versions of all software

### Modularity and Configurability

* LaMachine defines a limited number of 'software packages' of participating software
    * ('packages' are implemented as ansible *roles*)
* The user decides which to install, packages can be also be added later at will (but not removed)

### CLARIAH WP3 Software

* Frog, ucto, libfolia
    * timbl,
* foliapy, python-frog, python-ucto
* Deepfrog, folia-rust
* FLAT
* PICCL
* CLAM
* Alpino

### Third party software

* LaMachine includes (optionally) a lot of third party software common in the field:
    * Jupyter hub/lab/notebooks
    * Tesseract (OCR)
    * Kaldi (ASR), kaldi-nl
    * spacy (NLP), Stanford CoreNLP
    * pytorch (DL), tensorflow, fasttext
    * Moses (SMT)
    * Nextflow
    * Lots of generic Python libs (numpy, nltk, scikit-learn etc)..
* Common languages: C/C++, Python, JS, R, Go, Rust, Java, Julia

## Upgrade procedure

* Running ``lamachine-update`` inside a Lamachine environment will update it
  and all software in it
    * (simply invokes ansible again)

## Portal

![Portal screenshot]()

* Lists all included software and services
* Provides access to included services
* Each LaMachine intstallation can automatically provide such a portal
* Contents are derived from CodeMeta software metadata
* Also accessible on command-line through ``lamachine-list``

### CodeMeta as a Software Metadata scheme

*With codemeta, we want to formalize the schema used to map between the different services (GitHub, figshare, Zenodo) to
help others plug into existing systems. Having a standard software metadata interoperability schema will allow other
data archivers and libraries join in. This will help keep science on the web shareable and interoperable!*
[ from https://codemeta.github.io ]

**Codemeta**:

- is simple and minimalistic
- aimed at scientific software and enabling citability (DOI)
- is Linked Open Data
    - serialises to JSON-LD
    - re-uses and collaborates with schema.org
- is an existing effort, grew out of "Code as a Research Object", a Mozilla Science project with Github and Figshare
    - provides a mapping to other systems (DOAP, Debian Packages, DataCite, WikiData, Maven, NodeJS, Python distutils, R, Ruby gems)

### Software Metadata in LaMachine

During installating/bootstrapping, LaMachine:

- Takes the software metadata from each tool's source repository if available
- Otherwise: converts metadata from the upstream upstream *(Python Package Index, CRAN, CPAN, Maven Central)*
- Augments the metadata where needed with installation specific information:
    - to register web-based entrypoints as provided by LaMachine
    - with extra information specified in the (Ansible) build recipes
- Builds a software registry of all installed software *(JSON-LD graph)*
- Provides a portal web-application on the basis of this metadata *(Labirinto)*
    - Example: https://webservices.cls.ru.nl
- Note: CodeMeta describes software metadata, not APIs

## Authentication


### What is LaMachine *NOT*?

- *NOT* an NLP pipeline/workflow system; rather it may install such systems or components required by such systems.
  - *e.g PICCL (powered by Nextflow), Frog
- *NOT* a system for archiving/preserving legacy software
  - software **MUST** be maintained
- *NOT* only for Nijmegen software
- *NOT* a portal to search/access data collections
  - with LaMachine you can bring the tools to the data
