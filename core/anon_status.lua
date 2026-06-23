local state = require('core.state');

local anonStatus = {};

local function GetSelfServerId()
    local ok, serverId = pcall(function()
        local party = AshitaCore:GetMemoryManager():GetParty();
        return party ~= nil and party:GetMemberServerId(0) or nil;
    end);

    if (ok ~= true) then
        return nil;
    end

    serverId = tonumber(serverId) or 0;

    if (serverId <= 0) then
        return nil;
    end

    return serverId;
end

local function SetSelfAnonymous(value)
    local serverId = GetSelfServerId();

    if (serverId == nil) then
        return;
    end

    local anonymousByServerId = state.GetAnonymousByServerId();
    anonymousByServerId[tostring(serverId)] = value == true or nil;
    state.SaveThrottled(0.25);
end

local function SetServerAnonymous(serverId, value)
    serverId = tonumber(serverId) or 0;

    if (serverId <= 0) then
        return false;
    end

    if (serverId == GetSelfServerId()) then
        SetSelfAnonymous(false);
        return true;
    end

    local anonymousByServerId = state.GetAnonymousByServerId();
    anonymousByServerId[tostring(serverId)] = value == true or nil;
    state.SaveThrottled(0.25);

    return true;
end

local function GetSelfAnonymous()
    local serverId = GetSelfServerId();

    if (serverId == nil) then
        return false;
    end

    local anonymousByServerId = state.GetAnonymousByServerId();

    return anonymousByServerId[tostring(serverId)] == true or anonymousByServerId[serverId] == true;
end

function anonStatus.SetSelfAnonymous(value)
    SetSelfAnonymous(value == true);
end

function anonStatus.SetServerAnonymous(serverId, value)
    return SetServerAnonymous(serverId, value == true);
end

function anonStatus.GetSelfAnonymous()
    return GetSelfAnonymous();
end

local function NormalizeCommand(command)
    return tostring(command or ''):lower():gsub('^%s+', ''):gsub('%s+$', '');
end

function anonStatus.HandleCommandText(commandText)
    local text = NormalizeCommand(commandText);
    local command = text:match('^(%S+)');

    if (command ~= '/anon' and command ~= '/anonymous') then
        return;
    end

    SetSelfAnonymous(false);
end

return anonStatus;
