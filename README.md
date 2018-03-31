# GNU MCU Eclipse ARM Embedded GCC build

These are the additional files required by the **GNU MCU Eclipse ARM Embedded GCC** build procedures.

This release closely follows the official [GNU Arm Embedded Toolchain](https://developer.arm.com/open-source/gnu-toolchain/gnu-rm) maintained by ARM.

## Changes

Compared to the original ARM version, there are no functional changes; the **same architecture options** are supported, and **the same combinations of libraries** (derived from newlib) are provided.

The main difference is that the binaries generated cover all modern platforms, Windows 32/64-bits, GNU/Linux 32/64-bits, macOS 64-bits.

## Prerequisites

The prerequisites are common to all binary builds. Please follow the instructions in the separate [Prerequisites for building binaries]({{ site.baseurl }}/developer/build-binaries-prerequisites-xbb/) page and return when ready.

## Download the build scripts repo

The build script is available from GitHub and can be [viewed online](https://github.com/gnu-mcu-eclipse/arm-none-eabi-gcc-build/blob/master/scripts/build.sh).

To download it, clone the [gnu-mcu-eclipse/arm-none-eabi-gcc-build](https://github.com/gnu-mcu-eclipse/arm-none-eabi-gcc-build) Git repo, including submodules. 

```console
$ rm -rf ~/Downloads/arm-none-eabi-gcc-build.git
$ git clone --recurse-submodules https://github.com/gnu-mcu-eclipse/arm-none-eabi-gcc-build.git \
  ~/Downloads/arm-none-eabi-gcc-build.git
```

## Check the script

The script creates a temporary build `Work/arm-none-eabi-gcc-${version}` folder in the user home. Although not recommended, if for any reasons you need to change this, you can redefine `WORK_FOLDER_PATH` variable before invoking the script.

## Preload the Docker images

Docker does not require to explicitly download new images, but does this automatically at first use.

However, since the images used for this build are relatively large, it is recommended to load them explicitly before starting the build:

```console
$ bash ~/Downloads/arm-none-eabi-gcc-build.git/scripts/build.sh preload-images
```

The result should look similar to:

```console
$ docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
ilegeul/centos32    6-xbb-v1            f695dd6cb46e        2 weeks ago         2.92GB
ilegeul/centos      6-xbb-v1            294dd5ee82f3        2 weeks ago         3.09GB
hello-world         latest              f2a91732366c        2 months ago        1.85kB
```

## Update git repos

The GNU MCU Eclipse ARM Embedded GCC distribution follows the official [ARM](https://developer.arm.com/open-source/gnu-toolchain/gnu-rm) distributions, and it is planned to make a new release after each future ARM release.

Currently the build procedure uses the _Source Invariant_ archive and the configure options are the same as in the ARM build scripts.

## Prepare release

To prepare a new release, first determine the GCC version (like `7.2.1`) and update the `scripts/VERSION` file. The fourth digit is the number of the ARM release of the same GCC version, and the fifth digit is the GNU MCU Eclipse release number.

Add a new set of definitions in the `scripts/container-build.sh`, with the versions of various components.

## Update CHANGESLOG.txt

Check `arm-none-eabi-gcc-build.git/CHANGESLOG.txt` and add the new release.

## Build

Although it is perfectly possible to build all binaries in a single step on a macOS system, due to Docker specifics, it is faster to build the GNU/Linux and Windows binaries on a GNU/Linux system and the macOS binary separately.

### Build the GNU/Linux and Windows binaries

The current platform for GNU/Linux and Windows production builds is an Ubuntu 17.10 VirtualBox image running on a macMini with 16 GB of RAM and a fast SSD.

Before starting a multi-platform build, check if Docker is started:

```console
$ docker info
```

To build both th 32/64-bits Windows and GNU/Linux versions, use `--all`; to build selectively, use `--linux64 --win64` or `--linux32 --win32` (GNU/Linux can be built alone; Windows also requires the GNU/Linux build).

```console
$ bash ~/Downloads/arm-none-eabi-gcc-build.git/scripts/build.sh --all
```

To build one of the previous versions:

```console
$ RELEASE_VERSION=5.4.1-1.1 bash ~/Downloads/arm-none-eabi-gcc-build.git/scripts/build.sh --all
$ RELEASE_VERSION=6.3.1-1.1 bash ~/Downloads/arm-none-eabi-gcc-build.git/scripts/build.sh --all
$ RELEASE_VERSION=7.2.1-1.1 bash ~/Downloads/arm-none-eabi-gcc-build.git/scripts/build.sh --all
```

Many hours later, the output of the build script is a set of 4 files and their SHA signatures, created in the `deploy` folder:

```console
$ ls -l deploy
... TBD
```

### Build the macOS binary

The current platform for macOS production builds is a macOS 10.10.5 VirtualBox image running on the same macMini with 16 GB of RAM and a fast SSD.

To build the latest macOS version, with the same timestamp as the previous build:

```console
$ caffeinate bash ~/Downloads/arm-none-eabi-gcc-build.git/scripts/build.sh --osx --date YYYYMMDD-HHMM
```

To build one of the previous macOS versions:

```console
$ RELEASE_VERSION=5.4.1-1.1 caffeinate bash ~/Downloads/arm-none-eabi-gcc-build.git/scripts/build.sh --osx --date YYYYMMDD-HHMM
$ RELEASE_VERSION=6.3.1-1.1 caffeinate bash ~/Downloads/arm-none-eabi-gcc-build.git/scripts/build.sh --osx --date YYYYMMDD-HHMM
$ RELEASE_VERSION=7.2.1-1.1 caffeinate bash ~/Downloads/arm-none-eabi-gcc-build.git/scripts/build.sh --osx --date YYYYMMDD-HHMM
```

For consistency reasons, the date should be the same as the GNU/Linux and Windows builds.

Several hours later, the output of the build script is a compressed archive and its SHA signature, created in the `deploy` folder:

```console
$ ls -l deploy
total 784400
... TBD
```

## Subsequent runs

### Separate platform specific builds

Instead of `--all`, you can use any combination of:

```
--win32 --win64 --linux32 --linux64
```

Please note that, due to the specifics of the GCC build process, the Windows build requires the corresponding GNU/Linux build, so `--win32` alone is equivalent to `--linux32 --win32` and `--win64` alone is equivalent to `--linux64 --win64`.

### clean

To remove most build files, use:

```console
$ bash ~/Downloads/arm-none-eabi-gcc-build.git/scripts/build.sh clean
```

To also remove the repository and the output files, use:

```console
$ bash ~/Downloads/arm-none-eabi-gcc-build.git/scripts/build.sh cleanall
```

### --develop

For performance reasons, the actual build folders are internal to each Docker run, and are not persistent. This has the disadvantage that interrupted builds cannot be resumed.

For development builds, it is possible to define the build folders in the host file system, and resume an interrupted build.

### --debug

For development builds, it is also possible to create everything with `-g -O0` and be able to run debug sessions.

## Install

The procedure to install GNU MCU Eclipse ARM Embedded GCC is platform specific, but relatively straight forward (a .zip archive on Windows, a compressed tar archive on macOS and GNU/Linux).

A portable method is to use [`xpm`](https://www.npmjs.com/package/xpm):

```console
$ xpm install @gnu-mcu-eclipse/arm-none-eabi-gcc --global
```

After install, the package should create a structure like this (only the first two depth levels are shown):

```console
$ tree -L 2 /Users/ilg/opt/gnu-mcu-eclipse/arm-none-eabi-gcc/7.1.1-1-20170702-0625/
... TBD
```

No other files are installed in any system folders or other locations.

## Uninstall

The binaries are distributed as portable archives, that do not need to run a setup and do not require an uninstall.

## Test

A simple test is performed by the script at the end, by launching the executable to check if all shared/dynamic libraries are correctly used.

For a true test you need to first install the package and then run the program form the final location. For example on macOS the output should look like:

```console
$ .../gnu-mcu-eclipse/arm-none-eabi-gcc/7.1.1-1-20170702-0625/bin/arm-none-eabi-gcc --version
arm-none-eabi-gcc (GNU MCU Eclipse ARM Embedded GCC, 64-bits) 7.1.1 20170509
```

## More build details

The build process is split into several scripts. The build starts on the host, with `build.sh`, which runs `container-build.sh` several times, once for each target, in one of the two docker containers. Both scripts include several other helper scripts. The entire process is quite complex, and an attempt to explain its functionality in a few words would not be realistic. Thus, the authoritative source of details remains the source code.
