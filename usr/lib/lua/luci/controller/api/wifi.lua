module("luci.controller.api.wifi", package.seeall)
function index()
local page   = node("api","wifi")
page.target  = firstchild()
page.title   = _("")
page.order   = 140
page.sysauth = "admin"
page.sysauth_authenticator = "jsonauth"
page.index = true
local guide_access_tag
local HAVRESETWIFI_V = luci.util.get_agreement("HAVRESETWIFI")
if HAVRESETWIFI_V == 0 or HAVRESETWIFI_V == "0" then
guide_access_tag = true
else
guide_access_tag = false
end
entry({"api", "wifi"}, firstchild(), _(""), 140)
entry({"api", "wifi", "get_status_list"}, call("get_status_list"), _(""), 141,true)
entry({"api", "wifi", "view_detail"}, call("view_detail"), _(""), 142)
entry({"api", "wifi", "get_connected_devices_list"}, call("get_connected_devices_list"), _(""), 143)
entry({"api", "wifi", "restart"}, call("restart"), _(""), 144,guide_access_tag)
entry({"api", "wifi", "reconnect"}, call("reconnect"), _(""), 144)
entry({"api", "wifi", "shutdown"}, call("shutdown"), _(""), 145)
entry({"api", "wifi", "set_base"}, call("set_base"), _(""), 146)
entry({"api", "wifi", "get_channel"}, call("get_channel"), _(""), 147,true)
entry({"api", "wifi", "set_channel"}, call("set_channel"), _(""), 148)
entry({"api", "wifi", "get_scan_list"}, call("get_scan_list"), _(""), 149,true)
entry({"api", "wifi", "get_safe_macs"}, call("get_safe_macs"), _(""), 150,true)
entry({"api", "wifi", "set_safe_macs"}, call("set_safe_macs"), _(""), 151)
entry({"api", "wifi", "del_safe_macs"}, call("del_safe_macs"), _(""), 152)
entry({"api", "wifi", "get_mac_filter_list"}, call("get_mac_filter_list"), _(""), 153)
entry({"api", "wifi", "set_mac_filter"}, call("set_mac_filter"), _(""), 154)
entry({"api", "wifi", "get_txpwr"}, call("get_txpwr"), _(""), 155, true)
entry({"api", "wifi", "set_txpwr"}, call("set_txpwr"), _(""), 156)
entry({"api", "wifi", "wifi_ctl_scan"}, call("wifi_ctl_scan"), _(""), 157)
entry({"api", "wifi", "get_aplist"}, call("get_aplist"), _(""), 158)
entry({"api", "wifi", "get_bridge"}, call("get_bridge"), _(""), 160,true)
entry({"api", "wifi", "set_bridge"}, call("set_bridge"), _(""), 161)
entry({"api", "wifi", "del_bridge_history"}, call("del_bridge_history"), _(""), 161)
entry({"api", "wifi", "save_mac_filter"}, call("save_mac_filter"), _(""), 162)
entry({"api", "wifi", "load_mac_filter"}, call("load_mac_filter"), _(""), 163)
entry({"api", "wifi", "set_wifi_sleep"}, call("set_wifi_sleep"), _(""), 164)
entry({"api", "wifi", "get_wifi_sleep"}, call("get_wifi_sleep"), _(""), 165)
entry({"api", "wifi", "get_channel_rank"}, call("get_channel_rank"), _(""), 167, true)
end
local hiwifi_net = require "hiwifi.net"
local WIFI_IFNAMES
local wifi_sleep_status_file = "/etc/app/wifi_sleep.status"
function get_status_list()
local http = require "luci.http"
local statusResp = {}
local codeResp = 0
local msgResp = ""
local arr_out_put={}
local status = require "luci.tools.status"
local wifi_ssid = ""
local cnt=1
if status then
for i,user in ipairs(status:wifi_networks()) do
local network_index = 1
local device = user["device"]
local wifi_ssid = user["networks"][network_index]["ssid"]
statusResp[cnt] = {}
statusResp[cnt]['device'] = device..".network"..network_index
statusResp[cnt]['wifi_ssid'] = wifi_ssid
if user["up"] then
statusResp[cnt]['status'] = 1
else
statusResp[cnt]['status'] = 0
end
cnt=cnt+1
end
else
codeResp = -1
end
if (codeResp == 0) then
arr_out_put["device_status"] = {}
arr_out_put["device_status"] = statusResp
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put,true)
end
function view_detail()
local http = require "luci.http"
local deviceReq = luci.http.formvalue("device")
local deviceResp
local ssidResp
local ssidprefixResp
local modeResp
local encryptionResp
local wifi_keyResp
local statusResp
local signalResp
local qualityResp
local speedResp
local hiddenResp
local channelResp
local codeResp = 0
local msgResp = ""
local arr_out_put={}
local s    = require "luci.tools.status"
local rv   = { }
local dev
for dev in deviceReq:gmatch("[%w%.%-]+") do
rv[#rv+1] = s.wifi_network(dev)
end
if #rv > 0 then
ssidResp = rv[1]['ssid']
ssidprefixResp = rv[1]['ssidprefix']
channelResp = rv[1]['channel']
if(rv[1]['up']) then
statusResp = 1
else
statusResp = 0
end
speedResp = rv[1]['bitrate']
encryptionResp = rv[1]['encryption']
modeResp = rv[1]["mode"]
encryptionResp = rv[1]["encryption_src"]
hiddenResp = rv[1]["hidden"]
wifi_keyResp = rv[1]["key"]
signalResp  =  rv[1]["signal"]
qualityResp =  rv[1]["quality"]
deviceResp = deviceReq
if encryptionResp == "wep-open" then
wifi_keyResp = rv[1]["key1"]
if wifi_keyResp:len()>4 and wifi_keyResp:sub(0,2)=="s:" then
wifi_keyResp = wifi_keyResp:sub(3)
end
end
else
codeResp = 401
end
if (codeResp == 0) then
arr_out_put["device"] = deviceResp
arr_out_put["ssid"] = ssidResp
arr_out_put["ssidprefix"] = ssidprefixResp
arr_out_put["mode"] = modeResp
arr_out_put["encryption"] = encryptionResp
arr_out_put["wifi_key"] = wifi_keyResp
arr_out_put["status"] = statusResp
arr_out_put["signal"] = signalResp
arr_out_put["quality"] = qualityResp
arr_out_put["channel"] = channelResp
arr_out_put["hidden"] = hiddenResp
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put,true)
end
function get_connected_devices_list()
local http = require "luci.http"
local deviceReq = luci.http.formvalue("device")
local codeResp = 0
local msgResp = ""
local arr_out_put={}
local net = require "hiwifi.net"
local safe_mac = require "hiwifi.safe_mac"
local connected_devicesResp = net.get_wifi_client_list()
local safe_macs = safe_mac.get_all()
for _, device in pairs(connected_devicesResp) do
device['is_safe'] = safe_macs[device['mac']] and 1 or 0
end
if (codeResp == 0) then
arr_out_put["connected_devices"] = connected_devicesResp
else
msgResp = luci.util.get_api_error(codeResp)
end
local cnt=1
local arp_hash = {}
luci.sys.net.arptable(function(arplist)
local mac_arp = ""
local ip_arp = ""
for k, v in pairs(arplist) do
if k == 'HW address' then mac_arp = v end
if k == 'IP address' then ip_arp = v end
end
arp_hash[mac_arp] = ip_arp
end)
local cnt=1
for _, user in pairs(connected_devicesResp) do
connected_devicesResp[cnt]['ip'] = arp_hash[connected_devicesResp[cnt]['mac']]
cnt = cnt + 1
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put,true)
end
function reconnect()
local http = require "luci.http"
local codeResp = 0
local msgResp = ""
local arr_out_put={}
local net = require "hiwifi.net"
net.turn_wifi_on()
if (codeResp == 0) then
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put,true)
end
function shutdown()
local http = require "luci.http"
local codeResp = 0
local msgResp = ""
local arr_out_put={}
local net = require "hiwifi.net"
net.turn_wifi_off()
if (codeResp == 0) then
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put,true)
luci.http.close()
end
function restart()
local http = require "luci.http"
local codeResp = 0
local msgResp = ""
local arr_out_put={}
local guide_access_tag
local HAVEBEENSET_V = luci.util.get_agreement("HAVRESETWIFI")
if HAVEBEENSET_V == 0 or HAVEBEENSET_V == "0" then
luci.util.edit_agreemt_file("HAVRESETWIFI",1)
end
if (codeResp == 0) then
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put,true)
http.close()
local net = require "hiwifi.net"
if not net.get_wifi_bridge() then --桥接状态下 ifup wan 包含  wifi 命令
os.execute("sleep 3 && env -i /sbin/wifi >/dev/null 2>/dev/null")
else
os.execute("sleep 3 && env -i  /sbin/ifup wan >/dev/null 2>/dev/null")
end
end
function set_base()
local http = require "luci.http"
local deviceReq = luci.http.formvalue("device")
local ssidReq = luci.http.formvalue("ssid")
local keyReq = luci.http.formvalue("key")
local encryptionReq = luci.http.formvalue("encryption")
local hiddenReq = luci.http.formvalue("hidden")
if ssidReq ~= nil then
ssidReq = luci.util.trim(ssidReq)
end
if keyReq ~= nil then
keyReq = luci.util.trim(keyReq)
end
local codeResp = 0
local msgResp = ""
local arr_out_put={}
local netmd = require "luci.model.network".init()
local net = netmd:get_wifinet(deviceReq)
local req_ok = true
if net then
if (ssidReq == nil or ssidReq == "") then
req_ok = false
codeResp = 311
end
if (ssidReq:len()>32) then
req_ok = false
codeResp = 312
end
if (ssidReq == nil or ssidReq == "") and (encryptionReq == nil or encryptionReq == "") and (keyReq == nil or keyReq == "") then
req_ok = false
codeResp = 310
end
if encryptionReq ~= nil and encryptionReq ~= "none" and encryptionReq ~= "mixed-psk" then
req_ok = false
codeResp = 402
end
if encryptionReq ~= nil then
if encryptionReq == "psk" or encryptionReq == "psk2" then
if  keyReq:len()<8 then
req_ok = false
codeResp = 403
end
elseif encryptionReq == "mixed-psk" then
if  keyReq:len()<8 or keyReq:len()>63 then
req_ok = false
codeResp = 405
end
elseif encryptionReq == "wep-open" then
if  keyReq:len()~=5 and keyReq:len()~=13 then
req_ok = false
codeResp = 404
end
end
end
if keyReq:len()>0 and encryptionReq == "none" then
req_ok = false
codeResp = 406
end
if req_ok==true then 	--请求正常
arr_out_put["code"] = codeResp
arr_out_put["msg"] = ssidReq
http.write_json(arr_out_put,true)
luci.http.close()
if ssidReq~=nil and ssidReq~="" then
net:set("ssid",ssidReq)
end
if keyReq~=nil then
net:set("encryption",encryptionReq)
net:set("key",keyReq)
if encryptionReq=="none" then
net:set("key","")
elseif encryptionReq=="wep-open" then
net:set("key1","s:"..keyReq)
net:set("key",1)
end
end
if hiddenReq == "1" then
net:set("hidden","enable")
else
net:set("hidden",nil)
end
netmd:commit("wireless")
netmd:save("wireless")
end
else
codeResp = 401
end
if (codeResp == 0) then
local net = require "hiwifi.net"
if not net.get_wifi_bridge() then --桥接状态下 ifup wan 包含  wifi 命令
os.execute("env -i /sbin/wifi >/dev/null 2>/dev/null")
else
os.execute("env -i  /sbin/ifup wan >/dev/null 2>/dev/null")
end
else
msgResp = luci.util.get_api_error(codeResp)
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put,true)
end
end
function get_channel()
local http = require "luci.http"
local deviceReq = luci.http.formvalue("device")
local channelResp
local channel_autorealResp
local codeResp = 0
local msgResp = ""
local arr_out_put={}
local is_bridgeResp = 0
local netmd = require "luci.model.network".init()
local net = netmd:get_wifinet(deviceReq)
local req_ok = true
if net then
if net:active_mode()=='Master' then
channelResp = tostring(net:channel())
else
codeResp = 1000
end
else
codeResp = 401
end
local uci = require "luci.model.uci"
_uci_real  = uci.cursor()
local wan_if = _uci_real:get("network", "wan", "ifname")
WIFI_IFNAMES = hiwifi_net.get_wifi_ifnames()
local IFNAME = WIFI_IFNAMES[2]
if wan_if == IFNAME then
is_bridgeResp = 1
end
if (codeResp == 0) then
if(channelResp == "0") then
local hcwifi = require "hcwifi"
local IFNAME = net:ifname()--"wlan0"
local KEY_CH = "ch"
local channel_autorealResp = hcwifi.get(IFNAME, KEY_CH)
arr_out_put["channel_autoreal"] = channel_autorealResp
end
if channelResp == nil or channelResp == "" then
local hiwifi_net = require "hiwifi.net"
local hcwifi = require "hcwifi"
local WIFI_IFNAMES = hiwifi_net.get_wifi_ifnames()
local IFNAME = WIFI_IFNAMES[1]
local KEY_CH = "ch"
channelResp = hcwifi.get(IFNAME, KEY_CH)
end
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["channel"] = channelResp
arr_out_put["is_bridge"] = is_bridgeResp
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put,true)
end
function set_channel()
local http = require "luci.http"
local deviceReq = luci.http.formvalue("device")
local channelReq = luci.http.formvalue("channel")
local codeResp = 0
local msgResp = ""
local arr_out_put={}
local arr_dev = luci.util.split(deviceReq, ".")
local device_name = arr_dev[1]
local netmd = require "luci.model.network".init()
local wifidevice = netmd:get_wifidev(device_name)
local req_ok = true
if wifidevice then
if tonumber(channelReq) then
if tonumber(channelReq)>=0 and tonumber(channelReq)<=13 then
wifidevice:set("channel",channelReq);
netmd:commit("wireless")
netmd:save("wireless")
local net = require "hiwifi.net"
if not net.get_wifi_bridge() then --桥接状态下 ifup wan 包含  wifi 命令
luci.util.delay_exec_wifi(3)
else
luci.util.delay_exec_ifwanup(3)
end
else
codeResp = 523
end
else
codeResp = 523
end
else
codeResp = 401
end
if (codeResp == 0) then
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put,true)
end
function get_scan_list()
local http = require "luci.http"
local deviceReq = luci.http.formvalue("device")
local iwlistResp = {}
local ssidResp
local channelResp
local modeResp
local bssidResp
local encryptionResp
local signal_levelResp
local signalResp
local signal_percentResp
local qualityResp
local codeResp = 0
local msgResp = ""
local arr_out_put={}
local radio, ifnidx = deviceReq:match("^(%w+)%.network(%d+)$")
if radio and ifnidx then
local sys = require "luci.sys"
local utl = require "luci.util"
local iw = luci.sys.wifi.getiwinfo(deviceReq)
if iw  then
local iwlist = iw.scanlist
if iwlist then
for i, net in ipairs(iwlist) do
local qc = net.quality or 0
local qm = net.quality_max or 0
local signal_percent = 0
if net.bssid and qc > 0 and qm > 0 then
signal_percent = math.floor((100 / qm) * qc)
end
net.encryption = net.encryption or { }
iwlistResp[#iwlistResp+1] = {
ssid = (net.ssid and utl.pcdata(net.ssid) or "hidden"),
channel = net.channel,
mode = net.mode,
bssid = net.bssid,
encryption = net.encryption,
signal_level = net.signal .. " dB",
signal = (100 / (net.quality_max or 100) * (net.quality or 0)),
signal_percent = signal_percent,
quality = net.quality .. "/" .. net.quality_max
}
end
end
end
else
codeResp = 401
end
if (codeResp == 0) then
arr_out_put["iwlist"] = iwlistResp
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put,true)
end
function get_safe_macs()
local http = require "luci.http"
local macsResp
local codeResp = 0
local msgResp = ""
local arr_out_put={}
local safe_mac = require "hiwifi.safe_mac"
macsResp = safe_mac.list()
if (codeResp == 0) then
arr_out_put["macs"] = macsResp
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put,true)
end
function set_safe_macs()
local http = require "luci.http"
local macReq = luci.http.formvalue("mac")
local codeResp = 0
local msgResp = ""
local arr_out_put={}
local safe_mac = require "hiwifi.safe_mac"
safe_mac.add(macReq)
if (codeResp == 0) then
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put,true)
end
function del_safe_macs()
local http = require "luci.http"
local macReq = luci.http.formvalue("mac")
local codeResp = 0
local msgResp = ""
local arr_out_put={}
local safe_mac = require "hiwifi.safe_mac"
safe_mac.del(macReq)
if (codeResp == 0) then
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put,true)
end
function get_mac_filter_list()
local http = require "luci.http"
local deviceReq = luci.http.formvalue("device")
local mac_localResp
local codeResp = 0
local msgResp = ""
local arr_out_put={}
if deviceReq then
local sets = require "hiwifi.collection.sets"
local mac_filter = require "hiwifi.mac_filter"
local setting = mac_filter.load_setting()
arr_out_put = {
status = setting.mode,
macs = sets.to_list(setting.macs)
}
end
local remote_addr = luci.http.getenv("REMOTE_ADDR")
mac_localResp = luci.sys.net.ip4mac(remote_addr) or ""
if (codeResp == 0) then
arr_out_put["mac_local"] = mac_localResp
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put,true)
end
function set_mac_filter()
local http = require "luci.http"
local deviceReq = luci.http.formvalue("device")
local statusReq = luci.http.formvalue("status")
local macsReq = luci.http.formvalue("macs[]")
local codeResp = 0
local msgResp = ""
local arr_out_put={}
local all_mac_empty = true
if macsReq == nil then  macsReq={} end
for _, mac in pairs(macsReq) do
if mac ~= "" then
all_mac_empty = false
break
end
end
if all_mac_empty and statusReq == "deny" then
statusReq = "stop"
end
if statusReq == "allow" and all_mac_empty then
codeResp = 408
else
if deviceReq then
local sets = require "hiwifi.collection.sets"
local mac_filter = require "hiwifi.mac_filter"
local macs = {}
for _, mac in pairs(macsReq) do
if mac ~= "" then
sets.add(macs, mac)
end
end
local setting = {
mode = statusReq,
macs = macs
}
local defult_errorcode = 521
if statusReq == nil then defult_errorcode = 529 end
codeResp = mac_filter.save_setting(setting) and 0 or defult_errorcode
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
function save_mac_filter()
local http = require "luci.http"
local macsReq = luci.http.formvalue("macs[]")
local codeResp = 0
local msgResp = ""
local arr_out_put={}
if macsReq == nil then  macsReq={} end
local mac_input = table.concat(macsReq, ",")
for _, mac in pairs(macsReq) do
if mac ~= "" then
all_mac_empty = false
break
end
end
local tnetwork = require "luci.model.tnetwork".init()
local tnetwork_defaults = tnetwork:get_defaults()
tnetwork_defaults:set("save_mac_filter",mac_input)
tnetwork:commit("tnetwork")
tnetwork:save("tnetwork")
if (codeResp == 0) then
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put,true)
end
function load_mac_filter()
local http = require "luci.http"
local macsRsq
local codeResp = 0
local msgResp = ""
local arr_out_put={}
local tnetwork = require "luci.model.tnetwork".init()
local tnetwork_defaults = tnetwork:get_defaults()
local mac_str = tnetwork_defaults:get("save_mac_filter")
if mac_str then
macsRsq = Split(mac_str, ",")
for i, mac in pairs(macsRsq) do
if macsRsq[i] == "" then
macsRsq[i] = nil
end
end
end
if (codeResp == 0) then
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
arr_out_put["macs"] = macsRsq
http.write_json(arr_out_put,true)
end
function Split(szFullString, szSeparator)
local nFindStartIndex = 1
local nSplitIndex = 1
local nSplitArray = {}
while true do
local nFindLastIndex = string.find(szFullString, szSeparator, nFindStartIndex)
if not nFindLastIndex then
nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, string.len(szFullString))
break
end
nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, nFindLastIndex - 1)
nFindStartIndex = nFindLastIndex + string.len(szSeparator)
nSplitIndex = nSplitIndex + 1
end
return nSplitArray
end
function get_txpwr()
local http = require "luci.http"
local deviceReq = luci.http.formvalue("device")
local txpwrResp
local codeResp = 0
local msgResp = ""
local arr_out_put={}
local netmd = require "luci.model.network".init()
local net = netmd:get_wifinet(deviceReq)
local req_ok = true
if net then
if net:active_mode()=='Master' then
txpwrResp = tostring(net:txpwr())
else
codeResp = 1000
end
else
codeResp = 401
end
if (codeResp == 0) then
arr_out_put["txpwr"] = txpwrResp
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put,true)
end
function set_txpwr()
local http = require "luci.http"
local deviceReq = luci.http.formvalue("device")
local txpwrReq = luci.http.formvalue("txpwr")
local codeResp = 0
local msgResp = ""
local arr_out_put={}
local arr_dev = luci.util.split(deviceReq, ".")
local device_name = arr_dev[1]
local netmd = require "luci.model.network".init()
local wifidevice = netmd:get_wifidev(device_name)
local req_ok = true
if wifidevice then
wifidevice:set("txpwr",txpwrReq);
netmd:commit("wireless")
netmd:save("wireless")
local net = require "hiwifi.net"
if not net.get_wifi_bridge() then --桥接状态下 ifup wan 包含  wifi 命令
luci.util.delay_exec_wifi(0)
else
luci.util.delay_exec_ifwanup(0)
end
else
codeResp = 401
end
if (codeResp == 0) then
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put,true)
end
function wifi_ctl_scan()
local http = require "luci.http"
local codeResp = 0
local msgResp = ""
local arr_out_put={}
local hiwifi_net = require "hiwifi.net"
local result = hiwifi_net.do_wifi_ctl_scan()
if (codeResp == 0) then
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put)
end
function get_aplist()
local http = require "luci.http"
local net = require "hiwifi.net"
local aplistResp
local codeResp = 0
local msgResp = ""
local arr_out_put={}
if (codeResp == 0) then
arr_out_put["aplist"] = net.get_aplist()
local saved_list = net.get_wifi_bridge_saved()
local i,v,j,k
for i,v in ipairs(arr_out_put["aplist"]) do
arr_out_put["aplist"][i]["ssid"] = http.urlencode(luci.util.fliter_unsafe(arr_out_put["aplist"][i]["ssid"]))
for j,k in ipairs(saved_list) do
if arr_out_put["aplist"][i]["bssid"] == saved_list[j]["bssid"] then
arr_out_put["aplist"][i]["key"] = saved_list[j]["key"]
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
function set_bridge()
local http = require "luci.http"
local net = require "hiwifi.net"
local ssidReq = luci.http.formvalue("ssid")
local keyReq = luci.http.formvalue("key")
local encryptionReq = luci.http.formvalue("encryption")
local bssidReq = luci.http.formvalue("bssid")
local channelReq = luci.http.formvalue("channel")
local guideReq = luci.http.formvalue("guide")
local req_ok = true
local codeResp = 0
local msgResp = ""
local arr_out_put={}
if (ssidReq == nil or ssidReq == "") then
req_ok = false
codeResp = 311
end
if (ssidReq:len()>32) then
req_ok = false
codeResp = 312
end
if (ssidReq == nil or ssidReq == "") and (encryptionReq == nil or encryptionReq == "") and (keyReq == nil or keyReq == "") then
req_ok = false
codeResp = 310
end
if encryptionReq ~= nil and encryptionReq ~= "none" and encryptionReq ~= "mixed-psk" and encryptionReq ~= "psk" and encryptionReq ~= "psk2" then
req_ok = false
codeResp = 402
end
if encryptionReq ~= nil then
if encryptionReq == "psk" or encryptionReq == "psk2" then
if  keyReq:len()<8 then
req_ok = false
codeResp = 403
end
elseif encryptionReq == "mixed-psk" then
if  keyReq:len()<8 or keyReq:len()>63 then
req_ok = false
codeResp = 405
end
elseif encryptionReq == "wep-open" then
if  keyReq:len()~=5 and keyReq:len()~=13 then
req_ok = false
codeResp = 404
end
end
end
if keyReq:len()>0 and encryptionReq == "none" then
req_ok = false
codeResp = 406
end
if not tonumber(channelReq) or tonumber(channelReq)<0 and tonumber(channelReq)>13 then
req_ok = false
codeResp = 523
end
local result
if req_ok==true then 	--请求正常
result = net.set_wifi_bridge(ssidReq,encryptionReq,keyReq,channelReq,bssidReq)
if result ~= 0 then
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
if guideReq ~= nil and guideReq == "1" then
os.execute("echo -n '1' >/tmp/guide_net 2>/dev/null")
end
local mac_reset
local uci = require "luci.model.uci"
_uci_real  = uci.cursor()
mac_reset = _uci_real:get("network", "wan", "macaddr")
WIFI_IFNAMES = hiwifi_net.get_wifi_ifnames()
local IFNAME = WIFI_IFNAMES[2]
os.execute("wifi down")
os.execute("ifconfig "..IFNAME.." hw ether "..mac_reset)
os.execute("/sbin/ifup wan")
os.execute("killall wisp_chk.sh 1>/dev/null 2>1")
os.execute("wisp_chk.sh & >/dev/null 2>/dev/null")
end
end
function get_bridge()
local http = require "luci.http"
local statusResp
local ssidResp
local keyResp
local encryptionResp
local channelResp
local bssidResp
local is_connectResp = 0
local codeResp = 0
local msgResp = ""
local arr_out_put={}
local net = require "hiwifi.net"
if not net.get_wifi_bridge() then
statusResp = 0
else
statusResp = 1
end
ssidResp,encryptionResp,keyResp,channelResp,bssidResp  = net.get_wifi_bridge()
is_connectResp = net.get_wifi_bridge_connect()
if not is_connectResp then is_connectResp = 0 end
if (codeResp == 0) then
arr_out_put["status"] = statusResp	--  是否是 bridge 模式
arr_out_put["is_connect"] = is_connectResp	--  是否联通
arr_out_put["ssid"] = ssidResp
arr_out_put["key"] = keyResp
arr_out_put["encryption"] = encryptionResp
arr_out_put["channel"] = channelResp
arr_out_put["bssid"] = bssidResp
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put)
end
function del_bridge_history()
local http = require "luci.http"
local codeResp = 0
local msgResp = ""
local arr_out_put={}
local net = require "hiwifi.net"
local result  = net.del_bridge_history()
if (codeResp == 0) then
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put)
end
function set_wifi_sleep()
local http = require "luci.http"
local startReq = luci.http.formvalue("start")
local endReq = luci.http.formvalue("end")
local codeResp = 0
local msgResp = ""
local arr_out_put={}
local start_hour,start_min = luci.util.split_short_time(startReq)
local end_hour,end_min = luci.util.split_short_time(endReq)
if not start_hour or not end_hour then
codeResp = 604
elseif tonumber(startReq) == tonumber(endReq) and tonumber(startReq) ~= 0 then	-- 排除关闭状态
codeResp = 605
else
if tonumber(startReq) == 0 and tonumber(endReq) == 0 then
os.execute("/etc/app/wifi_sleep.script off >/dev/null 2>/dev/null")
else
os.execute("/etc/app/wifi_sleep.script update "..start_min.." "..start_hour.." "..end_min.." "..end_hour.." >/dev/null 2>/dev/null")
end
local status_file_c = tonumber(startReq)..","..tonumber(endReq)
fd = io.open(wifi_sleep_status_file, "w")
fd:write(status_file_c)
fd:close()
end
if (codeResp == 0) then
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put)
end
function get_wifi_sleep()
local http = require "luci.http"
local codeResp = 0
local msgResp = ""
local startResp = 0
local endResp = 0
local arr_out_put={}
local start_tmp,end_tmp = luci.util.get_wifi_sleep()
if start_tmp then
startResp,endResp = start_tmp,end_tmp
end
if (codeResp == 0) then
arr_out_put["start"] = startResp
arr_out_put["end"] = endResp
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put)
end
function get_channel_rank()
local http = require "luci.http"
local net = require "hiwifi.net"
local codeResp = 0
local msgResp = ""
local rankResp = {}
local arr_out_put={}
local is_bridgeResp=0
local hiwifi_net = require "hiwifi.net"
local result = hiwifi_net.do_wifi_ctl_scan()
local sleeptimes = 0
while sleeptimes < 10 do
local aplist = net.get_aplist()
if aplist ~= nil and table.getn(aplist) > 0 then
local i,v
for i,v in ipairs(aplist) do
aplist[i]["ssid"] = luci.util.fliter_unsafe(aplist[i]["ssid"])
end
rankResp = luci.util.get_channel_rank(aplist)
if rankResp ~= nil and ((0 <= rankResp[1]) and (rankResp[1] <= 1)) then
break
end
end
os.execute("sleep 1")
sleeptimes = sleeptimes + 1
end
if (codeResp == 0) then
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["rank"] = rankResp
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put)
end
