module("luci.controller.admin_web.guide", package.seeall)
function index()
local page   = node("admin_web","guide")
page.target  = firstchild()
page.title   = _("")
page.order   = 10
page.sysauth = "admin"
page.mediaurlbase = "/turbo-static/turbo/web"
local superkey = (luci.http.getcookie("superkey"))
if superkey ~= nil then
page.sysauth_authenticator = "appauth"
else
page.sysauth_authenticator = "htmlauth_web"
end
page.index = true
local guide_access_tag
local HAVEBEENSET_V = luci.util.get_agreement("HAVEBEENSET")
if HAVEBEENSET_V == 0 or HAVEBEENSET_V == "0" then
guide_access_tag = true
else
guide_access_tag = false
end
entry({"admin_web", "guide"}, firstchild(), _("新版首次安装"), 200)
entry({"admin_web", "guide", "index"}, template("admin_web/guide/index"), _("首页"), 200, guide_access_tag)
entry({"admin_web", "guide", "agreement"}, template("admin_web/guide/agreement"), _("agreement"), 200, guide_access_tag)
entry({"admin_web", "guide", "internet_check"}, template("admin_web/guide/internet_check"), _("检查上网方式"), 200)
entry({"admin_web", "guide", "dhcp"}, template("admin_web/guide/internet_DHCP"), _("dhcp"), 200, guide_access_tag)
entry({"admin_web", "guide", "pppoe"}, template("admin_web/guide/internet_PPPoE"), _("pppoe"), 200, guide_access_tag)
entry({"admin_web", "guide", "pppoe_find"}, template("admin_web/guide/find1"), _("pppoe find"), 200, guide_access_tag)
entry({"admin_web", "guide", "wisp"}, template("admin_web/guide/internet_relay"), _("wisp"), 200, guide_access_tag)
entry({"admin_web", "guide", "static"}, template("admin_web/guide/internet_static"), _("static"), 200, guide_access_tag)
entry({"admin_web", "guide", "unlink"}, template("admin_web/guide/insert"), _("static"), 200, guide_access_tag)
entry({"admin_web", "guide", "ssid"}, template("admin_web/guide/ssid"), _("ssid"), 200, guide_access_tag)
entry({"admin_web", "guide", "admin"}, template("admin_web/guide/admin"), _("admin"), 200, guide_access_tag)
entry({"admin_web", "guide", "internet_success"}, template("admin_web/guide/internet_success"), _("internet_success"), 200, guide_access_tag)
entry({"admin_web", "guide", "contact"}, template("admin_web/guide/contact"), _("contact"), 200, guide_access_tag)
entry({"admin_web", "guide", "guide_online"}, template("admin_web/guide/guide_online"), _("guide_online"), 200, guide_access_tag)
entry({"admin_web", "guide", "setsafe"}, template("admin_web/guide/setsafe"), _("setsafe"), 200, guide_access_tag)
entry({"admin_web", "guide", "open_app"}, template("admin_web/guide/open_app"), _("open_app"), 200, guide_access_tag)
end
