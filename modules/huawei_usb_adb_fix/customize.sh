#!/system/bin/sh
HW=$(getprop ro.hardware)
ui_print "- Detected hardware: $HW"
if [ "$BOOTMODE" = "true" ]; then
  if [ ! -d /config/usb_gadget/g1/functions ] || [ ! -d /dev/usb-ffs ]; then
    abort "! USB ConfigFS / FunctionFS paths not found (/config/usb_gadget/g1 or /dev/usb-ffs)."
  fi
fi
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/usb_adb_guard.sh" 0 0 0755
ui_print "- Huawei EMUI 9.1 Wired USB ADB Permanent Fix (v1.2.0) installed."
ui_print "- Overrides manufacture,adb and auto-heals FUNCTIONFS_BIND deadlocks at 0% idle CPU."
