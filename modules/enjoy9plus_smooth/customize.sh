#!/system/bin/sh
HW=$(getprop ro.hardware)
ui_print "- Detected hardware: $HW"
if [ "$HW" != "kirin710" ]; then
  abort "! This module is strictly for Huawei Enjoy 9 Plus / Kirin 710 (found: $HW). Do NOT flash on Kirin 970!"
fi
set_perm "$MODPATH/service.sh" 0 0 0755
ui_print "- Enjoy 9 Plus (Kirin 710) smooth & 2 GiB LZ4 ZRAM module installed."
