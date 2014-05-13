local fs = require "nixio.fs"
local io = require "io"
local math = require "math"
local table = require "table"
local debug = require "debug"
local ldebug = require "luci.debug"
local string = require "string"
local coroutine = require "coroutine"
local tparser = require "luci.template.parser"
local tw = require "tw"
local json = require "luci.tools.json"
local getmetatable, setmetatable = getmetatable, setmetatable
local rawget, rawset, unpack = rawget, rawset, unpack
local tostring, type, assert, tonumber = tostring, type, assert, tonumber
local ipairs, pairs, loadstring = ipairs, pairs, loadstring
local require, pcall, xpcall, os = require, pcall, xpcall, os
local collectgarbage, get_memory_limit = collectgarbage, get_memory_limit
module "luci.util"
getmetatable("").__mod = function(a, b)
if not b then
return a
elseif type(b) == "table" then
for k, _ in pairs(b) do if type(b[k]) == "userdata" then b[k] = tostring(b[k]) end end
return a:format(unpack(b))
else
if type(b) == "userdata" then b = tostring(b) end
return a:format(b)
end
end
local function _instantiate(class, ...)
local inst = setmetatable({}, {__index = class})
if inst.__init__ then
inst:__init__(...)
end
return inst
end
function class(base)
return setmetatable({}, {
__call  = _instantiate,
__index = base
})
end
function instanceof(object, class)
local meta = getmetatable(object)
while meta and meta.__index do
if meta.__index == class then
return true
end
meta = getmetatable(meta.__index)
end
return false
end
local tl_meta = {
__mode = "k",
__index = function(self, key)
local t = rawget(self, coxpt[coroutine.running()]
or coroutine.running() or 0)
return t and t[key]
end,
__newindex = function(self, key, value)
local c = coxpt[coroutine.running()] or coroutine.running() or 0
if not rawget(self, c) then
rawset(self, c, { [key] = value })
else
rawget(self, c)[key] = value
end
end
}
function threadlocal(tbl)
return setmetatable(tbl or {}, tl_meta)
end
function perror(obj)
return io.stderr:write(tostring(obj) .. "\n")
end
function dumptable(t, maxdepth, i, seen)
i = i or 0
seen = seen or setmetatable({}, {__mode="k"})
for k,v in pairs(t) do
perror(string.rep("\t", i) .. tostring(k) .. "\t" .. tostring(v))
if type(v) == "table" and (not maxdepth or i < maxdepth) then
if not seen[v] then
seen[v] = true
dumptable(v, maxdepth, i+1, seen)
else
perror(string.rep("\t", i) .. "*** RECURSION ***")
end
end
end
end
function escape(s, c)
c = c or "\\"
return s:gsub(c, "\\" .. c)
end
function pcdata(value)
return value and tparser.sanitize_pcdata(tostring(value))
end
function striptags(s)
return pcdata(tostring(s):gsub("</?[A-Za-z][A-Za-z0-9:_%-]*[^>]*>", " "):gsub("%s+", " "))
end
function split(str, pat, max, regex)
pat = pat or "\n"
max = max or #str
local t = {}
local c = 1
if #str == 0 then
return {""}
end
if #pat == 0 then
return nil
end
if max == 0 then
return str
end
repeat
local s, e = str:find(pat, c, not regex)
max = max - 1
if s and max < 0 then
t[#t+1] = str:sub(c)
else
t[#t+1] = str:sub(c, s and s - 1)
end
c = e and e + 1 or #str + 1
until not s or max < 0
return t
end
function trim(str)
return (str:gsub("^%s*(.-)%s*$", "%1"))
end
function cmatch(str, pat)
local count = 0
for _ in str:gmatch(pat) do count = count + 1 end
return count
end
function imatch(v)
if v == nil then
v = ""
elseif type(v) == "table" then
v = table.concat(v, " ")
elseif type(v) ~= "string" then
v = tostring(v)
end
return v:gmatch("%S+")
end
function parse_units(ustr)
local val = 0
local map = {
y   = 60 * 60 * 24 * 366,
m   = 60 * 60 * 24 * 31,
w   = 60 * 60 * 24 * 7,
d   = 60 * 60 * 24,
h   = 60 * 60,
min = 60,
kb  = 1024,
mb  = 1024 * 1024,
gb  = 1024 * 1024 * 1024,
kib = 1000,
mib = 1000 * 1000,
gib = 1000 * 1000 * 1000
}
for spec in ustr:lower():gmatch("[0-9%.]+[a-zA-Z]*") do
local num = spec:gsub("[^0-9%.]+$","")
local spn = spec:gsub("^[0-9%.]+", "")
if map[spn] or map[spn:sub(1,1)] then
val = val + num * ( map[spn] or map[spn:sub(1,1)] )
else
val = val + num
end
end
return val
end
string.escape      = escape
string.pcdata      = pcdata
string.striptags   = striptags
string.split       = split
string.trim        = trim
string.cmatch      = cmatch
string.parse_units = parse_units
function append(src, ...)
for i, a in ipairs({...}) do
if type(a) == "table" then
for j, v in ipairs(a) do
src[#src+1] = v
end
else
src[#src+1] = a
end
end
return src
end
function combine(...)
return append({}, ...)
end
function contains(table, value)
for k, v in pairs(table) do
if value == v then
return k
end
end
return false
end
function update(t, updates)
for k, v in pairs(updates) do
t[k] = v
end
end
function keys(t)
local keys = { }
if t then
for k, _ in kspairs(t) do
keys[#keys+1] = k
end
end
return keys
end
function clone(object, deep)
local copy = {}
for k, v in pairs(object) do
if deep and type(v) == "table" then
v = clone(v, deep)
end
copy[k] = v
end
return setmetatable(copy, getmetatable(object))
end
function dtable()
return setmetatable({}, { __index =
function(tbl, key)
return rawget(tbl, key)
or rawget(rawset(tbl, key, dtable()), key)
end
})
end
function _serialize_table(t, seen)
assert(not seen[t], "Recursion detected.")
seen[t] = true
local data  = ""
local idata = ""
local ilen  = 0
for k, v in pairs(t) do
if type(k) ~= "number" or k < 1 or math.floor(k) ~= k or ( k - #t ) > 3 then
k = serialize_data(k, seen)
v = serialize_data(v, seen)
data = data .. ( #data > 0 and ", " or "" ) ..
'[' .. k .. '] = ' .. v
elseif k > ilen then
ilen = k
end
end
for i = 1, ilen do
local v = serialize_data(t[i], seen)
idata = idata .. ( #idata > 0 and ", " or "" ) .. v
end
return idata .. ( #data > 0 and #idata > 0 and ", " or "" ) .. data
end
function serialize_data(val, seen)
seen = seen or setmetatable({}, {__mode="k"})
if val == nil then
return "nil"
elseif type(val) == "number" then
return val
elseif type(val) == "string" then
return "%q" % val
elseif type(val) == "boolean" then
return val and "true" or "false"
elseif type(val) == "function" then
return "loadstring(%q)" % get_bytecode(val)
elseif type(val) == "table" then
return "{ " .. _serialize_table(val, seen) .. " }"
else
return '"[unhandled data type:' .. type(val) .. ']"'
end
end
function restore_data(str)
return loadstring("return " .. str)()
end
function get_bytecode(val)
local code
if type(val) == "function" then
code = string.dump(val)
else
code = string.dump( loadstring( "return " .. serialize_data(val) ) )
end
return code -- and strip_bytecode(code)
end
function strip_bytecode(code)
local version, format, endian, int, size, ins, num, lnum = code:byte(5, 12)
local subint
if endian == 1 then
subint = function(code, i, l)
local val = 0
for n = l, 1, -1 do
val = val * 256 + code:byte(i + n - 1)
end
return val, i + l
end
else
subint = function(code, i, l)
local val = 0
for n = 1, l, 1 do
val = val * 256 + code:byte(i + n - 1)
end
return val, i + l
end
end
local function strip_function(code)
local count, offset = subint(code, 1, size)
local stripped = { string.rep("\0", size) }
local dirty = offset + count
offset = offset + count + int * 2 + 4
offset = offset + int + subint(code, offset, int) * ins
count, offset = subint(code, offset, int)
for n = 1, count do
local t
t, offset = subint(code, offset, 1)
if t == 1 then
offset = offset + 1
elseif t == 4 then
offset = offset + size + subint(code, offset, size)
elseif t == 3 then
offset = offset + num
elseif t == 254 or t == 9 then
offset = offset + lnum
end
end
count, offset = subint(code, offset, int)
stripped[#stripped+1] = code:sub(dirty, offset - 1)
for n = 1, count do
local proto, off = strip_function(code:sub(offset, -1))
stripped[#stripped+1] = proto
offset = offset + off - 1
end
offset = offset + subint(code, offset, int) * int + int
count, offset = subint(code, offset, int)
for n = 1, count do
offset = offset + subint(code, offset, size) + size + int * 2
end
count, offset = subint(code, offset, int)
for n = 1, count do
offset = offset + subint(code, offset, size) + size
end
stripped[#stripped+1] = string.rep("\0", int * 3)
return table.concat(stripped), offset
end
return code:sub(1,12) .. strip_function(code:sub(13,-1))
end
function _sortiter( t, f )
local keys = { }
for k, v in pairs(t) do
keys[#keys+1] = k
end
local _pos = 0
table.sort( keys, f )
return function()
_pos = _pos + 1
if _pos <= #keys then
return keys[_pos], t[keys[_pos]]
end
end
end
function spairs(t,f)
return _sortiter( t, f )
end
function kspairs(t)
return _sortiter( t )
end
function vspairs(t)
return _sortiter( t, function (a,b) return t[a] < t[b] end )
end
function bigendian()
return string.byte(string.dump(function() end), 7) == 0
end
function exec(command)
local pp   = io.popen(command)
local data = pp:read("*a")
pp:close()
return data
end
function execi(command)
local pp = io.popen(command)
return pp and function()
local line = pp:read()
if not line then
pp:close()
end
return line
end
end
function execl(command)
local pp   = io.popen(command)
local line = ""
local data = {}
while true do
line = pp:read()
if (line == nil) then break end
data[#data+1] = line
end
pp:close()
return data
end
function libpath()
return require "nixio.fs".dirname(ldebug.__file__)
end
local performResume, handleReturnValue
local oldpcall, oldxpcall = pcall, xpcall
coxpt = {}
setmetatable(coxpt, {__mode = "kv"})
local function copcall_id(trace, ...)
return ...
end
function coxpcall(f, err, ...)
local res, co = oldpcall(coroutine.create, f)
if not res then
local params = {...}
local newf = function() return f(unpack(params)) end
co = coroutine.create(newf)
end
local c = coroutine.running()
coxpt[co] = coxpt[c] or c or 0
return performResume(err, co, ...)
end
function copcall(f, ...)
return coxpcall(f, copcall_id, ...)
end
function handleReturnValue(err, co, status, ...)
if not status then
return false, err(debug.traceback(co, (...)), ...)
end
if coroutine.status(co) ~= 'suspended' then
return true, ...
end
return performResume(err, co, coroutine.yield(...))
end
function performResume(err, co, ...)
return handleReturnValue(err, co, coroutine.resume(co, ...))
end
function device_list()
local nixio = require "nixio"
local device_suggestions = nixio.fs.glob("/dev/tty[A-Z]*")
or nixio.fs.glob("/dev/tts/*")
or nixio.fs.glob("/dev/usb/tts/*")
or nixio.fs.glob("/dev/usb/acm/*")
return device_suggestions
end
function get_usb_device()
local rs = device_list()
if rs == nil then
return nil
end
local usb = nil
local list = ""
for name in rs do
list = list .. ";" .. name
end
if string.find(list,"ttyACM0") ~= nil and  string.find(list,"ttyACM0") > 0 then
usb = "/dev/ttyACM0"
elseif string.find(list,"ttyUSB0") ~= nil and string.find(list,"ttyUSB0") > 0 then
usb = "/dev/ttyUSB0"
elseif string.find(list,"usb/acm/0") ~= nil and string.find(list,"usb/acm/0") > 0 then
usb = "/dev/usb/acm/0"
elseif string.find(list,"usb/tts/0") ~= nil and  string.find(list,"usb/tts/0") > 0 then
usb = "/dev/usb/tts/0"
end
return usb
end
function is_eth_link()
local is_eth_link
local wan_status = get_status_wan()
if wan_status['dev_link'] then
is_eth_link = 1
else
is_eth_link = 0
end
return is_eth_link
end
function get_eth1_gateway()
local cmd = "route -n|grep UG"
local data = exec(cmd)
if data==nil then
return false
end
local dst_ip, gateway = data:match(
'^([^%s]+)%s+([^%s]+)%s+'
)
return gateway
end
function get_eth_ip(iface)
local netmd = require "luci.model.network".init()
local lan_ip = ""
local lan_mask = ""
local result = {}
local net = netmd:get_network(iface)
if net then
local device = net and net:get_interface()
if device and table.getn(device:ipaddrs()) > 0 then
for _, a in ipairs(device:ipaddrs()) do
result[#result+1] = {}
result[#result]['ip'] = a:host():string()
result[#result]['mask']= a:mask():string()
end
end
end
return result--{ip=lan_ip,mask=lan_mask}
end
function get_sys_board()
return tw.get_model()
end
function get_sys_board_sign()
local board = get_sys_board()
local sign = string.sub(board,1,2)
return sign
end
function get_mac()
local mac_local = tw.get_mac()
mac_local = string.sub(mac_local,1,2)..":"..string.sub(mac_local,3,4)..":"..string.sub(mac_local,5,6)..":"..string.sub(mac_local,7,8)..":"..string.sub(mac_local,9,10)..":"..string.sub(mac_local,11,12)
return mac_local
end
function md5file(file)
return trim(exec("/usr/bin/md5sum %s|/usr/bin/cut -d' ' -f1" % file))
end
function md5str(str)
return trim(exec("/bin/echo -n %s|/usr/bin/md5sum|/usr/bin/cut -d' ' -f1" % str))
end
function get_user_lang(http)
local conf = require "luci.config"
local lang = conf.main.lang or "auto"
if lang == "auto" then
local aclang = http.getenv("HTTP_ACCEPT_LANGUAGE") or ""
for lpat in aclang:gmatch("[%w-]+") do
lpat = lpat and lpat:gsub("-", "_")
lpat = lpat:lower()
if conf.languages[lpat] then
lang = lpat
break
end
end
end
lang = "zh_cn"
return lang
end
function is_dev_model(model)
local nixio = require "nixio"
return nixio.fs.access("/etc/config/"..model)
end
local appswitchfile = "/etc/app/switch"
function trim(s)
local from = s:match"^%s*()"
return from > #s and "" or s:match(".*%S", from)
end
function set_agreement_switch(conf_name,status)
exec("wget -q -O - 'http://tw-vars:81/set?key=AGREEMENT_"..conf_name.."&value="..status.."' > /dev/null")
edit_agreemt_file(conf_name,status)
end
function edit_app_switch_file(appname,status)
set_config_file(appswitchfile,appname,status)
end
function get_agreement(conf_name)
local fd = io.open("/etc/agreement", "r")
local status
while true do
local ln = fd:read("*l")
if not ln then
break
else
local name,status_tmp = ln:match("^(%S+):(%S+)")
if name and status_tmp then
if name == conf_name then
status = status_tmp
end
end
end
end
fd:close()
return status
end
local pppoptionfile = "/etc/ppp/options"
function edit_lcp_file(lcp_interval)
local rv = { }
local fd = io.open(pppoptionfile, "r")
local action_ok = false
local contant = ""
while true do
local ln = fd:read("*l")
if not ln then
break
else
local l,lcp_interval_now = ln:match("^lcp([^%s]+)interval%s+([^%s]+)")
if lcp_interval_now then
action_ok = true
contant = contant .. "lcp-echo-interval ".. lcp_interval .. "\n"
else
contant = contant .. ln .. "\n"
end
end
end
if action_ok == false then
contant = contant .. "lcp-echo-interval ".. lcp_interval .. "\n"
end
fd:close()
fd = io.open(pppoptionfile, "w")
fd:write(contant)
fd:close()
end
local loginlock_time = 10
function up_loginlock()
local num = fs.readfile("/tmp/loginerrnum") or 0
num=num+1
fs.writefile("/tmp/loginerrnum", num)
end
function unset_loginlock()
fs.writefile("/tmp/loginerrnum", 0)
end
function get_loginlock()
local num = fs.readfile("/tmp/loginerrnum") or 0
return num
end
function file_number_up(file,up)  --UP need >=0
if fs.access(file) then
local new_t = tonumber(fs.readfile(file))+tonumber(up)
os.execute("echo '"..new_t.."' > "..file)
else
os.execute("echo '"..up.."' >> "..file)
end
end
function is_loginlock()
local num = fs.readfile("/tmp/loginerrnum") or 0
num=num+1-1
if num>=loginlock_time then
fs.writefile("/tmp/login.lock","yes")
end
local lock = fs.readfile("/tmp/login.lock") or ""
if lock == "yes" then
return true
else
return false
end
end
function is_lan_link(port)
local cmd
local sys_board = get_sys_board()
if sys_board == "HC6361" or sys_board == "HC5661" or sys_board == "HC5761" then
cmd = 'switch status lan |grep "Port '..port..'"|grep "link:up"'
end
local data = exec(cmd)
if data==nil or data == "" then
return 0
else
return 1
end
end
function is_internet_connect()
local is_connect
local wan_status = get_status_wan()
if wan_status['dev_up'] and  wan_status['dev_link'] and  wan_status['iface_up'] then
is_connect = 1
else
is_connect = 0
end
return is_connect
end
function get_api_error(errorcode)
local error_list = {}
error_list[20] = "缺少参数"
error_list[80] = "api 地址错误"
error_list[300] = "no this language"
error_list[310] = "需要 SSID 或 密码至少一项"
error_list[311] = "SSID 不能为空"
error_list[312] = "SSID 需要是 1 至 32个英文字符,或 10 个中文字符"
error_list[100] = "非法请求"
error_list[110] = "升级失败请重试.  code:110"
error_list[120] = "软件文件格式错误"
error_list[301] = "密码不能为空"
error_list[302] = "原密码不正确"
error_list[303] = "密码长度需要在 5-64 位之间"
error_list[401] = "No this device"
error_list[402] = "Encryption error"
error_list[403] = "wpa 密码长度大于 8 位"
error_list[404] = "wep-open 密码需要 5位 或 13 位"
error_list[405] = "密码长度应为  8-63  位字符"
error_list[406] = "如果设置密码,请选择安全级别"
error_list[407] = "需要将此设备接网线到LAN口,才能关闭 WIFI"
error_list[408] = "至少需要填写一个 MAC 地址"
error_list[409] = "最多只能填写 64 个  MAC 地址"
error_list[410] = "终止地址不能小于起始地址"
error_list[411] = "IP 地址需要在 1-254 之间"
error_list[412] = "开始和终止地址不能为空"
error_list[500] = "检查软件版本错误，网络是否正常或稍后再尝试"
error_list[510] = "App Store to accelerate need ‘One word direction’"
error_list[511] = "没有 lan 或 wan 口"
error_list[512] = "IP 地址格式不正确"
error_list[513] = "子网掩码格式不正确"
error_list[514] = "需要传 mobile_type 和 mobile_dev_usb"
error_list[515] = "没有接上3g 设备"
error_list[516] = "mobile_dev_usb 有误"
error_list[517] = "不支持这个拨号方式 ，只支持 10086,10000,10010"
error_list[518] = "Adsl 的用户名密码不能为空"
error_list[519] = "DNS 格式不正确"
error_list[520] = "网关格式不正确"
error_list[521] = "MAC 地址格式错误"
error_list[522] = "MTU 不能为空"
error_list[523] = "Channel 必须是 0-13 的整数"
error_list[524] = "上传失败."
error_list[525] = "图片已经存在."
error_list[526] = "至少填写一个有效的 mac 地址."
error_list[527] = "请选择 允许 , 或者禁止 以下 mac 地址."
error_list[528] = "无可用更新."
error_list[529] = "请选择 允许 或 禁止以下 MAC 地址选项."
error_list[530] = "MTU 必须是 576-1492 之间的数字 ."
error_list[531] = "MTU 必须是 576-1500 之间的数字 ."
error_list[532] = "服务器错误 ."
error_list[533] = "WAN IP与LAN IP不能在同一网段."
error_list[534] = "WAN IP的范围必须是ABC类地址."
error_list[535] = "主机号不能全0，也不能全1."
error_list[536] = "DHCP 租用时间 的范围 是  2-2880 分钟 ，或  1-48 小时."
error_list[537] = "IP 分配范围 和 租用时间 必须为正整数."
error_list[538] = "非法 MAC 地址."
error_list[540] = "LAN IP的范围必须是ABC类地址."
error_list[541] = "172.31 为保留的 ip 段."
error_list[542] = "设备认证失败."
error_list[543] = "LCP请求发送间隔  范围 0-120 秒."
error_list[544] = "升级失败请重试. code:544"
error_list[545] = "设备名称不能为空."
error_list[546] = "设备名称不能超过30个字符."
error_list[547] = "当前路由器ROM不支持此功能，请升级路由器固件."
error_list[548] = "请填写正确的 MAC 与 IP 地址."
error_list[549] = "说明防火墙无法设置，终止操作."
error_list[550] = "限速数值需要为大于等于 0 KB"
error_list[551] = "未传入设备名称."
error_list[552] = "密码为默认不安全."
error_list[601] = "授权码必须是 16位字符."
error_list[602] = "用户名和密码不能为空."
error_list[603] = "用户名和密码长度小于 64 位."
error_list[604] = "时间参数不正确."
error_list[605] = "开始与结束时间不能相同."
error_list[610] = "未找到设备"
error_list[700] = "app登录失败"
error_list["up4"] = "网络不通，无法连接服务器"
error_list["up8"] = "服务器数据格式错误"
local out_put = "";
if (error_list[errorcode] == nil) then
out_put = 'unkown error'
else
out_put = error_list[errorcode]
end
return out_put
end
function get_ppp_error(errorcode)
local error_list = {}
error_list[0] = "正常"
error_list[-1] = "连接中"
error_list[646] = "此时不允许该帐户登录。"
error_list[647] = "此帐户被禁用。"
error_list[648] = "该帐户的密码已过期。"
error_list[649] = "帐户没有拨入的权限。"
error_list[678] = "远程计算机没有应答。"
error_list[691] = "因为用户名或密码在此域上无效，所以访问被拒绝。"
error_list[709] = "更改域上的密码时发生错误。密码可能太短或者可能与以前使用的密码匹配。"
local out_put = "";
if (error_list[errorcode] == nil) then
out_put = 'unkown error'
else
out_put = error_list[errorcode]
end
return out_put
end
function logger(str)
local logstr = fs.readfile("/tmp/wcy.log") or ""
fs.writefile("/tmp/wcy.log", logstr .. "\n" .. serialize_data(str))
end
function printTable(obj)
logger("printTable:")
for n, val in pairs(obj) do
if type(val)=="table" then
printTable(val)
else
logger("  "..n.."="..tostring(val))
end
end
end
function get_uptime()
local cmd = "cat /proc/uptime"
local data = exec(cmd)
if data==nil then
return 0
else
local t1,t2 = data:match("^(%S+) (%S+)")
return trim(t1)
end
end
function get_lan_wan_info(interface)
if interface == "lan" or interface == "wan" then
local all_ipv6 = get_all_ipv6()
local ipv4Resp = {}
local ipv6Resp = {}
local statusResp
local gate_wayResp
local dns_ipResp = {}
local macResp
local mtuResp
local uptimeResp
local resultResp
local netm = require "luci.model.network".init()
local net    = netm:get_network(interface)
if net then
local ethname= net:get_option_value("ifname")
local device = net and net:get_interface()
if interface == "wan" then
mtuResp = tostring(net:get_option_value("mtu"))
if mtuResp == nil or mtuResp == "" then
mtuResp = ""
end
end
if device and table.getn(device:ipaddrs()) > 0 then
for _, a in ipairs(device:ipaddrs()) do
ipv4Resp[#ipv4Resp+1] = {}
ipv4Resp[#ipv4Resp]['ip'] = a:host():string()
ipv4Resp[#ipv4Resp]['mask'] = a:mask():string()
end
end
if device and table.getn(device:ip6addrs()) > 0  then
for _, a in ipairs(device:ip6addrs()) do
ipv6Resp[#ipv6Resp+1] = {}
ipv6Resp[#ipv6Resp]['ip'] = a:host():string()
ipv6Resp[#ipv6Resp]['mask'] = a:mask():string()
for _,a in ipairs(all_ipv6) do
if a['ipv6'] == ipv6Resp[#ipv6Resp]['ip'] then
ipv6Resp[#ipv6Resp]['type'] = a['type']
end
end
end
end
if net:gwaddr()~=nil then
gate_wayResp = net:gwaddr()
end
if net:dnsaddrs() ~= nil and table.getn(net:dnsaddrs()) > 0 then
for _, ip in ipairs(net:dnsaddrs()) do
dns_ipResp[#dns_ipResp+1] = ip
end
end
if device and device:mac()~="00:00:00:00:00:00" then
macResp = device:mac()
end
if net:uptime()>0 then
uptimeResp = net:uptime()
else
uptimeResp = 0
end
local status = net:status()
if status=="down" then
statusResp = 0
elseif status=="up" then
statusResp = 1
elseif status=="connection" then
statusResp = 2
end
resultResp = true
return resultResp,ipv4Resp,ipv6Resp,statusResp,gate_wayResp,dns_ipResp,macResp,uptimeResp,mtuResp,wan_mac
else
resultResp = false
return resultResp
end
else
resultResp = false
return resultResp
end
end
function get_all_ipv6()
local ipobj = require "luci.ip"
local cmd = "ifconfig|grep inet6"--|awk -F'/' '{print $1}'
local data = execi(cmd)
local result = {}
for l in data do
l = trim(l)
local ipv6,mask, iptype = l:match(
'inet6 addr: ([^%s]+)/([^%s]+)%s+Scope:([^%s]+)'
)
if ipv6 then
result[#result+1] = {}
ipv6 = ipobj.IPv6(ipv6,"ffff:ffff:ffff:ffff::")
ipv6 = ipv6:host():string()
result[#result]['ipv6'] = ipv6
result[#result]['mask'] = mask
result[#result]['type'] = iptype
end
end
return result
end
function get_last2_pppoe_log()
local fd = io.open("/var/log/ppp.log", "r")
local last_log1 = {}
local last_log2 = {}
local last_log_all = {}
local last_log_tmp = {}
while true do
local ln = fd:read("*l")
if not ln then
break
else
if  ln:match("^[^%s]+%s+[^%s]+%s+[^%s]+%s+Plugin%s+rp") then
table.insert(last_log_tmp, "link start-------")
last_log1 = last_log2
last_log2 = last_log_tmp
last_log_tmp = {}
else
table.insert(last_log_tmp, ln)
end
end
end
last_log1 = last_log2
last_log2 = last_log_tmp
for i,v in ipairs(last_log1) do table.insert(last_log_all, v) end
for i,v in ipairs(last_log2) do table.insert(last_log_all, v) end
fd:close()
return last_log_all, last_log1,last_log2
end
function get_pppoe_status()
local last_log_all,last_log1,last_log2 = get_last2_pppoe_log()
local e
local ip
local last_line
local status
local have_ip = false
local have_ip = false
local conn_status = false
local remote_message
local special_dial
local special_dial_num
local uci = require "luci.model.uci"
_uci_real  = uci.cursor()
special_dial = _uci_real:get("network", "wan" ,"special_dial")
special_dial_num = _uci_real:get("network", "wan" ,"special_dial_num")
if not special_dial then special_dial = 0 end
if not special_dial_num then special_dial_num = 0 end
for i,v in ipairs(last_log_all) do
if have_ip and v == "link start-------" then conn_status = false end
if have_ip and v == "link start-------" then e_status = false end
if v:match('^[^%s]+%s+[^%s]+%s+[^%s]+%s+E=(%d+)%s+') then
e = v:match('^[^%s]+%s+[^%s]+%s+[^%s]+%s+E=(%d+)%s+')
end
if v:match('^[^%s]+%s+[^%s]+%s+[^%s]+%s+(Remote message)') == "Remote message" then
remote_message = v
end
if v:match('^[^%s]+%s+[^%s]+%s+[^%s]+%s+local%s+IP%s+address%s+([^%s]+)') then
ip = v:match('^[^%s]+%s+[^%s]+%s+[^%s]+%s+local%s+IP%s+address%s+([^%s]+)')
have_ip = true
conn_status = true
end
last_line = v
end
if conn_status then
status=0
elseif e then
status= e
else
status=-1
end
return status,last_line,remote_message,special_dial,special_dial_num
end
function get_wan_contact_info()
local typeResp
local mobile_typeResp
local mobile_dev_usbResp
local pppoe_nameResp
local pppoe_passwdResp
local static_ipResp
local static_gwResp
local static_dnsResp
local static_dns2Resp
local static_maskResp
local macaddrResp
local resultResp
local tnetwork = require "luci.model.tnetwork".init()
local tnetwork_defaults = tnetwork:get_defaults()
if tnetwork_defaults then
static_ipResp   = tnetwork_defaults:get("static_ip")
static_gwResp   = tnetwork_defaults:get("static_gw")
static_dnsResp  = tnetwork_defaults:get("static_dns")
static_dns2Resp  = tnetwork_defaults:get("static_dns2")
static_maskResp = tnetwork_defaults:get("static_mask")
peerdnsResp = tnetwork_defaults:get("peerdns")
override_dnsResp = tnetwork_defaults:get("override_dns")
override_dns2Resp = tnetwork_defaults:get("override_dns2")
pppoe_nameResp = tnetwork_defaults:get("pppoe_name")
pppoe_passwdResp = tnetwork_defaults:get("pppoe_passwd")
mobile_dev_usbResp = tnetwork_defaults:get("mobile_dev_usb")
typeResp = tnetwork_defaults:get("selected")
local netmd = require "luci.model.network".init()
local wan = netmd:get_network("wan")
if wan ~= nil then
typeResp = wan:proto()
end
if typeResp == "mobile" or typeResp == "3g" then
typeResp = "mobile"
mobile_typeResp = tnetwork_defaults:get("mobile_type")
elseif typeResp == "dhcp" or typeResp == "static" then
if typeResp == "static" then
static_ipResp = tnetwork_defaults:get("static_ip")
static_gwResp = tnetwork_defaults:get("static_gw")
static_dnsResp = tnetwork_defaults:get("static_dns")
static_dns2Resp = tnetwork_defaults:get("static_dns2")
static_maskResp = tnetwork_defaults:get("static_mask")
end
elseif typeResp == "pppoe" then
end
macaddrResp = wan:get_option_value("macaddr")
return typeResp,mobile_typeResp,mobile_dev_usbResp,pppoe_nameResp,pppoe_passwdResp,static_ipResp,static_gwResp,static_dnsResp,static_dns2Resp,static_maskResp, macaddrResp,peerdnsResp,override_dnsResp,override_dns2Resp
else
typeResp = 0
return typeResp
end
end
function get_vpn_dev()
local cmd = "route -n |grep tun | awk '{print $NF}' | head -1"
local data = exec(cmd)
if data==nil then
return nil
else
return trim(data)
end
end
function get_wifi_device_status()
local status = require "luci.tools.status"
local wifi_ifname = "";
local wifi_ssid = "";
local wifi_device = "";
local wifi_status = "0";
local wifi_encryption = "";
local wifi_channel = "0";
local wifi_mode = "";
local wifi_ssidprefix = "";
if status then
for i,user in ipairs(status:wifi_networks()) do
local network_index = 1
if user["up"] then
wifi_status = "1"
end
wifi_ifname = user["networks"][network_index]["ifname"];
wifi_device = user["device"]..".network"..network_index
wifi_ifname = user["networks"][network_index]["ifname"]
wifi_ssid   = user["networks"][network_index]["ssid"]
wifi_encryption = user["networks"][network_index]["encryption_src"]
wifi_channel 	= user["networks"][network_index]["channel"]
wifi_mode 		= user["networks"][network_index]["mode"]
wifi_ssidprefix 		= user["networks"][network_index]["ssidprefix"]
end
end
if not wifi_ssidprefix then
wifi_ssidprefix = ""
end
if wifi_channel == nil or wifi_channel == "" then
local hiwifi_net = require "hiwifi.net"
local hcwifi = require "hcwifi"
local WIFI_IFNAMES = hiwifi_net.get_wifi_ifnames()
local IFNAME = WIFI_IFNAMES[1]
local KEY_CH = "ch"
wifi_channel = hcwifi.get(IFNAME, KEY_CH)
end
return wifi_status,wifi_device,wifi_ifname,wifi_ssid,wifi_encryption,wifi_channel,wifi_mode,wifi_ssidprefix
end
function available_mac(mac)
local datatypes = require "luci.cbi.datatypes"
mac = format_mac(mac)
if not datatypes.macaddr(mac) then
return false
end
if mac == "ff:ff:ff:ff:ff:ff" or mac == "00:00:00:00:00:00" then
return false
end
local nixio = require "nixio"
local bit  = nixio.bit
local a = mac:match(
"^([a-fA-F0-9]+):([a-fA-F0-9]+):([a-fA-F0-9]+):" ..
"([a-fA-F0-9]+):([a-fA-F0-9]+):([a-fA-F0-9]+)$"
)
local a2 = string.sub(a,2,2)
if a2 ~= "0" and a2 ~= "2" and a2 ~= "4" and a2 ~= "6" and a2 ~= "8" and a2 ~= "a" and a2 ~= "c" and a2 ~= "e" then
return false
end
return true
end
function format_mac(mac)
return string.lower(string.gsub(mac,"-",":"));
end
function format_mac_saveable(mac)
return string.lower(string.gsub(mac,":","-"));
end
function get_adv_menu()
local adv_menu = {}
adv_menu = {
{
path={"admin_web", "network","setup","lan"},
info="局域网 IP 地址"
},
{
path={"admin_web", "network","setup","dhcp"},
info="局域网 DHCP 服务"
},
{
path={"admin_web", "network","setup","mtu"},
info="网络 MTU 设置"
},
{
path={"admin_web", "network","setup","ppp_adv"},
info="PPP 高级设置"
},
{
path={"admin_web", "network","setup","mac"},
info="MAC 地址克隆"
},
{
path={"admin_web", "network","upnp"},
info="UPNP 状态"
},
{
path={"admin_web", "network","l2tp"},
info="L2TP/PPTP"
},
{
path={"admin_web", "wifi","setup","channel"},
info="无线信道设置"
},
{
path={"admin_web", "wifi","setup","mac_filter"},
info="无线 MAC 访问控制"
},
{
path={"admin_web", "system","systime"},
info="系统时间管理"
},
{
path={"admin_web", "system","upgrade"},
info="路由器升级管理"
},
{
path={"admin_web", "system","reboot_reset"},
info="恢复出厂设置"
},
{
path={"admin_web", "system","disk"},
info="路由器诊断"
},
}
return adv_menu
end
function output_adv_menu()
local http = require "luci.http"
local dispatcher = require "luci.dispatcher"
local adv_menu = get_adv_menu()
local request_uri = http.getenv("REQUEST_URI")
for _, menus in pairs(adv_menu) do
local menus_info = menus['info']
local menus_path_s = table.concat(menus['path'],"/")
local show = request_uri:match(menus_path_s)
local select_html = ((show) and 'class="selected"' or "")
local menus_path_val
menus_path_val = menus_path_s:gsub("admin_web/", "")
http.write('<a href="'..dispatcher.build_url(unpack(menus['path']))..'" '..select_html..'>'..menus_info..'</a>')
end
end
function inc_html_header_end()
local inc_path = "/etc/plugin/inc_html_header_end"
local return_html =get_dirfile_content(inc_path)
return return_html
end
function inc_html_body_end()
local inc_path = "/etc/plugin/inc_html_body_end"
local return_html =get_dirfile_content(inc_path)
return return_html
end
function inc_html_loginpage_body_end()
local inc_path = "/etc/plugin/inc_html_loginpage_body_end"
local return_html =get_dirfile_content(inc_path)
return return_html
end
function replace_html_footer()
local inc_path = "/etc/plugin/replace_html_footer"
local return_html =get_dirfile_content(inc_path)
local ver = get_sys_board().." - "..tw.get_version():match("^([^%s]+)")
local mac = tw.get_mac()
if return_html == "" or return_html == nil then
return false
end
return_html = string.gsub(return_html,"$ver",ver)
return_html = string.gsub(return_html,"$mac",mac)
return return_html
end
function get_dirfile_content(inc_path)
local popen = io.popen
local file_path
local cont
local return_html = ""
for filename in popen('ls "'..inc_path..'"'):lines() do  --Linux
file_path = inc_path.."/"..filename
cont = fs.readfile(file_path)
return_html = return_html..cont
end
return return_html
end
function shell_safe_str(str)
str = str:gsub(";","")
str = str:gsub("&","")
str = str:gsub('"','')
str = str:gsub("'","")
str = str:gsub('`','')
return str
end
function fliter_unsafe(str)
if str ~= "" and str ~= nil then
return string.gsub(string.gsub(string.gsub(string.gsub(str, "<", " "),'"'," "),"'"," "),">"," ")
end
return str
end
function get_auto_wan_type_code()
local s = require "luci.tools.status"
local lines = execi('autowantype '..s.global_wan_ifname()..' 2000')
for l in lines do
local autowantype = l:match('^autowantype:%s+(%d+)')
if autowantype then
return tonumber(autowantype)
end
end
return false
end
function get_device_list_brief()
local net = require "hiwifi.net"
local sys = require "luci.sys"
local wifi_device= net.get_wifi_client_list()
local devicesResp = {}
local devices_mac_exist = {}
if wifi_device then
for _, net in ipairs(wifi_device) do
table.insert(devicesResp, {
['ip'] = "",
['mac'] = net['mac'],
['type'] = "wifi",
['type_wifi'] = net['type_wifi'],
['name'] = "",
['rpt'] = net['rpt'],
['signal'] = net['signal']
})
table.insert(devices_mac_exist, net['mac'])
end
end
local brlantable = sys.net.brlantable()
local type_tmp
local signal_tmp
if brlantable then
for _, net in ipairs(brlantable) do
if net['is local'] ~= "yes" then
if not in_array(net['mac addr'],devices_mac_exist) then --排除 wifi 中已经有的
if net['port no']=="1" then -- 有线
type_tmp = "line"
signal_tmp = ""
table.insert(devicesResp, {
['ip'] = "",
['mac'] = net['mac addr'],
['type'] = type_tmp,
['name'] = "",
['signal'] = signal_tmp
})
end
end
end
end
end
return devicesResp
end
function  in_array(b,list)
if not list then
return false
else
if list then
for k, v in pairs(list) do
if v==b then
return true
end
end
end
end
end
local traffic_path = "/proc/net/smartqos/stat"
function get_traffic_list()
local r = {}
local total = {}
if  fs.access(traffic_path) then
local rx_bytes = 0
local rx_pkts = 0
local tx_bytes = 0
local tx_pkts = 0
local start_get = false
local line_mark
local local_down_max = 0
local local_up_max = 0
local _,_,_,_,_,_,local_mac_1,_,_,local_mac_2 = get_lan_wan_info("lan")
if not local_mac_1  then local_mac_1 = local_mac_2 end
for line in io.lines(traffic_path) do
if start_get then
local ip, mac, down, up, down_max, up_max= line:match('^([^%s]+)%s+([^%s]+)%s+([^%s]+)%s+([^%s]+)%s+([^%s]+)%s+([^%s]+)')
if ip then
table.insert(r, {
['ip'] = ip,
['mac'] = mac,
['up'] = up,
['down'] = down,
['up_max'] = up_max,
['down_max'] = down_max
})
if format_mac(mac) == format_mac(local_mac_1) then
local_down_max = down_max
local_up_max = up_max
end
end
local t_down, t_up, t_down_max, t_up_max= line:match('^%s+([^%s]+)%s+([^%s]+)%s+([^%s]+)%s+([^%s]+)%s+')
if t_down then
total['down'] = t_down
total['up'] = t_up
total['down_max'] = t_down_max
total['up_max'] = t_up_max
end
else
line_mark = line:match("^=+")
if line_mark then
start_get = true
end
end
end
total['down_max'] = tonumber(total['down_max'] - local_down_max)
total['up_max'] = tonumber(total['up_max'] - local_up_max)
if total['down_max']<0 then total['down_max']=0 end
if total['up_max']<0 then total['up_max']=0 end
end
return r,total
end
local traffic_total_path = "/proc/net/smartqos/total_traffics_cache"
function get_traffic_total_list()
local r = {}
if  fs.access(traffic_total_path) then
local start_get = false
local line_mark
for line in io.lines(traffic_total_path) do
if start_get then
local mac, down, up= line:match('^([^%s]+)%s+([^%s]+)%s+([^%s]+)')
if mac then
table.insert(r, {
['mac'] = mac,
['down'] = down,
['up'] = up
})
end
else
line_mark = line:match("^=+")
if line_mark then
start_get = true
end
end
end
end
return r
end
function get_traffic_total()
local r = {}
if  fs.access(traffic_path) then
local start_get = false
local frist_line = true
local line_mark
for line in io.lines(traffic_path) do
if start_get then
if not frist_line then break end
local down, up, down_max, up_max= line:match('^%s+([^%s]+)%s+([^%s]+)%s+([^%s]+)%s+([^%s]+)%s+')
r['down'] = down
r['up'] = up
r['down_max'] = down_max
r['up_max'] = up_max
frist_line = false
else
line_mark = line:match("^=+")
if line_mark then
start_get = true
end
end
end
end
return r
end
function check_upgrade()
local hiwifi = require "hiwifi.firmware"
local code,update_info = hiwifi.get_update_info()
local tw = require "tw"
local local_version = tw.get_version()
if code == 0 then
versionResp = update_info.version
if local_version ~= versionResp then
sizeResp =  update_info.size
chagelogResp =  update_info.chagelog
needupgradeResp = 1
else
needupgradeResp = 0
end
return code, needupgradeResp , update_info
else
return code, 0 , "error"
end
end
function get_status_wan()
local cmd = "/etc/init.d/network status wan"
local status = json.Decode(exec(cmd))
return status
end
function edit_agreemt_file(conf_name,status)
set_config_file("/etc/agreement",conf_name,status)
end
function set_config_file(fielpath,conf_name,status)
local rv = { }
local fd = io.open(fielpath, "r")
local action_ok = false
local contant = ""
while true do
local ln = fd:read("*l")
if not ln then
break
else
local name,status_tmp = ln:match("^(%S+):(%S+)")
if name and status_tmp then
if name == conf_name then
status_now = status
action_ok = true
else
status_now = status_tmp
end
contant = contant .. name.. ":" .. status_now .. "\n"
end
end
end
if action_ok == false then
contant = contant .. conf_name.. ":" .. status .. "\n"
end
fd:close()
fd = io.open(fielpath, "w")
fd:write(contant)
fd:close()
end
function isExistModule(module)
local function requiref(module)
require(module)
end
res = pcall(requiref,module)
if not(res) then
return false
else
return true
end
end
function split_short_time(time)
if tonumber(time) then
local int_time = tonumber(time)
local int_hour = math.floor(int_time/100)
local int_min = int_time - int_hour*100
if int_hour>23 or int_min>59 then
return false
end
return int_hour,int_min
else
return false
end
end
local wifi_sleep_status_file = "/etc/app/wifi_sleep.status"
function get_wifi_sleep()
local startResp,endResp
fd = io.open(wifi_sleep_status_file, "r")
local ln = fd:read("*l")
local result = ln:match("^(%S+),(%S+)")
if result then
startResp,endResp = ln:match("^(%S+),(%S+)")
end
fd:close()
return startResp,endResp
end
function delay_exec(command,time)
if not time or time == "" then
return false
end
exec("/usr/sbin/hwf-at "..time.." '"..command.."' >/dev/null 2>/dev/null")
end
function delay_exec_wifi(time)
return delay_exec("/sbin/wifi",time)
end
function delay_exec_ifwanup(time)
return delay_exec("/sbin/ifup wan",time)
end
function delay_exec_exam_act(time)
exec("/usr/sbin/hwf-at "..time.." 'lua -e \"local util = require \\\"luci.util\\\";local result = util.do_exam_real();\"'");
end
function delay_exec_update(time)
exec("/usr/sbin/hwf-at "..time.." 'lua -e \"local firmware = require \\\"hiwifi.firmware\\\";local code,info = firmware.get_update_info();firmware.atomic_download_upgrade(info);\"'");
end
function get_channel_rank(aplist)
local rpt_list_hash = {}
local wifi_client_list = get_wifi_client_list()
for i, d in ipairs(wifi_client_list) do
if not d['rpt'] then
rpt_list_hash[format_mac(d['mac'])] = true
end
end
local res={0,0,0,0,0,0,0,0,0,0,0,0,0}
for key, v in pairs(aplist) do
if not rpt_list_hash[format_mac(v['bssid'])] then -- 排除小卫星
local index =0
local a1=0.75
local a2=0.375
index=v.channel+0
if index<14 then
res[index]=res[index]+v.rssi
end
index=v.channel+1
if index<14 then
res[index]=res[index]+v.rssi*a1
end
index=v.channel-1
if index>0 then
res[index]=res[index]+v.rssi*a1
end
index=v.channel+2
if index<14 then
res[index]=res[index]+v.rssi*a2
end
index=v.channel-2
if index>0 then
res[index]=res[index]+v.rssi*a2
end
end
end
local max=0;
for key, v in pairs(res) do
if v>max then
max=v
end
end
for key, v in pairs(res) do
res[key]=res[key]/max
end
return res
end
local traffic_folder = "/tmp/data/traffic_his/"
local total_traffic_folder = "/tmp/data/traffic_total_his/"
function get_traffic_day_total(date_n,cut_time)
local r={}
local file_path = traffic_folder..date_n.."/total"
local r_tmp=get_traffic_day(file_path,date_n,cut_time)
if r_tmp then
r = r_tmp
end
return r
end
function get_traffic_day_dev(mac,date_n,cut_time)
mac=format_mac_saveable(mac)
local file_path = traffic_folder..date_n.."/"..mac
local r={}
local r_tmp=get_traffic_day(file_path,date_n,cut_time)
if r_tmp then
r = r_tmp
end
return r
end
function get_traffic_day_dev_range(mac,date_n,max_range)
mac=format_mac_saveable(mac)
local file_path = traffic_folder..date_n.."/"..mac
local r={}
local t_det
local last_time=0
if  fs.access(file_path) then
local time_tmp={}
local idx=1
local cnt=1
r[cnt] = {}
local move_next
for line in io.lines(file_path) do
local time, traffic= line:match('^([^%s]+)%s+([^%s]+)')
t_det = os.date("*t", tonumber(time))
if t_det.min < 10 then
t_det.min = "0"..t_det.min
end
if idx == 2 and tonumber(time)-last_time>tonumber(max_range) then	-- 寻找结束时间时，时间差小于 max_range 则不记录
if r[cnt][2] then
cnt = cnt + 1
end
r[cnt] = {}
idx = 1
r[cnt][idx] = tonumber(t_det.hour..t_det.min)
else
r[cnt][idx] = tonumber(t_det.hour..t_det.min)
idx = 2
end
last_time = tonumber(time)
end
end
if os.time()-last_time<tonumber(max_range) then
r[#r][2]=nil
end
return r
end
function get_traffic_day(traf_file,date_n,cut_time)
local r = {}
local data = {}
local time_tmp={}
if  fs.access(traf_file) then
local idx
for line in io.lines(traf_file) do
local time, traffic= line:match('^([^%s]+)%s+([^%s]+)')
idx = math.modf(tonumber(time)/cut_time+1)*cut_time
if time_tmp[idx] then
if tonumber(traffic) > time_tmp[idx] then
time_tmp[idx] = tonumber(traffic)
end
else
time_tmp[idx] = tonumber(traffic)
end
end
end
local begin_time = get_time_format(date_n)
for i=tonumber(begin_time),tonumber(begin_time)+3600*24-1,cut_time do
if time_tmp[i] then
table.insert(r, time_tmp[i])
else
table.insert(r, -1)
end
end
return r
end
function get_time_his_device_list(date_n,force_offline)
local net = require "hiwifi.net"
local r = {}
local data = {}
local popen = io.popen
local file_path
local mac_name_hash = {}
local mac_online_hash = {}
local mac_type_hash = {}
local mac_show
local cont
local r_out={}
local interface = "lan"
local _,_,_,_,_,_,local_mac_1,_,_,local_mac_2 = get_lan_wan_info(interface)
if not local_mac_1  then local_mac_1 = local_mac_2 end
local file_path_all = traffic_folder..date_n
for mac in popen('ls "'..file_path_all..'"'):lines() do  --Linux
mac_show = format_mac(mac)
if available_mac(mac) and format_mac(local_mac_1) ~= mac_show then
file_path = file_path_all.."/"..mac
for line in io.lines(file_path) do
local time, traffic= line:match('^([^%s]+)%s+([^%s]+)')
if r[mac_show] then
r[mac_show] = r[mac_show] + 1
else
r[mac_show] = 1
end
end
end
end
local device_names = require "hiwifi.device_names"
local dhcp_mac_ip_hash = {}
local dhcp_devicesResp = net.get_dhcp_client_list()
if dhcp_devicesResp then
for _, net in ipairs(dhcp_devicesResp) do
mac_name_hash[net['mac']] = net['name']
dhcp_mac_ip_hash[net['mac']] = net['ip']
if net['name'] then
local result_devicename = device_names.refresh(net['mac'],net['name'])
end
end
end
local re_name
local device_name_all = device_names.get_all()
table.foreach(device_name_all, function(mac_one, re_name)
mac_name_hash[mac_one] = re_name
end)
local device_online = get_device_list_brief()
if force_offline ~= true then
for _, d in pairs(device_online) do
mac_online_hash[d['mac']] = true
mac_type_hash[d['mac']] = d['type']
end
end
local mac_rpt_hash = get_mac_rpt_hash()
local is_rpt
local traffic_qos_hash_v = traffic_qos_hash()
for mac, time in pairs(r) do
if mac_name_hash[mac] then
re_name = mac_name_hash[mac]
else
re_name = ""
end
if mac_online_hash[mac] and force_offline ~= true then
onl_tmp = 1
else
onl_tmp = 0
end
if mac_rpt_hash[mac] then
is_rpt = true
else
is_rpt = false
end
local type_tmp = mac_type_hash[mac]
if type_tmp == nil then
type_tmp = "wifi"
end
local qos_up_tmp
local qos_down_tmp
local qos_status_tmp
if traffic_qos_hash_v[mac] then
qos_up_tmp = traffic_qos_hash_v[mac]['up']
qos_down_tmp = traffic_qos_hash_v[mac]['down']
qos_status_tmp = 1
else
qos_up_tmp = 0
qos_down_tmp = 0
qos_status_tmp = 0
end
local traffic_c=0
local mac_saveable=format_mac_saveable(mac)
local traffic_c_path = total_traffic_folder..date_n.."/"..mac_saveable
if fs.access(traffic_c_path) then
traffic_c = tonumber(fs.readfile(traffic_c_path))
end
table.insert(r_out, {
['mac'] =  mac,
['name'] = re_name,
['online'] = onl_tmp,
['type'] = type_tmp,
['qos_up'] = qos_up_tmp,
['qos_down'] = qos_down_tmp,
['qos_status'] = qos_status_tmp,
['traffic'] = traffic_c,
['comid'] = 0,
['time'] = time,
['rpt'] = is_rpt
})
end
return r_out
end
function get_mac_rpt_hash()
local mac_rpt_hash = {}
local wifi_client_list = get_wifi_client_list()
local cnt=0
for i, d in ipairs(wifi_client_list) do
if d['rpt'] then
mac_rpt_hash[format_mac(d['mac'])]=true
cnt = cnt + 1
end
end
return mac_rpt_hash,cnt
end
function get_wifi_client_list()
local net = require "hiwifi.net"
local wifi_device = net.get_wifi_client_list()
local devicesResp = {}
if wifi_device then
for _, net in ipairs(wifi_device) do
table.insert(devicesResp, {
['ip'] = "",
['mac'] = net['mac'],
['type'] = "wifi",
['name'] = "",
['rpt'] = net['rpt'],
['signal'] = net['signal']
})
end
end
return devicesResp
end
function devctl(ip, cmd)
local cmd = "devctl '" .. ip .. "' '" .. cmd .. "'"
local data = exec(cmd)
return data
end
function get_dev_build(ip)
local data = devctl(ip, 'cat /etc/.build')
return data
end
function get_day_begin_time()
local t_now = os.time()
local t_det = os.date("*t", t_now)
local t_time = os.time({day=t_det.day, month=t_det.month, year=t_det.year, hour=0, minute=0, second=0})
return t_time
end
function get_date_format(days_befroe)
local t_now = os.time()
if days_befroe ~= nil then
t_now = t_now - 3600*24*tonumber(days_befroe)
end
return os.date("%y%m%d",t_now)
end
function get_time_format(date_t)
local year_t = tonumber("20"..string.sub(date_t,1,2))
local month_t = tonumber(string.sub(date_t,3,4))
local day_t = tonumber(string.sub(date_t,5,6))
return os.time({["year"]=year_t,["month"]=month_t,["day"]=day_t})-3600*12
end
function delete_before_time_file(fielpath,begin_time,delete_file)
local rv = { }
local fd = io.open(fielpath, "r")
local action_ok = false
local contant = ""
while true do
local ln = fd:read("*l")
if not ln then
break
else
local time,traff = ln:match('^([^%s]+)%s+([^%s]+)')
if time then
if tonumber(time) > tonumber(begin_time) then
contant = contant .. ln .. "\n"
end
end
end
end
fd:close()
fd = io.open(fielpath, "w")
fd:write(contant)
fd:close()
if contant == "" and delete_file == true then
exec("rm -rf "..fielpath.." ")
end
end
function set_exam_act_cache(act)
return fs.writefile("/tmp/exam_act_cache",  serialize_data(act))
end
function get_exam_act_cache()
local act_cache = restore_data(fs.readfile("/tmp/exam_act_cache"))
fs.writefile("/tmp/exam_act_cache",  "")
return act_cache
end
function do_exam_real()
local act = get_exam_act_cache()
local mobile_base = require("hiwifi.mobileapp.base")
local actid = act["actid"]
local hiwifi_net = require "hiwifi.net"
local result_ctl = hiwifi_net.do_wifi_ctl_scan()
local wifi_status,wifi_device,wifi_ifname,wifi_ssid,wifi_encryption,wifi_channel,wifi_mode,wifi_ssidprefix = get_wifi_device_status()
for _, exam_item in ipairs(act['exam_item_list']) do
local time_b = os.time()
local do_desc
local do_detail_data = ""
local do_optimize_data = ""
local do_status
local do_item_id = exam_item['item_id']
do_desc="正常"
do_status=2
if do_item_id == 102 then -- DNS 状态
local typeResp,mobile_typeResp,mobile_dev_usbResp,pppoe_nameResp,pppoe_passwdResp,static_ipResp,static_gwResp,static_dnsResp,static_dns2Resp,static_maskResp,macaddrResp,peerdnsResp,override_dnsResp,override_dns2Resp = get_wan_contact_info()
if peerdnsResp == "0" then
do_status= 2
do_detail_data= '{"override_dns":"'..override_dnsResp..'","override_dns2":"'..override_dns2Resp..'"}'
else
do_status= 1
end
elseif do_item_id == 103 then -- 固件版本
local code, needupgradeResp,update_info = check_upgrade()
if needupgradeResp == 1 then
do_status= -1
else
do_status= 1
end
elseif do_item_id == 201 then -- WiFi 信道拥挤度
local net = require "hiwifi.net"
local aplist={}
aplist["aplist"] = net.get_aplist()
aplist["wifi_channel"] = wifi_channel
do_detail_data = json.Encode(aplist)
do_status= 1
elseif do_item_id == 202 then -- 连接设备流量
local protocol = require "luci.http.protocol"
local urlencode = protocol.urlencode
do_detail_data= json.Encode(get_traffic_total())
do_status=1
elseif do_item_id == 203 then -- wifi 信号强度
local netmd = require "luci.model.network".init()
local net = netmd:get_wifinet("radio0.network1")
if net then
if net:active_mode()=='Master' then
txpwrResp = tostring(net:txpwr())
end
do_detail_data = '{"txpwr":"'..txpwrResp..'"}'
end
do_status= 1
elseif do_item_id == 501 then-- WiFi 密码
if wifi_encryption == "none" then
do_status=-1
else
do_status=1
end
elseif do_item_id == 502 then-- 路由器密码
local sys = require "luci.sys"
local is_defult_password = sys.user.checkpasswd("root", "admin")
if is_defult_password then
do_status=-1
else
do_status=1
end
end
if do_status ~= nil then
mobile_base.mobile_app_curl("Exam/addExamResultDetial",
{
actid=actid,
status=do_status,
item_id=exam_item['item_id'],
detail_data=do_detail_data
})
local time_sp = os.time() - time_b
end
end
end
function traffic_qos_hash()
local traffic_qos_hash_v = {}
local device_qos = require "hiwifi.device_qos"
local traffic_qos_all = device_qos.get_all()
table.foreach(traffic_qos_all, function(mac_one, traff)
mac_one = format_mac(mac_one)
traffic_qos_hash_v[mac_one] = {}
traffic_qos_hash_v[mac_one]['up'] = traff['up']
traffic_qos_hash_v[mac_one]['down'] = traff['down']
traffic_qos_hash_v[mac_one]['name'] = traff['name']
end)
return traffic_qos_hash_v
end
