---
layout: post
title: "[原创]elasticsearch-一些整理总结"
date: 2018-07-09 16:46:21
image: '/assets/img/'
description: "16年公司检索系统是用的 solr, 但使用过程中发现太糟心, 十分难用- - 17年初换到 es. 把当时整理的知识点记录一下.  机器配置:   1台 centos, 2台 ubuntu.   内存: 64G, CPU: 8核 硬盘: 8TB(SAS, es 数据), 250GB(SSD, 系统)  es 版本: 5.4.0  数据量: 目前为止一共40亿数据  内存: jvm 分配31G, ..."
tags:
    - elasticsearch
categories:
    - 大数据
    - elasticsearch
---



16年公司检索系统是用的 solr, 但使用过程中发现太糟心, 十分难用- - 17年初换到 es. 把当时整理的知识点记录一下.
机器配置: 
1台 centos, 2台 ubuntu. 
内存: 64G, CPU: 8核 硬盘: 8TB(SAS, es 数据), 250GB(SSD, 系统)
es 版本: 5.4.0

数据量: 目前为止一共51亿数据,  2副本 102亿 (10209------)
内存: jvm 分配31G, 整机实际使用内存35G
硬盘: 三台分别使用2.5T, 一共使用 7.4G (8133790------)

## install elasticsearch

### configure es user (root)
```
# configure es user.
cd ~
u=es
p=ES_PASSWORD
g=sudo
path=/solr_mongo
mem_size=20
adduser $u --ingroup $g --disabled-password --gecos "" && echo "$u:$p" |chpasswd
```

### download  and install es (root)
```
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-5.4.0.tar.gz
tar zxvf elasticsearch-5.4.0.tar.gz -C /usr/local/
mv /usr/local/elasticsearch-5.4.0/ /usr/local/elasticsearch
chown -R $u /usr/local/elasticsearch
```

### configure system setting (root)
```
## configure limits and vm.map
echo "$u -  nofile  65536" >> /etc/security/limits.conf
echo "$u -  nproc  65536"   >> /etc/security/limits.conf
echo "$u - memlock unlimited" >> /etc/security/limits.conf
echo "es - memlock unlimited" >> /etc/security/limits.conf
echo "es - memlock unlimited" >> /etc/security/limits.conf
echo "vm.max_map_count=262144" >> /etc/sysctl.conf

# configure /etc/hosts
echo "192.168.3.101    es-001" >> /etc/hosts
echo "192.168.3.102    es-002" >> /etc/hosts
echo "192.168.3.103    es-003" >> /etc/hosts

## install java
sudo yum install -y java java-openjdk
```

### configure jvm memory for elasticsearch(root)
```
cat /usr/local/elasticsearch/config/jvm.options |sed "s/^-Xms2g/-Xms$mem_sizeg/" | sed "s/^-Xmx2g/-Xmx$mem_sizeg/" > .jvm.options
mv .jvm.options  /usr/local/elasticsearch/config/jvm.options
chown -R $u /usr/local/elasticsearch
```

### configure data/log path for es(root)
```
path=/data/es/
mkdir -p $path/$u/{data,logs}
chown -R $u $path/$u
```

### install analysis-ik
```
cd ~
wget https://github.com/medcl/elasticsearch-analysis-ik/releases/download/v5.4.0/elasticsearch-analysis-ik-5.4.0.zip
unzip elasticsearch-analysis-ik-5.4.0.zip -d /usr/local/elasticsearch/plugins/ik

mv /usr/local/elasticsearch/plugins/ik/config/ /usr/local/elasticsearch/config/analysis-ik
chown -R $u /usr/local/elasticsearch
```


### elasticsearch.yml demo
```bash
# ======================== Elasticsearch Configuration =========================

# https://www.elastic.co/guide/en/elasticsearch/reference/index.html

# ---------------------------------- Cluster -----------------------------------
# Use a descriptive name for your cluster:
cluster.name: es_weibo

# ------------------------------------ Node ------------------------------------
# Use a descriptive name for the node:
node.name: es-001 
node.master: true
node.data: true

# Add custom attributes to the node:
node.attr.rack: r1

# ----------------------------------- Paths ------------------------------------
# Path to directory where to store the data (separate multiple locations by comma):
path.data: /data/es/data
#path.data: /tmp/es0/data,/tmp/es1/data

# Path to log files:
path.logs: /data/es/logs

#path.plugins: /tmp/es/plugins

# ----------------------------------- Memory -----------------------------------
# Lock the memory on startup:
## 锁定内存, 不使用交换区
bootstrap.memory_lock: true

# ---------------------------------- Network -----------------------------------
# Set the bind address to a specific IP (IPv4 or IPv6):
network.host: 10.30.57.230

http.port: 9200
transport.tcp.port: 9300

# --------------------------------- Discovery ----------------------------------
# Pass an initial list of hosts to perform discovery when new node is started:
# The default list of hosts is ["127.0.0.1", "[::1]"]

discovery.zen.ping.unicast.hosts: ["es-001","es-002","es-003"]
#
# Prevent the "split brain" by configuring the majority of nodes (total number of master-eligible nodes / 2 + 1):
#
## 解决数据一致性, 1 无法确保数据正确
discovery.zen.minimum_master_nodes: 2
## 没有主节点时, 锁定哪些功能. all/write
discovery.zen.no_master_block: write
#
# For more information, consult the zen discovery module documentation.
#
# ---------------------------------- Gateway -----------------------------------
#
# Block initial recovery after a full cluster restart until N nodes are started:
#
## 最少多少个节点在线 集群可用
gateway.recover_after_nodes: 1
## 集群节点总数 执行数据恢复
gateway.expected_nodes: 2
## 等待多长时间 执行数据恢复
gateway.recover_after_time: 5m
#
# For more information, consult the gateway module documentation.
#
# ---------------------------------- Various -----------------------------------
#
# Require explicit names when deleting indices:
#
action.destructive_requires_name: true

processors: 8


http.cors.enabled: true
http.cors.allow-origin: "*"
http.max_content_length: 200mb
-------------------------------------------------------------------------------------

```

### start es (es)
```
# start es
cd /usr/local/elasticsearch
screen -dm es
screen -ls
screen -S es -X stuff './bin/elasticsearch\n'

```
> 启动 es 之前, 最好重启一下系统`sudo reboot`


## 一些问题
```bash
# Q
"type": "cluster_block_exception",
"reason": "blocked by: [SERVICE_UNAVAILABLE/1/state not recovered / initialized];"
# A
gateway.expected_nodes: 1
gateway.recover_after_nodes: 1
```

```bash
# Q
413 Request Entity Too Large
# A
http.max_content_length: 500mb

https://github.com/elastic/elasticsearch/issues/2902
https://github.com/elastic/elasticsearch/blob/5.4/docs/reference/modules/http.asciidoc
https://github.com/elastic/elasticsearch/blob/5.4/core/src/main/java/org/elasticsearch/http/HttpTransportSettings.java
es 默认100MB
```

```bash
# 实现SQL: select books.* from books where books.id in (select users.books_id from user where users.id=1);

curl es:9200/books/_search -d
{
    "query": {
        "filtered": {
            "query" : {
                "match_all" :{}
            }
        }
        "filter":{
            "terms" : {
                "id" : {
                    "index" : "users",
                    "index" : "user",
                    "id" : 1,
                    "path" : "books_id"
                },
                "_cache_key" : "terms_lookup_user_1_books"
            }
        }
    }
}

```

```bash
# Q 
查询某个字段不为空的数据
# A
{
  "query": {
    "bool": {
      "must": [
        {
          "exists": {
            "field": "email"
          }
        }
      ],
      "must_not": {
        "term": {
          "email": ""
        }
      }
    }
  },
  "from": 0,
  "size": 10
}

```

> `__all` -- 6.0.0 会弃用.  可以用来做全局索引, 类似搜索引擎

```
status -- text

{
"index": "not_analyzed",  # 不作分析, 不会解析日期
"type":"date"
}

"ignore_above" : 20, ## 超过20个字符的那个字段 不作索引/存储
"settings": {
    "mapping.single_type": false  # 允许添加新字段
}

"_cache_key": 对查询结果做缓存, 可以用30分钟做一个 key
注意: 没看到怎么清理历史 "_cache_key"
需要存储: "_source"  -- mapping {"test_filed": {"_source": true}}
应该是指 store

"ignore_malformed" 忽略异常, 该字段不加入索引
"coerce"  强制转换类型, 例如把 "1" 转换为 1, 默认为 true, 如果为 false, 会被拒绝写入

"null_value" 不会更改原数据,返回值还是 null, 只可以在查询的时候使用 null_value 查询.
时间 null_value 可以设置为 "", 可以使用 
"must_not":[{"exists":{"field":"date"}}] 
查出 时间为空的, 没设置时间的, 时间为 null 的

"enabled": false 只存储 不索引
"index": false 不索引 不可查询
"store": false

{"index":{"_index":"weibo", "_type":"test"}}
{"name":"111", "date":"2017-01-01"}
{"index":{"_index":"weibo", "_type":"test"}}
{"name":"222", "date":"149664828100"}
{"index":{"_index":"weibo", "_type":"test"}}
{"name":"333", "date":""}
{"index":{"_index":"weibo", "_type":"test"}}
{"name":"444"}
{"index":{"_index":"weibo", "_type":"test"}}
{"name":"555", "date":null}

https://stackoverflow.com/questions/22796103/null-value-mapping-in-elasticsearch

```

```
es 默认 mapping 为:

{
    "email": {
        "type": "text",
        "fields": {
            "keyword": {
                "type": "keyword",
            }
        }
    }
}

注: 这里的 keyword 可以替换为任何名称, 可以认为是别名

查询语句需要调整为: 
{
  "query": {
    "bool": {
      "must": [
        {
          "exists": {
            "field": "email"
          }
        }
      ],
      "must_not": {
        "term": {
          "email.keyword": ""
        }
      }
    }
  },
  "from": 0,
  "size": 10
}
```

```bash
中文分词查询
prefix 是分词结果的开始
term 是分词结果 模糊查询
prefix = like WORD%
term  = like %WORD%

查询多个词组
{
  "query": {
    "terms": {
      "content": [
        "洪水",
        "你好"
      ]
    }
  }
}

Error:
curl -XPOST http://127.0.0.1:9200/testindex/fulltext/1 -H 'Content-Type:application/json' -d'{"content":"美国留给伊拉克的是个烂摊子吗"}'
 index_closed_exception, status:403

fixed:
curl -i -XPOST 'http://localhost:9200/testindex/_open/?pretty'


```