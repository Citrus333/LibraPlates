local statusEffects = require('core.status_effects');
local partyStatuses = require('core.party_statuses');
local mounted = require('core.mounted');

local playerStatuses = {};
local INFINITE_STATUS_DURATION = 0x7FFFFFFF;
local MIN_INITIAL_TIMER_SECONDS = 3;
local MOUNTED_STATUS_EFFECT_ID = 252;
local realUtcStampPointer = nil;
local selfTimerSeenLong = {};
local mountedTimerExpiresAt = nil;
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

    if (party == nil) then
        return nil;
    end

    local partyServerId = SafeCall(0, function()
        return party:GetMemberServerId(0);
    end);

    partyServerId = tonumber(partyServerId) or 0;

    if (partyServerId ~= 0) then
        return partyServerId;
    end

    if (entity == nil) then
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
        return nil;
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

local function NormalizeSelfTimer(statusId, seconds)
    statusId = tonumber(statusId) or 0;
    seconds = tonumber(seconds);

    if (statusId <= 0 or seconds == nil) then
        return nil;
    end

    if (seconds > MIN_INITIAL_TIMER_SECONDS) then
        selfTimerSeenLong[statusId] = true;
        return seconds;
    end

    if (selfTimerSeenLong[statusId] == true) then
        return seconds;
    end

    return nil;
end

local function PruneSelfTimerSeen(activeStatusIds)
    for statusId, _ in pairs(selfTimerSeenLong) do
        if (activeStatusIds[statusId] ~= true) then
            selfTimerSeenLong[statusId] = nil;
        end
    end
end

local function GetCachedMountedTimerSeconds()
    if (mountedTimerExpiresAt == nil) then
        return nil;
    end

    local remaining = mountedTimerExpiresAt - os.clock();

    if (remaining <= 0) then
        mountedTimerExpiresAt = nil;
        return nil;
    end

    return remaining;
end

local function TrackMountedTimer(statusId, seconds)
    if ((tonumber(statusId) or 0) ~= MOUNTED_STATUS_EFFECT_ID) then
        return;
    end

    seconds = tonumber(seconds);

    if (seconds ~= nil and seconds > 0) then
        mountedTimerExpiresAt = os.clock() + seconds;
    end
end

local function EnsureMountedBuffRow(rows, activeStatusIds, kind)
    if (kind ~= 'buff') then
        return;
    end

    if (mounted.IsSelfMounted() ~= true) then
        mountedTimerExpiresAt = nil;
        return;
    end

    if (activeStatusIds[MOUNTED_STATUS_EFFECT_ID] == true) then
        return;
    end

    activeStatusIds[MOUNTED_STATUS_EFFECT_ID] = true;
    rows[#rows + 1] = {
        id = MOUNTED_STATUS_EFFECT_ID,
        seconds = GetCachedMountedTimerSeconds(),
        order = 0,
    };
end

local function CopySelfTimersToPartyRows(selfRows, partyRows)
    local selfTimers = {};

    for _, row in ipairs(selfRows or {}) do
        local statusId = tonumber(row.id) or 0;

        if (statusId > 0 and row.seconds ~= nil) then
            selfTimers[statusId] = row.seconds;
        end
    end

    for _, row in ipairs(partyRows or {}) do
        local statusId = tonumber(row.id) or 0;

        if (selfTimers[statusId] ~= nil) then
            row.seconds = selfTimers[statusId];
        end
    end

    return partyRows;
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
    local selfServerId = GetSelfServerId();

    if (player == nil) then
        return rows;
    end

    local statusIds = GetStatusIds(player);
    local statusTimers = GetStatusTimers(player);

    if (statusIds == nil) then
        return partyStatuses.GetMemberRows(selfServerId, kind);
    end

    local startIndex = GetStartIndex(statusIds);
    local activeStatusIds = {};

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
            activeStatusIds[statusId] = true;
            rows[#rows + 1] = {
                id = statusId,
                seconds = NormalizeSelfTimer(statusId, GetTimerSeconds(statusTimers, index)),
                order = offset + 1,
            };
            if (statusId == MOUNTED_STATUS_EFFECT_ID and rows[#rows].seconds == nil) then
                rows[#rows].seconds = GetCachedMountedTimerSeconds();
            end
            TrackMountedTimer(statusId, rows[#rows].seconds);
        end
    end

    EnsureMountedBuffRow(rows, activeStatusIds, kind);
    PruneSelfTimerSeen(activeStatusIds);

    if (kind == 'buff' or kind == 'debuff') then
        local partyRows = partyStatuses.GetMemberRows(selfServerId, kind);

        if (#partyRows > 0) then
            return CopySelfTimersToPartyRows(rows, partyRows);
        end
    end

    if (#rows == 0) then
        local partyRows = partyStatuses.GetMemberRows(selfServerId, kind);

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

function playerStatuses.HasSelfLevelSyncStatus()
    local player = GetPlayer();
    local selfServerId = GetSelfServerId();

    if (player == nil) then
        return partyStatuses.HasLevelSyncStatus(selfServerId);
    end

    local statusIds = GetStatusIds(player);

    if (statusIds == nil) then
        return partyStatuses.HasLevelSyncStatus(selfServerId);
    end

    local startIndex = GetStartIndex(statusIds);

    for offset = 0, 31 do
        local index = startIndex + offset;
        local statusId = GetStatusId(statusIds, index);

        if (statusId ~= nil and levelSyncStatusIds[statusId] == true) then
            return true;
        end
    end

    return partyStatuses.HasLevelSyncStatus(selfServerId);
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

function playerStatuses.GetSelfRawStatusText()
    local player = GetPlayer();

    if (player == nil) then
        return 'selfRaw=nil';
    end

    local statusIds = GetStatusIds(player);
    local statusTimers = GetStatusTimers(player);
    local parts = {};

    if (statusIds ~= nil) then
        local startIndex = GetStartIndex(statusIds);

        for offset = 0, 31 do
            local index = startIndex + offset;
            local statusId = GetStatusId(statusIds, index);

            if (statusId ~= nil and statusId > 0 and statusId ~= 255) then
                local timerSeconds = GetTimerSeconds(statusTimers, index);
                parts[#parts + 1] = tostring(statusId) .. ':' .. tostring(timerSeconds ~= nil and math.floor(timerSeconds) or 'aura');
            end
        end
    end

    return 'selfRaw=' .. (#parts > 0 and table.concat(parts, '/') or 'none');
end

return playerStatuses;
