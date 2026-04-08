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
    error_log=$(printf '\n%s\n%s\n%s' \
        "🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥错误日志🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥" \
        "$clash_test_msg" \
        "🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥🟥")

    return 1
}


get_inotify_status() {
    inotify_pids=$(pgrep -f "^inotifyd $inotify_script $Module_dir\$")
    pid_count=$(echo "$inotify_pids" | sed '/^$/d' | wc -l | tr -d ' ')
}


get_inotify_status

if [ "$pid_count" -eq 0 ]; then
    nohup inotifyd "$inotify_script" "$Module_dir" >/dev/null 2>&1 &
    sleep 1
    get_inotify_status

    if [ "$pid_count" -eq 1 ] && check_inotifyd; then
        echo "🟨inotifyd 未运行 已修复 本次不重启内核"
        exit 0
    else
        echo "🟥inotifyd 未运行且修复失败，请检查模块状态"
        exit 1
    fi

elif [ "$pid_count" -gt 1 ]; then
    echo "$inotify_pids" | xargs -r kill -9 -- >/dev/null 2>&1
    nohup inotifyd "$inotify_script" "$Module_dir" >/dev/null 2>&1 &
    sleep 1
    get_inotify_status

    if [ "$pid_count" -eq 1 ] && check_inotifyd; then
        echo "🟨发现多个 inotifyd 进程 已修复 本次不重启内核"
        exit 0
    else
        echo "🟥inotifyd 修复失败，可能存在僵尸进程或其他故障，请重启手机"
        exit 1
    fi

elif [ "$pid_count" -eq 1 ]; then
    if check_inotifyd; then
        :
    else
        echo "$inotify_pids" | xargs -r kill -9 -- >/dev/null 2>&1
        nohup inotifyd "$inotify_script" "$Module_dir" >/dev/null 2>&1 &
        sleep 1
        get_inotify_status

        if [ "$pid_count" -eq 1 ] && check_inotifyd; then
            echo "🟨inotifyd 进程异常 已修复 本次不重启内核"
            exit 0
        else
            echo "🟥inotifyd失效 修复失败 请重启手机后再试"
            exit 1
        fi
    fi
fi


#------------------------------------------------------------------
sh "$service_script" stop >/dev/null 2>&1
case "$?" in
    1)
        echo "🟥Clash内核停止异常，本次不继续启动，请检查模块状态"
        exit 1
        ;;
    2)
        echo "🟨Clash内核当前未运行，直接执行启动"
        sh "$service_script" start >/dev/null 2>&1
        case "$?" in
            0)
                echo "🟩Clash内核启动成功"
                exit 0
                ;;
            1)
                if check_clash_config; then
                    echo "🟥Clash内核启动失败，但配置文件测试正常"
                else
                    echo "🟥Clash内核启动失败，配置文件可能存在问题"
                    echo "$error_log"
                fi
                exit 1
                ;;
            2)
                echo "🟥尝试启动时检测到Clash内核已在运行，请检查模块状态"
                exit 1
                ;;
            *)
                echo "🟥启动脚本返回未知状态码，请检查模块状态"
                exit 1
                ;;
        esac
        ;;
    0)
        echo "🟩成功停止Clash内核 1秒后尝试重启"
        sleep 1
        sh "$service_script" start >/dev/null 2>&1
        case "$?" in
            0)
                echo "🟩Clash内核重启成功"
                exit 0
                ;;
            1)
                if check_clash_config; then
                    echo "🟥Clash内核重新启动失败，但配置文件测试正常"
                else
                    echo "🟥Clash内核启动失败，配置文件可能存在问题"
                    echo "$error_log"
                fi
                exit 1
                ;;
            2)
                echo "🟥重新启动时检测到Clash内核已在运行，请检查模块状态"
                exit 1
                ;;
            *)
                echo "🟥重新启动阶段返回未知状态码，请检查模块状态"
                exit 1
                ;;
        esac
        ;;
    *)
        echo "🟥停止脚本返回未知状态码，请检查模块状态"
        exit 1
        ;;
esac
