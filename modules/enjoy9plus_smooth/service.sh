#!/system/bin/sh
# Huawei Enjoy 9 Plus (JKM-AL00b / Kirin 710 + Mali-G51 + 4 GB RAM)
while [ "$(getprop sys.boot_completed)" != "1" ]; do
  sleep 2
done
sleep 3

# 0. Stop LeaOS runaway debug logcat service writing /splash2/logcat-normal.txt
setprop ctl.stop dump-logs 2>/dev/null || true

# 1. Auto-enable 2 GiB LZ4 ZRAM (crucial on 4 GB RAM Android 14)
if [ -e /sys/block/zram0/disksize ]; then
  TARGET_BYTES=2147483648
  CUR_SIZE=$(cat /sys/block/zram0/disksize 2>/dev/null)
  if [ "$CUR_SIZE" != "$TARGET_BYTES" ] || ! grep -q '/dev/block/zram0' /proc/swaps 2>/dev/null; then
    /system/bin/swapoff /dev/block/zram0 2>/dev/null || true
    echo 1 > /sys/block/zram0/reset 2>/dev/null || true
    echo lz4 > /sys/block/zram0/comp_algorithm 2>/dev/null || true
    echo "$TARGET_BYTES" > /sys/block/zram0/disksize
    /system/bin/mkswap /dev/block/zram0 >/dev/null 2>&1
    /system/bin/swapon -p 100 /dev/block/zram0 >/dev/null 2>&1
  fi
  echo 0 > /proc/sys/vm/page-cluster 2>/dev/null || true
  echo 80 > /proc/sys/vm/swappiness 2>/dev/null || true
fi

# 2. Disable expensive Android 14 window blurs & snappy 0.5x animations
settings put global disable_window_blurs 1 2>/dev/null || true
settings put global window_animation_scale 0.5 2>/dev/null || true
settings put global transition_animation_scale 0.5 2>/dev/null || true
settings put global animator_duration_scale 0.5 2>/dev/null || true

# 3. Kirin 710 policy0 (4x Cortex-A53, 480..1709 MHz) schedutil
P0=/sys/devices/system/cpu/cpufreq/policy0/schedutil
if [ -d "$P0" ]; then
  echo 1 > $P0/fast_ramp_up 2>/dev/null || true
  echo 0 > $P0/fast_ramp_down 2>/dev/null || true
  echo 1 > $P0/io_is_busy 2>/dev/null || true
  echo 75 > $P0/go_hispeed_load 2>/dev/null || true
  echo 1440000 > $P0/hispeed_freq 2>/dev/null || true
  echo 10000 > $P0/above_hispeed_delay 2>/dev/null || true
  echo "70 960000:75 1152000:80 1440000:85" > $P0/target_loads 2>/dev/null || true
  echo 160000 > $P0/boostpulse_duration 2>/dev/null || true
fi

# 4. Kirin 710 policy4 (4x Cortex-A73, 807..2189 MHz) schedutil - enable fast_ramp_up & cut 118ms lag
P4=/sys/devices/system/cpu/cpufreq/policy4/schedutil
if [ -d "$P4" ]; then
  echo 1 > $P4/fast_ramp_up 2>/dev/null || true
  echo 0 > $P4/fast_ramp_down 2>/dev/null || true
  echo 1 > $P4/io_is_busy 2>/dev/null || true
  echo 70 > $P4/go_hispeed_load 2>/dev/null || true
  echo 1671000 > $P4/hispeed_freq 2>/dev/null || true
  echo "10000 1671000:15000" > $P4/above_hispeed_delay 2>/dev/null || true
  echo "65 1268000:70 1671000:80 1824000:88" > $P4/target_loads 2>/dev/null || true
  echo 120000 > $P4/boostpulse_duration 2>/dev/null || true
fi

# 5. Kirin 710 Mali-G51 MP4 GPU (413..999 MHz) - animation_boost & 567MHz wake floor
G=/sys/class/devfreq/gpufreq
if [ -d "$G/mali_ondemand" ]; then
  echo 50 > $G/mali_ondemand/vsync_upthreshold 2>/dev/null || true
  echo 15 > $G/mali_ondemand/vsync_downdifferential 2>/dev/null || true
  echo 682000000 > $G/mali_ondemand/hispeed_freq 2>/dev/null || true
  echo 1 > $G/mali_ondemand/animation_boost 2>/dev/null || true
  echo 682000000 > $G/mali_ondemand/animation_boost_freq 2>/dev/null || true
fi
if [ -w "$G/min_freq" ]; then
  echo 567000000 > $G/min_freq 2>/dev/null || true
fi
