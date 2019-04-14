local xml = require("xmlSimple")
local renderer = require("renderer")
local thread = require("thread")
local component = require("component")
local event = require("event")

function network_filter(name,a,b,c, ...)
  if c == 80 then
    return true
  else
    return false
  end
end

local browser = {}

function browser:parse_dom(page)
  self.dom = xml.newParser()
  self.dom = self.dom:ParseXmlText(page)
  
  self.scripts = {}
  local counter = 0
  for _, v in ipairs(self.dom:children()) do
    if v:name() == "script" then
      print(v:value())
      local f = io.open(counter  .. ".lua","w")
      f:write(v:value())
      f:close()
      local loaded_script = require(tostring(counter))
      table.insert(self.scripts,loaded_script)
      counter = counter + 1
    end
  end
end

function browser:spawn_renderer()
  thread.create(renderer.main_loop(renderer,self))
end

function browser:dns_get(addr)
  local m = component.modem
  m.send(self.dns,53,addr)
  
  local _, _, _, _, r = event.pull("modem_message")
  return r
end

function browser:network_get(addr,file)
  local m = component.modem
  
  m.send(dns_get(addr),80,file)
  
  local complete = false
  local page = ""
  while not complete do
    local _, _, _, _, chunk, last = event.pullFiltered(network_filter)
    page = page .. chunk
    complete = last
  end
  self:parse_dom(page)
end

function browser:init(dns)
  self.dns = dns
end

local f = io.open("test.ocml","r")
local content = f:read("*all")
f:close()


browser:network_get("athenas.com","index")
browser:spawn_renderer()

os.sleep(60)