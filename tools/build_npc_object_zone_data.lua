package.path = package.path .. ';./?.lua;./?/init.lua';

function T(value)
    return value;
end

local sources = {
    { key = 'npc', sourceTag = 'npc', group = 'npcs', data = require('data.npc_icons') },
    { key = 'item', sourceTag = 'item', group = 'objects', data = require('data.item_icons') },
    { key = 'catseyeNpc', sourceTag = 'catseye_npc', group = 'npcs', data = require('data.catseye_npc_icons') },
    { key = 'catseyeItem', sourceTag = 'catseye_item', group = 'objects', data = require('data.catseye_item_icons') },
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

    return nil;
end

local function cloneEntry(entry)
    local copy = {};

    for key, value in pairs(entry or {}) do
        copy[key] = value;
    end

    return copy;
end

local function sanitizeGeneratedEntry(entry)
    if (type(entry) ~= 'table') then
        return entry;
    end

    entry.zones = nil;
    entry.zoneIds = nil;
    entry.location = nil;
    entry.byZoneIndex = nil;

    return entry;
end

local reservedEntryKeys = {
    zones = true,
    zoneIds = true,
    byZoneIndex = true,
    location = true,
};

local function isUsableEntry(name, entry)
    if (reservedEntryKeys[name] == true) then
        return false;
    end

    return type(name) == 'string' and type(entry) == 'table';
end

local function mergeGeneratedEntry(primary, fallback)
    if (primary == nil) then
        return fallback;
    end

    if (fallback == nil) then
        return primary;
    end

    if ((primary.info == nil or primary.info == '') and fallback.info ~= nil and fallback.info ~= '') then
        primary.info = fallback.info;
    end

    if ((primary.note == nil or primary.note == '') and fallback.note ~= nil and fallback.note ~= '') then
        primary.note = fallback.note;
    end

    if ((primary.link == nil or primary.link == '') and fallback.link ~= nil and fallback.link ~= '') then
        primary.link = fallback.link;
    end

    if ((primary.type == nil or primary.type == '') and fallback.type ~= nil and fallback.type ~= '') then
        primary.type = fallback.type;
    end

    if ((primary.icon == nil or primary.icon == '') and fallback.icon ~= nil and fallback.icon ~= '') then
        primary.icon = fallback.icon;
    end

    if (primary.hidden ~= true and fallback.hidden == true) then
        primary.hidden = true;
    end

    if (primary.worldOffsetX == nil and fallback.worldOffsetX ~= nil) then
        primary.worldOffsetX = fallback.worldOffsetX;
    end

    if (primary.worldOffsetY == nil and fallback.worldOffsetY ~= nil) then
        primary.worldOffsetY = fallback.worldOffsetY;
    end

    if (primary.worldOffsetZ == nil and fallback.worldOffsetZ ~= nil) then
        primary.worldOffsetZ = fallback.worldOffsetZ;
    end

    if (primary.anchorBone == nil and fallback.anchorBone ~= nil) then
        primary.anchorBone = fallback.anchorBone;
    end

    return primary;
end

local function addEntry(bucket, source, name, entry)
    local group = source.group;
    local sourceTag = source.sourceTag;
    local target = bucket[group];
    local existing = target[name];
    local copy = sanitizeGeneratedEntry(cloneEntry(entry));

    copy._source = sourceTag;
    target[name] = mergeGeneratedEntry(copy, existing);
end

local function ensureBucket(buckets, key)
    buckets[key] = buckets[key] or {
        npcs = {},
        objects = {},
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

local zoneIdToName = {};
local zoneNameToId = {};
local zoneNameCandidates = {};
local canonicalZoneNames = {
    [139] = "Horlais Peak",
    [144] = "Waughroon Shrine",
    [146] = "Balga's Dais",
    [206] = "Qu'Bia Arena",
};

local function rememberZone(zoneId, zoneName)
    local id = tonumber(zoneId);
    local name = tostring(zoneName or '');
    local key = normalizeZoneName(name);

    if (id == nil or id <= 0 or key == '') then
        return;
    end

    zoneNameCandidates[id] = zoneNameCandidates[id] or {};
    zoneNameCandidates[id][key] = zoneNameCandidates[id][key] or {
        name = name,
        count = 0,
    };
    zoneNameCandidates[id][key].count = zoneNameCandidates[id][key].count + 1;
end

local function zoneNamePenalty(key, name)
    local penalty = #tostring(name or '');

    if (#key > 60) then
        penalty = penalty + 10000;
    end

    if (key:find('/') ~= nil or key:find('%*') ~= nil or key:find(':') ~= nil) then
        penalty = penalty + 10000;
    end

    if (key:find('available only') ~= nil or key:find('cutscene') ~= nil or key:find('cut scenes') ~= nil or key:find('special event') ~= nil) then
        penalty = penalty + 10000;
    end

    if (key:find('outland') ~= nil or key:find('roams') ~= nil or key:find('moved') ~= nil or key:find('located') ~= nil or key:find('appears') ~= nil) then
        penalty = penalty + 5000;
    end

    return penalty;
end

for _, source in ipairs(sources) do
    for _, entry in pairs(source.data) do
        if (type(entry) == 'table' and type(entry.zoneIds) == 'table' and type(entry.zones) == 'table') then
            for index, zoneId in pairs(entry.zoneIds) do
                if (entry.zones[index] ~= nil) then
                    rememberZone(zoneId, entry.zones[index]);
                end
            end

            if (#entry.zoneIds == 1) then
                for _, zoneName in pairs(entry.zones) do
                    rememberZone(entry.zoneIds[1], zoneName);
                end
            end
        end
    end
end

for id, candidates in pairs(zoneNameCandidates) do
    local bestName = nil;
    local bestScore = nil;

    if (canonicalZoneNames[id] ~= nil) then
        bestName = canonicalZoneNames[id];
    else
        for key, candidate in pairs(candidates) do
            local score = zoneNamePenalty(key, candidate.name) - (candidate.count * 1000);

            if (bestScore == nil or score < bestScore or (score == bestScore and tostring(candidate.name) < tostring(bestName))) then
                bestName = candidate.name;
                bestScore = score;
            end
        end
    end

    if (bestName ~= nil) then
        zoneIdToName[id] = bestName;
        zoneNameToId[normalizeZoneName(bestName)] = id;
    end
end

local function getZoneFileName(zoneId, zoneName)
    local id = tonumber(zoneId);
    local name = zoneIdToName[id] or zoneName;

    if (name ~= nil and normalizeZoneName(name) ~= '') then
        return slug(name) .. '.lua';
    end

    return 'zone_' .. tostring(id) .. '.lua';
end

local function addEntryToZone(zoneBuckets, sourceName, name, entry, zoneId, zoneName)
    local id = tonumber(zoneId);

    if (id == nil or id <= 0) then
        return false;
    end

    local fileName = getZoneFileName(id, zoneName);
    local bucketKey = fileName:gsub('%.lua$', '');
    local canonicalName = zoneIdToName[id] or zoneName;

    addEntry(ensureBucket(zoneBuckets, bucketKey), sourceName, name, entry);
    manifest.zoneIds[id] = fileName;

    if (canonicalName ~= nil and normalizeZoneName(canonicalName) ~= '') then
        manifest.zoneNames[normalizeZoneName(canonicalName)] = fileName;
    end

    return true;
end

for _, source in ipairs(sources) do
    for name, entry in pairs(source.data) do
        if (isUsableEntry(name, entry) == true) then
            local added = false;
            local zones = getEntryZones(entry);

            if (type(entry) == 'table' and type(entry.zoneIds) == 'table') then
                for index, zoneId in pairs(entry.zoneIds) do
                    added = addEntryToZone(zoneBuckets, source, name, entry, zoneId, zones and zones[index]) or added;
                end
            end

            if (type(entry) == 'table' and type(entry.byZoneIndex) == 'table') then
                for zoneId, _ in pairs(entry.byZoneIndex) do
                    added = addEntryToZone(zoneBuckets, source, name, entry, zoneId, nil) or added;
                end
            end

            if (added ~= true and type(zones) == 'table') then
                for _, zoneName in pairs(zones) do
                    local id = zoneNameToId[normalizeZoneName(zoneName)];

                    if (id ~= nil) then
                        added = addEntryToZone(zoneBuckets, source, name, entry, id, zoneName) or added;
                    end
                end
            end

            if (added ~= true) then
                addEntry(globalBucket, source, name, entry);
            end
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

local function pruneReservedBucketKeys(bucket)
    if (type(bucket) ~= 'table') then
        return;
    end

    for key, _ in pairs(reservedEntryKeys) do
        bucket[key] = nil;
    end
end

local function pruneReservedGeneratedKeys(zoneData)
    if (type(zoneData) ~= 'table') then
        return zoneData;
    end

    pruneReservedBucketKeys(zoneData.npcs);
    pruneReservedBucketKeys(zoneData.objects);

    return zoneData;
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

writeFile(outputDir .. '/global.lua', pruneReservedGeneratedKeys(globalBucket));

for key, bucket in pairs(zoneBuckets) do
    writeFile(outputDir .. '/' .. key .. '.lua', pruneReservedGeneratedKeys(bucket));
end

writeFile('data/npc_object_zone_manifest.lua', manifest);

print(string.format('Wrote %d zone files plus global data.', #sortedKeys(zoneBuckets)));
