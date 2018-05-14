#!/bin/bash
#Задаем хостнейм клмента
HOSTNAMECLIENT=${HOSTNAME%%.*}
HOSTNAMEDOMAINCLIENT=$HOSTNAME
SERVERIP=192.168.x.x
 
#проверка есть ли ключ, если нет то генерирует
if ! [ -e  ~/.ssh/id_rsa.pub ]; then
ssh-keygen
fi
 
#Создаем пользователя и папки

read -p "Enter login user name for SERVER: " REMOTE_USER
#echo $REMOTE_USER
USER=$REMOTE_USER
echo "Creating user and folders on the server..."
scp ~/.ssh/id_rsa.pub $USER@$SERVERIP:/home/$USER/ak
ssh -tt $USER@$SERVERIP "sudo useradd -m -s /bin/bash git-$HOSTNAMECLIENT ; \
sudo mkdir /home/git-$HOSTNAMECLIENT/repositories/ ; \
sudo chmod 750 /home/git-$HOSTNAMECLIENT/; \
sudo mkdir /home/git-$HOSTNAMECLIENT/.ssh/; \
sudo chown -R git-$HOSTNAMECLIENT:apache /home/git-$HOSTNAMECLIENT/; \
sudo chmod -R 700 /home/git-$HOSTNAMECLIENT/.ssh/; \
sudo touch /home/git-$HOSTNAMECLIENT/.ssh/authorized_keys; \
sudo mv /home/$USER/ak /home/git-$HOSTNAMECLIENT/.ssh/authorized_keys; \
sudo chown git-$HOSTNAMECLIENT:apache /home/git-$HOSTNAMECLIENT/.ssh/authorized_keys; \
if ! grep -q git-$HOSTNAMECLIENT /var/www/gitlist/config.ini; then \
sudo sed -i \"/detached/a repositories[] = \/home\/git-$HOSTNAMECLIENT\/repositories\/\" /var/www/gitlist/config.ini; \
else \
echo \"repo folder already add in /var/www/gitlist/config.ini\"; \
fi"
 
#инициируем репозиторий
ssh git-$HOSTNAMECLIENT@$SERVERIP "mkdir /home/git-$HOSTNAMECLIENT/repositories/$HOSTNAMECLIENT.git; \
cd /home/git-$HOSTNAMECLIENT/repositories/$HOSTNAMECLIENT.git; \
git init --bare; echo $HOSTNAMEDOMAINCLIENT > description"
 
#Ignore files etckeeper
cat > /etc/.gitignore << \EOF
*.dpkg-*
*.ucf-*
# old versions of files
*.old
blkid.tab
blkid.tab.old
ed
nologin
ld.so.cache
prelink.cache
mtab
mtab.fuselock
.pwd.lock
*.LOCK
network/run
adjtime
lvm/cache
lvm/archive
X11/xdm/authdir/authfiles/*
ntp.conf.dhcp
.initctl
webmin/fsdump/*.status
webmin/webmin/oscache
apparmor.d/cache/*
service/*/supervise/*
service/*/log/supervise/*
sv/*/supervise/*
sv/*/log/supervise/*
*.elc
*.pyc
*.pyo
init.d/.depend.*
openvpn/openvpn-status.log
cups/subscriptions.conf
cups/subscriptions.conf.O
fake-hwclock.data
check_mk/logwatch.state
*~
.*.sw?
.sw?
\#*\#
DEADJOE
ssh/*key
# begin section managed by etckeeper (do not edit this section by hand)
 
# new and old versions of conffiles, stored by dpkg
*.dpkg-*
# new and old versions of conffiles, stored by ucf
*.ucf-*
 
# old versions of files
*.old
 
# mount(8) records system state here, no need to store these
blkid.tab
blkid.tab.old
 
# some other files in /etc that typically do not need to be tracked
nologin
ld.so.cache
prelink.cache
mtab
mtab.fuselock
.pwd.lock
*.LOCK
network/run
adjtime
lvm/cache
lvm/archive
X11/xdm/authdir/authfiles/*
ntp.conf.dhcp
.initctl
webmin/fsdump/*.status
webmin/webmin/oscache
apparmor.d/cache/*
service/*/supervise/*
service/*/log/supervise/*
sv/*/supervise/*
sv/*/log/supervise/*
*.elc
*.pyc
*.pyo
init.d/.depend.*
openvpn/openvpn-status.log
cups/subscriptions.conf
cups/subscriptions.conf.O
fake-hwclock.data
check_mk/logwatch.state
 
# editor temp files
*~
.*.sw?
.sw?
\#*\#
DEADJOE
# end section managed by etckeeper
ssh/*key
EOF
chmod 600 /etc/.gitignore
 
#установка etckeeper
if grep -q "CentOS" /etc/*-release && ! which etckeeper > /dev/null; then
yum install epel-release && yum install etckeeper git
#echo centos
fi
 
if grep -q "Debian" /etc/*-release && ! which etckeeper > /dev/null; then
apt-get update
apt-get -y install etckeeper git
#echo debian
fi
 
#настройка etckeeper
sed -i 's/PUSH_REMOTE=""/PUSH_REMOTE="origin"/g' /etc/etckeeper/etckeeper.conf
 
#инициализация репозитория
cd /etc/
echo "etckeeper initialization..."
etckeeper init
git remote add origin git-$HOSTNAMECLIENT@$SERVERIP:~/repositories/$HOSTNAMECLIENT.git
git remote set-url origin git-$HOSTNAMECLIENT@$SERVERIP:~/repositories/$HOSTNAMECLIENT.git
 
#Включение в коммит всех файлов в дирректории
git add -A
 
#коммит
git commit -m 'Change 1st'
 
#пуш на сервер
git push origin master
 
#Добавляем в исключения ключи ssh
#if ! grep -q "ssh" /etc/.gitignore; then
#echo  "ssh/*key" >> /etc/.gitignore
#fi
 
#проверка и создание файла на пуш
if [ ! -f /usr/local/bin/ekp ]; then
touch /usr/local/bin/ekp
cat > /usr/local/bin/ekp << \EOF
#!/bin/bash
NOWDATE=$(date +%Y-%m-%d"_"%H_%M_%S)
cd /etc
git add -A
if [ -z "$1" ]; then
        git commit -m "Change on $NOWDATE"
 
 else
        git commit -m "$1"
 fi
git push origin master
EOF
chmod 755 /usr/local/bin/ekp
fi
