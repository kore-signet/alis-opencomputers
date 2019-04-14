local fs = require("filesystem")
local m = require("component").modem
local event = require("event")

local nest = {}

function nest:load_files()
  self.files = {}
  for f in fs.list("/home/web") do
    self.files[f] = "/home/web/" .. f
  end
end

function nest:respond(name,ra,sa,port,d,kind,file)
    if port == 80 then
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
end

function nest:init()
  m.open(80)
  self:load_files()
  event.listen("modem_message",nest.respond(self))
end

nest:init()