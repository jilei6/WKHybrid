# HybridDemo
上一篇讲了基于UIWebview的Hybrid的架构设计，深知UIWebview无法和WKWebview的优越性能相媲美，所以最近又讲框架优化完美的支持了WKWebview。架构思想其实都差不多，不过比UIWebview多了个别核心模块，话不多说，先上新设计图：
![ico原来的样子](https://github.com/jilei6/WKHybrid/blob/master/wk1.png)
整体思路是这样的：

1.在iOS里面启动一个weberver服务，这个服务映射根目录为前端包文件夹，启动这个服务的目的就是为了解决wk不能加载本地资源的问题

2.通过调用wk的私有API去拦截发出的所有的AJAX请求，并替换请求的域，转发该请求获得数据返回给前端。这个是为了解决WK的跨域请求的问题

3.核心的就是上述2个模块，其余的做了前端加密校验机制，和初次预加载机制。

解惑：

1.关于拦截跨域的问题 ，实质上是因为我本地起了一个weberver服务之后，所有页面发出的AJXA请求如下图所示：  
 ![ico原来的样子](https://github.com/jilei6/WKHybrid/blob/master/wk2.png)

跨域
就像你看到的一样，所有请求的域都会是本地的域,即：192.168.100.199这样的请求自然是无法得到想要的数据，所以需要进行拦截请求

2.关于本地启动weberver服务的问题。iOS支持本地启动weberver服务，我使用的第三方的插件库：GCDWebServer 一个轻量级的移动端web服务插件。可以指定根目录，指定端口号功能强大，使用简便。当然我在测试过程中发现，一但APP进入了后台，该服务会被停止，不能进行访问，APP激活状态下，通过PC端（同一局域网）任何浏览器均可访问到iOS沙盒目录下的文件。

3.关于私有API的问题，我参考了[这篇博客][这篇博客]。里面足够可以解释你想知道的问题。

4.我上传了一个前端打包的脚本zipTool.py，用于打包过程中配置基本信息和加密处理。加密密钥KEY=‘xxxxxxx’ 是约束好之后再iOS中通过该密钥进行检验的。请在python3环境下运行。

还有其他的一些细节，可以参考我的代码查看 。


[这篇博客]:https://blog.yeatse.com/2016/10/26/support-nsurlprotocol-in-wkwebview/
