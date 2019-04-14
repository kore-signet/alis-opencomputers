local m = require("component").modem
local event = require("event")
local s = require("serialization")
local shell = require("shell")

local pathfinder = {}

function pathfinder:load_domains()
  local f = io.open("/usr/misc/paths.data","r")
  local c = f:read("*all")
  self.paths = s.unserialize(c)
  f:close()
end

function pathfinder:save_domains()
  local f = io.open("/usr/misc/paths.data","w")
  f:write(s.serialize(self.paths))
  f:close()
end

function pathfinder:respond(ra,sa,port,d,req)
  if ra == sa then
    return nil
  end

  if self.paths[req] ~= nil then
    local a = self.paths[req]
    m.send(sa,53,a)
  end
end

function pathfinder:init()
  m.open(53)
  self:load_domains()
end

pathfinder:init()

local args, opts = shell.parse(...)

if args[1] == "update" then
  for k, v in pairs(opts) do
    pathfinder.paths[k] = v
  end
  pathfinder:save_domains()
elseif args[1] == "delete" then
  for i, v in ipairs(args) do
    pathfinder.paths[v] = nil
  end
else
  while true do
    local n, ra, sa, port, d, req = event.pull("modem_message")
    pathfinder:respond(ra,sa,port,d,req)
  end
end
