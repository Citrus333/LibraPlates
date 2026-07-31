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
local mounted = require('core.mounted');
local worldDepthPlate = require('core.world_depth_plate');
local worldMarkerProbe = require('core.world_marker_probe');
local widgets = require('modules.widgets.init');

local selfPlate = {};
local lagTestSuppressed = false;
local cachedWorldPlates = {};
local cachedWorldPlateLimit = 4;
local cachedWorldTextureKey = 'self-world';
local restingWidgetStableY = nil;
local restingWidgetStableClock = nil;
local restingWidgetDelaySeconds = 0.22;
local restingWidgetMoveThreshold = 18;

local function GetDisplayHeight()
    if (imgui.GetIO == nil) then
        return nil;
    end

    local ok, io = pcall(function()
        return imgui.GetIO();
    end);

    if (ok ~= true or io == nil or io.DisplaySize == nil) then
        return nil;
    end

    return tonumber(io.DisplaySize.y or io.DisplaySize.Y or io.DisplaySize[2]);
end

local function IsBadSelfTransitionCenter(center)
    local displayHeight = GetDisplayHeight();

    if (
        center ~= nil and
        displayHeight ~= nil and
        (tonumber(center.y) or 0) > (displayHeight * 0.55)
    ) then
        return true;
    end

    return false;
end

LibraPlatesSelfShouldDrawRestingWidget = function(center, isActive)
    if (isActive ~= true or center == nil) then
        restingWidgetStableY = nil;
        restingWidgetStableClock = nil;
        return false;
    end

    local now = os.clock();
    local centerY = tonumber(center.y);

    if (centerY == nil) then
        restingWidgetStableY = nil;
        restingWidgetStableClock = nil;
        return false;
    end

    if (
        restingWidgetStableY == nil or
        math.abs(centerY - restingWidgetStableY) > restingWidgetMoveThreshold
    ) then
        restingWidgetStableY = centerY;
        restingWidgetStableClock = now;
        return false;
    end

    restingWidgetStableY = centerY;
    return restingWidgetStableClock ~= nil and (now - restingWidgetStableClock) >= restingWidgetDelaySeconds;
end;

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

local function GetWorldCacheKey(stateName, targetStateName, layoutStateName, hasAoeCanvas)
    return table.concat({
        tostring(stateName or 'Idle'),
        tostring(targetStateName or 'Idle'),
        tostring(layoutStateName or 'Idle'),
        hasAoeCanvas == true and 'aoe' or 'plain',
    }, ':');
end

local function GetWorldTextureKey(cacheKey)
    return cachedWorldTextureKey .. '-' .. tostring(cacheKey or 'idle'):gsub('[^%w%-_]', '-');
end

local function TrimWorldPlateCache()
    local count = 0;
    local oldestKey = nil;
    local oldestTime = nil;

    for key, cached in pairs(cachedWorldPlates) do
        count = count + 1;

        local used = tonumber(cached ~= nil and cached.lastUsed) or 0;
        if (oldestTime == nil or used < oldestTime) then
            oldestTime = used;
            oldestKey = key;
        end
    end

    if (count <= cachedWorldPlateLimit or oldestKey == nil) then
        return;
    end

    local cached = cachedWorldPlates[oldestKey];
    if (cached ~= nil and cached.textureKey ~= nil) then
        canvasTexture.ReleaseKey(cached.textureKey);
    end

    cachedWorldPlates[oldestKey] = nil;
end

local function ClearWorldPlateCache()
    for _, cached in pairs(cachedWorldPlates) do
        if (cached ~= nil and cached.textureKey ~= nil) then
            canvasTexture.ReleaseKey(cached.textureKey);
        end
    end

    cachedWorldPlates = {};
end

local function BuildWorldCacheSignature(plateData, center, stateName, targetStateName, layoutStateName, globalSettings, aoeRangeSettings)
    local statusIconPack = globalSettings ~= nil and globalSettings.statusIcons ~= nil and globalSettings.statusIcons.iconPack or '';
    local aoeSignature = (aoeRangeSettings ~= nil and aoeRangeSettings.enabled == true)
        and aoeNameHighlight.GetSignature(center ~= nil and center.index or 0, 'self')
        or 'aoe-name:0';

    return table.concat({
        'v=1',
        'index=' .. tostring(center ~= nil and center.index or ''),
        'server=' .. tostring(center ~= nil and center.serverId or ''),
        'status=' .. tostring(center ~= nil and center.status or ''),
        'state=' .. tostring(stateName or ''),
        'target=' .. tostring(targetStateName or ''),
        'layout=' .. tostring(layoutStateName or ''),
        'aoe=' .. aoeSignature,
        'policy=' .. canvasTexture.GetRenderPolicyKey(),
        'statusIconPack=' .. tostring(statusIconPack),
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
        'hpValue=' .. tostring(center ~= nil and center.hp or '') .. '/' .. tostring(center ~= nil and center.maxHp or ''),
        'mp=' .. tostring(mpPercent or ''),
        'mpValue=' .. tostring(center ~= nil and center.mp or '') .. '/' .. tostring(center ~= nil and center.maxMp or ''),
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
    local plateWorldOffsetY = mounted.IsStatus(center.status) and (0.05 - mounted.GetPlateLift(center.index)) or 0.05;
    local plateWorldWidth, plateWorldHeight = canvasTexture.GetWorldSize(2.35, 1.18, textureWidth, textureHeight);

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
            plateWorldWidth = plateWorldWidth,
            plateWorldHeight = plateWorldHeight,
            plateWorldOffsetY = plateWorldOffsetY,
            pcBodyPlateOffsetEnabled = true,
            plateDistanceScaleOffsetY = -0.12,
            plateTextureWidth = textureWidth,
            plateTextureHeight = textureHeight,
            plateClickRects = plateClickRects,
            jobEnabled = false,
            selfBarModelDepthLift = 0.18,
            clickTargetType = 'self',
            clickName = center.name,
            layoutStateName = layoutStateName,
        }, 'self', 0, plateWorldOffsetY),
    });
end

local function BuildAoeNameSettings(layoutStateName, nameSettings, targetIndex)
    local aoeRangeSettings = state.GetWidgetSettings('Self', 'Combat', 'AOE range', aoeRangeDefaults);

    if (aoeRangeSettings.enabled ~= true or aoeNameHighlight.IsHighlighted(targetIndex, 'self') ~= true) then
        return nameSettings;
    end

    local merged = {};

    for key, value in pairs(nameSettings or {}) do
        merged[key] = value;
    end

    merged.textSize = tonumber(aoeRangeSettings.fontSize) or aoeRangeDefaults.fontSize;
    merged.color = aoeRangeSettings.fontColor or aoeRangeDefaults.fontColor or merged.color;
    return merged;
end

local function BuildPlayerIndicatorAnchorFallbackRects(definitions)
    local fallbacks = {};

    for _, definition in ipairs(definitions or {}) do
        local settings = definition.settings or {};
        local defaults = definition.defaults or {};
        local size = math.max(6, math.min(256, tonumber(settings.iconSize) or tonumber(defaults.iconSize) or 16));
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
                anchorCollapse = settings.anchorCollapse,
                anchorSpacing = settings.anchorSpacing,
                anchorOrder = settings.anchorOrder,
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

    local maxIcons = math.max(1, math.min(32, tonumber(iconSettings.maxIcons) or 12));
    local iconsPerRow = math.max(1, math.min(24, tonumber(iconSettings.iconsPerRow) or 6));
    local iconSize = math.max(6, math.min(256, tonumber(iconSettings.iconSize) or 18));
    local spacing = math.max(0, math.min(24, tonumber(iconSettings.iconSpacing) or 2));
    local rowSpacing = math.max(0, math.min(32, tonumber(iconSettings.rowSpacing) or 2));
    local growLeft = tostring(iconSettings.growthDirection or 'Right') == 'Left';
    local anchored = tostring(iconSettings.anchorTo or 'Plate') ~= 'Plate';
    local rowHeight = iconSize + rowSpacing;

    if (iconSettings.showTimers == true) then
        rowHeight = iconSize + math.max(rowSpacing, (tonumber(iconSettings.timerFontSize) or 8) + math.max(0, tonumber(iconSettings.timerOffsetY) or 0) + 2);
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
            local layoutRowCount = math.min(iconsPerRow, total);
            local rowWidth = (layoutRowCount * iconSize) + ((layoutRowCount - 1) * spacing);
            local iconOffsetX = baseX - (rowWidth * 0.5) + (iconSize * 0.5) + (col * (iconSize + spacing));
            local timerSeconds = type(rowData) == 'table' and tonumber(rowData.seconds) or nil;
            local timerText = nil;

            if (anchored == true) then
                iconOffsetX = growLeft == true
                    and (baseX - rowWidth + (col * (iconSize + spacing)))
                    or (baseX + (col * (iconSize + spacing)));
            end

            if (iconSettings.showTimers == true and timerSeconds ~= nil and timerSeconds > 0) then
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
                anchorCollapse = iconSettings.anchorCollapse,
                anchorSpacing = iconSettings.anchorSpacing,
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
                timerBackgroundColor = iconSettings.timerBackgroundColor,
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
                timerWarningOutlineColorEnabled = iconSettings.timerWarningOutlineColorEnabled == true,
                timerWarningOutlineStage1Color = iconSettings.timerWarningOutlineStage1Color,
                timerWarningOutlineStage2Color = iconSettings.timerWarningOutlineStage2Color,
                timerWarningOutlineStage3Color = iconSettings.timerWarningOutlineStage3Color,
                timerWarningBoxColorEnabled = iconSettings.timerWarningBoxColorEnabled == true,
                timerWarningBoxStage1Color = iconSettings.timerWarningBoxStage1Color,
                timerWarningBoxStage2Color = iconSettings.timerWarningBoxStage2Color,
                timerWarningBoxStage3Color = iconSettings.timerWarningBoxStage3Color,
                timerWarningBoxBorderEnabled = iconSettings.timerWarningBoxBorderEnabled == true,
                timerWarningBoxBorderStage1Color = iconSettings.timerWarningBoxBorderStage1Color,
                timerWarningBoxBorderStage2Color = iconSettings.timerWarningBoxBorderStage2Color,
                timerWarningBoxBorderStage3Color = iconSettings.timerWarningBoxBorderStage3Color,
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

local function IsEnabled(settings, isEngaged)
    return settings ~= nil and settings.enabled == true;
end

local function BuildTargetMarkerIfEnabled(layoutStateName, targetStateName, hpBarSettings)
    if (targetStateName ~= 'Target' and targetStateName ~= 'Subtarget') then
        return { enabled = false }, false;
    end

    local markerSettings = targetModuleMarker.GetSettings('Self', layoutStateName, targetStateName);
    if (targetModuleMarker.HasDrawableSettings('Self', markerSettings) ~= true) then
        return { enabled = false }, false;
    end

    local marker = targetModuleMarker.Build('Self', layoutStateName, targetStateName, hpBarSettings, 0);
    return marker, marker ~= nil and marker.enabled == true;
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
    if (stateName == 'Resting' or stateName == 'Fishing') then
        return 'Idle';
    end

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

    if (castData.interrupted == true and castBarSettings.interruptBarEnabled == false) then
        return nil, 0;
    end

    local castTime = math.max(0.1, tonumber(castData.castTime) or 0.1);
    local elapsed = math.max(0.0, os.clock() - (tonumber(castData.startTime) or os.clock()));
    if (castData.interrupted == true) then
        elapsed = math.max(0.0, tonumber(castData.elapsed) or elapsed);
    end
    local castPercent = math.max(0, math.min(100, (elapsed / castTime) * 100));
    if (castData.interrupted == true and tonumber(castData.progress) ~= nil) then
        castPercent = math.max(0, math.min(100, tonumber(castData.progress) or 0));
    end
    local displayText = (castData.interrupted == true)
        and tostring(castBarSettings.interruptedText or castBarDefaults.interruptedText or 'Interrupted')
        or tostring(castData.spellName or '');
    local showText = castBarSettings.showSpellName ~= false;
    if (castData.interrupted == true) then
        showText = castBarSettings.interruptTextEnabled == true;
    end
    local textUseSmallFont = castBarSettings.useSmallFont == true;
    local fontSize = castBarSettings.fontSize;
    local textColor = castBarSettings.textColor;
    local textOutlineEnabled = castBarSettings.textOutlineEnabled == true;
    local textOutlineColor = castBarSettings.textOutlineColor;
    local textOutlineSize = tonumber(castBarSettings.textOutlineSize) or castBarDefaults.textOutlineSize;
    local textOffsetX = tonumber(castBarSettings.textOffsetX) or castBarDefaults.textOffsetX;
    local textOffsetY = tonumber(castBarSettings.textOffsetY) or castBarDefaults.textOffsetY;

    if (castData.interrupted == true) then
        textUseSmallFont = castBarSettings.interruptUseSmallFont == true;
        fontSize = castBarSettings.interruptFontSize or castBarDefaults.interruptFontSize;
        textColor = castBarSettings.interruptTextColor or castBarDefaults.interruptTextColor;
        textOutlineEnabled = castBarSettings.interruptTextOutlineEnabled == true;
        textOutlineColor = castBarSettings.interruptTextOutlineColor or castBarDefaults.interruptTextOutlineColor;
        textOutlineSize = tonumber(castBarSettings.interruptTextOutlineSize) or castBarDefaults.interruptTextOutlineSize;
        textOffsetX = tonumber(castBarSettings.interruptTextOffsetX) or castBarDefaults.interruptTextOffsetX;
        textOffsetY = tonumber(castBarSettings.interruptTextOffsetY) or castBarDefaults.interruptTextOffsetY;
    end
    local barColor = castBarSettings.color or castBarDefaults.color;
    if (castData.interrupted == true and castBarSettings.interruptColorEnabled ~= false) then
        barColor = castBarSettings.interruptedColor or castBarDefaults.interruptedColor;
    end
    local spellIconId = tonumber(castData.spellIconId);
    local spellIconTextureId = nil;

    if (castBarSettings.showSpellIcon == true) then
        spellIconTextureId = statusIconTextures.GetTextureId(castData.spellStatusId)
            or spellIconTextures.GetGeoTextureId(castData.spellId)
            or spellIconTextures.GetTextureId(spellIconId)
            or spellIconTextures.GetTextureId(castData.spellId);
    end

    return {
        enabled = true,
        width = tonumber(castBarSettings.width) or castBarDefaults.width,
        height = tonumber(castBarSettings.height) or castBarDefaults.height,
        offsetX = tonumber(castBarSettings.offsetX) or castBarDefaults.offsetX,
        offsetY = tonumber(castBarSettings.offsetY) or castBarDefaults.offsetY,
        anchorTo = castBarSettings.anchorTo or castBarDefaults.anchorTo,
        anchorPoint = castBarSettings.anchorPoint or castBarDefaults.anchorPoint,
        anchorCollapse = castBarSettings.anchorCollapse,
        anchorSpacing = castBarSettings.anchorSpacing,
        color = barColor,
        backgroundColor = castBarSettings.backgroundColor or castBarDefaults.backgroundColor,
        borderColor = castBarSettings.borderColor or castBarDefaults.borderColor,
        borderSize = tonumber(castBarSettings.borderSize) or castBarDefaults.borderSize,
        texture = castBarSettings.texture or castBarDefaults.texture,
        textureId = barTextures.GetTextureId(castBarSettings.texture or castBarDefaults.texture),
        text = showText == true and displayText or '',
        textOffsetX = textOffsetX,
        textOffsetY = textOffsetY,
        fontFamily = fonts.GetRole(globalSettings, textUseSmallFont),
        fontFlags = fonts.GetRoleFlags(globalSettings, textUseSmallFont),
        fontSize = textScale.ToTextureFontSize(fontSize, (castData.interrupted == true and castBarDefaults.interruptFontSize) or castBarDefaults.fontSize),
        textColor = textColor or castBarDefaults.textColor,
        textOutlineEnabled = textOutlineEnabled,
        textOutlineColor = textOutlineColor or castBarDefaults.textOutlineColor,
        textOutlineSize = textOutlineSize,
        separateLabelOffsets = true,
        iconTextureId = spellIconTextureId,
        iconSize = tonumber(castBarSettings.spellIconSize) or castBarDefaults.spellIconSize,
        iconOffsetX = tonumber(castBarSettings.spellIconOffsetX) or castBarDefaults.spellIconOffsetX,
        iconOffsetY = tonumber(castBarSettings.spellIconOffsetY) or castBarDefaults.spellIconOffsetY,
        iconGap = 4,
    }, castPercent;
end

local function DrawBackground(drawList, bounds, backgroundSettings, isEngaged)
    if (IsEnabled(backgroundSettings, isEngaged) ~= true) then
        return;
    end

    local background = {
        enabled = true,
        width = tonumber(backgroundSettings.width) or backgroundDefaults.width,
        height = tonumber(backgroundSettings.height) or backgroundDefaults.height,
        offsetX = tonumber(backgroundSettings.offsetX) or backgroundDefaults.offsetX,
        offsetY = tonumber(backgroundSettings.offsetY) or backgroundDefaults.offsetY,
        color = backgroundSettings.color or backgroundDefaults.color,
        borderColor = backgroundSettings.borderColor or backgroundDefaults.borderColor,
        borderSize = tonumber(backgroundSettings.borderSize) or backgroundDefaults.borderSize,
        texture = backgroundSettings.texture or backgroundDefaults.texture,
        imageOpacity = backgroundSettings.imageOpacity or backgroundDefaults.imageOpacity,
    };

    if (background == nil or background.enabled ~= true) then
        return;
    end

    local rect = canvas.GetLocalRect(bounds, background);

    drawList:AddRectFilled(
        { rect.left, rect.top },
        { rect.left + rect.width, rect.top + rect.height },
        ColorToU32(background.color)
    );

    local textureId = backgroundTextures.GetTextureId(background.texture);

    if (textureId ~= nil) then
        local textureAlpha = tonumber(background.imageOpacity);
        if (textureAlpha ~= nil and textureAlpha > 1) then
            textureAlpha = textureAlpha / 100;
        end
        textureAlpha = textureAlpha or tonumber(background.color ~= nil and background.color[4] or nil) or 0.45;
        drawList:AddImage(textureId, { rect.left, rect.top }, { rect.left + rect.width, rect.top + rect.height }, { 0, 0 }, { 1, 1 }, ColorToU32({ 1.0, 1.0, 1.0, textureAlpha }));
    end

    if ((tonumber(background.borderSize) or 0) > 0) then
        drawList:AddRect(
            { rect.left, rect.top },
            { rect.left + rect.width, rect.top + rect.height },
            ColorToU32(background.borderColor),
            0,
            0,
            tonumber(background.borderSize) or 1
        );
    end
end

local function QueueWorldMarker(center, nameSettings, stateName)
    local targetStateName = targeting.GetTargetStateName(center.index);
    local layoutStateName = (targetStateName == 'Target' or targetStateName == 'Subtarget') and 'Combat' or GetLayoutStateName(stateName);
    nameSettings = state.GetWidgetSettings('Self', layoutStateName, 'Name', nameDefaults);
    local gameModeIconSettings = state.GetWidgetSettings('Self', layoutStateName, 'Game mode icon', gameModeIconDefaults);
    local partyLeaderIconSettings = state.GetWidgetSettings('Self', layoutStateName, 'Party leader icon', partyLeaderIconDefaults);
    local allianceLeaderIconSettings = state.GetWidgetSettings('Self', layoutStateName, 'Alliance leader icon', allianceLeaderIconDefaults);
    local bazaarIconSettings = state.GetWidgetSettings('Self', layoutStateName, 'Bazaar icon', bazaarIconDefaults);
    local linkshellIconSettings = state.GetWidgetSettings('Self', layoutStateName, 'Linkshell icon', linkshellIconDefaults);
    local awayIconSettings = state.GetWidgetSettings('Self', layoutStateName, 'Away icon', awayIconDefaults);
    local disconnectIconSettings = state.GetWidgetSettings('Self', layoutStateName, 'Disconnect icon', disconnectIconDefaults);
    local anonIconDefaults = require('config.widgets.anon_icon');
    local anonIconSettings = state.GetWidgetSettings('Self', layoutStateName, 'Anon icon', anonIconDefaults);
    local starsIconSettings = state.GetWidgetSettings('Self', layoutStateName, 'Stars icon', starsIconDefaults);
    local levelSyncIconDefaults = require('config.widgets.level_sync_icon');
    local levelSyncIconSettings = state.GetWidgetSettings('Self', layoutStateName, 'Level sync icon', levelSyncIconDefaults);
    local newAdventurerIconSettings = state.GetWidgetSettings('Self', layoutStateName, 'New adventurer icon', newAdventurerIconDefaults);
    local backgroundSettings = state.GetWidgetSettings('Self', layoutStateName, 'Background', backgroundDefaults);
    local hpBarSettings = state.GetWidgetSettings('Self', layoutStateName, 'HP Bar', barDefaults);
    local mpBarSettings = state.GetWidgetSettings('Self', layoutStateName, 'MP Bar', mpBarDefaults);
    local tpBarSettings = state.GetWidgetSettings('Self', layoutStateName, 'TP Bar', tpBarDefaults);
    local castBarSettings = state.GetWidgetSettings('Self', layoutStateName, 'Cast bar', castBarDefaults);
    local aoeRangeSettings = state.GetWidgetSettings('Self', 'Combat', 'AOE range', aoeRangeDefaults);
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
    local tpColor2 = tpBarSettings.color2 or tpBarDefaults.color2;
    local tpColor3 = tpBarSettings.color3 or tpBarDefaults.color3;
    local useTacticalOverlay = layoutStateName == 'Combat';
    local isEngaged = tonumber(center.status) == 1;
    local shouldLoadBuffs = ShouldLoadStatusRows(buffsSettings, isEngaged);
    local shouldLoadDebuffs = ShouldLoadStatusRows(debuffsSettings, isEngaged);
    local targetMarker, targetMarkerActive = BuildTargetMarkerIfEnabled(layoutStateName, targetStateName, hpBarSettings);
    local nameAoeActive = aoeRangeSettings.enabled == true and aoeNameHighlight.IsHighlighted(center.index, 'self');
    local enmityActive = globalSettings.enmity ~= nil and globalSettings.enmity.enabled == true and enmity.ShouldDrawAlly(center, globalSettings) == true;
    local fishingActive = (stateName == 'Fishing' or fishing.IsSessionActive() == true) and globalSettings.fishing ~= nil and globalSettings.fishing.enabled ~= false;
    local craftingActive = stateName == 'Crafting' and globalSettings.crafting ~= nil and globalSettings.crafting.enabled ~= false;
    local gatheringActive = globalSettings.gathering ~= nil and globalSettings.gathering.enabled ~= false and targeting.GetGatheringDisplayInfo() ~= nil;
    local restingActive = stateName == 'Resting' and restingSettings.enabled ~= false;
    local nameLoaded = IsEnabled(nameSettings, isEngaged);
    local backgroundLoaded = IsEnabled(backgroundSettings, isEngaged);
    local hpBarLoaded = IsEnabled(hpBarSettings, isEngaged);
    local mpBarLoaded = IsEnabled(mpBarSettings, isEngaged);
    local tpBarLoaded = IsEnabled(tpBarSettings, isEngaged);
    local castBarLoaded = IsEnabled(castBarSettings, isEngaged);
    local gameModeIconLoaded = IsEnabled(gameModeIconSettings, isEngaged);
    local partyLeaderIconLoaded = IsEnabled(partyLeaderIconSettings, isEngaged);
    local allianceLeaderIconLoaded = IsEnabled(allianceLeaderIconSettings, isEngaged);
    local bazaarIconLoaded = IsEnabled(bazaarIconSettings, isEngaged);
    local linkshellIconLoaded = IsEnabled(linkshellIconSettings, isEngaged);
    local awayIconLoaded = IsEnabled(awayIconSettings, isEngaged);
    local disconnectIconLoaded = IsEnabled(disconnectIconSettings, isEngaged);
    local anonIconLoaded = IsEnabled(anonIconSettings, isEngaged);
    local starsIconLoaded = IsEnabled(starsIconSettings, isEngaged);
    local levelSyncIconLoaded = IsEnabled(levelSyncIconSettings, isEngaged);
    local newAdventurerIconLoaded = IsEnabled(newAdventurerIconSettings, isEngaged);
    local castData = nil;
    if (castBarLoaded == true) then
        castData = enemyCasts.GetActiveCast(center.serverId) or enemyCasts.GetInterruptedCast(center.serverId);
    end
    local hasEnabledBaseWidget =
        nameLoaded == true or
        backgroundLoaded == true or
        hpBarLoaded == true or
        mpBarLoaded == true or
        tpBarLoaded == true or
        castBarLoaded == true or
        gameModeIconLoaded == true or
        partyLeaderIconLoaded == true or
        allianceLeaderIconLoaded == true or
        bazaarIconLoaded == true or
        linkshellIconLoaded == true or
        awayIconLoaded == true or
        disconnectIconLoaded == true or
        anonIconLoaded == true or
        starsIconLoaded == true or
        levelSyncIconLoaded == true or
        newAdventurerIconLoaded == true or
        shouldLoadBuffs == true or
        shouldLoadDebuffs == true;

    if (
        hasEnabledBaseWidget ~= true and
        targetMarkerActive ~= true and
        nameAoeActive ~= true and
        enmityActive ~= true and
        craftingActive ~= true and
        gatheringActive ~= true and
        restingActive ~= true
    ) then
        fishing.ClearResult();
        if (crafting.IsCraftingStatus(center.status) ~= true) then
            crafting.ClearResult();
        end
        if (restingTick.ShouldPreserveLogoutTransition() == true) then
            restingTick.Reset();
        else
            restingTick.ResetAll();
        end
        ClearWorldPlateCache();
        return;
    end

    local hpCriticalActive =
        hpBarSettings.criticalColorEnabled == true and
        hpPercent <= (tonumber(hpBarSettings.criticalColorPercent) or 25);

    if (hpCriticalActive == true) then
        hpColor = hpBarSettings.criticalColor or { 1.0, 0.15, 0.10, 1.0 };
    elseif (
        hpBarSettings.lowColorEnabled == true and
        hpPercent <= (tonumber(hpBarSettings.lowColorPercent) or 50)
    ) then
        hpColor = hpBarSettings.lowColor or { 1.0, 0.55, 0.05, 1.0 };
    end

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

    if (tpPercent >= 100) then
        tpColor = tpBarSettings.fullColor or tpBarDefaults.fullColor or tpColor;
        tpColor2 = tpColor;
        tpColor3 = tpColor;
    end
    local nameEnabled = nameLoaded == true;
    local defaultOffsetY = tonumber(nameDefaults.offsetY) or 0;
    local modeText = gameMode.Resolve(center.index, false);
    local modeIconTextureId = (gameModeIconLoaded == true) and gameMode.GetIconTextureId(modeText) or nil;
    local icons = {};

    if (allianceLeaderIconLoaded == true) then
        local allianceLeaderTextureId = playerIndicators.GetAllianceLeaderIconTextureId(center.index);
        if (allianceLeaderTextureId ~= nil) then
            table.insert(icons, {
                kind = 'allianceLeaderIcon',
                textureId = allianceLeaderTextureId,
                size = tonumber(allianceLeaderIconSettings.iconSize) or 16,
                offsetX = tonumber(allianceLeaderIconSettings.offsetX) or -120,
                offsetY = tonumber(allianceLeaderIconSettings.offsetY) or -54,
                anchorTo = allianceLeaderIconSettings.anchorTo,
                anchorPoint = allianceLeaderIconSettings.anchorPoint,
                anchorCollapse = allianceLeaderIconSettings.anchorCollapse,
                anchorSpacing = allianceLeaderIconSettings.anchorSpacing,
            });
        end
    end

    if (partyLeaderIconLoaded == true) then
        local partyLeaderTextureId = playerIndicators.GetPartyLeaderIconTextureId(center.index);
        if (partyLeaderTextureId ~= nil) then
            table.insert(icons, {
                kind = 'partyLeaderIcon',
                textureId = partyLeaderTextureId,
                size = tonumber(partyLeaderIconSettings.iconSize) or 16,
                offsetX = tonumber(partyLeaderIconSettings.offsetX) or -96,
                offsetY = tonumber(partyLeaderIconSettings.offsetY) or -54,
                anchorTo = partyLeaderIconSettings.anchorTo,
                anchorPoint = partyLeaderIconSettings.anchorPoint,
                anchorCollapse = partyLeaderIconSettings.anchorCollapse,
                anchorSpacing = partyLeaderIconSettings.anchorSpacing,
            });
        end
    end

    if (gameModeIconLoaded == true and modeIconTextureId ~= nil) then
        table.insert(icons, {
            kind = 'gameModeIcon',
            textureId = modeIconTextureId,
            size = tonumber(gameModeIconSettings.iconSize) or 16,
            offsetX = tonumber(gameModeIconSettings.offsetX) or -72,
            offsetY = tonumber(gameModeIconSettings.offsetY) or -54,
            anchorTo = gameModeIconSettings.anchorTo,
            anchorPoint = gameModeIconSettings.anchorPoint,
            anchorCollapse = gameModeIconSettings.anchorCollapse,
            anchorSpacing = gameModeIconSettings.anchorSpacing,
            anchorOrder = gameModeIconSettings.anchorOrder,
        });
    end

    if (linkshellIconLoaded == true) then
        local linkshellTextureId = playerIndicators.GetLinkshellIconTextureId(center.index);
        local linkshellTint = playerIndicators.GetLinkshellIconTint(center.index);
        if (linkshellTextureId ~= nil) then
            table.insert(icons, {
                kind = 'linkshellIcon',
                textureId = linkshellTextureId,
                size = tonumber(linkshellIconSettings.iconSize) or 16,
                offsetX = tonumber(linkshellIconSettings.offsetX) or 48,
                offsetY = tonumber(linkshellIconSettings.offsetY) or -54,
                anchorTo = linkshellIconSettings.anchorTo,
                anchorPoint = linkshellIconSettings.anchorPoint,
                anchorCollapse = linkshellIconSettings.anchorCollapse,
                anchorSpacing = linkshellIconSettings.anchorSpacing,
                tint = linkshellTint,
            });
        end
    end

    if (bazaarIconLoaded == true) then
        local bazaarTextureId = playerIndicators.GetBazaarIconTextureId(center.index);
        if (bazaarTextureId ~= nil) then
            table.insert(icons, {
                kind = 'bazaarIcon',
                textureId = bazaarTextureId,
                size = tonumber(bazaarIconSettings.iconSize) or 16,
                offsetX = tonumber(bazaarIconSettings.offsetX) or 72,
                offsetY = tonumber(bazaarIconSettings.offsetY) or -54,
                anchorTo = bazaarIconSettings.anchorTo,
                anchorPoint = bazaarIconSettings.anchorPoint,
                anchorCollapse = bazaarIconSettings.anchorCollapse,
                anchorSpacing = bazaarIconSettings.anchorSpacing,
            });
        end
    end

    if (awayIconLoaded == true) then
        local awayTextureId = playerIndicators.GetAwayIconTextureId(center.index);
        if (awayTextureId ~= nil) then
            table.insert(icons, {
                kind = 'awayIcon',
                textureId = awayTextureId,
                size = tonumber(awayIconSettings.iconSize) or 16,
                offsetX = tonumber(awayIconSettings.offsetX) or 120,
                offsetY = tonumber(awayIconSettings.offsetY) or -54,
                anchorTo = awayIconSettings.anchorTo,
                anchorPoint = awayIconSettings.anchorPoint,
                anchorCollapse = awayIconSettings.anchorCollapse,
                anchorSpacing = awayIconSettings.anchorSpacing,
            });
        end
    end

    if (disconnectIconLoaded == true) then
        local disconnectTextureId = playerIndicators.GetDisconnectIconTextureId(center.index);
        if (disconnectTextureId ~= nil) then
            table.insert(icons, {
                kind = 'disconnectIcon',
                textureId = disconnectTextureId,
                size = tonumber(disconnectIconSettings.iconSize) or 16,
                offsetX = tonumber(disconnectIconSettings.offsetX) or 144,
                offsetY = tonumber(disconnectIconSettings.offsetY) or -54,
                anchorTo = disconnectIconSettings.anchorTo,
                anchorPoint = disconnectIconSettings.anchorPoint,
                anchorCollapse = disconnectIconSettings.anchorCollapse,
                anchorSpacing = disconnectIconSettings.anchorSpacing,
            });
        end
    end

    if (anonIconLoaded == true) then
        local anonTextureId = playerIndicators.GetAnonIconTextureId(center.index);
        if (anonTextureId ~= nil) then
            table.insert(icons, {
                kind = 'anonIcon',
                textureId = anonTextureId,
                size = tonumber(anonIconSettings.iconSize) or 16,
                offsetX = tonumber(anonIconSettings.offsetX) or -120,
                offsetY = tonumber(anonIconSettings.offsetY) or -54,
                anchorTo = anonIconSettings.anchorTo,
                anchorPoint = anonIconSettings.anchorPoint,
                anchorCollapse = anonIconSettings.anchorCollapse,
                anchorSpacing = anonIconSettings.anchorSpacing,
            });
        end
    end

    if (starsIconLoaded == true) then
        local starsTextureId = playerIndicators.GetStarsIconTextureId(center.index);
        if (starsTextureId ~= nil) then
            table.insert(icons, {
                kind = 'starsIcon',
                textureId = starsTextureId,
                size = tonumber(starsIconSettings.iconSize) or 16,
                offsetX = tonumber(starsIconSettings.offsetX) or -48,
                offsetY = tonumber(starsIconSettings.offsetY) or -54,
                anchorTo = starsIconSettings.anchorTo,
                anchorPoint = starsIconSettings.anchorPoint,
                anchorCollapse = starsIconSettings.anchorCollapse,
                anchorSpacing = starsIconSettings.anchorSpacing,
            });
        end
    end

    if (levelSyncIconLoaded == true and playerStatuses.HasSelfLevelSyncStatus() == true) then
        local levelSyncTextureId = playerIndicators.GetStaticIconTextureId('lvsync');
        if (levelSyncTextureId ~= nil) then
            table.insert(icons, {
                kind = 'levelSyncIcon',
                textureId = levelSyncTextureId,
                size = tonumber(levelSyncIconSettings.iconSize) or 16,
                offsetX = tonumber(levelSyncIconSettings.offsetX) or -24,
                offsetY = tonumber(levelSyncIconSettings.offsetY) or -54,
                anchorTo = levelSyncIconSettings.anchorTo,
                anchorPoint = levelSyncIconSettings.anchorPoint,
                anchorCollapse = levelSyncIconSettings.anchorCollapse,
                anchorSpacing = levelSyncIconSettings.anchorSpacing,
            });
        end
    end

    if (newAdventurerIconLoaded == true) then
        local newAdventurerTextureId = playerIndicators.GetNewAdventurerIconTextureId(center.index);
        if (newAdventurerTextureId ~= nil) then
            table.insert(icons, {
                kind = 'newAdventurerIcon',
                textureId = newAdventurerTextureId,
                size = tonumber(newAdventurerIconSettings.iconSize) or 16,
                offsetX = tonumber(newAdventurerIconSettings.offsetX) or 24,
                offsetY = tonumber(newAdventurerIconSettings.offsetY) or -54,
                anchorTo = newAdventurerIconSettings.anchorTo,
                anchorPoint = newAdventurerIconSettings.anchorPoint,
                anchorCollapse = newAdventurerIconSettings.anchorCollapse,
                anchorSpacing = newAdventurerIconSettings.anchorSpacing,
                anchorOrder = newAdventurerIconSettings.anchorOrder,
            });
        end
    end

    local castBar, castPercent = BuildCastBar(castData, castBarLoaded == true and castBarSettings or nil, globalSettings);
    local nameTextSize = nameAoeActive == true and math.max(tonumber(nameSettings.textSize) or nameDefaults.textSize, tonumber(aoeRangeSettings.fontSize) or aoeRangeDefaults.fontSize) or nameSettings.textSize;
    local nameColor = nameSettings.color or { 1.0, 1.0, 1.0, 1.0 };

    if (nativeUiPolicy.ShouldOverwriteNativeNameColors() ~= true) then
        if (playerIndicators.HasAnonNameColor(center.index) == true) then
            nameColor = playerIndicators.GetAnonNameColor();
        elseif (modeText == 'CW' or modeText == 'UCW') then
            nameColor = playerIndicators.GetCampaignNameColor();
        end
    end

    local nameStyleKey = table.concat({
        'aoe=' .. tostring(nameAoeActive == true),
        'size=' .. tostring(nameTextSize or ''),
        'color=' .. StableTableKey(nameAoeActive == true and aoeRangeSettings.fontColor or nameColor),
        'icon=' .. tostring(aoeRangeSettings.iconEnabled == true) .. ':' .. tostring(aoeRangeSettings.iconFile or '') .. ':' .. tostring(aoeRangeSettings.iconSize or '') .. ':' .. tostring(aoeRangeSettings.iconOffsetX or '') .. ':' .. tostring(aoeRangeSettings.iconOffsetY or ''),
    }, ';');
    local streamerNames = require('core.streamer_names');
    local displayName = streamerNames.GetSelfDisplayName(center.name, targeting.GetSettings());

    local plateData = {
        hp = hpPercent,
        mp = mpPercent,
        tp = tpPercent,
        cast = castPercent,
        targetMarker = targetMarker,
        background = {
            enabled = backgroundLoaded == true,
            width = tonumber(backgroundSettings.width) or backgroundDefaults.width,
            height = tonumber(backgroundSettings.height) or backgroundDefaults.height,
            offsetX = tonumber(backgroundSettings.offsetX) or backgroundDefaults.offsetX,
            offsetY = tonumber(backgroundSettings.offsetY) or backgroundDefaults.offsetY,
            color = backgroundSettings.color or backgroundDefaults.color,
            borderColor = backgroundSettings.borderColor or backgroundDefaults.borderColor,
            borderSize = tonumber(backgroundSettings.borderSize) or backgroundDefaults.borderSize,
            texture = backgroundSettings.texture or backgroundDefaults.texture,
            textureId = backgroundLoaded == true and backgroundTextures.GetTextureId(backgroundSettings.texture or backgroundDefaults.texture) or nil,
            imageOpacity = backgroundSettings.imageOpacity or backgroundDefaults.imageOpacity,
            anchorTo = backgroundSettings.anchorTo or backgroundDefaults.anchorTo,
            anchorPoint = backgroundSettings.anchorPoint or backgroundDefaults.anchorPoint,
            anchorCollapse = backgroundSettings.anchorCollapse,
            anchorSpacing = backgroundSettings.anchorSpacing,
        },
        name = nameEnabled and displayName or '',
        aoeNameActive = nameAoeActive == true,
        nameFontFamily = fonts.GetRole(globalSettings, false),
        nameFontFlags = fonts.GetRoleFlags(globalSettings, false),
        nameFontSize = textScale.ToNameTextureFontSize(nameTextSize, nameDefaults.textSize),
        nameColor = (nameAoeActive == true and aoeRangeSettings.fontColor) or nameColor,
        nameOutlineEnabled = (tonumber(nameSettings.outlineSize) or 0) > 0,
        nameOutlineColor = nameSettings.outlineColor or { 0.0, 0.0, 0.0, 1.0 },
        nameOutlineSize = tonumber(nameSettings.outlineSize) or 0,
        nameOffsetX = tonumber(nameSettings.offsetX) or 0,
        nameOffsetY = tonumber(nameSettings.offsetY) or defaultOffsetY,
        nameAnchorTo = nameSettings.anchorTo or nameDefaults.anchorTo,
        nameAnchorPoint = nameSettings.anchorPoint or nameDefaults.anchorPoint,
        nameAnchorCollapse = nameSettings.anchorCollapse,
        nameAnchorSpacing = nameSettings.anchorSpacing,
        hpBar = {
            enabled = hpBarLoaded == true,
            width = tonumber(hpBarSettings.width) or 180,
            height = tonumber(hpBarSettings.height) or 12,
            offsetX = tonumber(hpBarSettings.offsetX) or 0,
            offsetY = tonumber(hpBarSettings.offsetY) or 0,
            color = hpColor,
            backgroundColor = hpBarSettings.backgroundColor or { 0.05, 0.05, 0.05, 0.85 },
            borderColor = hpBarSettings.borderColor or { 0.0, 0.0, 0.0, 1.0 },
            borderSize = tonumber(hpBarSettings.borderSize) or 0,
            cornerRadius = tonumber(hpBarSettings.cornerRadius) or 0,
            anchorTo = hpBarSettings.anchorTo or barDefaults.anchorTo,
            anchorPoint = hpBarSettings.anchorPoint or barDefaults.anchorPoint,
            anchorCollapse = hpBarSettings.anchorCollapse,
            anchorSpacing = hpBarSettings.anchorSpacing,
            texture = hpBarSettings.texture or 'Solid',
            textureStrength = tonumber(hpBarSettings.textureStrength) or 100,
            textureId = hpBarLoaded == true and barTextures.GetTextureId(hpBarSettings.texture) or nil,
            animationEnabled = hpBarLoaded == true and hpCriticalActive == true and hpBarSettings.lowAnimationEnabled == true,
            animationTextureId = hpBarLoaded == true and hpCriticalActive == true and hpBarSettings.lowAnimationEnabled == true and barAnimations.GetTextureId(hpBarSettings.lowAnimation) or nil,
            animationSpeed = tonumber(hpBarSettings.lowAnimationSpeed) or 40,
            animationColor = hpBarSettings.lowAnimationColor,
            showAtPercent = tonumber(hpBarSettings.showAtPercent) or 100,
            text = hpBarLoaded == true and BuildResourceText(hpBarSettings, 'HP', center.hp, center.maxHp, hpPercent) or '',
            textOffsetX = tonumber(hpBarSettings.textOffsetX) or 0,
            textOffsetY = tonumber(hpBarSettings.textOffsetY) or 0,
            fontFamily = hpBarLoaded == true and fonts.GetRole(globalSettings, hpBarSettings.useSmallFont == true) or nil,
            fontFlags = hpBarLoaded == true and fonts.GetRoleFlags(globalSettings, hpBarSettings.useSmallFont == true) or nil,
            fontSize = textScale.ToTextureFontSize(hpBarSettings.fontSize, barDefaults.fontSize),
            textColor = hpBarSettings.textColor or { 1.0, 1.0, 1.0, 1.0 },
            textOutlineEnabled = hpBarSettings.textOutlineEnabled == true,
            textOutlineColor = hpBarSettings.textOutlineColor or { 0.0, 0.0, 0.0, 1.0 },
            textOutlineSize = tonumber(hpBarSettings.textOutlineSize) or 1,
        },
        mpBar = {
            enabled = mpBarLoaded == true,
            width = tonumber(mpBarSettings.width) or 180,
            height = tonumber(mpBarSettings.height) or 8,
            offsetX = tonumber(mpBarSettings.offsetX) or 0,
            offsetY = tonumber(mpBarSettings.offsetY) or 16,
            color = mpColor,
            backgroundColor = mpBarSettings.backgroundColor or { 0.05, 0.05, 0.05, 0.85 },
            borderColor = mpBarSettings.borderColor or { 0.0, 0.0, 0.0, 1.0 },
            borderSize = tonumber(mpBarSettings.borderSize) or 0,
            cornerRadius = tonumber(mpBarSettings.cornerRadius) or 0,
            anchorTo = mpBarSettings.anchorTo or mpBarDefaults.anchorTo,
            anchorPoint = mpBarSettings.anchorPoint or mpBarDefaults.anchorPoint,
            anchorCollapse = mpBarSettings.anchorCollapse,
            anchorSpacing = mpBarSettings.anchorSpacing,
            texture = mpBarSettings.texture or 'Solid',
            textureStrength = tonumber(mpBarSettings.textureStrength) or 100,
            textureId = mpBarLoaded == true and barTextures.GetTextureId(mpBarSettings.texture) or nil,
            animationEnabled = mpBarLoaded == true and mpLowActive == true and mpBarSettings.lowAnimationEnabled == true,
            animationTextureId = mpBarLoaded == true and mpLowActive == true and mpBarSettings.lowAnimationEnabled == true and barAnimations.GetTextureId(mpBarSettings.lowAnimation) or nil,
            animationSpeed = tonumber(mpBarSettings.lowAnimationSpeed) or 40,
            animationColor = mpBarSettings.lowAnimationColor,
            showAtPercent = tonumber(mpBarSettings.showAtPercent) or 100,
            text = mpBarLoaded == true and BuildResourceText(mpBarSettings, 'MP', center.mp, center.maxMp, mpPercent) or '',
            textOffsetX = tonumber(mpBarSettings.textOffsetX) or 0,
            textOffsetY = tonumber(mpBarSettings.textOffsetY) or 0,
            fontFamily = mpBarLoaded == true and fonts.GetRole(globalSettings, mpBarSettings.useSmallFont == true) or nil,
            fontFlags = mpBarLoaded == true and fonts.GetRoleFlags(globalSettings, mpBarSettings.useSmallFont == true) or nil,
            fontSize = textScale.ToTextureFontSize(mpBarSettings.fontSize, mpBarDefaults.fontSize),
            textColor = mpBarSettings.textColor or { 1.0, 1.0, 1.0, 1.0 },
            textOutlineEnabled = mpBarSettings.textOutlineEnabled == true,
            textOutlineColor = mpBarSettings.textOutlineColor or { 0.0, 0.0, 0.0, 1.0 },
            textOutlineSize = tonumber(mpBarSettings.textOutlineSize) or 1,
        },
        tpBar = {
            enabled = tpBarLoaded == true,
            width = tonumber(tpBarSettings.width) or 180,
            height = tonumber(tpBarSettings.height) or 6,
            offsetX = tonumber(tpBarSettings.offsetX) or 0,
            offsetY = tonumber(tpBarSettings.offsetY) or 28,
            color = tpColor,
            backgroundColor = tpBarSettings.backgroundColor or { 0.05, 0.05, 0.05, 0.85 },
            borderColor = tpBarSettings.borderColor or { 0.0, 0.0, 0.0, 1.0 },
            borderSize = tonumber(tpBarSettings.borderSize) or 0,
            cornerRadius = tonumber(tpBarSettings.cornerRadius) or 0,
            anchorTo = tpBarSettings.anchorTo or tpBarDefaults.anchorTo,
            anchorPoint = tpBarSettings.anchorPoint or tpBarDefaults.anchorPoint,
            anchorCollapse = tpBarSettings.anchorCollapse,
            anchorSpacing = tpBarSettings.anchorSpacing,
            texture = tpBarSettings.texture or 'Solid',
            textureStrength = tonumber(tpBarSettings.textureStrength) or 100,
            textureId = tpBarLoaded == true and barTextures.GetTextureId(tpBarSettings.texture) or nil,
            color2 = tpColor2,
            color3 = tpColor3,
            showAtPercent = tonumber(tpBarSettings.showAtPercent) or tonumber(tpBarDefaults.showAtPercent) or 300,
            segmented = tpBarSettings.segmented ~= false,
            segmentGap = tonumber(tpBarSettings.segmentGap) or 3,
            text = tpBarLoaded == true and BuildResourceText(tpBarSettings, 'TP', tpValue, 3000, tpPercent) or '',
            textOffsetX = tonumber(tpBarSettings.textOffsetX) or 0,
            textOffsetY = tonumber(tpBarSettings.textOffsetY) or 0,
            fontFamily = tpBarLoaded == true and fonts.GetRole(globalSettings, tpBarSettings.useSmallFont == true) or nil,
            fontFlags = tpBarLoaded == true and fonts.GetRoleFlags(globalSettings, tpBarSettings.useSmallFont == true) or nil,
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
            { kind = 'anonIcon', settings = anonIconSettings, defaults = anonIconDefaults, defaultX = -120, defaultY = -54 },
            { kind = 'starsIcon', settings = starsIconSettings, defaults = starsIconDefaults, defaultX = -48, defaultY = -54 },
            { kind = 'levelSyncIcon', settings = levelSyncIconSettings, defaults = levelSyncIconDefaults, defaultX = -24, defaultY = -54 },
            { kind = 'newAdventurerIcon', settings = newAdventurerIconSettings, defaults = newAdventurerIconDefaults, defaultX = 24, defaultY = -54 },
        }),
    };

    if (plateData.aoeNameActive == true) then
        aoeRangeVisuals.Apply(plateData, aoeRangeSettings, hpBarSettings);
    end

    plateData.debugClickRects = worldMarkerProbe.GetClickDebug();
    plateData.debugClickRectColor = 0x01FFD400;

    if (shouldLoadBuffs == true) then
        AddStatusIconsToPlate(plateData, playerStatuses.GetSelfRows('buff'), buffsSettings, isEngaged, globalSettings, 'buffs');
    end

    if (shouldLoadDebuffs == true) then
        AddStatusIconsToPlate(plateData, playerStatuses.GetSelfRows('debuff'), debuffsSettings, isEngaged, globalSettings, 'debuffs');
    end

    if (enmityActive == true) then
        enmity.AddIcon(plateData, globalSettings.enmity, 'ally');
    end

    if (fishingActive ~= true) then
        fishing.ClearResult();
    end

    if (gatheringActive == true) then
        gathering.AddWidget(plateData, globalSettings.gathering or globalDefaults.gathering);
    end

    if (craftingActive == true) then
        crafting.AddWidget(plateData, globalSettings.crafting);
    elseif (crafting.IsCraftingStatus(center.status) ~= true) then
        crafting.ClearResult();
    end

    if (restingActive == true and LibraPlatesSelfShouldDrawRestingWidget(center, restingActive) == true) then
        local currentMp = tonumber(center.mp);
        local maxMp = tonumber(center.maxMp) or 0;
        local mpIsFull = mpPercent >= 100 or (currentMp ~= nil and maxMp > 0 and currentMp >= maxMp);
        local logoutActive = restingTick.IsLogoutActive(restingSettings);
        local hideAtFullHp = restingSettings.hideAtFullHp == true and hpPercent >= 100;
        local hideAtFullMp = restingSettings.hideAtFullMp == true and mpIsFull == true;
        local shouldHideResting = false;
        local tick = nil;

        if (restingSettings.hideAtFullHp == true and restingSettings.hideAtFullMp == true) then
            shouldHideResting = hideAtFullHp == true and hideAtFullMp == true;
        else
            shouldHideResting = hideAtFullHp == true or hideAtFullMp == true;
        end

        if (logoutActive == true or shouldHideResting ~= true) then
            tick = restingTick.Get(center.status, center.hp, center.mp, center.maxMp, restingSettings);
        else
            restingTick.Reset();
        end

        if ((logoutActive == true or shouldHideResting ~= true) and tick ~= nil) then
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
                anchorCollapse = restingSettings.anchorCollapse,
                anchorSpacing = restingSettings.anchorSpacing,
                color = restingSettings.color or { 0.55, 0.95, 0.35, 1.0 },
                backgroundColor = restingSettings.backgroundColor or { 0.10, 0.10, 0.10, 1.0 },
                borderColor = restingSettings.borderColor or { 1.0, 1.0, 1.0, 1.0 },
                borderSize = tonumber(restingSettings.borderSize) or 0,
                textureId = barTextures.GetTextureId(restingSettings.texture or 'Solid'),
                text = tick.text,
                textOffsetX = tonumber(restingSettings.textOffsetX) or 0,
                textOffsetY = tonumber(restingSettings.textOffsetY) or 0,
                fontFamily = fonts.GetRole(globalSettings, true),
                fontFlags = fonts.GetRoleFlags(globalSettings, true),
                fontSize = textScale.ToTextureFontSize(restingSettings.fontSize, 12),
                textColor = restingSettings.textColor or { 0.0, 0.0, 0.0, 1.0 },
                textOutlineEnabled = restingSettings.textOutlineEnabled == true,
                textOutlineColor = restingSettings.textOutlineColor or { 1.0, 1.0, 1.0, 1.0 },
                textOutlineSize = tonumber(restingSettings.textOutlineSize) or 1,
            };

            if (tick.countdown == true and tick.label ~= nil) then
                plateData.texts = plateData.texts or {};
                plateData.texts[#plateData.texts + 1] = {
                    kind = 'restingCountdownText',
                    text = tostring(tick.label or ''),
                    offsetX = tonumber(restingSettings.countdownTextOffsetX) or 0,
                    offsetY = tonumber(restingSettings.countdownTextOffsetY) or 0,
                    align = 'center',
                    fontFamily = fonts.GetRole(globalSettings, true),
                    fontFlags = fonts.GetRoleFlags(globalSettings, true),
                    fontSize = textScale.ToTextureFontSize(restingSettings.countdownFontSize, 12),
                    color = restingSettings.countdownTextColor or { 1.0, 0.84, 0.0, 1.0 },
                    outlineEnabled = restingSettings.countdownTextOutlineEnabled ~= false,
                    outlineColor = restingSettings.countdownTextOutlineColor or { 0.0, 0.0, 0.0, 1.0 },
                    outlineSize = tonumber(restingSettings.countdownTextOutlineSize) or 2,
                };
            end
        end
    elseif (restingActive ~= true) then
        LibraPlatesSelfShouldDrawRestingWidget(nil, false);
        if (restingTick.ShouldPreserveLogoutTransition() == true) then
            restingTick.Reset();
        else
            restingTick.ResetAll();
        end
    end

    local function HasActiveBarAnimation(bar)
        return bar ~= nil and bar.animationEnabled == true;
    end

    local animatedBarActive =
        HasActiveBarAnimation(plateData.hpBar) or
        HasActiveBarAnimation(plateData.mpBar) or
        HasActiveBarAnimation(plateData.tpBar) or
        HasActiveBarAnimation(plateData.castBar);

    if (animatedBarActive ~= true) then
        for _, extraBar in ipairs(plateData.extraBars or {}) do
            if (HasActiveBarAnimation(extraBar) == true) then
                animatedBarActive = true;
                break;
            end
        end
    end

    -- The enmity icon is already represented by the world-plate signature.
    -- Only the continuously animated bar needs to bypass the static cache.
    local cacheEligible = animatedBarActive ~= true;
    local signature = nil;
    local vitalSignature = nil;
    local cacheKey = GetWorldCacheKey(stateName, targetStateName, layoutStateName, plateData.canvasWidth ~= nil);
    local cachedWorldPlate = cachedWorldPlates[cacheKey];

    if (cacheEligible == true) then
        signature = BuildWorldCacheSignature(plateData, center, stateName, targetStateName, layoutStateName, globalSettings, aoeRangeSettings);
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

        if (
            cachedWorldPlate ~= nil and
            cachedWorldPlate.signature == signature and
            cachedWorldPlate.vitalSignature == vitalSignature and
            canvasTexture.TouchTextureForKey(
                cachedWorldPlate.textureKey,
                cachedWorldPlate.plateTextureId
            ) == true
        ) then
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

        perfMeter.Count('self.cache.miss', 1);
    else
        perfMeter.Count('self.cache.skip', 1);
    end

    local renderTextureKey = GetWorldTextureKey(cacheKey);
    local plateTexture, textureWidth, textureHeight = canvasTexture.Render(plateData, renderTextureKey);
    local plateTextureId = canvasTexture.GetTextureId(plateTexture);
    local plateClickRects = plateData._elementRects or canvasTexture.GetElementRects(plateData);

    if (plateTextureId == nil) then
        cachedWorldPlates[cacheKey] = nil;
        return;
    end

    if (cacheEligible == true and signature ~= nil) then
        cachedWorldPlates[cacheKey] = {
            signature = signature,
            vitalSignature = vitalSignature,
            textureKey = renderTextureKey,
            lastUsed = os.clock(),
            plateTextureId = plateTextureId,
            textureWidth = textureWidth,
            textureHeight = textureHeight,
            plateClickRects = plateClickRects,
        };
        TrimWorldPlateCache();
    else
        cachedWorldPlates[cacheKey] = nil;
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

    if (center.visibleSkeleton ~= true) then
        return;
    end

    if (IsBadSelfTransitionCenter(center) == true) then
        return;
    end

    local stateName = GetLiveSelfStateName(center);
    local layoutStateName = GetLayoutStateName(stateName);
    local isEngaged = tonumber(center.status) == 1;
    local nameSettings = state.GetWidgetSettings('Self', layoutStateName, 'Name', nameDefaults);
    local backgroundSettings = state.GetWidgetSettings('Self', layoutStateName, 'Background', backgroundDefaults);

    if (stateName ~= 'Fishing' and fishing.IsSessionActive() ~= true) then
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

    DrawBackground(drawList, bounds, backgroundSettings, isEngaged);

    if (nativeUiPolicy.ShouldDrawLibraNames() == true) then
        local streamerNames = require('core.streamer_names');
        local displayName = streamerNames.GetSelfDisplayName(center.name, targeting.GetSettings());
        widgets.name.Draw({ name = displayName }, BuildAoeNameSettings(layoutStateName, nameSettings, center.index), {
            drawList = drawList,
            bounds = bounds,
            canvas = canvas,
        });
    end
end

return selfPlate;
