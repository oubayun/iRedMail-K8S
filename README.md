# iRedMail K8S #

本镜像基于lejmr的iredmail-docker修改而来，解决原有iredmail-docker只能够部署在docker中，而无法部署到k8s的问题，并对一些参数进行了本地化。

iRedMail允许在几分钟之内免费部署一个开放源代码，全功能的邮件系统。而Docker容器化可以减少部署时间，并帮助您在短短的几秒钟内实现邮件系统部署。

当前版本的容器使用MySQL进行帐户保存。并通过PV、PVC挂载实现数据持久化，在容器销毁重构的情况下，不影响现有生产数据。容器包含所有组件（Postfix，Dovecot，Fail2ban，ClamAV，Roundcube和SoGo）和MySQL服务器。可以使用普通的Docker方法设置邮件服务器的主机名（docker run -h <host>或在docker compose文件中设置`hostname`），也可以通过对应的`03-create-mail01-dy.yaml`解决K8S无法设置主机名问题，并实现K8S化部署。

允许使用的环境变量:

MYSQL_ROOT_PASSWORD: 设置MySQL服务器安装时的初始化root账号密码；  
POSTMASTER_PASSWORD: 设置postmaster@DOMAIN的初始密码(邮箱管理员账号)，密码设置方式：({PLAIN}password)；  
SOGO_WORKERS: 调整可能影响SOGo接口性能的参数，默认为: 2；  
TZ: 设置容器时区；  

数据持久化目录:

 * /var/lib/mysql
 * /var/vmail
 * /var/lib/clamav

2020年2月26日主要功能修正 v1.0：

 * 修正原有iredmail需要使用hostname及域名解析初始化配置，而k8s pod无法配置hostname的问题；
 * 修正iredmail版本为稳定版1.1；
 * 修改时区为Asia/Shanghai（非必须）；
 * 修正DKIM初始化长度2048，无法满足国内域名解析TXT 1024长度限制问题；

纯Dokcker部署方式如下:

```
docker run -p 80:80 -p 443:443 \
           -h HOSTNAME.DOMAIN \
           -e "MYSQL_ROOT_PASSWORD=password" \
           -e "SOGO_WORKERS=1" \
           -e "TZ=Asia/Shanghai" \
           -e "POSTMASTER_PASSWORD={PLAIN}password" \
           -e "IREDAPD_PLUGINS=['reject_null_sender', 'reject_sender_login_mismatch', 'greylisting', 'throttle', 'amavisd_wblist', 'sql_alias_access_policy']" \
           -v /srv/iredmail/mysql:/var/lib/mysql \
           -v /srv/iredmail/vmail:/var/vmail \
           -v /srv/iredmail/clamav:/var/lib/clamav \
           --name=iredmail oubayun/iredmail-k8s:v1.1-latest
```


