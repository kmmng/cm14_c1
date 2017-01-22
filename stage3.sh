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
BDIR=~/android/cm14
echo Building LineageOS 14.1 for SHV-E210$C1VAR, this may take a long time...
sleep 5
cd $BDIR
if grep -q Microsoft /proc/version; then
cd build
git checkout -f
# Try to work around unsupported commands on WSL, Unfortunately, it doesn't help too much as the build hangs later anyway.
sed -i 's/mk_timer schedtool -B -n 1 -e ionice -n 1 //g' envsetup.sh
cd ..
fi
source build/envsetup.sh
# Enable ccache
export USE_CCACHE=1
export ANDROID_JACK_VM_ARGS="-Dfile.encoding=UTF-8 -XX:+TieredCompilation -Xmx4G"
prebuilts/misc/linux-x86/ccache/ccache -M 50G
# Compile
brunch $C1MODEL
