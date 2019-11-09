---
layout: post
title: "[原创]-Centos-安装部署-Hadoop-集群和-hive"
date: 2017-05-25 18:26:01
image: '/assets/img/'
description: "Centos 7.3 安装部署 Hadoop集群环境部署Server: Centos 7.3 (CPU:1 Core Mem: 1G Disk: 40G) Hadoop: 2.8.0 Hive: 2.1.1 JDK: 1.8.0 --- Master: 192.168.10.1 Hadoop-01: 192.168.10.2 Hadoop-02: 192.168.10.3  如果没有特别声明, 所有"
tags:
    - centos
    - hadoop
    - 集群
    - hive
categories:
    - linux
    - hadoop
    - Hive
    - 大数据
---



# Centos 7.3 安装部署 Hadoop集群

## 环境部署
	Server: Centos 7.3 (CPU:1 Core Mem: 1G Disk: 40G)
	Hadoop: 2.8.0
	Hive: 2.1.1
	JDK: 1.8.0
	---
	Master: 192.168.10.1
	Hadoop-01: 192.168.10.2
	Hadoop-02: 192.168.10.3
	
> 如果没有特别声明, 所有的步骤在所有机器上都执行.

## 配置服务器
#### 更新系统
```bash
yum clean all
yum update -y
```
#### 创建交换区 (重启生效)
```bash
# 创建3G 交换区, 交换区大小一般为物理内存2倍
dd if /dev/zero of=/swapfile bs=1024 count=3M
chmod 600 /swapfile
mkswap /swapfile
swapon /swafile
echo /swapfile  swap  swap defaults 0 0 >> /etc/fstab
```
#### 修改 hostname
```bash
# 分别在对应的机器上执行
$ echo master > /etc/hostname # 在 master 执行
$ echo hadoop-01 > /etc/hostname # 在 hadoop-01执行
$ echo hadoop-02 > /etc/hostname # 在 hadoop-02 执行
$ echo 192.168.10.1 master >> /etc/hosts
$ echo 192.168.10.2 hadoop-01 >> /etc/hosts
$ echo 192.168.10.3 hadoop-02 >> /etc/hosts
```
#### 安装 JDK
```bash
# search JDK version list
$ yum search openjdk
$ yum install -y java-1.8.0-openjdk # 注意版本号, 用上一步收到的JDK版本
$ java -version 
openjdk version "1.8.0_131"
OpenJDK Runtime Environment (build 1.8.0_131-b11)
OpenJDK 64-Bit Server VM (build 25.131-b11, mixed mode)
# 这里记录下 JDK 安装路径在 /usr/lib/jvm/jre-openjdk/, 后面配置 JAVA_HOME 需要
```
#### 添加用户
```bash
# 添加 eshadoop 用户, 添加至默认 sudo 用户组,和 hadoop 组
$ add user hadoop;adduser eshadoop -G hadoop, wheel
$ password eshadoop # 配置 eshadoop 密码
$ groups eshadoop
eshadoop: eshadoop wheel hadoop
```
#### 配置集群之间免密登录
```bash
# 使用 eshadoop 重新登录
$ yum install -y ssh
$ ssh-keygen -t rsa -C zhipeng@hadoop.com
$ ssh-copy-id localhost
$ ssh-copy-id master
$ ssh-copy-id hadoop-01
$ ssh-copy-id hadoop-02

# 编辑 /etc/ssh/sshd_config
# 找到 RSAAuthentication, PubkeyAuthentication, AuthorizedKeysFile, 将行首的#号去掉
# 正确结果如果
RSAAuthentication Yes
PubkeyAuthentication Yes
AuthorizedKeysFile .ssh/authorized_keys
$ sudo service sshd restart
```

## 安装 Hadoop
```bash
# 我使用的版本是2.8.0
$ wget http://mirror.bit.edu.cn/apache/hadoop/common/hadoop-2.8.0/hadoop-2.8.0.tar.gz
$ sudo tar zxvf hadoop-2.8.0.tar.gz -C /usr/local/
$ sudo mv /usr/local/hadoop-2.8.0/ /usr/local/hadoop
$ sudo chown -R eshadoop:hadoop /usr/local/hadoop
```
#### 配置环境变量
```bash
# 我使用的是 .bashrc, 只针对当前用户生效. 如果要设置为全局生效, 修改 /etc/profile 即可
$ vi ~/.bashrc
# 将下面追加至 .bashrc
# ----------- .bashrc START ----------
#Set JAVA_HOME
export JAVA_HOME=/usr/lib/jvm/jre-openjdk/
#Set Hadoop related environment variable
export HADOOP_INSTALL=/usr/local/hadoop
#Add bin and sbin directory to PATH
export PATH=$PATH:$HADOOP_INSTALL/bin
export PATH=$PATH:$HADOOP_INSTALL/sbin
#Set few more Hadoop related environment variable
export HADOOP_MAPRED_HOME=$HADOOP_INSTALL
export HADOOP_COMMON_HOME=$HADOOP_INSTALL
export HADOOP_HDFS_HOME=$HADOOP_INSTALL
export YARN_HOME=$HADOOP_INSTALL
export HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_INSTALL/lib/native
export HADOOP_OPTS="-Djava.library.path=$HADOOP_INSTALL/lib"
export HADOOP_HOME=/usr/local/hadoop/
# -------- .bashrc END -----------


$ hadoop version
Hadoop 2.8.0
Subversion https://git-wip-us.apache.org/repos/asf/hadoop.git -r 91f2b7a13d1e97be65db92ddabc627cc29ac0009
Compiled by jdu on 2017-03-17T04:12Z
Compiled with protoc 2.5.0
From source with checksum 60125541c2b3e266cbf3becc5bda666
This command was run using /usr/local/hadoop/share/hadoop/common/hadoop-common-2.8.0.jar
```
#### 配置 Hadoop
##### 配置 slaves
```bash
$ echo master > /usr/local/hadoop/etc/hadoop/slaves
$ echo hadoop-01 >> /usr/local/hadoop/etc/hadoop/slaves
$ echo hadoop-02 >> /usr/local/hadoop/etc/hadoop/slaver
```

##### 配置 hdfs-fite.xml
``` bash
# 将一下 xml 替换掉 hdfs-site.xml 中的 <configuration/>
$ vi /usr/local/hadoop/etc/hadoop/hdfs-site.xml
	<configuration>
	    <property>
	        <name>dfs.namenode.secondary.http-address</name>
	        <value>master:9001</value>
	    </property>
	    <property>
	       <name>dfs.namenode.name.dir</name>
	       <value>file:/home/eshadoop/hdfs/tmp/dfs/name</value>
	    </property>
	    <property>
	        <name>dfs.datanode.data.dir</name>
	        <value>file:/home/eshadoop/hdfs/tmp/dfs/data</value>
	    </property>
	    <property>
	      <name>dfs.replication</name>
	      <value>3</value>
	    </property>
	</configuration>
```
##### 配置 mapred-site.xml
``` bash
$ vi /usr/local/hadoop/etc/hadoop/mapred-site.xml
# 将一下 configuration 替换掉原文中的 <configuration/>
	<configuration>
	        <property>
	                <name>mapreduce.framework.name</name>
	                <value>yarn</value>
	        </property>
	        <property>
	                <name>mapreduce.jobhistory.address</name>
	                <value>master:10020</value>
	        </property>
	        <property>
	                <name>mapreduce.jobhistory.webapp.address</name>
	                <value>master:19888</value>
	        </property>
	</configuration>
```

##### 配置 yarn-site.xml
``` bash
$ /usr/local/hadoop/etc/hadoop/yarn-site.xml
	<configuration>
		<property>
		  <name>yarn.nodemanager.aux-services</name>
		  <value>mapreduce_shuffle</value>
		</property>
		<property>
		  <name>yarn.nodemanager.aux-services.mapreduce.shuffle.class</name>
		  <value>org.apache.hadoop.mapred.ShuffleHandler</value>
		</property>
		<property>
		  <name>yarn.resourcemanager.address</name>
		  <value>master:8032</value>
		</property>
		<property>
		  <name>yarn.resourcemanager.scheduler.address</name>
		  <value>master:8030</value>
		</property>
		<property>
		  <name>yarn.resourcemanager.resource-tracker.address</name>
		  <value>master:8035</value>
		</property>
		<property>
		  <name>yarn.resourcemanager.admin.address</name>
		  <value>master:8033</value>
		</property>
		<property>
		  <name>yarn.resourcemanager.webapp.address</name>
		  <value>master:8088</value>
		</property>
	</configuration>
```

##### 配置 core-site.xml
``` bash
$ vi /usr/local/hadoop/etc/hadoop/core-site.xml
# 注意: hadoop.proxyuser.eshadoop.** eshadoop 应该和 hadoop 所有者一致! 否则后续的 Hive2 无法登陆/建表/导入数据
	<configuration>
	    <property>
	        <name>hadoop.tmp.dir</name>
	        <value>/home/eshadoop/hdfs/tmp</value>
	        <description>A base for other temporary directories.</description>
	    </property>
	    <property>
	        <name>fs.default.name</name>
	        <value>hdfs://master:9000</value>
	    </property>
	    <property>
	        <name>hadoop.proxyuser.eshadoop.hosts</name>
	        <value>*</value>
	    </property>
	    <property>
	        <name>hadoop.proxyuser.eshadoop.groups</name>
	        <value>*</value>
	        </property>
	</configuration>
$ mkdir -p ~/hdfs/tmp/
```

> 到这里, hadoop 已经配置完成,  
> 特别注意
> 请保持所有机器的core-site.xml中fs.default.name 都为 hdfs://master:9000. 否则无法在 web 界面无法看到 nodename

#### 启动 hadoop
```bash
$ hadoop namenode -format
$ start-all.sh #  文件路径在 /usr/local/hadoop/sbin/
```

##  安装 Hive
```bash
 $ wget https://mirrors.tuna.tsinghua.edu.cn/apache/hive/hive-2.1.1/apache-hive-2.1.1-bin.tar.gz
 $ sudo tar zxvf apache-hive-2.1.1-bin.tar.gz -C /usr/local/
 $ sudo mv /usr/local/apache-hive-2.1.1-bin /usr/local/hive
 $ sudo chown -R eshadoop /usr/local/hive
```

##### 配置环境变量
```bash
$ vi ~/.bashrc
# 将下面追加至 .bashrc
# ----------- .bashrc START ----------
# config hive
export HIVE_HOME=/usr/local/hive
export PATH=$PATH:$HIVE_HOME/bin
export CLASSPATH=$CLASSPATH:/usr/local/hive/lib/*:.
export HADOOP_USER_CLASSPATH_FIRST=true
# export HIVE_AUX_JARS_PATH=/opt/lib/elasticsearch-hadoop-2.1.1.jar
# -----------  .bashrc END  ----------
$ source ~/.bashrc # 配置生效
```

##### 配置 hive-env.sh
``` bash
$ cp $HIVE_HOME/conf/hive-env.sh.template $HIVE_HOME/conf/hive-env.sh
$ vi $HIVE_HOME/conf/hive-env.sh
# ----------- hive-env.sh START -------------
# 配置 HADOOP_HOME 
HADOOP_HOME=/usr/local/hadoop
# -----------  hive-env.sh END  -------------
```

##### 配置 hive-log4j2.properties
``` bash
$ cp $HIVE_HOME/conf/hive-log4j2.properties.template $HIVE_HOME/conf/hive-log4j2.properties
$ vi $HIVE_HOME/conf/hive-log4j2.properties
# 配置 log 日志路径: 
property.hive.log.dir = /hive/log/
```
##### 其他

```bash
$ cp $HIVE_HOME/conf/hive-default.xml.template $HIVE_HOME/conf/hive-default.xml
$ cp $HIVE_HOME/conf/hive-site.xml.template $HIVE_HOME/conf/hive-site.xml
# hive-site.xml修改配置如下
hive.exec.scratchdir -- /hive/
hive.exec.local.scratchdir -- /hive/
hive.downloaded.resources.dir -- /hive/sessions/${hive.session.id}_resources
hive.hbase.snapshot.restoredir -- /hive/snapshot/
hive.querylog.location -- /hive/log/querylog
hive.service.metrics.file.location -- /hive/report.json
hive.server2.logging.operation.log.location -- /hive/log/operation_logs
hive.llap.io.allocator.mmap.path -- /hive/llap/
# -- end --
$ cp $HIVE_HOME/conf/hive-exec-log4j2.properties.template $HIVE_HOME/conf/hive-exec-log4j2.properties

```

##### 配置 hive 用户名密码 (这里有些问题,  需要再验证)
```bash
$ hive --service metastore
$ schematool -initSchema -dbType derby --verbose -userName eshadoop -passWord eshadoop
$ hdfs dfsadmin –refreshSuperUserGroupsConfiguration
$ yarn rmadmin -refreshSuperUserGroupsConfiguration
$ hdfs dfsadmin -fs hdfs://client-01:9000 -refreshSuperUserGroupsConfiguration
$ hdfs dfsadmin -fs hdfs://client-02:9000 -refreshSuperUserGroupsConfiguration
$ hdfs dfsadmin -fs hdfs://master:9000 -refreshSuperUserGroupsConfiguration
$ stop-all.sh
$ start-all.sh
```
> 修改 **hive-site.xml hive.server2.enable.doAs** 为 false 可以匿名
##### 启动 hive2 sever
```bash
$ hive --service hiveserver2
```

##### 测试 hive2 client
```bash
# 创建测试文件, 用于导入数据
$ echo 1 a >> /tmp/test_user.csv
$ echo 2 v >> /tmp/test_user.csv
$ echo 3 c >> /tmp/test_user.csv
$ echo 4 d >> /tmptest_user.csv

# 注意 hive2的用户名和密码是hadoop/core-site.xml中用户一致.
$ beeline -u jdbc:hive2://xxx.xxx.xxx.xxx:10000/default -n eshadoop -p eshadoop
# 进入 hive2 环境
# 建表 - 分隔符数空格(文件导入时分隔符要保持一致
0: jdbc:hive2://120.25.94.189:10000/default> create table users(id string, name string)  row format delimited fields terminated by " ";
No rows affected (1.269 seconds)
# 列出所有表
0: jdbc:hive2://120.25.94.189:10000/default> show tables;
+-----------+--+
| tab_name  |
+-----------+--+
| users     |
+-----------+--+
# 从文件导入数据
0: jdbc:hive2://120.25.94.189:10000/default> load data local inpath "/tmp/test_user.csv" into table users;
No rows affected (1.979 seconds)
# 查询数据
0: jdbc:hive2://120.25.94.189:10000/default> select * from users;
+-----------+-------------+--+
| users.id  | users.name  |
+-----------+-------------+--+
| 1         | a           |
| 2         | b           |
| 3         | c           |
| 4         | d           |
+-----------+-------------+--+
4 rows selected (1.647 seconds)

```

#### 参考
- [Hadoop集群安装配置教程_Hadoop2.6.0_Ubuntu/CentOS](http://www.powerxing.com/install-hadoop-cluster/)
- [Java之美[从菜鸟到高手演练]之Linux下Hadoop的完全分布式安装](http://blog.csdn.net/zhangerqing/article/details/42647435)
- [Apache Hive - Setting Up HiveServer2](https://cwiki.apache.org/confluence/display/Hive/Setting+Up+HiveServer2#SettingUpHiveServer2-LoggingConfiguration)
- [Hadoop 2.0中用户安全伪装/模仿机制实现原理](http://dongxicheng.org/mapreduce-nextgen/hadoop-secure-impersonation/)
- [How to use hive with other user](https://stackoverflow.com/questions/9713807/how-to-use-hive-with-other-user)
- [HIVE connecion error](https://community.hortonworks.com/questions/31528/hive-connecion-error.html)
- []()
