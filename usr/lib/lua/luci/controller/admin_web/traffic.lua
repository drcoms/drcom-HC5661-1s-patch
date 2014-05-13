module("luci.controller.admin_web.traffic", package.seeall)
function index()
local page   = node("admin_web","traffic")
page.target  = firstchild()
page.title   = _("")
page.order   = 10
page.sysauth = "admin"
page.mediaurlbase = "/turbo-static/turbo/web"
page.sysauth_authenticator = "htmlauth_web"
page.index = true
entry({"admin_web", "traffic", "index"}, template("admin_web/trafficinfo"), _(""), 120)
entry({"admin_web", "traffic", "update"}, call("get_traffic"), _(""), 120,true)
end
function get_traffic()
local http = require "luci.http"
local uci = require "luci.model.uci"
local fs = require "nixio.fs"
local wlanif = luci.util.fliter_unsafe(luci.http.formvalue("wlanif"))
local wanif = luci.util.fliter_unsafe(luci.http.formvalue("wanif"))
local vpnif = luci.util.fliter_unsafe(luci.http.formvalue("vpnif"))
local lanif = luci.util.fliter_unsafe(luci.http.formvalue("lanif"))
local wanul, wandl, lanul, landl
local waninfo,laninfo,wlaninfo,vpninfo
local devstats = fs.readfile("/proc/net/dev")
if lanif then
local tmp = lanif:gsub("%-", "%%-")
local rx, tx = devstats:match("%s*"..tmp..
":%s*([0-9]+)%s+[0-9]+%s+[0-9]+%s+[0-9]+%s+"..
"[0-9]+%s+[0-9]+%s+[0-9]+%s+[0-9]+%s+([0-9]+)")
lanul = tx and (tonumber(tx) )
landl = rx and (tonumber(rx) )
if lanul==nil then lanul = 0 end
if landl==nil then landl = 0 end
laninfo = "'" .. lanif .. "':{'rx':".. lanul ..",'tx':" .. landl .. "}"
end
if wanif then
local tmp = wanif:gsub("%-", "%%-")
local rx, tx = devstats:match("%s*"..tmp..
":%s*([0-9]+)%s+[0-9]+%s+[0-9]+%s+[0-9]+%s+"..
"[0-9]+%s+[0-9]+%s+[0-9]+%s+[0-9]+%s+([0-9]+)")
wanul = tx and tonumber(tx) --/ 1000000000
wandl = rx and tonumber(rx) --/ 1000000000
if wanul==nil then wanul = 0 end
if wandl==nil then wandl = 0 end
waninfo = "'" .. wanif .. "':{'rx':".. wandl ..",'tx':" .. wanul .. "}"
end
if vpnif then
local rx, tx = devstats:match("%s*" .. vpnif ..
":%s*([0-9]+)%s+[0-9]+%s+[0-9]+%s+[0-9]+%s+"..
"[0-9]+%s+[0-9]+%s+[0-9]+%s+[0-9]+%s+([0-9]+)")
wanul = tx and tonumber(tx)
wandl = rx and tonumber(rx) -- / 1000000000
if wanul==nil then wanul = 0 end
if wandl==nil then wandl = 0 end
if wandl>0 or wanul>0 then
vpninfo = "'" .. vpnif .. "':{'rx':".. wandl ..",'tx':" .. wanul .. "}"
end
end
if wlanif then
local rx, tx = devstats:match("%s*" .. wlanif ..
":%s*([0-9]+)%s+[0-9]+%s+[0-9]+%s+[0-9]+%s+"..
"[0-9]+%s+[0-9]+%s+[0-9]+%s+[0-9]+%s+([0-9]+)")
wanul = tx and tonumber(tx)
wandl = rx and tonumber(rx) -- / 1000000000
if wanul==nil then wanul = 0 end
if wandl==nil then wandl = 0 end
if wandl>0 or wanul>0 then
wlaninfo = "'" .. wlanif .. "':{'rx':".. wanul ..",'tx':" .. wandl .. "}"
end
end
local arr_out_put={}
local netdev = "netdev={"
local temp = ""
if laninfo then
temp = temp .. "," ..  laninfo
end
if waninfo then
temp = temp ..  "," .. waninfo
end
if vpninfo then
temp = temp ..  "," .. vpninfo
end
if wlaninfo then
temp = temp ..  "," .. wlaninfo
end
if temp~="" and string.sub(temp,1,1)=="," then
netdev = netdev .. string.sub(temp,2)
end
netdev = netdev .. "}"
luci.http.prepare_content("application/json")
http.write(netdev)
end
