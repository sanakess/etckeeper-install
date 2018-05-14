# etckeeper-install
bash etckeeper install script

WHAT IS IT
---
Its a script that install etckeeper on client and create repo on server side. 

After install, on server will be created user "git-hostname" with /etc repo of your host. 

Etckeeper do backups every day, but you can run it manualy by command:

```
ekp
```

DEPENDENCIES
---
You may need to install git on server before launch

USAGE
---
change server ip from SERVERIP=192.168.x.x to your serverip and run script on client:

```
chmod 750 etckeeper_install.sh
./etckeeper_install.sh
```
