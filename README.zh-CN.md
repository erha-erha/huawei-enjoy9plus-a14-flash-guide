# 华为畅享 9 Plus（JKM-AL00b / Kirin 710）解锁 BL + 刷入 Android 14（LeaOS 21.0 Google）实战经验总结

[English](README.md) | **简体中文**

> **目标设备**：华为畅享 9 Plus（型号 `JKM-AL00b` / `JKM-AL20`，SoC：海思麒麟 710，`arm64-v8a`，`system_a = 2392 MB`，`userdata = mmcblk0p70 / 111 GB`）  
> **起始系统**：EMUI `9.1.0.240(C00E235R4P3)`（安全补丁 `2021-03-01`）  
> **最终成果**：永久解锁 Bootloader + `Android 14`（`LeaOS 21.0` Google 版，基于 LineageOS 21）+ Iceows A14 适配内核 + `SHRP v3.1` Recovery + 4G LTE 蜂窝语音/短信/数据 + Google 全家桶 + **`Magisk v30.7`** + **麒麟 710 + Mali-G51 60Hz 流畅度与 2 GiB LZ4 ZRAM 专项模块（`enjoy9plus_smooth`）** + 后台 `dump-logs` 止损与 **有线 USB 调试永久自愈模块（`huawei_usb_adb_fix v1.2.0`）**。

---

## 目录

- [1. 实测可用软件、模块与镜像清单](#1-实测可用软件模块与镜像清单)
- [2. 阶段一：Windows 11 驱动与 ADB/COM 口排坑](#2-阶段一windows-11-驱动与-adbcom-口排坑)
- [3. 阶段二：Bootloader 永久解锁（SWTP 失效与硬件短接）](#3-阶段二bootloader-永久解锁swtp-失效与硬件短接)
- [4. 阶段三：备份原厂分区 + 刷入 Android 14（解决三圈无限重启）](#4-阶段三备份原厂分区--刷入-android-14解决三圈无限重启)
- [5. 阶段四：国内无外网初始化、代理配置、Google 套件与 SIM 卡排坑](#5-阶段四国内无外网初始化代理配置google-套件与-sim-卡排坑)
- [6. 阶段五：刷后深度优化（Magisk v30.7、麒麟 710 流畅度 + 2 GiB ZRAM、关停 `dump-logs` 与有线调试修复）](#6-阶段五刷后深度优化magisk-v307麒麟-710-流畅度--2-gib-zram关停-dump-logs-与有线调试修复)
- [7. 阶段六：刷机收尾（清理旧版驱动、恢复 Win11 内存完整性）](#7-阶段六刷机收尾清理旧版驱动恢复-win11-内存完整性)
- [8. 踩坑速查表](#8-踩坑速查表)
- [9. 致谢、版权声明与原作者署名](#9-致谢版权声明与原作者署名)

---

## 1. 实测可用软件、模块与镜像清单

> **高速镜像下载（GitHub Releases）**：
> - **基础解锁与刷机包**：**[Releases (`v1.0-mirror`)](https://github.com/erha-erha/huawei-enjoy9plus-a14-flash-guide/releases/tag/v1.0-mirror)**（含 `Kirin-Tool v2.4.2`、`LeaOS 21.0/20.0`、麒麟 710 双版内核、`SHRP v3.1 potter` 与 `SHA256SUMS.txt`）。
> - **Root / 流畅度 / ZRAM / 工具优化包（仅限畅享 9 Plus / 麒麟 710）**：**[Releases (`v1.1-optimization`)](https://github.com/erha-erha/huawei-enjoy9plus-a14-flash-guide/releases/tag/v1.1-optimization)**（含本机专用 `enjoy9plus_smooth`、`JKM-AL00b 9.1.0.240` Magisk v30.7 修补镜像及 GPLv3/Apache-2.0 上游工具镜像）。
> - **有线 USB 调试永久自愈包**：**[Releases (`v1.2-usb-adb-fix`)](https://github.com/erha-erha/huawei-enjoy9plus-a14-flash-guide/releases/tag/v1.2-usb-adb-fix)**（含 EMUI 9.1 麒麟 710/970 通用永久自愈模块 `huawei_usb_adb_fix-v1.2.0.zip` 与 `SHA256SUMS.txt`）。
> - **⚠️ 机型严格隔离提示**：本机性能调优模块（`enjoy9plus_smooth`）**仅适用于华为畅享 9 Plus（`JKM-AL00b` / 麒麟 710 / Mali-G51 / 4GB 内存）**，在 `customize.sh` 中内置了 `ro.hardware == kirin710` 防刷错校验。仅 `huawei_usb_adb_fix` 为 EMUI 9.1 通用 ConfigFS/FunctionFS 修复模块（已在麒麟 710 与麒麟 970 双机实测通过）。**荣耀 Play（`COR-AL10` / 麒麟 970 / Mali-G72 / 6GB 内存）** 请前往独立仓库 [honor-play-a14-flash-guide](https://github.com/erha-erha/honor-play-a14-flash-guide)。

| 用途 | 文件 / 工具 | 大小（实测） | 目标分区 / 说明 | 原作者上游与高速镜像 |
| :--- | :--- | :--- | :--- | :--- |
| BL 永久解锁 | `Kirin-Tool v2.4.2` | ~82.7 MB | 需 `.NET 8 Desktop Runtime` | [@kethily-daniel/Kirin-Tool](https://github.com/kethily-daniel/Kirin-Tool) \| [v1.0 镜像](https://github.com/erha-erha/huawei-enjoy9plus-a14-flash-guide/releases/download/v1.0-mirror/Kirin-Tool-v2.4.2.zip) |
| Android 14 ROM（带 GApps） | `LeaOS-21.0-20260118-iceows-google-pot.img` | 压缩包：`1,357,554,880` B<br>解压后：`2,197,798,912` B (~2.05 GiB) | 刷入 `system`（EROFS，可放入 `2392 MB` `system_a`） | [@Iceows SourceForge](https://sourceforge.net/projects/altairfr-huawei/files/LeaOS-21.0/LeaOS-21.0-20260118-iceows-google-pot.img.xz/download) \| [v1.0 镜像](https://github.com/erha-erha/huawei-enjoy9plus-a14-flash-guide/releases/download/v1.0-mirror/LeaOS-21.0-20260118-iceows-google-pot.img.xz) |
| A14 适配内核（Permissive） | `Kirin710_EMUI9.1_PM-2025.11.16-04_35.img` | `13,094,912` B (~12.5 MB) | 刷入 `kernel`（4.9.148+ 含 Android 14 必需补丁） | [@Iceows Kirin710 内核](https://github.com/Iceows/android_kernel_huawei_kirin710-9/releases) \| [v1.0 镜像](https://github.com/erha-erha/huawei-enjoy9plus-a14-flash-guide/releases/download/v1.0-mirror/Kirin710_EMUI9.1_PM-2025.11.16-04_35.img) |
| 第三方 Recovery（麒麟 710 eMMC） | `SHRP_v3.1_stable-Unofficial_potter-1773176050.zip`（含 `recovery.img`） | `27,146,240` B (~25.9 MB) | 刷入 `recovery_ramdisk`（内含 Iceows 定制 `make_f2fs 1.13.0`） | [@Iceows SourceForge](https://sourceforge.net/projects/altairfr-huawei/files/SHRP-Recovery/SHRP_v3.1_stable-Unofficial_potter-1773176050.zip/download) \| [v1.0 镜像 (zip)](https://github.com/erha-erha/huawei-enjoy9plus-a14-flash-guide/releases/download/v1.0-mirror/SHRP_v3.1_stable-Unofficial_potter-1773176050.zip) \| [预解压 `.img`](https://github.com/erha-erha/huawei-enjoy9plus-a14-flash-guide/releases/download/v1.0-mirror/SHRP_v3.1_potter-recovery.img) |
| Magisk Root（EMUI `9.1.0.240`） | `Magisk-v30.7.apk` 与 `JKM-AL00b_9.1.0.240_recovery_ramdisk_magisk307.img` | APK：`11.6 MB`<br>镜像：`33,554,432` B | 刷入 `recovery_ramdisk`（**仅限 `JKM-AL00b 9.1.0.240`**，`RECOVERYMODE=true`） | [@topjohnwu/Magisk](https://github.com/topjohnwu/Magisk/releases) \| [v1.1 APK](https://github.com/erha-erha/huawei-enjoy9plus-a14-flash-guide/releases/download/v1.1-optimization/Magisk-v30.7.apk) \| [v1.1 `.img`](https://github.com/erha-erha/huawei-enjoy9plus-a14-flash-guide/releases/download/v1.1-optimization/JKM-AL00b_9.1.0.240_recovery_ramdisk_magisk307.img) |
| 60Hz 流畅度 + 2 GiB ZRAM 模块（麒麟 710） | `enjoy9plus_smooth-v1.0.0.zip`（[源码](modules/enjoy9plus_smooth/)） | `2,864` B | Magisk 内直刷；麒麟 710 + Mali-G51 调优、2 GiB LZ4 ZRAM、停用 `dump-logs` | [v1.1 下载](https://github.com/erha-erha/huawei-enjoy9plus-a14-flash-guide/releases/download/v1.1-optimization/enjoy9plus_smooth-v1.0.0.zip) |
| 有线 USB 调试永久自愈（麒麟 710/970） | `huawei_usb_adb_fix-v1.2.0.zip`（[源码](modules/huawei_usb_adb_fix/)） | `3,811` B | **推荐**：Magisk 内直刷；覆盖 `manufacture,adb` 并以 0% 待机 CPU 事件监听自动自愈 `FUNCTIONFS_BIND` / `EBUSY` / `-12 ENOMEM` 死锁 | [v1.2 下载](https://github.com/erha-erha/huawei-enjoy9plus-a14-flash-guide/releases/download/v1.2-usb-adb-fix/huawei_usb_adb_fix-v1.2.0.zip) |
| 应急有线调试脚本（兜底备用） | `scripts/fix_wired_adb_ffs.sh`（[源码](scripts/fix_wired_adb_ffs.sh)） | `1.1 KB` | 尚未安装 `huawei_usb_adb_fix-v1.2.0.zip` 时的无线 ADB 一次性应急修复脚本 | 本仓库源码 |
| 开源免按键重启工具 | `RebootNya_1.9.0.apk` | `3.01 MB` | 一键**软重启**（`setprop ctl.restart zygote`），免拔线保留 Magisk 与 ZRAM | [@daisukiKaffuChino/RebootNya](https://github.com/daisukiKaffuChino/RebootNya/releases) \| [v1.1 镜像](https://github.com/erha-erha/huawei-enjoy9plus-a14-flash-guide/releases/download/v1.1-optimization/RebootNya_1.9.0.apk) |
| 可选真墓碑套件 | `LSPosed-v1.11.0-7209-zygisk-release.zip` 与 `Frozen8.3.0.zip` | `6.79 MB` / `3.04 MB` | 类 iOS 运行态挂起（`GLOBAL_SIGSTOP`，支持 4.9 内核 + A14） | [@JingMatrix/Vector](https://github.com/JingMatrix/Vector/releases) \| [@MoWei-2077/FrozenVS](https://github.com/MoWei-2077/FrozenVS) \| [v1.1 镜像](https://github.com/erha-erha/huawei-enjoy9plus-a14-flash-guide/releases/tag/v1.1-optimization) |
| 可选 Play Integrity 生态 | `PlayIntegrityFork-v19.zip`、`TEESimulator`、`TrickyAddonModule`、`KsuWebUI` | 见 `SHA256SUMS.txt` | GPLv3/Apache-2.0 镜像见 `v1.1`；`TrickyStore` / `KeyAttestation` 请从原仓库下载 | [@osm0sis](https://github.com/osm0sis/PlayIntegrityFork) \| [@JingMatrix](https://github.com/JingMatrix/TEESimulator) \| [@KOWX712](https://github.com/KOWX712/Tricky-Addon-Update-Target-List) \| [@5ec1cff/TrickyStore](https://github.com/5ec1cff/TrickyStore) \| [@vvb2060/KeyAttestation](https://github.com/vvb2060/KeyAttestation) |
| 代理工具（可选） | `FlClash-0.9.4-android-arm64-v8a.apk` | `60.86 MB` | `arm64-v8a` 版本，支持 URL Scheme 一键导入配置 | [@chen08209/FlClash](https://github.com/chen08209/FlClash/releases) \| [v1.1 镜像](https://github.com/erha-erha/huawei-enjoy9plus-a14-flash-guide/releases/download/v1.1-optimization/FlClash-0.9.4-android-arm64-v8a.apk) |
| 原厂底包备份 | `stock_KERNEL.img` / `stock_RECOVERY_RAMDISK.img` | 24 MB / 32 MB | 从官方 `UPDATE.APP` 提取留存，用于随时救砖回退 | 官方 EMUI 9.1 固件包 |
| 中文输入法（可选） | `doubaoime_v1.0.0_official.apk` | ~139.4 MB | 闭源软件不作镜像，请从官方渠道下载 | 字节跳动官方 CDN |

> **⚠️ 高危避坑（切勿刷错包）**：SourceForge 上的 `1-Huawei-DataPrep-A14-AB-v1.0-signed.zip` 是面向 **`hi6250`（麒麟 659）** 的分区预处理包，**不是给麒麟 710 用的，绝对不要刷入本机！**

---

## 2. 阶段一：Windows 11 驱动与 ADB/COM 口排坑

### 2.1 Windows 11 内存完整性（HVCI）拦截旧版华为驱动（Code 39）
- **现象**：设备管理器中出现黄色感叹号 / Code 39，核心原因是 2016 年的旧版华为驱动 `ew_usbccgpfilter.sys` 与 Windows 11 的 **内核隔离 → 内存完整性（HVCI）** 不兼容。
- **处理流程**：
  1. 刷机期间临时关闭 Windows 11 **内核隔离 → 内存完整性** 并重启电脑（仅刷机阶段临时关闭，刷完后卸载旧驱动再重新开启）。
  2. 通过 `pnputil /add-driver` 安装本地微软 WHQL 签名的华为驱动包（`ew_usbccgpfilter.inf`、`hw_cdcacm.inf`、`hw_quser.inf`、`hw_usbdev.inf`、`hw_goadb.inf`）。

### 2.2 `ADB Interface` 正常但 `adb devices` 为空
- **根因**：电脑后台的华为手机助手进程 `HiSuite` 和 `hwtransport` 抢占了 WinUSB 独占句柄。
- **解决**：结束这两个进程后再执行 `adb devices`：
  ```powershell
  Stop-Process -Name HiSuite, hwtransport -Force -ErrorAction SilentlyContinue
  adb devices -l
  ```

### 2.3 短接后识别为 `USB SER`（`VID_12D1&PID_3609`）且找不到驱动
- **现象**：手机拆机短接主板测试点插电脑后，设备管理器只显示未知设备 `USB SER`，但又不想开启 Windows 测试签名模式。
- **解决**：不要装来路不明的未签名驱动，直接通过 Windows SetupAPI（`DiInstallDevice`）把本地**已带微软 WHQL 签名**的 `hw_quser.inf`（对应 `HUAWEI USB COM 1.0`）强制绑定到该设备实例，即可稳定识别为 `HUAWEI USB COM 1.0 (COMx)`。

---

## 3. 阶段二：Bootloader 永久解锁（SWTP 失效与硬件短接）

### 3.1 为什么软件短接（SWTP）会失败
- 本机固件为 `JKM-AL00b 9.1.0.240`，安全补丁日期为 **`2021-03-01`**，晚于华为在 2021 年 2 月补丁中封堵 SWTP 的时间节点，因此软件短接必然报 `Failed to send partition header`。
- **结论**：安全补丁 ≥ `2021-03-01` 的 EMUI 9.1 机器不要在 SWTP 上浪费时间，直接走**拆机硬件短接**进入 `USB COM 1.0`。

### 3.2 `Kirin-Tool v2.4.2` 使用要点与权限坑
- 需要先安装 **`.NET 8 Desktop Runtime`**（`winget install Microsoft.DotNet.DesktopRuntime.8`）。
- **路径权限坑**：如果启动器当前工作目录（CWD）不在 `Kirin-Tool` 目录内，工具尝试写 `.\dload` 时会报 `Access to path ...\dload is denied`；若通过某些自动化进程直接起 EXE 可能遇到 `0xc0000142`。
- **稳妥做法**：为 `Kirin-Tool.exe` 创建一个桌面/目录快捷方式，明确将 **`WorkingDirectory`（起始位置）设为 `Kirin-Tool` 所在文件夹**，再打开执行解锁。

### 3.3 确认是否“永久解锁”与合盖提醒
1. **Fastboot 验证**：
   ```powershell
   fastboot oem get-bootinfo
   # 预期输出：unlocked / USER LockState: UNLOCKED
   ```
2. **开机后系统属性验证**：
   ```powershell
   adb shell "getprop | grep -iE 'flash\.locked|verifiedbootstate|vbmeta_state'"
   # ro.boot.flash.locked = 0
   # ro.boot.verifiedbootstate = orange
   # ro.keymaster.xxx.vbmeta_state = unlocked
   ```
3. **永久性说明**：
   - `Kirin-Tool` 写入的是底层持久解锁状态，经过多次冷重启、双清、进 SHRP、换刷不同 ROM 都**不会回锁**。
   - **唯一回锁风险**：手动执行 `fastboot oem relock` 或用官方三键强刷全量 EMUI 底包覆盖底层。
   - 装回后盖前务必检查：短接点附近无异物、**后置指纹排线**扣紧。

---

## 4. 阶段三：备份原厂分区 + 刷入 Android 14（解决三圈无限重启）

### 4.1 必做：先备份原厂关键镜像
从官方 EMUI 9.1 `UPDATE.APP` 解包提取并妥善保存：
- `stock_KERNEL.img`（原厂内核）
- `stock_RECOVERY_RAMDISK.img`（原厂 Recovery）

刷入第三方内核前，先核对第三方内核镜像的 Header、偏移量（Offsets）和 `cmdline` 与 `stock_KERNEL.img` 一致，防止直接变砖。

### 4.2 刷入三件套（Fastboot 模式）
```powershell
# 1. 刷入 Android 14 Google 系统镜像（LeaOS 21.0，EROFS，约 5 个 sparse 分片，耗时 ~68s）
fastboot flash system LeaOS-21.0-20260118-iceows-google-pot.img

# 2. 刷入 Iceows Kirin 710 EMUI 9.1 A14 适配内核（Permissive）
fastboot flash kernel Kirin710_EMUI9.1_PM-2025.11.16-04_35.img

# 3. 刷入 SHRP v3.1 Recovery
fastboot flash recovery_ramdisk recovery.img
```

### 4.3 核心复盘：为什么刷完只卡“三个转圈”无限重启？
本次实战踩穿了**两个叠加根因**，缺一不可：

1. **根因一：原厂 4.9.148 内核缺少 Android 14 必需补丁（麒麟 710）**
   - 麒麟 710 直接用 EMUI 9.1 原厂内核启动 Android 14 会因缺少 `LOOP_CONFIGURE` / loop 设备与挂载相关内核补丁导致启动失败。
   - **解法**：必须刷入上文 Iceows 编译的 `Kirin710_EMUI9.1_PM-2025.11.16-04_35.img`。
2. **根因二：EMUI 9.1 原厂 Recovery 格式化 `/data` 导致的 F2FS Superblock 校验冲突（华为 EMUI 9.1 跨机型通病！）**
   - 使用 **EMUI 9.1 原厂 Recovery** 执行“恢复出厂设置 / 格式化 Data”时，会写入华为新版/私有 F2FS 校验特性位（如 `superblock features = 481: encrypt verity quota_ino`）。
   - 同时，**未打补丁的上游 `f2fs-tools` / 普通第三方 TWRP** 同样会踩坑：上游 `mkfs.f2fs` 默认写入 `CP_NAT_BITS_FLAG`（NAT Bitmap 检查点页），而华为 EMUI 9.1 的 4.9 内核 F2FS 驱动并不支持该标志位（Iceows 专门通过 `0001-mkfs.f2fs-Remove-NAT-Bitmap-to-support-Huawei-EMUI9-.patch` 移除了该标志）。
   - 开机时，只读的 EROFS `system` 分区其实已经挂载成功并拉起了 `init`、`surfaceflinger` 和三个转圈动画，但内核在挂载 `userdata` 时直接拒挂：
     ```text
     F2FS-fs (mmcblk0p70): Invalid checksum crc(0x...)
     F2FS-fs (mmcblk0p70): Can't find valid F2FS filesystem in 1th/2th superblock
     ```
     随后 `mount_all` 失败 → `/data` 未挂载 → `credstore`（`chdir: /data/misc/credstore: No such file or directory`）与 `tombstoned`（`failed to open directory: /data/tombstones`，fatal signal 6）陷入无限崩溃 → 画面永远停在 LineageOS 三个转圈动画。

> **⚠️ 跨机型同类问题提示（已在麒麟 970 / 荣耀 Play 上 100% 复现并验证）**：
> 上述“卡在 LineageOS 三个转圈”的 F2FS Superblock CRC 校验冲突**并非畅享 9 Plus（麒麟 710）个例，而是华为/荣耀 EMUI 9.1 刷 Android 14（`LeaOS 21.0`）时的跨芯片通病**。在同为 EMUI 9.1 的 **荣耀 Play（`COR-AL10` / 麒麟 970 / UFS 存储）** 上刷入同一个 `LeaOS-21.0-20260118-iceows-google-pot.img` 并用原厂 Recovery 清数据后，复现了**完全一致的故障链**。
>
> | 对比维度 | 华为畅享 9 Plus（`JKM-AL00b` / 麒麟 710） | 荣耀 Play（`COR-AL10` / 麒麟 970） |
> | :--- | :--- | :--- |
> | **存储类型 / `userdata` 设备节点** | eMMC（`/dev/block/mmcblk0p70`，~111 GB） | UFS（`/dev/block/sdd66`，~112 GB） |
> | **原厂 Recovery 清数据后的报错** | `F2FS-fs (mmcblk0p70): Invalid checksum crc` → `credstore` 崩溃 → 卡三圈 | `F2FS-fs (sdd66): Invalid checksum crc(0x100b1449)` → `credstore` / `tombstoned` 崩溃 → 卡三圈 |
> | **ROM（`LeaOS-21.0-*-google-pot.img` EROFS）** | 正常挂载 | 正常挂载（实测 `rc=0`，压缩的 `framework.jar` 读取零报错） |
> | **所需 SHRP（含 Iceows `make_f2fs`）** | `SHRP v3.1 potter`（`make_f2fs 1.13.0`） | `SHRP-Reborn v3.2 charlotte`（`make_f2fs 1.14.0`，麒麟 970 UFS） |
> | **内核差异** | 需同时刷 Iceows 适配内核 `Kirin710_EMUI9.1_PM` + 重格 F2FS | 仅重格 F2FS 后即在原厂 `9.1.0.350` `4.9.148` 内核（带 212 字节 SELinux 补丁，默认 Enforcing 启动）上 **90 秒直接点亮** |
>
> **通用避坑结论**：凡是华为/荣耀 EMUI 9.1 机型刷 `LeaOS 21.0`（Android 14），**不要只靠原厂 Recovery 的“恢复出厂设置”**，必须刷入同 SoC/存储架构的 Iceows 版 SHRP（麒麟 710 eMMC 用 `potter`，麒麟 970 UFS 用 `charlotte`），用内置 Iceows 补丁版 `/system/bin/make_f2fs -f -O encrypt -w 4096 /dev/block/by-name/userdata` 重格（**切勿把本机的扇区数 `233340896` 照抄到其他机型**），并当场 `mount -t f2fs` 验证成功后再重启。

### 4.4 正确的 `/data` 格式化步骤（在 SHRP 中完成）
1. 刷完 `recovery_ramdisk` 后，拔线或按键重启进入 **SHRP Recovery**。
2. 首次进入 SHRP 提示 `Keep System Read Only?` 时，**保持只读即可**（不要随意挂载修改只读的 EROFS `system`）。
3. 通过 SHRP 内的 `adb shell`，调用 Iceows 定制的 `/system/bin/make_f2fs`（`Ver Iceows (Huawei EMUI9): 1.13.0`）手动重新格式化 `userdata`：
   ```sh
   # 格式化 userdata（带 encrypt 特性，不带引发冲突的校验特性与 NAT Bitmap）
   # 注意：233340896 仅适用于畅享 9 Plus（JKM-AL00b）；其他 EMUI 9.1 机型（如荣耀 Play COR-AL10）
   # 建议省略末尾扇区数让 make_f2fs 自动按分区实际容量格式化，切勿直接照抄。
   /system/bin/make_f2fs -f -O encrypt -w 4096 /dev/block/by-name/userdata 233340896

   # 实测直接挂载验证（必须返回 0 且容量正常约 111G）
   mount -t f2fs /dev/block/by-name/userdata /data && df -h /data && umount /data

   # 顺手清理 /cache
   rm -rf /cache/*
   reboot
   ```
4. 重启后即可顺利通过启动动画进入 Android 14（系统识别为 `POT-LX1` / `HWPOT`，内核 `4.9.148+ aarch64`）。

---

## 5. 阶段四：国内无外网初始化、代理配置、Google 套件与 SIM 卡排坑

### 5.1 国内无外网跳过 Google 开机向导
- 刷入 Google 版 ROM 后首次开机会进入 SetupWizard，若连着国内 Wi-Fi 会一直卡在“正在准备我的设备，这可能需要几分钟”。
- 可先**离线跳过 / 不连 Wi-Fi 完成开机向导**进入桌面，等安装好代理并开启外网后再登录 Google 账号。

### 5.2 直接通过 ADB 安装代理与输入法（免翻菜单开 USB 调试）
- `LeaOS 21.0` 默认开启了 `WITH_ADB_INSECURE=true`，进入系统后插上数据线即可直接用 `adb` 装软件：
  ```powershell
  adb install -r FlClash-0.9.4-android-arm64-v8a.apk
  adb install -r doubaoime_official.apk
  ```
- **免手输长订阅链接导入 FlClash**：利用 `com.follow.clash/.MainActivity` 注册的 `flclash://install-config` Intent，一行命令把 URL 编码后的订阅推给手机：
  ```powershell
  adb shell am start -a android.intent.action.VIEW `
    -d "flclash://install-config?url=<URL_ENCODED_SUBSCRIPTION_URL>" `
    -n com.follow.clash/.MainActivity
  ```
  在手机上确认导入并在仪表盘点启动、授权 Android VPN 即可。可用下面命令后台验证 VPN 是否已连通且通过系统校验：
  ```powershell
  adb shell "dumpsys connectivity | grep -E 'Vpn|tun0|VALIDATED'"
  ```

### 5.3 核心复盘：Play 商店点 Chrome“安装”没反应的真因与解法
- **现象**：已经连上代理、能正常搜索到 Google Chrome，也能安装 Firefox 等其他应用，但点击 Chrome 的“安装”按钮毫无反应。
- **日志与控件树定位（`uiautomator dump` + `dumpsys activity top`）**：
  - 新登录账号后，Play 商店与 Google Play 服务在后台静默自我更新（如 Play 商店 `36.6.25 -> 54.4.11`，GMS `23.25.18 -> 26.45.31`）。
  - 更新过渡期间点击“安装”触发的内部获取弹窗 `com.google.android.finsky.billing.acquire.SheetUiBuilderHostActivity` 卡在了 `INVISIBLE`（`正在加载…`）状态，相当于一层**全屏透明蒙板**盖在界面最上层，吞掉了所有触摸点击。
- **解法**：强制停止并重启 Play 商店即可瞬间恢复：
  ```powershell
  adb shell am force-stop com.android.vending
  ```
  重启后实测直接通过官方 Google Play 商店顺利装齐 **Chrome、Gmail、YouTube、Google 地图、Google 相册、Google 云端硬盘、Google 翻译**，且可自动处理 Chrome 的 `TrichromeLibrary` 依赖和后续自动更新。

### 5.4 核心复盘：开机后热插拔 SIM 卡无法识别（`ABSENT` / `+CME ERROR: 10`）
- **现象**：刷完首次空卡开机进系统后，再把 SIM 卡热插拔插回卡槽，系统一直显示无 SIM 卡（`gsm.sim.state=ABSENT,ABSENT`），即便开关飞行模式，基带依然返回 `+CME ERROR: 10`（SIM not inserted）。
- **根因定位（`dmesg` + `logcat -b radio` + `/odm/phone.prop`）**：
  - 拔出卡托时，内核 `mod_simhotplug` 触发 `SIM_CARD_OUT`，由于原厂属性 `ro.odm.pwroff_card_if_tray_out=true`，巴龙基带给卡槽断电。
  - 重新插卡时，虽然内核正常检测到卡托插入并发送 `SIM_CARD_IN`（`bsp_icc_send to CP`），但类原生 LeaOS 缺少 EMUI 专属框架（`HwUiccController`）在热插拔后自动向基带发送 `AT^HVSST=1,1` 重新给卡槽上电，导致卡槽持续断电、基带无法读卡。
- **解法与永久性边界**：
  - **日常插卡使用、正常关机/重启（长期稳定）**：插好 SIM 卡后重启手机，巴龙基带会在开机初始化阶段自动完成卡槽上电与 USIM 初始化（`+CPIN: READY` / `^CARDMODE:2`），实测 4G LTE 语音、短信与移动数据（`rmnet0`）立即全部恢复正常，后续每次正常开关机都会自动识别，不会失效。
  - **换卡注意事项（不支持热插拔）**：这是类原生 ROM 搭配 EMUI 9.1 巴龙基带的固有行为。以后更换 SIM 卡时，请**关机换卡再开机**，或者**插好卡托后重启一次手机**。
- **避免误触单/双卡属性覆盖**：不要在 Phh Treble Settings 里随意反复切换“强制单卡（`persist.sys.phh.monosim`）”，触发脚本会用通用值（`09A9D` / `ro.odm.multi.rild=true`）覆盖 `/odm/phone.prop` 里本机原厂的 `persist.radio.modem.cap=09B9D52` 和 `ro.odm.multi.rild=false`。如果误触导致双卡异常，可用 root 清理后重启恢复原厂配置：
  ```sh
  adb root
  adb shell "resetprop_phh -p --delete persist.sys.phh.monosim && setprop persist.radio.modem.cap 09B9D52"
  adb reboot
  ```

---

## 6. 阶段五：刷后深度优化（Magisk v30.7、麒麟 710 流畅度 + 2 GiB ZRAM、关停 `dump-logs` 与有线调试修复）

### 6.1 Magisk v30.7（`recovery_ramdisk`）与日常免按键重启（`RebootNya`）
- EMUI 9.1 下 Magisk 需以 `RECOVERYMODE=true` 修补原厂 `recovery_ramdisk` 后刷入（`JKM-AL00b_9.1.0.240_recovery_ramdisk_magisk307.img` **仅限 `JKM-AL00b 9.1.0.240`**，其他版本号请用 `Magisk-v30.7.apk` 自行修补原厂 `recovery_ramdisk.img`）。
- **冷开机进 Magisk 精准松手时机**：拔掉数据线 → 彻底关机 → 按住 **「音量上 + 电源键」** 至英文解锁警告画面 → 松电源键继续按住 **音量上约 5 秒**，看到底部出现 **`Your device is booting now...`** 瞬间立刻松手。
- **日常免拔线重启**：安装 [`RebootNya_1.9.0.apk`](https://github.com/daisukiKaffuChino/RebootNya)，装模块或改系统配置后直接点 **「软重启」**（`setprop ctl.restart zygote`），约 6–10 秒重载系统框架，全程免拔线、免按键且保留 Magisk 与 ZRAM。

### 6.2 麒麟 710 + Mali-G51 60Hz 流畅度、2 GiB LZ4 ZRAM 与关停 `dump-logs`（`enjoy9plus_smooth`）
- **本机硬件特征**：畅享 9 Plus（`JKM-AL00b` / `POT-LX1`）配备 `60.00 Hz` LCD 屏、麒麟 710（`4×A53 @ 1.71 GHz + 4×A73 @ 2.19 GHz`，华为 `schedutil`）、Mali-G51 MP4（`mali_ondemand`，`413–999 MHz`）及 `4 GB` 内存（可用 `3.6 GiB`，eMMC 5.1）。
- 默认刷完 `LeaOS 21.0` 时，**桌面（`Launcher3`）滑动仅约 19 FPS（中位 53ms、掉帧率 54.6%、丢帧 26 次）**，实测查清 5 处瓶颈并打包为专属模块 [`enjoy9plus_smooth-v1.0.0.zip`](https://github.com/erha-erha/huawei-enjoy9plus-a14-flash-guide/releases/download/v1.1-optimization/enjoy9plus_smooth-v1.0.0.zip)（[源码](modules/enjoy9plus_smooth/)）：
  1. **修复 `LeaOS` `/system/build.prop` 遗留图形属性**：通过 `system.prop` 修正 `hwui.disable_vsync=false`、`debug.hwui.use_buffer_age=true`、`debug.egl.profiler=0`、`debug.hwui.profile=false`，并**保留华为 HWC 2.2 必需的 `debug.sf.disable_backpressure=1` 与 `debug.sf.latch_unsignaled=1`**（注意需重启或执行 `setprop ctl.restart surfaceflinger` 让 `zygote` 重新加载 `libhwui` 才彻底生效）。
  2. **彻底停用后台吃满 100% 单核的 `dump-logs` 调试服务**：`/system/etc/init/debug-log-gsi.rc` 会在后台死循环跑 `logcat -b all -f /splash2/logcat-normal.txt -v threadtime`，不仅吃满一颗 CPU 核心还疯狂擦写 eMMC 闪存。模块开机自动 `setprop ctl.stop dump-logs` 彻底止损。
  3. **麒麟 710 `schedutil` 大核响应调优**：开启大核 `fast_ramp_up=1`（原为 `0`）、关闭 `fast_ramp_down=0`、开启 `io_is_busy=1`，大核高频起步提至 `1671 MHz`、升频延迟从 `118ms` 压至 `10–15ms`。
  4. **Mali-G51 `mali_ondemand` GPU 调优**：开启 `animation_boost=1`、`hispeed_freq=682 MHz`、`vsync_upthreshold=50`，唤醒起步档由 `413 MHz` 抬至 `567 MHz`（实测 SoC 温度仅 `25.4℃`）。
  5. **开机自启 2 GiB LZ4 ZRAM + 关闭高斯模糊**：针对 4GB 内存跑 Android 14 默认 `Swap=0` 导致的内存抖动，开机自动启用 `2 GiB` LZ4 ZRAM（`swapon -p 100`、`page-cluster=0`、`swappiness=80`），同时开启 `disable_window_blurs=1` 与 `0.5x` 动画缩放。
  - *（可选）* 如需类 iOS 运行态真墓碑，同样可搭配 `LSPosed v1.11.0 + Frozen 8.3.0`（`全局 SIGSTOP` 模式，详见 [荣耀 Play 指南第 7.3 节](https://github.com/erha-erha/honor-play-a14-flash-guide/blob/main/README.zh-CN.md#73-%E7%B1%BB-ios-%E8%BF%90%E8%A1%8C%E6%80%81%E7%9C%9F%E5%A2%93%E7%A2%91lsposed-v1110--frozen-830)）。

| 实测指标（`dumpsys gfxinfo`，60Hz） | 优化前基线 | 刷入 `enjoy9plus_smooth` 后 |
| :--- | :--- | :--- |
| 桌面（`Launcher3`）掉帧率 / 丢帧数 | `54.6%` / `26` 次丢帧 | **`8.9%–10.6%` / `0–2` 次丢帧** |
| 桌面中位帧耗时 / `DequeueBuffer` 阻塞 | `53 ms` / `25–30 ms` | **`18–26 ms` / `0.04 ms`** |
| 设置页中位帧耗时 / 掉帧率 | `15 ms`（旧版 `35.2%`） | **`15–16 ms`（`0.8%–1.6%`，0 丢帧）** |
| 后台 `dump-logs` CPU 占用 | `100%`（吃满单核） | **`0%`（已停用）** |

### 6.3 核心排坑：有线 USB 调试失灵（`FUNCTIONFS_BIND` / `EBUSY` / `ffs.adb -12 ENOMEM`）与永久自愈模块（`huawei_usb_adb_fix v1.2.0`）
- **现象**：插上电脑只显示充电中（`power_supply/USB/type=USB`），换多个 USB 3.0/2.0 口电脑端设备管理器均无任何 `VID_12D1` / ADB 设备，但无线调试正常。当电脑交替连接畅享 9 Plus 与荣耀 Play 两台华为/荣耀 EMUI 9.1 手机时，极易误判为 Windows 多机驱动冲突，**但经实测 100% 是手机端固件与内核交互死锁**。
- **三层叠加根因（`dmesg` + `logcat` + `/vendor/default.prop` + `/config/usb_gadget/g1`）**：
  1. **原厂 `/vendor/default.prop` 默认值失效**：华为原厂写死了 `persist.sys.usb.config=manufacture,adb`，但 LeaOS 的 `init.usb.configfs.rc` 与 `init.hisi.usb.rc` 中均无匹配规则（手动绑定纯 `mtp.gs0` 后 Windows 瞬间识别出 `USB\VID_12D1&PID_107E`，证明数据线与电脑端口完全正常）。
  2. **Android 14 `adbd` 与 Linux 4.9 `f_fs.c` 的 `FUNCTIONFS_BIND` / `EBUSY` 竞争死锁**：Android 14 APEX `/apex/com.android.adbd/bin/adbd` 硬编码了 1 秒等待 `FUNCTIONFS_BIND` 超时（`timed out while waiting for FUNCTIONFS_BIND, trying again`，无属性可关）。拔插或休眠导致 `adbd` 关闭重开 `ep0` 时，若 `g1/UDC` 仍绑定 `ff100000.dwc3`，`init` 重写 `UDC` 报 `EBUSY` 且 4.9 内核 `f_fs.c` 不再补发 `FUNCTIONFS_BIND`，`adbd` 陷入 1 秒死循环并拉低 USB D+ 上拉电阻。
  3. **`ffs.adb` 实例中毒触发 `-12 ENOMEM`**：一旦卡入该循环，Linux 4.9 的 `ffs.adb` 实例即便走常规 `sys.usb.config none → adb` 也会持续每秒报错，必须卸载 `/dev/usb-ffs/adb` 并重建 `ffs.adb`：
     ```text
     configfs_composite_bind:use_os_desc 0
     configfs-gadget ff100000.dwc3: failed to start g1: -12
     Unable to write to file '/config/usb_gadget/g1/UDC': Out of memory
     ```
- **推荐永久自愈方案（[`huawei_usb_adb_fix-v1.2.0.zip`](https://github.com/erha-erha/huawei-enjoy9plus-a14-flash-guide/releases/download/v1.2-usb-adb-fix/huawei_usb_adb_fix-v1.2.0.zip) / [源码](modules/huawei_usb_adb_fix/)）**：
  - 在 Magisk 管理器内直刷。`system.prop` 启动早期将 `persist.sys.usb.config` 覆盖为 `adb`，后台 `usb_adb_guard.sh` 以 **0% 待机 CPU** 运行事件驱动监听（`logcat -b main -T 1 -v epoch adbd:W '*:S'`）。
  - 通过 Unix 时间戳过滤启动前/修复前历史日志、**检测到 `UDC == configured` 时自动跳过绝不打断正常传输**、直接读取 `/proc/mounts`（彻底规避 `toybox mount` 无参扫描 Magisk 挂载表导致 99% CPU 死循环的陷阱），在触发故障时自动卸载并重建 `/config/usb_gadget/g1/functions/ffs.adb`、重挂 `functionfs`（`uid=2000,gid=2000`）并恢复原有 USB 模式（`adb` / `mtp,adb` 等）。
  - **畅享 9 Plus（`JKM-AL00b`）真实故障现场实测**：在手机已爆发 `FUNCTIONFS_BIND` / `EBUSY` 有线断连的状态下装入 v1.2.0，**零人工干预，4 秒内捕获故障、8 秒内完成重建（全程 ~12 秒）**，自动恢复 `UDC=[ff100000.dwc3] state=[configured]`，Windows 端自动枚举出 `USB\VID_12D1&PID_103A\<序列号>`，待机 CPU 占率为 `0%`。
- **应急一次性兜底脚本**（若尚未安装 Magisk 或 `huawei_usb_adb_fix-v1.2.0.zip`，仍可通过「无线调试」连入并用 `setsid` 脱离会话执行 [`scripts/fix_wired_adb_ffs.sh`](scripts/fix_wired_adb_ffs.sh)）：
  ```powershell
  adb -s <IP:端口> push scripts/fix_wired_adb_ffs.sh /data/local/tmp/
  adb -s <IP:端口> shell "su -c 'setsid sh /data/local/tmp/fix_wired_adb_ffs.sh </dev/null >/data/local/tmp/usb_fix.log 2>&1 &'"
  ```

---

## 7. 阶段六：刷机收尾（清理旧版驱动、恢复 Win11 内存完整性）

刷机与手机调试全部结束后，建议及时清理电脑上临时安装的 2016 旧版华为内核驱动，重新恢复 Windows 11 系统安全防护：

1. 查看已安装的华为第三方驱动包对应的 `oemXX.inf` 编号：
   ```powershell
   pnputil /enum-drivers | Select-String -Context 2,3 "huawei|ew_usbccgpfilter|hw_cdc|hw_qu"
   ```
2. 以**管理员权限**依次卸载对应旧版驱动包（如 `ew_usbccgpfilter.inf`、`hw_cdcacm.inf`、`hw_quser.inf`、`hw_usbdev.inf`、`hw_cdcmdm.inf`、`hw_qumdm.inf`、`hw_quusbnet.inf`）：
   ```powershell
   pnputil /delete-driver oemXX.inf /uninstall /force
   ```
3. 打开 **Windows 安全中心 → 设备安全性 → 内核隔离**，重新开启 **内存完整性（HVCI）** 并重启电脑。

---

## 8. 踩坑速查表

| 现象 / 报错 | 实际根因 | 解决方案 |
| :--- | :--- | :--- |
| 设备管理器旧版华为驱动报 Code 39 | Win11 内存完整性拦截 `ew_usbccgpfilter.sys` | 刷机期临时关闭内存完整性并重启；刷完后 `pnputil` 卸载旧驱动再重新开启 |
| `ADB Interface` 正常但 `adb devices` 为空 | `HiSuite` / `hwtransport` 独占 WinUSB 句柄 | `Stop-Process -Name HiSuite,hwtransport -Force` |
| 短接后显示 `USB SER` (`VID_12D1&PID_3609`) 无驱动 | 未自动匹配 `HUAWEI USB COM 1.0` | 用 SetupAPI `DiInstallDevice` 绑定 WHQL 签名的 `hw_quser.inf` |
| SWTP 报 `Failed to send partition header` | EMUI 9.1 安全补丁 `2021-03-01` 已封堵 SWTP | 放弃 SWTP，改用拆机硬件短接 + `Kirin-Tool v2.4.2` |
| `Kirin-Tool` 报 `Access to path ...\dload is denied` | 进程工作目录（CWD）不在 `Kirin-Tool` 文件夹 | 通过快捷方式指定 `WorkingDirectory` 为 `Kirin-Tool` 目录后运行 |
| 刷完 A14 卡在 LineageOS 三个转圈无限重启（麒麟 970 / 荣耀 Play 同款复现） | EMUI 9.1 原厂 Recovery 的 F2FS Superblock CRC 校验冲突（`Invalid checksum crc` → `/data` 未挂载 → `credstore` 崩溃），麒麟 710 还叠加原厂内核缺 A14 补丁 | 刷同架构 Iceows 版 SHRP（710 eMMC 用 `potter`，970 UFS 用 `charlotte`），用内置 Iceows `make_f2fs -f -O encrypt -w 4096` 重格 `userdata` 并实测 `mount -t f2fs`；麒麟 710 需同时刷 Iceows A14 内核 |
| 误下载 `1-Huawei-DataPrep-A14-AB-v1.0-signed.zip` | 该包仅适用于 `hi6250`（麒麟 659） | **严禁刷入**麒麟 710 设备 |
| 首次进入系统卡在“正在准备我的设备” | 国内无外网，Google SetupWizard 联网超时 | 离线跳过开机向导，进桌面先用 ADB 装代理再登录 Google |
| Play 商店点击 Chrome“安装”完全无反应 | 首次登录后台自更新导致透明 `SheetUiBuilderHostActivity` 卡死挡住点击 | 划掉后台或执行 `adb shell am force-stop com.android.vending` 后重开即可 |
| 开机后热插拔 SIM 卡显示无卡（`+CME ERROR: 10`） | 拔卡断电后类原生系统未自动下发 `AT^HVSST=1,1` 重新上电（不支持热插拔） | 关机换卡或插好 SIM 卡后**重启一次手机**即可恢复语音、短信与 4G LTE |
| 桌面卡顿仅 ~19 FPS 且后台 `logcat-normal.txt` 吃满 100% 单核 | LeaOS `hwui.disable_vsync=true` / `use_buffer_age=false`、麒麟 710 `fast_ramp_up=0`、失控 `dump-logs` 与 4GB 无 ZRAM | Magisk 刷入 `enjoy9plus_smooth-v1.0.0.zip` 后重启（或热重启 `SurfaceFlinger`） |
| 有线插电脑只充电无 `VID_12D1` 设备（`FUNCTIONFS_BIND` / `failed to start g1: -12`） | `/vendor/default.prop` 残留 `manufacture,adb` + A14 `adbd` 与 4.9 `f_fs.c` `FUNCTIONFS_BIND` / `EBUSY` / `ffs.adb -12 ENOMEM` 死锁（非电脑驱动冲突） | Magisk 刷入 `huawei_usb_adb_fix-v1.2.0.zip` 实现 0% CPU 永久自愈（应急备用无线 ADB `setsid` 运行 [`scripts/fix_wired_adb_ffs.sh`](scripts/fix_wired_adb_ffs.sh)） |

---

## 9. 致谢、版权声明与原作者署名

本仓库 GitHub Releases 中镜像的第三方开源软件均为**未经修改的官方原版发布包**，仅用于方便社区玩家高速下载；所有版权归原作者所有并遵循原开源协议。未声明再分发许可的仓库（如 `TrickyStore`、`KeyAttestation`）与闭源软件（如豆包输入法）不作镜像，仅提供官方上游链接。

| 项目 / 组件 | 原作者 | 上游仓库 / 官方地址 | 开源协议 |
| :--- | :--- | :--- | :--- |
| **LeaOS 21.0 / 20.0**、**麒麟 710 A14 内核** 与 **EMUI 9 F2FS `make_f2fs` 补丁** | **[@Iceows](https://github.com/Iceows)**（AltairFR） | [Iceows/huawei-creator](https://github.com/Iceows/huawei-creator) \| [Iceows/android_kernel_huawei_kirin710-9](https://github.com/Iceows/android_kernel_huawei_kirin710-9) \| [SourceForge](https://sourceforge.net/projects/altairfr-huawei/) | 开源（LineageOS / GPL / Apache-2.0） |
| **Kirin-Tool v2.4.2** | **[@kethily-daniel](https://github.com/kethily-daniel)** | [kethily-daniel/Kirin-Tool](https://github.com/kethily-daniel/Kirin-Tool) | 开源 |
| **SHRP v3.1（`potter`）** | **Team SHRP** & **[@Iceows](https://github.com/Iceows)** | [SHRP-Reborn](https://github.com/SHRP-Reborn) \| [SourceForge](https://sourceforge.net/projects/altairfr-huawei/files/SHRP-Recovery/) | GPL-3.0 |
| **Magisk v30.7** | **[@topjohnwu](https://github.com/topjohnwu)** | [topjohnwu/Magisk](https://github.com/topjohnwu/Magisk) | GPL-3.0 |
| **RebootNya v1.9.0** | **[@daisukiKaffuChino](https://github.com/daisukiKaffuChino)** | [daisukiKaffuChino/RebootNya](https://github.com/daisukiKaffuChino/RebootNya) | Apache-2.0 |
| **LSPosed v1.11.0（Zygisk 版）** 与 **TEESimulator** | **[@JingMatrix](https://github.com/JingMatrix)** & 贡献者 | [JingMatrix/Vector](https://github.com/JingMatrix/Vector) \| [JingMatrix/TEESimulator](https://github.com/JingMatrix/TEESimulator) | GPL-3.0 |
| **Frozen 8.3.0（可选真墓碑）** | **[@MoWei-2077](https://github.com/MoWei-2077)**（基于 **[@jark006](https://github.com/jark006)**） | [MoWei-2077/FrozenVS](https://github.com/MoWei-2077/FrozenVS) \| [jark006/freezeitVS](https://github.com/jark006/freezeitVS) | GPL-3.0 |
| **PlayIntegrityFork** | **[@osm0sis](https://github.com/osm0sis)** | [osm0sis/PlayIntegrityFork](https://github.com/osm0sis/PlayIntegrityFork) | GPL-3.0 |
| **TrickyStore** 与 **KsuWebUIStandalone** | **[@5ec1cff](https://github.com/5ec1cff)** | [5ec1cff/TrickyStore](https://github.com/5ec1cff/TrickyStore) \| [5ec1cff/KsuWebUIStandalone](https://github.com/5ec1cff/KsuWebUIStandalone) | 原仓库直链 / GPL-3.0 |
| **Tricky-Addon-Update-Target-List** | **[@KOWX712](https://github.com/KOWX712)** | [KOWX712/Tricky-Addon-Update-Target-List](https://github.com/KOWX712/Tricky-Addon-Update-Target-List) | Apache-2.0 |
| **KeyAttestation** | **[@vvb2060](https://github.com/vvb2060)** | [vvb2060/KeyAttestation](https://github.com/vvb2060/KeyAttestation) | 原仓库直链 |
| **FlClash v0.9.4** | **[@chen08209](https://github.com/chen08209)** | [chen08209/FlClash](https://github.com/chen08209/FlClash) | GPL-3.0 |
| **姊妹机型实战指南（荣耀 Play / 麒麟 970）** | **[@erha-erha](https://github.com/erha-erha)** | [erha-erha/honor-play-a14-flash-guide](https://github.com/erha-erha/honor-play-a14-flash-guide) | 开源 |
