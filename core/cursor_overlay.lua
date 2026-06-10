local imgui = require('imgui');
local state = require('core.state');
local globalDefaults = require('config.global');

local cursorOverlay = {};
local mouseX = nil;
local mouseY = nil;
local mouseDeltaX = 0;
local mouseDeltaY = 0;

local function Clamp(value, minValue, maxValue, fallback)
    value = tonumber(value) or fallback;
    return math.max(minValue, math.min(maxValue, value));
end

local function GetSettings()
    local global = state.GetGlobalSettings(globalDefaults);

    if (global.cursorOverlay == nil) then
        global.cursorOverlay = {};
    end

    local settings = global.cursorOverlay;
    local defaults = globalDefaults.cursorOverlay or {};

    if (settings.enabled == nil) then settings.enabled = defaults.enabled == true; end
    if (settings.shape == nil) then settings.shape = defaults.shape or 'Ring'; end
    if (settings.radius == nil) then settings.radius = defaults.radius or 13; end
    if (settings.trailLagReduction == nil) then settings.trailLagReduction = defaults.trailLagReduction or 0; end
    if (settings.showCenterMark == nil) then settings.showCenterMark = defaults.showCenterMark == true; end
    if (settings.outerEnabled == nil) then settings.outerEnabled = defaults.outerEnabled ~= false; end
    if (settings.innerEnabled == nil) then settings.innerEnabled = defaults.innerEnabled ~= false; end
    if (settings.centerEnabled == nil) then settings.centerEnabled = settings.showCenterMark == true or defaults.centerEnabled == true; end
    if (settings.ringColor == nil) then settings.ringColor = { unpack(defaults.ringColor or { 1.0, 1.0, 1.0, 1.0 }) }; end
    if (settings.accentColor == nil) then settings.accentColor = { unpack(defaults.accentColor or { 0.17, 0.84, 0.87, 1.0 }) }; end
    if (settings.centerColor == nil) then settings.centerColor = { unpack(defaults.centerColor or settings.accentColor or { 0.17, 0.84, 0.87, 1.0 }) }; end

    settings.radius = Clamp(settings.radius, 4, 48, defaults.radius or 13);
    settings.trailLagReduction = Clamp(settings.trailLagReduction, 0, 100, defaults.trailLagReduction or 0);

    if (settings.outerEnabled ~= true and settings.innerEnabled ~= true and settings.centerEnabled ~= true) then
        settings.outerEnabled = true;
    end

    return settings;
end

local function ColorToU32(color, fallback)
    color = color or fallback or { 1.0, 1.0, 1.0, 1.0 };

    local r = Clamp(color[1], 0, 1, fallback ~= nil and fallback[1] or 1);
    local g = Clamp(color[2], 0, 1, fallback ~= nil and fallback[2] or 1);
    local b = Clamp(color[3], 0, 1, fallback ~= nil and fallback[3] or 1);
    local a = Clamp(color[4], 0, 1, fallback ~= nil and fallback[4] or 1);

    return math.floor(a * 255) * 0x1000000
        + math.floor(b * 255) * 0x10000
        + math.floor(g * 255) * 0x100
        + math.floor(r * 255);
end

function cursorOverlay.GetSettings()
    return GetSettings();
end

function cursorOverlay.SetEnabled(value)
    GetSettings().enabled = value == true;
end

function cursorOverlay.GetEnabled()
    return GetSettings().enabled == true;
end

function cursorOverlay.Toggle()
    local settings = GetSettings();
    settings.enabled = settings.enabled ~= true;
    return settings.enabled;
end

function cursorOverlay.HandleMouse(e)
    if (e == nil or tonumber(e.message) ~= 512) then
        return;
    end

    local nextX = tonumber(e.x);
    local nextY = tonumber(e.y);

    if (nextX == nil or nextY == nil) then
        return;
    end

    if (mouseX ~= nil and mouseY ~= nil) then
        mouseDeltaX = math.max(-64, math.min(64, nextX - mouseX));
        mouseDeltaY = math.max(-64, math.min(64, nextY - mouseY));
    else
        mouseDeltaX = 0;
        mouseDeltaY = 0;
    end

    mouseX = nextX;
    mouseY = nextY;
end

function cursorOverlay.Render()
    local settings = GetSettings();

    if (settings.enabled ~= true or mouseX == nil or mouseY == nil) then
        return;
    end

    local drawList = nil;

    pcall(function()
        drawList = imgui.GetForegroundDrawList ~= nil and imgui.GetForegroundDrawList() or imgui.GetWindowDrawList();
    end);

    if (drawList == nil) then
        return;
    end

    local trailLagReduction = Clamp(settings.trailLagReduction, 0, 100, 0) / 100;
    local x = mouseX + (mouseDeltaX * trailLagReduction);
    local y = mouseY + (mouseDeltaY * trailLagReduction);
    local shadow = 0xAA000000;
    local ring = ColorToU32(settings.ringColor, { 1.0, 1.0, 1.0, 1.0 });
    local accent = ColorToU32(settings.accentColor, { 0.17, 0.84, 0.87, 1.0 });
    local centerColor = ColorToU32(settings.centerColor, { 0.17, 0.84, 0.87, 1.0 });
    local radius = Clamp(settings.radius, 4, 48, 13);
    local shape = tostring(settings.shape or 'Ring');
    local drawOuter = settings.outerEnabled == true;
    local drawInner = settings.innerEnabled == true;

    if (shape == 'Diamond') then
        if (drawOuter == true) then
            drawList:AddLine({ x + 1, y - radius + 1 }, { x + radius + 1, y + 1 }, shadow, 4);
            drawList:AddLine({ x + radius + 1, y + 1 }, { x + 1, y + radius + 1 }, shadow, 4);
            drawList:AddLine({ x + 1, y + radius + 1 }, { x - radius + 1, y + 1 }, shadow, 4);
            drawList:AddLine({ x - radius + 1, y + 1 }, { x + 1, y - radius + 1 }, shadow, 4);
            drawList:AddLine({ x, y - radius }, { x + radius, y }, ring, 2);
            drawList:AddLine({ x + radius, y }, { x, y + radius }, ring, 2);
            drawList:AddLine({ x, y + radius }, { x - radius, y }, ring, 2);
            drawList:AddLine({ x - radius, y }, { x, y - radius }, ring, 2);
        end
        if (drawInner == true) then
            drawList:AddCircle({ x, y }, math.max(3, radius * 0.35), accent, 16, 1);
        end
    elseif (shape == 'Corners') then
        local gap = math.max(3, radius * 0.35);
        local len = math.max(4, radius * 0.55);
        local outer = radius;
        local inner = radius - len;
        if (drawOuter == true) then
            drawList:AddLine({ x - outer + 1, y - outer + 1 }, { x - inner + 1, y - outer + 1 }, shadow, 4);
            drawList:AddLine({ x - outer + 1, y - outer + 1 }, { x - outer + 1, y - inner + 1 }, shadow, 4);
            drawList:AddLine({ x + outer + 1, y - outer + 1 }, { x + inner + 1, y - outer + 1 }, shadow, 4);
            drawList:AddLine({ x + outer + 1, y - outer + 1 }, { x + outer + 1, y - inner + 1 }, shadow, 4);
            drawList:AddLine({ x - outer + 1, y + outer + 1 }, { x - inner + 1, y + outer + 1 }, shadow, 4);
            drawList:AddLine({ x - outer + 1, y + outer + 1 }, { x - outer + 1, y + inner + 1 }, shadow, 4);
            drawList:AddLine({ x + outer + 1, y + outer + 1 }, { x + inner + 1, y + outer + 1 }, shadow, 4);
            drawList:AddLine({ x + outer + 1, y + outer + 1 }, { x + outer + 1, y + inner + 1 }, shadow, 4);
            drawList:AddLine({ x - outer, y - outer }, { x - inner, y - outer }, ring, 2);
            drawList:AddLine({ x - outer, y - outer }, { x - outer, y - inner }, ring, 2);
            drawList:AddLine({ x + outer, y - outer }, { x + inner, y - outer }, ring, 2);
            drawList:AddLine({ x + outer, y - outer }, { x + outer, y - inner }, ring, 2);
            drawList:AddLine({ x - outer, y + outer }, { x - inner, y + outer }, ring, 2);
            drawList:AddLine({ x - outer, y + outer }, { x - outer, y + inner }, ring, 2);
            drawList:AddLine({ x + outer, y + outer }, { x + inner, y + outer }, ring, 2);
            drawList:AddLine({ x + outer, y + outer }, { x + outer, y + inner }, ring, 2);
        end
        if (drawInner == true) then
            drawList:AddCircle({ x, y }, gap, accent, 16, 1);
        end
    elseif (shape == 'Dot Ring') then
        if (drawInner == true) then
            drawList:AddCircleFilled({ x + 1, y + 1 }, math.max(3, radius * 0.28), shadow, 16);
            drawList:AddCircleFilled({ x, y }, math.max(2, radius * 0.25), accent, 16);
        end
        if (drawOuter == true) then
            drawList:AddCircle({ x, y }, radius, ring, 32, 2);
        end
    elseif (shape == 'Crosshair') then
        local gap = math.max(3, radius * 0.30);
        if (drawOuter == true) then
            drawList:AddLine({ x - radius + 1, y + 1 }, { x - gap + 1, y + 1 }, shadow, 4);
            drawList:AddLine({ x + gap + 1, y + 1 }, { x + radius + 1, y + 1 }, shadow, 4);
            drawList:AddLine({ x + 1, y - radius + 1 }, { x + 1, y - gap + 1 }, shadow, 4);
            drawList:AddLine({ x + 1, y + gap + 1 }, { x + 1, y + radius + 1 }, shadow, 4);
            drawList:AddLine({ x - radius, y }, { x - gap, y }, ring, 2);
            drawList:AddLine({ x + gap, y }, { x + radius, y }, ring, 2);
            drawList:AddLine({ x, y - radius }, { x, y - gap }, ring, 2);
            drawList:AddLine({ x, y + gap }, { x, y + radius }, ring, 2);
        end
        if (drawInner == true) then
            drawList:AddCircle({ x, y }, gap, accent, 16, 1);
        end
    else
        if (drawOuter == true) then
            drawList:AddCircle({ x + 1, y + 1 }, radius + 1, shadow, 32, 4);
            drawList:AddCircle({ x, y }, radius, ring, 32, 2);
        end
        if (drawInner == true) then
            drawList:AddCircle({ x, y }, radius + 4, accent, 32, 1);
        end
    end

    if (settings.centerEnabled == true or settings.showCenterMark == true) then
        drawList:AddLine({ x - 4, y }, { x + 4, y }, shadow, 3);
        drawList:AddLine({ x, y - 4 }, { x, y + 4 }, shadow, 3);
        drawList:AddLine({ x - 4, y }, { x + 4, y }, centerColor, 1);
        drawList:AddLine({ x, y - 4 }, { x, y + 4 }, centerColor, 1);
    end
end

return cursorOverlay;
