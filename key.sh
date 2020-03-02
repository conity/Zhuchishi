#/bin/sh
apt-get update -y
apt-get install curl -y
yum clean all
yum make cache
yum install curl -y

cd ~

mkdir .ssh
cd .ssh
read -p "請輸入公鑰的文件名：" KEY_ID
mv /root/${KEY_ID} /root/.ssh/authorized_keys
chmod 700 authorized_keys
cd ../
chmod 600 .ssh
cd /etc/ssh/

read -p "請輸入重設的SSH端口：" port3

sed -i "/PasswordAuthentication no/c PasswordAuthentication no" sshd_config
sed -i "/RSAAuthentication no/c RSAAuthentication yes" sshd_config
sed -i "/PubkeyAuthentication no/c PubkeyAuthentication yes" sshd_config
sed -i "/PasswordAuthentication yes/c PasswordAuthentication no" sshd_config
sed -i "/RSAAuthentication yes/c RSAAuthentication yes" sshd_config
sed -i "/PubkeyAuthentication yes/c PubkeyAuthentication yes" sshd_config
sed -i 's%#Port 22%Port '${port3}%'' /etc/ssh/sshd_config
sed -i 's%#PermitEmptyPasswords no%PermitEmptyPasswords no%' /etc/ssh/sshd_config
sed -i 's%#UseDNS yes%UseDNS no%' /etc/ssh/sshd_config
yum -y install policycoreutils-python
semanage port -a -t ssh_port_t -p tcp ${port3}
egrep "UseDNS|${port3}|EmptyPass" /etc/ssh/sshd_config >> $LOG_FILE
service sshd restart
service ssh restart
systemctl restart sshd
systemctl restart ssh
cd ~
rm -rf key.sh
