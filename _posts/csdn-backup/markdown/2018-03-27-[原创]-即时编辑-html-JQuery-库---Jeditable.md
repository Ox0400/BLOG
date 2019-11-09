---
layout: post
title: "[原创]-即时编辑-html-JQuery-库---Jeditable"
date: 2018-03-27 11:41:41
image: '/assets/img/'
description: "官网地址: https://appelsiini.net/projects/jeditable/  Github 地址: https://github.com/NicolasCARPi/jquery_jeditable  这是实现的仅仅是修改 HTML 的展示, 所以不需要发请求提交更改.   editable 第一个参数设置为 function 即可替换默认的函数.    示例    &amp;lt;h..."
tags:
    - html
    - 编辑
    - 双击
    - jquery
    - jeditable
categories:
    - html
---



官网地址: https://appelsiini.net/projects/jeditable/
Github 地址: https://github.com/NicolasCARPi/jquery_jeditable

这是实现的仅仅是修改 HTML 的展示, 所以不需要发请求提交更改. 
editable 第一个参数设置为 function 即可替换默认的函数.

### 示例
```javascript
<html>
    <head>
	    <script type="text/javascript" src="/static/js/jeditable-2.0.1.min.js"></script>
	    <link rel="stylesheet" type="text/css" href="/static/css/bootstrap-3.3.7.min.css" />
	</head>
	<body>
		<p class="edit-area">Q: Test question</p>
		<p class="edit-area">A: Test for answer</p>
		
	    <script language="javascript">
		    $(document).ready(function() {
		        $(".edit-area").editable(function(input, settings, elem) {
		            console.info("Changed Value: ", input)
		            // WARNING: $(elm).data 必须调用, 否则元素只能编辑一次
		            console.info($(elem).data('_'));
		            $(this).html(input);
		        }, {
		            // submit: 'OK', // 设置后会显示确认按钮
		            // cancel: "Cancel", // 设置后会显示取消按钮
		            event: "dblclick", // 默认为 click, 这里修改为双击进入编辑模式
		            cssclass: "bs-example bs-example-form", // css class name, 编辑模式会生成 form, 这里使用的 bootstrap 的一个表单样式
		            select: false, // 是否默认全选
		            onblur: "submit", // 鼠标失去光标的操作. submit 保留更改. cancel 会取消标记. 默认为 calcel.
		            type: "textarea", // input 类型
		            style: 'color: blue' // 设置样式, 会覆盖 cssclass 中的设置
		        });
			};
		</script>
	</body>
</html>
```
### 注意事项
> editable 第一个参数如果是 function, HTML 元素想多次编辑, 必须调用 $(elem).data 这个函数, 参数可以随意设置. 否则编辑过一次之后, 双击没有反应了.

更多设置可以查看 editable 源码, 比文档更详细一些. 
https://github.com/NicolasCARPi/jquery_jeditable/blob/master/src/jquery.jeditable.js

### 参考文章:
<[jquery EditInPlace 插件 表格单击双击编辑行](https://blog.csdn.net/zilin110/article/details/51554899)> - https://blog.csdn.net/zilin110/article/details/51554899
<[Jeditable 即时编辑 Jquery 插件用法 (.Net)](https://blog.csdn.net/shulin85/article/details/7249223)> - https://blog.csdn.net/shulin85/article/details/7249223
<[Jeditable](https://appelsiini.net/projects/jeditable/)> -  https://appelsiini.net/projects/jeditable/
<[jquery实时编辑插件jeditable详细使用文档](http://www.xiaomlove.com/2014/06/02/jquery%E5%AE%9E%E6%97%B6%E7%BC%96%E8%BE%91%E6%8F%92%E4%BB%B6jeditable%E8%AF%A6%E7%BB%86%E4%BD%BF%E7%94%A8%E6%96%87%E6%A1%A3/)> - [http://www.xiaomlove.com/2014/06/02/jquery实时编辑插件jeditable详细使用文档/](http://www.xiaomlove.com/2014/06/02/jquery%E5%AE%9E%E6%97%B6%E7%BC%96%E8%BE%91%E6%8F%92%E4%BB%B6jeditable%E8%AF%A6%E7%BB%86%E4%BD%BF%E7%94%A8%E6%96%87%E6%A1%A3/)

