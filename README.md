CApp
====

# Overview
CApp is like a package manager, but it avoids a lot of package manager responsibilities
by building packages just to support one application, hence the name is a shortening of "C Application".
CApp depends only on CMake and Git, and is actually written in the CMake language for portability.
It assumes all packages have source code stored in Git repositories and are compiled with CMake.
CApp is built around the notion of an application repository, which is a Git repository
containing "package files": CMake language files which describe packages needed
to build the application, their exact version expressed as a Git commit,
their dependencies, and the CMake arguments needed to configure each package.
By knowing only about exactly one version of each package, CApp avoids any responsibilities
related to version compatibility resolution.
What CApp does do is automate the process of cloning, configuring, building, installing,
and otherwise developing the various packages needed to build an application.
It can be used for automated installation, continuous integration, and local
developer work, all in a unified system that is portable across operating systems.

# Usage

## Installing

CApp itself is fairly easy to install using CMake:

```bash
git clone git@cee-gitlab.sandia.gov:alegra/source-code/capp.git
cd capp
cmake .
cmake --install .
```

On Windows, this will install `capp.bat` to the `bin` directory and
elsewhere it will install `capp`.

## Setting Up an Application

The first step to using CApp is to create a repository that describes the packages needed
for the application.
This can be done by using the `capp init` command.
As the name suggests, an application repository is also a Git repository, and `capp init`
will call `git init`.

```bash
mkdir my-application
cd my-application
capp init my-application
vim app.cmake
git commit -a -m "initial application commit"
```

The easiest way to add a new package to the application repository is via `capp clone`:

```bash
cd my-application
capp clone git@github.com:Unidata/netcdf-c.git
vim package/netcdf-c/package.cmake 
git commit -a -m "added netcdf package"
```

## Installing an Application

With a copy of the application repository available, CApp can build it with the `capp build` command.

```bash
cd my-application
capp build
```

## Developing an Application

Another key use case of CApp is actual application development.

### Rebuilding a Package

Users of CApp are encouraged to edit package source code in the
the `source/` subdirectory of the application repository and follow
the normal Git workflow for each package as desired.
At some point, to see the effects of the source code changes,
users may want to rebuild a package and all downstream dependencies.
This can be done with the `capp rebuild` command:

```bash
cd my-application
cd source/package1
vim package_function.c
capp rebuild package1
```

If given no arguments, the `capp rebuild` command will rebuild all packages.

### Reconfiguring a Package

Sometimes a change to a package is substantial enough that it requires
CMake reconfiguration in order to properly update the build.
This can be done with the `capp reconfig` command, which works just
like `capp rebuild` but will force a fresh CMake configuration of
the package prior to rebuilding.
If given no arguments, the `capp reconfig` command will reconfigure and rebuild all packages.

### Accepting a New Package Version

One key function is updating which version of a package the application repository points to,
This is done by the `capp commit` command, which will update the git URL and git commit that
the application repository points to.

```bash
cd my-application
cd source/package1
git pull
capp commit package1
git commit -a -m "updated version of package1"
```

### Checking Out New Package Versions

An inverse of the prior function is to update the package source in the source directory
to be exactly the version pointed to by the application repository.
We do this with the `capp checkout` command.
This is especially helpful to run after other developers have made changes to package
versions.

```bash
cd my-application
git pull
capp checkout
capp build
```
