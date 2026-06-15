local enemyCasts = require('core.enemy_casts');
local entities = require('core.entities');
local targeting = require('core.targeting');

local aoeNameHighlight = {};
local automaticNameSize = 18;
local Distance2D = nil;
local enemyIndiSpells = {
    [769] = true, -- Indi-Poison
    [787] = true, -- Indi-Wilt
    [788] = true, -- Indi-Frailty
    [789] = true, -- Indi-Fade
    [790] = true, -- Indi-Malaise
    [791] = true, -- Indi-Slip
    [792] = true, -- Indi-Torpor
    [793] = true, -- Indi-Vex
    [794] = true, -- Indi-Languor
    [795] = true, -- Indi-Slow
    [796] = true, -- Indi-Paralysis
    [797] = true, -- Indi-Gravity
};

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

local function GetOwnPetIndex()
    if (entities ~= nil and entities.GetOwnPetTargetIndex ~= nil) then
        local petIndex = SafeNumber(function() return entities.GetOwnPetTargetIndex(); end);

        if (petIndex ~= nil and petIndex > 0) then
            return petIndex;
        end
    end

    local selfIndex = GetSelfIndex();

    if (selfIndex == nil or selfIndex <= 0) then
        return 0;
    end

    local memory = AshitaCore:GetMemoryManager();
    local entityManager = memory ~= nil and memory:GetEntity() or nil;

    if (entityManager == nil) then
        return 0;
    end

    return SafeNumber(function()
        local entity = entityManager:GetEntity(selfIndex);
        return entity ~= nil and entity.PetTargetIndex or 0;
    end) or 0;
end

local function GetPartySlotForIndex(index)
    local memory = AshitaCore:GetMemoryManager();
    local party = memory ~= nil and memory:GetParty() or nil;

    if (party == nil) then
        return nil;
    end

    for slot = 0, 17 do
        local active = SafeNumber(function() return party:GetMemberIsActive(slot); end) or 0;
        local memberIndex = SafeNumber(function() return party:GetMemberTargetIndex(slot); end) or 0;

        if (active == 1 and tonumber(memberIndex) == tonumber(index)) then
            return slot;
        end
    end

    return nil;
end

local function HasTargetFlag(flags, flag)
    flags = tonumber(flags) or 0;
    flag = tonumber(flag) or 0;

    if (flags <= 0 or flag <= 0 or bit == nil or bit.band == nil) then
        return false;
    end

    return bit.band(flags, flag) ~= 0;
end

local function GetSpellAoeKind(spellInfo)
    if (spellInfo == nil) then
        return 'all';
    end

    local targets = tonumber(spellInfo.targets) or 0;
    local spellType = tostring(spellInfo.type or '');
    local spellTypeLower = spellType:lower();
    local spellName = tostring(spellInfo.name or ''):lower();

    if (enemyIndiSpells[tonumber(spellInfo.id) or 0] == true) then
        return 'enemy';
    end

    if (
        spellName:find('curaga', 1, false) ~= nil or
        spellName:find('cura', 1, false) ~= nil
    ) then
        return 'friendly';
    end

    if (spellType == 'Geomancy' and spellName:find('indi%-poison', 1, false) ~= nil) then
        return 'enemy';
    end

    if (spellTypeLower == 'bluemagic') then
        if (targets == 32 or HasTargetFlag(targets, 32) == true) then
            return 'enemy';
        elseif (targets == 1 or HasTargetFlag(targets, 1) == true) then
            return 'friendly';
        end

        if (tonumber(spellInfo.id) == 584) then
            return 'enemy';
        end

        return 'friendly';
    end

    if (HasTargetFlag(targets, 32) == true) then
        return 'enemy';
    end

    if (
        HasTargetFlag(targets, 1) == true or
        HasTargetFlag(targets, 2) == true or
        HasTargetFlag(targets, 4) == true or
        HasTargetFlag(targets, 8) == true
    ) then
        return 'friendly';
    end

    return 'all';
end

local function GetSpellAoeCenterMode(spellInfo)
    if (spellInfo == nil) then
        return 'target';
    end

    local spellType = tostring(spellInfo.type or '');
    local spellName = tostring(spellInfo.name or ''):lower();

    if (enemyIndiSpells[tonumber(spellInfo.id) or 0] == true) then
        return 'self';
    end

    if (spellInfo.resourceKind == 'ability' and GetOwnPetIndex() > 0) then
        return 'pet';
    end

    if (spellType == 'BlueMagic') then
        return 'self';
    end

    if (spellType == 'Geomancy' and spellName:find('indi%-', 1, false) ~= nil) then
        return 'self';
    end

    return 'target';
end

local function GetActionResourceName(resource)
    if (resource == nil) then
        return '';
    end

    local function ReadNameValue(value, depth)
        depth = tonumber(depth) or 0;
        if (depth > 4) then
            return nil;
        end

        local valueType = type(value);

        local function CleanText(candidate)
            local candidateType = type(candidate);

            if (candidateType ~= 'string' and candidateType ~= 'number') then
                return nil;
            end

            local text = tostring(candidate);

            if (text ~= '' and text ~= '.' and text:find('userdata:', 1, true) == nil) then
                return text;
            end

            return nil;
        end

        if (valueType == 'table' or valueType == 'userdata') then
            for index = 1, 20 do
                local ok, result = pcall(function()
                    return value[index];
                end);
                local candidate = ok == true and result or nil;
                local text = ReadNameValue(candidate, depth + 1);

                if (text ~= nil) then
                    return text;
                end
            end

            for _, key in ipairs({ 'Name', 'name', 'English', 'english', 'FullName', 'fullName' }) do
                local ok, candidate = pcall(function()
                    return value[key];
                end);
                local text = ok == true and ReadNameValue(candidate, depth + 1) or nil;

                if (text ~= nil) then
                    return text;
                end
            end

            return nil;
        end

        return CleanText(value);
    end

    return ReadNameValue(resource.En)
        or ReadNameValue(resource.en)
        or ReadNameValue(resource.English)
        or ReadNameValue(resource.english)
        or ReadNameValue(resource.Name)
        or ReadNameValue(resource.name)
        or '';
end

local spellAoeRadiusOverrides = {
    [225] = 10, -- Poisonga: BG lists 20' cast range and 10' AOE range; Ashita spell range is not the radius.
};

local function GetSpellAoeRadiusOverride(spellInfo)
    local spellName = tostring(spellInfo ~= nil and spellInfo.name or ''):lower();

    if (
        spellName:find('curaga', 1, false) ~= nil or
        spellName:find('cura', 1, false) ~= nil
    ) then
        return 10;
    end

    return spellAoeRadiusOverrides[tonumber(spellInfo ~= nil and spellInfo.id) or 0];
end

local function GetResourceByMethod(resourceManager, methodName, actionId)
    if (resourceManager == nil or type(resourceManager[methodName]) ~= 'function') then
        return nil;
    end

    local resource = nil;
    local ok = pcall(function()
        resource = resourceManager[methodName](resourceManager, actionId);
    end);

    if (ok ~= true or resource == nil) then
        return nil;
    end

    return resource;
end

local function GetCurrentActionTargetIndex()
    return targeting.GetCurrentSubTargetIndex()
        or targeting.GetCurrentTargetIndex()
        or GetSelfIndex();
end

local function GetCurrentActionCenterIndex(spellInfo)
    local mode = GetSpellAoeCenterMode(spellInfo);

    if (mode == 'self') then
        return GetSelfIndex();
    end

    if (mode == 'pet') then
        local petIndex = GetOwnPetIndex();

        if (petIndex ~= nil and petIndex > 0) then
            return petIndex;
        end
    end

    return GetCurrentActionTargetIndex();
end

local function GetActionInfo(actionId)
    actionId = tonumber(actionId) or 0;

    if (actionId <= 0) then
        return nil;
    end

    local resourceManager = AshitaCore:GetResourceManager();

    if (resourceManager == nil) then
        return nil;
    end

    local spell = GetResourceByMethod(resourceManager, 'GetSpellById', actionId);

    if (spell ~= nil) then
        return {
            resource = spell,
            resourceKind = 'spell',
            resourceMethod = 'GetSpellById',
            id = actionId,
            name = GetActionResourceName(spell),
            type = tostring(spell.Type or spell.type or ''),
            targets = tonumber(spell.Targets or spell.targets or spell.Target or spell.target),
            range = tonumber(spell.Range or spell.range),
            status = tonumber(spell.Status or spell.status),
        };
    end

    for _, methodName in ipairs({ 'GetAbilityById', 'GetAbilityByTimerId' }) do
        local ability = GetResourceByMethod(resourceManager, methodName, actionId);

        if (ability ~= nil) then
            return {
                resource = ability,
                resourceKind = 'ability',
                resourceMethod = methodName,
                id = actionId,
                name = GetActionResourceName(ability),
                type = tostring(ability.Type or ability.type or 'Ability'),
                targets = tonumber(ability.Targets or ability.targets or ability.Target or ability.target),
                range = tonumber(ability.Range or ability.range),
            };
        end
    end

    return nil;
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

local function GetDebugPlateKind(index)
    index = tonumber(index) or 0;

    if (index <= 0) then
        return 'enemy';
    end

    if (index == GetSelfIndex()) then
        return 'self';
    end

    if (index == GetOwnPetIndex()) then
        return 'pet';
    end

    local partySlot = GetPartySlotForIndex(index);

    if (partySlot ~= nil) then
        if (partySlot == 0) then
            return 'self';
        end

        if (index >= 1024 and index <= 1791) then
            return 'pc';
        end

        return 'trust';
    end

    if (index >= 1024 and index <= 1791) then
        return 'pc';
    end

    return 'enemy';
end

local function IsFriendlyPlateKind(plateKind)
    plateKind = tostring(plateKind or '');

    return plateKind == 'self' or plateKind == 'pc' or plateKind == 'trust' or plateKind == 'pet';
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

    if (targeting.IsSubTargetModeActive() ~= true) then
        return nil;
    end

    local actionId = SafeNumber(function() return targetManager:GetActionId(); end);
    local spellInfo = GetActionInfo(actionId);

    if (actionId == nil or spellInfo == nil) then
        return nil;
    end

    local aoeKind = GetSpellAoeKind(spellInfo);
    local targetKind = GetDebugPlateKind(GetCurrentActionTargetIndex());

    if (
        aoeKind == 'enemy' and
        spellInfo.resourceKind == 'spell' and
        enemyIndiSpells[tonumber(spellInfo.id) or 0] ~= true and
        tostring(spellInfo.type or ''):lower() ~= 'bluemagic' and
        IsFriendlyPlateKind(targetKind) == true
    ) then
        aoeKind = 'friendly';
    end

    if (spellInfo.type == 'BlueMagic' and spellInfo.range ~= nil and spellInfo.range > 0) then
        return {
            range = spellInfo.range,
            centerIndex = GetCurrentActionCenterIndex(spellInfo),
            kind = aoeKind,
        };
    end

    local overrideRange = GetSpellAoeRadiusOverride(spellInfo);

    if (overrideRange ~= nil and overrideRange > 0) then
        return {
            range = overrideRange,
            centerIndex = GetCurrentActionCenterIndex(spellInfo),
            kind = aoeKind,
        };
    end

    local rawRange = nil;

    if (targetManager.GetActionAoeRange ~= nil) then
        rawRange = SafeNumber(function() return targetManager:GetActionAoeRange(); end);
    end

    if (rawRange ~= nil and rawRange > 0) then
        return {
            range = rawRange,
            centerIndex = GetCurrentActionCenterIndex(spellInfo),
            kind = aoeKind,
        };
    end

    local resourceManager = AshitaCore:GetResourceManager();

    if (resourceManager ~= nil and resourceManager.GetSpellRange ~= nil) then
        local spellRange = SafeNumber(function() return resourceManager:GetSpellRange(actionId, true); end);

        if (spellRange ~= nil and spellRange > 0) then
            return {
                range = spellRange,
                centerIndex = GetCurrentActionCenterIndex(spellInfo),
                kind = aoeKind,
            };
        end
    end

    return nil;
end

function aoeNameHighlight.GetCurrentActionTargetRange()
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

    if ((isActionAoe ~= 1 and isActionAoe ~= 2) or targeting.IsSubTargetModeActive() ~= true) then
        return nil;
    end

    local actionId = SafeNumber(function() return targetManager:GetActionId(); end);

    if (actionId == nil or actionId <= 0) then
        return nil;
    end

    local resourceManager = AshitaCore:GetResourceManager();

    if (resourceManager ~= nil and resourceManager.GetSpellRange ~= nil) then
        local castRange = SafeNumber(function() return resourceManager:GetSpellRange(actionId, false); end);

        if (castRange ~= nil and castRange > 0) then
            return castRange;
        end
    end

    local spellInfo = GetActionInfo(actionId);

    return tonumber(spellInfo ~= nil and spellInfo.range) or nil;
end

function aoeNameHighlight.GetDebugText()
    local memory = AshitaCore:GetMemoryManager();
    local targetManager = memory ~= nil and memory:GetTarget() or nil;

    if (targetManager == nil) then
        return 'AOE debug: no target manager';
    end

    local isActionAoe = targetManager.GetIsActionAoe ~= nil and SafeNumber(function() return targetManager:GetIsActionAoe(); end) or nil;
    local actionId = targetManager.GetActionId ~= nil and SafeNumber(function() return targetManager:GetActionId(); end) or nil;
    local slot0 = targetManager.GetTargetIndex ~= nil and SafeNumber(function() return targetManager:GetTargetIndex(0); end) or nil;
    local slot1 = targetManager.GetTargetIndex ~= nil and SafeNumber(function() return targetManager:GetTargetIndex(1); end) or nil;
    local subActive = targetManager.GetIsSubTargetActive ~= nil and SafeNumber(function() return targetManager:GetIsSubTargetActive(); end) or nil;
    local spellInfo = GetActionInfo(actionId);
    local rawAoeRange = targetManager.GetActionAoeRange ~= nil and SafeNumber(function() return targetManager:GetActionAoeRange(); end) or nil;
    local rmSpellRange = nil;
    local resourceManager = AshitaCore:GetResourceManager();
    if (resourceManager ~= nil and resourceManager.GetSpellRange ~= nil and actionId ~= nil) then
        rmSpellRange = SafeNumber(function() return resourceManager:GetSpellRange(actionId, true); end);
    end
    local liveAoe = GetLiveActionAoe();
    local nearby = {};
    local targetDistance = nil;

    if (liveAoe ~= nil and tonumber(liveAoe.centerIndex) ~= nil and tonumber(liveAoe.range) ~= nil) then
        local entityManager = memory ~= nil and memory:GetEntity() or nil;
        local centerPosition = GetWorldPosition(liveAoe.centerIndex);
        targetDistance = Distance2D(GetWorldPosition(GetCurrentActionTargetIndex()), centerPosition);

        if (entityManager ~= nil and centerPosition ~= nil) then
            for index = 0, 2303 do
                local name = nil;
                local okName = pcall(function()
                    name = entityManager:GetName(index);
                end);

                if (okName == true and name ~= nil and tostring(name) ~= '' and index ~= tonumber(liveAoe.centerIndex)) then
                    local position = GetWorldPosition(index);
                    local distance = Distance2D(position, centerPosition);

                    if (distance ~= nil and distance <= (tonumber(liveAoe.range) + 5)) then
                        nearby[#nearby + 1] = {
                            index = index,
                            name = tostring(name),
                            distance = distance,
                            plateKind = GetDebugPlateKind(index),
                            highlighted = aoeNameHighlight.IsHighlighted(index, GetDebugPlateKind(index)) == true,
                        };
                    end
                end
            end

            table.sort(nearby, function(left, right)
                if (liveAoe.kind == 'enemy' and left.plateKind ~= right.plateKind) then
                    if (left.plateKind == 'enemy') then
                        return true;
                    end

                    if (right.plateKind == 'enemy') then
                        return false;
                    end
                end

                return left.distance < right.distance;
            end);
        end
    end

    local nearbyText = {};
    for index = 1, math.min(6, #nearby) do
        local item = nearby[index];
        nearbyText[#nearbyText + 1] = tostring(item.name) .. '#' .. tostring(item.index) .. '=' .. string.format('%.1f', item.distance) .. ':' .. tostring(item.plateKind) .. ':' .. (item.highlighted == true and 'Y' or 'N');
    end

    if (spellInfo == nil) then
        return table.concat({
            'AOE debug:',
            'isAoe=' .. tostring(isActionAoe),
            'actionId=' .. tostring(actionId),
            'sub=' .. tostring(subActive),
            'slot0=' .. tostring(slot0),
            'slot1=' .. tostring(slot1),
        'resource=nil',
        }, ' ');
    end

    return table.concat({
        'AOE debug:',
        'isAoe=' .. tostring(isActionAoe),
        'actionId=' .. tostring(actionId),
        'name=' .. tostring(spellInfo.name),
        'resource=' .. tostring(spellInfo.resourceKind),
        'method=' .. tostring(spellInfo.resourceMethod),
        'type=' .. tostring(spellInfo.type),
        'status=' .. tostring(spellInfo.status),
        'targets=' .. tostring(spellInfo.targets),
        'resRange=' .. tostring(spellInfo.range),
        'rawAoeRange=' .. tostring(rawAoeRange),
        'rmSpellRange=' .. tostring(rmSpellRange),
        'override=' .. tostring(GetSpellAoeRadiusOverride(spellInfo)),
        'kind=' .. tostring(liveAoe ~= nil and liveAoe.kind or GetSpellAoeKind(spellInfo)),
        'targetKind=' .. tostring(GetDebugPlateKind(GetCurrentActionTargetIndex())),
        'centerMode=' .. tostring(GetSpellAoeCenterMode(spellInfo)),
        'pet=' .. tostring(GetOwnPetIndex()),
        'liveRange=' .. tostring(liveAoe ~= nil and liveAoe.range or nil),
        'center=' .. tostring(liveAoe ~= nil and liveAoe.centerIndex or nil),
        'targetDist=' .. tostring(targetDistance ~= nil and string.format('%.1f', targetDistance) or nil),
        'sub=' .. tostring(subActive),
        'slot0=' .. tostring(slot0),
        'slot1=' .. tostring(slot1),
        'near=' .. table.concat(nearbyText, ','),
    }, ' ');
end

Distance2D = function(a, b)
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
