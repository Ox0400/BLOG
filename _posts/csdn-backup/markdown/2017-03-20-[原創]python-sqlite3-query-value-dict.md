---
layout: post
title: "[原創]python sqlite3 select 輸出字典 dict"
date: 2017-03-20 14:47:16
image: '/assets/img/'
description: ""
tags:
    - 
categories:
    - python
    - sqlite
    - DictCursor
---


sqlite3默認查詢到的結果是list[tuple(value, value...)], 沒有發現類似 Mysqldb `DictCursor`

```text
1.13.4. Row Objects
class sqlite3.Row
A Row instance serves as a highly optimized row_factory for Connection objects. It tries to mimic a tuple in most of its features.

It supports mapping access by column name and index, iteration, representation, equality testing and len().

If two Row objects have exactly the same columns and their members are equal, they compare equal.

Changed in version 2.6: Added iteration and equality (hashability).

keys()
This method returns a list of column names. Immediately after a query, it is the first member of each tuple in Cursor.description.

New in version 2.6.

Let’s assume we initialize a table as in the example given above:

conn = sqlite3.connect(":memory:") 
c = conn.cursor() 
c.execute('''create table stocks (date text, trans text, symbol text, qty real, price real)''') 
c.execute("""insert into stocks values ('2006-01-05','BUY','RHAT',100,35.14)""") 
conn.commit() c.close()
```


其实用自定义的一个Row类就可以实现, init第一个参数应当为Cursor类，这里写一个none就可以了。


```python
class UserEntity(dict):
    # todo: 需要跟数据库列完全对应 ..
    def __init__(self, none=None, name=None, id=None):
        super(TaskEntity, self).__init__(id=id, name=name)

    def get(self, k, d=None):
        return self.__getitem__(k, d)

    def __getitem__(self, item, default=None):
        value = super(TaskEntity, self).__getitem__(item)
        if value:
            return value[0]
        else:
            return default

    @property
    def id(self):
        return self.get("id")

    @id.setter
    def id(self, id):
        self["id"] = id
```


test

```python
>>> from User_entity import UserEntity as user
>>> import sqlite3 as sql
>>> conn = sql.connect("my.db")
>>> conn.row_factory = user
>>> cur = conn.cursor()
>>> ex = cur.execute("select * from users")
>>> rows = ex.fetchall()
>>> rows
[{'name': (u'zhang',), 'id': None,'age': None}]
>>> print rows[0].name
zhang
>>> print rows[0]["name"]
zhang
```
