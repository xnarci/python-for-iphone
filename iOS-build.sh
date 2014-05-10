#!/bin/zsh
set -o errexit
set -x

echo "Starting =========="

# credit to:
# http://randomsplat.com/id5-cross-compiling-python-for-embedded-linux.html
# http://latenitesoft.blogspot.com/2008/10/iphone-programming-tips-building-unix.html

export IOS_VERSION="7.1"

# download python and patch if they aren't there
if [[ ! -a Python-2.7.6.tgz ]]; then
    curl https://www.python.org/ftp/python/2.7.6/Python-2.7.6.tgz -o Python-2.7.6.tgz
fi

# get rid of old build
rm -rf Python-2.7.6

open Python-2.7.6.tgz
pushd ./Python-2.7.6

# Patch Python for temporary reduce PY_SSIZE_T_MAX otherzise, splitting string doesnet work
#patch -p1 < ../Python-2.7.1-ssize-t-max.patch

#echo "Building for native machine ============================================"
# Compile some stuff statically; Modules/Setup taken from pgs4a-kivy
#cp ../ModulesSetup Modules/Setup.local
#
#CC=clang ./configure
#./configure CC="ccache clang -Qunused-arguments -fcolor-diagnostics"

#make python.exe Parser/pgen
#make python Parser/pgen
#
#mv python.exe hostpython
#mv python hostpython
#mv Parser/pgen Parser/hostpgen

#make distclean

# patch python to cross-compile
#patch -p1 < ../Python-2.7.1-xcompile.patch

# avoid iphone builddd
echo "Building for iPhone Simulator ==========================================="
export MACOSX_DEPLOYMENT_TARGET=10.6
# set up environment variables for simulator compilation
export DEVROOT="/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/"
export SDKROOT="$DEVROOT/SDKs/iPhoneSimulator7.1.sdk"

if [ ! -d "$DEVROOT" ]; then
    echo "DEVROOT doesn't exist. DEVROOT=$DEVROOT"
    exit 1
fi

if [ ! -d "$SDKROOT" ]; then
    echo "SDKROOT doesn't exist. SDKROOT=$SDKROOT"
    exit 1
fi

export CPPFLAGS="-I$SDKROOT/usr/lib/gcc/i686-apple-darwin10/4.2.1/include/ -I$SDKROOT/usr/include/"
export CFLAGS="$CPPFLAGS -pipe -no-cpp-precomp -isysroot $SDKROOT"
export LDFLAGS="-isysroot $SDKROOT"
export CPP="/usr/bin/cpp $CPPFLAGS"

# Compile some stuff statically; Modules/Setup taken from pgs4a-kivy
cp ../ModulesSetup Modules/Setup.local

./configure CC="$DEVROOT/usr/bin/gcc -m32" \
	    LD="$DEVROOT/usr/bin/ld" --disable-toolbox-glue --host=i386-apple-darwin --prefix=/python

make HOSTPYTHON=./hostpython HOSTPGEN=./Parser/hostpgen \
     CROSS_COMPILE_TARGET=yes

mv libpython2.7.a libpython2.7-i386.a

make distclean

