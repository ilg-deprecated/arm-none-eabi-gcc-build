# -----------------------------------------------------------------------------

# Helper script used in the second edition of the GNU MCU Eclipse build 
# scripts. As the name implies, it should contain only functions and 
# should be included with 'source' by the container build scripts.

# -----------------------------------------------------------------------------

function do_gcc_combo_download() 
{
  # https://developer.arm.com/open-source/gnu-toolchain/gnu-rm
  # https://developer.arm.com/open-source/gnu-toolchain/gnu-rm/downloads

  cd "${WORK_FOLDER_PATH}"

  download_and_extract "${GCC_COMBO_URL}" "${GCC_COMBO_ARCHIVE}" "${GCC_COMBO_FOLDER_NAME}"
}

function do_python_download() 
{
  # https://www.python.org/downloads/release/python-2714/
  # https://www.python.org/ftp/python/2.7.14/python-2.7.14.msi
  # https://www.python.org/ftp/python/2.7.14/python-2.7.14.amd64.msi


  cd "${WORK_FOLDER_PATH}"

  download "${PYTHON_WIN_URL}" "${PYTHON_WIN_PACK}"

  if [ ! -d "${PYTHON_WIN}" ]
  then
    # Hack to install a tool able to unpack .MSI setups.
    # TODO: move to XBB.
    # https://sourceforge.net/projects/p7zip/files/p7zip/16.02/p7zip_16.02_src_all.tar.bz2/download
    p7zip_version="16.02"
    p7zip_folder_name="p7zip_${p7zip_version}"
    p7zip_archive="${p7zip_folder_name}_src_all.tar.bz2"
    p7zip_url="https://sourceforge.net/projects/p7zip/files/p7zip/${p7zip_version}/${p7zip_archive}"

    cd "${BUILD_FOLDER_PATH}"
    download_and_extract "${p7zip_url}" "${p7zip_archive}" "${p7zip_folder_name}"

    cd "${p7zip_folder_name}"
    # Test only 7za
    make test

    cd "${WORK_FOLDER_PATH}"
    # Include only the headers and the python library and executable.
    echo '*.h' >/tmp/included
    echo 'python*.dll' >>/tmp/included
    echo 'python*.lib' >>/tmp/included
    "${BUILD_FOLDER_PATH}/${p7zip_folder_name}"/bin/7za x -o"${PYTHON_WIN}" "${DOWNLOAD_FOLDER_PATH}/${PYTHON_WIN_PACK}" -i@/tmp/included

    # Patch to disable the macro that renames hypot.
    if [ -f "${WORK_FOLDER_PATH}/patches/${PYTHON_WIN}.patch" ]
    then
      patch -p0 <"${WORK_FOLDER_PATH}/patches/${PYTHON_WIN}.patch" 
    fi
  else
    echo "Folder ${PYTHON_WIN} already present."
  fi
}

BINUTILS_SRC_FOLDER_NAME="binutils"

function do_binutils()
{
  # https://ftp.gnu.org/gnu/binutils/
  # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=binutils-git
  # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=gdb-git

  BINUTILS_FOLDER_NAME="binutils-${BINUTILS_VERSION}"
  local binutils_stamp_file_path="${BUILD_FOLDER_PATH}/${BINUTILS_FOLDER_NAME}/stamp-install-completed"

  if [ ! -f "${binutils_stamp_file_path}" ]
  then

    cd "${WORK_FOLDER_PATH}"

    extract "${GCC_COMBO_FOLDER_NAME}"/src/binutils.tar.bz2 "${BINUTILS_SRC_FOLDER_NAME}"

    (
      mkdir -p "${BUILD_FOLDER_PATH}/${BINUTILS_FOLDER_NAME}"
      cd "${BUILD_FOLDER_PATH}/${BINUTILS_FOLDER_NAME}"

      xbb_activate

      if [ ! -f "config.status" ]
      then

        echo
        echo "Running binutils configure..."
      
        bash "${WORK_FOLDER_PATH}/${BINUTILS_SRC_FOLDER_NAME}/configure" --help

        export CFLAGS="${EXTRA_CFLAGS} -Wno-unknown-warning-option -Wno-extended-offsetof -Wno-deprecated-declarations -Wno-incompatible-pointer-types-discards-qualifiers -Wno-implicit-function-declaration -Wno-parentheses -Wno-format-nonliteral -Wno-shift-count-overflow -Wno-constant-logical-operand -Wno-shift-negative-value -Wno-format"
        export CXXFLAGS="${EXTRA_CXXFLAGS} -Wno-format-nonliteral -Wno-format-security -Wno-deprecated -Wno-unknown-warning-option -Wno-c++11-narrowing"
        export CPPFLAGS="${EXTRA_CPPFLAGS}"
        LDFLAGS="${EXTRA_LDFLAGS_APP}" 
        if [ "${TARGET_OS}" == "win" ]
        then
          LDFLAGS="${LDFLAGS} -Wl,${XBB_FOLDER}/${CROSS_COMPILE_PREFIX}/lib/CRT_glob.o"
        fi
        export LDFLAGS

        # ? --without-python --without-curses, --with-expat

        bash "${WORK_FOLDER_PATH}/${BINUTILS_SRC_FOLDER_NAME}/configure" \
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
      echo
      "${APP_PREFIX}/bin/${GCC_TARGET}-ar" --version
      echo
      "${APP_PREFIX}/bin/${GCC_TARGET}-as" --version
      echo
      "${APP_PREFIX}/bin/${GCC_TARGET}-ld" --version
      echo
      "${APP_PREFIX}/bin/${GCC_TARGET}-nm" --version
      echo
      "${APP_PREFIX}/bin/${GCC_TARGET}-objcopy" --version
      echo
      "${APP_PREFIX}/bin/${GCC_TARGET}-objdump" --version
      echo
      "${APP_PREFIX}/bin/${GCC_TARGET}-ranlib" --version
      echo
      "${APP_PREFIX}/bin/${GCC_TARGET}-size" --version
      echo
      "${APP_PREFIX}/bin/${GCC_TARGET}-strings" --version
      echo
      "${APP_PREFIX}/bin/${GCC_TARGET}-strip" --version
    fi

    touch "${binutils_stamp_file_path}"
  else
    echo "Step binutils already done."
  fi
}

GCC_SRC_FOLDER_NAME="gcc"

function do_gcc_first()
{
  local gcc_first_folder_name="gcc-${GCC_VERSION}-first"
  local gcc_first_stamp_file_path="${BUILD_FOLDER_PATH}/${gcc_first_folder_name}/stamp-install-completed"

  if [ ! -f "${gcc_first_stamp_file_path}" ]
  then

    cd "${WORK_FOLDER_PATH}"

    extract "${GCC_COMBO_FOLDER_NAME}"/src/gcc.tar.bz2 "${GCC_SRC_FOLDER_NAME}"

    (
      mkdir -p "${BUILD_FOLDER_PATH}/${gcc_first_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${gcc_first_folder_name}"

      xbb_activate

      if [ ! -f "config.status" ]
      then

        echo
        echo "Running gcc first stage configure..."
      
        bash "${WORK_FOLDER_PATH}/${GCC_SRC_FOLDER_NAME}/configure" --help

        export GCC_WARN_CFLAGS="-Wno-tautological-compare -Wno-deprecated-declarations -Wno-unknown-warning-option -Wno-unused-value -Wno-extended-offsetof -Wno-implicit-fallthrough -Wno-implicit-function-declaration -Wno-mismatched-tags -Wno-unused-but-set-variable"
        export CFLAGS="${EXTRA_CFLAGS} ${GCC_WARN_CFLAGS}" 
        export GCC_WARN_CXXFLAGS="-Wno-keyword-macro -Wno-unused-private-field -Wno-format-security -Wno-char-subscripts -Wno-deprecated -Wno-gnu-zero-variadic-macro-arguments -Wno-mismatched-tags -Wno-c99-extensions -Wno-array-bounds -Wno-extended-offsetof -Wno-invalid-offsetof -Wno-implicit-fallthrough -Wno-mismatched-tags -Wno-format-security -Wno-suggest-attribute=format -Wno-format-extra-args -Wno-format -Wno-mismatched-tags -Wno-varargs -Wno-shift-count-overflow -Wno-ignored-attributes -Wno-tautological-compare -Wno-unused-label -Wno-format-pedantic -Wno-unused-parameter" 
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

        bash "${WORK_FOLDER_PATH}/${GCC_SRC_FOLDER_NAME}/configure" \
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
        # Parallel build failed once on win32.
        make ${JOBS} all-gcc
        make install-gcc
      ) | tee "${INSTALL_FOLDER_PATH}/make-gcc-first-output.txt"
    )

    touch "${gcc_first_stamp_file_path}"
  else
    echo "Step gcc first stage already done."
  fi
}

NEWLIB_SRC_FOLDER_NAME="newlib"

# For the nano build, call it with "-nano".
# $1="" or $1="-nano"
function do_newlib()
{
  local newlib_folder_name="newlib-${NEWLIB_VERSION}$1"
  local newlib_stamp_file_path="${BUILD_FOLDER_PATH}/${newlib_folder_name}/stamp-install-completed"

  if [ ! -f "${newlib_stamp_file_path}" ]
  then

    cd "${WORK_FOLDER_PATH}"

    extract "${GCC_COMBO_FOLDER_NAME}"/src/newlib.tar.bz2 "${NEWLIB_SRC_FOLDER_NAME}"

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
      
        bash "${WORK_FOLDER_PATH}/${NEWLIB_SRC_FOLDER_NAME}/configure" --help

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
          bash "${WORK_FOLDER_PATH}/${NEWLIB_SRC_FOLDER_NAME}/configure" \
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
          bash "${WORK_FOLDER_PATH}/${NEWLIB_SRC_FOLDER_NAME}/configure" \
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

function do_copy_nano_libs() 
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
      do_copy_nano_libs "${src_folder}/${multi_folder}" \
        "${dst_folder}/${multi_folder}"
    done
  else
    do_copy_nano_libs "${src_folder}" "${dst_folder}"
  fi
}

# -----------------------------------------------------------------------------

function do_copy_linux_libs()
{
  local copy_linux_stamp_file_path="${BUILD_FOLDER_PATH}/stamp-copy-linux-completed"
  if [ ! -f "${copy_linux_stamp_file_path}" ]
  then

    local linux_path="${LINUX_INSTALL_PATH}"

    copy_dir "${linux_path}/${GCC_TARGET}"/lib "${APP_PREFIX}/${GCC_TARGET}"/lib
    copy_dir "${linux_path}/${GCC_TARGET}"/include "${APP_PREFIX}/${GCC_TARGET}"/include
    copy_dir "${linux_path}"/include "${APP_PREFIX}"/include
    copy_dir "${linux_path}"/lib "${APP_PREFIX}"/lib
    copy_dir "${linux_path}"/share "${APP_PREFIX}"/share

    (
      cd "${APP_PREFIX}"
      find "${GCC_TARGET}"/lib "${GCC_TARGET}"/include include lib share \
        -perm /111 -and ! -type d \
        -exec rm '{}' ';'
    )
    touch "${copy_linux_stamp_file_path}"

  else
    echo "Step copy-linux-libs already done."
  fi
}

# -----------------------------------------------------------------------------

# For the nano build, call it with "-nano".
# $1="" or $1="-nano"
function do_gcc_final()
{
  local gcc_final_folder_name="gcc-${GCC_VERSION}-final$1"
  local gcc_final_stamp_file_path="${BUILD_FOLDER_PATH}/${gcc_final_folder_name}/stamp-install-completed"

  if [ ! -f "${gcc_final_stamp_file_path}" ]
  then

    cd "${WORK_FOLDER_PATH}"

    extract "${GCC_COMBO_FOLDER_NAME}"/src/gcc.tar.bz2 "${GCC_SRC_FOLDER_NAME}"

    (
      mkdir -p "${BUILD_FOLDER_PATH}/${gcc_final_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${gcc_final_folder_name}"

      xbb_activate

      if [ ! -f "config.status" ]
      then

        echo
        echo "Running gcc$1 final stage configure..."
      
        bash "${WORK_FOLDER_PATH}/${GCC_SRC_FOLDER_NAME}/configure" --help

        export GCC_WARN_CFLAGS="-Wno-tautological-compare -Wno-deprecated-declarations -Wno-unknown-warning-option -Wno-unused-value -Wno-extended-offsetof -Wno-implicit-fallthrough -Wno-implicit-function-declaration -Wno-mismatched-tags -Wno-unused-but-set-variable"
        export CFLAGS="${EXTRA_CFLAGS} ${GCC_WARN_CFLAGS}" 
        export GCC_WARN_CXXFLAGS="-Wno-keyword-macro -Wno-unused-private-field -Wno-format-security -Wno-char-subscripts -Wno-deprecated -Wno-gnu-zero-variadic-macro-arguments -Wno-mismatched-tags -Wno-c99-extensions -Wno-array-bounds -Wno-extended-offsetof -Wno-invalid-offsetof -Wno-implicit-fallthrough -Wno-mismatched-tags -Wno-format-security -Wno-suggest-attribute=format -Wno-format-extra-args -Wno-format -Wno-unused-function -Wno-attributes" 
        export CXXFLAGS="${EXTRA_CXXFLAGS} ${GCC_WARN_CXXFLAGS}" 
        export CPPFLAGS="${EXTRA_CPPFLAGS}" 
        export LDFLAGS="${EXTRA_LDFLAGS_APP}" 
        # Do not add CRT_glob.o here, it will fail with already defined,
        # since it is already handled by --enable-mingw-wildcard.

        local optimize="${CFLAGS_OPTIMIZATIONS_FOR_TARGET}"
        if [ "$1" == "-nano" ]
        then
          # For newlib-nano optimize for size.
          optimize="$(echo ${optimize} | sed -e 's/-O2/-Os/')"
        fi

        # Note the intentional `-g`.
        export CFLAGS_FOR_TARGET="${optimize} -g" 
        export CXXFLAGS_FOR_TARGET="${optimize} -fno-exceptions -g" 

        mingw_wildcard="--disable-mingw-wildcard"

        if [ "${TARGET_OS}" == "win" ]
        then
          mingw_wildcard="--enable-mingw-wildcard"

          export AR_FOR_TARGET=${GCC_TARGET}-ar
          export NM_FOR_TARGET=${GCC_TARGET}-nm
          export OBJDUMP_FOR_TARET=${GCC_TARGET}-objdump
          export STRIP_FOR_TARGET=${GCC_TARGET}-strip
          export CC_FOR_TARGET=${GCC_TARGET}-gcc
          export GCC_FOR_TARGET=${GCC_TARGET}-gcc
          export CXX_FOR_TARGET=${GCC_TARGET}-g++
        fi

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

          bash "${WORK_FOLDER_PATH}/${GCC_SRC_FOLDER_NAME}/configure" \
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
            ${mingw_wildcard} \
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

          bash "${WORK_FOLDER_PATH}/${GCC_SRC_FOLDER_NAME}/configure" \
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
        if [ "${TARGET_OS}" != "win" ]
        then

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

        else

          # For Windows build only the GCC binaries, the libraries were copied 
          # from the Linux build.
          make ${JOBS} all-gcc
          make install-gcc

          if [ "${WITH_PDF}" == "y" ]
          then
            make install-pdf-gcc
          fi

          if [ "${WITH_HTML}" == "y" ]
          then
            make install-html-gcc
          fi

        fi

      ) | tee "${INSTALL_FOLDER_PATH}/make-gcc-last-output.txt"
    )

    touch "${gcc_final_stamp_file_path}"
  else
    echo "Step gcc$1 final stage already done."
  fi
}

GDB_SRC_FOLDER_NAME="gdb"

# Called twice, with and without python support.
# $1="" or $1="-py"
function do_gdb()
{
  local gdb_folder_name="gdb-${GDB_VERSION}$1"
  local gdb_stamp_file_path="${BUILD_FOLDER_PATH}/${gdb_folder_name}/stamp-install-completed"

  if [ ! -f "${gdb_stamp_file_path}" ]
  then

    cd "${WORK_FOLDER_PATH}"

    extract "${GCC_COMBO_FOLDER_NAME}"/src/gdb.tar.bz2 "${GDB_SRC_FOLDER_NAME}" "${GDB_VERSION}"

    (
      mkdir -p "${BUILD_FOLDER_PATH}/${gdb_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${gdb_folder_name}"

      xbb_activate

      if [ "${TARGET_OS}" == "win" ]
      then
        # Definition required by python-config.sh.
        export GNURM_PYTHON_WIN_DIR="${WORK_FOLDER_PATH}/${PYTHON_WIN}"
      fi

      if [ ! -f "config.status" ]
      then

        echo
        echo "Running gdb$1 configure..."
      
        bash "${WORK_FOLDER_PATH}/${GDB_SRC_FOLDER_NAME}/configure" --help

        export GCC_WARN_CFLAGS="-Wno-implicit-function-declaration -Wno-parentheses -Wno-format -Wno-incompatible-pointer-types-discards-qualifiers -Wno-extended-offsetof -Wno-deprecated-declarations -Wno-maybe-uninitialized"
        export CFLAGS="${EXTRA_CFLAGS} ${GCC_WARN_CFLAGS}" 
        export GCC_WARN_CXXFLAGS="-Wno-deprecated-declarations" 
        export CXXFLAGS="${EXTRA_CXXFLAGS} ${GCC_WARN_CXXFLAGS}" 
        export CPPFLAGS="${EXTRA_CPPFLAGS}" 
        export LDFLAGS="${EXTRA_LDFLAGS_APP}" 
 
        local extra_python_opts="--with-python=no"
        if [ "$1" == "-py" ]
        then
          if [ "${TARGET_OS}" == "win" ]
          then
            extra_python_opts="--with-python=${WORK_FOLDER_PATH}/${GCC_COMBO_FOLDER_NAME}/python-config.sh"
          else
            extra_python_opts="--with-python=yes"
          fi
        fi

        bash "${WORK_FOLDER_PATH}/${GDB_SRC_FOLDER_NAME}/configure" \
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
  find "${APP_PREFIX}" -name "libiberty.a" -exec rm -v '{}' ';'
  find "${APP_PREFIX}" -name '*.la' -exec rm -v '{}' ';'
}

function do_strip_binaries()
{
  if [ "${WITH_STRIP}" == "y" ]
  then

    if [ "${TARGET_OS}" != "win" ]
    then

      local binaries=$(find "${INSTALL_FOLDER_PATH}"/bin -name ${GCC_TARGET}-\*)
      for bin in ${binaries} 
      do
        strip_binary strip ${bin}
      done

      binaries=$(find ${APP_PREFIX}/bin -maxdepth 1 -mindepth 1 -name \*)
      for bin in ${binaries} 
      do
        strip_binary strip ${bin}
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
        strip_binary strip ${bin}
      done

    else

      local binaries=$(find "${INSTALL_FOLDER_PATH}"/bin -name ${GCC_TARGET}-\*.exe)
      for bin in ${binaries} 
      do
        strip_binary "${CROSS_COMPILE_PREFIX}"-strip ${bin}
      done

      binaries=$(find ${APP_PREFIX}/bin -maxdepth 1 -mindepth 1 -name \*)
      for bin in ${binaries} 
      do
        strip_binary "${CROSS_COMPILE_PREFIX}"-strip ${bin}
      done

      binaries=$(find ${APP_PREFIX}/lib/gcc/${GCC_TARGET}/* -maxdepth 1 -name \*.exe)
      for bin in ${binaries} 
      do
        strip_binary "${CROSS_COMPILE_PREFIX}"-strip ${bin}
      done

    fi

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
  local stamp_file_path="${BUILD_FOLDER_PATH}/stamp-copy-license-completed"
  
  if [ ! -f "${stamp_file_path}" ]
  then

    echo
    echo "Copying license files..."

    copy_license \
      "${WORK_FOLDER_PATH}/${ZLIB_FOLDER_NAME}" "${ZLIB_FOLDER_NAME}"
    copy_license \
      "${WORK_FOLDER_PATH}/${GMP_FOLDER_NAME}" "${GMP_FOLDER_NAME}"
    copy_license \
      "${WORK_FOLDER_PATH}/${MPFR_FOLDER_NAME}" "${MPFR_FOLDER_NAME}"
    copy_license \
      "${WORK_FOLDER_PATH}/${MPC_FOLDER_NAME}" "${MPC_FOLDER_NAME}"
    copy_license \
      "${WORK_FOLDER_PATH}/${ISL_FOLDER_NAME}" "${ISL_FOLDER_NAME}"
    copy_license \
      "${WORK_FOLDER_PATH}/${LIBELF_FOLDER_NAME}" "${LIBELF_FOLDER_NAME}"
    copy_license \
      "${WORK_FOLDER_PATH}/${EXPAT_FOLDER_NAME}" "${EXPAT_FOLDER_NAME}"
    copy_license \
      "${WORK_FOLDER_PATH}/${LIBICONV_FOLDER_NAME}" "${LIBICONV_FOLDER_NAME}"
    copy_license \
      "${WORK_FOLDER_PATH}/${XZ_FOLDER_NAME}" "${XZ_FOLDER_NAME}"

    copy_license \
      "${WORK_FOLDER_PATH}/${BINUTILS_SRC_FOLDER_NAME}" "${BINUTILS_SRC_FOLDER_NAME}-${BINUTILS_VERSION}"
    copy_license \
      "${WORK_FOLDER_PATH}/${GCC_SRC_FOLDER_NAME}" "${GCC_SRC_FOLDER_NAME}-${GCC_VERSION}"
    copy_license \
      "${WORK_FOLDER_PATH}/${NEWLIB_SRC_FOLDER_NAME}" "${NEWLIB_SRC_FOLDER_NAME}-${NEWLIB_VERSION}"
    copy_license \
      "${WORK_FOLDER_PATH}/${GDB_SRC_FOLDER_NAME}" "${GDB_SRC_FOLDER_NAME}-${GDB_VERSION}"

    touch "${stamp_file_path}"

  else
    echo "Step copy-license already done."
  fi
}

function do_check_binaries()
{
  if [ "${WITH_STRIP}" == "y" ]
  then

    if [ "${TARGET_OS}" != "win" ]
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

    else

      local binaries=$(find "${INSTALL_FOLDER_PATH}"/bin -name ${GCC_TARGET}-\*.exe)
      for bin in ${binaries} 
      do
        check_binary ${bin}
      done

      binaries=$(find ${APP_PREFIX}/bin -maxdepth 1 -mindepth 1 -name \*.exe)
      for bin in ${binaries} 
      do
        check_binary ${bin}
      done

      binaries=$(find ${APP_PREFIX}/lib/gcc/${GCC_TARGET}/* -maxdepth 1 -name \*.exe)
      for bin in ${binaries}
      do
        check_binary ${bin}
      done

    fi

  fi
}
