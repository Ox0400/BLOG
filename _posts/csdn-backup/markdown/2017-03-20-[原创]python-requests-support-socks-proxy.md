---
layout: post
title: "[原创]python-requests-support-socks-proxy"
date: 2017-03-20 14:49:11
image: '/assets/img/'
description: ""
tags:
    - 
categories:
    - python
---


### 让python requests 支持socks5代理 requests support socket proxy
#### requests[socks]

```bash
pip install —upgrade requests “requests[socks]”
```

##### usage

```python
import requests
requests.get("http://www.google.com", proxies={"http":"sock5://127.0.0.1:1080"})
```


#### requests-unixsocket

```bash
pip install requests-unixsocket
```

##### usage

```python
import requests_unixsocket as requests
requests.get("http://www.google.com", proxies={"http":"sock5://127.0.0.1:1080"})
```
