local imgui = require('imgui');
local state = require('core.state');
local globalDefaults = require('config.global');

local windowLayout = {
    applied = false,
    lastSaved = {
        x = nil,
        y = nil,
        width = nil,
        height = nil,
    },
    lastSaveCheck = 0,
};

local function GetDisplaySize()
    if (imgui.GetIO == nil) then
        return 1280, 720;
    end

    local ok, io = pcall(function()
        return imgui.GetIO();
    end);

    if (ok ~= true or io == nil or io.DisplaySize == nil) then
        return 1280, 720;
    end

    return tonumber(io.DisplaySize.x or io.DisplaySize[1]) or 1280, tonumber(io.DisplaySize.y or io.DisplaySize[2]) or 720;
end

local function ReadVec2(value, valueY)
    if (type(value) == 'number') then
        return tonumber(value), tonumber(valueY);
    end

    if (type(value) ~= 'table') then
        return nil, nil;
    end

    return tonumber(value.x or value[1]), tonumber(value.y or value[2]);
end

local function ClampLayout(layout)
    local displayW, displayH = GetDisplaySize();
    local width = math.max(520, math.min(tonumber(layout.width) or 1100, math.max(520, displayW - 24)));
    local height = math.max(360, math.min(tonumber(layout.height) or 720, math.max(360, displayH - 24)));
    local maxX = math.max(0, displayW - width);
    local maxY = math.max(0, displayH - height);
    local x = tonumber(layout.x);
    local y = tonumber(layout.y);

    if (x == nil) then
        x = math.max(0, (displayW - width) * 0.5);
    end

    if (y == nil) then
        y = math.max(0, (displayH - height) * 0.5);
    end

    return {
        x = math.max(0, math.min(x, maxX)),
        y = math.max(0, math.min(y, maxY)),
        width = width,
        height = height,
    };
end

function windowLayout.ResetAppearing()
    windowLayout.applied = false;
end

function windowLayout.Apply()
    local global = state.GetGlobalSettings(globalDefaults);
    global.settingsWindow = global.settingsWindow or {};

    local layout = ClampLayout(global.settingsWindow);
    local cond = windowLayout.applied == true and (_G.ImGuiCond_FirstUseEver or 4) or (_G.ImGuiCond_Appearing or 8);

    if (imgui.SetNextWindowPos ~= nil) then
        imgui.SetNextWindowPos({ layout.x, layout.y }, cond);
    end

    if (imgui.SetNextWindowSize ~= nil) then
        imgui.SetNextWindowSize({ layout.width, layout.height }, cond);
    end

    windowLayout.applied = true;
end

function windowLayout.Save()
    if (imgui.GetWindowPos == nil or imgui.GetWindowSize == nil) then
        return;
    end

    local now = os.clock();
    local active = imgui.IsWindowFocused ~= nil and imgui.IsWindowFocused() == true and imgui.IsMouseDragging ~= nil and imgui.IsMouseDragging(0) == true;

    if (active ~= true and (now - (tonumber(windowLayout.lastSaveCheck) or 0)) < 1.0) then
        return;
    end

    windowLayout.lastSaveCheck = now;

    local posX, posY = ReadVec2(imgui.GetWindowPos());
    local width, height = ReadVec2(imgui.GetWindowSize());

    if (posX == nil or posY == nil or width == nil or height == nil) then
        return;
    end

    posX = math.floor(posX + 0.5);
    posY = math.floor(posY + 0.5);
    width = math.floor(width + 0.5);
    height = math.floor(height + 0.5);

    if (
        windowLayout.lastSaved.x == posX and
        windowLayout.lastSaved.y == posY and
        windowLayout.lastSaved.width == width and
        windowLayout.lastSaved.height == height
    ) then
        return;
    end

    windowLayout.lastSaved.x = posX;
    windowLayout.lastSaved.y = posY;
    windowLayout.lastSaved.width = width;
    windowLayout.lastSaved.height = height;

    local global = state.GetGlobalSettings(globalDefaults);
    global.settingsWindow = global.settingsWindow or {};
    global.settingsWindow.x = posX;
    global.settingsWindow.y = posY;
    global.settingsWindow.width = width;
    global.settingsWindow.height = height;

    -- This runs while the native ImGui Settings window is active.  Defer the
    -- actual profile write until the window has ended cleanly; settingsUi
    -- performs that save immediately after imgui.End().
    _G.LibraPlatesSettingsSaveRequested = true;
end

return windowLayout;
