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

local npc = load_table('data/npc_icons.lua', 'npcIcons')
local legacy = load_table('data/generated/wiki_legacy_npcs.lua', 'legacyWikiNpcs')

local keys = {'Grav\'iton','Mawl\'gofaur','Da\'Vhu','Esha\'ntarl','Door: Amchuchu\'s Laboratory','Kareh\'ayollio','Babban\'s Progeny','Kam\'lanaut (S)','Door: Svenja\'s Manor','Eald\'narche','Kam\'lanaut','Nag\'molada (S)','Gu\'Zho Thunderblade','Selh\'teus','Sajj\'aka','Yve\'noile','Nag\'molada','Esha\'ntarl (A)','Diva\'s Muscle'}
for _,k in ipairs(keys) do
  local n = npc[k]
  local l = legacy[k]
  if not n or not l then
    print(k, 'missing in npc/legacy?', tostring(not n), tostring(not l))
  else
    local zn = (type(n.zones)=='table' and #n.zones>0)
    local nn = (type(n.note)=='string' and #n.note>0)
    local zl = (l.zones ~= nil)
    local nl = (l.note ~= nil)
    print(k, 'zones', zn, 'need', zl, '| note', nn, 'need', nl)
  end
end
