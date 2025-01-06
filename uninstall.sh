{
  until [ "$(getprop sys.boot_completed)" = "1" ]; do
      sleep 2
  done

  until [ -d "/sdcard/Android" ]; do
      sleep 2
  done

  sdcard_dir="/sdcard"

  if [ -f "$sdcard_dir/Android/Clash/Clash配置.yaml" ]; then
    cp "$sdcard_dir/Android/Clash/Clash配置.yaml" "$sdcard_dir/Android/Clash模块配置-卸载备份.yaml"
  fi

  rm -rf "$sdcard_dir/Android/Clash"
} &