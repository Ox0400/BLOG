---
layout: post
title: "[原创]-Python-让-SimpleHTTPServer-支持DELETE,-并且支持并发下载"
date: 2018-06-06 17:24:58
image: '/assets/img/'
description: "将常有一些小需求搭建一个文件服务器下载数据, 大家一般都会用 python -m SimpleHTTPServer  但是这样有个问题,  这样是阻塞模式. 多个人下载文件时, 如果有一个人在下大文件, 后面的人就会一直等待响应.    # 查看 SimpleHTTPServer 源码 # lib/python2.7/SimpleHTTPServer.py  def test(HandlerCla..."
tags:
    - 
categories:
    - python
---



将常有一些小需求搭建一个文件服务器下载数据, 大家一般都会用 `python -m SimpleHTTPServer`
但是这样有个问题,  这样是阻塞模式. 多个人下载文件时, 如果有一个人在下大文件, 后面的人就会一直等待响应.
```python
# 查看 SimpleHTTPServer 源码
# lib/python2.7/SimpleHTTPServer.py 
def test(HandlerClass = SimpleHTTPRequestHandler,
         ServerClass = BaseHTTPServer.HTTPServer):
    BaseHTTPServer.test(HandlerClass, ServerClass)

ServerClass 用到的是 BaseHTTPServer.HTTPServer
```
```python
# 查看 BaseHTTPServer 源码
# lib/python2.7/BaseHTTPServer.py

class HTTPServer(SocketServer.TCPServer):
    allow_reuse_address = 1    # Seems to make sense in testing environment
    def server_bind(self):
        """Override server_bind to store the server name."""
        SocketServer.TCPServer.server_bind(self)
        host, port = self.socket.getsockname()[:2]
        self.server_name = socket.getfqdn(host)
        self.server_port = port
# HTTPServer 继承自 SocketServer.TCPServer
```
```python
# 查看 SocketServer.py 源码
# lib/python2.7/SocketServer.py

class TCPServer(BaseServer):
    # ...
    def server_bind(self):
        """Called by constructor to bind the socket.
        May be overridden.
        """
        if self.allow_reuse_address:
            self.socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.socket.bind(self.server_address)
        self.server_address = self.socket.getsockname()
    # ...
# 并且找到了下面几个类, 也就是内置库已经支持多进程/多线程的非阻塞模式
class ForkingUDPServer(ForkingMixIn, UDPServer): pass
class ForkingTCPServer(ForkingMixIn, TCPServer): pass

class ThreadingUDPServer(ThreadingMixIn, UDPServer): pass
class ThreadingTCPServer(ThreadingMixIn, TCPServer): pass

```

> 需要注意的是, BaseHTTPServer.HTTPServer.server_bind 函数中没有用 super 等方式调用父类 server_bind. 而是直接使用 `SocketServer.TCPServer.server_bind(self)` 
> 可以重新写一个 继承自ForkingTCPServer/ThreadingTCPServer 的 HTTPServer 类, 也可以直接继承 BaseHTTPServer.HTTPServer

```python
# 第一种方式
class HTTPServer(SocketServer.ForkingTCPServer):
    allow_reuse_address = 1    # Seems to make sense in testing environment
    def server_bind(self):
        """Override server_bind to store the server name."""
        SocketServer.ForkingTCPServer.server_bind(self)
        host, port = self.socket.getsockname()[:2]
        self.server_name = socket.getfqdn(host)
        self.server_port = port
```

```python
第二种方式
class MyHTTPServer(SocketServer.ForkingTCPServer, BaseHTTPServer.HTTPServer):
    pass
```
> 第二种方式需要特别注意父类继承的顺序. 集成多个父类, 如果某个函数被多次重写, 优先第一个父类.

```python
class Base:
    def __init__(self):
        print "start test: %s" % self.__class__

class BaseA(Base):
    def a(self):
        print "%s: a" % self.__class__ 

class BaseB(Base):
    def a(self):
        print "%s: b" % self.__class__ 

class TestAB(BaseA, BaseB):
    pass

class TestBA(BaseB, BaseA):
    pass

TestAB().a()
print
TestBA().a()

#### output ####
start test: __main__.TestAB
__main__.TestAB: a

start test: __main__.TestBA
__main__.TestBA: b

```

```python
# 完整代码
import SocketServer
import BaseHTTPServer
import SimpleHTTPServer


class MyHTTPServer(SocketServer.ForkingTCPServer, BaseHTTPServer.HTTPServer):
    pass
    
def start():
    SimpleHTTPServer.test(ServerClass=MyHTTPServer)

if __name__ == '__main__':
    start()

```

上述代码就实现了阻塞模式可以并发.

接下来实现 DELETE 方式, 并且支持自定义方式.
```python
# 查看 SimpleHTTPServer.py
def test(HandlerClass = SimpleHTTPRequestHandler,
         ServerClass = BaseHTTPServer.HTTPServer):
    BaseHTTPServer.test(HandlerClass, ServerClass)

class SimpleHTTPRequestHandler(BaseHTTPServer.BaseHTTPRequestHandler):
	def do_GET(self):
	    # ...
	    pass
    def do_HEAD(self):
        # ...
        pass
SimpleHTTPRequestHandler 中没有处理 Handler 的代码, 继承自 BaseHTTPServer.BaseHTTPRequestHandler
```

```python
查看 BaseHTTPServer.py
class BaseHTTPRequestHandler(SocketServer.StreamRequestHandler):

    def handle_one_request(self):
        """Handle a single HTTP request.

        You normally don't need to override this method; see the class
        __doc__ string for information on how to handle specific HTTP
        commands such as GET and POST.

        """
        try:
            # ...
            mname = 'do_' + self.command
            if not hasattr(self, mname):
                self.send_error(501, "Unsupported method (%r)" % self.command)
                return
            method = getattr(self, mname)
            method()
            self.wfile.flush() #actually send the response if not already done.
        except socket.timeout, e:
            #a read or a write timed out.  Discard this connection
            self.log_error("Request timed out: %r", e)
            self.close_connection = 1
            return

    def handle(self):
        """Handle multiple requests if necessary."""
        self.close_connection = 1

        self.handle_one_request()
        while not self.close_connection:
            self.handle_one_request()

可以看到, handle_one_request 中是拼接字符串来获取函数的. 正好对应 SimpleHTTPRequestHandler 中的 do_GET do_HEAD. 而且这里是没有限制哪些请求方式.
```
```python
# 实现
class MyHTTPHandler(SimpleHTTPServer.SimpleHTTPRequestHandler):
    error_message_format = """\
<head>
<title>%(code)d</title>
</head>
<body>
<h1>Error response</h1>
<p>Error code %(code)d.
<p>Message: %(message)s.
<p>Error code explanation: %(explain)s.
</body>
    """
    def do_DELETE(self):
        f = self.send_head()
        if f:
            try:
                self._delete_file(f)
                self.wfile.write("SUCCESS")
                #self.send_response(200, "SUCCESS")
            except OSError:
                self.wfile.write("FAILED")
                #self.send_response(500, "FAILED")
                # self.wfile
            finally:
                f.close()

    def do_FUNC(self):
        self.wfile.write("hello method func")

    def _delete_file(self, source):
        os.remove(source.name)
        
def start():
    SimpleHTTPServer.test(ServerClass=MyHTTPServer)

if __name__ == '__main__':
    start()

#### test ####
$ curl -X FUNC localhost:8000
hello method func

$ curl -X DELETE localhost:8000/thefilenotexists
<head>
<title>Error response</title>
</head>
<body>
<h1>Error response</h1>
<p>Error code 404.
<p>Message: File not found.
<p>Error code explanation: 404 = Nothing matches the given URI.
</body>

```
