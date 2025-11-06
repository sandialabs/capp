CApp
====

# Overview
CApp is like a package manager, but it avoids a lot of package manager responsibilities
by building packages just to support one application, hence the name is a shortening of "C Application".
CApp depends only on CMake and Git, and is actually written in the CMake language for portability.
It assumes all packages have source code stored in Git repositories and are compiled with CMake.
CApp is built around the notion of a build repository, which is a Git repository
containing "package files": CMake language files which describe packages needed
to build the application, their exact version expressed as a Git commit,
their dependencies, and the CMake arguments needed to configure each package.
By knowing only about exactly one version of each package, CApp avoids any responsibilities
related to version compatibility resolution.
What CApp does do is automate the process of cloning, configuring, building, installing,
and otherwise developing the various packages needed to build an application.
It can be used for automated installation, continuous integration, and local
developer work, all in a unified system that is portable across operating systems.

Slides describing CApp and modern CMake usage can be found [here](https://figshare.com/articles/presentation/Better_Package_Management/16556511)

# Usage

## Installing CApp

CApp consists of a CMake script and a Bash environment setup script.
These files can be used from the cloned Git repository or the three files can be
copied somewhere else (`capp.cmake` needs to be in the same directory as the setup script).

```bash
git clone git@github.com:sandialabs/capp.git
cd capp
cp capp.cmake capp-setup.sh /where/you/want
```

## Setting Up an Application

### init command

The first step to using CApp is to create a repository that describes the packages needed
for the application.
This can be done by using the `capp init` command.
As the name suggests, a build repository is also a Git repository, and `capp init`
will call `git init`.

```bash
git clone git@github.com:sandialabs/capp.git
cd capp
cp capp/capp.cmake capp/capp-setup.sh my-build/
cd my-build
. capp-setup.sh
capp init my-application
vim app.cmake
git commit -a -m "initial application commit"
```

The setup script must be sourced prior to using CApp in any context

```bash
cd my-build
. capp-setup.sh
```

### app.cmake

A build repository needs to have an `app.cmake` file in the top-level directory.
Similar to how Git identifies a Git repository by the presence of a `.git` directory,
CApp identifies a build repository by the presence of an `app.cmake` file.
`capp init` creates this file with some default content for convenience.
An application's `app.cmake` file should at minimum contain a call to the `capp_app` command,
whose signature is as follows:

```cmake
capp_app(
  ROOT_PACKAGES package1 [package2 ... ]
  [BUILD_TYPE type])
```

`ROOT_PACKAGES` should be the list of packages that CApp
must always try to compile.
CApp will try to build all packages that `ROOT_PACKAGES`
depend on (see the documentation on `capp_package`)
in the right order.
Most applications will have an "application package", which is a package
that contains the source code for the application but not any of the
other supporting packages.
The typical use case will be to list the `ROOT_PACKAGES` as
just the application package.
By default, CApp will configure all packages with `-DCMAKE_BUILD_TYPE=Release`.
The `BUILD_TYPE` argument can be used to change the build type to something else
(CMake supports `Release`, `Debug`, and `None`).
The build type can also be set on a per-flavor basis by setting `CAPP_BUILD_TYPE`
in a `flavor.cmake` file.

### flavor.cmake

CApp supports multiple flavors, which are just full-build configurations by a different name.
Each build flavor is contained in a directory `flavor/<flavor_name>/`.
This allows users to set variables that control the build, such as enabling or
disabling options in certain packages.
These options should be handled through CMake variables, and
should be defined in a file `flavor/<flavor_name>/flavor.cmake`.
This flavor file will be loaded via a cmake `include()` command prior to
including `app.cmake`.

For example, if there is an option in package `foo` called `FOO_ENABLE_FAST`,
and you'd like to control this at the overall application layer, you could put the following
in the `flavor.cmake` file:

```cmake
set(MY_APP_ENABLE_FAST TRUE)
```

Then the file `packages/foo/package.cmake` could do the following:

```cmake
capp_package(
  OPTIONS
  "-DFOO_ENABLE_FAST=${MY_APP_ENABLE_FAST}"
  )
```

If the `flavor.cmake` or `app.cmake` files are altered, the next time that CApp
tries to build it will re-configure all packages.

There are two ways the user can select which flavor CApp is operating on:
 1. The CApp command accepts an argument `--flavor <flavor_name>` or `-f <flavor_name>` for short
 2. If the CApp command is executed somewhere inside the flavor directory,
    it will infer the flavor based on the directory.

### clone command

The easiest way to add a new package to the build repository is via `capp clone`:

```bash
capp clone git@github.com:Unidata/netcdf-c.git
vim package/netcdf-c/package.cmake
git commit -a -m "added netcdf package"
```

### package.cmake

The primary package information in a CApp build repository
is stored in files:

```
package/<package_name>/package.cmake
```

The actual names of packages are the names of the sub-directories
in the `package` directory of the build repository.

A package's `package.cmake` file should at minimum call `capp_package`,
whose signature is as follows:

```cmake
capp_package(
  GIT_URL git_url
  COMMIT commit
  [OPTIONS option1 [option2 ...]]
  [DEPENDENCIES dep1 [dep2 ...]]
  [BUILD_TYPE type]
  [NO_CONFIGURE_CACHE]
  [IGNORE_UNCOMMITTED])
```

The `GIT_URL` option should be a Git URL suitable for `git clone`
and other commands.
An example Git URL would be `git@github.com:sandialabs/omega_h.git`.
While CApp doesn't impose restrictions on the type of Git URL,
it has only been tested with SSH protocol URLs and not
with HTTPS protocol URLs.

The `COMMIT` option should be the SHA-1 hash for a certain Git
commit, meaning the version of the package repository we
want to checkout and build.

Note that by directly listing a SHA-1 commit in `package.cmake`
files, CApp implements a submodule-like system that ensures
that the SHA-1 commit hashes of the build repository
are tied to the SHA-1 commit hashes of the package repositories.
This means that it is enough to know the version of the
build repository that was built in order to know
the exact versions of all package repositories that were built.

The `OPTIONS` list should be a list of command line arguments
to CMake when configuring the package.
For example, an item `option1` might be `-DFOO_ENABLE_FAST=ON`.
Note that CApp already defines
`CMAKE_BUILD_TYPE` and `CMAKE_INSTALL_PREFIX` when
configuring a package.

The `DEPENDENCIES` list should be a list of package names
on which the current package directly depends.
Recall that package names are the names of subdirectories
of the `package` directory of the build repository.

If the `BUILD_TYPE` option is present, it sets the value of
`CMAKE_BUILD_TYPE` for just this package.
Otherwise, the value of `BUILD_TYPE` given to `capp_app` is used.
If neither are given, `Release` is used.

If the `NO_CONFIGURE_CACHE` option is present, then when
CApp tries to re-configure a package it will first
remove the `CMakeCache.txt` file.
This is useful when packages have buggy CMake files
that produce different results when incrementally reconfigured
than they do when configured without a cache,
even with the same arguments supplied.

The `capp commit` command discussed later will check whether there
are uncommitted changes to a package's source repository.
However, some packages modify their source directory during their
configure, build, and install process even though this is bad practice.
For those packages, one can add `IGNORE_UNCOMMITTED` to the
`capp_package` arguments to tell CApp to ignore uncommitted changes
to that package.

## Building an Application

Recall that the setup script must be sourced prior to using CApp:

```bash
cd my-build
. capp-setup.sh
```

### build command

With a copy of the build repository available, CApp can build it with the `capp build` command.

```bash
capp build -f plain
```

### Directory structure

CApp will create sub-directories in the build repository directory called
`source`, `build`, and `install`.
Each package will have its Git repository cloned into:
```
source/<package-name>
```
Each package will have its CMake binary directory (where CMake is configured
and all intermediate build files are stored) at:
```
flavor/<flavor_name>/build/<package-name>
```
Each package will be installed by setting `CMAKE_INSTALL_PREFIX` equal to:
```
flavor/<flavor_name>/install/<package-name>
```

The `capp init` command populates `.gitignore` to ignore these directories,
since their content is an artifact of the current build and not part of the
fundamental specification of a build repository.

## Installing an Application

CApp has an install command which will copy files from its internal installation
directories to a directory that must be specified via the `--prefix` flag.
Because it copies the files, this could be problematic for dynamically linked
packages using RPATH, and is only advised for statically linked packages.
Like other commands, the install command accepts a list of packages and will
install all packages if not given any.

Recall that the setup script must be sourced prior to using CApp:

```bash
cd my-build
. capp-setup.sh
```

```bash
capp install my_root_package -f plain --prefix /usr
```

## Developing an Application

Possibly the most productive use of CApp is actual application development.
CApp was designed specifically for users to radidly conduct multi-package
development.

Recall that the setup script must be sourced prior to using CApp:

```bash
cd my-build
. capp-setup.sh
```

### Rebuilding a Package

Users of CApp are encouraged to edit package source code in the
the `source/` subdirectory of the build repository and follow
the normal Git workflow for each package as desired.
At some point, to see the effects of the source code changes,
users may want to rebuild a package and all downstream dependencies.
This can be done with the `capp rebuild` command:

```bash
cd source/package1
vim package_function.c
capp rebuild -f plain package1
```

If given no arguments, the `capp rebuild` command will rebuild all packages.

### Reconfiguring a Package

Sometimes a change to a package is substantial enough that it requires
CMake reconfiguration in order to properly update the build.
This can be done with the `capp reconfig` command, which works just
like `capp rebuild` but will force a fresh CMake configuration of
the package prior to rebuilding.
If given no arguments, the `capp reconfig` command will reconfigure and rebuild all packages.

### Testing a Package

Since CApp assumes all packages use CMake to compile, it also assumes that CTest is used for testing.
The command `capp test` is used to test packages.
Like other commands, it accepts one or more package names as arguments, and if not given any arguments
then all packages are tested.
CApp will simply call `ctest` in the appropriate package build directory in order to test a package.

```bash
capp test -f plain package1
```

### Accepting a New Package Version

After a developer is done modifying a package, the natural next step is getting the
build repository to accept and point to the new modified version of the package.
This is done by the `capp commit` command, which will update the git URL and git commit that
the build repository points to.

```bash
cd source/package1
git pull
capp commit package1
git commit -a -m "updated version of package1"
```

`capp commit` will fail if there are uncommitted changes to the package's source
repository, thereby helping to ensure that the current state of the source code
really gets captured.
This behavior can be avoided by specifying `IGNORE_UNCOMMITTED` in `package.cmake` files.

If given no package arguments, `capp commit` will operate on all packages.

### Checking Out New Package Versions

An inverse of the prior function is to update the package source in the source directory
to be exactly the version pointed to by the build repository.
We do this with the `capp checkout` command.
This is especially helpful to run after other developers have made changes to package
versions.

```bash
git pull
capp checkout
capp build -f plain
```

Even easier, the `capp pull` command is equivalent to `git pull` followed by `capp checkout`:

```bash
capp pull
capp build -f plain
```

## Exporting Build Information

CApp has a `capp export` command which produces a file `capp.json`
describing the build in a way that can be used by other tools to
automatically derive useful information.
The `capp.json` file encodes a JSON array of JSON objects, one
object per package.
Each JSON package object has the following members:

1. `name`: the package name
1. `git`: the package's Git URL
1. `commit`: the package's Git commit hash
1. `submodules`: a JSON boolean which is `true` if the checked out
   source has submodules
1. `depedencies`: a JSON array of JSON strings which are the names
   of upstream dependencies
1. `options`: a JSON array of JSON strings which are the
   command line options to be passed to the CMake configuration for
   this package.

Note that the description of the build is affected by options such
as flavor.
For best results, please specify a flavor when using `capp export`:

```bash
capp export -f plain
cat capp.json
```

## Packaging

The `capp checkout` command can also be used to generate self-contained application source packages
that contain all required dependencies to build and install the application, including source
packages and dependent python modules from pip.
When the `capp checkout` command is executed, the `pip download` command is used to download
dependent python modules for each package that contains a python configuration file.
The resulting wheel files are downloaded into the `./pip-cache/` subdirectory of the capp root prefix.
These wheel files are subsequently made available during the build and install phases of each package.

The environment variable `PIP_PLATFORM_FLAGS` can be used to control the platform, abi, and other
tags that determine which wheel file versions are downloaded.
The contents of this variable are passed directly to each invocation of `pip download`:
```bash
pip download ${PIP_PLATFORM_FLAGS} packages...
```

At Sandia, CApp is SCR# 2639.0
