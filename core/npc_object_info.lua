local npcInfo = {};
local textureLoader = require('core.texture_loader');
local entities = require('core.entities');

pcall(require, 'common');

local function LoadTable(moduleName)
    local ok, data = pcall(require, moduleName);

    if (ok == true and type(data) == 'table') then
        return data;
    end

    return {};
end

local npcIcons = LoadTable('data.npc_icons');
local itemIcons = LoadTable('data.item_icons');
local catseyeNpcIcons = LoadTable('data.catseye_npc_icons');
local catseyeItemIcons = LoadTable('data.catseye_item_icons');
local hiddenEntries = LoadTable('data.npc_object_hidden');
local textureIds = {};
local currentZoneId = nil;
local currentZoneName = nil;
local MergeEntry;

local function CleanName(name)
    return tostring(name or ''):gsub('\170', '');
end

local function NormalizeName(name)
    local text = CleanName(name);

    text = text:gsub('\\', '');
    text = text:gsub('[`´’]', "'");
    text = text:gsub('%s+', ' ');
    text = text:gsub('^%s+', ''):gsub('%s+$', '');

    return text;
end

local function NormalizeZoneName(zoneName)
    local text = tostring(zoneName or '');

    text = text:gsub('\\', '');
    text = text:gsub('[`´’]', "'");
    text = text:gsub('%s+', ' ');
    text = text:gsub('^%s+', ''):gsub('%s+$', '');

    return string.lower(text);
end

local function GetCurrentZoneName()
    local zoneId = nil;

    pcall(function()
        zoneId = AshitaCore:GetMemoryManager():GetParty():GetMemberZone(0);
    end);

    zoneId = tonumber(zoneId) or 0;

    if (zoneId == 0) then
        currentZoneId = nil;
        currentZoneName = nil;
        return nil;
    end

    if (zoneId == currentZoneId) then
        return currentZoneName;
    end

    local zoneName = nil;

    pcall(function()
        zoneName = AshitaCore:GetResourceManager():GetString('zones.names', zoneId);
    end);

    currentZoneId = zoneId;
    currentZoneName = NormalizeZoneName(zoneName);

    if (currentZoneName == '') then
        currentZoneName = nil;
    end

    return currentZoneName;
end

local function GetCurrentZoneId()
    local zoneId = nil;

    pcall(function()
        zoneId = AshitaCore:GetMemoryManager():GetParty():GetMemberZone(0);
    end);

    return tonumber(zoneId) or 0;
end

local function GetEntryZones(entry)
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

local function EntryMatchesCurrentZone(entry)
    if (type(entry) ~= 'table') then
        return false;
    end

    if (type(entry.zoneIds) == 'table' and next(entry.zoneIds) ~= nil) then
        local currentId = GetCurrentZoneId();

        if (currentId == 0) then
            return true;
        end

        for _, zoneId in pairs(entry.zoneIds) do
            if (tonumber(zoneId) == currentId) then
                return true;
            end
        end

        return false;
    end

    local zones = GetEntryZones(entry);

    if (zones == nil) then
        return true;
    end

    local zoneName = GetCurrentZoneName();

    if (zoneName == nil or zoneName == '') then
        return true;
    end

    for _, zone in pairs(zones) do
        if (NormalizeZoneName(zone) == zoneName) then
            return true;
        end
    end

    return false;
end

local function ReadEntry(sourceName, entry, ignoreZone)
    if (type(entry) ~= 'table') then
        return nil;
    end

    if (ignoreZone ~= true and EntryMatchesCurrentZone(entry) ~= true) then
        return nil;
    end

    local infoType = tostring(entry.type or '');
    local icon = tostring(entry.icon or '');
    local link = tostring(entry.link or '');
    local note = tostring(entry.note or '');
    local info = tostring(entry.info or '');
    local worldOffsetX = tonumber(entry.worldOffsetX);
    local worldOffsetY = tonumber(entry.worldOffsetY);
    local worldOffsetZ = tonumber(entry.worldOffsetZ);
    local anchorBone = tonumber(entry.anchorBone);
    local zones = GetEntryZones(entry);

    if (note ~= '' and info == '') then
        info = note;
    end

    if (infoType == '' and icon == '' and link == '' and note == '' and info == '' and worldOffsetX == nil and worldOffsetY == nil and worldOffsetZ == nil and anchorBone == nil) then
        return nil;
    end

    return {
        source = sourceName,
        type = infoType,
        icon = icon,
        link = link,
        info = info,
        note = note,
        zones = zones,
        worldOffsetX = worldOffsetX,
        worldOffsetY = worldOffsetY,
        worldOffsetZ = worldOffsetZ,
        anchorBone = anchorBone,
    };
end

local function ReadZoneIndexOverride(sourceName, entry, options)
    if (type(entry) ~= 'table' or type(options) ~= 'table' or type(entry.byZoneIndex) ~= 'table') then
        return nil;
    end

    local currentZoneIdValue = GetCurrentZoneId();
    local targetIndex = tonumber(options.targetIndex or options.index);

    if (currentZoneIdValue == 0 or targetIndex == nil) then
        return nil;
    end

    local zoneOverrides = entry.byZoneIndex[currentZoneIdValue] or entry.byZoneIndex[tostring(currentZoneIdValue)];

    if (type(zoneOverrides) ~= 'table') then
        return nil;
    end

    local override = zoneOverrides[targetIndex] or zoneOverrides[tostring(targetIndex)];

    if (type(override) ~= 'table') then
        return nil;
    end

    return ReadEntry(sourceName, override, true);
end

local function ApplyZoneIndexOverride(sourceName, entry, info, options)
    local override = ReadZoneIndexOverride(sourceName, entry, options);

    if (override == nil) then
        return info;
    end

    return MergeEntry(override, info);
end

local function FindIn(name, sourceName, source, ignoreZone, options)
    local entry = source[NormalizeName(name)] or source[CleanName(name)];
    local info = ReadEntry(sourceName, entry, ignoreZone == true);

    return ApplyZoneIndexOverride(sourceName, entry, info, options);
end

local function FindScopedIn(name, sourceName, source, ignoreZone, options)
    local entry = source[NormalizeName(name)] or source[CleanName(name)];

    if (GetEntryZones(entry) == nil) then
        return nil;
    end

    local info = ReadEntry(sourceName, entry, ignoreZone == true);

    return ApplyZoneIndexOverride(sourceName, entry, info, options);
end

local function FindMogHouseMoogleAlias(sourceName, source)
    if (entities.IsMogHouseObjectSuppressionArea() ~= true) then
        return nil;
    end

    return ReadEntry(sourceName, source['Moogle (Mog House)'], true);
end

MergeEntry = function(primary, fallback)
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

    return primary;
end

function npcInfo.ShouldHidePlate(name)
    local cleanName = NormalizeName(name);

    return hiddenEntries[cleanName] == true;
end

function npcInfo.Find(name, entityType, options)
    if (npcInfo.ShouldHidePlate(name) == true) then
        return nil;
    end

    local kind = tostring(entityType or ''):lower();
    local cleanName = CleanName(name);
    local ignoreZone = type(options) == 'table' and options.ignoreZone == true;

    if (kind == 'object') then
        local item = FindIn(name, 'catseye_item', catseyeItemIcons, ignoreZone, options)
            or FindScopedIn(name, 'item', itemIcons, ignoreZone, options)
            or FindIn(name, 'item', itemIcons, ignoreZone, options);
        local npc = FindIn(name, 'catseye_npc', catseyeNpcIcons, ignoreZone, options)
            or FindScopedIn(name, 'npc', npcIcons, ignoreZone, options)
            or (ignoreZone ~= true and cleanName == 'Moogle' and FindMogHouseMoogleAlias('npc', npcIcons) or nil)
            or FindIn(name, 'npc', npcIcons, ignoreZone, options);

        return MergeEntry(item, npc);
    end

    local catseyeNpc = FindIn(name, 'catseye_npc', catseyeNpcIcons, ignoreZone, options)
        or FindScopedIn(name, 'catseye_npc', catseyeNpcIcons, ignoreZone, options);
    local npc = FindScopedIn(name, 'npc', npcIcons, ignoreZone, options)
        or (ignoreZone ~= true and cleanName == 'Moogle' and FindMogHouseMoogleAlias('npc', npcIcons) or nil)
        or FindIn(name, 'npc', npcIcons, ignoreZone, options);

    return MergeEntry(catseyeNpc, npc) or npc;
end

function npcInfo.ResolveKind(name, entityType, options)
    local catseyeItemInfo = FindIn(name, 'catseye_item', catseyeItemIcons, false, options);

    if (catseyeItemInfo ~= nil) then
        return 'Object', catseyeItemInfo;
    end

    local info = npcInfo.Find(name, entityType, options);
    local rawType = tostring(entityType or ''):lower();

    if (info ~= nil) then
        if (info.source == 'item' or info.source == 'catseye_item') then
            return 'Object', info;
        end

        return 'NPC', info;
    end

    local itemInfo = FindIn(name, 'catseye_item', catseyeItemIcons, false, options)
        or FindScopedIn(name, 'item', itemIcons, false, options)
        or FindIn(name, 'item', itemIcons, false, options);

    if (itemInfo ~= nil) then
        return 'Object', itemInfo;
    end

    if (rawType == 'object') then
        -- If this is not a known object entry, keep unknowns on NPC behavior.
        return 'NPC', nil;
    end

    return 'NPC', nil;
end

function npcInfo.GetType(name, entityType, options)
    local info = npcInfo.Find(name, entityType, options);

    if (info ~= nil and info.type ~= nil and tostring(info.type) ~= '') then
        return tostring(info.type);
    end

    return nil;
end

local function GetAddonRoot()
    if (AshitaCore ~= nil and AshitaCore.GetInstallPath ~= nil) then
        return AshitaCore:GetInstallPath() .. '\\addons\\LibraPlates\\';
    end

    return '';
end

local function IsAbsolutePath(path)
    return path:match('^%a:[/\\]') ~= nil or path:match('^[/\\][/\\]') ~= nil;
end

local function PathExists(path)
    local ok, exists = pcall(function()
        return ashita ~= nil and ashita.fs ~= nil and ashita.fs.exists(path) == true;
    end);

    return ok == true and exists == true;
end

local function BuildIconPath(info)
    if (info == nil or info.icon == nil or tostring(info.icon) == '') then
        return nil;
    end

    local icon = tostring(info.icon):gsub('/', '\\');

    if (IsAbsolutePath(icon) == true) then
        return icon;
    end

    local folder = 'npc_icons';

    if (info.source == 'item') then
        folder = 'item_icons';
    elseif (info.source == 'catseye_npc' or info.source == 'catseye_item') then
        folder = 'catseye_icons';
    end

    local root = GetAddonRoot() .. 'assets\\images\\';
    local path = root .. folder .. '\\' .. icon;

    if (info.source == 'catseye_npc' and PathExists(path) ~= true) then
        local fallbackPath = root .. 'npc_icons\\' .. icon;

        if (PathExists(fallbackPath) == true) then
            return fallbackPath;
        end
    elseif (info.source == 'catseye_item' and PathExists(path) ~= true) then
        local fallbackPath = root .. 'item_icons\\' .. icon;

        if (PathExists(fallbackPath) == true) then
            return fallbackPath;
        end
    end

    return path;
end

function npcInfo.GetTextureId(name, entityType, options)
    local path = BuildIconPath(npcInfo.Find(name, entityType, options));

    if (path == nil or path == '') then
        return nil;
    end

    if (textureIds[path] == false) then
        return nil;
    end

    if (textureIds[path] ~= nil) then
        return textureIds[path];
    end

    local ok, texture = pcall(function()
        return textureLoader.Load(path);
    end);

    if (ok ~= true or texture == nil) then
        textureIds[path] = false;
        return nil;
    end

    textureIds[path] = textureLoader.ToTextureId(texture);
    return textureIds[path];
end

function npcInfo.ClearTextureCache()
    textureIds = {};
end

return npcInfo;
