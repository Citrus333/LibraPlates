-- Minimal stubs for addon runtime dependencies
package.path = package.path .. ';./data/?.lua;./core/?.lua;./libs/?.lua;./tools/?.lua;'
package.preload['common'] = function() return {} end
package.preload['core.texture_loader'] = function()
    return {
        Load = function(path) return path end,
        ToTextureId = function(path) return path end,
    }
end
function T(t) return t end

local npcInfo = assert(loadfile('core/npc_object_info.lua'))()

local names = {'Momiji','Rakuru-Rakoru','Zauko','Balasiel','Rottata','Tahmasp'}
for _,name in ipairs(names) do
    local info = npcInfo.Find(name, 'npc')
    print(name, info and info.source or 'nil', info and info.icon or 'nil', info and info.type or 'nil')
    if info and info.zones then print('  zones=' .. table.concat(info.zones, ',')) end
    if info and info.note then print('  noteLen=' .. #info.note) else print('  noteLen=0') end
end
