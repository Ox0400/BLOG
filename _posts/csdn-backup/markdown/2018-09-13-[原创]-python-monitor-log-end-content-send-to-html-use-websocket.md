---
layout: post
title: "[原创]-python-monitor-log-end-content-send-to-html-use-websocket"
date: 2018-09-13 17:28:15
image: '/assets/img/'
description: "Use Python monitor log file end content, like tail -f, and send to html use websocket.  server.py  # server.py import tornado.web import tornado.httpserver import tornado.options from tornado.options ..."
tags:
    - tail
    - websocket
    - monitor
categories:
    - python
    - html
---




#### Use Python monitor log file end content, like `tail -f`, and send to html use websocket.

##### server.py
```python
# server.py
import tornado.web
import tornado.httpserver
import tornado.options
from tornado.options import define
from tornado.options import options

from .log_handler import LogHandler, LogScoketHandler


define("port", default=8182, help="Run server on a specific port", type=int)
define("host", default='0.0.0.0', help="Bind host name or ip", type=str)
define("log_dir", default='logs', help="logs dirname", type=str)

class Server():
    def __init__(self, settings, *args, **kwargs):
        self.settings = settings
        self.handlers = [
            (r'/static/(.*)', tornado.web.StaticFileHandler, {'path': settings.get("static_path")}),
            (r"/log\.html$", LogHandler),
            (r"/log/?$", LogSocketHandler)
        ]
    def start(self):
        tornado.options.parse_command_line()
        app = tornado.web.Application(self, self.handlers, **self.settings)
        http_server = tornado.httpserver.HTTPServer(app, xheaders=True)
        http_server.listen(options.port, address=options.host)
        tornado.ioloop.IOLoop.instance().start()
if __name__ == "__main__":
    Server({"static_path": "static"}).start()
```

##### log_handler.py
```python
# log_handler.py
import os, sys, time

from tornado.web import RequestHandler
from tornado.websocket import WebSocketHandler
from tornado.websocket import WebSocketClosedError
from tornado.ioloop import IOLoop
from tornado.options import options


class LogHandler(RequestHandler):
    def get(self):
        job_name = self.get_argument("name")
        date = self.get_argument("date")
        self.render("log.html", name=job_name, date=date)

class LogSocketHandler(WebSocketHandler):
    def __init__(self, *args, **kwargs):
        super(LogSocketHandler, self).__init__(*args, **kwargs)
        self._fp = None
        self._filename = None
        self._st_ino = None

    def on_message(self, message):
        """
        action:open:{job_name}:{job_date}
        action:close
        """
        _tmp_list = message.split(":")
        action, func, args = _tmp_list[0],_tmp_list[1],_tmp_list[2:]
        if action != "action":
            self.write_message("not start with action, close.")
            self.close()
        if not hasattr(self, "do_" + func):
            self.close()
        try:
            getattr(self, "do_" + func)(*args)
        except Exception, e:
            traceback.print_exc()
            self.write_message(str(e))
            self.do_close()

    def do_open(self, job_name ="crawler", date="today", *args):
        # logs/crawler-wechat_2018-07-13.log
        path = os.path.join(options.log_dir, "%s_%s.log" % (job_name, date))
        if not os.path.isfile(path):
            self.write_message("log file not found. file: %s" % path)
            return
        self._filename = path
        self.read_file()

    def do_close(self, *args):
        self.on_close()

    def on_close(self):
        try:
            self.close()
            self._fp.close()
        except:
            pass

    def read_file(self):
        if self._fp is None or self._fp.closed:
            self._fp = open(self._filename)
            # self._fp = file(path, encoding="utf-8")
            self._st_ino = os.fstat(self._fp.fileno()).st_ino
        if not self._fp:
            return False
        while True:
            if self._fp.closed:
                break
            line = self._fp.readline()
            if line == "":
                break
            try:
                self.write_message(line)
            except WebSocketClosedError:
                self.on_close()
        if os.stat(self._filename).st_ino != self._st_ino:
            seek = self._fp.tell()
            new = open(self._filename)
            self._fp.close()
            self._fp = new
            self._fp.seek(seek)
            self._st_ino = os.fstat(self._fp.fileno()).st_ino
        IOLoop.instance().add_timeout(time.time() + 0.5, self.read_file)

```

##### static/log.html
```html
# log.html
<html>
<head>
    <meta charset="UTF-8">
    <title>Log History {{ name }}</title>
    <style>
    pre {
        /*white-space: pre-wrap;*/
        white-space: -moz-pre-wrap;
        white-space: -pre-wrap;
        white-space: -o-pre-wrap;
        word-wrap: break-word;
        margin: unset;
    }
    </style>
    <script type="text/javascript" src="/static/module/jquery-2.1.1.min.js"></script>
</head>

<body>
    <h5><span>Log File Name: {{ name }}_{{ date }} </span></h5>
    <code id="logs"> </code>
    <script>
    function scrollEnd() {
        $(document).scrollTop($(document).height() - $(window).height());
    }
    var ws = new WebSocket("ws://localhost:8182/log");
    ws.onopen = function() {
        ws.send("action:open:{{ name }}:{{ date }}");
    };
    ws.onmessage = function(msg) {
        $("#logs").append("<pre>" + msg.data + "</pre>");
        scrollEnd();
    };
    </script>
</body>

</html>

```

##### view files
```
# file list
- server.py
- log_handler.py
- static/log.html
- static/module/jquery-2.1.1.min.js
- logs/crawler-wechat_2018-07-13.log
```

##### view on browser
open url: http://localhost:8182/log.html

##### reference: 
https://github.com/892768447/SimpleTasksSystem/blob/master/AutoReportHandlers.py#L238 <br>
https://tornado-zh.readthedocs.io/zh/latest/websocket.html
[python: read file continuously, even after it has been logrotated](https://stackoverflow.com/questions/25537237/python-read-file-continuously-even-after-it-has-been-logrotated/25632664#25632664) - https://stackoverflow.com/questions/25537237/python-read-file-continuously-even-after-it-has-been-logrotated/25632664#25632664