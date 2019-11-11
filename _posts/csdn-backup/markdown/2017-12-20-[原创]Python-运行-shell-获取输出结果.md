---
layout: post
title: "[原创]Python-运行-shell-获取输出结果"
date: 2017-12-20 18:40:23
description: "python  获取 shell stdout stderr"
tags:
    - python
    - shell
    - stdout
    - timeout
categories:
    - python
---



#### 首先使用内置模块os.
```python
>>> import os
>>> code = os.system("pwd && sleep 2")
# /User/zhipeng
>>> print code
# 0
```
> 问题是 os.system 只能获取到结束状态

#### 使用内置模块 subprocess
```python
>>> import subprocess
>>> subprocess.Popen("pwd && sleep 2", shell=True, cwd="/home")
# <subprocess.Popen object at 0x106498310>
# /home

>>> sub = subprocess.Popen("pwd && sleep 2", shell=True, stdout=subprcess.PIPE)
>>> sub.wait()
>>> print sub.stdout.read()
# /User/zhipeng
```
> subprocess.Popen还支持一些别的参数 
> bufsize,executable=None, stdin=None, stdout=None, stderr=None
> preexec_fn=None, close_fds=False, shell=False, cwd=None, env=None
> universal_newlines=False, startupinfo=None, creationflags=0

#### 使用第三方模块 sh
```
# pip install sh
>>> from sh import ifconfig
>>> print ifconfig("eth0")

>>> from sh import bash
>>> bash("pwd")
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
  File "/Library/Python/2.7/site-packages/sh.py", line 1021, in __call__
    return RunningCommand(cmd, call_args, stdin, stdout, stderr)
  File "/Library/Python/2.7/site-packages/sh.py", line 486, in __init__
    self.wait()
  File "/Library/Python/2.7/site-packages/sh.py", line 500, in wait
    self.handle_command_exit_code(exit_code)
  File "/Library/Python/2.7/site-packages/sh.py", line 516, in handle_command_exit_code
    raise exc(self.ran, self.process.stdout, self.process.stderr)
sh.ErrorReturnCode_126: 
  RAN: '/bin/bash ls'
  STDOUT:
  STDERR:
/bin/ls: /bin/ls: cannot execute binary file

# 不能这么用
>>> from sh import ls
>>> ls()
# hello.txt 1.txt
# ls -al
>>> ls(a=True, l=True)
# ls(al=True) 是不可以的
```

> 这操作太复杂了, 项目中使用也太糟心了, 也没有办法多个命令同时用.不过可以用别的方式代替

```
# bash -c command 可以很好的解决这个问题
# bash -c "sleep 1 && pwd"
>>> result = bash(c="pwd", _timeout=1, _cwd="/home")
>>> print result
# -rw-r--r--@   1 zhipeng  staff    0 10 13 18:30 hello.txt
# -rw-r--r--@   1 zhipeng  staff    0 10 13 18:30 1.txt

>>> result = bash(c="pwd", _timeout=1, _cwd="/")
>>> print result
# /
>>> bash(c="pwd && sleep 2", _timeout=1)
Traceback (most recent call last):
  File "<stdin>", line 1, in <module>
  File "/Library/Python/2.7/site-packages/sh.py", line 1021, in __call__
    return RunningCommand(cmd, call_args, stdin, stdout, stderr)
  File "/Library/Python/2.7/site-packages/sh.py", line 486, in __init__
    self.wait()
  File "/Library/Python/2.7/site-packages/sh.py", line 498, in wait
    raise TimeoutException(-exit_code)
sh.TimeoutException

```
> 参数里面可以添加非命令参数. 需要以_开头, 例如上面的_timeout, _cwd. 详见sh.py  源码
> 还支持以下参数 
> internal_bufsize, err_bufsize, tee, done, in, decode_errors, tty_in,
> out, cwd, timeout_signal, bg, timeout, with, ok_code, err, env, no_out,

参考:
https://github.com/amoffat/sh/blob/master/sh.py
https://github.com/amoffat/sh
