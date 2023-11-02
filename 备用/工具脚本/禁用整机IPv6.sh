#!/system/bin/sh

echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
echo 1 > /proc/sys/net/ipv6/conf/default/disable_ipv6
echo 1 > /proc/sys/net/ipv6/conf/wlan0/disable_ipv6
echo 1 > /proc/sys/net/ipv6/conf/lo/disable_ipv6

echo 0 > /proc/sys/net/ipv6/conf/all/accept_ra
echo 0 > /proc/sys/net/ipv6/conf/wlan0/accept_ra

sysctl -w net.core.rmem_max=2500000