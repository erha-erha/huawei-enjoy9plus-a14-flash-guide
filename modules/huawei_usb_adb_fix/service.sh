#!/system/bin/sh
MODDIR=${0%/*}
while [ "$(getprop sys.boot_completed)" != "1" ]; do
  sleep 2
done
sleep 3
nohup sh "$MODDIR/usb_adb_guard.sh" >/dev/null 2>&1 < /dev/null &
