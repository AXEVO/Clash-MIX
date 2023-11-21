#!/system/bin/sh
Clash_data_dir="/data/clash"
Clash_delete_dir="/data/clash.delete"

wait_until_login() {
    while [ "$(getprop sys.boot_completed)" != "1" ]; do
        sleep 1
    done
    local test_file="/sdcard/Android/.PERMISSION_TEST"
    true >"$test_file"
    while [ ! -f "$test_file" ]; do
        true >"$test_file"
        sleep 1
    done
    rm "$test_file"
}

delete_cfm(){
    wait_until_login

    su -c "pm uninstall xyz.chz.clash"
    mv ${Clash_data_dir} ${Clash_delete_dir}
    rm -rf ${Clash_data_dir}
    rm -rf /data/clash.old
    rm -rf /data/adb/service.d/clash_service.sh
}

(delete_cfm &)