T = function(t) return t end
package.path = '.\\?.lua;.\\?\\init.lua;' .. package.path

local function load_table(path)
    local ok, data = pcall(dofile, path)
    if ok and type(data) == 'table' then return data end
    error('failed to load ' .. path .. ': ' .. tostring(data))
end
local existing = load_table('data/npc_icons.lua')
local legacy = load_table('data/generated/wiki_legacy_npcs.lua')
local current = load_table('data/generated/wiki_current_npcs.lua')
local generated = {}
for name, entry in pairs(legacy) do if type(name) == 'string' and type(entry) == 'table' then generated[name] = entry end end
for name, entry in pairs(current) do if type(name) == 'string' and type(entry) == 'table' then generated[name] = entry end end
local function sorted_keys(t) local keys = {}; for key in pairs(t) do keys[#keys+1]=key end; table.sort(keys,function(a,b)return tostring(a):lower()<tostring(b):lower() end); return keys end
local function q(value) return string.format('%q', tostring(value)) end
local function long_string(value) local text=tostring(value or ''); local eq=''; while string.find(text, ']'..eq..']', 1, true) do eq=eq..'=' end; return '['..eq..'['..text..']'..eq..']' end
local function zone_list(zones) if type(zones)~='table' then return nil end; local parts={}; for i=1,#zones do local z=tostring(zones[i] or ''); if z~='' then parts[#parts+1]=q(z) end end; if #parts==0 then return nil end; return '{ '..table.concat(parts, ', ')..' }' end
local function has_useful_field(entry) return entry.type~=nil or entry.icon~=nil or entry.zones~=nil or entry.note~=nil or entry.link~=nil end
local lines = {}
lines[#lines+1] = '    -- Unique generated FFXIclopedia NPC entries merged into this table.'
lines[#lines+1] = '    -- Existing curated entries above are kept as the authority when names overlap.'
lines[#lines+1] = '    -- Generated location fields are intentionally omitted; notes are UI-toggle data.'
lines[#lines+1] = ''
local added = 0
for _, name in ipairs(sorted_keys(generated)) do
    local entry = generated[name]
    if existing[name] == nil and has_useful_field(entry) then
        lines[#lines+1] = '    ['..q(name)..'] = {'
        if entry.type ~= nil and tostring(entry.type) ~= '' then lines[#lines+1] = '        type = '..q(entry.type)..',' end
        if entry.icon ~= nil and tostring(entry.icon) ~= '' then lines[#lines+1] = '        icon = '..q(entry.icon)..',' end
        local zones = zone_list(entry.zones); if zones ~= nil then lines[#lines+1] = '        zones = '..zones..',' end
        if entry.note ~= nil and tostring(entry.note) ~= '' then lines[#lines+1] = '        note = '..long_string(entry.note)..',' end
        if entry.link ~= nil and tostring(entry.link) ~= '' then lines[#lines+1] = '        link = '..q(entry.link)..',' end
        lines[#lines+1] = '    },'
        lines[#lines+1] = ''
        added = added + 1
    end
end
local section = table.concat(lines, '\n')
local path = 'data/npc_icons.lua'
local file = assert(io.open(path, 'rb')); local content = file:read('*a'); file:close()
local startPos = string.find(content, '%-%- Unique generated FFXIclopedia NPC entries merged into this table%.')
if startPos == nil then error('could not find generated marker') end
local footerStart = string.find(content, '\n};', startPos, true)
if footerStart == nil then error('could not find table footer after marker') end
local updated = string.sub(content, 1, startPos - 1) .. section .. string.sub(content, footerStart)
file = assert(io.open(path, 'wb')); file:write(updated); file:close()
print('added', added)
