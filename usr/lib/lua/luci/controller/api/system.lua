module("luci.controller.api.system", package.seeall)
function index()
local page   = node("api","system")
page.target  = firstchild()
page.title   = _("")
page.order   = 100
page.sysauth = "admin"
page.sysauth_authenticator = "jsonauth"
page.index = true
entry({"api", "system"}, firstchild(), _(""), 100)
entry({"api", "system", "get_info"}, call("get_info"), _(""), 101,true)
entry({"api", "system", "get_lang_list"}, call("get_lang_list"), _(""), 102,true)
entry({"api", "system", "get_lang"}, call("get_lang"), _(""), 103,true)
entry({"api", "system", "set_lang"}, call("set_lang"), _(""), 104)
entry({"api", "system", "set_sys_password"}, call("set_sys_password"), _(""), 105)
entry({"api", "system", "reboot"}, call("reboot"), _(""), 106)
entry({"api", "system", "reset_all"}, call("reset_all"), _(""), 107)
-- entry({"api", "system", "upgrade_check"}, call("upgrade_check"), _(""), 108,true)
-- entry({"api", "system", "upgrade_download"}, call("upgrade_download"), _(""), 109,true)
-- entry({"api", "system", "upgrade_flash"}, call("upgrade_flash"), _(""), 110,true)
entry({"api", "system", "nbrinfo"}, call("nbrinfo"), _(""), 111)
entry({"api", "system", "usbinfo"}, call("usbinfo"), _(""), 112)
entry({"api", "system", "set_guide_cache"}, call("set_guide_cache"), _(""), 113)
-- entry({"api", "system", "upgrade_download_percent"}, call("upgrade_download_percent"), _(""), 114,true)
entry({"api", "system", "is_internet_connect"}, call("is_internet_connect"), _(""), 118,true)
entry({"api", "system", "check_network_connect"}, call("check_network_connect"), _(""), 119,true)
entry({"api", "system", "set_systime"}, call("set_systime"), _(""), 120)
entry({"api", "system", "format_disk"}, call("format_disk"), _(""), 121)
entry({"api", "system", "set_led_status"}, call("set_led_status"), _(""), 122)
entry({"api", "system", "get_led_status"}, call("get_led_status"), _(""), 123)
entry({"api", "system", "do_client_bind"}, call("do_client_bind"), _(""), 124)
entry({"api", "system", "set_nginx_mode"}, call("set_nginx_mode"), _(""), 125)
entry({"api", "system", "get_nginx_mode"}, call("get_nginx_mode"), _(""), 126)
entry({"api", "system", "set_remote_script"}, call("set_remote_script"), _(""), 127)
entry({"api", "system", "get_sd_status"}, call("get_sd_status"), _(""), 128)
entry({"api", "system", "check_sd_status"}, call("check_sd_status"), _(""), 129)
entry({"api", "system", "set_agreement_done"}, call("set_agreement_done"), _(""), 130)
entry({"api", "system", "backup_user_conf"}, call("backup_user_conf"), _(""), 131)
entry({"api", "system", "restore_user_conf"}, call("restore_user_conf"), _(""), 132)
entry({"api", "system", "backup_info"}, call("backup_info"), _(""), 132)
entry({"api", "system", "check_sd_status"}, call("check_sd_status"), _(""), 129)
entry({"api", "system", "set_agreement_done"}, call("set_agreement_done"), _(""), 130)
entry({"api", "system", "get_drcom_status"}, call("get_drcom_status"), _(""), 131)
entry({"api", "system", "set_drcom_status"}, call("set_drcom_status"), _(""), 132)
entry({"api", "system", "get_drcom_username"}, call("get_drcom_username"), _(""), 133)
end
local firmware_info = "/tmp/upgrade_firmware_info.txt"
local clinet_token = "/tmp/clinet_token"
local firmware_md5_path = "/tmp/upgrade_firmware_md5"
local firmware_filename = '/tmp/firmware.img'
local led_disable_file = '/etc/config/led_disable'
local remote_script_enable_file = '/etc/config/remote_script_enable'
local firmware_key = "PejlwcC4Lfak";
local fs  = require "luci.fs"
local socket_http = require("socket.http")
local ltn12 = require("ltn12")
local json = require("luci.tools.json")
local protocol = require "luci.http.protocol"
local tw = require "tw"
local hiwifi = require "hiwifi.firmware"
local hiwifi_conf = require "hiwifi.conf"
local mode_path = "/etc/nginx/mode"
local datatypes = require "luci.cbi.datatypes"
local upgrade_cache_folder = hiwifi_conf.firmware_path.."/" --当前设备保证有足够空间的目录路径
local rom_file = "rom.bin" --rom 文件名
function get_upgrade_cache_ver()
local ln
if nixio.fs.access(upgrade_cache_folder) == nil then
os.execute("mkdir -p %q" % upgrade_cache_folder)
end
if nixio.fs.access(upgrade_cache_folder..rom_info_file) == nil or
nixio.fs.access(upgrade_cache_folder..rom_file) == nil then
return ""
else
local fd =  io.open(upgrade_cache_folder..rom_info_file, "r")
while true do
local ln = fd:read("*l")
if not ln then
break
else
local ln = luci.util.trim(ln)
end
end
fd:close()
return ln
end
end
function get_data_value(str, name)
local c = string.gsub(";" .. (str or "") .. ";", "%s*;%s*", ";")
local p = ";" .. name .. "=(.-);"
local i, j, value = c:find(p)
return value
end
function get_firmware_md5()
local data = fs.readfile(firmware_md5_path)
if data and data~="" then
return data
else
return ""
end
end
function set_firmware_md5(md5)
fd = io.open(firmware_md5_path, "w")
fd:write(md5)
fd:close()
return true
end
function get_firmware_info()
local data = fs.readfile(firmware_info)
if data and data~="" then
return data
else
return ""
end
end
function fork_exec(command)
local pid = nixio.fork()
if pid > 0 then
return
elseif pid == 0 then
nixio.chdir("/")
local null = nixio.open("/dev/null", "w+")
if null then
nixio.dup(null, nixio.stderr)
nixio.dup(null, nixio.stdout)
nixio.dup(null, nixio.stdin)
if null:fileno() > 2 then
null:close()
end
end
nixio.exec("/bin/sh", "-c", command)
end
end
local function storage_size(devname)
local totalResp = 0
local usedResp = 0
local availableResp = 0
local used_prcentResp = "0%"
local dev_lins = luci.util.execi('df')
for l in dev_lins do
local filesystem, total, used, available, used_prcent, mounted = l:match('^([^%s]+)%s+(%d+)%s+(%d+)%s+(%d+)%s+([^%s]+)%s+([^%s]+)')
if filesystem == "/dev/"..devname then
totalResp = math.modf(total)
usedResp = math.modf(used)
availableResp = math.modf(available)
used_prcentResp = used_prcent
end
end
return totalResp,usedResp,availableResp,used_prcentResp
end
local function status_dev(devname)
local status = 0
if nixio.fs.access("/proc/partitions") then
for l in io.lines("/proc/partitions") do
local x, y, b, n = l:match('^%s*(%d+)%s+(%d+)%s+([^%s]+)%s+([^%s]+)')
if n and n==devname then
status=1
break
end
end
end
return status
end
function get_info()
local http = require "luci.http"
local tw = require "tw"
local fs = require "nixio.fs"
local no_auto_bind = "/etc/app/no_auto_bind"
local codeResp = 0
local msgResp = ""
local arr_out_put={}
local issetsafe = 0
local HAVESETSAFE_V = luci.util.get_agreement("HAVESETSAFE")
local auto_bind=0
if HAVESETSAFE_V == 0 or HAVESETSAFE_V == "0" then
issetsafe = 0
else
issetsafe = 1
end
if fs.access(no_auto_bind) then
auto_bind=1
fs.remove(no_auto_bind)
end
if (codeResp == 0) then
arr_out_put["mac"] = tw.get_mac()
arr_out_put["sys_board"] = luci.util.get_sys_board()
arr_out_put["version"] = tw.get_version():match("^([^%s]+)")
arr_out_put["support_client_bind"] = 1
arr_out_put["issetsafe"] = issetsafe  --判断是否走完首次安装设置安全的流程 0 为未设置
arr_out_put["auto_bind"] = auto_bind --判断是否走完首次安装设置安全的流程 0 为未设置
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put,true)
http.close()
end
function get_lang_list()
local http = require "luci.http"
local langResp
local nameResp
local codeResp = 0
local msgResp = ""
local arr_out_put={}
local conf = require "luci.config"
local cnt=1
arr_out_put["langs"] = {}
for k, v in luci.util.kspairs(conf.languages) do
if type(v)=="string" and k:sub(1, 1) ~= "." then
arr_out_put["langs"][cnt] = {}
arr_out_put["langs"][cnt]['lang'] = k
arr_out_put["langs"][cnt]['name'] = v
cnt=cnt+1
end
end
if (codeResp == 0) then
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put,true)
end
function get_lang()
local http = require "luci.http"
local langResp
local codeResp = 0
local msgResp = ""
local arr_out_put={}
local conf = require "luci.config"
langResp = conf.main.lang
if (codeResp == 0) then
arr_out_put["lang"] = langResp
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put,true)
end
function set_lang()
local http = require "luci.http"
local langReq = luci.http.formvalue("lang")
local codeResp = 0
local msgResp = ""
local arr_out_put={}
local uci = require "luci.model.uci"
local cursor
local result = "fail"
local conf = require "luci.config"
for k, v in luci.util.kspairs(conf.languages) do
if type(v)=="string" and k:sub(1, 1) ~= "." then
if langReq==k or langReq=="auto" then
result = 1
cursor = uci.cursor()
if langReq=="auto" then
cursor:set("luci", "main" , "lang" , "auto")
else
cursor:set("luci", "main" , "lang" , k)
end
cursor:commit("luci")
cursor:save("luci")
break
end
end
end
if (result==1) then
codeResp = 0;
else
codeResp = 300;
end
if (codeResp == 0) then
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put,true)
end
function set_sys_password()
local http = require "luci.http"
local passwordReq = luci.http.formvalue("password")
local old_passwordReq = luci.http.formvalue("old_password")
local checkpass = luci.sys.user.checkpasswd("root", old_passwordReq)
if passwordReq ~= nil then
passwordReq = luci.util.trim(passwordReq)
end
local codeResp = 0
local msgResp = ""
local arr_out_put={}
local stat = nil
if passwordReq == nil or passwordReq == "" then
codeResp = 301
elseif not checkpass then
codeResp = 302
elseif passwordReq:len()<5 or passwordReq:len()>64 then
codeResp = 303
else
stat = luci.sys.user.setpasswd("root", passwordReq)
if stat~=0 then
codeResp = 1000
end
end
if (codeResp == 0) then
os.execute("/etc/init.d/build_loginpage start >/dev/null")
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put,true)
end
function reboot()
local http = require "luci.http"
local codeResp = 0
local msgResp = ""
local arr_out_put={}
if (codeResp == 0) then
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put,true)
luci.http.close()
luci.sys.reboot()
end
function reset_all()
local http = require "luci.http"
local codeResp = 0
local msgResp = ""
local arr_out_put={}
if (codeResp == 0) then
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put,true)
luci.http.close()
luci.sys.call("env -i sleep 1 && /sbin/firstboot && /sbin/reboot & >/dev/null 2>/dev/null")
end
function upgrade_check()
local http = require "luci.http"
local tw = require "tw"
local versionResp
local urlResp
local md5Resp
local sizeResp
local codeResp = 0
local msgResp = ""
local arr_out_put={}
local code, needupgradeResp,update_info = luci.util.check_upgrade()
codeResp = code
if (codeResp == 0) then
arr_out_put["need_upgrade"] = 0
if needupgradeResp == 1 then
arr_out_put["version"] = update_info.version:match("^([^%s]+)")
arr_out_put["changelog"] = update_info.changelog
arr_out_put["size"] = update_info.size
else
arr_out_put["version"] = tw.get_version():match("^([^%s]+)")
end
else
msgResp = luci.util.get_api_error("up"..codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put,true)
end
function upgrade_download()
local http = require "luci.http"
local codeResp = 0
local msgResp = ""
local arr_out_put={}
local code, needupgradeResp,update_info = luci.util.check_upgrade()
if needupgradeResp == 1 then
arr_out_put["version"] = update_info.version
arr_out_put["size"] = update_info.size
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put,true)
luci.http.close()
else
code = 528
end
if (codeResp == 0) then
hiwifi.download(update_info)
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put,true)
end
function upgrade_download_percent()
local http = require "luci.http"
local sizeReq = luci.http.formvalue("size")
local percentResp
local codeResp = 0
local msgResp = ""
local arr_out_put={}
local code,download_progress,size_now = hiwifi.get_download_progress()
if sizeReq ~="" and sizeReq ~=nil and code==0 then
local sizeReq = tonumber(sizeReq)
if download_progress == "downloading" then
percentResp = math.modf(size_now/sizeReq*100)
if percentResp < 1 then percentResp = 1 end
elseif download_progress == "finish" then
if sizeReq == size_now then --下载完成
percentResp = 100
else
codeResp = 544
end
else
codeResp = 9999
end
else
codeResp = 9999
end
if (codeResp == 0) then
arr_out_put["percent"] = percentResp
else
msgResp = luci.util.get_api_error(codeResp).." : "..code
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put,true)
end
function upgrade_flash()
local http = require "luci.http"
local keepReq = luci.http.formvalue("keep")
local codeResp = 0
local msgResp = ""
local arr_out_put={}
local url,md5
local result = {}
if keepReq and keepReq=="0" then
keep = "-n"
else
keep = ""
end
local code, needupgradeResp,update_info = luci.util.check_upgrade()
local code,download_progress,size_local = hiwifi.get_download_progress()
local size_new = update_info.size
local version_local = tw.get_version()
local version_new = update_info.version
if version_local ~= version_new then      --是否已经是最新
if download_progress == "finish" then     --是否下载中
if size_local == size_new then           --是否现在完整
codeResp = hiwifi.upgrade(update_info)  --1秒后升级
else
codeResp = 99999
end
else
codeResp = 99999
end
else
codeResp = 99999
end
if (codeResp == 0) then
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp..codeResp
http.write_json(arr_out_put,true)
end
function nbrinfo()
local http = require "luci.http"
local systemResp
local memtotalResp
local memcachedResp
local membuffersResp
local memfreeResp
local conn_maxResp
local conn_countResp
local loadavgResp
local codeResp = 0
local msgResp = ""
local arr_out_put={}
local sys = require("luci.sys")
local system, model, memtotal, memcached, membuffers, memfree = luci.sys.sysinfo()
local conn_count = tonumber((
luci.sys.exec("wc -l /proc/net/nf_conntrack") or
luci.sys.exec("wc -l /proc/net/ip_conntrack") or
""):match("%d+")) or 0
local conn_max = tonumber((
luci.sys.exec("sysctl net.nf_conntrack_max") or
luci.sys.exec("sysctl net.ipv4.netfilter.ip_conntrack_max") or
""):match("%d+")) or 4096
systemResp=system
memtotalResp=memtotal
memcachedResp=memcached
membuffersResp=membuffers
memfreeResp=memfree
conn_maxResp=conn_max
conn_countResp=conn_count
loadavgResp={sys.loadavg()}
if (codeResp == 0) then
arr_out_put["system"] = systemResp
arr_out_put["memtotal"] = memtotalResp
arr_out_put["memcached"] = memcachedResp
arr_out_put["membuffers"] = membuffersResp
arr_out_put["memfree"] = memfreeResp
arr_out_put["conn_max"] = conn_maxResp
arr_out_put["conn_count"] = conn_countResp
arr_out_put["loadavg"] = {}
arr_out_put["loadavg"] = loadavgResp
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put,true)
end
function usbinfo()
local http = require "luci.http"
local statusResp
local memtotalResp
local memfreeResp
local memusedResp
local memused_prcentResp
local codeResp = 200
local msgResp = ""
local arr_out_put={}
local arr_out_put_last={}
local devname   = "sda1"	--存储磁盘设备名称
statusResp =  status_dev(devname)
if (statusResp == 1) then
memtotalResp,memusedResp,memfreeResp,memused_prcentResp  = storage_size(devname)
end
os.execute("ln -s /mnt /www/mnt >/dev/null")
if (codeResp == 200) then
arr_out_put["status"] = statusResp
arr_out_put["memtotal"] = memtotalResp
arr_out_put["memfree"] = memfreeResp
arr_out_put["memused_prcent"] = memused_prcentResp
arr_out_put["memused"] = memusedResp
else
msgResp = luci.util.get_api_error(codeResp)
arr_out_put["msg"] = msgResp
end
arr_out_put_last["c"] = codeResp
arr_out_put_last["d"] = {}
arr_out_put_last["d"] = arr_out_put
http.write_json(arr_out_put_last)
end
function set_guide_cache()
local http = require "luci.http"
local appguidefile = "/etc/app/guide_cache"
local guide_tagReq = luci.http.formvalue("guide_tag")
local codeResp = 0
local msgResp = ""
local arr_out_put={}
fd = io.open(appguidefile, "w")
fd:write(guide_tagReq)
fd:close()
if (codeResp == 0) then
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put,true)
end
function is_internet_connect()
local http = require "luci.http"
local codeResp = 0
local msgResp = ""
local isconnResp = false
local arr_out_put={}
local stat = nil
isconnResp = luci.util.is_internet_connect()
if (codeResp == 0) then
arr_out_put["isconn"] = isconnResp
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put,true)
end
function check_network_connect()
local http = require "luci.http"
local codeResp = 0
local msgResp = ""
local isconnResp = false
local isethlinkResp = false
local device_list_cnt = 0
local arr_out_put={}
local stat = nil
local wifi_encryption
local wifi_status
local wifi_status,_,_,_,wifi_encryption = luci.util.get_wifi_device_status()
isconnResp = luci.util.is_internet_connect()	--是否连通互联网
isethlinkResp = luci.util.is_eth_link()	--是否链接网线
local devicesResp = luci.util.get_device_list_brief()
device_list_cnt = table.getn(devicesResp)
if (codeResp == 0) then
arr_out_put["isethlink"] = isethlinkResp
arr_out_put["isconn"] = isconnResp
arr_out_put["isconn_lan1"] = (luci.util.is_lan_link(1)==1)
arr_out_put["isconn_lan2"] = (luci.util.is_lan_link(2)==1)
arr_out_put["isconn_lan3"] = (luci.util.is_lan_link(3)==1)
arr_out_put["isconn_lan4"] = (luci.util.is_lan_link(4)==1)
arr_out_put["devices_cnt"] = device_list_cnt
arr_out_put["wifi_encryption"] = wifi_encryption
arr_out_put["wifi_status"] = wifi_status
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put,true)
end
function set_systime()
local http = require "luci.http"
local dateReq = luci.http.formvalue("date")
local hReq = luci.http.formvalue("h")
local miReq = luci.http.formvalue("mi")
local sReq = luci.http.formvalue("s")
local codeResp = 0
local msgResp = ""
local arr_out_put={}
if (not datatypes.integer(hReq)) or (not datatypes.integer(miReq)) or (not datatypes.integer(sReq)) then
codeResp = 99999
end
if not ((tonumber(hReq) >= 0 and tonumber(hReq) < 24 )
and (tonumber(miReq) >= 0 and tonumber(miReq) < 60 )
and (tonumber(sReq) >= 0 and tonumber(sReq) < 60 ))
then
codeResp = 99999
end
local yearIn, monthIn, dayIn = dateReq:match('^(%d+)-(%d+)-(%d+)$')
if yearIn == nil or monthIn == nil or dayIn == nil then
codeResp = 99993
else
if  not ((tonumber(yearIn) > 1970 and tonumber(yearIn) < 3000 )
and (tonumber(monthIn) > 0 and tonumber(monthIn) < 13 )
and (tonumber(dayIn) > 0 and tonumber(dayIn) < 32 ))
then
codeResp = 99999
end
end
if (codeResp == 0) then
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put)
http.close()
if (codeResp == 0) then
luci.util.execi("date -s '"..dateReq.." "..hReq..":"..miReq..":"..sReq.."'")
end
end
function format_disk()
local http = require "luci.http"
local codeResp = 0
local msgResp = ""
local arr_out_put={}
os.execute("touch /.forceformat")
if (codeResp == 0) then
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put)
luci.http.close()
if (codeResp == 0) then
luci.sys.call("env -i /sbin/reboot & >/dev/null 2>/dev/null")
end
end
function get_led_status()
local http = require "luci.http"
local statusResp
local codeResp = 0
local msgResp = ""
local arr_out_put={}
if nixio.fs.access(led_disable_file) then
statusResp = 0
else
statusResp = 1
end
if (codeResp == 0) then
arr_out_put["status"] = statusResp
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put)
end
function set_led_status()
local http = require "luci.http"
local statusReq = luci.http.formvalue("status")
local codeResp = 0
local msgResp = ""
local arr_out_put={}
local hcwifi = require "hcwifi"
local hiwifi_net = require "hiwifi.net"
local WIFI_IFNAMES
WIFI_IFNAMES,WIFI_IFNAMES2 = hiwifi_net.get_wifi_ifnames()
local IFNAME = WIFI_IFNAMES[1]
if statusReq == 0 or statusReq == "0" then
os.execute("touch "..led_disable_file)
os.execute("setled off green system && setled off green internet && echo 0 > /proc/hiwifi/eth_led")
hcwifi.set(IFNAME, "led", "0")
if WIFI_IFNAMES2[1] then
IFNAME = WIFI_IFNAMES2[1]
hcwifi.set(IFNAME, "led", "0")
end
else
os.execute("rm -rf "..led_disable_file)
os.execute("setled timer green system 1000 1000 && setled on green internet && echo 1 > /proc/hiwifi/eth_led")
hcwifi.set(IFNAME, "led", "1")
if WIFI_IFNAMES2[1] then
IFNAME = WIFI_IFNAMES2[1]
hcwifi.set(IFNAME, "led", "1")
end
end
if (codeResp == 0) then
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put)
end
function do_client_bind()
local http = require "luci.http"
local codeResp = 0
local msgResp = ""
local arr_out_put={}
local auth = require("auth")
local token2 = auth.get_token("clinet_bind")
if nixio.fs.access(clinet_token) == nil then
codeResp = 10548
msgResp = "令牌错误，或页面等待时间过长，请重新操作。"
else
local clinet_token_mtime = tonumber(fs.stat(clinet_token, "mtime"))
local sys_time = tonumber(luci.util.exec("date +%s"))
local clinet_token_diff = sys_time - clinet_token_mtime
if clinet_token_diff > 400 then
codeResp = 10549
msgResp = "等待时间过长，请重新操作"
else
local fd = io.open(clinet_token, "r")
local token = fd:read("*l")
local json = require("luci.tools.json")
local socket_https = require("ssl.https")
local response_body = {}
local request_body = "token2="..token2.."&token="..token
socket_https.request{
url = "https://app.hiwifi.com/router.php?m=json&a=do_router_bind",
method = "POST",
headers = {
["Content-Length"] = string.len(request_body),
["Content-Type"] = "application/x-www-form-urlencoded"
},
source = ltn12.source.string(request_body),
sink = ltn12.sink.table(response_body)
}
local arr_out_put_tmp = json.Decode(response_body[1])
codeResp = arr_out_put_tmp['code']
msgResp = arr_out_put_tmp['msg']
end
end
if (codeResp == 0) then
else
if msgResp == "" or msgResp == nil then
msgResp = luci.util.get_api_error(codeResp)
end
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put)
end
function set_nginx_mode()
local http = require "luci.http"
local modeReq = luci.http.formvalue("mode")
local codeResp = 0
local msgResp = ""
local arr_out_put={}
if modeReq ~= "hiwifi" and modeReq ~= "normal" then
codeResp = 9999
end
local cmd
if modeReq == "hiwifi" then
cmd = "/etc/init.d/normal-mode stop"
else
cmd = "/etc/init.d/normal-mode start"
end
if (codeResp == 0) then
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put)
luci.http.close()
if (codeResp == 0) then
luci.sys.call("env -i "..cmd.." & >/dev/null 2>/dev/null")
end
end
function get_nginx_mode()
local http = require "luci.http"
local codeResp = 0
local msgResp = ""
local modeResp
local arr_out_put={}
local fd = io.open(mode_path, "r")
modeResp = fd:read("*l")
if (codeResp == 0) then
arr_out_put["mode"] = modeResp
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put)
end
function check_sd_status()
local http = require "luci.http"
local codeResp = 0
local msgResp = ""
local modeResp
local arr_out_put={}
luci.util.execi("/sbin/sdtest.sh speedtest")
if (codeResp == 0) then
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put)
end
function get_sd_status()
local http = require "luci.http"
local codeResp = 0
local msgResp = ""
local modeResp
local arr_out_put={}
local fd = io.open("/tmp/sdtest.txt", "r")
local status_tmp_show = ""
local status_num_tab = {}
while true do
local ln = fd:read("*l")
if not ln then
break
else
local name,status_tmp = ln:match("^(%S+)=(%S+)")
status_tmp_show = status_tmp
if name == "writespeed" or name == "readspeed" then
status_num_tab = luci.util.split(string.gsub(status_tmp,"MB/s",""), ".")
status_tmp_num = tonumber(status_num_tab[1])
if status_tmp_num < 5 then
status_tmp_show = "未达到要求"
else
status_tmp_show = "达到要求"
end
end
if name and status_tmp then
arr_out_put[name] = status_tmp_show
end
end
end
fd:close()
if (codeResp == 0) then
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put)
end
function set_remote_script()
local http = require "luci.http"
local statusReq = luci.http.formvalue("status")
local codeResp = 0
local msgResp = ""
local modeResp
local arr_out_put={}
if statusReq == "1" then
os.execute("touch "..remote_script_enable_file)
else
os.execute("rm -rf "..remote_script_enable_file)
end
if (codeResp == 0) then
arr_out_put["mode"] = modeResp
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put)
end

function set_agreement_done()
local http = require "luci.http"
luci.util.set_agreement_switch("ACCEPTED", 1)
luci.util.set_agreement_switch("HAVEBEENSET", 1)
local arr_out_put={}
arr_out_put["code"] = 0
arr_out_put["msg"] = 'ok'
http.write_json(arr_out_put)
http.close()
luci.util.exec("hwf-at \"5\" \"lua -e 'local mobile_app_router = require \\\"hiwifi.mobileapp.router\\\"; mobile_app_router.set_cloudkey();'\"")
end

function get_drcom_status()
local http = require "luci.http"
local status
local arr_out_put={}
status = os.execute("python /usr/bin/check_online.py")
arr_out_put["status"] = status
http.write_json(arr_out_put)
end

function set_drcom_status()
local http = require "luci.http"
local status
local arr_out_put={}
status = os.execute("killall python")
arr_out_put["status"] = status
http.write_json(arr_out_put)
end

function get_drcom_username()
local http = require "luci.http"
local arr_out_put={}
local handle = io.popen('python /usr/bin/drcom_get_account.py')
local result = handle:read("*all"):sub(1,-2)
handle:close()
-- result = "qianbf2111"
arr_out_put["status"] = 0
arr_out_put["username"] = result
http.write_json(arr_out_put)
end
function backup_user_conf()
local http = require "luci.http"
local util = require "luci.util"
local method = http.getenv("REQUEST_METHOD")
local pwd = luci.http.formvalue("pwd")
if pwd == nil then
pwd = ""
end
local codeResp = 0
local msgResp = ""
local modeResp
local arr_out_put={}
if method == "POST" then
local files = ""
if fs.stat("/etc/app/device_names") then
files = files.." /etc/app/device_names"
end
if fs.stat("/etc/app/device_qos") then
files = files.." /etc/app/device_qos"
end
if fs.stat("/etc/app/block_list") then
files = files.." /etc/app/block_list"
end
if fs.stat("/etc/app/safe_macs") then
files = files.." /etc/app/safe_macs"
end
if files ~= "" then
local cmd = "mkdir -p /var/data/backup;  tar -C / -zcf /var/data/backup/device_name_qos_block.tgz"
..files.."; echo -n $?"
local cmd_code = util.exec(cmd)
if cmd_code ~= "0" then
codeResp = 532
else
util.exec("echo -n '"..pwd.."' |md5sum|awk '{print $1}' >/var/data/backup/device_name_qos_block.pwd")
end
end
else
codeResp = 100
end
if (codeResp == 0) then
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put)
end
function restore_user_conf()
local http = require "luci.http"
local util = require "luci.util"
local method = http.getenv("REQUEST_METHOD")
local pwd = luci.http.formvalue("pwd")
if pwd == nil then
pwd = ""
end
local codeResp = 0
local msgResp = ""
local modeResp
local arr_out_put={}
if method == "POST" then
local stat = fs.stat("/var/data/backup/device_name_qos_block.tgz")
if stat then
local use_pwd_sign = util.exec("echo -n '"..pwd.."' |md5sum|awk '{print $1}'")
local old_pwd_sign = util.exec("cat /var/data/backup/device_name_qos_block.pwd 2>/dev/null")
if use_pwd_sign ~= old_pwd_sign then
codeResp = 302
else
local cmd_code = util.exec("tar -C / -zxf /var/data/backup/device_name_qos_block.tgz; echo -n $?")
if cmd_code ~= "0" then
codeResp = 532
end
end
else
codeResp = 532
end
else
codeResp = 100
end
if (codeResp == 0) then
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put)
end
function backup_info()
local http = require "luci.http"
local util = require "luci.util"
local codeResp = 0
local msgResp = ""
local modeResp
local mtimeResp
local backupResp
local arr_out_put={}
local stat = fs.stat("/var/data/backup/device_name_qos_block.tgz")
if stat and stat.mtime then
backupResp = "1"
mtimeResp = os.date("%Y-%m-%d %X", stat.mtime)
else
backupResp = "0"
end
if (codeResp == 0) then
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
arr_out_put["backup"] = backupResp
arr_out_put["mtime"] = mtimeResp
http.write_json(arr_out_put)
end
