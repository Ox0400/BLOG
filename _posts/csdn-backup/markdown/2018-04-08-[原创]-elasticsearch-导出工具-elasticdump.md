---
layout: post
title: "[原创]-elasticsearch-导出工具-elasticdump"
date: 2018-04-08 18:46:37
image: '/assets/img/'
description: "// 日志记录 2017-11  项目是 node 写的, 依赖 nodejs, https://www.npmjs.com/package/elasticdump  GitHub 地址: https://github.com/taskrabbit/elasticsearch-dump备份文件elasticdump --type=data --input=\"http://localhost:9200"
tags:
    - elasticsearch
    - 备份
    - backup
categories:
    - elasticsearch
---




// 日志记录 2017-11
项目是 node 写的, 依赖 nodejs, https://www.npmjs.com/package/elasticdump
GitHub 地址: https://github.com/taskrabbit/elasticsearch-dump

#### 备份文件
```bash
elasticdump --type=data --input="http://localhost:9200/MyIndex" --output=myIndex.json --limit 1000 --sourceOnly --ignore-errors
elasticdump --type=data --input="http://localhost:9200/MyIndex/MyType" --output=myIndexMyType.json --limit 1000 --sourceOnly --ignore-errors
```

> `--sourceOnly` 只导出原数据, 忽略 _index,_type 等等信息, 默认为`{"_index":"","_type":"","_id":"", "_source":{SOURCE}}`
> `input=/index/type` 支持 es 版本1.2.0及以上

输出结果大概是这样的
```text
Fri, 17 Nov 2017 09:05:24 GMT | got 1000 objects from source elasticsearch (offset: 11035000)
Fri, 17 Nov 2017 09:05:24 GMT | sent 1000 objects to destination file, wrote 1000
Fri, 17 Nov 2017 09:05:24 GMT | got 8 objects from source elasticsearch (offset: 11036000)
Fri, 17 Nov 2017 09:05:24 GMT | sent 8 objects to destination file, wrote 8
Fri, 17 Nov 2017 09:05:24 GMT | got 0 objects from source elasticsearch (offset: 11036008)
Fri, 17 Nov 2017 09:05:24 GMT | Total Writes: 11036008
Fri, 17 Nov 2017 09:05:24 GMT | dump complete
```

#### 备份到另外一个线上数据库
```bash
# 备份 mapping
elasticdump --input="http://localhost:9200/MyIndex" --output="http://localhost:9200/MyIndex" --type=mapping
# 备份数据
elasticdump --input="http://localhost:9200/MyIndex" --output="http://localhost:9200/MyIndex" --type=data
```
