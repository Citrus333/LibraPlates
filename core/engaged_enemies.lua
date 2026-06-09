local bit = require('bit');
local entities = require('core.entities');
local log = require('core.log');

local engagedEnemies = {};
local tracked = {};
local claimCategories = {};
local debugUntil = 0;

local function IsDebugEnabled()
    return os.clock() < (tonumber(debugUntil) or 0);
end

local function DebugLog(text)
    if (IsDebugEnabled() ~= true) then
        return;
    end

    log.Info('Claim debug ' .. tostring(text or ''));
end

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

local function IsEntityValidTarget(index)
    index = tonumber(index);

    if (index == nil or index == 0) then
        return false;
    end

    local entityManager = GetEntityManager();

    if (entityManager ~= nil) then
        local methods = {
            'GetIsValidTarget',
            'GetValidTarget',
            'IsValidTarget',
            'GetTargetable',
            'IsTargetable',
        };

        for _, methodName in ipairs(methods) do
            if (entityManager[methodName] ~= nil) then
                local value = SafeCall(nil, function()
                    return entityManager[methodName](entityManager, index);
                end);

                if (value == true or tonumber(value) == 1) then
                    return true;
                end
            end
        end
    end

    local ent = GetEntity(index);

    if (ent ~= nil) then
        local fields = {
            'ValidTarget',
            'validTarget',
            'IsValidTarget',
            'Targetable',
            'IsTargetable',
        };

        for _, fieldName in ipairs(fields) do
            local value = ent[fieldName];

            if (value == true or tonumber(value) == 1) then
                return true;
            end
        end
    end

    return false;
end

local function GetEntityClaimStatus(index)
    index = tonumber(index);

    if (index == nil or index == 0) then
        return nil;
    end

    local entityManager = GetEntityManager();

    if (entityManager == nil or entityManager.GetClaimStatus == nil) then
        return nil;
    end

    return SafeCall(nil, function()
        return entityManager:GetClaimStatus(index);
    end);
end

local function IsCallForHelpEntity(index)
    index = tonumber(index);

    if (index == nil or index == 0) then
        return false;
    end

    local ent = GetEntity(index);

    if (
        ent ~= nil and
        ent.Render ~= nil and
        ent.Render.Flags0 ~= nil and
        ent.Render.Flags1 ~= nil and
        bit.band(tonumber(ent.Render.Flags0) or 0, 0x2000) ~= 0 and
        bit.band(tonumber(ent.Render.Flags1) or 0, 0x1000000) ~= 0
    ) then
        return true;
    end

    local entityManager = GetEntityManager();

    if (entityManager == nil) then
        return false;
    end

    local flags0 = SafeCall(0, function()
        return entityManager:GetRenderFlags0(index);
    end);
    local flags1 = SafeCall(0, function()
        return entityManager:GetRenderFlags1(index);
    end);

    return bit.band(tonumber(flags0) or 0, 0x2000) ~= 0 and bit.band(tonumber(flags1) or 0, 0x1000000) ~= 0;
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
        callForHelpTargets = {},
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
            local message = unpackBits(10);
            unpackBits(31);

            if (message == 19) then
                packet.callForHelpTargets[#packet.callForHelpTargets + 1] = targetId;
            end

            if (unpackBits(1) == 1) then
                unpackBits(10);
                unpackBits(17);
                if (unpackBits(10) == 19) then
                    packet.callForHelpTargets[#packet.callForHelpTargets + 1] = targetId;
                end
            end

            if (unpackBits(1) == 1) then
                unpackBits(10);
                unpackBits(14);
                if (unpackBits(10) == 19) then
                    packet.callForHelpTargets[#packet.callForHelpTargets + 1] = targetId;
                end
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
        claimCategories = {};
        return;
    end

    if (e.id == 0x0028) then
        local packet = ParseActionPacket(e);

        if (packet == nil or packet.userIndex == nil or packet.userIndex == 0) then
            return;
        end

        local partyIds = GetPartyServerIds();
        local userIsParty = partyIds[tonumber(packet.userId) or 0] == true;
        local userIsEnemy = IsValidTrackedEnemy(packet.userIndex) == true;
        local userIsOther = userIsParty ~= true and userIsEnemy ~= true;

        DebugLog(
            'action userId=' .. tostring(packet.userId) ..
            ' userIndex=' .. tostring(packet.userIndex) ..
            ' userParty=' .. tostring(userIsParty) ..
            ' userEnemy=' .. tostring(userIsEnemy) ..
            ' targets=' .. tostring(#packet.targets) ..
            ' cfhTargets=' .. tostring(#packet.callForHelpTargets)
        );

        if (userIsEnemy == true and #(packet.callForHelpTargets or {}) > 0) then
            claimCategories[packet.userIndex] = 'call_for_help';
            Track(packet.userIndex);
            DebugLog('set category index=' .. tostring(packet.userIndex) .. ' category=call_for_help reason=action-message-19-actor');
        end

        for _, targetId in ipairs(packet.callForHelpTargets or {}) do
            local targetIndex = GetIndexFromServerId(targetId);

            if (IsValidTrackedEnemy(targetIndex) == true) then
                claimCategories[targetIndex] = 'call_for_help';
                Track(targetIndex);
                DebugLog('set category index=' .. tostring(targetIndex) .. ' category=call_for_help reason=action-message-19-target');
            end
        end

        for _, targetId in ipairs(packet.targets) do
            local targetIndex = GetIndexFromServerId(targetId);
            local targetIsParty = partyIds[tonumber(targetId) or 0] == true;
            local targetIsEnemy = IsValidTrackedEnemy(targetIndex) == true;

            DebugLog(
                'action targetId=' .. tostring(targetId) ..
                ' targetIndex=' .. tostring(targetIndex) ..
                ' targetParty=' .. tostring(targetIsParty) ..
                ' targetEnemy=' .. tostring(targetIsEnemy)
            );

            if (partyIds[tonumber(targetId) or 0] == true) then
                if (userIsEnemy == true) then
                    if (claimCategories[packet.userIndex] ~= 'other' and claimCategories[packet.userIndex] ~= 'call_for_help') then
                        claimCategories[packet.userIndex] = 'party';
                        DebugLog('set category index=' .. tostring(packet.userIndex) .. ' category=party reason=enemy-hit-party');
                    else
                        DebugLog('keep category index=' .. tostring(packet.userIndex) .. ' category=' .. tostring(claimCategories[packet.userIndex]) .. ' reason=enemy-hit-party-no-overwrite');
                    end
                end

                Track(packet.userIndex);
                return;
            end

            if (targetIsEnemy == true) then
                if (userIsParty == true) then
                    claimCategories[targetIndex] = 'party';
                    Track(targetIndex);
                    DebugLog('set category index=' .. tostring(targetIndex) .. ' category=party reason=party-hit-enemy');
                elseif (userIsOther == true) then
                    claimCategories[targetIndex] = 'other';
                    DebugLog('set category index=' .. tostring(targetIndex) .. ' category=other reason=other-hit-enemy');
                end
            elseif (userIsEnemy == true and userIsOther ~= true) then
                claimCategories[packet.userIndex] = userIsParty == true and 'party' or claimCategories[packet.userIndex];
            elseif (userIsEnemy == true and partyIds[tonumber(targetId) or 0] ~= true) then
                claimCategories[packet.userIndex] = claimCategories[packet.userIndex] or 'other';
            end
        end
    elseif (e.id == 0x000E) then
        local packet = ParseMobUpdatePacket(e);

        if (packet ~= nil) then
            local claimId = tonumber(packet.newClaimId) or 0;
            local monsterIndex = tonumber(packet.monsterIndex) or 0;
            local partyIds = GetPartyServerIds();

            if (monsterIndex ~= 0) then
                if (claimId == 0) then
                    claimCategories[monsterIndex] = 'unclaimed';
                    DebugLog('mobupdate index=' .. tostring(monsterIndex) .. ' claimId=' .. tostring(claimId) .. ' category=unclaimed');
                elseif (partyIds[claimId] == true) then
                    claimCategories[monsterIndex] = 'party';
                    Track(monsterIndex);
                    DebugLog('mobupdate index=' .. tostring(monsterIndex) .. ' claimId=' .. tostring(claimId) .. ' category=party');
                elseif (
                    bit.band(tonumber(GetEntityClaimStatus(monsterIndex)) or 0, 0xFFFF0000) ~= 0 or
                    IsEntityValidTarget(monsterIndex) == true
                ) then
                    claimCategories[monsterIndex] = 'call_for_help';
                    Track(monsterIndex);
                    DebugLog('mobupdate index=' .. tostring(monsterIndex) .. ' claimId=' .. tostring(claimId) .. ' claimStatus=' .. tostring(GetEntityClaimStatus(monsterIndex)) .. ' category=call_for_help reason=other-claim-state');
                else
                    claimCategories[monsterIndex] = 'other';
                    DebugLog('mobupdate index=' .. tostring(monsterIndex) .. ' claimId=' .. tostring(claimId) .. ' category=other');
                end
            end
        end
    end
end

function engagedEnemies.GetClaimCategory(index)
    index = tonumber(index);

    if (index == nil or index == 0) then
        return nil;
    end

    if (IsValidTrackedEnemy(index) ~= true) then
        claimCategories[index] = nil;
        return nil;
    end

    if (IsCallForHelpEntity(index) == true) then
        claimCategories[index] = 'call_for_help';
        Track(index);
        return 'call_for_help';
    end

    return claimCategories[index];
end

function engagedEnemies.MarkCallForHelp(index)
    index = tonumber(index);

    if (index == nil or index == 0 or IsValidTrackedEnemy(index) ~= true) then
        return false;
    end

    claimCategories[index] = 'call_for_help';
    Track(index);
    DebugLog('set category index=' .. tostring(index) .. ' category=call_for_help reason=local-help-command');

    return true;
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

        parts[#parts + 1] = tostring(index) .. ':' .. tostring(ent ~= nil and ent.Name or '?') .. ':' .. tostring(ent ~= nil and ent.HPPercent or '?') .. ':claim=' .. tostring(claimCategories[index]);
    end

    table.sort(parts);

    if (#parts == 0) then
        return 'engaged=none';
    end

    return 'engaged=' .. table.concat(parts, ', ');
end

function engagedEnemies.EnableClaimDebugForSeconds(seconds)
    debugUntil = os.clock() + math.max(5, math.min(60, tonumber(seconds) or 20));
    log.Info('Claim debug enabled for ' .. tostring(math.floor(math.max(5, math.min(60, tonumber(seconds) or 20)))) .. ' seconds.');
end

function engagedEnemies.DisableClaimDebug()
    debugUntil = 0;
    log.Info('Claim debug disabled.');
end

return engagedEnemies;
