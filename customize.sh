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
ca_path="${dns_path}/security/cacerts"
clash_data_dir_kernel="${clash_data_dir}/kernel"
clash_data_sc="${clash_data_dir}/scripts"
mod_config="${clash_data_sc}/clash.config"
yacd_dir="${clash_data_dir}/dashboard"
latest=$(date +%Y%m%d%H%M)

if $BOOTMODE; then
  ui_print "- 准备安装模块"
else
  ui_print "**************************************************"
  ui_print "! 不支持从恢复模式安装"
  ui_print "! 请从Magisk应用安装"
  abort "*****************************************************"
fi

# 检查版本
if [ $KSU ]; then
    ui_print "- KernelSU版本: $KSU_VER ($KSU_VER_CODE)"
else
    ui_print "- Magisk版本: $MAGISK_VER ($MAGISK_VER_CODE)"
fi

# 检查Android版本
if [ "$API" -lt 19 ]; then
  ui_print "! 不支持的SDK版本: $API"
  abort "! 最小支持的SDK版本为19（Android 4.4）"
else
  ui_print "- 设备SDK版本: $API"
fi

# 检查架构
if [ "$ARCH" != "arm" ] && [ "$ARCH" != "arm64" ] && [ "$ARCH" != "x86" ] && [ "$ARCH" != "x64" ]; then
  abort "! 不支持的平台: $ARCH"
else
  ui_print "- 设备平台: $ARCH"
fi

ui_print "- 开始安装"

if [ -d "${clash_data_dir}" ] ; then
    ui_print "- 旧版clash模块文件已移动到clash.old"
    mkdir -p /data/clash.old/${latest}
    mv ${clash_data_dir}/* /data/clash.old/${latest}
    rm -rf ${clash_data_dir}
fi

ui_print "- 创建安装目录"
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

ui_print "- 安装Web面板"
unzip -o ${MODPATH}/dashboard.zip -d ${clash_data_dir}/dashboard/ >&2

ui_print "- 安装脚本"
mv ${MODPATH}/scripts/* ${clash_data_dir}/scripts/
mv ${MODPATH}/rule_providers/ ${clash_data_dir}/
mv ${MODPATH}/proxy_providers/ ${clash_data_dir}/
mv ${MODPATH}/assets/ ${clash_data_dir}/
mv ${MODPATH}/备用/ ${clash_data_dir}/
cp ${clash_data_dir}/scripts/config.yaml ${clash_data_dir}/
cp ${clash_data_dir}/scripts/template ${clash_data_dir}/

ui_print "- 安装密钥和Geo文件"
mv ${clash_data_dir}/scripts/cacert.pem ${MODPATH}${ca_path}
mv ${MODPATH}/GeoX/* ${clash_data_dir}/

if [ ! -d /data/adb/service.d ] ; then
    ui_print "- 创建自启动配置"
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

ui_print "- 创建黑白名单--默认为黑名单，请使用控制器选择要加入名单的应用"
if [ ! -f "${clash_data_dir}/scripts/packages.list" ] ; then
    touch ${clash_data_dir}/packages.list
fi

unzip -j -o "${ZIPFILE}" 'service.sh' -d ${MODPATH} >&2
unzip -j -o "${ZIPFILE}" 'uninstall.sh' -d ${MODPATH} >&2
unzip -j -o "${ZIPFILE}" 'clash_service.sh' -d ${clash_service_dir} >&2

ui_print "- 安装二进制文件-$ARCH "
tar -xjf ${MODPATH}/binary/${ARCH}.tar.bz2 -C ${clash_data_dir_kernel}/&& echo "- 安装内核成功" || echo "- 安装内核失败"
mv ${clash_data_dir_kernel}/setcap ${MODPATH}${bin_path}/
mv ${clash_data_dir_kernel}/getpcaps ${MODPATH}${bin_path}/
mv ${clash_data_dir_kernel}/getcap ${MODPATH}${bin_path}/
mv ${clash_data_dir}/scripts/clash.config ${clash_data_dir}/
mv ${clash_data_dir}/scripts/dnstt/dnstt-client ${clash_data_dir_kernel}/

if [ $KSU ]; then
    ui_print "- 使用Ksu的Busybox"
    sed -i 's/PATH_TO_BUSYBOX/\/data\/adb\/ksu\/bin\/busybox/' ${clash_data_dir}/clash.config
else
    ui_print "- 使用Magisk的Busybox"
    sed -i 's/PATH_TO_BUSYBOX/\/data\/adb\/magisk\/busybox/' ${clash_data_dir}/clash.config
fi

if [ ! -f "${bin_path}/ss" ] ; then
    mv ${clash_data_dir_kernel}/ss ${MODPATH}${bin_path}/
else
    rm -rf ${clash_data_dir_kernel}/ss
fi

ui_print "- 删除源文件"
rm -rf ${MODPATH}/dashboard.zip
rm -rf ${MODPATH}/scripts
rm -rf ${MODPATH}/GeoX
rm -rf ${MODPATH}/binary
rm -rf ${MODPATH}/clash_service.sh
rm -rf ${clash_data_dir}/scripts/dnstt
rm -rf ${clash_data_dir_kernel}/curl
rm -rf ${MODPATH}/verson.json

sleep 1

ui_print "- 安装控制器(1.6.4-90)"
chcon u:object_r:system_file:s0 $MODPATH/APP/clash.apk
output=$(pm install -r -f "$MODPATH/APP/clash.apk" 2>&1)

if [ "$output" == "Success" ]; then
    echo "- 控制器安装成功"
    rm -rf "$MODPATH/APP"
else
    apkPathSdcard="/sdcard/Clash控制器.apk"
    mv -f "$MODPATH/APP/clash.apk" "$apkPathSdcard"
    rm -rf ${MODPATH}/APP
    echo "*****************************************"
    echo "  控制器安装失败, 原因: [$output]"
    echo "  请手动安装 [ $apkPathSdcard ]"
    echo "*****************************************"
fi

sleep 1

if [  -f "/data/clash.old/${latest}/config.yaml" ] ; then
    config_ver=$(grep '#version:' /data/clash.old/${latest}/config.yaml | sed -n 's/^#version:\(.*\)/\1/p')
    if [ "$config_ver" != "20240110" ]; then
     ui_print "->>-----------------------------------------------------<<"
     ui_print "->>本次模块更新 变更了config.yaml，请重新填写订阅链接"
     ui_print "->>旧的配置文件已被重命名为clash.old，订阅链接在里面"
     ui_print "->>-----------------------------------------------------<<"
     cp /data/clash.old/${latest}/config.yaml ${clash_data_dir}/config.old
    else
     ui_print "->>-----------------------------------------------------<<"
     ui_print "->> 本次安装为模块升级，已恢复原订阅链接"
     ui_print "->>-----------------------------------------------------<<"
     cp /data/clash.old/${latest}/config.yaml ${clash_data_dir}/
    fi
    rm -rf /data/clash.delete
else 
    if [  -f "/data/clash.delete/config.yaml" ] ; then
     ui_print "->>-------------------------------------------------------<<"
     ui_print "->>检测到上次卸载Clash模块时自动备份的配置文件(内含订阅链接)"
     ui_print "->>已移动到/data/Clash/config.old 如需要，请自行复制订阅链接"
     ui_print "->>-------------------------------------------------------<<"
     mv /data/clash.delete/config.yaml ${clash_data_dir}/config.old
     rm -rf /data/clash.delete
    else
     ui_print "->>-------------------------------------------------------<<"
     ui_print "->> 全新安装 请根据提示在config.yaml指定位置填写订阅链接" 
     ui_print "->>-------------------------------------------------------<<"
    fi
fi

sleep 1
ui_print "- 设置文件权限"
set_perm_recursive ${MODPATH} 0 0 0755 0644
set_perm_recursive ${clash_service_dir} 0 0 0755 0755
set_perm_recursive ${clash_data_dir} ${uid} ${gid} 0755 0644
set_perm_recursive ${clash_data_dir}/scripts ${uid} ${gid} 0755 0755
set_perm_recursive ${clash_data_dir}/kernel ${uid} ${gid} 0755 0755
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
set_perm  ${clash_data_dir}/scripts/start.sh 0  0  0755
set_perm  ${clash_data_dir}/scripts/usage.sh 0  0  0755
set_perm  ${clash_data_dir}/clash.config ${uid} ${gid} 0755
set_perm  ${clash_data_dir}/kernel/dnstt-client  0  0  0755
set_perm  ${clash_service_dir}/clash_service.sh  0  0  0755
set_perm  ${clash_data_dir}/rule_providers/ 0  0  0755
set_perm  ${clash_data_dir}/proxy_providers/ 0  0  0755
set_perm  ${clash_data_dir}/assets/ 0  0  0755

sleep 3
ui_print "- -----------------------------------------------------"
ui_print "-  控制器已自动安装，请在桌面查找Clash控制器"
ui_print "-  第一次安装请先进入/data/clash/config.yaml "
ui_print "-  在配置文件的指定位置填写订阅链接，再重启手机"
ui_print "-  建议打开 /data/clash/备用 仔细查看详细说明"
ui_print "- -----------------------------------------------------"
