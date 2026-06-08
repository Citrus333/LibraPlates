local f=assert(io.open("C:\\catseyexi\\catseyexi-client\\Ashita\\addons\\LibraPlates\\data\\npc_icons.lua","r"))
local src=f:read("*a"); f:close()
src = src:gsub('local%s+npcIcons%s*=%s*T%s*{', 'npcIcons = {')
src = 'local T = function(t) return t end\n' .. src
local chunk, err = loadstring(src)
print(chunk and 'ok' or err)
if chunk then
 local env={ T=function(t) return t end }
 setfenv(chunk, env)
 local ok,e=pcall(chunk)
 print(ok,e)
 print(type(env.npcIcons))
end
