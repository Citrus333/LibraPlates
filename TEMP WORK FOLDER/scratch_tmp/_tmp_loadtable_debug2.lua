local function read_file(path)
  local f = assert(io.open(path,'r'))
  local c = f:read('*a')
  f:close()
  return c
end

local function load_table(path, varname)
  local src = read_file(path)
  local marker = "\n-- Auto-enriched from data/generated/wiki_legacy_npcs.lua"
  local splitPos = src:find(marker,1,true)
  if splitPos then src = src:sub(1, splitPos - 1) end
  src = src:gsub('local%s+' .. varname .. '%s*=\s*T%s*{', varname .. ' = {')
  src = src:gsub('local%s+' .. varname .. '%s*=%s*T%s*{', varname .. ' = {')
  src = 'local T = function(t) return t end\n' .. src
  local chunk, err = loadstring(src)
  if not chunk then
    print('FAIL:'..path)
    print(err)
    print(src:match('.?.-') )
    return nil, err
  end
  local env = { T = function(t) return t end }
  setfenv(chunk, env)
  local ok, e = pcall(chunk)
  if not ok then
    print('runtime fail:'..path..' '..e)
  end
  local tbl = env[varname]
  print(path, type(tbl))
  return tbl
end

load_table('C:\\catseyexi\\catseyexi-client\\Ashita\\addons\\LibraPlates\\data\\npc_icons.lua','npcIcons')
load_table('C:\\catseyexi\\catseyexi-client\\Ashita\\addons\\LibraPlates\\data\\generated\\wiki_legacy_npcs.lua','legacyWikiNpcs')
