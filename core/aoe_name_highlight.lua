local enemyCasts = require('core.enemy_casts');

local aoeNameHighlight = {};
local automaticNameSize = 18;

local function SafeNumber(fn)
    local ok, value = pcall(fn);

    if (ok ~= true) then
        return nil;
    end

    return tonumber(value);
end

local function GetWorldPosition(index)
    index = tonumber(index) or 0;

    if (index <= 0) then
        return nil;
    end

    local memory = AshitaCore:GetMemoryManager();
    local entityManager = memory ~= nil and memory:GetEntity() or nil;

    if (entityManager == nil) then
        return nil;
    end

    local x = SafeNumber(function() return entityManager:GetLocalPositionX(index); end)
        or SafeNumber(function() return entityManager:GetLastPositionX(index); end);
    local y = SafeNumber(function() return entityManager:GetLocalPositionY(index); end)
        or SafeNumber(function() return entityManager:GetLastPositionY(index); end);
    local z = SafeNumber(function() return entityManager:GetLocalPositionZ(index); end)
        or SafeNumber(function() return entityManager:GetLastPositionZ(index); end);

    if (x == nil or y == nil) then
        return nil;
    end

    return { x = x, y = y, z = z };
end

local function GetSelfIndex()
    local memory = AshitaCore:GetMemoryManager();
    local party = memory ~= nil and memory:GetParty() or nil;

    if (party == nil) then
        return 0;
    end

    return SafeNumber(function() return party:GetMemberTargetIndex(0); end) or 0;
end

local function GetCurrentActionTargetIndex()
    local memory = AshitaCore:GetMemoryManager();
    local targetManager = memory ~= nil and memory:GetTarget() or nil;

    if (targetManager == nil or targetManager.GetTargetIndex == nil) then
        return GetSelfIndex();
    end

    local isSubTargetActive = SafeNumber(function() return targetManager:GetIsSubTargetActive(); end) or 0;

    if (isSubTargetActive == 1 or isSubTargetActive == 2) then
        local subTargetIndex = SafeNumber(function() return targetManager:GetTargetIndex(0); end) or 0;

        if (subTargetIndex > 0) then
            return subTargetIndex;
        end
    end

    local targetIndex = SafeNumber(function() return targetManager:GetTargetIndex(0); end) or 0;

    if (targetIndex > 0) then
        return targetIndex;
    end

    return GetSelfIndex();
end

local function GetSpellActionInfo(actionId)
    actionId = tonumber(actionId) or 0;

    if (actionId <= 0) then
        return nil;
    end

    local resourceManager = AshitaCore:GetResourceManager();

    if (resourceManager == nil or resourceManager.GetSpellById == nil) then
        return nil;
    end

    local spell = nil;
    local ok = pcall(function()
        spell = resourceManager:GetSpellById(actionId);
    end);

    if (ok ~= true or spell == nil) then
        return nil;
    end

    return {
        spell = spell,
        id = actionId,
        type = tostring(spell.Type or spell.type or ''),
        targets = tonumber(spell.Targets or spell.targets or spell.Target or spell.target),
        range = tonumber(spell.Range or spell.range),
    };
end

local function GetBlueMagicAoeKind(spellInfo)
    if (spellInfo == nil or spellInfo.type ~= 'BlueMagic') then
        return 'all';
    end

    if (spellInfo.targets == 32) then
        return 'enemy';
    elseif (spellInfo.targets == 1) then
        return 'friendly';
    end

    if (tonumber(spellInfo.id) == 584) then
        return 'enemy';
    end

    return 'friendly';
end

local function PlateMatchesAoeKind(plateKind, aoeKind)
    if (aoeKind == nil or aoeKind == 'all') then
        return true;
    end

    plateKind = tostring(plateKind or '');

    if (aoeKind == 'enemy') then
        return plateKind == 'enemy';
    end

    if (aoeKind == 'friendly') then
        return plateKind == 'self' or plateKind == 'pc' or plateKind == 'trust' or plateKind == 'pet';
    end

    return true;
end

local function GetLiveActionAoe()
    local memory = AshitaCore:GetMemoryManager();
    local targetManager = memory ~= nil and memory:GetTarget() or nil;

    if (
        targetManager == nil or
        targetManager.GetIsActionAoe == nil or
        targetManager.GetActionId == nil
    ) then
        return nil;
    end

    local isActionAoe = SafeNumber(function() return targetManager:GetIsActionAoe(); end);

    if (isActionAoe ~= 1 and isActionAoe ~= 2) then
        return nil;
    end

    local actionId = SafeNumber(function() return targetManager:GetActionId(); end);
    local spellInfo = GetSpellActionInfo(actionId);

    if (actionId == nil or spellInfo == nil) then
        return nil;
    end

    if (spellInfo.type == 'BlueMagic' and spellInfo.range ~= nil and spellInfo.range > 0) then
        return {
            range = spellInfo.range,
            centerIndex = GetSelfIndex(),
            kind = GetBlueMagicAoeKind(spellInfo),
        };
    end

    local rawRange = nil;

    if (targetManager.GetActionAoeRange ~= nil) then
        rawRange = SafeNumber(function() return targetManager:GetActionAoeRange(); end);
    end

    if (rawRange ~= nil and rawRange > 0) then
        return {
            range = rawRange,
            centerIndex = GetCurrentActionTargetIndex(),
            kind = 'all',
        };
    end

    local resourceManager = AshitaCore:GetResourceManager();

    if (resourceManager ~= nil and resourceManager.GetSpellRange ~= nil) then
        local spellRange = SafeNumber(function() return resourceManager:GetSpellRange(actionId, true); end);

        if (spellRange ~= nil and spellRange > 0) then
            return {
                range = spellRange,
                centerIndex = GetCurrentActionTargetIndex(),
                kind = 'all',
            };
        end
    end

    return nil;
end

local function Distance2D(a, b)
    if (a == nil or b == nil) then
        return nil;
    end

    local dx = (tonumber(a.x) or 0) - (tonumber(b.x) or 0);
    local dy = (tonumber(a.y) or 0) - (tonumber(b.y) or 0);

    return math.sqrt((dx * dx) + (dy * dy));
end

function aoeNameHighlight.IsHighlighted(index, plateKind)
    index = tonumber(index) or 0;

    if (index <= 0) then
        return false;
    end

    local liveAoe = GetLiveActionAoe();

    if (liveAoe ~= nil and tonumber(liveAoe.range) ~= nil and tonumber(liveAoe.range) > 0 and PlateMatchesAoeKind(plateKind, liveAoe.kind) == true) then
        local centerIndex = tonumber(liveAoe.centerIndex) or GetSelfIndex();

        if (index == centerIndex) then
            return true;
        end

        local subjectPosition = GetWorldPosition(index);
        local centerPosition = GetWorldPosition(centerIndex);
        local distance = Distance2D(subjectPosition, centerPosition);

        if (distance ~= nil and distance <= tonumber(liveAoe.range)) then
            return true;
        end
    end

    local subjectPosition = nil;

    for _, castData in ipairs(enemyCasts.GetActiveAoeCasts()) do
        local radius = tonumber(castData.aoeRadius) or 0;
        local targetIndex = tonumber(castData.aoeCenterIndex or castData.targetIndex) or 0;

        if (radius > 0 and targetIndex > 0 and PlateMatchesAoeKind(plateKind, castData.aoeKind) == true) then
            if (targetIndex == index) then
                return true;
            end

            subjectPosition = subjectPosition or GetWorldPosition(index);
            local targetPosition = GetWorldPosition(targetIndex);
            local distance = Distance2D(subjectPosition, targetPosition);

            if (distance ~= nil and distance <= radius) then
                return true;
            end
        end
    end

    return false;
end

function aoeNameHighlight.ApplyNameSize(textSize, index, plateKind)
    local size = tonumber(textSize);

    if (size == nil or size <= 0) then
        return textSize;
    end

    if (aoeNameHighlight.IsHighlighted(index, plateKind) ~= true) then
        return size;
    end

    return math.max(size, automaticNameSize);
end

function aoeNameHighlight.GetSignature(index, plateKind)
    return aoeNameHighlight.IsHighlighted(index, plateKind) == true and 'aoe-name:1' or 'aoe-name:0';
end

return aoeNameHighlight;
