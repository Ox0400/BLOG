---
layout: post
title: "fix pymongo ServerSelectionTimeoutError"
date: 2019-10-31 16:32:25
image: '/assets/img/'
description: Fix pymongo ServerSelectionTimeoutError
tags:
  - pymongo
  - mongodb
categories:
  - python
  - mongodb
---

#### fix: pymongo ServerSelectionTimeoutError

```
/usr/local/lib/python2.7/dist-packages/pymongo/topology.py:145: UserWarning: MongoClient opened before fork. Create MongoClient with connect=False, or create client after forking. See PyMongo's documentation for details: http://api.mongodb.org/python/current/faq.html#pymongo-fork-safe>
  "MongoClient opened before fork. Create MongoClient "
  File "/usr/local/lib/python2.7/dist-packages/pymongo/collection.py", line 1102, in find_one
    for result in cursor.limit(-1):
  ...
  File "/usr/local/lib/python2.7/dist-packages/pymongo/topology.py", line 189, in select_servers
    self._error_message(selector))
ServerSelectionTimeoutError: No servers found yet

```

a: force set connect=False. some time not working, also raise error.
> https://stackoverflow.com/questions/31030307/why-is-pymongo-3-giving-serverselectiontimeouterror

b: change `serverselectiontimeoutms` same as `serverSelectionTimeoutMS`, `SERVER_SELECTION_TIMEOUT`. default is 30s.

```
import pymongo.common;
from pymongo import MongoClient;
print (pymongo.common.SERVER_SELECTION_TIMEOUT)

from pymongo.client_options import ClientOptions;
print (ClientOptions('', '', 'app', {}).server_selection_timeout)
print (MongoClient().server_selection_timeout)
```

usage:
```
## set global
import pymongo.common;
pymongo.common.SERVER_SELECTION_TIMEOUT *=2

## set single connect
from pymongo import MongoClient
MongoClient(serverselectiontimeoutms=pymongo.common.SERVER_SELECTION_TIMEOUT * 1000 * 2 )
```
> Note: The timeoutms unit is ms, set value is 30000.

