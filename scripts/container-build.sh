#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Safety settings (see https://gist.github.com/ilg-ul/383869cbb01f61a51c4d).

if [[ ! -z ${DEBUG} ]]
then
  set ${DEBUG} # Activate the expand mode if DEBUG is anything but empty.
else
  DEBUG=""
fi

set -o errexit # Exit if command failed.
set -o pipefail # Exit if pipe failed.
set -o nounset # Exit if variable not set.

# Remove the initial space and instead use '\n'.
IFS=$'\n\t'

# -----------------------------------------------------------------------------

# Inner script to run inside Docker containers to build the 
# GNU MCU Eclipse ARM Embedded GCC distribution packages.

# For native builds, it runs on the host (macOS build cases,
# and development builds for GNU/Linux).

# -----------------------------------------------------------------------------

# ----- Identify helper scripts. -----

build_script_path=$0
if [[ "${build_script_path}" != /* ]]
then
  # Make relative path absolute.
  build_script_path=$(pwd)/$0
fi

script_folder_path="$(dirname ${build_script_path})"
script_folder_name="$(basename ${script_folder_path})"

defines_script_path="${script_folder_path}/defs-source.sh"
echo "Definitions source script: \"${defines_script_path}\"."
source "${defines_script_path}"

TARGET_OS=""
TARGET_BITS=""
HOST_UNAME=""

# Keep them updated with combo archive content.
binutils_version="2.29"
gcc_version="7.2.1"
newlib_version="2.5.0"
gdb_version="8.0"

# Be sure the changes in the build.git are commited.
# otherwise the copied git may use the previous version.

RELEASE_VERSION=${RELEASE_VERSION:-"${gcc_version}-1"}

echo
echo "Preparing release ${RELEASE_VERSION}..."

# This file is generated by the host build script.
host_defines_script_path="${script_folder_path}/host-defs-source.sh"
echo "Host definitions source script: \"${host_defines_script_path}\"."
source "${host_defines_script_path}"

container_lib_functions_script_path="${script_folder_path}/${CONTAINER_LIB_FUNCTIONS_SCRIPT_NAME}"
echo "Container lib functions source script: \"${container_lib_functions_script_path}\"."
source "${container_lib_functions_script_path}"

container_app_functions_script_path="${script_folder_path}/${CONTAINER_APP_FUNCTIONS_SCRIPT_NAME}"
echo "Container app functions source script: \"${container_app_functions_script_path}\"."
source "${container_app_functions_script_path}"

container_functions_script_path="${script_folder_path}/helper/container-functions-source.sh"
echo "Container helper functions source script: \"${container_functions_script_path}\"."
source "${container_functions_script_path}"

# -----------------------------------------------------------------------------

WITH_STRIP="y"
MULTILIB_FLAGS="--with-multilib-list=rmprofile"
WITH_PDF="y"
IS_DEVELOP=""
IS_DEBUG=""

while [ $# -gt 0 ]
do

  case "$1" in

    --disable-strip)
      WITH_STRIP="n"
      shift
      ;;

    --without-pdf)
      WITH_PDF="n"
      shift
      ;;

    --disable-multilib)
      MULTILIB_FLAGS="--disable-multilib"
      shift
      ;;

    --jobs)
      JOBS="--jobs=$2"
      shift 2
      ;;

    --develop)
      IS_DEVELOP="y"
      shift
      ;;

    --debug)
      IS_DEBUG="y"
      shift
      ;;

    *)
      echo "Unknown action/option $1"
      exit 1
      ;;

  esac

done

# -----------------------------------------------------------------------------

start_timer

detect

prepare_prerequisites

# -----------------------------------------------------------------------------

UNAME="$(uname)"

# Make all tools choose gcc, not the old cc.
if [ "${UNAME}" == "Darwin" ]
then
  export CC=clang
  export CXX=clang++
elif [ "${TARGET_OS}" == "linux" ]
then
  export CC=gcc
  export CXX=g++
fi

EXTRA_CFLAGS="-ffunction-sections -fdata-sections -m${TARGET_BITS} -pipe -O2"
EXTRA_CXXFLAGS="-ffunction-sections -fdata-sections -m${TARGET_BITS} -pipe -O2"

if [ "${IS_DEBUG}" == "y" ]
then
  EXTRA_CFLAGS+=" -g"
  EXTRA_CXXFLAGS+=" -g"
fi

EXTRA_CPPFLAGS="-I${INSTALL_FOLDER_PATH}"/include
EXTRA_LDFLAGS_LIB="-L${INSTALL_FOLDER_PATH}"/lib
EXTRA_LDFLAGS="${EXTRA_LDFLAGS_LIB}"
EXTRA_LDFLAGS_APP="${EXTRA_LDFLAGS} -static-libstdc++"
if [ "${UNAME}" == "Darwin" ]
then
  EXTRA_LDFLAGS_APP+=" -Wl,-dead_strip"
else
  EXTRA_LDFLAGS_APP+=" -Wl,--gc-sections"
fi

export PKG_CONFIG=pkg-config-verbose
export PKG_CONFIG_LIBDIR="${INSTALL_FOLDER_PATH}"/lib/pkgconfig

APP_PREFIX="${INSTALL_FOLDER_PATH}/${APP_LC_NAME}"
APP_PREFIX_DOC="${APP_PREFIX}"/share/doc

APP_PREFIX_NANO="${INSTALL_FOLDER_PATH}/${APP_LC_NAME}"-nano

# The \x2C is a comma in hex; without this trick the regular expression
# that processes this string in the Makefile, silently fails and the 
# bfdver.h file remains empty.
BRANDING="${BRANDING}\x2C ${TARGET_BITS}-bits"
CFLAGS_OPTIMIZATIONS_FOR_TARGET="-ffunction-sections -fdata-sections -O2"

# -----------------------------------------------------------------------------
# Libraries

# For just in case, usually it should pick the lib packed inside the archive.
do_zlib

# The classical GCC libraries.
do_gmp
do_mpfr
do_mpc
do_isl

do_libelf
do_expat
do_libiconv
do_xz

# -----------------------------------------------------------------------------

# Download the combo package from ARM.
do_gcc_download

# The task numbers are from the ARM build script.

# Task [III-0] /$HOST_NATIVE/binutils/
do_binutils
# copy_dir to libs included above

# Task [III-1] /$HOST_NATIVE/gcc-first/
do_gcc_first

# Task [III-2] /$HOST_NATIVE/newlib/
do_newlib ""
# Task [III-3] /$HOST_NATIVE/newlib-nano/
do_newlib "-nano"

# Task [III-4] /$HOST_NATIVE/gcc-final/
do_gcc_final ""

# Task [III-5] /$HOST_NATIVE/gcc-size-libstdcxx/
do_gcc_final "-nano"

# Task [III-6] /$HOST_NATIVE/gdb/
do_gdb ""
do_gdb "-py"

# Task [III-7] /$HOST_NATIVE/build-manual

# Task [III-8] /$HOST_NATIVE/pretidy/
do_pretidy

# Task [III-9] /$HOST_NATIVE/strip_host_objects/
do_strip_binaries

# Task [III-10] /$HOST_NATIVE/strip_target_objects/
do_strip_libs

do_check_binaries
do_copy_license_files
do_copy_scripts

# Task [III-11] /$HOST_NATIVE/package_tbz2/
do_create_archive

fix_ownership

# -----------------------------------------------------------------------------

stop_timer

exit 0

# -----------------------------------------------------------------------------
