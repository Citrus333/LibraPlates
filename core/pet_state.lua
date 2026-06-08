require('common');

local log = require('core.log');

local petState = {};
local commandStates = {
    [69] = 'Fight',
    [70] = 'Heel',
    [73] = 'Stay',
};
local state = {
    index = nil,
    serverId = nil,
    name = nil,
    commandId = nil,
    commandName = nil,
    category = nil,
    updatedAt = nil,
    lastRestingCommandId = nil,
    lastRestingCommandName = nil,
};
local fightClearGraceSeconds = 2;

local function ClearCommand()
    state.commandId = nil;
    state.commandName = nil;
    state.category = nil;
    state.updatedAt = nil;
end

local function ClearRestingCommand()
    state.lastRestingCommandId = nil;
    state.lastRestingCommandName = nil;
end

local function ReadUInt16(data, offset)
    local ok, value = pcall(function()
        return struct.unpack('H', data, offset + 1);
    end);

    if (ok ~= true) then
        return nil;
    end

    return tonumber(value);
end

function petState.SyncPet(pet)
    if (pet == nil) then
        state.index = nil;
        state.serverId = nil;
        state.name = nil;
        ClearCommand();
        ClearRestingCommand();
        return;
    end

    if (
        state.index ~= nil and
        (state.index ~= pet.index or state.serverId ~= pet.serverId or state.name ~= pet.name)
    ) then
        ClearCommand();
        ClearRestingCommand();
    end

    state.index = pet.index;
    state.serverId = pet.serverId;
    state.name = pet.name;

    if (
        state.commandName == 'Fight' and
        tonumber(pet.status) ~= 1 and
        state.updatedAt ~= nil and
        (os.time() - state.updatedAt) > fightClearGraceSeconds
    ) then
        state.commandId = state.lastRestingCommandId;
        state.commandName = state.lastRestingCommandName;
        state.category = nil;
        state.updatedAt = nil;
    end
end

function petState.HandlePacketOut(e)
    if (e == nil or e.id ~= 0x01A or e.data == nil) then
        return;
    end

    local category = ReadUInt16(e.data, 0x0A);
    local actionId = ReadUInt16(e.data, 0x0C);
    local commandName = commandStates[actionId];

    if (commandName == nil) then
        return;
    end

    state.commandId = actionId;
    state.commandName = commandName;
    state.category = category;
    state.updatedAt = os.time();

    if (commandName == 'Heel' or commandName == 'Stay') then
        state.lastRestingCommandId = actionId;
        state.lastRestingCommandName = commandName;
    end

    log.Info(string.format(
        'Pet state caught: %s actionId=%s category=%s',
        commandName,
        tostring(actionId),
        tostring(category)
    ));
end

function petState.GetState()
    return state.commandName;
end

function petState.GetStatusText()
    return string.format(
        'Pet state=%s actionId=%s category=%s pet=%s index=%s',
        tostring(state.commandName or 'Unknown'),
        tostring(state.commandId or ''),
        tostring(state.category or ''),
        tostring(state.name or ''),
        tostring(state.index or '')
    );
end

return petState;
