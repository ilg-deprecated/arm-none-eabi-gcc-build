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

# Script to build the GNU MCU Eclipse ARM Embeded GCC distribution packages.
#
# Developed on macOS 10.13 High Sierra, but intended to run on
# macOS 10.10 Yosemite and CentOS 6 XBB. 

# -----------------------------------------------------------------------------

# Identify helper scripts.

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

# The Work folder is in HOME.
HOST_WORK_FOLDER_PATH=${HOST_WORK_FOLDER_PATH:-"${HOME}/Work/${APP_LC_NAME}"}
CONTAINER_WORK_FOLDER_PATH="/Host/Work/${APP_LC_NAME}"

host_functions_script_path="${script_folder_path}/helper/host-functions-source.sh"
echo "Host helper functions source script: \"${host_functions_script_path}\"."
source "${host_functions_script_path}"

# Copy the current scripts to the Work area, to later copy them into 
# the install folder.
rm -rf "${HOST_WORK_FOLDER_PATH}/scripts"
mkdir -p "${HOST_WORK_FOLDER_PATH}/scripts/helper"
cp "${script_folder_path}"/*.sh \
  "${HOST_WORK_FOLDER_PATH}/scripts"
cp "${script_folder_path}"/helper/container-functions-source.sh \
  "${HOST_WORK_FOLDER_PATH}/scripts/helper"
cp "${script_folder_path}"/helper/host-functions-source.sh \
  "${HOST_WORK_FOLDER_PATH}/scripts/helper"

# Copy the patches.
rm -rf "${HOST_WORK_FOLDER_PATH}"/patches
cp -r "$(dirname ${script_folder_path})"/gnu-mcu-eclipse/patches \
  "${HOST_WORK_FOLDER_PATH}"

# Copy VERSION.
cp -r "$(dirname ${script_folder_path})"/gnu-mcu-eclipse/VERSION \
  "${HOST_WORK_FOLDER_PATH}"/scripts

container_build_script_path="${script_folder_path}/helper/${CONTAINER_SCRIPT_NAME}"
echo "Container build script: \"${container_build_script_path}\"."


# -----------------------------------------------------------------------------

docker_linux64_image="ilegeul/centos:6-xbb-v1"
docker_linux32_image="ilegeul/centos32:6-xbb-v1"

# -----------------------------------------------------------------------------

ACTION=""

DO_BUILD_WIN32=""
DO_BUILD_WIN64=""
DO_BUILD_LINUX32=""
DO_BUILD_LINUX64=""
DO_BUILD_OSX=""
ENV_FILE=""

argc=$#
declare -a argv
argv=( $@ )
i=0

declare -a rest

while [ $i -lt $argc ]
do

  arg="${argv[$i]}"
  case "${arg}" in

    clean|cleanall|preload-images)
      ACTION="${arg}"
      ;;

    --win32|--window32)
      DO_BUILD_WIN32="y"
      ;;

    --win64|--windows64)
      DO_BUILD_WIN64="y"
      ;;

    --linux32)
      DO_BUILD_LINUX32="y"
      ;;

    --linux64)
      DO_BUILD_LINUX64="y"
      ;;

    --osx)
      DO_BUILD_OSX="y"
      ;;

    --all)
      DO_BUILD_WIN32="y"
      DO_BUILD_WIN64="y"
      DO_BUILD_LINUX32="y"
      DO_BUILD_LINUX64="y"
      if [ "$(uname)" == "Darwin" ] 
      then
        DO_BUILD_OSX="y"
      fi
      ;;

    --env-file)
      ((++i))
      ENV_FILE="${argv[$i]}"
      ;;

    --date)
      ((++i))
      DISTRIBUTION_FILE_DATE="${argv[$i]}"
      ;;

    --help)
      echo "Build the GNU MCU Eclipse ${APP_NAME} distributions."
      echo "Usage:"
      # Some of the options are processed by the container script.
      echo "    bash $0 helper_script [--win32] [--win64] [--linux32] [--linux64] [--osx] [--all] [clean|cleanall|preload-images] [--env-file file] [--date YYYYmmdd-HHMM] [--disable-strip] [--without-pdf] [--with-html] [--disable-multilib] [--develop] [--use-gits] [--jobs N] [--help]"
      echo
      exit 1
      ;;

    *)
      # Collect all other in an array. Append to the end.
      # Will be later processed by the container script.
      rest[${#rest[*]}]="$arg"
      ;;

  esac
  ((++i))

done

# The ${rest[@]} options will be passed to the inner script.
if [ -n "${DEBUG}" ]
then
  echo ${rest[@]-}
fi

# -----------------------------------------------------------------------------

# Set the DISTRIBUTION_FILE_DATE.
host_get_current_date

# -----------------------------------------------------------------------------

host_start_timer

host_detect

host_prepare_prerequisites

# TODO: pass more variables to host-defines-source.sh

# -----------------------------------------------------------------------------

if [ "${ACTION}" == "preload-images" ]
then
  host_prepare_docker

  echo
  echo "Check/Preload Docker images..."

  echo
  docker run --interactive --tty ${docker_linux64_image} \
    lsb_release --description --short

  echo
  docker run --interactive --tty ${docker_linux64_image} \
    lsb_release --description --short

  echo
  docker images

  host_stop_timer

  exit 0
elif [ \( "${ACTION}" == "clean" \) -o \( "${ACTION}" == "cleanall" \) ]
then
  # Remove most build and temporary folders.
  echo
  if [ "${ACTION}" == "cleanall" ]
  then
    echo "Remove all the build folders..."

    rm -rf "${HOST_WORK_FOLDER_PATH}"
  else
    echo "Remove most of the build folders (except output)..."

    rm -rf "${HOST_WORK_FOLDER_PATH}"/build
    rm -rf "${HOST_WORK_FOLDER_PATH}"/install
    rm -rf "${HOST_WORK_FOLDER_PATH}"/scripts

    rm -rf "${HOST_WORK_FOLDER_PATH}"/*-*
  fi

  echo
  echo "Clean completed. Proceed with a regular build."

  exit 0
fi


# -----------------------------------------------------------------------------

if [ -n "${DO_BUILD_WIN32}${DO_BUILD_WIN64}${DO_BUILD_LINUX32}${DO_BUILD_LINUX64}" ]
then
  host_prepare_docker
fi

# ----- Build the native distribution. ----------------------------------------

if [ -z "${DO_BUILD_OSX}${DO_BUILD_LINUX64}${DO_BUILD_WIN64}${DO_BUILD_LINUX32}${DO_BUILD_WIN32}" ]
then

  host_build_target "Creating the native distribution..." \
    --script "${HOST_WORK_FOLDER_PATH}/scripts/${CONTAINER_SCRIPT_NAME}" \
    --env-file "${ENV_FILE}" \
    -- \
    ${rest[@]-}

else

  # ----- Build the OS X distribution. ----------------------------------------

  if [ "${DO_BUILD_OSX}" == "y" ]
  then
    if [ "${HOST_UNAME}" == "Darwin" ]
    then
      host_build_target "Creating the OS X distribution..." \
        --script "${HOST_WORK_FOLDER_PATH}/scripts/${CONTAINER_SCRIPT_NAME}" \
        --env-file "${ENV_FILE}" \
        --target-os osx \
        -- \
        ${rest[@]-}
    else
      echo "Building the macOS image is not possible on this platform."
      exit 1
    fi
  fi

  # ----- Build the GNU/Linux 64-bits distribution. ---------------------------

  linux_distribution="centos"
  
  if [ "${DO_BUILD_LINUX64}" == "y" ]
  then
    host_build_target "Creating the GNU/Linux 64-bits distribution..." \
      --script "${CONTAINER_WORK_FOLDER_PATH}/scripts/${CONTAINER_SCRIPT_NAME}" \
      --env-file "${ENV_FILE}" \
      --target-os linux \
      --target-bits 64 \
      --docker-image "${docker_linux64_image}" \
      -- \
      ${rest[@]-}
  fi

  # ----- Build the Windows 64-bits distribution. -----------------------------

  if [ "${DO_BUILD_WIN64}" == "y" ]
  then
    if [ ! -f "${HOST_WORK_FOLDER_PATH}/install/${linux_distribution}64/${APP_LC_NAME}/bin/${GCC_TARGET}-gcc" ]
    then
      host_build_target "Creating the GNU/Linux 64-bits distribution..." \
        --script "${CONTAINER_WORK_FOLDER_PATH}/scripts/${CONTAINER_SCRIPT_NAME}" \
        --env-file "${ENV_FILE}" \
        --target-os linux \
        --target-bits 64 \
        --docker-image "${docker_linux64_image}" \
        -- \
        ${rest[@]-}
    fi

    if [ ! -f "${HOST_WORK_FOLDER_PATH}/install/${linux_distribution}64/${APP_LC_NAME}/bin/${GCC_TARGET}-gcc" ]
    then
      echo "Mandatory GNU/Linux binaries missing."
      exit 1
    fi

    host_build_target "Creating the Windows 64-bits distribution..." \
      --script "${CONTAINER_WORK_FOLDER_PATH}/scripts/${CONTAINER_SCRIPT_NAME}" \
      --env-file "${ENV_FILE}" \
      --target-os win \
      --target-bits 64 \
      --docker-image "${docker_linux64_image}" \
      -- \
      --linux-install-path "install/${linux_distribution}64/${APP_LC_NAME}" \
      ${rest[@]-}
  fi

  # ----- Build the GNU/Linux 32-bits distribution. ---------------------------

  if [ "${DO_BUILD_LINUX32}" == "y" ]
  then
    host_build_target "Creating the GNU/Linux 32-bits distribution..." \
      --script "${CONTAINER_WORK_FOLDER_PATH}/scripts/${CONTAINER_SCRIPT_NAME}" \
      --env-file "${ENV_FILE}" \
      --target-os linux \
      --target-bits 32 \
      --docker-image "${docker_linux32_image}" \
      -- \
      ${rest[@]-}
  fi

  # ----- Build the Windows 32-bits distribution. -----------------------------

  # Since the actual container is a 32-bits, use the debian32 binaries.
  if [ "${DO_BUILD_WIN32}" == "y" ]
  then
    if [ ! -f "${HOST_WORK_FOLDER_PATH}/install/${linux_distribution}32/${APP_LC_NAME}/bin/${GCC_TARGET}-gcc" ]
    then
      host_build_target "Creating the GNU/Linux 32-bits distribution..." \
        --script "${CONTAINER_WORK_FOLDER_PATH}/scripts/${CONTAINER_SCRIPT_NAME}" \
        --env-file "${ENV_FILE}" \
        --target-os linux \
        --target-bits 32 \
        --docker-image "${docker_linux32_image}" \
        -- \
        ${rest[@]-}
    fi

    if [ ! -f "${HOST_WORK_FOLDER_PATH}/install/${linux_distribution}32/${APP_LC_NAME}/bin/${GCC_TARGET}-gcc" ]
    then
      echo "Mandatory GNU/Linux binaries missing."
      exit 1
    fi

    host_build_target "Creating the Windows 32-bits distribution..." \
      --script "${CONTAINER_WORK_FOLDER_PATH}/scripts/${CONTAINER_SCRIPT_NAME}" \
      --env-file "${ENV_FILE}" \
      --target-os win \
      --target-bits 32 \
      --docker-image "${docker_linux32_image}" \
      -- \
      --linux-install-path "install/${linux_distribution}32/${APP_LC_NAME}" \
      ${rest[@]-}
  fi

fi

host_show_sha

# -----------------------------------------------------------------------------

host_stop_timer

# Done successfully.
exit 0

# -----------------------------------------------------------------------------
