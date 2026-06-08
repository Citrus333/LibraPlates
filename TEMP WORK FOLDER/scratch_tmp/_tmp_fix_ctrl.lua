local path='data/npc_icons.lua'
local f=assert(io.open(path,'r'))
local lines={}
for l in f:lines() do table.insert(lines,l) end
f:close()

local fixed=0
for i, s in ipairs(lines) do
  local ns = s:gsub('\r,', ',')
  ns = ns:gsub('\r$', '')
  if ns ~= s then
    lines[i]=ns
    fixed=fixed+1
  end
end

local g=assert(io.open(path,'w'))
for i,l in ipairs(lines) do
  g:write(l)
  g:write('\n')
end
g:close()
print('fixed='..fixed)
