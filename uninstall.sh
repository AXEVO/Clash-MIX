Clash_data_dir="/data/clash"
Clash_delete_dir="/data/clash.delete"

rm_data() {
    mv ${Clash_data_dir} ${Clash_delete_dir}
    rm -rf ${Clash_data_dir}
    rm -rf /data/clash.old
    rm -rf /data/adb/service.d/clash_service.sh
}

rm_data

su -c "pm uninstall $APP_PACKAGE_NAME"