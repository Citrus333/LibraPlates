local imgui = require('imgui');
local canvasDefaults = require('config.canvas');
local backgroundDefaults = require('config.widgets.background');
local nameDefaults = require('config.widgets.name');
local aoeRangeDefaults = require('config.widgets.aoe_range');
local buffsDefaults = require('config.widgets.buffs');
local debuffsDefaults = require('config.widgets.debuffs');
local gameModeIconDefaults = require('config.widgets.game_mode_icon');
local bazaarIconDefaults = require('config.widgets.bazaar_icon');
local linkshellIconDefaults = require('config.widgets.linkshell_icon');
local awayIconDefaults = require('config.widgets.away_icon');
local disconnectIconDefaults = require('config.widgets.disconnect_icon');
local partyLeaderIconDefaults = require('config.widgets.party_leader_icon');
local allianceLeaderIconDefaults = require('config.widgets.alliance_leader_icon');
local starsIconDefaults = require('config.widgets.stars_icon');
local newAdventurerIconDefaults = require('config.widgets.new_adventurer_icon');
local barDefaults = require('config.widgets.bar');
local mpBarDefaults = require('config.widgets.mp_bar');
local tpBarDefaults = require('config.widgets.tp_bar');
local castBarDefaults = require('config.widgets.cast_bar');
local globalDefaults = require('config.global');
local perfMeter = require('core.perf_meter');
local fonts = require('core.fonts');
local textScale = require('core.text_scale');
local canvas = require('core.canvas');
local canvasTexture = require('core.canvas_texture');
local adaptivePerformance = require('core.adaptive_performance');
local aoeNameHighlight = require('core.aoe_name_highlight');
local aoeRangeVisuals = require('core.aoe_range_visuals');
local backgroundTextures = require('core.background_textures');
local gathering = require('core.gathering');
local barTextures = require('core.bar_textures');
local barAnimations = require('core.bar_animations');
local entities = require('core.entities');
local gameMode = require('core.game_mode');
local playerIndicators = require('core.player_indicators');
local playerStatuses = require('core.player_statuses');
local state = require('core.state');
local statusIconTextures = require('core.status_icon_textures');
local spellIconTextures = require('core.spell_icon_textures');
local statusTimerFormat = require('core.status_timer_format');
local targetModuleMarker = require('core.target_module_marker');
local targeting = require('core.targeting');
local nativeUiPolicy = require('core.native_ui_policy');
local enmity = require('core.enmity');
local restingTick = require('core.resting_tick');
local fishing = require('core.fishing');
local crafting = require('core.crafting');
local enemyCasts = require('core.enemy_casts');
local worldDepthPlate = require('core.world_depth_plate');
local worldMarkerProbe = require('core.world_marker_probe');
local widgets = require('modules.widgets.init');

local selfPlate = {};
local mountedPlateLift = 1.05;
local lagTestSuppressed = false;
local cachedWorldPlate = nil;
local cachedWorldTextureKey = 'self-world';

local function ScalarKey(value)
    local valueType = type(value);

    if (valueType == 'boolean') then
        return value == true and '1' or '0';
    end

    if (valueType == 'number') then
        return string.format('%.3f', value);
    end

    return tostring(value);
end

local function StableTableKey(value, depth)
    depth = tonumber(depth) or 0;

    if (type(value) ~= 'table') then
        return ScalarKey(value);
    end

    if (depth > 7) then
        return '<depth>';
    end

    local keys = {};

    for key, _ in pairs(value) do
        if (
            key ~= '_elementRects' and
            key ~= 'anchorRect' and
            key ~= 'arrowAnchorRect'
        ) then
            keys[#keys + 1] = key;
        end
    end

    table.sort(keys, function(left, right)
        return tostring(left) < tostring(right);
    end);

    local parts = {};

    for _, key in ipairs(keys) do
        parts[#parts + 1] = tostring(key) .. '=' .. StableTableKey(value[key], depth + 1);
    end

    return '{' .. table.concat(parts, ';') .. '}';
end

local function BuildWorldCacheSignature(plateData, center, stateName, targetStateName, layoutStateName)
    return table.concat({
        'v=1',
        'index=' .. tostring(center ~= nil and center.index or ''),
        'server=' .. tostring(center ~= nil and center.serverId or ''),
        'status=' .. tostring(center ~= nil and center.status or ''),
        'state=' .. tostring(stateName or ''),
        'target=' .. tostring(targetStateName or ''),
        'layout=' .. tostring(layoutStateName or ''),
        'aoe=' .. aoeNameHighlight.GetSignature(center ~= nil and center.index or 0, 'self'),
        'policy=' .. canvasTexture.GetRenderPolicyKey(),
        'debug=' .. tostring(worldMarkerProbe.GetClickDebug() == true),
        'plate=' .. StableTableKey(plateData),
    }, '\n');
end

local function BuildWorldVitalSignature(center, hpPercent, mpPercent, tpValue, castPercent, castText, stateName, targetStateName, layoutStateName, nameStyleKey, gatheringSignature)
    return table.concat({
        'index=' .. tostring(center ~= nil and center.index or ''),
        'server=' .. tostring(center ~= nil and center.serverId or ''),
        'status=' .. tostring(center ~= nil and center.status or ''),
        'hp=' .. tostring(hpPercent or ''),
        'mp=' .. tostring(mpPercent or ''),
        'tp=' .. tostring(tpValue or ''),
        'cast=' .. tostring(castPercent or ''),
        'castText=' .. tostring(castText or ''),
        'state=' .. tostring(stateName or ''),
        'target=' .. tostring(targetStateName or ''),
        'layout=' .. tostring(layoutStateName or ''),
        'nameStyle=' .. tostring(nameStyleKey or ''),
        'gathering=' .. tostring(gatheringSignature or 'none'),
    }, '\n');
end

local function QueueRenderedWorldPlate(center, hpPercent, targetStateName, layoutStateName, plateTextureId, textureWidth, textureHeight, plateClickRects)
    local targetingSettings = targeting.GetSettings();

    worldMarkerProbe.QueuePlate({
        targetIndex = center.index,
        serverId = center.serverId,
        distance = center.distance,
        hp = hpPercent,
        name = '',
        jobText = '',
        jobIconTextureId = nil,
        isSelf = true,
        stateName = targetStateName,
        clickTargetType = 'self',
        worldMarker = targeting.ApplyPlateScalingSettings({
            hpBar = { enabled = false },
            plateTextureId = plateTextureId,
            plateAlwaysOnTop = true,
            plateTacticalOverlayOnly = true,
            plateWorldWidth = 2.35,
            plateWorldHeight = 1.18,
            plateWorldOffsetY = (tonumber(center.status) == 85) and (0.72 - mountedPlateLift) or 0.72,
            plateDistanceScaleOffsetY = -0.12,
            plateTextureWidth = textureWidth,
            plateTextureHeight = textureHeight,
            plateClickRects = plateClickRects,
            jobEnabled = false,
            selfBarModelDepthLift = 0.18,
            clickTargetType = 'self',
            clickName = center.name,
            layoutStateName = layoutStateName,
        }, 'self', 0, (tonumber(center.status) == 85) and (0.72 - mountedPlateLift) or 0.72),
    });
end

local function BuildAoeNameSettings(layoutStateName, nameSettings, targetIndex)
    local aoeRangeSettings = state.GetWidgetSettings('Self', layoutStateName, 'AOE range', aoeRangeDefaults);

    if (aoeRangeSettings.enabled ~= true or aoeNameHighlight.IsHighlighted(targetIndex, 'self') ~= true) then
        return nameSettings;
    end

    local merged = {};

    for key, value in pairs(nameSettings or {}) do
        merged[key] = value;
    end

    merged.textSize = tonumber(aoeRangeSettings.fontSize) or aoeRangeDefaults.fontSize;
    return merged;
end

local function BuildPlayerIndicatorAnchorFallbackRects(definitions)
    local fallbacks = {};

    for _, definition in ipairs(definitions or {}) do
        local settings = definition.settings or {};
        local defaults = definition.defaults or {};
        local size = math.max(6, math.min(160, tonumber(settings.iconSize) or tonumber(defaults.iconSize) or 16));
        local offsetX = tonumber(settings.offsetX) or tonumber(definition.defaultX) or tonumber(defaults.offsetX) or 0;
        local offsetY = tonumber(settings.offsetY) or tonumber(definition.defaultY) or tonumber(defaults.offsetY) or 0;

        fallbacks[#fallbacks + 1] = {
            kind = definition.kind,
            x = 512 - (size * 0.5) + offsetX,
            y = 256 - (size * 0.5) + offsetY,
            w = size,
            h = size,
            padding = 4,
            layout = {
                anchorTo = settings.anchorTo or defaults.anchorTo,
                anchorPoint = settings.anchorPoint or defaults.anchorPoint,
                offsetX = offsetX,
                offsetY = offsetY,
            },
        };
    end

    return fallbacks;
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

    if (iconSettings.showTimers == true) then
        rowHeight = iconSize + math.max(spacing, (tonumber(iconSettings.timerFontSize) or 8) + math.max(0, tonumber(iconSettings.timerOffsetY) or 0) + 2);
    end

    local baseX = tonumber(iconSettings.offsetX) or 0;
    local baseY = tonumber(iconSettings.offsetY) or 0;
    local visibleRows = {};
    local hideAboveSeconds = nil;

    if (iconSettings.hideAboveDurationEnabled == true) then
        local minutes = tonumber(iconSettings.hideAboveDurationMinutes) or 0;
        if (minutes > 0) then hideAboveSeconds = minutes * 60; end
    end

    for _, rowData in ipairs(statusRows) do
        local timerSeconds = type(rowData) == 'table' and tonumber(rowData.seconds) or nil;
        if (hideAboveSeconds == nil or timerSeconds == nil or timerSeconds <= hideAboveSeconds) then
            visibleRows[#visibleRows + 1] = rowData;
        end
    end

    local total = math.min(maxIcons, #visibleRows);

    plateData.icons = plateData.icons or {};

    for i = 1, total do
        local rowData = visibleRows[i];
        local statusId = type(rowData) == 'table' and rowData.id or rowData;
        local textureId = statusIconTextures.GetTextureId(statusId, iconSettings.iconPack);

        if (textureId ~= nil) then
            local row = math.floor((i - 1) / iconsPerRow);
            local col = (i - 1) % iconsPerRow;
            local rowCount = math.min(iconsPerRow, total - (row * iconsPerRow));
            local rowWidth = (rowCount * iconSize) + ((rowCount - 1) * spacing);
            local iconOffsetX = baseX - (rowWidth * 0.5) + (iconSize * 0.5) + (col * (iconSize + spacing));
            local timerSeconds = type(rowData) == 'table' and tonumber(rowData.seconds) or nil;
            local timerText = nil;

            if (anchored == true) then
                iconOffsetX = baseX + ((growLeft == true and -iconSize or 0) + ((growLeft == true and -1 or 1) * col * (iconSize + spacing)));
            elseif (growLeft == true) then
                iconOffsetX = baseX + (rowWidth * 0.5) - (iconSize * 0.5) - (col * (iconSize + spacing));
            end

            if (iconSettings.showTimers == true and timerSeconds ~= nil) then
                timerText = statusTimerFormat.Format(timerSeconds);
            end

            plateData.icons[#plateData.icons + 1] = {
                kind = kind or 'status',
                textureId = textureId,
                size = iconSize,
                offsetX = iconOffsetX,
                offsetY = baseY + (row * rowHeight),
                anchorTo = iconSettings.anchorTo,
                anchorPoint = iconSettings.anchorPoint,
                timerText = timerText,
                timerSeconds = timerSeconds,
                timerOffsetY = tonumber(iconSettings.timerOffsetY) or 0,
                timerFontFamily = fonts.GetRole(globalSettings, iconSettings.timerUseSmallFont == true),
                timerFontFlags = fonts.GetRoleFlags(globalSettings, iconSettings.timerUseSmallFont == true),
                timerFontSize = textScale.ToTextureFontSize(iconSettings.timerFontSize, 8),
                timerTextColor = iconSettings.timerTextColor,
                timerTextOutline = iconSettings.timerTextOutline,
                timerTextOutlineColor = iconSettings.timerTextOutlineColor,
                timerTextOutlineSize = tonumber(iconSettings.timerTextOutlineSize) or 1,
                timerBackground = iconSettings.timerBackground == true,
                timerBackgroundPaddingX = tonumber(iconSettings.timerBackgroundPaddingX) or 2,
                timerBackgroundPaddingY = tonumber(iconSettings.timerBackgroundPaddingY) or 1,
                timerBackgroundBorderSize = tonumber(iconSettings.timerBackgroundBorderSize) or 0,
                timerBackgroundBorderColor = iconSettings.timerBackgroundBorderColor,
                timerCornerRadius = tonumber(iconSettings.timerCornerRadius) or 0,
                timerWarningEnabled = iconSettings.timerWarningEnabled == true,
                timerWarningStage1Seconds = tonumber(iconSettings.timerWarningStage1Seconds) or 10,
                timerWarningStage2Seconds = tonumber(iconSettings.timerWarningStage2Seconds) or 8,
                timerWarningStage3Seconds = tonumber(iconSettings.timerWarningStage3Seconds) or 5,
                timerWarningStage1Color = iconSettings.timerWarningStage1Color,
                timerWarningStage2Color = iconSettings.timerWarningStage2Color,
                timerWarningStage3Color = iconSettings.timerWarningStage3Color,
                timerWarningTextColorEnabled = iconSettings.timerWarningTextColorEnabled == true,
                timerWarningFontStage1Color = iconSettings.timerWarningFontStage1Color,
                timerWarningFontStage2Color = iconSettings.timerWarningFontStage2Color,
                timerWarningFontStage3Color = iconSettings.timerWarningFontStage3Color,
                timerWarningBoxColorEnabled = iconSettings.timerWarningBoxColorEnabled == true,
                timerWarningBoxStage1Color = iconSettings.timerWarningBoxStage1Color,
                timerWarningBoxStage2Color = iconSettings.timerWarningBoxStage2Color,
                timerWarningBoxStage3Color = iconSettings.timerWarningBoxStage3Color,
                timerWarningBackgroundEnabled = iconSettings.timerWarningBackgroundEnabled == true,
                timerWarningIconPadding = tonumber(iconSettings.iconWarningPadding) or 6,
                timerWarningIconBackgroundStage1Color = iconSettings.timerWarningIconBackgroundStage1Color,
                timerWarningIconBackgroundStage2Color = iconSettings.timerWarningIconBackgroundStage2Color,
                timerWarningIconBackgroundStage3Color = iconSettings.timerWarningIconBackgroundStage3Color,
                timerWarningBorderEnabled = iconSettings.timerWarningBorderEnabled == true,
                timerWarningIconBorderStage1Color = iconSettings.timerWarningIconBorderStage1Color,
                timerWarningIconBorderStage2Color = iconSettings.timerWarningIconBorderStage2Color,
                timerWarningIconBorderStage3Color = iconSettings.timerWarningIconBorderStage3Color,
                timerNormalSeconds = tonumber(iconSettings.timerNormalSeconds) or 60,
                timerSoonSeconds = tonumber(iconSettings.timerSoonSeconds) or 20,
                timerNormalBackgroundColor = iconSettings.timerNormalBackgroundColor,
                timerSoonBackgroundColor = iconSettings.timerSoonBackgroundColor,
                timerUrgentBackgroundColor = iconSettings.timerUrgentBackgroundColor,
            };
        end
    end
end

local function ShouldLoadStatusRows(iconSettings, isEngaged)
    if (iconSettings == nil or iconSettings.enabled ~= true) then
        return false;
    end

    if (iconSettings.hideOutOfCombat == true and ((tostring(iconSettings.hideCombatMode or 'Out of combat') == 'Out of combat' and isEngaged ~= true) or (tostring(iconSettings.hideCombatMode or 'Out of combat') == 'In combat' and isEngaged == true))) then
        return false;
    end

    return true;
end

local function GetLiveSelfStateName(center)
    if (crafting.IsActive() == true) then
        return 'Crafting';
    end

    if (center ~= nil and center.index ~= nil) then
        if (crafting.IsCraftingStatus(center.status) == true) then
            return 'Crafting';
        end

        if (fishing.IsFishingStatus(center.status) == true) then
            return 'Fishing';
        end

        if (tonumber(center.status) == 33) then
            return 'Resting';
        end

        if (tonumber(center.status) == 1) then
            return 'Combat';
        end

        local ent = GetEntity(center.index);

        if (ent ~= nil and crafting.IsCraftingStatus(ent.Status) == true) then
            return 'Crafting';
        end

        if (ent ~= nil and fishing.IsFishingStatus(ent.Status) == true) then
            return 'Fishing';
        end

        if (ent ~= nil and ent.Status == 33) then
            return 'Resting';
        end

        if (ent ~= nil and ent.Status == 1) then
            return 'Combat';
        end
    end

    return 'Idle';
end

local function GetLayoutStateName(stateName)
    return stateName;
end

local function ClampColorChannel(value)
    local channel = tonumber(value) or 0;

    if (channel < 0) then
        return 0;
    end

    if (channel > 1) then
        return 1;
    end

    return channel;
end

local function ColorToU32(color)
    local value = color or { 1.0, 1.0, 1.0, 1.0 };
    local red = math.floor(ClampColorChannel(value[1]) * 255);
    local green = math.floor(ClampColorChannel(value[2]) * 255);
    local blue = math.floor(ClampColorChannel(value[3]) * 255);
    local alpha = math.floor(ClampColorChannel(value[4] or 1.0) * 255);

    return (alpha * 0x1000000) + (red * 0x10000) + (green * 0x100) + blue;
end

local function ClampPercent(value, fallback)
    local percent = tonumber(value) or fallback or 100;

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

local function BuildCastBar(castData, castBarSettings, globalSettings)
    if (castData == nil or castBarSettings == nil or castBarSettings.enabled ~= true) then
        return nil, 0;
    end

    local castTime = math.max(0.1, tonumber(castData.castTime) or 0.1);
    local elapsed = math.max(0.0, os.clock() - (tonumber(castData.startTime) or os.clock()));
    local castPercent = math.max(0, math.min(100, (elapsed / castTime) * 100));
    local spellIconId = tonumber(castData.spellIconId);
    local spellIconTextureId = castBarSettings.showSpellIcon == true
        and spellIconTextures.GetTextureId(spellIconId)
        or nil;

    return {
        enabled = true,
        width = tonumber(castBarSettings.width) or castBarDefaults.width,
        height = tonumber(castBarSettings.height) or castBarDefaults.height,
        offsetX = tonumber(castBarSettings.offsetX) or castBarDefaults.offsetX,
        offsetY = tonumber(castBarSettings.offsetY) or castBarDefaults.offsetY,
        anchorTo = castBarSettings.anchorTo or castBarDefaults.anchorTo,
        anchorPoint = castBarSettings.anchorPoint or castBarDefaults.anchorPoint,
        color = castBarSettings.color or castBarDefaults.color,
        backgroundColor = castBarSettings.backgroundColor or castBarDefaults.backgroundColor,
        borderColor = castBarSettings.borderColor or castBarDefaults.borderColor,
        borderSize = tonumber(castBarSettings.borderSize) or castBarDefaults.borderSize,
        texture = castBarSettings.texture or castBarDefaults.texture,
        textureId = barTextures.GetTextureId(castBarSettings.texture or castBarDefaults.texture),
        text = (castBarSettings.showSpellName ~= false) and tostring(castData.spellName or '') or '',
        textOffsetX = tonumber(castBarSettings.textOffsetX) or castBarDefaults.textOffsetX,
        textOffsetY = tonumber(castBarSettings.textOffsetY) or castBarDefaults.textOffsetY,
        fontFamily = fonts.GetRole(globalSettings, castBarSettings.useSmallFont == true),
        fontFlags = fonts.GetRoleFlags(globalSettings, castBarSettings.useSmallFont == true),
        fontSize = textScale.ToTextureFontSize(castBarSettings.fontSize, castBarDefaults.fontSize),
        textColor = castBarSettings.textColor or castBarDefaults.textColor,
        textOutlineEnabled = castBarSettings.textOutlineEnabled == true,
        textOutlineColor = castBarSettings.textOutlineColor or castBarDefaults.textOutlineColor,
        textOutlineSize = tonumber(castBarSettings.textOutlineSize) or castBarDefaults.textOutlineSize,
        separateLabelOffsets = true,
        iconTextureId = spellIconTextureId,
        iconSize = tonumber(castBarSettings.spellIconSize) or castBarDefaults.spellIconSize,
        iconOffsetX = tonumber(castBarSettings.spellIconOffsetX) or castBarDefaults.spellIconOffsetX,
        iconOffsetY = tonumber(castBarSettings.spellIconOffsetY) or castBarDefaults.spellIconOffsetY,
        iconGap = 4,
    }, castPercent;
end

local function DrawBackground(drawList, bounds)
    local background = canvasDefaults.background;

    if (background == nil or background.enabled ~= true) then
        return;
    end

    local rect = canvas.GetLocalRect(bounds, background);

    if (background.textureId ~= nil) then
        local textureAlpha = tonumber(background.color ~= nil and background.color[4] or nil) or 0.45;
        drawList:AddImage(background.textureId, { rect.left, rect.top }, { rect.left + rect.width, rect.top + rect.height }, { 0, 0 }, { 1, 1 }, ColorToU32({ 1.0, 1.0, 1.0, textureAlpha }));
    else
        drawList:AddRectFilled(
            { rect.left, rect.top },
            { rect.left + rect.width, rect.top + rect.height },
            ColorToU32(background.color)
        );
    end

    drawList:AddRect(
        { rect.left, rect.top },
        { rect.left + rect.width, rect.top + rect.height },
        ColorToU32(background.borderColor)
    );
end

local function QueueWorldMarker(center, nameSettings, stateName)
    local targetStateName = targeting.GetTargetStateName(center.index);
    local layoutStateName = GetLayoutStateName(stateName);
    nameSettings = state.GetWidgetSettings('Self', layoutStateName, 'Name', nameDefaults);
    local gameModeIconSettings = state.GetWidgetSettings('Self', layoutStateName, 'Game mode icon', gameModeIconDefaults);
    local partyLeaderIconSettings = state.GetWidgetSettings('Self', layoutStateName, 'Party leader icon', partyLeaderIconDefaults);
    local allianceLeaderIconSettings = state.GetWidgetSettings('Self', layoutStateName, 'Alliance leader icon', allianceLeaderIconDefaults);
    local bazaarIconSettings = state.GetWidgetSettings('Self', layoutStateName, 'Bazaar icon', bazaarIconDefaults);
    local linkshellIconSettings = state.GetWidgetSettings('Self', layoutStateName, 'Linkshell icon', linkshellIconDefaults);
    local awayIconSettings = state.GetWidgetSettings('Self', layoutStateName, 'Away icon', awayIconDefaults);
    local disconnectIconSettings = state.GetWidgetSettings('Self', layoutStateName, 'Disconnect icon', disconnectIconDefaults);
    local starsIconSettings = state.GetWidgetSettings('Self', layoutStateName, 'Stars icon', starsIconDefaults);
    local newAdventurerIconSettings = state.GetWidgetSettings('Self', layoutStateName, 'New adventurer icon', newAdventurerIconDefaults);
    local backgroundSettings = state.GetWidgetSettings('Self', layoutStateName, 'Background', backgroundDefaults);
    local hpBarSettings = state.GetWidgetSettings('Self', layoutStateName, 'HP Bar', barDefaults);
    local mpBarSettings = state.GetWidgetSettings('Self', layoutStateName, 'MP Bar', mpBarDefaults);
    local tpBarSettings = state.GetWidgetSettings('Self', layoutStateName, 'TP Bar', tpBarDefaults);
    local castData = enemyCasts.GetActiveCast(center.serverId);
    local castBarSettings = state.GetWidgetSettings('Self', layoutStateName, 'Cast bar', castBarDefaults);
    local aoeRangeSettings = state.GetWidgetSettings('Self', layoutStateName, 'AOE range', aoeRangeDefaults);
    local buffsSettings = state.GetWidgetSettings('Self', layoutStateName, 'Buffs', buffsDefaults);
    local debuffsSettings = state.GetWidgetSettings('Self', layoutStateName, 'Debuffs', debuffsDefaults);
    local globalSettings = state.GetGlobalSettings(globalDefaults);
    local restingSettings = globalSettings.resting or {};
    local hpPercent = ClampPercent(center.hpPercent, 100);
    local mpPercent = ClampPercent(center.mpPercent, 100);
    local tpValue = math.max(0, math.min(3000, tonumber(center.tp) or 0));
    local tpPercent = ClampTp(tpValue) / 10;
    local hpColor = hpBarSettings.color or { 0.90, 0.20, 0.20, 1.0 };
    local mpColor = mpBarSettings.color or { 0.25, 0.45, 1.0, 0.95 };
    local tpColor = tpBarSettings.color or { 1.0, 0.70, 0.18, 0.95 };
    local useTacticalOverlay = layoutStateName == 'Combat';

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

    if (
        tpBarSettings.lowColorEnabled == true and
        tpPercent <= (tonumber(tpBarSettings.lowColorPercent) or 25)
    ) then
        tpColor = tpBarSettings.lowColor or tpColor;
    end
    local nameEnabled = (nameSettings.enabled == true);
    local defaultOffsetY = tonumber(nameDefaults.offsetY) or 0;
    local modeText = (gameModeIconSettings.enabled == true) and gameMode.Resolve(center.index, false) or '';
    local modeIconTextureId = gameMode.GetIconTextureId(modeText);
    local icons = {};

    local allianceLeaderTextureId = playerIndicators.GetAllianceLeaderIconTextureId(center.index);

    if (allianceLeaderIconSettings.enabled == true and allianceLeaderTextureId ~= nil) then
        table.insert(icons, {
            kind = 'allianceLeaderIcon',
            textureId = allianceLeaderTextureId,
            size = tonumber(allianceLeaderIconSettings.iconSize) or 16,
            offsetX = tonumber(allianceLeaderIconSettings.offsetX) or -120,
            offsetY = tonumber(allianceLeaderIconSettings.offsetY) or -54,
            anchorTo = allianceLeaderIconSettings.anchorTo,
            anchorPoint = allianceLeaderIconSettings.anchorPoint,
        });
    end

    local partyLeaderTextureId = playerIndicators.GetPartyLeaderIconTextureId(center.index);

    if (partyLeaderIconSettings.enabled == true and partyLeaderTextureId ~= nil) then
        table.insert(icons, {
            kind = 'partyLeaderIcon',
            textureId = partyLeaderTextureId,
            size = tonumber(partyLeaderIconSettings.iconSize) or 16,
            offsetX = tonumber(partyLeaderIconSettings.offsetX) or -96,
            offsetY = tonumber(partyLeaderIconSettings.offsetY) or -54,
            anchorTo = partyLeaderIconSettings.anchorTo,
            anchorPoint = partyLeaderIconSettings.anchorPoint,
        });
    end

    if (gameModeIconSettings.enabled == true and modeIconTextureId ~= nil) then
        table.insert(icons, {
            kind = 'gameModeIcon',
            textureId = modeIconTextureId,
            size = tonumber(gameModeIconSettings.iconSize) or 16,
            offsetX = tonumber(gameModeIconSettings.offsetX) or -72,
            offsetY = tonumber(gameModeIconSettings.offsetY) or -54,
            anchorTo = gameModeIconSettings.anchorTo,
            anchorPoint = gameModeIconSettings.anchorPoint,
        });
    end

    local linkshellTextureId = playerIndicators.GetLinkshellIconTextureId(center.index);
    local linkshellTint = playerIndicators.GetLinkshellIconTint(center.index);

    if (linkshellIconSettings.enabled == true and linkshellTextureId ~= nil) then
        table.insert(icons, {
            kind = 'linkshellIcon',
            textureId = linkshellTextureId,
            size = tonumber(linkshellIconSettings.iconSize) or 16,
            offsetX = tonumber(linkshellIconSettings.offsetX) or 48,
            offsetY = tonumber(linkshellIconSettings.offsetY) or -54,
            anchorTo = linkshellIconSettings.anchorTo,
            anchorPoint = linkshellIconSettings.anchorPoint,
            tint = linkshellTint,
        });
    end

    local bazaarTextureId = playerIndicators.GetBazaarIconTextureId(center.index);

    if (bazaarIconSettings.enabled == true and bazaarTextureId ~= nil) then
        table.insert(icons, {
            kind = 'bazaarIcon',
            textureId = bazaarTextureId,
            size = tonumber(bazaarIconSettings.iconSize) or 16,
            offsetX = tonumber(bazaarIconSettings.offsetX) or 72,
            offsetY = tonumber(bazaarIconSettings.offsetY) or -54,
            anchorTo = bazaarIconSettings.anchorTo,
            anchorPoint = bazaarIconSettings.anchorPoint,
        });
    end

    local awayTextureId = playerIndicators.GetAwayIconTextureId(center.index);

    if (awayIconSettings.enabled == true and awayTextureId ~= nil) then
        table.insert(icons, {
            kind = 'awayIcon',
            textureId = awayTextureId,
            size = tonumber(awayIconSettings.iconSize) or 16,
            offsetX = tonumber(awayIconSettings.offsetX) or 120,
            offsetY = tonumber(awayIconSettings.offsetY) or -54,
            anchorTo = awayIconSettings.anchorTo,
            anchorPoint = awayIconSettings.anchorPoint,
        });
    end

    local disconnectTextureId = playerIndicators.GetDisconnectIconTextureId(center.index);

    if (disconnectIconSettings.enabled == true and disconnectTextureId ~= nil) then
        table.insert(icons, {
            kind = 'disconnectIcon',
            textureId = disconnectTextureId,
            size = tonumber(disconnectIconSettings.iconSize) or 16,
            offsetX = tonumber(disconnectIconSettings.offsetX) or 144,
            offsetY = tonumber(disconnectIconSettings.offsetY) or -54,
            anchorTo = disconnectIconSettings.anchorTo,
            anchorPoint = disconnectIconSettings.anchorPoint,
        });
    end

    local starsTextureId = playerIndicators.GetStarsIconTextureId(center.index);

    if (starsIconSettings.enabled == true and starsTextureId ~= nil) then
        table.insert(icons, {
            kind = 'starsIcon',
            textureId = starsTextureId,
            size = tonumber(starsIconSettings.iconSize) or 16,
            offsetX = tonumber(starsIconSettings.offsetX) or -48,
            offsetY = tonumber(starsIconSettings.offsetY) or -54,
            anchorTo = starsIconSettings.anchorTo,
            anchorPoint = starsIconSettings.anchorPoint,
        });
    end

    local newAdventurerTextureId = playerIndicators.GetNewAdventurerIconTextureId(center.index);

    if (newAdventurerIconSettings.enabled == true and newAdventurerTextureId ~= nil) then
        table.insert(icons, {
            kind = 'newAdventurerIcon',
            textureId = newAdventurerTextureId,
            size = tonumber(newAdventurerIconSettings.iconSize) or 16,
            offsetX = tonumber(newAdventurerIconSettings.offsetX) or 24,
            offsetY = tonumber(newAdventurerIconSettings.offsetY) or -54,
            anchorTo = newAdventurerIconSettings.anchorTo,
            anchorPoint = newAdventurerIconSettings.anchorPoint,
        });
    end

    local targetMarker = targetModuleMarker.Build('Self', layoutStateName, targetStateName, hpBarSettings, 0);
    local castBar, castPercent = BuildCastBar(castData, castBarSettings, globalSettings);
    local nameAoeActive = aoeRangeSettings.enabled == true and aoeNameHighlight.IsHighlighted(center.index, 'self');
    local nameTextSize = nameAoeActive == true and math.max(tonumber(nameSettings.textSize) or nameDefaults.textSize, tonumber(aoeRangeSettings.fontSize) or aoeRangeDefaults.fontSize) or nameSettings.textSize;
    local nameStyleKey = table.concat({
        'aoe=' .. tostring(nameAoeActive == true),
        'size=' .. tostring(nameTextSize or ''),
        'color=' .. StableTableKey(nameAoeActive == true and aoeRangeSettings.fontColor or ''),
        'icon=' .. tostring(aoeRangeSettings.iconEnabled == true) .. ':' .. tostring(aoeRangeSettings.iconSize or ''),
        'highlight=' .. tostring(aoeRangeSettings.highlightEnabled == true) .. ':' .. tostring(aoeRangeSettings.backgroundFile or '') .. ':' .. tostring(aoeRangeSettings.backgroundSpacing or '') .. ':' .. StableTableKey(aoeRangeSettings.backgroundColor or ''),
    }, ';');

    local plateData = {
        hp = hpPercent,
        mp = mpPercent,
        tp = tpPercent,
        cast = castPercent,
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
        name = nameEnabled and center.name or '',
        aoeNameActive = nameAoeActive == true,
        nameFontFamily = fonts.GetRole(globalSettings, false),
        nameFontFlags = fonts.GetRoleFlags(globalSettings, false),
        nameFontSize = textScale.ToNameTextureFontSize(nameTextSize, nameDefaults.textSize),
        nameColor = (nameAoeActive == true and aoeRangeSettings.fontColor) or nameSettings.color or { 1.0, 1.0, 1.0, 1.0 },
        nameOutlineEnabled = (tonumber(nameSettings.outlineSize) or 0) > 0,
        nameOutlineColor = nameSettings.outlineColor or { 0.0, 0.0, 0.0, 1.0 },
        nameOutlineSize = tonumber(nameSettings.outlineSize) or 0,
        nameOffsetX = tonumber(nameSettings.offsetX) or 0,
        nameOffsetY = tonumber(nameSettings.offsetY) or defaultOffsetY,
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
            text = BuildResourceText(hpBarSettings, 'HP', center.hp, center.maxHp, hpPercent),
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
            text = BuildResourceText(mpBarSettings, 'MP', center.mp, center.maxMp, mpPercent),
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
            color = tpColor,
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
        castBar = castBar,
        icons = icons,
        anchorFallbackRects = BuildPlayerIndicatorAnchorFallbackRects({
            { kind = 'allianceLeaderIcon', settings = allianceLeaderIconSettings, defaults = allianceLeaderIconDefaults, defaultX = -120, defaultY = -54 },
            { kind = 'partyLeaderIcon', settings = partyLeaderIconSettings, defaults = partyLeaderIconDefaults, defaultX = -96, defaultY = -54 },
            { kind = 'gameModeIcon', settings = gameModeIconSettings, defaults = gameModeIconDefaults, defaultX = -72, defaultY = -54 },
            { kind = 'linkshellIcon', settings = linkshellIconSettings, defaults = linkshellIconDefaults, defaultX = 48, defaultY = -54 },
            { kind = 'bazaarIcon', settings = bazaarIconSettings, defaults = bazaarIconDefaults, defaultX = 72, defaultY = -54 },
            { kind = 'awayIcon', settings = awayIconSettings, defaults = awayIconDefaults, defaultX = 120, defaultY = -54 },
            { kind = 'disconnectIcon', settings = disconnectIconSettings, defaults = disconnectIconDefaults, defaultX = 144, defaultY = -54 },
            { kind = 'starsIcon', settings = starsIconSettings, defaults = starsIconDefaults, defaultX = -48, defaultY = -54 },
            { kind = 'newAdventurerIcon', settings = newAdventurerIconSettings, defaults = newAdventurerIconDefaults, defaultX = 24, defaultY = -54 },
        }),
    };

    if (plateData.aoeNameActive == true) then
        aoeRangeVisuals.Apply(plateData, aoeRangeSettings, hpBarSettings);
    end
    plateData.debugClickRects = worldMarkerProbe.GetClickDebug();
    plateData.debugClickRectColor = 0x01FFD400;

    local isEngaged = tonumber(center.status) == 1;

    if (ShouldLoadStatusRows(buffsSettings, isEngaged) == true) then
        AddStatusIconsToPlate(plateData, playerStatuses.GetSelfRows('buff'), buffsSettings, isEngaged, globalSettings, 'buffs');
    end

    if (ShouldLoadStatusRows(debuffsSettings, isEngaged) == true) then
        AddStatusIconsToPlate(plateData, playerStatuses.GetSelfRows('debuff'), debuffsSettings, isEngaged, globalSettings, 'debuffs');
    end

    if (enmity.ShouldDrawAlly(center, globalSettings) == true) then
        enmity.AddIcon(plateData, globalSettings.enmity);
    end

    if (stateName == 'Fishing') then
        fishing.AddIcon(plateData, globalSettings.fishing);
    else
        fishing.ClearResult();
    end

    gathering.AddWidget(plateData, globalSettings.gathering or globalDefaults.gathering);

    if (stateName == 'Crafting') then
        crafting.AddWidget(plateData, globalSettings.crafting);
    elseif (crafting.IsCraftingStatus(center.status) ~= true) then
        crafting.ClearResult();
    end

    if (stateName == 'Resting' and restingSettings.enabled ~= false) then
        local currentMp = tonumber(center.mp);
        local maxMp = tonumber(center.maxMp) or 0;
        local mpIsFull = mpPercent >= 100 or (currentMp ~= nil and maxMp > 0 and currentMp >= maxMp);
        local logoutActive = restingTick.IsLogoutActive(restingSettings);
        local hideAtFullHp = restingSettings.hideAtFullHp == true and hpPercent >= 100;
        local hideAtFullMp = restingSettings.hideAtFullMp == true and mpIsFull == true;
        local tick = nil;
        if (logoutActive == true or (hideAtFullHp ~= true and hideAtFullMp ~= true)) then
            tick = restingTick.Get(center.status, center.hp, center.mp, center.maxMp, restingSettings);
        else
            restingTick.Reset();
        end

        if ((logoutActive == true or (hideAtFullHp ~= true and hideAtFullMp ~= true)) and tick ~= nil) then
            plateData.extraBars = plateData.extraBars or {};
            plateData.extraBars[#plateData.extraBars + 1] = {
                kind = 'resting',
                enabled = true,
                displayMode = restingSettings.displayMode or 'Bar',
                progress = tick.progress,
                width = tonumber(restingSettings.width) or 180,
                height = tonumber(restingSettings.height) or 12,
                ringSize = tonumber(restingSettings.ringSize) or 88,
                ringThickness = tonumber(restingSettings.ringThickness) or 10,
                offsetX = tonumber(restingSettings.offsetX) or 0,
                offsetY = tonumber(restingSettings.offsetY) or 38,
                anchorTo = restingSettings.anchorTo or 'Plate',
                anchorPoint = restingSettings.anchorPoint,
                color = restingSettings.color or { 0.55, 0.95, 0.35, 1.0 },
                backgroundColor = restingSettings.backgroundColor or { 0.10, 0.10, 0.10, 1.0 },
                borderColor = restingSettings.borderColor or { 1.0, 1.0, 1.0, 1.0 },
                borderSize = tonumber(restingSettings.borderSize) or 0,
                textureId = barTextures.GetTextureId(restingSettings.texture or 'Solid'),
                text = tick.text,
                textOffsetX = 0,
                textOffsetY = 0,
                fontFamily = fonts.GetRole(globalSettings, true),
                fontFlags = fonts.GetRoleFlags(globalSettings, true),
                fontSize = textScale.ToTextureFontSize(restingSettings.fontSize, 12),
                textColor = restingSettings.textColor or { 0.0, 0.0, 0.0, 1.0 },
                textOutlineEnabled = restingSettings.textOutlineEnabled == true,
                textOutlineColor = restingSettings.textOutlineColor or { 1.0, 1.0, 1.0, 1.0 },
                textOutlineSize = tonumber(restingSettings.textOutlineSize) or 1,
            };
        end
    else
        if (restingTick.ShouldPreserveLogoutTransition() == true) then
            restingTick.Reset();
        else
            restingTick.ResetAll();
        end
    end

    local cacheEligible = true;
    local signature = nil;
    local vitalSignature = nil;

    if (cacheEligible == true) then
        signature = BuildWorldCacheSignature(plateData, center, stateName, targetStateName, layoutStateName);
        vitalSignature = BuildWorldVitalSignature(
            center,
            hpPercent,
            mpPercent,
            tpValue,
            castPercent,
            castBar ~= nil and castBar.text or '',
            stateName,
            targetStateName,
            layoutStateName,
            nameStyleKey,
            targeting.GetGatheringDisplaySignature()
        );

        if (cachedWorldPlate ~= nil and cachedWorldPlate.signature == signature) then
            canvasTexture.TouchKey(cachedWorldPlate.textureKey);
            cachedWorldPlate.lastUsed = os.clock();
            perfMeter.Count('self.cache.hit', 1);
            QueueRenderedWorldPlate(
                center,
                hpPercent,
                targetStateName,
                layoutStateName,
                cachedWorldPlate.plateTextureId,
                cachedWorldPlate.textureWidth,
                cachedWorldPlate.textureHeight,
                cachedWorldPlate.plateClickRects
            );
            return;
        end

        if (
            adaptivePerformance.ShouldThrottleBackground() == true and
            cachedWorldPlate ~= nil and
            cachedWorldPlate.vitalSignature == vitalSignature and
            (os.clock() - (tonumber(cachedWorldPlate.lastUsed) or 0)) < 0.75
        ) then
            canvasTexture.TouchKey(cachedWorldPlate.textureKey);
            cachedWorldPlate.lastUsed = os.clock();
            perfMeter.Count('self.cache.smooth', 1);
            QueueRenderedWorldPlate(
                center,
                hpPercent,
                targetStateName,
                layoutStateName,
                cachedWorldPlate.plateTextureId,
                cachedWorldPlate.textureWidth,
                cachedWorldPlate.textureHeight,
                cachedWorldPlate.plateClickRects
            );
            return;
        end

        perfMeter.Count('self.cache.miss', 1);
    else
        perfMeter.Count('self.cache.skip', 1);
    end

    local renderTextureKey = cachedWorldTextureKey .. (plateData.canvasWidth ~= nil and '-aoe' or '');
    local plateTexture, textureWidth, textureHeight = canvasTexture.Render(plateData, renderTextureKey);
    local plateTextureId = canvasTexture.GetTextureId(plateTexture);
    local plateClickRects = plateData._elementRects or canvasTexture.GetElementRects(plateData);

    if (plateTextureId == nil) then
        cachedWorldPlate = nil;
        return;
    end

    if (cacheEligible == true and signature ~= nil) then
        cachedWorldPlate = {
            signature = signature,
            vitalSignature = vitalSignature,
            textureKey = renderTextureKey,
            lastUsed = os.clock(),
            plateTextureId = plateTextureId,
            textureWidth = textureWidth,
            textureHeight = textureHeight,
            plateClickRects = plateClickRects,
        };
    else
        cachedWorldPlate = nil;
    end

    QueueRenderedWorldPlate(
        center,
        hpPercent,
        targetStateName,
        layoutStateName,
        plateTextureId,
        textureWidth,
        textureHeight,
        plateClickRects
    );
end

function selfPlate.Build()
    return nil;
end

function selfPlate.SetLagTestSuppressed(value)
    lagTestSuppressed = value == true;
end

function selfPlate.GetLagTestSuppressed()
    return lagTestSuppressed == true;
end

-- ============================================================
-- Rendering
-- ============================================================

function selfPlate.Render()
    if (state.GetWorldEnabled() ~= true) then
        return;
    end

    if (worldDepthPlate.IsEnabled() == true) then
        return;
    end

    if (lagTestSuppressed == true) then
        return;
    end

    local center = entities.GetSelfCanvasCenter(canvasDefaults.offsetX, canvasDefaults.offsetY);

    if (center == nil) then
        return;
    end

    local stateName = GetLiveSelfStateName(center);
    local nameSettings = state.GetWidgetSettings('Self', GetLayoutStateName(stateName), 'Name', nameDefaults);

    if (stateName ~= 'Fishing') then
        fishing.ClearResult();
    end

    if (stateName ~= 'Crafting' and crafting.IsCraftingStatus(center.status) ~= true) then
        crafting.ClearResult();
    end

    if (worldMarkerProbe.GetEnabled() == true and worldMarkerProbe.GetReplacePlates() == true) then
        QueueWorldMarker(center, nameSettings, stateName);
        return;
    end

    local bounds = canvas.GetBounds(canvasDefaults, center.x, center.y);
    local drawList = imgui.GetForegroundDrawList and imgui.GetForegroundDrawList() or imgui.GetWindowDrawList();

    if (canvasDefaults.debugOutline == true) then
        drawList:AddRect({ bounds.left, bounds.top }, { bounds.left + bounds.width, bounds.top + bounds.height }, 0xFFFFFF00);
    end

    DrawBackground(drawList, bounds);

    if (nativeUiPolicy.ShouldDrawLibraNames() == true) then
        widgets.name.Draw({ name = center.name }, BuildAoeNameSettings(GetLayoutStateName(stateName), nameSettings, center.index), {
            drawList = drawList,
            bounds = bounds,
            canvas = canvas,
        });
    end
end

return selfPlate;
