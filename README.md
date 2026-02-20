# Clash MIX - 安装即用且运行稳定的透明代理模块

---

## 模块特性
1. **基于 TProxy 的透明代理方案**  
   模块内置 AndroidTProxyShell（`Scripts/tproxy.sh`），通过策略路由 + iptables TPROXY 方式接管流量，规避 Tun 在部分设备上的兼容性问题。
   
2. **可维护配置，便于按设备调优**  
   新增 `Scripts/tproxy.conf`，可独立调整端口、DNS 劫持、IPv6、热点代理等参数，无需改动主脚本。

3. **日志输出和配置管理便捷**  
   模块的日志输出和配置文件存放在 `/内部存储/Android/Clash` 文件夹中，现在可以更加方便地编辑配置文件和查看日志了。

4. **tproxy.sh 与上游保持一致**  
   模块内 `Scripts/tproxy.sh` 直接同步自 AndroidTProxyShell 上游脚本，便于后续差异排查和版本升级。

5. **常用功能全支持**    
   - 在 Magisk 或 KSU 管理器内一键更新  
   - Action 按键支持快速重启内核
   - KSU管理器内置网页面板支持  
   - 更新或卸载模块时保留旧配置文件  
   - 通过模块开关控制内核的启停等功能  

---

## 安装方式
1. **卸载已安装的所有代理模块**  
   包括 Clash MIX 3.0。

2. **重启手机一次**  
   特别是之前使用3.0的用户，需要重启以恢复环境

3. **在面具/ksu中安装 Clash MIX 模块**  
   然后在 `/内部存储/Android/Clash/Clash配置.yaml` 文件中填写你的订阅链接。

4. **重启手机并解锁屏幕**  
   内核将自动启动并下发 TProxy 规则。用 Chrome 等非国产浏览器打开 [http://127.0.0.1:9090/ui](http://127.0.0.1:9090/ui) 即可进入本地面板进行调整。

---

## 注意事项
1. **谨慎修改配置文件**  
   - `Clash配置.yaml` 文件中包含注释说明请注意阅读，请勿随意更改 `tproxy-port`、`dns.listen`、`sniffer` 等关键设置，以免出现问题。  
   - 如果配置出现问题，请到 `/内部存储/Android/Clash` 文件夹中查看默认配置备份，或者重新刷入模块。原有配置文件会被保留并重命名。

2. **手机开机后解锁后启动内核**  
   - 每次手机开机后需要解锁手机一次以解密 `data` 分区，内核才会启动。  
   - 如果未输入密码直接通过通知栏等方式开启热点，热点将无法被代理，使用随身WiFi用户请注意此项。

3. **TProxy 调优入口**  
   - 模块目录 `Scripts/tproxy.conf` 为 TProxy 主配置文件。  
   - 若设备不支持 TPROXY，可将 `PROXY_MODE` 调整为 `0`（自动）或 `2`（REDIRECT 仅 TCP）。  
   - 若出现 IPv6 异常，可将 `PROXY_IPV6=0` 后重启内核。

4. **三星 OneUI 兼容建议（默认已预置）**  
   - 模块已在 `tproxy.conf` 中预置 `BYPASS_APPS_LIST`，绕过 `com.sec.imsservice`、`com.sec.epdg`、拨号与通话 UI 等系统应用，以降低 VoLTE/来电异常风险。  
   - 如果你不是三星设备，可按需删减该列表。  
   - 若仍有待机耗电或唤醒锁异常，可继续尝试 `PROXY_IPV6=0` 或 `DNS_HIJACK_ENABLE=0`。
   - 新增 `BLUETOOTH_BYPASS_ENABLE=1`（默认开启），可让蓝牙系统 UID（默认 1002）绕过代理，缓解 `hal_Bluetooth_lock` / `898000.qcom,qup_uart` 持续唤醒。
   - `1002` 来自 Android AOSP 的 `AID_BLUETOOTH` 约定；若厂商ROM有改动，可将 `BLUETOOTH_UID=auto` 自动探测。

---

## 使用小技巧
面板支持网页应用特性，在 Chrome 等浏览器中打开网页面板：[http://127.0.0.1:9090/ui](http://127.0.0.1:9090/ui)，点击右上角选项，选择 `添加到主屏幕` ，并选择 `安装` 可在桌面创建快捷方式，点击后即可全屏打开面板，且在内核未启动时也能打开面板，体验更好



更多特性 **is coming sooooooon**  敬请期待！
---
