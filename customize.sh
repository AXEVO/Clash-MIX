SKIPUNZIP=1

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

backup_dir="$(ls -dt /sdcard/Android/Clash卸载备份-* 2>/dev/null | head -n 1)"

if [ -f "$sdcard_work/Clash配置.yaml" ]; then
  install_mode="update"
elif [ -n "$backup_dir" ] && [ -f "$backup_dir/Clash配置.yaml" ]; then
  install_mode="restore"
else
  install_mode="fresh"
fi


case "$install_mode" in
  update)

    cp -af "$sdcard_work/工具/自定义代理.yaml" "$MODPATH/Clash/工具/自定义代理.yaml" 2>/dev/null
    cp -af "$sdcard_work/工具/自定义直连.yaml" "$MODPATH/Clash/工具/自定义直连.yaml" 2>/dev/null

    if should_keep_old_config "$sdcard_work/Clash配置.yaml" "$MODPATH/Clash/Clash配置.yaml"; then
      ui_print "🟩配置文件无更新 保留原有 Clash配置.yaml🟩"
      ui_print "🟩模块内置Clash配置文件模板备份位于🟩"
      ui_print "🟩[内部存储/Android/Clash/资料/配置模板]🟩"
      cp -af "$sdcard_work/Clash配置.yaml" "$MODPATH/Clash/Clash配置.yaml"
    else
      cp -af "$sdcard_work/Clash配置.yaml" "$MODPATH/Clash/更新前配置.yaml"
      ui_print "🟨Clash配置.yaml已更新 需要重新填写订阅链接🟨"
      ui_print "🟨安装模块更新前的Clash配置文件已备份到🟨"
      ui_print "🟨[内部存储/Android/Clash/更新前配置.yaml]🟨"
      ui_print "🟨请从旧配置中复制订阅链接后 再填写到新配置🟨"
    fi
    ;;

  restore)
    ui_print "🟨检测到$(basename "$backup_dir")🟨"

    cp -af "$backup_dir/自定义代理.yaml" "$MODPATH/Clash/工具/自定义代理.yaml" 2>/dev/null
    cp -af "$backup_dir/自定义直连.yaml" "$MODPATH/Clash/工具/自定义直连.yaml" 2>/dev/null

    if should_keep_old_config "$backup_dir/Clash配置.yaml" "$MODPATH/Clash/Clash配置.yaml"; then
      ui_print "🟩配置文件无更新 使用卸载备份的配置.yaml🟩"
      ui_print "🟩模块内置Clash配置文件模板备份位于🟩"
      ui_print "🟩[内部存储/Android/Clash/资料/配置模板]🟩"
      cp -af "$backup_dir/Clash配置.yaml" "$MODPATH/Clash/Clash配置.yaml"
    else
      cp -af "$backup_dir/Clash配置.yaml" "$MODPATH/Clash/卸载备份配置.yaml"
      ui_print "🟨Clash配置.yaml已更新 卸载备份已复制到🟨"
      ui_print "🟨[内部存储/Android/Clash/卸载备份配置]🟨"
      ui_print "🟨请从旧配置中复制订阅链接后 再填写到新配置🟨"
    fi
    ;;

  fresh)
    ui_print "🟨全新安装 请安装完成后填写订阅链接并重启🟨"
    ui_print "🟨[内部存储/Android/Clash/Clash配置.yaml]🟨"
    ;;
esac


rm -rf "$sdcard_work"
mkdir -p /sdcard/Android
cp -af "$MODPATH/Clash" /sdcard/Android/
rm -rf "$MODPATH/Clash"


ln -sf "$sdcard_work/Clash配置.yaml" "$MODPATH/Proxy/config.yaml"
ln -sf "$sdcard_work/工具/自定义代理.yaml" "$MODPATH/Proxy/rule_providers/userProxy.yaml"
ln -sf "$sdcard_work/工具/自定义直连.yaml" "$MODPATH/Proxy/rule_providers/userDirect.yaml"
if [ "$KSU" = true ] || [ "$KERNELPATCH" = true ]; then
  ln -sf /data/adb/modules/Clash/Proxy/WebUI "$MODPATH/webroot"
fi

chmod 777 -Rf "$MODPATH"
