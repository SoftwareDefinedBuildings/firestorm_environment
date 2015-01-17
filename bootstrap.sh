#!/bin/bash

if [ $(whoami) != "root" ]
then
	echo "You need to run this script as root: try sudo ./bootstrap.sh"
	exit 1
fi

export DEBIAN_FRONTEND=noninteractive

function notify() {
	msg=$1
	length=$((${#msg}+4))
	buf=$(printf "%-${length}s" "#")
	echo ${buf// /#}
	echo "# "$msg" #"
	echo ${buf// /#}
	sleep 2
}

# display on stderr
exec 1>&2

UNAME=$(uname)
if [ "$UNAME" != "Linux" ] ; then
    echo "Requires Ubuntu 14.04"
    exit 1
fi

ISUBUNTU=$(lsb_release -is)
UBUNTUVERSION=$(lsb_release -rs)
if [ "$ISUBUNTU" != "Ubuntu" -o "$UBUNTUVERSION" != "14.04" ] ; then
    echo "Requires Ubuntu 14.04"
    exit 1
fi

notify "Updating submodules..."
cd toolchains
git submodule update --init --recursive
if [ $? != 0 ] ; then
	echo "There was an error updating git submodules"
	exit 1
fi
cd -

notify "Installing packages for TinyOS + nesc..."
apt-get install -y autoconf emacs automake gperf bison flex openjdk-7-jdk

notify "Installing nesc..."
cd toolchains/nesc
./Bootstrap
if [ $? != 0 ] ; then
	echo "Error running ./Bootstrap for nesc"
	exit 1
fi
./configure
if [ $? != 0 ] ; then
	echo "Error running ./configure for nesc"
	exit 1
fi
make
./configure
if [ $? != 0 ] ; then
	echo "Error running make for nesc"
	exit 1
fi
make install
if [ $? != 0 ] ; then
	echo "Error running sudo make install for nesc"
	exit 1
fi
cd -


# install TinyOS toolchain
notify "Installing TinyOS toolchain..."
cd toolchains/stormport/tools
./Bootstrap
if [ $? != 0 ] ; then
	echo "Error running ./Bootstrap for TinyOS"
	exit 1
fi
./configure
if [ $? != 0 ] ; then
	echo "Error running ./configure for TinyOS"
	exit 1
fi
make
./configure
if [ $? != 0 ] ; then
	echo "Error running make for TinyOS"
	exit 1
fi
sudo make install
if [ $? != 0 ] ; then
	echo "Error running sudo make install for TinyOS"
	exit 1
fi
cd -

notify "Installing ELua dependencies..."
# install storm_elua
cd toolchains/storm_elua
apt-get install -y lua5.1 luarocks
if [ $? != 0 ] ; then
	echo "Error installing aptitude lua packages"
	exit 1
fi
pip install --upgrade stormloader
if [ $? != 0 ] ; then
	echo "Error installing stormloader from pip"
	exit 1
fi
luarocks install luafilesystem
if [ $? != 0 ] ; then
	echo "Error installing luafilesystem from luarocks"
	exit 1
fi
luarocks install lpack
if [ $? != 0 ] ; then
	echo "Error installing lpack from luarocks"
	exit 1
fi
luarocks install md5
if [ $? != 0 ] ; then
	echo "Error installing md5 from luarocks"
	exit 1
fi
lua cross-lua.lua
if [ $? != 0 ] ; then
	echo "Error running cross-lua"
	exit 1
fi
cd -
