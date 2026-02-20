# 三星 OneUI 代理兼容性调研（GitHub 方向）

## 调研目标
- 聚焦 OneUI 上常见的代理副作用：VoLTE/来电异常、IMS 相关异常、待机功耗与唤醒锁。
- 优先参考 GitHub 上代理工具仓库的可落地方案。

## 主要结论
1. 在 Android TProxy/透明代理场景里，最常见且可移植的缓解方式是：
   - 通过 **按应用/UID 排除**（blacklist bypass）让 IMS、电话、短信相关系统组件绕过代理。
2. 该方式在多个代理脚本项目中都作为核心能力提供（`BYPASS_APPS_LIST` / `PROXY_APPS_LIST` 或 `exclude-package` 思路）。
3. 对 OneUI 设备，优先排除与 IMS/通话强相关的包名，通常能明显降低 VoLTE 失败与来电异常概率。

## 参考仓库与证据点
- AndroidTProxyShell（本模块当前使用的上游）
  - 仓库：<https://github.com/CHIZI-0618/AndroidTProxyShell>
  - 能力：支持基于包名/UID 的黑白名单分流，适合给系统通信组件做 bypass。
- box4magisk
  - 文档明确给出 `BYPASS_APPS_LIST` / `PROXY_APPS_LIST` 作为按应用排除/代理手段。
  - 参考：
    - <https://github.com/CHIZI-0618/box4magisk/blob/main/README.md>
    - <https://github.com/CHIZI-0618/box4magisk/blob/main/README_zh.md>
- box_for_magisk
  - Clash 文档保留 `exclude-package` / `exclude-uid-range` 等思路，说明 Android 侧排除系统组件是常见实践。
  - 参考：<https://github.com/taamarin/box_for_magisk/blob/main/box/clash/config_docs.yaml>

## OneUI 建议排除包（首批）
- `com.sec.imsservice`
- `com.sec.epdg`
- `com.android.phone`
- `com.samsung.android.app.telephonyui`
- `com.samsung.android.dialer`
- `com.samsung.android.incallui`
- `com.samsung.android.messaging`
- `com.samsung.android.smartcallprovider`

## 进一步排障建议
- 若仍出现异常：
  1. 先关闭 IPv6 代理（`PROXY_IPV6=0`）再观察 24h。
  2. 再尝试关闭 DNS 劫持（`DNS_HIJACK_ENABLE=0`）做 A/B 对照。
  3. 保持代理核心与规则不变，仅改 1 个变量，方便定位。


## 本次新增结论：蓝牙唤醒锁（`hal_Bluetooth_lock` / `898000.qcom,qup_uart`）

### 线上资料结论（截至本次调研）
- 社区（XDA/Pixel 社区/Reddit）存在大量同类现象报告，但**没有一个稳定、通用、且无需改内核/厂商蓝牙栈的“直接一键修复”方案**。
- 现有“有效案例”大多是：
  1. 关闭特定蓝牙外设特性（高频心跳/通知同步）；
  2. 避免代理链路干预蓝牙相关网络流量；
  3. 在系统层做更细粒度绕过后功耗恢复。

### 对本模块可落地的措施
1. 增加 `BLUETOOTH_BYPASS_ENABLE`（默认开）与 `BLUETOOTH_UID`：
   - 默认值 `1002`，来源于 AOSP 的 `AID_BLUETOOTH`；
   - 支持 `BLUETOOTH_UID=auto`，脚本会从 `/system/etc/passwd` 或 `/vendor/etc/passwd` 自动探测蓝牙 UID；
   - 让 Android 蓝牙系统 UID（`AID_BLUETOOTH`）流量在 OUTPUT 侧直接 bypass，避免进入代理链。
2. 与既有 OneUI 方案叠加：
   - 保留 IMS/电话/短信相关包名绕过；
   - 若仍异常，继续做单变量 A/B：`PROXY_IPV6=0`、`DNS_HIJACK_ENABLE=0`。

### 资料来源（用于确认“暂无直接通用修复”）
- XDA 讨论：`hal_bluetooth_lock` 长时间唤醒（机型/ROM相关，缺乏统一修复）
  - <https://xdaforums.com/t/hal_bluetooth_lock-wakelock.3753994/>
- Google Pixel 社区：`hal_bluetooth_lock active 100%` 反馈
  - <https://support.google.com/pixelphone/thread/235709034/hal-bluetooth-lock-active-100-of-the-time-on-pixel-7a>
- 社区聚合讨论：`qup_uart` 与蓝牙并发时待机耗电
  - <https://xdaforums.com/tags/qup_uart/>
