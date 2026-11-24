# 华为畅享 9 Plus（JKM-AL00b / Kirin 710）解锁 BL + 刷入 Android 14（LeaOS 21.0 Google）实战经验总结

> **目标设备**：华为畅享 9 Plus（型号 `JKM-AL00b` / `JKM-AL20`，SoC：海思麒麟 710，`arm64-v8a`，`system_a = 2392 MB`，`userdata = mmcblk0p70 / 111 GB`）  
> **起始系统**：EMUI `9.1.0.240(C00E235R4P3)`（安全补丁 `2021-03-01`）  
> **最终成果**：永久解锁 Bootloader + `Android 14`（`LeaOS 21.0` Google 版，基于 LineageOS 21）+ Iceows A14 适配内核 + `SHRP v3.1` Recovery + FlClash + 豆包输入法 + Google 全家桶（Chrome / Gmail / YouTube / Maps / Photos / Drive / Translate）全部正常运行。

---

## 目录

- [1. 实测可用软件与镜像清单](#1-实测可用软件与镜像清单)
- [2. 阶段一：Windows 11 驱动与 ADB/COM 口排坑](#2-阶段一windows-11-驱动与-adbcom-口排坑)
- [3. 阶段二：Bootloader 永久解锁（SWTP 失效与硬件短接）](#3-阶段二bootloader-永久解锁swtp-失效与硬件短接)
- [4. 阶段三：备份原厂分区 + 刷入 Android 14（解决三圈无限重启）](#4-阶段三备份原厂分区--刷入-android-14解决三圈无限重启)
- [5. 阶段四：国内无外网初始化、代理配置与 Google 套件排坑](#5-阶段四国内无外网初始化代理配置与-google-套件排坑)
- [6. 阶段五：刷机收尾（清理旧版驱动、恢复 Win11 内存完整性）](#6-阶段五刷机收尾清理旧版驱动恢复-win11-内存完整性)
- [7. 踩坑速查表](#7-踩坑速查表)

---

## 1. 实测可用软件与镜像清单

| 用途 | 文件 / 工具 | 大小（实测） | 目标分区 / 说明 | 公开来源 |
| :--- | :--- | :--- | :--- | :--- |
| BL 永久解锁 | `Kirin-Tool v2.4.2` | ~82.7 MB | 需 `.NET 8 Desktop Runtime` | [kethily-daniel/Kirin-Tool](https://github.com/kethily-daniel/Kirin-Tool) |
| Android 14 ROM（带 GApps） | `LeaOS-21.0-20260118-iceows-google-pot.img` | `2,197,798,912` B (~2.05 GB) | 刷入 `system`（EROFS，可放入 `2392 MB` 的 `system_a`） | [SourceForge: altairfr-huawei / LeaOS-21.0](https://sourceforge.net/projects/altairfr-huawei/files/LeaOS-21.0/LeaOS-21.0-20260118-iceows-google-pot.img.xz/download) |
| A14 适配内核（Permissive） | `Kirin710_EMUI9.1_PM-2025.11.16-04_35.img` | `13,094,912` B (~12.5 MB) | 刷入 `kernel`（4.9.148+ 含 Android 14 必需补丁） | [Iceows/android_kernel_huawei_kirin710-9](https://github.com/Iceows/android_kernel_huawei_kirin710-9/releases) |
| 第三方 Recovery | `SHRP_v3.1_stable-Unofficial_potter-1773176050.zip`（内含 `recovery.img`） | `27,146,240` B (~25.9 MB) | 刷入 `recovery_ramdisk`（内含 Iceows 定制 `make_f2fs`） | [SourceForge: altairfr-huawei / SHRP-Recovery](https://sourceforge.net/projects/altairfr-huawei/files/SHRP-Recovery/SHRP_v3.1_stable-Unofficial_potter-1773176050.zip/download) |
| 原厂底包备份 | `stock_KERNEL.img` / `stock_RECOVERY_RAMDISK.img` | 24 MB / 32 MB | 从官方 `UPDATE.APP` 提取留存，用于随时救砖回退 | 官方 EMUI 9.1 固件包 |
| 代理工具 | `FlClash-0.9.4-android-arm64-v8a.apk` | ~58.0 MB | `arm64-v8a` 版本，支持 URL Scheme 一键导入配置 | [chen08209/FlClash](https://github.com/chen08209/FlClash/releases) |
| 中文输入法 | `doubaoime_v1.0.0_official.apk` | ~139.4 MB | 豆包手机输入法官方包 | 字节跳动官方 CDN |

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

1. **根因一：原厂 4.9.148 内核缺少 Android 14 必需补丁**
   - 直接用 EMUI 9.1 原厂内核启动 Android 14 会因缺少 `LOOP_CONFIGURE` / loop 设备与挂载相关内核补丁导致启动失败。
   - **解法**：必须刷入上文 Iceows 编译的 `Kirin710_EMUI9.1_PM-2025.11.16-04_35.img`。
2. **根因二：EMUI 9.1 原厂 Recovery 格式化 `/data` 导致的 F2FS Superblock 校验冲突（最隐蔽！）**
   - 如果使用 EMUI 9.1 原厂 Recovery 执行“恢复出厂设置 / 格式化 Data”，它会启用较新的 F2FS 特性位 `superblock features = 481 (encrypt verity quota_ino)`。
   - 导致 A14 内核启动挂载 `/dev/block/mmcblk0p70` 时报错：
     ```text
     F2FS-fs (mmcblk0p70): Invalid checksum crc(0x...)
     ```
     随后 `mount_all` 失败 → `/data` 未挂载 → `credstore` 无限崩溃 → 画面永远停在 LineageOS 三个转圈动画。

### 4.4 正确的 `/data` 格式化步骤（在 SHRP 中完成）
1. 刷完 `recovery_ramdisk` 后，拔线或按键重启进入 **SHRP Recovery**。
2. 首次进入 SHRP 提示 `Keep System Read Only?` 时，**保持只读即可**（不要随意挂载修改只读的 EROFS `system`）。
3. 通过 SHRP 内的 `adb shell`，调用 Iceows 定制的 `/system/bin/make_f2fs`（`Ver Iceows (Huawei EMUI9): 1.13.0`）手动重新格式化 `userdata`：
   ```sh
   # 格式化 userdata（带 encrypt 特性，不带引发冲突的校验特性）
   /system/bin/make_f2fs -f -O encrypt -w 4096 /dev/block/by-name/userdata 233340896

   # 实测直接挂载验证（必须返回 0 且容量正常约 111G）
   mount -t f2fs /dev/block/by-name/userdata /data && df -h /data && umount /data

   # 顺手清理 /cache
   rm -rf /cache/*
   reboot
   ```
4. 重启后即可顺利通过启动动画进入 Android 14（系统识别为 `POT-LX1` / `HWPOT`，内核 `4.9.148+ aarch64`）。

---

## 5. 阶段四：国内无外网初始化、代理配置与 Google 套件排坑

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

---

## 6. 阶段五：刷机收尾（清理旧版驱动、恢复 Win11 内存完整性）

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

## 7. 踩坑速查表

| 现象 / 报错 | 实际根因 | 解决方案 |
| :--- | :--- | :--- |
| 设备管理器旧版华为驱动报 Code 39 | Win11 内存完整性拦截 `ew_usbccgpfilter.sys` | 刷机期临时关闭内存完整性并重启；刷完后 `pnputil` 卸载旧驱动再重新开启 |
| `ADB Interface` 正常但 `adb devices` 为空 | `HiSuite` / `hwtransport` 独占 WinUSB 句柄 | `Stop-Process -Name HiSuite,hwtransport -Force` |
| 短接后显示 `USB SER` (`VID_12D1&PID_3609`) 无驱动 | 未自动匹配 `HUAWEI USB COM 1.0` | 用 SetupAPI `DiInstallDevice` 绑定 WHQL 签名的 `hw_quser.inf` |
| SWTP 报 `Failed to send partition header` | EMUI 9.1 安全补丁 `2021-03-01` 已封堵 SWTP | 放弃 SWTP，改用拆机硬件短接 + `Kirin-Tool v2.4.2` |
| `Kirin-Tool` 报 `Access to path ...\dload is denied` | 进程工作目录（CWD）不在 `Kirin-Tool` 文件夹 | 通过快捷方式指定 `WorkingDirectory` 为 `Kirin-Tool` 目录后运行 |
| 刷完 A14 卡在 LineageOS 三个转圈无限重启 | 原厂内核缺 A14 补丁 + 原厂 Recovery 的 F2FS Superblock CRC 校验冲突 | 刷 Iceows A14 内核 + 刷 SHRP，用 SHRP 内 Iceows `make_f2fs -f -O encrypt -w 4096` 重格 `userdata` |
| 误下载 `1-Huawei-DataPrep-A14-AB-v1.0-signed.zip` | 该包仅适用于 `hi6250`（麒麟 659） | **严禁刷入**麒麟 710 设备 |
| 首次进入系统卡在“正在准备我的设备” | 国内无外网，Google SetupWizard 联网超时 | 离线跳过开机向导，进桌面先用 ADB 装代理再登录 Google |
| Play 商店点击 Chrome“安装”完全无反应 | 首次登录后台自更新导致透明 `SheetUiBuilderHostActivity` 卡死挡住点击 | 划掉后台或执行 `adb shell am force-stop com.android.vending` 后重开即可 |
