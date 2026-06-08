local function read_file(p)
  local f=assert(io.open(p,'r'))
  local c=f:read('*a')
  f:close(); return c
end
local txt = read_file('data/npc_icons.lua')
local key="Da'Vhu"
local p = txt:find("%['Da\'Vhu'%s*%]",1,true)
if not p then p = txt:find("%[\"Da\\'Vhu\"%]") end
print('p', p)
if p then
  local s = txt:sub(math.max(1,p-200), math.min(#txt,p+300))
  print(s)
end
