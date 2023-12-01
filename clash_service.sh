#!/system/bin/sh

(
until [ $(getprop init.svc.bootanim) = "stopped" ] ; do
    sleep 5
done
#Clash_run_path="/data/clash/run"

chmod 755 /data/clash/scripts/start.sh
#crond -c ${Clash_run_path}
/data/clash/scripts/start.sh
)&

# Clash Service 