local ffi = require('ffi');
local bit = require('bit');
local imgui = require('imgui');
local state = require('core.state');
local globalDefaults = require('config.global');

ffi.cdef[[
    typedef unsigned int UINT;
    typedef unsigned long DWORD;
    typedef unsigned long long ULONG_PTR;
    void keybd_event(unsigned char bVk, unsigned char bScan, DWORD dwFlags, ULONG_PTR dwExtraInfo);
    short GetAsyncKeyState(int vKey);
]];

local mouseControls = {};

local KEYEVENTF_KEYUP = 0x0002;
local KEYEVENTF_SCANCODE = 0x0008;
local VK_LBUTTON = 0x01;
local VK_RBUTTON = 0x02;
local SCAN_A = 0x1E;
local SCAN_D = 0x20;
local SCAN_W = 0x11;

local leftDown = false;
local rightDown = false;
local forwardDown = false;
local turnLeftDown = false;
local turnRightDown = false;
local lastMouseX = nil;
local lastMouseMoveClock = 0;

local function IsMouseButtonDown(vKey)
    local ok, stateValue = pcall(function()
        return ffi.C.GetAsyncKeyState(vKey);
    end);

    if (ok ~= true or stateValue == nil) then
        return false;
    end

    return bit.band(tonumber(stateValue) or 0, 0x8000) ~= 0;
end

local function SyncPhysicalMouseButtons()
    leftDown = IsMouseButtonDown(VK_LBUTTON);
    rightDown = IsMouseButtonDown(VK_RBUTTON);
end

local function GetSettings()
    local global = state.GetGlobalSettings(globalDefaults);

    if (global.mouseControls == nil) then
        global.mouseControls = {};
    end

    if (global.mouseControls.enableBothButtonForward == nil) then
        global.mouseControls.enableBothButtonForward = false;
    end

    if (global.mouseControls.enableBothButtonSteer == nil) then
        global.mouseControls.enableBothButtonSteer = false;
    end

    if (global.mouseControls.steerDeadzone == nil) then
        global.mouseControls.steerDeadzone = 1.5;
    end

    if (global.mouseControls.invertSteer == nil) then
        global.mouseControls.invertSteer = false;
    end

    global.mouseControls.steerDeadzone = math.max(0.5, math.min(20.0, tonumber(global.mouseControls.steerDeadzone) or 1.5));

    return global.mouseControls;
end

local function SetScanDown(scanCode, value)
    value = (value == true);

    if (value == true) then
        ffi.C.keybd_event(0, scanCode, KEYEVENTF_SCANCODE, 0);
    else
        ffi.C.keybd_event(0, scanCode, bit.bor(KEYEVENTF_SCANCODE, KEYEVENTF_KEYUP), 0);
    end
end

local function SetForwardDown(value)
    value = (value == true);

    if (forwardDown == value) then
        return;
    end

    forwardDown = value;
    SetScanDown(SCAN_W, value);
end

local function SetTurnLeftDown(value)
    value = (value == true);

    if (turnLeftDown == value) then
        return;
    end

    turnLeftDown = value;
    SetScanDown(SCAN_A, value);
end

local function SetTurnRightDown(value)
    value = (value == true);

    if (turnRightDown == value) then
        return;
    end

    turnRightDown = value;
    SetScanDown(SCAN_D, value);
end

local function ReleaseTurn()
    SetTurnLeftDown(false);
    SetTurnRightDown(false);
end

local function Refresh()
    local settings = GetSettings();

    if (settings.enableBothButtonForward ~= true) then
        SetForwardDown(false);
        ReleaseTurn();
        return;
    end

    SyncPhysicalMouseButtons();

    local bothDown = (leftDown == true and rightDown == true);

    SetForwardDown(bothDown);

    if (bothDown ~= true or settings.enableBothButtonSteer ~= true) then
        ReleaseTurn();
    end
end

function mouseControls.GetSettings()
    return GetSettings();
end

function mouseControls.SetBothButtonForwardEnabled(value)
    local settings = GetSettings();
    settings.enableBothButtonForward = (value == true);
    Refresh();
end

function mouseControls.GetBothButtonForwardEnabled()
    return GetSettings().enableBothButtonForward == true;
end

function mouseControls.SetBothButtonSteerEnabled(value)
    local settings = GetSettings();
    settings.enableBothButtonSteer = (value == true);
    Refresh();
end

function mouseControls.GetBothButtonSteerEnabled()
    return GetSettings().enableBothButtonSteer == true;
end

function mouseControls.SetInvertSteer(value)
    local settings = GetSettings();
    settings.invertSteer = (value == true);
end

function mouseControls.GetInvertSteer()
    return GetSettings().invertSteer == true;
end

function mouseControls.Update()
    local settings = GetSettings();

    SyncPhysicalMouseButtons();

    if (
        settings.enableBothButtonForward ~= true or
        settings.enableBothButtonSteer ~= true or
        leftDown ~= true or
        rightDown ~= true
    ) then
        ReleaseTurn();
        return;
    end

    if ((os.clock() - (tonumber(lastMouseMoveClock) or 0)) > 0.08) then
        ReleaseTurn();
    end
end

function mouseControls.HandleMouse(e)
    if (e == nil) then
        return false;
    end

    local message = tonumber(e.message);

    if (message == 512) then
        local settings = GetSettings();
        local x = tonumber(e.x);

        if (x == nil) then
            return false;
        end

        if (lastMouseX == nil) then
            lastMouseX = x;
            return false;
        end

        local deltaX = x - lastMouseX;
        lastMouseX = x;
        lastMouseMoveClock = os.clock();

        SyncPhysicalMouseButtons();

        if (
            settings.enableBothButtonForward ~= true or
            settings.enableBothButtonSteer ~= true or
            leftDown ~= true or
            rightDown ~= true
        ) then
            ReleaseTurn();
            return false;
        end

        if (settings.invertSteer == true) then
            deltaX = -deltaX;
        end

        local deadzone = tonumber(settings.steerDeadzone) or 1.5;

        if (deltaX <= -deadzone) then
            SetTurnRightDown(false);
            SetTurnLeftDown(true);
        elseif (deltaX >= deadzone) then
            SetTurnLeftDown(false);
            SetTurnRightDown(true);
        else
            ReleaseTurn();
        end

        e.blocked = true;
        return forwardDown == true;
    elseif (message == 513) then
        leftDown = true;
        lastMouseX = tonumber(e.x) or lastMouseX;
    elseif (message == 514) then
        leftDown = false;
    elseif (message == 516) then
        rightDown = true;
        lastMouseX = tonumber(e.x) or lastMouseX;
    elseif (message == 517) then
        rightDown = false;
    else
        return false;
    end

    Refresh();
    return forwardDown == true;
end

function mouseControls.Release()
    leftDown = false;
    rightDown = false;
    lastMouseX = nil;
    lastMouseMoveClock = 0;
    SetForwardDown(false);
    ReleaseTurn();
end

return mouseControls;
