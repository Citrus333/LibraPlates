local backgroundDefaults = require('config.widgets.background');
local imgui = require('imgui');
local nameDefaults = require('config.widgets.name');
local barDefaults = require('config.widgets.bar');
local mpBarDefaults = require('config.widgets.mp_bar');
local tpBarDefaults = require('config.widgets.tp_bar');
local distanceDefaults = require('config.widgets.distance');
local castBarDefaults = require('config.widgets.cast_bar');
local maneuverDefaults = require('config.widgets.maneuvers');
local buffsDefaults = require('config.widgets.buffs');
local globalDefaults = require('config.global');
local petDurations = require('data.pet_durations');
local abilityRecast = require('libs.abilityrecast');
local enemyCasts = require('core.enemy_casts');
local fonts = require('core.fonts');
local textScale = require('core.text_scale');
local canvasTexture = require('core.canvas_texture');
local barTextures = require('core.bar_textures');
local barAnimations = require('core.bar_animations');
local backgroundTextures = require('core.background_textures');
local statusIconTextures = require('core.status_icon_textures');
local spellIconTextures = require('core.spell_icon_textures');
local statusTimerFormat = require('core.status_timer_format');
local textureLoader = require('core.texture_loader');
local entities = require('core.entities');
local state = require('core.state');
local targeting = require('core.targeting');
local enmity = require('core.enmity');
local petState = require('core.pet_state');
local bstCharmTimer = require('core.bst_charm_timer');
local luopanStatuses = require('core.luopan_statuses');
local pupManeuvers = require('core.pup_maneuvers');
local pupEquipment = require('core.pup_equipment');
local targetModuleMarker = require('core.target_module_marker');
local playerStatuses = require('core.player_statuses');
local worldDepthPlate = require('core.world_depth_plate');
local worldMarkerProbe = require('core.world_marker_probe');
local gdiTextTexture = require('ui.gdi_text_texture');

local petPlate = {};
local bstPetTimer = {};
local jugIconTextureId = nil;
local petStateIconTextureIds = {};
local detachedFavorEffectTextureIds = {};
local detachedFavorEffectStatusIds = {
    carbuncle = 42,  -- Regen
    diabolos = 43,   -- Refresh
    fenrir = 611,    -- Magic Evasion Boost
    garuda = 92,     -- Evasion Boost
    ifrit = 410,     -- Saber Dance (Double Attack visual)
    leviathan = 555, -- Magic Accuracy Boost
    ramuh = 169,     -- Potency (critical-hit visual)
    shiva = 190,     -- Magic Attack Boost
    titan = 93,      -- Defense Boost
    caitsith = 191,  -- Magic Defense Boost
};
local AVATAR_FAVOR_ABILITY_ID = 250;
local AVATAR_FAVOR_RECAST_TIMER_ID = 176;
local staticPanelEditDrag = nil;
local DrawStaticPlateTexture = nil;
local DrawStaticArtworkTexture = nil;
local detachedSetupPreview = nil;
local pupOverloadGaugeTest = {
    chance = nil,
    element = nil,
    burdens = {},
    overloaded = false,
    overloadEnded = false,
    overloadSeconds = nil,
    statusSeenActive = false,
};
local pupEquipmentTest = {
    summonActive = false,
    head = nil,
    frame = nil,
};
local GetAvatarFavorStatusElapsed = nil;
local GetAvatarFavorCooldownSeconds = nil;
local BuildResourceText = nil;
local BuildPercentFallbackResourceText = nil;
local petAnchorBone = 12;
local petWorldOffsetY = 0.16;
local wyvernRestingAnchorBone = 0;
local wyvernRestingOverlayOffsetY = -170;
local luopanWorldOffsetY = -1.60;
local luopanCanvasHeight = 1024;
local luopanPlateWorldHeight = 2.36;
local luopanBuffsDefaults = {};
local petTimerDefaults = {
    enabled = true,
    displayMode = 'Text',
    iconSize = 18,
    labelOffsetX = 0,
    labelOffsetY = 0,
    textOffsetX = 0,
    textOffsetY = 0,
    textSize = 12,
    color = { 1.0, 1.0, 1.0, 1.0 },
    outlineEnabled = true,
    outlineColor = { 0.0, 0.0, 0.0, 1.0 },
    outlineSize = 2,
    offsetX = -52,
    offsetY = -52,
};
local petStateDefaults = {
    enabled = true,
    displayMode = 'Text',
    iconSize = 22,
    labelOffsetX = 0,
    labelOffsetY = 0,
    textSize = 12,
    color = { 1.0, 1.0, 1.0, 1.0 },
    outlineEnabled = true,
    outlineColor = { 0.0, 0.0, 0.0, 1.0 },
    outlineSize = 2,
    offsetX = 52,
    offsetY = -52,
};

for key, value in pairs(buffsDefaults) do
    luopanBuffsDefaults[key] = value;
end
luopanBuffsDefaults.enabled = true;
luopanBuffsDefaults.offsetY = -122;

local function IsTargetOrSubtarget(targetStateName)
    return targetStateName == 'Target' or targetStateName == 'Subtarget';
end

local function IsPetResting(pet)
    if (tonumber(pet ~= nil and pet.status or nil) == 33) then
        return true;
    end

    local self = entities.GetSelf();
    return tonumber(self ~= nil and self.status or nil) == 33;
end

function petPlate.GetWyvernWorldOffsetY(pet)
    return petWorldOffsetY;
end

function petPlate.GetWyvernAnchorBone(pet)
    return IsPetResting(pet) == true and wyvernRestingAnchorBone or petAnchorBone;
end

function petPlate.GetWyvernOverlayOffsetY(pet)
    return IsPetResting(pet) == true and wyvernRestingOverlayOffsetY or 0;
end

local function GetJugIconTextureId()
    if (jugIconTextureId ~= nil) then
        return jugIconTextureId;
    end

    jugIconTextureId = textureLoader.ToTextureId(textureLoader.Load(addon.path .. '\\assets\\images\\pet\\bst\\jug.png'));
    return jugIconTextureId;
end

local function GetPetStateIconTextureId(commandName)
    local key = tostring(commandName or ''):lower();

    if (key == '') then
        return nil;
    end

    if (key == 'sic') then
        key = 'ready';
    end

    if (petStateIconTextureIds[key] ~= nil) then
        return petStateIconTextureIds[key];
    end

    local jobFolder = (key == 'ward' or key == 'rage' or key == 'favor') and 'smn' or 'bst';
    petStateIconTextureIds[key] = textureLoader.ToTextureId(textureLoader.Load(addon.path .. '\\assets\\images\\pet\\' .. jobFolder .. '\\' .. key .. '.png'));
    return petStateIconTextureIds[key];
end

local function GetPetTimerIconTextureId(iconName)
    local key = tostring(iconName or ''):lower();

    if (key == 'jug') then
        return GetJugIconTextureId();
    end

    return GetPetStateIconTextureId(key);
end

local function CopySettingsWith(settings, overrides)
    local copy = {};

    for key, value in pairs(settings or {}) do
        copy[key] = value;
    end

    for key, value in pairs(overrides or {}) do
        copy[key] = value;
    end

    return copy;
end

local function GetDetachedFavorEffectTextureId(avatarName)
    local key = tostring(avatarName or ''):lower():gsub('[^%w]+', '');
    local statusId = detachedFavorEffectStatusIds[key];

    if (statusId ~= nil) then
        local cacheKey = tostring(statusId);
        if (detachedFavorEffectTextureIds[cacheKey] == nil) then
            local path = addon.path .. '\\assets\\images\\pet\\smn\\detached\\' .. cacheKey .. '.png';
            detachedFavorEffectTextureIds[cacheKey] = textureLoader.ToTextureId(textureLoader.Load(path)) or false;
        end

        if (detachedFavorEffectTextureIds[cacheKey] ~= false) then
            return detachedFavorEffectTextureIds[cacheKey];
        end
    end

    return nil;
end

local function ColorKey(color)
    if (type(color) ~= 'table') then
        return '';
    end

    return table.concat({
        tostring(color[1] or ''),
        tostring(color[2] or ''),
        tostring(color[3] or ''),
        tostring(color[4] or ''),
    }, ',');
end

local function TableSettingKey(settings, keys)
    if (type(settings) ~= 'table') then
        return '';
    end

    local parts = {};
    for _, key in ipairs(keys or {}) do
        local value = settings[key];
        if (type(value) == 'table') then
            parts[#parts + 1] = tostring(key) .. '=' .. ColorKey(value);
        else
            parts[#parts + 1] = tostring(key) .. '=' .. tostring(value);
        end
    end

    return table.concat(parts, ',');
end

local function GetSmnPetArtworkFile(petName)
    local normalizedName = tostring(petName or ''):gsub('[^%w]+', '');
    if (normalizedName == '') then
        return nil;
    end

    local spiritElement = normalizedName:match('^(.-)Spirit$');
    local wanted = spiritElement ~= nil and spiritElement ~= ''
        and ('Spirit_' .. spiritElement .. '.png')
        or ('Avatar_' .. normalizedName .. '.png');
    for _, fileName in ipairs(backgroundTextures.GetAvatarArtworkFiles() or {}) do
        if (tostring(fileName):lower() == wanted:lower()) then
            return tostring(fileName);
        end
    end

    return nil;
end

local function GetDetachedPetSetting(targetingSettings, prefix, settingsPrefix, suffix)
    local value = targetingSettings[settingsPrefix .. suffix];

    if (value == nil and settingsPrefix ~= prefix) then
        value = targetingSettings[prefix .. suffix];
    end

    return value;
end

local function BuildStaticPetBackground(targetingSettings, prefix, settingsPrefix, staticScale, petName)
    local settings = GetDetachedPetSetting(targetingSettings, prefix, settingsPrefix, 'PetStaticBackgroundSettings');
    if (type(settings) ~= 'table') then
        local defaults = (globalDefaults.targeting or {})[settingsPrefix .. 'PetStaticBackgroundSettings']
            or (globalDefaults.targeting or {})[prefix .. 'PetStaticBackgroundSettings'];
        settings = type(defaults) == 'table' and defaults or backgroundDefaults;
    end

    local scaleInverse = 1 / math.max(0.10, tonumber(staticScale) or 1.0);

    local textureName = settings.texture or backgroundDefaults.texture;
    local usingAvatarArtwork = false;
    local usingPupArtwork = false;
    local usingDrgArtwork = false;
    if (prefix == 'smn' and settings.useAvatarArtwork ~= false) then
        local avatarArtwork = GetSmnPetArtworkFile(petName);
        if (avatarArtwork ~= nil) then
            textureName = avatarArtwork;
            usingAvatarArtwork = true;
        end
    elseif (prefix == 'pup') then
        textureName = 'automaton.png';
        usingPupArtwork = true;
    elseif (prefix == 'drg') then
        textureName = 'Wyvern.png';
        usingDrgArtwork = true;
    end

    local baseWidth = tonumber(settings.width) or backgroundDefaults.width;
    local baseHeight = tonumber(settings.height) or backgroundDefaults.height;
    local offsetX = tonumber(settings.offsetX) or backgroundDefaults.offsetX;
    local offsetY = tonumber(settings.offsetY) or backgroundDefaults.offsetY;
    local color = settings.color or backgroundDefaults.color;
    local borderColor = settings.borderColor or backgroundDefaults.borderColor;
    local borderSize = tonumber(settings.borderSize) or backgroundDefaults.borderSize;

    if (usingAvatarArtwork == true) then
        baseHeight = baseWidth * (256 / 600);
        offsetX = 0;
        offsetY = 0;
        color = { 0.0, 0.0, 0.0, 0.0 };
    elseif (usingPupArtwork == true) then
        baseHeight = baseWidth * (471 / 836);
        offsetX = 0;
        offsetY = 0;
        color = { 0.0, 0.0, 0.0, 0.0 };
    elseif (usingDrgArtwork == true) then
        baseHeight = baseWidth * (849 / 1853);
        offsetX = 0;
        offsetY = 0;
        color = { 0.0, 0.0, 0.0, 0.0 };
    end

    return {
        enabled = settings.enabled ~= false,
        width = baseWidth * scaleInverse,
        height = baseHeight * scaleInverse,
        offsetX = offsetX * scaleInverse,
        offsetY = offsetY * scaleInverse,
        color = color,
        borderColor = borderColor,
        borderSize = borderSize * scaleInverse,
        texture = textureName,
        textureId = usingAvatarArtwork == true
            and backgroundTextures.GetAvatarArtworkTextureId(textureName)
            or (
                usingPupArtwork == true
                and backgroundTextures.GetPupArtworkTextureId(textureName)
                or (
                    usingDrgArtwork == true
                    and backgroundTextures.GetDrgArtworkTextureId(textureName)
                    or backgroundTextures.GetTextureId(textureName)
                )
            ),
        imageOpacity = usingAvatarArtwork == true
            and (tonumber(settings.avatarArtworkOpacity) or 100)
            or (
                usingPupArtwork == true
                and (tonumber(settings.pupArtworkOpacity) or 100)
                or (
                    usingDrgArtwork == true
                    and (tonumber(settings.drgArtworkOpacity) or 100)
                    or (settings.imageOpacity or backgroundDefaults.imageOpacity)
                )
            ),
        avatarArtwork = usingAvatarArtwork,
        pupArtwork = usingPupArtwork,
        drgArtwork = usingDrgArtwork,
        avatarGemMeters = settings.avatarGemMeters,
        avatarNameSettings = settings.avatarNameSettings,
        avatarHpBarSettings = settings.avatarHpBarSettings,
        avatarMpBarSettings = settings.avatarMpBarSettings,
        avatarTpBarSettings = settings.avatarTpBarSettings,
        avatarCastBarSettings = settings.avatarCastBarSettings,
        avatarEnmitySettings = settings.avatarEnmitySettings,
        avatarWardSettings = settings.avatarWardSettings,
        avatarRageSettings = settings.avatarRageSettings,
        avatarFavorSettings = settings.avatarFavorSettings,
        pupNameSettings = settings.pupNameSettings,
        pupHpBarSettings = settings.pupHpBarSettings,
        pupMpBarSettings = settings.pupMpBarSettings,
        pupTpBarSettings = settings.pupTpBarSettings,
        pupFrameArtworkSettings = settings.pupFrameArtworkSettings,
        pupHeadArtworkSettings = settings.pupHeadArtworkSettings,
        pupOverloadSettings = settings.pupOverloadSettings,
        pupSteamSettings = settings.pupSteamSettings,
        pupElementSettings = settings.pupElementSettings,
        pupManeuverSettings = settings.pupManeuverSettings,
        scaleInverse = scaleInverse,
        rawWidth = baseWidth,
        rawHeight = baseHeight,
    };
end

local function GetDetachedAvatarMeterNumber(settings, key, defaultValue)
    local value = tonumber(settings[key]);
    if (value == nil) then
        return defaultValue;
    end

    return value;
end

local function BuildDetachedAvatarMeterBar(background, settings, defaults)
    local scaleInverse = tonumber(background.scaleInverse) or 1;
    local baseX = tonumber(background.offsetX) or 0;
    local baseY = tonumber(background.offsetY) or 0;
    local rawWidth = tonumber(background.rawWidth) or 220;
    local rawHeight = tonumber(background.rawHeight) or 74;
    local texture = settings.texture or defaults.texture or 'Solid';
    local borderSize = math.floor((GetDetachedAvatarMeterNumber(settings, 'borderSize', defaults.borderSize) * scaleInverse) + 0.5);
    local borderColor = settings.borderColor or defaults.borderColor;

    -- Detached meter defaults historically stored a transparent border color.
    -- The RGB picker preserves that alpha, so increasing Border size could
    -- never produce a visible border. Keep size 0 disabled, but make a chosen
    -- positive border visible without mutating the user's saved settings.
    if (borderSize > 0 and type(borderColor) == 'table' and (tonumber(borderColor[4]) or 0) <= 0) then
        borderColor = {
            tonumber(borderColor[1]) or 0,
            tonumber(borderColor[2]) or 0,
            tonumber(borderColor[3]) or 0,
            1.0,
        };
    end

    return {
        width = math.max(1, GetDetachedAvatarMeterNumber(settings, 'width', defaults.width) * scaleInverse),
        height = math.max(1, GetDetachedAvatarMeterNumber(settings, 'height', defaults.height) * scaleInverse),
        offsetX = baseX + (GetDetachedAvatarMeterNumber(settings, 'offsetX', defaults.offsetX) * scaleInverse),
        offsetY = baseY + (GetDetachedAvatarMeterNumber(settings, 'offsetY', defaults.offsetY) * scaleInverse),
        color = settings.color or defaults.color,
        backgroundColor = settings.backgroundColor or defaults.backgroundColor,
        borderColor = borderColor,
        borderSize = borderSize,
        cornerRadius = math.max(0, GetDetachedAvatarMeterNumber(settings, 'cornerRadius', defaults.cornerRadius) * scaleInverse),
        texture = texture,
        textureId = barTextures.GetTextureId(texture),
        textureStrength = GetDetachedAvatarMeterNumber(settings, 'textureStrength', defaults.textureStrength),
        rawWidth = rawWidth,
        rawHeight = rawHeight,
    };
end

local function BuildDetachedAvatarResourceText(settings, label, value, maxValue, percent)
    local parts = {};

    if (settings.showValue == true and value ~= nil) then
        if (maxValue ~= nil and tonumber(maxValue) ~= nil and tonumber(maxValue) > 0) then
            local prefix = label == 'TP' and '' or (label .. ' ');
            parts[#parts + 1] = prefix .. tostring(value) .. '/' .. tostring(maxValue);
        else
            parts[#parts + 1] = tostring(value);
        end
    end

    if (settings.showPercent == true) then
        parts[#parts + 1] = tostring(math.floor(math.max(0, math.min(100, tonumber(percent) or 0)) + 0.5)) .. '%';
    end

    return table.concat(parts, ' ');
end

local function ApplyDetachedAvatarWidgets(plateData, background)
    if (background == nil or background.avatarArtwork ~= true) then
        return;
    end

    local detachedDefaults = ((globalDefaults.targeting or {}).smnPetStaticBackgroundSettings or {});
    local nameSettings = background.avatarNameSettings or detachedDefaults.avatarNameSettings or {};
    local hpSettings = background.avatarHpBarSettings or detachedDefaults.avatarHpBarSettings or {};
    local mpSettings = background.avatarMpBarSettings or detachedDefaults.avatarMpBarSettings or {};
    local tpSettings = background.avatarTpBarSettings or detachedDefaults.avatarTpBarSettings or {};
    local castSettings = background.avatarCastBarSettings or detachedDefaults.avatarCastBarSettings or {};
    local scaleInverse = tonumber(background.scaleInverse) or 1;
    local globalSettings = state.GetGlobalSettings(globalDefaults);
    local enmitySettings = background.avatarEnmitySettings or globalSettings.enmity or (globalDefaults.enmity or {});

    if (nameSettings.enabled == false) then
        plateData.name = '';
    else
        plateData.name = tostring(plateData.detachedAvatarName or plateData.name or '');
        plateData.nameOffsetX = GetDetachedAvatarMeterNumber(nameSettings, 'offsetX', tonumber(nameSettings.positionX) or 45) * scaleInverse;
        plateData.nameOffsetY = GetDetachedAvatarMeterNumber(nameSettings, 'offsetY', tonumber(nameSettings.positionY) or -25) * scaleInverse;
        plateData.nameFontSize = math.max(1, GetDetachedAvatarMeterNumber(nameSettings, 'textSize', tonumber(nameSettings.fontSize) or 14) * scaleInverse);
        plateData.nameColor = nameSettings.color or { 1.0, 1.0, 1.0, 1.0 };
        plateData.nameOutlineColor = nameSettings.outlineColor or { 0.0, 0.0, 0.0, 1.0 };
        plateData.nameOutlineSize = math.max(0, GetDetachedAvatarMeterNumber(nameSettings, 'outlineSize', 2) * scaleInverse);
        plateData.nameOutlineEnabled = plateData.nameOutlineSize > 0;
        plateData.nameAnchorTo = nameSettings.anchorTo or 'Plate';
        plateData.nameAnchorPoint = nameSettings.anchorPoint or 'Center';
        plateData.forceName = true;
    end

    local hpPercent = math.max(0, math.min(100, tonumber(plateData.hp) or 0));
    local hpColor = hpSettings.color or { 0.20, 0.95, 0.34, 0.95 };
    local hpLowActive = hpSettings.lowColorEnabled == true and hpPercent <= (tonumber(hpSettings.lowColorPercent) or 25);
    if (hpLowActive == true) then
        hpColor = hpSettings.lowColor or hpColor;
    end

    plateData.hpBar = CopySettingsWith(plateData.hpBar, {
        enabled = hpSettings.enabled ~= false,
        width = math.max(1, GetDetachedAvatarMeterNumber(hpSettings, 'width', 150) * scaleInverse),
        height = math.max(1, GetDetachedAvatarMeterNumber(hpSettings, 'height', 12) * scaleInverse),
        offsetX = GetDetachedAvatarMeterNumber(hpSettings, 'offsetX', tonumber(hpSettings.positionX) or 45) * scaleInverse,
        offsetY = GetDetachedAvatarMeterNumber(hpSettings, 'offsetY', tonumber(hpSettings.positionY) or -2) * scaleInverse,
        anchorTo = hpSettings.anchorTo or 'Plate',
        anchorPoint = hpSettings.anchorPoint or 'Center',
        color = hpColor,
        backgroundColor = hpSettings.backgroundColor or { 0.02, 0.02, 0.02, 0.70 },
        borderColor = hpSettings.borderColor or { 0.0, 0.0, 0.0, 0.0 },
        borderSize = GetDetachedAvatarMeterNumber(hpSettings, 'borderSize', 0) * scaleInverse,
        cornerRadius = GetDetachedAvatarMeterNumber(hpSettings, 'cornerRadius', 3) * scaleInverse,
        texture = hpSettings.texture or 'Solid',
        textureId = barTextures.GetTextureId(hpSettings.texture or 'Solid'),
        textureStrength = GetDetachedAvatarMeterNumber(hpSettings, 'textureStrength', 100),
        animationEnabled = hpLowActive == true and hpSettings.lowAnimationEnabled == true,
        animationTextureId = barAnimations.GetTextureId(hpSettings.lowAnimation),
        animationSpeed = tonumber(hpSettings.lowAnimationSpeed) or 40,
        animationColor = hpSettings.lowAnimationColor,
        showAtPercent = 100,
        text = hpSettings.showPercent == true
            and (tostring(math.floor(hpPercent + 0.5)) .. '%')
            or '',
        textOffsetX = GetDetachedAvatarMeterNumber(hpSettings, 'textOffsetX', 0) * scaleInverse,
        textOffsetY = GetDetachedAvatarMeterNumber(hpSettings, 'textOffsetY', 0) * scaleInverse,
        fontFamily = fonts.GetRole(globalSettings, hpSettings.useSmallFont == true),
        fontFlags = fonts.GetRoleFlags(globalSettings, hpSettings.useSmallFont == true),
        fontSize = math.max(1, GetDetachedAvatarMeterNumber(hpSettings, 'fontSize', 7) * scaleInverse),
        textColor = hpSettings.textColor or { 1.0, 1.0, 1.0, 1.0 },
        textOutlineEnabled = hpSettings.textOutlineEnabled == true,
        textOutlineColor = hpSettings.textOutlineColor or { 0.0, 0.0, 0.0, 1.0 },
        textOutlineSize = GetDetachedAvatarMeterNumber(hpSettings, 'textOutlineSize', 1) * scaleInverse,
    });

    local mpPercent = math.max(0, math.min(100, tonumber(plateData.mp) or 0));
    local mpColor = mpSettings.color or { 0.70, 0.90, 0.45, 1.0 };
    local mpLowActive = mpSettings.lowColorEnabled == true and mpPercent <= (tonumber(mpSettings.lowColorPercent) or 25);
    if (mpLowActive == true) then
        mpColor = mpSettings.lowColor or mpColor;
    end

    plateData.mpBar = CopySettingsWith(plateData.mpBar, {
        enabled = mpSettings.enabled ~= false and (
            plateData.detachedSmnPetType == 'Spirit' or
            plateData.detachedAvatarSetupPreview == true
        ),
        width = math.max(1, GetDetachedAvatarMeterNumber(mpSettings, 'width', 150) * scaleInverse),
        height = math.max(1, GetDetachedAvatarMeterNumber(mpSettings, 'height', 10) * scaleInverse),
        offsetX = GetDetachedAvatarMeterNumber(mpSettings, 'offsetX', 45) * scaleInverse,
        offsetY = GetDetachedAvatarMeterNumber(mpSettings, 'offsetY', 52) * scaleInverse,
        anchorTo = mpSettings.anchorTo or 'Plate',
        anchorPoint = mpSettings.anchorPoint or 'Center',
        color = mpColor,
        backgroundColor = mpSettings.backgroundColor or { 0.02, 0.02, 0.02, 0.70 },
        borderColor = mpSettings.borderColor or { 0.0, 0.0, 0.0, 1.0 },
        borderSize = GetDetachedAvatarMeterNumber(mpSettings, 'borderSize', 0) * scaleInverse,
        cornerRadius = GetDetachedAvatarMeterNumber(mpSettings, 'cornerRadius', 3) * scaleInverse,
        texture = mpSettings.texture or 'Solid',
        textureId = barTextures.GetTextureId(mpSettings.texture or 'Solid'),
        textureStrength = GetDetachedAvatarMeterNumber(mpSettings, 'textureStrength', 100),
        animationEnabled = mpLowActive == true and mpSettings.lowAnimationEnabled == true,
        animationTextureId = barAnimations.GetTextureId(mpSettings.lowAnimation),
        animationSpeed = tonumber(mpSettings.lowAnimationSpeed) or 40,
        animationColor = mpSettings.lowAnimationColor,
        showAtPercent = GetDetachedAvatarMeterNumber(mpSettings, 'showAtPercent', 100),
        text = mpSettings.showPercent == true
            and (tostring(math.floor(mpPercent + 0.5)) .. '%')
            or '',
        textOffsetX = GetDetachedAvatarMeterNumber(mpSettings, 'textOffsetX', 0) * scaleInverse,
        textOffsetY = GetDetachedAvatarMeterNumber(mpSettings, 'textOffsetY', 0) * scaleInverse,
        fontFamily = fonts.GetRole(globalSettings, mpSettings.useSmallFont == true),
        fontFlags = fonts.GetRoleFlags(globalSettings, mpSettings.useSmallFont == true),
        fontSize = math.max(1, GetDetachedAvatarMeterNumber(mpSettings, 'fontSize', 7) * scaleInverse),
        textColor = mpSettings.textColor or { 1.0, 1.0, 1.0, 1.0 },
        textOutlineEnabled = mpSettings.textOutlineEnabled == true,
        textOutlineColor = mpSettings.textOutlineColor or { 0.0, 0.0, 0.0, 1.0 },
        textOutlineSize = GetDetachedAvatarMeterNumber(mpSettings, 'textOutlineSize', 1) * scaleInverse,
    });

    local tpPercent = math.max(0, math.min(300, tonumber(plateData.tp) or 0));
    local tpColor = tpSettings.color or { 0.0, 0.55, 0.95, 1.0 };
    if (tpPercent >= (tonumber(tpSettings.showAtPercent) or 300)) then
        tpColor = tpSettings.fullColor or tpColor;
    end

    plateData.tpBar = CopySettingsWith(plateData.tpBar, {
        enabled = tpSettings.enabled ~= false,
        width = math.max(1, GetDetachedAvatarMeterNumber(tpSettings, 'width', 150) * scaleInverse),
        height = math.max(1, GetDetachedAvatarMeterNumber(tpSettings, 'height', 10) * scaleInverse),
        offsetX = GetDetachedAvatarMeterNumber(tpSettings, 'offsetX', tonumber(tpSettings.positionX) or 45) * scaleInverse,
        offsetY = GetDetachedAvatarMeterNumber(tpSettings, 'offsetY', tonumber(tpSettings.positionY) or 16) * scaleInverse,
        anchorTo = tpSettings.anchorTo or 'Plate',
        anchorPoint = tpSettings.anchorPoint or 'Center',
        color = tpColor,
        color2 = tpSettings.color2,
        color3 = tpSettings.color3,
        backgroundColor = tpSettings.backgroundColor or { 0.02, 0.02, 0.02, 0.70 },
        borderColor = tpSettings.borderColor or { 0.0, 0.0, 0.0, 0.0 },
        borderSize = GetDetachedAvatarMeterNumber(tpSettings, 'borderSize', 0) * scaleInverse,
        cornerRadius = GetDetachedAvatarMeterNumber(tpSettings, 'cornerRadius', 3) * scaleInverse,
        texture = tpSettings.texture or 'Solid',
        textureId = barTextures.GetTextureId(tpSettings.texture or 'Solid'),
        textureStrength = GetDetachedAvatarMeterNumber(tpSettings, 'textureStrength', 100),
        showAtPercent = GetDetachedAvatarMeterNumber(tpSettings, 'showAtPercent', 0),
        segmented = tpSettings.segmented == true,
        segmentGap = GetDetachedAvatarMeterNumber(tpSettings, 'segmentGap', 6) * scaleInverse,
        text = BuildDetachedAvatarResourceText(tpSettings, 'TP', plateData.detachedAvatarTp, 3000, tpPercent),
        textOffsetX = GetDetachedAvatarMeterNumber(tpSettings, 'textOffsetX', 0) * scaleInverse,
        textOffsetY = GetDetachedAvatarMeterNumber(tpSettings, 'textOffsetY', 0) * scaleInverse,
        fontFamily = fonts.GetRole(globalSettings, tpSettings.useSmallFont == true),
        fontFlags = fonts.GetRoleFlags(globalSettings, tpSettings.useSmallFont == true),
        fontSize = math.max(1, GetDetachedAvatarMeterNumber(tpSettings, 'fontSize', 7) * scaleInverse),
        textColor = tpSettings.textColor or { 1.0, 1.0, 1.0, 1.0 },
        textOutlineEnabled = tpSettings.textOutlineEnabled == true,
        textOutlineColor = tpSettings.textOutlineColor or { 0.0, 0.0, 0.0, 1.0 },
        textOutlineSize = GetDetachedAvatarMeterNumber(tpSettings, 'textOutlineSize', 1) * scaleInverse,
    });

    local detachedCastBar = plateData.detachedAvatarCastBar;
    if (detachedCastBar == nil and plateData.detachedAvatarSetupPreview == true) then
        detachedCastBar = {
            enabled = true,
            text = 'Stone',
            -- Use Stone I's actual spell artwork for the detached setup preview.
            iconTextureId = castSettings.showSpellIcon == true
                and spellIconTextures.GetTextureId(159)
                or nil,
        };
        plateData.detachedAvatarCast = 50;
    end

    if (detachedCastBar == nil) then
        plateData.castBar = nil;
    else
        plateData.cast = tonumber(plateData.detachedAvatarCast) or tonumber(plateData.cast) or 0;
        plateData.castBar = CopySettingsWith(detachedCastBar, {
            enabled = castSettings.enabled ~= false,
            width = math.max(1, GetDetachedAvatarMeterNumber(castSettings, 'width', 150) * scaleInverse),
            height = math.max(1, GetDetachedAvatarMeterNumber(castSettings, 'height', 10) * scaleInverse),
            offsetX = GetDetachedAvatarMeterNumber(castSettings, 'offsetX', 45) * scaleInverse,
            offsetY = GetDetachedAvatarMeterNumber(castSettings, 'offsetY', 34) * scaleInverse,
            anchorTo = castSettings.anchorTo or 'Plate',
            anchorPoint = castSettings.anchorPoint or 'Center',
            color = castSettings.color or { 0.95, 0.75, 0.20, 1.0 },
            backgroundColor = castSettings.backgroundColor or { 0.02, 0.02, 0.02, 0.70 },
            borderColor = castSettings.borderColor or { 0.0, 0.0, 0.0, 1.0 },
            borderSize = GetDetachedAvatarMeterNumber(castSettings, 'borderSize', 0) * scaleInverse,
            cornerRadius = GetDetachedAvatarMeterNumber(castSettings, 'cornerRadius', 3) * scaleInverse,
            texture = castSettings.texture or 'Solid',
            textureId = barTextures.GetTextureId(castSettings.texture or 'Solid'),
            text = castSettings.showSpellName ~= false and tostring(detachedCastBar.text or '') or '',
            textOffsetX = GetDetachedAvatarMeterNumber(castSettings, 'textOffsetX', 0) * scaleInverse,
            textOffsetY = GetDetachedAvatarMeterNumber(castSettings, 'textOffsetY', 0) * scaleInverse,
            fontFamily = fonts.GetRole(globalSettings, castSettings.useSmallFont == true),
            fontFlags = fonts.GetRoleFlags(globalSettings, castSettings.useSmallFont == true),
            fontSize = math.max(1, GetDetachedAvatarMeterNumber(castSettings, 'fontSize', 8) * scaleInverse),
            textColor = castSettings.textColor or { 1.0, 1.0, 1.0, 1.0 },
            textOutlineEnabled = castSettings.textOutlineEnabled == true,
            textOutlineColor = castSettings.textOutlineColor or { 0.0, 0.0, 0.0, 1.0 },
            textOutlineSize = GetDetachedAvatarMeterNumber(castSettings, 'textOutlineSize', 1) * scaleInverse,
            iconTextureId = castSettings.showSpellIcon == true and detachedCastBar.iconTextureId or nil,
            iconSize = GetDetachedAvatarMeterNumber(castSettings, 'spellIconSize', 16) * scaleInverse,
            iconOffsetX = GetDetachedAvatarMeterNumber(castSettings, 'spellIconOffsetX', -88) * scaleInverse,
            iconOffsetY = GetDetachedAvatarMeterNumber(castSettings, 'spellIconOffsetY', 0) * scaleInverse,
            separateLabelOffsets = castSettings.showSpellIcon == true and detachedCastBar.iconTextureId ~= nil,
        });
    end

    local retainedIcons = {};
    local hadLiveEnmityIcon = false;
    for _, icon in ipairs(plateData.icons or {}) do
        if (tostring(icon.kind or '') == 'enmity') then
            hadLiveEnmityIcon = true;
        else
            retainedIcons[#retainedIcons + 1] = icon;
        end
    end
    plateData.icons = retainedIcons;

    if (hadLiveEnmityIcon == true or plateData.detachedAvatarSetupPreview == true) then
        enmity.AddIcon(plateData, {
            allyIconFile = enmitySettings.allyIconFile,
            allyColor = enmitySettings.allyColor,
            allyIconSize = GetDetachedAvatarMeterNumber(enmitySettings, 'allyIconSize', 31) * scaleInverse,
            allyOffsetX = GetDetachedAvatarMeterNumber(enmitySettings, 'allyOffsetX', -108) * scaleInverse,
            allyOffsetY = GetDetachedAvatarMeterNumber(enmitySettings, 'allyOffsetY', -17) * scaleInverse,
        }, 'ally');
    end
end

local function BuildDetachedPupResourceBar(source, settings, defaults, percent, text, scaleInverse, globalSettings)
    local color = settings.color or defaults.color;
    local lowActive = settings.lowColorEnabled == true
        and percent <= (tonumber(settings.lowColorPercent) or 25);
    if (lowActive == true) then
        color = settings.lowColor or color;
    end

    return CopySettingsWith(source, {
        enabled = settings.enabled ~= false,
        width = math.max(1, GetDetachedAvatarMeterNumber(settings, 'width', defaults.width) * scaleInverse),
        height = math.max(1, GetDetachedAvatarMeterNumber(settings, 'height', defaults.height) * scaleInverse),
        offsetX = GetDetachedAvatarMeterNumber(settings, 'offsetX', defaults.offsetX) * scaleInverse,
        offsetY = GetDetachedAvatarMeterNumber(settings, 'offsetY', defaults.offsetY) * scaleInverse,
        anchorTo = settings.anchorTo or 'Plate',
        anchorPoint = settings.anchorPoint or 'Center',
        color = color,
        color2 = settings.color2 or defaults.color2,
        color3 = settings.color3 or defaults.color3,
        backgroundColor = settings.backgroundColor or defaults.backgroundColor,
        borderColor = settings.borderColor or defaults.borderColor,
        borderSize = GetDetachedAvatarMeterNumber(settings, 'borderSize', defaults.borderSize) * scaleInverse,
        cornerRadius = GetDetachedAvatarMeterNumber(settings, 'cornerRadius', defaults.cornerRadius or 0) * scaleInverse,
        texture = settings.texture or defaults.texture or 'Solid',
        textureId = barTextures.GetTextureId(settings.texture or defaults.texture or 'Solid'),
        textureStrength = GetDetachedAvatarMeterNumber(settings, 'textureStrength', defaults.textureStrength or 100),
        animationEnabled = lowActive == true and settings.lowAnimationEnabled == true,
        animationTextureId = barAnimations.GetTextureId(settings.lowAnimation),
        animationSpeed = tonumber(settings.lowAnimationSpeed) or defaults.lowAnimationSpeed,
        animationColor = settings.lowAnimationColor,
        showAtPercent = GetDetachedAvatarMeterNumber(settings, 'showAtPercent', defaults.showAtPercent or 100),
        segmented = settings.segmented == true,
        segmentGap = GetDetachedAvatarMeterNumber(settings, 'segmentGap', defaults.segmentGap or 0) * scaleInverse,
        text = text,
        textOffsetX = GetDetachedAvatarMeterNumber(settings, 'textOffsetX', defaults.textOffsetX or 0) * scaleInverse,
        textOffsetY = GetDetachedAvatarMeterNumber(settings, 'textOffsetY', defaults.textOffsetY or 0) * scaleInverse,
        fontFamily = fonts.GetRole(globalSettings, settings.useSmallFont == true),
        fontFlags = fonts.GetRoleFlags(globalSettings, settings.useSmallFont == true),
        fontSize = math.max(1, GetDetachedAvatarMeterNumber(settings, 'fontSize', defaults.fontSize or 7) * scaleInverse),
        textColor = settings.textColor or defaults.textColor,
        textOutlineEnabled = settings.textOutlineEnabled == true,
        textOutlineColor = settings.textOutlineColor or defaults.textOutlineColor,
        textOutlineSize = GetDetachedAvatarMeterNumber(settings, 'textOutlineSize', defaults.textOutlineSize or 1) * scaleInverse,
    });
end

local function ApplyDetachedPupWidgets(plateData, background)
    if (background == nil or background.pupArtwork ~= true) then
        return;
    end

    local defaults = ((globalDefaults.targeting or {}).pupPetStaticBackgroundSettings or {});
    local nameSettings = background.pupNameSettings or defaults.pupNameSettings or nameDefaults;
    local hpSettings = background.pupHpBarSettings or defaults.pupHpBarSettings or barDefaults;
    local mpSettings = background.pupMpBarSettings or defaults.pupMpBarSettings or mpBarDefaults;
    local tpSettings = background.pupTpBarSettings or defaults.pupTpBarSettings or tpBarDefaults;
    local maneuverSettings = background.pupManeuverSettings or defaults.pupManeuverSettings or maneuverDefaults;
    local scaleInverse = tonumber(background.scaleInverse) or 1;
    local globalSettings = state.GetGlobalSettings(globalDefaults);

    if (nameSettings.enabled == false) then
        plateData.name = '';
    else
        plateData.name = tostring(plateData.detachedPupName or plateData.name or '');
        plateData.nameOffsetX = GetDetachedAvatarMeterNumber(nameSettings, 'offsetX', 0) * scaleInverse;
        plateData.nameOffsetY = GetDetachedAvatarMeterNumber(nameSettings, 'offsetY', -54) * scaleInverse;
        plateData.nameFontSize = math.max(1, GetDetachedAvatarMeterNumber(nameSettings, 'textSize', 10) * scaleInverse);
        plateData.nameColor = nameSettings.color or nameDefaults.color;
        plateData.nameOutlineColor = nameSettings.outlineColor or nameDefaults.outlineColor;
        plateData.nameOutlineSize = math.max(0, GetDetachedAvatarMeterNumber(nameSettings, 'outlineSize', 2) * scaleInverse);
        plateData.nameOutlineEnabled = nameSettings.outlineEnabled ~= false and plateData.nameOutlineSize > 0;
        plateData.nameAnchorTo = nameSettings.anchorTo or 'Plate';
        plateData.nameAnchorPoint = nameSettings.anchorPoint or 'Center';
        plateData.forceName = true;
    end

    local hpPercent = math.max(0, math.min(100, tonumber(plateData.hp) or 0));
    local mpPercent = math.max(0, math.min(100, tonumber(plateData.mp) or 0));
    local setupPreview = plateData.detachedPupSetupPreview == true;
    local tpPercent = setupPreview
        and 300
        or math.max(0, math.min(300, tonumber(plateData.tp) or 0));
    local tpValue = setupPreview and 3000 or plateData.detachedPupTp;
    if (setupPreview == true) then
        -- DrawTpBar reads the plate value directly, so the unlocked detached
        -- settings preview must provide the sample used to fill all sections.
        plateData.tp = tpPercent;
    end

    plateData.hpBar = BuildDetachedPupResourceBar(
        plateData.hpBar,
        hpSettings,
        barDefaults,
        hpPercent,
        BuildPercentFallbackResourceText(hpSettings, 'HP', nil, nil, hpPercent),
        scaleInverse,
        globalSettings
    );
    plateData.mpBar = BuildDetachedPupResourceBar(
        plateData.mpBar,
        mpSettings,
        mpBarDefaults,
        mpPercent,
        BuildPercentFallbackResourceText(mpSettings, 'MP', nil, nil, mpPercent),
        scaleInverse,
        globalSettings
    );
    plateData.tpBar = BuildDetachedPupResourceBar(
        plateData.tpBar,
        tpSettings,
        tpBarDefaults,
        tpPercent,
        BuildResourceText(tpSettings, 'TP', tpValue, 3000, tpPercent),
        scaleInverse,
        globalSettings
    );
    if (setupPreview == true) then
        plateData.tpBar.enabled = true;
        plateData.tpBar.showAtPercent = 0;
    end

    plateData.icons = (function()
        local retained = {};
        for _, icon in ipairs(plateData.icons or {}) do
            if (tostring(icon.kind or '') ~= 'maneuvers') then
                retained[#retained + 1] = icon;
            end
        end
        return retained;
    end)();

    local detachedManeuverSettings = CopySettingsWith(maneuverSettings, {
        iconSize = GetDetachedAvatarMeterNumber(maneuverSettings, 'iconSize', maneuverDefaults.iconSize) * scaleInverse,
        iconSpacing = GetDetachedAvatarMeterNumber(maneuverSettings, 'iconSpacing', maneuverDefaults.iconSpacing) * scaleInverse,
        offsetX = GetDetachedAvatarMeterNumber(maneuverSettings, 'offsetX', maneuverDefaults.offsetX) * scaleInverse,
        offsetY = GetDetachedAvatarMeterNumber(maneuverSettings, 'offsetY', maneuverDefaults.offsetY) * scaleInverse,
        timerFontSize = GetDetachedAvatarMeterNumber(maneuverSettings, 'timerFontSize', maneuverDefaults.timerFontSize) * scaleInverse,
        timerOffsetY = GetDetachedAvatarMeterNumber(maneuverSettings, 'timerOffsetY', maneuverDefaults.timerOffsetY) * scaleInverse,
        timerTextOutlineSize = GetDetachedAvatarMeterNumber(maneuverSettings, 'timerTextOutlineSize', maneuverDefaults.timerTextOutlineSize) * scaleInverse,
    });
    pupManeuvers.AddIcons(
        plateData,
        detachedManeuverSettings,
        globalSettings,
        plateData.detachedPupManeuverState or pupManeuvers.GetPreviewState()
    );

end

local function AddDetachedAvatarGemMeters(plateData, background)
    if (background == nil or background.avatarArtwork ~= true) then
        return;
    end

    local originalBars = plateData.extraBars or {};
    local sourceBars = {};
    local retainedBars = {};

    for _, bar in ipairs(originalBars) do
        local kind = tostring(bar.kind or ''):lower();
        if (kind == 'rage' or kind == 'ward' or kind == 'favor') then
            sourceBars[kind] = bar;
        else
            retainedBars[#retainedBars + 1] = bar;
        end
    end

    -- Detached Avatar meters have their own data source.  Do not make their
    -- visibility or progress depend on whether the normal pet widgets happen
    -- to be enabled or present in the source plate.
    if (type(plateData.detachedAvatarBars) == 'table') then
        sourceBars = {};
        for _, bar in ipairs(plateData.detachedAvatarBars) do
            local kind = tostring(bar.kind or ''):lower();
            if (kind == 'rage' or kind == 'ward' or kind == 'favor') then
                sourceBars[kind] = bar;
            end
        end
    end

    -- The setup preview must provide visible sample text independently of the
    -- live Blood Pact recast state, which may be Ready and therefore textless.
    if (plateData.detachedAvatarSetupPreview == true) then
        sourceBars.rage = {
            kind = 'rage',
            progress = 50,
            text = '30s',
        };
    end

    local detachedDefaults = ((globalDefaults.targeting or {}).smnPetStaticBackgroundSettings or {});
    local wardSettings = background.avatarWardSettings or detachedDefaults.avatarWardSettings or {};
    local rageSettings = background.avatarRageSettings or detachedDefaults.avatarRageSettings or {};
    local favorSettings = background.avatarFavorSettings or detachedDefaults.avatarFavorSettings or {};
    local globalSettings = state.GetGlobalSettings(globalDefaults);
    local scaleInverse = tonumber(background.scaleInverse) or 1;
    local rawWidth = tonumber(background.rawWidth) or 220;
    local rawHeight = tonumber(background.rawHeight) or 74;
    local defaultMeterWidth = rawWidth * 0.088;
    local defaultMeterHeight = rawHeight * 0.265;

    local gemLayout = {
        rage = BuildDetachedAvatarMeterBar(background, rageSettings, {
            width = defaultMeterWidth,
            height = defaultMeterHeight,
            offsetX = (0.450 - 0.5) * rawWidth,
            offsetY = (0.730 - 0.5) * rawHeight,
            color = { 1.0, 0.12, 0.12, 0.92 },
            backgroundColor = { 0.02, 0.02, 0.02, 0.70 },
            borderColor = { 0.0, 0.0, 0.0, 0.0 },
            borderSize = 0,
            cornerRadius = defaultMeterWidth * 0.18,
            texture = 'Solid',
            textureStrength = 100,
        }),
        ward = BuildDetachedAvatarMeterBar(background, wardSettings, {
            width = defaultMeterWidth,
            height = defaultMeterHeight,
            offsetX = (0.642 - 0.5) * rawWidth,
            offsetY = (0.735 - 0.5) * rawHeight,
            color = { 0.12, 0.55, 1.0, 0.92 },
            backgroundColor = { 0.02, 0.02, 0.02, 0.70 },
            borderColor = { 0.0, 0.0, 0.0, 0.0 },
            borderSize = 0,
            cornerRadius = defaultMeterWidth * 0.18,
            texture = 'Solid',
            textureStrength = 100,
        }),
    };

    for _, kind in ipairs({ 'rage', 'ward' }) do
        local source = sourceBars[kind];
        local layout = gemLayout[kind];
        local settings = kind == 'rage' and rageSettings or wardSettings;
        local displayMode = tostring(settings.labelDisplayMode or 'None');

        if (source ~= nil and layout ~= nil and settings.enabled ~= false) then
            retainedBars[#retainedBars + 1] = {
                kind = 'detached_avatar_' .. kind,
                enabled = true,
                progress = tonumber(source.progress) or 0,
                width = layout.width,
                height = layout.height,
                offsetX = layout.offsetX,
                offsetY = layout.offsetY,
                color = layout.color,
                backgroundColor = layout.backgroundColor,
                borderColor = layout.borderColor,
                borderSize = layout.borderSize,
                cornerRadius = layout.cornerRadius,
                textureId = layout.textureId,
                textureStrength = layout.textureStrength,
                fillDirection = settings.fillDirection or 'Bottom to top',
                text = settings.showPercent ~= false and tostring(source.text or '') or '',
                labelText = displayMode == 'Text' and (kind == 'rage' and 'Rage' or 'Ward') or '',
                iconTextureId = displayMode == 'Icon' and GetPetStateIconTextureId(kind) or nil,
                iconSize = GetDetachedAvatarMeterNumber(settings, 'labelIconSize', 14) * scaleInverse,
                iconOffsetX = GetDetachedAvatarMeterNumber(settings, 'labelIconOffsetX', 0) * scaleInverse,
                iconOffsetY = GetDetachedAvatarMeterNumber(settings, 'labelIconOffsetY', 0) * scaleInverse,
                separateLabelOffsets = displayMode ~= 'None',
                fontFamily = fonts.GetRole(globalSettings, settings.useSmallFont == true),
                fontFlags = fonts.GetRoleFlags(globalSettings, settings.useSmallFont == true),
                fontSize = math.max(1, GetDetachedAvatarMeterNumber(settings, 'fontSize', 7) * scaleInverse),
                textColor = settings.textColor or { 1.0, 1.0, 1.0, 1.0 },
                textOutlineEnabled = settings.textOutlineEnabled == true,
                textOutlineSize = GetDetachedAvatarMeterNumber(settings, 'textOutlineSize', 1) * scaleInverse,
                textOutlineColor = settings.textOutlineColor or { 0.0, 0.0, 0.0, 1.0 },
                textOffsetX = GetDetachedAvatarMeterNumber(settings, 'textOffsetX', 0) * scaleInverse,
                textOffsetY = GetDetachedAvatarMeterNumber(settings, 'textOffsetY', 0) * scaleInverse,
            };
        end
    end

    local favorActive = plateData.detachedAvatarFavorActive == true;
    local favorCooldownSeconds = math.max(0, tonumber(plateData.detachedAvatarFavorCooldownSeconds) or 0);
    if (favorSettings.enabled ~= false and favorActive == true) then
        local avatarName = plateData.detachedAvatarFavorAvatarName;
        local hasPet = plateData.detachedAvatarHasPet == true;
        local favorTextureId = nil;

        if (hasPet == true and tostring(avatarName or '') ~= '') then
            favorTextureId = GetDetachedFavorEffectTextureId(avatarName);
        elseif (hasPet ~= true) then
            favorTextureId = GetPetStateIconTextureId('favor');
        end

        if (favorTextureId ~= nil) then
            plateData.icons = plateData.icons or {};
            plateData.icons[#plateData.icons + 1] = {
                kind = 'detachedAvatarFavor',
                textureId = favorTextureId,
                size = math.max(1, GetDetachedAvatarMeterNumber(
                    favorSettings,
                    'iconSize',
                    tonumber(favorSettings.labelIconSize) or 20
                ) * scaleInverse),
                offsetX = GetDetachedAvatarMeterNumber(favorSettings, 'offsetX', 72) * scaleInverse,
                offsetY = GetDetachedAvatarMeterNumber(favorSettings, 'offsetY', 17) * scaleInverse,
                anchorTo = favorSettings.anchorTo or 'Plate',
                anchorPoint = favorSettings.anchorPoint or 'Center',
            };
        end
    elseif (
        favorSettings.enabled ~= false and
        favorSettings.showCooldown ~= false and
        plateData.detachedAvatarHasPet ~= true
    ) then
        local favorText = favorCooldownSeconds > 0
            and statusTimerFormat.Format(favorCooldownSeconds)
            or 'Ready';
        local iconSize = GetDetachedAvatarMeterNumber(favorSettings, 'iconSize', 20);

        plateData.texts = plateData.texts or {};
        plateData.texts[#plateData.texts + 1] = {
            kind = 'detachedAvatarFavorCooldown',
            text = favorText,
            align = 'center',
            offsetX = (
                GetDetachedAvatarMeterNumber(favorSettings, 'offsetX', 72) +
                GetDetachedAvatarMeterNumber(favorSettings, 'cooldownOffsetX', 0)
            ) * scaleInverse,
            offsetY = (
                GetDetachedAvatarMeterNumber(favorSettings, 'offsetY', 17) +
                (iconSize * 0.5) + 1 +
                GetDetachedAvatarMeterNumber(favorSettings, 'cooldownOffsetY', 1)
            ) * scaleInverse,
            anchorTo = favorSettings.anchorTo or 'Plate',
            anchorPoint = favorSettings.anchorPoint or 'Center',
            fontFamily = fonts.GetRole(globalSettings, favorSettings.cooldownUseSmallFont == true),
            fontFlags = fonts.GetRoleFlags(globalSettings, favorSettings.cooldownUseSmallFont == true),
            fontSize = math.max(8, GetDetachedAvatarMeterNumber(favorSettings, 'cooldownFontSize', 8) * scaleInverse),
            color = favorSettings.cooldownTextColor or { 1.0, 1.0, 1.0, 1.0 },
            outlineEnabled = (tonumber(favorSettings.cooldownOutlineSize) or 0) > 0,
            outlineColor = favorSettings.cooldownOutlineColor or { 0.0, 0.0, 0.0, 1.0 },
            outlineSize = GetDetachedAvatarMeterNumber(favorSettings, 'cooldownOutlineSize', 1) * scaleInverse,
        };
    end

    plateData.extraBars = retainedBars;
end

local function BuildStaticPetBarsKey(plateData)
    local parts = {};

    for _, bar in ipairs((plateData or {}).extraBars or {}) do
        local kind = tostring(bar.kind or '');
        if (
            kind == 'detached_avatar_rage' or
            kind == 'detached_avatar_ward'
        ) then
            parts[#parts + 1] = table.concat({
                kind,
                tostring(math.floor(((tonumber(bar.progress) or 0) * 1000) + 0.5)),
                tostring(bar.text or ''),
            }, ':');
        end
    end

    return table.concat(parts, ',');
end

local function BuildStaticPetTextureKey(prefix, petIndex, background, plateData)
    return table.concat({
        tostring(prefix) .. '-pet-static',
        tostring(petIndex),
        'bg=' .. tostring(background.enabled),
        'w=' .. tostring(background.width),
        'h=' .. tostring(background.height),
        'x=' .. tostring(background.offsetX),
        'y=' .. tostring(background.offsetY),
        'tex=' .. tostring(background.texture),
        'imageOpacity=' .. tostring(background.imageOpacity),
        'color=' .. ColorKey(background.color),
        'border=' .. ColorKey(background.borderColor),
        'bs=' .. tostring(background.borderSize),
        'avatarMeters=' .. TableSettingKey(background.avatarGemMeters or {}, {
            'rageColor', 'rageBackgroundColor', 'rageBorderColor', 'rageBorderSize',
            'rageWidth', 'rageHeight', 'ragePositionX', 'ragePositionY',
            'rageTexture', 'rageTextureStrength', 'rageCornerRadius',
            'rageShowText', 'rageFontSize', 'rageFontColor', 'rageOutlineSize',
            'rageOutlineColor', 'rageOffsetX', 'rageOffsetY',
            'wardColor', 'wardBackgroundColor', 'wardBorderColor', 'wardBorderSize',
            'wardWidth', 'wardHeight', 'wardPositionX', 'wardPositionY',
            'wardTexture', 'wardTextureStrength', 'wardCornerRadius',
            'wardShowText', 'wardFontSize', 'wardFontColor', 'wardOutlineSize',
            'wardOutlineColor', 'wardOffsetX', 'wardOffsetY',
            'favorColor', 'favorColor1', 'favorColor2', 'favorColor3',
            'favorBackgroundColor', 'favorBorderColor', 'favorBorderSize',
            'favorWidth', 'favorHeight', 'favorPositionX', 'favorPositionY',
            'favorTexture', 'favorTextureStrength', 'favorCornerRadius',
            'favorShowText', 'favorFontSize', 'favorFontColor', 'favorOutlineSize',
            'favorOutlineColor', 'favorUseSmallFont',
            'favorSpacing', 'favorPadding',
        }),
        'avatarName=' .. TableSettingKey(background.avatarNameSettings or {}, {
            'enabled', 'offsetX', 'offsetY', 'textSize', 'color',
            'outlineEnabled', 'outlineColor', 'outlineSize', 'anchorTo', 'anchorPoint',
        }),
        'avatarHp=' .. TableSettingKey(background.avatarHpBarSettings or {}, {
            'enabled', 'width', 'height', 'offsetX', 'offsetY', 'color',
            'backgroundColor', 'borderColor', 'borderSize', 'cornerRadius',
            'texture', 'textureStrength', 'showValue', 'showPercent', 'showAtPercent',
            'textOffsetX', 'textOffsetY', 'useSmallFont', 'fontSize', 'textColor',
            'textOutlineEnabled', 'textOutlineColor', 'textOutlineSize',
            'lowColorEnabled', 'lowColorPercent', 'lowColor', 'lowAnimationEnabled',
            'lowAnimation', 'lowAnimationSpeed', 'lowAnimationColor', 'anchorTo', 'anchorPoint',
        }),
        'avatarMp=' .. TableSettingKey(background.avatarMpBarSettings or {}, {
            'enabled', 'width', 'height', 'offsetX', 'offsetY', 'color',
            'backgroundColor', 'borderColor', 'borderSize', 'cornerRadius',
            'texture', 'textureStrength', 'showPercent', 'showAtPercent',
            'textOffsetX', 'textOffsetY', 'useSmallFont', 'fontSize', 'textColor',
            'textOutlineEnabled', 'textOutlineColor', 'textOutlineSize',
            'lowColorEnabled', 'lowColorPercent', 'lowColor', 'lowAnimationEnabled',
            'lowAnimation', 'lowAnimationSpeed', 'lowAnimationColor', 'anchorTo', 'anchorPoint',
        }),
        'avatarTp=' .. TableSettingKey(background.avatarTpBarSettings or {}, {
            'enabled', 'width', 'height', 'offsetX', 'offsetY', 'color',
            'color2', 'color3', 'fullColor',
            'backgroundColor', 'borderColor', 'borderSize', 'cornerRadius',
            'texture', 'textureStrength', 'showValue', 'showPercent', 'showAtPercent',
            'segmented', 'segmentGap', 'textOffsetX', 'textOffsetY', 'useSmallFont',
            'fontSize', 'textColor', 'textOutlineEnabled', 'textOutlineColor',
            'textOutlineSize', 'anchorTo', 'anchorPoint',
        }),
        'avatarCast=' .. TableSettingKey(background.avatarCastBarSettings or {}, {
            'enabled', 'width', 'height', 'offsetX', 'offsetY', 'color',
            'backgroundColor', 'borderColor', 'borderSize', 'cornerRadius', 'texture',
            'showSpellName', 'textOffsetX', 'textOffsetY', 'useSmallFont',
            'fontSize', 'textColor', 'textOutlineEnabled', 'textOutlineColor',
            'textOutlineSize', 'showSpellIcon', 'spellIconSize',
            'spellIconOffsetX', 'spellIconOffsetY', 'anchorTo', 'anchorPoint',
        }),
        'avatarWard=' .. TableSettingKey(background.avatarWardSettings or {}, {
            'enabled', 'width', 'height', 'offsetX', 'offsetY', 'color',
            'backgroundColor', 'borderColor', 'borderSize', 'cornerRadius',
            'texture', 'textureStrength', 'fillDirection', 'labelDisplayMode',
            'labelIconSize', 'labelIconOffsetX', 'labelIconOffsetY', 'showPercent',
            'textOffsetX', 'textOffsetY', 'useSmallFont', 'fontSize', 'textColor',
            'textOutlineEnabled', 'textOutlineColor', 'textOutlineSize',
        }),
        'avatarRage=' .. TableSettingKey(background.avatarRageSettings or {}, {
            'enabled', 'width', 'height', 'offsetX', 'offsetY', 'color',
            'backgroundColor', 'borderColor', 'borderSize', 'cornerRadius',
            'texture', 'textureStrength', 'fillDirection', 'labelDisplayMode',
            'labelIconSize', 'labelIconOffsetX', 'labelIconOffsetY', 'showPercent',
            'textOffsetX', 'textOffsetY', 'useSmallFont', 'fontSize', 'textColor',
            'textOutlineEnabled', 'textOutlineColor', 'textOutlineSize',
        }),
        'avatarFavor=' .. TableSettingKey(background.avatarFavorSettings or {}, {
            'enabled', 'iconSize', 'offsetX', 'offsetY', 'showCooldown',
            'cooldownOffsetX', 'cooldownOffsetY', 'cooldownUseSmallFont',
            'cooldownFontSize', 'cooldownTextColor', 'cooldownOutlineColor',
            'cooldownOutlineSize', 'anchorTo', 'anchorPoint',
        }),
        'pupName=' .. TableSettingKey(background.pupNameSettings or {}, {
            'enabled', 'offsetX', 'offsetY', 'textSize', 'color',
            'outlineEnabled', 'outlineColor', 'outlineSize', 'anchorTo', 'anchorPoint',
        }),
        'pupHp=' .. TableSettingKey(background.pupHpBarSettings or {}, {
            'enabled', 'width', 'height', 'offsetX', 'offsetY', 'color',
            'backgroundColor', 'borderColor', 'borderSize', 'cornerRadius',
            'texture', 'textureStrength', 'showValue', 'showPercent',
            'textOffsetX', 'textOffsetY', 'useSmallFont', 'fontSize', 'textColor',
            'textOutlineEnabled', 'textOutlineColor', 'textOutlineSize',
            'lowColorEnabled', 'lowColorPercent', 'lowColor',
            'lowAnimationEnabled', 'lowAnimation', 'lowAnimationSpeed', 'lowAnimationColor',
        }),
        'pupMp=' .. TableSettingKey(background.pupMpBarSettings or {}, {
            'enabled', 'width', 'height', 'offsetX', 'offsetY', 'color',
            'backgroundColor', 'borderColor', 'borderSize', 'cornerRadius',
            'texture', 'textureStrength', 'showValue', 'showPercent',
            'textOffsetX', 'textOffsetY', 'useSmallFont', 'fontSize', 'textColor',
            'textOutlineEnabled', 'textOutlineColor', 'textOutlineSize',
            'lowColorEnabled', 'lowColorPercent', 'lowColor',
            'lowAnimationEnabled', 'lowAnimation', 'lowAnimationSpeed', 'lowAnimationColor',
        }),
        'pupTp=' .. TableSettingKey(background.pupTpBarSettings or {}, {
            'enabled', 'width', 'height', 'offsetX', 'offsetY', 'color',
            'color2', 'color3', 'fullColor', 'backgroundColor', 'borderColor',
            'borderSize', 'cornerRadius', 'texture', 'textureStrength',
            'showValue', 'showPercent', 'segmented', 'segmentGap',
            'textOffsetX', 'textOffsetY', 'useSmallFont', 'fontSize', 'textColor',
            'textOutlineEnabled', 'textOutlineColor', 'textOutlineSize',
            'lowColorEnabled', 'lowColorPercent', 'lowColor',
        }),
        'pupManeuvers=' .. TableSettingKey(background.pupManeuverSettings or {}, {
            'enabled', 'iconSet', 'iconSize', 'iconSpacing', 'offsetX', 'offsetY',
            'showTimers', 'timerUseSmallFont', 'timerFontSize', 'timerOffsetY',
            'timerTextColor', 'timerTextOutlineColor', 'timerTextOutlineSize',
        }),
        'favorState=' .. tostring(plateData.detachedAvatarFavorActive == true),
        'favorHasPet=' .. tostring(plateData.detachedAvatarHasPet == true),
        'favorAvatar=' .. tostring(plateData.detachedAvatarFavorAvatarName or plateData.detachedAvatarName or ''),
        'bars=' .. BuildStaticPetBarsKey(plateData),
    }, '|');
end

local function GetStaticPetContentCrop(plateData, textureWidth, textureHeight, ignoredKinds, includedKinds)
    local sourceW = math.max(1, tonumber(textureWidth) or 1024);
    local sourceH = math.max(1, tonumber(textureHeight) or 512);
    local minX, minY, maxX, maxY = nil, nil, nil, nil;
    local rects = plateData._elementRects or canvasTexture.GetElementRects(plateData);

    for _, rect in ipairs(rects or {}) do
        local rectKind = tostring(rect.kind or '');
        local ignored = type(ignoredKinds) == 'table' and ignoredKinds[rectKind] == true;
        if (type(includedKinds) == 'table' and includedKinds[rectKind] ~= true) then
            ignored = true;
        end
        if (rect.anchorOnly ~= true and ignored ~= true) then
            local x1 = tonumber(rect.x1) or tonumber(rect.drawX1);
            local y1 = tonumber(rect.y1) or tonumber(rect.drawY1);
            local x2 = tonumber(rect.x2) or tonumber(rect.drawX2);
            local y2 = tonumber(rect.y2) or tonumber(rect.drawY2);

            if (x1 ~= nil and y1 ~= nil and x2 ~= nil and y2 ~= nil and x2 > x1 and y2 > y1) then
                minX = minX == nil and x1 or math.min(minX, x1);
                minY = minY == nil and y1 or math.min(minY, y1);
                maxX = maxX == nil and x2 or math.max(maxX, x2);
                maxY = maxY == nil and y2 or math.max(maxY, y2);
            end
        end
    end

    if (minX == nil or minY == nil or maxX == nil or maxY == nil) then
        return 0, 0, sourceW, sourceH;
    end

    local padding = 4;
    minX = math.max(0, math.floor(minX - padding));
    minY = math.max(0, math.floor(minY - padding));
    maxX = math.min(sourceW, math.ceil(maxX + padding));
    maxY = math.min(sourceH, math.ceil(maxY + padding));

    return minX, minY, math.max(1, maxX - minX), math.max(1, maxY - minY);
end

local pupElementArtworkFiles = {
    fire = 'Fire.png',
    ice = 'Ice.png',
    wind = 'Wind.png',
    earth = 'Earth.png',
    thunder = 'Lightning.png',
    lightning = 'Lightning.png',
    water = 'Water.png',
    light = 'Light.png',
    dark = 'Dark.png',
};

local function NormalizePupBurdenElement(element)
    local key = tostring(element or ''):lower():gsub('%s+', '');
    if (key == 'lightning') then
        key = 'thunder';
    end
    return pupElementArtworkFiles[key] ~= nil and key or nil;
end

local function GetHighestPupBurden()
    local now = os.clock();
    local bestElement = nil;
    local bestChance = nil;
    local bestUpdatedAt = nil;

    for element, burden in pairs(pupOverloadGaugeTest.burdens or {}) do
        local updatedAt = tonumber(burden.updatedAt) or now;
        local age = math.max(0, now - updatedAt);
        local chance = math.max(
            0,
            (tonumber(burden.chance) or 0) - math.floor(age / 3)
        );

        -- A reported 0% can still contain sub-threshold burden. Activation
        -- burden fully dissipates in roughly two minutes, so do not retain a
        -- zero-value element indefinitely.
        if (chance <= 0 and age > 120) then
            pupOverloadGaugeTest.burdens[element] = nil;
        elseif (
            bestChance == nil or
            chance > bestChance or
            (chance == bestChance and updatedAt > (bestUpdatedAt or 0))
        ) then
            bestElement = element;
            bestChance = chance;
            bestUpdatedAt = updatedAt;
        end
    end

    return bestElement, bestChance;
end

local function DrawPupHighestBurdenElement(frameCenterX, frameCenterY, settings, preview, windowId)
    if (DrawStaticArtworkTexture == nil) then
        return;
    end

    settings = settings or {};
    if (settings.enabled == false) then
        return;
    end

    local element = select(1, GetHighestPupBurden());
    if (element == nil and preview == true) then
        element = 'fire';
    end

    local fileName = pupElementArtworkFiles[element];
    local textureId = fileName ~= nil
        and backgroundTextures.GetPupElementArtworkTextureId(fileName)
        or nil;
    if (textureId == nil) then
        return;
    end

    local size = math.max(1, tonumber(settings.size) or 24);
    local centerX = frameCenterX + (tonumber(settings.offsetX) or -112);
    local centerY = frameCenterY + (tonumber(settings.offsetY) or -5);
    DrawStaticArtworkTexture(
        textureId,
        centerX,
        centerY,
        size,
        size,
        tostring(windowId or 'static_pup') .. '_element',
        100
    );
end

local function DrawPupOverloadGaugeTest(drawList, frameCenterX, frameCenterY, settings, preview)
    if (
        drawList == nil or
        imgui.GetColorU32 == nil or
        drawList.AddCircle == nil or
        drawList.AddLine == nil
    ) then
        return;
    end

    settings = settings or {};
    if (settings.enabled == false) then
        return;
    end

    local highestElement, highestChance = GetHighestPupBurden();
    pupOverloadGaugeTest.element = highestElement;
    pupOverloadGaugeTest.chance = highestChance;
    local displayChance = highestChance;
    if (displayChance == nil and preview == true) then
        displayChance = 50;
    end
    local chance = math.max(0, math.min(100, tonumber(displayChance) or 0));
    local size = math.max(8, tonumber(settings.size) or 58);
    local centerX = frameCenterX + (tonumber(settings.offsetX) or -73);
    local centerY = frameCenterY + (tonumber(settings.offsetY) or -5);
    local radius = size * 0.5;
    -- The artwork's printed scale spans the long 270-degree arc:
    -- 0% at lower-left, 50% straight up, and 100% at lower-right.
    local angle = math.rad(135 + (chance * 2.70));
    local endX = centerX + (math.cos(angle) * (radius - 6));
    local endY = centerY + (math.sin(angle) * (radius - 6));
    local darkColor = imgui.GetColorU32(settings.backgroundColor or { 0.03, 0.03, 0.03, 0.95 });
    local rimColor = imgui.GetColorU32(settings.ringColor or { 0.90, 0.72, 0.38, 1.00 });
    local dialColor = settings.safeColor or { 0.25, 0.90, 0.35, 1.00 };
    if (pupOverloadGaugeTest.overloaded == true) then
        dialColor = settings.overloadedColor or { 1.00, 0.05, 0.02, 1.00 };
    elseif chance > 0 then
        dialColor = settings.warningColor or { 1.00, 0.60, 0.12, 1.00 };
    end
    local needleColor = imgui.GetColorU32(dialColor);
    local centerDotColor = imgui.GetColorU32(settings.centerDotColor or settings.ringColor or { 0.90, 0.72, 0.38, 1.00 });
    local ringSize = math.max(1, tonumber(settings.ringSize) or 3);
    local dialSize = math.max(1, tonumber(settings.dialSize) or 3);

    if (settings.showBackground ~= false and drawList.AddCircleFilled ~= nil) then
        drawList:AddCircleFilled({ centerX, centerY }, radius, darkColor, 32);
    end
    if (settings.showRing ~= false) then
        drawList:AddCircle({ centerX, centerY }, radius, rimColor, 32, ringSize);
    end
    drawList:AddLine({ centerX, centerY }, { endX, endY }, darkColor, dialSize + 3);
    drawList:AddLine({ centerX, centerY }, { endX, endY }, needleColor, dialSize);
    if (drawList.AddCircleFilled ~= nil) then
        drawList:AddCircleFilled({ centerX, centerY }, 4, centerDotColor, 16);
    end

    local percentText = displayChance ~= nil
        and string.format('%d%%', math.floor(chance + 0.5))
        or '--%';
    local globalSettings = state.GetGlobalSettings(globalDefaults);
    local textTextureId, textWidth, textHeight = gdiTextTexture.GetTexture(percentText, {
        fontFamily = fonts.GetRole(globalSettings, settings.useSmallFont == true),
        fontFlags = fonts.GetRoleFlags(globalSettings, settings.useSmallFont == true),
        fontSize = textScale.ToTextureFontSize(settings.fontSize, 10),
        color = settings.textColor or { 1.0, 1.0, 1.0, 1.0 },
        outlineEnabled = (tonumber(settings.textOutlineSize) or 0) > 0,
        outlineColor = settings.textOutlineColor or { 0.0, 0.0, 0.0, 1.0 },
        outlineSize = tonumber(settings.textOutlineSize) or 2,
    });
    if (textTextureId ~= nil and drawList.AddImage ~= nil) then
        local textX = centerX - ((tonumber(textWidth) or 0) * 0.5)
            + (tonumber(settings.textOffsetX) or 0);
        local textY = centerY + radius + 5
            + (tonumber(settings.textOffsetY) or 0);
        drawList:AddImage(
            textTextureId,
            { textX, textY },
            { textX + (tonumber(textWidth) or 0), textY + (tonumber(textHeight) or 0) },
            { 0, 0 },
            { 1, 1 },
            0xFFFFFFFF
        );
    end
end

local function DrawDetachedStaticPetFrame(prefix, petIndex, plateData, targetingSettings, windowId, petName, settingsPrefix)
    settingsPrefix = tostring(settingsPrefix or prefix);
    local staticScale = math.max(0.10, math.min(2.00, (tonumber(GetDetachedPetSetting(targetingSettings, prefix, settingsPrefix, 'PetStaticScale')) or 35) / 100));
    if (prefix == 'pup') then
        -- PUP uses a fixed internal scale so its wide artwork fits the
        -- 1024x512 canvas without an adaptive calculation or second render.
        staticScale = 0.60;
    end

    local staticBackground = BuildStaticPetBackground(targetingSettings, prefix, settingsPrefix, staticScale, petName);
    local staticPlateData = CopySettingsWith(plateData, {
        background = staticBackground,
    });
    local editEnabled = GetDetachedPetSetting(
        targetingSettings,
        prefix,
        settingsPrefix,
        'PetStaticEditFrame'
    ) == true;
    if (prefix == 'pup' and editEnabled == true) then
        staticPlateData.detachedPupSetupPreview = true;
        staticPlateData.detachedPupManeuverState = pupManeuvers.GetPreviewState();
    end
    ApplyDetachedAvatarWidgets(staticPlateData, staticBackground);
    ApplyDetachedPupWidgets(staticPlateData, staticBackground);
    AddDetachedAvatarGemMeters(staticPlateData, staticBackground);
    -- The source plate may already contain layout bounds for its normal Background
    -- widget. Detached frames have their own background and must rebuild those bounds.
    staticPlateData._elementRects = nil;
    local staticTexture, staticTextureWidth, staticTextureHeight = canvasTexture.Render(staticPlateData, BuildStaticPetTextureKey(prefix, petIndex, staticBackground, staticPlateData));
    local staticTextureId = canvasTexture.GetTextureId(staticTexture);

    if (staticTextureId == nil or staticTextureWidth == nil or staticTextureHeight == nil) then
        return;
    end

    local cropX, cropY, cropWidth, cropHeight = GetStaticPetContentCrop(staticPlateData, staticTextureWidth, staticTextureHeight);
    local referenceX, referenceY, referenceWidth, referenceHeight = GetStaticPetContentCrop(
        staticPlateData,
        staticTextureWidth,
        staticTextureHeight,
        nil,
        { background = true }
    );
    local cropCenterX = cropX + (cropWidth * 0.5);
    local cropCenterY = cropY + (cropHeight * 0.5);
    local referenceCenterX = referenceX + (referenceWidth * 0.5);
    local referenceCenterY = referenceY + (referenceHeight * 0.5);
    local positionOffsetX = (cropCenterX - referenceCenterX) * staticScale;
    local positionOffsetY = (cropCenterY - referenceCenterY) * staticScale;
    local uv1 = { cropX / staticTextureWidth, cropY / staticTextureHeight };
    local uv2 = { (cropX + cropWidth) / staticTextureWidth, (cropY + cropHeight) / staticTextureHeight };

    local staticCenterX = tonumber(GetDetachedPetSetting(targetingSettings, prefix, settingsPrefix, 'PetStaticX')) or 170;
    local staticCenterY = tonumber(GetDetachedPetSetting(targetingSettings, prefix, settingsPrefix, 'PetStaticY')) or 690;
    local editBounds = nil;

    if (prefix == 'pup' and editEnabled == true) then
        local plateDrawWidth = cropWidth * staticScale;
        local plateDrawHeight = cropHeight * staticScale;
        local left = staticCenterX + positionOffsetX - (plateDrawWidth * 0.5);
        local top = staticCenterY + positionOffsetY - (plateDrawHeight * 0.5);
        local right = left + plateDrawWidth;
        local bottom = top + plateDrawHeight;

        local function IncludeCenteredBounds(centerX, centerY, width, height)
            local halfWidth = math.max(1, tonumber(width) or 1) * 0.5;
            local halfHeight = math.max(1, tonumber(height) or 1) * 0.5;
            left = math.min(left, centerX - halfWidth);
            top = math.min(top, centerY - halfHeight);
            right = math.max(right, centerX + halfWidth);
            bottom = math.max(bottom, centerY + halfHeight);
        end

        for _, artworkSettings in ipairs({
            staticBackground.pupFrameArtworkSettings,
            staticBackground.pupHeadArtworkSettings,
        }) do
            if (type(artworkSettings) == 'table' and artworkSettings.enabled ~= false) then
                local artworkHeight = math.max(1, tonumber(artworkSettings.height) or 300);
                IncludeCenteredBounds(
                    staticCenterX + (tonumber(artworkSettings.offsetX) or 0),
                    staticCenterY + (tonumber(artworkSettings.offsetY) or 0),
                    artworkHeight * (1010 / 1385),
                    artworkHeight
                );
            end
        end

        local overloadSettings = staticBackground.pupOverloadSettings;
        if (type(overloadSettings) == 'table' and overloadSettings.enabled ~= false) then
            local gaugeSize = math.max(1, tonumber(overloadSettings.size) or 58);
            IncludeCenteredBounds(
                staticCenterX + (tonumber(overloadSettings.offsetX) or 0),
                staticCenterY + (tonumber(overloadSettings.offsetY) or 0),
                gaugeSize,
                gaugeSize
            );
        end

        local steamSettings = staticBackground.pupSteamSettings;
        if (type(steamSettings) == 'table' and steamSettings.enabled ~= false) then
            local steamSize = math.max(1, tonumber(steamSettings.size) or 160);
            IncludeCenteredBounds(
                staticCenterX + (tonumber(steamSettings.offsetX) or -240),
                staticCenterY + (tonumber(steamSettings.offsetY) or -155),
                steamSize,
                steamSize
            );
        end

        local elementSettings = staticBackground.pupElementSettings;
        if (type(elementSettings) == 'table' and elementSettings.enabled ~= false) then
            local elementSize = math.max(1, tonumber(elementSettings.size) or 24);
            IncludeCenteredBounds(
                staticCenterX + (tonumber(elementSettings.offsetX) or 0),
                staticCenterY + (tonumber(elementSettings.offsetY) or 0),
                elementSize,
                elementSize
            );
        end

        local maneuverSettings = staticBackground.pupManeuverSettings;
        if (type(maneuverSettings) == 'table' and maneuverSettings.enabled ~= false) then
            local iconSize = math.max(6, tonumber(maneuverSettings.iconSize) or 26);
            local iconSpacing = math.max(0, tonumber(maneuverSettings.iconSpacing) or 10);
            local timerHeight = 0;
            if (maneuverSettings.showTimers == true) then
                timerHeight = math.max(8, (tonumber(maneuverSettings.timerFontSize) or 7) * 1.8)
                    + math.max(0, tonumber(maneuverSettings.timerOffsetY) or 0)
                    + 2;
            end
            IncludeCenteredBounds(
                staticCenterX + (tonumber(maneuverSettings.offsetX) or 0),
                staticCenterY + (tonumber(maneuverSettings.offsetY) or 30) + (timerHeight * 0.5),
                (iconSize * 3) + (iconSpacing * 2),
                iconSize + timerHeight
            );
        end

        left = left - 3;
        top = top - 3;
        right = right + 3;
        bottom = bottom + 3;
        editBounds = {
            left = left,
            top = top,
            width = right - left,
            height = bottom - top,
        };
    end

    if (prefix == 'pup' and DrawStaticArtworkTexture ~= nil) then
        local steamSettings = staticBackground.pupSteamSettings;
        if (
            type(steamSettings) == 'table' and
            steamSettings.enabled ~= false and
            (
                pupOverloadGaugeTest.overloaded == true or
                staticPlateData.detachedPupSetupPreview == true
            )
        ) then
            local steamTextureId = backgroundTextures.GetPupArtworkTextureId('steam_overload.png');
            if (steamTextureId ~= nil) then
                local frame = math.floor(os.clock() * math.max(1, tonumber(steamSettings.speed) or 8)) % 8;
                local column = frame % 4;
                local row = math.floor(frame / 4);
                local steamSize = math.max(1, tonumber(steamSettings.size) or 160);
                DrawStaticArtworkTexture(
                    steamTextureId,
                    staticCenterX + (tonumber(steamSettings.offsetX) or -240),
                    staticCenterY + (tonumber(steamSettings.offsetY) or -155),
                    steamSize,
                    steamSize,
                    windowId .. '_pup_overload_steam',
                    tonumber(steamSettings.opacity) or 75,
                    { column * 0.25, row * 0.5 },
                    { (column + 1) * 0.25, (row + 1) * 0.5 }
                );
            end
        end

        local function DrawEquipmentLayer(layer, equipmentName, artworkSettings)
            if (
                type(artworkSettings) ~= 'table' or
                artworkSettings.enabled == false or
                tostring(equipmentName or '') == ''
            ) then
                return;
            end

            local textureId = backgroundTextures.GetPupEquipmentArtworkTextureId(
                layer,
                tostring(equipmentName) .. '.png'
            );
            if (textureId == nil) then
                return;
            end

            local drawHeight = math.max(1, tonumber(artworkSettings.height) or 300);
            local drawWidth = drawHeight * (1010 / 1385);
            DrawStaticArtworkTexture(
                textureId,
                staticCenterX + (tonumber(artworkSettings.offsetX) or 0),
                staticCenterY + (tonumber(artworkSettings.offsetY) or 0),
                drawWidth,
                drawHeight,
                windowId .. '_pup_' .. layer,
                tonumber(artworkSettings.opacity) or 100
            );
        end

        -- Preserve the shared source-canvas alignment: frame, then head, then UI plate.
        DrawEquipmentLayer(
            'frames',
            staticPlateData.detachedPupEquipmentFrame,
            staticBackground.pupFrameArtworkSettings
        );
        DrawEquipmentLayer(
            'heads',
            staticPlateData.detachedPupEquipmentHead,
            staticBackground.pupHeadArtworkSettings
        );
    end

    DrawStaticPlateTexture(
        staticTextureId,
        staticCenterX + positionOffsetX,
        staticCenterY + positionOffsetY,
        cropWidth * staticScale,
        cropHeight * staticScale,
        windowId,
        editEnabled,
        function(nextX, nextY, nextW)
            targetingSettings[settingsPrefix .. 'PetStaticX'] = nextX - positionOffsetX;
            targetingSettings[settingsPrefix .. 'PetStaticY'] = nextY - positionOffsetY;
            targetingSettings[settingsPrefix .. 'PetStaticScale'] = math.max(10, math.min(200, math.floor(((tonumber(nextW) or cropWidth) / math.max(1, cropWidth) * 100) + 0.5)));
            state.Save();
        end,
        uv1,
        uv2,
        prefix == 'pup' and function(drawList)
            DrawPupOverloadGaugeTest(
                drawList,
                staticCenterX,
                staticCenterY,
                staticBackground.pupOverloadSettings,
                staticPlateData.detachedPupSetupPreview == true
            );
        end or nil,
        editBounds
    );

    if (prefix == 'pup') then
        DrawPupHighestBurdenElement(
            staticCenterX,
            staticCenterY,
            staticBackground.pupElementSettings,
            staticPlateData.detachedPupSetupPreview == true,
            windowId
        );
    end
end

local function HasLivePetForPrefix(prefix)
    if (prefix == 'bst') then
        return entities.GetOwnBstPet() ~= nil;
    elseif (prefix == 'smn') then
        return entities.GetOwnSmnPet() ~= nil;
    elseif (prefix == 'drg') then
        return entities.GetOwnDrgPet() ~= nil;
    elseif (prefix == 'pup') then
        return entities.GetOwnPupPet() ~= nil;
    end

    return false;
end

local function IsPlayerOnSmn()
    return entities.GetPlayerMainJobId() == 15;
end

local function BuildSmnDetachedPlaceholderPlate()
    local layoutStateName = 'Avatar';
    local nameSettings = state.GetWidgetSettings('Pet (SMN)', layoutStateName, 'Name', nameDefaults);
    local backgroundSettings = state.GetWidgetSettings('Pet (SMN)', layoutStateName, 'Background', backgroundDefaults);
    local globalSettings = state.GetGlobalSettings(globalDefaults);

    return {
        hp = 0,
        mp = 0,
        tp = 0,
        cast = 0,
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
            imageOpacity = backgroundSettings.imageOpacity or backgroundDefaults.imageOpacity,
            anchorTo = backgroundSettings.anchorTo or backgroundDefaults.anchorTo,
            anchorPoint = backgroundSettings.anchorPoint or backgroundDefaults.anchorPoint,
        },
        name = '',
        nameFontFamily = fonts.GetRole(globalSettings, false),
        nameFontFlags = fonts.GetRoleFlags(globalSettings, false),
        nameFontSize = textScale.ToNameTextureFontSize(nameSettings.textSize, nameDefaults.textSize),
        nameColor = nameSettings.color or nameDefaults.color,
        nameOutlineEnabled = (tonumber(nameSettings.outlineSize) or 0) > 0,
        nameOutlineColor = nameSettings.outlineColor or nameDefaults.outlineColor,
        nameOutlineSize = tonumber(nameSettings.outlineSize) or 0,
        nameOffsetX = tonumber(nameSettings.offsetX) or nameDefaults.offsetX,
        nameOffsetY = tonumber(nameSettings.offsetY) or nameDefaults.offsetY,
        nameAnchorTo = nameSettings.anchorTo or nameDefaults.anchorTo,
        nameAnchorPoint = nameSettings.anchorPoint or nameDefaults.anchorPoint,
        hpBar = { enabled = false },
        mpBar = { enabled = false },
        tpBar = { enabled = false },
        castBar = nil,
        extraBars = {},
    };
end

local function DrawSmnDetachedPlaceholder(targetingSettings, plateData)
    if (
        IsPlayerOnSmn() ~= true or
        targetingSettings == nil or
        tostring(GetDetachedPetSetting(targetingSettings, 'smn', 'smnAvatar', 'PetPlateMode') or 'Normal') == 'Normal'
    ) then
        return;
    end

    DrawDetachedStaticPetFrame(
        'smn',
        'placeholder',
        plateData or BuildSmnDetachedPlaceholderPlate(),
        targetingSettings,
        'static_smn_pet_placeholder',
        'None',
        'smnAvatar'
    );
end

function petPlate.QueueDetachedSetupPreview(prefix, stateName, plateData)
    prefix = tostring(prefix or '');

    if (plateData == nil) then
        return false;
    end

    detachedSetupPreview = {
        prefix = prefix,
        stateName = tostring(stateName or 'pet'),
        plateData = plateData,
    };
    return true;
end

local function DrawQueuedDetachedSetupPreview()
    local request = detachedSetupPreview;
    detachedSetupPreview = nil;

    if (
        request == nil or
        HasLivePetForPrefix(request.prefix) == true or
        DrawStaticPlateTexture == nil
    ) then
        return;
    end

    local targetingSettings = targeting.GetSettings();

    if (
        targetingSettings == nil or
        GetDetachedPetSetting(
            targetingSettings,
            request.prefix,
            request.prefix == 'smn' and (request.stateName == 'Spirit' and 'smnSpirit' or 'smnAvatar') or request.prefix,
            'PetStaticEditFrame'
        ) ~= true or
        tostring(GetDetachedPetSetting(
            targetingSettings,
            request.prefix,
            request.prefix == 'smn' and (request.stateName == 'Spirit' and 'smnSpirit' or 'smnAvatar') or request.prefix,
            'PetPlateMode'
        ) or 'Normal') == 'Normal'
    ) then
        return;
    end

    local previewKey = 'setup-' .. request.prefix .. '-' .. request.stateName;
    local favorActive = false;
    local favorCooldownSeconds = 0;

    if (request.prefix == 'smn') then
        favorActive = GetAvatarFavorStatusElapsed ~= nil
            and select(1, GetAvatarFavorStatusElapsed()) == true;
        favorCooldownSeconds = GetAvatarFavorCooldownSeconds ~= nil
            and GetAvatarFavorCooldownSeconds()
            or 0;
    end

    local previewPlateData = CopySettingsWith(request.plateData, {
        detachedAvatarSetupPreview = request.prefix == 'smn',
        detachedAvatarFavorActive = favorActive,
        detachedAvatarFavorCooldownSeconds = favorCooldownSeconds,
        detachedAvatarHasPet = false,
        detachedAvatarFavorAvatarName = nil,
        detachedPupName = request.prefix == 'pup' and 'Automaton' or nil,
        detachedPupSetupPreview = request.prefix == 'pup',
        detachedPupTp = request.prefix == 'pup' and 1000 or nil,
        detachedPupManeuverState = request.prefix == 'pup' and pupManeuvers.GetPreviewState() or nil,
        detachedPupEquipmentHead = request.prefix == 'pup' and 'Harlequin Head' or nil,
        detachedPupEquipmentFrame = request.prefix == 'pup' and 'Harlequin Frame' or nil,
    });
    DrawDetachedStaticPetFrame(
        request.prefix,
        previewKey,
        previewPlateData,
        targetingSettings,
        'static_' .. request.prefix .. '_pet_setup',
        request.prefix == 'smn'
            and (request.stateName == 'Spirit' and 'LightSpirit' or 'Carbuncle')
            or nil,
        request.prefix == 'smn'
            and (request.stateName == 'Spirit' and 'smnSpirit' or 'smnAvatar')
            or request.prefix
    );
    return request.prefix;
end

local readyBarDefaults = {
    enabled = true,
    width = 160,
    height = 6,
    offsetX = 0,
    offsetY = 28,
    color = { 0.90, 0.65, 0.25, 1.0 },
    backgroundColor = { 0.255, 0.255, 0.255, 0.95 },
    borderColor = { 0.0, 0.0, 0.0, 1.0 },
    borderSize = 0,
    texture = 'Solid',
    color2 = { 0.80, 0.45, 1.0, 0.95 },
    color3 = { 0.35, 0.75, 1.0, 0.95 },
    segmented = true,
    segmentGap = 6,
    chargeSeconds = 30,
    labelDisplayMode = 'Text',
    labelIconSize = 14,
    labelIconOffsetX = 0,
    labelIconOffsetY = 0,
    showValue = false,
    showPercent = false,
    showAtPercent = 100,
    textOffsetX = 0,
    textOffsetY = 0,
    useSmallFont = true,
    fontSize = 7,
    textColor = { 1.0, 1.0, 1.0, 1.0 },
    textOutlineEnabled = true,
    textOutlineColor = { 0.0, 0.0, 0.0, 1.0 },
    textOutlineSize = 1,
};
local rewardBarDefaults = {
    enabled = true,
    width = 160,
    height = 6,
    offsetX = 0,
    offsetY = 52,
    color = { 0.70, 0.90, 0.45, 1.0 },
    backgroundColor = { 0.255, 0.255, 0.255, 0.95 },
    borderColor = { 0.0, 0.0, 0.0, 1.0 },
    borderSize = 0,
    texture = 'Solid',
    labelDisplayMode = 'Text',
    labelIconSize = 14,
    labelIconOffsetX = 0,
    labelIconOffsetY = 0,
    showValue = false,
    showPercent = false,
    showAtPercent = 100,
    textOffsetX = 0,
    textOffsetY = 0,
    useSmallFont = true,
    fontSize = 7,
    textColor = { 1.0, 1.0, 1.0, 1.0 },
    textOutlineEnabled = true,
    textOutlineColor = { 0.0, 0.0, 0.0, 1.0 },
    textOutlineSize = 1,
};
local wardBarDefaults = {
    enabled = true,
    width = 81,
    height = 12,
    offsetX = -44,
    offsetY = 16,
    color = { 0.00, 0.75, 0.85, 1.0 },
    backgroundColor = { 0.255, 0.255, 0.255, 0.95 },
    borderColor = { 0.0, 0.0, 0.0, 1.0 },
    borderSize = 0,
    texture = 'Solid',
    fillDirection = 'Left to right',
    labelDisplayMode = 'Text',
    labelIconSize = 14,
    labelIconOffsetX = 0,
    labelIconOffsetY = 0,
    showValue = false,
    showPercent = true,
    showAtPercent = 100,
    textOffsetX = 0,
    textOffsetY = 0,
    useSmallFont = true,
    fontSize = 7,
    textColor = { 1.0, 1.0, 1.0, 1.0 },
    textOutlineEnabled = true,
    textOutlineColor = { 0.0, 0.0, 0.0, 1.0 },
    textOutlineSize = 1,
};
local rageBarDefaults = {
    enabled = true,
    width = 81,
    height = 12,
    offsetX = 44,
    offsetY = 16,
    color = { 0.85, 0.20, 0.10, 1.0 },
    backgroundColor = { 0.255, 0.255, 0.255, 0.95 },
    borderColor = { 0.0, 0.0, 0.0, 1.0 },
    borderSize = 0,
    texture = 'Solid',
    fillDirection = 'Left to right',
    labelDisplayMode = 'Text',
    labelIconSize = 14,
    labelIconOffsetX = 0,
    labelIconOffsetY = 0,
    showValue = false,
    showPercent = true,
    showAtPercent = 100,
    textOffsetX = 0,
    textOffsetY = 0,
    useSmallFont = true,
    fontSize = 7,
    textColor = { 1.0, 1.0, 1.0, 1.0 },
    textOutlineEnabled = true,
    textOutlineColor = { 0.0, 0.0, 0.0, 1.0 },
    textOutlineSize = 1,
};
local favorBarDefaults = {
    enabled = true,
    width = 170,
    height = 8,
    texture = 'Solid',
    fillDirection = 'Left to right',
    labelDisplayMode = 'Text',
    labelIconSize = 14,
    labelIconOffsetX = 0,
    labelIconOffsetY = 0,
    color = { 0.55, 0.35, 0.95, 1.0 },
    backgroundColor = { 0.255, 0.255, 0.255, 0.95 },
    borderColor = { 0.0, 0.0, 0.0, 1.0 },
    borderSize = 0,
    offsetX = 0,
    offsetY = 34,
    showValue = false,
    showPercent = true,
    showAtPercent = 100,
    textOffsetX = 0,
    textOffsetY = 0,
    useSmallFont = true,
    fontSize = 7,
    textColor = { 1.0, 1.0, 1.0, 1.0 },
    textOutlineEnabled = true,
    textOutlineColor = { 0.0, 0.0, 0.0, 1.0 },
    textOutlineSize = 1,
};
local smnHpBarDefaults = CopySettingsWith(barDefaults, {
    width = 170,
    height = 14,
    offsetX = 0,
    offsetY = 0,
    color = { 0.95, 0.45, 0.45, 1.0 },
    showValue = false,
    showPercent = true,
    textColor = { 1.0, 1.0, 1.0, 1.0 },
    textOutlineEnabled = true,
    textOutlineColor = { 0.0, 0.0, 0.0, 1.0 },
});
local smnMpBarDefaults = CopySettingsWith(mpBarDefaults, {
    enabled = true,
    width = 170,
    height = 12,
    offsetX = 0,
    offsetY = 16,
    color = { 0.70, 0.90, 0.45, 1.0 },
    showPercent = true,
});
local smnTpBarDefaults = CopySettingsWith(tpBarDefaults, {
    enabled = true,
    width = 170,
    height = 12,
    offsetX = 0,
    offsetY = 30,
    color = { 0.0, 0.55, 0.95, 1.0 },
    segmented = false,
});
local smnCastBarDefaults = CopySettingsWith(castBarDefaults, {
    enabled = true,
    width = 170,
    height = 10,
    offsetX = 0,
    offsetY = 32,
    color = { 0.95, 0.75, 0.20, 1.0 },
});
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

local function ClampTextureOffset(value, axisSize, minVisible)
    local halfAxis = (tonumber(axisSize) or 0) * 0.5;
    local visible = math.max(1, tonumber(minVisible) or 24);
    local limit = math.max(0, halfAxis - visible);
    local current = tonumber(value) or 0;

    if (current < -limit) then
        return -limit;
    end

    if (current > limit) then
        return limit;
    end

    return current;
end

local function ShortenName(name, maxLength)
    local text = tostring(name or '');
    local limit = tonumber(maxLength) or 0;

    if (limit > 0 and string.len(text) > limit) then
        return string.sub(text, 1, limit);
    end

    return text;
end

BuildResourceText = function(settings, label, value, maxValue, percent)
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

BuildPercentFallbackResourceText = function(settings, label, value, maxValue, percent)
    local text = BuildResourceText(settings, label, value, maxValue, percent);

    if (text ~= '') then
        return text;
    end

    if (settings ~= nil and settings.showValue == true and percent ~= nil) then
        return tostring(math.floor(ClampPercent(percent, 100) + 0.5)) .. '%';
    end

    return text;
end

local function GetBstStateName(pet)
    if (pet ~= nil and petDurations.GetBstJugDurationMinutes(pet.name) ~= nil) then
        return 'Jug Pet';
    end

    return 'Charmed Pet';
end

local function FormatTimerSeconds(seconds)
    seconds = math.ceil(tonumber(seconds) or 0);

    if (seconds < 0) then
        seconds = 0;
    end

    if (seconds >= 60) then
        return tostring(math.ceil(seconds / 60)) .. 'm';
    end

    return tostring(seconds) .. 's';
end

local function GetBstPetDurationText(pet, layoutStateName)
    if (pet == nil or pet.name == nil or pet.index == nil) then
        return nil;
    end

    local isCharmedPet = tostring(layoutStateName or '') == 'Charmed Pet';

    if (isCharmedPet == true) then
        local charmRemaining = bstCharmTimer.GetRemainingSeconds();

        if (charmRemaining ~= nil and charmRemaining > 0) then
            return 'Charmed ' .. FormatTimerSeconds(charmRemaining);
        end

        return 'Charmed ?';
    end

    local durationMinutes = petDurations.GetBstJugDurationMinutes(pet.name);

    if (durationMinutes == nil or pet.serverId == nil) then
        return nil;
    end

    local now = os.time();

    if (
        bstPetTimer.index ~= pet.index or
        bstPetTimer.serverId ~= pet.serverId or
        bstPetTimer.name ~= pet.name or
        bstPetTimer.expireTime == nil or
        bstPetTimer.expireTime <= now
    ) then
        bstPetTimer.index = pet.index;
        bstPetTimer.serverId = pet.serverId;
        bstPetTimer.name = pet.name;
        bstPetTimer.expireTime = now + (durationMinutes * 60);
    end

    local remaining = bstPetTimer.expireTime - now;

    if (remaining <= 0) then
        return nil;
    end

    return (isCharmedPet and 'Charmed ' or 'Jug ') .. FormatTimerSeconds(remaining);
end

local function GetAbilityTimerModifier(timerId)
    local data = abilityRecast.GetAbilityTimerDataByTimerId(timerId);

    if (type(data) ~= 'table') then
        return 0;
    end

    return tonumber(data.Modifier or data.modifier) or 0;
end

local function GetBstReadyBarData(settings)
    local timerData = abilityRecast.GetAbilityTimerDataByTimerId(102) or {};
    local ticks = tonumber(timerData.Recast or timerData.recast) or tonumber(abilityRecast.GetAbilityTimerByTimerId(102)) or 0;
    local modifier = tonumber(timerData.Modifier or timerData.modifier) or 0;
    local chargeSeconds = math.max(1, tonumber(settings ~= nil and settings.chargeSeconds) or readyBarDefaults.chargeSeconds or 30);
    local totalBaseSeconds = math.max(1, (chargeSeconds * 3) + modifier);
    local baseTicks = math.max(1, totalBaseSeconds * 60);
    local chargeTicks = baseTicks / 3;

    if (ticks <= 0) then
        return 100, '3/3', 3, nil;
    end

    local chargesRecharging = math.ceil(ticks / chargeTicks);
    local fullCharges = math.max(0, math.min(3, 3 - chargesRecharging));
    local nextTicks = ((ticks - 1) % chargeTicks) + 1;
    local progress = fullCharges / 3;

    return progress * 100, FormatTimerSeconds(nextTicks / 60) .. ' ' .. tostring(fullCharges) .. '/3', fullCharges, FormatTimerSeconds(nextTicks / 60);
end

local function GetBstSicBarData(settings)
    local timerData = abilityRecast.GetAbilityTimerDataByTimerId(102) or {};
    local ticks = tonumber(timerData.Recast or timerData.recast) or tonumber(abilityRecast.GetAbilityTimerByTimerId(102)) or 0;
    local modifier = tonumber(timerData.Modifier or timerData.modifier) or 0;
    local chargeSeconds = math.max(1, tonumber(settings ~= nil and settings.chargeSeconds) or readyBarDefaults.chargeSeconds or 30);
    local maxTicks = math.max(1, (chargeSeconds + modifier) * 60);

    if (maxTicks < ticks) then
        maxTicks = ticks;
    end

    if (ticks <= 0) then
        return 100, nil;
    end

    return math.max(0, math.min(100, ((maxTicks - ticks) / maxTicks) * 100)), FormatTimerSeconds(ticks / 60);
end

local function BuildReadyCounterText(settings, charges)
    if (settings.showPercent ~= true) then
        return '';
    end

    return tostring(tonumber(charges) or 0) .. '/3';
end

local function BuildReadyLabelText(settings, label)
    if (tostring(settings.labelDisplayMode or 'Text') ~= 'Text') then
        return '';
    end

    return tostring(label or 'Ready');
end

local function GetBstRewardBarData()
    local ticks = tonumber(abilityRecast.GetAbilityTimerByTimerId(103)) or 0;

    if (ticks <= 0 and abilityRecast.GetAbilityTimerByAbilityId ~= nil) then
        ticks = tonumber(abilityRecast.GetAbilityTimerByAbilityId(78)) or 0;
    end

    local maxTicks = math.max(1, (90 + GetAbilityTimerModifier(103)) * 60);

    if (maxTicks < ticks) then
        maxTicks = ticks;
    end

    if (ticks <= 0) then
        return 100, 'Reward';
    end

    return math.max(0, math.min(100, ((maxTicks - ticks) / maxTicks) * 100)), FormatTimerSeconds(ticks / 60);
end

local bpRecastMaxTicks = {};
local avatarFavorFallbackStartedAt = nil;
local AVATAR_FAVOR_STATUS_ID = 431;
local AVATAR_FAVOR_DURATION_SECONDS = 7200;
local AVATAR_FAVOR_MAX_CHARGE_SECONDS = 75;
local avatarFavorState = {
    active = false,
    statusElapsedSeconds = nil,
    chargeSeconds = nil,
    lastChargeSampleAt = nil,
    avatarServerId = nil,
    avatarName = nil,
    lastBloodPactCommand = nil,
    lastBloodPactAt = 0,
};

local function GetBloodPactBarData(timerId)
    local ticks = tonumber(abilityRecast.GetAbilityTimerByTimerId(timerId)) or 0;
    local key = tostring(timerId);
    local maxTicks = 3600;

    if (ticks <= 0) then
        bpRecastMaxTicks[key] = nil;
        return 100, 'Ready';
    end

    if (bpRecastMaxTicks[key] == nil or ticks > bpRecastMaxTicks[key]) then
        bpRecastMaxTicks[key] = ticks;
    end

    maxTicks = math.max(1, bpRecastMaxTicks[key] or maxTicks);
    return math.max(0, math.min(100, ((maxTicks - ticks) / maxTicks) * 100)), FormatTimerSeconds(ticks / 60);
end

GetAvatarFavorCooldownSeconds = function()
    local ticks = tonumber(abilityRecast.GetAbilityTimerByTimerId(AVATAR_FAVOR_RECAST_TIMER_ID)) or 0;

    if (ticks <= 0 and abilityRecast.GetAbilityTimerByAbilityId ~= nil) then
        ticks = tonumber(abilityRecast.GetAbilityTimerByAbilityId(AVATAR_FAVOR_ABILITY_ID)) or 0;
    end

    if (ticks <= 0) then
        return 0;
    end

    return ticks / 60;
end

local function HideReadyTimerText(text)
    local value = tostring(text or '');

    if (value:gsub('^%s+', ''):gsub('%s+$', ''):lower() == 'ready') then
        return '';
    end

    return value;
end

local function BuildCastBar(castData, castBarSettings, globalSettings)
    if (castData == nil or castBarSettings == nil or castBarSettings.enabled ~= true) then
        return nil, 0;
    end

    local castTime = math.max(0.1, tonumber(castData.castTime) or 0.1);
    local elapsed = math.max(0.0, os.clock() - (tonumber(castData.startTime) or os.clock()));
    local castPercent = math.max(0, math.min(100, (elapsed / castTime) * 100));
    local spellIconId = tonumber(castData.spellIconId);
    local spellIconTextureId = nil;

    if (castBarSettings.showSpellIcon == true) then
        -- Spirit casts need the spell artwork first.  The resource Status field
        -- can point at a shared effect icon (for example Protect), which made
        -- unrelated live casts all display that same status icon.
        spellIconTextureId = spellIconTextures.GetTextureId(castData.spellId)
            or spellIconTextures.GetTextureId(spellIconId)
            or spellIconTextures.GetGeoTextureId(castData.spellId)
            or statusIconTextures.GetTextureId(castData.spellStatusId);
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
        anchorOrder = castBarSettings.anchorOrder,
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

local function AddStatusIconsToPlate(plateData, statusRows, iconSettings, globalSettings, kind)
    if (iconSettings == nil or iconSettings.enabled ~= true or statusRows == nil or #statusRows == 0) then
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
            };
        end
    end
end

local function AddDistanceToPlate(plateData, pet, distanceSettings, globalSettings)
    if (distanceSettings == nil or distanceSettings.enabled ~= true or pet == nil or pet.distance == nil) then
        return;
    end

    local distance = tonumber(pet.distance);

    if (distance == nil) then
        return;
    end

    plateData.badges = plateData.badges or {};
    plateData.badges[#plateData.badges + 1] = {
        kind = 'distance',
        text = tostring(distanceSettings.prefix or '') .. string.format('%.1f', distance):gsub(',', '.'),
        offsetX = tonumber(distanceSettings.offsetX) or 66,
        offsetY = tonumber(distanceSettings.offsetY) or -52,
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

local function AddTextBadge(plateData, text, settings, defaults, globalSettings, kind)
    if (settings == nil or settings.enabled ~= true or text == nil or tostring(text) == '') then
        return;
    end

    plateData.badges = plateData.badges or {};
    plateData.badges[#plateData.badges + 1] = {
        kind = kind or 'text',
        text = tostring(text),
        offsetX = tonumber(settings.offsetX) or defaults.offsetX,
        offsetY = tonumber(settings.offsetY) or defaults.offsetY,
        fontFamily = fonts.GetRole(globalSettings, true),
        fontFlags = fonts.GetRoleFlags(globalSettings, true),
        fontSize = textScale.ToTextureFontSize(settings.textSize, defaults.textSize),
        textColor = settings.color or defaults.color,
        textOutlineEnabled = settings.outlineEnabled == true,
        textOutlineColor = settings.outlineColor or defaults.outlineColor,
        textOutlineSize = tonumber(settings.outlineSize) or defaults.outlineSize,
        backgroundEnabled = false,
    };
end

local function AddPetTimerBadge(plateData, text, settings, globalSettings, labelName, iconName)
    if (settings == nil or settings.enabled ~= true or text == nil or tostring(text) == '') then
        return;
    end

    local badgeText = tostring(text);
    local labelText = '';
    local iconTextureId = nil;
    local displayMode = tostring(settings.displayMode or 'Text');
    local timerLabel = tostring(labelName or 'Jug');

    badgeText = badgeText:gsub('^Jug%s+', '');
    badgeText = badgeText:gsub('^Charmed%s+', '');

    if (displayMode == 'Text') then
        labelText = timerLabel;
    elseif (displayMode == 'Icon') then
        iconTextureId = GetPetTimerIconTextureId(iconName or timerLabel);
    end

    plateData.badges = plateData.badges or {};
    plateData.badges[#plateData.badges + 1] = {
        kind = 'petTimer',
        text = badgeText,
        labelText = labelText,
        offsetX = tonumber(settings.offsetX) or petTimerDefaults.offsetX,
        offsetY = tonumber(settings.offsetY) or petTimerDefaults.offsetY,
        fontFamily = fonts.GetRole(globalSettings, true),
        fontFlags = fonts.GetRoleFlags(globalSettings, true),
        fontSize = textScale.ToTextureFontSize(settings.textSize, petTimerDefaults.textSize),
        textColor = settings.color or petTimerDefaults.color,
        textOutlineEnabled = settings.outlineEnabled == true,
        textOutlineColor = settings.outlineColor or petTimerDefaults.outlineColor,
        textOutlineSize = tonumber(settings.outlineSize) or petTimerDefaults.outlineSize,
        backgroundEnabled = false,
        iconTextureId = iconTextureId,
        iconSize = tonumber(settings.iconSize) or petTimerDefaults.iconSize,
        labelOffsetX = tonumber(settings.labelOffsetX) or 0,
        labelOffsetY = tonumber(settings.labelOffsetY) or 0,
        textOffsetX = tonumber(settings.textOffsetX) or 0,
        textOffsetY = tonumber(settings.textOffsetY) or 0,
        separateLabelOffsets = true,
    };
end

local function AddPetStateBadge(plateData, commandName, settings, globalSettings)
    if (settings == nil or settings.enabled ~= true or commandName == nil or tostring(commandName) == '') then
        return;
    end

    local displayMode = tostring(settings.displayMode or 'Text');
    local badgeText = '';
    local labelText = '';
    local iconTextureId = nil;

    if (displayMode == 'Text') then
        labelText = tostring(commandName);
    elseif (displayMode == 'Icon') then
        iconTextureId = GetPetStateIconTextureId(commandName);
    end

    plateData.badges = plateData.badges or {};
    plateData.badges[#plateData.badges + 1] = {
        kind = 'petState',
        text = badgeText,
        labelText = labelText,
        offsetX = tonumber(settings.offsetX) or petStateDefaults.offsetX,
        offsetY = tonumber(settings.offsetY) or petStateDefaults.offsetY,
        fontFamily = fonts.GetRole(globalSettings, settings.useSmallFont == true),
        fontFlags = fonts.GetRoleFlags(globalSettings, settings.useSmallFont == true),
        fontSize = textScale.ToTextureFontSize(settings.textSize, petStateDefaults.textSize),
        textColor = settings.color or petStateDefaults.color,
        textOutlineEnabled = settings.outlineEnabled == true,
        textOutlineColor = settings.outlineColor or petStateDefaults.outlineColor,
        textOutlineSize = tonumber(settings.outlineSize) or petStateDefaults.outlineSize,
        backgroundEnabled = false,
        iconTextureId = iconTextureId,
        iconSize = tonumber(settings.iconSize) or petStateDefaults.iconSize,
        labelOffsetX = tonumber(settings.labelOffsetX) or 0,
        labelOffsetY = tonumber(settings.labelOffsetY) or 0,
        separateLabelOffsets = true,
    };
end

local function BuildExtraBar(settings, defaults, progress, text, kind, iconName, globalSettings, labelText)
    if (settings == nil or settings.enabled ~= true) then
        return nil;
    end

    local displayMode = tostring(settings.labelDisplayMode or 'Text');
    local barText = tostring(text or '');
    local iconTextureId = nil;

    if (iconName ~= nil and displayMode == 'Icon') then
        iconTextureId = GetPetStateIconTextureId(iconName);
    end

    local segmented = settings.segmented == true;
    local barProgress = tonumber(progress) or 0;

    if (segmented == true) then
        barProgress = barProgress * 3;
    end

    return {
        kind = kind,
        enabled = true,
        progress = barProgress,
        width = tonumber(settings.width) or defaults.width,
        height = tonumber(settings.height) or defaults.height,
        offsetX = tonumber(settings.offsetX) or defaults.offsetX,
        offsetY = tonumber(settings.offsetY) or defaults.offsetY,
        anchorTo = settings.anchorTo or defaults.anchorTo,
        anchorPoint = settings.anchorPoint or defaults.anchorPoint,
        anchorCollapse = settings.anchorCollapse,
        anchorSpacing = settings.anchorSpacing,
        anchorOrder = settings.anchorOrder,
        color = settings.color or defaults.color,
        backgroundColor = settings.backgroundColor or defaults.backgroundColor,
        borderColor = settings.borderColor or defaults.borderColor,
        borderSize = tonumber(settings.borderSize) or defaults.borderSize,
        cornerRadius = tonumber(settings.cornerRadius) or defaults.cornerRadius or 0,
        textureStrength = tonumber(settings.textureStrength) or 100,
        textureId = barTextures.GetTextureId(settings.texture),
        fillDirection = settings.fillDirection or defaults.fillDirection or 'Left to right',
        showAtPercent = segmented and 300 or (tonumber(settings.showAtPercent) or 100),
        segmented = segmented,
        segmentGap = tonumber(settings.segmentGap) or defaults.segmentGap,
        color2 = settings.color2 or defaults.color2,
        color3 = settings.color3 or defaults.color3,
        text = barText,
        labelText = tostring(labelText or ''),
        textOffsetX = tonumber(settings.textOffsetX) or 0,
        textOffsetY = tonumber(settings.textOffsetY) or 0,
        fontFamily = fonts.GetRole(globalSettings or globalDefaults, settings.useSmallFont == true),
        fontFlags = fonts.GetRoleFlags(globalSettings or globalDefaults, settings.useSmallFont == true),
        fontSize = textScale.ToTextureFontSize(settings.fontSize, defaults.fontSize),
        textColor = settings.textColor or defaults.textColor,
        textOutlineEnabled = settings.textOutlineEnabled == true,
        textOutlineColor = settings.textOutlineColor or defaults.textOutlineColor,
        textOutlineSize = tonumber(settings.textOutlineSize) or defaults.textOutlineSize,
        iconTextureId = iconTextureId,
        iconSize = tonumber(settings.labelIconSize) or defaults.labelIconSize,
        iconOffsetX = tonumber(settings.labelIconOffsetX) or 0,
        iconOffsetY = tonumber(settings.labelIconOffsetY) or 0,
        separateLabelOffsets = iconTextureId ~= nil or tostring(labelText or '') ~= '',
    };
end

local function BuildNameOnlyPlateData(source, nameText)
    return {
        hp = source.hp,
        name = tostring(nameText or source.name or ''),
        nameFontFamily = source.nameFontFamily,
        nameFontFlags = source.nameFontFlags,
        nameFontSize = source.nameFontSize,
        nameColor = source.nameColor,
        nameOutlineEnabled = source.nameOutlineEnabled,
        nameOutlineColor = source.nameOutlineColor,
        nameOutlineSize = source.nameOutlineSize,
        nameOffsetX = source.nameOffsetX,
        nameOffsetY = source.nameOffsetY,
        nameAnchorTo = source.nameAnchorTo,
        nameAnchorPoint = source.nameAnchorPoint,
    };
end

local function ReadImguiVec2(first, second)
    if (type(first) == 'table') then
        return tonumber(first.x or first[1]) or 0, tonumber(first.y or first[2]) or 0;
    end

    return tonumber(first) or 0, tonumber(second) or 0;
end

local function ResetAvatarFavorState()
    avatarFavorFallbackStartedAt = nil;
    avatarFavorState.active = false;
    avatarFavorState.statusElapsedSeconds = nil;
    avatarFavorState.chargeSeconds = nil;
    avatarFavorState.lastChargeSampleAt = nil;
    avatarFavorState.avatarServerId = nil;
    avatarFavorState.avatarName = nil;
    avatarFavorState.lastBloodPactCommand = nil;
    avatarFavorState.lastBloodPactAt = 0;
end

local function FormatFavorCharge(seconds)
    seconds = math.max(0, math.min(AVATAR_FAVOR_MAX_CHARGE_SECONDS, math.floor(tonumber(seconds) or 0)));
    return string.format('%d:%02d / 1:15', math.floor(seconds / 60), seconds % 60);
end

GetAvatarFavorStatusElapsed = function()
    local active = false;
    local remainingSeconds = nil;

    for _, row in ipairs(playerStatuses.GetSelfRows('all') or {}) do
        if ((tonumber(row.id) or 0) == AVATAR_FAVOR_STATUS_ID) then
            active = true;
            remainingSeconds = tonumber(row.seconds);
            break;
        end
    end

    if (active ~= true) then
        return false, nil;
    end

    local elapsedSeconds = 0;

    -- The status timer is normally available immediately.  This fallback only
    -- covers the brief period before Ashita exposes it, while keeping the bar
    -- stable if the player reloads the addon with Favor already active.
    if (remainingSeconds == nil or remainingSeconds <= 0) then
        if (avatarFavorFallbackStartedAt == nil) then
            avatarFavorFallbackStartedAt = os.clock();
        end
        elapsedSeconds = math.max(0, os.clock() - avatarFavorFallbackStartedAt);
    else
        elapsedSeconds = AVATAR_FAVOR_DURATION_SECONDS - math.min(AVATAR_FAVOR_DURATION_SECONDS, math.max(0, remainingSeconds));
        avatarFavorFallbackStartedAt = os.clock() - elapsedSeconds;
    end

    return true, elapsedSeconds;
end

-- The stance itself stays active without an Avatar, but its strength only
-- grows while one is actually summoned.  Track that separately from the
-- two-hour status timer so dismissing an Avatar pauses the meter instead of
-- silently adding no-Avatar time to it.
local function UpdateAvatarFavorCharge(pet)
    local active, elapsedSeconds = GetAvatarFavorStatusElapsed();
    if (active ~= true) then
        ResetAvatarFavorState();
        return false;
    end

    local now = os.clock();
    local statusRestarted = (
        avatarFavorState.active == true and
        avatarFavorState.statusElapsedSeconds ~= nil and
        elapsedSeconds + 2 < avatarFavorState.statusElapsedSeconds
    );

    if (avatarFavorState.active ~= true or statusRestarted == true or avatarFavorState.chargeSeconds == nil) then
        -- The exact Avatar uptime before an addon reload is not exposed by the
        -- game.  Begin a truthful local meter here rather than treating the
        -- stance's age as Avatar uptime.
        avatarFavorState.chargeSeconds = 0;
        avatarFavorState.lastChargeSampleAt = now;
    end

    local elapsedSinceSample = math.max(0, now - (tonumber(avatarFavorState.lastChargeSampleAt) or now));
    local isAvatarOut = pet ~= nil and pet.petType == 'avatar';
    if (isAvatarOut == true) then
        avatarFavorState.chargeSeconds = math.min(
            AVATAR_FAVOR_MAX_CHARGE_SECONDS,
            math.max(0, tonumber(avatarFavorState.chargeSeconds) or 0) + elapsedSinceSample
        );
    end

    avatarFavorState.active = true;
    avatarFavorState.statusElapsedSeconds = elapsedSeconds;
    avatarFavorState.lastChargeSampleAt = now;
    return true;
end

local function GetAvatarFavorBarData(pet)
    -- QueueSmnPet can also be called by preview/rebuild paths outside the
    -- normal world render pass.  Refresh here as well so those paths never
    -- lose the Favor bar merely because the shared state was not sampled yet.
    if (UpdateAvatarFavorCharge(pet) ~= true) then
        return nil, nil;
    end

    -- Favor is kept while Avatars are exchanged.  Preserve its accumulated
    -- charge; only a completed Blood Pact or a new Favor stance starts over.
    if (pet ~= nil and pet.petType == 'avatar') then
        local petServerId = tonumber(pet.serverId);
        local petName = tostring(pet.name or '');
        if (petServerId ~= nil and petServerId > 0) then
            avatarFavorState.avatarServerId = petServerId;
            avatarFavorState.avatarName = petName;
        end
    end

    local clampedChargeSeconds = math.min(
        AVATAR_FAVOR_MAX_CHARGE_SECONDS,
        math.max(0, tonumber(avatarFavorState.chargeSeconds) or 0)
    );
    return (clampedChargeSeconds / AVATAR_FAVOR_MAX_CHARGE_SECONDS) * 100, FormatFavorCharge(clampedChargeSeconds);
end

local function BuildDetachedSmnMeterSources(pet)
    local wardProgress, wardText = GetBloodPactBarData(174);
    local rageProgress, rageText = GetBloodPactBarData(173);
    return {
        {
            kind = 'ward',
            progress = wardProgress,
            text = tostring(wardText or ''),
        },
        {
            kind = 'rage',
            progress = rageProgress,
            text = tostring(rageText or ''),
        },
    };
end

local function ResetAvatarFavorCharge()
    if (avatarFavorState.active ~= true) then
        return;
    end

    avatarFavorState.chargeSeconds = 0;
    avatarFavorState.lastChargeSampleAt = os.clock();
end

local function IsBloodPactCommand(commandText)
    local command = tostring(commandText or '')
        :lower()
        :gsub('^%s*/?', '')
        :gsub('%s+', ' ')
        :gsub('%s+$', '');
    local prefix, action = command:match('^(%S+)%s+"?([^"<]+)');

    if (prefix ~= 'pet' or action == nil) then
        return false, nil;
    end

    action = tostring(action):gsub('^%s*(.-)%s*$', '%1');
    local nonBloodPactCommands = {
        fight = true,
        heel = true,
        stay = true,
        leave = true,
        assault = true,
        retreat = true,
        release = true,
        deploy = true,
        deactivate = true,
        activate = true,
    };

    if (action == '' or nonBloodPactCommands[action] == true) then
        return false, nil;
    end

    return true, action;
end

function petPlate.HandleCommandText(commandText)
    if (avatarFavorState.active ~= true) then
        return;
    end

    local isBloodPact, action = IsBloodPactCommand(commandText);
    if (isBloodPact ~= true) then
        return;
    end

    local now = os.clock();
    if (
        avatarFavorState.lastBloodPactCommand == action and
        (now - (tonumber(avatarFavorState.lastBloodPactAt) or 0)) < 0.75
    ) then
        return;
    end

    avatarFavorState.lastBloodPactCommand = action;
    avatarFavorState.lastBloodPactAt = now;
    -- Do not reset here: a typed /pet command can be interrupted or rejected.
    -- The matching "Avatar uses ..." chat message below confirms completion.
end

local function CleanFavorActionMessage(value)
    return tostring(value or '')
        :gsub(string.char(0x1E) .. '.', '')
        :gsub('[%z\1-\31]', '')
        :gsub('[\127-\255]', '')
        :gsub('^%s*(.-)%s*$', '%1');
end

function petPlate.HandleTextIn(e)
    if (entities.GetPlayerMainJobId() == 18) then
        local overloadMessage = CleanFavorActionMessage(
            e ~= nil and (e.message or e.text or e.original or e.message_modified or e.modified) or ''
        );
        local actor, element, chance = overloadMessage:match(
            "([%a][%w_]*)'s%s+([%a]+)%s+[Mm]aneuver%s+overload%s+chance%s+is%s+(%d+)%%"
        );
        local overloadedActor = overloadMessage:match("([%a][%w_]*)%s+is%s+overloaded!");
        local endedActor = overloadMessage:match(
            "([%a][%w_]*)'s%s+[Oo]verload%s+effect%s+wears%s+off%."
        );
        local messageActor = actor or overloadedActor or endedActor;
        local self = messageActor ~= nil and entities.GetSelf() or nil;
        local compactActor = tostring(messageActor or ''):lower():gsub('%s+', '');
        local compactSelf = tostring(self ~= nil and self.name or ''):lower():gsub('%s+', '');

        if (compactActor ~= '' and compactActor == compactSelf) then
            if (actor ~= nil) then
                local burdenElement = NormalizePupBurdenElement(element);
                if (burdenElement ~= nil) then
                    pupOverloadGaugeTest.burdens[burdenElement] = {
                        chance = math.max(0, math.min(100, tonumber(chance) or 0)),
                        updatedAt = os.clock(),
                    };
                    pupOverloadGaugeTest.element, pupOverloadGaugeTest.chance = GetHighestPupBurden();
                end
                pupOverloadGaugeTest.overloadEnded = false;
            elseif (overloadedActor ~= nil) then
                pupOverloadGaugeTest.overloaded = true;
                pupOverloadGaugeTest.overloadEnded = false;
            elseif (endedActor ~= nil) then
                pupOverloadGaugeTest.overloaded = false;
                pupOverloadGaugeTest.overloadEnded = true;
                pupOverloadGaugeTest.overloadSeconds = nil;
                pupOverloadGaugeTest.statusSeenActive = false;
            end
        end
    end

    if (avatarFavorState.active ~= true) then
        return;
    end

    local pet = entities.GetOwnSmnPet();
    if (pet == nil or pet.petType ~= 'avatar') then
        return;
    end

    local message = CleanFavorActionMessage(
        e ~= nil and (e.message or e.text or e.original or e.message_modified or e.modified) or ''
    );
    local actor = message:match('^[Tt]he%s+(.+)%s+uses%s+') or message:match('^(.+)%s+uses%s+');

    if (actor == nil) then
        return;
    end

    local compactActor = tostring(actor):lower():gsub('%s+', '');
    local compactPet = tostring(pet.name or ''):lower():gsub('%s+', '');
    if (compactActor ~= '' and compactActor == compactPet) then
        ResetAvatarFavorCharge();
    end
end

local function AddSmnAvatarExtraBars(plateData, wardSettings, rageSettings, globalSettings)
    plateData.extraBars = plateData.extraBars or {};

    if (wardSettings.enabled == true) then
        local wardProgress, wardText = GetBloodPactBarData(174);
        local wardTimerText = HideReadyTimerText(wardText);
        local wardBar = BuildExtraBar(wardSettings, wardBarDefaults, wardProgress, (wardSettings.showPercent ~= false) and wardTimerText or '', 'ward', 'ward', globalSettings, (tostring(wardSettings.labelDisplayMode or 'Text') == 'Text') and 'Ward' or '');

        if (wardBar ~= nil) then
            plateData.extraBars[#plateData.extraBars + 1] = wardBar;
        end
    end

    if (rageSettings.enabled == true) then
        local rageProgress, rageText = GetBloodPactBarData(173);
        local rageTimerText = HideReadyTimerText(rageText);
        local rageBar = BuildExtraBar(rageSettings, rageBarDefaults, rageProgress, (rageSettings.showPercent ~= false) and rageTimerText or '', 'rage', 'rage', globalSettings, (tostring(rageSettings.labelDisplayMode or 'Text') == 'Text') and 'Rage' or '');

        if (rageBar ~= nil) then
            plateData.extraBars[#plateData.extraBars + 1] = rageBar;
        end
    end

end

local function GetMousePosition()
    if (imgui.GetIO == nil) then
        return nil, nil;
    end

    local ok, io = pcall(function()
        return imgui.GetIO();
    end);

    if (ok ~= true or io == nil or io.MousePos == nil) then
        return nil, nil;
    end

    return
        tonumber(io.MousePos.x or io.MousePos.X or io.MousePos[1]),
        tonumber(io.MousePos.y or io.MousePos.Y or io.MousePos[2]);
end

local function GetMouseDragDelta()
    if (imgui.GetMouseDragDelta == nil) then
        return 0, 0;
    end

    return ReadImguiVec2(imgui.GetMouseDragDelta(0));
end

local function DrawStaticPanelEditOverlay(windowId, left, top, width, height, onEdited, editCenterX, editCenterY, editWidth)
    if (
        imgui.GetForegroundDrawList == nil or
        imgui.GetColorU32 == nil or
        imgui.IsMouseClicked == nil or
        imgui.IsMouseDown == nil
    ) then
        return;
    end

    local id = tostring(windowId or 'static_pet');
    local x = tonumber(left) or 0;
    local y = tonumber(top) or 0;
    local w = math.max(1, tonumber(width) or 1);
    local h = math.max(1, tonumber(height) or 1);
    local mouseX, mouseY = GetMousePosition();

    if (mouseX ~= nil and mouseY ~= nil and imgui.IsMouseClicked(0) == true) then
        staticPanelEditDrag = nil;

        local inRect = mouseX >= x and mouseX <= x + w and mouseY >= y and mouseY <= y + h;
        if (inRect == true) then
            staticPanelEditDrag = {
                id = id,
            };

            if (imgui.ResetMouseDragDelta ~= nil) then
                imgui.ResetMouseDragDelta(0);
            end
        end
    end

    if (imgui.IsMouseDown(0) ~= true) then
        staticPanelEditDrag = nil;
    elseif (staticPanelEditDrag ~= nil and staticPanelEditDrag.id == id and type(onEdited) == 'function') then
        local dx, dy = GetMouseDragDelta();

        if (math.abs(dx) >= 0.5 or math.abs(dy) >= 0.5) then
            onEdited(
                math.floor((tonumber(editCenterX) or (x + (w * 0.5))) + dx + 0.5),
                math.floor((tonumber(editCenterY) or (y + (h * 0.5))) + dy + 0.5),
                tonumber(editWidth) or w
            );

            if (imgui.ResetMouseDragDelta ~= nil) then
                imgui.ResetMouseDragDelta(0);
            end
        end
    end

    local drawList = imgui.GetForegroundDrawList();
    if (drawList == nil) then
        return;
    end

    local fillColor = imgui.GetColorU32({ 1.0, 0.80, 0.10, 0.06 });
    local borderColor = imgui.GetColorU32({ 1.0, 0.80, 0.10, 1.0 });
    local borderShadowColor = imgui.GetColorU32({ 0.0, 0.0, 0.0, 0.92 });
    local labelBackgroundColor = imgui.GetColorU32({ 0.0, 0.0, 0.0, 0.78 });
    local textColor = imgui.GetColorU32({ 1.0, 1.0, 1.0, 1.0 });

    if (staticPanelEditDrag ~= nil and staticPanelEditDrag.id == id) then
        drawList:AddRectFilled({ x, y }, { x + w, y + h }, fillColor);
    end

    drawList:AddRect({ x, y }, { x + w, y + h }, borderShadowColor, 0, 0, 6);
    drawList:AddRect({ x, y }, { x + w, y + h }, borderColor, 0, 0, 3);

    if (drawList.AddText ~= nil) then
        drawList:AddRectFilled({ x + 4, y - 24 }, { x + 112, y - 2 }, labelBackgroundColor, 3);
        drawList:AddText({ x + 9, y - 21 }, textColor, 'Detached pet');
    end
end

DrawStaticPlateTexture = function(textureId, centerX, centerY, width, height, windowId, editEnabled, onEdited, uv1, uv2, overlayDraw, editBounds)
    if (imgui == nil or textureId == nil) then
        return false;
    end

    if (imgui.Begin == nil or imgui.Image == nil) then
        return false;
    end

    local drawW = math.max(1, tonumber(width) or 1);
    local drawH = math.max(1, tonumber(height) or 1);
    local left = (tonumber(centerX) or 0) - (drawW * 0.5);
    local top = (tonumber(centerY) or 0) - (drawH * 0.5);
    local flags =
        (_G.ImGuiWindowFlags_NoTitleBar or 0) +
        (_G.ImGuiWindowFlags_NoScrollbar or 0) +
        (_G.ImGuiWindowFlags_NoScrollWithMouse or 0) +
        (_G.ImGuiWindowFlags_NoSavedSettings or 0) +
        (_G.ImGuiWindowFlags_NoBackground or 0);

    flags = flags +
        (_G.ImGuiWindowFlags_NoResize or 0) +
        (_G.ImGuiWindowFlags_NoMove or 0) +
        (_G.ImGuiWindowFlags_NoInputs or 0);

    if (imgui.SetNextWindowPos ~= nil) then
        imgui.SetNextWindowPos({ left, top }, _G.ImGuiCond_Always or 1);
    end

    if (imgui.SetNextWindowSize ~= nil) then
        imgui.SetNextWindowSize({ drawW, drawH }, _G.ImGuiCond_Always or 1);
    end

    local pushedPadding = false;
    if (imgui.PushStyleVar ~= nil and _G.ImGuiStyleVar_WindowPadding ~= nil) then
        imgui.PushStyleVar(_G.ImGuiStyleVar_WindowPadding, { 0, 0 });
        pushedPadding = true;
    end

    local visible = imgui.Begin('LibraPlates Pet Static Panel##' .. tostring(windowId or 'static_pet'), true, flags);

    if (visible == true) then
        if (imgui.SetCursorPos ~= nil) then
            imgui.SetCursorPos({ 0, 0 });
        end

        imgui.Image(textureId, { drawW, drawH }, uv1 or { 0, 0 }, uv2 or { 1, 1 });

        if (type(overlayDraw) == 'function' and imgui.GetWindowDrawList ~= nil) then
            overlayDraw(imgui.GetWindowDrawList(), left, top, drawW, drawH);
        end

    end

    imgui.End();

    if (pushedPadding == true and imgui.PopStyleVar ~= nil) then
        imgui.PopStyleVar();
    end

    if (editEnabled == true) then
        local overlayLeft = type(editBounds) == 'table' and tonumber(editBounds.left) or left;
        local overlayTop = type(editBounds) == 'table' and tonumber(editBounds.top) or top;
        local overlayWidth = type(editBounds) == 'table' and tonumber(editBounds.width) or drawW;
        local overlayHeight = type(editBounds) == 'table' and tonumber(editBounds.height) or drawH;
        DrawStaticPanelEditOverlay(
            windowId,
            overlayLeft,
            overlayTop,
            overlayWidth,
            overlayHeight,
            onEdited,
            centerX,
            centerY,
            drawW
        );
    end

    return true;
end

DrawStaticArtworkTexture = function(textureId, centerX, centerY, width, height, windowId, opacity, uv1, uv2)
    if (
        imgui == nil or
        textureId == nil or
        imgui.Begin == nil or
        imgui.GetWindowDrawList == nil
    ) then
        return false;
    end

    local drawW = math.max(1, tonumber(width) or 1);
    local drawH = math.max(1, tonumber(height) or 1);
    local left = (tonumber(centerX) or 0) - (drawW * 0.5);
    local top = (tonumber(centerY) or 0) - (drawH * 0.5);
    local alpha = math.max(0, math.min(255, math.floor(((tonumber(opacity) or 100) * 2.55) + 0.5)));
    local tint = (alpha * 0x1000000) + 0xFFFFFF;
    local flags =
        (_G.ImGuiWindowFlags_NoTitleBar or 0) +
        (_G.ImGuiWindowFlags_NoScrollbar or 0) +
        (_G.ImGuiWindowFlags_NoScrollWithMouse or 0) +
        (_G.ImGuiWindowFlags_NoSavedSettings or 0) +
        (_G.ImGuiWindowFlags_NoBackground or 0) +
        (_G.ImGuiWindowFlags_NoResize or 0) +
        (_G.ImGuiWindowFlags_NoMove or 0) +
        (_G.ImGuiWindowFlags_NoInputs or 0);

    if (imgui.SetNextWindowPos ~= nil) then
        imgui.SetNextWindowPos({ left, top }, _G.ImGuiCond_Always or 1);
    end
    if (imgui.SetNextWindowSize ~= nil) then
        imgui.SetNextWindowSize({ drawW, drawH }, _G.ImGuiCond_Always or 1);
    end

    local pushedPadding = false;
    if (imgui.PushStyleVar ~= nil and _G.ImGuiStyleVar_WindowPadding ~= nil) then
        imgui.PushStyleVar(_G.ImGuiStyleVar_WindowPadding, { 0, 0 });
        pushedPadding = true;
    end

    local visible = imgui.Begin(
        'LibraPlates Pet Artwork##' .. tostring(windowId or 'static_artwork'),
        true,
        flags
    );
    if (visible == true) then
        local drawList = imgui.GetWindowDrawList();
        drawList:AddImage(
            textureId,
            { left, top },
            { left + drawW, top + drawH },
            uv1 or { 0, 0 },
            uv2 or { 1, 1 },
            tint
        );
    end
    imgui.End();

    if (pushedPadding == true and imgui.PopStyleVar ~= nil) then
        imgui.PopStyleVar();
    end

    return true;
end

local function QueueBstPet(pet)
    local layoutStateName = GetBstStateName(pet);
    local targetStateName = targeting.GetTargetStateName(pet.index);
    local nameSettings = state.GetWidgetSettings('Pet (BST)', layoutStateName, 'Name', nameDefaults);
    local backgroundSettings = state.GetWidgetSettings('Pet (BST)', layoutStateName, 'Background', backgroundDefaults);
    local hpBarSettings = state.GetWidgetSettings('Pet (BST)', layoutStateName, 'HP Bar', barDefaults);
    local tpBarSettings = state.GetWidgetSettings('Pet (BST)', layoutStateName, 'TP Bar', tpBarDefaults);
    local petTimerSettings = state.GetWidgetSettings('Pet (BST)', layoutStateName, 'Pet timer', petTimerDefaults);
    local petStateSettings = state.GetWidgetSettings('Pet (BST)', layoutStateName, 'Pet state', petStateDefaults);
    local sicSettings = state.GetWidgetSettings('Pet (BST)', layoutStateName, 'Sic', readyBarDefaults);
    local readySettings = state.GetWidgetSettings('Pet (BST)', layoutStateName, 'Ready bar', readyBarDefaults);
    local rewardSettings = state.GetWidgetSettings('Pet (BST)', layoutStateName, 'Reward', rewardBarDefaults);
    local targetMarker = targetModuleMarker.Build('Pet (BST)', layoutStateName, targetStateName, hpBarSettings, pet.distance);
    local globalSettings = state.GetGlobalSettings(globalDefaults);
    local targetingSettings = targeting.GetSettings();
    local hpPercent = ClampPercent(pet.hpPercent, 100);
    local tpValue = ClampTp(pet.tp);
    local tpPercent = tpValue / 10;
    local hpColor = hpBarSettings.color or { 0.95, 0.45, 0.45, 1.0 };

    local hpLowActive = (
        hpBarSettings.lowColorEnabled == true and
        hpPercent <= (tonumber(hpBarSettings.lowColorPercent) or 25)
    );

    if (hpLowActive == true) then
        hpColor = hpBarSettings.lowColor or hpColor;
    end

    local plateData = {
        hp = hpPercent,
        tp = tpPercent,
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
            imageOpacity = backgroundSettings.imageOpacity or backgroundDefaults.imageOpacity,
            anchorTo = backgroundSettings.anchorTo or backgroundDefaults.anchorTo,
            anchorPoint = backgroundSettings.anchorPoint or backgroundDefaults.anchorPoint,
        },
        name = (nameSettings.enabled == true) and ShortenName(pet.name, nameSettings.shortenName) or '',
        nameFontFamily = fonts.GetRole(globalSettings, false),
        nameFontFlags = fonts.GetRoleFlags(globalSettings, false),
        nameFontSize = textScale.ToNameTextureFontSize(nameSettings.textSize, nameDefaults.textSize),
        nameColor = nameSettings.color or { 1.0, 1.0, 1.0, 1.0 },
        nameOutlineEnabled = (tonumber(nameSettings.outlineSize) or 0) > 0,
        nameOutlineColor = nameSettings.outlineColor or { 0.0, 0.0, 0.0, 1.0 },
        nameOutlineSize = tonumber(nameSettings.outlineSize) or 0,
        nameOffsetX = ClampTextureOffset(tonumber(nameSettings.offsetX) or -38, 1024, 24),
        nameOffsetY = ClampTextureOffset(tonumber(nameSettings.offsetY) or -34, 512, 24),
        nameAnchorTo = nameSettings.anchorTo or nameDefaults.anchorTo,
        nameAnchorPoint = nameSettings.anchorPoint or nameDefaults.anchorPoint,
        hpBar = {
            enabled = hpBarSettings.enabled == true,
            width = tonumber(hpBarSettings.width) or 160,
            height = tonumber(hpBarSettings.height) or 14,
            offsetX = tonumber(hpBarSettings.offsetX) or 0,
            offsetY = tonumber(hpBarSettings.offsetY) or -16,
            color = hpColor,
            backgroundColor = hpBarSettings.backgroundColor or { 0.05, 0.05, 0.05, 0.85 },
            borderColor = hpBarSettings.borderColor or { 0.0, 0.0, 0.0, 1.0 },
            borderSize = tonumber(hpBarSettings.borderSize) or 0,
            cornerRadius = tonumber(hpBarSettings.cornerRadius) or 0,
            anchorTo = hpBarSettings.anchorTo or barDefaults.anchorTo,
            anchorPoint = hpBarSettings.anchorPoint or barDefaults.anchorPoint,
            texture = hpBarSettings.texture or 'Solid',
            textureStrength = tonumber(hpBarSettings.textureStrength) or 100,
            textureId = barTextures.GetTextureId(hpBarSettings.texture),
            animationEnabled = hpLowActive == true and hpBarSettings.lowAnimationEnabled == true,
            animationTextureId = barAnimations.GetTextureId(hpBarSettings.lowAnimation),
            animationSpeed = tonumber(hpBarSettings.lowAnimationSpeed) or 40,
            animationColor = hpBarSettings.lowAnimationColor,
            showAtPercent = tonumber(hpBarSettings.showAtPercent) or 100,
            text = BuildPercentFallbackResourceText(hpBarSettings, 'HP', pet.hp, pet.maxHp, hpPercent),
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
            enabled = tpBarSettings.enabled == true,
            width = tonumber(tpBarSettings.width) or 160,
            height = tonumber(tpBarSettings.height) or 6,
            offsetX = tonumber(tpBarSettings.offsetX) or 0,
            offsetY = tonumber(tpBarSettings.offsetY) or 4,
            color = tpBarSettings.color or { 0.0, 0.55, 0.95, 1.0 },
            backgroundColor = tpBarSettings.backgroundColor or { 0.05, 0.05, 0.05, 0.85 },
            borderColor = tpBarSettings.borderColor or { 0.0, 0.0, 0.0, 1.0 },
            borderSize = tonumber(tpBarSettings.borderSize) or 0,
            cornerRadius = tonumber(tpBarSettings.cornerRadius) or 0,
            anchorTo = tpBarSettings.anchorTo or tpBarDefaults.anchorTo,
            anchorPoint = tpBarSettings.anchorPoint or tpBarDefaults.anchorPoint,
            texture = tpBarSettings.texture or 'Solid',
            textureStrength = tonumber(tpBarSettings.textureStrength) or 100,
            textureId = barTextures.GetTextureId(tpBarSettings.texture),
            color2 = tpBarSettings.color2 or tpBarDefaults.color2,
            color3 = tpBarSettings.color3 or tpBarDefaults.color3,
            showAtPercent = tonumber(tpBarSettings.showAtPercent) or 300,
            segmented = tpBarSettings.segmented ~= false,
            segmentGap = tonumber(tpBarSettings.segmentGap) or 6,
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

    if (petTimerSettings.enabled == true) then
        AddPetTimerBadge(
            plateData,
            GetBstPetDurationText(pet, layoutStateName),
            petTimerSettings,
            globalSettings,
            (layoutStateName == 'Jug Pet') and 'Jug' or 'Charmed',
            (layoutStateName == 'Jug Pet') and 'jug' or 'charmed'
        );
    end

    if (petStateSettings.enabled == true) then
        AddPetStateBadge(plateData, petState.GetState(), petStateSettings, globalSettings);
    end

    local readyLabel = (layoutStateName == 'Jug Pet') and 'Ready' or 'Sic';
    local readyBar = nil;

    if (layoutStateName == 'Jug Pet') then
        if (readySettings.enabled == true) then
            local readyProgress, _, readyCharges = GetBstReadyBarData(readySettings);
            local readyText = BuildReadyCounterText(readySettings, readyCharges);
            readyBar = BuildExtraBar(readySettings, readyBarDefaults, readyProgress, readyText, 'ready', 'ready', globalSettings, BuildReadyLabelText(readySettings, readyLabel));
        end
    elseif (sicSettings.enabled == true) then
        local sicProgress = GetBstSicBarData(sicSettings);
        local singleBarSicSettings = CopySettingsWith(sicSettings, { segmented = false, showPercent = false });
        readyBar = BuildExtraBar(singleBarSicSettings, readyBarDefaults, sicProgress, '', 'sic', 'sic', globalSettings, BuildReadyLabelText(singleBarSicSettings, readyLabel));
    end

    if (readyBar ~= nil) then
        plateData.extraBars = plateData.extraBars or {};
        plateData.extraBars[#plateData.extraBars + 1] = readyBar;
    end

    local rewardBar = nil;

    if (rewardSettings.enabled == true) then
        local rewardProgress, rewardText = GetBstRewardBarData();
        if (tostring(rewardSettings.labelDisplayMode or 'Text') ~= 'Text') then
            rewardText = '';
        end
        rewardBar = BuildExtraBar(rewardSettings, rewardBarDefaults, rewardProgress, '', 'reward', 'reward', globalSettings, rewardText);
    end

    if (rewardBar ~= nil) then
        plateData.extraBars = plateData.extraBars or {};
        plateData.extraBars[#plateData.extraBars + 1] = rewardBar;
    end

    if (enmity.ShouldDrawAlly(pet, globalSettings) == true) then
        enmity.AddIcon(plateData, globalSettings.enmity, 'ally');
    end

    local plateTexture, textureWidth, textureHeight = canvasTexture.Render(plateData, 'bst-pet-' .. tostring(pet.index));
    local plateTextureId = canvasTexture.GetTextureId(plateTexture);

    if (plateTextureId == nil) then
        return;
    end

    local petPlateMode = tostring(targetingSettings.bstPetPlateMode or 'Normal');
    local worldPlateTextureId = plateTextureId;
    local worldTextureWidth = textureWidth;
    local worldTextureHeight = textureHeight;
    local worldClickRects = plateData._elementRects or canvasTexture.GetElementRects(plateData);

    if (petPlateMode ~= 'Normal') then
        DrawDetachedStaticPetFrame('bst', pet.index, plateData, targetingSettings, 'static_bst_pet_' .. tostring(pet.index), pet.name);
    end

    if (petPlateMode == 'Detach from pet') then
        local nameOnlyPlateData = BuildNameOnlyPlateData(plateData, ShortenName(pet.name, nameSettings.shortenName));
        local nameTexture, nameTextureWidth, nameTextureHeight = canvasTexture.Render(nameOnlyPlateData, 'bst-pet-name-' .. tostring(pet.index));
        local nameTextureId = canvasTexture.GetTextureId(nameTexture);

        if (nameTextureId == nil) then
            return;
        end

        worldPlateTextureId = nameTextureId;
        worldTextureWidth = nameTextureWidth;
        worldTextureHeight = nameTextureHeight;
        worldClickRects = nameOnlyPlateData._elementRects or canvasTexture.GetElementRects(nameOnlyPlateData);
    end

    local plateWorldWidth, plateWorldHeight = canvasTexture.GetWorldSize(2.35, 1.18, worldTextureWidth, worldTextureHeight);

    worldMarkerProbe.QueuePlate({
        targetIndex = pet.index,
        serverId = pet.serverId,
        distance = pet.distance,
        hp = hpPercent,
        tp = tpValue,
        name = '',
        isSelf = false,
        stateName = targetStateName,
        clickTargetType = 'pet',
        worldMarker = targeting.ApplyPlateScalingSettings({
            hpBar = { enabled = false },
            plateTextureId = worldPlateTextureId,
            plateAlwaysOnTop = true,
            plateTacticalOverlayOnly = true,
            anchorBone = petAnchorBone,
            plateWorldWidth = plateWorldWidth,
            plateWorldHeight = plateWorldHeight,
            plateWorldOffsetY = petWorldOffsetY,
            plateTextureWidth = worldTextureWidth,
            plateTextureHeight = worldTextureHeight,
            plateClickRects = worldClickRects,
            plateClickTargetEnabled = targetingSettings.enablePetPlateTargeting ~= false,
            clickTargetType = 'pet',
        }, 'pet', 0, petWorldOffsetY),
    });
end

local function QueueSmnPet(pet)
    local layoutStateName = (pet.petType == 'spirit') and 'Spirit' or 'Avatar';
    local targetStateName = targeting.GetTargetStateName(pet.index);
    local nameSettings = state.GetWidgetSettings('Pet (SMN)', layoutStateName, 'Name', nameDefaults);
    local backgroundSettings = state.GetWidgetSettings('Pet (SMN)', layoutStateName, 'Background', backgroundDefaults);
    local hpBarSettings = state.GetWidgetSettings('Pet (SMN)', layoutStateName, 'HP Bar', smnHpBarDefaults);
    local mpBarSettings = state.GetWidgetSettings('Pet (SMN)', layoutStateName, 'MP Bar', smnMpBarDefaults);
    local tpBarSettings = state.GetWidgetSettings('Pet (SMN)', layoutStateName, 'TP Bar', smnTpBarDefaults);
    local castBarSettings = state.GetWidgetSettings('Pet (SMN)', layoutStateName, 'Cast bar', smnCastBarDefaults);
    local wardSettings = state.GetWidgetSettings('Pet (SMN)', layoutStateName, 'Ward timer', wardBarDefaults);
    local rageSettings = state.GetWidgetSettings('Pet (SMN)', layoutStateName, 'Rage timer', rageBarDefaults);
    local targetMarker = targetModuleMarker.Build('Pet (SMN)', layoutStateName, targetStateName, hpBarSettings, pet.distance);
    local globalSettings = state.GetGlobalSettings(globalDefaults);
    local targetingSettings = targeting.GetSettings();
    local hpPercent = ClampPercent(pet.hpPercent, 100);
    local mpPercent = ClampPercent(pet.mpPercent, 0);
    local tpValue = ClampTp(pet.tp);
    local tpPercent = tpValue / 10;
    local hpColor = hpBarSettings.color or barDefaults.color;
    local mpColor = mpBarSettings.color or mpBarDefaults.color;
    local tpColor = tpBarSettings.color or tpBarDefaults.color;

    local hpLowActive = (
        hpBarSettings.lowColorEnabled == true and
        hpPercent <= (tonumber(hpBarSettings.lowColorPercent) or 25)
    );
    local mpLowActive = (
        mpBarSettings.lowColorEnabled == true and
        mpPercent <= (tonumber(mpBarSettings.lowColorPercent) or 25)
    );
    local tpLowActive = (
        tpBarSettings.lowColorEnabled == true and
        tpPercent <= (tonumber(tpBarSettings.lowColorPercent) or 25)
    );

    if (hpLowActive == true) then
        hpColor = hpBarSettings.lowColor or hpColor;
    end

    if (mpLowActive == true) then
        mpColor = mpBarSettings.lowColor or mpColor;
    end

    if (tpLowActive == true) then
        tpColor = tpBarSettings.lowColor or tpColor;
    end

    local castBar = nil;
    local castPercent = 0;
    local detachedCastBar = nil;
    local detachedCastPercent = 0;

    if (layoutStateName == 'Spirit') then
        local activeCast = enemyCasts.GetActiveCast(pet.serverId);
        local detachedBackgroundSettings = GetDetachedPetSetting(
            targetingSettings,
            'smn',
            'smnSpirit',
            'PetStaticBackgroundSettings'
        ) or {};
        local detachedCastSettings = detachedBackgroundSettings.avatarCastBarSettings
            or (((globalDefaults.targeting or {}).smnPetStaticBackgroundSettings or {}).avatarCastBarSettings)
            or smnCastBarDefaults;
        castBar, castPercent = BuildCastBar(activeCast, castBarSettings, globalSettings);
        detachedCastBar, detachedCastPercent = BuildCastBar(activeCast, detachedCastSettings, globalSettings);
    end

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
            imageOpacity = backgroundSettings.imageOpacity or backgroundDefaults.imageOpacity,
            anchorTo = backgroundSettings.anchorTo or backgroundDefaults.anchorTo,
            anchorPoint = backgroundSettings.anchorPoint or backgroundDefaults.anchorPoint,
        },
        name = (nameSettings.enabled == true) and ShortenName(pet.name, nameSettings.shortenName) or '',
        nameFontFamily = fonts.GetRole(globalSettings, false),
        nameFontFlags = fonts.GetRoleFlags(globalSettings, false),
        nameFontSize = textScale.ToNameTextureFontSize(nameSettings.textSize, nameDefaults.textSize),
        nameColor = nameSettings.color or nameDefaults.color,
        nameOutlineEnabled = (tonumber(nameSettings.outlineSize) or 0) > 0,
        nameOutlineColor = nameSettings.outlineColor or nameDefaults.outlineColor,
        nameOutlineSize = tonumber(nameSettings.outlineSize) or 0,
        nameOffsetX = ClampTextureOffset(tonumber(nameSettings.offsetX) or nameDefaults.offsetX, 1024, 24),
        nameOffsetY = ClampTextureOffset(tonumber(nameSettings.offsetY) or nameDefaults.offsetY, 512, 24),
        nameAnchorTo = nameSettings.anchorTo or nameDefaults.anchorTo,
        nameAnchorPoint = nameSettings.anchorPoint or nameDefaults.anchorPoint,
        hpBar = {
            enabled = hpBarSettings.enabled == true,
            width = tonumber(hpBarSettings.width) or smnHpBarDefaults.width,
            height = tonumber(hpBarSettings.height) or smnHpBarDefaults.height,
            offsetX = tonumber(hpBarSettings.offsetX) or smnHpBarDefaults.offsetX,
            offsetY = tonumber(hpBarSettings.offsetY) or smnHpBarDefaults.offsetY,
            color = hpColor,
            backgroundColor = hpBarSettings.backgroundColor or smnHpBarDefaults.backgroundColor,
            borderColor = hpBarSettings.borderColor or smnHpBarDefaults.borderColor,
            borderSize = tonumber(hpBarSettings.borderSize) or smnHpBarDefaults.borderSize,
            cornerRadius = tonumber(hpBarSettings.cornerRadius) or smnHpBarDefaults.cornerRadius or 0,
            anchorTo = hpBarSettings.anchorTo or smnHpBarDefaults.anchorTo,
            anchorPoint = hpBarSettings.anchorPoint or smnHpBarDefaults.anchorPoint,
            texture = hpBarSettings.texture or smnHpBarDefaults.texture,
            textureStrength = tonumber(hpBarSettings.textureStrength) or 100,
            textureId = barTextures.GetTextureId(hpBarSettings.texture or smnHpBarDefaults.texture),
            animationEnabled = hpLowActive == true and hpBarSettings.lowAnimationEnabled == true,
            animationTextureId = barAnimations.GetTextureId(hpBarSettings.lowAnimation),
            animationSpeed = tonumber(hpBarSettings.lowAnimationSpeed) or smnHpBarDefaults.lowAnimationSpeed,
            animationColor = hpBarSettings.lowAnimationColor,
            showAtPercent = tonumber(hpBarSettings.showAtPercent) or smnHpBarDefaults.showAtPercent,
            text = BuildResourceText(hpBarSettings, 'HP', pet.hp, pet.maxHp, hpPercent),
            textOffsetX = tonumber(hpBarSettings.textOffsetX) or smnHpBarDefaults.textOffsetX,
            textOffsetY = tonumber(hpBarSettings.textOffsetY) or smnHpBarDefaults.textOffsetY,
            fontFamily = fonts.GetRole(globalSettings, hpBarSettings.useSmallFont == true),
            fontFlags = fonts.GetRoleFlags(globalSettings, hpBarSettings.useSmallFont == true),
            fontSize = textScale.ToTextureFontSize(hpBarSettings.fontSize, smnHpBarDefaults.fontSize),
            textColor = hpBarSettings.textColor or smnHpBarDefaults.textColor,
            textOutlineEnabled = hpBarSettings.textOutlineEnabled == true,
            textOutlineColor = hpBarSettings.textOutlineColor or smnHpBarDefaults.textOutlineColor,
            textOutlineSize = tonumber(hpBarSettings.textOutlineSize) or smnHpBarDefaults.textOutlineSize,
        },
        mpBar = {
            enabled = layoutStateName == 'Spirit' and mpBarSettings.enabled == true,
            width = tonumber(mpBarSettings.width) or smnMpBarDefaults.width,
            height = tonumber(mpBarSettings.height) or smnMpBarDefaults.height,
            offsetX = tonumber(mpBarSettings.offsetX) or smnMpBarDefaults.offsetX,
            offsetY = tonumber(mpBarSettings.offsetY) or smnMpBarDefaults.offsetY,
            color = mpColor,
            backgroundColor = mpBarSettings.backgroundColor or smnMpBarDefaults.backgroundColor,
            borderColor = mpBarSettings.borderColor or smnMpBarDefaults.borderColor,
            borderSize = tonumber(mpBarSettings.borderSize) or smnMpBarDefaults.borderSize,
            cornerRadius = tonumber(mpBarSettings.cornerRadius) or smnMpBarDefaults.cornerRadius or 0,
            anchorTo = mpBarSettings.anchorTo or smnMpBarDefaults.anchorTo,
            anchorPoint = mpBarSettings.anchorPoint or smnMpBarDefaults.anchorPoint,
            texture = mpBarSettings.texture or smnMpBarDefaults.texture,
            textureStrength = tonumber(mpBarSettings.textureStrength) or 100,
            textureId = barTextures.GetTextureId(mpBarSettings.texture or smnMpBarDefaults.texture),
            animationEnabled = mpLowActive == true and mpBarSettings.lowAnimationEnabled == true,
            animationTextureId = barAnimations.GetTextureId(mpBarSettings.lowAnimation),
            animationSpeed = tonumber(mpBarSettings.lowAnimationSpeed) or smnMpBarDefaults.lowAnimationSpeed,
            animationColor = mpBarSettings.lowAnimationColor,
            showAtPercent = tonumber(mpBarSettings.showAtPercent) or smnMpBarDefaults.showAtPercent,
            text = BuildPercentFallbackResourceText(mpBarSettings, 'MP', nil, nil, mpPercent),
            textOffsetX = tonumber(mpBarSettings.textOffsetX) or smnMpBarDefaults.textOffsetX,
            textOffsetY = tonumber(mpBarSettings.textOffsetY) or smnMpBarDefaults.textOffsetY,
            fontFamily = fonts.GetRole(globalSettings, mpBarSettings.useSmallFont == true),
            fontFlags = fonts.GetRoleFlags(globalSettings, mpBarSettings.useSmallFont == true),
            fontSize = textScale.ToTextureFontSize(mpBarSettings.fontSize, smnMpBarDefaults.fontSize),
            textColor = mpBarSettings.textColor or smnMpBarDefaults.textColor,
            textOutlineEnabled = mpBarSettings.textOutlineEnabled == true,
            textOutlineColor = mpBarSettings.textOutlineColor or smnMpBarDefaults.textOutlineColor,
            textOutlineSize = tonumber(mpBarSettings.textOutlineSize) or smnMpBarDefaults.textOutlineSize,
        },
        tpBar = {
            enabled = layoutStateName == 'Avatar' and tpBarSettings.enabled == true,
            width = tonumber(tpBarSettings.width) or smnTpBarDefaults.width,
            height = tonumber(tpBarSettings.height) or smnTpBarDefaults.height,
            offsetX = tonumber(tpBarSettings.offsetX) or smnTpBarDefaults.offsetX,
            offsetY = tonumber(tpBarSettings.offsetY) or smnTpBarDefaults.offsetY,
            color = tpColor,
            backgroundColor = tpBarSettings.backgroundColor or smnTpBarDefaults.backgroundColor,
            borderColor = tpBarSettings.borderColor or smnTpBarDefaults.borderColor,
            borderSize = tonumber(tpBarSettings.borderSize) or smnTpBarDefaults.borderSize,
            cornerRadius = tonumber(tpBarSettings.cornerRadius) or smnTpBarDefaults.cornerRadius or 0,
            anchorTo = tpBarSettings.anchorTo or smnTpBarDefaults.anchorTo,
            anchorPoint = tpBarSettings.anchorPoint or smnTpBarDefaults.anchorPoint,
            texture = tpBarSettings.texture or smnTpBarDefaults.texture,
            textureStrength = tonumber(tpBarSettings.textureStrength) or 100,
            textureId = barTextures.GetTextureId(tpBarSettings.texture or smnTpBarDefaults.texture),
            animationEnabled = tpLowActive == true and tpBarSettings.lowAnimationEnabled == true,
            animationTextureId = barAnimations.GetTextureId(tpBarSettings.lowAnimation),
            animationSpeed = tonumber(tpBarSettings.lowAnimationSpeed) or smnTpBarDefaults.lowAnimationSpeed,
            animationColor = tpBarSettings.lowAnimationColor,
            color2 = tpBarSettings.color2 or smnTpBarDefaults.color2,
            color3 = tpBarSettings.color3 or smnTpBarDefaults.color3,
            showAtPercent = tonumber(tpBarSettings.showAtPercent) or smnTpBarDefaults.showAtPercent,
            segmented = tpBarSettings.segmented ~= false,
            segmentGap = tonumber(tpBarSettings.segmentGap) or smnTpBarDefaults.segmentGap,
            text = BuildResourceText(tpBarSettings, 'TP', tpValue, 3000, tpPercent),
            textOffsetX = tonumber(tpBarSettings.textOffsetX) or smnTpBarDefaults.textOffsetX,
            textOffsetY = tonumber(tpBarSettings.textOffsetY) or smnTpBarDefaults.textOffsetY,
            fontFamily = fonts.GetRole(globalSettings, tpBarSettings.useSmallFont == true),
            fontFlags = fonts.GetRoleFlags(globalSettings, tpBarSettings.useSmallFont == true),
            fontSize = textScale.ToTextureFontSize(tpBarSettings.fontSize, smnTpBarDefaults.fontSize),
            textColor = tpBarSettings.textColor or smnTpBarDefaults.textColor,
            textOutlineEnabled = tpBarSettings.textOutlineEnabled == true,
            textOutlineColor = tpBarSettings.textOutlineColor or smnTpBarDefaults.textOutlineColor,
            textOutlineSize = tonumber(tpBarSettings.textOutlineSize) or smnTpBarDefaults.textOutlineSize,
        },
        castBar = castBar,
    };

    if (layoutStateName == 'Avatar') then
        AddSmnAvatarExtraBars(plateData, wardSettings, rageSettings, globalSettings);
    end

    local detachedSettingsPrefix = layoutStateName == 'Spirit' and 'smnSpirit' or 'smnAvatar';
    local petPlateMode = tostring(
        GetDetachedPetSetting(targetingSettings, 'smn', detachedSettingsPrefix, 'PetPlateMode')
        or 'Normal'
    );
    if (petPlateMode ~= 'Normal') then
        plateData.detachedSmnPetType = layoutStateName;
        plateData.detachedAvatarName = tostring(pet.name or '');
        plateData.detachedAvatarHp = pet.hp;
        plateData.detachedAvatarMaxHp = pet.maxHp;
        plateData.detachedAvatarTp = tpValue;
        plateData.detachedAvatarSetupPreview = GetDetachedPetSetting(
            targetingSettings,
            'smn',
            detachedSettingsPrefix,
            'PetStaticEditFrame'
        ) == true;
        plateData.detachedAvatarFavorActive = select(1, GetAvatarFavorStatusElapsed());
        plateData.detachedAvatarFavorCooldownSeconds = GetAvatarFavorCooldownSeconds();
        plateData.detachedAvatarHasPet = true;
        plateData.detachedAvatarFavorAvatarName = layoutStateName == 'Avatar'
            and tostring(pet.name or '')
            or nil;

        plateData.detachedAvatarBars = BuildDetachedSmnMeterSources(pet);

        if (layoutStateName == 'Spirit') then
            plateData.detachedAvatarCastBar = detachedCastBar;
            plateData.detachedAvatarCast = detachedCastPercent;
        end
    end

    if (enmity.ShouldDrawAlly(pet, globalSettings) == true) then
        enmity.AddIcon(plateData, globalSettings.enmity, 'ally');
    end

    local plateTexture, textureWidth, textureHeight = canvasTexture.Render(plateData, 'smn-pet-' .. tostring(pet.index));
    local plateTextureId = canvasTexture.GetTextureId(plateTexture);

    if (plateTextureId == nil) then
        return;
    end

    local worldPlateTextureId = plateTextureId;
    local worldTextureWidth = textureWidth;
    local worldTextureHeight = textureHeight;
    local worldClickRects = plateData._elementRects or canvasTexture.GetElementRects(plateData);

    if (petPlateMode ~= 'Normal') then
        DrawDetachedStaticPetFrame(
            'smn',
            pet.index,
            plateData,
            targetingSettings,
            'static_smn_pet_' .. tostring(pet.index),
            pet.name,
            layoutStateName == 'Spirit' and 'smnSpirit' or 'smnAvatar'
        );
    end

    if (petPlateMode == 'Detach from pet') then
        local nameOnlyPlateData = BuildNameOnlyPlateData(plateData, ShortenName(pet.name, nameSettings.shortenName));
        local nameTexture, nameTextureWidth, nameTextureHeight = canvasTexture.Render(nameOnlyPlateData, 'smn-pet-name-' .. tostring(pet.index));
        local nameTextureId = canvasTexture.GetTextureId(nameTexture);

        if (nameTextureId == nil) then
            return;
        end

        worldPlateTextureId = nameTextureId;
        worldTextureWidth = nameTextureWidth;
        worldTextureHeight = nameTextureHeight;
        worldClickRects = nameOnlyPlateData._elementRects or canvasTexture.GetElementRects(nameOnlyPlateData);
    end

    local plateWorldWidth, plateWorldHeight = canvasTexture.GetWorldSize(2.35, 1.18, worldTextureWidth, worldTextureHeight);

    worldMarkerProbe.QueuePlate({
        targetIndex = pet.index,
        serverId = pet.serverId,
        distance = pet.distance,
        hp = hpPercent,
        tp = tpValue,
        name = '',
        isSelf = false,
        stateName = targetStateName,
        clickTargetType = 'pet',
        worldMarker = targeting.ApplyPlateScalingSettings({
            hpBar = { enabled = false },
            plateTextureId = worldPlateTextureId,
            plateAlwaysOnTop = true,
            plateTacticalOverlayOnly = true,
            anchorBone = petAnchorBone,
            plateWorldWidth = plateWorldWidth,
            plateWorldHeight = plateWorldHeight,
            plateWorldOffsetY = petWorldOffsetY,
            plateTextureWidth = worldTextureWidth,
            plateTextureHeight = worldTextureHeight,
            plateClickRects = worldClickRects,
            plateClickTargetEnabled = targetingSettings.enablePetPlateTargeting ~= false,
            clickTargetType = 'pet',
        }, 'pet', 0, petWorldOffsetY),
    });
end

local function QueueWyvernPet(pet)
    local layoutStateName = 'Wyvern';
    local targetStateName = targeting.GetTargetStateName(pet.index);
    local wyvernAnchorBone = petPlate.GetWyvernAnchorBone(pet);
    local wyvernWorldOffsetY = petPlate.GetWyvernWorldOffsetY(pet);
    local wyvernOverlayOffsetY = petPlate.GetWyvernOverlayOffsetY(pet);
    local nameSettings = state.GetWidgetSettings('Wyvern', layoutStateName, 'Name', nameDefaults);
    local backgroundSettings = state.GetWidgetSettings('Wyvern', layoutStateName, 'Background', backgroundDefaults);
    local hpBarSettings = state.GetWidgetSettings('Wyvern', layoutStateName, 'HP Bar', barDefaults);
    local tpBarSettings = state.GetWidgetSettings('Wyvern', layoutStateName, 'TP Bar', tpBarDefaults);
    local distanceSettings = state.GetWidgetSettings('Wyvern', layoutStateName, 'Distance', distanceDefaults);
    local targetMarker = targetModuleMarker.Build('Wyvern', layoutStateName, targetStateName, hpBarSettings, pet.distance);
    local globalSettings = state.GetGlobalSettings(globalDefaults);
    local targetingSettings = targeting.GetSettings();
    local hpPercent = ClampPercent(pet.hpPercent, 100);
    local tpValue = ClampTp(pet.tp);
    local tpPercent = tpValue / 10;
    local hpColor = hpBarSettings.color or barDefaults.color;
    local tpColor = tpBarSettings.color or tpBarDefaults.color;
    local tpColor2 = tpBarSettings.color2 or tpBarDefaults.color2;
    local tpColor3 = tpBarSettings.color3 or tpBarDefaults.color3;

    local hpLowActive = (
        hpBarSettings.lowColorEnabled == true and
        hpPercent <= (tonumber(hpBarSettings.lowColorPercent) or 25)
    );
    local tpLowActive = (
        tpBarSettings.lowColorEnabled == true and
        tpPercent <= (tonumber(tpBarSettings.lowColorPercent) or 25)
    );

    if (hpLowActive == true) then
        hpColor = hpBarSettings.lowColor or hpColor;
    end

    if (tpLowActive == true) then
        tpColor = tpBarSettings.lowColor or tpColor;
    end

    if (tpPercent >= 100) then
        tpColor = tpBarSettings.fullColor or tpBarDefaults.fullColor or tpColor;
        tpColor2 = tpColor;
        tpColor3 = tpColor;
    end

    local plateData = {
        hp = hpPercent,
        tp = tpPercent,
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
            imageOpacity = backgroundSettings.imageOpacity or backgroundDefaults.imageOpacity,
            anchorTo = backgroundSettings.anchorTo or backgroundDefaults.anchorTo,
            anchorPoint = backgroundSettings.anchorPoint or backgroundDefaults.anchorPoint,
        },
        name = (nameSettings.enabled == true) and ShortenName(pet.name, nameSettings.shortenName) or '',
        nameFontFamily = fonts.GetRole(globalSettings, false),
        nameFontFlags = fonts.GetRoleFlags(globalSettings, false),
        nameFontSize = textScale.ToNameTextureFontSize(nameSettings.textSize, nameDefaults.textSize),
        nameColor = nameSettings.color or nameDefaults.color,
        nameOutlineEnabled = (tonumber(nameSettings.outlineSize) or 0) > 0,
        nameOutlineColor = nameSettings.outlineColor or nameDefaults.outlineColor,
        nameOutlineSize = tonumber(nameSettings.outlineSize) or 0,
        nameOffsetX = ClampTextureOffset(tonumber(nameSettings.offsetX) or nameDefaults.offsetX, 1024, 24),
        nameOffsetY = ClampTextureOffset(tonumber(nameSettings.offsetY) or nameDefaults.offsetY, 512, 24),
        nameAnchorTo = nameSettings.anchorTo or nameDefaults.anchorTo,
        nameAnchorPoint = nameSettings.anchorPoint or nameDefaults.anchorPoint,
        hpBar = {
            enabled = hpBarSettings.enabled == true,
            width = tonumber(hpBarSettings.width) or barDefaults.width,
            height = tonumber(hpBarSettings.height) or barDefaults.height,
            offsetX = tonumber(hpBarSettings.offsetX) or barDefaults.offsetX,
            offsetY = tonumber(hpBarSettings.offsetY) or barDefaults.offsetY,
            color = hpColor,
            backgroundColor = hpBarSettings.backgroundColor or barDefaults.backgroundColor,
            borderColor = hpBarSettings.borderColor or barDefaults.borderColor,
            borderSize = tonumber(hpBarSettings.borderSize) or barDefaults.borderSize,
            cornerRadius = tonumber(hpBarSettings.cornerRadius) or barDefaults.cornerRadius or 0,
            anchorTo = hpBarSettings.anchorTo or barDefaults.anchorTo,
            anchorPoint = hpBarSettings.anchorPoint or barDefaults.anchorPoint,
            texture = hpBarSettings.texture or barDefaults.texture,
            textureStrength = tonumber(hpBarSettings.textureStrength) or 100,
            textureId = barTextures.GetTextureId(hpBarSettings.texture or barDefaults.texture),
            animationEnabled = hpLowActive == true and hpBarSettings.lowAnimationEnabled == true,
            animationTextureId = barAnimations.GetTextureId(hpBarSettings.lowAnimation),
            animationSpeed = tonumber(hpBarSettings.lowAnimationSpeed) or barDefaults.lowAnimationSpeed,
            animationColor = hpBarSettings.lowAnimationColor,
            showAtPercent = tonumber(hpBarSettings.showAtPercent) or barDefaults.showAtPercent,
            text = BuildPercentFallbackResourceText(hpBarSettings, 'HP', nil, nil, hpPercent),
            textOffsetX = tonumber(hpBarSettings.textOffsetX) or barDefaults.textOffsetX,
            textOffsetY = tonumber(hpBarSettings.textOffsetY) or barDefaults.textOffsetY,
            fontFamily = fonts.GetRole(globalSettings, hpBarSettings.useSmallFont == true),
            fontFlags = fonts.GetRoleFlags(globalSettings, hpBarSettings.useSmallFont == true),
            fontSize = textScale.ToTextureFontSize(hpBarSettings.fontSize, barDefaults.fontSize),
            textColor = hpBarSettings.textColor or barDefaults.textColor,
            textOutlineEnabled = hpBarSettings.textOutlineEnabled == true,
            textOutlineColor = hpBarSettings.textOutlineColor or barDefaults.textOutlineColor,
            textOutlineSize = tonumber(hpBarSettings.textOutlineSize) or barDefaults.textOutlineSize,
        },
        mpBar = {
            enabled = false,
        },
        tpBar = {
            enabled = tpBarSettings.enabled == true,
            width = tonumber(tpBarSettings.width) or tpBarDefaults.width,
            height = tonumber(tpBarSettings.height) or tpBarDefaults.height,
            offsetX = tonumber(tpBarSettings.offsetX) or tpBarDefaults.offsetX,
            offsetY = tonumber(tpBarSettings.offsetY) or tpBarDefaults.offsetY,
            color = tpColor,
            backgroundColor = tpBarSettings.backgroundColor or tpBarDefaults.backgroundColor,
            borderColor = tpBarSettings.borderColor or tpBarDefaults.borderColor,
            borderSize = tonumber(tpBarSettings.borderSize) or tpBarDefaults.borderSize,
            cornerRadius = tonumber(tpBarSettings.cornerRadius) or tpBarDefaults.cornerRadius or 0,
            anchorTo = tpBarSettings.anchorTo or tpBarDefaults.anchorTo,
            anchorPoint = tpBarSettings.anchorPoint or tpBarDefaults.anchorPoint,
            texture = tpBarSettings.texture or tpBarDefaults.texture,
            textureStrength = tonumber(tpBarSettings.textureStrength) or 100,
            textureId = barTextures.GetTextureId(tpBarSettings.texture or tpBarDefaults.texture),
            animationEnabled = tpLowActive == true and tpBarSettings.lowAnimationEnabled == true,
            animationTextureId = barAnimations.GetTextureId(tpBarSettings.lowAnimation),
            animationSpeed = tonumber(tpBarSettings.lowAnimationSpeed) or tpBarDefaults.lowAnimationSpeed,
            animationColor = tpBarSettings.lowAnimationColor,
            color2 = tpColor2,
            color3 = tpColor3,
            showAtPercent = tonumber(tpBarSettings.showAtPercent) or tpBarDefaults.showAtPercent,
            segmented = tpBarSettings.segmented ~= false,
            segmentGap = tonumber(tpBarSettings.segmentGap) or tpBarDefaults.segmentGap,
            text = BuildResourceText(tpBarSettings, 'TP', tpValue, 3000, tpPercent),
            textOffsetX = tonumber(tpBarSettings.textOffsetX) or tpBarDefaults.textOffsetX,
            textOffsetY = tonumber(tpBarSettings.textOffsetY) or tpBarDefaults.textOffsetY,
            fontFamily = fonts.GetRole(globalSettings, tpBarSettings.useSmallFont == true),
            fontFlags = fonts.GetRoleFlags(globalSettings, tpBarSettings.useSmallFont == true),
            fontSize = textScale.ToTextureFontSize(tpBarSettings.fontSize, tpBarDefaults.fontSize),
            textColor = tpBarSettings.textColor or tpBarDefaults.textColor,
            textOutlineEnabled = tpBarSettings.textOutlineEnabled == true,
            textOutlineColor = tpBarSettings.textOutlineColor or tpBarDefaults.textOutlineColor,
            textOutlineSize = tonumber(tpBarSettings.textOutlineSize) or tpBarDefaults.textOutlineSize,
        },
    };

    if (IsTargetOrSubtarget(targetStateName) == true) then
        AddDistanceToPlate(plateData, pet, distanceSettings, globalSettings);
    end

    if (enmity.ShouldDrawAlly(pet, globalSettings) == true) then
        enmity.AddIcon(plateData, globalSettings.enmity, 'ally');
    end

    local plateTexture, textureWidth, textureHeight = canvasTexture.Render(plateData, 'wyvern-pet-' .. tostring(pet.index));
    local plateTextureId = canvasTexture.GetTextureId(plateTexture);

    if (plateTextureId == nil) then
        return;
    end

    local petPlateMode = tostring(targetingSettings.drgPetPlateMode or 'Normal');
    local worldPlateTextureId = plateTextureId;
    local worldTextureWidth = textureWidth;
    local worldTextureHeight = textureHeight;
    local worldClickRects = plateData._elementRects or canvasTexture.GetElementRects(plateData);

    if (petPlateMode ~= 'Normal') then
        DrawDetachedStaticPetFrame('drg', pet.index, plateData, targetingSettings, 'static_drg_pet_' .. tostring(pet.index), pet.name);
    end

    if (petPlateMode == 'Detach from pet') then
        local nameOnlyPlateData = BuildNameOnlyPlateData(plateData, ShortenName(pet.name, nameSettings.shortenName));
        local nameTexture, nameTextureWidth, nameTextureHeight = canvasTexture.Render(nameOnlyPlateData, 'drg-pet-name-' .. tostring(pet.index));
        local nameTextureId = canvasTexture.GetTextureId(nameTexture);

        if (nameTextureId == nil) then
            return;
        end

        worldPlateTextureId = nameTextureId;
        worldTextureWidth = nameTextureWidth;
        worldTextureHeight = nameTextureHeight;
        worldClickRects = nameOnlyPlateData._elementRects or canvasTexture.GetElementRects(nameOnlyPlateData);
    end

    local plateWorldWidth, plateWorldHeight = canvasTexture.GetWorldSize(2.35, 1.18, worldTextureWidth, worldTextureHeight);

    worldMarkerProbe.QueuePlate({
        targetIndex = pet.index,
        serverId = pet.serverId,
        distance = pet.distance,
        hp = hpPercent,
        tp = tpValue,
        name = '',
        isSelf = false,
        stateName = targetStateName,
        clickTargetType = 'pet',
        worldMarker = targeting.ApplyPlateScalingSettings({
            hpBar = { enabled = false },
            plateTextureId = worldPlateTextureId,
            plateAlwaysOnTop = true,
            plateTacticalOverlayOnly = true,
            anchorBone = wyvernAnchorBone,
            plateWorldWidth = plateWorldWidth,
            plateWorldHeight = plateWorldHeight,
            plateWorldOffsetY = wyvernWorldOffsetY,
            plateOverlayOffsetY = wyvernOverlayOffsetY,
            plateTextureWidth = worldTextureWidth,
            plateTextureHeight = worldTextureHeight,
            plateClickRects = worldClickRects,
            plateClickTargetEnabled = targetingSettings.enablePetPlateTargeting ~= false,
            clickTargetType = 'pet',
            layoutStateName = layoutStateName,
        }, 'pet', 0, petWorldOffsetY),
    });
end

local function QueuePupPet(pet)
    local layoutStateName = 'Automaton';
    local targetStateName = targeting.GetTargetStateName(pet.index);
    local nameSettings = state.GetWidgetSettings('Automaton', layoutStateName, 'Name', nameDefaults);
    local backgroundSettings = state.GetWidgetSettings('Automaton', layoutStateName, 'Background', backgroundDefaults);
    local hpBarSettings = state.GetWidgetSettings('Automaton', layoutStateName, 'HP Bar', barDefaults);
    local mpBarSettings = state.GetWidgetSettings('Automaton', layoutStateName, 'MP Bar', mpBarDefaults);
    local tpBarSettings = state.GetWidgetSettings('Automaton', layoutStateName, 'TP Bar', tpBarDefaults);
    local distanceSettings = state.GetWidgetSettings('Automaton', layoutStateName, 'Distance', distanceDefaults);
    local maneuverSettings = state.GetWidgetSettings('Automaton', layoutStateName, 'Maneuvers', maneuverDefaults);
    local targetMarker = targetModuleMarker.Build('Automaton', layoutStateName, targetStateName, hpBarSettings, pet.distance);
    local globalSettings = state.GetGlobalSettings(globalDefaults);
    local targetingSettings = targeting.GetSettings();
    local hpPercent = ClampPercent(pet.hpPercent, 100);
    local mpPercent = ClampPercent(pet.mpPercent, 0);
    local tpValue = ClampTp(pet.tp);
    local tpPercent = tpValue / 10;
    local hpColor = hpBarSettings.color or barDefaults.color;
    local mpColor = mpBarSettings.color or mpBarDefaults.color;
    local tpColor = tpBarSettings.color or tpBarDefaults.color;

    if (pupEquipmentTest.summonActive ~= true) then
        local equipment = pupEquipment.Read();
        pupEquipmentTest.summonActive = true;
        pupEquipmentTest.head = equipment.head;
        pupEquipmentTest.frame = equipment.frame;
    end

    local hpLowActive = (
        hpBarSettings.lowColorEnabled == true and
        hpPercent <= (tonumber(hpBarSettings.lowColorPercent) or 25)
    );
    local mpLowActive = (
        mpBarSettings.lowColorEnabled == true and
        mpPercent <= (tonumber(mpBarSettings.lowColorPercent) or 25)
    );
    local tpLowActive = (
        tpBarSettings.lowColorEnabled == true and
        tpPercent <= (tonumber(tpBarSettings.lowColorPercent) or 25)
    );

    if (hpLowActive == true) then
        hpColor = hpBarSettings.lowColor or hpColor;
    end

    if (mpLowActive == true) then
        mpColor = mpBarSettings.lowColor or mpColor;
    end

    if (tpLowActive == true) then
        tpColor = tpBarSettings.lowColor or tpColor;
    end

    local plateData = {
        hp = hpPercent,
        mp = mpPercent,
        tp = tpPercent,
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
            imageOpacity = backgroundSettings.imageOpacity or backgroundDefaults.imageOpacity,
            anchorTo = backgroundSettings.anchorTo or backgroundDefaults.anchorTo,
            anchorPoint = backgroundSettings.anchorPoint or backgroundDefaults.anchorPoint,
        },
        name = (nameSettings.enabled == true) and ShortenName(pet.name, nameSettings.shortenName) or '',
        nameFontFamily = fonts.GetRole(globalSettings, false),
        nameFontFlags = fonts.GetRoleFlags(globalSettings, false),
        nameFontSize = textScale.ToNameTextureFontSize(nameSettings.textSize, nameDefaults.textSize),
        nameColor = nameSettings.color or nameDefaults.color,
        nameOutlineEnabled = (tonumber(nameSettings.outlineSize) or 0) > 0,
        nameOutlineColor = nameSettings.outlineColor or nameDefaults.outlineColor,
        nameOutlineSize = tonumber(nameSettings.outlineSize) or 0,
        nameOffsetX = ClampTextureOffset(tonumber(nameSettings.offsetX) or nameDefaults.offsetX, 1024, 24),
        nameOffsetY = ClampTextureOffset(tonumber(nameSettings.offsetY) or nameDefaults.offsetY, 512, 24),
        nameAnchorTo = nameSettings.anchorTo or nameDefaults.anchorTo,
        nameAnchorPoint = nameSettings.anchorPoint or nameDefaults.anchorPoint,
        hpBar = {
            enabled = hpBarSettings.enabled == true,
            width = tonumber(hpBarSettings.width) or barDefaults.width,
            height = tonumber(hpBarSettings.height) or barDefaults.height,
            offsetX = tonumber(hpBarSettings.offsetX) or barDefaults.offsetX,
            offsetY = tonumber(hpBarSettings.offsetY) or barDefaults.offsetY,
            color = hpColor,
            backgroundColor = hpBarSettings.backgroundColor or barDefaults.backgroundColor,
            borderColor = hpBarSettings.borderColor or barDefaults.borderColor,
            borderSize = tonumber(hpBarSettings.borderSize) or barDefaults.borderSize,
            cornerRadius = tonumber(hpBarSettings.cornerRadius) or barDefaults.cornerRadius or 0,
            anchorTo = hpBarSettings.anchorTo or barDefaults.anchorTo,
            anchorPoint = hpBarSettings.anchorPoint or barDefaults.anchorPoint,
            texture = hpBarSettings.texture or barDefaults.texture,
            textureStrength = tonumber(hpBarSettings.textureStrength) or 100,
            textureId = barTextures.GetTextureId(hpBarSettings.texture or barDefaults.texture),
            animationEnabled = hpLowActive == true and hpBarSettings.lowAnimationEnabled == true,
            animationTextureId = barAnimations.GetTextureId(hpBarSettings.lowAnimation),
            animationSpeed = tonumber(hpBarSettings.lowAnimationSpeed) or barDefaults.lowAnimationSpeed,
            animationColor = hpBarSettings.lowAnimationColor,
            showAtPercent = tonumber(hpBarSettings.showAtPercent) or barDefaults.showAtPercent,
            text = BuildPercentFallbackResourceText(hpBarSettings, 'HP', pet.hp, pet.maxHp, hpPercent),
            textOffsetX = tonumber(hpBarSettings.textOffsetX) or barDefaults.textOffsetX,
            textOffsetY = tonumber(hpBarSettings.textOffsetY) or barDefaults.textOffsetY,
            fontFamily = fonts.GetRole(globalSettings, hpBarSettings.useSmallFont == true),
            fontFlags = fonts.GetRoleFlags(globalSettings, hpBarSettings.useSmallFont == true),
            fontSize = textScale.ToTextureFontSize(hpBarSettings.fontSize, barDefaults.fontSize),
            textColor = hpBarSettings.textColor or barDefaults.textColor,
            textOutlineEnabled = hpBarSettings.textOutlineEnabled == true,
            textOutlineColor = hpBarSettings.textOutlineColor or barDefaults.textOutlineColor,
            textOutlineSize = tonumber(hpBarSettings.textOutlineSize) or barDefaults.textOutlineSize,
        },
        mpBar = {
            enabled = mpBarSettings.enabled == true,
            width = tonumber(mpBarSettings.width) or mpBarDefaults.width,
            height = tonumber(mpBarSettings.height) or mpBarDefaults.height,
            offsetX = tonumber(mpBarSettings.offsetX) or mpBarDefaults.offsetX,
            offsetY = tonumber(mpBarSettings.offsetY) or mpBarDefaults.offsetY,
            color = mpColor,
            backgroundColor = mpBarSettings.backgroundColor or mpBarDefaults.backgroundColor,
            borderColor = mpBarSettings.borderColor or mpBarDefaults.borderColor,
            borderSize = tonumber(mpBarSettings.borderSize) or mpBarDefaults.borderSize,
            cornerRadius = tonumber(mpBarSettings.cornerRadius) or mpBarDefaults.cornerRadius or 0,
            anchorTo = mpBarSettings.anchorTo or mpBarDefaults.anchorTo,
            anchorPoint = mpBarSettings.anchorPoint or mpBarDefaults.anchorPoint,
            texture = mpBarSettings.texture or mpBarDefaults.texture,
            textureStrength = tonumber(mpBarSettings.textureStrength) or 100,
            textureId = barTextures.GetTextureId(mpBarSettings.texture or mpBarDefaults.texture),
            animationEnabled = mpLowActive == true and mpBarSettings.lowAnimationEnabled == true,
            animationTextureId = barAnimations.GetTextureId(mpBarSettings.lowAnimation),
            animationSpeed = tonumber(mpBarSettings.lowAnimationSpeed) or mpBarDefaults.lowAnimationSpeed,
            animationColor = mpBarSettings.lowAnimationColor,
            showAtPercent = tonumber(mpBarSettings.showAtPercent) or mpBarDefaults.showAtPercent,
            text = BuildPercentFallbackResourceText(mpBarSettings, 'MP', nil, nil, mpPercent),
            textOffsetX = tonumber(mpBarSettings.textOffsetX) or mpBarDefaults.textOffsetX,
            textOffsetY = tonumber(mpBarSettings.textOffsetY) or mpBarDefaults.textOffsetY,
            fontFamily = fonts.GetRole(globalSettings, mpBarSettings.useSmallFont == true),
            fontFlags = fonts.GetRoleFlags(globalSettings, mpBarSettings.useSmallFont == true),
            fontSize = textScale.ToTextureFontSize(mpBarSettings.fontSize, mpBarDefaults.fontSize),
            textColor = mpBarSettings.textColor or mpBarDefaults.textColor,
            textOutlineEnabled = mpBarSettings.textOutlineEnabled == true,
            textOutlineColor = mpBarSettings.textOutlineColor or mpBarDefaults.textOutlineColor,
            textOutlineSize = tonumber(mpBarSettings.textOutlineSize) or mpBarDefaults.textOutlineSize,
        },
        tpBar = {
            enabled = tpBarSettings.enabled == true,
            width = tonumber(tpBarSettings.width) or tpBarDefaults.width,
            height = tonumber(tpBarSettings.height) or tpBarDefaults.height,
            offsetX = tonumber(tpBarSettings.offsetX) or tpBarDefaults.offsetX,
            offsetY = tonumber(tpBarSettings.offsetY) or tpBarDefaults.offsetY,
            color = tpColor,
            backgroundColor = tpBarSettings.backgroundColor or tpBarDefaults.backgroundColor,
            borderColor = tpBarSettings.borderColor or tpBarDefaults.borderColor,
            borderSize = tonumber(tpBarSettings.borderSize) or tpBarDefaults.borderSize,
            cornerRadius = tonumber(tpBarSettings.cornerRadius) or tpBarDefaults.cornerRadius or 0,
            anchorTo = tpBarSettings.anchorTo or tpBarDefaults.anchorTo,
            anchorPoint = tpBarSettings.anchorPoint or tpBarDefaults.anchorPoint,
            texture = tpBarSettings.texture or tpBarDefaults.texture,
            textureStrength = tonumber(tpBarSettings.textureStrength) or 100,
            textureId = barTextures.GetTextureId(tpBarSettings.texture or tpBarDefaults.texture),
            animationEnabled = tpLowActive == true and tpBarSettings.lowAnimationEnabled == true,
            animationTextureId = barAnimations.GetTextureId(tpBarSettings.lowAnimation),
            animationSpeed = tonumber(tpBarSettings.lowAnimationSpeed) or tpBarDefaults.lowAnimationSpeed,
            animationColor = tpBarSettings.lowAnimationColor,
            color2 = tpBarSettings.color2 or tpBarDefaults.color2,
            color3 = tpBarSettings.color3 or tpBarDefaults.color3,
            showAtPercent = tonumber(tpBarSettings.showAtPercent) or tpBarDefaults.showAtPercent,
            segmented = tpBarSettings.segmented ~= false,
            segmentGap = tonumber(tpBarSettings.segmentGap) or tpBarDefaults.segmentGap,
            text = BuildResourceText(tpBarSettings, 'TP', tpValue, 3000, tpPercent),
            textOffsetX = tonumber(tpBarSettings.textOffsetX) or tpBarDefaults.textOffsetX,
            textOffsetY = tonumber(tpBarSettings.textOffsetY) or tpBarDefaults.textOffsetY,
            fontFamily = fonts.GetRole(globalSettings, tpBarSettings.useSmallFont == true),
            fontFlags = fonts.GetRoleFlags(globalSettings, tpBarSettings.useSmallFont == true),
            fontSize = textScale.ToTextureFontSize(tpBarSettings.fontSize, tpBarDefaults.fontSize),
            textColor = tpBarSettings.textColor or tpBarDefaults.textColor,
            textOutlineEnabled = tpBarSettings.textOutlineEnabled == true,
            textOutlineColor = tpBarSettings.textOutlineColor or tpBarDefaults.textOutlineColor,
            textOutlineSize = tonumber(tpBarSettings.textOutlineSize) or tpBarDefaults.textOutlineSize,
        },
    };

    if (IsTargetOrSubtarget(targetStateName) == true) then
        AddDistanceToPlate(plateData, pet, distanceSettings, globalSettings);
    end
    local maneuverState = pupManeuvers.GetState();
    pupManeuvers.AddIcons(plateData, maneuverSettings, globalSettings, maneuverState);
    plateData.detachedPupName = tostring(pet.name or '');
    plateData.detachedPupTp = tpValue;
    plateData.detachedPupManeuverState = maneuverState;
    plateData.detachedPupEquipmentHead = pupEquipmentTest.head;
    plateData.detachedPupEquipmentFrame = pupEquipmentTest.frame;

    if (maneuverState.overload == true) then
        pupOverloadGaugeTest.overloaded = true;
        pupOverloadGaugeTest.overloadEnded = false;
        pupOverloadGaugeTest.overloadSeconds = tonumber(maneuverState.overloadSeconds);
        pupOverloadGaugeTest.statusSeenActive = true;
    elseif (pupOverloadGaugeTest.statusSeenActive == true) then
        pupOverloadGaugeTest.overloaded = false;
        pupOverloadGaugeTest.overloadEnded = true;
        pupOverloadGaugeTest.overloadSeconds = nil;
        pupOverloadGaugeTest.statusSeenActive = false;
    end

    if (enmity.ShouldDrawAlly(pet, globalSettings) == true) then
        enmity.AddIcon(plateData, globalSettings.enmity, 'ally');
    end

    local plateTexture, textureWidth, textureHeight = canvasTexture.Render(plateData, 'pup-pet-' .. tostring(pet.index));
    local plateTextureId = canvasTexture.GetTextureId(plateTexture);

    if (plateTextureId == nil) then
        return;
    end

    local petPlateMode = tostring(targetingSettings.pupPetPlateMode or 'Normal');
    local worldPlateTextureId = plateTextureId;
    local worldTextureWidth = textureWidth;
    local worldTextureHeight = textureHeight;
    local worldClickRects = plateData._elementRects or canvasTexture.GetElementRects(plateData);

    if (petPlateMode ~= 'Normal') then
        DrawDetachedStaticPetFrame('pup', pet.index, plateData, targetingSettings, 'static_pup_pet_' .. tostring(pet.index), pet.name);
    end

    if (petPlateMode == 'Detach from pet') then
        local nameOnlyPlateData = BuildNameOnlyPlateData(plateData, ShortenName(pet.name, nameSettings.shortenName));
        local nameTexture, nameTextureWidth, nameTextureHeight = canvasTexture.Render(nameOnlyPlateData, 'pup-pet-name-' .. tostring(pet.index));
        local nameTextureId = canvasTexture.GetTextureId(nameTexture);

        if (nameTextureId == nil) then
            return;
        end

        worldPlateTextureId = nameTextureId;
        worldTextureWidth = nameTextureWidth;
        worldTextureHeight = nameTextureHeight;
        worldClickRects = nameOnlyPlateData._elementRects or canvasTexture.GetElementRects(nameOnlyPlateData);
    end

    local plateWorldWidth, plateWorldHeight = canvasTexture.GetWorldSize(2.35, 1.18, worldTextureWidth, worldTextureHeight);

    worldMarkerProbe.QueuePlate({
        targetIndex = pet.index,
        serverId = pet.serverId,
        distance = pet.distance,
        hp = hpPercent,
        mp = mpPercent,
        tp = tpValue,
        name = '',
        isSelf = false,
        stateName = targetStateName,
        clickTargetType = 'pet',
        worldMarker = targeting.ApplyPlateScalingSettings({
            hpBar = { enabled = false },
            plateTextureId = worldPlateTextureId,
            plateAlwaysOnTop = true,
            plateTacticalOverlayOnly = true,
            anchorBone = petAnchorBone,
            plateWorldWidth = plateWorldWidth,
            plateWorldHeight = plateWorldHeight,
            plateWorldOffsetY = petWorldOffsetY,
            plateTextureWidth = worldTextureWidth,
            plateTextureHeight = worldTextureHeight,
            plateClickRects = worldClickRects,
            plateClickTargetEnabled = targetingSettings.enablePetPlateTargeting ~= false,
            clickTargetType = 'pet',
            layoutStateName = layoutStateName,
        }, 'pet', 0, petWorldOffsetY),
    });
end

local function QueueLuopan(pet)
    local layoutStateName = 'Luopan';
    local targetStateName = targeting.GetTargetStateName(pet.index);
    local nameSettings = state.GetWidgetSettings('Luopan', layoutStateName, 'Name', nameDefaults);
    local backgroundSettings = state.GetWidgetSettings('Luopan', layoutStateName, 'Background', backgroundDefaults);
    local hpBarSettings = state.GetWidgetSettings('Luopan', layoutStateName, 'HP Bar', barDefaults);
    local buffsSettings = state.GetWidgetSettings('Luopan', layoutStateName, 'Buffs', luopanBuffsDefaults);
    local distanceSettings = state.GetWidgetSettings('Luopan', layoutStateName, 'Distance', distanceDefaults);
    local targetMarker = targetModuleMarker.Build('Luopan', layoutStateName, targetStateName, hpBarSettings, pet.distance);
    local globalSettings = state.GetGlobalSettings(globalDefaults);
    local targetingSettings = targeting.GetSettings();
    local hpPercent = ClampPercent(pet.hpPercent, 100);
    local hpColor = hpBarSettings.color or barDefaults.color;
    local hpLowActive = (
        hpBarSettings.lowColorEnabled == true and
        hpPercent <= (tonumber(hpBarSettings.lowColorPercent) or 25)
    );

    if (hpLowActive == true) then
        hpColor = hpBarSettings.lowColor or hpColor;
    end

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
            imageOpacity = backgroundSettings.imageOpacity or backgroundDefaults.imageOpacity,
            anchorTo = backgroundSettings.anchorTo or backgroundDefaults.anchorTo,
            anchorPoint = backgroundSettings.anchorPoint or backgroundDefaults.anchorPoint,
        },
        name = (nameSettings.enabled == true) and ShortenName(pet.name, nameSettings.shortenName) or '',
        nameFontFamily = fonts.GetRole(globalSettings, false),
        nameFontFlags = fonts.GetRoleFlags(globalSettings, false),
        nameFontSize = textScale.ToNameTextureFontSize(nameSettings.textSize, nameDefaults.textSize),
        nameColor = nameSettings.color or nameDefaults.color,
        nameOutlineEnabled = (tonumber(nameSettings.outlineSize) or 0) > 0,
        nameOutlineColor = nameSettings.outlineColor or nameDefaults.outlineColor,
        nameOutlineSize = tonumber(nameSettings.outlineSize) or 0,
        nameOffsetX = ClampTextureOffset(tonumber(nameSettings.offsetX) or nameDefaults.offsetX, 1024, 24),
        nameOffsetY = ClampTextureOffset(tonumber(nameSettings.offsetY) or nameDefaults.offsetY, luopanCanvasHeight, 24),
        nameAnchorTo = nameSettings.anchorTo or nameDefaults.anchorTo,
        nameAnchorPoint = nameSettings.anchorPoint or nameDefaults.anchorPoint,
        hpBar = {
            enabled = hpBarSettings.enabled == true,
            width = tonumber(hpBarSettings.width) or barDefaults.width,
            height = tonumber(hpBarSettings.height) or barDefaults.height,
            offsetX = tonumber(hpBarSettings.offsetX) or barDefaults.offsetX,
            offsetY = tonumber(hpBarSettings.offsetY) or barDefaults.offsetY,
            color = hpColor,
            backgroundColor = hpBarSettings.backgroundColor or barDefaults.backgroundColor,
            borderColor = hpBarSettings.borderColor or barDefaults.borderColor,
            borderSize = tonumber(hpBarSettings.borderSize) or barDefaults.borderSize,
            cornerRadius = tonumber(hpBarSettings.cornerRadius) or barDefaults.cornerRadius or 0,
            anchorTo = hpBarSettings.anchorTo or barDefaults.anchorTo,
            anchorPoint = hpBarSettings.anchorPoint or barDefaults.anchorPoint,
            texture = hpBarSettings.texture or barDefaults.texture,
            textureStrength = tonumber(hpBarSettings.textureStrength) or 100,
            textureId = barTextures.GetTextureId(hpBarSettings.texture or barDefaults.texture),
            animationEnabled = hpLowActive == true and hpBarSettings.lowAnimationEnabled == true,
            animationTextureId = barAnimations.GetTextureId(hpBarSettings.lowAnimation),
            animationSpeed = tonumber(hpBarSettings.lowAnimationSpeed) or barDefaults.lowAnimationSpeed,
            animationColor = hpBarSettings.lowAnimationColor,
            showAtPercent = tonumber(hpBarSettings.showAtPercent) or barDefaults.showAtPercent,
            text = BuildPercentFallbackResourceText(hpBarSettings, 'HP', pet.hp, pet.maxHp, hpPercent),
            textOffsetX = tonumber(hpBarSettings.textOffsetX) or barDefaults.textOffsetX,
            textOffsetY = tonumber(hpBarSettings.textOffsetY) or barDefaults.textOffsetY,
            fontFamily = fonts.GetRole(globalSettings, hpBarSettings.useSmallFont == true),
            fontFlags = fonts.GetRoleFlags(globalSettings, hpBarSettings.useSmallFont == true),
            fontSize = textScale.ToTextureFontSize(hpBarSettings.fontSize, barDefaults.fontSize),
            textColor = hpBarSettings.textColor or barDefaults.textColor,
            textOutlineEnabled = hpBarSettings.textOutlineEnabled == true,
            textOutlineColor = hpBarSettings.textOutlineColor or barDefaults.textOutlineColor,
            textOutlineSize = tonumber(hpBarSettings.textOutlineSize) or barDefaults.textOutlineSize,
        },
        mpBar = { enabled = false },
        tpBar = { enabled = false },
        canvasHeight = luopanCanvasHeight,
    };

    if (IsTargetOrSubtarget(targetStateName) == true) then
        AddDistanceToPlate(plateData, pet, distanceSettings, globalSettings);
    end
    AddStatusIconsToPlate(plateData, luopanStatuses.GetRows('buff'), buffsSettings, globalSettings, 'buffs');

    local plateTexture, textureWidth, textureHeight = canvasTexture.Render(plateData, 'luopan-' .. tostring(pet.index));
    local plateTextureId = canvasTexture.GetTextureId(plateTexture);

    if (plateTextureId == nil) then
        return;
    end

    local plateWorldWidth, plateWorldHeight = canvasTexture.GetWorldSize(2.35, luopanPlateWorldHeight, textureWidth, textureHeight);

    worldMarkerProbe.QueuePlate({
        targetIndex = pet.index,
        serverId = pet.serverId,
        distance = pet.distance,
        hp = hpPercent,
        name = '',
        isSelf = false,
        stateName = targetStateName,
        clickTargetType = 'pet',
        worldMarker = targeting.ApplyPlateScalingSettings({
            hpBar = { enabled = false },
            plateTextureId = plateTextureId,
            plateAlwaysOnTop = true,
            plateTacticalOverlayOnly = true,
            anchorBone = petAnchorBone,
            plateWorldWidth = plateWorldWidth,
            plateWorldHeight = plateWorldHeight,
            plateWorldOffsetY = luopanWorldOffsetY,
            plateTextureWidth = textureWidth,
            plateTextureHeight = textureHeight,
            plateClickRects = plateData._elementRects or canvasTexture.GetElementRects(plateData),
            plateClickTargetEnabled = targetingSettings.enablePetPlateTargeting ~= false,
            clickTargetType = 'pet',
            layoutStateName = layoutStateName,
        }, 'pet', 0, luopanWorldOffsetY),
    });
end

function petPlate.Build()
    return nil;
end

function petPlate.SetAnchorBone(value)
    local bone = math.floor(tonumber(value) or petAnchorBone);

    if (bone < 0) then
        bone = 0;
    elseif (bone > 32) then
        bone = 32;
    end

    petAnchorBone = bone;
end

function petPlate.GetAnchorBone()
    return petAnchorBone;
end

function petPlate.SetWorldOffsetY(value)
    petWorldOffsetY = tonumber(value) or petWorldOffsetY;
end

function petPlate.GetWorldOffsetY()
    return petWorldOffsetY;
end

function petPlate.ResetPositionDebug()
    petAnchorBone = 12;
    petWorldOffsetY = 0.16;
end

function petPlate.GetPositionDebugText()
    return 'Pet plate position bone=' .. tostring(petAnchorBone) .. ' offsetY=' .. tostring(petWorldOffsetY);
end

function petPlate.Render()
    local detachedPreviewPrefix = DrawQueuedDetachedSetupPreview();

    if (state.GetWorldEnabled() ~= true) then
        return;
    end

    if (worldDepthPlate.IsEnabled() == true) then
        return;
    end

    if (worldMarkerProbe.GetEnabled() ~= true or worldMarkerProbe.GetReplacePlates() ~= true) then
        return;
    end

    local pet = entities.GetOwnBstPet();
    local layoutStateName = pet ~= nil and GetBstStateName(pet) or nil;
    petState.SyncPet(pet);
    bstCharmTimer.SyncPet(pet, layoutStateName == 'Charmed Pet');

    if (pet ~= nil) then
        QueueBstPet(pet);
    end

    local smnPet = entities.GetOwnSmnPet();
    -- Keep Favor's local charge clock current even while no Avatar is out so
    -- the meter pauses cleanly between summons instead of gaining that time.
    UpdateAvatarFavorCharge(smnPet);

    if (smnPet ~= nil) then
        QueueSmnPet(smnPet);
    elseif (detachedPreviewPrefix ~= 'smn') then
        local targetingSettings = targeting.GetSettings();
        if (
            IsPlayerOnSmn() == true and
            targetingSettings ~= nil and
            tostring(GetDetachedPetSetting(targetingSettings, 'smn', 'smnAvatar', 'PetPlateMode') or 'Normal') ~= 'Normal'
        ) then
            local placeholderPlate = BuildSmnDetachedPlaceholderPlate();
            placeholderPlate.detachedAvatarBars = BuildDetachedSmnMeterSources(nil);
            placeholderPlate.detachedAvatarFavorActive = select(1, GetAvatarFavorStatusElapsed());
            placeholderPlate.detachedAvatarFavorCooldownSeconds = GetAvatarFavorCooldownSeconds();
            placeholderPlate.detachedAvatarHasPet = false;
            DrawSmnDetachedPlaceholder(targetingSettings, placeholderPlate);
        end
    end

    local drgPet = entities.GetOwnDrgPet();

    if (drgPet ~= nil) then
        QueueWyvernPet(drgPet);
    end

    local pupPet = entities.GetOwnPupPet();

    if (pupPet ~= nil) then
        QueuePupPet(pupPet);
    else
        if (pupEquipmentTest.summonActive == true) then
            pupOverloadGaugeTest.chance = nil;
            pupOverloadGaugeTest.element = nil;
            pupOverloadGaugeTest.burdens = {};
        end
        pupEquipmentTest.summonActive = false;
        pupEquipmentTest.head = nil;
        pupEquipmentTest.frame = nil;
    end

    local luopan = entities.GetOwnLuopan();

    if (luopan ~= nil) then
        QueueLuopan(luopan);
    end
end

return petPlate;
