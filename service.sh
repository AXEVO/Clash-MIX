#!/system/bin/sh
until [ "$(getprop sys.boot_completed)" = "1" ]; do
    sleep 2
done

until [ -d "/sdcard/Android" ]; do
    sleep 2
done

script_path=/data/adb/modules/Clash/script
watch_dir=/data/adb/modules/Clash

"$script_path/Proxy.sh" -d "$script_path" start

if ! pgrep -f "inotifyd.*Clash.Inotify" >/dev/null; then
    nohup inotifyd "$script_path/Clash.Inotify" "$watch_dir" >> /dev/null &
fi
