package.path = package.path .. ';./?.lua;./?/init.lua';

local manifest = require('data.npc_object_zone_manifest');

local function loadTable(path)
    local loader, err = loadfile(path);

    if (loader == nil) then
        error('Could not load ' .. tostring(path) .. ': ' .. tostring(err));
    end

    return loader();
end

local function addFile(files, seen, fileName)
    fileName = tostring(fileName or '');

    if (fileName == '' or seen[fileName] == true) then
        return;
    end

    seen[fileName] = true;
    files[#files + 1] = fileName;
end

local function getZoneFiles()
    local files = {};
    local seen = {};

    addFile(files, seen, manifest.global);

    for _, fileName in pairs(manifest.zoneIds or {}) do
        addFile(files, seen, fileName);
    end

    for _, fileName in pairs(manifest.zoneNames or {}) do
        addFile(files, seen, fileName);
    end

    table.sort(files);
    return files;
end

print('Zone data audit:');

for _, fileName in ipairs(getZoneFiles()) do
    local zoneData = loadTable('data/npc_object_zones/' .. fileName);
    local npcCount = 0;
    local objectCount = 0;

    for _, _ in pairs(zoneData.npcs or {}) do
        npcCount = npcCount + 1;
    end

    for _, _ in pairs(zoneData.objects or {}) do
        objectCount = objectCount + 1;
    end

    print(string.format('  %s npcs=%d objects=%d', fileName, npcCount, objectCount));
end
