module("luci.controller.api.plugin", package.seeall)
function index()
local page   = node("api","plugin")
page.target  = firstchild()
page.title   = _("")
page.order   = 170
page.sysauth = "admin"
page.sysauth_authenticator = "jsonauth"
page.index = true
entry({"api", "plugin"}, firstchild(), _(""), 600)
entry({"api", "plugin", "set_mentohust"}, call("set_mentohust"), _(""), 610,true)
entry({"api", "plugin", "get_mentohust"}, call("get_mentohust"), _(""), 620,true)
entry({"api", "plugin", "set_mentohust_upfile_tag"}, call("set_mentohust_upfile_tag"), _(""), 630,true)
entry({"api", "plugin", "del_mentohust_file"}, call("del_mentohust_file"), _(""), 630,true)
entry({"api", "plugin", "get_x3c"}, call("get_x3c"), _(""), 630,true)
entry({"api", "plugin", "set_x3c"}, call("set_x3c"), _(""), 640,true)
end
local mentohust_datafile_base64_path = "/etc/mentohust.mpf.base64"
local mentohust_datafile_mpf_path = "/etc/mentohust.mpf"
local mentohust_tagfile = "/tmp/mentohust_upfile_tag"
local s = require "luci.tools.status"
function get_mentohust()
local http = require "luci.http"
local enableResp
local BootResp
local UsernameResp
local NicResp
local IPResp
local MaskResp
local GatewayResp
local DNSResp
local PingHostResp
local TimeoutResp
local EchoIntervalResp
local RestartWaitResp
local MaxFailResp
local StartModeResp
local DhcpModeResp
local dhcpscriptResp
local DaemonModeResp
local ShowNotifyResp
local VersionResp
local dhcpscriptResp
local PasswordResp
local DataFileReq
local codeResp = 0
local msgResp = ""
local arr_out_put={}
local uci = require "luci.model.uci"
local name
_uci_real = uci.cursor()
_uci_real:foreach("mentohust", "option",
function(s)
name = s[".name"]
enableResp = s["enable"]
BootResp = s["boot"]
end)
_uci_real:foreach("mentohust", "mentohust",
function(s)
name = s[".name"]
UsernameResp = s["Username"]
PasswordResp = s["Password"]
NicResp = s["Nic"]
IPResp = s["IP"]
MaskResp = s["Mask"]
GatewayResp = s["Gateway"]
DNSResp = s["DNS"]
PingHostResp = s["PingHost"]
TimeoutResp = s["Timeout"]
EchoIntervalResp = s["EchoInterval"]
RestartWaitResp = s["RestartWait"]
MaxFailResp = s["MaxFail"]
StartModeResp = s["StartMode"]
DhcpModeResp = s["DhcpMode"]
DaemonModeResp = s["DaemonMode"]
dhcpscriptResp = s["dhcpscript"]
ShowNotifyResp = s["ShowNotify"]
VersionResp = s["Version"]
dhcpscriptResp = s["dhcpscript"]
end)
local fd
local all = ""
if nixio.fs.access(mentohust_datafile_base64_path) then
local io = require "io"
local fd = io.open(mentohust_datafile_base64_path, "r")
while true do
local ln = fd:read("*l")
if not ln then
break
else
all = all..ln
end
end
end
DataFileReq = all
if (codeResp == 0) then
arr_out_put["enable"] = enableResp
arr_out_put["Boot"] = BootResp
arr_out_put["Username"] = UsernameResp
arr_out_put["Password"] = PasswordResp
arr_out_put["Nic"] = NicResp
arr_out_put["IP"] = IPResp
arr_out_put["Mask"] = MaskResp
arr_out_put["Gateway"] = GatewayResp
arr_out_put["DNS"] = DNSResp
arr_out_put["PingHost"] = PingHostResp
arr_out_put["Timeout"] = TimeoutResp
arr_out_put["EchoInterval"] = EchoIntervalResp
arr_out_put["RestartWait"] = RestartWaitResp
arr_out_put["MaxFail"] = MaxFailResp
arr_out_put["StartMode"] = StartModeResp
arr_out_put["DhcpMode"] = DhcpModeResp
arr_out_put["dhcpscript"] = dhcpscriptResp
arr_out_put["DaemonMode"] = DaemonModeResp
arr_out_put["ShowNotify"] = ShowNotifyResp
arr_out_put["Version"] = VersionResp
arr_out_put["dhcpscript"] = dhcpscriptResp
arr_out_put["DataFile"] = DataFileReq
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put)
end
function set_mentohust_upfile_tag()
local http = require "luci.http"
local codeResp = 0
local msgResp = ""
local arr_out_put={}
os.execute("echo '1' > "..mentohust_tagfile)
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put)
http.close()
end
function del_mentohust_file()
local file_short_nameReq = tostring(luci.http.formvalue("file_short_name"))
local http = require "luci.http"
local codeResp = 0
local msgResp = ""
local arr_out_put={}
if file_short_nameReq == "mentohust" then
os.execute("rm -rf /etc/mentohust.mpf")
elseif file_short_nameReq == "8021x" then
os.execute("rm -rf  /etc/mentohust/8021x.exe")
elseif file_short_nameReq == "SuConfig" then
os.execute("rm -rf /etc/mentohust/SuConfig.dat")
elseif file_short_nameReq == "W32N55" then
os.execute("rm -rf  /etc/mentohust/W32N55.dll")
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put)
http.close()
end
function set_mentohust()
local http = require "luci.http"
local fp
local fd
local io = require "io"
local DataFileReq
os.execute("echo '' > "..mentohust_datafile_base64_path)
if not nixio.fs.access(mentohust_tagfile) then
os.execute("echo '' > "..mentohust_tagfile)
end
local fd = io.open(mentohust_tagfile, "r")
local mentohust_tagfile_ln = fd:read("*l")
if mentohust_tagfile_ln == "1" then 	-- 此标示在提交前设置
luci.http.setfilehandler(
function(meta, chunk, eof)
if not fp then
if meta and meta.name == "datafile_mpf" then
fp = io.open(mentohust_datafile_mpf_path, "w")
end
end
if chunk then
fp:write(chunk)
end
if eof then
fp:close()
os.execute("echo '' > "..mentohust_tagfile)
DataFileReq = luci.util.exec("base64 %s" % mentohust_datafile_mpf_path)
fd = io.open(mentohust_datafile_base64_path, "w")
fd:write(DataFileReq)
fd:close()
end
end
)
else
local DataFileReq = tostring(luci.http.formvalue("DataFile"))
fd = io.open(mentohust_datafile_base64_path, "w")
fd:write(DataFileReq)
fd:close()
end
local enableReq = tostring(luci.http.formvalue("enable"))
local BootReq = "1"
local UsernameReq = tostring(luci.http.formvalue("Username"))
local PasswordReq = tostring(luci.http.formvalue("Password"))
local NicReq = s.global_wan_ifname()
local IPReq = tostring(luci.http.formvalue("IP"))
local MaskReq = tostring(luci.http.formvalue("Mask"))
local GatewayReq = tostring(luci.http.formvalue("Gateway"))
local DNSReq = "0.0.0.0"
local PingHostReq = "0.0.0.0"
local TimeoutReq = "8"
local EchoIntervalReq = "30"
local RestartWaitReq = "15"
local MaxFailReq = "8"
local StartModeReq = tostring(luci.http.formvalue("StartMode"))
local DhcpModeReq = tostring(luci.http.formvalue("DhcpMode"))
local DaemonModeReq = "2"
local ShowNotifyReq = "0"
local VersionReq = tostring(luci.http.formvalue("Version"))
local dhcpscriptReq = "udhcpc -i"
local codeResp = 0
local msgResp = ""
if enableReq ~= "1" then
enableReq = ""
end
local arr_out_put={}
local datatypes = require "luci.cbi.datatypes"
if not datatypes.ipaddr(IPReq) then
codeResp = 512
elseif not datatypes.ipaddr(GatewayReq) then
codeResp = 520
elseif not datatypes.ipaddr(DNSReq) then
codeResp = 519
else
local uci = require "luci.model.uci"
local option_name,mentohust_name
_uci_real = uci.cursor()
_uci_real:foreach("mentohust", "option",
function(s)
option_name = s[".name"]
end)
_uci_real:foreach("mentohust", "mentohust",
function(s)
mentohust_name = s[".name"]
end)
if option_name == nil then
option_name = _uci_real:add("mentohust", "option")
end
if mentohust_name == nil then
mentohust_name = _uci_real:add("mentohust", "mentohust")
end
_uci_real:set("mentohust",option_name,"enable",enableReq)
_uci_real:set("mentohust",option_name,"boot",BootReq)
_uci_real:set("mentohust",mentohust_name,"Username",UsernameReq)
_uci_real:set("mentohust",mentohust_name,"Password",PasswordReq)
_uci_real:set("mentohust",mentohust_name,"Nic",NicReq)
_uci_real:set("mentohust",mentohust_name,"IP",IPReq)
_uci_real:set("mentohust",mentohust_name,"Mask",MaskReq)
_uci_real:set("mentohust",mentohust_name,"Gateway",GatewayReq)
_uci_real:set("mentohust",mentohust_name,"DNS",DNSReq)
_uci_real:set("mentohust",mentohust_name,"PingHost",PingHostReq)
_uci_real:set("mentohust",mentohust_name,"Timeout",TimeoutReq)
_uci_real:set("mentohust",mentohust_name,"EchoInterval",EchoIntervalReq)
_uci_real:set("mentohust",mentohust_name,"RestartWait",RestartWaitReq)
_uci_real:set("mentohust",mentohust_name,"MaxFail",MaxFailReq)
_uci_real:set("mentohust",mentohust_name,"StartMode",StartModeReq)
_uci_real:set("mentohust",mentohust_name,"DhcpMode",DhcpModeReq)
_uci_real:set("mentohust",mentohust_name,"DaemonMode",DaemonModeReq)
_uci_real:set("mentohust",mentohust_name,"ShowNotify",ShowNotifyReq)
_uci_real:set("mentohust",mentohust_name,"Version",VersionReq)
_uci_real:set("mentohust",mentohust_name,"dhcpscript",dhcpscriptReq)
_uci_real:save("mentohust")
_uci_real:load("mentohust")
_uci_real:commit("mentohust")
_uci_real:load("mentohust")
end
if (codeResp == 0) then
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put)
http.close()
os.execute("/etc/init.d/mentohust restart")
end
function get_x3c()
local http = require "luci.http"
local wanifResp
local md5verResp
local enableResp
local usernameResp
local passwordResp
local xorkeyResp
local mcastResp
local ipcommitResp
local vercommitResp
local assitifResp
local privikeyResp
local verResp
local langResp
local codeResp = 0
local msgResp = ""
local arr_out_put={}
local uci = require "luci.model.uci"
local name
_uci_real = uci.cursor()
_uci_real:foreach("x3c8021x", "base_set",
function(s)
name = s[".name"]
enableResp = s["enable"]
passwordResp = s["password"]
usernameResp = s["username"]
end)
_uci_real:foreach("x3c8021x", "adv_set",
function(s)
name = s[".name"]
xorkeyResp = s["xorkey"]
mcastResp = s["mcast"]
md5verResp = s["md5ver"]
ipcommitResp = s["ipcommit"]
vercommitResp = s["vercommit"]
privikeyResp = s["privikey"]
verResp = s["ver"]
langResp = s["lang"]
end)
if (codeResp == 0) then
arr_out_put["wanif"] = wanifResp
arr_out_put["enable"] = enableResp
arr_out_put["username"] = usernameResp
arr_out_put["password"] = passwordResp
arr_out_put["xorkey"] = xorkeyResp
arr_out_put["mcast"] = mcastResp
arr_out_put["md5ver"] = md5verResp
arr_out_put["ipcommit"] = ipcommitResp
arr_out_put["vercommit"] = vercommitResp
arr_out_put["assitif"] = assitifResp
arr_out_put["privikey"] = privikeyResp
arr_out_put["ver"] = verResp
arr_out_put["lang"] = langResp
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put)
end
function set_x3c()
local http = require "luci.http"
local wanifReq = s.global_wan_ifname()
local enableReq = tostring(luci.http.formvalue("enable"))
local md5verReq = tostring(luci.http.formvalue("md5ver"))
local usernameReq = tostring(luci.http.formvalue("username"))
local passwordReq = tostring(luci.http.formvalue("password"))
local xorkeyReq = tostring(luci.http.formvalue("xorkey"))
local mcastReq = tostring(luci.http.formvalue("mcast"))
local ipcommitReq = tostring(luci.http.formvalue("ipcommit"))
local vercommitReq = tostring(luci.http.formvalue("vercommit"))
local privikeyReq = tostring(luci.http.formvalue("privikey"))
local verReq = tostring(luci.http.formvalue("ver"))
local langReq = tostring(luci.http.formvalue("lang"))
local codeResp = 0
local msgResp = ""
if enableReq ~= "1" then
enableReq = ""
end
local arr_out_put={}
if usernameReq:len() == 0 or passwordReq:len() == 0  then
codeResp = 602
elseif usernameReq:len() > 64 or passwordReq:len() > 64  then
codeResp = 603
else
local uci = require "luci.model.uci"
local base_name,adv_name
_uci_real = uci.cursor()
_uci_real:foreach("x3c8021x", "base_set",
function(s)
base_name = s[".name"]
end)
_uci_real:foreach("x3c8021x", "adv_set",
function(s)
adv_name = s[".name"]
end)
if base_name == nil then
base_name = _uci_real:add("x3c8021x", "base_set")
end
if adv_name == nil then
adv_name = _uci_real:add("x3c8021x", "adv_set")
end
_uci_real:set("x3c8021x",base_name,"enable",enableReq)
_uci_real:set("x3c8021x",base_name,"username",usernameReq)
_uci_real:set("x3c8021x",base_name,"password",passwordReq)
_uci_real:set("x3c8021x",base_name,"wanif",wanifReq)
_uci_real:set("x3c8021x",adv_name,"xorkey",xorkeyReq)
_uci_real:set("x3c8021x",adv_name,"mcast",mcastReq)
_uci_real:set("x3c8021x",adv_name,"ipcommit",ipcommitReq)
_uci_real:set("x3c8021x",adv_name,"vercommit",vercommitReq)
_uci_real:set("x3c8021x",adv_name,"privikey",privikeyReq)
_uci_real:set("x3c8021x",adv_name,"md5ver",md5verReq)
_uci_real:set("x3c8021x",adv_name,"ver",verReq)
_uci_real:set("x3c8021x",adv_name,"lang",langReq)
_uci_real:save("x3c8021x")
_uci_real:load("x3c8021x")
_uci_real:commit("x3c8021x")
_uci_real:load("x3c8021x")
end
if (codeResp == 0) then
else
msgResp = luci.util.get_api_error(codeResp)
end
arr_out_put["code"] = codeResp
arr_out_put["msg"] = msgResp
http.write_json(arr_out_put)
http.close()
os.execute("/etc/init.d/x3c8021x restart")
end
