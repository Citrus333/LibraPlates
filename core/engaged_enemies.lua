local bit = require('bit');
local entities = require('core.entities');

local engagedEnemies = {};
local tracked = {};

local function SafeCall(fallback, fn)
    local ok, result = pcall(fn);

    if (ok ~= true or result == nil) then
        return fallback;
    end

    return result;
end

local function GetEntityManager()
    local memory = AshitaCore:GetMemoryManager();

    if (memory == nil) then
        return nil;
    end

    return memory:GetEntity();
end

local function GetPartyManager()
    local memory = AshitaCore:GetMemoryManager();

    if (memory == nil) then
        return nil;
    end

    return memory:GetParty();
end

local function GetIndexFromServerId(serverId)
    serverId = tonumber(serverId) or 0;

    if (serverId == 0) then
        return 0;
    end

    local entityManager = GetEntityManager();

    if (entityManager == nil) then
        return 0;
    end

    if (bit.band(serverId, 0x1000000) ~= 0) then
        local index = bit.band(serverId, 0xFFF);

        if (index >= 0x900) then
            index = index - 0x100;
        end

        if (
            index > 0 and
            index < 0x900 and
            SafeCall(0, function() return entityManager:GetServerId(index); end) == serverId
        ) then
            return index;
        end
    end

    for index = 1, 0x8FF do
        if (SafeCall(0, function() return entityManager:GetServerId(index); end) == serverId) then
            return index;
        end
    end

    return 0;
end

local function GetPartyServerIds()
    local ids = {};
    local party = GetPartyManager();

    if (party == nil) then
        return ids;
    end

    for i = 0, 17 do
        if (SafeCall(0, function() return party:GetMemberIsActive(i); end) == 1) then
            local serverId = SafeCall(0, function() return party:GetMemberServerId(i); end);

            if (serverId ~= 0) then
                ids[serverId] = true;
            end
        end
    end

    return ids;
end

local function GetPartyTargetIndexes()
    local indexes = {};
    local party = GetPartyManager();

    if (party == nil) then
        return indexes;
    end

    for i = 0, 17 do
        if (SafeCall(0, function() return party:GetMemberIsActive(i); end) == 1) then
            local index = SafeCall(0, function() return party:GetMemberTargetIndex(i); end);

            if (index ~= 0) then
                indexes[index] = true;
            end
        end
    end

    return indexes;
end

local function IsValidTrackedEnemy(index)
    index = tonumber(index);

    if (index == nil or index == 0) then
        return false;
    end

    local entityManager = GetEntityManager();

    if (entityManager == nil) then
        return false;
    end

    local ent = GetEntity(index);

    if (ent == nil or ent.Name == nil or ent.Name == '') then
        return false;
    end

    if (ent.HPPercent ~= nil and ent.HPPercent <= 0) then
        return false;
    end

    local spawnFlags = SafeCall(0, function()
        return entityManager:GetSpawnFlags(index);
    end);

    return bit.band(spawnFlags, 0x10) ~= 0;
end

local function Track(index)
    index = tonumber(index);

    if (IsValidTrackedEnemy(index) ~= true) then
        return;
    end

    tracked[index] = true;
end

local function ParseActionPacket(e)
    if (e == nil or e.id ~= 0x0028 or e.data_raw == nil or ashita.bits == nil) then
        return nil;
    end

    local bitData = e.data_raw;
    local bitOffset = 40;
    local maxLength = (tonumber(e.size) or 0) * 8;

    local function unpackBits(length)
        if ((bitOffset + length) >= maxLength) then
            maxLength = 0;
            return 0;
        end

        local value = ashita.bits.unpack_be(bitData, 0, bitOffset, length);
        bitOffset = bitOffset + length;
        return value;
    end

    local packet = {
        userId = unpackBits(32),
        targets = {},
    };

    packet.userIndex = GetIndexFromServerId(packet.userId);

    local targetCount = unpackBits(6);
    bitOffset = bitOffset + 4;
    local actionType = unpackBits(4);

    if (actionType == 8 or actionType == 9) then
        unpackBits(16);
        unpackBits(16);
    else
        unpackBits(32);
    end

    unpackBits(32);

    for _ = 1, targetCount do
        local targetId = unpackBits(32);
        local actionCount = unpackBits(4);

        packet.targets[#packet.targets + 1] = targetId;

        if (actionCount == 0) then
            break;
        end

        for _ = 1, actionCount do
            unpackBits(5);
            unpackBits(12);
            unpackBits(7);
            unpackBits(3);
            unpackBits(17);
            unpackBits(10);
            unpackBits(31);

            if (unpackBits(1) == 1) then
                unpackBits(10);
                unpackBits(17);
                unpackBits(10);
            end

            if (unpackBits(1) == 1) then
                unpackBits(10);
                unpackBits(14);
                unpackBits(10);
            end
        end
    end

    return maxLength ~= 0 and packet or nil;
end

local function ParseMobUpdatePacket(e)
    if (e == nil or e.id ~= 0x000E or e.data == nil) then
        return nil;
    end

    local updateFlags = struct.unpack('B', e.data, 0x0A + 1);

    if (bit.band(updateFlags, 0x02) ~= 0x02) then
        return nil;
    end

    return {
        monsterIndex = struct.unpack('H', e.data, 0x08 + 1),
        newClaimId = struct.unpack('L', e.data, 0x2C + 1),
    };
end

local function Prune()
    for index in pairs(tracked) do
        if (IsValidTrackedEnemy(index) ~= true) then
            tracked[index] = nil;
        end
    end
end

function engagedEnemies.HandlePacketIn(e)
    if (e == nil) then
        return;
    end

    if (e.id == 0x000A) then
        tracked = {};
        return;
    end

    if (e.id == 0x0028) then
        local packet = ParseActionPacket(e);

        if (packet == nil or packet.userIndex == nil or packet.userIndex == 0) then
            return;
        end

        local partyIds = GetPartyServerIds();

        for _, targetId in ipairs(packet.targets) do
            if (partyIds[tonumber(targetId) or 0] == true) then
                Track(packet.userIndex);
                return;
            end
        end
    elseif (e.id == 0x000E) then
        local packet = ParseMobUpdatePacket(e);

        if (packet ~= nil and GetPartyServerIds()[tonumber(packet.newClaimId) or 0] == true) then
            Track(packet.monsterIndex);
        end
    end
end

function engagedEnemies.IsEngaged(index)
    index = tonumber(index);

    if (index == nil or index == 0) then
        return false;
    end

    Prune();

    if (tracked[index] ~= nil) then
        return true;
    end

    local entityManager = GetEntityManager();

    if (entityManager == nil or entityManager.GetTargetedIndex == nil) then
        return false;
    end

    local targetIndex = SafeCall(0, function()
        return entityManager:GetTargetedIndex(index);
    end);

    if (targetIndex ~= 0 and GetPartyTargetIndexes()[targetIndex] == true) then
        Track(index);
        return true;
    end

    return false;
end

function engagedEnemies.GetTrackedIndexes()
    Prune();

    local indexes = {};

    for index in pairs(tracked) do
        indexes[#indexes + 1] = index;
    end

    table.sort(indexes);
    return indexes;
end

function engagedEnemies.GetStatusText()
    Prune();

    local parts = {};

    for index in pairs(tracked) do
        local ent = GetEntity(index);

        parts[#parts + 1] = tostring(index) .. ':' .. tostring(ent ~= nil and ent.Name or '?') .. ':' .. tostring(ent ~= nil and ent.HPPercent or '?');
    end

    table.sort(parts);

    if (#parts == 0) then
        return 'engaged=none';
    end

    return 'engaged=' .. table.concat(parts, ', ');
end

return engagedEnemies;
