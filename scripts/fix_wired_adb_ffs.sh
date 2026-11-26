#!/system/bin/sh
# Huawei Enjoy 9 Plus (Kirin 710 / Linux 4.9) - Fix wired USB ADB (-12 ENOMEM on ffs.adb)
# Run as root via Wireless ADB (wrapped in setsid so stopping adbd does not kill the script):
#   adb -s <IP:PORT> shell "su -c 'setsid sh /data/local/tmp/fix_wired_adb_ffs.sh </dev/null >/data/local/tmp/usb_fix.log 2>&1 &'"

setprop sys.usb.config none
stop adbd
sleep 1.5
echo "" > /config/usb_gadget/g1/UDC 2>/dev/null || true
rm -f /config/usb_gadget/g1/configs/b.1/f* 2>/dev/null || true
sleep 0.5

# Cleanly remount functionfs & recreate ffs.adb to clear Linux 4.9 -ENOMEM (-12) bind deadlock
umount /dev/usb-ffs/adb 2>/dev/null || true
rmdir /config/usb_gadget/g1/functions/ffs.adb 2>/dev/null || true
sleep 0.5
mkdir /config/usb_gadget/g1/functions/ffs.adb
mount -t functionfs adb /dev/usb-ffs/adb -o uid=2000,gid=2000,rmode=0770,fmode=0660   || mount -t functionfs adb /dev/usb-ffs/adb

echo "HUAWEI" > /config/usb_gadget/g1/strings/0x409/manufacturer
echo "POT-LX1" > /config/usb_gadget/g1/strings/0x409/product
setprop persist.sys.usb.config adb
setprop sys.usb.config adb
sleep 3
echo "Done: state=$(getprop sys.usb.state) UDC=$(cat /config/usb_gadget/g1/UDC 2>/dev/null) dwc3=$(cat /sys/class/udc/ff100000.dwc3/state 2>/dev/null)"
