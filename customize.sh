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
sdcard_dir="/sdcard/Download"
CPFM_mode_dir="${modules_dir}/clash_premium"
busybox_data_dir="/data/adb/magisk/busybox"
ca_path="${dns_path}/security/cacerts"
clash_data_dir_core="${clash_data_dir}/core"
CPFM_mode_dir="${modules_dir}/clash_premium"
clash_data_sc="${clash_data_dir}/scripts"
mod_config="${clash_data_sc}/clash.config"
geoip_file_path="${clash_data_dir}/Country.mmdb"
yacd_dir="${clash_data_dir}/dashboard"

if [ -d "${CPFM_mode_dir}" ] ; then
    touch ${CPFM_mode_dir}/remove && ui_print "- CPFM古董模块在重启后将会被删除."
fi

if [ $BOOTMODE ! = true ] ; then
  abort "请在magisk manager中安装模块"
fi

if [ -d "${clash_data_dir}" ] ; then
    ui_print "- 旧的clash文件已移动到clash.old"
    if [ -d "/data/clash.old" ] ; then
        rm -rf /data/clash.old
    fi
    mkdir -p /data/clash.old
    mv ${clash_data_dir}/* data/clash.old/
fi

ui_print "- 正在准备安装环境"
ui_print "- 正在创建安装文件夹"
mkdir -p ${clash_data_dir}
mkdir -p ${clash_data_dir_core}
mkdir -p ${MODPATH}${ca_path}
mkdir -p ${clash_data_dir}/dashboard
mkdir -p ${MODPATH}/system/bin
mkdir -p ${clash_data_dir}/run
mkdir -p ${clash_data_dir}/scripts

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

ui_print "- 正在安装流量显示面板"
if [ ! -d /data/dashboard ] ; then
    rm -rf "${clash_data_dir}/dashboard/*"
fi
unzip -o ${MODPATH}/dashboard.zip -d ${clash_data_dir}/dashboard/ >&2

ui_print "- 正在移动安装文件"
rm -rf "${clash_data_dir}/scripts/*"
mv ${MODPATH}/scripts/* ${clash_data_dir}/scripts/
mv ${MODPATH}/rule_providers/ ${clash_data_dir}/
mv ${MODPATH}/proxy_providers/ ${clash_data_dir}/
mv ${MODPATH}/confs/ ${clash_data_dir}/
mv ${MODPATH}/备用/ ${clash_data_dir}/
mv ${MODPATH}/mosdns/ ${clash_data_dir}/
ui_print "- 正在安装主要配置"
cp ${clash_data_dir}/scripts/config.yaml ${clash_data_dir}/
mv ${clash_data_dir}/scripts/clash.config ${clash_data_dir}/
mv ${clash_data_dir}/scripts/template ${clash_data_dir}/

ui_print "- 正在安装密钥和Geo文件"
mv ${clash_data_dir}/scripts/cacert.pem ${MODPATH}${ca_path}
mv ${MODPATH}/GeoX/* ${clash_data_dir}/

ui_print "- 配置开机自启"
if [ ! -d /data/adb/service.d ] ; then
    mkdir -p /data/adb/service.d
fi

if [ ! -f "${dns_path}/resolv.conf" ] ; then
    touch ${MODPATH}${dns_path}/resolv.conf
    echo nameserver 8.8.8.8 > ${MODPATH}${dns_path}/resolv.conf
    echo nameserver 1.1.1.1 >> ${MODPATH}${dns_path}/resolv.conf
    echo nameserver 223.5.5.5 >> ${MODPATH}${dns_path}/resolv.conf
    echo nameserver 120.53.53.53 >> ${MODPATH}${dns_path}/resolv.conf
fi

if [ ! -f "${clash_data_dir}/scripts/packages.list" ] ; then
    touch ${clash_data_dir}/packages.list
fi

ui_print "- 查找并补全丢失的文件"
if [ ! -f "${MODPATH}/service.sh" ] ; then
    unzip -j -o "${ZIPFILE}" 'service.sh' -d ${MODPATH} >&2
fi

if [ ! -f "${MODPATH}/uninstall.sh" ] ; then
    unzip -j -o "${ZIPFILE}" 'uninstall.sh' -d ${MODPATH} >&2
fi

if [ ! -f "${clash_service_dir}/clash_service.sh" ] ; then
    unzip -j -o "${ZIPFILE}" 'clash_service.sh' -d ${clash_service_dir} >&2
fi

ui_print "- 正在安装内核 $ARCH"
tar -xjf ${MODPATH}/binary/${ARCH}.tar.bz2 -C ${clash_data_dir_core}/&& echo "- 解压内核成功" || echo "- 解压内核失败"
mv ${clash_data_dir_core}/setcap ${MODPATH}${bin_path}/
mv ${clash_data_dir_core}/getpcaps ${MODPATH}${bin_path}/
mv ${clash_data_dir_core}/getcap ${MODPATH}${bin_path}/
mv ${clash_data_dir_core}/curl ${MODPATH}${bin_path}/

if [ ! -f "${bin_path}/ss" ] ; then
    mv ${clash_data_dir_core}/ss ${MODPATH}${bin_path}/
else
    rm -rf ${clash_data_dir_core}/ss
fi

rm -rf ${MODPATH}/dashboard.zip
rm -rf ${MODPATH}/scripts
rm -rf ${MODPATH}/GeoX
rm -rf ${MODPATH}/binary
rm -rf ${MODPATH}/clash_service.sh
sleep 2

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
sleep2

ui_print "- 正在更新模块信息"
rm -rf ${MODPATH}/module.prop
touch ${MODPATH}/module.prop
echo "id=ClashForMagisk" > ${MODPATH}/module.prop
echo "name=Clash For Magisk" >> ${MODPATH}/module.prop
echo "version=v2.0" >> ${MODPATH}/module.prop
echo "versionCode=20231017" >> ${MODPATH}/module.prop
echo "author=t@amarin 魔改" >> ${MODPATH}/module.prop
echo "description= Clash透明代理 内核:meta 1.16.0" >> ${MODPATH}/module.prop
echo "updateJson=https://raw.githubusercontent.com/Gayhub666/Clash-Mix/master/version.json" >> ${MODPATH}/module.prop

ui_print "- 正在设置权限"
set_perm_recursive ${MODPATH} 0 0 0755 0644
set_perm_recursive ${clash_service_dir} 0 0 0755 0755
set_perm_recursive ${clash_data_dir} ${uid} ${gid} 0755 0644
set_perm_recursive ${clash_data_dir}/scripts ${uid} ${gid} 0755 0755
set_perm_recursive ${clash_data_dir}/core ${uid} ${gid} 0755 0755
set_perm_recursive ${clash_data_dir}/dashboard ${uid} ${gid} 0755 0644
set_perm  ${MODPATH}/service.sh  0  0  0755
set_perm  ${MODPATH}/uninstall.sh  0  0  0755
set_perm  ${MODPATH}/system/bin/setcap  0  0  0755
set_perm  ${MODPATH}/system/bin/curl  0  0  0755
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
set_perm  ${clash_data_dir}/clash.config ${uid} ${gid} 0755
set_perm  ${clash_service_dir}/clash_service.sh  0  0  0755
set_perm  ${clash_data_dir}/rule_providers/ 0  0  0755
set_perm  ${clash_data_dir}/proxy_providers/ 0  0  0755
set_perm  ${clash_data_dir}/备用/ 0  0  0755
set_perm  ${clash_data_dir}/confs/ 0  0  0755

sleep 3
ui_print "- 控制器已安装为系统应用，卸载模块后会自动删除"
ui_print "- 标准版请进入data/clash/config.yaml 指定位置填写订阅链接"
ui_print "- 免流版 极简版请打开/data/clash/confs/查看说明"
ui_print "- 在对应配置文件内填写订阅链接并在控制台切换到相应配置文件"
ui_print "- 建议打开 备用 文件夹仔细查看详细说明和配置模板"
ui_print "- 操作前多看看教程，免得出问题一脸懵逼到处问"
