(
  
  until [ "$(getprop sys.boot_completed)" = "1" ]; do
      sleep 2
  done

  until [ -d "/sdcard/Android" ]; do
      sleep 2
  done

  sdcard_dir="/sdcard"
  clash_dir="$sdcard_dir/Android/Clash"

  if [ -d "$clash_dir" ]; then

    backup_dir="$sdcard_dir/Android/Clash卸载备份-[$(date +%Y.%m.%d-%H.%M)]"

    mkdir -p "$backup_dir"

    [ -f "$clash_dir/Clash配置.yaml" ] && cp "$clash_dir/Clash配置.yaml" "$backup_dir/Clash配置.yaml"

    [ -f "$clash_dir/工具/自定义直连.yaml" ] && cp "$clash_dir/工具/自定义直连.yaml" "$backup_dir/自定义直连.yaml"

    [ -f "$clash_dir/工具/自定义代理.yaml" ] && cp "$clash_dir/工具/自定义代理.yaml" "$backup_dir/自定义代理.yaml"

    echo "此目录为 Clash MIX 卸载后配置备份，欢迎下次使用" > "$backup_dir/说明.txt"
    echo "Telegram频道  @wocao_esu  https://t.me/wocao_esu" >> "$backup_dir/说明.txt"
    echo "Github  https://github.com/AXEVO/Clash-MIX" >> "$backup_dir/说明.txt"

    rm -rf "$clash_dir"

  fi
  
) &