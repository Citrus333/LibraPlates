local f=assert(io.open("C:\\catseyexi\\catseyexi-client\\Ashita\\addons\\LibraPlates\\data\\npc_icons.lua","r"))
local src=f:read("*a"); f:close()
local marker="\n-- Auto-enriched from data/generated/wiki_legacy_npcs.lua"
local p=src:find(marker,1,true)
if p then src=src:sub(1,p-1) end
src = src:gsub('local%s+npcIcons%s*=\s*T%s*{', 'npcIcons = {')
src = src:gsub('local%s+npcIcons%s*=%s*T%s*{', 'npcIcons = {')
src = 'local T = function(t) return t end\n' .. src
local chunk, err = loadstring(src)
print(chunk and 'ok' or err)
if chunk then
  local env = { T = function(t) return t end }
  setfenv(chunk, env)
  local ok,e = pcall(chunk)
  print(ok, e)
  if ok then print(type(env.npcIcons)) end
end
