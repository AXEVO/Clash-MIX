SKIPUNZIP=1

# 定义安装路径
Module_dir=/data/adb/modules/Clash

# 解压 ZIP 文件到模块路径
unzip -o "${ZIPFILE}" -x 'META-INF/*' -d $MODPATH >&2

# 删除已存在的安装目录并创建新目录
rm -rf ${Module_dir} && mkdir -p ${Module_dir}

# 移动解压的 Clash 文件夹到安装目录
mv ${MODPATH}/Clash/* ${Module_dir}/

# 设置安装目录的权限
chmod 777 -Rf ${Module_dir}