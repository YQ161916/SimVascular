#!/bin/bash

set -e

MAKE="make --jobs=$NUM_THREADS --keep-going"
MAKE_TEST="xvfb-run -a make test ARGS=-V"

### install latest version of CMake
if [[ "$TRAVIS_OS_NAME" == "linux" ]]
  wget http://simvascular.stanford.edu/downloads/public/open_source/linux/cmake/cmake-3.6.1-Linux-x86_64.sh
  chmod a+rx ./cmake-3.6.1-Linux-x86_64.sh
  sudo mkdir -p /usr/local/package
  sudo ./cmake-3.6.1-Linux-x86_64.sh --prefix=/usr/local/package
  sudo ln -s /usr/local/package/cmake-3.6.1-Linux-x86_64/bin/ccmake    /usr/local/bin/ccmake
  sudo ln -s /usr/local/package/cmake-3.6.1-Linux-x86_64/bin/cmake     /usr/local/bin/cmake
  sudo ln -s /usr/local/package/cmake-3.6.1-Linux-x86_64/bin/cmake-gui /usr/local/bin/cmake-gui
  sudo ln -s /usr/local/package/cmake-3.6.1-Linux-x86_64/bin/cpack     /usr/local/bin/cpack
  sudo ln -s /usr/local/package/cmake-3.6.1-Linux-x86_64/bin/ctest     /usr/local/bin/ctest
  echo "Version of CMake: "
  cmake --version
fi

if $WITH_CMAKE; then
  mkdir -p $BUILD_DIR
  cd $BUILD_DIR
  CMAKE_BUILD_ARGS=""
  if $BUILD_TEST; then
     CMAKE_BUILD_ARGS="$CMAKE_BUILD_ARGS -DBUILD_TESTING:BOOL=1  -DSV_TEST_DIR:PATH=$SV_TEST_DIR/automated_tests -DSV_NO_RENDERER:BOOL=1"
  fi
  echo CMAKE_BUILD_ARGS: $CMAKE_BUILD_ARGS
  source $SCRIPTS/travis_cmake_config.sh
  pushd $BUILD_DIR
  $MAKE
  popd
  if $BUILD_TEST; then
    $MAKE_TEST
  fi
#  $MAKE clean
  cd -

else
    if [[ "$TRAVIS_OS_NAME" == "linux" ]]
    then
      echo "CLUSTER=x64_linux" > BuildWithMake/cluster_overrides.mk
      echo "CXX_COMPILER_VERSION=gcc" >> BuildWithMake/cluster_overrides.mk
      echo "OPEN_SOFTWARE_BINARIES_TOPLEVEL=$SV_EXTERNALS_BUILD_DIR/sv_externals/bin/gnu/4.8/x64" > BuildWithMake/global_overrides.mk
    elif [[ "$TRAVIS_OS_NAME" == "osx" ]]
    then
      echo "CLUSTER=x64_macosx" > BuildWithMake/cluster_overrides.mk
      echo "CXX_COMPILER_VERSION=clang" >> BuildWithMake/cluster_overrides.mk
      echo "OPEN_SOFTWARE_BINARIES_TOPLEVEL=$SV_EXTERNALS_BUILD_DIR/sv_externals/bin/clang/7.3/x64" > BuildWithMake/global_overrides.mk
    fi
    echo "FORTRAN_COMPILER_VERSION=gfortran" >> BuildWithMake/cluster_overrides.mk
    echo "OPEN_SOFTWARE_BUILDS_TOPLEVEL=" >> BuildWithMake/global_overrides.mk
    echo "OPEN_SOFTWARE_SOURCES_TOPLEVEL=" >> BuildWithMake/global_overrides.mk
    echo "LICENSED_SOFTWARE_TOPLEVEL=" >> BuildWithMake/global_overrides.mk

    echo "Building with just make (i.e. NOT cmake!)"
    pushd BuildWithMake
    make --keep-going
    popd
fi

