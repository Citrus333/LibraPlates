require('common');

local textureLoader = require('core.texture_loader');

local crafting = {};
local iconTextureIds = {};
local state = {
    active = false,
    result = nil,
};

local iconFiles = {
    normal = 'craft_01.png',
    hq = 'craft_02.png',
    breakResult = 'craft_03.png',
};

local resultLabels = {
    normal = 'Normal Quality',
    hq = 'High-Quality',
    breakResult = 'Break',
};

local resultChoices = T{
    'Normal Quality',
    'High-Quality',
    'Break',
};

local function NormalizeResult(result)
    result = tostring(result or '');

    if (result == 'break') then
        return 'breakResult';
    end

    if (result == 'normal' or result == 'hq' or result == 'breakResult') then
        return result;
    end

    if (result == 'Normal Quality') then
        return 'normal';
    end

    if (result == 'High-Quality') then
        return 'hq';
    end

    if (result == 'Break') then
        return 'breakResult';
    end

    return nil;
end

local function SetResultFromAnimationId(animationId)
    animationId = tonumber(animationId);

    if (animationId == 0) then
        state.result = 'normal';
        return;
    end

    if (animationId == 1) then
        state.result = 'breakResult';
        return;
    end

    if (animationId == 2 or animationId == 3 or animationId == 4) then
        state.result = 'hq';
        return;
    end

    state.result = nil;
end

local function Read(data, format, offset)
    if (data == nil) then
        return nil;
    end

    local ok, value = pcall(function()
        return struct.unpack(format, data, offset + 1);
    end);

    if (ok ~= true) then
        return nil;
    end

    return value;
end

function crafting.HandlePacketIn(e)
    if (e == nil) then
        return;
    end

    if (e.id == 0x0030) then
        local data = e.data_modified or e.data;
        local player = GetPlayerEntity();
        local targetIndex = Read(data, 'H', 0x08);

        if (player ~= nil and targetIndex ~= nil and player.TargetIndex == targetIndex) then
            state.active = true;
            SetResultFromAnimationId(Read(data, 'b', 0x0C));
        end

        return;
    end

    if (e.id == 0x006F) then
        state.active = false;
        state.result = nil;
    end
end

function crafting.IsCraftingStatus(status)
    return tonumber(status) == 44;
end

function crafting.IsActive()
    return state.active == true;
end

function crafting.ClearResult()
    state.active = false;
    state.result = nil;
end

function crafting.GetResult()
    return state.result;
end

function crafting.GetTextForResult(result)
    local key = NormalizeResult(result);

    if (key == nil) then
        return nil;
    end

    return resultLabels[key];
end

function crafting.GetText()
    return crafting.GetTextForResult(state.result);
end

local function GetIconTextureId(result)
    local key = NormalizeResult(result);

    if (key == nil) then
        return nil;
    end

    if (iconTextureIds[key] ~= nil) then
        return iconTextureIds[key];
    end

    local path = addon.path .. '\\assets\\images\\crafting\\' .. iconFiles[key];
    iconTextureIds[key] = textureLoader.ToTextureId(textureLoader.Load(path));
    return iconTextureIds[key];
end

function crafting.GetResultChoices()
    return resultChoices;
end

function crafting.GetTextureId(settings)
    settings = settings or {};

    local result = state.result;

    if (result == nil and settings.previewResult ~= true) then
        return nil;
    end

    return GetIconTextureId(result or NormalizeResult(settings.previewResultName) or 'hq');
end

function crafting.AddWidget(plateData, settings)
    settings = settings or {};

    if (plateData == nil or settings.enabled == false) then
        return;
    end

    local result = state.result;
    local previewResult = NormalizeResult(settings.previewResultName) or 'hq';
    local text = crafting.GetTextForResult(result or (settings.previewResult == true and previewResult or nil));

    if (text == nil or text == '') then
        return;
    end

    if (tostring(settings.displayMode or 'Icon') == 'Text') then
        plateData.texts = plateData.texts or {};
        plateData.texts[#plateData.texts + 1] = {
            kind = 'crafting',
            text = text,
            align = 'center',
            offsetX = tonumber(settings.offsetX) or 0,
            offsetY = tonumber(settings.offsetY) or 38,
            fontSize = math.max(6, tonumber(settings.textFontSize) or 14),
            color = settings.textColor or { 1.0, 1.0, 1.0, 1.0 },
            outlineEnabled = (tonumber(settings.textOutlineSize) or 2) > 0,
            outlineColor = settings.textOutlineColor or { 0.0, 0.0, 0.0, 1.0 },
            outlineSize = tonumber(settings.textOutlineSize) or 2,
        };
        return;
    end

    local textureId = crafting.GetTextureId(settings);

    if (textureId == nil) then
        return;
    end

    plateData.icons = plateData.icons or {};
    plateData.icons[#plateData.icons + 1] = {
        kind = 'crafting',
        textureId = textureId,
        size = math.max(6, math.min(200, tonumber(settings.iconSize) or 42)),
        offsetX = tonumber(settings.offsetX) or 0,
        offsetY = tonumber(settings.offsetY) or 38,
        timerText = (settings.showLabel ~= false) and text or '',
        timerFontSize = math.max(4, tonumber(settings.labelFontSize) or 12),
        timerTextColor = settings.labelColor or { 1.0, 1.0, 1.0, 1.0 },
        timerTextOutline = (tonumber(settings.labelOutlineSize) or 2) > 0,
        timerTextOutlineColor = settings.labelOutlineColor or { 0.0, 0.0, 0.0, 1.0 },
        timerTextOutlineSize = tonumber(settings.labelOutlineSize) or 2,
        timerOffsetY = tonumber(settings.labelOffsetY) or 0,
    };
end

return crafting;
