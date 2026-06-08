local state = require('core.state');

local overlaySuppression = {};
local pGameMenu = nil;
local pEventSystem = nil;
local pInterfaceHidden = nil;
local pointersResolved = false;

local function MemoryCall(fallback, fn)
    local ok, result = pcall(fn);

    if (ok ~= true or result == nil) then
        return fallback;
    end

    return result;
end

local function ResolvePointers()
    if (pointersResolved == true) then
        return;
    end

    pointersResolved = true;

    if (ashita == nil or ashita.memory == nil or ashita.memory.find == nil) then
        return;
    end

    pGameMenu = MemoryCall(0, function()
        return ashita.memory.find('FFXiMain.dll', 0, '8B480C85C974??8B510885D274??3B05', 16, 0);
    end);
    pEventSystem = MemoryCall(0, function()
        return ashita.memory.find('FFXiMain.dll', 0, 'A0????????84C0741AA1????????85C0741166A1????????663B05????????0F94C0C3', 0, 0);
    end);
    pInterfaceHidden = MemoryCall(0, function()
        return ashita.memory.find('FFXiMain.dll', 0, '8B4424046A016A0050B9????????E8????????F6D81BC040C3', 0, 0);
    end);
end

local function GetMenuName()
    ResolvePointers();

    if (pGameMenu == nil or pGameMenu == 0) then
        return '';
    end

    return MemoryCall('', function()
        local subPointer = ashita.memory.read_uint32(pGameMenu);
        local subValue = ashita.memory.read_uint32(subPointer);

        if (subValue == 0) then
            return '';
        end

        local menuHeader = ashita.memory.read_uint32(subValue + 4);
        return tostring(ashita.memory.read_string(menuHeader + 0x46, 16) or ''):gsub('\x00', '');
    end);
end

local function IsEventSystemActive()
    ResolvePointers();

    if (pEventSystem == nil or pEventSystem == 0) then
        return false;
    end

    return MemoryCall(false, function()
        local ptr = ashita.memory.read_uint32(pEventSystem + 1);
        return ptr ~= 0 and ashita.memory.read_uint8(ptr) == 1;
    end);
end

local function IsInterfaceHidden()
    ResolvePointers();

    if (pInterfaceHidden == nil or pInterfaceHidden == 0) then
        return false;
    end

    return MemoryCall(false, function()
        local ptr = ashita.memory.read_uint32(pInterfaceHidden + 10);
        return ptr ~= 0 and ashita.memory.read_uint8(ptr + 0xB4) == 1;
    end);
end

function overlaySuppression.GetStatusText()
    local menuName = GetMenuName():lower();
    local configOpen = state.GetConfigOpen() == true;
    local eventActive = IsEventSystemActive() == true;
    local interfaceHidden = IsInterfaceHidden() == true;
    local suppressed = overlaySuppression.IsSuppressed();

    return 'overlay suppressed=' .. tostring(suppressed) ..
        ' config=' .. tostring(configOpen) ..
        ' menu=' .. tostring(menuName) ..
        ' event=' .. tostring(eventActive) ..
        ' interfaceHidden=' .. tostring(interfaceHidden);
end

function overlaySuppression.IsSuppressed()
    local menuName = GetMenuName():lower();

    if (state.GetConfigOpen() == true) then
        return menuName:find('map', 1, true) ~= nil;
    end

    return
        menuName:find('map', 1, true) ~= nil or
        IsEventSystemActive() == true or
        IsInterfaceHidden() == true;
end

return overlaySuppression;
