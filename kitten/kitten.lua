local xml = require("xmlSimple")
local renderer = require("kittenrenderer")
local thread = require("thread")
local component = require("component")
local event = require("event")
local shell = require("shell")
local s = require("serialization")

local browser = {}

function browser:parse_dom(page,page_name)
  self.dom = xml.newParser()
  self.dom = self.dom:ParseXmlText(page)

  self.scripts = {}
  self.script_env = {}
  self.script_env["browser"] = self
  local counter = 0
  for _, v in ipairs(self.dom:children()) do
    if v:name() == "script" then
      print(v:value())
      local path = "/tmp/kitten/" .. page_name .. ":" .. counter  .. ".lua"
      local f = io.open(path,"w")
      f:write(v:value())
      f:close()
      local loaded_script = loadfile(path,self.script_env)()
      table.insert(self.scripts,loaded_script)
      counter = counter + 1
    end
  end
end

function browser:spawn_renderer()
  return thread.create(renderer.main_loop(renderer,self))
end

function browser:dns_get(addr)
  self.m.send(self.dns,53,addr)

  local _, _, _, _, _, r = event.pull("modem_message",nil,self.dns,53)
  return r
end

function browser:network_get(addr,file)
  local trueaddr = self:dns_get(addr)
  self.m.send(trueaddr,80,file)

  local complete = false
  local page = ""
  while not complete do
    local _, _, _, _, _, chunk, last = event.pull("modem_message",nil,trueaddr,80)
    if chunk ~= nil then
      page = page .. chunk
    end
    complete = last
  end
  self:parse_dom(page)
end

function browser:file_get(file)
  local f = io.open(file,"r")
  self:parse_dom(f:read("*all"))
  f:close()
end

function browser:init(dns)
  self.m = component.modem
  if self.m ~= nil then
    self.m.open(80)
    self.m.open(53)
  end

  if dns == nil then
    local kitten_f = io.open("/etc/kitten.conf","r")
    local kitten_conf = s.unserialize(kitten_f:read("*all"))
    kitten_f:close()
    self.dns = kitten_conf["dns"]
  else
    self.dns = dns
  end
end

function browser:run()
  local renderer = self:spawn_renderer()
  event.pull("key_down",nil,nil,0x10)
  renderer:suspend()
  os.exit()
end

local args, ops = shell.parse(...)

if args[1] == "setdns" then
  local kitten_f = io.open("/etc/kitten.conf","w")
  local kitten_conf = {dns=args[2]}
  kitten_f:write(s.serialize(kitten_conf))
  kitten_f:close()
elseif args[1] == "file" then
  browser:init(nil)
  browser:file_get(args[2])
  browser:run()
else
  browser:init(ops["dns"])
  browser:network_get(args[1],args[2])
  browser:run()
end
