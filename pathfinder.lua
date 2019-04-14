local m = require("component").modem
local event = require("event")
local s = require("serialization")

local pathfinder = {}

function pathfinder:load_domains()
  local f = io.read("pathes.data","r")
  self.paths = s.unserialize(f:read("*all"))
end

function pathfinder:respond(ra,sa,port,d,req)
  if self.paths[req] ~= nil then
    m.send(sa,53,self.paths[req])
  end
end

function nest:init()
  m.open(53)
  self:load_domains()
  event.listen("modem_message",self.respond(self))    
end

nest:init()