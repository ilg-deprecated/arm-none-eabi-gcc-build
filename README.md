# GNU MCU Eclipse ARM Embedded GCC build

These are the additional files required by the **GNU MCU Eclipse ARM Embedded GCC** build procedures.

This release closely follows the official [GNU Arm Embedded Toolchain](https://developer.arm.com/open-source/gnu-toolchain/gnu-rm).

## Changes

Compared to the original ARM version, there are no functional changes; the **same architecture options** are supported, and **the same combinations of libraries** (derived from newlib) are provided.

The main difference is that the binaries generated cover all modern platforms, Windows 32/64-bits, GNU/Linux 32/64-bits, macOS 64-bits.

## How to build?

To download the build scripts:

```console
$ git clone --recurse-submodules https://github.com/gnu-mcu-eclipse/arm-none-eabi-gcc-build.git \
  ~/Downloads/arm-none-eabi-gcc-build.git
```

To build the latest version:

```console
$ caffeinate bash ~/Downloads/arm-none-eabi-gcc-build.git/scripts/build.sh --osx
```

To build a previous version:

```console
$ RELEASE_VERSION=5.4.1-1 caffeinate bash ~/Downloads/arm-none-eabi-gcc-build.git/scripts/build.sh --osx
$ RELEASE_VERSION=6.3.1-1 caffeinate bash ~/Downloads/arm-none-eabi-gcc-build.git/scripts/build.sh --osx
$ RELEASE_VERSION=7.2.1-1 caffeinate bash ~/Downloads/arm-none-eabi-gcc-build.git/scripts/build.sh --osx
```

For the prerequisites and more details on the build procedure, please see the [How to build the ARM Embedded GCC binaries?](http://gnu-mcu-eclipse.github.io/toolchain/arm/build-procedure/) page. 

