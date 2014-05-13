module("luci.controller.api.turbo", package.seeall)
function index()
local page   = node("api","turbo")
page.target  = firstchild()
page.title   = _("")
page.order   = 160
page.sysauth = "admin"
page.sysauth_authenticator = "jsonauth"
page.index = true
entry({"api", "turbo"}, firstchild(), _(""), 160)
entry({"api", "turbo", "get_yicitong_status"}, call("get_yicitong_status"), _(""), 161)
entry({"api", "turbo", "set_yicitong_status"}, call("set_yicitong_status"), _(""), 162)
entry({"api", "turbo", "get_apple_accelerate_status"}, call("get_apple_accelerate_status"), _(""), 163)
entry({"api", "turbo", "set_apple_accelerate_status"}, call("set_apple_accelerate_status"), _(""), 164)
end
function get_yicitong_status()
local http = require "luci.http"
local statusResp
local codeResp = 0
local msgResp = ""
local arr_out_put={}
if luci.sys.process.runing("nginx")==0 then
statusResp = 1	-- 运行
else
statusResp = 0	-- 停止
end
if (codeResp == 0) then
arr_out_put["status"] = statusResp
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put,true)
end
function set_yicitong_status()
local http = require "luci.http"
local statusReq = luci.http.formvalue("status")
local codeResp = 0
local msgResp = ""
local arr_out_put={}
if statusReq == "1" then
os.execute("/etc/init.d/nginx start >/dev/null")
os.execute("/etc/init.d/haproxy start >/dev/null")
elseif statusReq == "0" then
os.execute("/etc/init.d/nginx stop >/dev/null")
elseif statusReq == "2" then
os.execute("/etc/init.d/nginx restart >/dev/null")
else
codeResp = 1000
end
if (codeResp == 0) then
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put,true)
end
function get_apple_accelerate_status()
local http = require "luci.http"
local statusResp
local codeResp = 0
local msgResp = ""
local arr_out_put={}
if luci.sys.process.runing("nginx")==0 and luci.sys.isapplecdn()==0 then
statusResp = 1	-- 运行
else
if luci.sys.process.runing("nginx")==0 then
statusResp = 0	--停止
else
codeResp = 510 -- App Store下载加速需要一词通同时启动
end
end
if (codeResp == 0) then
arr_out_put["status"] = statusResp
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put,true)
end
function set_apple_accelerate_status()
local http = require "luci.http"
local statusReq = luci.http.formvalue("status")
local codeResp = 0
local msgResp = ""
local arr_out_put={}
if statusReq == "1" then
os.execute("cp /etc/nginx/vh.phobos_apple_com.conf.default /etc/nginx/vh.phobos_apple_com.conf")
os.execute("/usr/sbin/nginx -s reload >/dev/null")
elseif statusReq == "0" then
os.execute("rm -f /etc/nginx/vh.phobos_apple_com.conf")
os.execute("/usr/sbin/nginx -s reload >/dev/null")
else
codeResp = 1000
end
if (codeResp == 0) then
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put,true)
end
