module("luci.controller.admin_mobile.index", package.seeall)
function index()
local root = node()
if not root.target then
root.target = alias("admin_mobile")
root.index = true
end
local page   = node("admin_mobile")
page.target  = firstchild()
page.title   = _("")
page.order   = 110
page.sysauth = "admin"
page.mediaurlbase = "/turbo-static/turbo/mobile"
local superkey = (luci.http.getcookie("superkey"))
if superkey ~= nil then
page.sysauth_authenticator = "appauth"
else
page.sysauth_authenticator = "htmlauth_moblie"
end
page.index = true
entry({"admin_mobile"}, template("admin_mobile/index"), _(""), 111)
entry({"admin_mobile","info"}, template("admin_mobile/sysinfo"), _(""), 112)
entry({"admin_mobile","wifi"}, template("admin_mobile/wifi/wifi_setup"), _(""), 113)
entry({"admin_mobile","network"}, template("admin_mobile/network/net_setup"), _(""), 114)
entry({"admin_mobile","clinet_bind"}, template("admin_mobile/system/clinet_bind"), _(""), 115)
entry({"admin_mobile","net_detect_1"}, template("admin_mobile/system/net_detect_1"), _("网络监测手机版1.1"), 116,true)
entry({"admin_mobile","backup"}, template("admin_mobile/system/backup"), _(""), 124)
entry({"admin_mobile","guide_start"}, template("admin_mobile/system/guide_start"), _(""), 117,true)
entry({"admin_mobile","guide_net"}, template("admin_mobile/system/guide_net"), _(""), 118)
entry({"admin_mobile","guide_offline_pppoe"}, template("admin_mobile/system/guide_offline_pppoe"), _(""), 119)
entry({"admin_mobile","guide_offline_static"}, template("admin_mobile/system/guide_offline_static"), _(""), 120)
entry({"admin_mobile","guide_password"}, template("admin_mobile/system/guide_password"), _(""), 121)
entry({"admin_mobile","guide_wifi"}, template("admin_mobile/system/guide_wifi"), _(""), 122)
entry({"admin_mobile","guide_finish"}, template("admin_mobile/system/guide_finish"), _(""), 123)
end
function action_logout()
local dsp = require "luci.dispatcher"
local sauth = require "luci.sauth"
if dsp.context.authsession then
sauth.kill(dsp.context.authsession)
dsp.context.urltoken.stok = nil
end
luci.http.header("Set-Cookie", "sysauth=; path=" .. dsp.build_url())
luci.http.redirect(luci.dispatcher.build_url())
end
