script_path=/data/adb/modules/Clash/Scripts

$script_path/Clash.Service stop > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "-   内核已关闭"
else
    echo "-   停止内核失败"
fi

echo "-   3秒钟后重启内核"
sleep 1
echo "-   2"
sleep 1
echo "-   1"
sleep 1
echo "-   正在重启内核"

$script_path/Clash.Service start > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "-   内核重启成功"
else
    echo "-   启动内核失败"
fi
