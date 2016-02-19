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
ISUBUNTU=$(lsb_release -is)
if [ "$ISUBUNTU" != "Ubuntu" -o "$UNAME" != "Linux" ] ; then
    echo "Requires Ubuntu"
    exit 1
fi

notify "Updating submodules..."
cd toolchains

if [ -f ../.bootstrapped ] ; then
    git submodule update --recursive --remote
    echo ".boostrapped exists, so we've already built everything. Remove .bootstrapped if you want to rebuild everything"
    exit
else
    git submodule update --init --recursive
    if [ $? != 0 ] ; then
    	echo "There was an error updating git submodules"
    	exit 1
    fi

fi

cd -


notify "Installing packages for TinyOS + nesc..."
if [ `uname -i` -eq "x86_64" ] ; then
  apt-get install -y autoconf emacs automake build-essential gperf bison flex openjdk-7-jdk rlwrap libftdi-dev lib32gcc-4.8-dev gcc-multilib g++-multilib lib32z1 lib32ncurses5 lib32bz2-dev gcc-arm-none-eabi curl python-dev
else
  apt-get install -y autoconf emacs automake build-essential gperf bison flex openjdk-7-jdk rlwrap libftdi-dev libgcc-4.8-dev gcc-multilib g++-multilib libz1 libncurses5 libbz2-dev gcc-arm-none-eabi curl python-dev
fi

if [ $? != 0 ] ; then
	echo "Error running apt-get"
	exit 1
fi
sudo apt-get remove python-pip
curl -O https://bootstrap.pypa.io/get-pip.py
python get-pip.py
rm get-pip.py

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
lua5.1 cross-lua.lua
if [ $? != 0 ] ; then
	echo "Error running cross-lua"
	exit 1
fi
cd -

if [ ! -f /etc/udev/rules.d/99-storm.rules ]; then
    echo 'ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6015", MODE="0666"' > /etc/udev/rules.d/99-storm.rules
fi

sudo chown -R $SUDO_USER .
touch /home/$SUDO_USER/.sload_history
sudo chown $SUDO_USER /home/$SUDO_USER/.sload_history
touch .bootstrapped
