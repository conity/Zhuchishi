PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

Green="\033[32m"
Font="\033[0m"
Blue="\033[33m"

rootness(){
    if [[ $EUID -ne 0 ]]; then
       echo "Error:此脚本需以root权限运行!" 1>&2
       exit 1
    fi
}

disable_selinux(){
    if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
        setenforce 0
    fi
}

get_ip(){
    ip=`curl http://whatismyip.akamai.com`
}

config_tinyPortMapper(){
    echo -e "${Green}转发配置信息！${Font}"
    read -p "请输入接收端口:" port1
    read -p "请输入转出端口:" port2
    read -p "请输入远程IP:" tinyPortMapperip
}

firewall(){
    yum -y install firewalld
    systemctl restart firewalld.service
    systemctl enable firewalld.service
    firewall-cmd --set-default-zone=public
    firewall-cmd --add-interface=$ETH
    firewall-cmd --add-port=${port1}/tcp --permanent
    firewall-cmd --add-port=${port2}/tcp --permanent
    firewall-cmd --add-masquerade --permanent
    firewall-cmd --permanent --direct --add-rule ipv4 filter INPUT 0 -i $ETH -p gre -j ACCEPT
    firewall-cmd --reload
}


start_tinyPortMapper(){
    echo -e "${Green}正在配置转发...${Font}"
    nohup /tinyPortMapper/tinymapper -l 0.0.0.0:${port1} -r ${tinyPortMapperip}:${port2} -t -u > /root/tinymapper.log 2>&1 &
    if [ "${OS}" == 'CentOS' ];then
        sed -i '/exit/d' /etc/rc.d/rc.local
        echo "nohup /tinyPortMapper/tinymapper -l 0.0.0.0:${port1} -r ${tinyPortMapperip}:${port2} -t -u > /root/tinymapper.log 2>&1 &
        " >> /etc/rc.d/rc.local
        chmod +x /etc/rc.d/rc.local
    elif [ -s /etc/rc.local ]; then
        sed -i '/exit/d' /etc/rc.local
        echo "nohup /tinyPortMapper/tinymapper -l 0.0.0.0:${port1} -r ${tinyPortMapperip}:${port2} -t -u > /root/tinymapper.log 2>&1 &
        " >> /etc/rc.local
        chmod +x /etc/rc.local
    else
echo -e "${Green}检测到系统无rc.local自启，正在为其配置... ${Font} "
echo "[Unit]
Description=/etc/rc.local
ConditionPathExists=/etc/rc.local
 
[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99
 
[Install]
WantedBy=multi-user.target
" > /etc/systemd/system/rc-local.service
echo "#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.
" > /etc/rc.local
echo "nohup /tinyPortMapper/tinymapper -l 0.0.0.0:${port1} -r ${tinyPortMapperip}:${port2} -t -u > /root/tinymapper.log 2>&1 &
" >> /etc/rc.local
chmod +x /etc/rc.local
systemctl enable rc-local >/dev/null 2>&1
systemctl start rc-local >/dev/null 2>&1
    fi
    get_ip
    sleep 3
    echo
    echo -e "${Green}tinyPortMapper安装并配置成功!${Font}"
    echo -e "${Blue}你的接收端口为:${port1}${Font}"
    echo -e "${Blue}你的转出端口为:${port2}${Font}"
    echo -e "${Blue}你的服务器IP为:${ip}${Font}"
    exit 0
}

install_tinyPortMapper(){
echo -e "${Green}即将安装端口转发...${Font}"
#下载
wget -N --no-check-certificate "https://github.com/wangyu-/tinyPortMapper/releases/download/20180224.0/tinymapper_binaries.tar.gz"
#解压
tar -xzf tinymapper_binaries.tar.gz
mkdir /tinyPortMapper
KernelBit="$(getconf LONG_BIT)"
    if [[ "$KernelBit" == '32' ]];then
        mv tinymapper_x86 /tinyPortMapper/tinymapper
    elif [[ "$KernelBit" == '64' ]];then
        mv tinymapper_amd64 /tinyPortMapper/tinymapper
    fi
    if [ -f /tinyPortMapper/tinymapper ]; then
    echo -e "${Green}tinyPortMapper安装成功！${Font}"
    else
    echo -e "${Green}tinyPortMapper安装失败！${Font}"
    exit 1
    fi
chmod +x /tinyPortMapper/tinymapper
rm -rf version.txt
rm -rf tinymapper_*
}

status_tinyPortMapper(){
    if [ -f /tinyPortMapper/tinymapper ]; then
    echo -e "${Green}检测到tinyPortMapper已存在，并跳过安装步骤！${Font}"
        main_x
    else
        main_y
    fi
}

main_x(){
rootness
disable_selinux
config_tinyPortMapper
firewall
start_tinyPortMapper
}

main_y(){
rootness
disable_selinux
install_tinyPortMapper
config_tinyPortMapper
firewall
start_tinyPortMapper
}

status_tinyPortMapper
