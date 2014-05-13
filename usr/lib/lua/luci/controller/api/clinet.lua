module("luci.controller.api.clinet", package.seeall)
function index()
local page   = node("api","clinet")
page.target  = firstchild()
page.title   = _("")
page.order   = 170
page.sysauth = "admin"
page.sysauth_authenticator = "jsonauth"
page.index = true
entry({"api", "clinet"}, firstchild(), _(""), 170)
entry({"api", "clinet", "get_mobi_list_info"}, call("get_mobi_list_info"), _(""), 171)
entry({"api", "clinet", "get_mobi_view_info"}, call("get_mobi_view_info"), _(""), 172)
entry({"api", "clinet", "get_mobi_view_info_out"}, call("get_mobi_view_info_out"), _(""), 173)		--3.0 外部状态,成就,健康状态，设备数等
entry({"api", "clinet", "get_mobi_view_info_out_40"}, call("get_mobi_view_info_out_40"), _(""), 173)		--3.0 外部状态,成就,健康状态，设备数等
entry({"api", "clinet", "get_traffic"}, call("get_traffic"), _(""), 173)		--3.0 外部状态,成就,健康状态，设备数等
entry({"api", "clinet", "get_traffic_list"}, call("get_traffic_list"), _(""), 173)		--3.0 外部状态,成就,健康状态，设备数等
entry({"api", "clinet", "get_mobi_health"}, call("get_mobi_health"), _(""), 174)		--3.0 外部状态,成就,健康状态，设备数等
entry({"api", "clinet", "set_safe_key"}, call("set_safe_key"), _(""), 175)
entry({"api", "clinet", "get_part_speedup_list"}, call("get_part_speedup_list"), _(""), 175)
entry({"api", "clinet", "set_part_speedup"}, call("set_part_speedup"), _(""), 175)
entry({"api", "clinet", "cancel_part_speedup"}, call("cancel_part_speedup"), _(""), 175)
end
local DEVICES_SPEEDUP_TIME_DEFULT = 3600	  --second
local DEVICES_SPEEDUP_LOWEST_DEFULT = 20  --KB/S
local DEVICES_SPEEDUP_PERCENT_DEFULT = 99
function get_mobi_list_info()
local http = require "luci.http"
local need_upgradeResp
local versionResp
local changelogResp
local sizeResp
local ssidResp
local uptimeResp
local codeResp = 0
local msgResp = ""
local arr_out_put={}
local tw = require "tw"
local _,_,_,ssidResp = luci.util.get_wifi_device_status()
versionResp = tw.get_version():match("^([^%s]+)")
uptimeResp = luci.util.get_uptime()
if (codeResp == 0) then
arr_out_put["version"] = versionResp
arr_out_put["uptime"] = uptimeResp
arr_out_put["ssid"] = ssidResp
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put)
end
function get_mobi_view_info()
local http = require "luci.http"
local ios_client_ver = luci.http.formvalue("ios_client_ver")
local traffic_upResp
local traffic_downResp
local wifi_swich_statusResp
local wifi_txpwr_statusResp = 0
local device_cntResp
local rom_versionResp
local ssidResp
local led_statusResp
local codeResp = 0
local msgResp = ""
local arr_out_put={}
local traffic_stats = require "hiwifi.traffic_stats"
local traffic_stats_now = traffic_stats.read_stats()
traffic_upResp = traffic_stats_now['tx_bps']
traffic_downResp = traffic_stats_now['rx_bps']
local wifi_swich_status = luci.util.get_wifi_device_status()
local netmd = require "luci.model.network".init()
local net = netmd:get_wifinet("radio0.network1")
local txpwrResp
local t_time = luci.util.get_day_begin_time()
local his_td = luci.util.get_time_his_device_list(t_time)
local traffic_today_cnt = table.getn(his_td)
if net then
if net:active_mode()=='Master' then
txpwrResp = tostring(net:txpwr())
if txpwrResp == "140" then
wifi_txpwr_statusResp = 1
end
end
end
local devices = luci.util.get_device_list_brief()
device_cntResp = table.getn(devices)
local led_disable_file = '/etc/config/led_disable'
if nixio.fs.access(led_disable_file) then
led_statusResp = 0
else
led_statusResp = 1
end
_,_,_,ssidResp = luci.util.get_wifi_device_status()
rom_versionResp = tw.get_version():match("^([^%s]+)")
local _,rpt_cnt = luci.util.get_mac_rpt_hash()
if (codeResp == 0) then
arr_out_put["traffic_up"] = traffic_upResp
arr_out_put["traffic_down"] = traffic_downResp
arr_out_put["wifi_swich_status"] = tonumber(wifi_swich_status)
arr_out_put["wifi_txpwr_status"] = wifi_txpwr_statusResp
arr_out_put["led_status"] = led_statusResp
arr_out_put["rpt_cnt"] = rpt_cnt
arr_out_put["traffic_cnt"] = traffic_today_cnt
arr_out_put["device_cnt"] = device_cntResp
arr_out_put["rom_version"] = rom_versionResp
arr_out_put["ssid"] = ssidResp
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put)
end
function get_mobi_view_info_out()
local http = require "luci.http"
local ios_client_ver = luci.http.formvalue("ios_client_ver")
local wifi_sleep_startResp = 0
local wifi_sleep_endResp = 0
local device_cntResp
local codeResp = 0
local msgResp = ""
local arr_out_put={}
local devices = luci.util.get_device_list_brief()
device_cntResp = table.getn(devices)
local start_tmp,end_tmp = luci.util.get_wifi_sleep()
if start_tmp then
wifi_sleep_startResp,wifi_sleep_endResp = start_tmp,end_tmp
end
if (codeResp == 0) then
arr_out_put["wifi_sleep_start"] = wifi_sleep_startResp
arr_out_put["wifi_sleep_end"] = wifi_sleep_endResp
arr_out_put["device_cnt"] = device_cntResp
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put)
end
function get_mobi_view_info_out_40()
local http = require "luci.http"
local ios_client_ver = luci.http.formvalue("ios_client_ver")
local wifi_sleep_startResp = 0
local wifi_sleep_endResp = 0
local traffic_upResp
local traffic_downResp
local traffic
local wifi_swich_statusResp
local wifi_txpwr_statusResp = 0
local device_cntResp
local rom_versionResp
local ssidResp
local led_statusResp
local codeResp = 0
local msgResp = ""
local arr_out_put={}
local start_tmp,end_tmp = luci.util.get_wifi_sleep()
if start_tmp then
wifi_sleep_startResp,wifi_sleep_endResp = start_tmp,end_tmp
end
local wifi_swich_status = luci.util.get_wifi_device_status()
local netmd = require "luci.model.network".init()
local net = netmd:get_wifinet("radio0.network1")
local txpwrResp
if net then
if net:active_mode()=='Master' then
txpwrResp = tostring(net:txpwr())
if txpwrResp == "140" then
wifi_txpwr_statusResp = 1
end
end
end
local led_disable_file = '/etc/config/led_disable'
if nixio.fs.access(led_disable_file) then
led_statusResp = 0
else
led_statusResp = 1
end
_,_,_,ssidResp = luci.util.get_wifi_device_status()
rom_versionResp = tw.get_version():match("^([^%s]+)")
local _,rpt_cnt = luci.util.get_mac_rpt_hash()
if (codeResp == 0) then
arr_out_put["wifi_sleep_start"] = wifi_sleep_startResp
arr_out_put["wifi_sleep_end"] = wifi_sleep_endResp
arr_out_put["np"] = "" --TODO
arr_out_put["wifi_swich_status"] = tonumber(wifi_swich_status)
arr_out_put["wifi_txpwr_status"] = wifi_txpwr_statusResp
arr_out_put["led_status"] = led_statusResp
arr_out_put["rpt_cnt"] = rpt_cnt
arr_out_put["rom_version"] = rom_versionResp
arr_out_put["ssid"] = ssidResp
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put)
end
function get_traffic_list()
local http = require "luci.http"
local ios_client_ver = luci.http.formvalue("ios_client_ver")
local traffic
local traffic_upResp
local traffic_downResp
local codeResp = 0
local msgResp = ""
local arr_out_put={}
local traffic_stats = require "hiwifi.traffic_stats"
local traffic_stats_now = traffic_stats.read_stats()
traffic_upResp = traffic_stats_now['tx_bps']
traffic_downResp = traffic_stats_now['rx_bps']
if (codeResp == 0) then
arr_out_put["traffic"] = traffic_upResp + traffic_downResp
arr_out_put["traffic_list"] = {-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1}
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put)
end
function get_traffic()
local http = require "luci.http"
local ios_client_ver = luci.http.formvalue("ios_client_ver")
local traffic
local traffic_upResp
local traffic_downResp
local codeResp = 0
local msgResp = ""
local arr_out_put={}
local traffic_stats = require "hiwifi.traffic_stats"
local traffic_stats_now = traffic_stats.read_stats()
traffic_upResp = traffic_stats_now['tx_bps']
traffic_downResp = traffic_stats_now['rx_bps']
if (codeResp == 0) then
arr_out_put["traffic"] = traffic_upResp + traffic_downResp
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put)
end
function get_mobi_health()
local http = require "luci.http"
local ios_client_ver = luci.http.formvalue("ios_client_ver")
local wifi_sleep_startResp = 0
local wifi_sleep_endResp = 0
local led_statusResp
local codeResp = 0
local msgResp = ""
local arr_out_put={}
local start_tmp,end_tmp = luci.util.get_wifi_sleep()
if start_tmp then
wifi_sleep_startResp,wifi_sleep_endResp = start_tmp,end_tmp
end
local led_disable_file = '/etc/config/led_disable'
if nixio.fs.access(led_disable_file) then
led_statusResp = 0
else
led_statusResp = 1
end
if (codeResp == 0) then
arr_out_put["wifi_sleep_start"] = wifi_sleep_startResp
arr_out_put["wifi_sleep_end"] = wifi_sleep_endResp
arr_out_put["led_status"] = led_statusResp
arr_out_put["device_cnt"] = device_cntResp
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put)
end
function set_safe_key()
local http = require "luci.http"
local codeResp = 0
local msgResp = ""
local arr_out_put={}
local ios_client_ver = luci.http.formvalue("ios_client_ver")
local passwordReq = luci.http.formvalue("password")
local wifikeyReq = luci.http.formvalue("wifikey")
local actidResp = luci.http.formvalue("actid")
local need_restart_wifi = false
local is_safe_now
local wifikey_score_after_optimize=13
local password_score_after_optimize=17
if wifikeyReq ~= nil then
local deviceReq = "radio0.network1"
local keyReq = wifikeyReq
local encryptionReq = "mixed-psk"
is_safe_now = 0
local netmd = require "luci.model.network".init()
local net = netmd:get_wifinet(deviceReq)
local req_ok = true
local _,_,_,_,wifi_encryption = luci.util.get_wifi_device_status()
if wifi_encryption ~= "none" then
is_safe_now=1
wifikey_score_after_optimize = 0
end
if net then
if  keyReq:len()<8 or keyReq:len()>63 then
req_ok = false
codeResp = 405
end
if req_ok==true then 	--请求正常
if ssidReq~=nil and ssidReq~="" then
net:set("ssid",ssidReq)
end
if keyReq~=nil then
net:set("encryption",encryptionReq)
net:set("key",keyReq)
end
netmd:commit("wireless")
netmd:save("wireless")
end
else
codeResp = 401
end
local mobile_base = require("hiwifi.mobileapp.base")
local json = require("luci.tools.json")
local result_json = mobile_base.mobile_app_curl("Exam/doOptimize",
{
actid=actidResp,
item_id=501,
is_safe_now=is_safe_now
})
need_restart_wifi = true
arr_out_put["wifikey_score_after_optimize"] = password_score_after_optimize
arr_out_put["wifikey_remark_after_optimize"] = "安全"
end
if passwordReq ~= nil then
is_safe_now = 0
local is_defult_password = luci.sys.user.checkpasswd("root", "admin")
if not is_defult_password then
is_safe_now=1
password_score_after_optimize = 0
end
if passwordReq == "" then
codeResp = 301
elseif passwordReq:len()<5 or passwordReq:len()>64 then
codeResp = 303
else
local stat = luci.sys.user.setpasswd("root", passwordReq)
if stat~=0 then
codeResp = 1000
end
end
local mobile_base = require("hiwifi.mobileapp.base")
local json = require("luci.tools.json")
local result_json = mobile_base.mobile_app_curl("Exam/doOptimize",
{
actid=actidResp,
item_id=502,
is_safe_now=is_safe_now
})
arr_out_put["password_score_after_optimize"] = 17
arr_out_put["password_remark_after_optimize"] = "安全"
end
if (codeResp == 0) then
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put)
http.close()
if need_restart_wifi then
local net = require "hiwifi.net"
if not net.get_wifi_bridge() then --桥接状态下 ifup wan 包含  wifi 命令
luci.util.delay_exec_wifi(5)
else
luci.util.delay_exec_ifwanup(5)
end
end
end
function get_part_speedup_list()
local http = require "luci.http"
local ios_client_ver = luci.http.formvalue("ios_client_ver")
local codeResp = 0
local msgResp = ""
local arr_out_put={}
local list={}
if (codeResp == 0) then
arr_out_put["list"] = {}
local device_list = luci.util.get_device_list_brief()
local net = require "hiwifi.net"
local mac_name_hash = {}
local dhcp_devicesResp = net.get_dhcp_client_list()
if dhcp_devicesResp then
for _, net in ipairs(dhcp_devicesResp) do
mac_name_hash[net['mac']] = net['name']
end
end
local re_name
local device_names = require "hiwifi.device_names"
local device_name_all = device_names.get_all()
table.foreach(device_name_all, function(mac_one, re_name)
mac_name_hash[mac_one] = re_name
end)
local part_speedup = require("hiwifi.mobileapp.part_speedup")
local mac_ing,time_ing = part_speedup.get_device_speedup()
local real_name
for i,device in ipairs(device_list) do
if not mac_name_hash[device["mac"]] or mac_name_hash[device["mac"]] == "" then
real_name = "未知"
else
real_name = mac_name_hash[device["mac"]]
end
arr_out_put["list"][i] = {}
arr_out_put["list"][i]["item_id"] = device["mac"]
arr_out_put["list"][i]["rpt"] = device["rpt"]
arr_out_put["list"][i]["name"] = real_name
arr_out_put["list"][i]["icon"] = "http://s.hiwifi.com/m/pc_icon.png"
arr_out_put["list"][i]["time_total"] = DEVICES_SPEEDUP_TIME_DEFULT
arr_out_put["list"][i]["time_over"] = DEVICES_SPEEDUP_TIME_DEFULT
arr_out_put["list"][i]["status"] = 0
if mac_ing then
if string.lower(mac_ing) == string.lower(device["mac"])then
arr_out_put["list"][i]["time_over"] = time_ing
arr_out_put["list"][i]["status"] = 1
end
end
end
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put)
end
function set_part_speedup()
local http = require "luci.http"
local ios_client_ver = luci.http.formvalue("ios_client_ver")
local item_id = luci.http.formvalue("item_id")
local part_speedup = require("hiwifi.mobileapp.part_speedup")
part_speedup.set_device_speedup(item_id,DEVICES_SPEEDUP_PERCENT_DEFULT,DEVICES_SPEEDUP_TIME_DEFULT,DEVICES_SPEEDUP_LOWEST_DEFULT)
local codeResp = 0
local msgResp = ""
local arr_out_put={}
if (codeResp == 0) then
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put)
end
function cancel_part_speedup()
local http = require "luci.http"
local ios_client_ver = luci.http.formvalue("ios_client_ver")
local item_id = luci.http.formvalue("item_id")
local part_speedup = require("hiwifi.mobileapp.part_speedup")
part_speedup.cancel_device_speedup(item_id)
local codeResp = 0
local msgResp = ""
local arr_out_put={}
if (codeResp == 0) then
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put)
end
