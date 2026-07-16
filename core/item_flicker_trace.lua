local log = require('core.log');

local itemTrace = {};

local activeUntil = 0;
local startedAt = 0;
local path = nil;
local file = nil;
local frameCount = 0;
local lastFrameClock = nil;

local interestingPacketIds = {
    [0x01A] = 'action',
    [0x01B] = 'action-message',
    [0x028] = 'action',
    [0x029] = 'action-message',
    [0x034] = 'menu',
    [0x037] = 'item-update',
    [0x05B] = 'event/menu-choice',
    [0x05C] = 'event/menu-update',
    [0x061] = 'char-update',
    [0x063] = 'inventory-finish',
    [0x0DD] = 'inventory',
    [0x0DF] = 'inventory-assign',
    [0x0E0] = 'inventory-size',
};

local function GetTraceDirectory()
    local root = '';

    pcall(function()
        root = AshitaCore:GetInstallPath() .. '\\config\\addons\\LibraPlates\\traces';
    end);

    if (root == '') then
        root = 'config\\addons\\LibraPlates\\traces';
    end

    pcall(function()
        if (ashita ~= nil and ashita.fs ~= nil and ashita.fs.create_dir ~= nil) then
            ashita.fs.create_dir(root);
        end
    end);

    return root;
end

local function Stamp()
    return string.format('%.3f', os.clock() - startedAt);
end

local function Write(line)
    if (file == nil) then
        return;
    end

    file:write('+' .. Stamp() .. ' ' .. tostring(line or '') .. '\n');
    file:flush();
end

local function Close(reason)
    if (file ~= nil) then
        Write('stop reason=' .. tostring(reason or 'done') .. ' frames=' .. tostring(frameCount));
        file:close();
        file = nil;
    end

    activeUntil = 0;
end

local function IsActive()
    return file ~= nil and os.clock() <= activeUntil;
end

local function PacketId(e)
    return tonumber(e ~= nil and (e.id or e.Id or e.packet_id or e.PacketId)) or 0;
end

function itemTrace.Start(seconds)
    Close('restart');

    seconds = math.max(1, math.min(30, tonumber(seconds) or 5));
    startedAt = os.clock();
    activeUntil = startedAt + seconds;
    frameCount = 0;
    lastFrameClock = nil;

    local date = os.date('%Y%m%d-%H%M%S');
    path = GetTraceDirectory() .. '\\item-flicker-' .. tostring(date) .. '.txt';
    file = io.open(path, 'w');

    if (file == nil) then
        log.Warn('Item trace could not open trace file: ' .. tostring(path));
        return false;
    end

    Write('start seconds=' .. tostring(seconds));
    log.Info('Item trace started for ' .. tostring(seconds) .. 's: ' .. tostring(path));
    return true;
end

function itemTrace.HandleCommandText(command)
    if (IsActive() ~= true) then
        return;
    end

    Write('command ' .. tostring(command or ''));
end

function itemTrace.HandlePacketIn(e)
    if (IsActive() ~= true) then
        return;
    end

    local id = PacketId(e);
    local label = interestingPacketIds[id];

    if (label ~= nil) then
        Write(string.format('packet_in 0x%03X %s blocked=%s', id, label, tostring(e ~= nil and e.blocked)));
    end
end

function itemTrace.HandlePacketOut(e)
    if (IsActive() ~= true) then
        return;
    end

    local id = PacketId(e);
    local label = interestingPacketIds[id] or '';
    Write(string.format('packet_out 0x%03X %s blocked=%s', id, label, tostring(e ~= nil and e.blocked)));
end

function itemTrace.HandleTextIn(e)
    if (IsActive() ~= true) then
        return;
    end

    local text = tostring((e ~= nil and (e.message or e.text or e.original or e.modified)) or '');
    text = text:gsub(string.char(0x1E) .. '.', ''):gsub('[%z\1-\31]', '');

    if (text ~= '') then
        Write('text ' .. text);
    end
end

function itemTrace.HandlePresent()
    if (file == nil) then
        return;
    end

    local now = os.clock();

    if (now > activeUntil) then
        Close('timeout');
        log.Info('Item trace finished: ' .. tostring(path));
        return;
    end

    frameCount = frameCount + 1;

    if (lastFrameClock ~= nil) then
        local delta = now - lastFrameClock;

        if (delta >= 0.050) then
            Write(string.format('frame_gap %.1fms frame=%d', delta * 1000, frameCount));
        end
    end

    lastFrameClock = now;
end

function itemTrace.GetStatusText()
    if (file ~= nil) then
        return 'Item trace active left=' .. string.format('%.1f', math.max(0, activeUntil - os.clock())) .. 's file=' .. tostring(path);
    end

    return 'Item trace inactive last=' .. tostring(path or 'none');
end

return itemTrace;
