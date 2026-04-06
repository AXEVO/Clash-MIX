#!/system/bin/sh

Module_dir="/data/adb/modules/Clash"
script_path="$Module_dir/Scripts"
service_script="$script_path/Clash.Service"
inotify_script="$script_path/Clash.Inotify"
core_path="$Module_dir/Proxy/Clash.Core"
work_dir="$Module_dir/Proxy"
config_path="$work_dir/config.yaml"

check_inotifyd() {
    rm -f "$Module_dir/Inotifyd_test" "$Module_dir/Inotifyd_OK" || return 1
    touch "$Module_dir/Inotifyd_test" || return 1
    sleep 1

    if [ -f "$Module_dir/Inotifyd_OK" ]; then
        rm -f "$Module_dir/Inotifyd_OK" || return 1
        return 0
    else
        return 1
    fi
}

check_clash_config() {
    clash_test_msg=""
    error_log=""

    output=$("$core_path" -t -d "$work_dir" 2>&1)
    status=$?

    if [ "$status" -eq 0 ]; then
        return 0
    fi

    clash_test_msg=$(printf '%s\n' "$output" | sed -n '
        /msg="/ {
            s/.*msg="\([^"]*\)".*/\1/
            p
            b
        }
        p
    ')

    # 使用 printf 构造多行字符串，避免缩进和对齐问题
    error_log=$(printf '%s\n%s\n%s' \
        "🟥🟥🟥🟥🟥🟥内核日志🟥🟥🟥🟥🟥" \
        "$clash_test_msg" \
        "🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥")

    return 1
}




get_inotify_status() {
    inotify_pids=$(pgrep -f '/data/adb/modules/Clash/Scripts/Clash.Inotify')
    pid_count=$(echo "$inotify_pids" | sed '/^$/d' | wc -l | tr -d ' ')
}




get_inotify_status

if [ "$pid_count" -eq 0 ]; then
    nohup inotifyd "$inotify_script" "$Module_dir:n,d" >/dev/null 2>&1 &
    sleep 1
    get_inotify_status

    if [ "$pid_count" -eq 1 ] && check_inotifyd; then
        echo "[检测]inotifyd 未运行，已重新拉起，本次不重启内核。"
        exit 0
    else
        echo "[模块故障]inotifyd 未运行，尝试拉起后仍异常，请重启手机后再试。"
        exit 1
    fi

elif [ "$pid_count" -gt 1 ]; then
    echo "$inotify_pids" | xargs -r kill -9 -- >/dev/null 2>&1
    nohup inotifyd "$inotify_script" "$Module_dir:n,d" >/dev/null 2>&1 &
    sleep 1
    get_inotify_status

    if [ "$pid_count" -eq 1 ] && check_inotifyd; then
        echo "[检测]发现多个 inotifyd 进程，已清理并重新拉起，本次不重启内核。"
        exit 0
    else
        echo "[模块故障]inotifyd 清理重建后仍异常，可能存在僵尸进程或其他异常，请重启手机后再试。"
        exit 1
    fi

elif [ "$pid_count" -eq 1 ]; then
    if check_inotifyd; then
        :
    else
        echo "$inotify_pids" | xargs -r kill -9 -- >/dev/null 2>&1
        nohup inotifyd "$inotify_script" "$Module_dir:n,d" >/dev/null 2>&1 &
        sleep 1
        get_inotify_status

        if [ "$pid_count" -eq 1 ] && check_inotifyd; then
            echo "[检测]inotifyd 进程工作异常，已重新拉起，本次不重启内核。"
            exit 0
        else
            echo "[模块故障]inotifyd 进程存在但工作异常，且重建后仍异常，请重启手机后再试。"
            exit 1
        fi
    fi
fi


#------------------------------------------------------------------
sh "$service_script" stop
case "$?" in
    1)
        echo "[模块故障]Clash内核停止异常，本次不继续启动，请检查模块状态。"
        exit 1
        ;;
    2)
        echo "[检测]Clash内核当前未运行，直接执行启动。"
        sh "$service_script" start
        case "$?" in
            0)
                echo "[完成]Clash内核启动成功。"
                exit 0
                ;;
            1)
                if check_clash_config; then
                    echo "[模块故障]Clash内核启动失败，但配置文件测试正常，请检查模块状态和内核日志。"
                else
                    echo "[配置错误]Clash内核启动失败，且检测到配置文件存在问题。"
                    echo "$error_log"
                fi
                exit 1
                ;;
            2)
                echo "[状态异常]启动脚本判断 Clash 内核已在运行，请检查模块状态。"
                exit 1
                ;;
            *)
                echo "[模块故障]启动脚本返回未知状态码，请检查模块状态。"
                exit 1
                ;;
        esac
        ;;
    0)
        echo "[检测]Clash内核已停止，1 秒后执行启动。"
        sleep 1
        sh "$service_script" start
        case "$?" in
            0)
                echo "[完成]Clash内核重启成功。"
                exit 0
                ;;
            1)
                if check_clash_config; then
                    echo "[模块故障]Clash内核重新启动失败，但配置文件测试正常，请检查模块状态和内核日志。"
                else
                    echo "[配置错误]Clash内核重新启动失败，且检测到配置文件存在问题。"
                    echo "$error_log"
                fi
                exit 1
                ;;
            2)
                echo "[状态异常]停止后重新启动时，启动脚本判断 Clash 内核已在运行，请检查模块状态。"
                exit 1
                ;;
            *)
                echo "[模块故障]重新启动阶段返回未知状态码，请检查模块状态。"
                exit 1
                ;;
        esac
        ;;
    *)
        echo "[模块故障]停止脚本返回未知状态码，请检查模块状态。"
        exit 1
        ;;
esac
