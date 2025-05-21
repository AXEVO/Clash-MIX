script_path=/data/adb/modules/Clash/Scripts
status_file=/data/adb/modules/Clash/clash_status

# 检查状态文件是否存在，判断当前内核状态
if [ -f "$status_file" ]; then
    # 状态文件存在，说明内核正在运行，执行关闭操作
    echo "-   检测到内核正在运行，准备关闭"
    echo "-       3秒钟后关闭内核"
    sleep 1
    echo "-       2"
    sleep 1
    echo "-       1"
    sleep 1
    echo "-       正在关闭内核"
    $script_path/Clash.Service stop > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "-   内核已关闭"
        # 删除状态文件，标记为已关闭
        rm -f "$status_file"
    else
        echo "-   停止内核失败"
    fi
else
    # 状态文件不存在，说明内核已关闭，执行启动操作
    echo "-   检测到内核已关闭，准备启动"
    echo "-       3秒钟后启动内核"
    sleep 1
    echo "-       2"
    sleep 1
    echo "-       1"
    sleep 1
    echo "-       正在启动内核"
    $script_path/Clash.Service start > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "-   内核启动成功"
        # 创建状态文件，标记为已启动
        touch "$status_file"
    else
        echo "-   启动内核失败"
    fi
fi
