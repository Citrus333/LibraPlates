local nameDefaults = require('config.widgets.name');
local backgroundDefaults = require('config.widgets.background');
local barDefaults = require('config.widgets.bar');
local distanceDefaults = require('config.widgets.distance');
local typeLineDefaults = require('config.widgets.type_line');
local npcObjectIconDefaults = require('config.widgets.npc_object_icon');
local globalDefaults = require('config.global');
local fonts = require('core.fonts');
local textScale = require('core.text_scale');
local canvasTexture = require('core.canvas_texture');
local barTextures = require('core.bar_textures');
local backgroundTextures = require('core.background_textures');
local entities = require('core.entities');
local clientVisibility = require('core.client_visibility');
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
local wasConfigOpen = false;
local scanCache = {
    clock = 0,
    range = nil,
    entities = nil,
    tacticalClock = 0,
    tacticalRange = nil,
    tacticalEntities = nil,
};
local plateWorkGateCache = {
    clock = 0,
    result = true,
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
    local text = tostring(name or ''):gsub('\170', '');
    text = text:gsub('%c', '');
    text = text:gsub('^%s+', ''):gsub('%s+$', '');
    return text;
end

local function HasText(value, needle)
    return tostring(value or ''):lower():find(tostring(needle or ''):lower(), 1, true) ~= nil;
end

local function TableTextHas(value, needle)
    if (type(value) == 'table') then
        for _, item in pairs(value) do
            if (TableTextHas(item, needle) == true) then
                return true;
            end
        end
        return false;
    end

    return HasText(value, needle);
end

local function IsAlliedTacticalNpcInfo(info)
    if (type(info) ~= 'table') then
        return false;
    end

    local typeText = tostring(info.type or '');
    local noteText = tostring(info.note or '');
    local isCampaignArbiter =
        HasText(noteText, 'Offers Campaign Information') == true or
        HasText(noteText, 'Campaign Allied Tags') == true or
        HasText(noteText, 'Teleportation') == true;

    if (isCampaignArbiter == true) then
        return false;
    end

    if (
        HasText(typeText, 'Campaign Battle') == true or
        HasText(typeText, 'Campaign Ally') == true or
        HasText(typeText, 'Campaign Warrior') == true or
        HasText(typeText, 'Campaign Freelance') == true or
        HasText(typeText, 'Campaign Hero') == true or
        HasText(typeText, 'Domain Invasion Ally') == true
    ) then
        return true;
    end

    return TableTextHas(info.zones, 'Battle') == true and (
        HasText(noteText, 'Campaign battle') == true or
        HasText(noteText, 'Campaign battles') == true or
        HasText(noteText, 'squadron') == true or
        HasText(noteText, 'fortifications') == true or
        HasText(noteText, 'participates') == true or
        HasText(noteText, 'engage') == true or
        HasText(typeText, 'Freelance') == true
    );
end

local function IsAlliedTacticalNpc(entity)
    local displayName = CleanDisplayName(entity ~= nil and entity.name or '');
    local _, info = npcObjectInfo.ResolveKind(displayName, 'NPC', {
        targetIndex = entity ~= nil and entity.index or nil,
        ignoreZone = true,
    });

    if (IsAlliedTacticalNpcInfo(info) == true) then
        return true;
    end

    return HasText(displayName, 'Ascetic') == true;
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

local function BuildPlateSignature(displayName, renderedDisplayName, resolvedEntityName, targetStateName, npcInfo, settings, values)
    local parts = {
        'v=1',
        'policy=' .. canvasTexture.GetRenderPolicyKey(),
        'name=' .. tostring(displayName or ''),
        'renderedName=' .. tostring(renderedDisplayName or ''),
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
        displayName == 'Harvesting Point' or
        displayName == 'Mining Point' or
        displayName == 'Excavation Point' or
        displayName == 'Excav. Point';
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
            plateSuppressWorldWhenAlwaysOnTop = isTacticalTarget == true and clickTargetType ~= 'object',
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
        }, tostring(clickTargetType or ''):lower() == 'object' and 'object' or 'npc', cached.plateWorldOffsetX, cached.plateWorldOffsetY),
    });
    perfMeter.EndDetail(queueTimer);

    return true;
end

local function QueueNpcObject(entity)
    local resolveTimer = perfMeter.BeginDetail('npc.resolve');
    local entityName = tostring(entity.entityType or 'NPC');
    local displayName = CleanDisplayName(entity.name);

    if (npcObjectInfo.ShouldHidePlate(displayName) == true) then
        perfMeter.EndDetail(resolveTimer);
        return;
    end

    if (entities.IsOwnPetIndex(entity.index) == true) then
        perfMeter.EndDetail(resolveTimer);
        return;
    end

    if (displayName == 'Luopan' or entities.IsOwnLuopanIndex(entity.index) == true) then
        perfMeter.EndDetail(resolveTimer);
        return;
    end

    if (entities.ShouldHideOtherPlayerPet(entity.index, displayName) == true) then
        perfMeter.EndDetail(resolveTimer);
        return;
    end

    local resolvedEntityName, npcInfo = npcObjectInfo.ResolveKind(displayName, entityName, { targetIndex = entity.index });
    local renderedDisplayName = tostring(npcInfo ~= nil and npcInfo.displayName or '');

    if (renderedDisplayName == '') then
        renderedDisplayName = displayName;
    end

    local settingsEntityName = resolvedEntityName;
    local clickTargetType = string.lower(resolvedEntityName);
    local targetStateName = targeting.GetTargetStateName(entity.index);
    local isTacticalTarget = targetStateName ~= 'Idle';

    if (targetStateName == 'Idle' and npcInfo ~= nil and npcInfo.hidden == true) then
        perfMeter.EndDetail(resolveTimer);
        return;
    end

    if (
        entities.IsOwnPetIndex(entity.index) ~= true and
        entities.IsSummonedPetTypeText(npcInfo ~= nil and npcInfo.type or nil) == true and
        targeting.GetSettings().hideOtherPlayerPetPlates ~= false
    ) then
        perfMeter.EndDetail(resolveTimer);
        return;
    end

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
    local showDistanceBadge = targetStateName == 'Target' or targetStateName == 'Subtarget';

    local suppressExpensiveWorldWidgets = adaptivePerformance.ShouldDisableExpensiveWorldWidgets(isTacticalTarget == true);
    local backgroundSettings = state.GetWidgetSettings(settingsEntityName, 'Idle', 'Background', backgroundDefaults);
    local nameSettings = state.GetWidgetSettings(settingsEntityName, 'Idle', 'Name', nameDefaults);
    local distanceSettings = state.GetWidgetSettings(settingsEntityName, 'Idle', 'Distance', distanceDefaults);
    local typeLineSettings = state.GetWidgetSettings(settingsEntityName, 'Idle', 'Type line', typeLineDefaults);
    local iconSettings = state.GetWidgetSettings(settingsEntityName, 'Idle', 'Icon', npcObjectIconDefaults);
    local targetMarker = { enabled = false };

    ApplyNpcAnchorDefaults(iconSettings, npcObjectIconDefaults, -28, -30);
    ApplyNpcAnchorDefaults(typeLineSettings, typeLineDefaults, 0, -30);

    local globalSettings = state.GetGlobalSettings(globalDefaults);
    local iconTextureId = suppressExpensiveWorldWidgets ~= true and iconSettings.enabled == true and npcObjectInfo.GetTextureId(displayName, resolvedEntityName) or nil;
    local typeText = suppressExpensiveWorldWidgets ~= true and typeLineSettings.enabled == true and npcObjectInfo.GetType(displayName, resolvedEntityName) or nil;
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
    local signature = BuildPlateSignature(displayName, renderedDisplayName, resolvedEntityName, targetStateName, npcInfo, {
        background = backgroundSettings,
        name = nameSettings,
        distance = distanceSettings,
        typeLine = suppressExpensiveWorldWidgets == true and { enabled = false } or typeLineSettings,
        icon = suppressExpensiveWorldWidgets == true and { enabled = false } or iconSettings,
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
        name = (nameSettings.enabled == true and (targetStateName == 'Idle' or HasReadableDisplayName(renderedDisplayName) == true)) and ShortenName(renderedDisplayName, nameSettings.shortenName) or '',
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
            plateSuppressWorldWhenAlwaysOnTop = isTacticalTarget == true and clickTargetType ~= 'object',
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
        }, resolvedEntityName == 'Object' and 'object' or 'npc', plateWorldOffsetX, plateWorldOffsetY),
    });
    perfMeter.EndDetail(queueTimer);
end

local function QueueTacticalNpc(entity)
    local displayName = CleanDisplayName(entity.name);
    if (displayName == '') then
        return;
    end

    local layoutStateName = 'Combat';
    local targetStateName = targeting.GetTargetStateName(entity.index);
    local globalSettings = state.GetGlobalSettings(globalDefaults);
    local backgroundSettings = state.GetWidgetSettings('NPC', layoutStateName, 'Background', backgroundDefaults);
    local nameSettings = state.GetWidgetSettings('NPC', layoutStateName, 'Name', nameDefaults);
    local hpBarSettings = state.GetWidgetSettings('NPC', layoutStateName, 'HP Bar', barDefaults);
    local hpPercent = math.max(0, math.min(100, tonumber(entity.hpPercent) or 100));
    local targetMarker = targetStateName ~= 'Idle'
        and targetModuleMarker.Build('NPC', layoutStateName, targetStateName, hpBarSettings, entity.distance)
        or { enabled = false };

    local plateData = {
        hp = hpPercent,
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
        name = nameSettings.enabled == true and ShortenName(displayName, nameSettings.shortenName) or '',
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
        hpBar = {
            enabled = hpBarSettings.enabled == true,
            width = tonumber(hpBarSettings.width) or 180,
            height = tonumber(hpBarSettings.height) or 12,
            offsetX = tonumber(hpBarSettings.offsetX) or 0,
            offsetY = tonumber(hpBarSettings.offsetY) or 0,
            color = hpBarSettings.color or { 0.15, 0.85, 0.25, 1.0 },
            backgroundColor = hpBarSettings.backgroundColor or { 0.05, 0.05, 0.05, 0.85 },
            borderColor = hpBarSettings.borderColor or { 0.0, 0.0, 0.0, 1.0 },
            borderSize = tonumber(hpBarSettings.borderSize) or 0,
            anchorTo = hpBarSettings.anchorTo or barDefaults.anchorTo,
            anchorPoint = hpBarSettings.anchorPoint or barDefaults.anchorPoint,
            texture = hpBarSettings.texture or 'Solid',
            textureId = barTextures.GetTextureId(hpBarSettings.texture),
            showAtPercent = tonumber(hpBarSettings.showAtPercent) or 100,
            text = hpBarSettings.showPercent == true and (tostring(math.floor(hpPercent + 0.5)) .. '%') or '',
            fontFamily = fonts.GetRole(globalSettings, hpBarSettings.useSmallFont == true),
            fontFlags = fonts.GetRoleFlags(globalSettings, hpBarSettings.useSmallFont == true),
            fontSize = textScale.ToTextureFontSize(hpBarSettings.fontSize, barDefaults.fontSize),
            textColor = hpBarSettings.textColor or { 1.0, 1.0, 1.0, 1.0 },
            textOutlineEnabled = hpBarSettings.textOutlineEnabled == true,
            textOutlineColor = hpBarSettings.textOutlineColor or { 0.0, 0.0, 0.0, 1.0 },
            textOutlineSize = tonumber(hpBarSettings.textOutlineSize) or 1,
        },
    };

    local textureKey = 'npc-tactical-' .. tostring(entity.index);
    local plateTexture, textureWidth, textureHeight = canvasTexture.Render(plateData, textureKey);
    local plateTextureId = canvasTexture.GetTextureId(plateTexture);
    if (plateTextureId == nil) then
        return;
    end

    worldMarkerProbe.QueuePlate({
        targetIndex = entity.index,
        serverId = entity.serverId,
        distance = entity.distance,
        hp = hpPercent,
        name = '',
        isSelf = false,
        stateName = targetStateName,
        clickTargetType = 'npc',
        worldMarker = targeting.ApplyPlateScalingSettings({
            hpBar = { enabled = false },
            plateTextureId = plateTextureId,
            plateAlwaysOnTop = true,
            plateTacticalOverlayOnly = true,
            plateWorldWidth = 2.35,
            plateWorldHeight = 1.18,
            plateWorldOffsetY = 0.50,
            plateDistanceScaleOffsetY = 0.28,
            plateTextureWidth = textureWidth,
            plateTextureHeight = textureHeight,
            plateClickRects = plateData._elementRects or canvasTexture.GetElementRects(plateData),
            clickTargetType = 'npc',
            clickName = displayName,
            layoutStateName = layoutStateName,
        }, 'npc', 0, 0.50),
    });
end

local function AnyNpcObjectWidgetCanLoadForEntity(entityName)
    local backgroundSettings = state.GetWidgetSettings(entityName, 'Idle', 'Background', backgroundDefaults);
    local nameSettings = state.GetWidgetSettings(entityName, 'Idle', 'Name', nameDefaults);
    local distanceSettings = state.GetWidgetSettings(entityName, 'Idle', 'Distance', distanceDefaults);
    local typeLineSettings = state.GetWidgetSettings(entityName, 'Idle', 'Type line', typeLineDefaults);
    local iconSettings = state.GetWidgetSettings(entityName, 'Idle', 'Icon', npcObjectIconDefaults);

    return
        backgroundSettings.enabled == true or
        nameSettings.enabled == true or
        distanceSettings.enabled == true or
        typeLineSettings.enabled == true or
        iconSettings.enabled == true;
end

local function AnyNpcObjectPlateWorkCanLoad()
    local now = os.clock();

    if ((now - (tonumber(plateWorkGateCache.clock) or 0)) < 0.50) then
        return plateWorkGateCache.result == true;
    end

    local result =
        AnyNpcObjectWidgetCanLoadForEntity('NPC') == true or
        AnyNpcObjectWidgetCanLoadForEntity('Object') == true;

    plateWorkGateCache.clock = now;
    plateWorkGateCache.result = result == true;

    return result == true;
end

local function AnyTacticalNpcWidgetCanLoad()
    local hpBarSettings = state.GetWidgetSettings('NPC', 'Combat', 'HP Bar', barDefaults);
    local nameSettings = state.GetWidgetSettings('NPC', 'Combat', 'Name', nameDefaults);
    local backgroundSettings = state.GetWidgetSettings('NPC', 'Combat', 'Background', backgroundDefaults);

    return hpBarSettings.enabled == true or
        nameSettings.enabled == true or
        backgroundSettings.enabled == true;
end

local function AnyNpcTargetModuleCanLoad()
    local npcTargetSettings = targetModuleMarker.GetSettings('NPC', 'Combat', 'Target');
    local npcSubtargetSettings = targetModuleMarker.GetSettings('NPC', 'Combat', 'Subtarget');

    return targetModuleMarker.HasDrawableSettings('NPC', npcTargetSettings) == true or
        targetModuleMarker.HasDrawableSettings('NPC', npcSubtargetSettings) == true;
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

    local configOpen = state.GetConfigOpen() == true;

    if (configOpen == true and wasConfigOpen ~= true) then
        ClearPlateCache();
    end
    wasConfigOpen = configOpen;

    TrimPlateCache();

    if (worldDepthPlate.IsEnabled() == true) then
        return;
    end

    if (worldMarkerProbe.GetEnabled() ~= true or worldMarkerProbe.GetReplacePlates() ~= true) then
        return;
    end

    if (clientVisibility.ShouldHideNpcObjectPlates() == true) then
        scanCache.entities = nil;
        scanCache.tacticalEntities = nil;
        return;
    end

    local canRenderNpcObjects = AnyNpcObjectPlateWorkCanLoad() == true;
    local canRenderTacticalNpcs = AnyTacticalNpcWidgetCanLoad() == true;
    local canRenderTargetNpcs = AnyNpcTargetModuleCanLoad() == true;

    if (canRenderNpcObjects ~= true and canRenderTacticalNpcs ~= true and canRenderTargetNpcs ~= true) then
        scanCache.entities = nil;
        scanCache.tacticalEntities = nil;
        return;
    end

    local playerEngaged = targeting.IsPlayerEngaged() == true;
    local range = targeting.GetWorldPlateRange();
    local now = os.clock();
    local canUseScanCache = playerEngaged ~= true
        and state.GetConfigOpen() ~= true;
    local worldNpcObjectRefreshSeconds = math.min(
        adaptivePerformance.GetWorldRefreshSeconds('npc'),
        adaptivePerformance.GetWorldRefreshSeconds('object')
    );
    local entitiesList = nil;

    if (canRenderTargetNpcs == true) then
        local queuedTargets = {};
        local targetIndex, subTargetIndex = targeting.GetCurrentTargetAndSubTargetIndexes();
        local targetIndexes = { targetIndex, subTargetIndex };

        for targetSlot = 1, 2 do
            local index = targetIndexes[targetSlot];
            index = tonumber(index);

            if (index ~= nil and queuedTargets[index] ~= true) then
                queuedTargets[index] = true;

                local tacticalEntity = entities.GetTacticalNpcByIndex(index, range);
                if (tacticalEntity ~= nil and IsAlliedTacticalNpc(tacticalEntity) == true) then
                    QueueTacticalNpc(tacticalEntity);
                end
            end
        end
    end

    if (canRenderNpcObjects ~= true) then
        entitiesList = {};
        scanCache.entities = nil;
    elseif (
        canUseScanCache == true and
        scanCache.entities ~= nil and
        scanCache.range == range and
        (now - (tonumber(scanCache.clock) or 0)) < worldNpcObjectRefreshSeconds
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

    local tacticalEntities = nil;

    if (canRenderTacticalNpcs ~= true) then
        tacticalEntities = {};
        scanCache.tacticalEntities = nil;
    elseif (
        canUseScanCache == true and
        scanCache.tacticalEntities ~= nil and
        scanCache.tacticalRange == range and
        (now - (tonumber(scanCache.tacticalClock) or 0)) < idleScanCacheSeconds
    ) then
        tacticalEntities = scanCache.tacticalEntities;
    else
        local tacticalScanTimer = perfMeter.BeginDetail('npc.tactical.scan');
        tacticalEntities = entities.GetNearbyTacticalNpcs(range);
        perfMeter.EndDetail(tacticalScanTimer);

        if (canUseScanCache == true) then
            scanCache.tacticalClock = now;
            scanCache.tacticalRange = range;
            scanCache.tacticalEntities = tacticalEntities;
        else
            scanCache.tacticalEntities = nil;
        end
    end

    local tacticalNpcIndexes = {};
    for _, entity in ipairs(tacticalEntities) do
        if (IsAlliedTacticalNpc(entity) == true) then
            tacticalNpcIndexes[tonumber(entity.index) or 0] = true;
            QueueTacticalNpc(entity);
        end
    end

    for _, entity in ipairs(entitiesList) do
        if (tacticalNpcIndexes[tonumber(entity.index) or 0] ~= true) then
            QueueNpcObject(entity);
        end
    end
end

return npcPlate;
