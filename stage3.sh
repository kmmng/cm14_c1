#!/bin/bash
echo Stage 3 - compile LineageOS
if [ ! "$C1MODEL" ]; then
C1MODEL=c1lgt
fi
if [ "$C1MODEL" = "c1lgt" ]; then
C1VAR=L
elif [ "$C1MODEL" = "c1skt" ]; then
C1VAR=S
elif [ "$C1MODEL" = "c1ktt" ]; then
C1VAR=K
else
echo Unknown device model, C1MODEL should be c1lgt/c1skt/c1ktt
exit
fi
#if grep -q Microsoft /proc/version; then
#BDIR=/mnt/e/wsl/cm14
#else
BDIR=~/android/cm14
#fi
echo Building LineageOS 14.1 for SHV-E210$C1VAR, this may take a long time...
cd $BDIR
if grep -q Microsoft /proc/version; then
cd build
git checkout -f
# Workarounds for unsupported commands on WSL
sed -i 's/mk_timer schedtool -B -n 1 -e ionice -n 1 //g' envsetup.sh
cd ..
cp /usr/bin/bison prebuilts/misc/linux-x86/bison/
cp /usr/bin/python2.7 prebuilts/python/linux-x86/2.7.5/bin/
cd external/v8
git checkout -f
sed -i 's/ENABLE_V8_SNAPSHOT = true/ENABLE_V8_SNAPSHOT = false/' Android.mk
cd ../..
else
export USE_CCACHE=1
prebuilts/misc/linux-x86/ccache/ccache -M 50G
fi
source build/envsetup.sh
# Compile
brunch $C1MODEL
