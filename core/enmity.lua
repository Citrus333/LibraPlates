local bit = require('bit');
local textureLoader = require('core.texture_loader');

local enmity = {};
local enemyTargetServerIds = {};
local enemyTargetClocks = {};
local enmityIconTextureId = nil;
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
    index = tonumber(index) or 0;

    if (index == 0) then
        return nil;
    end

    local entityManager = GetEntityManager();

    if (entityManager == nil) then
        return nil;
    end

    local serverId = SafeCall(nil, function()
        return entityManager:GetServerId(index);
    end);

    return tonumber(serverId);
end

local function ResolveServerId(serverId, index)
    serverId = tonumber(serverId) or 0;

    if (serverId ~= 0) then
        return serverId;
    end

    return GetServerId(index);
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

    for index = 0, 2303 do
        if ((tonumber(SafeCall(0, function() return entityManager:GetServerId(index); end)) or 0) == serverId) then
            return index;
        end
    end

    return 0;
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

    for enemyServerId, clock in pairs(enemyTargetClocks) do
        if ((now - (tonumber(clock) or 0)) > targetTimeoutSeconds) then
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

    if (mode ~= 'tank') then
        return 'healer';
    end

    return 'tank';
end

local function GetIconTextureId()
    if (enmityIconTextureId ~= nil) then
        return enmityIconTextureId;
    end

    enmityIconTextureId = textureLoader.ToTextureId(textureLoader.Load(addon.path .. '\\assets\\images\\enmity_icon.png'));
    return enmityIconTextureId;
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

    local ok, actorServerId, targetCount, targetServerId = pcall(function()
        return
            tonumber(ashita.bits.unpack_be(e.data_raw, 0, 40, 32)) or 0,
            tonumber(ashita.bits.unpack_be(e.data_raw, 0, 72, 6)) or 0,
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

    local serverId = ResolveServerId(enemy.serverId, enemy.index);
    local selfServerId = GetSelfServerId();

    return serverId ~= nil and selfServerId ~= nil and enemyTargetServerIds[serverId] == selfServerId;
end

function enmity.IsServerIdTargeted(serverId, index)
    serverId = ResolveServerId(serverId, index);

    if (serverId == nil or serverId == 0) then
        return false;
    end

    PruneExpired();

    for _, targetServerId in pairs(enemyTargetServerIds) do
        if (targetServerId == serverId) then
            return true;
        end
    end

    return false;
end

function enmity.ShouldDrawEnemy(enemy, globalSettings)
    local settings = globalSettings ~= nil and globalSettings.enmity or nil;

    return settings ~= nil and settings.enabled == true and GetMode(settings) == 'tank' and enmity.IsEnemyTargetingSelf(enemy) == true;
end

function enmity.ShouldDrawAlly(ally, globalSettings)
    local settings = globalSettings ~= nil and globalSettings.enmity or nil;

    return settings ~= nil and settings.enabled == true and GetMode(settings) == 'healer' and ally ~= nil and enmity.IsServerIdTargeted(ally.serverId, ally.index) == true;
end

function enmity.AddIcon(plateData, settings)
    local textureId = GetIconTextureId();

    if (plateData == nil or settings == nil or textureId == nil) then
        return;
    end

    plateData.icons = plateData.icons or {};
    plateData.icons[#plateData.icons + 1] = {
        kind = 'enmity',
        textureId = textureId,
        size = math.max(6, math.min(160, tonumber(settings.iconSize) or 31)),
        offsetX = tonumber(settings.offsetX) or -108,
        offsetY = tonumber(settings.offsetY) or -17,
    };
end

return enmity;
