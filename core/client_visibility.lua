local clientVisibility = {};

local pointers = {
    event = nil,
    interface = nil,
};

local function SafeCall(fallback, fn)
    local ok, result = pcall(fn);

    if (ok ~= true or result == nil) then
        return fallback;
    end

    return result;
end

local function FindPointer(key, pattern, offset)
    if (pointers[key] ~= nil) then
        return tonumber(pointers[key]) or 0;
    end

    pointers[key] = SafeCall(0, function()
        return ashita.memory.find('FFXiMain.dll', 0, pattern, offset, 0);
    end) or 0;

    return tonumber(pointers[key]) or 0;
end

local function GetEventPointer()
    return FindPointer(
        'event',
        'A0????????84C0741AA1????????85C0741166A1????????663B05????????0F94C0C3',
        0
    );
end

local function GetInterfacePointer()
    return FindPointer(
        'interface',
        '8B4424046A016A0050B9????????E8????????F6D81BC040C3',
        0
    );
end

function clientVisibility.IsEventActive()
    local basePointer = GetEventPointer();

    if (basePointer == 0) then
        return false;
    end

    local pointer = SafeCall(0, function()
        return ashita.memory.read_uint32(basePointer + 0x01);
    end) or 0;

    if (pointer == 0) then
        return false;
    end

    return (SafeCall(0, function()
        return ashita.memory.read_uint8(pointer);
    end) or 0) == 1;
end

function clientVisibility.IsInterfaceHidden()
    local basePointer = GetInterfacePointer();

    if (basePointer == 0) then
        return false;
    end

    local pointer = SafeCall(0, function()
        return ashita.memory.read_uint32(basePointer + 0x0A);
    end) or 0;

    if (pointer == 0) then
        return false;
    end

    return (SafeCall(0, function()
        return ashita.memory.read_uint8(pointer + 0xB4);
    end) or 0) == 1;
end

function clientVisibility.ShouldHideNpcObjectPlates()
    return clientVisibility.IsEventActive() == true
        or clientVisibility.IsInterfaceHidden() == true;
end

function clientVisibility.GetDebugText()
    return 'event=' .. tostring(clientVisibility.IsEventActive())
        .. ' interfaceHidden=' .. tostring(clientVisibility.IsInterfaceHidden());
end

return clientVisibility;
