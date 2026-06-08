local function read_file(path)
  local f=assert(io.open(path,'r'))
  local c=f:read('*a'); f:close(); return c
end
local function load_table(path,varname)
  local src = read_file(path)
  src = src:gsub('local%s+'..varname..'%s*=%s*T%s*{', varname .. ' = {')
  src = 'local T=function(t) return t end\n'..src
  local chunk = assert(loadstring(src))
  local env = { T=function(t) return t end }
  setfenv(chunk, env)
  assert(chunk())
  return env[varname]
end

local npc = load_table('data/npc_icons.lua','npcIcons')
for k,v in pairs(npc) do
  if tostring(k):find('Diva') then
    print(k)
    if v and type(v)=='table' then
      print('zones', v.zones and #v.zones or 0)
      print('note', tostring(v.note))
    end
  end
end
