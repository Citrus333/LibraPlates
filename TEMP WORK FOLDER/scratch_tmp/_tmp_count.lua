local function read_file(path)
  local f=assert(io.open(path,'r'))
  local c=f:read('*a')
  f:close()
  return c
end

local function load_file_table(path, varname)
  local src=read_file(path)
  local marker = '\n-- Auto-enriched from data/generated/wiki_legacy_npcs.lua'
  local p = src:find(marker, 1, true)
  if p then
    src = src:sub(1,p-1)
  end
  src = src:gsub('local%s+'..varname..'%s*=%s*T%s*{', varname .. ' = {')
  src = 'local T = function(t) return t end\n' .. src
  local chunk, err = loadstring(src)
  assert(chunk, err)
  local env = { T = function(t) return t end }
  setfenv(chunk, env)
  chunk()
  local tbl = env[varname]
  assert(tbl, 'Table '..varname..' missing after load')
  return tbl
end

local npc = load_file_table('C:\\catseyexi\\catseyexi-client\\Ashita\\addons\\LibraPlates\\data\\npc_icons.lua', 'npcIcons')
local legacy = load_file_table('C:\\catseyexi\\catseyexi-client\\Ashita\\addons\\LibraPlates\\data\\generated\\wiki_legacy_npcs.lua', 'legacyWikiNpcs')

local missingZones = 0
local missingNotes = 0
local both = 0
local example = nil
for name,entry in pairs(legacy) do
  local n = npc[name]
  if n then
    local missingZ = (entry.zones ~= nil and n.zones == nil)
    local missingN = (entry.note ~= nil and n.note == nil)
    if missingZ then missingZones = missingZones + 1 end
    if missingN then missingNotes = missingNotes + 1 end
    if missingZ or missingN then both = both + 1 end
    if missingZ and missingN and not example then example = name end
  end
end
print('MISSING_ZONES='..missingZones)
print('MISSING_NOTES='..missingNotes)
print('MISSING_EITHER='..both)
print('EXAMPLE=' .. tostring(example))
