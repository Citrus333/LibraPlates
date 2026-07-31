local bit = require('bit');
local enmityIcons = require('core.enmity_icons');
local engagedEnemies = require('core.engaged_enemies');
local entityResolver = require('core.entity_resolver');

local enmity = {};
local enemyTargetServerIds = {};
local enemyTargetClocks = {};
local targetTimeoutSeconds = 10.0;

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

local function GetServerId(index)
    local serverId = entityResolver.GetServerId(index);
    return serverId > 0 and serverId or nil;
end

local function GetLiveTargetIndex(index)
    index = tonumber(index) or 0;

    if (index == 0) then
        return nil, false;
    end

    local entityManager = GetEntityManager();

    if (entityManager == nil or entityManager.GetTargetedIndex == nil) then
        return nil, false;
    end

    local ok, targetIndex = pcall(function()
        return entityManager:GetTargetedIndex(index);
    end);

    if (ok ~= true) then
        return nil, false;
    end

    return tonumber(targetIndex) or 0, true;
end

local function ResolveServerId(serverId, index)
    serverId = tonumber(serverId) or 0;

    if (serverId ~= 0) then
        return serverId;
    end

    return GetServerId(index);
end

local function GetIndexFromServerId(serverId)
    return entityResolver.GetIndex(serverId);
end

local function IsMobIndex(entityManager, index)
    local spawnFlags = SafeCall(0, function()
        return entityManager:GetSpawnFlags(index);
    end);

    return bit.band(tonumber(spawnFlags) or 0, 0x10) ~= 0;
end

local function GetOwnPetIndex()
    local memory = AshitaCore:GetMemoryManager();

    if (memory == nil) then
        return 0;
    end

    local party = memory:GetParty();

    if (party == nil) then
        return 0;
    end

    local selfIndex = SafeCall(0, function()
        return party:GetMemberTargetIndex(0);
    end);

    if (selfIndex == 0) then
        return 0;
    end

    local self = GetEntity(selfIndex);

    return tonumber(self ~= nil and self.PetTargetIndex) or 0;
end

local function IsOwnPetCommand(actorServerId, actionType)
    local ownPetIndex = GetOwnPetIndex();
    local memory = AshitaCore:GetMemoryManager();
    local party = memory ~= nil and memory:GetParty() or nil;
    local selfIndex = party ~= nil and SafeCall(0, function()
        return party:GetMemberTargetIndex(0);
    end) or 0;

    return
        ownPetIndex ~= 0 and
        tonumber(actorServerId) == tonumber(GetServerId(selfIndex)) and
        tonumber(actionType) == 6;
end

local function IsEnemyIndex(index)
    index = tonumber(index) or 0;

    if (index == 0 or (index >= 1024 and index <= 1791) or index == GetOwnPetIndex()) then
        return false;
    end

    local entityManager = GetEntityManager();
    local ent = GetEntity(index);

    if (entityManager == nil or ent == nil or ent.Name == nil or ent.Name == '' or (tonumber(ent.HPPercent) or 0) <= 0) then
        return false;
    end

    return IsMobIndex(entityManager, index);
end

local function PruneExpired()
    local now = os.clock();

    for enemyServerId, _ in pairs(enemyTargetServerIds) do
        local clock = enemyTargetClocks[enemyServerId];
        local enemyIndex = GetIndexFromServerId(enemyServerId);
        if (
            ((now - (tonumber(clock) or 0)) > targetTimeoutSeconds) or
            IsEnemyIndex(enemyIndex) ~= true
        ) then
            enemyTargetClocks[enemyServerId] = nil;
            enemyTargetServerIds[enemyServerId] = nil;
        end
    end
end

local function GetSelfServerId()
    local memory = AshitaCore:GetMemoryManager();

    if (memory == nil) then
        return nil;
    end

    local party = memory:GetParty();

    if (party == nil) then
        return nil;
    end

    local index = SafeCall(0, function()
        return party:GetMemberTargetIndex(0);
    end);

    return GetServerId(index);
end

local function IsProtectedTargetServerId(serverId, targetIndex)
    serverId = tonumber(serverId) or 0;

    if (serverId == 0) then
        return false;
    end

    local memory = AshitaCore:GetMemoryManager();
    local party = memory ~= nil and memory:GetParty() or nil;

    if (party ~= nil) then
        for slot = 0, 17 do
            local active = SafeCall(0, function()
                return party:GetMemberIsActive(slot);
            end);
            local index = SafeCall(0, function()
                return party:GetMemberTargetIndex(slot);
            end);

            if (tonumber(active) == 1 and (GetServerId(index) or 0) == serverId) then
                return true;
            end
        end
    end

    local ownPetIndex = GetOwnPetIndex();

    if (ownPetIndex ~= 0 and ((tonumber(targetIndex) or 0) == ownPetIndex or (GetServerId(ownPetIndex) or 0) == serverId)) then
        return true;
    end

    return false;
end

local function GetMode(settings)
    local mode = tostring(settings ~= nil and settings.mode or 'healer'):lower();

    if (mode == 'tank' or mode == 'both') then
        return mode;
    end

    return 'healer';
end

function enmity.HandlePacketIn(e)
    if (e == nil) then
        return;
    end

    if (e.id == 0x000A) then
        enmity.Clear();
        return;
    end

    if (e.id ~= 0x0028 or e.data_raw == nil or ashita.bits == nil) then
        return;
    end

    local ok, actorServerId, targetCount, actionType, targetServerId = pcall(function()
        return
            tonumber(ashita.bits.unpack_be(e.data_raw, 0, 40, 32)) or 0,
            tonumber(ashita.bits.unpack_be(e.data_raw, 0, 72, 6)) or 0,
            tonumber(ashita.bits.unpack_be(e.data_raw, 0, 82, 4)) or 0,
            tonumber(ashita.bits.unpack_be(e.data_raw, 0, 150, 32)) or 0;
    end);

    if (ok ~= true) then
        return;
    end

    if (actorServerId == 0 or targetServerId == 0 or actorServerId == targetServerId or targetCount <= 0) then
        return;
    end

    local actorIndex = GetIndexFromServerId(actorServerId);
    local targetIndex = GetIndexFromServerId(targetServerId);

    if (IsEnemyIndex(actorIndex) ~= true) then
        if (IsOwnPetCommand(actorServerId, actionType) == true) then
            return;
        end

        enemyTargetServerIds[actorServerId] = nil;
        enemyTargetClocks[actorServerId] = nil;
        return;
    end

    if (IsEnemyIndex(targetIndex) == true or IsProtectedTargetServerId(targetServerId, targetIndex) ~= true) then
        enemyTargetServerIds[actorServerId] = nil;
        enemyTargetClocks[actorServerId] = nil;
        return;
    end

    enemyTargetServerIds[actorServerId] = targetServerId;
    enemyTargetClocks[actorServerId] = os.clock();
end

function enmity.Clear()
    enemyTargetServerIds = {};
    enemyTargetClocks = {};
end

function enmity.GetMode(settings)
    return GetMode(settings);
end

function enmity.IsEnemyTargetingSelf(enemy)
    if (enemy == nil) then
        return false;
    end

    PruneExpired();

    local enemyIndex = tonumber(enemy.index) or GetIndexFromServerId(enemy.serverId);
    local liveTargetIndex, liveTargetAvailable = GetLiveTargetIndex(enemyIndex);
    local memory = AshitaCore:GetMemoryManager();
    local party = memory ~= nil and memory:GetParty() or nil;
    local selfIndex = party ~= nil and SafeCall(0, function()
        return party:GetMemberTargetIndex(0);
    end) or 0;

    -- A zero target is not authoritative; Ashita can briefly expose zero while
    -- the entity target is unavailable.  Keep the packet-tracked target as the
    -- fallback in that case.
    if (liveTargetAvailable == true and liveTargetIndex ~= 0) then
        return liveTargetIndex ~= 0 and tonumber(liveTargetIndex) == tonumber(selfIndex);
    end

    local serverId = ResolveServerId(enemy.serverId, enemyIndex);
    local selfServerId = GetSelfServerId();

    return serverId ~= nil and selfServerId ~= nil and enemyTargetServerIds[serverId] == selfServerId;
end

function enmity.IsServerIdTargeted(serverId, index)
    serverId = ResolveServerId(serverId, index);

    if (serverId == nil or serverId == 0) then
        return false;
    end

    PruneExpired();

    local allyIndex = tonumber(index) or 0;

    if (allyIndex == 0) then
        allyIndex = GetIndexFromServerId(serverId);
    end

    local checkedEnemyIndexes = {};
    local liveTargetKnownByServerId = {};

    local function CheckEnemyIndex(enemyIndex)
        enemyIndex = tonumber(enemyIndex) or 0;

        if (enemyIndex == 0 or checkedEnemyIndexes[enemyIndex] == true or IsEnemyIndex(enemyIndex) ~= true) then
            return false;
        end

        checkedEnemyIndexes[enemyIndex] = true;
        local liveTargetIndex, available = GetLiveTargetIndex(enemyIndex);

        if (available == true and liveTargetIndex ~= 0) then
            local enemyServerId = GetServerId(enemyIndex);
            if (enemyServerId ~= nil and enemyServerId ~= 0) then
                liveTargetKnownByServerId[enemyServerId] = true;
            end
            return liveTargetIndex ~= 0 and tonumber(liveTargetIndex) == allyIndex;
        end

        return false;
    end

    for _, enemyIndex in ipairs(engagedEnemies.GetTrackedIndexes()) do
        if (CheckEnemyIndex(enemyIndex) == true) then
            return true;
        end
    end

    for enemyServerId in pairs(enemyTargetServerIds) do
        if (CheckEnemyIndex(GetIndexFromServerId(enemyServerId)) == true) then
            return true;
        end
    end

    for enemyServerId, targetServerId in pairs(enemyTargetServerIds) do
        if (IsEnemyIndex(GetIndexFromServerId(enemyServerId)) ~= true) then
            enemyTargetServerIds[enemyServerId] = nil;
            enemyTargetClocks[enemyServerId] = nil;
        elseif liveTargetKnownByServerId[enemyServerId] ~= true and targetServerId == serverId then
            return true;
        end
    end

    return false;
end

function enmity.ShouldDrawEnemy(enemy, globalSettings)
    local settings = globalSettings ~= nil and globalSettings.enmity or nil;
    local mode = GetMode(settings);

    return settings ~= nil and settings.enabled == true and (mode == 'tank' or mode == 'both') and enmity.IsEnemyTargetingSelf(enemy) == true;
end

function enmity.ShouldDrawAlly(ally, globalSettings)
    local settings = globalSettings ~= nil and globalSettings.enmity or nil;
    local mode = GetMode(settings);

    return settings ~= nil and settings.enabled == true and (mode == 'healer' or mode == 'both') and ally ~= nil and enmity.IsServerIdTargeted(ally.serverId, ally.index) == true;
end

local function GetMarkerSettings(settings, role)
    settings = settings or {};

    if (role == 'enemy') then
        return {
            iconFile = settings.enemyIconFile or settings.iconFile or 'shield-alert.png',
            color = settings.enemyColor or settings.color or { 0.25, 0.85, 1.0, 1.0 },
            iconSize = tonumber(settings.enemyIconSize) or tonumber(settings.iconSize) or 31,
            offsetX = tonumber(settings.enemyOffsetX) or tonumber(settings.offsetX) or -108,
            offsetY = tonumber(settings.enemyOffsetY) or tonumber(settings.offsetY) or -17,
            anchorTo = settings.enemyAnchorTo or settings.anchorTo,
            anchorPoint = settings.enemyAnchorPoint or settings.anchorPoint,
            anchorCollapse = settings.enemyAnchorCollapse,
            anchorSpacing = settings.enemyAnchorSpacing,
            anchorOrder = settings.enemyAnchorOrder,
        };
    end

    return {
        iconFile = settings.allyIconFile or settings.iconFile or 'warning-dimond.png',
        color = settings.allyColor or settings.color or { 1.0, 0.28, 0.20, 1.0 },
        iconSize = tonumber(settings.allyIconSize) or tonumber(settings.iconSize) or 31,
        offsetX = tonumber(settings.allyOffsetX) or tonumber(settings.offsetX) or -108,
        offsetY = tonumber(settings.allyOffsetY) or tonumber(settings.offsetY) or -17,
        anchorTo = settings.allyAnchorTo or settings.anchorTo,
        anchorPoint = settings.allyAnchorPoint or settings.anchorPoint,
        anchorCollapse = settings.allyAnchorCollapse,
        anchorSpacing = settings.allyAnchorSpacing,
        anchorOrder = settings.allyAnchorOrder,
    };
end

function enmity.AddIcon(plateData, settings, role)
    local marker = GetMarkerSettings(settings, role);
    local textureId = enmityIcons.GetTextureId(marker.iconFile);

    if (plateData == nil or settings == nil or textureId == nil) then
        return;
    end

    plateData.icons = plateData.icons or {};
    plateData.icons[#plateData.icons + 1] = {
        kind = 'enmity',
        textureId = textureId,
        tint = marker.color,
        size = math.max(6, math.min(256, tonumber(marker.iconSize) or 31)),
        offsetX = tonumber(marker.offsetX) or -108,
        offsetY = tonumber(marker.offsetY) or -17,
        anchorTo = marker.anchorTo,
        anchorPoint = marker.anchorPoint,
        anchorCollapse = marker.anchorCollapse,
        anchorSpacing = marker.anchorSpacing,
        anchorOrder = marker.anchorOrder,
    };
end

return enmity;
