local gameFps = {};

local fpsDivisorSignature = '81EC000100003BC174218B0D';

local function NormalizeMode(mode)
    local text = tostring(mode or 'Keep current'):lower();

    if (text == 'fps1' or text == 'fps1 (60 fps)' or text == '1') then
        return 'FPS1 (60 FPS)';
    end

    if (text == 'fps2' or text == 'fps2 (30 fps)' or text == '2') then
        return 'FPS2 (30 FPS)';
    end

    return 'Keep current';
end

local function ModeFromDivisor(divisor)
    divisor = tonumber(divisor) or 0;

    if (divisor == 1) then
        return 'FPS1 (60 FPS)';
    end

    if (divisor == 2) then
        return 'FPS2 (30 FPS)';
    end

    if (divisor > 0) then
        return 'FPS divisor ' .. tostring(divisor);
    end

    return 'Unknown';
end

local function GetModeDivisor(mode)
    mode = NormalizeMode(mode);

    if (mode == 'FPS1 (60 FPS)') then
        return 1;
    end

    if (mode == 'FPS2 (30 FPS)') then
        return 2;
    end

    return nil;
end

local function FindFpsDivisorBase()
    if (ashita == nil or ashita.memory == nil or ashita.memory.find == nil) then
        return nil;
    end

    local ok, pointer = pcall(function()
        return ashita.memory.find('FFXiMain.dll', 0, fpsDivisorSignature, 0, 0);
    end);

    if (ok ~= true or pointer == nil or pointer == 0) then
        return nil;
    end

    ok, pointer = pcall(function()
        return ashita.memory.read_uint32(pointer + 0x0C);
    end);

    if (ok ~= true or pointer == nil or pointer == 0) then
        return nil;
    end

    ok, pointer = pcall(function()
        return ashita.memory.read_uint32(pointer);
    end);

    if (ok ~= true or pointer == nil or pointer == 0) then
        return nil;
    end

    return pointer;
end

function gameFps.GetModeChoices()
    return T{ 'Keep current', 'FPS1 (60 FPS)', 'FPS2 (30 FPS)' };
end

function gameFps.NormalizeMode(mode)
    return NormalizeMode(mode);
end

function gameFps.ApplyMode(mode)
    mode = NormalizeMode(mode);
    local divisor = GetModeDivisor(mode);

    if (divisor == nil) then
        return true, 'Keeping current FPS mode.';
    end

    local pointer = FindFpsDivisorBase();
    if (pointer == nil) then
        return false, 'Could not find FPS divisor.';
    end

    local ok, err = pcall(function()
        ashita.memory.write_uint32(pointer + 0x30, divisor);
    end);

    if (ok ~= true) then
        return false, tostring(err or 'Could not write FPS divisor.');
    end

    return true;
end

function gameFps.DetectCurrentMode()
    local pointer = FindFpsDivisorBase();
    if (pointer == nil) then
        return 'Unknown';
    end

    local ok, divisor = pcall(function()
        return ashita.memory.read_uint32(pointer + 0x30);
    end);

    if (ok ~= true) then
        return 'Unknown';
    end

    return ModeFromDivisor(divisor);
end

return gameFps;
