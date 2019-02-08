# -----------------------------------------------------------------------------

# Helper script used in the second edition of the GNU MCU Eclipse build 
# scripts. As the name implies, it should contain only functions and 
# should be included with 'source' by the container build scripts.

# -----------------------------------------------------------------------------


function do_zlib() 
{
  # http://zlib.net
  # http://zlib.net/fossils/
  # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=zlib-static
  # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=zlib-git
  # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=mingw-w64-zlib

  # 2013-04-28
  # ZLIB_VERSION="1.2.8"
  # 2017-01-15
  # ZLIB_VERSION="1.2.11"

  ZLIB_FOLDER_NAME="zlib-${ZLIB_VERSION}"
  local zlib_archive="${ZLIB_FOLDER_NAME}.tar.gz"
  # local zlib_url="http://zlib.net/fossils/${zlib_archive}"
  local zlib_url="https://github.com/gnu-mcu-eclipse/files/raw/master/libs/${zlib_archive}"

  local zlib_stamp_file_path="${INSTALL_FOLDER_PATH}/stamp-zlib-installed"
  if [ ! -f "${zlib_stamp_file_path}" ]
  then

    cd "${WORK_FOLDER_PATH}"

    download_and_extract "${zlib_url}" "${zlib_archive}" "${ZLIB_FOLDER_NAME}"

    (
      if [ ! -d "${BUILD_FOLDER_PATH}/${ZLIB_FOLDER_NAME}" ]
      then
        mkdir -p "${BUILD_FOLDER_PATH}/${ZLIB_FOLDER_NAME}"
        # Copy the sources in the build folder.
        cp -r "${WORK_FOLDER_PATH}/${ZLIB_FOLDER_NAME}"/* "${BUILD_FOLDER_PATH}/${ZLIB_FOLDER_NAME}"
      fi
      cd "${BUILD_FOLDER_PATH}/${ZLIB_FOLDER_NAME}"

      xbb_activate

      export CFLAGS="${EXTRA_CFLAGS} -Wno-shift-negative-value"
      # export LDFLAGS="${EXTRA_LDFLAGS}"

      if [ "${TARGET_OS}" != "win" ]
      then
        (
          echo
          echo "Running zlib configure..."

          bash "./configure" --help

          bash "./configure" \
            --prefix="${INSTALL_FOLDER_PATH}" \
            \
            --static \

          cp "configure.log" "${INSTALL_FOLDER_PATH}"/configure-zlib-log.txt
        ) | tee "${INSTALL_FOLDER_PATH}/configure-zlib-output.txt"
      fi
    
      (
        echo
        echo "Running zlib make..."

        # Build.
        if [ "${TARGET_OS}" != "win" ]
        then
          make ${JOBS}
          make install
        else
          make -f win32/Makefile.gcc \
            PREFIX=${CROSS_COMPILE_PREFIX}- \
            prefix="${INSTALL_FOLDER_PATH}" \
            CFLAGS="${EXTRA_CFLAGS} -Wp,-D_FORTIFY_SOURCE=2 -fexceptions --param=ssp-buffer-size=4"
          make -f win32/Makefile.gcc install \
            DESTDIR="${INSTALL_FOLDER_PATH}/" \
            INCLUDE_PATH="include" \
            LIBRARY_PATH="lib" \
            BINARY_PATH="bin"
        fi
      ) | tee "${INSTALL_FOLDER_PATH}/make-zlib-output.txt"
    )

    touch "${zlib_stamp_file_path}"

  else
    echo "Library zlib already installed."
  fi
}

function do_gmp() 
{
  # https://gmplib.org
  # https://gmplib.org/download/gmp/
  # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=gmp-hg

  # 01-Nov-2015
  # GMP_VERSION="6.1.0"
  # 16-Dec-2016
  # GMP_VERSION="6.1.2"

  GMP_FOLDER_NAME="gmp-${GMP_VERSION}"
  local gmp_archive="${GMP_FOLDER_NAME}.tar.xz"
  # local gmp_url="https://gmplib.org/download/gmp/${gmp_archive}"
  local gmp_url="https://github.com/gnu-mcu-eclipse/files/raw/master/libs/${gmp_archive}"

  local gmp_stamp_file_path="${INSTALL_FOLDER_PATH}/stamp-gmp-installed"
  if [ ! -f "${gmp_stamp_file_path}" ]
  then

    cd "${WORK_FOLDER_PATH}"

    download_and_extract "${gmp_url}" "${gmp_archive}" "${GMP_FOLDER_NAME}"

    (
      mkdir -p "${BUILD_FOLDER_PATH}/${GMP_FOLDER_NAME}"
      cd "${BUILD_FOLDER_PATH}/${GMP_FOLDER_NAME}"

      xbb_activate

      export CFLAGS="-Wno-unused-value -Wno-empty-translation-unit -Wno-tautological-compare -Wno-overflow"
      export CPPFLAGS="${EXTRA_CPPFLAGS}"
      export LDFLAGS="${EXTRA_LDFLAGS}"
      export ABI="${TARGET_BITS}"
        
      if [ ! -f "config.status" ]
      then 
        (
          echo
          echo "Running gmp configure..."

          # ABI is mandatory, otherwise configure fails on 32-bit.
          # (see https://gmplib.org/manual/ABI-and-ISA.html)

          bash "${WORK_FOLDER_PATH}/${GMP_FOLDER_NAME}/configure" --help

          bash "${WORK_FOLDER_PATH}/${GMP_FOLDER_NAME}/configure" \
            --prefix="${INSTALL_FOLDER_PATH}" \
            \
            --build=${BUILD} \
            --host=${HOST} \
            --target=${TARGET} \
            \
            --disable-shared \
            --enable-static \
            --enable-cxx \
            
          cp "config.log" "${INSTALL_FOLDER_PATH}"/config-gmp-log.txt
        ) | tee "${INSTALL_FOLDER_PATH}/configure-gmp-output.txt"
      fi

      (
        echo
        echo "Running gmp make..."

        # Build.
        make ${JOBS}
        make install-strip
      ) | tee "${INSTALL_FOLDER_PATH}/make-gmp-output.txt"
    )

    touch "${gmp_stamp_file_path}"

  else
    echo "Library gmp already installed."
  fi
}

function do_mpfr()
{
  # http://www.mpfr.org
  # http://www.mpfr.org/history.html
  # https://git.archlinux.org/svntogit/packages.git/tree/trunk/PKGBUILD?h=packages/mpfr

  # 6 March 2016
  # MPFR_VERSION="3.1.4"
  # 7 September 2017
  # MPFR_VERSION="3.1.6"

  MPFR_FOLDER_NAME="mpfr-${MPFR_VERSION}"
  local mpfr_archive="${MPFR_FOLDER_NAME}.tar.xz"
  # local mpfr_url="http://www.mpfr.org/${MPFR_FOLDER_NAME}/${mpfr_archive}"
  local mpfr_url="https://github.com/gnu-mcu-eclipse/files/raw/master/libs/${mpfr_archive}"

  local mpfr_stamp_file_path="${INSTALL_FOLDER_PATH}/stamp-mpfr-installed"
  if [ ! -f "${mpfr_stamp_file_path}" ]
  then

    cd "${WORK_FOLDER_PATH}"

    download_and_extract "${mpfr_url}" "${mpfr_archive}" "${MPFR_FOLDER_NAME}"

    (
      mkdir -p "${BUILD_FOLDER_PATH}/${MPFR_FOLDER_NAME}"
      cd "${BUILD_FOLDER_PATH}/${MPFR_FOLDER_NAME}"

      xbb_activate

      export CFLAGS="${EXTRA_CFLAGS}"
      export CPPFLAGS="${EXTRA_CPPFLAGS}"
      export LDFLAGS="${EXTRA_LDFLAGS_LIB}"

      if [ ! -f "config.status" ]
      then 
        (
          echo
          echo "Running mpfr configure..."

          bash "${WORK_FOLDER_PATH}/${MPFR_FOLDER_NAME}/configure" --help

          bash "${WORK_FOLDER_PATH}/${MPFR_FOLDER_NAME}/configure" \
            --prefix="${INSTALL_FOLDER_PATH}" \
            \
            --build=${BUILD} \
            --host=${HOST} \
            --target=${TARGET} \
            \
            --disable-warnings \
            --disable-shared \
            --enable-static \
            
          cp "config.log" "${INSTALL_FOLDER_PATH}"/config-mpfr-log.txt
        ) | tee "${INSTALL_FOLDER_PATH}/configure-mpfr-output.txt"
      fi

      (
        echo
        echo "Running mpfr make..."

        # Build.
        make ${JOBS}
        make install-strip
      ) | tee "${INSTALL_FOLDER_PATH}/make-mpfr-output.txt"
    )
    touch "${mpfr_stamp_file_path}"

  else
    echo "Library mpfr already installed."
  fi
}

function do_mpc()
{
  # http://www.multiprecision.org/
  # ftp://ftp.gnu.org/gnu/mpc
  # https://git.archlinux.org/svntogit/packages.git/tree/trunk/PKGBUILD?h=packages/libmpc

  # 20 Feb 2015
  # MPC_VERSION="1.0.3"

  MPC_FOLDER_NAME="mpc-${MPC_VERSION}"
  local mpc_archive="${MPC_FOLDER_NAME}.tar.gz"

  local mpc_url="ftp://ftp.gnu.org/gnu/mpc/${mpc_archive}"
  if [[ "${MPC_VERSION}" =~ 0\.* ]]
  then
    mpc_url="http://www.multiprecision.org/downloads/${mpc_archive}"
  fi

  local mpc_stamp_file_path="${INSTALL_FOLDER_PATH}/stamp-mpc-installed"
  if [ ! -f "${mpc_stamp_file_path}" ]
  then

    cd "${WORK_FOLDER_PATH}"

    download_and_extract "${mpc_url}" "${mpc_archive}" "${MPC_FOLDER_NAME}"

    (
      mkdir -p "${BUILD_FOLDER_PATH}/${MPC_FOLDER_NAME}"
      cd "${BUILD_FOLDER_PATH}/${MPC_FOLDER_NAME}"

      xbb_activate

      export CFLAGS="${EXTRA_CFLAGS} -Wno-unused-value -Wno-empty-translation-unit -Wno-tautological-compare"
      export CPPFLAGS="${EXTRA_CPPFLAGS}"
      export LDFLAGS="${EXTRA_LDFLAGS_LIB}"

      if [ ! -f "config.status" ]
      then 
        (
          echo
          echo "Running mpc configure..."
        
          bash "${WORK_FOLDER_PATH}/${MPC_FOLDER_NAME}/configure" --help

          bash "${WORK_FOLDER_PATH}/${MPC_FOLDER_NAME}/configure" \
            --prefix="${INSTALL_FOLDER_PATH}" \
            \
            --build=${BUILD} \
            --host=${HOST} \
            --target=${TARGET} \
            \
            --disable-shared \
            --enable-static \
            
          cp "config.log" "${INSTALL_FOLDER_PATH}"/config-mpc-log.txt
        ) | tee "${INSTALL_FOLDER_PATH}/configure-mpc-output.txt"
      fi

      (
        echo
        echo "Running mpc make..."

        # Build.
        make ${JOBS}
        make install-strip
      ) | tee "${INSTALL_FOLDER_PATH}/make-mpc-output.txt"
    )
    touch "${mpc_stamp_file_path}"

  else
    echo "Library mpc already installed."
  fi
}

function do_isl()
{
  # http://isl.gforge.inria.fr
  # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=isl

  # 2015-06-12
  # ISL_VERSION="0.15"
  # 2016-01-15
  # ISL_VERSION="0.16.1"
  # 2016-12-20
  # ISL_VERSION="0.18"

  ISL_FOLDER_NAME="isl-${ISL_VERSION}"
  local isl_archive="${ISL_FOLDER_NAME}.tar.xz"
  if [[ "${ISL_VERSION}" =~ 0\.12\.* ]]
  then
    isl_archive="${ISL_FOLDER_NAME}.tar.gz"
  fi

  # local isl_url="http://isl.gforge.inria.fr/${isl_archive}"
  local isl_url="https://github.com/gnu-mcu-eclipse/files/raw/master/libs/${isl_archive}"

  local isl_stamp_file_path="${INSTALL_FOLDER_PATH}/stamp-isl-installed"
  if [ ! -f "${isl_stamp_file_path}" ]
  then

    cd "${WORK_FOLDER_PATH}"

    download_and_extract "${isl_url}" "${isl_archive}" "${ISL_FOLDER_NAME}"

    (
      mkdir -p "${BUILD_FOLDER_PATH}/${ISL_FOLDER_NAME}"
      cd "${BUILD_FOLDER_PATH}/${ISL_FOLDER_NAME}"

      xbb_activate

      export CFLAGS="${EXTRA_CFLAGS} -Wno-dangling-else -Wno-header-guard"
      export CPPFLAGS="${EXTRA_CPPFLAGS}"
      export LDFLAGS="${EXTRA_LDFLAGS_LIB}"

      if [ ! -f "config.status" ]
      then 
        (
          echo
          echo "Running isl configure..."

          bash "${WORK_FOLDER_PATH}/${ISL_FOLDER_NAME}/configure" --help

          bash "${WORK_FOLDER_PATH}/${ISL_FOLDER_NAME}/configure" \
            --prefix="${INSTALL_FOLDER_PATH}" \
            \
            --build=${BUILD} \
            --host=${HOST} \
            --target=${TARGET} \
            \
            --disable-shared \
            --enable-static \
            
          cp "config.log" "${INSTALL_FOLDER_PATH}"/config-isl-log.txt
        ) | tee "${INSTALL_FOLDER_PATH}/configure-isl-output.txt"
      fi

      (
        echo
        echo "Running isl make..."

        # Build.
        make ${JOBS}
        make install-strip
      ) | tee "${INSTALL_FOLDER_PATH}/make-isl-output.txt"

    )
    touch "${isl_stamp_file_path}"

  else
    echo "Library isl already installed."
  fi
}

function do_libelf()
{
  # http://www.mr511.de/
  # http://www.mr511.de/software/

  # LIBELF_VERSION="0.8.13"

  LIBELF_FOLDER_NAME="libelf-${LIBELF_VERSION}"
  local libelf_archive="${LIBELF_FOLDER_NAME}.tar.gz"
  # local libelf_url="http://www.mr511.de/software/${libelf_archive}"
  local libelf_url="https://github.com/gnu-mcu-eclipse/files/raw/master/libs/${libelf_archive}"

  local libelf_stamp_file_path="${INSTALL_FOLDER_PATH}/stamp-libelf-installed"
  if [ ! -f "${libelf_stamp_file_path}" ]
  then

    cd "${WORK_FOLDER_PATH}"

    download_and_extract "${libelf_url}" "${libelf_archive}" "${LIBELF_FOLDER_NAME}"

    (
      mkdir -p "${BUILD_FOLDER_PATH}/${LIBELF_FOLDER_NAME}"
      cd "${BUILD_FOLDER_PATH}/${LIBELF_FOLDER_NAME}"

      xbb_activate

      export CFLAGS="${EXTRA_CFLAGS} -Wno-tautological-compare"
      export CPPFLAGS="${EXTRA_CPPFLAGS}"
      export LDFLAGS="${EXTRA_LDFLAGS}"

      if [ ! -f "config.status" ]
      then 
        (
          echo
          echo "Running libelf configure..."

          bash "${WORK_FOLDER_PATH}/${LIBELF_FOLDER_NAME}/configure" --help

          bash "${WORK_FOLDER_PATH}/${LIBELF_FOLDER_NAME}/configure" \
            --prefix="${INSTALL_FOLDER_PATH}" \
            \
            --build=${BUILD} \
            --host=${HOST} \
            --target=${TARGET} \
            \
            --disable-shared \
            --enable-static \
            --disable-nls \

          cp "config.log" "${INSTALL_FOLDER_PATH}"/config-libelf-log.txt
        ) | tee "${INSTALL_FOLDER_PATH}/configure-libelf-output.txt"
      fi

      (
        echo
        echo "Running libelf make..."

        # Build.
        make ${JOBS}
        make install
      ) | tee "${INSTALL_FOLDER_PATH}/make-libelf-output.txt"

    )

    touch "${libelf_stamp_file_path}"

  else
    echo "Library libelf already installed."
  fi
}

function do_expat()
{
  # https://libexpat.github.io
  # https://github.com/libexpat/libexpat/releases
  # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=expat-git

  # Oct 21, 2017
  # EXPAT_VERSION="2.1.1"
  # Nov 1, 2017
  # EXPAT_VERSION="2.2.5"

  EXPAT_FOLDER_NAME="expat-${EXPAT_VERSION}"
  local expat_archive="${EXPAT_FOLDER_NAME}.tar.bz2"
  if [[ "${EXPAT_VERSION}" =~ 2\.0\.* ]]
  then
    expat_archive="${EXPAT_FOLDER_NAME}.tar.gz"
  fi
  
  local expat_release="R_$(echo ${EXPAT_VERSION} | sed -e 's|[.]|_|g')"
  local expat_url="https://github.com/libexpat/libexpat/releases/download/${expat_release}/${expat_archive}"

  local expat_stamp_file_path="${INSTALL_FOLDER_PATH}/stamp-expat-installed"
  if [ ! -f "${expat_stamp_file_path}" ]
  then

    cd "${WORK_FOLDER_PATH}"

    download_and_extract "${expat_url}" "${expat_archive}" "${EXPAT_FOLDER_NAME}"

    (
      mkdir -p "${BUILD_FOLDER_PATH}/${EXPAT_FOLDER_NAME}"
      cd "${BUILD_FOLDER_PATH}/${EXPAT_FOLDER_NAME}"

      xbb_activate

      export CFLAGS="${EXTRA_CFLAGS}"
      export CPPFLAGS="${EXTRA_CPPFLAGS}"
      export LDFLAGS="${EXTRA_LDFLAGS}"

      if [ ! -f "config.status" ]
      then 
        (
          echo
          echo "Running expat configure..."

          bash "${WORK_FOLDER_PATH}/${EXPAT_FOLDER_NAME}/configure" --help

          bash "${WORK_FOLDER_PATH}/${EXPAT_FOLDER_NAME}/configure" \
            --prefix="${INSTALL_FOLDER_PATH}" \
            \
            --build=${BUILD} \
            --host=${HOST} \
            --target=${TARGET} \
            \
            --disable-shared \
            --enable-static \
            
          cp "config.log" "${INSTALL_FOLDER_PATH}"/config-expat-log.txt
        ) | tee "${INSTALL_FOLDER_PATH}/configure-expat-output.txt"
      fi

      (
        echo
        echo "Running expat make..."

        # Build.
        make ${JOBS}
        make install
      ) | tee "${INSTALL_FOLDER_PATH}/make-expat-output.txt"
    )

    touch "${expat_stamp_file_path}"

  else
    echo "Library expat already installed."
  fi
}

function do_libiconv()
{
  # https://www.gnu.org/software/libiconv/
  # https://ftp.gnu.org/pub/gnu/libiconv/
  # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=libiconv

  # 2011-08-07
  # LIBICONV_VERSION="1.14"
  # 2017-02-02
  # LIBICONV_VERSION="1.15"

  LIBICONV_FOLDER_NAME="libiconv-${LIBICONV_VERSION}"
  local libiconv_archive="${LIBICONV_FOLDER_NAME}.tar.gz"
  local libiconv_url="https://ftp.gnu.org/pub/gnu/libiconv/${libiconv_archive}"

  local libiconv_stamp_file_path="${INSTALL_FOLDER_PATH}/stamp-libiconv-installed"
  if [ ! -f "${libiconv_stamp_file_path}" ]
  then

    cd "${WORK_FOLDER_PATH}"

    download_and_extract "${libiconv_url}" "${libiconv_archive}" "${LIBICONV_FOLDER_NAME}"

    (
      mkdir -p "${BUILD_FOLDER_PATH}/${LIBICONV_FOLDER_NAME}"
      cd "${BUILD_FOLDER_PATH}/${LIBICONV_FOLDER_NAME}"

      xbb_activate

      # -fgnu89-inline fixes "undefined reference to `aliases2_lookup'"
      #  https://savannah.gnu.org/bugs/?47953
      export CFLAGS="${EXTRA_CFLAGS} -fgnu89-inline -Wno-tautological-compare -Wno-parentheses-equality -Wno-static-in-inline -Wno-pointer-to-int-cast"
      export CPPFLAGS="${EXTRA_CPPFLAGS}"
      export LDFLAGS="${EXTRA_LDFLAGS}"

      if [ ! -f "config.status" ]
      then 
        (
          echo
          echo "Running libiconv configure..."

          bash "${WORK_FOLDER_PATH}/${LIBICONV_FOLDER_NAME}/configure" --help

          bash "${WORK_FOLDER_PATH}/${LIBICONV_FOLDER_NAME}/configure" \
            --prefix="${INSTALL_FOLDER_PATH}" \
            \
            --build=${BUILD} \
            --host=${HOST} \
            --target=${TARGET} \
            \
            --disable-shared \
            --enable-static \
            --disable-nls \

          cp "config.log" "${INSTALL_FOLDER_PATH}"/config-libiconv-log.txt
        ) | tee "${INSTALL_FOLDER_PATH}/configure-libiconv-output.txt"
      fi

      (
        echo
        echo "Running libiconv make..."

        # Build.
        make ${JOBS}
        make install-strip
      ) | tee "${INSTALL_FOLDER_PATH}/make-libiconv-output.txt"
    )

    touch "${libiconv_stamp_file_path}"

  else
    echo "Library libiconv already installed."
  fi
}

function do_xz()
{
  # https://tukaani.org/xz/
  # https://sourceforge.net/projects/lzmautils/files/
  # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=xz-git

  # 2016-12-30
  # XZ_VERSION="5.2.3"

  XZ_FOLDER_NAME="xz-${XZ_VERSION}"
  local xz_archive="${XZ_FOLDER_NAME}.tar.xz"
  # local xz_url="https://sourceforge.net/projects/lzmautils/files/${xz_archive}"
  local xz_url="https://github.com/gnu-mcu-eclipse/files/raw/master/libs/${xz_archive}"

  local xz_stamp_file_path="${INSTALL_FOLDER_PATH}/stamp-xz-installed"
  if [ ! -f "${xz_stamp_file_path}" ]
  then

    cd "${WORK_FOLDER_PATH}"

    download_and_extract "${xz_url}" "${xz_archive}" "${XZ_FOLDER_NAME}"

    (
      mkdir -p "${BUILD_FOLDER_PATH}/${XZ_FOLDER_NAME}"
      cd "${BUILD_FOLDER_PATH}/${XZ_FOLDER_NAME}"

      xbb_activate

      export CFLAGS="${EXTRA_CFLAGS} -Wno-implicit-fallthrough"
      export CPPFLAGS="${EXTRA_CPPFLAGS}"
      export LDFLAGS="${EXTRA_LDFLAGS}"

      if [ ! -f "config.status" ]
      then 
        (
          echo
          echo "Running xz configure..."

          bash "${WORK_FOLDER_PATH}/${XZ_FOLDER_NAME}/configure" --help

          bash "${WORK_FOLDER_PATH}/${XZ_FOLDER_NAME}/configure" \
            --prefix="${INSTALL_FOLDER_PATH}" \
            \
            --build=${BUILD} \
            --host=${HOST} \
            --target=${TARGET} \
            \
            --disable-shared \
            --enable-static \
            --disable-rpath \
            --disable-nls \

          cp "config.log" "${INSTALL_FOLDER_PATH}"/config-xz-log.txt
        ) | tee "${INSTALL_FOLDER_PATH}/configure-xz-output.txt"

      fi

      (
        echo
        echo "Running xz make..."

        # Build.
        make ${JOBS}
        make install-strip
      ) | tee "${INSTALL_FOLDER_PATH}/make-xz-output.txt"
    )

    touch "${xz_stamp_file_path}"

  else
    echo "Library xz already installed."
  fi
}
