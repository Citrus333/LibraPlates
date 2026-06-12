local backgroundDefaults = require('config.widgets.background');
local nameDefaults = require('config.widgets.name');
local barDefaults = require('config.widgets.bar');
local mpBarDefaults = require('config.widgets.mp_bar');
local tpBarDefaults = require('config.widgets.tp_bar');
local buffsDefaults = require('config.widgets.buffs');
local debuffsDefaults = require('config.widgets.debuffs');
local aoeRangeDefaults = require('config.widgets.aoe_range');
local globalDefaults = require('config.global');
local fonts = require('core.fonts');
local textScale = require('core.text_scale');
local canvasTexture = require('core.canvas_texture');
local barTextures = require('core.bar_textures');
local barAnimations = require('core.bar_animations');
local backgroundTextures = require('core.background_textures');
local statusIconTextures = require('core.status_icon_textures');
local entities = require('core.entities');
local state = require('core.state');
local trustStatusIcons = require('core.trust_status_icons');
local targetModuleMarker = require('core.target_module_marker');
local targeting = require('core.targeting');
local enmity = require('core.enmity');
local worldDepthPlate = require('core.world_depth_plate');
local worldMarkerProbe = require('core.world_marker_probe');
local aoeNameHighlight = require('core.aoe_name_highlight');
local aoeRangeVisuals = require('core.aoe_range_visuals');
local perfMeter = require('core.perf_meter');

local trustPlate = {};
local plateCache = {};
local indexCache = {};
local maxPlateCacheEntries = 32;
local lastPlateCacheTrim = 0;
local trustBuffDefaults = {};
local nearbyScanCache = {
    clock = 0,
    range = nil,
    trusts = nil,
};
local nearbyTrustScanCacheSeconds = 0.20;

for key, value in pairs(buffsDefaults) do
    trustBuffDefaults[key] = value;
end

trustBuffDefaults.enabled = true;

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

local function NumberKey(value)
    local number = tonumber(value);

    if (number == nil) then
        return tostring(value);
    end

    return string.format('%.3f', number);
end

local function BuildTargetMarkerKey(marker)
    if (marker == nil or marker.enabled ~= true) then
        return 'target=off';
    end

    return table.concat({
        'target=on',
        'bg=' .. BoolKey(marker.showBackground == true),
        'arrow=' .. BoolKey(marker.showArrow == true),
        'chev=' .. BoolKey(marker.showChevrons == true),
        'arrowTex=' .. tostring(marker.arrowTextureId or ''),
        'chevTex=' .. tostring(marker.chevronTextureId or ''),
        'bgTex=' .. tostring(marker.backgroundTextureId or ''),
        'arrowW=' .. NumberKey(marker.arrowWidth),
        'arrowH=' .. NumberKey(marker.arrowHeight),
        'arrowX=' .. NumberKey(marker.arrowOffsetX),
        'arrowY=' .. NumberKey(marker.arrowOffsetY),
        'arrowSpacing=' .. NumberKey(marker.arrowSpacing),
        'chevW=' .. NumberKey(marker.chevronWidth),
        'chevH=' .. NumberKey(marker.chevronHeight),
        'chevX=' .. NumberKey(marker.chevronOffsetX),
        'chevY=' .. NumberKey(marker.chevronOffsetY),
        'chevSpacing=' .. NumberKey(marker.chevronSpacing),
        'bgW=' .. NumberKey(marker.backgroundWidth),
        'bgH=' .. NumberKey(marker.backgroundHeight),
        'bgX=' .. NumberKey(marker.backgroundOffsetX),
        'bgY=' .. NumberKey(marker.backgroundOffsetY),
        'anchorArrow=' .. BoolKey(marker.arrowAnchorToName == true),
        'anchorChev=' .. BoolKey(marker.chevronAnchorToPlate == true),
        'anchorBg=' .. BoolKey(marker.backgroundAnchorToPlate == true),
        'anchorChevKinds=' .. table.concat(marker.chevronAnchorKinds or {}, ','),
        'anchorBgKinds=' .. table.concat(marker.backgroundAnchorKinds or {}, ','),
        'color=' .. ColorKey(marker.color),
        'arrowColor=' .. ColorKey(marker.arrowColor),
        'chevColor=' .. ColorKey(marker.chevronColor),
        'bgColor=' .. ColorKey(marker.backgroundColor),
    }, ';');
end

local function ClampPercent(percent, fallback)
    percent = tonumber(percent) or fallback or 0;

    if (percent < 0) then
        return 0;
    end

    if (percent > 100) then
        return 100;
    end

    return percent;
end

local function ClampTp(value)
    local tp = tonumber(value) or 0;

    if (tp < 0) then
        return 0;
    end

    if (tp > 3000) then
        return 3000;
    end

    return tp;
end

local function ShortenName(name, maxLength)
    local text = tostring(name or '');
    local limit = tonumber(maxLength) or 0;

    if (limit > 0 and string.len(text) > limit) then
        return string.sub(text, 1, limit);
    end

    return text;
end

local function BuildResourceText(settings, label, value, maxValue, percent)
    local parts = {};

    if (settings.showValue == true and value ~= nil) then
        if (maxValue ~= nil and tonumber(maxValue) ~= nil and tonumber(maxValue) > 0) then
            local prefix = (label == 'TP') and '' or (label .. ' ');
            table.insert(parts, prefix .. tostring(value) .. '/' .. tostring(maxValue));
        else
            table.insert(parts, tostring(value));
        end
    end

    if (settings.showPercent == true) then
        table.insert(parts, tostring(math.floor(ClampPercent(percent, 100) + 0.5)) .. '%');
    end

    return table.concat(parts, ' ');
end

local function BuildStatusRowsKey(rows)
    if (rows == nil or #rows == 0) then
        return 'none';
    end

    local parts = {};

    for _, row in ipairs(rows) do
        parts[#parts + 1] = tostring(type(row) == 'table' and row.id or row);
    end

    return table.concat(parts, ',');
end

local function AddStatusIconsToPlate(plateData, statusRows, iconSettings, isEngaged, globalSettings, kind)
    if (
        iconSettings == nil or
        iconSettings.enabled ~= true or
        (iconSettings.hideOutOfCombat == true and ((tostring(iconSettings.hideCombatMode or 'Out of combat') == 'Out of combat' and isEngaged ~= true) or (tostring(iconSettings.hideCombatMode or 'Out of combat') == 'In combat' and isEngaged == true))) or
        statusRows == nil or
        #statusRows == 0
    ) then
        return;
    end

    local maxIcons = math.max(1, math.min(64, tonumber(iconSettings.maxIcons) or 12));
    local iconsPerRow = math.max(1, math.min(24, tonumber(iconSettings.iconsPerRow) or 6));
    local iconSize = math.max(6, math.min(160, tonumber(iconSettings.iconSize) or 18));
    local spacing = math.max(0, math.min(24, tonumber(iconSettings.iconSpacing) or 2));
    local growLeft = tostring(iconSettings.growthDirection or 'Right') == 'Left';
    local anchored = tostring(iconSettings.anchorTo or 'Plate') ~= 'Plate';
    local rowHeight = iconSize + spacing;
    local baseX = tonumber(iconSettings.offsetX) or 0;
    local baseY = tonumber(iconSettings.offsetY) or 0;
    local total = math.min(maxIcons, #statusRows);

    plateData.icons = plateData.icons or {};

    for i = 1, total do
        local rowData = statusRows[i];
        local statusId = type(rowData) == 'table' and rowData.id or rowData;
        local textureId = statusIconTextures.GetTextureId(statusId, iconSettings.iconPack);

        if (textureId ~= nil) then
            local row = math.floor((i - 1) / iconsPerRow);
            local col = (i - 1) % iconsPerRow;
            local rowCount = math.min(iconsPerRow, total - (row * iconsPerRow));
            local rowWidth = (rowCount * iconSize) + ((rowCount - 1) * spacing);
            local iconOffsetX = baseX - (rowWidth * 0.5) + (iconSize * 0.5) + (col * (iconSize + spacing));

            if (anchored == true) then
                iconOffsetX = baseX + ((growLeft == true and -iconSize or 0) + ((growLeft == true and -1 or 1) * col * (iconSize + spacing)));
            elseif (growLeft == true) then
                iconOffsetX = baseX + (rowWidth * 0.5) - (iconSize * 0.5) - (col * (iconSize + spacing));
            end

            plateData.icons[#plateData.icons + 1] = {
                kind = kind or 'status',
                textureId = textureId,
                size = iconSize,
                offsetX = iconOffsetX,
                offsetY = baseY + (row * rowHeight),
                anchorTo = iconSettings.anchorTo,
                anchorPoint = iconSettings.anchorPoint,
                timerText = nil,
                timerFontFamily = fonts.GetRole(globalSettings, iconSettings.timerUseSmallFont == true),
                timerFontFlags = fonts.GetRoleFlags(globalSettings, iconSettings.timerUseSmallFont == true),
                timerFontSize = textScale.ToTextureFontSize(iconSettings.timerFontSize, 8),
            };
        end
    end
end

local function GetLayoutStateName(trust, targetStateName)
    if (
        trust ~= nil and
        (trust.slot ~= nil or targetStateName ~= 'Idle') and
        tonumber(trust.status) == 1
    ) then
        return 'Combat';
    end

    return 'Idle';
end

local function QueueCachedTrust(trust, cached, targetStateName, layoutStateName, hpPercent, mpPercent, tpValue, useTargetOverlay)
    if (cached == nil or cached.texture == nil) then
        return false;
    end

    TouchPlateCacheEntry(cached);

    local plateTextureId = canvasTexture.GetTextureId(cached.texture);

    if (plateTextureId == nil) then
        return false;
    end

    local queueTimer = perfMeter.BeginDetail('trust.queue');
    local targetingSettings = targeting.GetSettings();

    worldMarkerProbe.QueuePlate({
        targetIndex = trust.index,
        serverId = trust.serverId,
        distance = trust.distance,
        hp = hpPercent,
        mp = mpPercent,
        tp = tpValue,
        name = '',
        isSelf = false,
        trustIsMine = trust.slot ~= nil,
        stateName = targetStateName,
        clickTargetType = 'trust',
        worldMarker = {
            hpBar = { enabled = false },
            plateTextureId = plateTextureId,
            plateAlwaysOnTop = useTargetOverlay == true,
            plateTacticalOverlayOnly = useTargetOverlay == true,
            plateWorldWidth = cached.plateWorldWidth,
            plateWorldHeight = cached.plateWorldHeight,
            plateWorldOffsetY = cached.plateWorldOffsetY,
            plateDistanceScaleStart = tonumber(targetingSettings.pcDistanceScaleStart) or 2.0,
            plateDistanceScaleEnd = tonumber(targetingSettings.pcDistanceScaleEnd) or 8.0,
            plateDistanceScaleMax = tonumber(targetingSettings.pcDistanceScaleMax) or 2.65,
            plateDistanceScaleOffsetY = 0.28,
            plateTextureWidth = cached.textureWidth,
            plateTextureHeight = cached.textureHeight,
            plateClickRects = cached.elementRects,
            clickTargetType = 'trust',
            clickName = trust.name,
            layoutStateName = layoutStateName,
        },
    });
    perfMeter.EndDetail(queueTimer);

    return true;
end

local function QueueTrust(trust)
    local targetStateName = targeting.GetTargetStateName(trust.index);
    local layoutStateName = GetLayoutStateName(trust, targetStateName);
    local useTargetOverlay = layoutStateName == 'Combat' or targetStateName ~= 'Idle';
    local settingsTimer = perfMeter.BeginDetail('trust.settings');
    local nameSettings = state.GetWidgetSettings('Trust', layoutStateName, 'Name', nameDefaults);
    local backgroundSettings = state.GetWidgetSettings('Trust', layoutStateName, 'Background', backgroundDefaults);
    local hpBarSettings = state.GetWidgetSettings('Trust', layoutStateName, 'HP Bar', barDefaults);
    local mpBarSettings = state.GetWidgetSettings('Trust', layoutStateName, 'MP Bar', mpBarDefaults);
    local tpBarSettings = state.GetWidgetSettings('Trust', layoutStateName, 'TP Bar', tpBarDefaults);
    local buffsSettings = state.GetWidgetSettings('Trust', layoutStateName, 'Buffs', trustBuffDefaults);
    local debuffsSettings = state.GetWidgetSettings('Trust', layoutStateName, 'Debuffs', debuffsDefaults);
    local aoeRangeSettings = state.GetWidgetSettings('Self', layoutStateName, 'AOE range', aoeRangeDefaults);
    local globalSettings = state.GetGlobalSettings(globalDefaults);
    local hpPercent = ClampPercent(trust.hpPercent, 100);
    local mpPercent = ClampPercent(trust.mpPercent, 100);
    local tpValue = tonumber(trust.tp) or 0;
    local tpPercent = ClampTp(tpValue) / 10;
    local hpColor = hpBarSettings.color or { 0.90, 0.20, 0.20, 1.0 };
    local mpColor = mpBarSettings.color or { 0.20, 0.45, 0.95, 1.0 };

    if (
        hpBarSettings.lowColorEnabled == true and
        hpPercent <= (tonumber(hpBarSettings.lowColorPercent) or 25)
    ) then
        hpColor = hpBarSettings.lowColor or hpColor;
    end

    local hpLowActive =
        hpBarSettings.lowColorEnabled == true and
        hpPercent <= (tonumber(hpBarSettings.lowColorPercent) or 25);

    if (
        mpBarSettings.lowColorEnabled == true and
        mpPercent <= (tonumber(mpBarSettings.lowColorPercent) or 25)
    ) then
        mpColor = mpBarSettings.lowColor or mpColor;
    end

    local mpLowActive =
        mpBarSettings.lowColorEnabled == true and
        mpPercent <= (tonumber(mpBarSettings.lowColorPercent) or 25);
    local targetMarker = targetModuleMarker.Build('Trust', layoutStateName, targetStateName, hpBarSettings, trust.distance);
    local enmityEnabled = enmity.ShouldDrawAlly(trust, globalSettings) == true;
    local buffRows = trustStatusIcons.GetRows(trust.serverId, 'buff');
    local debuffRows = trustStatusIcons.GetRows(trust.serverId, 'debuff');
    local cacheEligible = state.GetConfigOpen() ~= true;
    local cacheKey = nil;
    local signature = nil;

    if (cacheEligible == true) then
        cacheKey = 'trust:' .. tostring(trust.index);
        signature = table.concat({
            'v=1',
            'policy=' .. canvasTexture.GetRenderPolicyKey(),
            'name=' .. tostring(trust.name or ''),
            'layout=' .. tostring(layoutStateName or ''),
            'status=' .. tostring(trust.status or ''),
            'target=' .. tostring(targetStateName or ''),
            'hp=' .. tostring(hpPercent),
            'mp=' .. tostring(mpPercent),
            'tp=' .. tostring(tpValue),
            'enmity=' .. BoolKey(enmityEnabled),
            'aoe=' .. aoeNameHighlight.GetSignature(trust.index, 'trust'),
            'aoeSettings=' .. SettingKey(aoeRangeSettings, { 'enabled', 'fontSize', 'fontColor', 'iconEnabled', 'iconSize', 'highlightEnabled', 'backgroundFile', 'autoPlaceBackground', 'backgroundAutoPlaceAnchor', 'backgroundSpacing', 'backgroundWidth', 'backgroundHeight', 'backgroundOffsetX', 'backgroundOffsetY', 'backgroundColor' }),
            'bg:' .. SettingKey(backgroundSettings, { 'enabled', 'width', 'height', 'offsetX', 'offsetY', 'texture', 'color', 'borderColor', 'borderSize', 'anchorTo', 'anchorPoint' }),
            'name:' .. SettingKey(nameSettings, { 'enabled', 'shortenName', 'textSize', 'color', 'outlineSize', 'outlineColor', 'offsetX', 'offsetY', 'anchorTo', 'anchorPoint' }),
            'hp:' .. SettingKey(hpBarSettings, { 'enabled', 'width', 'height', 'offsetX', 'offsetY', 'color', 'backgroundColor', 'borderColor', 'borderSize', 'anchorTo', 'anchorPoint', 'texture', 'showValue', 'showPercent', 'fontSize', 'textColor', 'textOutlineEnabled', 'textOutlineColor', 'textOutlineSize', 'lowColorEnabled', 'lowColorPercent', 'lowColor', 'lowAnimationEnabled', 'lowAnimation', 'lowAnimationSpeed', 'lowAnimationColor' }),
            'mp:' .. SettingKey(mpBarSettings, { 'enabled', 'width', 'height', 'offsetX', 'offsetY', 'color', 'backgroundColor', 'borderColor', 'borderSize', 'anchorTo', 'anchorPoint', 'texture', 'showValue', 'showPercent', 'fontSize', 'textColor', 'textOutlineEnabled', 'textOutlineColor', 'textOutlineSize', 'lowColorEnabled', 'lowColorPercent', 'lowColor', 'lowAnimationEnabled', 'lowAnimation', 'lowAnimationSpeed', 'lowAnimationColor' }),
            'tp:' .. SettingKey(tpBarSettings, { 'enabled', 'width', 'height', 'offsetX', 'offsetY', 'color', 'color2', 'color3', 'backgroundColor', 'borderColor', 'borderSize', 'anchorTo', 'anchorPoint', 'texture', 'showValue', 'showPercent', 'fontSize', 'textColor', 'textOutlineEnabled', 'textOutlineColor', 'textOutlineSize', 'segmented', 'segmentGap' }),
            'buffs:' .. SettingKey(buffsSettings, { 'enabled', 'iconPack', 'iconSize', 'offsetX', 'offsetY', 'iconSpacing', 'iconsPerRow', 'maxIcons', 'hideOutOfCombat', 'hideCombatMode', 'anchorTo', 'anchorPoint', 'growthDirection' }) .. ':' .. BuildStatusRowsKey(buffRows),
            'debuffs:' .. SettingKey(debuffsSettings, { 'enabled', 'iconPack', 'iconSize', 'offsetX', 'offsetY', 'iconSpacing', 'iconsPerRow', 'maxIcons', 'hideOutOfCombat', 'hideCombatMode', 'anchorTo', 'anchorPoint', 'growthDirection' }) .. ':' .. BuildStatusRowsKey(debuffRows),
            'targetMarker:' .. BuildTargetMarkerKey(targetMarker),
        }, '\n');

        local indexed = indexCache[tonumber(trust.index) or 0];
        local cached = indexed ~= nil and indexed.signature == signature and plateCache[indexed.cacheKey] or nil;

        if (QueueCachedTrust(trust, cached, targetStateName, layoutStateName, hpPercent, mpPercent, tpValue, useTargetOverlay) == true) then
            perfMeter.Count('trust.cache.hit', 1);
            perfMeter.EndDetail(settingsTimer);
            return;
        end

        perfMeter.Count('trust.cache.miss', 1);
    end
    perfMeter.EndDetail(settingsTimer);

    local buildTimer = perfMeter.BeginDetail('trust.build');
    local nameAoeActive = aoeRangeSettings.enabled == true and aoeNameHighlight.IsHighlighted(trust.index, 'trust') == true;
    local nameTextSize = nameAoeActive == true and math.max(tonumber(nameSettings.textSize) or nameDefaults.textSize, tonumber(aoeRangeSettings.fontSize) or aoeRangeDefaults.fontSize) or nameSettings.textSize;
    local plateData = {
        hp = hpPercent,
        mp = mpPercent,
        tp = tpPercent,
        targetMarker = targetMarker,
        aoeNameActive = nameAoeActive == true,
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
        name = (nameSettings.enabled == true) and ShortenName(trust.name, nameSettings.shortenName) or '',
        nameFontFamily = fonts.GetRole(globalSettings, false),
        nameFontFlags = fonts.GetRoleFlags(globalSettings, false),
        nameFontSize = textScale.ToNameTextureFontSize(nameTextSize, nameDefaults.textSize),
        nameColor = (nameAoeActive == true and aoeRangeSettings.fontColor) or nameSettings.color or { 1.0, 1.0, 1.0, 1.0 },
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
            color = hpColor,
            backgroundColor = hpBarSettings.backgroundColor or { 0.05, 0.05, 0.05, 0.85 },
            borderColor = hpBarSettings.borderColor or { 0.0, 0.0, 0.0, 1.0 },
            borderSize = tonumber(hpBarSettings.borderSize) or 0,
            anchorTo = hpBarSettings.anchorTo or barDefaults.anchorTo,
            anchorPoint = hpBarSettings.anchorPoint or barDefaults.anchorPoint,
            texture = hpBarSettings.texture or 'Solid',
            textureId = barTextures.GetTextureId(hpBarSettings.texture),
            animationEnabled = hpLowActive == true and hpBarSettings.lowAnimationEnabled == true,
            animationTextureId = barAnimations.GetTextureId(hpBarSettings.lowAnimation),
            animationSpeed = tonumber(hpBarSettings.lowAnimationSpeed) or 40,
            animationColor = hpBarSettings.lowAnimationColor,
            showAtPercent = tonumber(hpBarSettings.showAtPercent) or 100,
            text = BuildResourceText(hpBarSettings, 'HP', trust.hp, trust.maxHp, hpPercent),
            textOffsetX = tonumber(hpBarSettings.textOffsetX) or 0,
            textOffsetY = tonumber(hpBarSettings.textOffsetY) or 0,
            fontFamily = fonts.GetRole(globalSettings, hpBarSettings.useSmallFont == true),
            fontFlags = fonts.GetRoleFlags(globalSettings, hpBarSettings.useSmallFont == true),
            fontSize = textScale.ToTextureFontSize(hpBarSettings.fontSize, barDefaults.fontSize),
            textColor = hpBarSettings.textColor or { 1.0, 1.0, 1.0, 1.0 },
            textOutlineEnabled = hpBarSettings.textOutlineEnabled == true,
            textOutlineColor = hpBarSettings.textOutlineColor or { 0.0, 0.0, 0.0, 1.0 },
            textOutlineSize = tonumber(hpBarSettings.textOutlineSize) or 1,
        },
        mpBar = {
            enabled = mpBarSettings.enabled == true,
            width = tonumber(mpBarSettings.width) or 180,
            height = tonumber(mpBarSettings.height) or 8,
            offsetX = tonumber(mpBarSettings.offsetX) or 0,
            offsetY = tonumber(mpBarSettings.offsetY) or 16,
            color = mpColor,
            backgroundColor = mpBarSettings.backgroundColor or { 0.05, 0.05, 0.05, 0.85 },
            borderColor = mpBarSettings.borderColor or { 0.0, 0.0, 0.0, 1.0 },
            borderSize = tonumber(mpBarSettings.borderSize) or 0,
            anchorTo = mpBarSettings.anchorTo or mpBarDefaults.anchorTo,
            anchorPoint = mpBarSettings.anchorPoint or mpBarDefaults.anchorPoint,
            texture = mpBarSettings.texture or 'Solid',
            textureId = barTextures.GetTextureId(mpBarSettings.texture),
            animationEnabled = mpLowActive == true and mpBarSettings.lowAnimationEnabled == true,
            animationTextureId = barAnimations.GetTextureId(mpBarSettings.lowAnimation),
            animationSpeed = tonumber(mpBarSettings.lowAnimationSpeed) or 40,
            animationColor = mpBarSettings.lowAnimationColor,
            showAtPercent = tonumber(mpBarSettings.showAtPercent) or 100,
            text = BuildResourceText(mpBarSettings, 'MP', trust.mp, trust.maxMp, mpPercent),
            textOffsetX = tonumber(mpBarSettings.textOffsetX) or 0,
            textOffsetY = tonumber(mpBarSettings.textOffsetY) or 0,
            fontFamily = fonts.GetRole(globalSettings, mpBarSettings.useSmallFont == true),
            fontFlags = fonts.GetRoleFlags(globalSettings, mpBarSettings.useSmallFont == true),
            fontSize = textScale.ToTextureFontSize(mpBarSettings.fontSize, mpBarDefaults.fontSize),
            textColor = mpBarSettings.textColor or { 1.0, 1.0, 1.0, 1.0 },
            textOutlineEnabled = mpBarSettings.textOutlineEnabled == true,
            textOutlineColor = mpBarSettings.textOutlineColor or { 0.0, 0.0, 0.0, 1.0 },
            textOutlineSize = tonumber(mpBarSettings.textOutlineSize) or 1,
        },
        tpBar = {
            enabled = tpBarSettings.enabled == true,
            width = tonumber(tpBarSettings.width) or 180,
            height = tonumber(tpBarSettings.height) or 6,
            offsetX = tonumber(tpBarSettings.offsetX) or 0,
            offsetY = tonumber(tpBarSettings.offsetY) or 28,
            color = tpBarSettings.color or { 0.95, 0.55, 0.05, 1.0 },
            backgroundColor = tpBarSettings.backgroundColor or { 0.05, 0.05, 0.05, 0.85 },
            borderColor = tpBarSettings.borderColor or { 0.0, 0.0, 0.0, 1.0 },
            borderSize = tonumber(tpBarSettings.borderSize) or 0,
            anchorTo = tpBarSettings.anchorTo or tpBarDefaults.anchorTo,
            anchorPoint = tpBarSettings.anchorPoint or tpBarDefaults.anchorPoint,
            texture = tpBarSettings.texture or 'Solid',
            textureId = barTextures.GetTextureId(tpBarSettings.texture),
            color2 = tpBarSettings.color2 or tpBarDefaults.color2,
            color3 = tpBarSettings.color3 or tpBarDefaults.color3,
            showAtPercent = tonumber(tpBarSettings.showAtPercent) or 100,
            segmented = tpBarSettings.segmented ~= false,
            segmentGap = tonumber(tpBarSettings.segmentGap) or 3,
            text = BuildResourceText(tpBarSettings, 'TP', tpValue, 3000, tpPercent),
            textOffsetX = tonumber(tpBarSettings.textOffsetX) or 0,
            textOffsetY = tonumber(tpBarSettings.textOffsetY) or 0,
            fontFamily = fonts.GetRole(globalSettings, tpBarSettings.useSmallFont == true),
            fontFlags = fonts.GetRoleFlags(globalSettings, tpBarSettings.useSmallFont == true),
            fontSize = textScale.ToTextureFontSize(tpBarSettings.fontSize, tpBarDefaults.fontSize),
            textColor = tpBarSettings.textColor or { 1.0, 1.0, 1.0, 1.0 },
            textOutlineEnabled = tpBarSettings.textOutlineEnabled == true,
            textOutlineColor = tpBarSettings.textOutlineColor or { 0.0, 0.0, 0.0, 1.0 },
            textOutlineSize = tonumber(tpBarSettings.textOutlineSize) or 1,
        },
    };

    if (enmityEnabled == true) then
        enmity.AddIcon(plateData, globalSettings.enmity);
    end

    AddStatusIconsToPlate(plateData, buffRows, buffsSettings, layoutStateName == 'Combat', globalSettings, 'buffs');
    AddStatusIconsToPlate(plateData, debuffRows, debuffsSettings, layoutStateName == 'Combat', globalSettings, 'debuffs');
    if (plateData.aoeNameActive == true) then
        aoeRangeVisuals.Apply(plateData, aoeRangeSettings, hpBarSettings);
    end
    perfMeter.EndDetail(buildTimer);

    local canvasTimer = perfMeter.BeginDetail('trust.canvas');
    local textureKey = 'trust-' .. tostring(trust.index) .. (plateData.canvasWidth ~= nil and '-aoe' or '');
    local plateTexture, textureWidth, textureHeight = canvasTexture.Render(plateData, textureKey);
    local plateTextureId = canvasTexture.GetTextureId(plateTexture);
    perfMeter.EndDetail(canvasTimer);

    if (plateTextureId == nil) then
        indexCache[tonumber(trust.index) or 0] = nil;
        return;
    end

    local plateClickRects = plateData._elementRects or canvasTexture.GetElementRects(plateData);

    if (cacheEligible == true and cacheKey ~= nil and signature ~= nil) then
        plateCache[cacheKey] = {
            signature = signature,
            texture = plateTexture,
            textureKey = textureKey,
            lastUsed = os.clock(),
            textureWidth = textureWidth,
            textureHeight = textureHeight,
            elementRects = plateClickRects,
            plateWorldWidth = 2.35,
            plateWorldHeight = 1.18,
            plateWorldOffsetY = 0.50,
        };
        indexCache[tonumber(trust.index) or 0] = {
            cacheKey = cacheKey,
            signature = signature,
        };
    end

    local queueTimer = perfMeter.BeginDetail('trust.queue');
    local targetingSettings = targeting.GetSettings();
    worldMarkerProbe.QueuePlate({
        targetIndex = trust.index,
        serverId = trust.serverId,
        distance = trust.distance,
        hp = hpPercent,
        mp = mpPercent,
        tp = tpValue,
        name = '',
        isSelf = false,
        trustIsMine = trust.slot ~= nil,
        stateName = targetStateName,
        clickTargetType = 'trust',
        worldMarker = {
            hpBar = { enabled = false },
            plateTextureId = plateTextureId,
            plateAlwaysOnTop = useTargetOverlay == true,
            plateTacticalOverlayOnly = useTargetOverlay == true,
            plateWorldWidth = 2.35,
            plateWorldHeight = 1.18,
            plateWorldOffsetY = 0.50,
            plateDistanceScaleStart = tonumber(targetingSettings.pcDistanceScaleStart) or 2.0,
            plateDistanceScaleEnd = tonumber(targetingSettings.pcDistanceScaleEnd) or 8.0,
            plateDistanceScaleMax = tonumber(targetingSettings.pcDistanceScaleMax) or 2.65,
            plateDistanceScaleOffsetY = 0.28,
            plateTextureWidth = textureWidth,
            plateTextureHeight = textureHeight,
            plateClickRects = plateClickRects,
            clickTargetType = 'trust',
            clickName = trust.name,
            layoutStateName = layoutStateName,
        },
    });
    perfMeter.EndDetail(queueTimer);
end

function trustPlate.Build()
    return nil;
end

function trustPlate.Render()
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

    local targetingSettings = targeting.GetSettings();
    local range = tonumber(targetingSettings.enemyPlateRange) or 49.9;
    local now = os.clock();
    local nearbyTrusts = nil;
    local scanTimer = perfMeter.BeginDetail('trust.scan');
    local trusts = entities.GetPartyTrusts(range);

    if (
        nearbyScanCache.trusts ~= nil and
        nearbyScanCache.range == range and
        (now - (tonumber(nearbyScanCache.clock) or 0)) < nearbyTrustScanCacheSeconds
    ) then
        nearbyTrusts = nearbyScanCache.trusts;
    else
        nearbyTrusts = entities.GetNearbyTrusts(range);
        nearbyScanCache.clock = now;
        nearbyScanCache.range = range;
        nearbyScanCache.trusts = nearbyTrusts;
    end

    perfMeter.EndDetail(scanTimer);
    local queued = {};

    for _, trust in ipairs(trusts) do
        queued[tonumber(trust.index) or 0] = true;
        QueueTrust(trust);
    end

    for _, trust in ipairs(nearbyTrusts) do
        if (queued[tonumber(trust.index) or 0] ~= true) then
            queued[tonumber(trust.index) or 0] = true;
            QueueTrust(trust);
        end
    end
end

return trustPlate;
