---
layout: post
title: "[原创]-gitlab-commit-集成-redmine-issue"
date: 2019-01-29 14:20:28
image: '/assets/img/'
description: "gitlab  集成 redmine issue web 容器我使用的是 nginx nginx 配置目录 /etc/nginx/nginx.conf nginx html 文件目录 /var/www/cgi/ 更改 nginx/redmine 进程运行用户 启动 nginx 后, redmine 不会有任何进程. 当访问 redmine 后, 后台会 fork 一个子进程. ps aux|gre..."
tags:
    - redmine
    - gitlab
    - issue
    - commit
    - bug
categories:
    - git
---



## gitlab  集成 redmine issue
web 容器我使用的是 nginx
nginx 配置目录 /etc/nginx/nginx.conf
nginx html 文件目录 /var/www/cgi/

### 更改 nginx/redmine 进程运行用户
启动 nginx 后, redmine 不会有任何进程. 当访问 redmine 后, 后台会 fork 一个子进程.
```
ps aux|grep nginx
apache      5771  0.0  2.1 655160 175300 ?       Sl   16:52   0:00 Passenger AppPreloader: /var/www/cgi/redmine (forking...)
```
再查看一下 nginx 进程
```
ps aux| grep nginx
nginx     19268  0.0  0.0  58812  4440 ?        Ss   Jan25   0:00 nginx: master process /etc/nginx/sbin/nginx
nginx      5619  0.0  0.0  61140  5024 ?        S    16:52   0:00 nginx: worker process
...
```
发现 redmine 用户和 nginx 不是一个用户. 需要保持 nginx 用户有权限读写 redmine目录, 并且 redmine 也需要有权限读写本地代码库, 使得 redmine 能够更新版本库. 假设nginx/redmine/git 服务需要以 redmine 执行.
更改 nginx 启动用户, 更改 redmine 启动用户, redmine 使用 nginx 的 passenger启动.
#### 修改 redmine 代码文件用户
```
chown -R redmine:redmine /var/www/cgi/redmine/
```
#### 修改 nginx 配置
```
# /etc/nginx/nginx.conf 部分配置
user  root;
http {
    ...
    passenger_default_user root; # 必填
    passenger_default_group root; # 必填
    ...
    server {
        ...
        listen 80;
        server_name redmine.HOST.com;
        rewrite ^(.*) https://$host$1 permanent;
        ...
    }
    server{
        listen 443;
        server_name redmine.HOST.com;
        root /var/www/cgi/redmine/public;
        passenger_enabled on; # 必填
        passenger_user root; # 必填
        passenger_group root; # 必填
        ...
    }
}
```

#### 重新启动 nginx, 并访问一次 redmine, 即可发现用户已经更改.

```
ps aux|grep -e 'nginx' -e 'redmine'
redmine      5616  0.0  0.0  61140  3516 ?        S    16:52   0:00 nginx: worker process
redmine      5619  0.0  0.0  61140  5024 ?        S    16:52   0:00 nginx: worker process
redmine      5771  0.0  2.3 655160 187320 ?       Sl   16:52   0:01 Passenger AppPreloader: /var/www/redmine (forking...)
redmine     15620  0.0  0.0 112708   992 pts/1    S+   17:23   0:00 grep --color=auto -e nginx -e redmine
redmine     19268  0.0  0.0  58812  4440 ?        Ss   Jan25   0:00 nginx: master process /etc/nginx/sbin/nginx
```
### 克隆需要集成的代码仓库
#### 在 redmine 服务器上 clone 一份项目代码
> 保证用户和 nginx/redmine 一致, 获取 redmine 用户优先权读写本地代码库, 否则后面操作可能会出现 404
#####  配置公钥私钥, 无密码 clone pull 代码
```
ssh-keygen # 一路回车 (如果 redmine 没有创建过私钥)
cat ~/.ssh/id_rsa.pub
# 将公钥添加到 gitlab 个人账户中, `setting`-`ssh keys`, https://gitlab.HOST.com/profile/keys
```
##### clone 代码, 并修改所有权限
```
mkdir  /gitlab/
cd /gitlab/
git clone git@gitlab.HOST.com:USER/YOU_PROJECT.git
chown -R redmine:redmine /gitlab/
```
#### 创建 redmine 项目
在 redmine 创建一个项目, 项目标识就是后面用到的 project_id. 
进入项目, 配置, 版本库, 新建版本库.
SCM 选 Git, 库路径 `/gitlab/YOU_PROJECT`
报告最后一次文件/目录提交选是
创建后点版本库.
##### 解决 Not a git repository: '/gitlab/redmine' 
提示错误, 查看 log 日志, `stderr: fatal: Not a git repository: '/gitlab/YOU_PROJECT' `
```
cd /gitlab
rm -rf redmine
git clone --mirror git@gitlab.HOST.com:USER/YOU_PROJECT.git
chown -R redmine:redmine /gitlab/
```
##### 重新设置 redmine 版本库
将redmine 上设置的版本库删除, 重新添加. 版本库路径 `/gitlab/YOU_PROJECT.git`.
#### redmine 可以获取到 gitlab 项目的提交历史了
### 给 redmine 添加一个 webhook
> 我使用的是第三方的 webhook
项目地址:  https://github.com/phlegx/redmine_gitlab_hook

#### 安装 `redmine_gitlab_hook`
```
cd /var/www/cgi/redmine/plugins
git clone --depth=1 https://github.com/phlegx/redmine_gitlab_hook
chown -R redmine:redmine /var/www/cgi/redmine/plugins/
```
进入 redmine `管理` - `插件` 提示 500, log 提示找不到函数. 这个是因为是版本不兼容导致的. `redmine_gitlab_hook` 用到了几个旧版本的函数.
##### 修改 redmine_gitlab_hook 源码
```ruby
# app/controllers/gitlab_hook_controller.rb:6
class GitlabHookController < ActionController::Base
    ....
    skip_before_filter :verify_authenticity_token, :check_if_login_required
    ...
    # 将这行注释即可. skip_before_filter 是旧版本关键词, skip_before_action 
    # 这行意思是不执行这个几个函数, 实际上无论有没有这行, 都不会执行, 而且还是提示函数不存在, 继承的父类也不对.
    # skip_before_filter :verify_authenticity_token, :check_if_login_required
```

重新启动 nginx, 访问插件页面, 可以看到 `gitlab_hook` 插件.

#### 设置 gitlab_hook
进入`plugin`-`gitlab_hook`-`setting`, 页面是 erb 源码, rails 根本没有进行对 `_gitlab_settings.html` 模版渲染.
这个坑, 具体从哪个版本开始的我也不清楚, 最后在我看了很多 render 渲染内容, 最后突发奇想, 我把 .html 改成 .erb, 发现可以了.
##### 重命名模版文件名
```bash
cd /var/www/cgi/redmine/plugins/redmine_gitlab_hook/app/views/settings/
mv _gitlab_settings.html _gitlab_settings.html.erb
```
##### 重启 nginx, 保存插件设置
重启 nginx, 便可以看到 Redmine GitLab Hook Plugin 渲染后的配置页面.
将从最后一项`从库中获取更新`选中, 应用保存.

#### 配置 redmine Rest Web Service(WS)
redmine `管理`-`配置`-`API`, 打开 `REST web service` 并保存. 
`管理`-`配置`-`版本库`, 选择 SCM 只需要选 git, 自动获取变更, `启用版本管理的 web service`, 版本管理 API 秘钥, 生成 key, 然后保存, 后面会用到这个 `redmine_ws_api_key`.
#### 配置 issue 关键词
页面最下-`跟踪标签`, 这块是用来检测 commit log 的, 匹配到某个关键词, 然后修改 issue 状态, 并显示 issue 进度. 关键词用`,`分割. 设置后保存.

```txt
# 这是我的关键词设置.
finish,ok,fix,fixed   resolved    100%
start,started   ongoing  0%
close,closed closed    100%
# 用法是 commit 的时候 start:#22 @某某,  就可对第22个 issue 进行状态修改, 并抄送给某某.
```
### 测试 API
插件和 redmine 的一些系统设置配置完成, 测试一下API.

```bash
curl -I "https://redmine.HOST.com/gitlab_hook?key={redmine_api_key}&project_id={you_redmine_project_id}"
# 返回404, 看了下说明文档, 说是要必须使用 post 
curl -X POST -I "https://redmine.HOST.com/gitlab_hook?key={redmine_api_key}&project_id={you_redmine_project_id}"
# 还是提示错误, 查看 redmine log, 发现是在返回消息的是或否报错, 提示没有找到模版文件. 
`Issues with ActionView::MissingTemplate: Missing template gitlab_hook/index`
app/controllers/gitlab_hook_controller.rb:22
render(:text => 'OK', :status => :ok)
查看了一些文档, 最后发现了问题所在, 好像是从 rails 5.0 开始, render :text 必须会获取对应的模版. 
解决方案: 将`:text`改成`:plain` 即可.
curl -X POST -I "https://redmine.HOST.com/gitlab_hook?key={redmine_api_key}&project_id={you_redmine_project_id}"
成功返回 OK, webhook 插件安装测试通过.
```

到目前为止, redmine 所有项目都已经配置完成. 只需要在 gitlab 中添加 webhook, 将消息推送到 redmine.
### 在 gitlab 配置 redmine webhook
登录 gitlab web 页面, 打开 `PROJECT`-`settings`-`integrations`,  URL 填上面测试测的地址, 勾选你想监控的触发器, 最后一行有使用启用 SSL(如果需要) 添加保存. 
在 hook 右边 `Test` 选择一个勾选的触发器就可以测试. 成功会返回 `Hook executed successfully: HTTP 200`.

### 总结
总结, 整个搭建过程,需要注意几个点
确保 nginx 运行 redmine 的用户和本地 git 仓库用户一致, 使redmine 有权限读取 git log
git clone 项目时加上 `--mirror`, 并确保可以无密码 pull 代码. 即可打开 gitlab 对 redmine 的22 端口.
redmine 启动 Seb Server, 并生成一个 api key
redmine 创建几个关键词, 用来标记 redmine issue 状态.
redmine 安装 `redmine_gitlab_hook`插件, 因为版本不兼容, 我把插件权限认证代码注释 (#非常不安全,特别注意, 只用于临时测试). 将 `render(:text ...)` 修改为 `render(:plain...)`, 将模版`_gitlab_settings.html` 改名为 `_gitlab_settings.html.erb`, 确保插件设置页面可以被 rails 渲染.
### 系统环境
```bash
$ ruby --version
# ruby 2.4.5p335 (2018-10-18 revision 65137) [x86_64-linux]
$ rails --version
# Rails 5.2.2
$ passenger --version
# Phusion Passenger 6.0.1
Redmine version                4.0.0.stable.17799
Plugins - redmine_gitlab_hook            0.2.2
```

你以为完了, 其实并没有, 权限问题还没有解决, 上面只是注释了! 
### 授权验证
再说授权问题, 上面提到把权限认证代码注释后, 依旧可以访问, 把 hook 参数中的 key 删除, 依旧是可以访问的. 下面做一些测试. ActionController 并没有`verify_authenticity_token` 和 `check_if_login_required` , 所以即便 skip 了,也不会执行, 所以这个 hook 是裸奔状态.
授权相关代码在 `app/controllers/application_controller.rb:114:find_current_user, user_setup` 可以找到
#### 再次修改 gitlab_hook 源码
```
class GitlabHookController < ActionController::Base
  GIT_BIN = Redmine::Configuration[:scm_git_command] || 'git'

  def index
    if params[:key].present?
      key = params[:key].to_s
    elsif request.headers["X-Redmine-API-Key"].present?
      key = request.headers["X-Redmine-API-Key"].to_s
    end
    logger.info("check key:" + key)
    user = User.find_by_api_key(key)
    logger.info("check key, current user: " + (User.current.logged? ? "#{User.current.login} (id=#{User.current.id})" : "anonymous"))

    logger.info(user)
    if request.post?
      ....

```
log 显示无论 key 填什么, 用户始终是 anonymous, 根本没有检测到 ws_api_key 是否有效, 没有403, 直接返回 OK.
通过查看一些别的 *controller.rb 代码, 代码改成如下:

#### 修改继承的父类
```
# 查看源码, ApplicationController 也是继承于 ActionController::Base 的
class GitlabHookController < ApplicationController
  GIT_BIN = Redmine::Configuration[:scm_git_command] || 'git'

  def index
    if params[:key].present?
      key = params[:key].to_s
    elsif request.headers["X-Redmine-API-Key"].present?
      key = request.headers["X-Redmine-API-Key"].to_s
    end
    logger.info("check key:" + key)
    user = User.find_by_api_key(key)
    logger.info("check key, current user: " + (User.current.logged? ? "#{User.current.login} (id=#{User.current.id})" : "anonymous")) if logger

    logger.info(user)
    if request.post?
      ....
```
通过测试, 无论 key 怎么填, 都直接返回 422,拒绝连接. 
查看了一些文档得知, 这几个函数所检测 key 并不是 web server 的 ws_api_key, 而且每个用户账号下面生成的一个 user_api_key, `我的账号` - `API访问键`, 是每个用户独立的 key.
#### 修改源码, 跳过授权检查, 在 index 对 user_api_key 检测
将代码改为如下, 忽略用户安全验证. ApplicationController 用户验证号并不会对 find_by_api_key 的结果进行检查, 而是对 User.current 检查, 所以无论是通不过检查的的. 只能自己对结果检查.

```
class GitlabHookController < ApplicationController
  GIT_BIN = Redmine::Configuration[:scm_git_command] || 'git'
  skip_before_action :verify_authenticity_token, :check_if_login_required
  def index
    if params[:key].present?
      key = params[:key].to_s
    elsif request.headers["X-Redmine-API-Key"].present?
      key = request.headers["X-Redmine-API-Key"].to_s
    end
    logger.info("check key:" + key)
    user = User.find_by_api_key(key)
    logger.info("check key, current user: " + (User.current.logged? ? "#{User.current.login} (id=#{User.current.id})" : "anonymous")) if logger

    logger.info(user)
    if (!user)
      logger.info("unauthorize, not find user, key: " + key)
      render(:plain=> 'unauthorize', :status => 403)
      return false
    end
    if request.post?
      ....
```

```
# 日志如下
Started POST "/gitlab_hook?key= xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx&project_id=yyyyy" for 12.12.8.8 at 2019-01-29 11:27:55 +0800
Processing by GitlabHookController#index as */*
  Parameters: {"key"=>"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx", "project_id"=>"yyyyy"}
  Current user: anonymous
------ api key: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
zhipeng
Completed 200 OK in 385ms (Views: 1.1ms | ActiveRecord: 6.8ms)

Started POST "/gitlab_hook?key= xxxxxxxxxxxxxxxxxxxxx000000000&project_id= yyyyy" for 12.12.8.8 at 2019-01-29 11:28:00 +0800
Processing by GitlabHookController#index as */*
  Parameters: {"key"=>"xxxxxxxxxxxxxxxxxxxxx000000000", "project_id"=>"yyyyy"}
  Current user: anonymous
------ api key: xxxxxxxxxxxxxxxxxxxxx000000000

unauthorize, not find user, key: xxxxxxxxxxxxxxxxxxxxx000000000
Completed 403 Forbidden in 4ms (Views: 0.3ms | ActiveRecord: 0.7ms)

```
如上, 实现了对 `user_api_key` 的校验. 可以确保不会被匿名用户访问.
除了可以使用 `skip_before_action`, 还可以使用 `before_action` 进行强制执行一些函数.

那么问题来了, 上面只是对单个用户的 key 进行校验, 那怎么 rest web server api key 校验? 
#### 校验 redmine_ws_api_key
在网页上我找到了 element 对应的 setting key, `sys_api_key`. 
```
<p><label for="settings_sys_api_key">版本库管理网页服务 API 密钥</label><input type="text" name="settings[sys_api_key]" id="settings_sys_api_key" value="EHefPUSy6R8A1bNstqIe" size="30"  autofill-prediction="UNKNOWN_TYPE">
  <a href="#" onclick="if (!$('#settings_sys_api_key').attr('disabled')) { $('#settings_sys_api_key').val(randomKey(20)) }; return false;">生成一个key</a>
</p>
```
##### 查找用到 sys_api_key 的 controller.rb
通过查找, 找到一个 `app/controllers/sys_controller.rb`

```
class SysController < ActionController::Base
 # 强制执行 check_enabled 这个函数
  before_action :check_enabled
  ...
  def check_enabled
    User.current = nil
    unless Setting.sys_api_enabled? && params[:key].to_s == Setting.sys_api_key
      render :plain => 'Access denied. Repository management WS is disabled or key is invalid.', :status => 403
      return false
    end
  end
```
##### 修改继承的父类为 SysController
```
class GitlabHookController < SysController

  GIT_BIN = Redmine::Configuration[:scm_git_command] || 'git'

  def index
    if request.post?
      repository = find_repository
      ...
```
##### 测试
```
# log 日志
# 测试 redmine_ws_api_key
Started POST "/gitlab_hook?key=XXXXXXXXXXXXX&project_id=YYYY" for 103.255.228.99 at 2019-01-29 11:57:10 +0800
Processing by GitlabHookController#index as */*
  Parameters: {"key"=>"XXXXXXXXXXXXX", "project_id"=>"YYYY"}
Completed 200 OK in 279ms (Views: 0.5ms | ActiveRecord: 0.5ms)

# 测试一个用户 api key
Started POST "/gitlab_hook?project_id=YYYY&key= xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" for 103.255.228.99 at 2019-01-29 11:57:14 +0800
Processing by GitlabHookController#index as */*
  Parameters: {"project_id"=>"YYYY", "key"=>"xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"}
Filter chain halted as :check_enabled rendered or redirected
Completed 403 Forbidden in 0ms (Views: 0.2ms | ActiveRecord: 0.0ms)
# curl response: Access denied. Repository management WS is disabled or key is invalid.
```

到现在为止, 所以问题都已经搞定, 也实现了对 web service api key 的校验. 很多都是官方文档中没有提到的, 只能通过查看源码解决.


### 参考

[Replace render :text with :plain](https://trello.com/c/3UDSiNSA/20-replace-render-text-with-plain)
[Redmine与Gitlab深度集成](https://blog.csdn.net/hxpjava1/article/details/78522411?locationNum=7&fps=1)
[Redmine Wiki](https://www.redmine.org/guide)
[phlegx/redmine\_gitlab\_hook](https://github.com/phlegx/redmine_gitlab_hook)
[Redmine and Git - stderr: fatal: Not a git repository](https://stackoverflow.com/questions/44116270/redmine-and-git-stderr-fatal-not-a-git-repository)

