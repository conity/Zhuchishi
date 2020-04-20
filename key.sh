#/bin/sh
apt-get update -y
yum clean all
yum install firewalld -y 
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
systemctl restart firewalld.service
firewall-cmd --add-port=${port3}/tcp --permanen
firewall-cmd --reload

sed -i 's:# AuthorizedKeysFile:AuthorizedKeysFile:'  /etc/ssh/sshd_config
sed -i 's/# PasswordAuthenticati yes/PasswordAuthentication no/'  /etc/ssh/sshd_config

sed -i 's/# RSAAuthentication yes/RSAAuthentication yes/'  /etc/ssh/sshd_config
sed -i 's/# StrictModes no/StrictModes no/'  /etc/ssh/sshd_config

sed -i 's/# Port 22/Port '${port3}'/' /etc/ssh/sshd_config     

systemctl restart sshd.service
cd ~
rm -rf key.sh
