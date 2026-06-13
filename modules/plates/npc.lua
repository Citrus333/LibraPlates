local nameDefaults = require('config.widgets.name');
local backgroundDefaults = require('config.widgets.background');
local distanceDefaults = require('config.widgets.distance');
local typeLineDefaults = require('config.widgets.type_line');
local npcObjectIconDefaults = require('config.widgets.npc_object_icon');
local globalDefaults = require('config.global');
local fonts = require('core.fonts');
local textScale = require('core.text_scale');
local canvasTexture = require('core.canvas_texture');
local backgroundTextures = require('core.background_textures');
local entities = require('core.entities');
local adaptivePerformance = require('core.adaptive_performance');
local npcObjectInfo = require('core.npc_object_info');
local perfMeter = require('core.perf_meter');
local state = require('core.state');
local targetModuleMarker = require('core.target_module_marker');
local targeting = require('core.targeting');
local worldDepthPlate = require('core.world_depth_plate');
local worldMarkerProbe = require('core.world_marker_probe');

local npcPlate = {};
local plateCache = {};
local indexCache = {};
local maxPlateCacheEntries = 128;
local lastPlateCacheTrim = 0;
local scanCache = {
    clock = 0,
    range = nil,
    entities = nil,
};
local idleScanCacheSeconds = 0.20;

local function ColorKey(color)
    color = color or {};

    return table.concat({
        string.format('%.3f', tonumber(color[1]) or 0),
        string.format('%.3f', tonumber(color[2]) or 0),
        string.format('%.3f', tonumber(color[3]) or 0),
        string.format('%.3f', tonumber(color[4]) or 0),
    }, ',');
end

local function BoolKey(value)
    return value == true and '1' or '0';
end

local function ClearPlateCache()
    for _, cached in pairs(plateCache) do
        if (cached ~= nil and cached.textureKey ~= nil) then
            canvasTexture.ReleaseKey(cached.textureKey);
        end
    end

    plateCache = {};
    indexCache = {};
    collectgarbage('step', 64);
end

local function TouchPlateCacheEntry(cached)
    if (cached == nil) then
        return;
    end

    cached.lastUsed = os.clock();

    if (cached.textureKey ~= nil) then
        canvasTexture.TouchKey(cached.textureKey);
    end
end

local function TrimPlateCache()
    local now = os.clock();

    if ((now - lastPlateCacheTrim) < 5.0) then
        return;
    end

    lastPlateCacheTrim = now;

    local entries = {};

    for key, cached in pairs(plateCache) do
        entries[#entries + 1] = {
            key = key,
            lastUsed = tonumber(cached ~= nil and cached.lastUsed) or 0,
            textureKey = cached ~= nil and cached.textureKey or nil,
        };
    end

    if (#entries <= maxPlateCacheEntries) then
        return;
    end

    table.sort(entries, function(left, right)
        return (tonumber(left.lastUsed) or 0) < (tonumber(right.lastUsed) or 0);
    end);

    for i = 1, (#entries - maxPlateCacheEntries) do
        local entry = entries[i];

        plateCache[entry.key] = nil;

        if (entry.textureKey ~= nil) then
            canvasTexture.ReleaseKey(entry.textureKey);
        end

        for index, indexed in pairs(indexCache) do
            if (indexed ~= nil and indexed.cacheKey == entry.key) then
                indexCache[index] = nil;
            end
        end
    end

    collectgarbage('step', 64);
end

local function NumberKey(value)
    return tostring(tonumber(value) or 0);
end

local function FormatDistanceText(settings, distance)
    return tostring(settings ~= nil and settings.prefix or '') .. string.format('%.0f', tonumber(distance) or 0);
end

local function SettingKey(settings, fields)
    local parts = {};

    settings = settings or {};

    for _, field in ipairs(fields) do
        local value = settings[field];

        if (type(value) == 'table') then
            parts[#parts + 1] = field .. '=' .. ColorKey(value);
        elseif (type(value) == 'boolean') then
            parts[#parts + 1] = field .. '=' .. BoolKey(value);
        else
            parts[#parts + 1] = field .. '=' .. tostring(value);
        end
    end

    return table.concat(parts, ';');
end

local function ApplyNpcAnchorDefaults(settings, defaults, oldOffsetX, oldOffsetY)
    if (settings == nil or defaults == nil or settings.anchorTo ~= nil) then
        return;
    end

    settings.anchorTo = defaults.anchorTo;
    settings.anchorPoint = defaults.anchorPoint;

    if (
        tonumber(settings.offsetX) == tonumber(oldOffsetX) and
        tonumber(settings.offsetY) == tonumber(oldOffsetY)
    ) then
        settings.offsetX = defaults.offsetX;
        settings.offsetY = defaults.offsetY;
    end
end

local function ShortenName(name, maxLength)
    local text = tostring(name or '');
    local limit = tonumber(maxLength) or 0;

    if (limit > 0 and string.len(text) > limit) then
        return string.sub(text, 1, limit);
    end

    return text;
end

local function CleanDisplayName(name)
    return tostring(name or ''):gsub('\170', '');
end

local function HasReadableDisplayName(name)
    local text = CleanDisplayName(name);
    text = text:gsub('%c', '');
    text = text:gsub('^%s+', ''):gsub('%s+$', '');

    return text:match('%S') ~= nil;
end

local function BuildTargetMarkerKey(marker)
    if (marker == nil or marker.enabled ~= true) then
        return 'target=off';
    end

    return table.concat({
        'target=on',
        BoolKey(marker.showBackground),
        BoolKey(marker.showArrow),
        BoolKey(marker.showChevrons),
        tostring(marker.backgroundTextureId or ''),
        tostring(marker.arrowTextureId or ''),
        tostring(marker.chevronTextureId or ''),
        NumberKey(marker.arrowWidth),
        NumberKey(marker.arrowHeight),
        NumberKey(marker.arrowSpacing),
        NumberKey(marker.chevronWidth),
        NumberKey(marker.chevronHeight),
        NumberKey(marker.chevronSpacing),
        table.concat(marker.backgroundAnchorKinds or {}, ','),
        table.concat(marker.chevronAnchorKinds or {}, ','),
        ColorKey(marker.color),
        ColorKey(marker.backgroundColor),
        ColorKey(marker.arrowColor),
        ColorKey(marker.chevronColor),
    }, '|');
end

local function BuildPlateSignature(displayName, resolvedEntityName, targetStateName, npcInfo, settings, values)
    local parts = {
        'v=1',
        'policy=' .. canvasTexture.GetRenderPolicyKey(),
        'name=' .. tostring(displayName or ''),
        'entity=' .. tostring(resolvedEntityName or ''),
        'targetState=' .. tostring(targetStateName or 'Idle'),
        'infoType=' .. tostring(npcInfo ~= nil and npcInfo.type or ''),
        'infoWorldOffsetX=' .. tostring(npcInfo ~= nil and npcInfo.worldOffsetX or ''),
        'infoWorldOffsetY=' .. tostring(npcInfo ~= nil and npcInfo.worldOffsetY or ''),
        'infoWorldOffsetZ=' .. tostring(npcInfo ~= nil and npcInfo.worldOffsetZ or ''),
        'iconTex=' .. tostring(values.iconTextureId or ''),
        'typeText=' .. tostring(values.typeText or ''),
        'distanceText=' .. tostring(values.distanceText or ''),
        BuildTargetMarkerKey(values.targetMarker),
        'bg:' .. SettingKey(settings.background, { 'enabled', 'width', 'height', 'offsetX', 'offsetY', 'texture', 'color', 'borderColor', 'borderSize', 'anchorTo', 'anchorPoint' }),
        'name:' .. SettingKey(settings.name, { 'enabled', 'shortenName', 'textSize', 'color', 'outlineSize', 'outlineColor', 'offsetX', 'offsetY', 'anchorTo', 'anchorPoint' }),
        'dist:' .. SettingKey(settings.distance, { 'enabled', 'textSize', 'color', 'outlineEnabled', 'outlineColor', 'outlineSize', 'useSmallFont', 'offsetX', 'offsetY', 'prefix', 'anchorTo', 'anchorPoint' }),
        'type:' .. SettingKey(settings.typeLine, { 'enabled', 'useSmallFont', 'textSize', 'color', 'outlineEnabled', 'outlineColor', 'outlineSize', 'offsetX', 'offsetY', 'anchorTo', 'anchorPoint' }),
        'icon:' .. SettingKey(settings.icon, { 'enabled', 'iconSize', 'offsetX', 'offsetY', 'anchorTo', 'anchorPoint' }),
    };

    return table.concat(parts, '\n');
end

local function IsAlwaysReadableGatheringPoint(clickTargetType, displayName)
    if (clickTargetType ~= 'object') then
        return false;
    end

    return
        displayName == 'Logging Point' or
        displayName == 'Harvest Point' or
        displayName == 'Mining Point' or
        displayName == 'Excavation Point';
end

local function QueueCachedPlate(entity, cached, targetStateName, clickTargetType, displayName)
    if (cached == nil or cached.texture == nil) then
        return false;
    end

    TouchPlateCacheEntry(cached);

    local plateTextureId = canvasTexture.GetTextureId(cached.texture);

    if (plateTextureId == nil) then
        return false;
    end

    local isTacticalTarget = targetStateName ~= 'Idle';
    local isAlwaysReadableGatheringPoint = IsAlwaysReadableGatheringPoint(clickTargetType, displayName);
    local queueTimer = perfMeter.BeginDetail('npc.queue');
    local targetingSettings = targeting.GetSettings();

    worldMarkerProbe.QueuePlate({
        targetIndex = entity.index,
        distance = entity.distance,
        hp = 100,
        name = '',
        isSelf = false,
        stateName = targetStateName,
        clickTargetType = clickTargetType,
        worldMarker = targeting.ApplyPlateScalingSettings({
            hpBar = { enabled = false },
            plateTextureId = plateTextureId,
            plateAlwaysOnTop = isTacticalTarget == true or isAlwaysReadableGatheringPoint == true,
            plateTacticalOverlayOnly = false,
            plateWorldWidth = 2.35,
            plateWorldHeight = 1.18,
            plateWorldOffsetX = cached.plateWorldOffsetX,
            plateWorldOffsetY = cached.plateWorldOffsetY,
            plateWorldOffsetZ = cached.plateWorldOffsetZ,
            plateDistanceScaleOffsetY = -0.12,
            plateTextureWidth = cached.textureWidth,
            plateTextureHeight = cached.textureHeight,
            plateClickRects = cached.elementRects,
            clickTargetType = clickTargetType,
            clickName = displayName,
            layoutStateName = 'Idle',
        }, clickTargetType == 'object' and 'object' or 'npc', cached.plateWorldOffsetX, cached.plateWorldOffsetY),
    });
    perfMeter.EndDetail(queueTimer);

    return true;
end

local function QueueNpcObject(entity)
    local resolveTimer = perfMeter.BeginDetail('npc.resolve');
    local entityName = tostring(entity.entityType or 'NPC');
    local displayName = CleanDisplayName(entity.name);
    local resolvedEntityName, npcInfo = npcObjectInfo.ResolveKind(displayName, entityName);
    local settingsEntityName = resolvedEntityName;
    local clickTargetType = string.lower(resolvedEntityName);
    local targetStateName = targeting.GetTargetStateName(entity.index);
    perfMeter.EndDetail(resolveTimer);

    local now = os.clock();
    local throttleBackground = adaptivePerformance.ShouldThrottleBackground() == true;

    if (targetStateName == 'Idle' and state.GetConfigOpen() ~= true) then
        local fastCacheTimer = perfMeter.BeginDetail('npc.fastCache');
        local indexed = indexCache[tonumber(entity.index) or 0];

        if (
            indexed ~= nil and
            indexed.displayName == displayName and
            indexed.clickTargetType == clickTargetType and
            indexed.targetStateName == targetStateName
        ) then
            local distanceMatches = true;

            if (indexed.distanceEnabled == true and targetStateName ~= 'Idle') then
                local distanceText = FormatDistanceText({ prefix = indexed.distancePrefix or '' }, entity.distance);
                distanceMatches = distanceText == indexed.distanceText;
            end

            local quickCached = distanceMatches == true and plateCache[indexed.cacheKey] or nil;

            if (
                quickCached == nil and
                throttleBackground == true and
                indexed.cacheKey ~= nil and
                (now - (tonumber(indexed.clock) or 0)) < 1.00
            ) then
                quickCached = plateCache[indexed.cacheKey];
            end

            if (quickCached ~= nil and quickCached.fastReusable == true) then
                if (QueueCachedPlate(entity, quickCached, targetStateName, clickTargetType, displayName) == true) then
                    perfMeter.EndDetail(fastCacheTimer);
                    return;
                end
            end
        end
        perfMeter.EndDetail(fastCacheTimer);
    end

    local settingsTimer = perfMeter.BeginDetail('npc.settings');
    local isTacticalTarget = targetStateName ~= 'Idle';
    local showDistanceBadge = targetStateName == 'Target' or targetStateName == 'Subtarget';
    local backgroundSettings = state.GetWidgetSettings(settingsEntityName, 'Idle', 'Background', backgroundDefaults);
    local nameSettings = state.GetWidgetSettings(settingsEntityName, 'Idle', 'Name', nameDefaults);
    local distanceSettings = state.GetWidgetSettings(settingsEntityName, 'Idle', 'Distance', distanceDefaults);
    local typeLineSettings = state.GetWidgetSettings(settingsEntityName, 'Idle', 'Type line', typeLineDefaults);
    local iconSettings = state.GetWidgetSettings(settingsEntityName, 'Idle', 'Icon', npcObjectIconDefaults);
    local targetMarker = (resolvedEntityName ~= 'Object' and targetStateName ~= 'Idle')
        and targetModuleMarker.Build(settingsEntityName, 'Idle', targetStateName, { enabled = false }, entity.distance)
        or { enabled = false };

    ApplyNpcAnchorDefaults(iconSettings, npcObjectIconDefaults, -28, -30);
    ApplyNpcAnchorDefaults(typeLineSettings, typeLineDefaults, 0, -30);

    local globalSettings = state.GetGlobalSettings(globalDefaults);
    local iconTextureId = iconSettings.enabled == true and npcObjectInfo.GetTextureId(displayName, resolvedEntityName) or nil;
    local typeText = typeLineSettings.enabled == true and npcObjectInfo.GetType(displayName, resolvedEntityName) or nil;
    local distanceText = nil;

    if (showDistanceBadge == true and distanceSettings.enabled == true and entity.distance ~= nil) then
        distanceText = FormatDistanceText(distanceSettings, entity.distance);
    end
    perfMeter.EndDetail(settingsTimer);

    local signatureTimer = perfMeter.BeginDetail('npc.signature');
    local cacheKey = table.concat({
        clickTargetType,
        displayName,
        targetStateName,
        tostring(distanceText or ''),
    }, ':');
    local signature = BuildPlateSignature(displayName, resolvedEntityName, targetStateName, npcInfo, {
        background = backgroundSettings,
        name = nameSettings,
        distance = distanceSettings,
        typeLine = typeLineSettings,
        icon = iconSettings,
    }, {
        iconTextureId = iconTextureId,
        typeText = typeText,
        distanceText = distanceText,
        targetMarker = targetMarker,
    });
    local cached = plateCache[cacheKey];
    local plateTexture = nil;
    local textureWidth = nil;
    local textureHeight = nil;
    local elementRects = nil;

    if (cached ~= nil and cached.signature == signature and cached.texture ~= nil) then
        TouchPlateCacheEntry(cached);
        plateTexture = cached.texture;
        textureWidth = cached.textureWidth;
        textureHeight = cached.textureHeight;
        elementRects = cached.elementRects;
    end
    perfMeter.EndDetail(signatureTimer);

    local plateData = {
        name = (nameSettings.enabled == true and (targetStateName == 'Idle' or HasReadableDisplayName(displayName) == true)) and ShortenName(displayName, nameSettings.shortenName) or '',
        nameFontFamily = fonts.GetRole(globalSettings, false),
        nameFontFlags = fonts.GetRoleFlags(globalSettings, false),
        nameFontSize = textScale.ToNameTextureFontSize(nameSettings.textSize, nameDefaults.textSize),
        nameColor = nameSettings.color or { 1.0, 1.0, 1.0, 1.0 },
        nameOutlineEnabled = (tonumber(nameSettings.outlineSize) or 0) > 0,
        nameOutlineColor = nameSettings.outlineColor or { 0.0, 0.0, 0.0, 1.0 },
        nameOutlineSize = tonumber(nameSettings.outlineSize) or 0,
        nameOffsetX = tonumber(nameSettings.offsetX) or 0,
        nameOffsetY = tonumber(nameSettings.offsetY) or -54,
        nameAnchorTo = nameSettings.anchorTo or nameDefaults.anchorTo,
        nameAnchorPoint = nameSettings.anchorPoint or nameDefaults.anchorPoint,
        anchorMap = {
            ['Background'] = 'background',
            ['Name'] = 'name',
            ['HP Bar'] = 'hp',
            ['MP Bar'] = 'mp',
            ['TP Bar'] = 'tp',
            ['Cast bar'] = 'cast',
            ['Job'] = 'job',
            ['Level'] = 'level',
            ['ID'] = 'id',
            ['Icon'] = 'npc_object_icon',
            ['Type line'] = 'type',
            ['Distance'] = 'distance',
        },
        hpBar = { enabled = false },
        mpBar = { enabled = false },
        tpBar = { enabled = false },
        targetMarker = targetMarker,
        background = {
            enabled = backgroundSettings.enabled == true,
            width = tonumber(backgroundSettings.width) or backgroundDefaults.width,
            height = tonumber(backgroundSettings.height) or backgroundDefaults.height,
            offsetX = tonumber(backgroundSettings.offsetX) or backgroundDefaults.offsetX,
            offsetY = tonumber(backgroundSettings.offsetY) or backgroundDefaults.offsetY,
            color = backgroundSettings.color or backgroundDefaults.color,
            borderColor = backgroundSettings.borderColor or backgroundDefaults.borderColor,
            borderSize = tonumber(backgroundSettings.borderSize) or backgroundDefaults.borderSize,
            texture = backgroundSettings.texture or backgroundDefaults.texture,
            textureId = backgroundTextures.GetTextureId(backgroundSettings.texture or backgroundDefaults.texture),
            anchorTo = backgroundSettings.anchorTo or backgroundDefaults.anchorTo,
            anchorPoint = backgroundSettings.anchorPoint or backgroundDefaults.anchorPoint,
        },
    };

    if (distanceText ~= nil) then
        plateData.badges = plateData.badges or {};
        plateData.badges[#plateData.badges + 1] = {
            kind = 'distance',
            text = distanceText,
            offsetX = tonumber(distanceSettings.offsetX) or distanceDefaults.offsetX,
            offsetY = tonumber(distanceSettings.offsetY) or distanceDefaults.offsetY,
            fontFamily = fonts.GetRole(globalSettings, distanceSettings.useSmallFont == true),
            fontFlags = fonts.GetRoleFlags(globalSettings, distanceSettings.useSmallFont == true),
            fontSize = textScale.ToTextureFontSize(distanceSettings.textSize, distanceDefaults.textSize),
            textColor = distanceSettings.color or distanceDefaults.color,
            textOutlineEnabled = distanceSettings.outlineEnabled == true,
            textOutlineColor = distanceSettings.outlineColor or distanceDefaults.outlineColor,
            textOutlineSize = tonumber(distanceSettings.outlineSize) or distanceDefaults.outlineSize,
            anchorTo = distanceSettings.anchorTo or distanceDefaults.anchorTo,
            anchorPoint = distanceSettings.anchorPoint or distanceDefaults.anchorPoint,
            backgroundEnabled = false,
        };
    end

    if (iconSettings.enabled == true and iconTextureId ~= nil) then
        plateData.icons = plateData.icons or {};
        plateData.icons[#plateData.icons + 1] = {
            kind = 'npc_object_icon',
            textureId = iconTextureId,
            size = tonumber(iconSettings.iconSize) or npcObjectIconDefaults.iconSize,
            offsetX = tonumber(iconSettings.offsetX) or npcObjectIconDefaults.offsetX,
            offsetY = tonumber(iconSettings.offsetY) or npcObjectIconDefaults.offsetY,
            anchorTo = iconSettings.anchorTo or npcObjectIconDefaults.anchorTo,
            anchorPoint = iconSettings.anchorPoint or npcObjectIconDefaults.anchorPoint,
        };
    end

    if (typeLineSettings.enabled == true and typeText ~= nil and typeText ~= '') then
        plateData.texts = plateData.texts or {};
        plateData.texts[#plateData.texts + 1] = {
            kind = 'type',
            text = typeText,
            align = 'center',
            offsetX = tonumber(typeLineSettings.offsetX) or typeLineDefaults.offsetX,
            offsetY = tonumber(typeLineSettings.offsetY) or typeLineDefaults.offsetY,
            anchorTo = typeLineSettings.anchorTo or typeLineDefaults.anchorTo,
            anchorPoint = typeLineSettings.anchorPoint or typeLineDefaults.anchorPoint,
            fontFamily = fonts.GetRole(globalSettings, typeLineSettings.useSmallFont == true),
            fontFlags = fonts.GetRoleFlags(globalSettings, typeLineSettings.useSmallFont == true),
            fontSize = textScale.ToTextureFontSize(typeLineSettings.textSize, typeLineDefaults.textSize),
            color = typeLineSettings.color or typeLineDefaults.color,
            outlineEnabled = typeLineSettings.outlineEnabled == true,
            outlineColor = typeLineSettings.outlineColor or typeLineDefaults.outlineColor,
            outlineSize = tonumber(typeLineSettings.outlineSize) or typeLineDefaults.outlineSize,
        };
    end

    if (
        plateTexture == nil and
        throttleBackground == true and
        targetStateName == 'Idle' and
        adaptivePerformance.AllowBackgroundBuild('npc.idle.canvas', 1) ~= true
    ) then
        local indexed = indexCache[tonumber(entity.index) or 0];
        local deferredCached = indexed ~= nil and plateCache[indexed.cacheKey] or nil;

        if (deferredCached ~= nil and deferredCached.fastReusable == true) then
            QueueCachedPlate(entity, deferredCached, targetStateName, clickTargetType, displayName);
            return;
        end
    end

    if (plateTexture == nil) then
        local canvasTimer = perfMeter.BeginDetail('npc.canvas');
        plateTexture, textureWidth, textureHeight = canvasTexture.Render(plateData, 'npc-cache-' .. cacheKey);
        elementRects = plateData._elementRects or canvasTexture.GetElementRects(plateData);
        plateCache[cacheKey] = {
            signature = signature,
            texture = plateTexture,
            textureKey = 'npc-cache-' .. cacheKey,
            lastUsed = os.clock(),
            textureWidth = textureWidth,
            textureHeight = textureHeight,
            elementRects = elementRects,
            plateWorldOffsetX = tonumber(npcInfo ~= nil and npcInfo.worldOffsetX or nil) or 0,
            plateWorldOffsetY = tonumber(npcInfo ~= nil and npcInfo.worldOffsetY or nil) or ((resolvedEntityName == 'Object') and 0.95 or 0.62),
            plateWorldOffsetZ = tonumber(npcInfo ~= nil and npcInfo.worldOffsetZ or nil) or 0,
            fastReusable = targetStateName == 'Idle',
        };
        perfMeter.EndDetail(canvasTimer);
    end

    if (targetStateName == 'Idle') then
        indexCache[tonumber(entity.index) or 0] = {
            cacheKey = cacheKey,
            displayName = displayName,
            clickTargetType = clickTargetType,
            targetStateName = targetStateName,
            clock = os.clock(),
            distanceEnabled = distanceText ~= nil,
            distancePrefix = distanceSettings.prefix or '',
            distanceText = distanceText,
        };
    else
        indexCache[tonumber(entity.index) or 0] = nil;
    end

    local plateTextureId = canvasTexture.GetTextureId(plateTexture);

    if (plateTextureId == nil) then
        return;
    end

    local plateWorldOffsetX = tonumber(npcInfo ~= nil and npcInfo.worldOffsetX or nil) or 0;
    local plateWorldOffsetY = tonumber(npcInfo ~= nil and npcInfo.worldOffsetY or nil) or ((resolvedEntityName == 'Object') and 0.95 or 0.62);
    local plateWorldOffsetZ = tonumber(npcInfo ~= nil and npcInfo.worldOffsetZ or nil) or 0;
    local anchorBone = tonumber(npcInfo ~= nil and npcInfo.anchorBone or nil);
    local isAlwaysReadableGatheringPoint = IsAlwaysReadableGatheringPoint(clickTargetType, displayName);
    local queueTimer = perfMeter.BeginDetail('npc.queue');
    local targetingSettings = targeting.GetSettings();

    worldMarkerProbe.QueuePlate({
        targetIndex = entity.index,
        distance = entity.distance,
        hp = 100,
        name = '',
        isSelf = false,
        stateName = targetStateName,
        clickTargetType = clickTargetType,
        worldMarker = targeting.ApplyPlateScalingSettings({
            hpBar = { enabled = false },
            plateTextureId = plateTextureId,
            plateAlwaysOnTop = isTacticalTarget == true or isAlwaysReadableGatheringPoint == true,
            plateTacticalOverlayOnly = false,
            anchorBone = anchorBone,
            plateWorldWidth = 2.35,
            plateWorldHeight = 1.18,
            plateWorldOffsetX = plateWorldOffsetX,
            plateWorldOffsetY = plateWorldOffsetY,
            plateWorldOffsetZ = plateWorldOffsetZ,
            plateDistanceScaleOffsetY = -0.12,
            plateTextureWidth = textureWidth,
            plateTextureHeight = textureHeight,
            plateClickRects = elementRects or plateData._elementRects or canvasTexture.GetElementRects(plateData),
            clickTargetType = clickTargetType,
            clickName = displayName,
            layoutStateName = 'Idle',
        }, clickTargetType == 'object' and 'object' or 'npc', plateWorldOffsetX, plateWorldOffsetY),
    });
    perfMeter.EndDetail(queueTimer);
end

function npcPlate.Build()
    return nil;
end

function npcPlate.ClearCache()
    ClearPlateCache();
end

function npcPlate.Render()
    if (state.GetWorldEnabled() ~= true) then
        return;
    end

    if (state.GetConfigOpen() == true) then
        ClearPlateCache();
    end

    TrimPlateCache();

    if (worldDepthPlate.IsEnabled() == true) then
        return;
    end

    if (worldMarkerProbe.GetEnabled() ~= true or worldMarkerProbe.GetReplacePlates() ~= true) then
        return;
    end

    local playerEngaged = targeting.IsPlayerEngaged() == true;
    local range = targeting.GetWorldPlateRange();
    local now = os.clock();
    local canUseScanCache = playerEngaged ~= true
        and state.GetConfigOpen() ~= true;
    local entitiesList = nil;

    if (
        canUseScanCache == true and
        scanCache.entities ~= nil and
        scanCache.range == range and
        (now - (tonumber(scanCache.clock) or 0)) < idleScanCacheSeconds
    ) then
        entitiesList = scanCache.entities;
    else
        local scanTimer = perfMeter.BeginDetail('npc.scan');
        entitiesList = entities.GetNearbyNpcObjects(range);
        perfMeter.EndDetail(scanTimer);

        if (canUseScanCache == true) then
            scanCache.clock = now;
            scanCache.range = range;
            scanCache.entities = entitiesList;
        else
            scanCache.entities = nil;
        end
    end

    for _, entity in ipairs(entitiesList) do
        QueueNpcObject(entity);
    end
end

return npcPlate;
