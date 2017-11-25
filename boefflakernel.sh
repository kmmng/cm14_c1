#!/bin/bash
echo Build Boeffla kernel
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
echo Building Boeffla Kernel for SHV-E210$C1VAR...
mkdir -p $BDIR/boeffla_kernel
cd $BDIR/boeffla_kernel
# Download Boeffla kernel source
git clone https://github.com/andip71/boeffla-kernel-cm-s3 -b boeffla_cm14
cd boeffla-kernel-cm-s3
# This is needed
git pull
git checkout -f boeffla_cm14
export CROSS_COMPILE=${BDIR}/prebuilts/gcc/linux-x86/arm/arm-eabi-4.8/bin/arm-eabi-
export PATH=${BDIR}/prebuilts/gcc/linux-x86/arm/arm-eabi-4.8/bin:${PATH}
export ARCH=arm
rm -rf ../build ../repack ../compile.log
rm -rf drivers/misc/modem_if_c1
rm -rf include/linux/platform_data/modem_c1.h
# Patch source to support c1
patch --no-backup-if-mismatch -t -r - -p1 < $SDIR/c1kernel-cm.diff
# Update camera driver
cp $SDIR/camera/s5c73m3.c drivers/media/video/
cp $SDIR/camera/s5c73m3.h drivers/media/video/
cp $SDIR/camera/s5c73m3_spi.c drivers/media/video/
cp $SDIR/camera/s5c73m3_platform.h include/media/
cp $SDIR/camera/midas-camera.c arch/arm/mach-exynos/
# Patch kernel config
pushd arch/arm/configs
KCFG=boeffla_defconfig
sed -i '/CONFIG_TARGET_LOCALE_EUR=y/d' $KCFG
sed -i '/# CONFIG_TARGET_LOCALE_KOR is not set/d' $KCFG
echo CONFIG_TARGET_LOCALE_KOR=y>>$KCFG
sed -i '/CONFIG_MACH_M0=y/d' $KCFG
sed -i '/# CONFIG_MACH_C1 is not set/d' $KCFG
echo CONFIG_MACH_C1=y>>$KCFG
sed -i '/CONFIG_WLAN_REGION_CODE=100/d' $KCFG
sed -i '/CONFIG_SEC_MODEM_M0=y/d' $KCFG
sed -i '/# CONFIG_LTE_MODEM_CMC221 is not set/d' $KCFG
echo CONFIG_LTE_MODEM_CMC221=y>>$KCFG
sed -i '/# CONFIG_LINK_DEVICE_DPRAM is not set/d' $KCFG
echo CONFIG_LINK_DEVICE_DPRAM=y>>$KCFG
sed -i '/# CONFIG_LINK_DEVICE_USB is not set/d' $KCFG
echo CONFIG_LINK_DEVICE_USB=y>>$KCFG
sed -i '/# CONFIG_USBHUB_USB3503 is not set/d' $KCFG
echo CONFIG_USBHUB_USB3503=y>>$KCFG
sed -i '/CONFIG_UMTS_MODEM_XMM6262=y/d' $KCFG
sed -i '/CONFIG_LINK_DEVICE_HSIC=y/d' $KCFG
sed -i '/# CONFIG_SIPC_VER_5 is not set/d' $KCFG
echo CONFIG_SIPC_VER_5=y>>$KCFG
sed -i '/CONFIG_SND_DEBUG=y/d' $KCFG
sed -i '/CONFIG_FM_RADIO=y/d' $KCFG
sed -i '/CONFIG_FM_SI4705=y/d' $KCFG
sed -i '/# CONFIG_TDMB is not set/d' $KCFG
echo CONFIG_TDMB=y>>$KCFG
echo CONFIG_TDMB_VENDOR_RAONTECH=y>>$KCFG
echo CONFIG_TDMB_MTV318=y>>$KCFG
echo CONFIG_TDMB_SPI=y>>$KCFG
# We need this one only if we want to reuse the kernel in TWRP
sed -i '/# CONFIG_RD_LZMA is not set/d' $KCFG
echo CONFIG_RD_LZMA=y>>$KCFG
# Fix video playback error, thanks to FullGreen
sed -i '/CONFIG_DMA_CMA=y/d' $KCFG
sed -i '/CONFIG_CMA_SIZE_MBYTES/d' $KCFG
sed -i '/CONFIG_CMA_SIZE_SEL_MBYTES/d' $KCFG
sed -i '/CONFIG_CMA_ALIGNMENT/d' $KCFG
sed -i '/CONFIG_CMA_AREAS/d' $KCFG
sed -i '/CONFIG_USE_FIMC_CMA=y/d' $KCFG
sed -i '/CONFIG_USE_MFC_CMA=y/d' $KCFG
# Model-specific kernel config
if [ "$C1MODEL" = "c1lgt" ]; then
echo CONFIG_MACH_C1_KOR_LGT=y>>$KCFG
echo CONFIG_C1_LGT_EXPERIMENTAL=y>>$KCFG
sed -i '/# CONFIG_FM34_WE395 is not set/d' $KCFG
echo CONFIG_FM34_WE395=y>>$KCFG
echo CONFIG_WLAN_REGION_CODE=203>>$KCFG
sed -i '/# CONFIG_SEC_MODEM_C1_LGT is not set/d' $KCFG
echo CONFIG_SEC_MODEM_C1_LGT=y>>$KCFG
sed -i '/# CONFIG_CDMA_MODEM_CBP72 is not set/d' $KCFG
echo CONFIG_CDMA_MODEM_CBP72=y>>$KCFG
sed -i '/# CONFIG_LTE_VIA_SWITCH is not set/d' $KCFG
echo CONFIG_LTE_VIA_SWITCH=y>>$KCFG
echo CONFIG_CMC_MODEM_HSIC_SYSREV=11>>$KCFG
elif [ "$C1MODEL" = "c1skt" ]; then
echo CONFIG_MACH_C1_KOR_SKT=y>>$KCFG
echo CONFIG_WLAN_REGION_CODE=201>>$KCFG
sed -i '/# CONFIG_SEC_MODEM_C1 is not set/d' $KCFG
echo CONFIG_SEC_MODEM_C1=y>>$KCFG
echo CONFIG_CMC_MODEM_HSIC_SYSREV=9>>$KCFG
elif [ "$C1MODEL" = "c1ktt" ]; then
echo CONFIG_MACH_C1_KOR_SKT=y>>$KCFG
echo CONFIG_WLAN_REGION_CODE=202>>$KCFG
sed -i '/# CONFIG_SEC_MODEM_C1 is not set/d' $KCFG
echo CONFIG_SEC_MODEM_C1=y>>$KCFG
echo CONFIG_CMC_MODEM_HSIC_SYSREV=9>>$KCFG
fi
popd
pushd anykernel_boeffla
find -path "*.sh" -exec sed -i "s/i9300/${C1MODEL}/g" {} \;
find -path "*.sh" -exec sed -i "s/GT-I9300/SHV-E210${C1VAR}/g" {} \;
if [ "$C1MODEL" = "c1lgt" ]; then
find -path "*.sh" -exec sed -i -e 's/mmcblk0p12/mmcblk0p13/g' -e 's/mmcblk0p11/mmcblk0p12/g' -e 's/mmcblk0p10/mmcblk0p11/g' -e 's/mmcblk0p9/mmcblk0p10/g' -e 's/mmcblk0p8/mmcblk0p9/g' {} \;
fi
cd ramdisk/res/misc
zip -q -d boeffla-config-reset-v4.zip META-INF/CERT.RSA META-INF/CERT.SF META-INF/MANIFEST.MF
unzip -q boeffla-config-reset-v4.zip META-INF/com/google/android/updater-script
sed -i "s/i9300\/n8000\/n801x/      ${C1MODEL}      /" META-INF/com/google/android/updater-script
if [ "$C1MODEL" = "c1lgt" ]; then
sed -i -e 's/mmcblk0p12/mmcblk0p13/g' -e 's/mmcblk0p11/mmcblk0p12/g' -e 's/mmcblk0p10/mmcblk0p11/g' -e 's/mmcblk0p9/mmcblk0p10/g' -e 's/mmcblk0p8/mmcblk0p9/g' META-INF/com/google/android/updater-script
fi
zip -q -m -9 boeffla-config-reset-v4.zip META-INF/com/google/android/updater-script
rm -rf META-INF
popd
BK_VER=`tail -n 1 versions.txt`
BK_VER=`echo $BK_VER ^| sed s/:.*//`
sed -i "s/BOEFFLA_VERSION=\".*/BOEFFLA_VERSION=\"${BK_VER}-CM14.1-$C1MODEL\"/" bbuild-anykernel.sh
sed -i "s#TOOLCHAIN=\".*#TOOLCHAIN=\"${CROSS_COMPILE}\"#" bbuild-anykernel.sh
bash ./bbuild-anykernel.sh rel
