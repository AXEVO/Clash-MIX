SKIPUNZIP=1
sdcard_dir="/mnt/user/0/emulated/0/Android"

unzip -o "$ZIPFILE" -x 'META-INF/*' -d $MODPATH >&2

mkdir -p $sdcard_dir/Clash
if [ -f "$sdcard_dir/Clash/Clash配置.yaml" ]; then
  cp "$sdcard_dir/Clash/Clash配置.yaml" "$sdcard_dir/Clash/更新模块前的Clash配置.yaml"
  rm -rf $sdcard_dir/Clash/Clash配置.yaml
fi
cp -rf $MODPATH/Clash/* "$sdcard_dir/Clash/"
rm -rf $MODPATH/Clash

ln -sf "$sdcard_dir/Clash/Clash配置.yaml" "$MODPATH/Proxy/config.yaml"

if [ "$KSU" = true ]; then
  ln -sf /data/adb/modules/Clash/Proxy/WebUI $MODPATH/webroot
fi

chmod 777 -Rf $MODPATH