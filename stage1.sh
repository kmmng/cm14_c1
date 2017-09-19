#!/bin/bash
echo Stage 1 - configure OS for build and download Android source
# Install required packages including openjdk
echo Configuring build environment, this may take a VERY long time...
SDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
#if grep -q Microsoft /proc/version; then
#BDIR=/mnt/e/wsl/cm14
#else
BDIR=~/android/cm14
#fi
sudo add-apt-repository -y ppa:openjdk-r/ppa
sudo apt-get update
sudo apt-get install -y bc bison build-essential curl flex git gnupg gperf libesd0-dev liblz4-tool libncurses5-dev libsdl1.2-dev libxml2 libxml2-utils lzop maven pngcrush
sudo apt-get install -y schedtool squashfs-tools xsltproc zip zlib1g-dev g++-multilib gcc-multilib lib32ncurses5-dev lib32readline6-dev lib32z1-dev libwxgtk3.0-dev openjdk-8-jdk
# Install repo
mkdir -p ~/bin
mkdir -p $BDIR
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo
export PATH="$HOME/bin:$PATH"
# Download Android source. This will take a VERY LONG time. If download fails, the script should be run again and the download will be resumed.
cd $BDIR
repo init -u https://github.com/LineageOS/android.git -b cm-14.1
#if grep -q Microsoft /proc/version; then
repo sync --force-sync
#else
#repo sync --force-sync
#fi
