---
layout: post
title: "[原创]-前端-diff-文本---mergely"
date: 2018-04-08 11:37:56
image: '/assets/img/'
description: "介绍  需要前端展示文本编辑历史, 并做 diff.  找了三个库, 分别是: CodeMirror, DiffMatchPatch, Mergely  CodeMirror 效果不是很好, DiffMatchPatch 是 Google 开发的, 感觉实现后效果同样不好.最后选用了 Mergely.     实际上, Mergely 用到了 CodeMirror, 而 CodeMirror 用到..."
tags:
    - 前端
    - diff
    - mergely
    - google
categories:
    - html
---




### 介绍

需要前端展示文本编辑历史, 并做 diff.
找了三个库, 分别是: CodeMirror, DiffMatchPatch, Mergely
CodeMirror 效果不是很好, DiffMatchPatch 是 Google 开发的, 感觉实现后效果同样不好.最后选用了 Mergely.
> 实际上, Mergely 用到了 CodeMirror, 而 CodeMirror 用到了 DiffMatchPatch.

先上最终效果图
![MergelyDemo](/assets/img/d13f14d36a4408636231d17599c9ecde.png)

#### CodeMirror
CodeMirror 和 DiffMatchPatch 这里不做过多介绍. 有兴趣可以试试.
CodeMirror Github: [https://github.com/codemirror/CodeMirror](https://github.com/codemirror/CodeMirror)
CodeMirror Demo: [http://codemirror.net/demo/merge.html](http://codemirror.net/demo/merge.html)

#### DiffMatchPatch
DiffMatchPatch Github: [https://github.com/google/diff-match-patch](https://github.com/google/diff-match-patch)
DiffMatchPatch Diff Demo: [https://neil.fraser.name/software/diff_match_patch/demos/diff.html](https://neil.fraser.name/software/diff_match_patch/demos/diff.html)
DiffMatchPatch Match Demo: [https://neil.fraser.name/software/diff_match_patch/demos/match.html](https://neil.fraser.name/software/diff_match_patch/demos/match.html)
DiffMatchPatch Patch Demo: [https://neil.fraser.name/software/diff_match_patch/demos/patch.html](https://neil.fraser.name/software/diff_match_patch/demos/patch.html)

#### Mergely 
官网地址: [http://www.mergely.com/](http://www.mergely.com/)
Github: [https://github.com/wickedest/Mergely](https://github.com/wickedest/Mergely)
Demo 1: [https://jsfiddle.net/bilgehansolo/142r02ny/](https://jsfiddle.net/bilgehansolo/142r02ny/)
Demo 2: [https://codepen.io/Sphinxxxx/pen/grVvjG](https://codepen.io/Sphinxxxx/pen/grVvjG)


### 示例

```js
<HTML>

<HEAD>
    <meta charset="UTF-8">
    <TITLE>Diff Demo</TITLE>
    <!-- <SCRIPT TYPE="text/javascript" LANGUAGE="JavaScript" SRC="diff_match_patch.js"></SCRIPT> -->
    <script type="text/javascript" src="jquery-2.1.1.min.js"></script>
    <script type="text/javascript" src="codemirror.min-5.32.0.js"></script>
    <script type="text/javascript" src="searchcursor.min-5.32.0.js"></script>
    <script type="text/javascript" src="mergely.min-3.4.5.js"></script>
    <link rel="stylesheet" href="../css/codemirror.min-5.32.0.css">
    <link rel="stylesheet" media="all" href="../css/mergely-3.4.5.css" />
    <style>
    .CodeMirror,
    .mergely-margin,
    .mergely-column {
        height: 400px;
    }
    </style>
</HEAD>

<BODY>
    <div>
        <h2>Diff Demo</h2>
        <div class="mergely-full-screen-8">
            <div class="mergely-resizer">
                <div id="mergely"></div>
            </div>
        </div>
    </div>
    <script>
    $(document).ready(function() {
        // initialize mergely
        options = { line_numbers: true, editor_height: "400px", autoresize: false, lcs: true }
        $('#mergely').mergely('options', options);

    });
    l = "Q:唉我问一下我们用的这个400电话外呼的时候对方会显示几个号码呀\n\
A:您这边是那个上海欣荣汽车科技有限公司是吗？唉。\n\
Q:11300571对吧？\n\
A:对就是您那个件号码\n\
Q:哪个？你说客户是哪个方向的吗？客户是江苏的\n\
A:是您稍等我这边查一下我，您是外省，号码是11300571呀\n\
Q:你稍等一下，我马上去看一下我外呼的是哪个号码。\n\
A:是江苏无锡的吗？\n\
Q:那11300001这个是什么号码呢？\n\
A:上当，\n\
Q:其他没有了，谢谢嗯好再见。\n\
A:唉好。"
    r = "Q:唉我问一下我们用的这个400电话外呼的时候对方会显示几个号码呀\n\
A:您这边是那个上海欣荣汽车科技有限公司是吗？\n\
Q:11300571对吧？\n\
A:对就是您那个号码\n\
Q:哪个？你说客户是哪个方向的吗？客户是江苏的\n\
A:是您稍等我这边查一下我，您是外省，号码是11300571\n\
Q:你稍等一下，我马上去看一下我外省的是哪个号码。\n\
A:是江苏无锡的吗？\n\
Q:其他没有了，谢谢嗯好再见。\n\
A:唉好。"
    $('#mergely').mergely({
        line_numbers: true,
        lhs: function(setValue) {
            setValue(l);
        },
        rhs: function(setValue) {
            setValue(r);
        }
    });
    </script>
</BODY>

</HTML>

```

> 需要注意的是HEAD 中必须指定 ```<meta charset="UTF-8">```, 否则编辑框指针会乱码.

---
