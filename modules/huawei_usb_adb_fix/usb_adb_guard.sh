#!/system/bin/sh
MODDIR=${0%/*}
PIDFILE=/dev/.huawei_usb_adb_guard.pid
LOGFILE="$MODDIR/guard.log"

[ -d /config/usb_gadget/g1/functions ] || exit 0
[ -d /dev/usb-ffs ] || exit 0

# Singleton guard (clean up previous guardian and its child logcat)
if [ -f "$PIDFILE" ]; then
  OLD_PID="$(cat "$PIDFILE" 2>/dev/null)"
  if [ -n "$OLD_PID" ] && [ "$OLD_PID" != "$$" ] && [ -d "/proc/$OLD_PID" ]; then
    pkill -P "$OLD_PID" 2>/dev/null || true
    kill "$OLD_PID" 2>/dev/null || true
    sleep 1
  fi
fi
echo "$$" > "$PIDFILE"

log_msg() {
  echo "$(date '+%m-%d %H:%M:%S') [$$] $1" >> "$LOGFILE"
  if [ -f "$LOGFILE" ] && [ "$(wc -l < "$LOGFILE" 2>/dev/null || echo 0)" -gt 120 ]; then
    tail -n 60 "$LOGFILE" > "${LOGFILE}.tmp" && mv "${LOGFILE}.tmp" "$LOGFILE"
  fi
}

recover_ffs_adb() {
  REASON="$1"
  ADB_EN="$(settings get global adb_enabled 2>/dev/null)"
  [ "$ADB_EN" = "1" ] || return 0

  # Never disrupt an already healthy configured USB connection
  UDC_STATE="$(cat /sys/class/udc/*/state 2>/dev/null | head -n 1)"
  if [ "$UDC_STATE" = "configured" ]; then
    log_msg "Skip recovery (reason=$REASON): UDC already configured"
    return 0
  fi

  CUR="$(getprop sys.usb.config)"
  case "$CUR" in
    mtp,adb|ptp,adb|rndis,adb|midi,adb|accessory,adb|audio_source,adb|adb) TARGET="$CUR" ;;
    *) TARGET="adb" ;;
  esac

  log_msg "Triggering ffs.adb recovery (reason=$REASON, cur=$CUR -> target=$TARGET)"
  setprop persist.sys.usb.config adb 2>/dev/null || true
  setprop sys.usb.config none 2>/dev/null || true

  # Wait cleanly for init's sys.usb.config=none action to settle (max 4s)
  i=0
  while [ "$i" -lt 4 ]; do
    ST="$(getprop sys.usb.state)"
    AP="$(pidof adbd)"
    if [ "$ST" = "none" ] && [ -z "$AP" ]; then
      break
    fi
    if [ "$i" -eq 2 ] && [ -n "$AP" ]; then
      setprop ctl.stop adbd 2>/dev/null || stop adbd 2>/dev/null || true
    fi
    sleep 1
    i=$((i + 1))
  done
  sleep 1

  echo "" > /config/usb_gadget/g1/UDC 2>/dev/null || echo none > /config/usb_gadget/g1/UDC 2>/dev/null || true
  rm -f /config/usb_gadget/g1/configs/b.1/f* 2>/dev/null || true

  # Unmount functionfs & recreate ffs.adb kernel instance (use /proc/mounts, NEVER bare `mount`!)
  umount /dev/usb-ffs/adb 2>/dev/null || umount -l /dev/usb-ffs/adb 2>/dev/null || true
  sleep 1
  if ! rmdir /config/usb_gadget/g1/functions/ffs.adb 2>/dev/null; then
    rm -f /config/usb_gadget/g1/configs/b.1/f* 2>/dev/null || true
    rmdir /config/usb_gadget/g1/functions/ffs.adb 2>/dev/null || true
  fi
  mkdir -p /config/usb_gadget/g1/functions/ffs.adb
  if ! grep -q ' /dev/usb-ffs/adb ' /proc/mounts 2>/dev/null; then
    mount -t functionfs -o uid=2000,gid=2000 adb /dev/usb-ffs/adb 2>/dev/null || true
  fi

  setprop sys.usb.ffs.ready 0 2>/dev/null || true
  sleep 1
  setprop sys.usb.config "$TARGET" 2>/dev/null || true

  # Wait for adbd to come back up (and explicitly ensure it is running)
  sleep 4
  if [ -z "$(pidof adbd)" ]; then
    setprop ctl.start adbd 2>/dev/null || start adbd 2>/dev/null || true
    sleep 3
  fi

  UDC_VAL="$(cat /config/usb_gadget/g1/UDC 2>/dev/null)"
  UDC_ST="$(cat /sys/class/udc/*/state 2>/dev/null | head -n 1)"
  log_msg "Recovery done: UDC=[$UDC_VAL] state=[$UDC_ST] adbd=[$(pidof adbd)]"
}

# Boot-time sanitization
PERSIST_CFG="$(getprop persist.sys.usb.config)"
case "$PERSIST_CFG" in
  *manufacture*|*hisuite*|"")
    setprop persist.sys.usb.config adb 2>/dev/null || true
    log_msg "Sanitized persist.sys.usb.config ($PERSIST_CFG -> adb)"
    ;;
esac

if [ "$(settings get global adb_enabled 2>/dev/null)" = "1" ]; then
  CUR_CFG="$(getprop sys.usb.config)"
  UDC_NOW="$(cat /config/usb_gadget/g1/UDC 2>/dev/null)"
  case "$CUR_CFG" in
    *manufacture*|*hisuite*)
      recover_ffs_adb "boot_bad_config"
      ;;
    *adb*)
      if [ -z "$UDC_NOW" ] || [ "$UDC_NOW" = "none" ]; then
        recover_ffs_adb "boot_empty_udc"
      fi
      ;;
  esac
fi

log_msg "Guardian v1.2.0 started (epoch-filtered event watch)"

START_TS="$(date +%s)"
LAST_FIX=0
STREAK=0
LAST_HIT=0

while true; do
  logcat -b main -T 1 -v epoch adbd:W '*:S' 2>/dev/null | while IFS= read -r line; do
    case "$line" in
      *"timed out while waiting for FUNCTIONFS_BIND"*)
        TS="$(echo "$line" | awk '{print int($1)}')"
        [ -n "$TS" ] && [ "$TS" -gt 0 ] || TS="$(date +%s)"
        if [ "$TS" -le "$START_TS" ] || [ "$TS" -le "$LAST_FIX" ]; then
          continue
        fi
        if [ $((TS - LAST_HIT)) -le 8 ]; then
          STREAK=$((STREAK + 1))
        else
          STREAK=1
        fi
        LAST_HIT="$TS"
        if [ "$STREAK" -ge 3 ] && [ $((TS - LAST_FIX)) -ge 20 ]; then
          STREAK=0
          recover_ffs_adb "FUNCTIONFS_BIND_timeout"
          LAST_FIX="$(date +%s)"
        fi
        ;;
    esac
  done
  sleep 2
done
