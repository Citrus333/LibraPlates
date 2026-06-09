local nameDefaults = require('config.widgets.name');
local backgroundDefaults = require('config.widgets.background');
local barDefaults = require('config.widgets.bar');
local mpBarDefaults = require('config.widgets.mp_bar');
local tpBarDefaults = require('config.widgets.tp_bar');
local jobDefaults = require('config.widgets.job');
local levelDefaults = require('config.widgets.level');
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
local distanceDefaults = require('config.widgets.distance');
local globalDefaults = require('config.global');
local fonts = require('core.fonts');
local textScale = require('core.text_scale');
local canvasTexture = require('core.canvas_texture');
local barTextures = require('core.bar_textures');
local barAnimations = require('core.bar_animations');
local textureLoader = require('core.texture_loader');
local statusIconTextures = require('core.status_icon_textures');
local statusTimerFormat = require('core.status_timer_format');
local jobIconTextures = require('core.job_icon_textures');
local entities = require('core.entities');
local gameMode = require('core.game_mode');
local playerIndicators = require('core.player_indicators');
local perfMeter = require('core.perf_meter');
local state = require('core.state');
local targetModuleMarker = require('core.target_module_marker');
local targeting = require('core.targeting');
local enmity = require('core.enmity');
local partyStatuses = require('core.party_statuses');
local worldDepthPlate = require('core.world_depth_plate');
local worldMarkerProbe = require('core.world_marker_probe');

pcall(require, 'common');

local pcPlate = {};
local plateCache = {};
local indexCache = {};
local maxPlateCacheEntries = 64;
local lastPlateCacheTrim = 0;
local scanCache = {
    clock = 0,
    range = nil,
    players = nil,
};
local staffPlayers = {};
local staffIconTextureIds = {};
local mountedPlateLift = 1.05;
local idleScanCacheSeconds = 0.20;
local idleDirectDynamicCacheSeconds = 0.35;
local idleDirectStaticCacheSeconds = 2.00;
local jobAbbreviations = {
    [1] = 'WAR',
    [2] = 'MNK',
    [3] = 'WHM',
    [4] = 'BLM',
    [5] = 'RDM',
    [6] = 'THF',
    [7] = 'PLD',
    [8] = 'DRK',
    [9] = 'BST',
    [10] = 'BRD',
    [11] = 'RNG',
    [12] = 'SAM',
    [13] = 'NIN',
    [14] = 'DRG',
    [15] = 'SMN',
    [16] = 'BLU',
    [17] = 'COR',
    [18] = 'PUP',
    [19] = 'DNC',
    [20] = 'SCH',
    [21] = 'GEO',
    [22] = 'RUN',
};

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

local function FormatDistanceText(settings, distance)
    return tostring(settings ~= nil and settings.prefix or '') .. string.format('%.1f', tonumber(distance) or 0);
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

local function GetJobText(jobId)
    jobId = tonumber(jobId);

    if (jobId == nil or jobId <= 0) then
        return '';
    end

    local text = nil;

    pcall(function()
        text = AshitaCore:GetResourceManager():GetString('jobs.names_abbr', jobId);
    end);

    text = tostring(text or '');

    if (text == '' or text == 'nil') then
        text = jobAbbreviations[jobId] or '';
    end

    return text;
end

local function AddJobToPlate(plateData, jobText, jobSettings, globalSettings)
    if (jobSettings == nil or jobSettings.enabled ~= true or jobText == nil or tostring(jobText) == '') then
        return;
    end

    if ((tonumber(jobSettings.displayModeIndex) or 1) == 2) then
        local textureId = jobIconTextures.GetTextureId(jobText, jobSettings.iconTheme);

        if (textureId ~= nil) then
            plateData.icons = plateData.icons or {};
            plateData.icons[#plateData.icons + 1] = {
                kind = 'job',
                textureId = textureId,
                size = math.max(8, math.min(160, tonumber(jobSettings.iconSize) or 16)),
                offsetX = tonumber(jobSettings.offsetX) or 0,
                offsetY = tonumber(jobSettings.offsetY) or -54,
                anchorTo = jobSettings.anchorTo or jobDefaults.anchorTo,
                anchorPoint = jobSettings.anchorPoint or jobDefaults.anchorPoint,
            };

            return;
        end
    end

    plateData.jobText = tostring(jobText);
    plateData.jobFontFamily = fonts.GetRole(globalSettings, true);
    plateData.jobFontFlags = fonts.GetRoleFlags(globalSettings, true);
    plateData.jobFontSize = textScale.ToTextureFontSize(jobSettings.textSize, jobDefaults.textSize);
    plateData.jobColor = jobSettings.color or jobDefaults.color;
    plateData.jobOutlineEnabled = jobSettings.outlineEnabled == true;
    plateData.jobOutlineColor = jobSettings.outlineColor or jobDefaults.outlineColor;
    plateData.jobOutlineSize = tonumber(jobSettings.outlineSize) or jobDefaults.outlineSize;
    plateData.jobOffsetX = tonumber(jobSettings.offsetX) or 0;
    plateData.jobOffsetY = tonumber(jobSettings.offsetY) or -54;
    plateData.jobAnchorTo = jobSettings.anchorTo or jobDefaults.anchorTo;
    plateData.jobAnchorPoint = jobSettings.anchorPoint or jobDefaults.anchorPoint;
end

local function AddIcon(icons, settings, textureId, defaultX, defaultY, kind)
    if (settings == nil or settings.enabled ~= true or textureId == nil) then
        return;
    end

    icons[#icons + 1] = {
        kind = kind,
        textureId = textureId,
        size = tonumber(settings.iconSize) or 16,
        offsetX = tonumber(settings.offsetX) or defaultX,
        offsetY = tonumber(settings.offsetY) or defaultY,
        anchorTo = settings.anchorTo,
        anchorPoint = settings.anchorPoint,
    };
end

local function LoadStaffPlayers()
    local ok, data = pcall(require, 'data.staff_players');

    if (ok == true and type(data) == 'table') then
        staffPlayers = data;
    end
end

local function GetStaffInfo(name, serverId)
    if (type(staffPlayers.serverIds) == 'table') then
        local id = tonumber(serverId);

        if (id ~= nil and staffPlayers.serverIds[id] ~= nil) then
            return staffPlayers.serverIds[id];
        end
    end

    if (type(staffPlayers.names) == 'table') then
        return staffPlayers.names[tostring(name or '')];
    end

    return staffPlayers[tostring(name or '')];
end

local function ResolveStaffInfo(player)
    if (playerIndicators.IsGameMaster(player.index) == true) then
        return { type = 'GM', icon = 'GM.png', source = 'native' };
    end

    return GetStaffInfo(player.name, player.serverId);
end

local function GetAddonRoot()
    if (AshitaCore ~= nil and AshitaCore.GetInstallPath ~= nil) then
        return AshitaCore:GetInstallPath() .. '\\addons\\LibraPlates\\';
    end

    return '';
end

local function GetStaffIconTextureId(iconFile)
    local fileName = tostring(iconFile or '');

    if (fileName == '') then
        return nil;
    end

    if (staffIconTextureIds[fileName] ~= nil) then
        return staffIconTextureIds[fileName];
    end

    local path = GetAddonRoot() .. 'assets\\images\\staff\\' .. fileName:gsub('/', '\\');
    staffIconTextureIds[fileName] = textureLoader.ToTextureId(textureLoader.Load(path));
    return staffIconTextureIds[fileName];
end

LoadStaffPlayers();

local function AddTextBadge(plateData, kind, text, settings, defaults, globalSettings)
    if (settings == nil or settings.enabled ~= true or text == nil or tostring(text) == '') then
        return;
    end

    plateData.badges = plateData.badges or {};
    plateData.badges[#plateData.badges + 1] = {
        kind = kind,
        text = tostring(text),
        offsetX = tonumber(settings.offsetX) or defaults.offsetX,
        offsetY = tonumber(settings.offsetY) or defaults.offsetY,
        fontFamily = fonts.GetRole(globalSettings, settings.useSmallFont == true),
        fontFlags = fonts.GetRoleFlags(globalSettings, settings.useSmallFont == true),
        fontSize = textScale.ToTextureFontSize(settings.textSize, defaults.textSize),
        textColor = settings.color or defaults.color,
        textOutlineEnabled = settings.outlineEnabled == true,
        textOutlineColor = settings.outlineColor or defaults.outlineColor,
        textOutlineSize = tonumber(settings.outlineSize) or defaults.outlineSize,
        anchorTo = settings.anchorTo or defaults.anchorTo,
        anchorPoint = settings.anchorPoint or defaults.anchorPoint,
        backgroundEnabled = false,
    };
end

local function AddStatusIconsToPlate(plateData, statusRows, iconSettings, isEngaged, globalSettings, kind)
    if (
        iconSettings == nil or
        iconSettings.enabled ~= true or
        (iconSettings.hideOutOfCombat == true and isEngaged ~= true) or
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

local function ShortenName(name, maxLength)
    local text = tostring(name or '');
    local limit = tonumber(maxLength) or 0;

    if (limit > 0 and string.len(text) > limit) then
        return string.sub(text, 1, limit);
    end

    return text;
end

local pcSocialLoadDefaults = {
    ['Job'] = 'Out of combat',
    ['Level'] = 'Out of combat',
    ['Distance'] = 'Out of combat',
    ['Game mode icon'] = 'Out of combat',
    ['Linkshell icon'] = 'Out of combat',
    ['Bazaar icon'] = 'Out of combat',
    ['Away icon'] = 'Out of combat',
    ['Disconnect icon'] = 'Out of combat',
    ['Stars icon'] = 'Out of combat',
    ['New adventurer icon'] = 'Out of combat',
};

local currentPlayerEngaged = false;

local function NormalizeLoadMode(value, fallback)
    local mode = tostring(value or fallback or 'Always');

    if (mode == 'OutOfCombat') then return 'Out of combat'; end
    if (mode == 'InCombat') then return 'In combat'; end
    if (mode == 'Out of combat' or mode == 'In combat' or mode == 'Never') then return mode; end

    return 'Always';
end

local function WidgetLoads(settings, widgetName)
    if (settings == nil or settings.enabled ~= true) then
        return false;
    end

    local mode = NormalizeLoadMode(settings.loadMode, pcSocialLoadDefaults[tostring(widgetName or '')] or 'Always');

    if (mode == 'Never') then
        return false;
    end

    if (mode == 'Out of combat') then
        return currentPlayerEngaged ~= true;
    end

    if (mode == 'In combat') then
        return currentPlayerEngaged == true;
    end

    return true;
end

local function ShouldLoadStatusRows(settings, widgetName, isEngaged)
    if (WidgetLoads(settings, widgetName) ~= true) then
        return false;
    end

    if (settings.hideOutOfCombat == true and isEngaged ~= true) then
        return false;
    end

    return true;
end

local function QueueCachedPlayer(player, cached, targetStateName, useTargetOverlay, layoutStateName, hasHp, hasMp, hasTp, hpPercent, mpPercent, tpValue)
    if (cached == nil or cached.texture == nil) then
        return false;
    end

    TouchPlateCacheEntry(cached);

    local plateTextureId = canvasTexture.GetTextureId(cached.texture);

    if (plateTextureId == nil) then
        return false;
    end

    local queueTimer = perfMeter.BeginDetail('pc.queue');
    local targetingSettings = targeting.GetSettings();

    worldMarkerProbe.QueuePlate({
        targetIndex = player.index,
        serverId = player.serverId,
        distance = player.distance,
        hp = hasHp == true and hpPercent or 100,
        mp = hasMp == true and mpPercent or nil,
        tp = hasTp == true and tpValue or nil,
        name = '',
        isSelf = false,
        stateName = targetStateName,
        clickTargetType = 'pc',
        worldMarker = {
            hpBar = { enabled = false },
            plateTextureId = plateTextureId,
            plateAlwaysOnTop = useTargetOverlay == true,
            plateTacticalOverlayOnly = useTargetOverlay == true,
            plateWorldWidth = 2.35,
            plateWorldHeight = 1.18,
            plateWorldOffsetY = cached.plateWorldOffsetY,
            plateDistanceScaleStart = tonumber(targetingSettings.pcDistanceScaleStart) or 2.0,
            plateDistanceScaleEnd = tonumber(targetingSettings.pcDistanceScaleEnd) or 8.0,
            plateDistanceScaleMax = tonumber(targetingSettings.pcDistanceScaleMax) or 2.65,
            plateDistanceScaleOffsetY = 0.28,
            plateTextureWidth = cached.textureWidth,
            plateTextureHeight = cached.textureHeight,
            plateClickRects = cached.elementRects,
            clickTargetType = 'pc',
            clickName = player.name,
            layoutStateName = layoutStateName,
        },
    });
    perfMeter.EndDetail(queueTimer);

    return true;
end

local function QueueFreshIdleCache(player, targetStateName, useTargetOverlay, layoutStateName, hasHp, hasMp, hasTp, hpPercent, mpPercent, tpValue)
    if (targetStateName ~= 'Idle' or useTargetOverlay == true or state.GetConfigOpen() == true) then
        return false;
    end

    local indexed = indexCache[tonumber(player.index) or 0];

    if (indexed == nil) then
        return false;
    end

    local cached = plateCache[indexed.cacheKey];

    if (cached == nil or cached.texture == nil) then
        return false;
    end

    local now = os.clock();
    local lastRefresh = tonumber(cached.lastFullRefresh) or 0;
    local maxAge = cached.hasDynamicVisuals == true and idleDirectDynamicCacheSeconds or idleDirectStaticCacheSeconds;

    if ((now - lastRefresh) >= maxAge) then
        return false;
    end

    if (QueueCachedPlayer(player, cached, targetStateName, useTargetOverlay, layoutStateName, hasHp, hasMp, hasTp, hpPercent, mpPercent, tpValue) == true) then
        perfMeter.Count('pc.cache.directHit', 1);
        return true;
    end

    return false;
end

local function QueuePlayer(player)
    local targetStateName = targeting.GetTargetStateName(player.index);

    local isPartyPlayer = tonumber(player.slot) ~= nil;
    local isTargetContext = targetStateName ~= 'Idle';
    local isTacticalPlayer = isPartyPlayer == true or isTargetContext == true;
    local useTargetOverlay = isTacticalPlayer == true or targetStateName ~= 'Idle';
    local layoutStateName = useTargetOverlay == true and 'Combat' or 'Idle';
    local hasHp = player.hpPercent ~= nil or (player.hp ~= nil and player.maxHp ~= nil and tonumber(player.maxHp) > 0);
    local hasMp = layoutStateName == 'Combat' and (player.mpPercent ~= nil or (player.mp ~= nil and player.maxMp ~= nil and tonumber(player.maxMp) > 0));
    local hasTp = layoutStateName == 'Combat' and player.tp ~= nil;
    local hpPercent = ClampPercent(player.hpPercent, 100);
    local mpPercent = ClampPercent(player.mpPercent, 100);
    local tpValue = ClampTp(player.tp);

    if (QueueFreshIdleCache(player, targetStateName, useTargetOverlay, layoutStateName, hasHp, hasMp, hasTp, hpPercent, mpPercent, tpValue) == true) then
        return;
    end

    local settingsTimer = perfMeter.BeginDetail('pc.settings');
    local backgroundSettings = state.GetWidgetSettings('PC', layoutStateName, 'Background', backgroundDefaults);
    local nameSettings = state.GetWidgetSettings('PC', layoutStateName, 'Name', nameDefaults);
    local distanceSettings = state.GetWidgetSettings('PC', layoutStateName, 'Distance', distanceDefaults);
    local hpBarSettings = state.GetWidgetSettings('PC', layoutStateName, 'HP Bar', barDefaults);
    local mpBarSettings = state.GetWidgetSettings('PC', layoutStateName, 'MP Bar', mpBarDefaults);
    local tpBarSettings = state.GetWidgetSettings('PC', layoutStateName, 'TP Bar', tpBarDefaults);
    local jobSettings = state.GetWidgetSettings('PC', layoutStateName, 'Job', jobDefaults);
    local levelSettings = state.GetWidgetSettings('PC', layoutStateName, 'Level', levelDefaults);
    local buffsSettings = state.GetWidgetSettings('PC', layoutStateName, 'Buffs', buffsDefaults);
    local debuffsSettings = state.GetWidgetSettings('PC', layoutStateName, 'Debuffs', debuffsDefaults);
    local gameModeIconSettings = state.GetWidgetSettings('PC', layoutStateName, 'Game mode icon', gameModeIconDefaults);
    local partyLeaderIconSettings = state.GetWidgetSettings('PC', layoutStateName, 'Party leader icon', partyLeaderIconDefaults);
    local allianceLeaderIconSettings = state.GetWidgetSettings('PC', layoutStateName, 'Alliance leader icon', allianceLeaderIconDefaults);
    local linkshellIconSettings = state.GetWidgetSettings('PC', layoutStateName, 'Linkshell icon', linkshellIconDefaults);
    local bazaarIconSettings = state.GetWidgetSettings('PC', layoutStateName, 'Bazaar icon', bazaarIconDefaults);
    local awayIconSettings = state.GetWidgetSettings('PC', layoutStateName, 'Away icon', awayIconDefaults);
    local disconnectIconSettings = state.GetWidgetSettings('PC', layoutStateName, 'Disconnect icon', disconnectIconDefaults);
    local starsIconSettings = state.GetWidgetSettings('PC', layoutStateName, 'Stars icon', starsIconDefaults);
    local newAdventurerIconSettings = state.GetWidgetSettings('PC', layoutStateName, 'New adventurer icon', newAdventurerIconDefaults);
    local targetMarker = targetStateName ~= 'Idle'
        and targetModuleMarker.Build('PC', layoutStateName, targetStateName, hpBarSettings, player.distance)
        or { enabled = false };

    local globalSettings = state.GetGlobalSettings(globalDefaults);
    local tpPercent = tpValue / 10;
    local hpColor = hpBarSettings.color or { 0.90, 0.20, 0.20, 1.0 };
    local mpColor = mpBarSettings.color or { 0.20, 0.45, 0.95, 1.0 };
    local tpColor = tpBarSettings.color or { 0.95, 0.55, 0.05, 1.0 };
    local icons = {};
    local nameLoads = WidgetLoads(nameSettings, 'Name');
    local backgroundLoads = WidgetLoads(backgroundSettings, 'Background');
    local hpBarLoads = hasHp == true and WidgetLoads(hpBarSettings, 'HP Bar');
    local mpBarLoads = hasMp == true and WidgetLoads(mpBarSettings, 'MP Bar');
    local tpBarLoads = hasTp == true and WidgetLoads(tpBarSettings, 'TP Bar');
    local hpAnimationEnabled = hpBarLoads == true and hpBarSettings.lowColorEnabled == true and hpPercent <= (tonumber(hpBarSettings.lowColorPercent) or 25) and hpBarSettings.lowAnimationEnabled == true;
    local mpAnimationEnabled = mpBarLoads == true and mpBarSettings.lowColorEnabled == true and mpPercent <= (tonumber(mpBarSettings.lowColorPercent) or 25) and mpBarSettings.lowAnimationEnabled == true;
    perfMeter.EndDetail(settingsTimer);

    if (hpBarSettings.lowColorEnabled == true and hpPercent <= (tonumber(hpBarSettings.lowColorPercent) or 25)) then
        hpColor = hpBarSettings.lowColor or hpColor;
    end

    if (mpBarSettings.lowColorEnabled == true and mpPercent <= (tonumber(mpBarSettings.lowColorPercent) or 25)) then
        mpColor = mpBarSettings.lowColor or mpColor;
    end

    if (tpBarSettings.lowColorEnabled == true and tpPercent <= (tonumber(tpBarSettings.lowColorPercent) or 25)) then
        tpColor = tpBarSettings.lowColor or tpColor;
    end

    local iconsTimer = perfMeter.BeginDetail('pc.icons');
    local gameModeIconTextureId = nil;
    local linkshellIconTextureId = nil;
    local bazaarIconTextureId = nil;
    local awayIconTextureId = nil;
    local disconnectIconTextureId = nil;
    local starsIconTextureId = nil;
    local newAdventurerIconTextureId = nil;
    local allianceLeaderIconTextureId = nil;
    local partyLeaderIconTextureId = nil;
    local staffInfo = ResolveStaffInfo(player);
    local staffIconTextureId = nil;

    if (staffInfo ~= nil) then
        staffIconTextureId = GetStaffIconTextureId(staffInfo.icon);
        AddIcon(icons, { enabled = true, iconSize = 28, offsetX = -42, offsetY = -78 }, staffIconTextureId, -42, -78, 'staffIcon');
    end

    if (WidgetLoads(gameModeIconSettings, 'Game mode icon') == true) then
        gameModeIconTextureId = gameMode.GetIconTextureId(gameMode.Resolve(player.index, false));
        AddIcon(icons, gameModeIconSettings, gameModeIconTextureId, -72, -54, 'gameModeIcon');
    end

    if (WidgetLoads(linkshellIconSettings, 'Linkshell icon') == true) then
        linkshellIconTextureId = playerIndicators.GetLinkshellIconTextureId(player.index);
        AddIcon(icons, linkshellIconSettings, linkshellIconTextureId, 48, -54, 'linkshellIcon');
    end

    if (WidgetLoads(bazaarIconSettings, 'Bazaar icon') == true) then
        bazaarIconTextureId = playerIndicators.GetBazaarIconTextureId(player.index);
        AddIcon(icons, bazaarIconSettings, bazaarIconTextureId, 72, -54, 'bazaarIcon');
    end

    if (WidgetLoads(awayIconSettings, 'Away icon') == true) then
        awayIconTextureId = playerIndicators.GetAwayIconTextureId(player.index);
        AddIcon(icons, awayIconSettings, awayIconTextureId, 120, -54, 'awayIcon');
    end

    if (WidgetLoads(disconnectIconSettings, 'Disconnect icon') == true) then
        disconnectIconTextureId = playerIndicators.GetDisconnectIconTextureId(player.index);
        AddIcon(icons, disconnectIconSettings, disconnectIconTextureId, 144, -54, 'disconnectIcon');
    end

    if (WidgetLoads(starsIconSettings, 'Stars icon') == true) then
        starsIconTextureId = playerIndicators.GetStarsIconTextureId(player.index);
        AddIcon(icons, starsIconSettings, starsIconTextureId, -48, -54, 'starsIcon');
    end

    if (WidgetLoads(newAdventurerIconSettings, 'New adventurer icon') == true) then
        newAdventurerIconTextureId = playerIndicators.GetNewAdventurerIconTextureId(player.index);
        AddIcon(icons, newAdventurerIconSettings, newAdventurerIconTextureId, 24, -54, 'newAdventurerIcon');
    end

    if (layoutStateName == 'Combat') then
        if (WidgetLoads(allianceLeaderIconSettings, 'Alliance leader icon') == true) then
            allianceLeaderIconTextureId = playerIndicators.GetAllianceLeaderIconTextureId(player.index);
            AddIcon(icons, allianceLeaderIconSettings, allianceLeaderIconTextureId, -120, -54, 'allianceLeaderIcon');
        end

        if (WidgetLoads(partyLeaderIconSettings, 'Party leader icon') == true) then
            partyLeaderIconTextureId = playerIndicators.GetPartyLeaderIconTextureId(player.index);
            AddIcon(icons, partyLeaderIconSettings, partyLeaderIconTextureId, -96, -54, 'partyLeaderIcon');
        end
    end
    perfMeter.EndDetail(iconsTimer);

    local distanceText = nil;

    if (WidgetLoads(distanceSettings, 'Distance') == true and player.distance ~= nil) then
        distanceText = FormatDistanceText(distanceSettings, player.distance);
    end

    local cacheEligible = targetStateName == 'Idle'
        and isPartyPlayer ~= true
        and isTacticalPlayer ~= true
        and useTargetOverlay ~= true
        and state.GetConfigOpen() ~= true;

    local cacheKey = nil;
    local signature = nil;

    if (cacheEligible == true) then
        cacheKey = 'pc:' .. tostring(player.index);
        signature = table.concat({
            'v=1',
            'policy=' .. canvasTexture.GetRenderPolicyKey(),
            'name=' .. tostring(player.name or ''),
            'status=' .. tostring(player.status or ''),
            'engaged=' .. BoolKey(currentPlayerEngaged),
            'hp=' .. tostring(hasHp == true and hpPercent or ''),
            'mp=' .. tostring(hasMp == true and mpPercent or ''),
            'tp=' .. tostring(hasTp == true and tpValue or ''),
            'distance=' .. tostring(distanceText or ''),
            'game=' .. tostring(gameModeIconTextureId or ''),
            'linkshell=' .. tostring(linkshellIconTextureId or ''),
            'bazaar=' .. tostring(bazaarIconTextureId or ''),
            'away=' .. tostring(awayIconTextureId or ''),
            'disconnect=' .. tostring(disconnectIconTextureId or ''),
            'stars=' .. tostring(starsIconTextureId or ''),
            'new=' .. tostring(newAdventurerIconTextureId or ''),
            'staff=' .. tostring(staffIconTextureId or '') .. ':' .. tostring(staffInfo ~= nil and staffInfo.type or ''),
            'bg:' .. SettingKey(backgroundSettings, { 'enabled', 'loadMode', 'width', 'height', 'offsetX', 'offsetY', 'color', 'borderColor', 'borderSize', 'anchorTo', 'anchorPoint' }),
            'name:' .. SettingKey(nameSettings, { 'enabled', 'loadMode', 'shortenName', 'textSize', 'color', 'outlineSize', 'outlineColor', 'offsetX', 'offsetY', 'anchorTo', 'anchorPoint' }),
            'dist:' .. SettingKey(distanceSettings, { 'enabled', 'loadMode', 'textSize', 'color', 'outlineEnabled', 'outlineColor', 'outlineSize', 'useSmallFont', 'offsetX', 'offsetY', 'prefix', 'anchorTo', 'anchorPoint' }),
            'hp:' .. SettingKey(hpBarSettings, { 'enabled', 'loadMode', 'width', 'height', 'offsetX', 'offsetY', 'color', 'backgroundColor', 'borderColor', 'borderSize', 'anchorTo', 'anchorPoint', 'texture', 'showValue', 'showPercent', 'fontSize', 'textColor', 'textOutlineEnabled', 'textOutlineColor', 'textOutlineSize' }),
            'icons=' .. tostring(#icons),
        }, '\n');

        local indexed = indexCache[tonumber(player.index) or 0];
        local cached = indexed ~= nil and indexed.signature == signature and plateCache[indexed.cacheKey] or nil;

        if (QueueCachedPlayer(player, cached, targetStateName, useTargetOverlay, layoutStateName, hasHp, hasMp, hasTp, hpPercent, mpPercent, tpValue) == true) then
            cached.lastFullRefresh = os.clock();
            perfMeter.Count('pc.cache.hit', 1);
            return;
        end

        perfMeter.Count('pc.cache.miss', 1);
    end

    local buildTimer = perfMeter.BeginDetail('pc.build');
    local plateData = {
        hp = hpPercent,
        mp = mpPercent,
        tp = tpPercent,
        name = (nameLoads == true) and ShortenName(player.name, nameSettings.shortenName) or '',
        nameFontFamily = fonts.GetRole(globalSettings, false),
        nameFontFlags = fonts.GetRoleFlags(globalSettings, false),
        nameFontSize = textScale.ToTextureFontSize(math.min(40, tonumber(nameSettings.textSize) or nameDefaults.textSize), nameDefaults.textSize),
        nameColor = nameSettings.color or { 1.0, 1.0, 1.0, 1.0 },
        nameOutlineEnabled = (tonumber(nameSettings.outlineSize) or 0) > 0,
        nameOutlineColor = nameSettings.outlineColor or { 0.0, 0.0, 0.0, 1.0 },
        nameOutlineSize = tonumber(nameSettings.outlineSize) or 0,
        nameOffsetX = tonumber(nameSettings.offsetX) or 0,
        nameOffsetY = tonumber(nameSettings.offsetY) or -54,
        nameAnchorTo = nameSettings.anchorTo or nameDefaults.anchorTo,
        nameAnchorPoint = nameSettings.anchorPoint or nameDefaults.anchorPoint,
        hpBar = {
            enabled = hpBarLoads == true,
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
            textureId = hpBarLoads == true and barTextures.GetTextureId(hpBarSettings.texture) or nil,
            animationEnabled = hpAnimationEnabled,
            animationTextureId = hpAnimationEnabled == true and barAnimations.GetTextureId(hpBarSettings.lowAnimation) or nil,
            animationSpeed = tonumber(hpBarSettings.lowAnimationSpeed) or 40,
            animationColor = hpBarSettings.lowAnimationColor,
            showAtPercent = tonumber(hpBarSettings.showAtPercent) or 100,
            text = BuildResourceText(hpBarSettings, 'HP', player.hp, player.maxHp, hpPercent),
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
            enabled = mpBarLoads == true,
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
            textureId = mpBarLoads == true and barTextures.GetTextureId(mpBarSettings.texture) or nil,
            animationEnabled = mpAnimationEnabled,
            animationTextureId = mpAnimationEnabled == true and barAnimations.GetTextureId(mpBarSettings.lowAnimation) or nil,
            animationSpeed = tonumber(mpBarSettings.lowAnimationSpeed) or 40,
            animationColor = mpBarSettings.lowAnimationColor,
            showAtPercent = tonumber(mpBarSettings.showAtPercent) or 100,
            text = BuildResourceText(mpBarSettings, 'MP', player.mp, player.maxMp, mpPercent),
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
            enabled = tpBarLoads == true,
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
            textureId = tpBarLoads == true and barTextures.GetTextureId(tpBarSettings.texture) or nil,
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
        targetMarker = targetMarker,
        icons = icons,
        background = {
            enabled = backgroundLoads == true,
            width = tonumber(backgroundSettings.width) or backgroundDefaults.width,
            height = tonumber(backgroundSettings.height) or backgroundDefaults.height,
            offsetX = tonumber(backgroundSettings.offsetX) or backgroundDefaults.offsetX,
            offsetY = tonumber(backgroundSettings.offsetY) or backgroundDefaults.offsetY,
            color = backgroundSettings.color or backgroundDefaults.color,
            borderColor = backgroundSettings.borderColor or backgroundDefaults.borderColor,
            borderSize = tonumber(backgroundSettings.borderSize) or backgroundDefaults.borderSize,
            anchorTo = backgroundSettings.anchorTo or backgroundDefaults.anchorTo,
            anchorPoint = backgroundSettings.anchorPoint or backgroundDefaults.anchorPoint,
        },
    };

    if (WidgetLoads(jobSettings, 'Job') == true) then
        AddJobToPlate(plateData, GetJobText(player.mainJob), jobSettings, globalSettings);
    end

    if (WidgetLoads(levelSettings, 'Level') == true) then
        AddTextBadge(plateData, 'level', player.mainJobLevel, levelSettings, levelDefaults, globalSettings);
    end

    if (staffInfo ~= nil and tostring(staffInfo.type or '') ~= '') then
        AddTextBadge(plateData, 'staff', staffInfo.type, {
            enabled = true,
            textSize = 11,
            color = { 1.0, 0.12, 0.12, 1.0 },
            outlineEnabled = true,
            outlineColor = { 0.0, 0.0, 0.0, 1.0 },
            outlineSize = 2,
            useSmallFont = true,
            offsetX = -42,
            offsetY = -56,
        }, {
            textSize = 11,
            color = { 1.0, 0.12, 0.12, 1.0 },
            outlineColor = { 0.0, 0.0, 0.0, 1.0 },
            outlineSize = 2,
            offsetX = -42,
            offsetY = -56,
        }, globalSettings);
    end

    local statusTimer = perfMeter.BeginDetail('pc.status');
    local isEngaged = tonumber(player.status) == 1;

    if (ShouldLoadStatusRows(buffsSettings, 'Buffs', isEngaged) == true) then
        AddStatusIconsToPlate(plateData, partyStatuses.GetMemberRows(player.serverId, 'buff'), buffsSettings, isEngaged, globalSettings, 'buffs');
    end

    if (ShouldLoadStatusRows(debuffsSettings, 'Debuffs', isEngaged) == true) then
        AddStatusIconsToPlate(plateData, partyStatuses.GetMemberRows(player.serverId, 'debuff'), debuffsSettings, isEngaged, globalSettings, 'debuffs');
    end
    perfMeter.EndDetail(statusTimer);

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

    if (layoutStateName == 'Combat' and enmity.ShouldDrawAlly(player, globalSettings) == true) then
        enmity.AddIcon(plateData, globalSettings.enmity);
    end
    perfMeter.EndDetail(buildTimer);

    local canvasTimer = perfMeter.BeginDetail('pc.canvas');
    local plateTexture, textureWidth, textureHeight = canvasTexture.Render(plateData, 'pc-' .. tostring(player.index));
    local plateTextureId = canvasTexture.GetTextureId(plateTexture);
    local elementRects = plateData._elementRects or canvasTexture.GetElementRects(plateData);
    perfMeter.EndDetail(canvasTimer);

    if (plateTextureId == nil) then
        return;
    end

    if (cacheEligible == true and cacheKey ~= nil and signature ~= nil) then
        plateCache[cacheKey] = {
            signature = signature,
            texture = plateTexture,
            textureKey = 'pc-' .. tostring(player.index),
            lastUsed = os.clock(),
            lastFullRefresh = os.clock(),
            hasDynamicVisuals = hpBarLoads == true or (distanceText ~= nil and distanceText ~= ''),
            textureWidth = textureWidth,
            textureHeight = textureHeight,
            elementRects = elementRects,
            plateWorldOffsetY = (tonumber(player.status) == 85) and (0.50 - mountedPlateLift) or 0.50,
        };
        indexCache[tonumber(player.index) or 0] = {
            cacheKey = cacheKey,
            signature = signature,
        };
    else
        indexCache[tonumber(player.index) or 0] = nil;
    end

    local queueTimer = perfMeter.BeginDetail('pc.queue');
    local plateWorldOffsetY = (tonumber(player.status) == 85) and (0.50 - mountedPlateLift) or 0.50;
    local targetingSettings = targeting.GetSettings();

    worldMarkerProbe.QueuePlate({
        targetIndex = player.index,
        serverId = player.serverId,
        distance = player.distance,
        hp = hasHp == true and hpPercent or 100,
        mp = hasMp == true and mpPercent or nil,
        tp = hasTp == true and tpValue or nil,
        name = '',
        isSelf = false,
        stateName = targetStateName,
        clickTargetType = 'pc',
        worldMarker = {
            hpBar = { enabled = false },
            plateTextureId = plateTextureId,
            plateAlwaysOnTop = useTargetOverlay == true,
            plateTacticalOverlayOnly = useTargetOverlay == true,
            plateWorldWidth = 2.35,
            plateWorldHeight = 1.18,
            plateWorldOffsetY = plateWorldOffsetY,
            plateDistanceScaleStart = tonumber(targetingSettings.pcDistanceScaleStart) or 2.0,
            plateDistanceScaleEnd = tonumber(targetingSettings.pcDistanceScaleEnd) or 8.0,
            plateDistanceScaleMax = tonumber(targetingSettings.pcDistanceScaleMax) or 2.65,
            plateDistanceScaleOffsetY = 0.28,
            plateTextureWidth = textureWidth,
            plateTextureHeight = textureHeight,
            plateClickRects = elementRects,
            clickTargetType = 'pc',
            clickName = player.name,
            layoutStateName = layoutStateName,
        },
    });
    perfMeter.EndDetail(queueTimer);
end

function pcPlate.Build()
    return nil;
end

function pcPlate.Render()
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

    currentPlayerEngaged = targeting.IsPlayerEngaged() == true;
    local targetingSettings = targeting.GetSettings();
    local range = tonumber(targetingSettings.enemyPlateRange) or 49.9;
    local now = os.clock();
    local canUseScanCache = currentPlayerEngaged ~= true
        and state.GetConfigOpen() ~= true;
    local players = nil;

    if (
        canUseScanCache == true and
        scanCache.players ~= nil and
        scanCache.range == range and
        (now - (tonumber(scanCache.clock) or 0)) < idleScanCacheSeconds
    ) then
        perfMeter.Count('pc.scan.cacheHit', 1);
        players = scanCache.players;
    else
        perfMeter.Count('pc.scan.cacheMiss', 1);
        local scanTimer = perfMeter.BeginDetail('pc.scan');
        players = entities.GetNearbyPlayers(range);
        perfMeter.EndDetail(scanTimer);

        if (canUseScanCache == true) then
            scanCache.clock = now;
            scanCache.range = range;
            scanCache.players = players;
        else
            scanCache.players = nil;
        end
    end

    for _, player in ipairs(players) do
        QueuePlayer(player);
    end
end

return pcPlate;
