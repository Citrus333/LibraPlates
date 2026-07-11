local trustNames = require('core.trust_names');
local entities = require('core.entities');

local actionRelevance = {};

local function SafeCall(fallback, fn)
    local ok, result = pcall(fn);

    if (ok ~= true or result == nil) then
        return fallback;
    end

    return result;
end

local function GetEntityManager()
    local memory = AshitaCore:GetMemoryManager();

    return memory ~= nil and memory:GetEntity() or nil;
end

function actionRelevance.GetIndexFromServerId(serverId)
    serverId = tonumber(serverId) or 0;

    if (serverId == 0) then
        return 0;
    end

    local entityManager = GetEntityManager();

    if (entityManager == nil) then
        return 0;
    end

    for index = 1, 0x8FF do
        if (SafeCall(0, function() return entityManager:GetServerId(index); end) == serverId) then
            return index;
        end
    end

    return 0;
end

function actionRelevance.GetEntityName(index)
    index = tonumber(index) or 0;

    if (index <= 0) then
        return nil;
    end

    local entityManager = GetEntityManager();

    if (entityManager == nil) then
        return nil;
    end

    local name = SafeCall(nil, function() return entityManager:GetName(index); end);

    if (name ~= nil and tostring(name) ~= '') then
        return tostring(name);
    end

    local entity = SafeCall(nil, function() return GetEntity(index); end);

    return entity ~= nil and entity.Name or nil;
end

function actionRelevance.IsPcIndex(index)
    index = tonumber(index) or 0;

    return index >= 1024 and index <= 1791;
end

function actionRelevance.IsPartyOrAllianceIndex(index)
    index = tonumber(index) or 0;

    if (index <= 0) then
        return false;
    end

    local party = SafeCall(nil, function()
        return AshitaCore:GetMemoryManager():GetParty();
    end);

    if (party == nil) then
        return false;
    end

    for slot = 0, 17 do
        local active = SafeCall(0, function() return party:GetMemberIsActive(slot); end) or 0;
        local memberIndex = SafeCall(0, function() return party:GetMemberTargetIndex(slot); end) or 0;

        if (active == 1 and tonumber(memberIndex) == index) then
            return true;
        end
    end

    return false;
end

function actionRelevance.IsPartyOrAllianceServerId(serverId)
    serverId = tonumber(serverId) or 0;

    if (serverId == 0) then
        return false;
    end

    local party = SafeCall(nil, function()
        return AshitaCore:GetMemoryManager():GetParty();
    end);

    if (party == nil) then
        return false;
    end

    for slot = 0, 17 do
        local active = SafeCall(0, function() return party:GetMemberIsActive(slot); end) or 0;
        local memberId = SafeCall(0, function() return party:GetMemberServerId(slot); end) or 0;

        if (active == 1 and tonumber(memberId) == serverId) then
            return true;
        end
    end

    return false;
end

function actionRelevance.IsKnownTrustIndex(index)
    local name = actionRelevance.GetEntityName(index);

    return name ~= nil and trustNames.IsKnownTrustName(name) == true;
end

function actionRelevance.IsKnownPetIndex(index)
    if (entities.IsEnemy(index) == true) then
        return false;
    end

    local name = actionRelevance.GetEntityName(index);

    return name ~= nil and entities.IsKnownPetName(name) == true;
end

function actionRelevance.IsOutsideFriendlyIndex(index)
    index = tonumber(index) or 0;

    if (
        index <= 0 or
        actionRelevance.IsPartyOrAllianceIndex(index) == true or
        entities.IsOwnPetIndex(index) == true
    ) then
        return false;
    end

    return
        actionRelevance.IsPcIndex(index) == true or
        actionRelevance.IsKnownTrustIndex(index) == true or
        actionRelevance.IsKnownPetIndex(index) == true;
end

function actionRelevance.ShouldIgnoreOutsideFriendlyCaster(actionPacket)
    if (actionPacket == nil) then
        return false;
    end

    local userIndex = tonumber(actionPacket.UserIndex) or 0;

    if (userIndex <= 0 and actionPacket.UserId ~= nil) then
        userIndex = actionRelevance.GetIndexFromServerId(actionPacket.UserId);
        actionPacket.UserIndex = userIndex;
    end

    return actionRelevance.IsOutsideFriendlyIndex(userIndex) == true;
end

return actionRelevance;
