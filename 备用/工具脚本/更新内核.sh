url=$(curl -s https://api.github.com/repos/MetaCubeX/Clash.Meta/releases/tags/Prerelease-Alpha \
| grep "download/Prerelease-Alpha/Clash.Meta-android-arm64-alpha" \
| cut -d : -f 2,3 \
| tr -d \")

curl -L $url -o clash.gz

gunzip clash.gz

mv /data/adb/modules/Clash_For_Magisk/system/bin/clash /data/adb/modules/Clash_For_Magisk/system/bin/clash.bak

mv clash /data/adb/modules/Clash_For_Magisk/system/bin/clash

chmod 777 /data/adb/modules/Clash_For_Magisk/system/bin/clash
echo 已安装最新版 meta alpha内核