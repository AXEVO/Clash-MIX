SKIPUNZIP=1
sdcard_dir="/data/media/0/Android"

unzip -o "$ZIPFILE" -x 'META-INF/*' -d $MODPATH >&2

mv "$MODPATH/Clash" "$sdcard_dir"
ln -sf "$sdcard_dir/Clash/Clash配置文件.yaml" "$MODPATH/Proxy/config.yaml"

if [ "$KSU" = true ]; then
  ln -sf $MODPATH/Proxy/WebUI $MODPATH/webroot
fi


chmod 777 -Rf $MODPATH