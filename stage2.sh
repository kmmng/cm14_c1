#!/bin/bash
echo Stage 2 - prepare source for build and patch it for c1
SDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BDIR=~/android/cm14
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
echo Configuring source for SHV-E210$C1VAR...
echo Errors may appear in the first part of the configuration, please ignore them.
sleep 5
export PATH="$HOME/bin:$PATH"
cd $BDIR
source build/envsetup.sh
rm -rf vendor/samsung/i9300
rm -rf vendor/samsung/$C1MODEL
rm -rf vendor/samsung/smdk4412-common
# Init i9300 source. This will produce some errors but this is normal and we should continue.
breakfast i9300
# Start converting i9300 sources to c1
cd device/samsung
rm -rf $C1MODEL
mv i9300 $C1MODEL
cd $C1MODEL
git checkout -f
# Patch device specific sources and config files
sed -i "s/GT-I9300/SHV-E210$C1VAR/" bluetooth/bdroid_buildcfg.h
if [ "$C1MODEL" = "c1lgt" ]; then
sed -i "/<device name=\"speaker\">/ { N; /    <path name=\"on\">/ s/    <path name=\"on\">/    <path name=\"on\">\n        <ctl name=\"FM Control\" val=\"4\"\/>/}" configs/tiny_hw.xml
sed -i "/    <path name=\"off\">/ { N; /        <ctl name=\"SPK Switch\" val=\"0\"\/>/ s/    <path name=\"off\">/    <path name=\"off\">\n        <ctl name=\"FM Control\" val=\"4\"\/>/}" configs/tiny_hw.xml
sed -i "/<device name=\"earpiece\">/ { N; /    <path name=\"on\">/ s/    <path name=\"on\">/    <path name=\"on\">\n        <ctl name=\"FM Control\" val=\"4\"\/>/}" configs/tiny_hw.xml
sed -i "/    <path name=\"off\">/ { N; /        <ctl name=\"RCV Switch\" val=\"0\"\/>/ s/    <path name=\"off\">/    <path name=\"off\">\n        <ctl name=\"FM Control\" val=\"4\"\/>/}" configs/tiny_hw.xml
sed -i "/<device name=\"headphone\">/ { N; /    <path name=\"on\">/ s/    <path name=\"on\">/    <path name=\"on\">\n        <ctl name=\"FM Control\" val=\"4\"\/>/}" configs/tiny_hw.xml
sed -i "/    <path name=\"off\">/ { N; /        <ctl name=\"HP Switch\" val=\"0\"\/>/ s/    <path name=\"off\">/    <path name=\"off\">\n        <ctl name=\"FM Control\" val=\"4\"\/>/}" configs/tiny_hw.xml
sed -i "/<device name=\"sco-out\">/ { N; /    <path name=\"on\">/ s/    <path name=\"on\">/    <path name=\"on\">\n        <ctl name=\"FM Control\" val=\"4\"\/>/}" configs/tiny_hw.xml
sed -i "/    <path name=\"off\">/ { N; /        <ctl name=\"AIF2DAC2L Mixer AIF1.1 Switch\" val=\"0\"\/>/ s/    <path name=\"off\">/    <path name=\"off\">\n        <ctl name=\"FM Control\" val=\"4\"\/>/}" configs/tiny_hw.xml
sed -i -e "s/mmcblk0p12/mmcblk0p13/" -e "s/mmcblk0p11/mmcblk0p12/" -e "s/mmcblk0p10/mmcblk0p11/" -e "s/mmcblk0p9/mmcblk0p10/" -e "s/mmcblk0p8/mmcblk0p9/" rootdir/fstab.smdk4x12
sed -i -e "s/mmcblk0p12/mmcblk0p13/" -e "s/mmcblk0p11/mmcblk0p12/" -e "s/mmcblk0p10/mmcblk0p11/" -e "s/mmcblk0p9 /mmcblk0p10/"  -e "s/mmcblk0p8/mmcblk0p9/" selinux/file_contexts
sed -i "s/\/dev\/umts_boot0                         u:object_r:radio_device:s0/\/dev\/umts_boot0                         u:object_r:radio_device:s0\n\/dev\/cdma_boot0                         u:object_r:radio_device:s0/" selinux/file_contexts
sed -i "s/\/dev\/umts_boot1                         u:object_r:radio_device:s0/\/dev\/umts_boot1                         u:object_r:radio_device:s0\n\/dev\/cdma_boot1                         u:object_r:radio_device:s0/" selinux/file_contexts
sed -i "s/\/dev\/umts_ipc0                          u:object_r:radio_device:s0/\/dev\/umts_ipc0                          u:object_r:radio_device:s0\n\/dev\/cdma_ipc0                          u:object_r:radio_device:s0/" selinux/file_contexts
sed -i "s/\/dev\/umts_ramdump0                      u:object_r:radio_device:s0/\/dev\/umts_ramdump0                      u:object_r:radio_device:s0\n\/dev\/cdma_ramdump0                      u:object_r:radio_device:s0/" selinux/file_contexts
sed -i "s/\/dev\/umts_rfs0                          u:object_r:radio_device:s0/\/dev\/umts_rfs0                          u:object_r:radio_device:s0\n\/dev\/cdma_rfs0                          u:object_r:radio_device:s0/" selinux/file_contexts
sed -i "s/\/dev\/cdma_rfs0                          u:object_r:radio_device:s0/\/dev\/cdma_rfs0                          u:object_r:radio_device:s0\n\/dev\/cdma_multipdp                      u:object_r:radio_device:s0/" selinux/file_contexts
fi
sed -i "s@export LD_SHIM_LIBS /system/lib/libsec-ril@export LD_SHIM_LIBS /system/lib/libril@" rootdir/init.target.rc
sed -i "s/    write \/data\/.cid.info 0/    write \/data\/.cid.info murata\n    chown wifi system \/data\/.cid.info\n    chmod 0660 \/data\/.cid.info/" rootdir/init.target.rc
sed -i "s/service cpboot-daemon \/sbin\/cbd -d/service cbd-lte \/sbin\/cbd -d -t cmc221 -b d -m d/" rootdir/init.target.rc
sed -i "s/i9300/$C1MODEL/g" selinux/file_contexts
sed -i "s/i9300/$C1MODEL/g" Android.mk
sed -i "s/xmm6262/cmc221/" BoardConfig.mk
sed -i "s/i9300/$C1MODEL/g" BoardConfig.mk
sed -i "s/GT-I9300/SHV-E210$C1VAR/g" BoardConfig.mk
# Enlarge system partition
sed -i 's/# assert/# system partition size\nBOARD_SYSTEMIMAGE_PARTITION_SIZE := 2147483648\n\n# assert/' BoardConfig.mk
# Definition for rild patch
sed -i "s/COMMON_GLOBAL_CFLAGS += -DDISABLE_ASHMEM_TRACKING/COMMON_GLOBAL_CFLAGS += -DDISABLE_ASHMEM_TRACKING -DRIL_PRE_M_BLOBS/" BoardConfig.mk
sed -i "s/i9300/$C1MODEL/g" lineage.mk
sed -i "s/GT-I9300/SHV-E210$C1VAR/g" lineage.mk
sed -i "s/I9300/E210$C1VAR/g" lineage.mk
if [ "$C1MODEL" = "c1lgt" ]; then
sed -i 's/samsung\/m0xx\/m0:4\.3\/JSS15J\/E210LXXUGMJ9:user\/release-keys/samsung\/c1lgt\/c1lgt:4.4.4\/KTU84P\/E210LKLUKPJ2:user\/release-keys/' lineage.mk
sed -i 's/m0xx-user 4\.3 JSS15J E210LXXUGMJ9 release-keys/c1lgt-user 4.4.4 KTU84P E210LKLUKPJ2 release-keys/' lineage.mk
elif [ "$C1MODEL" = "c1skt" ]; then
sed -i 's/samsung\/m0xx\/m0:4\.3\/JSS15J\/E210SXXUGMJ9:user\/release-keys/samsung\/c1skt\/c1skt:4.4.4\/KTU84P\/E210SKSUKPJ2:user\/release-keys/' lineage.mk
sed -i 's/m0xx-user 4\.3 JSS15J E210SXXUGMJ9 release-keys/c1skt-user 4.4.4 KTU84P E210SKSUKPJ2 release-keys/' lineage.mk
elif [ "$C1MODEL" = "c1ktt" ]; then
sed -i 's/samsung\/m0xx\/m0:4\.3\/JSS15J\/E210KXXUGMJ9:user\/release-keys/samsung\/c1ktt\/c1ktt:4.4.4\/KTU84P\/E210KKTUKPJ2:user\/release-keys/' lineage.mk
sed -i 's/m0xx-user 4\.3 JSS15J E210KXXUGMJ9 release-keys/c1ktt-user 4.4.4 KTU84P E210KKTUKPJ2 release-keys/' lineage.mk
fi
sed -i "s/m0xx/$C1MODEL/" lineage.mk
sed -i "s/m0/$C1MODEL/" lineage.mk
# Add settings to build.prop
echo ro.ril.telephony.mqanelements=6>>system.prop
echo persist.radio.add_power_save=1>>system.prop
echo persist.radio.snapshot_enabled=1>>system.prop
echo persist.radio.snapshot_timer=22>>system.prop
#echo telephony.lteOnGsmDevice=1>>system.prop
#echo telephony.lteOnCdmaDevice=0>>system.prop
#echo persist.radio.use_se_table_only=1>>system.prop
#echo ro.ril.hsxpa=1>>system.prop
#echo ro.ril.gprsclass=10>>system.prop
sed -i "s/i9300/$C1MODEL/g" extract-files.sh
mv i9300.mk $C1MODEL.mk
sed -i "s/i9300/$C1MODEL/g" $C1MODEL.mk
sed -i "s/m0/$C1MODEL/g" $C1MODEL.mk
# Patch RILJ
patch --no-backup-if-mismatch -t -r - ril/telephony/java/com/android/internal/telephony/SamsungExynos4RIL.java < $SDIR/c1ril-cm.diff
# Add more proprietary files
#echo bin/rild>>proprietary-files.txt
echo lib/libril.so>>proprietary-files.txt
echo lib/libsecril-client.so>>proprietary-files.txt
echo lib/hw/sensors.smdk4x12.so>>proprietary-files.txt
sed -i "s/i9300/$C1MODEL/g" system.prop
# Patch config files to support LTE
sed -i 's/>GPRS|EDGE|WCDMA</>GSM|WCDMA|LTE</' overlay/frameworks/base/core/res/res/values/config.xml
mkdir -p overlay/packages/services/Telephony/res/values/
echo \<?xml version=\"1.0\" encoding=\"utf-8\"?\>>overlay/packages/services/Telephony/res/values/config.xml
echo \<resources\>>>overlay/packages/services/Telephony/res/values/config.xml
echo \<bool name=\"config_enabled_lte\" translatable=\"false\"\>true\</bool\>>>overlay/packages/services/Telephony/res/values/config.xml
echo \</resources\>>>overlay/packages/services/Telephony/res/values/config.xml
# Make SamsungServiceMode work with the new RIL
mkdir -p overlay/packages/apps/SamsungServiceMode/res/values/
echo \<?xml version=\"1.0\" encoding=\"utf-8\"?\>>overlay/packages/apps/SamsungServiceMode/res/values/config.xml
echo \<resources\>>>overlay/packages/apps/SamsungServiceMode/res/values/config.xml
echo \<integer name=\"config_api_version\"\>2\</integer\>>>overlay/packages/apps/SamsungServiceMode/res/values/config.xml
echo \</resources\>>>overlay/packages/apps/SamsungServiceMode/res/values/config.xml
# Patch smdk4412 common files
cd ../smdk4412-common
git checkout -f
# TODO Make this change only for c1 with if
sed -i 's/phone-xhdpi-1024-dalvik-heap/phone-xhdpi-2048-dalvik-heap/' common.mk
sed -i "s/i9300 i9305/i9300 c1lgt c1skt c1ktt i9305/g" Android.mk
sed -i "s/i9300 i9305/i9300 c1lgt c1skt c1ktt i9305/g" extract-files.sh
sed -i "s/i9300 i9305/i9300 c1lgt c1skt c1ktt i9305/g" camera/Android.mk
# Add more camera firmware variants, I don't sure it is needed but it should cause no harm
echo vendor/firmware/SlimISP_BK.bin>>proprietary-files.txt
echo vendor/firmware/SlimISP_GJ.bin>>proprietary-files.txt
echo vendor/firmware/SlimISP_GM.bin>>proprietary-files.txt
cd ../$C1MODEL
# Now we can copy proprietary files to vendor directory
. ./extract-files.sh $SDIR/blobs/
croot
# Configure samsung libril to be built like for i9300. It is needed for dependencies but won't be used anyway.
cd hardware/samsung
git checkout -f
sed -i "s/xmm6262 xmm6360/xmm6262 cmc221 xmm6360/g" ril/Android.mk
sed -i "s/xmm6262 xmm6360/xmm6262 cmc221 xmm6360/g" ril/libril/Android.mk
# Patch rild to load properitary libril, thanks to Haxynox
cd ../ril
git checkout -f
sed -i 's/extern void RIL_register_socket (RIL_RadioFunctions \*(\*rilUimInit)/#ifndef RIL_PRE_M_BLOBS\nextern void RIL_register_socket (RIL_RadioFunctions *(*rilUimInit)/' rild/rild.c
sed -i 's/        (const struct RIL_Env \*, int, char \*\*), RIL_SOCKET_TYPE socketType, int argc, char \*\*argv);/        (const struct RIL_Env *, int, char **), RIL_SOCKET_TYPE socketType, int argc, char **argv);\n#endif/' rild/rild.c
sed -i 's/    if (rilUimInit) {/#ifndef RIL_PRE_M_BLOBS\n    if (rilUimInit) {/' rild/rild.c
sed -i 's/    RLOGD("RIL_register_socket completed");/    RLOGD("RIL_register_socket completed");\n#endif/' rild/rild.c
croot
# Patch rild.rc for c1
echo "	onrestart restart cbd-lte" >> hardware/ril/rild/rild.rc
# Patch samsung kernel for c1
cd kernel/samsung/smdk4412
git checkout -f
if grep -q Microsoft /proc/version; then
# Workaround for strange WSL bug
cd include
rm asm
ln -s asm-generic asm
cd ..
fi
rm -rf drivers/misc/modem_if_c1
rm -rf include/linux/platform_data/modem_c1.h
patch --no-backup-if-mismatch -t -r - -p1 < $SDIR/c1kernel-cm.diff
# CDMA modem is not used in this build, so we disable it and maybe save some power
sed -i 's/	setup_cdma_modem_env();/#if !defined(CONFIG_C1_LGT_EXPERIMENTAL)\n	setup_cdma_modem_env();\n#endif/' arch/arm/mach-exynos/board-c1lgt-modems.c
sed -i 's/	config_cdma_modem_gpio();/#if !defined(CONFIG_C1_LGT_EXPERIMENTAL)\n	config_cdma_modem_gpio();\n#endif/' arch/arm/mach-exynos/board-c1lgt-modems.c
sed -i 's/	bnk_cfg = \&cbp_edpram_bank_cfg;/#if !defined(CONFIG_C1_LGT_EXPERIMENTAL)\n	bnk_cfg = \&cbp_edpram_bank_cfg;/' arch/arm/mach-exynos/board-c1lgt-modems.c
sed -i 's/	sromc_config_access_timing(bnk_cfg->csn, tm_cfg);/@ @ @ @/' arch/arm/mach-exynos/board-c1lgt-modems.c
sed -i '1,/@ @ @ @/s/@ @ @ @/	sromc_config_access_timing(bnk_cfg->csn, tm_cfg);/' arch/arm/mach-exynos/board-c1lgt-modems.c
sed -i '1,/@ @ @ @/s/@ @ @ @/	sromc_config_access_timing(bnk_cfg->csn, tm_cfg);\n#endif/' arch/arm/mach-exynos/board-c1lgt-modems.c
sed -i 's/	platform_device_register(\&cdma_modem);/#if !defined(CONFIG_C1_LGT_EXPERIMENTAL)\n	platform_device_register(\&cdma_modem);\n#endif/' arch/arm/mach-exynos/board-c1lgt-modems.c
# Update camera kernel driver from Samsung source, this seems to make camera app glitches less severe
cp $SDIR/camera/s5c73m3.c drivers/media/video/
cp $SDIR/camera/s5c73m3.h drivers/media/video/
cp $SDIR/camera/s5c73m3_spi.c drivers/media/video/
cp $SDIR/camera/s5c73m3_platform.h include/media/
cp $SDIR/camera/midas-camera.c arch/arm/mach-exynos/
# sed -i 's@clk_set_rate(sclk, 100 \* 1000 \* 1000); /\*50MHz\*/@clk_set_rate(sclk, 50 * 1000 * 1000); /*25MHz*/@' arch/arm/mach-exynos/mach-midas.c
cd arch/arm/configs
# Kernel config for all c1 models
cp lineageos_i9300_defconfig lineageos_${C1MODEL}_defconfig
sed -i 's/CONFIG_TARGET_LOCALE_EUR=y//' lineageos_${C1MODEL}_defconfig
sed -i 's/# CONFIG_TARGET_LOCALE_KOR is not set//' lineageos_${C1MODEL}_defconfig
echo CONFIG_TARGET_LOCALE_KOR=y>>lineageos_${C1MODEL}_defconfig
sed -i 's/CONFIG_MACH_M0=y//' lineageos_${C1MODEL}_defconfig
sed -i 's/# CONFIG_MACH_C1 is not set//' lineageos_${C1MODEL}_defconfig
echo CONFIG_MACH_C1=y>>lineageos_${C1MODEL}_defconfig
sed -i 's/CONFIG_WLAN_REGION_CODE=100//' lineageos_${C1MODEL}_defconfig
sed -i 's/CONFIG_SEC_MODEM_M0=y//' lineageos_${C1MODEL}_defconfig
sed -i 's/# CONFIG_LTE_MODEM_CMC221 is not set//' lineageos_${C1MODEL}_defconfig
echo CONFIG_LTE_MODEM_CMC221=y>>lineageos_${C1MODEL}_defconfig
sed -i 's/# CONFIG_LINK_DEVICE_DPRAM is not set//' lineageos_${C1MODEL}_defconfig
echo CONFIG_LINK_DEVICE_DPRAM=y>>lineageos_${C1MODEL}_defconfig
sed -i 's/# CONFIG_LINK_DEVICE_USB is not set//' lineageos_${C1MODEL}_defconfig
echo CONFIG_LINK_DEVICE_USB=y>>lineageos_${C1MODEL}_defconfig
sed -i 's/# CONFIG_USBHUB_USB3503 is not set//' lineageos_${C1MODEL}_defconfig
echo CONFIG_USBHUB_USB3503=y>>lineageos_${C1MODEL}_defconfig
sed -i 's/CONFIG_UMTS_MODEM_XMM6262=y//' lineageos_${C1MODEL}_defconfig
sed -i 's/CONFIG_LINK_DEVICE_HSIC=y//' lineageos_${C1MODEL}_defconfig
sed -i 's/# CONFIG_SIPC_VER_5 is not set//' lineageos_${C1MODEL}_defconfig
echo CONFIG_SIPC_VER_5=y>>lineageos_${C1MODEL}_defconfig
sed -i 's/CONFIG_SND_DEBUG=y//' lineageos_${C1MODEL}_defconfig
sed -i 's/CONFIG_FM_RADIO=y//' lineageos_${C1MODEL}_defconfig
sed -i 's/CONFIG_FM_SI4705=y//' lineageos_${C1MODEL}_defconfig
sed -i 's/# CONFIG_TDMB is not set//' lineageos_${C1MODEL}_defconfig
echo CONFIG_TDMB=y>>lineageos_${C1MODEL}_defconfig
echo CONFIG_TDMB_VENDOR_RAONTECH=y>>lineageos_${C1MODEL}_defconfig
echo CONFIG_TDMB_MTV318=y>>lineageos_${C1MODEL}_defconfig
echo CONFIG_TDMB_SPI=y>>lineageos_${C1MODEL}_defconfig
# We need this one only if we want to reuse the kernel in TWRP
sed -i 's/# CONFIG_RD_LZMA is not set//' lineageos_${C1MODEL}_defconfig
echo CONFIG_RD_LZMA=y>>lineageos_${C1MODEL}_defconfig
# Fix video playback error, thanks to FullGreen
sed -i 's/CONFIG_DMA_CMA=y//' lineageos_${C1MODEL}_defconfig
sed -i '/CONFIG_CMA_SIZE_MBYTES/d' lineageos_${C1MODEL}_defconfig
sed -i '/CONFIG_CMA_SIZE_SEL_MBYTES/d' lineageos_${C1MODEL}_defconfig
sed -i '/CONFIG_CMA_ALIGNMENT/d' lineageos_${C1MODEL}_defconfig
sed -i '/CONFIG_CMA_AREAS/d' lineageos_${C1MODEL}_defconfig
sed -i 's/CONFIG_USE_FIMC_CMA=y//' lineageos_${C1MODEL}_defconfig
sed -i 's/CONFIG_USE_MFC_CMA=y//' lineageos_${C1MODEL}_defconfig
# Model-specific kernel config
if [ "$C1MODEL" = "c1lgt" ]; then
echo CONFIG_MACH_C1_KOR_LGT=y>>lineageos_${C1MODEL}_defconfig
echo CONFIG_C1_LGT_EXPERIMENTAL=y>>lineageos_${C1MODEL}_defconfig
sed -i 's/# CONFIG_FM34_WE395 is not set//' lineageos_${C1MODEL}_defconfig
echo CONFIG_FM34_WE395=y>>lineageos_${C1MODEL}_defconfig
echo CONFIG_WLAN_REGION_CODE=203>>lineageos_${C1MODEL}_defconfig
sed -i 's/# CONFIG_SEC_MODEM_C1_LGT is not set//' lineageos_${C1MODEL}_defconfig
echo CONFIG_SEC_MODEM_C1_LGT=y>>lineageos_${C1MODEL}_defconfig
sed -i 's/# CONFIG_CDMA_MODEM_CBP72 is not set//' lineageos_${C1MODEL}_defconfig
echo CONFIG_CDMA_MODEM_CBP72=y>>lineageos_${C1MODEL}_defconfig
sed -i 's/# CONFIG_LTE_VIA_SWITCH is not set//' lineageos_${C1MODEL}_defconfig
echo CONFIG_LTE_VIA_SWITCH=y>>lineageos_${C1MODEL}_defconfig
echo CONFIG_CMC_MODEM_HSIC_SYSREV=11>>lineageos_${C1MODEL}_defconfig
elif [ "$C1MODEL" = "c1skt" ]; then
echo CONFIG_MACH_C1_KOR_SKT=y>>lineageos_${C1MODEL}_defconfig
echo CONFIG_WLAN_REGION_CODE=201>>lineageos_${C1MODEL}_defconfig
sed -i 's/# CONFIG_SEC_MODEM_C1 is not set//' lineageos_${C1MODEL}_defconfig
echo CONFIG_SEC_MODEM_C1=y>>lineageos_${C1MODEL}_defconfig
echo CONFIG_CMC_MODEM_HSIC_SYSREV=9>>lineageos_${C1MODEL}_defconfig
elif [ "$C1MODEL" = "c1ktt" ]; then
echo CONFIG_MACH_C1_KOR_SKT=y>>lineageos_${C1MODEL}_defconfig
echo CONFIG_WLAN_REGION_CODE=202>>lineageos_${C1MODEL}_defconfig
sed -i 's/# CONFIG_SEC_MODEM_C1 is not set//' lineageos_${C1MODEL}_defconfig
echo CONFIG_SEC_MODEM_C1=y>>lineageos_${C1MODEL}_defconfig
echo CONFIG_CMC_MODEM_HSIC_SYSREV=9>>lineageos_${C1MODEL}_defconfig
fi
# Now that everything is configured correctly we can run breakfast again and it should complete without errors
croot
breakfast $C1MODEL
