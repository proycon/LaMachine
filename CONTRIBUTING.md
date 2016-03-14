
Adding new software
==========================

**Requirements and preparation for each software package:**
* Only add relevant NLP software that fits with the rest
* All software must be on *github*, be *public*, and be fully *open source*
* LaMachine distinguishes between latest development versions and stable
  releases. If your software is mature enough to be released, please do so
  using the releases mechanism on github. Version numbers should start with a v
  (like v0.1.2, the ``major.minor.revision`` format is recommended)
* The latest state of the ``master`` branch of your repository will be considered the development version.
* LaMachine currently supports **C/C++** and **Python**


**Packaging the software:**
* **[c++]** 
 * C++ software should use GNU autotools and be installable through: ``bash bootstrap.sh && ./configure && make && make install``
 * C++ software needs to be published to the [Arch User Repository (AUR)](https://aur.archlinux.org)
  * Create a ``yourproject-git`` package for the Arch User Repository (AUR),
    tracking latest development release. Consult the ``PKGBUILD`` of https://aur.archlinux.org/packages/frog-git/  as an example. The ``-git`` suffix is mandatory for development software pulled straight from git.
  * If you have stable releases, create a ``yourproject`` package for the Arch User Repository (AUR). 
    Consult the ``PKGBUILD`` of https://aur.archlinux.org/packages/frog-git/  as an example.
* **[python]**
 * Stable releases of Python software should be published in the [Python Package Index](https://pypi.python.org) (PyPI)
  * Create a proper ``setup.py`` using the ``distutils`` or ``setuptools`` standard.
  * Upload your package to the Python Package Index using ``python setup.py sdist upload``

**Adding the packages to LaMachine**:
* You will need to adapt two shell script to this end, ``virtualenv-bootstrap.sh`` for the virtualenv version, and ``bootstrap.sh`` for the VM/Docker version. Always do both and not just one!
* **[c++]** 
 * Add ``yourproject`` to the ``PROJECTS=`` list in ``virtualenv-bootstrap.sh`` (there is one list for Linux/BSD and one list for Mac OS X, so you can decide to omit it if it doesn't work for mac yet)
 * Add ``yourproject-git`` (development) or ``yourproject`` to the two ``PACKAGES=`` lists in ``bootstrap.sh``
* **[python]**
 * Add ``yourproject`` (as it is named in PyPI) to the ``PYTHONPROJECTS=`` list in ``virtualenv-bootstrap.sh`` 
 * Add ``yourproject`` to the ``PYTHONPACKAGES=`` list  ``bootstrap.sh``.
* If the software relies on global dependencies, figure out how the necessary
  packages are called on the various supported distributions and add them to
  the respective ``INSTALL=`` definitions in ``virtualenv-bootstrap.sh`` and
  to ``PKGS=`` in ``bootstrap.sh`` (always  Arch Linux packages)

**Update a release:**
* Make a release on github.
* **[c++]** Run ``LaMachine/helpers/aur_github_releaseupdate.sh`` to
  automatically update your AUR package according to the latest github release
* **[python]** Publish it to PyPI.


**Adding a new supported distribution for the virtualenv version**
* Edit ``virtualenv-bootstrap.sh``
 * add a new detection statement in the *platform detection* section
 * add code to invoke the package manager to install all necessary  dependencies in  *global package installation* section

