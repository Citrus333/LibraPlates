local npcInfo = {};
local textureLoader = require('core.texture_loader');

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
local textureIds = {};
local currentZoneId = nil;
local currentZoneName = nil;

local function CleanName(name)
    return tostring(name or ''):gsub('\170', '');
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

local function ReadEntry(sourceName, entry)
    if (type(entry) ~= 'table') then
        return nil;
    end

    if (EntryMatchesCurrentZone(entry) ~= true) then
        return nil;
    end

    local infoType = tostring(entry.type or '');
    local icon = tostring(entry.icon or '');
    local link = tostring(entry.link or '');
    local note = tostring(entry.note or '');
    local info = tostring(entry.info or '');
    local worldOffsetY = tonumber(entry.worldOffsetY);
    local anchorBone = tonumber(entry.anchorBone);
    local zones = GetEntryZones(entry);

    if (note ~= '' and info == '') then
        info = note;
    end

    if (infoType == '' and icon == '' and link == '' and note == '' and info == '' and worldOffsetY == nil and anchorBone == nil) then
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
        worldOffsetY = worldOffsetY,
        anchorBone = anchorBone,
    };
end

local function FindIn(name, sourceName, source)
    return ReadEntry(sourceName, source[CleanName(name)]);
end

local function FindScopedIn(name, sourceName, source)
    local entry = source[CleanName(name)];

    if (GetEntryZones(entry) == nil) then
        return nil;
    end

    return ReadEntry(sourceName, entry);
end

local function MergeEntry(primary, fallback)
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

function npcInfo.Find(name, entityType)
    local kind = tostring(entityType or ''):lower();

    if (kind == 'object') then
        local item = FindIn(name, 'catseye_item', catseyeItemIcons)
            or FindScopedIn(name, 'item', itemIcons);
        local npc = FindIn(name, 'catseye_npc', catseyeNpcIcons)
            or FindScopedIn(name, 'npc', npcIcons)
            or FindIn(name, 'npc', npcIcons);

        return MergeEntry(item, npc);
    end

    local catseyeNpc = FindIn(name, 'catseye_npc', catseyeNpcIcons)
        or FindScopedIn(name, 'catseye_npc', catseyeNpcIcons);
    local npc = FindScopedIn(name, 'npc', npcIcons)
        or FindIn(name, 'npc', npcIcons);

    return MergeEntry(catseyeNpc, npc) or npc;
end

function npcInfo.ResolveKind(name, entityType)
    local info = npcInfo.Find(name, entityType);
    local rawType = tostring(entityType or ''):lower();

    if (info ~= nil) then
        if (info.source == 'item' or info.source == 'catseye_item') then
            return 'Object', info;
        end

        return 'NPC', info;
    end

    if (rawType == 'object') then
        -- If this is not a known object entry, keep unknowns on NPC behavior.
        return 'NPC', nil;
    end

    return 'NPC', nil;
end

function npcInfo.GetType(name, entityType)
    local info = npcInfo.Find(name, entityType);

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

function npcInfo.GetTextureId(name, entityType)
    local path = BuildIconPath(npcInfo.Find(name, entityType));

    if (path == nil or path == '') then
        return nil;
    end

    if (textureIds[path] ~= nil) then
        return textureIds[path];
    end

    textureIds[path] = textureLoader.ToTextureId(textureLoader.Load(path));
    return textureIds[path];
end

return npcInfo;
