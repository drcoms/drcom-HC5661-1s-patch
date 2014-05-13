DrCOM FOR HC5661
------------------

# 警告
* 请先确保在PC上使用 *drcom-generic-debug-u62.py* 测试可以上网以后再考虑本补丁
* 所有风险由使用者承担，作者不承担任何法律责任，否则请您不要使用

首先，刷打开了ssh的固件，通俗说为root （详细参考www.hiwifimi.com)，版本 0.9003.2446s <br>
下载连接 http://www.hiwifimi.com/root/%E6%9E%81%E5%A3%B9s2446root.zip

1.修改/etc/drcom.conf中的认证地址，用户名，密码，和在网络中心注册时填写的mac，注意mac按范例格式写

    server = "192.168.100.150" # 这里填写认证服务器ip
    username = "" # 上网的用户名
    password = "" # 密码
    host_name = "LIYUANYUAN" # 改不改无所谓
    host_os = "8089D" # 改不改无所谓
    host_ip = "10.30.22.17" # 改不改无所谓，如果学校给您分配了ip，可以修改此项 
    dhcp_server = "0.0.0.0" # 不用改
    mac = 0xb888e3051680 # 学校绑定的mac地址，注意按照左边的格式写，如果您的mac是121212121212，则写成0x121212121212


2.可用scp或者ftp的方式，覆盖本压缩包内所有的文件到 / (根目录)
  (windows用户安装winscp，选择scp方式，账号root密码为路由器密码)
  
3.在ssh下执行下列命令(windows下可用putty连接)
  1. opkg update
  2. opkg install python-mini （注意安装的应该是python2.7.3以上的版本）   
  3. chmod +x /usr/bin/dog_drcom 
  
4.重启路由器