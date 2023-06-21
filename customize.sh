SKIPUNZIP=1
ASH_STANDALONE=1

status=""
architecture=""
uid="0"
gid="3005"
clash_data_dir="/data/clash"
modules_dir="/data/adb/modules"
bin_path="/system/bin/"
dns_path="/system/etc"
clash_adb_dir="/data/adb"
clash_service_dir="/data/adb/service.d"
busybox_data_dir="/data/adb/magisk/busybox"
ca_path="${dns_path}/security/cacerts"
clash_data_dir_kernel="${clash_data_dir}/kernel"
clash_data_sc="${clash_data_dir}/scripts"
mod_config="${clash_data_sc}/clash.config"
yacd_dir="${clash_data_dir}/dashboard"
latest=$(date +%Y%m%d%H%M)
#--------------------------------------------------
ui_print "- 正在检测安装环境"
if [ -d "${CPFM_mode_dir}" ]; then
    touch "${CPFM_mode_dir}/remove" && ui_print "- CPFM古董模块在重启后将会被删除."
fi

if [ "$BOOTMODE" != true ]; then
  abort "请在Magisk Manager中安装模块"
else
  ui_print "- Magisk版本： $MAGISK_VER ($MAGISK_VER_CODE)"
fi 

if [ "$API" -lt 19 ]; then
  ui_print "不支持的sdk: $API"
  abort "- 最小支持版本Android 4.4"
else
  ui_print "- 本设备 sdk: $API"
fi

if [ "$ARCH" != "arm" ] && [ "$ARCH" != "arm64" ] && [ "$ARCH" != "x86" ] && [ "$ARCH" != "x64" ]; then
  abort "不支持本平台: $ARCH"
else
  ui_print "- 本设备平台: $ARCH"
fi
#----------------------------------------------------
ui_print "- 正在处理备份"
if [ -d "${clash_data_dir}" ] ; then
    ui_print "- 旧的clash文件已移动到clash.old"
    if [ -d "/data/clash.old" ] ; then
        rm -rf /data/clash.old
    fi
    mkdir -p /data/clash.old
    mv ${clash_data_dir}/* data/clash.old/
fi

if [  -f "/data/clash.old/config.yaml" ] ; then
    ui_print "- >>>>>本次安装为模块升级，已恢复原订阅链接<<<<<"
    mv /data/clash.old/config.yaml ${clash_data_dir}/
else 
    if [  -f "/data/clash.delete/config.yaml" ] ; then
    ui_print "- >>>>>检测到上次卸载Clash模块时的配置信息（内含订阅链接）<<<<<"
    ui_print "- >>>>>已移动到Clash/config.old 如需要，请自行复制订阅链接<<<<<"
    mv /data/clash.delete/config.yaml ${clash_data_dir}/config.old
    else
    ui_print "- >>>>>全新安装 请根据提示在指定位置填写订阅链接<<<<<" 
    fi
fi
#-------------------------------------------------------
ui_print "- 正在安装内核-$ARCH "
mkdir -p ${clash_data_dir}
mkdir -p ${clash_data_dir_kernel}
mkdir -p ${MODPATH}${ca_path}
mkdir -p ${clash_data_dir}/dashboard
mkdir -p ${MODPATH}/system/bin
mkdir -p ${clash_data_dir}/run
mkdir -p ${clash_data_dir}/scripts
mkdir -p ${clash_data_dir}/assets

case "${ARCH}" in
    arm)
        architecture="armv7"
        ;;
    arm64)
        architecture="armv8"
        ;;
    x86)
        architecture="386"
        ;;
    x64)
        architecture="amd64"
        ;;
esac

unzip -o "${ZIPFILE}" -x 'META-INF/*' -d $MODPATH >&2

tar -xjf ${MODPATH}/binary/${ARCH}.tar.bz2 -C ${clash_data_dir_kernel}/&& echo "- 安装内核成功" || echo "- 安装内核失败"
mv ${clash_data_dir_kernel}/setcap ${MODPATH}${bin_path}/
mv ${clash_data_dir_kernel}/getpcaps ${MODPATH}${bin_path}/
mv ${clash_data_dir_kernel}/getcap ${MODPATH}${bin_path}/

if [ ! -f "${bin_path}/ss" ] ; then
    mv ${clash_data_dir_kernel}/ss ${MODPATH}${bin_path}/
else
    rm -rf ${clash_data_dir_kernel}/ss
fi
#安装附件-------------------------------------------------
ui_print "- 正在安装流量显示面板"
if [ ! -d /data/dashboard ] ; then
    rm -rf "${clash_data_dir}/dashboard/*"
fi
unzip -o ${MODPATH}/dashboard.zip -d ${clash_data_dir}/dashboard/ >&2

ui_print "- 正在移动文件"
rm -rf "${clash_data_dir}/scripts/*"
mv ${MODPATH}/scripts/ ${clash_data_dir}/
mv ${MODPATH}/rule_providers/ ${clash_data_dir}/
mv ${MODPATH}/proxy_providers/ ${clash_data_dir}/
mv ${MODPATH}/assets/ ${clash_data_dir}/
mv ${MODPATH}/备用/ ${clash_data_dir}/
mv ${clash_data_dir}/scripts/clash.config ${clash_data_dir}/
mv ${clash_data_dir}/scripts/dnstt/dnstt-client ${clash_data_dir_kernel}/

ui_print "- 正在安装配置"
mv ${clash_data_dir}/scripts/config.yaml ${clash_data_dir}/
mv ${clash_data_dir}/scripts/template ${clash_data_dir}/

ui_print "- 正在安装密钥和Geo文件"
mv ${clash_data_dir}/scripts/cacert.pem ${MODPATH}${ca_path}
mv ${MODPATH}/GeoX/* ${clash_data_dir}/

ui_print "- 配置开机自启"
if [ ! -d /data/adb/service.d ] ; then
    mkdir -p /data/adb/service.d
fi

ui_print "- 创建系统DNS配置"
if [ ! -f "${dns_path}/resolv.conf" ] ; then
    touch ${MODPATH}${dns_path}/resolv.conf
    echo nameserver 8.8.8.8 > ${MODPATH}${dns_path}/resolv.conf
    echo nameserver 1.1.1.1 >> ${MODPATH}${dns_path}/resolv.conf
    echo nameserver 223.5.5.5 >> ${MODPATH}${dns_path}/resolv.conf
    echo nameserver 120.53.53.53 >> ${MODPATH}${dns_path}/resolv.conf
fi

ui_print "- 创建黑白名单"
if [ ! -f "${clash_data_dir}/scripts/packages.list" ] ; then
    touch ${clash_data_dir}/packages.list
fi

ui_print "- 安装Magsik配置文件"
unzip -j -o "${ZIPFILE}" 'service.sh' -d ${MODPATH} >&2
unzip -j -o "${ZIPFILE}" 'uninstall.sh' -d ${MODPATH} >&2
unzip -j -o "${ZIPFILE}" 'clash_service.sh' -d ${clash_service_dir} >&2

ui_print "- 正在安装控制器"
chmod a+x "$MODPATH"/APP/clash.apk
fullApkPath=$(ls "$MODPATH"/APP/clash*.apk)
apkPath=$TMPDIR/clash.apk
mv -f "$fullApkPath" "$apkPath"
chmod 666 "$apkPath"
output=$(pm install -r -f "$apkPath" 2>&1)
if [ "$output" == "Success" ]; then
    echo "- 控制器安装成功"
    rm -rf "$apkPath"
else
    echo "- 控制器安装失败, 原因: [$output] 正在尝试重新安装"
    pm uninstall xyz.chz.clash
    sleep 1
    output=$(pm install -r -f "$apkPath" 2>&1)
    if [ "$output" == "Success" ]; then
        echo "- 重装成功"
        rm -rf "$apkPath"
    else
        apkPathSdcard="/sdcard/clash_${module_version}.apk"
        cp -f "$apkPath" "$apkPathSdcard"
        echo "!!! *********************** !!!"
        echo "  控制器安装失败, 原因: [$output]"
        echo "  请手动安装 [ $apkPathSdcard ]"
        echo "  如果是降级安装, 请手动重装"
        echo "!!! *********************** !!!"
    fi
fi

ui_print "- 删除源文件"
rm -rf ${MODPATH}/dashboard.zip
rm -rf ${MODPATH}/scripts
rm -rf ${MODPATH}/GeoX
rm -rf ${MODPATH}/binary
rm -rf ${MODPATH}/clash_service.sh
rm -rf ${clash_data_dir}/scripts/config.yaml
rm -rf ${clash_data_dir}/scripts/dnstt
rm -rf ${clash_data_dir_kernel}/curl

sleep 1

ui_print "- 正在设置权限"
set_perm_recursive ${MODPATH} 0 0 0755 0644
set_perm_recursive ${clash_service_dir} 0 0 0755 0755
set_perm_recursive ${clash_data_dir} ${uid} ${gid} 0755 0644
set_perm_recursive ${clash_data_dir}/scripts ${uid} ${gid} 0755 0755
set_perm_recursive ${clash_data_dir}/kernel ${uid} ${gid} 0755 0755
set_perm_recursive ${clash_data_dir}/dashboard ${uid} ${gid} 0755 0644
set_perm  ${MODPATH}/service.sh  0  0  0755
set_perm  ${MODPATH}/uninstall.sh  0  0  0755
set_perm  ${MODPATH}/system/bin/setcap  0  0  0755
set_perm  ${MODPATH}/system/bin/getcap  0  0  0755
set_perm  ${MODPATH}/system/bin/getpcaps  0  0  0755
set_perm  ${MODPATH}/system/bin/ss 0 0 0755
set_perm  ${MODPATH}/system/bin/clash 0 0 6755
set_perm  ${MODPATH}${ca_path}/cacert.pem 0 0 0644
set_perm  ${MODPATH}${dns_path}/resolv.conf 0 0 0755
set_perm  ${clash_data_dir}/scripts/clash.iptables 0  0  0755
set_perm  ${clash_data_dir}/scripts/clash.tool 0  0  0755
set_perm  ${clash_data_dir}/scripts/clash.inotify 0  0  0755
set_perm  ${clash_data_dir}/scripts/clash.service 0  0  0755
set_perm  ${clash_data_dir}/scripts/clash.cron 0  0  0755
set_perm  ${clash_data_dir}/scripts/start.sh 0  0  0755
set_perm  ${clash_data_dir}/scripts/usage.sh 0  0  0755
set_perm  ${clash_data_dir}/scripts/upSub.sh 0  0  0755
set_perm  ${clash_data_dir}/clash.config ${uid} ${gid} 0755
set_perm  ${clash_data_dir}/kernel/dnstt-client  0  0  0755
set_perm  ${clash_service_dir}/clash_service.sh  0  0  0755
set_perm  ${clash_data_dir}/rule_providers/ 0  0  0755
set_perm  ${clash_data_dir}/proxy_providers/ 0  0  0755
set_perm  ${clash_data_dir}/备用/ 0  0  0755
set_perm  ${clash_data_dir}/assets/ 0  0  0755


#ui_print "- 正在更新模块信息"
#rm -rf ${MODPATH}/module.prop
#touch ${MODPATH}/module.prop
#echo "id=ClashForMagisk" > ${MODPATH}/module.prop
#echo "name=Clash For Magisk" >> ${MODPATH}/module.prop
#echo "version=v1.13.0" >> ${MODPATH}/module.prop
#echo "versionCode=20220910" >> ${MODPATH}/module.prop
#echo "author=t@amarin 魔改" >> ${MODPATH}/module.prop
#echo "description= Clash透明代理   Mosdns Aria(88端口)  内核:meta 1.13.1" >> ${MODPATH}/module.prop
#echo "updateJson=/Clash-Mix/master/version.json" >> ${MODPATH}/module.prop

sleep 1
ui_print "- 控制器已经安装，卸载模块后会自动删除"
ui_print "- 标准版请进入data/clash/config.yaml 指定位置填写订阅链接"
ui_print "- 免流版 极简版请打开/data/clash/confs/查看说明"
ui_print "- 在对应配置文件内填写订阅链接并在控制台切换到相应配置文件"
ui_print "- 建议打开 备用 文件夹仔细查看详细说明和配置模板"
ui_print "- 操作前多看看教程，免得出问题一脸懵逼到处问"
ui_print "- 安装已完成，请重启"
