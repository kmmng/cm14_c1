#!/bin/bash
echo Stage 3 - compile LineageOS
SDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
eval BDIR=`cat $SDIR/builddir`
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
echo Building LineageOS 14.1 for SHV-E210$C1VAR, this may take a long time...
cd $BDIR
# Workarounds for WSL
if grep -q Microsoft /proc/version; then
# Patcj ijar to work with WSL, thanks to Reker
patch --no-backup-if-mismatch -t -r - -N build/tools/ijar/zip.cc < $SDIR/wslbuild.diff
# Use system bison just to build correct version of bison, then replace it with newly built one
if [ ! -f out/host/linux-x86/bin/bison ]; then
cp /usr/bin/bison prebuilts/misc/linux-x86/bison/
make bison
fi
cp out/host/linux-x86/bin/bison prebuilts/misc/linux-x86/bison/
mkdir -p prebuilts/misc/linux-x86/lib64/
cp out/host/linux-x86/lib64/libc++.so prebuilts/misc/linux-x86/lib64/
else
# We don't use ccache under WSL as it seems to cause problems
export USE_CCACHE=1
prebuilts/misc/linux-x86/ccache/ccache -M 50G
fi
source build/envsetup.sh
# Compile
export WITH_SU=true
brunch $C1MODEL
