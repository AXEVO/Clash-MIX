SKIPUNZIP=1
module_dir="/data/adb/modules/Clash"
sdcard_dir="/sdcard/Android"

#解压全部文件到模块安装目录
unzip -o "$ZIPFILE" -x 'META-INF/*' -d $MODPATH >&2
#开始处理内部存储中的配置
mkdir -p $sdcard_dir/Clash
if [ -f "$sdcard_dir/Clash/Clash配置.yaml" ]; then
  cp "$sdcard_dir/Clash/Clash配置.yaml" "$sdcard_dir/Clash/更新模块前的Clash配置.yaml"
  rm -rf $sdcard_dir/Clash/Clash配置.yaml
fi
cp -rf $MODPATH/Clash/* "$sdcard_dir/Clash/"
rm -rf $MODPATH/Clash
#不覆盖用户自定义规则
if [ -d "$module_dir/Proxy/rule_providers" ]; then
  rm -rf $MODPATH/Proxy/rule_providers/userDirect.yaml
  rm -rf $MODPATH/Proxy/rule_providers/userProxy.yaml
  cp "$module_dir/Proxy/rule_providers/userDirect.yaml" "$MODPATH/Proxy/rule_providers/userDirect.yaml"
  cp "$module_dir/Proxy/rule_providers/userProxy.yaml" "$MODPATH/Proxy/rule_providers/userProxy.yaml"
fi
#配置软链接
ln -sf "$sdcard_dir/Clash/Clash配置.yaml" "$MODPATH/Proxy/config.yaml"
#适配KSU
if [ "$KSU" ] || [ "$APATCH" ]; then
  ln -sf /data/adb/modules/Clash/Proxy/WebUI/ZashBoard $MODPATH/webroot
fi
#---
chmod 777 -Rf $MODPATH
