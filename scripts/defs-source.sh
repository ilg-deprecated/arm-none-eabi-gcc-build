# -----------------------------------------------------------------------------

# Helper script used in the second edition of the build scripts.
# As the name implies, it should contain only definitions and should
# be included with 'source' by the host and container scripts.

# Warning: MUST NOT depend on $HOME or other environment variables.

# -----------------------------------------------------------------------------

# Used to display the application name.
APP_NAME=${APP_NAME:-"ARM Embedded GCC"}

# Used as part of file/folder paths.
APP_UC_NAME=${APP_UC_NAME:-"ARM Embedded GCC"}
APP_LC_NAME=${APP_LC_NAME:-"arm-none-eabi-gcc"}

BRANDING=${BRANDING:-"GNU MCU Eclipse ARM Embedded GCC"}

GCC_TARGET=${GCC_TARGET:-"arm-none-eabi-gcc"}

# Attempts to use 8 occasionally failed.
JOBS="--jobs=4"

CONTAINER_SCRIPT_NAME=${CONTAINER_SCRIPT_NAME:-"container-build.sh"}
CONTAINER_LIB_FUNCTIONS_SCRIPT_NAME=${CONTAINER_LIB_FUNCTIONS_SCRIPT_NAME:-"container-lib-functions-source.sh"}

# -----------------------------------------------------------------------------
