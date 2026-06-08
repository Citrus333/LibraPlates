local f=assert(io.open("C:\\catseyexi\\catseyexi-client\\Ashita\\addons\\LibraPlates\\data\\npc_icons.lua","r"))
local src=f:read('*a')
f:close()
-- keep only lines 2948-2970 and wrap in a table for test
local lines={}
for l in (src.."\n"):gmatch("(.-)\n") do table.insert(lines,l) end
local snippet = "local npcIcons = T{\n"
for i=2948,2970 do
  snippet = snippet .. lines[i] .. "\n"
end
snippet = snippet .. "}; return npcIcons;"
local chunk,err=loadstring(snippet)
print(chunk and 'loaded' or err)
if chunk then
  local env = {_ENV={}}; setfenv(chunk, {T=function(t) return t end})
  chunk()
  print(env)
end
