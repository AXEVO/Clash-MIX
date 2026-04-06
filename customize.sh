SKIPUNZIP=1

module_dir="/data/adb/modules/Clash"
sdcard_work="/sdcard/Android/Clash"

should_keep_old_config() {
  old_cfg="$1"
  new_cfg="$2"

  [ -f "$old_cfg" ] || return 1
  [ -f "$new_cfg" ] || return 0

  old_ver="$(sed -n 's/^# *version[：:] *\([0-9][0-9]*\).*$/\1/p' "$old_cfg" 2>/dev/null | head -n 1)"
  new_ver="$(sed -n 's/^# *version[：:] *\([0-9][0-9]*\).*$/\1/p' "$new_cfg" 2>/dev/null | head -n 1)"

  [ -z "$old_ver" ] && return 1
  [ -z "$new_ver" ] && return 0
  [ "$new_ver" -gt "$old_ver" ] 2>/dev/null && return 1

  return 0
}

ui_print "- 解压模块文件到 MODPATH"
unzip -o "$ZIPFILE" -x 'META-INF/*' -d "$MODPATH" >&2

install_mode="fresh"
backup_dir=""

if [ -d "$sdcard_work" ]; then
  install_mode="update"
else
  backup_dir="$(ls -dt /sdcard/Android/Clash卸载备份-* 2>/dev/null | head -n 1)"
  if [ -n "$backup_dir" ] && [ -d "$backup_dir" ]; then
    install_mode="restore"
  fi
fi

ui_print "- 安装模式：$install_mode"

case "$install_mode" in
  update)
    ui_print "- 保留更新前的用户配置"

    if [ -f "$sdcard_work/工具/自定义代理.yaml" ]; then
      cp -af "$sdcard_work/工具/自定义代理.yaml" "$MODPATH/Clash/工具/自定义代理.yaml"
    fi

    if [ -f "$sdcard_work/工具/自定义直连.yaml" ]; then
      cp -af "$sdcard_work/工具/自定义直连.yaml" "$MODPATH/Clash/工具/自定义直连.yaml"
    fi

    if should_keep_old_config "$sdcard_work/Clash配置.yaml" "$MODPATH/Clash/Clash配置.yaml"; then
      ui_print "- 保留原有 Clash配置.yaml"
      cp -af "$sdcard_work/Clash配置.yaml" "$MODPATH/Clash/Clash配置.yaml"
    else
      ui_print "- 使用模块内置 Clash配置.yaml"
    fi
    ;;

  restore)
    ui_print "- 检测到卸载备份：$(basename "$backup_dir")"

    if [ -f "$backup_dir/自定义代理.yaml" ]; then
      cp -af "$backup_dir/自定义代理.yaml" "$MODPATH/Clash/工具/自定义代理.yaml"
    fi

    if [ -f "$backup_dir/自定义直连.yaml" ]; then
      cp -af "$backup_dir/自定义直连.yaml" "$MODPATH/Clash/工具/自定义直连.yaml"
    fi

    if should_keep_old_config "$backup_dir/Clash配置.yaml" "$MODPATH/Clash/Clash配置.yaml"; then
      ui_print "- 保留备份中的 Clash配置.yaml"
      cp -af "$backup_dir/Clash配置.yaml" "$MODPATH/Clash/Clash配置.yaml"
    else
      ui_print "- 使用模块内置 Clash配置.yaml"
    fi
    ;;

  fresh)
    ui_print "- 全新安装，使用模块内置配置"
    ;;
esac

ui_print "- 部署内部存储工作目录"
rm -rf "$sdcard_work"
mkdir -p /sdcard/Android
cp -af "$MODPATH/Clash" /sdcard/Android/
rm -rf "$MODPATH/Clash"

ui_print "- 配置软链接"
mkdir -p "$MODPATH/Proxy/rule_providers"
ln -sf "$sdcard_work/Clash配置.yaml" "$MODPATH/Proxy/config.yaml"
ln -sf "$sdcard_work/工具/自定义代理.yaml" "$MODPATH/Proxy/rule_providers/userProxy.yaml"
ln -sf "$sdcard_work/工具/自定义直连.yaml" "$MODPATH/Proxy/rule_providers/userDirect.yaml"
if [ "$KSU" = true ] || [ "$KERNELPATCH" = true ]; then
  ln -sf /data/adb/modules/Clash/Proxy/WebUI "$MODPATH/webroot"
fi

ui_print "- 设置权限"
chmod 777 -Rf "$MODPATH"

ui_print "- Clash MIX 安装完成"
