# Huawei Enjoy 9 Plus (`JKM-AL00b` / Kirin 710) — Permanent Bootloader Unlock & Android 14 (LeaOS 21.0 Google) Field Guide

**English** | [简体中文](README.zh-CN.md)

> **Target Device**: Huawei Enjoy 9 Plus (`JKM-AL00b` / `JKM-AL20`, HiSilicon Kirin 710, `arm64-v8a`, `system_a = 2392 MB`, `userdata = mmcblk0p70 / 111 GB`)  
> **Starting Firmware**: Stock EMUI `9.1.0.240(C00E235R4P3)` (Android security patch `2021-03-01`)  
> **Verified Outcome**: Permanently unlocked Bootloader + **Android 14** (`LeaOS 21.0` Google / LineageOS 21) + Iceows A14 Kirin 710 kernel + `SHRP v3.1` Recovery + working 4G LTE voice/SMS/data + Google Play & core Google apps + **Magisk v30.7**, **Kirin 710 + Mali-G51 60Hz smoothness & 2 GiB LZ4 ZRAM module (`enjoy9plus_smooth`)**, runaway `dump-logs` fix, and **wired USB ADB (`ffs.adb -12 ENOMEM`) recovery**.

---

## Table of Contents

- [1. Verified Images, Modules & Tools](#1-verified-images-modules--tools)
- [2. Phase 1: Windows 11 Drivers, ADB & USB COM 1.0 Pitfalls](#2-phase-1-windows-11-drivers-adb--usb-com-10-pitfalls)
- [3. Phase 2: Permanent Bootloader Unlock (Why SWTP Fails + Hardware Testpoint)](#3-phase-2-permanent-bootloader-unlock-why-swtp-fails--hardware-testpoint)
- [4. Phase 3: Stock Partition Backup & Flashing Android 14 (Fixing the Bootloop)](#4-phase-3-stock-partition-backup--flashing-android-14-fixing-the-bootloop)
- [5. Phase 4: First Boot, Proxy Setup, Play Store Freeze & SIM Card Hot-Plug Fix](#5-phase-4-first-boot-proxy-setup-play-store-freeze--sim-card-hot-plug-fix)
- [6. Phase 5: Post-Flash Optimization (Magisk v30.7, Kirin 710 60Hz Smoothness + 2 GiB ZRAM, `dump-logs` & Wired USB ADB Fix)](#6-phase-5-post-flash-optimization-magisk-v307-kirin-710-60hz-smoothness--2-gib-zram-dump-logs--wired-usb-adb-fix)
- [7. Phase 6: Post-Flash Windows 11 Cleanup (Re-enabling Memory Integrity)](#7-phase-6-post-flash-windows-11-cleanup-re-enabling-memory-integrity)
- [8. Troubleshooting Quick Reference](#8-troubleshooting-quick-reference)
- [9. Credits, Copyright & Upstream Attribution](#9-credits-copyright--upstream-attribution)

---

## 1. Verified Images, Modules & Tools

> **Fast Download Mirrors (GitHub Releases)**:
> - **Core ROM, Kernel, Unlock & Recovery Pack**: **[Releases (`v1.0-mirror`)](https://github.com/erha-erha/huawei-enjoy9plus-a14-flash-guide/releases/tag/v1.0-mirror)** (`Kirin-Tool v2.4.2`, `LeaOS 21.0/20.0`, `Kirin710_EMUI9.1` kernels, `SHRP v3.1 potter`, `SHA256SUMS.txt`).
> - **Root, Smoothness, ZRAM & Tools Pack (Enjoy 9 Plus / Kirin 710 ONLY)**: **[Releases (`v1.1-optimization`)](https://github.com/erha-erha/huawei-enjoy9plus-a14-flash-guide/releases/tag/v1.1-optimization)** (`enjoy9plus_smooth`, `JKM-AL00b 9.1.0.240` Magisk v30.7 recovery image, plus GPLv3/Apache-2.0 upstream mirrors).
> - **⚠️ Hardware Separation Warning**: All modules in this repo target **Huawei Enjoy 9 Plus (`JKM-AL00b` / Kirin 710 / Mali-G51 / 4 GB RAM)** ONLY. For **Honor Play (`COR-AL10` / Kirin 970 / Mali-G72 / 6 GB RAM)**, use [honor-play-a14-flash-guide](https://github.com/erha-erha/honor-play-a14-flash-guide). `enjoy9plus_smooth` verifies `ro.hardware == kirin710` inside `customize.sh` to prevent cross-flashing.

| Role | Artifact / Tool | Verified Size | Target Partition / Notes | Upstream Source & Fast Mirror |
| :--- | :--- | :--- | :--- | :--- |
| Permanent BL Unlock | `Kirin-Tool v2.4.2` | ~82.7 MB | Requires `.NET 8 Desktop Runtime` | [@kethily-daniel/Kirin-Tool](https://github.com/kethily-daniel/Kirin-Tool) \| [v1.0 Mirror](https://github.com/erha-erha/huawei-enjoy9plus-a14-flash-guide/releases/download/v1.0-mirror/Kirin-Tool-v2.4.2.zip) |
| Android 14 ROM (GApps) | `LeaOS-21.0-20260118-iceows-google-pot.img` | Compressed: `1,357,554,880` B<br>Extracted: `2,197,798,912` B (~2.05 GiB) | Flash to `system` (EROFS; fits inside `2392 MB` `system_a`) | [@Iceows SourceForge](https://sourceforge.net/projects/altairfr-huawei/files/LeaOS-21.0/LeaOS-21.0-20260118-iceows-google-pot.img.xz/download) \| [v1.0 Mirror](https://github.com/erha-erha/huawei-enjoy9plus-a14-flash-guide/releases/download/v1.0-mirror/LeaOS-21.0-20260118-iceows-google-pot.img.xz) |
| A14 Patched Kernel (Permissive) | `Kirin710_EMUI9.1_PM-2025.11.16-04_35.img` | `13,094,912` B (~12.5 MB) | Flash to `kernel` (`4.9.148+` with required Android 14 patches) | [@Iceows Kirin710 Kernel](https://github.com/Iceows/android_kernel_huawei_kirin710-9/releases) \| [v1.0 Mirror](https://github.com/erha-erha/huawei-enjoy9plus-a14-flash-guide/releases/download/v1.0-mirror/Kirin710_EMUI9.1_PM-2025.11.16-04_35.img) |
| Custom Recovery (Kirin 710 eMMC) | `SHRP_v3.1_stable-Unofficial_potter-1773176050.zip` (`recovery.img`) | `27,146,240` B (~25.9 MB) | Flash to `recovery_ramdisk` (includes Iceows patched `make_f2fs 1.13.0`) | [@Iceows SourceForge](https://sourceforge.net/projects/altairfr-huawei/files/SHRP-Recovery/SHRP_v3.1_stable-Unofficial_potter-1773176050.zip/download) \| [v1.0 Mirror (zip)](https://github.com/erha-erha/huawei-enjoy9plus-a14-flash-guide/releases/download/v1.0-mirror/SHRP_v3.1_stable-Unofficial_potter-1773176050.zip) \| [Pre-extracted `.img`](https://github.com/erha-erha/huawei-enjoy9plus-a14-flash-guide/releases/download/v1.0-mirror/SHRP_v3.1_potter-recovery.img) |
| Magisk Root (EMUI `9.1.0.240`) | `Magisk-v30.7.apk` & `JKM-AL00b_9.1.0.240_recovery_ramdisk_magisk307.img` | APK: `11.6 MB`<br>Image: `33,554,432` B | Flash patched image to `recovery_ramdisk` (**ONLY** for `JKM-AL00b 9.1.0.240`, `RECOVERYMODE=true`) | [@topjohnwu/Magisk](https://github.com/topjohnwu/Magisk/releases) \| [v1.1 APK](https://github.com/erha-erha/huawei-enjoy9plus-a14-flash-guide/releases/download/v1.1-optimization/Magisk-v30.7.apk) \| [v1.1 `.img`](https://github.com/erha-erha/huawei-enjoy9plus-a14-flash-guide/releases/download/v1.1-optimization/JKM-AL00b_9.1.0.240_recovery_ramdisk_magisk307.img) |
| 60Hz Smoothness + 2 GiB ZRAM (Kirin 710) | `enjoy9plus_smooth-v1.0.0.zip` ([source](modules/enjoy9plus_smooth/)) | `2,864` B | Flash in Magisk Manager; Kirin 710 + Mali-G51 tuning, 2 GiB LZ4 ZRAM, stops runaway `dump-logs` | [v1.1 Release](https://github.com/erha-erha/huawei-enjoy9plus-a14-flash-guide/releases/download/v1.1-optimization/enjoy9plus_smooth-v1.0.0.zip) |
| Wired USB ADB Recovery Script | `scripts/fix_wired_adb_ffs.sh` ([source](scripts/fix_wired_adb_ffs.sh)) | `1.1 KB` | Fixes Linux 4.9 `ffs.adb` `-12 (Out of memory)` USB Gadget deadlock live via Wireless ADB | In this repo |
| Open-Source Reboot Tool | `RebootNya_1.9.0.apk` | `3.01 MB` | One-tap **Soft Reboot** (`setprop ctl.restart zygote`) keeping Magisk & ZRAM alive | [@daisukiKaffuChino/RebootNya](https://github.com/daisukiKaffuChino/RebootNya/releases) \| [v1.1 Mirror](https://github.com/erha-erha/huawei-enjoy9plus-a14-flash-guide/releases/download/v1.1-optimization/RebootNya_1.9.0.apk) |
| Optional Runtime Tombstone | `LSPosed-v1.11.0-7209-zygisk-release.zip` & `Frozen8.3.0.zip` | `6.79 MB` / `3.04 MB` | iOS-style background suspension (`GLOBAL_SIGSTOP`, compatible with Linux 4.9 + A14) | [@JingMatrix/Vector](https://github.com/JingMatrix/Vector/releases) \| [@MoWei-2077/FrozenVS](https://github.com/MoWei-2077/FrozenVS) \| [v1.1 Mirrors](https://github.com/erha-erha/huawei-enjoy9plus-a14-flash-guide/releases/tag/v1.1-optimization) |
| Optional Play Integrity Modules | `PlayIntegrityFork-v19.zip`, `TEESimulator`, `TrickyAddonModule`, `KsuWebUI` | See `SHA256SUMS.txt` | GPLv3/Apache-2.0 mirrors in `v1.1`; obtain `TrickyStore` / `KeyAttestation` directly from upstream | [@osm0sis](https://github.com/osm0sis/PlayIntegrityFork) \| [@JingMatrix](https://github.com/JingMatrix/TEESimulator) \| [@KOWX712](https://github.com/KOWX712/Tricky-Addon-Update-Target-List) \| [@5ec1cff/TrickyStore](https://github.com/5ec1cff/TrickyStore) \| [@vvb2060/KeyAttestation](https://github.com/vvb2060/KeyAttestation) |
| Proxy Client (Optional) | `FlClash-0.9.4-android-arm64-v8a.apk` | `60.86 MB` | `arm64-v8a` build; supports `flclash://` deep-link import | [@chen08209/FlClash](https://github.com/chen08209/FlClash/releases) \| [v1.1 Mirror](https://github.com/erha-erha/huawei-enjoy9plus-a14-flash-guide/releases/download/v1.1-optimization/FlClash-0.9.4-android-arm64-v8a.apk) |
| Stock Rescue Backups | `stock_KERNEL.img` / `stock_RECOVERY_RAMDISK.img` | 24 MB / 32 MB | Extracted from official EMUI 9.1 `UPDATE.APP` before flashing | Stock EMUI 9.1 firmware |
| Chinese IME (Optional) | `doubaoime_v1.0.0_official.apk` | ~139.4 MB | Proprietary app — download from official CDN (not mirrored) | Official CDN |

> **⚠️ CRITICAL WARNING — DO NOT FLASH THE WRONG PREP ZIP**: `1-Huawei-DataPrep-A14-AB-v1.0-signed.zip` hosted under LeaOS-A14 on SourceForge is built for **`hi6250` (Kirin 659)**, **NOT Kirin 710**. Never flash it on `JKM-AL00b` / Kirin 710 devices.

---

## 2. Phase 1: Windows 11 Drivers, ADB & USB COM 1.0 Pitfalls

### 2.1 Windows 11 Memory Integrity (HVCI) Blocking Legacy Huawei Drivers (Code 39)
- **Symptom**: Device Manager reports Code 39 because the legacy 2016 `ew_usbccgpfilter.sys` driver is incompatible with Windows 11 **Core Isolation → Memory Integrity (HVCI)**.
- **Workaround**:
  1. Temporarily disable **Memory Integrity (HVCI)** and reboot Windows 11 only for the duration of flashing (re-enable after Phase 5 cleanup).
  2. Register local WHQL-signed Huawei INF packages (`ew_usbccgpfilter.inf`, `hw_cdcacm.inf`, `hw_quser.inf`, `hw_usbdev.inf`, `hw_goadb.inf`) via `pnputil /add-driver`.

### 2.2 `ADB Interface` Looks Healthy, Yet `adb devices` Is Empty
- **Root Cause**: Background Huawei processes (`HiSuite` and `hwtransport`) hold exclusive WinUSB handles on the ADB interface.
- **Fix**: Terminate them before invoking `adb`:
  ```powershell
  Stop-Process -Name HiSuite, hwtransport -Force -ErrorAction SilentlyContinue
  adb devices -l
  ```

### 2.3 Hardware Testpoint Shows Unknown `USB SER` (`VID_12D1&PID_3609`) Without a Driver
- **Symptom**: After shorting the motherboard testpoint, Windows detects `USB\VID_12D1&PID_3609` as an unrecognized `USB SER` device.
- **Clean Fix (No Test-Signing Mode Required)**: Bind the already WHQL-signed local `hw_quser.inf` (`HUAWEI USB COM 1.0`) directly to that device instance via Windows SetupAPI (`DiInstallDevice`). The device immediately enumerates as `HUAWEI USB COM 1.0 (COMx)`.

---

## 3. Phase 2: Permanent Bootloader Unlock (Why SWTP Fails + Hardware Testpoint)

### 3.1 Why Software Testpoint (SWTP) Fails on `2021-03-01` Patch
- Stock firmware `JKM-AL00b 9.1.0.240` ships with `ro.huawei.build.version.security_patch=2021-03-01`, which is past Huawei's February 2021 SWTP patch cutoff.
- Attempting SWTP reliably fails with `Failed to send partition header`. Skip SWTP and go straight to **Hardware Testpoint** (`HUAWEI USB COM 1.0`).

### 3.2 `Kirin-Tool v2.4.2` Runtime & Working-Directory Gotchas
- Install **`.NET 8 Desktop Runtime`** (`winget install Microsoft.DotNet.DesktopRuntime.8`).
- **Working-Directory Permission Bug**: Launching `Kirin-Tool.exe` from another CWD causes `Access to path ...\dload is denied`, and some non-interactive shells hit `0xc0000142`.
- **Reliable Launch**: Create a Windows shortcut (`.lnk`) whose **`WorkingDirectory` ("Start in")** points explicitly to the `Kirin-Tool` folder, then run the unlock flow from there.

### 3.3 Verifying Permanent Unlock & Reassembling the Back Cover
1. **Verify in Fastboot**:
   ```powershell
   fastboot oem get-bootinfo
   # Expected: unlocked / USER LockState: UNLOCKED
   ```
2. **Verify inside booted Android**:
   ```powershell
   adb shell "getprop | grep -iE 'flash\.locked|verifiedbootstate|vbmeta_state'"
   # ro.boot.flash.locked = 0
   # ro.boot.verifiedbootstate = orange
   # ro.keymaster.xxx.vbmeta_state = unlocked
   ```
3. **Persistence & Reassembly Notes**:
   - The unlock written by `Kirin-Tool` persists across cold reboots, factory wipes, SHRP sessions, and ROM swaps.
   - **What WILL re-lock it**: Manually running `fastboot oem relock` or force-flashing a full stock EMUI `dload` firmware package.
   - Before snapping the back cover shut, check that no debris remains near the testpoint pads and that the **rear fingerprint flex cable** is firmly seated.

---

## 4. Phase 3: Stock Partition Backup & Flashing Android 14 (Fixing the Bootloop)

### 4.1 Always Back Up Stock Kernel & Recovery First
Extract and keep safe copies from your stock EMUI 9.1 `UPDATE.APP`:
- `stock_KERNEL.img`
- `stock_RECOVERY_RAMDISK.img`

Before flashing any custom kernel, verify that its image header, offsets, and `cmdline` match `stock_KERNEL.img`.

### 4.2 Fastboot Flash Sequence
```powershell
# 1. Flash Android 14 Google system image (LeaOS 21.0 EROFS, ~5 sparse chunks, ~68s)
fastboot flash system LeaOS-21.0-20260118-iceows-google-pot.img

# 2. Flash Iceows Kirin 710 EMUI 9.1 Android 14 kernel (Permissive)
fastboot flash kernel Kirin710_EMUI9.1_PM-2025.11.16-04_35.img

# 3. Flash SHRP v3.1 Recovery
fastboot flash recovery_ramdisk recovery.img
```

### 4.3 Root-Cause Analysis: Infinite LineageOS 3-Circle Bootloop
Two separate issues combined to cause an endless bootloop on the 3-circle LineageOS boot animation:

1. **Cause #1 — Stock EMUI 9.1 Kernel Lacks Android 14 Patches (Kirin 710)**:
   - The stock Kirin 710 `4.9.148` kernel lacks Android 14 `LOOP_CONFIGURE` / loop-device and mount patches.
   - **Fix**: Flash `Kirin710_EMUI9.1_PM-2025.11.16-04_35.img` to `kernel`.
2. **Cause #2 — Stock EMUI 9.1 Recovery F2FS Superblock CRC Mismatch (Universal Cross-Device EMUI 9.1 Trap!)**:
   - Formatting `/data` with **stock EMUI 9.1 Recovery** enables Huawei's newer/proprietary F2FS superblock checksum & feature bits (`superblock features = 481: encrypt verity quota_ino`).
   - Meanwhile, **unpatched upstream `f2fs-tools` / generic TWRP** also fails on Huawei EMUI 9.1 `4.9` kernels because upstream `mkfs.f2fs` enables `CP_NAT_BITS_FLAG` (NAT bitmap checkpoint pages), which Huawei's EMUI 9.1 F2FS kernel driver does not support (Iceows specifically strips this via `0001-mkfs.f2fs-Remove-NAT-Bitmap-to-support-Huawei-EMUI9-.patch`).
   - On boot, `/system` (EROFS) still mounts and launches `init` + `surfaceflinger` + the 3-circle boot animation, **but the kernel rejects `/data` (`userdata`)**:
     ```text
     F2FS-fs (mmcblk0p70): Invalid checksum crc(0x...)
     F2FS-fs (mmcblk0p70): Can't find valid F2FS filesystem in 1th/2th superblock
     ```
     `mount_all` fails → `/data` never mounts → `credstore` (`chdir: /data/misc/credstore: No such file or directory`) and `tombstoned` (`failed to open directory: /data/tombstones`, fatal signal 6) crash in an infinite loop → stuck on the 3-circle boot animation forever.

> **⚠️ Cross-Device Warning (Same Failure Pattern on Other Huawei/Honor EMUI 9.1 Devices — Verified on Kirin 970)**:
> This exact 3-circle boot hang is **NOT unique to Enjoy 9 Plus (`JKM-AL00b` / Kirin 710)** — it is a **general Huawei EMUI 9.1 F2FS formatting trap** that reproduces identically on other Kirin SoCs when flashing `LeaOS 21.0` (`iceows-google-pot.img`) and wiping data via stock EMUI 9.1 Recovery.
>
> | Comparison | Enjoy 9 Plus (`JKM-AL00b` / Kirin 710) | Honor Play (`COR-AL10` / Kirin 970) |
> | :--- | :--- | :--- |
> | **Storage / `userdata` node** | eMMC (`/dev/block/mmcblk0p70`, ~111 GB) | UFS (`/dev/block/sdd66`, ~112 GB) |
> | **Failure after stock Recovery wipe** | `F2FS-fs (mmcblk0p70): Invalid checksum crc` → `credstore` crash → 3-circle hang | `F2FS-fs (sdd66): Invalid checksum crc(0x100b1449)` → `credstore` / `tombstoned` crash → 3-circle hang |
> | **ROM compatibility (`LeaOS-21.0-*-google-pot.img` EROFS)** | Mounts cleanly | Mounts cleanly (`rc=0`, reads compressed `framework.jar` with zero EROFS errors) |
> | **Required Recovery (Iceows `make_f2fs`)** | `SHRP v3.1 potter` (`make_f2fs 1.13.0`) | `SHRP-Reborn v3.2 charlotte` (`make_f2fs 1.14.0`, Kirin 970 UFS) |
> | **Kernel requirement** | Required Iceows patched `Kirin710_EMUI9.1_PM` kernel + F2FS fix | Booted in **90s** on stock `9.1.0.350` `4.9.148` kernel (with 212-byte SELinux-unlock patch, Enforcing at boot) after F2FS fix alone |
>
> **Takeaway for any Huawei/Honor EMUI 9.1 device**: Never rely on stock EMUI 9.1 Recovery's Factory Reset alone when moving to Android 14 (`LeaOS 21.0`). Always use an Iceows-built SHRP matching your SoC/storage family (`potter` for Kirin 710 eMMC, `charlotte` for Kirin 970 UFS), format `userdata` with Iceows's patched `/system/bin/make_f2fs -f -O encrypt -w 4096 /dev/block/by-name/userdata` (**do NOT copy another model's sector count verbatim**), and verify `mount -t f2fs` succeeds before rebooting.

### 4.4 Proper `/data` Format Inside SHRP Recovery
1. Boot into **SHRP Recovery**. When asked `Keep System Read Only?`, **keep it read-only** (do not modify the EROFS `system` partition).
2. Over `adb shell` in SHRP, format `userdata` using Iceows' custom `/system/bin/make_f2fs` (`Ver Iceows (Huawei EMUI9): 1.13.0`), verify direct kernel mount, wipe `/cache`, and reboot:
   ```sh
   # Format userdata with -O encrypt (without the conflicting checksum / NAT-bitmap feature bits)
   # Note: 233340896 is specific to Enjoy 9 Plus (JKM-AL00b). On other EMUI 9.1 devices
   # (e.g., Honor Play COR-AL10), omit the sector count so make_f2fs auto-sizes the partition.
   /system/bin/make_f2fs -f -O encrypt -w 4096 /dev/block/by-name/userdata 233340896

   # Verify clean F2FS mount before rebooting (must return 0 and show ~111G)
   mount -t f2fs /dev/block/by-name/userdata /data && df -h /data && umount /data

   # Clear /cache and reboot into Android 14
   rm -rf /cache/*
   reboot
   ```
3. The device boots cleanly into Android 14 (`POT-LX1` / `HWPOT`, kernel `4.9.148+ aarch64`).

---

## 5. Phase 4: First Boot, Proxy Setup, Play Store Freeze & SIM Card Hot-Plug Fix

### 5.1 Bypassing Google SetupWizard Without Unrestricted Internet
- On first boot with GApps inside a restricted network environment, SetupWizard hangs indefinitely on *"Getting your phone ready..."*.
- Complete SetupWizard **offline** (skip Wi-Fi) to reach the launcher, install your proxy tool via ADB, and sign into Google afterward.

### 5.2 Sideloading Apps & Deep-Link Config Import via ADB
- `LeaOS 21.0` enables `WITH_ADB_INSECURE=true`, so ADB works immediately after boot:
  ```powershell
  adb install -r FlClash-0.9.4-android-arm64-v8a.apk
  adb install -r doubaoime_official.apk
  ```
- Push a URL-encoded Clash subscription directly to FlClash without manually typing a long URL:
  ```powershell
  adb shell am start -a android.intent.action.VIEW `
    -d "flclash://install-config?url=<URL_ENCODED_SUBSCRIPTION_URL>" `
    -n com.follow.clash/.MainActivity
  ```
- Confirm VPN validation from the shell:
  ```powershell
  adb shell "dumpsys connectivity | grep -E 'Vpn|tun0|VALIDATED'"
  ```

### 5.3 Play Store "Install" Button Completely Unresponsive on Google Chrome
- **Symptom**: Play Store searches normally and even installs other apps (e.g., Firefox), yet tapping **Install** on Google Chrome does nothing.
- **Root Cause (`uiautomator dump` + `dumpsys activity top`)**:
  - Right after initial sign-in, Google Play Store and Google Play Services silently self-update in the background (e.g., Play Store `36.6.25 → 54.4.11`, GMS `23.25.18 → 26.45.31`).
  - Tapping Install during that transition leaves `com.google.android.finsky.billing.acquire.SheetUiBuilderHostActivity` stuck in an `INVISIBLE` loading state, acting as a **full-screen transparent glass wall** intercepting all touches.
- **Fix**: Force-stop and reopen Play Store:
  ```powershell
  adb shell am force-stop com.android.vending
  ```
  Chrome (along with its `TrichromeLibrary` dependency), Gmail, YouTube, Maps, Photos, Drive, and Translate all install cleanly immediately afterward.

### 5.4 SIM Card Not Detected After Hot-Plugging (`ABSENT` / `+CME ERROR: 10`)
- **Symptom**: Booting first with an empty tray and later inserting a SIM card while Android is running leaves both slots stuck at `gsm.sim.state=ABSENT,ABSENT`. Even toggling Airplane Mode yields `+CME ERROR: 10` (`SIM not inserted`) directly from the Balong modem.
- **Root Cause (`dmesg` + `logcat -b radio` + `/odm/phone.prop`)**:
  - Stock vendor configuration sets `ro.odm.pwroff_card_if_tray_out=true`, so ejecting the tray powers down the SIM slot inside the Balong baseband (`SIM_CARD_OUT`).
  - Re-inserting the tray fires the kernel hotplug interrupt (`mod_simhotplug`: `SIM_CARD_IN` → `bsp_icc_send to CP`), **but AOSP/LeaOS lacks EMUI's proprietary `HwUiccController`**, which normally sends `AT^HVSST=1,1` to re-energize the SIM slot after hot-plug. The slot therefore stays powered off.
- **Fix & Permanence Boundaries**:
  - **Daily use & normal power cycles (permanently stable)**: Simply **reboot the phone with the SIM card inserted**. During boot initialization, the Balong modem powers up and initializes the USIM (`+CPIN: READY`, `^CARDMODE:2`), bringing up 4G LTE voice, SMS, and mobile data (`rmnet0`) reliably across every subsequent reboot.
  - **Swapping SIM cards (no hot-plug support)**: Hot-swapping SIM cards while powered on is not supported on this AOSP/LeaOS + EMUI 9.1 Balong vendor stack. Always **power off before swapping SIMs**, or **reboot once after inserting the SIM tray**.
- **Avoid toggling `persist.sys.phh.monosim` unnecessarily**: Flipping the Mono-SIM toggle in Phh Treble Settings overwrites `/odm/phone.prop` vendor defaults (`persist.radio.modem.cap=09B9D52`, `ro.odm.multi.rild=false`) with generic values (`09A9D`, `ro.odm.multi.rild=true`). If you ever experience Dual-SIM issues after toggling it, clear the persisted override and reboot:
  ```sh
  adb root
  adb shell "resetprop_phh -p --delete persist.sys.phh.monosim && setprop persist.radio.modem.cap 09B9D52"
  adb reboot
  ```

---

## 6. Phase 5: Post-Flash Optimization (Magisk v30.7, Kirin 710 60Hz Smoothness + 2 GiB ZRAM, `dump-logs` & Wired USB ADB Fix)

### 6.1 Magisk v30.7 (`recovery_ramdisk`) & Zero-Button Daily Restarts (`RebootNya`)
- On EMUI 9.1, Magisk patches `recovery_ramdisk` with `RECOVERYMODE=true` (flash `JKM-AL00b_9.1.0.240_recovery_ramdisk_magisk307.img` **only** on `JKM-AL00b 9.1.0.240`, or patch your own stock `recovery_ramdisk.img` in `Magisk-v30.7.apk`).
- **Cold-booting with Magisk**: Unplug USB → power off → hold **Volume Up + Power** until the unlocked warning screen appears → keep holding **Volume Up** until **`Your device is booting now...`** appears (~5s), then release immediately.
- **Daily Zero-Button Restarts**: Install [`RebootNya_1.9.0.apk`](https://github.com/daisukiKaffuChino/RebootNya) and use **Soft Reboot** (`setprop ctl.restart zygote`) whenever reloading modules or system tweaks — completes in ~6–10 seconds with zero cable unplugging and keeps Magisk + ZRAM intact.

### 6.2 Kirin 710 + Mali-G51 60Hz Smoothness, 2 GiB LZ4 ZRAM & Stopping Runaway `dump-logs` (`enjoy9plus_smooth`)
- **Hardware Baseline**: Enjoy 9 Plus (`JKM-AL00b` / `POT-LX1`) has a `60.00 Hz` LCD, Kirin 710 (`4×A53 @ 1.71 GHz + 4×A73 @ 2.19 GHz`, Huawei `schedutil`), Mali-G51 MP4 (`mali_ondemand`, `413–999 MHz`), and `4 GB` RAM (`3.6 GiB` usable, eMMC 5.1).
- Out of the box on `LeaOS 21.0`, **home screen (`Launcher3`) scrolling measured only ~19 FPS (`53 ms` median, `54.6%` janky frames, `26` missed VSyncs)** due to 5 verified bottlenecks fixed in [`enjoy9plus_smooth-v1.0.0.zip`](https://github.com/erha-erha/huawei-enjoy9plus-a14-flash-guide/releases/download/v1.1-optimization/enjoy9plus_smooth-v1.0.0.zip) ([source](modules/enjoy9plus_smooth/)):
  1. **Broken `LeaOS` `/system/build.prop` HWUI/EGL Flags**: Overrode `hwui.disable_vsync=false`, `debug.hwui.use_buffer_age=true`, `debug.egl.profiler=0`, `debug.hwui.profile=false` via Magisk `system.prop` **while preserving Huawei HWC 2.2's `debug.sf.disable_backpressure=1` & `debug.sf.latch_unsignaled=1`** (note: requires a full Magisk boot or `setprop ctl.restart surfaceflinger` so `zygote` reloads `libhwui` cleanly!).
  2. **Runaway `dump-logs` Service Burning 100% CPU + Hammering eMMC Flash**: `/system/etc/init/debug-log-gsi.rc` runs `logcat -b all -f /splash2/logcat-normal.txt -v threadtime` in a restart loop, saturating a CPU core and writing tens of MBs to `/splash2`. Stopped automatically at boot (`setprop ctl.stop dump-logs`).
  3. **Kirin 710 `schedutil` Big-Core Lag**: Enabled `fast_ramp_up=1` (was `0`), disabled `fast_ramp_down=0`, set `io_is_busy=1`, raised `hispeed_freq` to `1671 MHz` (`policy4`) / `1440 MHz` (`policy0`), and cut big-core ramp delay from `118 ms` to `10–15 ms`.
  4. **Mali-G51 `mali_ondemand` Tuning**: Enabled `animation_boost=1`, `hispeed_freq=682 MHz`, `vsync_upthreshold=50`, and raised wake floor from `413 MHz` to `567 MHz` (measured SoC temp `25.4℃`).
  5. **2 GiB LZ4 ZRAM + Disable Window Blurs**: Auto-enables `2 GiB` LZ4 ZRAM (`2,147,483,648` B, `swapon -p 100`, `vm.page-cluster=0`, `vm.swappiness=80`) to eliminate 4 GB RAM thrashing, disables GPU window blurs (`disable_window_blurs=1`), and sets `0.5x` animation scales.
  - *(Optional)* You can also pair `LSPosed v1.11.0` + `Frozen 8.3.0` (`GLOBAL_SIGSTOP` mode) for iOS-style background app suspension (see Phase 6.3 of [honor-play-a14-flash-guide](https://github.com/erha-erha/honor-play-a14-flash-guide#73-true-ios-style-runtime-tombstone-lsposed-v1110--frozen-830-on-android-14--linux-49)).

| Measured Metric (`dumpsys gfxinfo`, 60Hz) | Before Tuning | After `enjoy9plus_smooth` |
| :--- | :--- | :--- |
| Launcher3 Jank / Missed VSyncs | `54.6%` / `26` missed | **`8.9%–10.6%` / `0–2` missed** |
| Launcher3 Median Frame / `DequeueBuffer` | `53 ms` / `25–30 ms` | **`18–26 ms` / `0.04 ms`** |
| Settings Median Frame / Jank | `15 ms` (Legacy `35.2%`) | **`15–16 ms` (`0.8%–1.6%`, `0` missed)** |
| Runaway `dump-logs` CPU Usage | `100%` (1 full core) | **`0%` (`stopped`)** |

### 6.3 Root-Cause Fix: Wired USB Debugging Vanishes (`ffs.adb` `-12 Out of memory` Deadlock)
- **Symptom**: Phone shows charging over USB (`power_supply/USB/type=USB`), yet Windows Device Manager sees no Huawei/ADB device at all even across different USB ports — while Wireless Debugging works fine.
- **Root Cause (`dmesg` + `/config/usb_gadget/g1`)**:
  - Binding pure `mtp.gs0` immediately enumerates `USB\VID_12D1&PID_107E` at `high-speed`, proving the cable and PC port are healthy.
  - `persist.sys.usb.config` was stuck on Huawei factory `manufacture,adb`, and Linux `4.9`'s `ffs.adb` FunctionFS instance entered a corrupted state after long uptime/replugs, looping every second:
    ```text
    configfs_composite_bind:use_os_desc 0
    configfs-gadget ff100000.dwc3: failed to start g1: -12
    Unable to write to file '/config/usb_gadget/g1/UDC': Out of memory
    ```
- **Live Zero-Reboot Fix** (connect via Wireless ADB and run [`scripts/fix_wired_adb_ffs.sh`](scripts/fix_wired_adb_ffs.sh) detached via `setsid` so stopping `adbd` does not kill the script mid-run):
  ```powershell
  adb -s <IP:PORT> push scripts/fix_wired_adb_ffs.sh /data/local/tmp/
  adb -s <IP:PORT> shell "su -c 'setsid sh /data/local/tmp/fix_wired_adb_ffs.sh </dev/null >/data/local/tmp/usb_fix.log 2>&1 &'"
  ```
  It cleanly unbinds `UDC`, unmounts `/dev/usb-ffs/adb`, recreates `/config/usb_gadget/g1/functions/ffs.adb`, remounts `functionfs` (`uid=2000,gid=2000`), sets `persist.sys.usb.config=adb`, and rebinds `ff100000.dwc3` → Windows immediately enumerates `USB\VID_12D1&PID_103A` (`high-speed / CONFIGURED`).

---

## 7. Phase 6: Post-Flash Windows 11 Cleanup (Re-enabling Memory Integrity)

Once flashing and USB debugging are finished, remove the legacy 2016 Huawei kernel drivers so you can safely re-enable Windows 11 **Memory Integrity (HVCI)**:

1. Find all installed Huawei OEM driver packages (`oemXX.inf`):
   ```powershell
   pnputil /enum-drivers | Select-String -Context 2,3 "huawei|ew_usbccgpfilter|hw_cdc|hw_qu"
   ```
2. From an **elevated Administrator PowerShell**, uninstall each incompatible driver package (`ew_usbccgpfilter.inf`, `hw_cdcacm.inf`, `hw_quser.inf`, `hw_usbdev.inf`, `hw_cdcmdm.inf`, `hw_qumdm.inf`, `hw_quusbnet.inf`):
   ```powershell
   pnputil /delete-driver oemXX.inf /uninstall /force
   ```
3. Open **Windows Security → Device Security → Core Isolation**, turn **Memory Integrity** back ON, and reboot Windows.

---

## 8. Troubleshooting Quick Reference

| Symptom / Error | Verified Root Cause | Solution |
| :--- | :--- | :--- |
| Device Manager Code 39 on Huawei USB drivers | Win11 Memory Integrity (HVCI) blocks legacy `ew_usbccgpfilter.sys` | Temporarily disable HVCI during flashing; remove legacy drivers via `pnputil` and re-enable HVCI afterward |
| `ADB Interface` OK, `adb devices` empty | `HiSuite` / `hwtransport` holds exclusive WinUSB handle | `Stop-Process -Name HiSuite,hwtransport -Force` |
| Hardware testpoint shows unknown `USB SER` (`VID_12D1&PID_3609`) | Windows doesn't auto-match `HUAWEI USB COM 1.0` | Bind WHQL-signed `hw_quser.inf` via SetupAPI `DiInstallDevice` (no test-signing needed) |
| SWTP fails with `Failed to send partition header` | EMUI 9.1 `2021-03-01` security patch blocks SWTP | Use Hardware Testpoint + `Kirin-Tool v2.4.2` |
| `Kirin-Tool` throws `Access to path ...\dload is denied` | Process CWD is outside the `Kirin-Tool` directory | Launch via `.lnk` shortcut with `WorkingDirectory` set to the `Kirin-Tool` folder |
| Infinite LineageOS 3-circle bootloop after flashing A14 (also reproduces on Kirin 970 / Honor Play) | Stock EMUI 9.1 Recovery F2FS superblock CRC conflict (`Invalid checksum crc` → `/data` unmounted → `credstore` crash), plus on Kirin 710 missing A14 kernel `LOOP_CONFIGURE` patches | Flash matching Iceows SHRP (`potter` for Kirin 710 eMMC, `charlotte` for Kirin 970 UFS), reformat `userdata` with Iceows `/system/bin/make_f2fs -f -O encrypt -w 4096`, verify `mount -t f2fs`; on Kirin 710 also flash Iceows A14 kernel |
| Downloaded `1-Huawei-DataPrep-A14-AB-v1.0-signed.zip` | Built for `hi6250` (Kirin 659), NOT Kirin 710 | **Do NOT flash** on Kirin 710 |
| SetupWizard stuck on *"Getting your phone ready..."* | Restricted internet prevents Google check-in | Finish SetupWizard offline, install proxy via ADB, then sign in |
| Tapping **Install** on Chrome in Play Store does nothing | Invisible `SheetUiBuilderHostActivity` stuck during background Play Store/GMS self-update | Force-stop Play Store (`adb shell am force-stop com.android.vending`) and reopen |
| SIM card shows `ABSENT` / `+CME ERROR: 10` after hot-plug | Tray eject powers off SIM (`ro.odm.pwroff_card_if_tray_out=true`); AOSP lacks EMUI's `AT^HVSST=1,1` re-power flow | **Reboot with the SIM card inserted** (power off or reboot whenever swapping SIMs) |
| Home screen sluggish (~19 FPS) & 100% CPU `logcat-normal.txt` | LeaOS `hwui.disable_vsync=true` / `use_buffer_age=false`, conservative Kirin 710 `schedutil` (`fast_ramp_up=0`), runaway `dump-logs`, and 0 Swap on 4 GB RAM | Flash `enjoy9plus_smooth-v1.0.0.zip` in Magisk and reboot (or `ctl.restart surfaceflinger`) |
| Wired USB only charges; PC sees no ADB (`failed to start g1: -12`) | Linux 4.9 `ffs.adb` FunctionFS state corrupted (`-ENOMEM` on `UDC` bind) + `persist.sys.usb.config=manufacture,adb` | Run [`scripts/fix_wired_adb_ffs.sh`](scripts/fix_wired_adb_ffs.sh) detached via `setsid` over Wireless ADB |

---

## 9. Credits, Copyright & Upstream Attribution

All third-party open-source files mirrored in GitHub Releases are **unmodified official upstream builds** provided strictly for community download convenience with full credit to their original authors and licenses. Repositories without an explicit redistribution license (e.g., `TrickyStore`, `KeyAttestation`) and proprietary apps (`doubaoime`) are linked directly to their upstream sources instead of being mirrored.

| Project / Component | Original Author(s) | Upstream Repository / Link | License |
| :--- | :--- | :--- | :--- |
| **LeaOS 21.0 / 20.0**, **Kirin 710 A14 Kernel** & **EMUI 9 F2FS `make_f2fs` Patch** | **[@Iceows](https://github.com/Iceows)** (AltairFR) | [Iceows/huawei-creator](https://github.com/Iceows/huawei-creator) \| [Iceows/android_kernel_huawei_kirin710-9](https://github.com/Iceows/android_kernel_huawei_kirin710-9) \| [SourceForge](https://sourceforge.net/projects/altairfr-huawei/) | Open Source (LineageOS / GPL / Apache-2.0) |
| **Kirin-Tool v2.4.2** | **[@kethily-daniel](https://github.com/kethily-daniel)** | [kethily-daniel/Kirin-Tool](https://github.com/kethily-daniel/Kirin-Tool) | Open Source |
| **SHRP v3.1 (`potter`)** | **Team SHRP** & **[@Iceows](https://github.com/Iceows)** | [SHRP-Reborn](https://github.com/SHRP-Reborn) \| [SourceForge](https://sourceforge.net/projects/altairfr-huawei/files/SHRP-Recovery/) | GPL-3.0 |
| **Magisk v30.7** | **[@topjohnwu](https://github.com/topjohnwu)** | [topjohnwu/Magisk](https://github.com/topjohnwu/Magisk) | GPL-3.0 |
| **RebootNya v1.9.0** | **[@daisukiKaffuChino](https://github.com/daisukiKaffuChino)** | [daisukiKaffuChino/RebootNya](https://github.com/daisukiKaffuChino/RebootNya) | Apache-2.0 |
| **LSPosed v1.11.0 (Zygisk)** & **TEESimulator** | **[@JingMatrix](https://github.com/JingMatrix)** & Contributors | [JingMatrix/Vector](https://github.com/JingMatrix/Vector) \| [JingMatrix/TEESimulator](https://github.com/JingMatrix/TEESimulator) | GPL-3.0 |
| **Frozen 8.3.0 (Optional Tombstone)** | **[@MoWei-2077](https://github.com/MoWei-2077)** (forked from **[@jark006](https://github.com/jark006)**) | [MoWei-2077/FrozenVS](https://github.com/MoWei-2077/FrozenVS) \| [jark006/freezeitVS](https://github.com/jark006/freezeitVS) | GPL-3.0 |
| **PlayIntegrityFork** | **[@osm0sis](https://github.com/osm0sis)** | [osm0sis/PlayIntegrityFork](https://github.com/osm0sis/PlayIntegrityFork) | GPL-3.0 |
| **TrickyStore** & **KsuWebUIStandalone** | **[@5ec1cff](https://github.com/5ec1cff)** | [5ec1cff/TrickyStore](https://github.com/5ec1cff/TrickyStore) \| [5ec1cff/KsuWebUIStandalone](https://github.com/5ec1cff/KsuWebUIStandalone) | Upstream / GPL-3.0 |
| **Tricky-Addon-Update-Target-List** | **[@KOWX712](https://github.com/KOWX712)** | [KOWX712/Tricky-Addon-Update-Target-List](https://github.com/KOWX712/Tricky-Addon-Update-Target-List) | Apache-2.0 |
| **KeyAttestation** | **[@vvb2060](https://github.com/vvb2060)** | [vvb2060/KeyAttestation](https://github.com/vvb2060/KeyAttestation) | Upstream |
| **FlClash v0.9.4** | **[@chen08209](https://github.com/chen08209)** | [chen08209/FlClash](https://github.com/chen08209/FlClash) | GPL-3.0 |
| **Sibling Guide (Honor Play / Kirin 970)** | **[@erha-erha](https://github.com/erha-erha)** | [erha-erha/honor-play-a14-flash-guide](https://github.com/erha-erha/honor-play-a14-flash-guide) | Open Source |
