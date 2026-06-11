local enemyCasts = require('core.enemy_casts');

local aoeNameHighlight = {};
local automaticNameSize = 18;

local function GetSpellNameValue(value)
    if (value == nil) then
        return nil;
    end

    if (type(value) == 'string') then
        return value;
    end

    local ok, result = pcall(function()
        return ffi.string(value);
    end);

    if (ok == true and result ~= nil and result ~= '') then
        return result;
    end

    return nil;
end

local function IsDefensiveAoeName(actionName)
    local name = tostring(actionName or ''):lower():gsub('[%s%-_]+', '');

    if (name == '') then
        return false;
    end

    return (
        name:find('curaga', 1, true) ~= nil or
        name:find('protectra', 1, true) ~= nil or
        name:find('shellra', 1, true) ~= nil or
        name:find('hastega', 1, true) ~= nil
    );
end

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

local function GetActionNameById(actionId)
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

    if (spell.Name ~= nil) then
        return GetSpellNameValue(spell.Name[1]) or GetSpellNameValue(spell.Name[2]);
    end

    return GetSpellNameValue(spell.En);
end

local function GetLiveDefensiveActionAoeRange()
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

    if (actionId == nil or IsDefensiveAoeName(GetActionNameById(actionId)) ~= true) then
        return nil;
    end

    local rawRange = nil;

    if (targetManager.GetActionAoeRange ~= nil) then
        rawRange = SafeNumber(function() return targetManager:GetActionAoeRange(); end);
    end

    if (rawRange ~= nil and rawRange > 0) then
        return rawRange;
    end

    local resourceManager = AshitaCore:GetResourceManager();

    if (resourceManager ~= nil and resourceManager.GetSpellRange ~= nil) then
        return SafeNumber(function() return resourceManager:GetSpellRange(actionId, true); end);
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

function aoeNameHighlight.IsHighlighted(index)
    index = tonumber(index) or 0;

    if (index <= 0) then
        return false;
    end

    local liveRange = GetLiveDefensiveActionAoeRange();

    if (liveRange ~= nil and liveRange > 0) then
        local centerIndex = GetCurrentActionTargetIndex();

        if (index == centerIndex) then
            return true;
        end

        local subjectPosition = GetWorldPosition(index);
        local centerPosition = GetWorldPosition(centerIndex);
        local distance = Distance2D(subjectPosition, centerPosition);

        if (distance ~= nil and distance <= liveRange) then
            return true;
        end
    end

    local subjectPosition = nil;

    for _, castData in ipairs(enemyCasts.GetActiveAoeCasts()) do
        local radius = tonumber(castData.aoeRadius) or 0;
        local targetIndex = tonumber(castData.targetIndex) or 0;

        if (radius > 0 and targetIndex > 0) then
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

function aoeNameHighlight.ApplyNameSize(textSize, index)
    local size = tonumber(textSize);

    if (size == nil or size <= 0) then
        return textSize;
    end

    if (aoeNameHighlight.IsHighlighted(index) ~= true) then
        return size;
    end

    return math.max(size, automaticNameSize);
end

function aoeNameHighlight.GetSignature(index)
    return aoeNameHighlight.IsHighlighted(index) == true and 'aoe-name:1' or 'aoe-name:0';
end

return aoeNameHighlight;
