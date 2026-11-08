#!/bin/bash
# Add the device shims (device/amazon/mt8127-common/libshims, installed to /vendor/lib)
# and libutilscallstack to the DT_NEEDED of the Nougat blobs that use their symbols.
# This replaces Lineage's TARGET_LD_SHIM_LIBS, which only Lineage's linker honours
# (a GSI's does not). Idempotent. The map was generated from each blob's undefined
# symbols against the shims' exports. libcam.utils.sensorlistener's libsensor calls go
# to libshim_sensor: libsensor is outside the VNDK, so a GSI's vendor namespace can't
# load it.
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
lib/hw/audio.primary.mt8127.so: libshim_liblog.so libshim_audio.so
lib/hw/camera.mt8127.so: libshim_liblog.so
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
lib/libcameraanalyzer.so: libshim_liblog.so libshim_libcamera.so
lib/libcamera_client_mtk.so: libshim_liblog.so
lib/libcameracustom.so: libshim_liblog.so
lib/libcam.exif.so: libshim_liblog.so
lib/libcam.paramsmgr.so: libshim_liblog.so
lib/libcam_platform.so: libshim_liblog.so
lib/libcam.utils.sensorlistener.so: libshim_libcamera.so libshim_liblog.so libshim_sensor.so
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
lib/libstagefright_omx.so: libshim_liblog.so
lib/libaal.so: libshim_liblog.so
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

# System libraries outside the VNDK that the blobs list in DT_NEEDED but import nothing
# from (beyond __aeabi_* helpers libc also exports). A GSI's linker puts vendor processes
# in the strict VNDK namespace, where these can't be found and fail the whole load.
# libsensor was added by an earlier version of this script; libjnigraphics' three
# AndroidBitmap_* calls are stubbed in libshim_libcamera (JNI-only, never reached in the
# camera HAL).
DROP='
lib/hw/audio.primary.mt8127.so: libmedia.so libpowermanager.so
bin/audiocli: libmedia.so libpowermanager.so
bin/meta_tst: libmedia.so
lib/libmediacodeclogger.so: libmedia.so
lib/libmediacodecloggerservice.so: libmedia.so libnbaio.so
lib/libaudiocompensationfilter.so: libnativehelper.so
lib/libaudiocomponentengine.so: libnativehelper.so
lib/libaudiodcrflt.so: libnativehelper.so
lib/libaudiomtkdcremoval.so: libnativehelper.so
lib/libaudiosetting.so: libnativehelper.so
lib/libbessound_hd_mtk.so: libnativehelper.so
lib/libbessound_mtk.so: libnativehelper.so
lib/libblisrc.so: libnativehelper.so
lib/libblisrc32.so: libnativehelper.so
lib/libcvsd_mtk.so: libnativehelper.so
lib/libgsswrapper.so: libnativehelper.so
lib/libmatv_cust.so: libnativehelper.so
lib/libmsbc_mtk.so: libnativehelper.so
lib/libmtklimiter.so: libnativehelper.so
lib/libmtkshifter.so: libnativehelper.so
lib/libspeech_enh_lib.so: libnativehelper.so
lib/libMtkOmxVdec.so: libstagefright.so
lib/libMtkOmxVdecEx.so: libstagefright.so
lib/hw/keystore.mt8127.so: libkeystore_binder.so
lib/libdrmplayreadydecryptor.so: libandroid_runtime.so libdrmframework.so
lib/libsmartsuspendmanagerservice.so: libandroid_runtime.so
lib/libdrmmtkutil.so: libdrmframework.so
bin/ext4_resize: libext2_com_err.so libext2_e2p.so
lib/hw/camera.mt8127.so: libsensor.so
lib/libcam.utils.sensorlistener.so: libsensor.so
lib/libcameraanalyzer.so: libjnigraphics.so
'
echo "$DROP" | while IFS=: read rel libs; do
    [ -n "$rel" ] || continue
    name=$(basename "$rel")
    src=$(find mt8127-common/proprietary ford/proprietary -name "$name" -type f)
    [ $(echo "$src" | wc -l) = 1 ] && [ -n "$src" ] || { echo "can't find a unique $name"; exit 1; }
    for l in $libs; do
        patchelf --print-needed "$src" | grep -qx "$l" && { patchelf --remove-needed "$l" "$src"; echo "$src -= $l"; }
    done
done
true

# Nougat blobs start threads without a name, which Q's libutils aborts on. Rename their
# Thread::run(const char*, int, unsigned) import (same length, so only .dynstr changes)
# to libshim_liblog's wrapper, which supplies a name.
python3 - mt8127-common/proprietary ford/proprietary <<'PY'
import os, subprocess, sys
OLD, NEW = b'_ZN7android6Thread3runEPKcij\0', b'shim_android_Thread_run_name\0'
for root in sys.argv[1:]:
    for d, _, files in os.walk(root):
        for f in files:
            p = os.path.join(d, f)
            data = open(p, 'rb').read()
            if not data.startswith(b'\x7fELF') or OLD not in data:
                continue
            out = subprocess.run(['readelf', '-SW', p], capture_output=True, text=True).stdout
            sec = [l.split() for l in out.splitlines() if ' .dynstr ' in l][0]
            i = sec.index('.dynstr')
            off, size = int(sec[i + 3], 16), int(sec[i + 4], 16)
            pos = data.find(b'\0' + OLD, off - 1, off + size) + 1
            if pos <= 0:
                continue
            open(p, 'wb').write(data[:pos] + NEW + data[pos + len(NEW):])
            print(p, 'Thread::run -> shim_android_Thread_run_name')
PY
