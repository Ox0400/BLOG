---
layout: post
title: "[原创]-记一次-ElasticSearch-问题查找---数据同步非常慢"
date: 2018-08-02 17:16:53
image: '/assets/img/'
description: "开始是三个节点组成的集群, 后加了两台. 但是同步数据变的非常慢.   追查问题后发现是 ulimit 配置不当导致.    $ curl 192.168.3.48:9200/_nodes/stats/process?filter_path=**.max_file_descriptors {     &quot;nodes&quot;: {         &quot;bf79DOwKQ4GJxJcsIaFDqQ&quot;: {   ..."
tags:
    - 
categories:
    - 大数据
    - elasticsearch
---



开始是三个节点组成的集群, 后加了两台. 但是同步数据变的非常慢. 
追查问题后发现是 ulimit 配置不当导致.

```json
$ curl 192.168.3.48:9200/_nodes/stats/process?filter_path=**.max_file_descriptors
{
    "nodes": {
        "bf79DOwKQ4GJxJcsIaFDqQ": {
            "process": {
                "max_file_descriptors": 655360
            }
        },
        "OU7A1WPBSUuZ8QooWmkyRQ": {
            "process": {
                "max_file_descriptors": 655360
            }
        },
        "DrUpoM8TRoarg0XiGcMP_A": {
            "process": {
                "max_file_descriptors": 65536
            }
        },
        "KMVIqfNgSty0pdJhoHlZeg": {
            "process": {
                "max_file_descriptors": 655360
            }
        },
        "Wa8LvscDT5KjrhyNfTfwXQ": {
            "process": {
                "max_file_descriptors": 65536
            }
        }
    }
}
```
其中三台是655360, 两台新加的机器是65536.

修改 /etc/security/limits.conf  文件.
```bash
es - nproc 655360
es - nofile 655360
# es 是用户名
```
修改之后重启 es 服务, 再查看

```json
{
    "nodes": {
        "OU7A1WPBSUuZ8QooWmkyRQ": {
            "process": {
                "max_file_descriptors": 655360
            }
        },
        "KMVIqfNgSty0pdJhoHlZeg": {
            "process": {
                "max_file_descriptors": 655360
            }
        },
        "bf79DOwKQ4GJxJcsIaFDqQ": {
            "process": {
                "max_file_descriptors": 655360
            }
        },
        "DrUpoM8TRoarg0XiGcMP_A": {
            "process": {
                "max_file_descriptors": 655360
            }
        },
        "Wa8LvscDT5KjrhyNfTfwXQ": {
            "process": {
                "max_file_descriptors": 655360
            }
        }
    }
}
```
节点的文件最大句柄数已经一样.

ps aux|grep elastic;ps aux |grep elasticsearch|awk '{print "kill "$2}' | bash; ps aux|grep elastic

cd /usr/local/elasticsearch/ && ./bin/elasticsearch -d -s

