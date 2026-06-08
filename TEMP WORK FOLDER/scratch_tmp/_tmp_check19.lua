local function read_file(path)
  local f = assert(io.open(path, 'r'))
  local c = f:read('*a')
  f:close()
  return c
end

local function load_table(path, varname)
  local src = read_file(path)
  src = src:gsub('local%s+' .. varname .. '%s*=%s*T%s*{', varname .. ' = {')
  src = 'local T = function(t) return t end\n' .. src
  local chunk = assert(loadstring(src))
  local env = { T = function(t) return t end }
  setfenv(chunk, env)
  assert(chunk())
  return env[varname]
end

local npc = load_table('data/npc_icons.lua','npcIcons')
local keys = {'Grav\'iton','Mawl\'gofaur','Da\'Vhu','Esha\'ntarl','Door: Amchuchu\'s Laboratory','Kareh\'ayollio','Babban\'s Progeny','Kam\'lanaut (S)','Door: Svenja\'s Manor','Eald\'narche','Kam\'lanaut','Nag\'molada (S)','Gu\'Zho Thunderblade','Selh\'teus','Sajj\'aka','Yve\'noile','Nag\'molada','Esha\'ntarl (A)','Diva\'s Muscle'}
for _,k in ipairs(keys) do
  local e = npc[k]
  if not e then
    print('missing',k)
  else
    local z = (e.zones and type(e.zones)=='table' and #e.zones > 0) and 'yes' or 'no'
    local n = (type(e.note)=='string' and e.note ~= '') and 'yes' or 'no'
    print(k, z, n)
  end
end
