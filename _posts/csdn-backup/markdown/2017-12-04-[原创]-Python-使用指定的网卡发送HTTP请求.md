---
layout: post
title: "[原创]-Python-使用指定的网卡发送HTTP请求"
date: 2017-12-04 17:07:06
image: '/assets/img/'
description: "多个网卡的情况, 如何使用指定的网卡发送数据?$  curl --interface eth0 www.baidu.com # curl interface 可以指定网卡. 阅读 urllib.py 的源码, 追述到 open_http –> httplib.HTTP –> httplib.HTTP._connection_class = HTTPConnection"
tags:
    - python
    - 网卡
    - interface
    - requests
    - socket
categories:
    - linux
    - python
---



需求: 一台机器上有多个网卡, 如何访问指定的 URL 时使用指定的网卡发送数据呢?

```bash
$ curl --interface eth0 www.baidu.com # curl interface 可以指定网卡
```

阅读 urllib.py 的源码, 追述到 open_http --> httplib.HTTP --> httplib.HTTP._connection_class = HTTPConnection
HTTPConnection 在创建的时候会指定一个 source_address. 
HTTPConnection.connect 时调用 HTTPConnection._create_connection = socket.create_connection

```bash
# 先看一下本地网卡信息
$ ifconfig
lo0: flags=8049<UP,LOOPBACK,RUNNING,MULTICAST> mtu 16384
	options=3<RXCSUM,TXCSUM>
	inet6 ::1 prefixlen 128 
	inet 127.0.0.1 netmask 0xff000000 
	inet6 fe80::1%lo0 prefixlen 64 scopeid 0x1 
	nd6 options=1<PERFORMNUD>
en0: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
	ether c8:e0:eb:17:3a:73 
	inet6 fe80::cae0:ebff:fe17:3a73%en0 prefixlen 64 scopeid 0x4 
	inet 192.168.20.2 netmask 0xffffff00 broadcast 192.168.20.255
	nd6 options=1<PERFORMNUD>
	media: autoselect
	status: active
en1: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
	options=4<VLAN_MTU>
	ether 0c:5b:8f:27:9a:64 
	inet6 fe80::e5b:8fff:fe27:9a64%en8 prefixlen 64 scopeid 0xa 
	inet 192.168.8.100 netmask 0xffffff00 broadcast 192.168.8.255
	nd6 options=1<PERFORMNUD>
	media: autoselect (100baseTX <full-duplex>)
	status: active
```

可以看到en0和en1, 这两块网卡都可以访问公网. lo0是本地回环.
直接修改 socket.py 做测试.
```python
def create_connection(address, timeout=_GLOBAL_DEFAULT_TIMEOUT,
                      source_address=None):
    """If *source_address* is set it must be a tuple of (host, port)
    for the socket to bind as a source address before making the connection.
    An host of '' or port 0 tells the OS to use the default.
    source_address 如果设置, 必须是传递元组 (host, port), 默认是 ("", 0) 
    """

    host, port = address
    err = None
    for res in getaddrinfo(host, port, 0, SOCK_STREAM):
        af, socktype, proto, canonname, sa = res
        sock = None
        try:
            sock = socket(af, socktype, proto)
            # sock.bind(("192.168.20.2", 0)) # en0
            # sock.bind(("192.168.8.100", 0)) # en1
            # sock.bind(("127.0.0.1", 0)) # lo0
            if timeout is not _GLOBAL_DEFAULT_TIMEOUT:
                sock.settimeout(timeout)
            if source_address:
                print "socket bind source_address: %s" % source_address
                sock.bind(source_address)
            sock.connect(sa)
            return sock

        except error as _:
            err = _
            if sock is not None:
                sock.close()
    if err is not None:
        raise err
    else:
        raise error("getaddrinfo returns an empty list")
```

参考说明文档, 直接分三次绑定不通网卡的 IP 地址, 端口设置为0.
```bash
# 测试 en0
$ python -c 'import urllib as u;print u.urlopen("http://ip.haschek.at").read()'
61.148.245.16

# 测试 en1
$ python -c 'import urllib as u;print u.urlopen("http://ip.haschek.at").read()'
211.94.115.227

# 测试 lo0
$ python -c 'import urllib as u;print u.urlopen("http://ip.haschek.at").read()'
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
  File "/System/Library/Frameworks/Python.framework/Versions/2.7/lib/python2.7/urllib.py", line 87, in urlopen
    return opener.open(url)
  File "/System/Library/Frameworks/Python.framework/Versions/2.7/lib/python2.7/urllib.py", line 213, in open
    return getattr(self, name)(url)
  File "/System/Library/Frameworks/Python.framework/Versions/2.7/lib/python2.7/urllib.py", line 350, in open_http
    h.endheaders(data)
  File "/System/Library/Frameworks/Python.framework/Versions/2.7/lib/python2.7/httplib.py", line 1049, in endheaders
    self._send_output(message_body)
  File "/System/Library/Frameworks/Python.framework/Versions/2.7/lib/python2.7/httplib.py", line 893, in _send_output
    self.send(msg)
  File "/System/Library/Frameworks/Python.framework/Versions/2.7/lib/python2.7/httplib.py", line 855, in send
    self.connect()
  File "/System/Library/Frameworks/Python.framework/Versions/2.7/lib/python2.7/httplib.py", line 832, in connect
    self.timeout, self.source_address)
  File "/System/Library/Frameworks/Python.framework/Versions/2.7/lib/python2.7/socket.py", line 578, in create_connection
    raise err
IOError: [Errno socket error] [Errno 49] Can't assign requested address
```
<br><br>
测试通过, 说明在多网卡情况下, 创建 socket 时绑定某块网卡的 IP 就可以, 端口需要设置为0. 如果端口不设置为0, 第二次请求时, 可以看到抛异常, 端口被占用.
```python
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
  File "/System/Library/Frameworks/Python.framework/Versions/2.7/lib/python2.7/urllib.py", line 87, in urlopen
    return opener.open(url)
  File "/System/Library/Frameworks/Python.framework/Versions/2.7/lib/python2.7/urllib.py", line 213, in open
    return getattr(self, name)(url)
  File "/System/Library/Frameworks/Python.framework/Versions/2.7/lib/python2.7/urllib.py", line 350, in open_http
    h.endheaders(data)
  File "/System/Library/Frameworks/Python.framework/Versions/2.7/lib/python2.7/httplib.py", line 1049, in endheaders
    self._send_output(message_body)
  File "/System/Library/Frameworks/Python.framework/Versions/2.7/lib/python2.7/httplib.py", line 893, in _send_output
    self.send(msg)
  File "/System/Library/Frameworks/Python.framework/Versions/2.7/lib/python2.7/httplib.py", line 855, in send
    self.connect()
  File "/System/Library/Frameworks/Python.framework/Versions/2.7/lib/python2.7/httplib.py", line 832, in connect
    self.timeout, self.source_address)
  File "/System/Library/Frameworks/Python.framework/Versions/2.7/lib/python2.7/socket.py", line 577, in create_connection
    raise err
IOError: [Errno socket error] [Errno 48] Address already in use
```

<br><br>
如果是在项目中, 只需要把 `socket.create_connection` 这个函数的形参 `source_address` 设置为对应网卡的 (IP, 0) 就可以.

```python
# test-interface_urllib.py
import socket
import urllib, urllib2

_create_socket = socket.create_connection

SOURCE_ADDRESS = ("127.0.0.1", 0)
#SOURCE_ADDRESS = ("172.28.153.121", 0)
#SOURCE_ADDRESS = ("172.16.30.41", 0)

def create_connection(*args, **kwargs):
    in_args = False
    if len(args) >=3:
        args = list(args)
        args[2] = SOURCE_ADDRESS
        args = tuple(args)
        in_args = True
    if not in_args:
        kwargs["source_address"] = SOURCE_ADDRESS
    print "args", args
    print "kwargs", str(kwargs)
    return _create_socket(*args, **kwargs)
    
socket.create_connection = create_connection

print urllib.urlopen("http://ip.haschek.at").read()

```
> 通过测试, 可以发现已经可以通过制定的网卡发送数据, 并且 IP 地址对应网卡分配的 IP.

问题, 爬虫经常使用 requests, requests 是否支持呢. 通过测试, 可以发现, requests 并没有使用 python 内置的 socket 模块.

看源码, requests 是如果创建的 socket 连接呢. 方法和查看 urllib 创建socket 的方式一样. 具体就不写了.
因为我用的是 python 2.7, 所以可以定位到 requests 使用的 socket 模块是 urllib3.utils.connection 的.
修改方法和 urllib 相差不大.

```python
import urllib3.connection
_create_socket = urllib3.connection.connection.create_connection
# pass

urllib3.connection.connection.create_connection = create_connection
# pass

```
运行后, 可能会抛出异常.  ` requests.exceptions.ConnectionError: Max retries exceeded with .. Invalid argument` 
> 这个异常不是每次出现, 跟 IP 段有关系, 跳转递归层数太多导致, 只需要将 kwargs 中的 socket_options去掉即可.  127.0.0.1肯定会出异常. 

```python
import socket
import urllib
import urllib2
import urllib3.connection

import requests as req

_default_create_socket = socket.create_connection
_urllib3_create_socket = urllib3.connection.connection.create_connection


SOURCE_ADDRESS = ("127.0.0.1", 0)
#SOURCE_ADDRESS = ("172.28.153.121", 0)
#SOURCE_ADDRESS = ("172.16.30.41", 0)

def default_create_connection(*args, **kwargs):
    try:
        del kwargs["socket_options"]
    except:
        pass
    in_args = False
    if len(args) >=3:
        args = list(args)
        args[2] = SOURCE_ADDRESS
        args = tuple(args)
        in_args = True
    if not in_args:
        kwargs["source_address"] = SOURCE_ADDRESS
    print "args", args
    print "kwargs", str(kwargs)
    return _default_create_socket(*args, **kwargs)

def urllib3_create_connection(*args, **kwargs):
    in_args = False
    if len(args) >=3:
        args = list(args)
        args[2] = SOURCE_ADDRESS
        in_args = True
        args = tuple(args)
    if not in_args:
        kwargs["source_address"] = SOURCE_ADDRESS
    print "args", args
    print "kwargs", str(kwargs)
    return _urllib3_create_socket(*args, **kwargs)

socket.create_connection = default_create_connection
# 因为偶尔会出问题, 所以使用默认的 socket.create_connection
# urllib3.connection.connection.create_connection = urllib3_create_connection
urllib3.connection.connection.create_connection = default_create_connection

print " *** test requests: " + req.get("http://ip.haschek.at").content
print " *** test urllib: " + urllib.urlopen("http://ip.haschek.at").read()
print " *** test urllib2: " + urllib2.urlopen("http://ip.haschek.at").read()

```

> 注意: 使用 urllib3.utils.connection 好像不起作用
> 稍微再完善一下, 就是把根据网卡名自动获取 IP.

```python
import subprocess

def get_all_net_devices():
	sub = subprocess.Popen("ls /sys/class/net", shell=True, stdout=subprocess.PIPE)
	sub.wait()
	net_devices = sub.stdout.read().strip().splitlines()
	# ['eth0', 'eth1', 'lo']
	# 这里简单过滤一下网卡名字, 根据需求改动
	net_devices = [i for i in net_devices if "ppp" in i]
	return net_devices
ALL_DEVICES = get_all_net_devices()

def get_local_ip(device_name):
	sub = subprocess.Popen("/sbin/ifconfig en0 | grep '%s ' | awk '{print $2}'" % device_name, shell=True, stdout=subprocess.PIPE)
	sub.wait()
	ip = sub.stdout.read().strip()
	return ip

def random_local_ip():
    return get_local_ip(random.choice(ALL_DEVICES))

# code ...

```

> 只需要把 `args[2] = SOURCE_ADDRESS` 和 `kwargs["source_address"] = SOURCE_ADDRESS`改成 `random_local_ip() ` 或者 `get_local_ip("eth0")` 

至于有什么用途, 就全凭想象了.

参考: 
[How to send HTTP request using virtual IP address in Linux?](https://stackoverflow.com/questions/26903520/how-to-send-http-request-using-virtual-ip-address-in-linux) - https://stackoverflow.com/questions/26903520/how-to-send-http-request-using-virtual-ip-address-in-linux

[Source interface with Python and urllib2](https://stackoverflow.com/questions/1150332/source-interface-with-python-and-urllib2) - https://stackoverflow.com/questions/1150332/source-interface-with-python-and-urllib2

[proc与awk实时网卡流量监控](http://www.361way.com/proc-awk-network/4971.html) - http://www.361way.com/proc-awk-network/4971.html

