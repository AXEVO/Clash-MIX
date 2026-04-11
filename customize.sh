SKIPUNZIP=1

module_dir="/data/adb/modules/Clash"
sdcard_work="/sdcard/Android/Clash"

should_keep_old_config() {
  old_cfg="$1"
  new_cfg="$2"

  [ -f "$old_cfg" ] || return 1
  [ -f "$new_cfg" ] || return 0

  old_ver="$(grep -i -m 1 '^[[:space:]]*# *version' "$old_cfg" 2>/dev/null | tr -cd '0-9')"
  new_ver="$(grep -i -m 1 '^[[:space:]]*# *version' "$new_cfg" 2>/dev/null | tr -cd '0-9')"

  [ -z "$old_ver" ] && return 1
  [ -z "$new_ver" ] && return 0
  [ "$new_ver" -gt "$old_ver" ] 2>/dev/null && return 1

  return 0
}


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


case "$install_mode" in
  update)

    if [ -f "$sdcard_work/工具/自定义代理.yaml" ]; then
      cp -af "$sdcard_work/工具/自定义代理.yaml" "$MODPATH/Clash/工具/自定义代理.yaml"
    fi

    if [ -f "$sdcard_work/工具/自定义直连.yaml" ]; then
      cp -af "$sdcard_work/工具/自定义直连.yaml" "$MODPATH/Clash/工具/自定义直连.yaml"
    fi

    if should_keep_old_config "$sdcard_work/Clash配置.yaml" "$MODPATH/Clash/Clash配置.yaml"; then
      ui_print "🟩配置文件无更新 保留原有 Clash配置.yaml🟩"
      ui_print "🟩配置模板请在[/Android/Clash/资料]内查看🟩"
      cp -af "$sdcard_work/Clash配置.yaml" "$MODPATH/Clash/Clash配置.yaml"
    else
      ui_print "🟨Clash配置.yaml已更新 请重新填写订阅链接🟨"
    fi
    ;;

  restore)
    ui_print "🟨检测到卸载备份：$(basename "$backup_dir")🟨"

    if [ -f "$backup_dir/自定义代理.yaml" ]; then
      cp -af "$backup_dir/自定义代理.yaml" "$MODPATH/Clash/工具/自定义代理.yaml"
    fi

    if [ -f "$backup_dir/自定义直连.yaml" ]; then
      cp -af "$backup_dir/自定义直连.yaml" "$MODPATH/Clash/工具/自定义直连.yaml"
    fi

    if should_keep_old_config "$backup_dir/Clash配置.yaml" "$MODPATH/Clash/Clash配置.yaml"; then
      ui_print "🟩配置文件无更新 使用备份中的 Clash配置.yaml🟩"
      cp -af "$backup_dir/Clash配置.yaml" "$MODPATH/Clash/Clash配置.yaml"
    else
      ui_print "🟨Clash配置.yaml已更新 请重新填写订阅链接🟨"
    fi
    ;;

  fresh)
    ui_print "🟨全新安装 请安装完成后填写订阅链接并重启手机🟨"
    ;;
esac


rm -rf "$sdcard_work"
mkdir -p /sdcard/Android
cp -af "$MODPATH/Clash" /sdcard/Android/
rm -rf "$MODPATH/Clash"


mkdir -p "$MODPATH/Proxy/rule_providers"
ln -sf "$sdcard_work/Clash配置.yaml" "$MODPATH/Proxy/config.yaml"
ln -sf "$sdcard_work/工具/自定义代理.yaml" "$MODPATH/Proxy/rule_providers/userProxy.yaml"
ln -sf "$sdcard_work/工具/自定义直连.yaml" "$MODPATH/Proxy/rule_providers/userDirect.yaml"
if [ "$KSU" = true ] || [ "$KERNELPATCH" = true ]; then
  ln -sf /data/adb/modules/Clash/Proxy/WebUI "$MODPATH/webroot"
fi


chmod 777 -Rf "$MODPATH"


