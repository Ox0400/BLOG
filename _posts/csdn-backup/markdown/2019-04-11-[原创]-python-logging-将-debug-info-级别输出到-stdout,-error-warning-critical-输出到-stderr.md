---
layout: post
title: "[原创]-python-logging-将-debug-info-级别输出到-stdout,-error-warning-critical-输出到-stderr"
date: 2019-04-11 18:42:14
image: '/assets/img/'
description: "将 logging debug/info 级别的日志输出到 stdout, 将 warning, error, critical 输出到 stderr. 结果示例. 代码已经提交到 Stack Overflow 上. 详见: https://stackoverflow.com/a/55494220/3992791 # 只输出 print/logging.debug/logging.info 内容 ..."
tags:
    - 
categories:
    - python
---



将 logging debug/info 级别的日志输出到 stdout, 将 warning, error, critical 输出到 stderr.

结果示例. 代码已经提交到 Stack Overflow 上. 详见: [https://stackoverflow.com/a/55494220/3992791](https://stackoverflow.com/a/55494220/3992791)

```bash
# 只输出 print/logging.debug/logging.info 内容
python demo.py 2>/dev/null
# 只输出 logging.warning/logging.error/logging.critical 错误日志
python demo.py 1>/dev/null
```

在 google, Stack Overflow 搜索之后解决办法大多都是建议创建多个处理器. 所以只能自己写了. 
python logging 默认所有的日志都是输出到 stderr 中的, 如果想通过 shell 区分正常和错误日志还需要根据关键词过滤, 考虑给 logging 打补丁实现这个目的.

```python
class Logger(Filterer):
# ...
    def _log(self, level, msg, args, exc_info=None, extra=None):
        """
        Low-level logging routine which creates a LogRecord and then calls
        all the handlers of this logger to handle the record.
        """
        if _srcfile:
            #IronPython doesn't track Python frames, so findCaller raises an
            #exception on some versions of IronPython. We trap it here so that
            #IronPython can use logging.
            try:
                fn, lno, func = self.findCaller()
            except ValueError:
                fn, lno, func = "(unknown file)", 0, "(unknown function)"
        else:
            fn, lno, func = "(unknown file)", 0, "(unknown function)"
        if exc_info:
            if not isinstance(exc_info, tuple):
                exc_info = sys.exc_info()
        record = self.makeRecord(self.name, level, fn, lno, msg, args, exc_info, func, extra)
        self.handle(record)
# ...
    def handle(self, record):
        """
        Call the handlers for the specified record.

        This method is used for unpickled records received from a socket, as
        well as those created locally. Logger-level filtering is applied.
        """
        if (not self.disabled) and self.filter(record):
            self.callHandlers(record)
            
    def callHandlers(self, record):
        """
        Pass a record to all relevant handlers.

        Loop through all handlers for this logger and its parents in the
        logger hierarchy. If no handler was found, output a one-off error
        message to sys.stderr. Stop searching up the hierarchy whenever a
        logger with the "propagate" attribute set to zero is found - that
        will be the last logger whose handlers are called.
        """
        c = self
        found = 0
        while c:
            for hdlr in c.handlers:
                found = found + 1
                if record.levelno >= hdlr.level:
                    hdlr.handle(record)
            if not c.propagate:
                c = None    #break out
            else:
                c = c.parent
        if (found == 0) and raiseExceptions and not self.manager.emittedNoHandlerWarning:
            sys.stderr.write("No handlers could be found for logger"
                             " \"%s\"\n" % self.name)
            self.manager.emittedNoHandlerWarning = 1

```
> 查看 `Logger` 得知, `_log` 会调用 `Handler` 中的 `handle` 函数

```python
class StreamHandler(Handler):
    """
    A handler class which writes logging records, appropriately formatted,
    to a stream. Note that this class does not close the stream, as
    sys.stdout or sys.stderr may be used.
    """

    def __init__(self, stream=None):
        """
        Initialize the handler.

        If stream is not specified, sys.stderr is used.
        """
        Handler.__init__(self)
        if stream is None:
            stream = sys.stderr
        self.stream = stream
    

    def emit(self, record):
        """
        Emit a record.

        If a formatter is specified, it is used to format the record.
        The record is then written to the stream with a trailing newline.  If
        exception information is present, it is formatted using
        traceback.print_exception and appended to the stream.  If the stream
        has an 'encoding' attribute, it is used to determine how to do the
        output to the stream.
        """
        try:
            msg = self.format(record)
            stream = self.stream
            fs = "%s\n"
            if not _unicode: #if no unicode support...
                stream.write(fs % msg)
            else:
                try:
                    if (isinstance(msg, unicode) and
                        getattr(stream, 'encoding', None)):
                        ufs = u'%s\n'
                        try:
                            stream.write(ufs % msg)
                        except UnicodeEncodeError:
                            #Printing to terminals sometimes fails. For example,
                            #with an encoding of 'cp1251', the above write will
                            #work if written to a stream opened or wrapped by
                            #the codecs module, but fail when writing to a
                            #terminal even when the codepage is set to cp1251.
                            #An extra encoding step seems to be needed.
                            stream.write((ufs % msg).encode(stream.encoding))
                    else:
                        stream.write(fs % msg)
                except UnicodeError:
                    stream.write(fs % msg.encode("UTF-8"))
            self.flush()
        except (KeyboardInterrupt, SystemExit):
            raise
        except:
            self.handleError(record)


```

> `StreamHandler` 默认是写入 `sys.stderr` 中的,  继续看父类 `Handler` 

```python

class Handler(Filterer):
    """
    Handler instances dispatch logging events to specific destinations.

    The base handler class. Acts as a placeholder which defines the Handler
    interface. Handlers can optionally use Formatter instances to format
    records as desired. By default, no formatter is specified; in this case,
    the 'raw' message as determined by record.message is logged.
    """
# ... 

    def handle(self, record):
        """
        Conditionally emit the specified logging record.

        Emission depends on filters which may have been added to the handler.
        Wrap the actual emission of the record with acquisition/release of
        the I/O thread lock. Returns whether the filter passed the record for
        emission.
        """
        rv = self.filter(record)
        if rv:
            self.acquire()
            try:
                self.emit(record)
            finally:
                self.release()
        return rv

```
> 先对`record`进行过滤, 如果被过滤, 就不会记录日志. 先加锁, 在写入日志. `emit` 需要在子类`StreamHandler`中实现. 

> `StreamHandler.emit` 在上一块已经看过, 多次调用了 stream.write 且逻辑过于复杂, 并不适合打补丁. 最完美的选择就是在`StreamHandler.handle`中实现.


> `Logger._log`中 record = self.makeRecord(...).  `record`是`LogRecord`的实例. 
> 
`levelname` 是 "DEBUG"/"INFO"/"WARNING"/"ERROR"/"CRITICAL"

思路: `StreamHandler.handle`中, 在`self.emit`之前判断`record`的级别, 切换`stream`, `emit`之后再切换回去.

```python
# logger_helper.py
import sys, logging, threading

def _logging_handle(self, record):
    self.STREAM_LOCKER = getattr(self, "STREAM_LOCKER", threading.RLock())
    if self.stream in (sys.stdout, sys.stderr) and record.levelname in self.FIX_LEVELS:
        try:
            self.STREAM_LOCKER.acquire()
            self.stream = sys.stdout
            self.old_handle(record)
            self.stream = sys.stderr
        finally:
            self.STREAM_LOCKER.release()
    else:
        self.old_handle(record)


def patch_logging_stream(*levels):
    """
    writing some logging level message to sys.stdout

    example:
    patch_logging_stream(logging.INFO, logging.DEBUG)
    logging.getLogger('root').setLevel(logging.DEBUG)

    logging.getLogger('root').debug('test stdout')
    logging.getLogger('root').error('test stderr')
    """
    stream_handler = logging.StreamHandler
    levels = levels or [logging.DEBUG, logging.INFO]
    stream_handler.FIX_LEVELS = [logging.getLevelName(i) for i in levels]
    if hasattr(stream_handler, "old_handle"):
        stream_handler.handle = stream_handler.old_handle
    stream_handler.old_handle = stream_handler.handle
    stream_handler.handle = _logging_handle

```

```python
# demo.py
import logging
from logger_helper import patch_logging_stream

logging.getLogger().setLevel(logging.DEBUG)
patch_logging_stream(logging.DEBUG, logging.INFO)

if __name__ == "__main__":
	logging.info('test info')
	logging.debug('test debug')
	logging.debug('test error')
```

```bash
$ python demo.py 1>/dev/null
$ python demo.py 2>/dev/null
```

参考
[Logging, StreamHandler and standard streams](https://stackoverflow.com/questions/1383254/logging-streamhandler-and-standard-streams/)
