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
  local chunk, err = loadstring(src)
  if not chunk then
    error(err)
  end
  local env = { T = function(t) return t end }
  setfenv(chunk, env)
  assert(chunk())
  return env[varname]
end

local npc = load_table('data/npc_icons.lua', 'npcIcons')
local legacy = load_table('data/generated/wiki_legacy_npcs.lua', 'legacyWikiNpcs')

local missingEither = 0
local missingZones = 0
local missingNotes = 0
local missingList = {}
local overlap = 0
local overlapMissingZones = 0
local overlapMissingNotes = 0
local overlapMissingEither = 0

for k, v in pairs(legacy) do
  if type(v) == 'table' and type(npc[k]) == 'table' then
    overlap = overlap + 1
    local mz = v.zones and (not npc[k].zones or (type(npc[k].zones)=='table' and #npc[k].zones==0))
    local mn = v.note and (not npc[k].note or npc[k].note == '')
    if mz then overlapMissingZones = overlapMissingZones + 1 end
    if mn then overlapMissingNotes = overlapMissingNotes + 1 end
    if mz or mn then overlapMissingEither = overlapMissingEither + 1 end
  end
  local m = false
  if v.zones and (not npc[k].zones or (type(npc[k].zones)=='table' and #npc[k].zones==0)) then
    missingZones = missingZones + 1
    m = true
  end
  if v.note and (not npc[k].note or npc[k].note == '') then
    missingNotes = missingNotes + 1
    m = true
  end
  if m then
    missingEither = missingEither + 1
    table.insert(missingList, k)
  end
end

print('legacy_overlap=' .. overlap)
print('legacy_overlap_missing_zones=' .. overlapMissingZones)
print('legacy_overlap_missing_notes=' .. overlapMissingNotes)
print('legacy_overlap_missing_either=' .. overlapMissingEither)
print('missing_zones=' .. missingZones)
print('missing_notes=' .. missingNotes)
print('missing_either=' .. missingEither)

if overlapMissingEither > 0 then
  table.sort(missingList)
  print('first_missing:')
  for i = 1, math.min(40, #missingList) do
    print('  ' .. missingList[i])
  end
end
