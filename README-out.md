# GNU MCU Eclipse ARM Embedded GCC

This is the **GNU MCU Eclipse** (formerly GNU ARM Eclipse) version of the 
[GNU Arm Embedded Toolchain](https://developer.arm.com/open-source/gnu-toolchain/gnu-rm).

## Easy install

The **GNU MCU Eclipse ARM Embedded GCC** toolchain is also available as a binary [xPack](https://www.npmjs.com/package/@gnu-mcu-eclipse/arm-none-eabi-gcc) and can be conveniently installed with [xpm](https://www.npmjs.com/package/xpm):

```console
$ xpm install @gnu-mcu-eclipse/arm-none-eabi-gcc --global
```

For more details on how to install the toolchain, please see [How to install the ARM toolchain?](http://gnu-mcu-eclipse.github.io/toolchain/arm/install/) page.

## Compliance

This release closely follows the official ARM distribution, as described in the original ARM release text files:

- `gnu-mcu-eclipse/arm-readme.txt`
- `gnu-mcu-eclipse/arm-release.txt`

## Changes

Compared to the ARM distribution, the build procedure is more or less the same and there should be no functional differences.

The only addition affects newlib, which was extended with `printf()`/`scanf()` support for `long long` and C99 formats (`--enable-newlib-io-long-long` and `--enable-newlib-io-c99-formats`).

## Compatibility

The binaries were built using [xPack Build Box (XBB)](https://github.com/xpack/xpack-build-box), a set of build environments based on slightly older systems that should be compatible with most recent systems.

- GNU/Linux: all binaries built with GCC 7.2, running in a CentOS 6 Docker container
- Windows: all binaries built with mingw-w64 GCC 7.2, running in a CentOS 6 Docker container 
- macOS: all binaries built GCC 7.2, running in a custom Homebrew instance on macOS 10.10.5, except GDB which was built with Apple clang, since neither building with GCC 7 or GCC 6 produced functional binaries (SIGABRT for `set language auto`)

## Build

The scripts used to build this distribution are in:

- `gnu-mcu-eclipse/scripts`

For the prerequisites and more details on the build procedure, please see the [How to build the ARM Embedded GCC binaries?](http://gnu-mcu-eclipse.github.io/toolchain/arm/build-procedure/) page. 

## Documentation

The original PDF documentation is available in:

- `share/doc/pdf`

## More info

For more info and support, please see the GNU MCU Eclipse project pages from:

http://gnu-mcu-eclipse.github.io


Thank you for using **GNU MCU Eclipse**,

Liviu Ionescu


