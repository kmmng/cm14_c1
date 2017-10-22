#!/bin/bash
echo Stage 1 - configure OS for build and download Android source
# Install required packages including openjdk
echo Configuring build environment, this may take a long time at first run
SDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
eval BDIR=`cat $SDIR/builddir`
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
echo Downloading Android sources, this will take a long time
cd $BDIR
repo init -u https://github.com/LineageOS/android.git -b cm-14.1
repo sync --force-sync
echo If there are fetch errors, please run the script again and it will continue downloading.
echo Sometimes multiple retries are needed, especially under WSL.
