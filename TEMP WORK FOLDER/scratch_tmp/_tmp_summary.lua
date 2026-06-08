function T(t) return t end
package.preload['common']=function() return {} end
package.preload['core.texture_loader']=function() return {Load=function() return 0 end, ToTextureId=function(v) return v end} end
local npc = assert(loadfile('data/npc_icons.lua'))()
local total=0; local missingIcon=0; local missingType=0
for _ in pairs(npc) do total=total+1 end
for _,entry in pairs(npc) do
  if type(entry)=='table' then
    if tostring(entry.icon or '')=='' then missingIcon=missingIcon+1 end
    if tostring(entry.type or '')=='' then missingType=missingType+1 end
  end
end
print('entries='..total..' missingIcon='..missingIcon..' missingType='..missingType)
