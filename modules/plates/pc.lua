local nameDefaults = require('config.widgets.name');
local backgroundDefaults = require('config.widgets.background');
local barDefaults = require('config.widgets.bar');
local mpBarDefaults = require('config.widgets.mp_bar');
local tpBarDefaults = require('config.widgets.tp_bar');
local jobDefaults = require('config.widgets.job');
local levelDefaults = require('config.widgets.level');
local buffsDefaults = require('config.widgets.buffs');
local debuffsDefaults = require('config.widgets.debuffs');
local aoeRangeDefaults = require('config.widgets.aoe_range');
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
local backgroundTextures = require('core.background_textures');
local barAnimations = require('core.bar_animations');
local textureLoader = require('core.texture_loader');
local statusIconTextures = require('core.status_icon_textures');
local statusTimerFormat = require('core.status_timer_format');
local jobIconTextures = require('core.job_icon_textures');
local entities = require('core.entities');
local gameMode = require('core.game_mode');
local playerIndicators = require('core.player_indicators');
local perfMeter = require('core.perf_meter');
local adaptivePerformance = require('core.adaptive_performance');
local aoeNameHighlight = require('core.aoe_name_highlight');
local aoeRangeVisuals = require('core.aoe_range_visuals');
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
local wasConfigOpen = false;
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
local pcIdleCanvasBuildsThisFrame = 0;
local pcIdleCanvasBuildLimitThisFrame = 0;
local plateWorkGateCache = {
    clock = 0,
    engaged = nil,
    result = true,
};
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

local function SolidColor(color, fallback)
    local source = color or fallback or { 1.0, 1.0, 1.0, 1.0 };

    return {
        tonumber(source[1]) or 1.0,
        tonumber(source[2]) or 1.0,
        tonumber(source[3]) or 1.0,
        1.0,
    };
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

local function AddIcon(icons, settings, textureId, defaultX, defaultY, kind, tint)
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
        tint = tint,
    };
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
    ['Level sync icon'] = 'Out of combat',
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

    if (settings.hideOutOfCombat == true and ((tostring(settings.hideCombatMode or 'Out of combat') == 'Out of combat' and isEngaged ~= true) or (tostring(settings.hideCombatMode or 'Out of combat') == 'In combat' and isEngaged == true))) then
        return false;
    end

    return true;
end

local function GetPlayerIdentityKey(player)
    local serverId = tonumber(player ~= nil and player.serverId) or 0;
    local name = tostring(player ~= nil and player.name or '');

    if (serverId > 0) then
        return 'sid:' .. tostring(serverId);
    end

    return 'name:' .. name:lower():gsub('[^%w]', '');
end

local function CachedPlayerIdentityMatches(player, cached)
    if (cached == nil) then
        return false;
    end

    local identityKey = GetPlayerIdentityKey(player);

    if (cached.identityKey ~= nil) then
        return cached.identityKey == identityKey;
    end

    local cachedServerId = tonumber(cached.serverId) or 0;
    local playerServerId = tonumber(player ~= nil and player.serverId) or 0;

    if (cachedServerId > 0 or playerServerId > 0) then
        return cachedServerId == playerServerId;
    end

    return tostring(cached.name or '') == tostring(player ~= nil and player.name or '');
end

local function QueueCachedPlayer(player, cached, targetStateName, useTargetOverlay, layoutStateName, hasHp, hasMp, hasTp, hpPercent, mpPercent, tpValue, hpBarStyle, mpBarStyle, tpBarStyle, isProtectedPlate, isPartyPlayer)
    if (cached == nil or cached.texture == nil) then
        return false;
    end

    if (CachedPlayerIdentityMatches(player, cached) ~= true) then
        return false;
    end

    local targetingSettings = targeting.GetSettings();
    local streamerNames = require('core.streamer_names');

    if ((cached.streamerNameSignature or 'streamer=legacy') ~= streamerNames.GetSignature(player, targetingSettings)) then
        return false;
    end

    TouchPlateCacheEntry(cached);

    local plateTextureId = canvasTexture.GetTextureId(cached.texture);

    if (plateTextureId == nil) then
        return false;
    end

    local queueTimer = perfMeter.BeginDetail('pc.queue');

    worldMarkerProbe.QueuePlate({
        targetIndex = player.index,
        serverId = player.serverId,
        distance = player.distance,
        hp = hasHp == true and hpPercent or 100,
        mp = hasMp == true and mpPercent or nil,
        tp = hasTp == true and tpValue or nil,
        name = '',
        isSelf = false,
        isProtectedPlate = isProtectedPlate == true,
        isPartyPlayer = isPartyPlayer == true,
        stateName = targetStateName,
        clickTargetType = 'pc',
        worldMarker = targeting.ApplyPlateScalingSettings({
            hpBar = hpBarStyle or cached.hpBar or { enabled = false },
            mpBar = mpBarStyle or cached.mpBar or { enabled = false },
            tpBar = tpBarStyle or cached.tpBar or { enabled = false },
            liveResourceBars = false,
            plateTextureId = plateTextureId,
            plateAlwaysOnTop = isProtectedPlate == true or useTargetOverlay == true,
            plateTacticalOverlayOnly = useTargetOverlay == true,
            useExactNameplateAnchor = true,
            plateWorldWidth = cached.plateWorldWidth or 2.35,
            plateWorldHeight = 1.18,
            plateWorldOffsetY = cached.plateWorldOffsetY,
            plateDistanceScaleOffsetY = 0.28,
            pcBodyPlateOffsetEnabled = true,
            plateTextureWidth = cached.textureWidth,
            plateTextureHeight = cached.textureHeight,
            plateClickRects = cached.elementRects,
            clickTargetType = 'pc',
            clickName = player.name,
            layoutStateName = layoutStateName,
            protectedPlate = isProtectedPlate == true,
            partyPlate = isPartyPlayer == true,
        }, 'pc', 0, cached.plateWorldOffsetY),
    });
    perfMeter.EndDetail(queueTimer);

    return true;
end

local function QueueFreshIdleCache(player, targetStateName, useTargetOverlay, layoutStateName, hasHp, hasMp, hasTp, hpPercent, mpPercent, tpValue, hpBarStyle, mpBarStyle, tpBarStyle, maxAgeOverride, isProtectedPlate, isPartyPlayer)
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
    local maxAge = tonumber(maxAgeOverride) or adaptivePerformance.GetWorldRefreshSeconds('pc');

    if ((now - lastRefresh) >= maxAge) then
        return false;
    end

    if (QueueCachedPlayer(player, cached, targetStateName, useTargetOverlay, layoutStateName, hasHp, hasMp, hasTp, hpPercent, mpPercent, tpValue, hpBarStyle, mpBarStyle, tpBarStyle, isProtectedPlate, isPartyPlayer) == true) then
        perfMeter.Count('pc.cache.directHit', 1);
        return true;
    end

    return false;
end

local function ShouldDeferIdlePcCanvasBuild(cacheEligible)
    if (cacheEligible ~= true or pcIdleCanvasBuildLimitThisFrame <= 0) then
        return false;
    end

    if (pcIdleCanvasBuildsThisFrame >= pcIdleCanvasBuildLimitThisFrame) then
        return true;
    end

    pcIdleCanvasBuildsThisFrame = pcIdleCanvasBuildsThisFrame + 1;
    return false;
end

local function TargetMarkerCanDraw(layoutStateName, targetStateName)
    local nativeUiPolicy = require('core.native_ui_policy');

    if (nativeUiPolicy.ShouldDrawLibraTargetingSystem() ~= true) then
        return false;
    end

    local markerSettings = targetModuleMarker.GetSettings('PC', layoutStateName, targetStateName);
    return targetModuleMarker.HasDrawableSettings('PC', markerSettings) == true;
end

local function AnyPcWidgetCanLoadForState(layoutStateName)
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
    local anonIconDefaults = require('config.widgets.anon_icon');
    local anonIconSettings = state.GetWidgetSettings('PC', layoutStateName, 'Anon icon', anonIconDefaults);
    local starsIconSettings = state.GetWidgetSettings('PC', layoutStateName, 'Stars icon', starsIconDefaults);
    local levelSyncIconDefaults = require('config.widgets.level_sync_icon');
    local levelSyncIconSettings = state.GetWidgetSettings('PC', layoutStateName, 'Level sync icon', levelSyncIconDefaults);
    local newAdventurerIconSettings = state.GetWidgetSettings('PC', layoutStateName, 'New adventurer icon', newAdventurerIconDefaults);

    return
        WidgetLoads(backgroundSettings, 'Background') == true or
        WidgetLoads(nameSettings, 'Name') == true or
        WidgetLoads(distanceSettings, 'Distance') == true or
        WidgetLoads(hpBarSettings, 'HP Bar') == true or
        WidgetLoads(mpBarSettings, 'MP Bar') == true or
        WidgetLoads(tpBarSettings, 'TP Bar') == true or
        WidgetLoads(jobSettings, 'Job') == true or
        WidgetLoads(levelSettings, 'Level') == true or
        WidgetLoads(gameModeIconSettings, 'Game mode icon') == true or
        WidgetLoads(partyLeaderIconSettings, 'Party leader icon') == true or
        WidgetLoads(allianceLeaderIconSettings, 'Alliance leader icon') == true or
        WidgetLoads(linkshellIconSettings, 'Linkshell icon') == true or
        WidgetLoads(bazaarIconSettings, 'Bazaar icon') == true or
        WidgetLoads(awayIconSettings, 'Away icon') == true or
        WidgetLoads(disconnectIconSettings, 'Disconnect icon') == true or
        WidgetLoads(anonIconSettings, 'Anon icon') == true or
        WidgetLoads(starsIconSettings, 'Stars icon') == true or
        WidgetLoads(levelSyncIconSettings, 'Level sync icon') == true or
        WidgetLoads(newAdventurerIconSettings, 'New adventurer icon') == true or
        ShouldLoadStatusRows(buffsSettings, 'Buffs', layoutStateName == 'Combat') == true or
        ShouldLoadStatusRows(debuffsSettings, 'Debuffs', layoutStateName == 'Combat') == true;
end

local function AnyPcPlateWorkCanLoad()
    local now = os.clock();
    local engagedKey = currentPlayerEngaged == true;

    if (
        plateWorkGateCache.engaged == engagedKey and
        (now - (tonumber(plateWorkGateCache.clock) or 0)) < 0.50
    ) then
        return plateWorkGateCache.result == true;
    end

    local globalSettings = state.GetGlobalSettings(globalDefaults);
    local enmitySettings = globalSettings ~= nil and globalSettings.enmity or nil;
    local result =
        AnyPcWidgetCanLoadForState('Idle') == true or
        AnyPcWidgetCanLoadForState('Combat') == true or
        TargetMarkerCanDraw('Combat', 'Target') == true or
        TargetMarkerCanDraw('Combat', 'Subtarget') == true or
        (enmitySettings ~= nil and enmitySettings.enabled == true);

    plateWorkGateCache.clock = now;
    plateWorkGateCache.engaged = engagedKey;
    plateWorkGateCache.result = result == true;

    return result == true;
end

local function AnyPcWorldPlateWorkCanLoad()
    local globalSettings = state.GetGlobalSettings(globalDefaults);
    local enmitySettings = globalSettings ~= nil and globalSettings.enmity or nil;

    return
        AnyPcWidgetCanLoadForState('Idle') == true or
        AnyPcWidgetCanLoadForState('Combat') == true or
        (enmitySettings ~= nil and enmitySettings.enabled == true);
end

local function AnyPcTargetModuleCanLoad()
    return
        TargetMarkerCanDraw('Combat', 'Target') == true or
        TargetMarkerCanDraw('Combat', 'Subtarget') == true;
end

local function AnyPcIdleWorldPlateWorkCanLoad()
    return AnyPcWidgetCanLoadForState('Idle') == true;
end

local function AnyPcPartyPlateWorkCanLoad()
    local globalSettings = state.GetGlobalSettings(globalDefaults);
    local enmitySettings = globalSettings ~= nil and globalSettings.enmity or nil;

    return
        AnyPcWidgetCanLoadForState('Combat') == true or
        (enmitySettings ~= nil and enmitySettings.enabled == true);
end

local function BuildPcPlateData(context)
    local hpBarColor = context.hpBarOutOfRange == true and SolidColor(context.hpBarSettings.outOfRangeColor, { 0.02, 0.08, 0.12, 1.0 }) or context.hpColor;
    local hpBarAnimationColor = context.hpBarOutOfRange == true and hpBarColor or context.hpBarSettings.lowAnimationColor;
    local nameColor = context.nameSettings.color or { 1.0, 1.0, 1.0, 1.0 };
    local targetingSettings = targeting.GetSettings();
    local playerBlacklist = require('core.player_blacklist');
    local streamerNames = require('core.streamer_names');

    if (targetingSettings.overwriteNativeNameColors == false) then
        if (playerIndicators.HasAnonNameColor(context.player.index) == true) then
            nameColor = playerIndicators.GetAnonNameColor();
        else
            local modeText = context.gameModeText or gameMode.Resolve(context.player.index, false);
            if (modeText == 'CW' or modeText == 'UCW') then
                nameColor = playerIndicators.GetCampaignNameColor();
            end
        end
    end

    local displayName = ShortenName(context.player.name, context.nameSettings.shortenName);
    displayName = playerBlacklist.GetDisplayName(context.player, displayName);
    nameColor = playerBlacklist.GetDisplayNameColor(context.player, nameColor);
    displayName = streamerNames.GetDisplayName(context.player, displayName, targetingSettings);

    local plateData = {
        hp = context.hpPercent,
        mp = context.mpPercent,
        tp = context.tpPercent,
        aoeNameActive = context.nameAoeActive == true,
        name = (context.nameLoads == true) and displayName or '',
        nameFontFamily = fonts.GetRole(context.globalSettings, false),
        nameFontFlags = fonts.GetRoleFlags(context.globalSettings, false),
        nameFontSize = textScale.ToNameTextureFontSize(context.nameTextSize, nameDefaults.textSize),
        nameColor = (context.nameAoeActive == true and context.aoeRangeSettings.fontColor) or nameColor,
        nameOutlineEnabled = (tonumber(context.nameSettings.outlineSize) or 0) > 0,
        nameOutlineColor = context.nameSettings.outlineColor or { 0.0, 0.0, 0.0, 1.0 },
        nameOutlineSize = tonumber(context.nameSettings.outlineSize) or 0,
        nameOffsetX = tonumber(context.nameSettings.offsetX) or 0,
        nameOffsetY = tonumber(context.nameSettings.offsetY) or -54,
        nameAnchorTo = context.nameSettings.anchorTo or nameDefaults.anchorTo,
        nameAnchorPoint = context.nameSettings.anchorPoint or nameDefaults.anchorPoint,
        hpBar = {
            enabled = context.hpBarLoads == true,
            width = tonumber(context.hpBarSettings.width) or 180,
            height = tonumber(context.hpBarSettings.height) or 12,
            offsetX = tonumber(context.hpBarSettings.offsetX) or 0,
            offsetY = tonumber(context.hpBarSettings.offsetY) or 0,
            color = hpBarColor,
            backgroundColor = context.hpBarSettings.backgroundColor or { 0.05, 0.05, 0.05, 0.85 },
            borderColor = context.hpBarSettings.borderColor or { 0.0, 0.0, 0.0, 1.0 },
            borderSize = tonumber(context.hpBarSettings.borderSize) or 0,
            anchorTo = context.hpBarSettings.anchorTo or barDefaults.anchorTo,
            anchorPoint = context.hpBarSettings.anchorPoint or barDefaults.anchorPoint,
            texture = context.hpBarSettings.texture or 'Solid',
            textureStrength = tonumber(context.hpBarSettings.textureStrength) or 100,
            textureId = context.hpBarLoads == true and barTextures.GetTextureId(context.hpBarSettings.texture) or nil,
            animationEnabled = context.hpAnimationEnabled,
            animationTextureId = context.hpAnimationEnabled == true and barAnimations.GetTextureId(context.hpBarSettings.lowAnimation) or nil,
            animationSpeed = tonumber(context.hpBarSettings.lowAnimationSpeed) or 40,
            animationColor = hpBarAnimationColor,
            showAtPercent = tonumber(context.hpBarSettings.showAtPercent) or 100,
            text = BuildResourceText(context.hpBarSettings, 'HP', context.player.hp, context.player.maxHp, context.hpPercent),
            textOffsetX = tonumber(context.hpBarSettings.textOffsetX) or 0,
            textOffsetY = tonumber(context.hpBarSettings.textOffsetY) or 0,
            fontFamily = fonts.GetRole(context.globalSettings, context.hpBarSettings.useSmallFont == true),
            fontFlags = fonts.GetRoleFlags(context.globalSettings, context.hpBarSettings.useSmallFont == true),
            fontSize = textScale.ToTextureFontSize(context.hpBarSettings.fontSize, barDefaults.fontSize),
            textColor = context.hpBarSettings.textColor or { 1.0, 1.0, 1.0, 1.0 },
            textOutlineEnabled = context.hpBarSettings.textOutlineEnabled == true,
            textOutlineColor = context.hpBarSettings.textOutlineColor or { 0.0, 0.0, 0.0, 1.0 },
            textOutlineSize = tonumber(context.hpBarSettings.textOutlineSize) or 1,
        },
        mpBar = {
            enabled = context.mpBarLoads == true,
            width = tonumber(context.mpBarSettings.width) or 180,
            height = tonumber(context.mpBarSettings.height) or 8,
            offsetX = tonumber(context.mpBarSettings.offsetX) or 0,
            offsetY = tonumber(context.mpBarSettings.offsetY) or 16,
            color = context.mpColor,
            backgroundColor = context.mpBarSettings.backgroundColor or { 0.05, 0.05, 0.05, 0.85 },
            borderColor = context.mpBarSettings.borderColor or { 0.0, 0.0, 0.0, 1.0 },
            borderSize = tonumber(context.mpBarSettings.borderSize) or 0,
            anchorTo = context.mpBarSettings.anchorTo or mpBarDefaults.anchorTo,
            anchorPoint = context.mpBarSettings.anchorPoint or mpBarDefaults.anchorPoint,
            texture = context.mpBarSettings.texture or 'Solid',
            textureStrength = tonumber(context.mpBarSettings.textureStrength) or 100,
            textureId = context.mpBarLoads == true and barTextures.GetTextureId(context.mpBarSettings.texture) or nil,
            animationEnabled = context.mpAnimationEnabled,
            animationTextureId = context.mpAnimationEnabled == true and barAnimations.GetTextureId(context.mpBarSettings.lowAnimation) or nil,
            animationSpeed = tonumber(context.mpBarSettings.lowAnimationSpeed) or 40,
            animationColor = context.mpBarSettings.lowAnimationColor,
            showAtPercent = tonumber(context.mpBarSettings.showAtPercent) or 100,
            text = BuildResourceText(context.mpBarSettings, 'MP', context.player.mp, context.player.maxMp, context.mpPercent),
            textOffsetX = tonumber(context.mpBarSettings.textOffsetX) or 0,
            textOffsetY = tonumber(context.mpBarSettings.textOffsetY) or 0,
            fontFamily = fonts.GetRole(context.globalSettings, context.mpBarSettings.useSmallFont == true),
            fontFlags = fonts.GetRoleFlags(context.globalSettings, context.mpBarSettings.useSmallFont == true),
            fontSize = textScale.ToTextureFontSize(context.mpBarSettings.fontSize, mpBarDefaults.fontSize),
            textColor = context.mpBarSettings.textColor or { 1.0, 1.0, 1.0, 1.0 },
            textOutlineEnabled = context.mpBarSettings.textOutlineEnabled == true,
            textOutlineColor = context.mpBarSettings.textOutlineColor or { 0.0, 0.0, 0.0, 1.0 },
            textOutlineSize = tonumber(context.mpBarSettings.textOutlineSize) or 1,
        },
        tpBar = {
            enabled = context.tpBarLoads == true,
            width = tonumber(context.tpBarSettings.width) or 180,
            height = tonumber(context.tpBarSettings.height) or 6,
            offsetX = tonumber(context.tpBarSettings.offsetX) or 0,
            offsetY = tonumber(context.tpBarSettings.offsetY) or 28,
            color = context.tpColor,
            backgroundColor = context.tpBarSettings.backgroundColor or { 0.05, 0.05, 0.05, 0.85 },
            borderColor = context.tpBarSettings.borderColor or { 0.0, 0.0, 0.0, 1.0 },
            borderSize = tonumber(context.tpBarSettings.borderSize) or 0,
            anchorTo = context.tpBarSettings.anchorTo or tpBarDefaults.anchorTo,
            anchorPoint = context.tpBarSettings.anchorPoint or tpBarDefaults.anchorPoint,
            texture = context.tpBarSettings.texture or 'Solid',
            textureStrength = tonumber(context.tpBarSettings.textureStrength) or 100,
            textureId = context.tpBarLoads == true and barTextures.GetTextureId(context.tpBarSettings.texture) or nil,
            color2 = context.tpBarSettings.color2 or tpBarDefaults.color2,
            color3 = context.tpBarSettings.color3 or tpBarDefaults.color3,
            showAtPercent = tonumber(context.tpBarSettings.showAtPercent) or 100,
            segmented = context.tpBarSettings.segmented ~= false,
            segmentGap = tonumber(context.tpBarSettings.segmentGap) or 3,
            text = BuildResourceText(context.tpBarSettings, 'TP', context.tpValue, 3000, context.tpPercent),
            textOffsetX = tonumber(context.tpBarSettings.textOffsetX) or 0,
            textOffsetY = tonumber(context.tpBarSettings.textOffsetY) or 0,
            fontFamily = fonts.GetRole(context.globalSettings, context.tpBarSettings.useSmallFont == true),
            fontFlags = fonts.GetRoleFlags(context.globalSettings, context.tpBarSettings.useSmallFont == true),
            fontSize = textScale.ToTextureFontSize(context.tpBarSettings.fontSize, tpBarDefaults.fontSize),
            textColor = context.tpBarSettings.textColor or { 1.0, 1.0, 1.0, 1.0 },
            textOutlineEnabled = context.tpBarSettings.textOutlineEnabled == true,
            textOutlineColor = context.tpBarSettings.textOutlineColor or { 0.0, 0.0, 0.0, 1.0 },
            textOutlineSize = tonumber(context.tpBarSettings.textOutlineSize) or 1,
        },
        targetMarker = context.targetMarker,
        icons = context.icons,
        anchorFallbackRects = BuildPlayerIndicatorAnchorFallbackRects(context.anchorFallbackDefinitions),
        background = {
            enabled = context.backgroundLoads == true,
            width = tonumber(context.backgroundSettings.width) or backgroundDefaults.width,
            height = tonumber(context.backgroundSettings.height) or backgroundDefaults.height,
            offsetX = tonumber(context.backgroundSettings.offsetX) or backgroundDefaults.offsetX,
            offsetY = tonumber(context.backgroundSettings.offsetY) or backgroundDefaults.offsetY,
            color = context.backgroundSettings.color or backgroundDefaults.color,
            borderColor = context.backgroundSettings.borderColor or backgroundDefaults.borderColor,
            borderSize = tonumber(context.backgroundSettings.borderSize) or backgroundDefaults.borderSize,
            texture = context.backgroundSettings.texture or backgroundDefaults.texture,
            textureId = backgroundTextures.GetTextureId(context.backgroundSettings.texture or backgroundDefaults.texture),
            anchorTo = context.backgroundSettings.anchorTo or backgroundDefaults.anchorTo,
            anchorPoint = context.backgroundSettings.anchorPoint or backgroundDefaults.anchorPoint,
        },
    };

    return plateData;
end

local function QueuePlayer(player)
    local function canUseLiveResourceBarSettings(settings)
        settings = settings or {};

        if (settings.enabled ~= true) then
            return false;
        end

        if (settings.showPercent == true or settings.showValue == true) then
            return false;
        end

        if (settings.lowAnimationEnabled == true) then
            return false;
        end

        if (tostring(settings.anchorTo or 'Plate') ~= 'Plate') then
            return false;
        end

        local texture = tostring(settings.texture or 'Solid');
        return texture == '' or texture == 'Solid';
    end

    local targetStateName = targeting.GetTargetStateName(player.index);

    if (entities.ShouldHideOtherPlayerPet(player.index, player.name) == true) then
        return;
    end

    local isPartyPlayer = tonumber(player.slot) ~= nil;
    local isTargetContext = targetStateName ~= 'Idle';
    local isTacticalPlayer = isPartyPlayer == true;
    local isProtectedPlate = isPartyPlayer == true or isTargetContext == true;

    local suppressExpensiveWorldWidgets = adaptivePerformance.ShouldDisableExpensiveWorldWidgets(isProtectedPlate);
    local useTargetOverlay = isTargetContext == true;
    local layoutStateName = (isTacticalPlayer == true or isTargetContext == true) and 'Combat' or 'Idle';
    local targetModuleStateName = (isTacticalPlayer == true or isTargetContext == true) and 'Combat' or layoutStateName;
    local hasHp = player.hpPercent ~= nil or (player.hp ~= nil and player.maxHp ~= nil and tonumber(player.maxHp) > 0);
    local playerMaxMp = tonumber(player.maxMp);
    local playerMainJob = tonumber(player.mainJob);
    local mainJobCanHaveMp =
        playerMainJob == nil or
        playerMainJob == 3 or -- WHM
        playerMainJob == 4 or -- BLM
        playerMainJob == 5 or -- RDM
        playerMainJob == 7 or -- PLD
        playerMainJob == 8 or -- DRK
        playerMainJob == 10 or -- BRD
        playerMainJob == 15 or -- SMN
        playerMainJob == 16 or -- BLU
        playerMainJob == 20 or -- SCH
        playerMainJob == 21 or -- GEO
        playerMainJob == 22; -- RUN
    local hasMp = layoutStateName == 'Combat' and (
        (playerMaxMp ~= nil and playerMaxMp > 0) or
        (playerMaxMp == nil and (player.mpPercent ~= nil or player.mp ~= nil) and mainJobCanHaveMp == true)
    );
    local hasTp = layoutStateName == 'Combat' and player.tp ~= nil;
    local hpPercent = ClampPercent(player.hpPercent, 100);
    local mpPercent = ClampPercent(player.mpPercent, 100);
    local tpValue = ClampTp(player.tp);

    local earlyDistanceSettings = nil;
    local canUseFreshIdleCache = true;

    if (targetStateName == 'Idle' and useTargetOverlay ~= true and state.GetConfigOpen() ~= true) then
        earlyDistanceSettings = state.GetWidgetSettings('PC', layoutStateName, 'Distance', distanceDefaults);

        if (WidgetLoads(earlyDistanceSettings, 'Distance') == true) then
            canUseFreshIdleCache = false;
        end

        local earlyHpBarSettings = state.GetWidgetSettings('PC', layoutStateName, 'HP Bar', barDefaults);

        if (WidgetLoads(earlyHpBarSettings, 'HP Bar') == true and canUseLiveResourceBarSettings(earlyHpBarSettings) ~= true) then
            canUseFreshIdleCache = false;
        end

    end

    local canUseTacticalCacheWindow = isPartyPlayer == true and isTargetContext ~= true;
    local earlyCacheMaxAge = canUseTacticalCacheWindow == true
        and adaptivePerformance.GetPlateRefreshSeconds('tactical', 'critical')
        or nil;

    if (
        (canUseFreshIdleCache == true or canUseTacticalCacheWindow == true) and
        QueueFreshIdleCache(player, targetStateName, useTargetOverlay, layoutStateName, hasHp, hasMp, hasTp, hpPercent, mpPercent, tpValue, nil, nil, nil, earlyCacheMaxAge, isProtectedPlate, isPartyPlayer) == true
    ) then
        return;
    end

    local settingsTimer = perfMeter.BeginDetail('pc.settings');
    local backgroundSettings = state.GetWidgetSettings('PC', layoutStateName, 'Background', backgroundDefaults);
    local nameSettings = state.GetWidgetSettings('PC', layoutStateName, 'Name', nameDefaults);
    local distanceSettings = earlyDistanceSettings or state.GetWidgetSettings('PC', layoutStateName, 'Distance', distanceDefaults);
    local showDistanceBadge = WidgetLoads(distanceSettings, 'Distance') == true;
    local hpBarSettings = state.GetWidgetSettings('PC', layoutStateName, 'HP Bar', barDefaults);
    local mpBarSettings = state.GetWidgetSettings('PC', layoutStateName, 'MP Bar', mpBarDefaults);
    local tpBarSettings = state.GetWidgetSettings('PC', layoutStateName, 'TP Bar', tpBarDefaults);
    local jobSettings = state.GetWidgetSettings('PC', layoutStateName, 'Job', jobDefaults);
    local levelSettings = state.GetWidgetSettings('PC', layoutStateName, 'Level', levelDefaults);
    local buffsSettings = state.GetWidgetSettings('PC', layoutStateName, 'Buffs', buffsDefaults);
    local debuffsSettings = state.GetWidgetSettings('PC', layoutStateName, 'Debuffs', debuffsDefaults);
    local aoeRangeSettings = state.GetWidgetSettings('Self', 'Combat', 'AOE range', aoeRangeDefaults);
    local gameModeIconSettings = state.GetWidgetSettings('PC', layoutStateName, 'Game mode icon', gameModeIconDefaults);
    local partyLeaderIconSettings = state.GetWidgetSettings('PC', layoutStateName, 'Party leader icon', partyLeaderIconDefaults);
    local allianceLeaderIconSettings = state.GetWidgetSettings('PC', layoutStateName, 'Alliance leader icon', allianceLeaderIconDefaults);
    local linkshellIconSettings = state.GetWidgetSettings('PC', layoutStateName, 'Linkshell icon', linkshellIconDefaults);
    local bazaarIconSettings = state.GetWidgetSettings('PC', layoutStateName, 'Bazaar icon', bazaarIconDefaults);
    local awayIconSettings = state.GetWidgetSettings('PC', layoutStateName, 'Away icon', awayIconDefaults);
    local disconnectIconSettings = state.GetWidgetSettings('PC', layoutStateName, 'Disconnect icon', disconnectIconDefaults);
    local anonIconDefaults = require('config.widgets.anon_icon');
    local anonIconSettings = state.GetWidgetSettings('PC', layoutStateName, 'Anon icon', anonIconDefaults);
    local starsIconSettings = state.GetWidgetSettings('PC', layoutStateName, 'Stars icon', starsIconDefaults);
    local levelSyncIconDefaults = require('config.widgets.level_sync_icon');
    local levelSyncIconSettings = state.GetWidgetSettings('PC', layoutStateName, 'Level sync icon', levelSyncIconDefaults);
    local newAdventurerIconSettings = state.GetWidgetSettings('PC', layoutStateName, 'New adventurer icon', newAdventurerIconDefaults);
    local nativeUiPolicy = require('core.native_ui_policy');
    local targetMarker = targetStateName ~= 'Idle'
        and nativeUiPolicy.ShouldDrawLibraTargetingSystem() == true
        and targetModuleMarker.Build('PC', targetModuleStateName, targetStateName, hpBarSettings, player.distance)
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
    local jobLoads = suppressExpensiveWorldWidgets ~= true and WidgetLoads(jobSettings, 'Job');
    local levelLoads = suppressExpensiveWorldWidgets ~= true and WidgetLoads(levelSettings, 'Level');
    local hpAnimationEnabled = hpBarLoads == true and hpBarSettings.lowColorEnabled == true and hpPercent <= (tonumber(hpBarSettings.lowColorPercent) or 25) and hpBarSettings.lowAnimationEnabled == true;
    local mpAnimationEnabled = mpBarLoads == true and mpBarSettings.lowColorEnabled == true and mpPercent <= (tonumber(mpBarSettings.lowColorPercent) or 25) and mpBarSettings.lowAnimationEnabled == true;
    local canEvaluateHpBarRange = isPartyPlayer == true or isTargetContext == true;
    local queuedActionRange = (canEvaluateHpBarRange == true and hpBarSettings.outOfRangeOpacityEnabled == true) and targetModuleMarker.GetCurrentActionRange() or nil;
    local hpBarOutOfRangeDistance = tonumber(queuedActionRange) or tonumber(hpBarSettings.outOfRangeDefaultDistance) or 21;
    local hpBarOutOfRange = hpBarSettings.outOfRangeOpacityEnabled == true
        and canEvaluateHpBarRange == true
        and hpBarOutOfRangeDistance ~= nil
        and tonumber(player.distance) ~= nil
        and tonumber(player.distance) > hpBarOutOfRangeDistance;
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

    local liveHpColor = hpColor;

    if (hpBarOutOfRange == true) then
        local source = hpBarSettings.outOfRangeColor or { 0.02, 0.08, 0.12, 1.0 };
        liveHpColor = {
            tonumber(source[1]) or 1.0,
            tonumber(source[2]) or 1.0,
            tonumber(source[3]) or 1.0,
            1.0,
        };
    end

    local function makeLiveBarStyle(settings, color, defaultWidth, defaultHeight, defaultOffsetY)
        settings = settings or {};

        if (canUseLiveResourceBarSettings(settings) ~= true) then
            return { enabled = false };
        end

        local barHeight = tonumber(settings.height) or defaultHeight or 12;
        local offsetY = tonumber(settings.offsetY) or defaultOffsetY or 0;

        return {
            enabled = true,
            worldWidth = math.max(0.04, (tonumber(settings.width) or defaultWidth or 180) / 430),
            worldHeight = math.max(0.006, barHeight / 260),
            worldOffsetX = (tonumber(settings.offsetX) or 0) / 430,
            worldOffsetY = offsetY / 260,
            color = color,
            backgroundColor = settings.backgroundColor,
            borderColor = settings.borderColor,
            borderWorldSize = math.max(0, tonumber(settings.borderSize) or 0) / 260,
            showAtPercent = tonumber(settings.showAtPercent) or 100,
        };
    end

    local liveHpBarStyle = hpBarLoads == true and makeLiveBarStyle(hpBarSettings, liveHpColor, 180, 12, 0) or { enabled = false };
    local liveMpBarStyle = mpBarLoads == true and makeLiveBarStyle(mpBarSettings, mpColor, 180, 8, 16) or { enabled = false };
    local liveTpBarStyle = tpBarLoads == true and makeLiveBarStyle(tpBarSettings, tpColor, 180, 6, 28) or { enabled = false };

    local iconsTimer = perfMeter.BeginDetail('pc.icons');
    local gameModeIconTextureId = nil;
    local linkshellIconTextureId = nil;
    local linkshellIconTint = nil;
    local bazaarIconTextureId = nil;
    local awayIconTextureId = nil;
    local disconnectIconTextureId = nil;
    local anonIconTextureId = nil;
    local starsIconTextureId = nil;
    local levelSyncIconTextureId = nil;
    local newAdventurerIconTextureId = nil;
    local allianceLeaderIconTextureId = nil;
    local partyLeaderIconTextureId = nil;
    local playerGameModeText = gameMode.Resolve(player.index, false);
    local playerAnonNameColor = playerIndicators.HasAnonNameColor(player.index) == true;
    local staffInfo = ResolveStaffInfo(player);
    local staffIconTextureId = nil;

    if (staffInfo ~= nil) then
        staffIconTextureId = GetStaffIconTextureId(staffInfo.icon);
        AddIcon(icons, { enabled = true, iconSize = 28, offsetX = -42, offsetY = -78 }, staffIconTextureId, -42, -78, 'staffIcon');
    end

    if (suppressExpensiveWorldWidgets ~= true and WidgetLoads(gameModeIconSettings, 'Game mode icon') == true) then
        gameModeIconTextureId = gameMode.GetIconTextureId(playerGameModeText);
        AddIcon(icons, gameModeIconSettings, gameModeIconTextureId, -72, -54, 'gameModeIcon');
    end

    if (suppressExpensiveWorldWidgets ~= true and WidgetLoads(linkshellIconSettings, 'Linkshell icon') == true) then
        linkshellIconTextureId = playerIndicators.GetLinkshellIconTextureId(player.index);
        linkshellIconTint = playerIndicators.GetLinkshellIconTint(player.index);
        AddIcon(icons, linkshellIconSettings, linkshellIconTextureId, 48, -54, 'linkshellIcon', linkshellIconTint);
    end

    if (suppressExpensiveWorldWidgets ~= true and WidgetLoads(bazaarIconSettings, 'Bazaar icon') == true) then
        bazaarIconTextureId = playerIndicators.GetBazaarIconTextureId(player.index);
        AddIcon(icons, bazaarIconSettings, bazaarIconTextureId, 72, -54, 'bazaarIcon');
    end

    if (suppressExpensiveWorldWidgets ~= true and WidgetLoads(awayIconSettings, 'Away icon') == true) then
        awayIconTextureId = playerIndicators.GetAwayIconTextureId(player.index);
        AddIcon(icons, awayIconSettings, awayIconTextureId, 120, -54, 'awayIcon');
    end

    if (suppressExpensiveWorldWidgets ~= true and WidgetLoads(disconnectIconSettings, 'Disconnect icon') == true) then
        disconnectIconTextureId = playerIndicators.GetDisconnectIconTextureId(player.index);
        AddIcon(icons, disconnectIconSettings, disconnectIconTextureId, 144, -54, 'disconnectIcon');
    end

    if (suppressExpensiveWorldWidgets ~= true and WidgetLoads(anonIconSettings, 'Anon icon') == true) then
        anonIconTextureId = playerIndicators.GetAnonIconTextureId(player.index);
        AddIcon(icons, anonIconSettings, anonIconTextureId, -120, -54, 'anonIcon');
    end

    if (suppressExpensiveWorldWidgets ~= true and WidgetLoads(starsIconSettings, 'Stars icon') == true) then
        starsIconTextureId = playerIndicators.GetStarsIconTextureId(player.index);
        AddIcon(icons, starsIconSettings, starsIconTextureId, -48, -54, 'starsIcon');
    end

    if (suppressExpensiveWorldWidgets ~= true and WidgetLoads(levelSyncIconSettings, 'Level sync icon') == true and partyStatuses.HasLevelSyncStatus(player.serverId) == true) then
        levelSyncIconTextureId = playerIndicators.GetStaticIconTextureId('lvsync');
        AddIcon(icons, levelSyncIconSettings, levelSyncIconTextureId, -24, -54, 'levelSyncIcon');
    end

    if (suppressExpensiveWorldWidgets ~= true and WidgetLoads(newAdventurerIconSettings, 'New adventurer icon') == true) then
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

    if (showDistanceBadge == true and player.distance ~= nil) then
        distanceText = FormatDistanceText(distanceSettings, player.distance);
    end

    local isEngaged = tonumber(player.status) == 1;
    local buffsLoad = suppressExpensiveWorldWidgets ~= true and ShouldLoadStatusRows(buffsSettings, 'Buffs', isEngaged);
    local debuffsLoad = suppressExpensiveWorldWidgets ~= true and ShouldLoadStatusRows(debuffsSettings, 'Debuffs', isEngaged);
    local buffRows = buffsLoad == true and partyStatuses.GetMemberRows(player.serverId, 'buff') or {};
    local debuffRows = debuffsLoad == true and partyStatuses.GetMemberRows(player.serverId, 'debuff') or {};

    local function statusRowsSignature(rows)
        local parts = {};

        for index, row in ipairs(rows or {}) do
            local statusId = type(row) == 'table' and row.id or row;
            local seconds = type(row) == 'table' and tonumber(row.seconds) or nil;

            parts[#parts + 1] = tostring(statusId or '');

            if (seconds ~= nil and seconds >= 0) then
                parts[#parts] = parts[#parts] .. ':' .. tostring(math.floor(seconds + 0.5));
            end
        end

        return table.concat(parts, ',');
    end

    local nameAoeActive = isPartyPlayer == true and aoeRangeSettings.enabled == true and aoeNameHighlight.IsHighlighted(player.index, 'pc') == true;
    local enmityAllyDraws = layoutStateName == 'Combat' and enmity.ShouldDrawAlly(player, globalSettings) == true;
    local targetMarkerDraws = targetMarker ~= nil and targetMarker.enabled == true;

    if (
        backgroundLoads ~= true and
        nameLoads ~= true and
        hpBarLoads ~= true and
        mpBarLoads ~= true and
        tpBarLoads ~= true and
        jobLoads ~= true and
        levelLoads ~= true and
        buffsLoad ~= true and
        debuffsLoad ~= true and
        distanceText == nil and
        #icons == 0 and
        targetMarkerDraws ~= true and
        enmityAllyDraws ~= true and
        nameAoeActive ~= true
    ) then
        indexCache[tonumber(player.index) or 0] = nil;
        return;
    end

    local cacheEligible = targetStateName == 'Idle'
        and state.GetConfigOpen() ~= true
        and distanceText == nil
        and (hpBarLoads ~= true or liveHpBarStyle.enabled == true or hpAnimationEnabled ~= true)
        and (mpBarLoads ~= true or liveMpBarStyle.enabled == true or mpAnimationEnabled ~= true)
        and (tpBarLoads ~= true or liveTpBarStyle.enabled == true);

    local cacheKey = nil;
    local signature = nil;
    local staleCached = nil;
    local blacklistSignature = require('core.player_blacklist').GetSignature(player);
    local streamerNames = require('core.streamer_names');
    local streamerNameSignature = streamerNames.GetSignature(player, targeting.GetSettings());
    local canUseStaleCachedPlate =
        (hpBarLoads ~= true or liveHpBarStyle.enabled == true) and
        (mpBarLoads ~= true or liveMpBarStyle.enabled == true) and
        (tpBarLoads ~= true or liveTpBarStyle.enabled == true);

    if (cacheEligible == true) then
        cacheKey = 'pc:' .. tostring(player.index) .. ':' .. GetPlayerIdentityKey(player);
        signature = table.concat({
            'v=1',
            'policy=' .. canvasTexture.GetRenderPolicyKey(),
            'overwriteNativeNameColors=' .. tostring(targeting.GetSettings().overwriteNativeNameColors ~= false),
            'blacklist=' .. blacklistSignature,
            streamerNameSignature,
            'gameModeText=' .. tostring(playerGameModeText or ''),
            'anonNameColor=' .. tostring(playerAnonNameColor),
            'statusIconPack=' .. tostring(globalSettings ~= nil and globalSettings.statusIcons ~= nil and globalSettings.statusIcons.iconPack or ''),
            'name=' .. tostring(player.name or ''),
            'layout=' .. tostring(layoutStateName or ''),
            'overlay=' .. (useTargetOverlay == true and '1' or '0'),
            'targetState=' .. tostring(targetStateName or 'Idle'),
            'status=' .. tostring(player.status or ''),
            'engaged=' .. (currentPlayerEngaged == true and '1' or '0'),
            'hasHp=' .. (hasHp == true and '1' or '0'),
            'hpPercent=' .. tostring(hpPercent or ''),
            'hpValue=' .. tostring(player.hp or ''),
            'hpMax=' .. tostring(player.maxHp or ''),
            'hasMp=' .. (hasMp == true and '1' or '0'),
            'mpPercent=' .. tostring(mpPercent or ''),
            'mpValue=' .. tostring(player.mp or ''),
            'mpMax=' .. tostring(player.maxMp or ''),
            'hasTp=' .. (hasTp == true and '1' or '0'),
            'tpValue=' .. tostring(tpValue or ''),
            'distance=' .. tostring(distanceText or ''),
            'game=' .. tostring(gameModeIconTextureId or ''),
            'linkshell=' .. tostring(linkshellIconTextureId or ''),
            'linkshellTint=' .. ColorKey(linkshellIconTint),
            'bazaar=' .. tostring(bazaarIconTextureId or ''),
            'away=' .. tostring(awayIconTextureId or ''),
            'disconnect=' .. tostring(disconnectIconTextureId or ''),
            'stars=' .. tostring(starsIconTextureId or ''),
            'lvsync=' .. tostring(levelSyncIconTextureId or ''),
            'new=' .. tostring(newAdventurerIconTextureId or ''),
            'staff=' .. tostring(staffIconTextureId or '') .. ':' .. tostring(staffInfo ~= nil and staffInfo.type or ''),
            'aoe=' .. (isPartyPlayer == true and aoeRangeSettings.enabled == true and aoeNameHighlight.GetSignature(player.index, 'pc') or 'aoe-name:0'),
            'buffs=' .. statusRowsSignature(buffRows),
            'debuffs=' .. statusRowsSignature(debuffRows),
            'aoeSettings=' .. SettingKey(aoeRangeSettings, { 'enabled', 'fontSize', 'fontColor', 'iconEnabled', 'iconSize', 'iconOffsetX', 'iconOffsetY' }),
            'bg:' .. SettingKey(backgroundSettings, { 'enabled', 'loadMode', 'width', 'height', 'offsetX', 'offsetY', 'texture', 'color', 'borderColor', 'borderSize', 'anchorTo', 'anchorPoint' }),
            'name:' .. SettingKey(nameSettings, { 'enabled', 'loadMode', 'shortenName', 'textSize', 'color', 'outlineSize', 'outlineColor', 'offsetX', 'offsetY', 'anchorTo', 'anchorPoint' }),
            'dist:' .. SettingKey(distanceSettings, { 'enabled', 'loadMode', 'textSize', 'color', 'outlineEnabled', 'outlineColor', 'outlineSize', 'useSmallFont', 'offsetX', 'offsetY', 'prefix', 'anchorTo', 'anchorPoint' }),
            'hp:' .. SettingKey(hpBarSettings, { 'enabled', 'loadMode', 'width', 'height', 'offsetX', 'offsetY', 'color', 'backgroundColor', 'borderColor', 'borderSize', 'anchorTo', 'anchorPoint', 'texture', 'textureStrength', 'showValue', 'showPercent', 'showAtPercent', 'fontSize', 'textColor', 'textOutlineEnabled', 'textOutlineColor', 'textOutlineSize', 'outOfRangeOpacityEnabled', 'outOfRangeDefaultDistance', 'outOfRangeColor' }),
            'mp:' .. SettingKey(mpBarSettings, { 'enabled', 'loadMode', 'width', 'height', 'offsetX', 'offsetY', 'color', 'backgroundColor', 'borderColor', 'borderSize', 'anchorTo', 'anchorPoint', 'texture', 'textureStrength', 'showValue', 'showPercent', 'showAtPercent', 'fontSize', 'textColor', 'textOutlineEnabled', 'textOutlineColor', 'textOutlineSize' }),
            'tp:' .. SettingKey(tpBarSettings, { 'enabled', 'loadMode', 'width', 'height', 'offsetX', 'offsetY', 'color', 'color2', 'color3', 'backgroundColor', 'borderColor', 'borderSize', 'anchorTo', 'anchorPoint', 'texture', 'textureStrength', 'showValue', 'showPercent', 'showAtPercent', 'fontSize', 'textColor', 'textOutlineEnabled', 'textOutlineColor', 'textOutlineSize', 'segmented', 'segmentGap' }),
            'icons=' .. tostring(#icons),
        }, '\n');

        local indexed = indexCache[tonumber(player.index) or 0];
        staleCached = indexed ~= nil and plateCache[indexed.cacheKey] or nil;
        local cached = indexed ~= nil and indexed.signature == signature and staleCached or nil;

        if (QueueCachedPlayer(player, cached, targetStateName, useTargetOverlay, layoutStateName, hasHp, hasMp, hasTp, hpPercent, mpPercent, tpValue, liveHpBarStyle, liveMpBarStyle, liveTpBarStyle, isProtectedPlate, isPartyPlayer) == true) then
            cached.lastFullRefresh = os.clock();
            perfMeter.Count('pc.cache.hit', 1);
            return;
        end

        if (
            canUseStaleCachedPlate == true and
            adaptivePerformance.ShouldThrottleBackground() == true and
            staleCached ~= nil and
            (os.clock() - (tonumber(staleCached.lastUsed) or 0)) < 1.00 and
            QueueCachedPlayer(player, staleCached, targetStateName, useTargetOverlay, layoutStateName, hasHp, hasMp, hasTp, hpPercent, mpPercent, tpValue, liveHpBarStyle, liveMpBarStyle, liveTpBarStyle, isProtectedPlate, isPartyPlayer) == true
        ) then
            perfMeter.Count('pc.cache.smooth', 1);
            return;
        end

        perfMeter.Count('pc.cache.miss', 1);
    end

    if (
        cacheEligible == true and
        canUseStaleCachedPlate == true and
        (
            ShouldDeferIdlePcCanvasBuild(cacheEligible) == true or
            (
                adaptivePerformance.ShouldThrottleBackground() == true and
                adaptivePerformance.AllowBackgroundBuild('pc.idle.canvas', 1) ~= true
            )
        )
    ) then
        if (
            staleCached ~= nil and
            QueueCachedPlayer(player, staleCached, targetStateName, useTargetOverlay, layoutStateName, hasHp, hasMp, hasTp, hpPercent, mpPercent, tpValue, liveHpBarStyle, liveMpBarStyle, liveTpBarStyle, isProtectedPlate, isPartyPlayer) == true
        ) then
            perfMeter.Count('pc.cache.deferred', 1);
        else
            perfMeter.Count('pc.cache.deferredCold', 1);
        end

        return;
    end

    local buildTimer = perfMeter.BeginDetail('pc.build');
    local nameTextSize = nameAoeActive == true and math.max(tonumber(nameSettings.textSize) or nameDefaults.textSize, tonumber(aoeRangeSettings.fontSize) or aoeRangeDefaults.fontSize) or nameSettings.textSize;
    local plateData = BuildPcPlateData({
        player = player,
        hpPercent = hpPercent,
        mpPercent = mpPercent,
        tpPercent = tpPercent,
        tpValue = tpValue,
        nameAoeActive = nameAoeActive,
        nameTextSize = nameTextSize,
        nameLoads = nameLoads,
        nameSettings = nameSettings,
        hpBarLoads = hpBarLoads,
        hpBarSettings = hpBarSettings,
        hpColor = hpColor,
        hpAnimationEnabled = hpAnimationEnabled,
        hpBarOutOfRange = hpBarOutOfRange,
        mpBarLoads = mpBarLoads,
        mpBarSettings = mpBarSettings,
        mpColor = mpColor,
        mpAnimationEnabled = mpAnimationEnabled,
        tpBarLoads = tpBarLoads,
        tpBarSettings = tpBarSettings,
        tpColor = tpColor,
        targetMarker = targetMarker,
        gameModeText = playerGameModeText,
        icons = icons,
        anchorFallbackDefinitions = {
            { kind = 'gameModeIcon', settings = gameModeIconSettings, defaults = gameModeIconDefaults, defaultX = -72, defaultY = -54 },
            { kind = 'linkshellIcon', settings = linkshellIconSettings, defaults = linkshellIconDefaults, defaultX = 48, defaultY = -54 },
            { kind = 'bazaarIcon', settings = bazaarIconSettings, defaults = bazaarIconDefaults, defaultX = 72, defaultY = -54 },
            { kind = 'awayIcon', settings = awayIconSettings, defaults = awayIconDefaults, defaultX = 120, defaultY = -54 },
            { kind = 'disconnectIcon', settings = disconnectIconSettings, defaults = disconnectIconDefaults, defaultX = 144, defaultY = -54 },
            { kind = 'anonIcon', settings = anonIconSettings, defaults = anonIconDefaults, defaultX = -120, defaultY = -54 },
            { kind = 'starsIcon', settings = starsIconSettings, defaults = starsIconDefaults, defaultX = -48, defaultY = -54 },
            { kind = 'levelSyncIcon', settings = levelSyncIconSettings, defaults = levelSyncIconDefaults, defaultX = -24, defaultY = -54 },
            { kind = 'newAdventurerIcon', settings = newAdventurerIconSettings, defaults = newAdventurerIconDefaults, defaultX = 24, defaultY = -54 },
            { kind = 'partyLeaderIcon', settings = partyLeaderIconSettings, defaults = partyLeaderIconDefaults, defaultX = -96, defaultY = -54 },
            { kind = 'allianceLeaderIcon', settings = allianceLeaderIconSettings, defaults = allianceLeaderIconDefaults, defaultX = -120, defaultY = -54 },
        },
        backgroundLoads = backgroundLoads,
        backgroundSettings = backgroundSettings,
        globalSettings = globalSettings,
        aoeRangeSettings = aoeRangeSettings,
    });
    if (cacheEligible == true) then
        if (liveHpBarStyle.enabled == true) then
            plateData.hpBar = { enabled = false };
        end

        if (liveMpBarStyle.enabled == true) then
            plateData.mpBar = { enabled = false };
        end

        if (liveTpBarStyle.enabled == true) then
            plateData.tpBar = { enabled = false };
        end
    end

    if (jobLoads == true) then
        AddJobToPlate(plateData, GetJobText(player.mainJob), jobSettings, globalSettings);
    end

    if (levelLoads == true) then
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

    if (buffsLoad == true) then
        AddStatusIconsToPlate(plateData, buffRows, buffsSettings, isEngaged, globalSettings, 'buffs');
    end

    if (debuffsLoad == true) then
        AddStatusIconsToPlate(plateData, debuffRows, debuffsSettings, isEngaged, globalSettings, 'debuffs');
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

    if (enmityAllyDraws == true) then
        enmity.AddIcon(plateData, globalSettings.enmity, 'ally');
    end
    if (plateData.aoeNameActive == true) then
        aoeRangeVisuals.Apply(plateData, aoeRangeSettings, hpBarSettings);
    end
    perfMeter.EndDetail(buildTimer);

    local canvasTimer = perfMeter.BeginDetail('pc.canvas');
    local textureKey = 'pc-' .. tostring(player.index) .. '-' .. GetPlayerIdentityKey(player):gsub('[^%w%-_]', '-') .. (plateData.canvasWidth ~= nil and '-aoe' or '');
    local plateTexture, textureWidth, textureHeight = canvasTexture.Render(plateData, textureKey);
    local plateTextureId = canvasTexture.GetTextureId(plateTexture);
    local elementRects = plateData._elementRects or canvasTexture.GetElementRects(plateData);
    perfMeter.EndDetail(canvasTimer);

    if (plateTextureId == nil) then
        return;
    end

    local playerMounted = require('core.mounted').IsStatus(player.status);
    local plateWorldOffsetY = playerMounted and (0.05 - mountedPlateLift) or 0.05;

    if (cacheEligible == true and cacheKey ~= nil and signature ~= nil) then
        plateCache[cacheKey] = {
            signature = signature,
            texture = plateTexture,
            textureKey = textureKey,
            identityKey = GetPlayerIdentityKey(player),
            serverId = player.serverId,
            name = player.name,
            streamerNameSignature = streamerNameSignature,
            lastUsed = os.clock(),
            lastFullRefresh = os.clock(),
            hasDynamicVisuals = buffsLoad == true or debuffsLoad == true or (distanceText ~= nil and distanceText ~= ''),
            textureWidth = textureWidth,
            textureHeight = textureHeight,
            elementRects = elementRects,
            plateWorldWidth = 2.35,
            plateWorldOffsetY = plateWorldOffsetY,
            hpBar = liveHpBarStyle,
            mpBar = liveMpBarStyle,
            tpBar = liveTpBarStyle,
        };
        indexCache[tonumber(player.index) or 0] = {
            cacheKey = cacheKey,
            signature = signature,
        };
    else
        indexCache[tonumber(player.index) or 0] = nil;
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
        isProtectedPlate = isProtectedPlate == true,
        isPartyPlayer = isPartyPlayer == true,
        stateName = targetStateName,
        clickTargetType = 'pc',
        worldMarker = targeting.ApplyPlateScalingSettings({
            hpBar = liveHpBarStyle,
            mpBar = liveMpBarStyle,
            tpBar = liveTpBarStyle,
            liveResourceBars = false,
            plateTextureId = plateTextureId,
            plateAlwaysOnTop = isProtectedPlate == true or useTargetOverlay == true,
            plateTacticalOverlayOnly = useTargetOverlay == true,
            useExactNameplateAnchor = true,
            plateWorldWidth = 2.35,
            plateWorldHeight = 1.18,
            plateWorldOffsetY = plateWorldOffsetY,
            plateDistanceScaleOffsetY = 0.28,
            pcBodyPlateOffsetEnabled = true,
            plateTextureWidth = textureWidth,
            plateTextureHeight = textureHeight,
            plateClickRects = elementRects,
            clickTargetType = 'pc',
            clickName = player.name,
            layoutStateName = layoutStateName,
            protectedPlate = isProtectedPlate == true,
            partyPlate = isPartyPlayer == true,
        }, 'pc', 0, plateWorldOffsetY),
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

    currentPlayerEngaged = targeting.IsPlayerEngaged() == true;

    local canRenderWorldPlayers = AnyPcIdleWorldPlateWorkCanLoad() == true;
    local canRenderPartyPlayers = AnyPcPartyPlateWorkCanLoad() == true;
    local canRenderTargetPlayers = AnyPcTargetModuleCanLoad() == true;

    if (canRenderWorldPlayers ~= true and canRenderPartyPlayers ~= true and canRenderTargetPlayers ~= true) then
        scanCache.players = nil;
        return;
    end

    local range = targeting.GetWorldPlateRange();
    local queuedSpecialPlayers = {};

    if (canRenderPartyPlayers == true) then
        for _, player in ipairs(entities.GetPartyPlayers(range)) do
            queuedSpecialPlayers[tonumber(player.index) or 0] = true;
            QueuePlayer(player);
        end
    end

    if (canRenderTargetPlayers == true) then
        local queuedTargets = {};
        local targetIndex, subTargetIndex = targeting.GetCurrentTargetAndSubTargetIndexes();
        local targetIndexes = { targetIndex, subTargetIndex };

        for targetSlot = 1, 2 do
            local index = targetIndexes[targetSlot];
            index = tonumber(index);

            if (index ~= nil and queuedTargets[index] ~= true) then
                queuedTargets[index] = true;

                local player = entities.GetPlayerByIndex(index, range);
                if (player ~= nil) then
                    queuedSpecialPlayers[tonumber(player.index) or 0] = true;
                    QueuePlayer(player);
                end
            end
        end
    end

    if (canRenderWorldPlayers ~= true) then
        scanCache.players = nil;
        return;
    end

    local now = os.clock();
    local canUseScanCache = currentPlayerEngaged ~= true
        and state.GetConfigOpen() ~= true;
    local players = nil;

    if (
        canUseScanCache == true and
        scanCache.players ~= nil and
        scanCache.range == range and
        (now - (tonumber(scanCache.clock) or 0)) < adaptivePerformance.GetWorldRefreshSeconds('pc')
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

    pcIdleCanvasBuildsThisFrame = 0;
    if (#players >= 30) then
        pcIdleCanvasBuildLimitThisFrame = 3;
    elseif (#players >= 18) then
        pcIdleCanvasBuildLimitThisFrame = 5;
    elseif (#players >= 10) then
        pcIdleCanvasBuildLimitThisFrame = 8;
    else
        pcIdleCanvasBuildLimitThisFrame = 0;
    end

    for _, player in ipairs(players) do
        if (queuedSpecialPlayers[tonumber(player.index) or 0] ~= true and entities.IsOwnPetIndex(player.index) ~= true) then
            QueuePlayer(player);
        end
    end

    pcIdleCanvasBuildLimitThisFrame = 0;
end

return pcPlate;
