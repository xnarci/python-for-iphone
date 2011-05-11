#!/bin/zsh
set -o errexit

echo "Starting =========="

# credit to:
# http://randomsplat.com/id5-cross-compiling-python-for-embedded-linux.html
# http://latenitesoft.blogspot.com/2008/10/iphone-programming-tips-building-unix.html

export IOS_VERSION="4.3"

# download python and patch if they aren't there
if [[ ! -a Python-2.6.5.tar.bz2 ]]; then
    curl http://www.python.org/ftp/python/2.6.5/Python-2.6.5.tar.bz2 > Python-2.6.5.tar.bz2
fi

# get rid of old build
rm -rf Python-2.6.5

tar -xjf Python-2.6.5.tar.bz2
pushd ./Python-2.6.5

# Patch Python for OSX because there is no _environ symbol on OSX
patch -p0 < ../environ_symbol_fix.patch

echo "Building for native machine ============================================"
# Compile some stuff statically; Modules/Setup taken from pgs4a-kivy
cp ../ModulesSetup Modules/Setup.local

CC=clang ./configure

#make python.exe Parser/pgen
make python Parser/pgen

#mv python.exe hostpython
mv python hostpython
mv Parser/pgen Parser/hostpgen

make distclean

# patch python to cross-compile
patch -p1 < ../Python-2.6.5-xcompile.patch

echo "Building for iPhone Simulator ==========================================="
export MACOSX_DEPLOYMENT_TARGET=10.6
# set up environment variables for simulator compilation
export DEVROOT="/Developer/Platforms/iPhoneSimulator.platform/Developer"
export SDKROOT="$DEVROOT/SDKs/iPhoneSimulator${IOS_VERSION}.sdk"

if [ ! -d "$DEVROOT" ]; then
    echo "DEVROOT doesn't exist. DEVROOT=$DEVROOT"
    exit 1
fi

if [ ! -d "$SDKROOT" ]; then
    echo "SDKROOT doesn't exist. SDKROOT=$SDKROOT"
    exit 1
fi

export CPPFLAGS="-I$SDKROOT/usr/lib/gcc/arm-apple-darwin10/4.2.1/include/ -I$SDKROOT/usr/include/"
export CFLAGS="$CPPFLAGS -pipe -no-cpp-precomp -isysroot $SDKROOT"
export LDFLAGS="-isysroot $SDKROOT"
export CPP="/usr/bin/cpp $CPPFLAGS"

# Compile some stuff statically; Modules/Setup taken from pgs4a-kivy
cp ../ModulesSetup Modules/Setup.local

./configure CC="$DEVROOT/usr/bin/i686-apple-darwin10-llvm-gcc-4.2 -m32" \
            LD="$DEVROOT/usr/bin/ld" --disable-toolbox-glue --host=i386-apple-darwin --prefix=/python

make HOSTPYTHON=./hostpython HOSTPGEN=./Parser/hostpgen \
     CROSS_COMPILE_TARGET=yes

mv libpython2.6.a libpython2.6-i386.a

make distclean

export MACOSX_DEPLOYMENT_TARGET=

echo "Building for iOS ======================================================="
# set up environment variables for cross compilation
export DEVROOT="/Developer/Platforms/iPhoneOS.platform/Developer"
export SDKROOT="$DEVROOT/SDKs/iPhoneOS${IOS_VERSION}.sdk"

if [ ! -d "$DEVROOT" ]; then
    echo "DEVROOT doesn't exist. DEVROOT=$DEVROOT"
    exit 1
fi

if [ ! -d "$SDKROOT" ]; then
    echo "SDKROOT doesn't exist. SDKROOT=$SDKROOT"
    exit 1
fi

export CPPFLAGS="-I$SDKROOT/usr/lib/gcc/arm-apple-darwin10/4.2.1/include/ -I$SDKROOT/usr/include/"
export CFLAGS="$CPPFLAGS -pipe -no-cpp-precomp -isysroot $SDKROOT"
export LDFLAGS="-isysroot $SDKROOT -Lextralibs/"
export CPP="/usr/bin/cpp $CPPFLAGS"

# make a link to a differently named library for who knows what reason
mkdir extralibs
ln -s "$SDKROOT/usr/lib/libgcc_s.1.dylib" extralibs/libgcc_s.10.4.dylib

# Compile some stuff statically; Modules/Setup taken from pgs4a-kivy
cp ../ModulesSetup Modules/Setup.local

./configure CC="$DEVROOT/usr/bin/arm-apple-darwin10-llvm-gcc-4.2" \
            LD="$DEVROOT/usr/bin/ld" --disable-toolbox-glue --host=armv6-apple-darwin --prefix=/python

make HOSTPYTHON=./hostpython HOSTPGEN=./Parser/hostpgen \
     CROSS_COMPILE_TARGET=yes

make install HOSTPYTHON=./hostpython CROSS_COMPILE_TARGET=yes prefix="$PWD/_install"

pushd _install/lib
mv libpython2.6.a libpython2.6-arm.a
lipo -create -output libpython2.6.a ../../libpython2.6-i386.a libpython2.6-arm.a
