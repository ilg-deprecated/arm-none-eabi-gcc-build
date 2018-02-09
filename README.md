# GNU MCU Eclipse ARM Embedded GCC build

These are the additional files required by the **GNU MCU Eclipse ARM Embedded GCC** build procedures.

This release closely follows the official [GNU Arm Embedded Toolchain](https://developer.arm.com/open-source/gnu-toolchain/gnu-rm).

## Changes

Compared to the original ARM version, there are no functional changes; the **same architecture options** are supported, and **the same combinations of libraries** (derived from newlib) are provided.

The main difference is that the binaries generated cover all modern platforms, Windows 32/64-bits, GNU/Linux 32/64-bits, macOS 64-bits.

## How to build?

```console
$ git clone --recurse-submodules https://github.com/gnu-mcu-eclipse/arm-none-eabi-gcc-build.git \
  ~/Downloads/arm-none-eabi-gcc-build.git
```

