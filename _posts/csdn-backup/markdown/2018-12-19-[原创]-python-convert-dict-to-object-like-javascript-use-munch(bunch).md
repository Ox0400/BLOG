---
layout: post
title: "[原创]-python-convert-dict-to-object-like-javascript-use-munch(bunch)"
date: 2018-12-19 18:21:10
image: '/assets/img/'
description: "python convert dict to object like javascript install pip install munch # (munch clone from bunch, but bunch has not update long time)  example from munch import munchify from munch import unmunchify ..."
tags:
    - python
    - object
    - javascript
    - bunch
    - munch
categories:
    - python
---




## python convert dict to object like javascript


### install

```bash
pip install munch
# (munch clone from bunch, bunch has not update long time)
```

### example
```python
from munch import munchify
from munch import unmunchify
## test list
>>> obj = munchify([{"name": "zhipeng", "age": 15}, {"name":"zz", "age":19}])
>>> obj
[Munch({'age': 15, 'name': 'zhipeng'}), Munch({'age': 19, 'name': 'zz'})]
>>> obj[0]
Munch({'age': 15, 'name': 'zhipeng'})
>>> obj[0].age
15
>>> unmunchify(obj)[0]
{'age': 15, 'name': 'zhipeng'}
>>> mm.toDict()
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
AttributeError: 'list' object has no attribute 'toDict'
>>> print mm.toJSON()
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
AttributeError: 'list' object has no attribute 'toJSON'
>>> print mm.toYAML()
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
AttributeError: 'list' object has no attribute 'toYAML'
# if source not is dict, can't use toDict,toJSON,toYAML.

## test dict
>>> obj = munchify({'list': [{"name": "zhipeng", "age": 15}, {"name":"zz", "age":19}]})
>>> obj.list[0]
Munch({'age': 15, 'name': 'zhipeng'})
>>> unmunchify(obj)
{'list': [{'age': 15, 'name': 'zhipeng'}, {'age': 19, 'name': 'zz'}]}
>>> mm.toDict()
{'list': [{'age': 15, 'name': 'zhipeng'}, {'age': 19, 'name': 'zz'}]}
>>> print obj.toJSON()
{"list": [{"age": 15, "name": "zhipeng"}, {"age": 19, "name": "zz"}]}
>>> print obj.toYAML()
list:
-   age: 15
    name: zhipeng
-   age: 19
    name: zz
```
### more
More info go to [Github](https://github.com/Infinidat/munch): https://github.com/Infinidat/munch
