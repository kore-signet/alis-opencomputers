local term = require("term")
local gpu = term.gpu()

local renderer = {}

function renderer:render_tag(tag)
  if tag["@fg"] ~= nil then
    gpu.setForeground(tonumber(tag["@fg"]))
  else
    gpu.setForeground(0xFFFFFF)
  end

  if tag["@bg"] ~= nil then
    gpu.setBackground(tonumber(tag["@bg"]))
  else
    gpu.setBackground(0x000000)
  end

  term.write(tag:value() .. "\n")
end

function renderer:render(tag)
  if tag:name() == "script" then return nil end

  if tag:children()[1] ~= nil then
    for _, v in ipairs(tag:children()) do
      self:render(v)
     end
  else
    self:render_tag(tag)
  end
end

function renderer:main_loop(browser)
  while true do
    gpu.setBackground(0x000000)
    term.clear()

    for _, v in ipairs(browser.dom:children()) do
      self:render(v)
    end

    event.pull("kitten_render_tick")
  end
end

return renderer
