#!/system/bin/sh

# 获取脚本的绝对路径和目录
scripts=$(realpath $0)
scripts_dir=$(dirname ${scripts})
# 导入Clash的配置文件
source /data/clash/clash.config

# 查找应用程序UID的函数
find_packages_uid() {
  echo -n "" > ${appuid_file} 
  if [ "${Clash_enhanced_mode}" == "redir-host" ] ; then
    for package in $(cat ${filter_packages_file} | sort -u) ; do
      ${busybox_path} awk '$1~/'^"${package}"$'/{print $2}' ${system_packages_file} >> ${appuid_file}
    done
  else
    log "[info] 当前DNS服务模式: ${Clash_enhanced_mode} "
    log "[info] 如需使用黑白名单，请使用redr-host"
  fi
}

# 重启Clash的函数
restart_clash() {
  ${scripts_dir}/clash.service -k && ${scripts_dir}/clash.iptables -k
  echo -n "disable" > ${Clash_run_path}/root
  sleep 0.5
  ${scripts_dir}/clash.service -s && ${scripts_dir}/clash.iptables -s
  if [ "$?" == "0" ] ; then
    log "[info] Clash内核已重启"
  else
    log "[error] Clash内核重启失败"
  fi
}

# 更新文件的函数
update_file() {
    current_time=$(date "+%Y-%m-%d %H:%M:%S")
    file="$1"
    file_bak="${file}.bak"
    update_url="$2"
    if [ -f ${file} ] ; then
      mv -f ${file} ${file_bak}
    fi
    echo "${current_time} - ${busybox_path} wget --no-check-certificate ${update_url} -O ${file}" >> update.log
    ${busybox_path} wget --no-check-certificate ${update_url} -O ${file} 2>&1
    sleep 5
    if [ -f "${file}" ] ; then
      echo ""
    else
      if [ -f "${file_bak}" ] ; then
        mv ${file_bak} ${file}
      fi
    fi
}

# 更新地理位置和订阅的函数
update_geo() {
  local restart_required=false
  
  if [ "${auto_updateGeoX}" == "true" ] ; then
    update_file ${Clash_GeoIP_file} ${GeoIP_dat_url}
    update_file ${Clash_GeoSite_file} ${GeoSite_url}
    if [ "$?" = "0" ] ; then
      restart_required=true
      log "[info] 更新Geo数据库"
    else 
      log "[warning] 更新Geo数据库失败"
    fi
  fi

  if [ ${auto_updateSubcript} == "true" ] ; then
    update_file ${Clash_config_file} ${Subcript_url}
    if [ "$?" = "0" ] ; then
      restart_required=true
      log "[info] 更新订阅"
    else 
      log "[warning] 更新订阅失败"
    fi
  fi
  sleep 5
  if [ -f "${Clash_pid_file}" ] && [ ${restart_required} == true ] ; then
    restart_clash
  fi
}

# 在线下载配置的函数
config_online() {
  clash_pid=$(cat ${Clash_pid_file})
  match_count=0
  log "[warning] 正在下载在线配置" > ${CFM_logs_file}
  update_file ${Clash_config_file} ${Subcript_url}
  sleep 0.5
  if [ -f "${Clash_config_file}" ] ; then
    match_count=$((${match_count} + 1))
  fi

  if [ ${match_count} -ge 1 ] ; then
    log "[info] 下载成功"
    exit 0
  else
    log "[error] 下载失败，请检查地址设置"
    exit 1
  fi
}

# 端口检测的函数
port_detection() {
  clash_pid=$(cat ${Clash_pid_file})
  match_count=0
  
  if (ss -h > /dev/null 2>&1)
  then
    clash_port=$(ss -antup | grep "clash" | ${busybox_path} awk '$7~/'pid="${clash_pid}"*'/{print $5}' | ${busybox_path} awk -F ':' '{print $2}' | sort -u)
  else
    logs "[info] 关闭端口检测"
    exit 0
  fi

  logs "[info] 检测到端口: "
  for sub_port in ${clash_port[*]} ; do
    sleep 0.5
    echo -n "${sub_port} " >> ${CFM_logs_file}
  done
    echo "" >> ${CFM_logs_file}
}

# 更新内核函数
update_kernel() {
  if [ "${use_premium}" == "false" ] ; then
    if [ "${meta_alpha}" == "false" ] ; then
      tag_meta=$(/data/adb/magisk/busybox wget --no-check-certificate -qO- ${url_meta} | grep -oE "v[0-9]+\.[0-9]+\.[0-9]+" | head -1)
      filename="${file_kernel}-${platform}-${arch}-${tag_meta}"
      update_file "${Clash_data_dir}/${file_kernel}.gz" "${url_meta}/download/${tag_meta}/${filename}.gz"
        if [ "$?" = "0" ]
        then
          flag=false
        fi
    else
      tag_meta=$(/data/adb/magisk/busybox wget --no-check-certificate -qO- ${url_meta}/expanded_assets/${tag} | grep -oE "${tag_name}" | head -1)
      filename="${file_kernel}-${platform}-${arch}-${tag_meta}"
      update_file "${Clash_data_dir}/${file_kernel}.gz" "${url_meta}/download/${tag}/${filename}.gz"
        if [ "$?" = "0" ]
        then
          flag=false
        fi
    fi
  else
    filename=$(/data/adb/magisk/busybox wget --no-check-certificate -qO- "${url_premium}/expanded_assets/premium" | grep -oE "clash-${platform}-${arch}-[0-9]+.[0-9]+.[0-9]+" | head -1)
    update_file "${Clash_data_dir}/${file_kernel}.gz" "${url_premium}/download/premium/${filename}.gz"
    if [ "$?" = "0" ] ; then
      flag=false
    fi
  fi

  if [ ${flag} == false ] ; then
    if (gunzip --help > /dev/null 2>&1); then
       if [ -f "${Clash_data_dir}/${file_kernel}.gz" ] ; then
        if (gunzip "${Clash_data_dir}/${file_kernel}.gz"); then
          echo ""
        else
          log "[error] 解压 ${file_kernel}.gz 失败"  > ${CFM_logs_file}
          log "[warning] 请检查下载地址"
          if [ -f "${Clash_data_dir}/${file_kernel}.gz.bak" ] ; then
            rm -rf "${Clash_data_dir}/${file_kernel}.gz.bak"
          else
            rm -rf "${Clash_data_dir}/${file_kernel}.gz"
          fi
          if [ -f ${Clash_run_path}/clash.pid ] ; then
            log "[info] Clash服务正在运行 (PID: $(cat ${Clash_pid_file}))"
            log "[info] 已连接"
          fi
          exit 1
        fi
       else
        log "[warning] 解压 ${file_kernel}.gz 失败" 
        log "[warning] 请确认网络连接正常" 
        exit 1
      fi
    else
      log "[error] 无法解压" 
      exit 1
    fi
  fi

  mv -f "${Clash_data_dir}/${file_kernel}" ${Clash_data_dir}/kernel/lib

  if [ "$?" = "0" ] ; then
    flag=true
  fi

  if [ -f "${Clash_pid_file}" ] && [ ${flag} == true ] ; then
    restart_clash
  else
     log "[warning] Clash 重新启动失败"
  fi
}

cgroup_limit() {
  if [ "${Cgroup_memory_limit}" == "" ] ; then
    return
  fi
  if [ "${Cgroup_memory_path}" == "" ] ; then
    Cgroup_memory_path=$(mount | grep cgroup | ${busybox_path} awk '/memory/{print $3}' | head -1)
  fi

  mkdir -p "${Cgroup_memory_path}/clash"
  echo $(cat ${Clash_pid_file}) > "${Cgroup_memory_path}/clash/cgroup.procs" \
  && log "[info] ${Cgroup_memory_path}/clash/cgroup.procs"  

  echo "${Cgroup_memory_limit}" > "${Cgroup_memory_path}/clash/memory.limit_in_bytes" \
  && log "[info] ${Cgroup_memory_path}/clash/memory.limit_in_bytes"
}

# 更新仪表板的函数
update_dashboard () {
  url_dashboard="https://github.com/MetaCubeX/metacubexd/archive/refs/heads/gh-pages.zip"
  file_dasboard="${Clash_data_dir}/dashboard.zip"
  rm -rf ${Clash_data_dir}/dashboard/metacubexd

  ${busybox_path} wget --no-check-certificate ${url_dashboard} -o ${file_dasboard} 2>&1
  unzip -o  "${file_dasboard}" "metacubexd-gh-pages/*" -d ${Clash_data_dir}/dashboard >&2
  mv -f ${Clash_data_dir}/dashboard/yacd-gh-pages ${Clash_data_dir}/dashboard/metacubexd
  rm -rf ${file_dasboard}
}

# dnstt客户端函数
dnstt_client() {
  if [ "${run_dnstt}" == "1" ] ; then
    if [ -f ${dnstt_client_bin} ] ; then
      chmod 0700 ${dnstt_client_bin}
      chown 0:3005 ${dnstt_client_bin}
      if [ ! ${nsdomain} == "" ] && [ ! ${pubkey} == "" ] ; then
         nohup ${busybox_path} setuidgid 0:3005 ${dnstt_client_bin} -udp ${dns_for_dnstt}:53 -pubkey ${pubkey} ${nsdomain} 127.0.0.1:9553 > /dev/null 2>&1 &
         echo -n $! > ${Clash_run_path}/dnstt.pid
         sleep 1
         local dnstt_pid=$(cat ${Clash_run_path}/dnstt.pid 2> /dev/null)
         if (cat /proc/$dnstt_pid/cmdline | grep -q ${dnstt_bin_name}); then
           log "[info] ${dnstt_bin_name} 已启用"
         else
           log "[error] ${dnstt_bin_name} 配置不正确"
           log "[error] 启动失败，以下是错误信息"
           kill -9 $(cat ${Clash_run_path}/dnstt.pid)
         fi
      else
        log "[warning] ${dnstt_bin_name} 未启用" 
        log "[warning] (nsdomain) & (pubkey) 为空" 
      fi
    else
      log "[error] 内核 ${dnstt_bin_name} 未找到"
    fi
  fi
}

while getopts ":dfklopsv" signal ; do
  case ${signal} in
    d)
      update_dashboard 
      ;;
    f)
      find_packages_uid
      ;;
    k)
      update_kernel
      ;;
    l)
      cgroup_limit
      ;;
    o)
      config_online
      ;;
    p)
      port_detection
      ;;
    s)
      update_geo
      rm -rf ${Clash_data_dir}/*dat.bak && exit 1
      ;;
    v)
      dnstt_client
      ;;

    ?)
      echo ""
      ;;
  esac
done