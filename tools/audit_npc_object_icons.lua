-- Standalone validation for the generated NPC/Object database icon paths.
-- Run from the LibraPlates root with Lua 5.1:
--   lua tools/audit_npc_object_icons.lua

local root = '.\\';
local imageRoot = root .. 'assets\\images\\';
local zoneRoot = root .. 'data\\npc_object_zones\\';

local function FileExists(path)
    local file = io.open(path, 'rb');
    if (file == nil) then
        return false;
    end

    file:close();
    return true;
end

local function ResolveIcon(icon, source)
    local preferred = 'npc_icons';
    if (source == 'item') then
        preferred = 'item_icons';
    elseif (source == 'catseye_npc' or source == 'catseye_item') then
        preferred = 'catseye_icons';
    end

    local preferredPath = imageRoot .. preferred .. '\\' .. icon;
    if (FileExists(preferredPath)) then
        return preferred .. '\\' .. icon;
    end

    if (source == 'catseye_npc') then
        local fallbackPath = imageRoot .. 'npc_icons\\' .. icon;
        if (FileExists(fallbackPath)) then
            return 'npc_icons\\' .. icon;
        end
    elseif (source == 'catseye_item') then
        local fallbackPath = imageRoot .. 'item_icons\\' .. icon;
        if (FileExists(fallbackPath)) then
            return 'item_icons\\' .. icon;
        end
    end

    return nil;
end

local bucketSources = {
    npcs = 'npc',
    npc = 'npc',
    objects = 'item',
    item = 'item',
    catseyeNpc = 'catseye_npc',
    catseyeItem = 'catseye_item',
};

local used = {};
local missing = {};
local referenceCount = 0;

local function ScanTable(value, inheritedSource, location, seen)
    if (type(value) ~= 'table' or seen[value] == true) then
        return;
    end
    seen[value] = true;

    local source = tostring(value._source or inheritedSource or 'npc');
    if (type(value.icon) == 'string' and value.icon ~= '') then
        referenceCount = referenceCount + 1;
        local resolved = ResolveIcon(value.icon:gsub('/', '\\'), source);
        if (resolved ~= nil) then
            used[string.lower(resolved)] = true;
        else
            missing[#missing + 1] = string.format('%s | source=%s | icon=%s', location, source, value.icon);
        end
    end

    for key, child in pairs(value) do
        if (type(child) == 'table') then
            local childSource = bucketSources[key] or source;
            ScanTable(child, childSource, location .. '.' .. tostring(key), seen);
        end
    end
end

local manifest = assert(dofile(root .. 'data\\npc_object_zone_manifest.lua'));
local files = {};
local function AddFile(name)
    if (type(name) == 'string' and name ~= '') then
        files[name] = true;
    end
end

AddFile(manifest.global);
for _, name in pairs(manifest.zoneIds or {}) do AddFile(name); end
for _, name in pairs(manifest.zoneNames or {}) do AddFile(name); end

local fileCount = 0;
for fileName in pairs(files) do
    fileCount = fileCount + 1;
    local data = assert(dofile(zoneRoot .. fileName));
    ScanTable(data, nil, fileName, {});
end

local usedCount = 0;
for _ in pairs(used) do usedCount = usedCount + 1; end

table.sort(missing);
print(string.format('zone_files=%d icon_references=%d unique_resolved_files=%d missing_references=%d', fileCount, referenceCount, usedCount, #missing));
for _, value in ipairs(missing) do
    print('MISSING ' .. value);
end

for _, folder in ipairs({ 'npc_icons', 'item_icons', 'catseye_icons' }) do
    local pipe = io.popen('dir /b "' .. imageRoot .. folder .. '\\*.png" 2>nul');
    if (pipe ~= nil) then
        for fileName in pipe:lines() do
            local key = string.lower(folder .. '\\' .. fileName);
            if (used[key] ~= true) then
                print('NOT_DB ' .. folder .. '\\' .. fileName);
            end
        end
        pipe:close();
    end
end
