---
layout: post
title: "[原创]Nominatim--快速部署-备份还原(PGSQL-数据库文件)"
date: 2018-05-15 12:31:27
image: '/assets/img/'
description: "nominatim 物理迁移, 其实是迁移 PGSQL 的数据库文件.  因为 nominatim 数据库文件少则几个GB, 多则几百 GB. 如果每次部署都使用 setup.php 进行导入, 时间非常慢. 测试 1.5MB 的马尔代夫地理信息 pbf 文件,  整个入库用了5分钟. (测试机用的1核1G, 不过1.5MB 用5分钟实在有点过分)  使用物理备份恢复, 脚本可以做到一键且秒级恢复..."
tags:
    - 
categories:
    - linux
    - SQL
---



nominatim 物理迁移, 其实是迁移 PGSQL 的数据库文件.
因为 nominatim 数据库文件少则几个GB, 多则几百 GB. 如果每次部署都使用 setup.php 进行导入, 时间非常慢. 测试 1.5MB 的马尔代夫地理信息 pbf 文件,  整个入库用了5分钟. (测试机用的1核1G, 不过1.5MB 用5分钟实在有点过分)
使用物理备份恢复, 脚本可以做到一键且秒级恢复.
搭配上 docker, 会更简单. docker 中部署 nominatim 和 pgsql 服务, 宿主机解压 pgsql 的数据库文件, 将宿主的 pgsql 文件目录挂载到 docker 中, 即可一键部署.

Nominatim 安装: http://nominatim.org/release-docs/latest/appendix/Install-on-Centos-7/
可选地图数据库: http://download.geofabrik.de/


### 修改 PGSQL 配置

```bash
# /usr/lib/systemd/system/postgresql.service
# 默认端口: 5432, 数据库文件地址: /usr/local/var/postgres
修改后端口使用5433, 数据库文件地址: /pgsql_data
Environment=PGPORT=5433
Environment=PGDATA=/pgsql_data

```

> pgsql 数据库中, nominatim 数据库是地理信息, postgres 数据库包含授权信息等. 迁移时不要删除任何数据.

### 修改 Nominatim 配置
```php
// 如果需要重新编译, 可以在编译前修改路径
// PATH: /home/nominatim/new/Nominatim-3.1.0/settings/defaults.php

// 如果不需要重新编译, 可以直接改已经编译后的路径
// PATH: /home/nominatim/new/Nominatim-3.1.0/build/settings/settings.php

// @define('CONST_Database_DSN', 'pgsql://@/nominatim'); // <driver>://<username>:<password>@<host>:<port>/<database>
@define('CONST_Database_DSN', 'pgsql://@:5433/nominatim');
```


### 修改 HTTPD Nominatim 配置(其实只要配置 pgsql 就可以, 这步可以不用操作)

```bash
# /etc/httpd/conf.d/nominatim.conf 
nominatim 初始位置位于 /home/nominatim, 后迁移至 /home/nominatim/new
```

```xml
<Directory "/home/nominatim/new/Nominatim-3.1.0/build/website">
  Options FollowSymLinks MultiViews
  AddType text/html   .php
  DirectoryIndex search.php
  Require all granted
</Directory>

Alias /nominatim /home/nominatim/new/Nominatim-3.1.0/build/website
```
> 注意: Directory 和 Alias 路径保持一致, 否则会报 403

```php
// 需要注意, 一定要确保 local.php 存在, 否则 Apache 无法解析路径
// /home/nominatim/new/Nominatim-3.1.0/build/settings/settings.php
<?php
 @define('CONST_Database_Web_User', 'apache');
 @define('CONST_Website_BaseURL', '/nominatim/');
  
```

> pgsql 修改端口, 数据库文件位置: /usr/lib/systemd/system/postgresql.service
apache 解析 php的 位置: /etc/httpd/conf.d/nominatim.conf 
nominatim 路径解析配置(必须设置, 否则网址会变成 hostname):  Nominatim-3.1.0/build/settings/local.php
nominatim 配置(配置数据库连接), build/settings/settings.php

我测试的时候用的马尔代夫的地理信息  1.5MB, 是最小的文件. 
http://download.geofabrik.de/asia/maldives-latest.osm.pbf
更多的国家从 http://download.geofabrik.de/ 选择下载.

```bash
# 导入 pbf 地理信息
# 删除 pgsql 中的 nom 数据库, 不删除没法导入. 没做其他测试, 或许可以在不删除的情况下导入.
dropdb nominatim
# 下载全球的国家信息, 必须下载.
wget -O data/country_osm_grid.sql.gz http://lonvia.de/nominatim/country_grid.sql.gz
# 下载 国家的的地理数据库.
wget -O data/maldives-latest.osm.pbf http://download.geofabrik.de/asia/maldives-latest.osm.pbf
./build/utils/setup.php  --osm-file data/maldives-latest.osm.pbf --all

```

### 参考
[Installing nominatim](http://nominatim.org/release-docs/latest/appendix/Install-on-Centos-7/) -- http://nominatim.org/release-docs/latest/appendix/Install-on-Centos-7/
[Centos 7 environment variables for Postgres service](https://stackoverflow.com/questions/26848495) -- https://stackoverflow.com/questions/26848495/
[Archlinux PostgreSQL](https://wiki.archlinux.org/index.php/PostgreSQL) -- https://wiki.archlinux.org/index.php/PostgreSQL
[Nominatim Importing and Updating](http://nominatim.org/release-docs/latest/admin/Import-and-Update/) -- http://nominatim.org/release-docs/latest/admin/Import-and-Update/
[localhost/nominatim ERROR 403 Forbidden](https://github.com/openstreetmap/Nominatim/issues/591) -- https://github.com/openstreetmap/Nominatim/issues/591
[OpenStreetMap](https://wiki.openstreetmap.org/wiki/Beginners%27_guide) -- https://wiki.openstreetmap.org/wiki/Beginners%27_guide

