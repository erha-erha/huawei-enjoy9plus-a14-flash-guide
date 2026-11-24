# Huawei Enjoy 9 Plus (`JKM-AL00b` / Kirin 710) — Permanent Bootloader Unlock & Android 14 (LeaOS 21.0 Google) Field Guide

**English** | [简体中文](README.zh-CN.md)

> **Target Device**: Huawei Enjoy 9 Plus (`JKM-AL00b` / `JKM-AL20`, HiSilicon Kirin 710, `arm64-v8a`, `system_a = 2392 MB`, `userdata = mmcblk0p70 / 111 GB`)  
> **Starting Firmware**: Stock EMUI `9.1.0.240(C00E235R4P3)` (Android security patch `2021-03-01`)  
> **Verified Outcome**: Permanently unlocked Bootloader + **Android 14** (`LeaOS 21.0` Google / LineageOS 21) + Iceows A14 Kirin 710 kernel + `SHRP v3.1` Recovery + working 4G LTE voice/SMS/data + Google Play & core Google apps (Chrome, Gmail, YouTube, Maps, Photos, Drive, Translate).

---

## Table of Contents

- [1. Verified Images & Tools](#1-verified-images--tools)
- [2. Phase 1: Windows 11 Drivers, ADB & USB COM 1.0 Pitfalls](#2-phase-1-windows-11-drivers-adb--usb-com-10-pitfalls)
- [3. Phase 2: Permanent Bootloader Unlock (Why SWTP Fails + Hardware Testpoint)](#3-phase-2-permanent-bootloader-unlock-why-swtp-fails--hardware-testpoint)
- [4. Phase 3: Stock Partition Backup & Flashing Android 14 (Fixing the Bootloop)](#4-phase-3-stock-partition-backup--flashing-android-14-fixing-the-bootloop)
- [5. Phase 4: First Boot, Proxy Setup, Play Store Freeze & SIM Card Hot-Plug Fix](#5-phase-4-first-boot-proxy-setup-play-store-freeze--sim-card-hot-plug-fix)
- [6. Phase 5: Post-Flash Windows 11 Cleanup (Re-enabling Memory Integrity)](#6-phase-5-post-flash-windows-11-cleanup-re-enabling-memory-integrity)
- [7. Troubleshooting Quick Reference](#7-troubleshooting-quick-reference)

---

## 1. Verified Images & Tools

| Role | Artifact / Tool | Verified Size | Target Partition / Notes | Public Source |
| :--- | :--- | :--- | :--- | :--- |
| Permanent BL Unlock | `Kirin-Tool v2.4.2` | ~82.7 MB | Requires `.NET 8 Desktop Runtime` | [kethily-daniel/Kirin-Tool](https://github.com/kethily-daniel/Kirin-Tool) |
| Android 14 ROM (GApps) | `LeaOS-21.0-20260118-iceows-google-pot.img` | `2,197,798,912` B (~2.05 GB) | Flash to `system` (EROFS; fits inside `2392 MB` `system_a`) | [SourceForge: altairfr-huawei / LeaOS-21.0](https://sourceforge.net/projects/altairfr-huawei/files/LeaOS-21.0/LeaOS-21.0-20260118-iceows-google-pot.img.xz/download) |
| A14 Patched Kernel (Permissive) | `Kirin710_EMUI9.1_PM-2025.11.16-04_35.img` | `13,094,912` B (~12.5 MB) | Flash to `kernel` (`4.9.148+` with required Android 14 patches) | [Iceows/android_kernel_huawei_kirin710-9](https://github.com/Iceows/android_kernel_huawei_kirin710-9/releases) |
| Custom Recovery | `SHRP_v3.1_stable-Unofficial_potter-1773176050.zip` (`recovery.img`) | `27,146,240` B (~25.9 MB) | Flash to `recovery_ramdisk` (includes Iceows patched `make_f2fs`) | [SourceForge: altairfr-huawei / SHRP-Recovery](https://sourceforge.net/projects/altairfr-huawei/files/SHRP-Recovery/SHRP_v3.1_stable-Unofficial_potter-1773176050.zip/download) |
| Stock Rescue Backups | `stock_KERNEL.img` / `stock_RECOVERY_RAMDISK.img` | 24 MB / 32 MB | Extracted from official EMUI 9.1 `UPDATE.APP` before flashing | Stock EMUI 9.1 firmware |
| Proxy Client (Optional) | `FlClash-0.9.4-android-arm64-v8a.apk` | ~58.0 MB | `arm64-v8a` build; supports `flclash://` deep-link import | [chen08209/FlClash](https://github.com/chen08209/FlClash/releases) |
| Chinese IME (Optional) | `doubaoime_v1.0.0_official.apk` | ~139.4 MB | Official ByteDance CDN release | Official CDN |

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

1. **Cause #1 — Stock EMUI 9.1 Kernel Lacks Android 14 Patches**:
   - The stock `4.9.148` kernel lacks Android 14 `LOOP_CONFIGURE` / loop-device and mount patches.
   - **Fix**: Flash `Kirin710_EMUI9.1_PM-2025.11.16-04_35.img` to `kernel`.
2. **Cause #2 — Stock EMUI 9.1 Recovery F2FS Superblock CRC Mismatch (Subtle!)**:
   - Formatting `/data` with **stock EMUI 9.1 Recovery** enables newer F2FS superblock checksum features (`superblock features = 481: encrypt verity quota_ino`).
   - On boot, the kernel fails to mount `/dev/block/mmcblk0p70`:
     ```text
     F2FS-fs (mmcblk0p70): Invalid checksum crc(0x...)
     ```
     `mount_all` fails → `/data` never mounts → `credstore` crashes in an infinite loop → stuck on the boot animation forever.

### 4.4 Proper `/data` Format Inside SHRP Recovery
1. Boot into **SHRP Recovery**. When asked `Keep System Read Only?`, **keep it read-only** (do not modify the EROFS `system` partition).
2. Over `adb shell` in SHRP, format `userdata` using Iceows' custom `/system/bin/make_f2fs` (`Ver Iceows (Huawei EMUI9): 1.13.0`), verify direct kernel mount, wipe `/cache`, and reboot:
   ```sh
   # Format userdata with -O encrypt (without the conflicting checksum feature bits)
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

## 6. Phase 5: Post-Flash Windows 11 Cleanup (Re-enabling Memory Integrity)

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

## 7. Troubleshooting Quick Reference

| Symptom / Error | Verified Root Cause | Solution |
| :--- | :--- | :--- |
| Device Manager Code 39 on Huawei USB drivers | Win11 Memory Integrity (HVCI) blocks legacy `ew_usbccgpfilter.sys` | Temporarily disable HVCI during flashing; remove legacy drivers via `pnputil` and re-enable HVCI afterward |
| `ADB Interface` OK, `adb devices` empty | `HiSuite` / `hwtransport` holds exclusive WinUSB handle | `Stop-Process -Name HiSuite,hwtransport -Force` |
| Hardware testpoint shows unknown `USB SER` (`VID_12D1&PID_3609`) | Windows doesn't auto-match `HUAWEI USB COM 1.0` | Bind WHQL-signed `hw_quser.inf` via SetupAPI `DiInstallDevice` (no test-signing needed) |
| SWTP fails with `Failed to send partition header` | EMUI 9.1 `2021-03-01` security patch blocks SWTP | Use Hardware Testpoint + `Kirin-Tool v2.4.2` |
| `Kirin-Tool` throws `Access to path ...\dload is denied` | Process CWD is outside the `Kirin-Tool` directory | Launch via `.lnk` shortcut with `WorkingDirectory` set to the `Kirin-Tool` folder |
| Infinite LineageOS 3-circle bootloop after flashing A14 | Stock kernel missing A14 patches + stock Recovery F2FS superblock CRC conflict | Flash Iceows A14 kernel + SHRP; format `userdata` in SHRP with `/system/bin/make_f2fs -f -O encrypt -w 4096` |
| Downloaded `1-Huawei-DataPrep-A14-AB-v1.0-signed.zip` | Built for `hi6250` (Kirin 659), NOT Kirin 710 | **Do NOT flash** on Kirin 710 |
| SetupWizard stuck on *"Getting your phone ready..."* | Restricted internet prevents Google check-in | Finish SetupWizard offline, install proxy via ADB, then sign in |
| Tapping **Install** on Chrome in Play Store does nothing | Invisible `SheetUiBuilderHostActivity` stuck during background Play Store/GMS self-update | Force-stop Play Store (`adb shell am force-stop com.android.vending`) and reopen |
| SIM card shows `ABSENT` / `+CME ERROR: 10` after hot-plug | Tray eject powers off SIM (`ro.odm.pwroff_card_if_tray_out=true`); AOSP lacks EMUI's `AT^HVSST=1,1` re-power flow | **Reboot with the SIM card inserted** (power off or reboot whenever swapping SIMs) |
