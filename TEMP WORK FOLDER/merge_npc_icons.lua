local srcPath = 'C:\catseyexi\catseyexi-client\Ashita\addons\LibraPlates\data\npc_icons.lua'
local legacyPath = 'C:\catseyexi\catseyexi-client\Ashita\addons\LibraPlates\data\generated\wiki_legacy_npcs.lua'

local function copyTable(source)
    if type(source) ~= 'table' then
        return nil
    end

    local dest = {}

    for key, value in pairs(source) do
        if type(value) == 'table' then
            dest[key] = copyTable(value)
        else
            dest[key] = value
        end
    end

    return dest
end

local function isNonEmptyString(v)
    return type(v) == 'string' and v:gsub('%s+', '') ~= ''
end

local function isMissing(v)
    return v == nil or (type(v) == 'table' and next(v) == nil) or isNonEmptyString(v) == false
end

local function isBlank(v)
    return v == nil or isNonEmptyString(v) == false or (type(v) == 'table' and next(v) == nil)
end

local function sortKeys(tbl)
    local keys = {}

    for key in pairs(tbl) do
        if type(key) == 'string' then
            keys[#keys + 1] = key
        end
    end

    table.sort(keys)
    return keys
end

local function quote(value)
    value = tostring(value)
        :gsub('\\', '\\\\')
        :gsub('"', '\\"')
        :gsub('\r', '\\r')
        :gsub('\n', '\\n')
        :gsub('\t', '\\t')
        :gsub('%z', '\\0')

    return '"' .. value .. '"'
end

local function serializeValue(value)
    if type(value) == 'string' then
        return quote(value)
    end

    if type(value) == 'number' or type(value) == 'boolean' then
        return tostring(value)
    end

    if type(value) ~= 'table' then
        return 'nil'
    end

    local isArray = true
    local count = 0

    for key in pairs(value) do
        if type(key) ~= 'number' then
            isArray = false
            break
        end
        count = count + 1
    end

    if isArray == true then
        if count == 0 then
            return '{ }'
        end

        for i = 1, count do
            if value[i] == nil then
                isArray = false
                break
            end
        end
    end

    if isArray == false then
        local parts = {}
        local keys = sortKeys(value)

        for _, key in ipairs(keys) do
            local val = serializeValue(value[key])
            parts[#parts + 1] = '"' .. key .. '" = ' .. val
        end

        return '{ ' .. table.concat(parts, ', ') .. ' }'
    end

    local parts = {}

    for i = 1, count do
        parts[#parts + 1] = serializeValue(value[i])
    end

    return '{ ' .. table.concat(parts, ', ') .. ' }'
end

local function serializeSpecialWarmachine(entry)
    return '\"??? Warmachine\" = {\n        type = \'Orc Warmachine\',\n        icon = \'Dialogue.png\',\n        zones = { \"Bibiki Bay - Purgonorgo Isle\", \"Outland\" },\n        note = "Involved in Quests:\\n* One Good Deed?\\n\\nInvolved in Missions:\\n* Promathia Mission 5-3\\n* Promathia Mission 8-4",\n    },'
end

local oldT = T
T = function(tableValue)
    return tableValue
end

local function loadNpcFile(path)
    local chunk = assert(loadfile(path))
    local value = chunk()
    return value
end

local function keyFor(name)
    return name
end

local npcIcons = loadNpcFile(srcPath)
local legacyNpcs = loadNpcFile(legacyPath)

if type(npcIcons) ~= 'table' or type(legacyNpcs) ~= 'table' then
    error('Expected both tables from source files')
end

local changed = 0
local updated = copyTable(npcIcons)

for name, legacy in pairs(legacyNpcs) do
    if type(name) == 'string' and type(legacy) == 'table' then
        local entry = updated[name]
        if type(entry) == 'table' then
            if isMissing(entry.zones) and type(legacy.zones) == 'table' and next(legacy.zones) ~= nil then
                entry.zones = copyTable(legacy.zones)
                changed = changed + 1
            end

            if isBlank(entry.note) and isNonEmptyString(legacy.note) then
                entry.note = legacy.note
                changed = changed + 1
            end
        end
    end
end

-- Keep note formatting for ??? Warmachine exactly as requested.
local warmachine = updated['??? Warmachine']
if type(warmachine) == 'table' then
    warmachine.note = 'Involved in Quests:\n* One Good Deed?\\n\\nInvolved in Missions:\\n* Promathia Mission 5-3\\n* Promathia Mission 8-4'
    warmachine.type = warmachine.type or 'Orc Warmachine'
    warmachine.icon = warmachine.icon or 'Dialogue.png'
    if type(warmachine.zones) ~= 'table' or #warmachine.zones == 0 then
        warmachine.zones = { 'Bibiki Bay - Purgonorgo Isle', 'Outland' }
    end
    changed = changed + 1
end

local out = assert(io.open(srcPath, 'w'))
out:write('-- Converted from C:\\Users\\Lila\\Downloads\\npc_icons.csv\n')
out:write('local npcIcons = T{\n')

local names = sortKeys(updated)
for _, name in ipairs(names) do
    local entry = updated[name]

    if name == '??? Warmachine' then
        out:write('    ' .. serializeSpecialWarmachine(entry) .. '\n')
    else
        out:write('    [')
        out:write(quote(name))
        out:write('] = ')
        out:write('{ ')

        local ekeys = sortKeys(entry)
        local fields = {}

        for _, ekey in ipairs(ekeys) do
            fields[#fields + 1] = ekey .. ' = ' .. serializeValue(entry[ekey])
        end

        out:write(table.concat(fields, ', '))
        out:write(' },\n')
    end
end

out:write('}\n\nreturn npcIcons\n')
out:close()
print('updated=' .. changed)
