local d3d = require('d3d8');
local ffi = require('ffi');
local bit = require('bit');
local trustNames = require('core.trust_names');
local targeting = require('core.targeting');
local petDurations = require('data.pet_durations');
local C = ffi.C;

local entities = {};
local d3d8dev = d3d.get_device();
local modelReadyCache = {};
local trustPartyVitalCache = {};
local characterModelReadyDelay = 1.50;
local trustPartyVitalReadInterval = 0.50;
local bstMainJobId = 9;
local drgMainJobId = 14;
local smnMainJobId = 15;
local pupMainJobId = 18;
local geoMainJobId = 21;
local mogHouseObjectSuppressionCache = {
    clock = 0,
    value = false,
};
local avatarPetNames = {
    ['Carbuncle'] = true,
    ['Fenrir'] = true,
    ['Ifrit'] = true,
    ['Titan'] = true,
    ['Leviathan'] = true,
    ['Garuda'] = true,
    ['Shiva'] = true,
    ['Ramuh'] = true,
    ['Diabolos'] = true,
    ['Cait Sith'] = true,
    ['Siren'] = true,
};
local spiritPetNames = {
    ['FireSpirit'] = true,
    ['IceSpirit'] = true,
    ['AirSpirit'] = true,
    ['EarthSpirit'] = true,
    ['ThunderSpirit'] = true,
    ['WaterSpirit'] = true,
    ['LightSpirit'] = true,
    ['DarkSpirit'] = true,
};
local otherPlayerPetNames = {
    ['Wyvern'] = true,
    ['Lumiere'] = true,
    ['Mnejing'] = true,
    ['Ovjang'] = true,
    ['Valkeng'] = true,
};
local normalizedPetNameSet = nil;

local function SafeCall(fallback, fn)
    local ok, result = pcall(fn);

    if (ok ~= true or result == nil) then
        return fallback;
    end

    return result;
end

local hiddenUntilAggroEnemyNames = {
    ['chigoe'] = true,
    ['greateramphiptere'] = true,
};

local function NormalizeEnemyName(name)
    return tostring(name or ''):lower():gsub('[^%w]', '');
end

local function IsHiddenUntilAggroEnemy(ent)
    if (ent == nil or hiddenUntilAggroEnemyNames[NormalizeEnemyName(ent.Name)] ~= true) then
        return false;
    end

    return tonumber(ent.Status) == 0;
end

function entities.IsHiddenUntilAggroEnemyNameStatus(name, status)
    if (hiddenUntilAggroEnemyNames[NormalizeEnemyName(name)] ~= true) then
        return false;
    end

    return tonumber(status) == 0;
end

-- ============================================================
-- Matrix helpers
-- ============================================================

local function MatrixMultiply(m1, m2)
    return ffi.new('D3DXMATRIX', {
        m1._11 * m2._11 + m1._12 * m2._21 + m1._13 * m2._31 + m1._14 * m2._41,
        m1._11 * m2._12 + m1._12 * m2._22 + m1._13 * m2._32 + m1._14 * m2._42,
        m1._11 * m2._13 + m1._12 * m2._23 + m1._13 * m2._33 + m1._14 * m2._43,
        m1._11 * m2._14 + m1._12 * m2._24 + m1._13 * m2._34 + m1._14 * m2._44,
        m1._21 * m2._11 + m1._22 * m2._21 + m1._23 * m2._31 + m1._24 * m2._41,
        m1._21 * m2._12 + m1._22 * m2._22 + m1._23 * m2._32 + m1._24 * m2._42,
        m1._21 * m2._13 + m1._22 * m2._23 + m1._23 * m2._33 + m1._24 * m2._43,
        m1._21 * m2._14 + m1._22 * m2._24 + m1._23 * m2._34 + m1._24 * m2._44,
        m1._31 * m2._11 + m1._32 * m2._21 + m1._33 * m2._31 + m1._34 * m2._41,
        m1._31 * m2._12 + m1._32 * m2._22 + m1._33 * m2._32 + m1._34 * m2._42,
        m1._31 * m2._13 + m1._32 * m2._23 + m1._33 * m2._33 + m1._34 * m2._43,
        m1._31 * m2._14 + m1._32 * m2._24 + m1._33 * m2._34 + m1._34 * m2._44,
        m1._41 * m2._11 + m1._42 * m2._21 + m1._43 * m2._31 + m1._44 * m2._41,
        m1._41 * m2._12 + m1._42 * m2._22 + m1._43 * m2._32 + m1._44 * m2._42,
        m1._41 * m2._13 + m1._42 * m2._23 + m1._43 * m2._33 + m1._44 * m2._43,
        m1._41 * m2._14 + m1._42 * m2._24 + m1._43 * m2._34 + m1._44 * m2._44,
    });
end

local function Vec4Transform(v, m)
    return ffi.new('D3DXVECTOR4', {
        m._11 * v.x + m._21 * v.y + m._31 * v.z + m._41 * v.w,
        m._12 * v.x + m._22 * v.y + m._32 * v.z + m._42 * v.w,
        m._13 * v.x + m._23 * v.y + m._33 * v.z + m._43 * v.w,
        m._14 * v.x + m._24 * v.y + m._34 * v.z + m._44 * v.w,
    });
end

local function WorldToScreen(x, y, z)
    if (d3d8dev == nil) then
        return nil, nil, nil;
    end

    local _, viewport = d3d8dev:GetViewport();
    local _, view = d3d8dev:GetTransform(C.D3DTS_VIEW);
    local _, projection = d3d8dev:GetTransform(C.D3DTS_PROJECTION);
    local vector = ffi.new('D3DXVECTOR4', { x, y, z, 1 });
    local camera = Vec4Transform(vector, MatrixMultiply(view, projection));

    if (camera.w == 0) then
        return nil, nil, nil;
    end

    local rhw = 1 / camera.w;
    local ndcX = camera.x * rhw;
    local ndcY = camera.y * rhw;
    local ndcZ = camera.z * rhw;
    local screenX = math.floor((ndcX + 1) * 0.5 * viewport.Width);
    local screenY = math.floor((1 - ndcY) * 0.5 * viewport.Height);

    return screenX, screenY, ndcZ;
end

function entities.RefreshDevice()
    d3d8dev = d3d.get_device();
    return d3d8dev ~= nil;
end

function entities.ResetDevice()
    d3d8dev = nil;
end

local function GetBone(actorPointer, bone)
    local x = ashita.memory.read_float(actorPointer + 0x678);
    local y = ashita.memory.read_float(actorPointer + 0x680);
    local z = ashita.memory.read_float(actorPointer + 0x67C);
    local skeletonBaseAddress = ashita.memory.read_uint32(actorPointer + 0x6B8);

    if (skeletonBaseAddress == 0) then
        return x, y, z;
    end

    local skeletonOffsetAddress = ashita.memory.read_uint32(skeletonBaseAddress + 0x0C);

    if (skeletonOffsetAddress == 0) then
        return x, y, z;
    end

    local skeletonAddress = ashita.memory.read_uint32(skeletonOffsetAddress);

    if (skeletonAddress == 0) then
        return x, y, z;
    end

    local boneCount = ashita.memory.read_uint16(skeletonAddress + 0x32);
    local bufferPointer = skeletonAddress + 0x30;
    local skeletonSize = 0x04;
    local boneSize = 0x1E;
    local generatorsAddress = bufferPointer + skeletonSize + boneSize * boneCount + 4;

    return
        x + ashita.memory.read_float(generatorsAddress + (bone * 0x1A) + 0x0E + 0x0),
        y + ashita.memory.read_float(generatorsAddress + (bone * 0x1A) + 0x0E + 0x8),
        z + ashita.memory.read_float(generatorsAddress + (bone * 0x1A) + 0x0E + 0x4);
end

local function IsMobIndex(entityManager, index)
    local ok, spawnFlags = pcall(function()
        return entityManager:GetSpawnFlags(index);
    end);

    return ok == true and spawnFlags ~= nil and bit.band(spawnFlags, 0x10) ~= 0;
end

local function IsActivePartyMemberIndex(index)
    index = tonumber(index);

    if (index == nil or index == 0) then
        return false;
    end

    local party = AshitaCore:GetMemoryManager():GetParty();

    if (party == nil) then
        return false;
    end

    for slot = 0, 17 do
        local active = 0;
        local memberIndex = 0;

        pcall(function()
            active = party:GetMemberIsActive(slot);
        end);

        pcall(function()
            memberIndex = party:GetMemberTargetIndex(slot);
        end);

        if (active == 1 and tonumber(memberIndex) == index) then
            return true;
        end
    end

    return false;
end

local function IsNpcObjectStatusAllowed(status)
    return status == nil or status == 0 or status == 32 or status == 33 or status == 34 or status == 38 or status == 39 or status == 40 or status == 41 or status == 47 or status == 50;
end

local function IsTrustStatusAllowed(status)
    return status == nil or status == 0 or status == 1 or status == 33 or status == 34 or status == 47;
end

local IsVisibleEntity = nil;

local function HasLoadedSkeleton(entityManager, index)
    index = tonumber(index);

    if (entityManager == nil or index == nil) then
        return false;
    end

    local okActor, actorPointer = pcall(function()
        return entityManager:GetActorPointer(index);
    end);

    if (okActor ~= true) then
        return false;
    end

    if (actorPointer == nil or actorPointer == 0) then
        return false;
    end

    local ok, skeletonBase = pcall(function()
        return ashita.memory.read_uint32(actorPointer + 0x6B8);
    end);

    return ok == true and skeletonBase ~= nil and skeletonBase ~= 0;
end

local function HasSettledCharacterModel(entityManager, index)
    index = tonumber(index);

    if (entityManager == nil or index == nil) then
        return false;
    end

    local okActor, actorPointer = pcall(function()
        return entityManager:GetActorPointer(index);
    end);

    if (okActor ~= true) then
        modelReadyCache[index] = nil;
        return false;
    end

    if (actorPointer == nil or actorPointer == 0 or HasLoadedSkeleton(entityManager, index) ~= true) then
        modelReadyCache[index] = nil;
        return false;
    end

    local now = os.clock();
    local entry = modelReadyCache[index];

    if (entry == nil or entry.actorPointer ~= actorPointer) then
        modelReadyCache[index] = {
            actorPointer = actorPointer,
            readyAt = now + characterModelReadyDelay,
        };
        return false;
    end

    return now >= entry.readyAt;
end

local function IsPlayerIndexRange(index)
    index = tonumber(index);
    return index ~= nil and index >= 1024 and index <= 1791;
end

local function IsPlayerActorEntity(ent, index)
    if (ent == nil) then
        return false;
    end

    if (tonumber(ent.Type) == 0) then
        return true;
    end

    return IsPlayerIndexRange(index) == true and tonumber(ent.Type) == 2;
end

local function IsInvisiblePlayerActor(entityManager, index, actorPointer)
    if (entityManager == nil or IsPlayerIndexRange(index) ~= true or actorPointer == nil or actorPointer == 0) then
        return false;
    end

    local ok, alphaA, alphaB, alphaC, alphaD = pcall(function()
        return
            ashita.memory.read_uint8(actorPointer + 0x663),
            ashita.memory.read_uint8(actorPointer + 0x666),
            ashita.memory.read_uint8(actorPointer + 0x667),
            ashita.memory.read_uint8(actorPointer + 0x66C);
    end);

    if (ok ~= true) then
        return false;
    end

    return
        tonumber(alphaA) == 0 and
        tonumber(alphaB) == 0 and
        tonumber(alphaC) == 0 and
        tonumber(alphaD) == 0;
end

local function GetSkeletonBoneCount(actorPointer)
    if (actorPointer == nil or actorPointer == 0) then
        return nil;
    end

    local ok, boneCount = pcall(function()
        local skeletonBaseAddress = ashita.memory.read_uint32(actorPointer + 0x6B8);

        if (skeletonBaseAddress == 0) then
            return nil;
        end

        local skeletonOffsetAddress = ashita.memory.read_uint32(skeletonBaseAddress + 0x0C);

        if (skeletonOffsetAddress == 0) then
            return nil;
        end

        local skeletonAddress = ashita.memory.read_uint32(skeletonOffsetAddress);

        if (skeletonAddress == 0) then
            return nil;
        end

        return ashita.memory.read_uint16(skeletonAddress + 0x32);
    end);

    if (ok ~= true) then
        return nil;
    end

    return tonumber(boneCount);
end

local function IsObjectCostumePlayer(entityManager, index, ent)
    if (
        entityManager == nil or
        IsPlayerIndexRange(index) ~= true or
        tonumber(ent ~= nil and ent.Type or nil) ~= 2
    ) then
        return false;
    end

    local actorPointer = SafeCall(nil, function()
        return entityManager:GetActorPointer(index);
    end);
    local boneCount = GetSkeletonBoneCount(actorPointer);

    return boneCount ~= nil and boneCount > 0 and boneCount <= 8;
end

local function IsCampaignBattleActor(entityManager, index, ent)
    if (entityManager == nil or ent == nil or tonumber(ent.Type) ~= 0) then
        return false;
    end

    if (entities.IsPartyMemberIndex(index) == true) then
        return false;
    end

    local spawnFlags = tonumber(SafeCall(nil, function()
        return entityManager:GetSpawnFlags(index);
    end)) or 0;
    local renderFlags1 = tonumber(SafeCall(nil, function()
        return entityManager:GetRenderFlags1(index);
    end)) or 0;

    return
        bit.band(spawnFlags, 0x02) == 0x02 and
        bit.band(renderFlags1, 0x800) == 0x800 and
        tonumber(ent.HPPercent) ~= nil and
        tonumber(ent.HPPercent) > 0;
end

function entities.GetEntityManager()
    return AshitaCore:GetMemoryManager():GetEntity();
end

function entities.GetEntity(index)
    index = tonumber(index);

    if (index == nil or index <= 0) then
        return nil;
    end

    return SafeCall(nil, function()
        return GetEntity(index);
    end);
end

function entities.GetBone(actorPointer, bone)
    return GetBone(actorPointer, bone);
end

function entities.GetSelf()
    local party = AshitaCore:GetMemoryManager():GetParty();
    local targetIndex = party:GetMemberTargetIndex(0);

    if (targetIndex == nil or targetIndex <= 0) then
        return nil;
    end

    local entity = GetEntity(targetIndex);

    if (entity == nil) then
        return nil;
    end

    local hp = nil;
    local maxHp = nil;
    local hpPercent = nil;
    local mp = nil;
    local maxMp = nil;
    local mpPercent = nil;
    local tp = nil;
    local serverId = nil;

    pcall(function()
        hp = party:GetMemberHP(0);
    end);

    pcall(function()
        maxHp = party:GetMemberMaxHP(0);
    end);

    pcall(function()
        hpPercent = party:GetMemberHPPercent(0);
    end);

    pcall(function()
        mp = party:GetMemberMP(0);
    end);

    pcall(function()
        maxMp = party:GetMemberMaxMP(0);
    end);

    pcall(function()
        mpPercent = party:GetMemberMPPercent(0);
    end);

    pcall(function()
        tp = party:GetMemberTP(0);
    end);

    pcall(function()
        serverId = AshitaCore:GetMemoryManager():GetEntity():GetServerId(targetIndex);
    end);

    if ((hpPercent == nil or hpPercent <= 0) and hp ~= nil and maxHp ~= nil and maxHp > 0) then
        hpPercent = math.floor(((hp / maxHp) * 100) + 0.5);
    end

    if ((mpPercent == nil or mpPercent <= 0) and mp ~= nil and maxMp ~= nil and maxMp > 0) then
        mpPercent = math.floor(((mp / maxMp) * 100) + 0.5);
    end

    return {
        index = targetIndex,
        serverId = serverId,
        name = entity.Name or 'Self',
        status = entity.Status,
        hp = hp,
        maxHp = maxHp,
        hpPercent = hpPercent,
        mp = mp,
        maxMp = maxMp,
        mpPercent = mpPercent,
        tp = tp,
    };
end

function entities.GetSelfCanvasCenter(offsetX, offsetY)
    local self = entities.GetSelf();

    if (self == nil) then
        return nil;
    end

    local entityManager = AshitaCore:GetMemoryManager():GetEntity();
    local actorPointer = entityManager:GetActorPointer(self.index);

    if (actorPointer == nil or actorPointer == 0) then
        return nil;
    end

    local visibleSkeleton = HasLoadedSkeleton(entityManager, self.index);

    local boneWorldX = nil;
    local boneWorldY = nil;
    local boneWorldZ = nil;
    local ok, screenX, screenY, screenZ = pcall(function()
        local boneX, boneY, boneZ = GetBone(actorPointer, 2);
        boneWorldX = boneX;
        boneWorldY = boneY;
        boneWorldZ = boneZ;
        return WorldToScreen(boneX, boneZ, boneY);
    end);

    if (ok ~= true or screenX == nil or screenY == nil or screenZ == nil) then
        return nil;
    end

    if (screenZ < 0 or screenZ > 1) then
        return nil;
    end

    return {
        x = screenX + (tonumber(offsetX) or 0),
        y = screenY - (tonumber(offsetY) or 0),
        z = screenZ,
        boneScreenX = screenX,
        boneScreenY = screenY,
        boneScreenZ = screenZ,
        boneWorldX = boneWorldX,
        boneWorldY = boneWorldY,
        boneWorldZ = boneWorldZ,
        visibleSkeleton = visibleSkeleton,
        name = self.name,
        index = self.index,
        hp = self.hp,
        maxHp = self.maxHp,
        hpPercent = self.hpPercent,
        mp = self.mp,
        maxMp = self.maxMp,
        mpPercent = self.mpPercent,
        tp = self.tp,
        status = self.status,
        serverId = self.serverId,
    };
end

function entities.IsEnemy(index)
    index = tonumber(index);

    if (index == nil or index == 0) then
        return false;
    end

    if (index >= 1024 and index <= 1791) then
        return false;
    end

    if (entities.IsOwnPetIndex(index) == true) then
        return false;
    end

    local entityManager = AshitaCore:GetMemoryManager():GetEntity();

    if (entityManager == nil) then
        return false;
    end

    local ent = GetEntity(index);

    if (ent == nil or ent.Name == nil or ent.Name == '' or ent.HPPercent == nil or ent.HPPercent <= 0) then
        return false;
    end

    if (IsMobIndex(entityManager, index) ~= true) then
        return false;
    end

    local ok, renderFlags = pcall(function()
        return entityManager:GetRenderFlags0(index);
    end);

    if (ok ~= true or renderFlags == nil) then
        return false;
    end

    if (bit.band(renderFlags, 0x200) ~= 0x200 or bit.band(renderFlags, 0x4000) ~= 0) then
        return false;
    end

    if (IsHiddenUntilAggroEnemy(ent) == true) then
        return false;
    end

    if (IsVisibleEntity(entityManager, index, false) ~= true) then
        return false;
    end

    return true;
end

function entities.GetEnemy(index, allowHidden)
    index = tonumber(index);

    if (index == nil or index == 0) then
        return nil;
    end

    local entityManager = AshitaCore:GetMemoryManager():GetEntity();

    if (entityManager == nil) then
        return nil;
    end

    local ent = GetEntity(index);

    if (ent == nil or ent.Name == nil or ent.Name == '' or ent.HPPercent == nil or ent.HPPercent <= 0) then
        return nil;
    end

    if (IsMobIndex(entityManager, index) ~= true or IsActivePartyMemberIndex(index) == true) then
        return nil;
    end

    if (allowHidden ~= true and entities.IsEnemy(index) ~= true) then
        return nil;
    end

    local serverId = nil;

    pcall(function()
        serverId = entityManager:GetServerId(index);
    end);

    local renderFlags0 = SafeCall(nil, function()
        return entityManager:GetRenderFlags0(index);
    end);
    local renderFlags1 = SafeCall(nil, function()
        return entityManager:GetRenderFlags1(index);
    end);
    local spawnFlags = SafeCall(nil, function()
        return entityManager:GetSpawnFlags(index);
    end);

    return {
        index = index,
        serverId = serverId,
        name = ent.Name or 'Enemy',
        status = ent.Status,
        hpPercent = ent.HPPercent or 100,
        distance = ent.Distance ~= nil and math.sqrt(ent.Distance) or nil,
        spawnFlags = spawnFlags,
        renderFlags0 = renderFlags0,
        renderFlags1 = renderFlags1,
    };
end

function entities.GetNearbyEnemies(maxDistance)
    local results = {};
    local maxDistanceSq = (tonumber(maxDistance) or 50) * (tonumber(maxDistance) or 50);
    local entityManager = AshitaCore:GetMemoryManager():GetEntity();
    local ownPetIndex = entities.GetOwnPetTargetIndex();

    if (entityManager == nil) then
        return results;
    end

    for index = 0, 2303 do
        if (index < 1024 or index > 1791) then
            local ent = GetEntity(index);

            if (
                ent ~= nil and
                ent.Name ~= nil and
                ent.Name ~= '' and
                ent.HPPercent ~= nil and
                ent.HPPercent > 0 and
                ent.Distance ~= nil and
                ent.Distance <= maxDistanceSq and
                tonumber(index) ~= tonumber(ownPetIndex) and
                IsActivePartyMemberIndex(index) ~= true and
                IsMobIndex(entityManager, index) == true and
                IsHiddenUntilAggroEnemy(ent) ~= true and
                IsVisibleEntity(entityManager, index, false) == true
            ) then
                local serverId = nil;

                pcall(function()
                    serverId = entityManager:GetServerId(index);
                end);

                results[#results + 1] = {
                    index = index,
                    serverId = serverId,
                    name = ent.Name or 'Enemy',
                    status = ent.Status,
                    hpPercent = ent.HPPercent or 100,
                    distance = math.sqrt(ent.Distance),
                    spawnFlags = SafeCall(nil, function() return entityManager:GetSpawnFlags(index); end),
                    renderFlags0 = SafeCall(nil, function() return entityManager:GetRenderFlags0(index); end),
                    renderFlags1 = SafeCall(nil, function() return entityManager:GetRenderFlags1(index); end),
                };
            end
        end
    end

    table.sort(results, function(a, b)
        return (tonumber(a.distance) or 0) < (tonumber(b.distance) or 0);
    end);

    return results;
end

IsVisibleEntity = function(entityManager, index, requireSkeleton, allowInvisiblePlayer)
    local ok, renderFlags = pcall(function()
        return entityManager:GetRenderFlags0(index);
    end);

    if (ok ~= true or renderFlags == nil) then
        return false;
    end

    if (bit.band(renderFlags, 0x200) ~= 0x200 or bit.band(renderFlags, 0x4000) ~= 0) then
        return false;
    end

    local actorPointer = entityManager:GetActorPointer(index);

    if (actorPointer == nil or actorPointer == 0) then
        return false;
    end

    if (allowInvisiblePlayer ~= true and IsInvisiblePlayerActor(entityManager, index, actorPointer) == true) then
        return false;
    end

    if (requireSkeleton == true and HasSettledCharacterModel(entityManager, index) ~= true) then
        return false;
    end

    return true;
end

local function IsLoadedIdlePlayerEntity(entityManager, index)
    if (entityManager == nil or IsPlayerIndexRange(index) ~= true) then
        return false;
    end

    local okFlags, renderFlags = pcall(function()
        return entityManager:GetRenderFlags0(index);
    end);

    if (okFlags ~= true or renderFlags == nil or bit.band(renderFlags, 0x4000) ~= 0) then
        return false;
    end

    local okActor, actorPointer = pcall(function()
        return entityManager:GetActorPointer(index);
    end);

    return
        okActor == true and
        actorPointer ~= nil and
        actorPointer ~= 0 and
        HasLoadedSkeleton(entityManager, index) == true;
end

local function GetSelfIndex()
    local selfIndex = nil;

    pcall(function()
        selfIndex = AshitaCore:GetMemoryManager():GetParty():GetMemberTargetIndex(0);
    end);

    return selfIndex;
end

function entities.GetOwnPetTargetIndex()
    local selfIndex = GetSelfIndex();

    if (selfIndex == nil or selfIndex == 0) then
        return nil;
    end

    local entityManager = AshitaCore:GetMemoryManager():GetEntity();
    local petIndex = nil;

    if (entityManager ~= nil and entityManager.GetPetTargetIndex ~= nil) then
        pcall(function()
            petIndex = entityManager:GetPetTargetIndex(selfIndex);
        end);
    end

    if (tonumber(petIndex) ~= nil and tonumber(petIndex) ~= 0) then
        return tonumber(petIndex);
    end

    -- Older Ashita builds may not expose GetPetTargetIndex; retain the entity
    -- field as a compatibility fallback rather than using it as the live source.
    local playerEntity = GetEntity(selfIndex);

    if (playerEntity == nil or playerEntity.PetTargetIndex == nil or tonumber(playerEntity.PetTargetIndex) == 0) then
        return nil;
    end

    return tonumber(playerEntity.PetTargetIndex);
end

function entities.IsOwnPetIndex(index)
    local petIndex = entities.GetOwnPetTargetIndex();

    return petIndex ~= nil and tonumber(index) == petIndex;
end

function entities.IsOwnLuopanIndex(index)
    return entities.GetPlayerMainJobId() == geoMainJobId and entities.IsOwnPetIndex(index) == true;
end

local function NormalizePetName(name)
    local rawName = tostring(name or ''):gsub('\170', '');
    rawName = rawName:gsub('%c', '');
    rawName = rawName:gsub('^%s+', ''):gsub('%s+$', '');
    rawName = rawName:gsub('[^%w%s]', '');
    rawName = rawName:gsub('%s+', '');

    return string.lower(rawName);
end

local function GetNormalizedPetNameSet()
    if (normalizedPetNameSet ~= nil) then
        return normalizedPetNameSet;
    end

    normalizedPetNameSet = {};

    for name, _ in pairs(avatarPetNames) do
        normalizedPetNameSet[NormalizePetName(name)] = true;
    end

    for name, _ in pairs(spiritPetNames) do
        normalizedPetNameSet[NormalizePetName(name)] = true;
    end

    for name, _ in pairs(otherPlayerPetNames) do
        normalizedPetNameSet[NormalizePetName(name)] = true;
    end

    for name, _ in pairs(petDurations.bstJugMinutes or {}) do
        normalizedPetNameSet[NormalizePetName(name)] = true;
    end

    return normalizedPetNameSet;
end

function entities.IsKnownPetName(name)
    return GetNormalizedPetNameSet()[NormalizePetName(name)] == true;
end

function entities.IsSummonedPetTypeText(typeText)
    local text = tostring(typeText or ''):lower();

    return text:find('summoned avatar', 1, true) ~= nil;
end

function entities.ShouldHideOtherPlayerPet(index, name)
    local settings = targeting.GetSettings();

    if (settings.hideOtherPlayerPetPlates == false) then
        return false;
    end

    if (entities.IsOwnPetIndex(index) == true) then
        return false;
    end

    return entities.IsKnownPetName(name) == true;
end

local function GetPartyVitalsByTargetIndex(index)
    index = tonumber(index);

    if (index == nil or index == 0) then
        return nil;
    end

    local party = AshitaCore:GetMemoryManager():GetParty();

    if (party == nil) then
        return nil;
    end

    for slot = 0, 17 do
        local active = 0;
        local memberIndex = 0;

        pcall(function()
            active = party:GetMemberIsActive(slot);
        end);

        pcall(function()
            memberIndex = party:GetMemberTargetIndex(slot);
        end);

        if (active == 1 and tonumber(memberIndex) == index) then
            local vitals = {};

            pcall(function()
                vitals.hp = tonumber(party:GetMemberHP(slot));
            end);

            pcall(function()
                vitals.maxHp = tonumber(party:GetMemberMaxHP(slot));
            end);

            pcall(function()
                vitals.hpPercent = tonumber(party:GetMemberHPPercent(slot));
            end);

            return vitals;
        end
    end

    return nil;
end

local function TryPartyNumber(party, slot, names)
    if (party == nil) then
        return nil;
    end

    for _, name in ipairs(names or {}) do
        local fn = party[name];

        if (fn ~= nil) then
            local ok, value = pcall(function()
                return fn(party, slot);
            end);

            if (ok == true and tonumber(value) ~= nil) then
                return tonumber(value);
            end
        end
    end

    return nil;
end

local function GetPartyMemberDataByTargetIndex(index)
    index = tonumber(index);

    if (index == nil or index == 0) then
        return nil;
    end

    local party = AshitaCore:GetMemoryManager():GetParty();

    if (party == nil) then
        return nil;
    end

    for slot = 0, 17 do
        local active = 0;
        local memberIndex = 0;

        pcall(function()
            active = party:GetMemberIsActive(slot);
        end);

        pcall(function()
            memberIndex = party:GetMemberTargetIndex(slot);
        end);

        if (active == 1 and tonumber(memberIndex) == index) then
            local data = {
                slot = slot,
            };

            data.hp = TryPartyNumber(party, slot, { 'GetMemberHP' });
            data.maxHp = TryPartyNumber(party, slot, { 'GetMemberMaxHP' });
            data.hpPercent = TryPartyNumber(party, slot, { 'GetMemberHPPercent' });
            data.mp = TryPartyNumber(party, slot, { 'GetMemberMP' });
            data.maxMp = TryPartyNumber(party, slot, { 'GetMemberMaxMP' });
            data.mpPercent = TryPartyNumber(party, slot, { 'GetMemberMPPercent' });
            data.tp = TryPartyNumber(party, slot, { 'GetMemberTP' });
            data.mainJob = TryPartyNumber(party, slot, { 'GetMemberMainJob', 'GetMemberMainJobId', 'GetMemberJob', 'GetMemberJobId' });
            data.mainJobLevel = TryPartyNumber(party, slot, { 'GetMemberMainJobLevel', 'GetMemberMainLevel', 'GetMemberLevel' });
            if ((data.hpPercent == nil or data.hpPercent <= 0) and data.hp ~= nil and data.maxHp ~= nil and data.maxHp > 0) then
                data.hpPercent = math.floor(((data.hp / data.maxHp) * 100) + 0.5);
            end

            if ((data.mpPercent == nil or data.mpPercent <= 0) and data.mp ~= nil and data.maxMp ~= nil and data.maxMp > 0) then
                data.mpPercent = math.floor(((data.mp / data.maxMp) * 100) + 0.5);
            end

            return data;
        end
    end

    return nil;
end

local function BuildPartyMemberDataByTargetIndex()
    local byIndex = {};
    local party = AshitaCore:GetMemoryManager():GetParty();

    if (party == nil) then
        return byIndex;
    end

    for slot = 0, 17 do
        local active = 0;
        local memberIndex = 0;

        pcall(function()
            active = party:GetMemberIsActive(slot);
        end);

        pcall(function()
            memberIndex = party:GetMemberTargetIndex(slot);
        end);

        memberIndex = tonumber(memberIndex) or 0;

        if (active == 1 and memberIndex > 0) then
            local data = {
                slot = slot,
            };

            data.hp = TryPartyNumber(party, slot, { 'GetMemberHP' });
            data.maxHp = TryPartyNumber(party, slot, { 'GetMemberMaxHP' });
            data.hpPercent = TryPartyNumber(party, slot, { 'GetMemberHPPercent' });
            data.mp = TryPartyNumber(party, slot, { 'GetMemberMP' });
            data.maxMp = TryPartyNumber(party, slot, { 'GetMemberMaxMP' });
            data.mpPercent = TryPartyNumber(party, slot, { 'GetMemberMPPercent' });
            data.tp = TryPartyNumber(party, slot, { 'GetMemberTP' });
            data.mainJob = TryPartyNumber(party, slot, { 'GetMemberMainJob', 'GetMemberMainJobId', 'GetMemberJob', 'GetMemberJobId' });
            data.mainJobLevel = TryPartyNumber(party, slot, { 'GetMemberMainJobLevel', 'GetMemberMainLevel', 'GetMemberLevel' });

            if ((data.hpPercent == nil or data.hpPercent <= 0) and data.hp ~= nil and data.maxHp ~= nil and data.maxHp > 0) then
                data.hpPercent = math.floor(((data.hp / data.maxHp) * 100) + 0.5);
            end

            if ((data.mpPercent == nil or data.mpPercent <= 0) and data.mp ~= nil and data.maxMp ~= nil and data.maxMp > 0) then
                data.mpPercent = math.floor(((data.mp / data.maxMp) * 100) + 0.5);
            end

            byIndex[memberIndex] = data;
        end
    end

    return byIndex;
end

function entities.GetPlayerMainJobId()
    local party = AshitaCore:GetMemoryManager():GetParty();
    local job = nil;

    if (party == nil) then
        return nil;
    end

    pcall(function()
        job = party:GetMemberMainJob(0);
    end);

    return tonumber(job);
end

function entities.GetPlayerSubJobId()
    local memory = AshitaCore:GetMemoryManager();
    local party = memory:GetParty();
    local job = nil;

    if (party ~= nil) then
        pcall(function()
            if (party.GetMemberSubJob ~= nil) then
                job = party:GetMemberSubJob(0);
            elseif (party.GetMemberSubJobId ~= nil) then
                job = party:GetMemberSubJobId(0);
            end
        end);
    end

    if (tonumber(job) == nil) then
        pcall(function()
            local player = memory:GetPlayer();

            if (player ~= nil and player.GetSubJob ~= nil) then
                job = player:GetSubJob();
            end
        end);
    end

    return tonumber(job);
end

function entities.GetOwnBstPet()
    if (entities.GetPlayerMainJobId() ~= bstMainJobId) then
        return nil;
    end

    local index = entities.GetOwnPetTargetIndex();
    local entityManager = AshitaCore:GetMemoryManager():GetEntity();

    if (index == nil or entityManager == nil or IsVisibleEntity(entityManager, index, true) ~= true) then
        return nil;
    end

    local ent = GetEntity(index);

    if (ent == nil or ent.Name == nil or ent.Name == '' or ent.Distance == nil) then
        return nil;
    end

    local player = AshitaCore:GetMemoryManager():GetPlayer();
    local vitals = GetPartyVitalsByTargetIndex(index);
    local tp = nil;
    local mpPercent = nil;
    local serverId = nil;

    if (player ~= nil) then
        pcall(function()
            tp = player:GetPetTP();
        end);

        pcall(function()
            mpPercent = player:GetPetMPPercent();
        end);
    end

    pcall(function()
        serverId = entityManager:GetServerId(index);
    end);

    return {
        index = index,
        serverId = serverId,
        name = ent.Name,
        status = ent.Status,
        distance = math.sqrt(ent.Distance),
        hp = vitals ~= nil and vitals.hp or nil,
        maxHp = vitals ~= nil and vitals.maxHp or nil,
        hpPercent = (vitals ~= nil and vitals.hpPercent) or ent.HPPercent or 100,
        mpPercent = mpPercent,
        tp = tp,
    };
end

local function GetOwnPet()
    local index = entities.GetOwnPetTargetIndex();
    local entityManager = AshitaCore:GetMemoryManager():GetEntity();

    if (index == nil or entityManager == nil or IsVisibleEntity(entityManager, index, true) ~= true) then
        return nil;
    end

    local ent = GetEntity(index);

    if (ent == nil or ent.Name == nil or ent.Name == '' or ent.Distance == nil) then
        return nil;
    end

    local player = AshitaCore:GetMemoryManager():GetPlayer();
    local vitals = GetPartyVitalsByTargetIndex(index);
    local tp = nil;
    local mpPercent = nil;
    local serverId = nil;

    if (player ~= nil) then
        pcall(function()
            tp = player:GetPetTP();
        end);

        pcall(function()
            mpPercent = player:GetPetMPPercent();
        end);
    end

    pcall(function()
        serverId = entityManager:GetServerId(index);
    end);

    return {
        index = index,
        serverId = serverId,
        name = ent.Name,
        status = ent.Status,
        distance = math.sqrt(ent.Distance),
        hp = vitals ~= nil and vitals.hp or nil,
        maxHp = vitals ~= nil and vitals.maxHp or nil,
        hpPercent = (vitals ~= nil and vitals.hpPercent) or ent.HPPercent or 100,
        mpPercent = mpPercent,
        tp = tp,
    };
end

function entities.GetOwnSmnPet()
    if (entities.GetPlayerMainJobId() ~= smnMainJobId) then
        return nil;
    end

    local pet = GetOwnPet();

    if (pet == nil) then
        return nil;
    end

    local compactName = tostring(pet.name or ''):gsub('%s+', '');

    if (avatarPetNames[tostring(pet.name or '')] == true) then
        pet.petType = 'avatar';
        return pet;
    end

    if (spiritPetNames[compactName] == true) then
        pet.petType = 'spirit';
        return pet;
    end

    return nil;
end

function entities.GetOwnDrgPet()
    if (entities.GetPlayerMainJobId() ~= drgMainJobId) then
        return nil;
    end

    local pet = GetOwnPet();

    if (pet == nil) then
        return nil;
    end

    pet.petType = 'wyvern';
    return pet;
end

function entities.GetOwnPupPet()
    if (entities.GetPlayerMainJobId() ~= pupMainJobId) then
        return nil;
    end

    local pet = GetOwnPet();

    if (pet == nil) then
        return nil;
    end

    pet.petType = 'pup';
    return pet;
end

function entities.GetOwnLuopan()
    if (entities.GetPlayerMainJobId() ~= geoMainJobId) then
        return nil;
    end

    local pet = GetOwnPet();

    if (pet == nil or tostring(pet.name or '') ~= 'Luopan') then
        return nil;
    end

    pet.petType = 'luopan';
    return pet;
end

local function TryPlayerNumber(player, names)
    if (player == nil) then
        return nil;
    end

    for _, name in ipairs(names or {}) do
        local fn = player[name];

        if (fn ~= nil) then
            local ok, value = pcall(function()
                return fn(player);
            end);

            if (ok == true and tonumber(value) ~= nil) then
                return tonumber(value);
            end
        end
    end

    return nil;
end

function entities.GetOwnPupDebugText()
    local index = entities.GetOwnPetTargetIndex();
    local entityManager = AshitaCore:GetMemoryManager():GetEntity();
    local player = AshitaCore:GetMemoryManager():GetPlayer();
    local ent = (index ~= nil) and GetEntity(index) or nil;
    local vitals = GetPartyVitalsByTargetIndex(index);
    local pet = GetOwnPet();
    local serverId = nil;

    if (entityManager ~= nil and index ~= nil) then
        pcall(function()
            serverId = entityManager:GetServerId(index);
        end);
    end

    return table.concat({
        'PUP debug',
        'job=' .. tostring(entities.GetPlayerMainJobId()),
        'petIndex=' .. tostring(index),
        'serverId=' .. tostring(serverId),
        'name=' .. tostring(ent ~= nil and ent.Name or nil),
        'status=' .. tostring(ent ~= nil and ent.Status or nil),
        'entityHpPct=' .. tostring(ent ~= nil and ent.HPPercent or nil),
        'entityMp=' .. tostring(ent ~= nil and ent.MP or nil),
        'entityMaxMp=' .. tostring(ent ~= nil and ent.MaxMP or nil),
        'entityMpPct=' .. tostring(ent ~= nil and ent.MPPercent or nil),
        'entityTp=' .. tostring(ent ~= nil and ent.TP or nil),
        'partyHp=' .. tostring(vitals ~= nil and vitals.hp or nil),
        'partyMaxHp=' .. tostring(vitals ~= nil and vitals.maxHp or nil),
        'partyHpPct=' .. tostring(vitals ~= nil and vitals.hpPercent or nil),
        'playerPetMpPct=' .. tostring(TryPlayerNumber(player, { 'GetPetMPPercent' })),
        'playerPetTp=' .. tostring(TryPlayerNumber(player, { 'GetPetTP' })),
        'plateHp=' .. tostring(pet ~= nil and pet.hp or nil),
        'plateMaxHp=' .. tostring(pet ~= nil and pet.maxHp or nil),
        'plateHpPct=' .. tostring(pet ~= nil and pet.hpPercent or nil),
        'plateMpPct=' .. tostring(pet ~= nil and pet.mpPercent or nil),
        'plateTp=' .. tostring(pet ~= nil and pet.tp or nil),
    }, ' ');
end

local function GetTrustMemberVitals(party, slot)
    local now = os.clock();
    local cache = trustPartyVitalCache[slot] or {};

    if (cache.checkedAt ~= nil and (now - cache.checkedAt) < trustPartyVitalReadInterval) then
        return cache;
    end

    cache.checkedAt = now;

    pcall(function()
        cache.hp = tonumber(party:GetMemberHP(slot));
    end);

    pcall(function()
        cache.tp = tonumber(party:GetMemberTP(slot));
    end);

    trustPartyVitalCache[slot] = cache;

    return cache;
end

local function GetTrustMemberHP(party, slot)
    return GetTrustMemberVitals(party, slot).hp;
end

local function GetTrustMemberTP(party, slot)
    return GetTrustMemberVitals(party, slot).tp;
end

function entities.IsPartyMemberIndex(index)
    return IsActivePartyMemberIndex(index);
end

local function BuildPartyMemberIndexSet()
    local set = {};
    local party = AshitaCore:GetMemoryManager():GetParty();

    if (party == nil) then
        return set;
    end

    for slot = 0, 17 do
        local active = 0;
        local memberIndex = 0;

        pcall(function()
            active = party:GetMemberIsActive(slot);
        end);

        pcall(function()
            memberIndex = party:GetMemberTargetIndex(slot);
        end);

        memberIndex = tonumber(memberIndex) or 0;

        if (active == 1 and memberIndex > 0) then
            set[memberIndex] = true;
        end
    end

    return set;
end

function entities.GetPartyTrusts(maxDistance)
    local results = {};
    local maxDistanceSq = (tonumber(maxDistance) or 50) * (tonumber(maxDistance) or 50);
    local party = AshitaCore:GetMemoryManager():GetParty();
    local entityManager = AshitaCore:GetMemoryManager():GetEntity();

    if (party == nil or entityManager == nil) then
        return results;
    end

    for slot = 1, 17 do
        local active = 0;
        local index = 0;

        pcall(function()
            active = party:GetMemberIsActive(slot);
        end);

        pcall(function()
            index = party:GetMemberTargetIndex(slot);
        end);

        index = tonumber(index) or 0;

        if (
            active == 1 and
            index > 0 and
            (index < 1024 or index > 1791) and
            IsVisibleEntity(entityManager, index, true) == true
        ) then
            local ent = GetEntity(index);
            local spawnFlags = SafeCall(nil, function() return entityManager:GetSpawnFlags(index); end);

            if (
                ent ~= nil and
                ent.Name ~= nil and
                ent.Name ~= '' and
                ent.Distance ~= nil and
                ent.Distance <= maxDistanceSq
            ) then
                results[#results + 1] = {
                    index = index,
                    serverId = SafeCall(nil, function() return party:GetMemberServerId(slot); end),
                    slot = slot,
                    name = ent.Name,
                    status = ent.Status,
                    spawnFlags = spawnFlags,
                    distance = math.sqrt(ent.Distance),
                    hp = GetTrustMemberHP(party, slot),
                    maxHp = nil,
                    hpPercent = ent.HPPercent or 100,
                    mp = nil,
                    maxMp = nil,
                    mpPercent = nil,
                    tp = GetTrustMemberTP(party, slot),
                };
            end
        end
    end

    table.sort(results, function(a, b)
        return (tonumber(a.distance) or 0) < (tonumber(b.distance) or 0);
    end);

    return results;
end

function entities.GetNearbyTrusts(maxDistance)
    local results = {};
    local maxDistanceSq = (tonumber(maxDistance) or 50) * (tonumber(maxDistance) or 50);
    local entityManager = AshitaCore:GetMemoryManager():GetEntity();
    local partyIndexes = nil;

    if (entityManager == nil) then
        return results;
    end

    for index = 0, 2303 do
        if (index < 1024 or index > 1791) then
            local ent = GetEntity(index);

            if (
                ent ~= nil and
                ent.Name ~= nil and
                ent.Name ~= '' and
                ent.Distance ~= nil and
                ent.Distance <= maxDistanceSq and
                IsTrustStatusAllowed(ent.Status) == true and
                trustNames.IsKnownTrustName(ent.Name) == true and
                IsCampaignBattleActor(entityManager, index, ent) ~= true
            ) then
                partyIndexes = partyIndexes or BuildPartyMemberIndexSet();

                if (
                    IsMobIndex(entityManager, index) ~= true and
                    partyIndexes[index] ~= true and
                    IsVisibleEntity(entityManager, index, true) == true
                ) then
                    results[#results + 1] = {
                        index = index,
                        serverId = SafeCall(nil, function() return entityManager:GetServerId(index); end),
                        slot = nil,
                        name = ent.Name,
                        status = ent.Status,
                        spawnFlags = SafeCall(nil, function() return entityManager:GetSpawnFlags(index); end),
                        distance = math.sqrt(ent.Distance),
                        hp = nil,
                        maxHp = nil,
                        hpPercent = ent.HPPercent or 100,
                        mp = nil,
                        maxMp = nil,
                        mpPercent = nil,
                        tp = nil,
                    };
                end
            end
        end
    end

    table.sort(results, function(a, b)
        return (tonumber(a.distance) or 0) < (tonumber(b.distance) or 0);
    end);

    return results;
end

function entities.GetNearbyPlayers(maxDistance)
    local results = {};
    local maxDistanceSq = (tonumber(maxDistance) or 50) * (tonumber(maxDistance) or 50);
    local entityManager = AshitaCore:GetMemoryManager():GetEntity();
    local selfIndex = GetSelfIndex();
    local targetIndex = targeting.GetCurrentTargetIndex();
    local subTargetIndex = targeting.GetCurrentSubTargetIndex();
    local partyDataByIndex = BuildPartyMemberDataByTargetIndex();

    if (entityManager == nil) then
        return results;
    end

    for index = 1024, 1791 do
        if (
            index ~= selfIndex and
            IsMobIndex(entityManager, index) ~= true and
            -- FFXI does not reliably retain the 0x200 render bit or nonzero
            -- actor-alpha bytes for valid untargeted PCs at a distance. A
            -- loaded actor/skeleton plus the explicit suppression bit is the
            -- stable idle-world eligibility check.
            IsLoadedIdlePlayerEntity(entityManager, index) == true
        ) then
            local ent = GetEntity(index);
            local isCurrentTargetContext = tonumber(index) == tonumber(targetIndex) or tonumber(index) == tonumber(subTargetIndex);
            local objectCostumePlayer = IsObjectCostumePlayer(entityManager, index, ent);

            local isPartyListed = partyDataByIndex[index] ~= nil;

            if (
                ent ~= nil and
                IsPlayerActorEntity(ent, index) == true and
                ent.Name ~= nil and
                ent.Name ~= '' and
                ent.Distance ~= nil and
                ent.Distance <= maxDistanceSq and
                objectCostumePlayer ~= true and
                IsCampaignBattleActor(entityManager, index, ent) ~= true and
                entities.ShouldHideOtherPlayerPet(index, ent.Name) ~= true and
                (isPartyListed == true or trustNames.IsKnownTrustName(ent.Name) ~= true)
            ) then
                results[#results + 1] = {
                    index = index,
                    serverId = SafeCall(nil, function() return entityManager:GetServerId(index); end),
                    name = ent.Name,
                    status = ent.Status,
                    distance = math.sqrt(ent.Distance),
                    hpPercent = ent.HPPercent or 100,
                    missingHpPercent = ent.HPPercent == nil and isCurrentTargetContext ~= true,
                };

                local partyData = partyDataByIndex[index];

                if (partyData ~= nil) then
                    for key, value in pairs(partyData) do
                        results[#results][key] = value;
                    end
                end
            end
        end
    end

    table.sort(results, function(a, b)
        return (tonumber(a.distance) or 0) < (tonumber(b.distance) or 0);
    end);

    return results;
end

function entities.GetPlayerByIndex(index, maxDistance, partyDataByIndex)
    index = tonumber(index);
    local entityManager = AshitaCore:GetMemoryManager():GetEntity();
    local selfIndex = GetSelfIndex();
    local maxDistanceSq = (tonumber(maxDistance) or 50) * (tonumber(maxDistance) or 50);

    if (index == nil or index == selfIndex or entityManager == nil) then
        return nil;
    end

    if (index < 1024 or index > 1791 or IsMobIndex(entityManager, index) == true or IsVisibleEntity(entityManager, index, true, true) ~= true) then
        return nil;
    end

    local ent = GetEntity(index);
    local targetIndex = targeting.GetCurrentTargetIndex();
    local subTargetIndex = targeting.GetCurrentSubTargetIndex();
    local isCurrentTargetContext = tonumber(index) == tonumber(targetIndex) or tonumber(index) == tonumber(subTargetIndex);
    local campaignBattleActor = IsCampaignBattleActor(entityManager, index, ent);
    local partyData = partyDataByIndex ~= nil and partyDataByIndex[index] or GetPartyMemberDataByTargetIndex(index);

    if (
        ent == nil or
        IsPlayerActorEntity(ent, index) ~= true or
        ent.Name == nil or
        ent.Name == '' or
        ent.Distance == nil or
        ent.Distance > maxDistanceSq or
        IsObjectCostumePlayer(entityManager, index, ent) == true or
        campaignBattleActor == true or
        entities.ShouldHideOtherPlayerPet(index, ent.Name) == true or
        (partyData == nil and trustNames.IsKnownTrustName(ent.Name) == true)
    ) then
        return nil;
    end

    local result = {
        index = index,
        serverId = SafeCall(nil, function() return entityManager:GetServerId(index); end),
        name = ent.Name,
        status = ent.Status,
        distance = math.sqrt(ent.Distance),
        hpPercent = ent.HPPercent or 100,
    };

    if (partyData ~= nil) then
        for key, value in pairs(partyData) do
            result[key] = value;
        end
    end

    return result;
end

function entities.GetPartyPlayers(maxDistance)
    local results = {};
    local seen = {};
    local party = AshitaCore:GetMemoryManager():GetParty();
    local partyDataByIndex = BuildPartyMemberDataByTargetIndex();

    if (party == nil) then
        return results;
    end

    for slot = 0, 17 do
        local active = 0;
        local memberIndex = 0;

        pcall(function()
            active = party:GetMemberIsActive(slot);
        end);

        pcall(function()
            memberIndex = party:GetMemberTargetIndex(slot);
        end);

        memberIndex = tonumber(memberIndex) or 0;

        if (active == 1 and memberIndex > 0 and seen[memberIndex] ~= true) then
            seen[memberIndex] = true;

            local player = entities.GetPlayerByIndex(memberIndex, maxDistance, partyDataByIndex);
            if (player ~= nil) then
                results[#results + 1] = player;
            end
        end
    end

    table.sort(results, function(a, b)
        return (tonumber(a.distance) or 0) < (tonumber(b.distance) or 0);
    end);

    return results;
end

function entities.GetNearbyTacticalNpcs(maxDistance)
    local results = {};
    local maxDistanceSq = (tonumber(maxDistance) or 50) * (tonumber(maxDistance) or 50);
    local entityManager = AshitaCore:GetMemoryManager():GetEntity();
    local partyIndexes = BuildPartyMemberIndexSet();
    local ownPetIndex = entities.GetOwnPetTargetIndex();
    local playerMainJobId = entities.GetPlayerMainJobId();

    if (entityManager == nil) then
        return results;
    end

    for index = 0, 2303 do
        local ent = GetEntity(index);
        local playerIndexRange = IsPlayerIndexRange(index) == true;
        local objectCostumePlayer = IsObjectCostumePlayer(entityManager, index, ent) == true;
        local campaignBattleActor = IsCampaignBattleActor(entityManager, index, ent) == true;
        local campaignAlly = campaignBattleActor == true and IsMobIndex(entityManager, index) ~= true;
        local rawEntityType = tonumber(ent ~= nil and ent.Type or nil);
        local rawObject = rawEntityType == 2 or rawEntityType == 3;
        local tacticalEntityType = (rawObject == true and objectCostumePlayer ~= true) and 'Object' or 'NPC';

        if (playerIndexRange ~= true or objectCostumePlayer == true or campaignBattleActor == true) then
            -- NPC Tactical is for active combat actors.  Ordinary status-0
            -- town/service NPCs remain NPC World plates even when targeted.
            local statusAllowsTactical = tonumber(ent ~= nil and ent.Status or nil) == 1;

            if (
                ent ~= nil and
                ent.Name ~= nil and
                ent.Name ~= '' and
                ent.HPPercent ~= nil and
                ent.HPPercent > 0 and
                ent.Distance ~= nil and
                ent.Distance <= maxDistanceSq and
                tacticalEntityType == 'NPC' and
                statusAllowsTactical == true and
                partyIndexes[index] ~= true and
                tonumber(index) ~= tonumber(ownPetIndex) and
                (playerMainJobId ~= geoMainJobId or tonumber(index) ~= tonumber(ownPetIndex)) and
                IsVisibleEntity(entityManager, index, false) == true
            ) then
                local spawnFlags = SafeCall(nil, function() return entityManager:GetSpawnFlags(index); end);

                results[#results + 1] = {
                    index = index,
                    serverId = SafeCall(nil, function() return entityManager:GetServerId(index); end),
                    name = ent.Name,
                    status = ent.Status,
                    entityType = tacticalEntityType,
                    layoutStateName = 'Combat',
                    tacticalNpc = true,
                    campaignBattleActor = campaignBattleActor,
                    campaignAlly = campaignAlly,
                    hpPercent = ent.HPPercent or 100,
                    distance = math.sqrt(ent.Distance),
                    spawnFlags = spawnFlags,
                    renderFlags0 = SafeCall(nil, function() return entityManager:GetRenderFlags0(index); end),
                    renderFlags1 = SafeCall(nil, function() return entityManager:GetRenderFlags1(index); end),
                };
            end
        end
    end

    table.sort(results, function(a, b)
        return (tonumber(a.distance) or 0) < (tonumber(b.distance) or 0);
    end);

    return results;
end

function entities.GetTacticalNpcByIndex(index, maxDistance)
    index = tonumber(index);
    local entityManager = AshitaCore:GetMemoryManager():GetEntity();
    local maxDistanceSq = (tonumber(maxDistance) or 50) * (tonumber(maxDistance) or 50);

    if (index == nil or entityManager == nil) then
        return nil;
    end

    local ent = GetEntity(index);
    local playerIndexRange = IsPlayerIndexRange(index) == true;
    local objectCostumePlayer = IsObjectCostumePlayer(entityManager, index, ent) == true;
    local campaignBattleActor = IsCampaignBattleActor(entityManager, index, ent) == true;
    local rawEntityType = tonumber(ent ~= nil and ent.Type or nil);
    local rawObject = rawEntityType == 2 or rawEntityType == 3;
    local tacticalEntityType = (rawObject == true and objectCostumePlayer ~= true) and 'Object' or 'NPC';

    if (playerIndexRange == true and objectCostumePlayer ~= true and campaignBattleActor ~= true) then
        return nil;
    end

    if (tacticalEntityType ~= 'NPC') then
        return nil;
    end

    local spawnFlags = SafeCall(nil, function() return entityManager:GetSpawnFlags(index); end);
    -- See GetNearbyTacticalNpcs: do not route passive town NPCs through
    -- the combat plate just because they have an HP percentage.
    local statusAllowsTactical = tonumber(ent ~= nil and ent.Status or nil) == 1;

    if (
        ent == nil or
        ent.Name == nil or
        ent.Name == '' or
        ent.HPPercent == nil or
        ent.HPPercent <= 0 or
        ent.Distance == nil or
        ent.Distance > maxDistanceSq or
        statusAllowsTactical ~= true or
        entities.IsPartyMemberIndex(index) == true or
        entities.IsOwnPetIndex(index) == true or
        entities.IsOwnLuopanIndex(index) == true or
        IsVisibleEntity(entityManager, index, false) ~= true
    ) then
        return nil;
    end

    return {
        index = index,
        serverId = SafeCall(nil, function() return entityManager:GetServerId(index); end),
        name = ent.Name,
        status = ent.Status,
        entityType = tacticalEntityType,
        layoutStateName = 'Combat',
        tacticalNpc = true,
        hpPercent = ent.HPPercent or 100,
        distance = math.sqrt(ent.Distance),
        spawnFlags = spawnFlags,
        renderFlags0 = SafeCall(nil, function() return entityManager:GetRenderFlags0(index); end),
        renderFlags1 = SafeCall(nil, function() return entityManager:GetRenderFlags1(index); end),
    };
end

local function IsMogHouseFurniturePlaceholder(entityManager, index, ent)
    if (entityManager == nil or ent == nil) then
        return false;
    end

    if (tostring(ent.Name or '') ~= 'Furniture' or tonumber(ent.Type) ~= 3) then
        return false;
    end

    local spawnFlags = SafeCall(nil, function()
        return entityManager:GetSpawnFlags(index);
    end);
    local renderFlags0 = SafeCall(nil, function()
        return entityManager:GetRenderFlags0(index);
    end);
    local renderFlags1 = SafeCall(nil, function()
        return entityManager:GetRenderFlags1(index);
    end);

    return
        tonumber(spawnFlags) == 0x22 and
        tonumber(renderFlags0) == 0x200 and
        tonumber(renderFlags1) == 0x880;
end

function entities.IsMogHouseFurniturePlaceholder(index)
    local entityManager = AshitaCore:GetMemoryManager():GetEntity();

    if (entityManager == nil) then
        return false;
    end

    return IsMogHouseFurniturePlaceholder(entityManager, index, GetEntity(index));
end

function entities.IsMogHouseObjectSuppressionArea()
    local now = os.clock();

    if ((now - (tonumber(mogHouseObjectSuppressionCache.clock) or 0)) < 1.0) then
        return mogHouseObjectSuppressionCache.value == true;
    end

    mogHouseObjectSuppressionCache.clock = now;
    mogHouseObjectSuppressionCache.value = false;

    local entityManager = AshitaCore:GetMemoryManager():GetEntity();

    if (entityManager == nil) then
        return false;
    end

    for index = 0, 2303 do
        if (IsMogHouseFurniturePlaceholder(entityManager, index, GetEntity(index)) == true) then
            mogHouseObjectSuppressionCache.value = true;
            return true;
        end
    end

    return false;
end

function entities.GetNearbyNpcObjects(maxDistance, isKnownNpcObject)
    local results = {};
    local maxDistanceSq = (tonumber(maxDistance) or 50) * (tonumber(maxDistance) or 50);
    local entityManager = AshitaCore:GetMemoryManager():GetEntity();
    local targetIndex = targeting.GetCurrentTargetIndex();
    local subTargetIndex = targeting.GetCurrentSubTargetIndex();
    local partyIndexes = nil;
    local mogHouseObjectSuppressionArea = entities.IsMogHouseObjectSuppressionArea() == true;

    if (entityManager == nil) then
        return results;
    end

    for index = 0, 2303 do
        local ent = GetEntity(index);
        local inPlayerIndexRange = index >= 1024 and index <= 1791;
        local isCurrentTargetContext = tonumber(index) == tonumber(targetIndex) or tonumber(index) == tonumber(subTargetIndex);
        local isMob = ent ~= nil and IsMobIndex(entityManager, index) == true;
        local allowTargetedNpcObject = isCurrentTargetContext == true and isMob ~= true;
        local cleanName = tostring(ent ~= nil and ent.Name or ''):gsub('\170', '');
        local rawEntityType = ent ~= nil and ((ent.Type == 2 or ent.Type == 3) and 'Object' or 'NPC') or 'NPC';
        local allowKnownNpcObject = isMob ~= true and SafeCall(false, function()
            return ent ~= nil and cleanName ~= '' and
                type(isKnownNpcObject) == 'function' and
                isKnownNpcObject(cleanName, rawEntityType, index) == true;
        end);
        local allowNonstandardNpcObject = allowTargetedNpcObject == true or allowKnownNpcObject == true;
        local allowPlayerRangeNpcObject = false;

        if (ent ~= nil and inPlayerIndexRange == true) then
            allowPlayerRangeNpcObject =
                (ent.HPPercent == nil or isCurrentTargetContext == true) and
                (IsNpcObjectStatusAllowed(ent.Status) == true or allowNonstandardNpcObject == true);
        end

        if (ent ~= nil and inPlayerIndexRange ~= true or allowPlayerRangeNpcObject == true) then
            local entityStatus = tonumber(ent.Status) or 0;
            local isObject = (ent.Type == 2 or ent.Type == 3);
            local allowUnsettledCharacter = entityStatus == 40 or entityStatus == 47 or entityStatus == 50;
            local isMogHouseMoogle = mogHouseObjectSuppressionArea == true and cleanName == 'Moogle';
            -- Campaign allies use status 1 (engaged), which ordinary NPC
            -- World plates reject.  They are distinguished from campaign
            -- enemies by not being mob-class entities.
            local campaignBattleActor = tonumber(ent.Type) == 0
                and tonumber(ent.HPPercent) ~= nil
                and tonumber(ent.HPPercent) > 0
                and IsCampaignBattleActor(entityManager, index, ent) == true;
            local campaignAlly = campaignBattleActor == true and isMob ~= true;

            if (
                ent.Name ~= nil and
                ent.Name ~= '' and
                ent.Distance ~= nil and
                ent.Distance <= maxDistanceSq and
                (IsNpcObjectStatusAllowed(entityStatus) == true or campaignAlly == true or allowNonstandardNpcObject == true) and
                entities.ShouldHideOtherPlayerPet(index, ent.Name) ~= true and
                IsMogHouseFurniturePlaceholder(entityManager, index, ent) ~= true and
                (trustNames.IsKnownTrustName(ent.Name) ~= true or isMogHouseMoogle == true)
            ) then
                partyIndexes = partyIndexes or BuildPartyMemberIndexSet();

                -- Campaign allies use the same mob-class flag as campaign
                -- enemies.  Keep the allied candidates available to the NPC
                -- world renderer; it will discard any non-allied campaign
                -- actor after resolving its data record.
                if (
                    (isMob ~= true or campaignAlly == true) and
                    partyIndexes[index] ~= true and
                    IsVisibleEntity(entityManager, index, false) == true and
                    -- Campaign allies can be fully visible in battle before the
                    -- generic character-settle check reports ready.  They use
                    -- the regular NPC World plate while idle, so do not drop
                    -- them solely for that transient flag.
                    (isObject == true or allowUnsettledCharacter == true or campaignAlly == true or allowNonstandardNpcObject == true or HasSettledCharacterModel(entityManager, index) == true)
                ) then
                    results[#results + 1] = {
                        index = index,
                        name = ent.Name,
                        distance = math.sqrt(ent.Distance),
                        entityType = isObject and 'Object' or 'NPC',
                        campaignBattleActor = campaignBattleActor,
                        campaignAlly = campaignAlly,
                    };
                end
            end
        end
    end

    table.sort(results, function(a, b)
        return (tonumber(a.distance) or 0) < (tonumber(b.distance) or 0);
    end);

    return results;
end

function entities.GetNearbyRawObjects(maxDistance, maxResults)
    local results = {};
    local maxDistanceSq = (tonumber(maxDistance) or 12) * (tonumber(maxDistance) or 12);
    local entityManager = AshitaCore:GetMemoryManager():GetEntity();

    if (entityManager == nil) then
        return results;
    end

    for index = 0, 2303 do
        if (index < 1024 or index > 1791) then
            local ent = GetEntity(index);
            local isObject = ent ~= nil and (ent.Type == 2 or ent.Type == 3);
            local distanceSq = ent ~= nil and tonumber(ent.Distance) or nil;

            if (
                isObject == true and
                distanceSq ~= nil and
                distanceSq <= maxDistanceSq
            ) then
                results[#results + 1] = {
                    index = index,
                    name = ent.Name,
                    nameLen = string.len(tostring(ent.Name or '')),
                    type = ent.Type,
                    status = ent.Status,
                    distance = math.sqrt(distanceSq),
                    distanceSq = distanceSq,
                    spawnFlags = SafeCall(nil, function() return entityManager:GetSpawnFlags(index); end),
                    renderFlags0 = SafeCall(nil, function() return entityManager:GetRenderFlags0(index); end),
                    renderFlags1 = SafeCall(nil, function() return entityManager:GetRenderFlags1(index); end),
                    visible = IsVisibleEntity(entityManager, index, false),
                    statusAllowed = IsNpcObjectStatusAllowed(ent.Status),
                    mogHouseFurniturePlaceholder = IsMogHouseFurniturePlaceholder(entityManager, index, ent),
                };
            end
        end
    end

    table.sort(results, function(a, b)
        return (tonumber(a.distance) or 0) < (tonumber(b.distance) or 0);
    end);

    local limit = tonumber(maxResults) or #results;

    if (#results > limit) then
        local limited = {};

        for i = 1, limit do
            limited[i] = results[i];
        end

        return limited;
    end

    return results;
end

function entities.GetEntityDebugInfo(index, maxDistance)
    local entityManager = AshitaCore:GetMemoryManager():GetEntity();
    local targetIndex = tonumber(index);

    if (entityManager == nil or targetIndex == nil) then
        return nil;
    end

    local ent = entities.GetEntity(targetIndex);
    local spawnFlags = SafeCall(nil, function() return entityManager:GetSpawnFlags(targetIndex); end);
    local renderFlags = {};

    for flagIndex = 0, 7 do
        local methodName = 'GetRenderFlags' .. tostring(flagIndex);
        renderFlags[flagIndex] = SafeCall(nil, function()
            if (entityManager[methodName] == nil) then
                return nil;
            end

            return entityManager[methodName](entityManager, targetIndex);
        end);
    end

    local renderFlags0 = renderFlags[0];
    local renderFlags1 = renderFlags[1];
    local maxDistanceSq = (tonumber(maxDistance) or 50) * (tonumber(maxDistance) or 50);
    local distanceSq = ent ~= nil and tonumber(ent.Distance) or nil;
    local status = ent ~= nil and ent.Status or nil;
    local entityType = ent ~= nil and ent.Type or nil;
    local isObject = (entityType == 2 or entityType == 3);
    local isMob = IsMobIndex(entityManager, targetIndex);
    local currentTargetIndex = targeting.GetCurrentTargetIndex();
    local currentSubTargetIndex = targeting.GetCurrentSubTargetIndex();
    local isCurrentTargetContext =
        targetIndex == tonumber(currentTargetIndex) or
        targetIndex == tonumber(currentSubTargetIndex);
    local allowTargetedNpcObject = isCurrentTargetContext == true and isMob ~= true;
    local isParty = entities.IsPartyMemberIndex(targetIndex);
    local actorPointer = SafeCall(nil, function() return entityManager:GetActorPointer(targetIndex); end);
    local invisibleActor = IsInvisiblePlayerActor(entityManager, targetIndex, actorPointer);
    local objectCostumePlayer = IsObjectCostumePlayer(entityManager, targetIndex, ent);
    local visible = IsVisibleEntity(entityManager, targetIndex, false);
    local visibleWithSkeleton = IsVisibleEntity(entityManager, targetIndex, true);
    local mogHouseFurniturePlaceholder = IsMogHouseFurniturePlaceholder(entityManager, targetIndex, ent);
    local allowUnsettledCharacter = tonumber(status) == 40 or tonumber(status) == 47 or tonumber(status) == 50;
    local settled = isObject == true or allowUnsettledCharacter == true or HasSettledCharacterModel(entityManager, targetIndex);
    local indexAllowed = targetIndex < 1024 or targetIndex > 1791;
    local statusAllowed = IsNpcObjectStatusAllowed(status);
    local inRange = distanceSq ~= nil and distanceSq <= maxDistanceSq;
    local partyData = GetPartyMemberDataByTargetIndex(targetIndex);
    local spawnFlagValue = tonumber(spawnFlags) or 0;
    local hasNpcSpawnFlag = bit.band(spawnFlagValue, 0x02) == 0x02;
    local alliedTacticalInfo = nil;
    local statusAllowsTactical = tonumber(status) == 1;
    local tacticalNpcAllowed = indexAllowed == true
        and isParty ~= true
        and visible == true
        and ent ~= nil
        and ent.Name ~= nil
        and ent.Name ~= ''
        and inRange == true
        and statusAllowsTactical == true
        and tonumber(ent.HPPercent) ~= nil
        and tonumber(ent.HPPercent) > 0
        and entities.IsOwnPetIndex(targetIndex) ~= true
        and entities.IsOwnLuopanIndex(targetIndex) ~= true;
    local npcScanAllowed = indexAllowed == true
        and isMob ~= true
        and isParty ~= true
        and visible == true
        and ent ~= nil
        and ent.Name ~= nil
        and ent.Name ~= ''
        and mogHouseFurniturePlaceholder ~= true
        and inRange == true
        and (statusAllowed == true or allowTargetedNpcObject == true)
        and (settled == true or allowTargetedNpcObject == true);

    return {
        index = targetIndex,
        name = ent ~= nil and ent.Name or nil,
        status = status,
        hpPercent = ent ~= nil and ent.HPPercent or nil,
        mp = ent ~= nil and ent.MP or nil,
        maxMp = ent ~= nil and ent.MaxMP or nil,
        mpPercent = ent ~= nil and ent.MPPercent or nil,
        tp = ent ~= nil and ent.TP or nil,
        type = entityType,
        distance = distanceSq ~= nil and math.sqrt(distanceSq) or nil,
        distanceSq = distanceSq,
        spawnFlags = spawnFlags,
        renderFlags = renderFlags,
        renderFlags0 = renderFlags0,
        renderFlags1 = renderFlags1,
        indexAllowed = indexAllowed,
        isMob = isMob,
        isParty = isParty,
        invisibleActor = invisibleActor,
        objectCostumePlayer = objectCostumePlayer,
        visible = visible,
        visibleWithSkeleton = visibleWithSkeleton,
        mogHouseFurniturePlaceholder = mogHouseFurniturePlaceholder,
        mogHouseObjectSuppression = entities.IsMogHouseObjectSuppressionArea(),
        settled = settled,
        inRange = inRange,
        statusAllowed = statusAllowed,
        targetedNpcObjectFallback = allowTargetedNpcObject,
        npcScanAllowed = npcScanAllowed,
        tacticalNpcAllowed = tacticalNpcAllowed,
        alliedTacticalInfo = alliedTacticalInfo,
        tacticalNpcInfoType = nil,
        layoutStateName = tacticalNpcAllowed == true and 'Combat' or nil,
        partySlot = partyData ~= nil and partyData.slot or nil,
        partyHp = partyData ~= nil and partyData.hp or nil,
        partyMaxHp = partyData ~= nil and partyData.maxHp or nil,
        partyHpPercent = partyData ~= nil and partyData.hpPercent or nil,
        partyMp = partyData ~= nil and partyData.mp or nil,
        partyMaxMp = partyData ~= nil and partyData.maxMp or nil,
        partyMpPercent = partyData ~= nil and partyData.mpPercent or nil,
        partyTp = partyData ~= nil and partyData.tp or nil,
        partyMainJob = partyData ~= nil and partyData.mainJob or nil,
        partyMainJobLevel = partyData ~= nil and partyData.mainJobLevel or nil,
    };
end

return entities;
