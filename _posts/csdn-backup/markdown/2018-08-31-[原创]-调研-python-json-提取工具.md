---
layout: post
title: "[原创]-调研-python-json-提取工具"
date: 2018-08-31 18:23:05
image: '/assets/img/'
description: "为便捷配置信息提取规则, 调研 json 格式的数据提取方案.  jsonselect     css selector 实现   $ pip install jsonselect  &amp;gt;&amp;gt;&amp;gt; import jsonselect as j &amp;gt;&amp;gt;&amp;gt;  &amp;gt;&amp;gt;&amp;gt; data = {'name':'zz', 'books':[{'name':'x','pr..."
tags:
    - 
categories:
    - python
---



为便捷配置信息提取规则, 调研 json 格式的数据提取方案.

### jsonselect
>   css selector 实现

```python
$ pip install jsonselect 
>>> import jsonselect as j
>>> 
>>> data = {'name':'zz', 'books':[{'name':'x','price':1}, {'name':'y', 'price':2,'tag':'t'}]}

# 默认情况下和 css selector 一样, 根据标签进行递归的, 不区分是不是根节点的子节点
>>> j.select('.name', data)
['x', 'y', 'zz']
>>> j.select(':root>.name', data)
zz
>>> j.select('.books .tag', data)
't'
# 官方提供的示例 `[{}, {}]` 可以根据 value 过滤, 但没有实现从 `{key: [{}, {}]}` 结构中过滤成功(外层再加上:has 之后就没有数据了)
>>> j.select('.books .tag:val("t")', data)
't'
>>> j.select('object:last-child', data)
{'price': 2, 'tag': 't', 'name': 'y'}
# 虽然不能根据 value 进行过滤, 但是可以根据 key 是否存在进行过滤
>>> j.select(''.books>object:has(string.tag)', data)
{'price': 2, 'tag': 't', 'name': 'y'}
>>> j.select('.books object:has(.tag)', data)
{'price': 2, 'tag': 't', 'name': 'y'}
```
> 特别注意, 选择器 key 是 css 中的 class, 数据类型是 css 中的 tag.
> {} -> object, [] -> array.  {name: xyz}, -> .name || object
>
> 缺点: 不能根据 value 过滤. 实现[key=value]就基本完美.

### jmespath
> xpath 实现, 功能十分强大

```python
$ pip install jmespath

>>> jmespath.search('name', data)
'zz'
>>> jmespath.search('books[].tag', data)
['t']
# 根据 value 过滤, 但 value 需要加 ``
>>> jmespath.search('books[?tag==`t`]', data)
[{'price': 2, 'tag': 't', 'name': 'y'}]
# ``中不区分类型
>>> jmespath.search('books[?price==`1`]', data)
[{'price': 1, 'name': 'x'}]
>>> jmespath.search('books[?price==`2`]', data)
[{'price': 2, 'tag': 't', 'name': 'y'}]
# 根据 key 是否存在进行过滤, 十分方便
>>> jmespath.search('books[?tag]', data)
[{'price': 2, 'tag': 't', 'name': 'y'}]
>>> jmespath.search('books[?name]', data)
[{'price': 1, 'name': 'x'}, {'price': 2, 'tag': 't', 'name': 'y'}]
# 管道操作, 对结果再进行一次匹配
# @匹配到的值. 可以不填. 如果填可以用函数括起来. 比如 sort(@)
>>> jmespath.search('books[?name] | (@)[?tag]', data)
>>> jmespath.search(''books[?name] | [?tag]', data) 
[{'price': 2, 'tag': 't', 'name': 'y'}]
# 使用 or 匹配
>>> jmespath.search('books[?no] || books[?tag]', data)
[{'price': 2, 'tag': 't', 'name': 'y'}]
>>> jmespath.search('books[?no] || books[?name]', data)
[{'price': 1, 'name': 'x'}, {'price': 2, 'tag': 't', 'name': 'y'}]
# 使用 and 匹配
>>> jmespath.search('books[?name] && books[?tag]', data)
[{'price': 2, 'tag': 't', 'name': 'y'}]
# 默认匹配到结果不区分字段, 也可以将匹配到的结果按字段区分. 可以直接存数据库.
>>> jmespath.search('{uname:name, like_books:books[?name] && books[?tag]}', data)
{'like_books': [{'price': 2, 'tag': 't', 'name': 'y'}], 'uname': 'zz'}
>>> jmespath.search('books[?tag].name', data)
['y']
>>> jmespath.search('{book_names:books[?tag].name}', data)
{'book_names': ['y']}
```

> 缺点: []匹配规则需要加?, value 需要加``

###jsonpath
> 基于 xpath

```python
pip install jsonpath
>>> import jsonpath as j
>>> 
>>> j.jsonpath(data, '$.books')
[[{'price': 1, 'name': 'x'}, {'price': 2, 'tag': 't', 'name': 'y'}]]
>>> j.jsonpath(data, '$.books[*]')
[{'price': 1, 'name': 'x'}, {'price': 2, 'tag': 't', 'name': 'y'}]
>>> j.jsonpath(d, '$.books[*].tag')
['t']
>>> j.jsonpath(data, '$.books[0]')
[{'price': 1, 'name': 'x'}]
>>> j.jsonpath(data, '$.books[1]')
[{'price': 2, 'tag': 't', 'name': 'y'}]
>>> j.jsonpath(data, '$.books.1')
[{'price': 2, 'tag': 't', 'name': 'y'}]
>>> j.jsonpath(data, '$.books.0')
[{'price': 1, 'name': 'x'}]
# 根据 key 进行过滤
>>> j.jsonpath(data, '$.books[?(@.tag)]')
[{'price': 2, 'tag': 't', 'name': 'y'}]
# 根据 value 进行过滤
>>> j.jsonpath(data, '$.books[?(@.tag=="t")]')
[{'price': 2, 'tag': 't', 'name': 'y'}]
>>> 
```
> 可以直接 `.索引下标` 取值, 用处不算太大
> 
> 缺点: 过于啰嗦
> 优点: 用户群体多, 语法比较标准

### objectpath

> 结合 xpath, python

``` python
$ pip install objectpath
>>> from objectpath import Tree
>>> 
>>> for i in Tree(data).execute('$.books[@.tag is "t"]'):print i
{'price': 2, 'tag': 't', 'name': 'y'}
>>> Tree(data).execute('$.books[-1]]')
{'price': 2, 'tag': 't', 'name': 'y'}
>>> Tree(data).execute('$.books[0]]')
{'price': 1, 'name': 'x'}
```
> 缺点: 语法相比 jsonpath 有些简化, 但仍有些啰嗦.
> 匹配 value 用 `is`, 而且必须从根节点`$`开始.
> 匹配 key 必须用@指定当前结果(子项)

### jsonpath-ng
> 集成 jsonpath-rw jsonpath-rw-ext
> xpath 语法

```python
$ pip install --upgrade jsonpath-ng
>>> from jsonpath_ng import jsonpath, parse
>>> 
>>> [i.value for i in parse('$.books[?(tag="t")]').find(data)]
#!!! ERROR  !!!, 不支持 value 过滤
# 对 value 过滤
>>> from jsonpath_ng.ext import parse
[i.value for i in parse('$.books[?(tag="t")]').find(data)]
[{'price': 2, 'tag': 't', 'name': 'y'}]
```
> 缺点: 开始我以为是将jsonpath-rw jsonpath-rw-ext结合到一起, 没想到只是打成一个包而已.


### jsonpath-rw-ext

> jsonpath-rw 的补充版本
> xpath 语法

```python
$ pip install jsonpath-rw-ext --user
>>> import jsonpath_rw_ext
>>> 
# 根据 value 过滤
>>> [i.value for i in jsonpath_rw_ext.parse('$.books[?(tag="t")]').find(data)]
[{'price': 2, 'tag': 't', 'name': 'y'}]
>>> jsonpath_rw_ext.match('$.books[?(tag="t")]', data)
[{'price': 2, 'tag': 't', 'name': 'y'}]
>>> jsonpath_rw_ext.match('$.books[?(tag=t)]', data)
[{'price': 2, 'tag': 't', 'name': 'y'}]
# 根据 key 过滤
>>> jsonpath_rw_ext.match('books[?(tag)]', data)
[{'price': 2, 'tag': 't', 'name': 'y'}]
>>> jsonpath_rw_ext.match('name', data)
['zz']
>>> jsonpath_rw_ext.match('books', data)
[[{'price': 1, 'name': 'x'}, {'price': 2, 'tag': 't', 'name': 'y'}]]
>>> 
```
> 优点: 对 jsonpath 语法做了一些简化, 比如不需要`$`指定根节点
> 缺点: 根据 value 过滤, 还是有些啰嗦

### ujsonpath
> xpath 语法
> 不支持属性判断 !!!

```
pip install ujsonpath
from ujsonpath import parse
>>> [i.value for i in parse('name').find({'name':'zz', 'books':[{'name':'x','price':1}, {'name':'y', 'price':2,'tag':'t'}]})]
['zz']

>>> [i.value for i in parse('books[*].name').find({'name':'zz', 'books':[{'name':'x','price':1}, {'name':'y', 'price':2,'tag':'t'}]})]
['x', 'y']
>>> [i.value for i in parse('books.1').find({'name':'zz', 'books':[{'name':'x','price':1}, {'name':'y', 'price':2,'tag':'t'}]})]
[{'price': 2, 'tag': 't', 'name': 'y'}]
>>> [i.value for i in parse('books[*][name|tag]').find({'name':'zz', 'books':[{'name':'x','price':1}, {'name':'y', 'price':2,'tag':'t'}]})]
['x', 'y']
>>> [i.value for i in parse('books[*][tag|name]').find({'name':'zz', 'books':[{'name':'x','price':1}, {'name':'y', 'price':2,'tag':'t'}]})]
['x', 't']
>>> [i.value for i in parse('$store.book[?(@.price==2)]').find({'name':'zz', 'books':[{'name':'x','price':1}, {'name':'y', 'price':2,'tag':'t'}]})]
!!! NotImplementedError !!!
```
> 缺点: 不支持属性判断, 示例代码中定义 NotImplementedError.

### jsonxs

```
pip install jsonxs
>>> import jsonxs as j
>>> j.jsonxs( data, 'name')
'zz'
>>> j.jsonxs(data, 'books[1].name')
'y'
>>> j.jsonxs(data, 'books[0]')
{'price': 1, 'name': 'x'}
>>> j.jsonxs(data, 'books[1]')
{'price': 2, 'tag': 't', 'name': 'y'}
```
> 优点: 代码实现非常简单.
> 缺点: 功能单一, 只能取 key, 取索引. 不支持过滤

---
综上, 只有` jsonpath`, `jmespath`, `jsonpath-rw-ext` 这三个是方便用户使用的.
`jsonpath` 用户群体大, 语法最啰嗦
`jsonpath-rw-ext` 语法有过简化, 但依旧啰嗦
`jmespath` 过滤语法标新立异, 功能强大. 支持组合查询, 非常容易.
