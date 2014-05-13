module("luci.controller.api.index", package.seeall)
function index()
local page   = node("api")
page.target  = firstchild()
page.title   = _("")
page.order   = 10
page.sysauth = "admin"
page.sysauth_authenticator = "jsonauth"
page.index = true
local var_remote_addr = (luci.http.getenv('REMOTE_ADDR'))
local noauthall
if var_remote_addr == "127.0.0.1" then
noauthall = true
else
noauthall = false
end
entry({"api"}, firstchild(), _(""), 100,noauthall)
entry({"api","index"}, call("api_error"), _(""), 91)
end
function api_error()
local arr_out_put = {}
local codeResp
local msgResp
codeResp = 80
msgResp = luci.util.get_api_error(codeResp)
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
luci.http.write_json(arr_out_put,true)
end
