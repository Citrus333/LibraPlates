local statusEffects = require('core.status_effects');
local partyStatuses = require('core.party_statuses');

local playerStatuses = {};
local INFINITE_STATUS_DURATION = 0x7FFFFFFF;
local realUtcStampPointer = nil;
local levelSyncStatusIds = {
    [269] = true,
};

local function SafeCall(fallback, fn)
    local ok, result = pcall(fn);

    if (ok ~= true or result == nil) then
        return fallback;
    end

    return result;
end

local function GetPlayer()
    return AshitaCore:GetMemoryManager():GetPlayer();
end

local function GetSelfServerId()
    local memory = AshitaCore:GetMemoryManager();
    local party = memory ~= nil and memory:GetParty() or nil;
    local entity = memory ~= nil and memory:GetEntity() or nil;

    if (party == nil or entity == nil) then
        return nil;
    end

    local targetIndex = SafeCall(0, function()
        return party:GetMemberTargetIndex(0);
    end);

    targetIndex = tonumber(targetIndex) or 0;

    if (targetIndex == 0) then
        return nil;
    end

    return SafeCall(nil, function()
        return entity:GetServerId(targetIndex);
    end);
end

local function GetStatusId(statusIds, index)
    if (statusIds == nil) then
        return nil;
    end

    return tonumber(statusIds[index]);
end

local function GetRealUtcStampPointer()
    if (realUtcStampPointer ~= nil) then
        return realUtcStampPointer;
    end

    realUtcStampPointer = SafeCall(0, function()
        return ashita.memory.find(
            'FFXiMain.dll',
            0,
            '8B0D????????8B410C8B49108D04808D04808D04808D04C1C3',
            2,
            0
        );
    end);

    return realUtcStampPointer;
end

local function GetGameUtcStamp()
    local ptr = tonumber(GetRealUtcStampPointer()) or 0;

    if (ptr == 0) then
        return nil;
    end

    ptr = tonumber(SafeCall(0, function()
        return ashita.memory.read_uint32(ptr);
    end)) or 0;

    if (ptr == 0) then
        return nil;
    end

    ptr = tonumber(SafeCall(0, function()
        return ashita.memory.read_uint32(ptr);
    end)) or 0;

    if (ptr == 0) then
        return nil;
    end

    return SafeCall(nil, function()
        return ashita.memory.read_uint32(ptr + 0x0C);
    end);
end

local function ConvertRawStatusTimerToSeconds(rawTimer)
    rawTimer = tonumber(rawTimer);

    if (rawTimer == nil or rawTimer == 0) then
        return nil;
    end

    if (rawTimer == INFINITE_STATUS_DURATION) then
        return nil;
    end

    if (rawTimer <= 86400) then
        return rawTimer / 60;
    end

    local utcStamp = GetGameUtcStamp();

    if (utcStamp == nil) then
        return nil;
    end

    local vanaBaseStamp = 0x3C307D70;
    local offset = utcStamp - vanaBaseStamp;
    local comparand = offset * 60;
    local realDuration = rawTimer - comparand;

    while (realDuration < -2147483648) do
        realDuration = realDuration + 0xFFFFFFFF;
    end

    if (realDuration < 1) then
        return 0;
    end

    return realDuration / 60;
end

local function GetTimerSeconds(statusTimers, index)
    if (statusTimers == nil) then
        return nil;
    end

    local value = tonumber(statusTimers[index]);

    if (value == nil or value <= 0) then
        return nil;
    end

    return ConvertRawStatusTimerToSeconds(value);
end

local function GetStatusIds(player)
    local statusIds = SafeCall(nil, function()
        return player:GetStatusIcons();
    end);

    if (statusIds ~= nil) then
        return statusIds;
    end

    return SafeCall(nil, function()
        return player:GetBuffs();
    end);
end

local function GetStatusTimers(player)
    local statusTimers = SafeCall(nil, function()
        return player:GetStatusTimers();
    end);

    if (statusTimers ~= nil) then
        return statusTimers;
    end

    return SafeCall(nil, function()
        return player:GetBuffTimers();
    end);
end

local function GetStartIndex(statusIds)
    if (statusIds == nil) then
        return 1;
    end

    if (statusIds[0] ~= nil) then
        return 0;
    end

    return 1;
end

function playerStatuses.GetSelfRows(kind)
    local player = GetPlayer();
    local rows = {};

    if (player == nil) then
        return rows;
    end

    local statusIds = GetStatusIds(player);
    local statusTimers = GetStatusTimers(player);

    if (statusIds == nil) then
        return partyStatuses.GetMemberRows(GetSelfServerId(), kind);
    end

    local startIndex = GetStartIndex(statusIds);

    for offset = 0, 31 do
        local index = startIndex + offset;
        local statusId = GetStatusId(statusIds, index);

        if (
            statusId ~= nil and
            statusId > 0 and
            statusId ~= 255 and
            levelSyncStatusIds[statusId] ~= true and
            (
                (kind == 'buff' and statusEffects.IsBuff(statusId) == true) or
                (kind == 'debuff' and statusEffects.IsDebuff(statusId) == true) or
                (kind ~= 'buff' and kind ~= 'debuff')
            )
        ) then
            rows[#rows + 1] = {
                id = statusId,
                seconds = GetTimerSeconds(statusTimers, index),
                order = offset + 1,
            };
        end
    end

    if (#rows == 0) then
        local partyRows = partyStatuses.GetMemberRows(GetSelfServerId(), kind);

        if (#partyRows > 0) then
            return partyRows;
        end
    end

    table.sort(rows, function(a, b)
        local aSeconds = tonumber(a.seconds);
        local bSeconds = tonumber(b.seconds);
        local aHasTimer = aSeconds ~= nil and aSeconds >= 0;
        local bHasTimer = bSeconds ~= nil and bSeconds >= 0;

        if (aHasTimer ~= bHasTimer) then
            return aHasTimer == true;
        end

        if (aHasTimer == true and bHasTimer == true and aSeconds ~= bSeconds) then
            return aSeconds < bSeconds;
        end

        return (tonumber(a.order) or 0) < (tonumber(b.order) or 0);
    end);

    return rows;
end

function playerStatuses.GetSelfDebugText()
    local player = GetPlayer();

    if (player == nil) then
        return 'player=nil';
    end

    local statusIds = GetStatusIds(player);
    local statusTimers = GetStatusTimers(player);
    local rawCount = 0;
    local raw = {};

    if (statusIds ~= nil) then
        local startIndex = GetStartIndex(statusIds);

        for offset = 0, 31 do
            local index = startIndex + offset;
            local statusId = GetStatusId(statusIds, index);

            if (statusId ~= nil and statusId > 0 and statusId ~= 255) then
                rawCount = rawCount + 1;

                if (#raw < 8) then
                    raw[#raw + 1] = tostring(statusId);
                end
            end
        end
    end

    local buffs = playerStatuses.GetSelfRows('buff');
    local debuffs = playerStatuses.GetSelfRows('debuff');

    return 'raw=' .. tostring(rawCount) ..
        ' ids=' .. table.concat(raw, '/') ..
        ' timers=' .. tostring(statusTimers ~= nil) ..
        ' buffs=' .. tostring(#buffs) ..
        ' debuffs=' .. tostring(#debuffs) ..
        ' selfServer=' .. tostring(GetSelfServerId()) ..
        ' ' .. partyStatuses.GetDebugText(GetSelfServerId());
end

return playerStatuses;
