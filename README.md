DrCOM FOR HC5661
------------------

# 警告
* 请先确保在PC上使用 *drcom-generic-debug-u62.py* 测试可以上网以后再考虑本补丁
* 所有风险由使用者承担，作者不承担任何法律责任，否则请您不要使用

有关其他可以让程序运行的更美好的办法可以参考 README 尾部 <br>
首先，刷打开了ssh的固件，通俗说为root （详细参考www.hiwifimi.com)，版本 0.9003.2446s
[下载连接](http://www.hiwifimi.com/root/%E6%9E%81%E5%A3%B9s2446root.zip)<br>
或者可以手动开启ssh，办法请参考[将固件中ssh开启][sshon]

*如果您的学校是 PPPOE 拨号和 DrCOM 双重认证，请您先在路由器上设置相应的拨号配置*

* 修改/etc/drcom.conf中的认证地址，用户名，密码，和在网络中心注册时填写的mac，注意mac按范例格式写

```python
server = "192.168.100.150" # 这里填写认证服务器ip
username = "" # 上网的用户名
password = "" # 密码
host_name = "LIYUANYUAN" # 改不改无所谓
host_os = "8089D" # 改不改无所谓
host_ip = "10.30.22.17" # 有关这个选项请参考wiki
dhcp_server = "0.0.0.0" # 不用改
mac = 0xb888e3051680 # 学校绑定的mac地址，注意按照左边的格式写，如果您的mac是121212121212，则写成0x121212121212
```


* 可用scp或者ftp的方式，覆盖本压缩包内所有的文件到 / (根目录)
  (windows用户安装winscp，选择scp方式，账号root密码为路由器密码)
  
* 在ssh下执行下列命令(windows下可用putty连接)
  1. opkg update
  2. opkg install python-mini （注意安装的应该是python2.7.3以上的版本）   
  3. chmod +x /usr/bin/dog_drcom 
  
* 重启路由器

*注意：* 由于替换了界面，会失去 app 按钮，您可以通过直接访问 http://app.hiwifi.com 或者通过手机端管理插件等。

# 不改变界面下使用(for Openwrt users)

**适用于不想改动界面的用户或者一切基于 Openwrt 路由的其他用户**

*注意:* 本操作任需要有 *ssh* 权限。手工开启 *ssh* 可以参考[将固件中ssh开启][sshon]

复制以下文件(夹)到路由器上相同目录

```
/usr
/etc/drcom.conf
/etc/opkg.conf
```

* 在ssh下执行下列命令(windows下可用putty连接)
  1. opkg update
  2. opkg install python-mini （注意安装的应该是python2.7.3以上的版本）   
  3. chmod +x /usr/bin/dog_drcom 

*/etc/rc.local* 文件请在 `exit 0;` 之前加入 dog_drcom&

# 检查运行情况

无论是哪种方式安装的本脚本，如果重启后仍然无法上网，您可以通过以下步骤检查问题所在

* 检查 dog_drcom 是否执行
ssh 中执行 `ps | grep dog_drcom` ，看到如同 `3594  root  3248 S  {dog_drcom} /bin/sh /usr/bin/dog_drcom` 说明 *dog_drcom* 正常运行，否则请您检查 `/usr/bin/dog_drcom` 是否有执行权限，或者重新执行 `chmod +x /usr/bin/dog_drcom`

* 检查客户端脚本是否运行
ssh 中执行 `ps | grep python` ，看到如同 ` 3596  root  9064 S  python /usr/bin/wired.py` 说明 *客户端脚本* 正常运行
如无法运行脚本，请检查 *python-mini* 是否已正确安装，`opkg list-installed | grep python-mini`，看到如同 `python-mini - 2.7.3-2` 文字说明安装正确，请您手工执行 `python /usr/bin/wired.py` 将错误信息以各种方式发给我 （Issue和Email都没问题）

* 检查 /etc/drcom.conf 是否配置正确，请参考上方配置说明。已知需要注意的地方见 [wiki链接][wiki]。


如果上述三项检查均通过，而仍然无法上网，请检查您学校的 *DrCOM* 通信版本号，如果为 u3x u2x 或者 0.7,您可以试试另外的一个项目 [jlu-drcom-client](http://github.com/ly0/jlu-drcom-client), 配置方法大同小异。

理论上如果通过了 *drcom-generic-debug-u62.py* , 但是路由器上不通过的情况一般是不存在的，但是如果真的发生了，恳请您将 `/usr/bin/wired.py` 中 `DEBUG = False` 改成 `DEBUG = True` 之后执行如下的命令。

```
killall dog_drcom
kill -9 `ps | grep wired.py | grep python | awk '{print $1}'`
python /usr/bin/wired.py
```

在看到程序执行到稳定时（约20s发生一次变化），或者明显进入死循环时，请`Ctrl+C`结束程序，将 `/var/log/drcom_client.log` 通过 Issue 或者 Email 发给我，并附上您的上网账号密码以及网络环境（包括但不限于如是否固定ip，是否ip-mac绑定，是否需要运行客户端前pppoe拨号等等）。

# 其他事项

* 如果您的学校是 **u62-u64** 但是不能登陆的话，请将您的学校的[截包情况](#wireshark)发给我。
* 有任何问题请在 Issue 里提出
* 欢迎 pull 任何可以让代码更好看一些、容错性能更好些的代码，感激不尽。
* 缺少登出等功能，因为作者比较懒…… 如果您可以提交确认可以用的代码，当然感激不尽。
* 如果您肯花一些时间将其改写成 *C语言* 版本，请一定要通知我。 


<span id="wireshark"></span>
# 关于截包

* 下载 Wireshark 软件
* 尽可能的退出和网络有关的应用程序
* 用 Wireshark 开始截包
* 打开官方客户端，登陆，等待1-2分钟
* 停止截包，将封包保存，连同您的账号密码，ip信息，网络环境等发至[我的邮箱][mail]

我看到邮件后会找时间与您联系。

# Tricks

可以在 `/etc/inittab` 中加入 `::respawn:/usr/bin/dog_drcom` 来防止 **dog_drcom** 挂掉。

[sshon]: http://wenku.baidu.com/view/056fceb84693daef5ff73d15.html
[wiki]: https://github.com/drcoms/HC5661-1s-patch/wiki/-etc-drcom.conf%E6%B3%A8%E6%84%8F%E4%BA%8B%E9%A1%B9
[mail]: latyas@gmail.com
