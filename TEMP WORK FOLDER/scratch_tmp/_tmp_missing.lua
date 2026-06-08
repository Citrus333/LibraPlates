function T(t) return t end
package.preload['common']=function() return {} end
package.preload['core.texture_loader']=function() return {Load=function() return 0 end, ToTextureId=function(v) return v end} end
local data = assert(loadfile('data/npc_icons.lua'))()
local missing={}
for name,entry in pairs(data) do
  if type(entry)=='table' then
    local hasIcon = tostring(entry.icon or '') ~= ''
    local hasNote = tostring(entry.note or '') ~= ''
    if hasNote and not hasIcon then table.insert(missing, name) end
  end
end
table.sort(missing)
print('missing_icon_with_note='..#missing)
for i=1, math.min(40,#missing) do print(missing[i]) end
if #missing > 40 then print('... and '..(#missing-40)..' more') end
