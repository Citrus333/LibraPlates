function T(t) return t end
package.preload['common']=function() return {} end
package.preload['core.texture_loader']=function() return {Load=function() return 0 end, ToTextureId=function(v) return v end} end
local npc = assert(loadfile('data/npc_icons.lua'))()
local targets={'Momiji','Rakuru-Rakoru','Zauko','Balasiel','Rottata','Tahmasp','Jedelaih','Lucretia (Ceizak Battlegrounds)','Mionie','Ramblix','Rottata','Trailmix','Kusei'}
for _,n in ipairs(targets) do
  local e=npc[n]
  if e then
    print(n, 'type='..tostring(e.type or ''), 'icon='..tostring(e.icon or ''), 'zones='..(e.zones and table.concat(e.zones, ',') or 'nil'), 'noteLen='..(#(tostring(e.note or ''))))
  else
    print(n, 'missing')
  end
end
