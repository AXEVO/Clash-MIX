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
