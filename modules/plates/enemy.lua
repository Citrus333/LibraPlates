local nameDefaults = require('config.widgets.name');
local ffi = require('ffi');
local bit = require('bit');
local backgroundDefaults = require('config.widgets.background');
local barDefaults = require('config.widgets.bar');
local buffsDefaults = require('config.widgets.buffs');
local castBarDefaults = require('config.widgets.cast_bar');
local debuffsDefaults = require('config.widgets.debuffs');
local jobDefaults = require('config.widgets.job');
local levelDefaults = require('config.widgets.level');
local idDefaults = require('config.widgets.id');
local distanceDefaults = require('config.widgets.distance');
local globalDefaults = require('config.global');
local fonts = require('core.fonts');
local textScale = require('core.text_scale');
local canvasTexture = require('core.canvas_texture');
local barTextures = require('core.bar_textures');
local textureLoader = require('core.texture_loader');
local jobIconTextures = require('core.job_icon_textures');
local entities = require('core.entities');
local mobInfoData = require('core.mobinfo_data');
local perfMeter = require('core.perf_meter');
local adaptivePerformance = require('core.adaptive_performance');
local state = require('core.state');
local targeting = require('core.targeting');
local engagedEnemies = require('core.engaged_enemies');
local enmity = require('core.enmity');
local enemyCasts = require('core.enemy_casts');
local enemyStatuses = require('core.enemy_statuses');
local statusIconTextures = require('core.status_icon_textures');
local statusTimerFormat = require('core.status_timer_format');
local targetModuleMarker = require('core.target_module_marker');
local worldDepthPlate = require('core.world_depth_plate');
local worldMarkerProbe = require('core.world_marker_probe');

local enemyPlate = {};
local targetOverlayEnabled = true;
local enemyAnchorBone = 2;
local enemyWorldOffsetY = 0.50;
local user32 = nil;
local mobInfoIconTextureIds = {};
local catseyeIconTextureIds = {};
local plateCache = {};
local indexCache = {};
local maxPlateCacheEntries = 64;
local lastPlateCacheTrim = 0;
local nonCombatZoneIds = {
    [26] = true, -- Tavnazian Safehold
    [50] = true, -- Aht Urhgan Whitegate
    [53] = true, -- Nashmau
    [80] = true, -- Southern San d'Oria [S]
    [87] = true, -- Bastok Markets [S]
    [94] = true, -- Windurst Waters [S]
    [230] = true, -- Southern San d'Oria
    [231] = true, -- Northern San d'Oria
    [232] = true, -- Port San d'Oria
    [233] = true, -- Chateau d'Oraguille
    [234] = true, -- Bastok Mines
    [235] = true, -- Bastok Markets
    [236] = true, -- Port Bastok
    [237] = true, -- Metalworks
    [238] = true, -- Windurst Waters
    [239] = true, -- Windurst Walls
    [240] = true, -- Port Windurst
    [241] = true, -- Windurst Woods
    [242] = true, -- Heavens Tower
    [243] = true, -- Ru'Lude Gardens
    [244] = true, -- Upper Jeuno
    [245] = true, -- Lower Jeuno
    [246] = true, -- Port Jeuno
    [247] = true, -- Rabao
    [248] = true, -- Selbina
    [249] = true, -- Mhaura
    [250] = true, -- Kazham
    [252] = true, -- Norg
    [256] = true, -- Western Adoulin
    [257] = true, -- Eastern Adoulin
    [280] = true, -- Mog Garden
    [281] = true, -- Leafallia
    [284] = true, -- Celennia Memorial Library
};

pcall(function()
    ffi.cdef[[
        short __stdcall GetAsyncKeyState(int vKey);
    ]];

    user32 = ffi.load('user32');
end);

local function IsVirtualKeyDown(vk)
    if (user32 == nil) then
        return false;
    end

    local ok, keyState = pcall(function()
        return user32.GetAsyncKeyState(vk);
    end);

    return ok == true and bit.band(tonumber(keyState) or 0, 0x8000) ~= 0;
end

local function IsPeerModifierActive(peerSettings)
    local modifier = tostring(peerSettings ~= nil and peerSettings.activationModifier or 'Shift');

    if (modifier == 'None') then
        return true;
    end

    if (modifier == 'Ctrl') then
        return IsVirtualKeyDown(0x11);
    end

    if (modifier == 'Alt') then
        return IsVirtualKeyDown(0x12);
    end

    return IsVirtualKeyDown(0x10);
end

local function GetCurrentZoneId()
    local zoneId = nil;

    pcall(function()
        zoneId = AshitaCore:GetMemoryManager():GetParty():GetMemberZone(0);
    end);

    return tonumber(zoneId);
end

local function IsNonCombatZone()
    local zoneId = GetCurrentZoneId();

    return zoneId ~= nil and nonCombatZoneIds[zoneId] == true;
end

local function IsAlTaieuFish(name)
    local zoneId = GetCurrentZoneId();

    if (zoneId ~= 33) then
        return false;
    end

    name = tostring(name or ''):gsub('\170', ''):lower();

    return name == "ul'hpemde" or name == "ul'phuabo";
end

local function GetPeerHoverScale(peerSettings)
    return math.max(1.0, math.min(15.0, tonumber(peerSettings ~= nil and peerSettings.zoom) or 3.0));
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

local function ShortenName(name, maxLength)
    local text = tostring(name or '');
    local limit = tonumber(maxLength) or 0;

    if (limit > 0 and string.len(text) > limit) then
        return string.sub(text, 1, limit);
    end

    return text;
end

local function GetAddonPath()
    local ok, path = pcall(function()
        return AshitaCore:GetInstallPath() .. '\\addons\\LibraPlates\\';
    end);

    if (ok == true and path ~= nil) then
        return tostring(path);
    end

    return '.\\';
end

local function SanitizeIconStyle(iconStyle)
    local style = tostring(iconStyle or 'round'):gsub('[\\/]', '');

    if (style == '') then
        return 'round';
    end

    return style;
end

local function GetMobInfoIconPath(iconName, iconStyle)
    return GetAddonPath() ..
        'assets\\images\\peer-icons\\' ..
        SanitizeIconStyle(iconStyle) ..
        '\\' ..
        tostring(iconName or '') ..
        '.png';
end

local function GetMobInfoIconTextureId(iconName, iconStyle)
    iconName = tostring(iconName or '');
    iconStyle = SanitizeIconStyle(iconStyle);

    if (iconName == '') then
        return nil;
    end

    local cacheKey = iconStyle .. ':' .. iconName;

    if (mobInfoIconTextureIds[cacheKey] ~= nil) then
        return mobInfoIconTextureIds[cacheKey];
    end

    mobInfoIconTextureIds[cacheKey] = textureLoader.ToTextureId(textureLoader.Load(GetMobInfoIconPath(iconName, iconStyle)));
    return mobInfoIconTextureIds[cacheKey];
end

local function GetCatseyeIconTextureId(iconName)
    iconName = tostring(iconName or ''):gsub('^.*[\\/]', '');

    if (iconName == '') then
        return nil;
    end

    if (catseyeIconTextureIds[iconName] ~= nil) then
        return catseyeIconTextureIds[iconName];
    end

    catseyeIconTextureIds[iconName] = textureLoader.ToTextureId(textureLoader.Load(
        GetAddonPath() .. 'assets\\images\\catseye_icons\\' .. iconName
    ));

    return catseyeIconTextureIds[iconName];
end

local function AddActivityPointIconToPlate(plateData, enemyName, nameSettings)
    if (mobInfoData.HasActivityPointMarker(enemyName) ~= true) then
        return;
    end

    local textureId = GetCatseyeIconTextureId('AP.png');

    if (textureId == nil) then
        return;
    end

    local nameSize = tonumber(nameSettings.textSize) or tonumber(nameDefaults.textSize) or 24;
    local iconSize = math.max(24, math.min(96, math.floor((nameSize * 2.2) + 0.5)));

    plateData.icons = plateData.icons or {};
    plateData.icons[#plateData.icons + 1] = {
        kind = 'catseyeAp',
        textureId = textureId,
        size = iconSize,
        offsetX = (tonumber(nameSettings.offsetX) or 0) - iconSize - 8,
        offsetY = (tonumber(nameSettings.offsetY) or -54) + 1,
        anchorTo = nameSettings.anchorTo or nameDefaults.anchorTo,
        anchorPoint = nameSettings.anchorPoint or nameDefaults.anchorPoint,
    };
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
        end

        return;
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

local function FormatModifierPercent(potency)
    potency = tonumber(potency) or 1;

    if (potency > 1) then
        return '+' .. tostring(math.floor(((potency - 1) * 100) + 0.5)) .. '%';
    end

    return '-' .. tostring(math.floor(((1 - potency) * 100) + 0.5)) .. '%';
end

local function AddMobInfoIcon(icons, iconName, offsetX, offsetY, size, iconStyle)
    local textureId = GetMobInfoIconTextureId(iconName, iconStyle);

    if (textureId == nil) then
        return false;
    end

    icons[#icons + 1] = {
        textureId = textureId,
        size = size,
        offsetX = offsetX,
        offsetY = offsetY,
    };

    return true;
end

local function AddMobInfoText(texts, text, offsetX, offsetY, globalSettings, options)
    options = options or {};

    texts[#texts + 1] = {
        text = text,
        offsetX = offsetX,
        offsetY = offsetY,
        fontFamily = fonts.GetRole(globalSettings, options.useSmallFont == true),
        fontFlags = fonts.GetRoleFlags(globalSettings, options.useSmallFont == true),
        fontSize = tonumber(options.fontSize) or 12,
        color = options.color or { 1.0, 1.0, 1.0, 1.0 },
        outlineEnabled = options.outlineEnabled ~= false,
        outlineColor = options.outlineColor or { 0.0, 0.0, 0.0, 1.0 },
        outlineSize = tonumber(options.outlineSize) or 2,
        align = options.align,
    };
end

local function GetPeerTextOptions(peerSettings, prefix)
    return {
        fontSize = textScale.ToTextureFontSize(peerSettings[prefix .. 'FontSize'], 12),
        color = peerSettings[prefix .. 'Color'],
        outlineColor = peerSettings[prefix .. 'OutlineColor'],
        outlineSize = tonumber(peerSettings[prefix .. 'OutlineSize']) or 2,
    };
end

local function AddPeerIconRow(icons, iconNames, peerSettings, prefix, iconStyle)
    if (iconNames == nil or #iconNames == 0) then
        return;
    end

    local iconSize = math.max(6, math.min(64, tonumber(peerSettings[prefix .. 'IconSize']) or tonumber(peerSettings.iconSize) or 18));
    local x = tonumber(peerSettings[prefix .. 'OffsetX']) or tonumber(peerSettings.iconOffsetX) or -190;
    local y = tonumber(peerSettings[prefix .. 'OffsetY']) or tonumber(peerSettings.iconOffsetY) or -16;
    local maxX = x + 395;

    for _, iconName in ipairs(iconNames) do
        if (x > maxX) then break; end

        if (AddMobInfoIcon(icons, iconName, x, y, iconSize, iconStyle) == true) then
            x = x + iconSize + 3;
        end
    end
end

local function ApplyPeerHpBar(plateData, peerSettings, hpPercent, globalSettings)
    if (peerSettings.showHpBar == false) then
        plateData.hpBar.enabled = false;
        return;
    end

    plateData.hpBar.enabled = true;
    plateData.hpBar.width = tonumber(peerSettings.hpBarWidth) or 437;
    plateData.hpBar.height = tonumber(peerSettings.hpBarHeight) or 16;
    plateData.hpBar.offsetX = tonumber(peerSettings.hpBarOffsetX) or 0;
    plateData.hpBar.offsetY = tonumber(peerSettings.hpBarOffsetY) or 0;
    plateData.hpBar.color = peerSettings.hpBarColor or { 0.0, 0.75, 0.16, 1.0 };
    plateData.hpBar.backgroundColor = peerSettings.hpBarBackgroundColor or { 0.05, 0.05, 0.05, 0.85 };
    plateData.hpBar.borderColor = peerSettings.hpBarBorderColor or { 0.0, 0.0, 0.0, 1.0 };
    plateData.hpBar.borderSize = tonumber(peerSettings.hpBarBorderSize) or 0;
    plateData.hpBar.text = (peerSettings.showHpPercent ~= false) and (tostring(math.floor((tonumber(hpPercent) or 0) + 0.5)) .. '%') or '';
    plateData.hpBar.textOffsetX = tonumber(peerSettings.hpPercentOffsetX) or 0;
    plateData.hpBar.textOffsetY = tonumber(peerSettings.hpPercentOffsetY) or 0;
    plateData.hpBar.fontFamily = fonts.GetRole(globalSettings, true);
    plateData.hpBar.fontFlags = fonts.GetRoleFlags(globalSettings, true);
    plateData.hpBar.fontSize = textScale.ToTextureFontSize(peerSettings.hpPercentFontSize, 12);
    plateData.hpBar.textColor = peerSettings.hpPercentColor or { 1.0, 1.0, 1.0, 1.0 };
    plateData.hpBar.textOutlineEnabled = (tonumber(peerSettings.hpPercentOutlineSize) or 0) > 0;
    plateData.hpBar.textOutlineColor = peerSettings.hpPercentOutlineColor or { 0.0, 0.0, 0.0, 1.0 };
    plateData.hpBar.textOutlineSize = tonumber(peerSettings.hpPercentOutlineSize) or 2;
end

local function ApplyPeerBackground(plateData, peerSettings)
    plateData.background = plateData.background or {};

    plateData.background.enabled = true;
    plateData.background.width = tonumber(peerSettings.backgroundWidth) or 460;
    plateData.background.height = tonumber(peerSettings.backgroundHeight) or 72;
    plateData.background.offsetX = tonumber(peerSettings.backgroundOffsetX) or 0;
    plateData.background.offsetY = tonumber(peerSettings.backgroundOffsetY) or 0;

    local color = peerSettings.backgroundColor or { 0.0, 0.0, 0.0, 0.45 };
    plateData.background.color = {
        tonumber(color[1]) or 0.0,
        tonumber(color[2]) or 0.0,
        tonumber(color[3]) or 0.0,
        math.max(0.0, math.min(1.0, (tonumber(peerSettings.backgroundOpacity) or ((tonumber(color[4]) or 0.45) * 100)) / 100)),
    };
    plateData.background.borderColor = peerSettings.backgroundBorderColor or { 0.0, 0.0, 0.0, 1.0 };
    plateData.background.borderSize = tonumber(peerSettings.backgroundBorderSize) or 0;
end

local function ApplyPeerName(plateData, peerSettings, globalSettings)
    if (peerSettings.showName == false) then
        plateData.name = '';
        return;
    end

    plateData.nameFontFamily = fonts.GetRole(globalSettings, false);
    plateData.nameFontFlags = fonts.GetRoleFlags(globalSettings, false);
    plateData.nameFontSize = textScale.ToTextureFontSize(peerSettings.nameFontSize, 32);
    plateData.nameColor = peerSettings.nameColor or { 1.0, 1.0, 1.0, 1.0 };
    plateData.nameOutlineEnabled = (tonumber(peerSettings.nameOutlineSize) or 0) > 0;
    plateData.nameOutlineColor = peerSettings.nameOutlineColor or { 0.0, 0.0, 0.0, 1.0 };
    plateData.nameOutlineSize = tonumber(peerSettings.nameOutlineSize) or 3;
    plateData.nameOffsetX = tonumber(peerSettings.nameOffsetX) or 0;
    plateData.nameOffsetY = tonumber(peerSettings.nameOffsetY) or -54;
end

local function GetPeerViewerLevel()
    local level = 0;

    pcall(function()
        level = AshitaCore:GetMemoryManager():GetParty():GetMemberMainJobLevel(0);
    end);

    return tonumber(level) or 0;
end

local function GetPeerDifficultyKey(mobInfo)
    local viewerLevel = GetPeerViewerLevel();
    local mobLevel = mobInfo ~= nil and (mobInfo.MaxLevel or mobInfo.Level or mobInfo.MinLevel) or nil;

    viewerLevel = tonumber(viewerLevel) or 0;
    mobLevel = tonumber(mobLevel);

    if (viewerLevel <= 0 or mobLevel == nil) then
        return nil;
    end

    local delta = mobLevel - viewerLevel;

    if (delta <= -21) then return 'tw'; end
    if (delta <= -8) then return 'ep'; end
    if (delta <= -1) then return 'dc'; end
    if (delta == 0) then return 'em'; end
    if (delta <= 6) then return 't'; end
    if (delta == 7) then return 'vt'; end
    return 'it';
end

local function GetPeerLevelColor(peerSettings, mobInfo)
    if (peerSettings == nil or peerSettings.levelDifficultyColorsEnabled ~= true) then
        return peerSettings ~= nil and peerSettings.levelColor or { 1.0, 1.0, 1.0, 1.0 };
    end

    local key = GetPeerDifficultyKey(mobInfo);

    if (key == 'tw') then return peerSettings.levelTwColor or peerSettings.levelColor; end
    if (key == 'ep') then return peerSettings.levelEpColor or peerSettings.levelColor; end
    if (key == 'dc') then return peerSettings.levelDcColor or peerSettings.levelColor; end
    if (key == 'em') then return peerSettings.levelEmColor or peerSettings.levelColor; end
    if (key == 't') then return peerSettings.levelTColor or peerSettings.levelColor; end
    if (key == 'vt') then return peerSettings.levelVtColor or peerSettings.levelColor; end
    if (key == 'it') then return peerSettings.levelItColor or peerSettings.levelColor; end

    return peerSettings.levelColor or { 1.0, 1.0, 1.0, 1.0 };
end

local function AddPeerIdToPlate(plateData, enemy, peerSettings, globalSettings)
    if (peerSettings.showId ~= true or enemy == nil) then
        return;
    end

    local idValue = tonumber(enemy.serverId) or tonumber(enemy.index) or 0;

    if (idValue <= 0) then
        return;
    end

    local boxSize = tonumber(peerSettings.idBoxSize) or 18;

    plateData.badges = plateData.badges or {};
    plateData.badges[#plateData.badges + 1] = {
        kind = 'peerId',
        text = string.format('%02d', idValue % 100),
        offsetX = tonumber(peerSettings.idOffsetX) or 0,
        offsetY = tonumber(peerSettings.idOffsetY) or 24,
        fontFamily = fonts.GetRole(globalSettings, true),
        fontFlags = fonts.GetRoleFlags(globalSettings, true),
        fontSize = textScale.ToTextureFontSize(peerSettings.idFontSize, 7),
        textColor = peerSettings.idColor or { 0.65, 0.90, 1.0, 1.0 },
        textOutlineEnabled = (tonumber(peerSettings.idOutlineSize) or 0) > 0,
        textOutlineColor = peerSettings.idOutlineColor or { 0.0, 0.0, 0.0, 1.0 },
        textOutlineSize = tonumber(peerSettings.idOutlineSize) or 2,
        backgroundEnabled = peerSettings.idBoxEnabled == true,
        backgroundColor = peerSettings.idBoxColor or { 0.45, 0.15, 0.15, 0.90 },
        borderColor = peerSettings.idBoxBorderColor or { 1.0, 1.0, 1.0, 1.0 },
        borderSize = tonumber(peerSettings.idBoxBorderSize) or 0,
        paddingX = 0,
        paddingY = 0,
        minWidth = boxSize,
        minHeight = boxSize,
        cornerRadius = tonumber(peerSettings.idCornerRadius) or 4,
    };
end

local function BuildMobInfoRows(enemy, globalSettings, peerSettings)
    local info = mobInfoData.GetMobInfo(enemy.name, enemy.index);
    local icons = {};
    local texts = {};
    local iconStyle = 'round';

    if (info == nil) then
        return icons, texts;
    end

    peerSettings = peerSettings or {};
    iconStyle = SanitizeIconStyle(peerSettings.iconStyle);

    local jobText = mobInfoData.GetJobString(info);
    local levelText = mobInfoData.GetLevelString(info);

    if (peerSettings.showJob ~= false and jobText ~= '') then
        if (tostring(peerSettings.jobDisplay or 'Text') == 'Icon') then
            local textureId = jobIconTextures.GetTextureId(jobText, peerSettings.jobIconTheme);

            if (textureId ~= nil) then
                icons[#icons + 1] = {
                    kind = 'peerJob',
                    textureId = textureId,
                    size = math.max(6, math.min(160, tonumber(peerSettings.jobIconSize) or 18)),
                    offsetX = tonumber(peerSettings.jobOffsetX) or -190,
                    offsetY = tonumber(peerSettings.jobOffsetY) or -16,
                };
            end
        else
            AddMobInfoText(
                texts,
                jobText,
                tonumber(peerSettings.jobOffsetX) or -190,
                tonumber(peerSettings.jobOffsetY) or -16,
                globalSettings,
                GetPeerTextOptions(peerSettings, 'job')
            );
        end
    end

    if (peerSettings.showLevel ~= false and levelText ~= '') then
        local levelOptions = GetPeerTextOptions(peerSettings, 'level');
        levelOptions.color = GetPeerLevelColor(peerSettings, info);

        AddMobInfoText(
            texts,
            levelText,
            tonumber(peerSettings.levelOffsetX) or -145,
            tonumber(peerSettings.levelOffsetY) or -16,
            globalSettings,
            levelOptions
        );
    end

    if (peerSettings.showRange ~= false and enemy.distance ~= nil) then
        AddMobInfoText(
            texts,
            string.format('%.1f', tonumber(enemy.distance) or 0),
            tonumber(peerSettings.rangeOffsetX) or 92,
            tonumber(peerSettings.rangeOffsetY) or -54,
            globalSettings,
            GetPeerTextOptions(peerSettings, 'range')
        );
    end

    local aggroIcons = {};
    local detectionIcons = {};

    for _, iconName in ipairs(mobInfoData.GetFlags(info)) do
        local isAggroIcon = (
            iconName == 'AggroHQ' or
            iconName == 'AggroNQ' or
            iconName == 'PassiveHQ' or
            iconName == 'PassiveNQ'
        );

        if (isAggroIcon == true) then
            aggroIcons[#aggroIcons + 1] = iconName;
        else
            detectionIcons[#detectionIcons + 1] = iconName;
        end
    end

    if (peerSettings.showAggro ~= false) then
        AddPeerIconRow(icons, aggroIcons, peerSettings, 'aggro', iconStyle);
    end

    if (peerSettings.showDetection ~= false) then
        AddPeerIconRow(icons, detectionIcons, peerSettings, 'detection', iconStyle);
    end

    if (peerSettings.showImmunities ~= false) then
        AddPeerIconRow(icons, mobInfoData.GetImmunityFlags(info), peerSettings, 'immunity', iconStyle);
    end

    if (peerSettings.showModifiers ~= false) then
        local iconSize = math.max(6, math.min(64, tonumber(peerSettings.modifierIconSize) or tonumber(peerSettings.iconSize) or 18));
        local x = tonumber(peerSettings.modifierOffsetX) or 120;
        local y = tonumber(peerSettings.modifierOffsetY) or -16;
        local maxX = x + 395;

        for _, modifier in ipairs(mobInfoData.GetModifierRows(info)) do
            if (x > maxX) then break; end

            if (AddMobInfoIcon(icons, modifier.icon, x, y, iconSize, iconStyle) == true) then
                if (peerSettings.showModifierValues ~= false) then
                    AddMobInfoText(texts, FormatModifierPercent(modifier.potency), x, y + (iconSize * 0.5) + 1, globalSettings, {
                        fontSize = textScale.ToTextureFontSize(peerSettings.modifierValueFontSize, 12),
                        color = peerSettings.modifierValueColor,
                        outlineColor = peerSettings.modifierValueOutlineColor,
                        outlineSize = tonumber(peerSettings.modifierValueOutlineSize) or 2,
                        align = 'center',
                    });
                end

                x = x + iconSize + 3;
            end
        end
    end

    return icons, texts;
end

local function BuildCastBar(castData, castBarSettings, globalSettings)
    if (castData == nil or castBarSettings == nil or castBarSettings.enabled ~= true) then
        return nil, 0;
    end

    local castTime = math.max(0.1, tonumber(castData.castTime) or 0.1);
    local elapsed = math.max(0.0, os.clock() - (tonumber(castData.startTime) or os.clock()));
    local castPercent = math.max(0, math.min(100, (elapsed / castTime) * 100));

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
    }, castPercent;
end

local function GetViewerLevel()
    local level = 0;

    pcall(function()
        level = AshitaCore:GetMemoryManager():GetParty():GetMemberMainJobLevel(0);
    end);

    return tonumber(level) or 0;
end

local function GetDifficultyKey(viewerLevel, mobLevel)
    viewerLevel = tonumber(viewerLevel) or 0;
    mobLevel = tonumber(mobLevel);

    if (viewerLevel <= 0 or mobLevel == nil) then
        return nil;
    end

    local delta = mobLevel - viewerLevel;

    if (delta <= -21) then return 'tw'; end
    if (delta <= -8) then return 'ep'; end
    if (delta <= -1) then return 'dc'; end
    if (delta == 0) then return 'em'; end
    if (delta <= 6) then return 't'; end
    if (delta == 7) then return 'vt'; end
    return 'it';
end

local function GetDifficultyColor(settings, defaults, mobInfo)
    if (settings == nil or settings.difficultyColorsEnabled ~= true) then
        return settings ~= nil and settings.color or defaults.color;
    end

    local key = GetDifficultyKey(GetViewerLevel(), mobInfo ~= nil and (mobInfo.MaxLevel or mobInfo.Level or mobInfo.MinLevel));

    if (key == 'tw') then return settings.twColor or defaults.twColor; end
    if (key == 'ep') then return settings.epColor or defaults.epColor; end
    if (key == 'dc') then return settings.dcColor or defaults.dcColor; end
    if (key == 'em') then return settings.emColor or defaults.emColor; end
    if (key == 't') then return settings.tColor or defaults.tColor; end
    if (key == 'vt') then return settings.vtColor or defaults.vtColor; end
    if (key == 'it') then return settings.itColor or defaults.itColor; end

    return settings.color or defaults.color;
end
local function GetClaimNameColor(nameSettings, nameDefaults, claimCategory)
    if (nameSettings == nil) then
        return nil;
    end

    if (claimCategory == 'unclaimed') then
        return nameSettings.claimUnclaimedColor or nameDefaults.claimUnclaimedColor or nameDefaults.color;
    end

    if (claimCategory == 'party') then
        return nameSettings.claimPartyColor or nameDefaults.claimPartyColor or nameDefaults.color;
    end

    if (claimCategory == 'other') then
        return nameSettings.claimOtherColor or nameDefaults.claimOtherColor or nameDefaults.color;
    end

    if (claimCategory == 'call_for_help') then
        return nameSettings.claimCallForHelpColor or nameDefaults.claimCallForHelpColor or nameDefaults.color;
    end

    return nameSettings.claimUnclaimedColor or nameDefaults.claimUnclaimedColor or nameDefaults.color;
end

local function GetIdBoxColor(idSettings, mobInfo)
    if (idSettings == nil or idSettings.boxDifficultyColorsEnabled ~= true) then
        return idSettings ~= nil and idSettings.boxBackgroundColor or idDefaults.boxBackgroundColor;
    end

    local key = GetDifficultyKey(GetViewerLevel(), mobInfo ~= nil and (mobInfo.MaxLevel or mobInfo.Level or mobInfo.MinLevel));

    if (key == 'tw') then return idSettings.boxTwColor or idDefaults.boxTwColor; end
    if (key == 'ep') then return idSettings.boxEpColor or idDefaults.boxEpColor; end
    if (key == 'dc') then return idSettings.boxDcColor or idDefaults.boxDcColor; end
    if (key == 'em') then return idSettings.boxEmColor or idDefaults.boxEmColor; end
    if (key == 't') then return idSettings.boxTColor or idDefaults.boxTColor; end
    if (key == 'vt') then return idSettings.boxVtColor or idDefaults.boxVtColor; end
    if (key == 'it') then return idSettings.boxItColor or idDefaults.boxItColor; end

    return idSettings.boxBackgroundColor or idDefaults.boxBackgroundColor;
end

local function AddLevelToPlate(plateData, levelText, levelSettings, mobInfo, globalSettings)
    if (levelSettings == nil or levelSettings.enabled ~= true or levelText == nil or tostring(levelText) == '') then
        return;
    end

    local text = tostring(levelText);

    plateData.badges = plateData.badges or {};
    plateData.badges[#plateData.badges + 1] = {
        kind = 'level',
        text = text,
        offsetX = tonumber(levelSettings.offsetX) or 0,
        offsetY = tonumber(levelSettings.offsetY) or -54,
        fontFamily = fonts.GetRole(globalSettings, true),
        fontFlags = fonts.GetRoleFlags(globalSettings, true),
        fontSize = textScale.ToTextureFontSize(levelSettings.textSize, levelDefaults.textSize),
        textColor = GetDifficultyColor(levelSettings, levelDefaults, mobInfo),
        textOutlineEnabled = levelSettings.outlineEnabled == true,
        textOutlineColor = levelSettings.outlineColor or levelDefaults.outlineColor,
        textOutlineSize = tonumber(levelSettings.outlineSize) or levelDefaults.outlineSize,
        anchorTo = levelSettings.anchorTo or levelDefaults.anchorTo,
        anchorPoint = levelSettings.anchorPoint or levelDefaults.anchorPoint,
        backgroundEnabled = false,
    };
end

local function AddIdToPlate(plateData, enemy, idSettings, mobInfo, globalSettings)
    if (idSettings == nil or idSettings.enabled ~= true or enemy == nil) then
        return;
    end

    local idValue = tonumber(enemy.serverId) or tonumber(enemy.index) or 0;

    if (idValue <= 0) then
        return;
    end

    local text = string.format('%02d', idValue % 100);
    local boxSize = tonumber(idSettings.boxSize) or idDefaults.boxSize;

    plateData.badges = plateData.badges or {};
    plateData.badges[#plateData.badges + 1] = {
        kind = 'id',
        text = text,
        offsetX = tonumber(idSettings.offsetX) or 0,
        offsetY = tonumber(idSettings.offsetY) or 24,
        fontFamily = fonts.GetRole(globalSettings, idSettings.useSmallFont == true),
        fontFlags = fonts.GetRoleFlags(globalSettings, idSettings.useSmallFont == true),
        fontSize = textScale.ToTextureFontSize(idSettings.textSize, idDefaults.textSize),
        textColor = idSettings.color or idDefaults.color,
        textOutlineEnabled = idSettings.outlineEnabled == true,
        textOutlineColor = idSettings.outlineColor or idDefaults.outlineColor,
        textOutlineSize = tonumber(idSettings.outlineSize) or idDefaults.outlineSize,
        anchorTo = idSettings.anchorTo or idDefaults.anchorTo,
        anchorPoint = idSettings.anchorPoint or idDefaults.anchorPoint,
        backgroundEnabled = idSettings.boxEnabled == true,
        backgroundColor = GetIdBoxColor(idSettings, mobInfo),
        borderColor = idSettings.boxBorderColor or idDefaults.boxBorderColor,
        borderSize = tonumber(idSettings.boxBorderSize) or idDefaults.boxBorderSize,
        paddingX = 0,
        paddingY = 0,
        minWidth = boxSize,
        minHeight = boxSize,
        cornerRadius = tonumber(idSettings.cornerRadius) or idDefaults.cornerRadius,
    };
end

local function AddDistanceToPlate(plateData, enemy, distanceSettings, globalSettings)
    if (distanceSettings == nil or distanceSettings.enabled ~= true or enemy == nil or enemy.distance == nil) then
        return;
    end

    local distance = tonumber(enemy.distance);

    if (distance == nil) then
        return;
    end

    plateData.badges = plateData.badges or {};
    plateData.badges[#plateData.badges + 1] = {
        kind = 'distance',
        text = tostring(distanceSettings.prefix or '') .. string.format('%.1f', distance),
        offsetX = tonumber(distanceSettings.offsetX) or 92,
        offsetY = tonumber(distanceSettings.offsetY) or -54,
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

local function RemoveBadgeKind(plateData, kind)
    if (plateData == nil or plateData.badges == nil) then
        return;
    end

    local keep = {};

    for _, badge in ipairs(plateData.badges) do
        if (badge.kind ~= kind) then
            keep[#keep + 1] = badge;
        end
    end

    plateData.badges = keep;
end

local function AddStatusIconsToPlate(plateData, statusIds, iconSettings, isEngaged, globalSettings, kind)
    if (
        iconSettings == nil or
        iconSettings.enabled ~= true or
        (iconSettings.hideOutOfCombat == true and isEngaged ~= true) or
        statusIds == nil or
        #statusIds == 0
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

    for _, rowData in ipairs(statusIds) do
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

local function ShouldLoadStatusRows(iconSettings, isEngaged, hasActiveDetail)
    if (hasActiveDetail ~= true) then
        return false;
    end

    if (iconSettings == nil or iconSettings.enabled ~= true) then
        return false;
    end

    if (iconSettings.hideOutOfCombat == true and isEngaged ~= true) then
        return false;
    end

    return true;
end

local function QueueCachedEnemy(enemy, cached, stateName, importantAlwaysOnTop, hpPercent)
    if (cached == nil or cached.texture == nil) then
        return false;
    end

    TouchPlateCacheEntry(cached);

    local plateTextureId = canvasTexture.GetTextureId(cached.texture);

    if (plateTextureId == nil) then
        return false;
    end

    local queueTimer = perfMeter.BeginDetail('enemy.queue');
    local targetingSettings = targeting.GetSettings();

    worldMarkerProbe.QueuePlate({
        targetIndex = enemy.index,
        serverId = enemy.serverId,
        distance = enemy.distance,
        hp = hpPercent,
        name = '',
        isSelf = false,
        stateName = stateName,
        clickTargetType = 'enemy',
        worldMarker = {
            hpBar = { enabled = false },
            plateTextureId = plateTextureId,
            plateAlwaysOnTop = importantAlwaysOnTop,
            plateTacticalOverlayOnly = importantAlwaysOnTop,
            anchorBone = enemyAnchorBone,
            plateWorldWidth = cached.plateWorldWidth,
            plateWorldHeight = cached.plateWorldHeight,
            plateWorldOffsetY = enemyWorldOffsetY,
            plateDistanceScaleStart = tonumber(targetingSettings.pcDistanceScaleStart) or 2.0,
            plateDistanceScaleEnd = tonumber(targetingSettings.pcDistanceScaleEnd) or 8.0,
            plateDistanceScaleMax = tonumber(targetingSettings.pcDistanceScaleMax) or 2.65,
            plateDistanceScaleOffsetY = 0.28,
            plateTextureWidth = cached.textureWidth,
            plateTextureHeight = cached.textureHeight,
            plateClickRects = cached.elementRects,
            clickTargetType = 'enemy',
            hideWhenProjectedBelowViewport = importantAlwaysOnTop ~= true and IsAlTaieuFish(enemy.name) == true,
            belowViewportHideMargin = 96,
            belowPlayerViewHideDelta = 1.50,
        },
    });
    perfMeter.EndDetail(queueTimer);

    return true;
end

local function QueueEnemy(enemy)
    local settingsTimer = perfMeter.BeginDetail('enemy.settings');
    local stateName = targeting.GetTargetStateName(enemy.index);

    local castData = enemyCasts.GetActiveCast(enemy.serverId);
    local isEngaged = engagedEnemies.IsEngaged(enemy.index) == true;
    local claimCategory = engagedEnemies.GetClaimCategory(enemy.index);
    local layoutStateName = (stateName ~= 'Idle' or isEngaged == true or castData ~= nil) and 'Combat' or 'Idle';
    local nameSettings = state.GetWidgetSettings('Enemy', layoutStateName, 'Name', nameDefaults);
    local backgroundSettings = state.GetWidgetSettings('Enemy', layoutStateName, 'Background', backgroundDefaults);
    local hpBarSettings = state.GetWidgetSettings('Enemy', layoutStateName, 'HP Bar', barDefaults);
    local jobSettings = state.GetWidgetSettings('Enemy', layoutStateName, 'Job', jobDefaults);
    local levelSettings = state.GetWidgetSettings('Enemy', layoutStateName, 'Level', levelDefaults);
    local idSettings = state.GetWidgetSettings('Enemy', layoutStateName, 'ID', idDefaults);
    local distanceSettings = state.GetWidgetSettings('Enemy', layoutStateName, 'Distance', distanceDefaults);
    local buffsSettings = state.GetWidgetSettings('Enemy', layoutStateName, 'Buffs', buffsDefaults);
    local debuffsSettings = state.GetWidgetSettings('Enemy', layoutStateName, 'Debuffs', debuffsDefaults);
    local peerPlateSettings = state.GetWidgetSettings('Enemy', layoutStateName, 'Peer', { enabled = true });
    local castBarSettings = state.GetWidgetSettings('Enemy', layoutStateName, 'Cast bar', castBarDefaults);
    local globalSettings = state.GetGlobalSettings(globalDefaults);
    local targetingSettings = targeting.GetSettings();
    local hpPercent = ClampPercent(enemy.hpPercent, 100);
    local hpColor = hpBarSettings.color or { 0.90, 0.20, 0.20, 1.0 };
    local isTacticalTarget = stateName ~= 'Idle';
    local isHovered = worldMarkerProbe.IsPlateHovered(enemy.index, 'enemy') == true;
    local importantAlwaysOnTop =
        isTacticalTarget == true or
        isEngaged == true;
    local activeDetailRange = math.max(10.0, math.min(49.9, tonumber(targetingSettings.enemyActiveDetailRange) or 25.0));
    local hasActiveDetail =
        importantAlwaysOnTop == true or
        castData ~= nil or
        isHovered == true or
        ((tonumber(enemy.distance) or 0) <= activeDetailRange);

    if (
        hpBarSettings.lowColorEnabled == true and
        hpPercent <= (tonumber(hpBarSettings.lowColorPercent) or 25)
    ) then
        hpColor = hpBarSettings.lowColor or hpColor;
    end

    local targetMarker = targetOverlayEnabled == true and stateName ~= 'Idle'
        and targetModuleMarker.Build('Enemy', layoutStateName, stateName, hpBarSettings, enemy.distance)
        or { enabled = false };
    local castBar, castPercent = BuildCastBar(hasActiveDetail == true and castData or nil, castBarSettings, globalSettings);
    local displayName = mobInfoData.GetLookupName(enemy.name);
    local mobInfo = mobInfoData.GetMobInfo(enemy.name, enemy.index);
    local jobText = mobInfoData.GetJobString(mobInfo);
    local levelText = mobInfoData.GetLevelString(mobInfo);
    local buffRows = ShouldLoadStatusRows(buffsSettings, isEngaged, hasActiveDetail) == true
        and enemyStatuses.GetActiveStatusRows(enemy.serverId, 'buff')
        or {};
    local debuffRows = ShouldLoadStatusRows(debuffsSettings, isEngaged, hasActiveDetail) == true
        and enemyStatuses.GetActiveStatusRows(enemy.serverId, 'debuff')
        or {};
    local distanceText = nil;

    if (hasActiveDetail == true and distanceSettings ~= nil and distanceSettings.enabled == true and enemy.distance ~= nil) then
        distanceText = tostring(distanceSettings.prefix or '') .. string.format('%.1f', tonumber(enemy.distance) or 0);
    end

    local cacheEligible = stateName == 'Idle'
        and isEngaged ~= true
        and castData == nil
        and #buffRows == 0
        and #debuffRows == 0
        and state.GetConfigOpen() ~= true
        and isHovered ~= true;
    local cacheKey = nil;
    local signature = nil;

    if (cacheEligible == true) then
        cacheKey = 'enemy:' .. tostring(enemy.index);
        signature = table.concat({
            'v=1',
            'policy=' .. canvasTexture.GetRenderPolicyKey(),
            'activeDetail=' .. tostring(hasActiveDetail),
            'name=' .. tostring(displayName or ''),
            'server=' .. tostring(enemy.serverId or ''),
            'hp=' .. (hasActiveDetail == true and tostring(hpPercent) or ''),
            'dist=' .. tostring(distanceText or ''),
            'job=' .. tostring(jobText or ''),
            'level=' .. tostring(levelText or ''),
            'id=' .. tostring(tonumber(enemy.serverId) or tonumber(enemy.index) or 0),
            'difficulty=' .. tostring(mobInfo ~= nil and mobInfo.Difficulty or ''),
            'claim=' .. tostring(claimCategory or ''),
            'ap=' .. tostring(mobInfoData.HasActivityPointMarker(enemy.name) == true),
            'nm=' .. tostring(mobInfo ~= nil and mobInfo.IsNM or ''),
            'bg=' .. SettingKey(backgroundSettings, { 'enabled', 'width', 'height', 'offsetX', 'offsetY', 'color', 'borderColor', 'borderSize', 'anchorTo', 'anchorPoint' }),
            'nameSettings=' .. SettingKey(nameSettings, { 'enabled', 'shortenName', 'textSize', 'color', 'claimColorsEnabled', 'claimUnclaimedColor', 'claimPartyColor', 'claimOtherColor', 'claimCallForHelpColor', 'outlineSize', 'outlineColor', 'offsetX', 'offsetY', 'anchorTo', 'anchorPoint' }),
            'hpSettings=' .. (hasActiveDetail == true and SettingKey(hpBarSettings, { 'enabled', 'width', 'height', 'offsetX', 'offsetY', 'color', 'backgroundColor', 'borderColor', 'borderSize', 'anchorTo', 'anchorPoint', 'texture', 'showPercent', 'fontSize', 'textColor', 'textOutlineEnabled', 'textOutlineColor', 'textOutlineSize', 'lowColorEnabled', 'lowColorPercent', 'lowColor' }) or ''),
            'jobSettings=' .. SettingKey(jobSettings, { 'enabled', 'displayModeIndex', 'textSize', 'color', 'outlineSize', 'outlineColor', 'offsetX', 'offsetY', 'anchorTo', 'anchorPoint', 'iconTheme', 'iconSize' }),
            'levelSettings=' .. SettingKey(levelSettings, { 'enabled', 'textSize', 'color', 'outlineSize', 'outlineColor', 'offsetX', 'offsetY', 'anchorTo', 'anchorPoint' }),
            'idSettings=' .. SettingKey(idSettings, { 'enabled', 'textSize', 'color', 'outlineSize', 'outlineColor', 'offsetX', 'offsetY', 'anchorTo', 'anchorPoint', 'prefix' }),
            'distanceSettings=' .. SettingKey(distanceSettings, { 'enabled', 'textSize', 'color', 'outlineEnabled', 'outlineColor', 'outlineSize', 'useSmallFont', 'offsetX', 'offsetY', 'prefix', 'anchorTo', 'anchorPoint' }),
            'debug=' .. tostring(worldMarkerProbe.GetClickDebug()),
        }, '\n');

        local indexed = indexCache[tonumber(enemy.index) or 0];
        local staleCached = indexed ~= nil and plateCache[indexed.cacheKey] or nil;
        local cached = indexed ~= nil and indexed.signature == signature and staleCached or nil;

        if (QueueCachedEnemy(enemy, cached, stateName, importantAlwaysOnTop, hpPercent) == true) then
            perfMeter.Count('enemy.cache.hit', 1);
            perfMeter.EndDetail(settingsTimer);
            return;
        end

        if (
            adaptivePerformance.ShouldThrottleBackground() == true and
            staleCached ~= nil and
            (os.clock() - (tonumber(staleCached.lastUsed) or 0)) < 1.00 and
            QueueCachedEnemy(enemy, staleCached, stateName, importantAlwaysOnTop, hpPercent) == true
        ) then
            perfMeter.Count('enemy.cache.smooth', 1);
            perfMeter.EndDetail(settingsTimer);
            return;
        end

        if (
            adaptivePerformance.ShouldThrottleBackground() == true and
            adaptivePerformance.AllowBackgroundBuild('enemy.idle.canvas', 1) ~= true
        ) then
            perfMeter.Count('enemy.cache.defer', 1);
            perfMeter.EndDetail(settingsTimer);
            return;
        end

        perfMeter.Count('enemy.cache.miss', 1);
    end
    perfMeter.EndDetail(settingsTimer);

    local buildTimer = perfMeter.BeginDetail('enemy.build');
    local plateData = {
        hp = hpPercent,
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
            anchorTo = backgroundSettings.anchorTo or backgroundDefaults.anchorTo,
            anchorPoint = backgroundSettings.anchorPoint or backgroundDefaults.anchorPoint,
        },
        name = (nameSettings.enabled == true) and ShortenName(displayName, nameSettings.shortenName) or '',
        nameFontFamily = fonts.GetRole(globalSettings, false),
        nameFontFlags = fonts.GetRoleFlags(globalSettings, false),
        nameFontSize = textScale.ToTextureFontSize(nameSettings.textSize, nameDefaults.textSize),
        nameColor = GetClaimNameColor(nameSettings, nameDefaults, claimCategory) or GetDifficultyColor(nameSettings, nameDefaults, mobInfo),
        nameOutlineEnabled = (tonumber(nameSettings.outlineSize) or 0) > 0,
        nameOutlineColor = nameSettings.outlineColor or { 0.0, 0.0, 0.0, 1.0 },
        nameOutlineSize = tonumber(nameSettings.outlineSize) or 0,
        nameOffsetX = tonumber(nameSettings.offsetX) or 0,
        nameOffsetY = tonumber(nameSettings.offsetY) or -54,
        nameAnchorTo = nameSettings.anchorTo or nameDefaults.anchorTo,
        nameAnchorPoint = nameSettings.anchorPoint or nameDefaults.anchorPoint,
        hpBar = {
            enabled = hasActiveDetail == true and hpBarSettings.enabled == true,
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
            showAtPercent = tonumber(hpBarSettings.showAtPercent) or 100,
            text = (hpBarSettings.showPercent == true) and (tostring(math.floor(hpPercent + 0.5)) .. '%') or '',
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
            enabled = false,
        },
        tpBar = {
            enabled = false,
        },
        castBar = castBar,
    };
    AddActivityPointIconToPlate(plateData, enemy.name, nameSettings);
    AddJobToPlate(plateData, jobText, jobSettings, globalSettings);
    AddLevelToPlate(plateData, levelText, levelSettings, mobInfo, globalSettings);
    AddIdToPlate(plateData, enemy, idSettings, mobInfo, globalSettings);
    if (hasActiveDetail == true) then
        AddDistanceToPlate(plateData, enemy, distanceSettings, globalSettings);
    end
    perfMeter.EndDetail(buildTimer);

    local statusTimer = perfMeter.BeginDetail('enemy.status');
    AddStatusIconsToPlate(plateData, buffRows, buffsSettings, isEngaged, globalSettings, 'buffs');
    AddStatusIconsToPlate(plateData, debuffRows, debuffsSettings, isEngaged, globalSettings, 'debuffs');
    perfMeter.EndDetail(statusTimer);

    if (hasActiveDetail == true and enmity.ShouldDrawEnemy(enemy, globalSettings) == true) then
        enmity.AddIcon(plateData, globalSettings.enmity);
    end
    plateData.debugClickRects = worldMarkerProbe.GetClickDebug();
    plateData.debugClickRectColor = 0x01FFD400;

    local canvasTimer = perfMeter.BeginDetail('enemy.canvas');
    local plateTexture, textureWidth, textureHeight = canvasTexture.Render(plateData, 'enemy-' .. tostring(enemy.index));
    local plateTextureId = canvasTexture.GetTextureId(plateTexture);
    local plateClickRects = plateData._elementRects or canvasTexture.GetElementRects(plateData);
    perfMeter.EndDetail(canvasTimer);
    local plateScale = 1.0;

    local peerSettings = globalSettings.peer or {};
    local peerModifierActive = IsPeerModifierActive(peerSettings) == true;
    local useWorldPeer = false;

    if (
        useWorldPeer == true and
        peerPlateSettings.enabled ~= false and
        (tonumber(enemy.distance) or 0) <= math.max(0.0, math.min(49.9, tonumber(peerSettings.maxRange) or 49.9)) and
        peerModifierActive == true and
        isHovered == true
    ) then
        plateScale = GetPeerHoverScale(peerSettings);
        plateData.jobText = '';
        plateData.jobIconTextureId = nil;
        RemoveBadgeKind(plateData, 'id');
        RemoveBadgeKind(plateData, 'level');
        RemoveBadgeKind(plateData, 'distance');
        ApplyPeerBackground(plateData, peerSettings);
        ApplyPeerName(plateData, peerSettings, globalSettings);
        ApplyPeerHpBar(plateData, peerSettings, hpPercent, globalSettings);
        AddPeerIdToPlate(plateData, enemy, peerSettings, globalSettings);
        plateData.icons, plateData.texts = BuildMobInfoRows(enemy, globalSettings, peerSettings);
        if (hasActiveDetail == true and enmity.ShouldDrawEnemy(enemy, globalSettings) == true) then
            enmity.AddIcon(plateData, globalSettings.enmity);
        end
        canvasTimer = perfMeter.BeginDetail('enemy.canvas');
        plateTexture, textureWidth, textureHeight = canvasTexture.Render(plateData, 'enemy-libra-' .. tostring(enemy.index));
        plateTextureId = canvasTexture.GetTextureId(plateTexture);
        plateClickRects = plateData._elementRects or canvasTexture.GetElementRects(plateData);
        perfMeter.EndDetail(canvasTimer);
    end

    if (plateTextureId == nil) then
        indexCache[tonumber(enemy.index) or 0] = nil;
        return;
    end

    if (cacheEligible == true and cacheKey ~= nil and signature ~= nil) then
        plateCache[cacheKey] = {
            signature = signature,
            texture = plateTexture,
            textureKey = 'enemy-' .. tostring(enemy.index),
            lastUsed = os.clock(),
            textureWidth = textureWidth,
            textureHeight = textureHeight,
            elementRects = plateClickRects,
            plateWorldWidth = 2.35 * plateScale,
            plateWorldHeight = 1.18 * plateScale,
        };
        indexCache[tonumber(enemy.index) or 0] = {
            cacheKey = cacheKey,
            signature = signature,
        };
    else
        indexCache[tonumber(enemy.index) or 0] = nil;
    end

    local queueTimer = perfMeter.BeginDetail('enemy.queue');
    local targetingSettings = targeting.GetSettings();
    worldMarkerProbe.QueuePlate({
        targetIndex = enemy.index,
        serverId = enemy.serverId,
        distance = enemy.distance,
        hp = hpPercent,
        name = '',
        isSelf = false,
        stateName = stateName,
        clickTargetType = 'enemy',
        worldMarker = {
            hpBar = { enabled = false },
            plateTextureId = plateTextureId,
            plateAlwaysOnTop = importantAlwaysOnTop,
            plateTacticalOverlayOnly = importantAlwaysOnTop,
            anchorBone = enemyAnchorBone,
            plateWorldWidth = 2.35 * plateScale,
            plateWorldHeight = 1.18 * plateScale,
            plateWorldOffsetY = enemyWorldOffsetY,
            plateDistanceScaleStart = tonumber(targetingSettings.pcDistanceScaleStart) or 2.0,
            plateDistanceScaleEnd = tonumber(targetingSettings.pcDistanceScaleEnd) or 8.0,
            plateDistanceScaleMax = tonumber(targetingSettings.pcDistanceScaleMax) or 2.65,
            plateDistanceScaleOffsetY = 0.28,
            plateTextureWidth = textureWidth,
            plateTextureHeight = textureHeight,
            plateClickRects = plateClickRects,
            clickTargetType = 'enemy',
            hideWhenProjectedBelowViewport = importantAlwaysOnTop ~= true and IsAlTaieuFish(enemy.name) == true,
            belowViewportHideMargin = 96,
            belowPlayerViewHideDelta = 1.50,
        },
    });
    perfMeter.EndDetail(queueTimer);
end

function enemyPlate.Build()
    return nil;
end

function enemyPlate.SetAnchorBone(value)
    local bone = math.floor(tonumber(value) or enemyAnchorBone);

    if (bone < 0) then
        bone = 0;
    elseif (bone > 32) then
        bone = 32;
    end

    enemyAnchorBone = bone;
end

function enemyPlate.GetAnchorBone()
    return enemyAnchorBone;
end

function enemyPlate.SetWorldOffsetY(value)
    enemyWorldOffsetY = tonumber(value) or enemyWorldOffsetY;
end

function enemyPlate.GetWorldOffsetY()
    return enemyWorldOffsetY;
end

function enemyPlate.ResetPositionDebug()
    enemyAnchorBone = 2;
    enemyWorldOffsetY = 0.50;
end

function enemyPlate.GetPositionDebugText()
    return 'Enemy plate position bone=' .. tostring(enemyAnchorBone) .. ' offsetY=' .. tostring(enemyWorldOffsetY);
end

function enemyPlate.SetTargetOverlayEnabled(value)
    targetOverlayEnabled = value == true;
end

function enemyPlate.GetTargetOverlayEnabled()
    return targetOverlayEnabled == true;
end

function enemyPlate.Render(importantOnly)
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
    local currentTargetIndex = targeting.GetCurrentTargetIndex();
    local currentSubTargetIndex = targeting.GetCurrentSubTargetIndex();
    local subTargetActive = targeting.IsSubTargetModeActive();
    local queued = {};

    local function QueueByIndex(index, allowHidden)
        if (index == nil or queued[index] == true) then
            return false;
        end

        local enemy = entities.GetEnemy(index, allowHidden);

        if (enemy == nil) then
            return false;
        end

        queued[index] = true;
        QueueEnemy(enemy);
        return true;
    end

    QueueByIndex(currentSubTargetIndex, true);
    QueueByIndex(currentTargetIndex, true);

    for _, index in ipairs(engagedEnemies.GetTrackedIndexes()) do
        QueueByIndex(index, true);
    end

    if (importantOnly == true) then
        return;
    end

    if (IsNonCombatZone() == true) then
        return;
    end

    local scanTimer = perfMeter.BeginDetail('enemy.scan');
    local enemies = entities.GetNearbyEnemies(targetingSettings.enemyPlateRange);
    perfMeter.EndDetail(scanTimer);

    for _, enemy in ipairs(enemies) do
        if (queued[enemy.index] == true) then
            -- Already queued target/subtarget above.
        else
            queued[enemy.index] = true;
            QueueEnemy(enemy);
        end
    end
end

return enemyPlate;
