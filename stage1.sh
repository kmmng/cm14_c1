#!/bin/bash
echo Stage 1 - configure OS for build and download Android source
# Install required packages including openjdk
echo Configuring build environment, this may take a VERY long time...
sleep 5
SDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BDIR=~/android/cm14
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
## Gello workaround
#sudo keytool -noprompt -alias mavensrve -import -file $SDIR/maven.crt -keystore /usr/lib/jvm/java-8-openjdk-amd64/jre/lib/security/cacerts -storepass changeit
#echo JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64>~/.mavenrc
#echo MAVEN_OPTS=\"-Djavax.net.ssl.trustStore=/usr/lib/jvm/java-8-openjdk-amd64/jre/lib/security/cacerts -Djavax.net.ssl.trustStorePassword=changeit -Djavax.net.ssl.trustStoreType=JKS\">>~/.mavenrc
# TODO remove this command later
rm -f ~/.mavenrc
# Download Android source. This will take a VERY LONG time. If download fails, the script should be run again and the download will be resumed.
cd $BDIR
repo init -u https://github.com/LineageOS/android.git -b cm-14.1
repo sync
