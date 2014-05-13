module("luci.controller.api.passport", package.seeall)
function index()
local page   = node("api","passport")
page.target  = firstchild()
page.title   = _("")
page.order   = 160
page.sysauth = "admin"
page.sysauth_authenticator = "jsonauth"
page.index = true
entry({"api", "passport"}, firstchild(), _(""), 90)
entry({"api", "passport", "bind_request"}, call("bind_request"), _(""), 510)
entry({"api", "passport", "bind_token"}, call("bind_token"), _(""), 520)
entry({"api", "passport", "bind_unbind"}, call("bind_unbind"), _(""), 530)
entry({"api", "passport", "user"}, call("user"), _(""), 540)
entry({"api", "passport", "bind_token_v2"}, call("bind_token_v2"), _(""), 542)
end
local io = require("io")
local socket_http = require("socket.http")
local socket_https = require("ssl.https")
local ltn12 = require("ltn12")
local json = require("luci.tools.json")
local passport_host = "https://app.hiwifi.com"
local http_host = luci.http.getenv("HTTP_HOST")
if http_host == nil or http_host == "" then
local interface = "lan"
local ipv4Resp_tmp
local resultResp_tmp
resultResp_tmp,ipv4Resp_tmp = luci.util.get_lan_wan_info(interface)
if table.getn(ipv4Resp_tmp) > 0 then
http_host = ipv4Resp_tmp[1]['ip']
else
http_host = "tw"
end
end
local callback_url = "http://"..http_host..luci.dispatcher.build_url("admin_web", "passport","bind","callback").."/?tmp"
local request_token_file = "/tmp/passport_requesttoken"
local user_file = "/etc/passport/user"
local token_file = "/etc/passport/token"
local protocol = require "luci.http.protocol"
function save_requesttoken(RequestToken)
fd = io.open(request_token_file, "w")
fd:write(RequestToken)
fd:close()
return true
end
function del_requesttoken()
end
function get_requesttoken()
local rv = { }
local fd = io.open(request_token_file, "r")
local token = ""
if fd then
while true do
local ln = fd:read("*l")
if not ln then
break
else
token = ln
end
end
end
return token
end
function save_user_token(cont)
local all_cont = json.Decode(cont)
local user = {}
user['username'] = all_cont['username']
user['OpenID'] = all_cont['OpenID']
local token = all_cont['RefreshToken']
fd = io.open(user_file, "w")
fd:write(json.Encode(user))
fd:close()
fd = io.open(token_file, "w")
fd:write(token)
fd:close()
return true
end
function del_user_token()
fd = io.open(user_file, "w")
fd:write("")
fd:close()
fd = io.open(token_file, "w")
fd:write("")
fd:close()
return true
end
function get_token()
local rv = { }
local fd = io.open(token_file, "r")
local token = ""
if fd then
while true do
local ln = fd:read("*l")
if not ln then
break
else
token = ln
end
end
end
return token
end
function get_user()
local rv = { }
local fd = io.open(user_file, "r")
local all_coent = fd:read("*a")
if all_coent == "" or all_coent == nil then
return false
else
return json.Decode(all_coent)
end
end
function bind_request()
local http = require "luci.http"
local codeResp = 0
local msgResp = ""
local arr_out_put={}
local requesttokenResp=""
macResp = luci.util.get_mac()
local response_body = {}
local request_body = "mac="..protocol.urlencode(macResp).."&returl="..protocol.urlencode(callback_url)
socket_https.request{
url = passport_host.."/router.php?m=oauth&a=request",
method = "POST",
headers = {
["Content-Length"] = string.len(request_body),
["Content-Type"] = "application/x-www-form-urlencoded"
},
source = ltn12.source.string(request_body),
sink = ltn12.sink.table(response_body)
}
if (response_body[1]) then
local response_api = json.Decode(response_body[1])
if response_api['status'] == 200 then
requesttokenResp = response_api['info']['RequestToken']
requestRedirectURLResp = response_api['info']['RedirectURL']
if save_requesttoken(requesttokenResp) then
else
codeResp = 1000
end
else
codeResp = response_api['status']
msgResp = response_api['status'] .." ".. response_api['info']
end
else
codeResp = 532
end
if (codeResp == 0) then
else
if msgResp == "" then
msgResp = luci.util.get_api_error(codeResp)
end
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
arr_out_put["requesttoken"] = requesttokenResp
arr_out_put["redirectuRL"] = requestRedirectURLResp
http.write_json(arr_out_put,true)
end
function bind_token_v2()
local http = require "luci.http"
local codeResp = 0
local msgResp = ""
local arr_out_put={}
local auth = require("auth")
local token,servercode = auth.get_token("passport")
if token == nil or token == "" then
local _,_,_,_,_,_,lanmac = luci.util.get_lan_wan_info("lan")
local tw = require "tw"
local twmac = string.lower(tw.get_mac())
lanmac = string.lower(string.gsub(lanmac,":",""))
if servercode == nil then servercode = "" end
if twmac ~= lanmac then
servercode = servercode.." 1000"
end
codeResp = 542
end
if servercode == nil then servercode = "" end
if (codeResp == 0) then
arr_out_put["token"] = token
else
if msgResp == "" then
msgResp = luci.util.get_api_error(codeResp)
end
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp.." "..servercode
http.write_json(arr_out_put,true)
end
function bind_token()
local http = require "luci.http"
local codeReq = luci.http.formvalue("code")
local codeResp = 0
local msgResp = ""
local OpenIDResp
local AccessTokenResp
local RefreshTokenResp
local ExpireInResp
local arr_out_put={}
macResp = luci.util.get_mac()
local response_body = {}
local request_body = "mac="..protocol.urlencode(macResp).."&code="..protocol.urlencode(codeReq)
socket_https.request{
url = passport_host.."/router.php?m=oauth&a=token",
method = "POST",
headers = {
["Content-Length"] = string.len(request_body),
["Content-Type"] = "application/x-www-form-urlencoded"
},
source = ltn12.source.string(request_body),
sink = ltn12.sink.table(response_body)
}
local response_api = json.Decode(response_body[1]);
if response_api['status'] == 200 then
response_api['info']['username'] = protocol.urldecode(response_api['info']['username'])
if save_user_token(json.Encode(response_api['info'])) then
username = response_api['info']['username']
else
codeResp = 1000
end
else
codeResp = response_api['status']
if not response_api['info'] == nil then
msgResp = response_api['status'] .." ".. response_api['info']
end
if codeResp == 400 then
msgResp = "have binded"
end
end
if (codeResp == 0) then
arr_out_put["username"] = username
else
if msgResp == "" then
msgResp = luci.util.get_api_error(codeResp)
end
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put,true)
end
function bind_unbind()
local http = require "luci.http"
local macReq = luci.util.get_mac()
local tokenReq = get_token()
local codeResp = 0
local msgResp = ""
local arr_out_put={}
del_user_token()
local response_body = {}
local request_body = "mac="..protocol.urlencode(macReq).."&token="..protocol.urlencode(tokenReq)
socket_https.request{
url = passport_host.."/router.php?m=oauth&a=unbind",
method = "POST",
headers = {
["Content-Length"] = string.len(request_body),
["Content-Type"] = "application/x-www-form-urlencoded"
},
source = ltn12.source.string(request_body),
sink = ltn12.sink.table(response_body)
}
local response_api = json.Decode(response_body[1]);
if response_api['status'] == 200 then
else
end
if (codeResp == 0) then
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put,true)
end
function user()
local http = require "luci.http"
local codeResp = 0
local msgResp = ""
local usernameResp
local OpenIDResp
local arr_out_put={}
local user = get_user()
if not user then
codeResp = 1000 -- 未绑定
else
usernameResp = user['username']
OpenIDResp = user['OpenID']
end
if (codeResp == 0) then
arr_out_put["username"] = usernameResp
arr_out_put["OpenID"] = OpenIDResp
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put,true)
end
