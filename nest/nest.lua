local fs = require("filesystem")
local m = require("component").modem
local event = require("event")

local nest = {}

function nest:load_files()
  self.files = {}
  for f in fs.list("/usr/web") do
    self.files[f] = "/usr/web/" .. f
  end
end

function nest:respond(name,ra,sa,port,d,file)
    if ra == sa then
      return nil
    end
    
    if self.files[file] ~= nil then
      local f = fs.open(self.files[file],"r")
      local complete = false
      while not complete do
        local chunk = f:read(8092)
        if chunk == nil then
          complete = true
        end
        m.send(sa,80,chunk,complete)
      end
      f:close()
    end
end

function nest:init()
  m.open(80)
  self:load_files()
end

nest:init()

while true do
  local n, ra, sa, port, distance, file = event.pull("modem_message",nil,nil,80)
  nest:respond(n,ra,sa,port,distance,file)
end
