module("luci.controller.api.exam", package.seeall)
function index()
local page   = node("api","exam")
page.target  = firstchild()
page.title   = _("")
page.order   = 180
page.sysauth = "admin"
page.sysauth_authenticator = "jsonauth"
page.index = true
entry({"api", "exam"}, firstchild(), _(""), 180)
entry({"api", "exam", "do_exam"}, call("do_exam"), _(""), 181)
entry({"api", "exam", "do_st"}, call("do_st"), _(""), 182)
entry({"api", "exam", "do_exam_optimize"}, call("do_exam_optimize"), _(""), 182)
end
local mobile_base = require("hiwifi.mobileapp.base")
function do_exam()
local http = require "luci.http"
local codeResp = 0
local msgResp = ""
local actidResp
local exam_item_listResp
local item_idResp
local infoResp
local weightResp
local arr_out_put={}
local mobile_base = require("hiwifi.mobileapp.base")
local json = require("luci.tools.json")
local exam=require("hiwifi.mobileapp.exam");
local result,code=exam.do_exam()
if (codeResp == 0) then
arr_out_put = result;
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put)
luci.http.close()
luci.util.set_exam_act_cache(result)
luci.util.delay_exec_exam_act(0)
end
function do_st()
local http = require "luci.http"
local codeResp = 0
local msgResp = ""
local actidResp
local arr_out_put={}
local st=require("hiwifi.mobileapp.st");
actid_lastResp = luci.http.formvalue("actid_last")
local actidResp,code=st.do_st(actid_lastResp)
if (codeResp == 0) then
arr_out_put["actid"] = actidResp
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put)
http.close()
end
function do_exam_optimize()
local http = require "luci.http"
local codeResp = 0
local msgResp = ""
local item_idResp
local actidResp
local arr_out_put={}
local score_after_optimize=0
local remark_after_optimize="正常"
local status=0
local mobile_base = require("hiwifi.mobileapp.base")
local json = require("luci.tools.json")
local optimize_data
local delay_time_min = luci.http.formvalue("delay_time_min")
item_idResp = tonumber(luci.http.formvalue("item_id"))
actidResp = luci.http.formvalue("actid")
if actidResp ~= nil and item_idResp ~=nil then
local result_json = mobile_base.mobile_app_curl("Exam/doOptimize",
{
actid=actidResp,
item_id=item_idResp,
delay_time_min=delay_time_min
})
local result_data = json.Decode(result_json)
score_after_optimize = result_data['score_after_optimize']
remark_after_optimize = result_data['remark_after_optimize']
optimize_data = result_data['optimize_data']
if item_idResp == 102 then -- DNS 状态
elseif item_idResp == 103 then -- 固件版本
status=-1
remark_after_optimize = "有更新"
if delay_time_min then
if tonumber(delay_time_min) == 5 then
score_after_optimize = 10
luci.util.delay_exec_update(300)
status=1
remark_after_optimize = "更新中"
elseif tonumber(delay_time_min) == 0 then
luci.util.delay_exec_update(0)
score_after_optimize = 10
status=1
remark_after_optimize = "更新中"
end
end
elseif item_idResp == 201 then -- WiFi 信道拥挤度
if optimize_data then
if optimize_data['channel'] then
local netmd = require "luci.model.network".init()
local wifidevice = netmd:get_wifidev("radio0")
local net = require "hiwifi.net"
if wifidevice then
if tonumber(optimize_data['channel'])>=0 and tonumber(optimize_data['channel'])<=13 then
wifidevice:set("channel",optimize_data['channel']);
netmd:commit("wireless")
netmd:save("wireless")
local net = require "hiwifi.net"
if not net.get_wifi_bridge() then --桥接状态下 ifup wan 包含  wifi 命令
luci.util.delay_exec_wifi(5)
else
luci.util.delay_exec_ifwanup(5)
end
remark_after_optimize = ""
status=1
end
end
end
end
elseif item_idResp == 203 then -- wifi 信号强度
if optimize_data then
if optimize_data['pwr'] then
local netmd = require "luci.model.network".init()
local wifidevice = netmd:get_wifidev("radio0")
local net = require "hiwifi.net"
if wifidevice then
wifidevice:set("txpwr",optimize_data['pwr']);
netmd:commit("wireless")
netmd:save("wireless")
local net = require "hiwifi.net"
if not net.get_wifi_bridge() then --桥接状态下 ifup wan 包含  wifi 命令
luci.util.delay_exec_wifi(5)
else
luci.util.delay_exec_ifwanup(5)
end
score_after_optimize = 10
remark_after_optimize = "强"
status=1
end
end
end
end
end
if (codeResp == 0) then
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["score_after_optimize"] = score_after_optimize
arr_out_put["remark_after_optimize"] = remark_after_optimize
arr_out_put["status"] = status
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put)
end
