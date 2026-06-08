local f=assert(io.open("C:\\catseyexi\\catseyexi-client\\Ashita\\addons\\LibraPlates\\data\\npc_icons.lua","r"))
local src=f:read('*a')
f:close()
src = src:gsub('\n-- Auto-enriched from data/generated/wiki_legacy_npcs.lua', '')
src = src:gsub('local%s+npcIcons%s*=\\s*T%s*{', 'npcIcons = {')
src = src:gsub('local%s+npcIcons%s*=%s*T%s*{', 'npcIcons = {')
src = 'local T = function(t) return t end\n' .. src
local chunk, err = loadstring(src)
print(chunk and 'loaded' or err)
