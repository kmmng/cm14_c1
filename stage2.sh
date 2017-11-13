#!/bin/bash
echo Stage 2 - prepare source for build and patch it for SHV-E210.
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
echo Unknown device model, C1MODEL should be c1lgt/c1skt/c1ktt.
exit
fi
echo Configuring source for SHV-E210$C1VAR...
echo Errors may appear in the first part of the configuration, please ignore them.
export PATH="$HOME/bin:$PATH"
cd $BDIR
source build/envsetup.sh
# Cleanup
rm -rf vendor/samsung/i9300
rm -rf vendor/samsung/$C1MODEL
rm -rf vendor/samsung/smdk4412-common
# Init i9300 source. This will produce some errors but this is normal and we should continue.
breakfast i9300
echo No more errors should appear below this message.
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
# Only if we use CDMA modem
#sed -i "s/\/dev\/umts_boot0                         u:object_r:radio_device:s0/\/dev\/umts_boot0                         u:object_r:radio_device:s0\n\/dev\/cdma_boot0                         u:object_r:radio_device:s0/" selinux/file_contexts
#sed -i "s/\/dev\/umts_boot1                         u:object_r:radio_device:s0/\/dev\/umts_boot1                         u:object_r:radio_device:s0\n\/dev\/cdma_boot1                         u:object_r:radio_device:s0/" selinux/file_contexts
#sed -i "s/\/dev\/umts_ipc0                          u:object_r:radio_device:s0/\/dev\/umts_ipc0                          u:object_r:radio_device:s0\n\/dev\/cdma_ipc0                          u:object_r:radio_device:s0/" selinux/file_contexts
#sed -i "s/\/dev\/umts_ramdump0                      u:object_r:radio_device:s0/\/dev\/umts_ramdump0                      u:object_r:radio_device:s0\n\/dev\/cdma_ramdump0                      u:object_r:radio_device:s0/" selinux/file_contexts
#sed -i "s/\/dev\/umts_rfs0                          u:object_r:radio_device:s0/\/dev\/umts_rfs0                          u:object_r:radio_device:s0\n\/dev\/cdma_rfs0                          u:object_r:radio_device:s0/" selinux/file_contexts
#sed -i "s/\/dev\/cdma_rfs0                          u:object_r:radio_device:s0/\/dev\/cdma_rfs0                          u:object_r:radio_device:s0\n\/dev\/cdma_multipdp                      u:object_r:radio_device:s0/" selinux/file_contexts
fi
sed -i "s@export LD_SHIM_LIBS /system/lib/libsec-ril@export LD_SHIM_LIBS /system/lib/libril@" rootdir/init.target.rc
sed -i '/    write \/data\/.cid.info 0/d' rootdir/init.target.rc
sed -i "s/service cpboot-daemon \/system\/bin\/cbd -d/service cbd-lte \/system\/bin\/cbd -d -t cmc221 -b d -m d/" rootdir/init.target.rc
sed -i "s/i9300/$C1MODEL/g" selinux/file_contexts
sed -i "s/i9300/$C1MODEL/g" Android.mk
sed -i "s/xmm6262/cmc221/" BoardConfig.mk
sed -i "s/i9300/$C1MODEL/g" BoardConfig.mk
sed -i "s/GT-I9300/SHV-E210$C1VAR/g" BoardConfig.mk
# Enlarge system partition
sed -i 's/# assert/# system partition size\nBOARD_SYSTEMIMAGE_PARTITION_SIZE := 2147483648\n\n# assert/' BoardConfig.mk
sed -i "s/-DDISABLE_ASHMEM_TRACKING/-DDISABLE_ASHMEM_TRACKING -DRIL_PRE_M_BLOBS -DC1_WIFI_FIX/" BoardConfig.mk
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
# Change settings of build.prop
sed -i '/ro.ril.telephony.mqanelements/d' system.prop
echo ro.tvout.enable=true>>system.prop
echo persist.radio.add_power_save=1>>system.prop
echo persist.radio.snapshot_enabled=1>>system.prop
echo persist.radio.snapshot_timer=22>>system.prop
echo ro.ril.telephony.mqanelements=6>>system.prop
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
echo lib/libomission_avoidance.so>>proprietary-files.txt
echo lib/libril.so>>proprietary-files.txt
echo lib/libfactoryutil.so>>proprietary-files.txt
echo lib/hw/sensors.smdk4x12.so>>proprietary-files.txt
#echo lib/libsecril-client.so>>proprietary-files.txt # Only for libsec-ril from 4.4.4
sed -i "s/i9300/$C1MODEL/g" system.prop
# Patch config files to support LTE
sed -i 's/>GPRS|EDGE|WCDMA</>GSM|WCDMA|LTE</' overlay/frameworks/base/core/res/res/values/config.xml
mkdir -p overlay/packages/services/Telephony/res/values/
echo \<?xml version=\"1.0\" encoding=\"utf-8\"?\>>overlay/packages/services/Telephony/res/values/config.xml
echo \<resources\>>>overlay/packages/services/Telephony/res/values/config.xml
echo \<bool name=\"config_enabled_lte\" translatable=\"false\"\>true\</bool\>>>overlay/packages/services/Telephony/res/values/config.xml
echo \</resources\>>>overlay/packages/services/Telephony/res/values/config.xml
# For new libsec-ril, make SamsungServiceMode work with it
mkdir -p overlay/packages/apps/SamsungServiceMode/res/values/
echo \<?xml version=\"1.0\" encoding=\"utf-8\"?\>>overlay/packages/apps/SamsungServiceMode/res/values/config.xml
echo \<resources\>>>overlay/packages/apps/SamsungServiceMode/res/values/config.xml
echo \<integer name=\"config_api_version\"\>2\</integer\>>>overlay/packages/apps/SamsungServiceMode/res/values/config.xml
echo \</resources\>>>overlay/packages/apps/SamsungServiceMode/res/values/config.xml
# Patch smdk4412 common files
cd ../smdk4412-common
git checkout -f
sed -i 's@$(call inherit-product, frameworks/native/build/phone-xhdpi-1024-dalvik-heap.mk)@ifneq ($(filter c1lgt c1skt c1ktt, $(PRODUCT_RELEASE_NAME)),)\n$(call inherit-product, frameworks/native/build/phone-xhdpi-2048-dalvik-heap.mk)\nM-O-R-E@' common.mk
sed -i 's@M-O-R-E@else\n$(call inherit-product, frameworks/native/build/phone-xhdpi-1024-dalvik-heap.mk)\nendif@' common.mk
sed -i "s/i9300 i9305/i9300 c1lgt c1skt c1ktt i9305/g" Android.mk
sed -i "s/i9300 i9305/i9300 c1lgt c1skt c1ktt i9305/g" extract-files.sh
sed -i "s/i9300 i9305/i9300 c1lgt c1skt c1ktt i9305/g" camera/Android.mk
# Add more camera firmware variants, I don't sure it is needed but it should cause no harm
echo vendor/firmware/SlimISP_BK.bin>>proprietary-files.txt
echo vendor/firmware/SlimISP_GJ.bin>>proprietary-files.txt
echo vendor/firmware/SlimISP_GM.bin>>proprietary-files.txt
echo vendor/firmware/SlimISP_PH.bin>>proprietary-files.txt
cd ../$C1MODEL
# Now we can copy proprietary files to vendor directory
. ./extract-files.sh $SDIR/blobs/
croot
cd hardware/samsung
git checkout -f
# Configure samsung libril to be built like for i9300. It is needed for dependencies but won't be used anyway.
sed -i "s/xmm6262 xmm6360/xmm6262 cmc221 xmm6360/g" ril/Android.mk
sed -i "s/xmm6262 xmm6360/xmm6262 cmc221 xmm6360/g" ril/libril/Android.mk
# Workaround for incomplete MAC address list of macloader
sed -i 's/    int type = NONE;/#ifdef C1_WIFI_FIX\n    int type = MURATA;\n#else\n    int type = NONE;\n#endif/' macloader/macloader.c
# Patch rild to load properitary libril, thanks to Haxynox
cd ../ril
git checkout -f
sed -i 's/extern void RIL_register_socket (RIL_RadioFunctions \*(\*rilUimInit)/#ifndef RIL_PRE_M_BLOBS\nextern void RIL_register_socket (RIL_RadioFunctions *(*rilUimInit)/' rild/rild.c
sed -i 's/        (const struct RIL_Env \*, int, char \*\*), RIL_SOCKET_TYPE socketType, int argc, char \*\*argv);/        (const struct RIL_Env *, int, char **), RIL_SOCKET_TYPE socketType, int argc, char **argv);\n#endif/' rild/rild.c
sed -i 's/    if (rilUimInit) {/#ifndef RIL_PRE_M_BLOBS\n    if (rilUimInit) {/' rild/rild.c
sed -i 's/    RLOGD("RIL_register_socket completed");/    RLOGD("RIL_register_socket completed");\n#endif/' rild/rild.c
sed -i 's/extern void RIL_onRequestAck(RIL_Token t);/#ifndef RIL_PRE_M_BLOBS\nextern void RIL_onRequestAck(RIL_Token t);\n#endif/' rild/rild.c
sed -i 's/    RIL_onRequestAck/#ifndef RIL_PRE_M_BLOBS\n    RIL_onRequestAck\n#else\n    NULL\n#endif/' rild/rild.c
croot
# Patch rild.rc for c1
echo "    onrestart restart cbd-lte" >> hardware/ril/rild/rild.rc
# Fix cellular data by making telephony provider use storage paths hardcoded in libsec-ril
sed -i 's/defaultToDeviceProtectedStorage="true"/defaultToDeviceProtectedStorage="false"/' packages/providers/TelephonyProvider/AndroidManifest.xml
# Patch samsung kernel for c1
cd kernel/samsung/smdk4412
git checkout -f
# Update modem drivers from Samsung sources and patch them
rm -rf drivers/misc/modem_if_c1
rm -rf include/linux/platform_data/modem_c1.h
patch --no-backup-if-mismatch -t -r - -p1 < $SDIR/c1kernel-cm.diff
# Update camera kernel driver from Samsung sources, this should make camera app glitches less severe.
cp $SDIR/camera/s5c73m3.c drivers/media/video/
cp $SDIR/camera/s5c73m3.h drivers/media/video/
cp $SDIR/camera/s5c73m3_spi.c drivers/media/video/
cp $SDIR/camera/s5c73m3_platform.h include/media/
cp $SDIR/camera/midas-camera.c arch/arm/mach-exynos/
cd arch/arm/configs
KCFG=lineageos_${C1MODEL}_defconfig
# Kernel config for all c1 models
cp lineageos_i9300_defconfig $KCFG
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
# Now that everything is configured correctly we can run breakfast again and it should complete without errors
croot
export WITH_SU=true
breakfast $C1MODEL
