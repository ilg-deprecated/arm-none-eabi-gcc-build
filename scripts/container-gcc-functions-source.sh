# -----------------------------------------------------------------------------

# Helper script used in the second edition of the GNU MCU Eclipse build 
# scripts. As the name implies, it should contain only functions and 
# should be included with 'source' by the container build scripts.

# -----------------------------------------------------------------------------

# https://developer.arm.com/-/media/Files/downloads/gnu-rm/7-2017q4/gcc-arm-none-eabi-7-2017-q4-major-src.tar.bz2

gcc_combo_version="7-2017-q4-major"
gcc_combo_folder="gcc-arm-none-eabi-${gcc_combo_version}"
gcc_combo_archive="${gcc_combo_folder}-src.tar.bz2"

function do_gcc_download() 
{
  # https://developer.arm.com/open-source/gnu-toolchain/gnu-rm
  # https://developer.arm.com/open-source/gnu-toolchain/gnu-rm/downloads

  local gcc_combo_url="https://developer.arm.com/-/media/Files/downloads/gnu-rm/7-2017q4/gcc-arm-none-eabi-7-2017-q4-major-src.tar.bz2"

  cd "${WORK_FOLDER_PATH}"

  download_and_extract "${gcc_combo_url}" "${gcc_combo_archive}" "${gcc_combo_folder}"
}

binutils_src_folder_name="binutils"

function do_binutils()
{
  # https://ftp.gnu.org/gnu/binutils/
  # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=binutils-git
  # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=gdb-git

  binutils_folder_name="binutils"
  local binutils_stamp_file_path="${BUILD_FOLDER_PATH}/${binutils_folder_name}/stamp-install-completed"

  if [ ! -f "${binutils_stamp_file_path}" ]
  then

    cd "${WORK_FOLDER_PATH}"

    extract "${gcc_combo_folder}"/src/binutils.tar.bz2 "${binutils_src_folder_name}"

    (
      mkdir -p "${BUILD_FOLDER_PATH}/${binutils_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${binutils_folder_name}"

      xbb_activate

      if [ ! -f "config.status" ]
      then

        echo
        echo "Running binutils configure..."
      
        bash "${WORK_FOLDER_PATH}/${binutils_src_folder_name}/configure" --help

        export CFLAGS="${EXTRA_CFLAGS} -Wno-unknown-warning-option -Wno-extended-offsetof -Wno-deprecated-declarations -Wno-incompatible-pointer-types-discards-qualifiers -Wno-implicit-function-declaration -Wno-parentheses -Wno-format-nonliteral -Wno-shift-count-overflow -Wno-constant-logical-operand -Wno-shift-negative-value -Wno-format"
        export CXXFLAGS="${EXTRA_CXXFLAGS} -Wno-format-nonliteral -Wno-format-security -Wno-deprecated -Wno-unknown-warning-option -Wno-c++11-narrowing"
        export CPPFLAGS="${EXTRA_CPPFLAGS}"
        export LDFLAGS="${EXTRA_LDFLAGS_APP}" 

        # ? --without-python --without-curses, --with-expat

        bash "${WORK_FOLDER_PATH}/${binutils_src_folder_name}/configure" \
          --prefix="${APP_PREFIX}" \
          --infodir="${APP_PREFIX_DOC}/info" \
          --mandir="${APP_PREFIX_DOC}/man" \
          --htmldir="${APP_PREFIX_DOC}/html" \
          --pdfdir="${APP_PREFIX_DOC}/pdf" \
          \
          --build=${BUILD} \
          --host=${HOST} \
          --target=${GCC_TARGET} \
          \
          --with-pkgversion="${BRANDING}" \
          \
          --disable-nls \
          --disable-werror \
          --disable-sim \
          --disable-gdb \
          --enable-interwork \
          --enable-plugins \
          --with-sysroot="${APP_PREFIX}/${GCC_TARGET}" \
          \
          --disable-shared \
          --enable-static \
          --disable-build-warnings \
          --disable-rpath \
          --with-system-zlib \
          \
        | tee "${INSTALL_FOLDER_PATH}/configure-binutils-output.txt"
        cp "config.log" "${INSTALL_FOLDER_PATH}"/config-binutils-log.txt

      fi

      echo
      echo "Running binutils make..."
      
      (
        make ${JOBS} 
        make install

        if [ "${WITH_PDF}" == "y" ]
        then
          make ${JOBS} pdf
          make install-pdf
        fi

        if [ "${WITH_HTML}" == "y" ]
        then
          make ${JOBS} html
          make install-html
        fi

        # Without this copy, the build for the nano version of the GCC second 
        # step fails with unexpected errors, like "cannot compute suffix of 
        # object files: cannot compile".
        copy_dir "${APP_PREFIX}" "${APP_PREFIX_NANO}"

      ) | tee "${INSTALL_FOLDER_PATH}/make-newlib-output.txt"
    )

    if [ "${TARGET_OS}" != "win" ]
    then
      "${APP_PREFIX}/bin/${GCC_TARGET}-ar" --version
      "${APP_PREFIX}/bin/${GCC_TARGET}-as" --version
      "${APP_PREFIX}/bin/${GCC_TARGET}-ld" --version
      "${APP_PREFIX}/bin/${GCC_TARGET}-nm" --version
      "${APP_PREFIX}/bin/${GCC_TARGET}-objcopy" --version
      "${APP_PREFIX}/bin/${GCC_TARGET}-objdump" --version
      "${APP_PREFIX}/bin/${GCC_TARGET}-ranlib" --version
      "${APP_PREFIX}/bin/${GCC_TARGET}-size" --version
      "${APP_PREFIX}/bin/${GCC_TARGET}-strings" --version
      "${APP_PREFIX}/bin/${GCC_TARGET}-strip" --version
    fi

    touch "${binutils_stamp_file_path}"
  else
    echo "Step binutils already done."
  fi
}

gcc_src_folder_name="gcc"

function do_gcc_first()
{
  local gcc_first_folder_name="gcc-first"
  local gcc_first_stamp_file_path="${BUILD_FOLDER_PATH}/${gcc_first_folder_name}/stamp-install-completed"

  if [ ! -f "${gcc_first_stamp_file_path}" ]
  then

    cd "${WORK_FOLDER_PATH}"

    extract "${gcc_combo_folder}"/src/gcc.tar.bz2 "${gcc_src_folder_name}"

    (
      mkdir -p "${BUILD_FOLDER_PATH}/${gcc_first_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${gcc_first_folder_name}"

      xbb_activate

      if [ ! -f "config.status" ]
      then

        echo
        echo "Running gcc first stage configure..."
      
        bash "${WORK_FOLDER_PATH}/${gcc_src_folder_name}/configure" --help

        export GCC_WARN_CFLAGS="-Wno-tautological-compare -Wno-deprecated-declarations -Wno-unknown-warning-option -Wno-unused-value -Wno-extended-offsetof -Wno-implicit-fallthrough -Wno-implicit-function-declaration -Wno-mismatched-tags"
        export CFLAGS="${EXTRA_CFLAGS} ${GCC_WARN_CFLAGS}" 
        export GCC_WARN_CXXFLAGS="-Wno-keyword-macro -Wno-unused-private-field -Wno-format-security -Wno-char-subscripts -Wno-deprecated -Wno-gnu-zero-variadic-macro-arguments -Wno-mismatched-tags -Wno-c99-extensions -Wno-array-bounds -Wno-extended-offsetof -Wno-invalid-offsetof -Wno-implicit-fallthrough -Wno-mismatched-tags -Wno-format-security" 
        export CXXFLAGS="${EXTRA_CXXFLAGS} ${GCC_WARN_CXXFLAGS}" 
        export CPPFLAGS="${EXTRA_CPPFLAGS}" 
        export LDFLAGS="${EXTRA_LDFLAGS_APP}" 

        export CFLAGS_FOR_TARGET="${CFLAGS_OPTIMIZATIONS_FOR_TARGET}" 
        export CXXFLAGS_FOR_TARGET="${CFLAGS_OPTIMIZATIONS_FOR_TARGET}" 

        # https://gcc.gnu.org/install/configure.html
        # --enable-shared[=package[,…]] build shared versions of libraries
        # --enable-tls specify that the target supports TLS (Thread Local Storage). 
        # --enable-nls enables Native Language Support (NLS)
        # --enable-checking=list the compiler is built to perform internal consistency checks of the requested complexity. ‘yes’ (most common checks)
        # --with-headers=dir specify that target headers are available when building a cross compiler
        # --with-newlib Specifies that ‘newlib’ is being used as the target C library. This causes `__eprintf`` to be omitted from `libgcc.a`` on the assumption that it will be provided by newlib.
        # --enable-languages=c newlib does not use C++, so C should be enough

        # --enable-checking=no ???

        bash "${WORK_FOLDER_PATH}/${gcc_src_folder_name}/configure" \
          --prefix="${APP_PREFIX}"  \
          --libexecdir="${APP_PREFIX}/lib" \
          --infodir="${APP_PREFIX_DOC}/info" \
          --mandir="${APP_PREFIX_DOC}/man" \
          --htmldir="${APP_PREFIX_DOC}/html" \
          --pdfdir="${APP_PREFIX_DOC}/pdf" \
          \
          --build=${BUILD} \
          --host=${HOST} \
          --target=${GCC_TARGET} \
          \
          --with-pkgversion="${BRANDING}" \
          \
          --enable-languages=c \
          --disable-decimal-float \
          --disable-libffi \
          --disable-libgomp \
          --disable-libmudflap \
          --disable-libquadmath \
          --disable-libssp \
          --disable-libstdcxx-pch \
          --disable-nls \
          --disable-shared \
          --disable-threads \
          --disable-tls \
          --with-newlib \
          --without-headers \
          --with-gnu-as \
          --with-gnu-ld \
          --with-python-dir=share/gcc-${GCC_TARGET} \
          --with-sysroot="${APP_PREFIX}/${GCC_TARGET}" \
          ${MULTILIB_FLAGS} \
          \
          --disable-rpath \
          --with-system-zlib \
          WARN_PEDANTIC='' \
          \
        | tee "${INSTALL_FOLDER_PATH}/configure-gcc-first-output.txt"
        cp "config.log" "${INSTALL_FOLDER_PATH}"/config-gcc-first-log.txt

      fi

      # Partial build, without documentation.
      echo
      echo "Running gcc first stage make..."

      (
        # No need to make 'all', 'all-gcc' is enough to compile the libraries.
        # Parallel build fails for win32.
        if [ "${UNAME}" == "Darwin" ]
        then
          make all-gcc ${JOBS}
        else
          make all-gcc ${JOBS}
        fi
        make install-gcc
      ) | tee "${INSTALL_FOLDER_PATH}/make-gcc-first-output.txt"
    )

    touch "${gcc_first_stamp_file_path}"
  else
    echo "Step gcc first stage already done."
  fi
}

newlib_src_folder_name="newlib"

# For the nano build, call it with "-nano".
# $1="" or $1="-nano"
function do_newlib()
{
  local newlib_folder_name="newlib$1"
  local newlib_stamp_file_path="${BUILD_FOLDER_PATH}/${newlib_folder_name}/stamp-install-completed"

  if [ ! -f "${newlib_stamp_file_path}" ]
  then

    cd "${WORK_FOLDER_PATH}"

    extract "${gcc_combo_folder}"/src/newlib.tar.bz2 "${newlib_src_folder_name}"

    (
      mkdir -p "${BUILD_FOLDER_PATH}/${newlib_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${newlib_folder_name}"

      xbb_activate

      # Add the gcc first stage binaries to the path.
      PATH="${APP_PREFIX}/bin":${PATH}

      if [ ! -f "config.status" ]
      then

        # --disable-nls do not use Native Language Support
        # --enable-newlib-io-long-double   enable long double type support in IO functions printf/scanf
        # --enable-newlib-io-long-long   enable long long type support in IO functions like printf/scanf
        # --enable-newlib-io-c99-formats   enable C99 support in IO functions like printf/scanf
        # --enable-newlib-register-fini   enable finalization function registration using atexit
        # --disable-newlib-supplied-syscalls disable newlib from supplying syscalls (__NO_SYSCALLS__)

        # --disable-newlib-fvwrite-in-streamio    disable iov in streamio
        # --disable-newlib-fseek-optimization    disable fseek optimization
        # --disable-newlib-wide-orient    Turn off wide orientation in streamio
        # --disable-newlib-unbuf-stream-opt    disable unbuffered stream optimization in streamio
        # --enable-newlib-nano-malloc    use small-footprint nano-malloc implementation
        # --enable-lite-exit	enable light weight exit
        # --enable-newlib-global-atexit	enable atexit data structure as global
        # --enable-newlib-nano-formatted-io    Use nano version formatted IO
        # --enable-newlib-reent-small

        # --enable-newlib-retargetable-locking ???

        echo
        echo "Running newlib$1 configure..."
      
        bash "${WORK_FOLDER_PATH}/${newlib_src_folder_name}/configure" --help

        local optimize="${CFLAGS_OPTIMIZATIONS_FOR_TARGET}"
        if [ "$1" == "-nano" ]
        then
          # For newlib-nano optimize for size.
          optimize="$(echo ${optimize} | sed -e 's/-O2/-Os/')"
        fi

        export CFLAGS="${EXTRA_CFLAGS}"
        export CXXFLAGS="${EXTRA_CXXFLAGS}"
        export CPPFLAGS="${EXTRA_CPPFLAGS}" 

        # Note the intentional `-g`.
        export CFLAGS_FOR_TARGET="${optimize} -g -Wno-implicit-function-declaration -Wno-incompatible-pointer-types -Wno-int-conversion -Wno-logical-not-parentheses -Wno-implicit-int" 
        export CXXFLAGS_FOR_TARGET="${optimize} -g" 

        # I still did not figure out how to define a variable with
        # the list of options, such that it can be extended, so the
        # brute force approach is to duplicate the entire call.

        if [ "$1" == "" ]
        then

          # TODO: Check if long-long and c990formats are ok.
          bash "${WORK_FOLDER_PATH}/${newlib_src_folder_name}/configure" \
            --prefix="${APP_PREFIX}"  \
            --infodir="${APP_PREFIX_DOC}/info" \
            --mandir="${APP_PREFIX_DOC}/man" \
            --htmldir="${APP_PREFIX_DOC}/html" \
            --pdfdir="${APP_PREFIX_DOC}/pdf" \
            \
            --build=${BUILD} \
            --host=${HOST} \
            --target="${GCC_TARGET}" \
            \
            --enable-newlib-io-long-double \
            --enable-newlib-register-fini \
            --enable-newlib-retargetable-locking \
            --disable-newlib-supplied-syscalls \
            --disable-nls \
            \
            --enable-newlib-io-long-long \
            --enable-newlib-io-c99-formats \
            \
          | tee "${INSTALL_FOLDER_PATH}/configure-newlib$1-output.txt"

        elif [ "$1" == "-nano" ]
        then

          # TODO: Check if long-long and c990formats are ok.
          # TODO: Check if register-fini is needed.
          bash "${WORK_FOLDER_PATH}/${newlib_src_folder_name}/configure" \
            --prefix="${APP_PREFIX_NANO}"  \
            \
            --build=${BUILD} \
            --host=${HOST} \
            --target="${GCC_TARGET}" \
            \
            --disable-newlib-supplied-syscalls \
            --enable-newlib-reent-small \
            --disable-newlib-fvwrite-in-streamio \
            --disable-newlib-fseek-optimization \
            --disable-newlib-wide-orient \
            --enable-newlib-nano-malloc \
            --disable-newlib-unbuf-stream-opt \
            --enable-lite-exit \
            --enable-newlib-global-atexit \
            --enable-newlib-nano-formatted-io \
            --disable-nls \
            \
            --enable-newlib-io-long-long \
            --enable-newlib-io-c99-formats \
            --enable-newlib-register-fini \
            \
          | tee "${INSTALL_FOLDER_PATH}/configure-newlib$1-output.txt"

        else
          echo "Unsupported do_newlib arg $1"
          exit 1
        fi
        cp "config.log" "${INSTALL_FOLDER_PATH}"/config-newlib$1-log.txt

      fi

      # Partial build, without documentation.
      echo
      echo "Running newlib$1 make..."

      (
        # Parallel build failed on CentOS XBB
        if [ "${TARGET_OS}" == "osx" ]
        then
          make ${JOBS}
        else
          make
        fi 
        make install

        if [ "$1" == "" ]
        then

          if [ "${WITH_PDF}" == "y" ]
          then

            # Waning, parallel build failed on Debian 32-bits.

            make ${JOBS} pdf

            /usr/bin/install -v -d "${APP_PREFIX_DOC}"/pdf

            /usr/bin/install -v -c -m 644 \
              "${GCC_TARGET}"/libgloss/doc/porting.pdf "${APP_PREFIX_DOC}"/pdf
            /usr/bin/install -v -c -m 644 \
              "${GCC_TARGET}"/newlib/libc/libc.pdf "${APP_PREFIX_DOC}"/pdf
            /usr/bin/install -v -c -m 644 \
              "${GCC_TARGET}"/newlib/libm/libm.pdf "${APP_PREFIX_DOC}"/pdf

          fi

          if [ "${WITH_HTML}" == "y" ]
          then

            make ${JOBS} html

            /usr/bin/install -v -d "${APP_PREFIX_DOC}"/html

            copy_dir "${GCC_TARGET}"/newlib/libc/libc.html "${APP_PREFIX_DOC}"/html/libc
            copy_dir "${GCC_TARGET}"/newlib/libm/libm.html "${APP_PREFIX_DOC}"/html/libm

          fi

        fi

      ) | tee "${INSTALL_FOLDER_PATH}/make-gcc-first-output.txt"
    )

    touch "${newlib_stamp_file_path}"
  else
    echo "Step newlib$1 already done."
  fi
}

# -----------------------------------------------------------------------------

function do_copy_libs() 
{
  local src_folder="$1"
  local dst_folder="$2"

  if [ -f "${src_folder}"/libstdc++.a ]
  then
    cp -v -f "${src_folder}"/libstdc++.a "${dst_folder}"/libstdc++_nano.a
  fi
  if [ -f "${src_folder}"/libsupc++.a ]
  then
    cp -v -f "${src_folder}"/libsupc++.a "${dst_folder}"/libsupc++_nano.a
  fi
  cp -v -f "${src_folder}"/libc.a "${dst_folder}"/libc_nano.a
  cp -v -f "${src_folder}"/libg.a "${dst_folder}"/libg_nano.a
  if [ -f "${src_folder}"/librdimon.a ]
  then
    cp -v -f "${src_folder}"/librdimon.a "${dst_folder}"/librdimon_nano.a
  fi

  cp -v -f "${src_folder}"/nano.specs "${dst_folder}"/
  if [ -f "${src_folder}"/rdimon.specs ]
  then
    cp -v -f "${src_folder}"/rdimon.specs "${dst_folder}"/
  fi
  cp -v -f "${src_folder}"/nosys.specs "${dst_folder}"/
  cp -v -f "${src_folder}"/*crt0.o "${dst_folder}"/
}

# Copy target libraries from each multilib folders.
# $1=source
# $2=destination
# $3=target gcc
function do_copy_multi_libs()
{
  local -a multilibs
  local multilib
  local multi_folder
  local src_folder="$1"
  local dst_folder="$2"
  local gcc_target="$3"

  echo ${gcc_target}
  multilibs=( $("${gcc_target}" -print-multi-lib 2>/dev/null) )
  if [ ${#multilibs[@]} -gt 0 ]
  then
    for multilib in "${multilibs[@]}"
    do
      multi_folder="${multilib%%;*}"
      do_copy_libs "${src_folder}/${multi_folder}" \
        "${dst_folder}/${multi_folder}"
    done
  else
    do_copy_libs "${src_folder}" "${dst_folder}"
  fi
}

# -----------------------------------------------------------------------------

# For the nano build, call it with "-nano".
# $1="" or $1="-nano"
function do_gcc_final()
{
  local gcc_final_folder_name="gcc-final$1"
  local gcc_final_stamp_file_path="${BUILD_FOLDER_PATH}/${gcc_final_folder_name}/stamp-install-completed"

  if [ ! -f "${gcc_final_stamp_file_path}" ]
  then

    cd "${WORK_FOLDER_PATH}"

    extract "${gcc_combo_folder}"/src/gcc.tar.bz2 "${gcc_src_folder_name}"

    (
      mkdir -p "${BUILD_FOLDER_PATH}/${gcc_final_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${gcc_final_folder_name}"

      xbb_activate

      if [ ! -f "config.status" ]
      then

        echo
        echo "Running gcc$1 final stage configure..."
      
        bash "${WORK_FOLDER_PATH}/${gcc_src_folder_name}/configure" --help

        export GCC_WARN_CFLAGS="-Wno-tautological-compare -Wno-deprecated-declarations -Wno-unknown-warning-option -Wno-unused-value -Wno-extended-offsetof -Wno-implicit-fallthrough -Wno-implicit-function-declaration -Wno-mismatched-tags"
        export CFLAGS="${EXTRA_CFLAGS} ${GCC_WARN_CFLAGS}" 
        export GCC_WARN_CXXFLAGS="-Wno-keyword-macro -Wno-unused-private-field -Wno-format-security -Wno-char-subscripts -Wno-deprecated -Wno-gnu-zero-variadic-macro-arguments -Wno-mismatched-tags -Wno-c99-extensions -Wno-array-bounds -Wno-extended-offsetof -Wno-invalid-offsetof -Wno-implicit-fallthrough -Wno-mismatched-tags -Wno-format-security" 
        export CXXFLAGS="${EXTRA_CXXFLAGS} ${GCC_WARN_CXXFLAGS}" 
        export CPPFLAGS="${EXTRA_CPPFLAGS}" 
        export LDFLAGS="${EXTRA_LDFLAGS_APP}" 

        local optimize="${CFLAGS_OPTIMIZATIONS_FOR_TARGET}"
        if [ "$1" == "-nano" ]
        then
          # For newlib-nano optimize for size.
          optimize="$(echo ${optimize} | sed -e 's/-O2/-Os/')"
        fi

        # Note the intentional `-g`.
        export CFLAGS_FOR_TARGET="${optimize} -g" 
        export CXXFLAGS_FOR_TARGET="${optimize} -fno-exceptions -g" 

        # https://gcc.gnu.org/install/configure.html
        # --enable-shared[=package[,…]] build shared versions of libraries
        # --enable-tls specify that the target supports TLS (Thread Local Storage). 
        # --enable-nls enables Native Language Support (NLS)
        # --enable-checking=list the compiler is built to perform internal consistency checks of the requested complexity. ‘yes’ (most common checks)
        # --with-headers=dir specify that target headers are available when building a cross compiler
        # --with-newlib Specifies that ‘newlib’ is being used as the target C library. This causes `__eprintf`` to be omitted from `libgcc.a`` on the assumption that it will be provided by newlib.
        # --enable-languages=c,c++ Support only C/C++, ignore all other.

        # WARN_PEDANTIC seems ignored and requires more work.

        if [ "$1" == "" ]
        then

          bash "${WORK_FOLDER_PATH}/${gcc_src_folder_name}/configure" \
            --prefix="${APP_PREFIX}"  \
            --libexecdir="${APP_PREFIX}/lib" \
            --infodir="${APP_PREFIX_DOC}/info" \
            --mandir="${APP_PREFIX_DOC}/man" \
            --htmldir="${APP_PREFIX_DOC}/html" \
            --pdfdir="${APP_PREFIX_DOC}/pdf" \
            \
            --build=${BUILD} \
            --host=${HOST} \
            --target=${GCC_TARGET} \
            \
            --with-pkgversion="${BRANDING}" \
            \
            --enable-languages=c,c++ \
            --enable-plugins \
            --disable-decimal-float \
            --disable-libffi \
            --disable-libgomp \
            --disable-libmudflap \
            --disable-libquadmath \
            --disable-libssp \
            --disable-libstdcxx-pch \
            --disable-nls \
            --disable-shared \
            --disable-threads \
            --disable-tls \
            --with-gnu-as \
            --with-gnu-ld \
            --with-newlib \
            --with-headers=yes \
            --with-python-dir=share/gcc-${GCC_TARGET} \
            --with-sysroot="${APP_PREFIX}/${GCC_TARGET}" \
            ${MULTILIB_FLAGS} \
            \
            --disable-rpath \
            --with-system-zlib \
            WARN_PEDANTIC= \
            \
          | tee "${INSTALL_FOLDER_PATH}/configure-gcc$1-last-output.txt"
          cp "config.log" "${INSTALL_FOLDER_PATH}"/config-gcc$1-first-log.txt

        else

          bash "${WORK_FOLDER_PATH}/${gcc_src_folder_name}/configure" \
            --prefix="${APP_PREFIX_NANO}"  \
            \
            --build=${BUILD} \
            --host=${HOST} \
            --target=${GCC_TARGET} \
            \
            --with-pkgversion="${BRANDING}" \
            \
            --enable-languages=c,c++ \
            --disable-decimal-float \
            --disable-libffi \
            --disable-libgomp \
            --disable-libmudflap \
            --disable-libquadmath \
            --disable-libssp \
            --disable-libstdcxx-pch \
            --disable-libstdcxx-verbose \
            --disable-nls \
            --disable-shared \
            --disable-threads \
            --disable-tls \
            --with-gnu-as \
            --with-gnu-ld \
            --with-newlib \
            --with-headers=yes \
            --with-python-dir=share/gcc-${GCC_TARGET} \
            --with-sysroot="${APP_PREFIX_NANO}/${GCC_TARGET}" \
            ${MULTILIB_FLAGS} \
            \
            --disable-rpath \
            --with-system-zlib \
            WARN_PEDANTIC= \
            \
          | tee "${INSTALL_FOLDER_PATH}/configure-gcc$1-last-output.txt"
          cp "config.log" "${INSTALL_FOLDER_PATH}"/config-gcc$1-first-log.txt

        fi

      fi

      # Partial build, without documentation.
      echo
      echo "Running gcc$1 final stage make..."

      (
        # Passing USE_TM_CLONE_REGISTRY=0 via INHIBIT_LIBC_CFLAGS to disable
        # transactional memory related code in crtbegin.o.
        # This is a workaround. Better approach is have a t-* to set this flag via
        # CRTSTUFF_T_CFLAGS
        make ${JOBS} INHIBIT_LIBC_CFLAGS="-DUSE_TM_CLONE_REGISTRY=0"
        make install-strip

        if [ "$1" == "" ]
        then

          # Full build, with documentation.
          if [ "${WITH_PDF}" == "y" ]
          then
            make ${JOBS} pdf
            make install-pdf
          fi

          if [ "${WITH_HTML}" == "y" ]
          then
            make ${JOBS} html
            make install-html
          fi

        elif [ "$1" == "-nano" ]
        then

          local target_gcc=""
          if [ "${TARGET_OS}" == "win" ]
          then
            target_gcc="${GCC_TARGET}-gcc"
          else
            target_gcc="${APP_PREFIX_NANO}/bin/${GCC_TARGET}-gcc"
          fi

          # Copy the libraries after appending the `_nano` suffix.
          # Iterate through all multilib names.
          do_copy_multi_libs \
            "${APP_PREFIX_NANO}/${GCC_TARGET}/lib" \
            "${APP_PREFIX}/${GCC_TARGET}/lib" \
            "${target_gcc}"

          # Copy the nano configured newlib.h file into the location that nano.specs
          # expects it to be.
          mkdir -p "${APP_PREFIX}/${GCC_TARGET}/include/newlib-nano"
          cp -v -f "${APP_PREFIX_NANO}/${GCC_TARGET}/include/newlib.h" \
            "${APP_PREFIX}/${GCC_TARGET}/include/newlib-nano/newlib.h"

        fi

      ) | tee "${INSTALL_FOLDER_PATH}/make-gcc-last-output.txt"
    )

    touch "${gcc_final_stamp_file_path}"
  else
    echo "Step gcc$1 final stage already done."
  fi
}

gdb_src_folder_name="gdb"

# Called twice, with and without python support.
# $1="" or $1="-py"
function do_gdb()
{
  local gdb_folder_name="gdb$1"
  local gdb_stamp_file_path="${BUILD_FOLDER_PATH}/${gdb_folder_name}/stamp-install-completed"

  if [ ! -f "${gdb_stamp_file_path}" ]
  then

    cd "${WORK_FOLDER_PATH}"

    extract "${gcc_combo_folder}"/src/gdb.tar.bz2 "${gdb_src_folder_name}" "${gdb_version}"

    (
      mkdir -p "${BUILD_FOLDER_PATH}/${gdb_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${gdb_folder_name}"

      xbb_activate

      if [ ! -f "config.status" ]
      then

        echo
        echo "Running gdb$1 configure..."
      
        bash "${WORK_FOLDER_PATH}/${gdb_src_folder_name}/configure" --help

        export GCC_WARN_CFLAGS="-Wno-implicit-function-declaration -Wno-parentheses -Wno-format -Wno-incompatible-pointer-types-discards-qualifiers -Wno-extended-offsetof -Wno-deprecated-declarations"
        export CFLAGS="${EXTRA_CFLAGS} ${GCC_WARN_CFLAGS}" 
        export GCC_WARN_CXXFLAGS="-Wno-deprecated-declarations" 
        export CXXFLAGS="${EXTRA_CXXFLAGS} ${GCC_WARN_CXXFLAGS}" 
        export CPPFLAGS="${EXTRA_CPPFLAGS}" 
        export LDFLAGS="${EXTRA_LDFLAGS_APP}" 

        local extra_python_opts="--with-python=no"
        if [ "$1" == "-py" ]
        then
          extra_python_opts="--with-python=yes"
        fi

        bash "${WORK_FOLDER_PATH}/${gdb_src_folder_name}/configure" \
          --prefix="${APP_PREFIX}"  \
          --infodir="${APP_PREFIX_DOC}/info" \
          --mandir="${APP_PREFIX_DOC}/man" \
          --htmldir="${APP_PREFIX_DOC}/html" \
          --pdfdir="${APP_PREFIX_DOC}/pdf" \
          \
          --build=${BUILD} \
          --host=${HOST} \
          --target=${GCC_TARGET} \
          \
          --with-pkgversion="${BRANDING}" \
          \
          --disable-nls \
          --disable-sim \
          --disable-gas \
          --disable-binutils \
          --disable-ld \
          --disable-gprof \
          --with-libexpat \
          --with-lzma=yes \
          --with-system-gdbinit="${APP_PREFIX}/${GCC_TARGET}"/lib/gdbinit \
          \
          ${extra_python_opts} \
          --program-prefix="${GCC_TARGET}-" \
          --program-suffix="$1" \
          \
          --disable-werror \
          --disable-rpath \
          --with-system-zlib \
          --without-guile \
          --without-babeltrace \
          --without-libunwind-ia64 \
          \
        | tee "${INSTALL_FOLDER_PATH}/configure-gdb$1-output.txt"
        cp "config.log" "${INSTALL_FOLDER_PATH}"/config-gdb$1-log.txt

      fi

      # Partial build, without documentation.
      echo
      echo "Running gdb$1 make..."

      (
        make ${JOBS}
        make install

        if [ "$1" == "" ]
        then

          if [ "${WITH_PDF}" == "y" ]
          then
            make ${JOBS} pdf
            make install-pdf
          fi

          if [ "${WITH_HTML}" == "y" ]
          then
            make ${JOBS} html 
            make install-html 
          fi
          
        fi
      ) | tee "${INSTALL_FOLDER_PATH}/make-gdb$1-output.txt"
    )

    if [ "${TARGET_OS}" != "win" ]
    then
      (
        # Required by gdb-py to access the python shared library.
        xbb_activate

        "${APP_PREFIX}/bin/${GCC_TARGET}-gdb$1" --version
        "${APP_PREFIX}/bin/${GCC_TARGET}-gdb$1" --config
      )
    fi

    touch "${gdb_stamp_file_path}"
  else
    echo "Step gdb$1 already done."
  fi
}

function do_pretidy() 
{
  local stamp_file_path="${BUILD_FOLDER_PATH}/stamp-pretidy-completed"

  if [ ! -f "${stamp_file_path}" ]
  then
    find "${APP_PREFIX}" -name "libiberty.a" -exec rm -v '{}' ';'
    find "${APP_PREFIX}" -name '*.la' -exec rm -v '{}' ';'

    touch "${stamp_file_path}"
  else
    echo "Step pretidy already done."
  fi
}

function do_strip_binaries()
{
  local stamp_file_path="${BUILD_FOLDER_PATH}/stamp-strip-binaries-completed"
  
  if [ ! -f "${stamp_file_path}" ]
  then
    if [ "${WITH_STRIP}" == "y" ]
    then
      local binaries=$(find "${INSTALL_FOLDER_PATH}"/bin -name ${GCC_TARGET}-\*)
      for bin in ${binaries} ; do
          strip_binary strip ${bin}
      done

      binaries=$(find ${APP_PREFIX}/bin -maxdepth 1 -mindepth 1 -name \*)
      for bin in ${binaries} ; do
          strip_binary strip ${bin}
      done

      set +e
      if [ "${UNAME}" == "Darwin" ]; then
          binaries=$(find ${APP_PREFIX}/lib/gcc/${GCC_TARGET}/* -maxdepth 1 -name \* -perm +111 -and ! -type d)
      else
          binaries=$(find ${APP_PREFIX}/lib/gcc/${GCC_TARGET}/* -maxdepth 1 -name \* -perm /111 -and ! -type d)
      fi
      set -e

      for bin in ${binaries} ; do
          strip_binary strip ${bin}
      done
    fi

    touch "${stamp_file_path}"
  else
    echo "Step strip-binaries already done."
  fi
}

function do_strip_libs()
{
  local stamp_file_path="${BUILD_FOLDER_PATH}/stamp-strip-libs-completed"
  
  if [ ! -f "${stamp_file_path}" ]
  then
    if [ "${WITH_STRIP}" == "y" ]
    then
      (
        PATH="${APP_PREFIX}/bin":${PATH}

        local libs=$(find "${APP_PREFIX}" -name '*.[ao]')
        for lib in ${libs}
        do
            echo ${GCC_TARGET}-objcopy -R ... ${lib}
            ${GCC_TARGET}-objcopy -R .comment -R .note -R .debug_info -R .debug_aranges -R .debug_pubnames -R .debug_pubtypes -R .debug_abbrev -R .debug_line -R .debug_str -R .debug_ranges -R .debug_loc ${lib} || true
        done
      )
    fi

    touch "${stamp_file_path}"
  else
    echo "Step strip-libs already done."
  fi
}

function do_copy_license_files()
{
  local stamp_file_path="${BUILD_FOLDER_PATH}/stamp-copy_license-completed"
  
  if [ ! -f "${stamp_file_path}" ]
  then

    echo
    echo "Copying license files..."

    copy_license \
      "${WORK_FOLDER_PATH}/${zlib_folder}" "${zlib_folder}"
    copy_license \
      "${WORK_FOLDER_PATH}/${gmp_folder}" "${gmp_folder}"
    copy_license \
      "${WORK_FOLDER_PATH}/${mpfr_folder}" "${mpfr_folder}"
    copy_license \
      "${WORK_FOLDER_PATH}/${mpc_folder}" "${mpc_folder}"
    copy_license \
      "${WORK_FOLDER_PATH}/${isl_folder}" "${isl_folder}"
    copy_license \
      "${WORK_FOLDER_PATH}/${libelf_folder}" "${libelf_folder}"
    copy_license \
      "${WORK_FOLDER_PATH}/${expat_folder}" "${expat_folder}"
    copy_license \
      "${WORK_FOLDER_PATH}/${libiconv_folder}" "${libiconv_folder}"
    copy_license \
      "${WORK_FOLDER_PATH}/${xz_folder}" "${xz_folder}"

    copy_license \
      "${WORK_FOLDER_PATH}/${binutils_src_folder_name}" "${binutils_src_folder_name}-${binutils_version}"
    copy_license \
      "${WORK_FOLDER_PATH}/${gcc_src_folder_name}" "${gcc_src_folder_name}-${gcc_version}"
    copy_license \
      "${WORK_FOLDER_PATH}/${newlib_src_folder_name}" "${newlib_src_folder_name}-${newlib_version}"
    copy_license \
      "${WORK_FOLDER_PATH}/${gdb_src_folder_name}" "${gdb_src_folder_name}-${gdb_version}"

    touch "${stamp_file_path}"

  else
    echo "Step copy-license already done."
  fi
}

function do_check_binaries()
{
  local stamp_file_path="${BUILD_FOLDER_PATH}/stamp-check-binaries-completed"
  
  if [ ! -f "${stamp_file_path}" ]
  then
    if [ "${WITH_STRIP}" == "y" ]
    then
      local binaries=$(find "${INSTALL_FOLDER_PATH}"/bin -name ${GCC_TARGET}-\*)
      for bin in ${binaries} 
      do
          check_binary ${bin}
      done

      binaries=$(find ${APP_PREFIX}/bin -maxdepth 1 -mindepth 1 -name \*)
      for bin in ${binaries} 
      do
          check_binary ${bin}
      done

      set +e
      if [ "${UNAME}" == "Darwin" ]; then
          binaries=$(find ${APP_PREFIX}/lib/gcc/${GCC_TARGET}/* -maxdepth 1 -name \* -perm +111 -and ! -type d)
      else
          binaries=$(find ${APP_PREFIX}/lib/gcc/${GCC_TARGET}/* -maxdepth 1 -name \* -perm /111 -and ! -type d)
      fi
      set -e

      for bin in ${binaries}
      do
        check_binary ${bin}
      done
    fi

    # touch "${stamp_file_path}"
  else
    echo "Step strip-binaries already done."
  fi
}

function do_create_archive()
{
  (
    xbb_activate

    cd "${APP_PREFIX}"

    local distribution_file_version="${RELEASE_VERSION}-${DISTRIBUTION_FILE_DATE}"
    local distribution_file="${WORK_FOLDER_PATH}/${DEPLOY_FOLDER_NAME}/gnu-mcu-eclipse-${APP_LC_NAME}-${distribution_file_version}-${TARGET_FOLDER_NAME}.tgz"

    local prefix
    prefix_path="gnu-mcu-eclipse/${APP_LC_NAME}/${distribution_file_version}"
    echo
    echo "Creating \"${distribution_file}\" ..."
    tar -c -z -f "${distribution_file}" \
      --transform="s|^|${prefix_path}/|" \
      --owner=0 \
      --group=0 \
      *

    cd "${WORK_FOLDER_PATH}/${DEPLOY_FOLDER_NAME}"
    compute_sha shasum -a 256 -p "$(basename ${distribution_file})"
  )
}