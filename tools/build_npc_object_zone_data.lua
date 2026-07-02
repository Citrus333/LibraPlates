package.path = package.path .. ';./?.lua;./?/init.lua';

function T(value)
    return value;
end

local sources = {
    npc = require('data.npc_icons'),
    item = require('data.item_icons'),
    catseyeNpc = require('data.catseye_npc_icons'),
    catseyeItem = require('data.catseye_item_icons'),
};

local outputDir = 'data/npc_object_zones';

local function normalizeZoneName(zoneName)
    local text = tostring(zoneName or '');

    text = text:gsub('\\', '');
    text = text:gsub('[`´’]', "'");
    text = text:gsub('%s+', ' ');
    text = text:gsub('^%s+', ''):gsub('%s+$', '');

    return string.lower(text);
end

local function slug(text)
    local value = normalizeZoneName(text):gsub('[^%w]+', '_'):gsub('^_+', ''):gsub('_+$', '');

    if (value == '') then
        return 'unknown';
    end

    if (#value > 80) then
        local hash = 5381;

        for i = 1, #value do
            hash = (hash * 33 + string.byte(value, i)) % 2147483647;
        end

        value = value:sub(1, 64):gsub('_+$', '') .. '_' .. tostring(hash);
    end

    return value;
end

local function getEntryZones(entry)
    if (type(entry) ~= 'table') then
        return nil;
    end

    if (type(entry.zones) == 'table' and next(entry.zones) ~= nil) then
        return entry.zones;
    end

    if (entry.location ~= nil and tostring(entry.location) ~= '') then
        return { tostring(entry.location) };
    end

    return nil;
end

local function addEntry(bucket, sourceName, name, entry)
    bucket[sourceName] = bucket[sourceName] or {};
    bucket[sourceName][name] = entry;
end

local function ensureBucket(buckets, key)
    buckets[key] = buckets[key] or {
        npc = {},
        item = {},
        catseyeNpc = {},
        catseyeItem = {},
    };

    return buckets[key];
end

local zoneBuckets = {};
local globalBucket = ensureBucket({}, 'global');
local manifest = {
    global = 'global.lua',
    zoneNames = {},
    zoneIds = {},
};

for sourceName, source in pairs(sources) do
    for name, entry in pairs(source) do
        local added = false;
        local zones = getEntryZones(entry);

        if (type(zones) == 'table') then
            for _, zoneName in pairs(zones) do
                local key = normalizeZoneName(zoneName);

                if (key ~= '') then
                    addEntry(ensureBucket(zoneBuckets, 'n_' .. slug(zoneName)), sourceName, name, entry);
                    manifest.zoneNames[key] = 'n_' .. slug(zoneName) .. '.lua';
                    added = true;
                end
            end
        end

        if (type(entry) == 'table' and type(entry.zoneIds) == 'table') then
            for _, zoneId in pairs(entry.zoneIds) do
                local id = tonumber(zoneId);

                if (id ~= nil and id > 0) then
                    addEntry(ensureBucket(zoneBuckets, 'z_' .. tostring(id)), sourceName, name, entry);
                    manifest.zoneIds[id] = 'z_' .. tostring(id) .. '.lua';
                    added = true;
                end
            end
        end

        if (type(entry) == 'table' and type(entry.byZoneIndex) == 'table') then
            for zoneId, _ in pairs(entry.byZoneIndex) do
                local id = tonumber(zoneId);

                if (id ~= nil and id > 0) then
                    addEntry(ensureBucket(zoneBuckets, 'z_' .. tostring(id)), sourceName, name, entry);
                    manifest.zoneIds[id] = 'z_' .. tostring(id) .. '.lua';
                    added = true;
                end
            end
        end

        if (added ~= true) then
            addEntry(globalBucket, sourceName, name, entry);
        end
    end
end

local function sortedKeys(tbl)
    local keys = {};

    for key, _ in pairs(tbl or {}) do
        keys[#keys + 1] = key;
    end

    table.sort(keys, function(a, b)
        if (type(a) == type(b)) then
            return tostring(a) < tostring(b);
        end

        return type(a) < type(b);
    end);

    return keys;
end

local function serialize(value, indent)
    indent = indent or '';

    if (type(value) == 'string') then
        return string.format('%q', value);
    end

    if (type(value) == 'number' or type(value) == 'boolean') then
        return tostring(value);
    end

    if (type(value) ~= 'table') then
        return 'nil';
    end

    local nextIndent = indent .. '    ';
    local parts = { '{' };

    for _, key in ipairs(sortedKeys(value)) do
        parts[#parts + 1] = '\n' .. nextIndent .. '[' .. serialize(key, nextIndent) .. '] = ' .. serialize(value[key], nextIndent) .. ',';
    end

    parts[#parts + 1] = '\n' .. indent .. '}';

    return table.concat(parts);
end

os.execute('if not exist "data\\npc_object_zones" mkdir "data\\npc_object_zones"');

local function writeFile(path, tbl)
    local file = assert(io.open(path, 'wb'));

    file:write('return ');
    file:write(serialize(tbl, ''));
    file:write('\n');
    file:close();
end

writeFile(outputDir .. '/global.lua', globalBucket);

for key, bucket in pairs(zoneBuckets) do
    writeFile(outputDir .. '/' .. key .. '.lua', bucket);
end

writeFile('data/npc_object_zone_manifest.lua', manifest);

print(string.format('Wrote %d zone files plus global data.', #sortedKeys(zoneBuckets)));
