CApp
====

# Purpose
CApp is like a package manager, but it avoids a lot of package manager responsibilities
by building packages just to support one application, hence "C Application".
CApp uses CMake and Git, and is actually written in the CMake language for portability.
It assumes all packages have source stored Git repositories and are compiled with CMake.

# Usage

## Installing

CApp itself is fairly easy to install using CMake:

```bash
git clone git@cee-gitlab.sandia.gov:daibane/capp.git
cd capp
cmake .
cmake --install .
```

On Windows, this will install `capp.bat` to the `bin` directory and
elsewhere it will install `capp`.

## Building an Application Repository

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

## Working with an Application

Another key use case of CApp is actual application development.
One key function is updating which version of a package the application repository points to:

```bash
cd my-application
cd source/package1
git pull
capp commit package1
git commit -a -m "updated version of package1"
```
