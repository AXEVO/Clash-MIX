until [ "$(getprop sys.boot_completed)" = "1" ]; do
    sleep 2
done

until [ -d "/sdcard/Android" ]; do
    sleep 2
done
sleep 10
script_path=/data/adb/modules/Clash/Scripts

$script_path/Clash.Service start
nohup inotifyd "$script_path/Clash.Inotify" "/data/adb/modules/Clash" >/dev/null 2>&1 &