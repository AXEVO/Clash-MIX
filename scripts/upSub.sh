#!/system/bin/sh
. /data/clash/clash.config
scripts=`realpath $0`
scripts_dir=`dirname ${scripts}`
subItem=""
bkPath="/data/clash/dashboard/dist/subs"
gotoUrl(){
name="$1"
url=${2}
textIndex=1
#echo ${name}  ${url}
echo "$(curl -H 'User-Agent:ClashforWindows/0.19.23' -I ${url})" >${scripts_dir}/${1//:/}
hsums=$(cat "${scripts_dir}/${1//:/}" | wc -l)
while (($textIndex<=$hsums)) do
 lin=$(sed -n ${textIndex},${textIndex}p "${scripts_dir}/${1//:/}");
 result=$(echo ${lin} | grep 'subscription-userinfo:')
 if [ "${result}" != "" ]; then
  echo ${lin//subscription-userinfo:/$1} >> "${bkPath}.bk"
  #subItem+=${lin//subscription-userinfo:/$1}"\n"
  rm -rf "${scripts_dir}/${1//:/}"
# echo ${subItem}>>""
  break
 fi
 let 'textIndex++';
done
}
UpStart(){
i=1;

echo [`TZ=Asia/Shanghai date "+%H:%M:%S"`]"info: 更新订阅流量信息" >> ${CFM_logs_file}

sums=$(cat "${Clash_config_file}" | wc -l)
#echo $(($sums-1))
while (($i <= $sums )) do
 lin="$(sed -n ${i},${i}p "${Clash_config_file}")";
 lin2="";
 if [ ${i} -ge 2 ]; then
  Index=$(expr ${i} - 2)
  lin2="$(sed -n ${Index},"${Index}"p "${Clash_config_file}")";
 fi
 #echo ${lin}
 lin=${lin// /}
 result=$(echo ${lin} | grep 'url:"http')
 if [ "${result}" != "" ]; then
 {
  #echo ${lin2//:/}
  lin=${lin//"url:"/}
  #echo ${lin//'"'/}"&flag=clash"
 gotoUrl ${lin2} ${lin//'"'/}"&flag=clash"
 # sleep 5
 }&
 fi
 result=$(echo ${lin} | grep 'proxy-groups:')
 if [ "${result}" != "" ]; then
  #echo ${lin2//:/}
  #lin=${lin//"url:"/}
  
  break
 # sleep 5
 fi
 let 'i++';
done;
wait;
echo `TZ=Asia/Shanghai date "+%Y-%m-%d %H:%M:%S"`>"${bkPath}";
cat "${bkPath}.bk" >>"${bkPath}"
rm "${bkPath}.bk";

echo "解析完成 ${subItem}"
}
while getopts ":kfmpusl" signal; do
    case ${signal} in
        s)
            UpStart
            ;;
        k)
            
            ;;
        ?)
            echo ""
            ;;
    esac
done