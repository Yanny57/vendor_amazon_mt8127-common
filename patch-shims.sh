#!/bin/bash
# Add the device shims (device/amazon/mt8127-common/libshims, installed to /vendor/lib)
# and libutilscallstack to the DT_NEEDED of the Nougat blobs that use their symbols.
# This replaces Lineage's TARGET_LD_SHIM_LIBS, which only Lineage's linker honours
# (a GSI's does not). Idempotent. The map was generated from each blob's undefined
# symbols against the shims' exports. camera.mt8127 and libcam.utils.sensorlistener
# also get libsensor (not VNDK, so libshim_libcamera can't link it): the camera provider,
# unlike cameraserver, doesn't load it on its own, and libcam_platform is dlopened
# separately from camera.mt8127.
set -e
cd "$(dirname "$0")/.."
MAP='
bin/6620_launcher: libshim_liblog.so
bin/atcid: libshim_liblog.so
bin/audiocli: libshim_liblog.so
bin/audiocmdservice_atci: libshim_liblog.so
bin/ext4_resize: libshim_liblog.so
bin/kisd: libshim_liblog.so
bin/meta_tst: libshim_liblog.so
bin/nvram_agent_binder: libshim_liblog.so
bin/recovery_reporter: libshim_liblog.so
bin/rpmb_svc: libshim_liblog.so
bin/thermald: libshim_libbinder.so
bin/wmt_loader: libshim_liblog.so
lib/hw/audio.primary.mt8127.so: libshim_liblog.so
lib/hw/camera.mt8127.so: libshim_liblog.so libsensor.so
lib/hw/gralloc.mt8127.so: libshim_liblog.so
lib/hw/hwcomposer.mt8127.so: libshim_liblog.so
lib/hw/keystore.mt8127.so: libshim_liblog.so
lib/hw/memtrack.mt8127.so: libshim_liblog.so
lib/hw/sensors.mt8127.so: libshim_liblog.so
lib/hw/thermal.mt8127.so: libshim_liblog.so
lib/libaudiocompensationfilter.so: libshim_liblog.so
lib/libaudiocomponentengine.so: libshim_liblog.so libutilscallstack.so
lib/libaudiocustparam.so: libshim_liblog.so
lib/libaudiomtkdcremoval.so: libshim_liblog.so
lib/libbluetoothem_mtk.so: libshim_liblog.so
lib/libbluetooth_hw_test.so: libshim_liblog.so
lib/libbluetooth_mtk_pure.so: libshim_liblog.so
lib/libbluetooth_mtk.so: libshim_liblog.so
lib/libbluetooth_relayer.so: libshim_liblog.so
lib/libbt-vendor.so: libshim_liblog.so
lib/libbwc.so: libshim_liblog.so
lib/libcamalgo.so: libshim_liblog.so
lib/libcam.camadapter.so: libshim_liblog.so
lib/libcam.campipe.so: libshim_liblog.so
lib/libcam.camshot.so: libshim_liblog.so
lib/libcam.client.so: libshim_libcamera.so libshim_liblog.so
lib/libcam.device1.so: libshim_liblog.so
lib/libcamdrv.so: libshim_liblog.so
lib/libcameraanalyzer.so: libshim_liblog.so
lib/libcamera_client_mtk.so: libshim_liblog.so
lib/libcameracustom.so: libshim_liblog.so
lib/libcam.exif.so: libshim_liblog.so
lib/libcam.paramsmgr.so: libshim_liblog.so
lib/libcam_platform.so: libshim_liblog.so
lib/libcam.utils.sensorlistener.so: libshim_libcamera.so libshim_liblog.so libsensor.so
lib/libcam_utils.so: libshim_libcamera.so libshim_liblog.so libutilscallstack.so
lib/libcam.utils.so: libshim_liblog.so libutilscallstack.so
lib/libcustom_nvram.so: libshim_liblog.so
lib/libdrmplayreadydecryptor.so: libshim_liblog.so
lib/libfeatureio.so: libshim_liblog.so
lib/libGdmaScalerPipe.so: libshim_liblog.so
lib/libgralloc_extra.so: libshim_liblog.so
lib/libgui_ext.so: libshim_libbinder.so libshim_liblog.so libshim_gui.so
lib/libhwm.so: libshim_liblog.so
lib/libimageio_plat_drv.so: libshim_liblog.so
lib/libimageio.so: libshim_liblog.so
lib/libion_mtk.so: libshim_liblog.so
lib/libJpgDecPipe.so: libshim_liblog.so
lib/libm4u.so: libshim_liblog.so
lib/libMali.so: libshim_liblog.so libutilscallstack.so
lib/libmatv_cust.so: libshim_liblog.so
lib/libmediacodecloggerservice.so: libshim_libbinder.so libshim_liblog.so
lib/libmediacodeclogger.so: libshim_liblog.so libshim_gui.so
lib/libmediaerrorlogger.so: libshim_liblog.so
lib/libmtk_mali_user.so: libutilscallstack.so
lib/libMtkOmxAIVPlayer.so: libshim_liblog.so libshim_gui.so libshim_libwvm.so
lib/libMtkOmxApeDec.so: libshim_libbinder.so
lib/libMtkOmxVdecEx.so: libshim_gui.so
lib/libMtkOmxVdec.so: libshim_libcamera.so libshim_liblog.so
lib/libMtkOmxVenc.so: libshim_libcamera.so
lib/libnvramagentclient.so: libshim_libbinder.so
lib/libnvram.so: libshim_liblog.so
lib/libsmartsuspendmanagerservice.so: libshim_liblog.so
lib/libsmartvolume.so: libshim_liblog.so
lib/libSwJpgCodec.so: libshim_liblog.so
lib/libtz_uree.so: libshim_liblog.so
lib/lib_uree_mtk_video_secure_al.so: libshim_liblog.so
lib/libvcodecdrv.so: libshim_liblog.so
lib/mediadrm/libwvdrmengine.so: libshim_liblog.so
'
echo "$MAP" | while IFS=: read rel libs; do
    [ -n "$rel" ] || continue
    name=$(basename "$rel")
    src=$(find mt8127-common/proprietary ford/proprietary -name "$name" -type f)
    [ $(echo "$src" | wc -l) = 1 ] && [ -n "$src" ] || { echo "can't find a unique $name"; exit 1; }
    for l in $libs; do
        patchelf --print-needed "$src" | grep -qx "$l" || { patchelf --add-needed "$l" "$src"; echo "$src += $l"; }
    done
done
