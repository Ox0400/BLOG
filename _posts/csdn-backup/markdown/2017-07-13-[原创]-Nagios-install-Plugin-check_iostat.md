---
layout: post
title: "[原创]-Nagios-install-Plugin-check_iostat"
date: 2017-07-13 16:15:06
image: '/assets/img/'
description: "使用 Nagios 监控机器 IO 性能   Nagios 安装过程略过    插件一般存放于: /usr/lib/nagios/plugins/ 或者 /usr/lib64/nagios/plugins/, 或者 /usr/lib/nagios3/plugins/ 在Nagios 官网查找想要的插件 Category: Pluginscheck_iostat 地址在这里:  check_iosta"
tags:
    - nagios
    - 插件
    - iostat
    - plugin
categories:
    - linux
---



#### **使用 Nagios 监控机器 IO 性能**
> Nagios 安装过程略过
> 插件一般存放于: /usr/lib/nagios/plugins/ 或者 /usr/**lib64**/nagios/plugins/, 或者 /usr/lib/**nagios3**/plugins/


#### 在Nagios 官网查找想要的插件 [Category: Plugins](https://exchange.nagios.org/directory/Plugins)
#### check_iostat 地址在这里:  [check_iostat - I/O statistics](https://exchange.nagios.org/directory/Plugins/Operating-Systems/Linux/check_iostat--2D-I-2FO-statistics/details)

#### 将脚本保存到 Nagios Plugins 目录就可以

#### 在被监控机本地机器测试
```bash
$ bash check_iostat -d sdb -c 10 -w 5
OK - I/O stats tps=0.00 KB_read/s=0.00 KB_written/s=0.00 | 'tps'=0.00; 'KB_read/s'=0.00; 'KB_written/s'=0.00;
```
#### 结果是有了, 但是在用 iostat 和用 check_iostat 对比输出后发现, check_iostat 结果几乎没有任何变化, 但硬盘命名正在做一下读写的操作.

#### 对 check_iostat 做修改
```bash
# 查看原文件, tps/w/r 也是通过 iostat 获取的
# 分别执行3次获取 tps/w/r, 很快的输出结果, 没有做延时统计
# Doing the actual check:
tps=`$iostat $disk | grep $disk | awk '{print $2}'`
kbread=`$iostat $disk | grep $disk | awk '{print $3}'`
kbwritten=`$iostat $disk | grep $disk | awk '{print $4}'`

# 开始改造代码

# 将这块修改为如下代码
# Doing the actual check:
iostat_out=`$iostat -m -d 2 2 $disk | grep $disk | tail -n 1`
tps=`echo $iostat_out| awk '{print $2}'`
mbread=`echo $iostat_out| awk '{print $3}'`
mbwritten=`echo $iostat_out| awk '{print $4}'`
# 将这个文件中所有的 kbread 修改为 mbread, kmwritten修改为 kmwritten

# 把输出结果 echo 语句中 KB 修改为 MB,
# echo "$msg - I/O stats tps=$tps MB_read/s=$mbread MB_written/s=$mbwritten | 'tps'=$tps; 'MB_read/s'=$mbread; 'MB_written/s'=$mbwritten;"

# 这快代码意思是
# 1. 执行一次 iostat, 读取两次 io 状态, 中间休息2s.
# 2. -m, 读取结果转换为 MB, 不再是 KB, 更方便看结果.
# 如有需要, 将首行的 /bin/sh 修改为 /bin/bash
```

#### 再次测试结果
```bash
$ bash check_iostat -d sdb -c 10 -w 5
OK - I/O stats tps=0.50 MB_read/s=0.05 MB_written/s=0.00 | 'tps'=0.50; 'MB_read/s'=0.05; 'MB_written/s'=0.00;
```

> 在 ubuntu 上以上代码完全可用, 在 centos 测试, 发现本地调用可用,
> 但是通过远程监控, 会报错磁盘不存在.


``` bash
$ bash check_iostat -d sd1b -c 10 -w 5
ERROR: Device incorrectly specified
# ... ...
```
#### 查看源码, 问题定位到参数检查磁盘是否存在这块代码
```bash
# Checking parameters:
[ ! -b "/dev/$disk" ] && echo "ERROR: Device incorrectly specified" && help

# 这块代码很有意思的, 无非就是检查磁盘是否存在, 但是为啥在 centos 上运行会报错呢?
# 测试结果: 在 centos 本地执行并不会报错, 只有在远程调用的时候会意识磁盘不存在. 
#! -b意思是: 磁盘不存在, 但是远程调用结果恰恰相反?
# 将 ! 去掉(这本身语法就是如果磁盘存在就提示错误), 远程调用正常, 但本地执行报磁盘不存在.
```
> 多次测试后, 排除个 bash/sh/zsh 的原因, 实在找不到原因了. 执行通过另类办法了. 
> 同事找到一个原因, 可能是权限问题.切换到 nagios 用后, ls /dev/, 权限都显示??????

```bash
# 将这里修改为如下代码
df -h|grep sdb > /dev/null && [ $? ]  && sleep 0 || echo "ERROR: Device incorrectly specified" && help
# 什么意思, 使用 df -h 检查磁盘是否存在, 如果存在, sleep 0s, 否在提示错误, 并执行 help 函数结束进程.
```

#### 总结

- 确保头部是 /bin/bash
- 修改 iostat 语法, 保证检查2次以上再输出
- 可以将输出 KB 调整为 MB
- 将检查磁盘是否存在这块, 使用 df -h 能方式检查. 

#### 参考
- [Nagios Plugin - check_iostat](https://exchange.nagios.org/directory/Plugins/Operating-Systems/Linux/check_iostat--2D-I-2FO-statistics/details)
