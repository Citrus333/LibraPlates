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

local npcIcons = nil;
local itemIcons = nil;
local catseyeNpcIcons = nil;
local catseyeItemIcons = nil;
local fullNpcIcons = nil;
local fullItemIcons = nil;
local fullCatseyeNpcIcons = nil;
local fullCatseyeItemIcons = nil;
local fullSourcesLoaded = false;
local activeZoneSignature = nil;
local zoneManifest = LoadTable('data.npc_object_zone_manifest');
local textureIds = {};
local currentZoneId = nil;
local currentZoneName = nil;
local MergeEntry;
local IsHiddenEntry;

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

local function GetHomePointKey(name)
    local text = NormalizeName(name);
    local lower = string.lower(text);
    local number = lower:match('home%s*point%s*#?%s*(%d+)')
        or lower:match('home%s*point.-(%d+)');

    if (number ~= nil) then
        return 'Home Point #' .. tostring(number);
    end

    return nil;
end

local function IsHomePointName(name)
    return GetHomePointKey(name) ~= nil;
end

local gatheringPointNames = {
    ['Excavation Point'] = true,
    ['Excav. Point'] = true,
    ['Harvest Point'] = true,
    ['Harvesting Point'] = true,
    ['Logging Point'] = true,
    ['Mining Point'] = true,
};

local gatheringPointFallbacks = {
    ['Excavation Point'] = { type = 'Excavation Point', icon = 'ExcavationPoint.png' },
    ['Excav. Point'] = { type = 'Excavation Point', icon = 'ExcavationPoint.png' },
    ['Harvest Point'] = { type = 'Harvest Point', icon = 'HarvestPoint.png' },
    ['Harvesting Point'] = { type = 'Harvest Point', icon = 'HarvestPoint.png' },
    ['Logging Point'] = { type = 'Logging Point', icon = 'LoggingPoint.png' },
    ['Mining Point'] = { type = 'Mining Point', icon = 'MiningPoint.png' },
};

local function IsGatheringPointName(name)
    return gatheringPointNames[NormalizeName(name)] == true;
end

local function GetGatheringPointFallback(name)
    local entry = gatheringPointFallbacks[NormalizeName(name)];

    if (entry == nil) then
        return nil;
    end

    return {
        source = 'item',
        type = entry.type,
        displayName = '',
        icon = entry.icon,
        link = '',
        info = '',
        note = '',
        zones = nil,
        worldOffsetX = nil,
        worldOffsetY = nil,
        worldOffsetZ = nil,
        anchorBone = nil,
    };
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

local function CopySourceEntries(target, source)
    if (type(target) ~= 'table' or type(source) ~= 'table') then
        return;
    end

    for name, entry in pairs(source) do
        target[name] = entry;
    end
end

local function LoadZoneFile(fileName)
    local moduleName = tostring(fileName or ''):gsub('%.lua$', '');

    if (moduleName == '') then
        return {};
    end

    return LoadTable('data.npc_object_zones.' .. moduleName);
end

local function LoadFullSources()
    if (fullSourcesLoaded == true) then
        return;
    end

    fullNpcIcons = LoadTable('data.npc_icons');
    fullItemIcons = LoadTable('data.item_icons');
    fullCatseyeNpcIcons = LoadTable('data.catseye_npc_icons');
    fullCatseyeItemIcons = LoadTable('data.catseye_item_icons');
    fullSourcesLoaded = true;
end

local function BuildActiveZoneSources()
    local zoneId = GetCurrentZoneId();
    local zoneName = GetCurrentZoneName();

    if (zoneId == 0 and zoneName == nil) then
        LoadFullSources();
        npcIcons = fullNpcIcons;
        itemIcons = fullItemIcons;
        catseyeNpcIcons = fullCatseyeNpcIcons;
        catseyeItemIcons = fullCatseyeItemIcons;
        activeZoneSignature = 'full';
        return;
    end

    local signature = tostring(zoneId or 0) .. ':' .. tostring(zoneName or '');

    if (signature == activeZoneSignature and npcIcons ~= nil and itemIcons ~= nil and catseyeNpcIcons ~= nil and catseyeItemIcons ~= nil) then
        return;
    end

    local globalData = LoadZoneFile(zoneManifest.global);
    local zoneIdFile = nil;
    local zoneNameFile = nil;

    if (type(zoneManifest.zoneIds) == 'table') then
        zoneIdFile = zoneManifest.zoneIds[zoneId] or zoneManifest.zoneIds[tostring(zoneId)];
    end

    if (type(zoneManifest.zoneNames) == 'table' and zoneName ~= nil) then
        zoneNameFile = zoneManifest.zoneNames[zoneName];
    end

    local zoneIdData = LoadZoneFile(zoneIdFile);
    local zoneNameData = (zoneNameFile ~= zoneIdFile) and LoadZoneFile(zoneNameFile) or {};
    local activeNpcIcons = {};
    local activeItemIcons = {};
    local activeCatseyeNpcIcons = {};
    local activeCatseyeItemIcons = {};

    CopySourceEntries(activeNpcIcons, globalData.npc);
    CopySourceEntries(activeItemIcons, globalData.item);
    CopySourceEntries(activeCatseyeNpcIcons, globalData.catseyeNpc);
    CopySourceEntries(activeCatseyeItemIcons, globalData.catseyeItem);
    CopySourceEntries(activeNpcIcons, zoneIdData.npc);
    CopySourceEntries(activeItemIcons, zoneIdData.item);
    CopySourceEntries(activeCatseyeNpcIcons, zoneIdData.catseyeNpc);
    CopySourceEntries(activeCatseyeItemIcons, zoneIdData.catseyeItem);
    CopySourceEntries(activeNpcIcons, zoneNameData.npc);
    CopySourceEntries(activeItemIcons, zoneNameData.item);
    CopySourceEntries(activeCatseyeNpcIcons, zoneNameData.catseyeNpc);
    CopySourceEntries(activeCatseyeItemIcons, zoneNameData.catseyeItem);

    npcIcons = activeNpcIcons;
    itemIcons = activeItemIcons;
    catseyeNpcIcons = activeCatseyeNpcIcons;
    catseyeItemIcons = activeCatseyeItemIcons;
    activeZoneSignature = signature;
end

local function GetSourceTables(useFull)
    if (useFull == true) then
        LoadFullSources();

        return {
            npc = fullNpcIcons,
            item = fullItemIcons,
            catseyeNpc = fullCatseyeNpcIcons,
            catseyeItem = fullCatseyeItemIcons,
        };
    end

    BuildActiveZoneSources();

    return {
        npc = npcIcons or {},
        item = itemIcons or {},
        catseyeNpc = catseyeNpcIcons or {},
        catseyeItem = catseyeItemIcons or {},
    };
end

local function ReadEntry(sourceName, entry, ignoreZone)
    if (type(entry) ~= 'table') then
        return nil;
    end

    if (ignoreZone ~= true and EntryMatchesCurrentZone(entry) ~= true) then
        return nil;
    end

    local infoType = tostring(entry.type or '');
    local displayName = tostring(entry.displayName or '');
    local icon = tostring(entry.icon or '');
    local link = tostring(entry.link or '');
    local note = tostring(entry.note or '');
    local info = tostring(entry.info or '');
    local worldOffsetX = tonumber(entry.worldOffsetX);
    local worldOffsetY = tonumber(entry.worldOffsetY);
    local worldOffsetZ = tonumber(entry.worldOffsetZ);
    local anchorBone = tonumber(entry.anchorBone);
    local hidden = IsHiddenEntry(entry);
    local zones = GetEntryZones(entry);

    if (note ~= '' and info == '') then
        info = note;
    end

    if (infoType == '' and displayName == '' and icon == '' and link == '' and note == '' and info == '' and worldOffsetX == nil and worldOffsetY == nil and worldOffsetZ == nil and anchorBone == nil and hidden ~= true) then
        return nil;
    end

    return {
        source = sourceName,
        type = infoType,
        displayName = displayName,
        icon = icon,
        link = link,
        info = info,
        note = note,
        zones = zones,
        worldOffsetX = worldOffsetX,
        worldOffsetY = worldOffsetY,
        worldOffsetZ = worldOffsetZ,
        anchorBone = anchorBone,
        hidden = hidden,
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

    if (primary.hidden ~= true and fallback.hidden == true) then
        primary.hidden = true;
    end

    return primary;
end

IsHiddenEntry = function(entry)
    if (type(entry) ~= 'table') then
        return false;
    end

    local value = entry.hidden;

    if (value == nil) then value = entry.hidePlate; end
    if (value == nil) then value = entry.hiddenPlate; end
    if (value == nil) then value = entry.status; end

    if (value == true) then
        return true;
    end

    local text = tostring(value or ''):lower();

    return text == 'hidden' or text == 'hide' or text == 'hideplate' or text == 'hide_plate';
end

function npcInfo.ShouldHidePlate(name)
    local sources = GetSourceTables(false);
    local cleanName = NormalizeName(name);
    local entry = (sources.catseyeItem or {})[cleanName]
        or (sources.item or {})[cleanName]
        or (sources.catseyeNpc or {})[cleanName]
        or (sources.npc or {})[cleanName]
        or (sources.catseyeItem or {})[CleanName(name)]
        or (sources.item or {})[CleanName(name)]
        or (sources.catseyeNpc or {})[CleanName(name)]
        or (sources.npc or {})[CleanName(name)];

    return IsHiddenEntry(entry) == true;
end

function npcInfo.Find(name, entityType, options)
    if (npcInfo.ShouldHidePlate(name) == true) then
        return nil;
    end

    local kind = tostring(entityType or ''):lower();
    local cleanName = CleanName(name);
    local ignoreZone = type(options) == 'table' and options.ignoreZone == true;
    local homePointKey = GetHomePointKey(name);
    local itemLookupName = homePointKey or name;
    local forceItemZoneMatchOff = homePointKey ~= nil;
    local sources = GetSourceTables(ignoreZone or forceItemZoneMatchOff);

    if (kind == 'object') then
        local item = FindIn(itemLookupName, 'catseye_item', sources.catseyeItem, ignoreZone or forceItemZoneMatchOff, options)
            or FindScopedIn(itemLookupName, 'item', sources.item, ignoreZone or forceItemZoneMatchOff, options)
            or FindIn(itemLookupName, 'item', sources.item, ignoreZone or forceItemZoneMatchOff, options)
            or GetGatheringPointFallback(name);
        local npc = FindIn(name, 'catseye_npc', sources.catseyeNpc, ignoreZone, options)
            or FindScopedIn(name, 'npc', sources.npc, ignoreZone, options)
            or (ignoreZone ~= true and cleanName == 'Moogle' and FindMogHouseMoogleAlias('npc', sources.npc) or nil)
            or FindIn(name, 'npc', sources.npc, ignoreZone, options);

        return MergeEntry(item, npc);
    end

    local catseyeNpc = FindIn(name, 'catseye_npc', sources.catseyeNpc, ignoreZone, options)
        or FindScopedIn(name, 'catseye_npc', sources.catseyeNpc, ignoreZone, options);
    local npc = FindScopedIn(name, 'npc', sources.npc, ignoreZone, options)
        or (ignoreZone ~= true and cleanName == 'Moogle' and FindMogHouseMoogleAlias('npc', sources.npc) or nil)
        or FindIn(name, 'npc', sources.npc, ignoreZone, options);

    return MergeEntry(catseyeNpc, npc) or npc;
end

function npcInfo.ResolveKind(name, entityType, options)
    local homePointKey = GetHomePointKey(name);
    local itemLookupName = homePointKey or name;
    local forceItemZoneMatchOff = homePointKey ~= nil;
    local sources = GetSourceTables(type(options) == 'table' and options.ignoreZone == true or forceItemZoneMatchOff);
    local catseyeItemInfo = FindIn(itemLookupName, 'catseye_item', sources.catseyeItem, forceItemZoneMatchOff, options);

    if (catseyeItemInfo ~= nil) then
        return 'Object', catseyeItemInfo;
    end

    local itemInfo = FindScopedIn(itemLookupName, 'item', sources.item, forceItemZoneMatchOff, options)
        or FindIn(itemLookupName, 'item', sources.item, forceItemZoneMatchOff, options);

    if (itemInfo ~= nil and (forceItemZoneMatchOff == true or IsGatheringPointName(name) == true)) then
        return 'Object', itemInfo;
    end

    local gatheringFallback = GetGatheringPointFallback(name);

    if (gatheringFallback ~= nil) then
        return 'Object', gatheringFallback;
    end

    local info = npcInfo.Find(name, entityType, options);
    local rawType = tostring(entityType or ''):lower();

    if (info ~= nil) then
        if (info.source == 'item' or info.source == 'catseye_item') then
            return 'Object', info;
        end

        return 'NPC', info;
    end

    itemInfo = FindIn(itemLookupName, 'catseye_item', sources.catseyeItem, forceItemZoneMatchOff, options)
        or itemInfo
        or FindScopedIn(itemLookupName, 'item', sources.item, forceItemZoneMatchOff, options)
        or FindIn(itemLookupName, 'item', sources.item, forceItemZoneMatchOff, options);

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

function npcInfo.GetTextureIdForInfo(info)
    local path = BuildIconPath(info);
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

function npcInfo.GetTextureId(name, entityType, options)
    return npcInfo.GetTextureIdForInfo(npcInfo.Find(name, entityType, options));
end

function npcInfo.ClearTextureCache()
    textureIds = {};
end

return npcInfo;
