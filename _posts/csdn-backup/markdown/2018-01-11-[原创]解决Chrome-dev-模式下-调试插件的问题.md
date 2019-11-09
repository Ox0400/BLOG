---
layout: post
title: "[原创]解决Chrome-dev-模式下-调试插件的问题"
date: 2018-01-11 19:03:27
image: '/assets/img/'
description: "Debug 网页的时候, 如果 Chrome 安装了一些插件, Chrome 会对这些插件也进行 Debug, 尤其是一些周期性的 JS 代码. 网上解决办法都是屏蔽某一个, 其实可以屏蔽全部.  打开 dev tool, 再打开设置(F1), 在 blackboxing 加入一项 "
tags:
    - chrome
    - 调试
    - debug
    - blackbox
    - extensions
categories:
    - tool
---



Debug 网页的时候, 如果 Chrome 安装了一些插件, Chrome 会对这些插件也进行 Debug, 尤其是一些周期性的 JS 代码. 网上解决办法都是屏蔽某一个, 其实可以屏蔽全部.
打开 dev tool, 再打开设置(F1), 在 blackboxing 加入一项:  `^chrome-extension://.*\.js$` 即可忽略所有拓展程序.
还以用正则过滤某个子域名, URI 等等.

```js
^chrome-extension://.*\.js$
```
参考:
<[blackbox third party code](https://developers.google.com/web/tools/chrome-devtools/javascript/step-code#blackbox_third-party_code)>
