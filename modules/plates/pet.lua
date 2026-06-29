local backgroundDefaults = require('config.widgets.background');
local imgui = require('imgui');
local nameDefaults = require('config.widgets.name');
local barDefaults = require('config.widgets.bar');
local mpBarDefaults = require('config.widgets.mp_bar');
local tpBarDefaults = require('config.widgets.tp_bar');
local distanceDefaults = require('config.widgets.distance');
local castBarDefaults = require('config.widgets.cast_bar');
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
local targetModuleMarker = require('core.target_module_marker');
local worldDepthPlate = require('core.world_depth_plate');
local worldMarkerProbe = require('core.world_marker_probe');

local petPlate = {};
local bstPetTimer = {};
local jugIconTextureId = nil;
local petStateIconTextureIds = {};
local staticPanelEditDrag = nil;
local DrawStaticPlateTexture = nil;
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

    local jobFolder = (key == 'ward' or key == 'rage') and 'smn' or 'bst';
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

local function BuildStaticPetBackground(targetingSettings, prefix, plateBackground, staticScale)
    local settings = targetingSettings[prefix .. 'PetStaticBackgroundSettings'];
    if (type(settings) ~= 'table') then
        local defaults = (globalDefaults.targeting or {})[prefix .. 'PetStaticBackgroundSettings'];
        settings = type(defaults) == 'table' and defaults or plateBackground or backgroundDefaults;
    end

    local scaleInverse = 1 / math.max(0.10, tonumber(staticScale) or 1.0);

    return {
        enabled = settings.enabled ~= false,
        width = (tonumber(settings.width) or backgroundDefaults.width) * scaleInverse,
        height = (tonumber(settings.height) or backgroundDefaults.height) * scaleInverse,
        offsetX = (tonumber(settings.offsetX) or backgroundDefaults.offsetX) * scaleInverse,
        offsetY = (tonumber(settings.offsetY) or backgroundDefaults.offsetY) * scaleInverse,
        color = settings.color or backgroundDefaults.color,
        borderColor = settings.borderColor or backgroundDefaults.borderColor,
        borderSize = (tonumber(settings.borderSize) or backgroundDefaults.borderSize) * scaleInverse,
        texture = settings.texture or backgroundDefaults.texture,
        textureId = backgroundTextures.GetTextureId(settings.texture or backgroundDefaults.texture),
    };
end

local function BuildStaticPetTextureKey(prefix, petIndex, background)
    return table.concat({
        tostring(prefix) .. '-pet-static',
        tostring(petIndex),
        'bg=' .. tostring(background.enabled),
        'w=' .. tostring(background.width),
        'h=' .. tostring(background.height),
        'x=' .. tostring(background.offsetX),
        'y=' .. tostring(background.offsetY),
        'tex=' .. tostring(background.texture),
        'color=' .. ColorKey(background.color),
        'border=' .. ColorKey(background.borderColor),
        'bs=' .. tostring(background.borderSize),
    }, '|');
end

local function DrawDetachedStaticPetFrame(prefix, petIndex, plateData, targetingSettings, windowId)
    local staticScale = math.max(0.10, math.min(2.00, (tonumber(targetingSettings[prefix .. 'PetStaticScale']) or 35) / 100));
    local staticBackground = BuildStaticPetBackground(targetingSettings, prefix, plateData.background, staticScale);
    local staticPlateData = CopySettingsWith(plateData, {
        background = staticBackground,
    });
    local staticTexture, staticTextureWidth, staticTextureHeight = canvasTexture.Render(staticPlateData, BuildStaticPetTextureKey(prefix, petIndex, staticBackground));
    local staticTextureId = canvasTexture.GetTextureId(staticTexture);

    if (staticTextureId == nil or staticTextureWidth == nil or staticTextureHeight == nil) then
        return;
    end

    DrawStaticPlateTexture(
        staticTextureId,
        tonumber(targetingSettings[prefix .. 'PetStaticX']) or 170,
        tonumber(targetingSettings[prefix .. 'PetStaticY']) or 690,
        staticTextureWidth * staticScale,
        staticTextureHeight * staticScale,
        windowId,
        targetingSettings[prefix .. 'PetStaticEditFrame'] == true,
        function(nextX, nextY, nextW)
            targetingSettings[prefix .. 'PetStaticX'] = nextX;
            targetingSettings[prefix .. 'PetStaticY'] = nextY;
            targetingSettings[prefix .. 'PetStaticScale'] = math.max(10, math.min(200, math.floor(((tonumber(nextW) or staticTextureWidth) / math.max(1, staticTextureWidth) * 100) + 0.5)));
            state.Save();
        end
    );
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
local maneuverDefaults = require('config.widgets.maneuvers');

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

local function BuildPercentFallbackResourceText(settings, label, value, maxValue, percent)
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
        text = tostring(distanceSettings.prefix or '') .. string.format('%.1f', distance),
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
        color = settings.color or defaults.color,
        backgroundColor = settings.backgroundColor or defaults.backgroundColor,
        borderColor = settings.borderColor or defaults.borderColor,
        borderSize = tonumber(settings.borderSize) or defaults.borderSize,
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

local function DrawStaticPanelEditOverlay(windowId, left, top, width, height, onEdited)
    if (
        imgui.GetForegroundDrawList == nil or
        imgui.GetColorU32 == nil or
        imgui.IsMouseClicked == nil or
        imgui.IsMouseDown == nil
    ) then
        return;
    end

    local id = tostring(windowId or 'static_pet');
    local handleSize = 18;
    local x = tonumber(left) or 0;
    local y = tonumber(top) or 0;
    local w = math.max(1, tonumber(width) or 1);
    local h = math.max(1, tonumber(height) or 1);
    local mouseX, mouseY = GetMousePosition();

    if (mouseX ~= nil and mouseY ~= nil and imgui.IsMouseClicked(0) == true) then
        staticPanelEditDrag = nil;

        local inRect = mouseX >= x and mouseX <= x + w and mouseY >= y and mouseY <= y + h;
        local inRightHandle = mouseX >= x + w - handleSize and mouseX <= x + w and mouseY >= y + h - handleSize and mouseY <= y + h;
        local inLeftHandle = mouseX >= x and mouseX <= x + handleSize and mouseY >= y + h - handleSize and mouseY <= y + h;

        if (inRightHandle == true or inLeftHandle == true or inRect == true) then
            staticPanelEditDrag = {
                id = id,
                mode = inRightHandle == true and 'resize-right' or (inLeftHandle == true and 'resize-left' or 'move'),
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
            if (staticPanelEditDrag.mode == 'move') then
                onEdited(math.floor(x + (w * 0.5) + dx + 0.5), math.floor(y + (h * 0.5) + dy + 0.5), w);
            elseif (staticPanelEditDrag.mode == 'resize-left') then
                local right = x + w;
                local nextW = math.max(20, w - dx);
                onEdited(math.floor(right - (nextW * 0.5) + 0.5), math.floor(y + (h * 0.5) + 0.5), nextW);
            else
                local nextW = math.max(20, w + dx);
                onEdited(math.floor(x + (nextW * 0.5) + 0.5), math.floor(y + (h * 0.5) + 0.5), nextW);
            end

            if (imgui.ResetMouseDragDelta ~= nil) then
                imgui.ResetMouseDragDelta(0);
            end
        end
    end

    local drawList = imgui.GetForegroundDrawList();
    if (drawList == nil) then
        return;
    end

    local fillColor = imgui.GetColorU32({ 1.0, 0.80, 0.10, 0.28 });
    local borderColor = imgui.GetColorU32({ 1.0, 0.80, 0.10, 1.0 });
    local textColor = imgui.GetColorU32({ 1.0, 1.0, 1.0, 1.0 });
    local handleColor = imgui.GetColorU32({ 1.0, 1.0, 1.0, 0.82 });

    drawList:AddRectFilled({ x, y }, { x + w, y + h }, fillColor);
    drawList:AddRect({ x, y }, { x + w, y + h }, borderColor, 0, 0, 4);

    if (drawList.AddTriangleFilled ~= nil) then
        drawList:AddTriangleFilled(
            { x + w, y + h - handleSize },
            { x + w, y + h },
            { x + w - handleSize, y + h },
            handleColor
        );
        drawList:AddTriangleFilled(
            { x, y + h - handleSize },
            { x, y + h },
            { x + handleSize, y + h },
            handleColor
        );
        drawList:AddTriangle({ x + w, y + h - handleSize }, { x + w, y + h }, { x + w - handleSize, y + h }, borderColor, 2);
        drawList:AddTriangle({ x, y + h - handleSize }, { x, y + h }, { x + handleSize, y + h }, borderColor, 2);
    else
        drawList:AddRectFilled({ x + w - handleSize, y + h - handleSize }, { x + w, y + h }, handleColor);
        drawList:AddRect({ x + w - handleSize, y + h - handleSize }, { x + w, y + h }, borderColor, 0, 0, 2);
        drawList:AddRectFilled({ x, y + h - handleSize }, { x + handleSize, y + h }, handleColor);
        drawList:AddRect({ x, y + h - handleSize }, { x + handleSize, y + h }, borderColor, 0, 0, 2);
    end

    if (drawList.AddText ~= nil) then
        drawList:AddText({ x + 6, y + 6 }, textColor, 'Detached avatar');
    end
end

DrawStaticPlateTexture = function(textureId, centerX, centerY, width, height, windowId, editEnabled, onEdited)
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

        imgui.Image(textureId, { drawW, drawH }, { 0, 0 }, { 1, 1 });

    end

    imgui.End();

    if (pushedPadding == true and imgui.PopStyleVar ~= nil) then
        imgui.PopStyleVar();
    end

    if (editEnabled == true) then
        DrawStaticPanelEditOverlay(windowId, left, top, drawW, drawH, onEdited);
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
    hpBarSettings.showValue = false;

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
            anchorTo = hpBarSettings.anchorTo or barDefaults.anchorTo,
            anchorPoint = hpBarSettings.anchorPoint or barDefaults.anchorPoint,
            texture = hpBarSettings.texture or 'Solid',
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
            anchorTo = tpBarSettings.anchorTo or tpBarDefaults.anchorTo,
            anchorPoint = tpBarSettings.anchorPoint or tpBarDefaults.anchorPoint,
            texture = tpBarSettings.texture or 'Solid',
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
        DrawDetachedStaticPetFrame('bst', pet.index, plateData, targetingSettings, 'static_bst_pet_' .. tostring(pet.index));
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
            plateWorldWidth = 2.35,
            plateWorldHeight = 1.18,
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

    if (layoutStateName == 'Spirit') then
        castBar, castPercent = BuildCastBar(enemyCasts.GetActiveCast(pet.serverId), castBarSettings, globalSettings);
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
            anchorTo = hpBarSettings.anchorTo or smnHpBarDefaults.anchorTo,
            anchorPoint = hpBarSettings.anchorPoint or smnHpBarDefaults.anchorPoint,
            texture = hpBarSettings.texture or smnHpBarDefaults.texture,
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
            anchorTo = mpBarSettings.anchorTo or smnMpBarDefaults.anchorTo,
            anchorPoint = mpBarSettings.anchorPoint or smnMpBarDefaults.anchorPoint,
            texture = mpBarSettings.texture or smnMpBarDefaults.texture,
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
            anchorTo = tpBarSettings.anchorTo or smnTpBarDefaults.anchorTo,
            anchorPoint = tpBarSettings.anchorPoint or smnTpBarDefaults.anchorPoint,
            texture = tpBarSettings.texture or smnTpBarDefaults.texture,
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

    if (enmity.ShouldDrawAlly(pet, globalSettings) == true) then
        enmity.AddIcon(plateData, globalSettings.enmity, 'ally');
    end

    local plateTexture, textureWidth, textureHeight = canvasTexture.Render(plateData, 'smn-pet-' .. tostring(pet.index));
    local plateTextureId = canvasTexture.GetTextureId(plateTexture);

    if (plateTextureId == nil) then
        return;
    end

    local petPlateMode = tostring(targetingSettings.smnPetPlateMode or 'Normal');
    local worldPlateTextureId = plateTextureId;
    local worldTextureWidth = textureWidth;
    local worldTextureHeight = textureHeight;
    local worldClickRects = plateData._elementRects or canvasTexture.GetElementRects(plateData);

    if (petPlateMode ~= 'Normal') then
        DrawDetachedStaticPetFrame('smn', pet.index, plateData, targetingSettings, 'static_smn_pet_' .. tostring(pet.index));
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
            plateWorldWidth = 2.35,
            plateWorldHeight = 1.18,
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
            anchorTo = hpBarSettings.anchorTo or barDefaults.anchorTo,
            anchorPoint = hpBarSettings.anchorPoint or barDefaults.anchorPoint,
            texture = hpBarSettings.texture or barDefaults.texture,
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
            anchorTo = tpBarSettings.anchorTo or tpBarDefaults.anchorTo,
            anchorPoint = tpBarSettings.anchorPoint or tpBarDefaults.anchorPoint,
            texture = tpBarSettings.texture or tpBarDefaults.texture,
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
        DrawDetachedStaticPetFrame('drg', pet.index, plateData, targetingSettings, 'static_drg_pet_' .. tostring(pet.index));
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
            plateWorldWidth = 2.35,
            plateWorldHeight = 1.18,
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
            anchorTo = hpBarSettings.anchorTo or barDefaults.anchorTo,
            anchorPoint = hpBarSettings.anchorPoint or barDefaults.anchorPoint,
            texture = hpBarSettings.texture or barDefaults.texture,
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
            anchorTo = mpBarSettings.anchorTo or mpBarDefaults.anchorTo,
            anchorPoint = mpBarSettings.anchorPoint or mpBarDefaults.anchorPoint,
            texture = mpBarSettings.texture or mpBarDefaults.texture,
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
            anchorTo = tpBarSettings.anchorTo or tpBarDefaults.anchorTo,
            anchorPoint = tpBarSettings.anchorPoint or tpBarDefaults.anchorPoint,
            texture = tpBarSettings.texture or tpBarDefaults.texture,
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
    pupManeuvers.AddIcons(plateData, maneuverSettings, globalSettings);

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
        DrawDetachedStaticPetFrame('pup', pet.index, plateData, targetingSettings, 'static_pup_pet_' .. tostring(pet.index));
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
            plateWorldWidth = 2.35,
            plateWorldHeight = 1.18,
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
            anchorTo = hpBarSettings.anchorTo or barDefaults.anchorTo,
            anchorPoint = hpBarSettings.anchorPoint or barDefaults.anchorPoint,
            texture = hpBarSettings.texture or barDefaults.texture,
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
            plateWorldWidth = 2.35,
            plateWorldHeight = luopanPlateWorldHeight,
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

    if (smnPet ~= nil) then
        QueueSmnPet(smnPet);
    end

    local drgPet = entities.GetOwnDrgPet();

    if (drgPet ~= nil) then
        QueueWyvernPet(drgPet);
    end

    local pupPet = entities.GetOwnPupPet();

    if (pupPet ~= nil) then
        QueuePupPet(pupPet);
    end

    local luopan = entities.GetOwnLuopan();

    if (luopan ~= nil) then
        QueueLuopan(luopan);
    end
end

return petPlate;
