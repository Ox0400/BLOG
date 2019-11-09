---
layout: post
title: "[原创]-Nginx-添加授权访问-使用-httpd-tools"
date: 2017-03-28 17:27:58
image: '/assets/img/'
description: "安装 nginx 安装 iptables iptables-services 配置 iptables 启动 iptables 安装 httpd-tools 生成密码文件 配置 nginx 启动 nginx安装 nginxyum install -y nginx安装 iptables iptables-services 使用 iptables-services 管理配置文件 yum install"
tags:
    - nginx
    - 密码
    - iptables
categories:
    - linux
---



---

#### 安装 nginx
``` bash
yum install -y nginx
```
#### 安装 iptables iptables-services
> 使用 iptables-services 管理配置文件
``` bash
yum install -y iptables iptables-services
```
#### 配置 iptables
``` bash
# vi /etc/sysconfig/iptable
# 默认有22端口, 复制一行, 改为 nginx 端口即可.
-A INPUT -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT
```
#### 启动 iptables
``` bash
service iptables start
```
#### 安装 httpd-tools
``` bash
# 生成密码
yum install -y httpd-tools
```
#### 生成密码文件
``` bash
htpasswd /etc/nginx/httpdwd nginx_user
```
#### 配置 nginx
```  bash
# vi /etc/nginx/nginx.conf
# 在 配置中添加 auth_basic 和 auth_bashc_user_file 即可
server {
        listen       80 default_server;
        listen       [::]:80 default_server;
        server_name  _;
        client_max_body_size 10K;
        root         /usr/share/nginx/html;
        # 在这里添加授权配置
        auth_basic "Username and Password are required";
        auth_basic_user_file /etc/nginx/httpdwd;
        # ... ...
    }
```
#### 启动 nginx
``` bash
service nginx start
```

---
 完
