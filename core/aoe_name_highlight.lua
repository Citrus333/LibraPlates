local enemyCasts = require('core.enemy_casts');
local entities = require('core.entities');
local petSkills = require('data.pet_skills');
local statusEffects = require('core.status_effects');
local targetActionRange = require('core.target_action_range');
local targeting = require('core.targeting');

local aoeNameHighlight = {};
local automaticNameSize = 18;
local aoeEdgeAllowance = 0.9;
local highlightCacheSeconds = 0.03;
local highlightCache = {
    clock = 0,
    positions = {},
    results = {},
    liveAoe = nil,
    activeCasts = nil,
    partySlotByIndex = nil,
    selfIndex = nil,
    petIndex = nil,
};
local Distance2D = nil;
local suppressUntil = 0;
local suppressReason = nil;
local recentCommandAction = nil;
local GetLiveActionAoe = nil;

local function SafeNumber(fn)
    local ok, value = pcall(fn);

    if (ok ~= true) then
        return nil;
    end

    return tonumber(value);
end

local function GetHighlightCache()
    local now = os.clock();

    if ((now - (tonumber(highlightCache.clock) or 0)) > highlightCacheSeconds) then
        highlightCache.clock = now;
        highlightCache.positions = {};
        highlightCache.results = {};
        highlightCache.liveAoe = nil;
        highlightCache.activeCasts = nil;
        highlightCache.partySlotByIndex = nil;
        highlightCache.selfIndex = nil;
        highlightCache.petIndex = nil;
    end

    return highlightCache;
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

local function GetCachedWorldPosition(index)
    index = tonumber(index) or 0;

    if (index <= 0) then
        return nil;
    end

    local cache = GetHighlightCache();
    local cached = cache.positions[index];

    if (cached ~= nil) then
        return cached ~= false and cached or nil;
    end

    local position = GetWorldPosition(index);
    cache.positions[index] = position or false;
    return position;
end

local function GetSelfIndex()
    local cache = GetHighlightCache();

    if (cache.selfIndex ~= nil) then
        return cache.selfIndex;
    end

    local memory = AshitaCore:GetMemoryManager();
    local party = memory ~= nil and memory:GetParty() or nil;

    if (party == nil) then
        cache.selfIndex = 0;
        return 0;
    end

    cache.selfIndex = SafeNumber(function() return party:GetMemberTargetIndex(0); end) or 0;
    return cache.selfIndex;
end

local function GetOwnPetIndex()
    local cache = GetHighlightCache();

    if (cache.petIndex ~= nil) then
        return cache.petIndex;
    end

    if (entities ~= nil and entities.GetOwnPetTargetIndex ~= nil) then
        local petIndex = SafeNumber(function() return entities.GetOwnPetTargetIndex(); end);

        if (petIndex ~= nil and petIndex > 0) then
            cache.petIndex = petIndex;
            return petIndex;
        end
    end

    local selfIndex = GetSelfIndex();

    if (selfIndex == nil or selfIndex <= 0) then
        cache.petIndex = 0;
        return 0;
    end

    local memory = AshitaCore:GetMemoryManager();
    local entityManager = memory ~= nil and memory:GetEntity() or nil;

    if (entityManager == nil) then
        cache.petIndex = 0;
        return 0;
    end

    cache.petIndex = SafeNumber(function()
        local entity = entityManager:GetEntity(selfIndex);
        return entity ~= nil and entity.PetTargetIndex or 0;
    end) or 0;
    return cache.petIndex;
end

local function GetPartySlotForIndex(index)
    index = tonumber(index) or 0;

    if (index <= 0) then
        return nil;
    end

    local cache = GetHighlightCache();

    if (cache.partySlotByIndex ~= nil) then
        return cache.partySlotByIndex[index];
    end

    cache.partySlotByIndex = {};

    local memory = AshitaCore:GetMemoryManager();
    local party = memory ~= nil and memory:GetParty() or nil;

    if (party == nil) then
        return nil;
    end

    for slot = 0, 17 do
        local active = SafeNumber(function() return party:GetMemberIsActive(slot); end) or 0;
        local memberIndex = SafeNumber(function() return party:GetMemberTargetIndex(slot); end) or 0;

        if (active == 1 and memberIndex > 0) then
            cache.partySlotByIndex[memberIndex] = slot;
        end
    end

    return cache.partySlotByIndex[index];
end

local function HasTargetFlag(flags, flag)
    flags = tonumber(flags) or 0;
    flag = tonumber(flag) or 0;

    if (flags <= 0 or flag <= 0 or bit == nil or bit.band == nil) then
        return false;
    end

    return bit.band(flags, flag) ~= 0;
end

local function HasSelfTargetFlag(targets)
    targets = tonumber(targets) or 0;

    return targets == 1 or HasTargetFlag(targets, 1) == true;
end

local function HasFriendlyTargetFlag(targets)
    targets = tonumber(targets) or 0;

    return HasTargetFlag(targets, 1) == true
        or HasTargetFlag(targets, 2) == true
        or HasTargetFlag(targets, 3) == true;
end

local function NormalizeCommandText(value)
    return tostring(value or ''):lower():gsub('%s+', ' ');
end

function aoeNameHighlight.HandleCommandText(commandText)
    local text = NormalizeCommandText(commandText);

    if (
        text:find('^%s*/pet%s+') ~= nil and
        text:find('fight', 1, true) ~= nil
    ) then
        suppressUntil = os.clock() + 8.0;
        suppressReason = 'pet-fight';
    end
end

local function IsSuppressed()
    if (suppressUntil <= os.clock()) then
        suppressReason = nil;
        return false;
    end

    return true;
end

function aoeNameHighlight.IsSuppressed()
    return IsSuppressed();
end

function aoeNameHighlight.GetSuppressionReason()
    IsSuppressed();
    return suppressReason;
end

local function NormalizeResourceText(value)
    return tostring(value or ''):lower():gsub('[%s_%-%p]+', '');
end

local function ReadResourceScalar(resource, keys)
    if (resource == nil) then
        return nil;
    end

    for _, key in ipairs(keys) do
        local ok, value = pcall(function()
            return resource[key];
        end);

        if (ok == true and value ~= nil and tostring(value) ~= '' and tostring(value):find('userdata:', 1, true) == nil) then
            return value;
        end
    end

    return nil;
end

local blueMagicSkillId = 43;
local spellSkillKeys = {
    'Skill',
    'skill',
    'SkillId',
    'skillId',
    'SkillID',
    'skill_id',
    'MagicSkill',
    'magicSkill',
    'magic_skill',
};
local blueMagicPointKeys = {
    'BluPoints',
    'BLUPoints',
    'bluPoints',
    'blu_points',
    'BlueMagicPoints',
    'blueMagicPoints',
    'blue_magic_points',
};

local function IsBlueMagicResource(resource, spellType)
    local normalizedType = NormalizeResourceText(spellType);
    local skillId = tonumber(ReadResourceScalar(resource, spellSkillKeys));
    local bluPoints = tonumber(ReadResourceScalar(resource, blueMagicPointKeys));

    return normalizedType == 'bluemagic'
        or skillId == blueMagicSkillId
        or (bluPoints ~= nil and bluPoints > 0);
end

local function IsGeomancyResource(spellInfo)
    if (spellInfo == nil) then
        return false;
    end

    local spellType = tostring(spellInfo.type or '');
    local spellTypeNumber = tonumber(spellInfo.type);

    if (spellType == 'Geomancy' or spellTypeNumber == 7) then
        return true;
    end

    return false;
end

local function IsIndiGeomancy(spellInfo)
    if (IsGeomancyResource(spellInfo) ~= true) then
        return false;
    end

    local spellName = tostring(spellInfo.name or ''):lower();

    return spellName:find('indi%-', 1, false) ~= nil;
end

local function IsEnemyAuraResource(spellInfo)
    if (IsIndiGeomancy(spellInfo) ~= true) then
        return false;
    end

    return statusEffects.IsDebuff(spellInfo.status) == true;
end

local GetPetSkillInfo = nil;

local function IsEnemyPetAbilityResource(spellInfo)
    local petSkill = GetPetSkillInfo(spellInfo);

    if (petSkill ~= nil and tonumber(petSkill.validTargets) ~= nil) then
        return tonumber(petSkill.validTargets) == 4;
    end

    return false;
end

GetPetSkillInfo = function(spellInfo)
    if (
        spellInfo == nil or
        spellInfo.resourceKind ~= 'ability' or
        tonumber(spellInfo.category) ~= 18
    ) then
        return nil;
    end

    local actionId = tonumber(spellInfo.id) or 0;

    if (actionId <= 0) then
        return nil;
    end

    return petSkills[actionId - 512] or petSkills[actionId];
end

local function GetPetSkillAoeKind(spellInfo)
    local petSkill = GetPetSkillInfo(spellInfo);
    local validTargets = tonumber(petSkill ~= nil and petSkill.validTargets or nil);

    if (validTargets == 4) then
        return 'enemy';
    end

    if (validTargets == 3) then
        return 'friendly';
    end

    return nil;
end

local function GetPetSkillAoeRange(spellInfo)
    local petSkill = GetPetSkillInfo(spellInfo);

    if (petSkill == nil or tonumber(petSkill.aoe) == nil or tonumber(petSkill.aoe) <= 0) then
        return nil;
    end

    local radius = tonumber(petSkill.radius);

    if (radius ~= nil and radius > 0) then
        return radius;
    end

    return nil;
end

local function GetSpellAoeKind(spellInfo)
    if (spellInfo == nil) then
        return 'all';
    end

    local targets = tonumber(spellInfo.targets) or 0;
    local petAoeKind = GetPetSkillAoeKind(spellInfo);

    if (petAoeKind ~= nil) then
        return petAoeKind;
    end

    if (IsEnemyPetAbilityResource(spellInfo) == true) then
        return 'enemy';
    end

    if (IsEnemyAuraResource(spellInfo) == true) then
        return 'enemy';
    end

    if (spellInfo.isBlueMagic == true) then
        if (targets == 4 or targets == 32 or HasTargetFlag(targets, 4) == true or HasTargetFlag(targets, 32) == true) then
            return 'enemy';
        elseif (targets == 1 or targets == 2 or targets == 3 or HasTargetFlag(targets, 1) == true or HasTargetFlag(targets, 2) == true) then
            return 'friendly';
        end

        return 'all';
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

    if (spellInfo.resourceKind == 'ability' and GetPetSkillInfo(spellInfo) ~= nil and GetOwnPetIndex() > 0) then
        return 'pet';
    end

    if (
        spellInfo.resourceKind == 'spell' and
        HasSelfTargetFlag(spellInfo.targets) == true and
        targeting.IsSubTargetModeActive() ~= true
    ) then
        return 'self';
    end

    if (spellInfo.isBlueMagic == true) then
        return 'self';
    end

    if (IsIndiGeomancy(spellInfo) == true) then
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

local function BuildActionInfoFromResource(resource, resourceKind, resourceMethod, actionId)
    if (resource == nil or GetActionResourceName(resource) == '') then
        return nil;
    end

    local actionType = tostring(resource.Type or resource.type or ((resourceKind == 'spell') and '' or 'Ability'));

    return {
        resource = resource,
        resourceKind = resourceKind,
        resourceMethod = resourceMethod,
        id = actionId,
        name = GetActionResourceName(resource),
        type = actionType,
        category = tonumber(resource.category),
        isBlueMagic = (resourceKind == 'spell') and IsBlueMagicResource(resource, actionType) or false,
        targets = tonumber(resource.Targets or resource.targets or resource.Target or resource.target),
        range = tonumber(resource.Range or resource.range),
        status = tonumber(resource.Status or resource.status),
    };
end

local function GetActionInfo(actionId, preferredCategory, preferredMethod)
    actionId = tonumber(actionId) or 0;

    if (actionId <= 0) then
        return nil;
    end

    local resourceManager = AshitaCore:GetResourceManager();

    if (resourceManager == nil) then
        return nil;
    end

    local methodOrder = {};
    local seenMethods = {};
    local function AddMethod(methodName)
        methodName = tostring(methodName or '');

        if (methodName ~= '' and seenMethods[methodName] ~= true) then
            methodOrder[#methodOrder + 1] = methodName;
            seenMethods[methodName] = true;
        end
    end

    AddMethod(preferredMethod);

    local category = tonumber(preferredCategory) or 0;

    if (category == 2 or category == 9 or category == 16 or category == 18) then
        AddMethod('GetAbilityById');
        AddMethod('GetAbilityByTimerId');
        AddMethod('GetSpellById');
    elseif (category == 3) then
        AddMethod('GetSpellById');
        AddMethod('GetAbilityById');
        AddMethod('GetAbilityByTimerId');
    else
        AddMethod('GetSpellById');
        AddMethod('GetAbilityById');
        AddMethod('GetAbilityByTimerId');
    end

    for _, methodName in ipairs(methodOrder) do
        local resource = GetResourceByMethod(resourceManager, methodName, actionId);
        local resourceKind = (methodName == 'GetSpellById') and 'spell' or 'ability';
        local actionInfo = BuildActionInfoFromResource(resource, resourceKind, methodName, actionId);

        if (actionInfo ~= nil) then
            actionInfo.category = category;
            return actionInfo;
        end
    end

    return nil;
end

local IsFriendlyPlateKind = nil;

local function GetQueuedActionForId(actionId)
    local action = nil;

    if (targetActionRange ~= nil and targetActionRange.GetCurrentAction ~= nil) then
        local ok, currentAction = pcall(function()
            return targetActionRange.GetCurrentAction();
        end);

        if (ok == true and currentAction ~= nil and tonumber(currentAction.id) == tonumber(actionId)) then
            action = currentAction;
        end

        if (action == nil and targetActionRange.GetRecentAction ~= nil) then
            ok, currentAction = pcall(function()
                return targetActionRange.GetRecentAction();
            end);

            if (ok == true and currentAction ~= nil and tonumber(currentAction.id) == tonumber(actionId)) then
                action = currentAction;
            end
        end
    end

    if (action ~= nil and action.resource ~= nil) then
        return action;
    end

    if (
        recentCommandAction ~= nil and
        tonumber(recentCommandAction.id) == tonumber(actionId) and
        (os.clock() - (tonumber(recentCommandAction.updated) or 0)) <= 10.0
    ) then
        return recentCommandAction;
    end

    return action;
end

local function GetActionInfoForQueuedAction(actionId, queuedAction)
    if (
        queuedAction ~= nil and
        queuedAction.resource ~= nil and
        tonumber(queuedAction.id) == tonumber(actionId)
    ) then
        local methodName = tostring(queuedAction.resourceMethod or '');
        local resourceKind = (methodName == 'GetSpellById') and 'spell' or 'ability';
        local resolvedId = tonumber(queuedAction.resolvedId) or tonumber(actionId);
        local actionInfo = BuildActionInfoFromResource(queuedAction.resource, resourceKind, methodName, resolvedId);

        if (actionInfo ~= nil) then
            actionInfo.category = tonumber(queuedAction.category);
            actionInfo.id = tonumber(actionId) or resolvedId;
            actionInfo.resolvedId = resolvedId;
            return actionInfo;
        end
    end

    return GetActionInfo(
        actionId,
        queuedAction ~= nil and queuedAction.category or nil,
        queuedAction ~= nil and queuedAction.resourceMethod or nil
    );
end

local function ResolveSelfTargetAbilityCollision(actionId, actionInfo, targetKind, isActionAoe, rawActionAoeRange)
    if (
        actionInfo == nil or
        actionInfo.resourceKind ~= 'spell' or
        IsFriendlyPlateKind == nil or
        IsFriendlyPlateKind(targetKind) ~= true or
        isActionAoe ~= 2 or
        rawActionAoeRange == nil or
        rawActionAoeRange <= 0
    ) then
        return actionInfo;
    end

    local spellTargets = tonumber(actionInfo.targets) or 0;

    if (HasTargetFlag(spellTargets, 32) ~= true) then
        return actionInfo;
    end

    local abilityInfo = GetActionInfo(actionId, 2, 'GetAbilityById');

    if (
        abilityInfo ~= nil and
        abilityInfo.resourceKind == 'ability' and
        HasFriendlyTargetFlag(abilityInfo.targets) == true
    ) then
        return abilityInfo;
    end

    return actionInfo;
end

local function IsEligibleFriendlyAoeTarget(index, plateKind)
    index = tonumber(index) or 0;
    plateKind = tostring(plateKind or '');

    if (index <= 0) then
        return false;
    end

    if (plateKind == 'self') then
        return index == GetSelfIndex();
    end

    if (plateKind == 'pc' or plateKind == 'trust') then
        return GetPartySlotForIndex(index) ~= nil;
    end

    if (plateKind == 'pet') then
        return index == GetOwnPetIndex();
    end

    return false;
end

local function PlateMatchesAoeKind(index, plateKind, aoeKind)
    if (aoeKind == nil or aoeKind == 'all') then
        if (IsFriendlyPlateKind(plateKind) == true) then
            return IsEligibleFriendlyAoeTarget(index, plateKind);
        end

        return true;
    end

    plateKind = tostring(plateKind or '');

    if (aoeKind == 'enemy') then
        return plateKind == 'enemy';
    end

    if (aoeKind == 'friendly') then
        return IsEligibleFriendlyAoeTarget(index, plateKind);
    end

    return true;
end

local function GetCachedLiveActionAoe()
    local cache = GetHighlightCache();

    if (cache.liveAoe ~= nil) then
        return cache.liveAoe ~= false and cache.liveAoe or nil;
    end

    local liveAoe = GetLiveActionAoe();
    cache.liveAoe = liveAoe or false;
    return liveAoe;
end

local function GetCachedActiveAoeCasts()
    local cache = GetHighlightCache();

    if (cache.activeCasts ~= nil) then
        return cache.activeCasts;
    end

    cache.activeCasts = enemyCasts.GetActiveAoeCasts();
    return cache.activeCasts;
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

IsFriendlyPlateKind = function(plateKind)
    plateKind = tostring(plateKind or '');

    return plateKind == 'self' or plateKind == 'pc' or plateKind == 'trust' or plateKind == 'pet';
end

local function GetResolvedActionTargetIndex(spellInfo, targetManager)
    local actionTargetIndex = GetCurrentActionTargetIndex();

    if (
        spellInfo == nil or
        spellInfo.resourceKind ~= 'ability' or
        GetSpellAoeCenterMode(spellInfo) ~= 'pet' or
        IsEnemyPetAbilityResource(spellInfo) == true or
        targetManager == nil or
        targetManager.GetTargetIndex == nil
    ) then
        return actionTargetIndex;
    end

    local targetKind = GetDebugPlateKind(actionTargetIndex);

    if (IsFriendlyPlateKind(targetKind) ~= true) then
        return actionTargetIndex;
    end

    local slot1 = SafeNumber(function() return targetManager:GetTargetIndex(1); end);

    if (slot1 ~= nil and slot1 > 0 and GetDebugPlateKind(slot1) == 'enemy') then
        return slot1;
    end

    return actionTargetIndex;
end

GetLiveActionAoe = function()
    if (IsSuppressed() == true) then
        return nil;
    end

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

    local actionId = SafeNumber(function() return targetManager:GetActionId(); end);
    local queuedAction = GetQueuedActionForId(actionId);
    local spellInfo = GetActionInfoForQueuedAction(actionId, queuedAction);
    local rawActionAoeRange = targetManager.GetActionAoeRange ~= nil and SafeNumber(function() return targetManager:GetActionAoeRange(); end) or nil;

    if (actionId == nil or spellInfo == nil) then
        return nil;
    end

    local isSelfOrFriendlySpellAoe = (
        spellInfo.resourceKind == 'spell' and
        (isActionAoe == 1 or isActionAoe == 2) and
        rawActionAoeRange ~= nil and
        rawActionAoeRange > 0 and
        (
            HasSelfTargetFlag(spellInfo.targets) == true or
            HasFriendlyTargetFlag(spellInfo.targets) == true
        )
    );

    if (
        targeting.IsSubTargetModeActive() ~= true and
        spellInfo.resourceKind ~= 'ability' and
        isSelfOrFriendlySpellAoe ~= true
    ) then
        return nil;
    end

    local aoeKind = GetSpellAoeKind(spellInfo);
    local actionTargetIndex = GetResolvedActionTargetIndex(spellInfo, targetManager);
    local targetKind = GetDebugPlateKind(actionTargetIndex);

    spellInfo = ResolveSelfTargetAbilityCollision(actionId, spellInfo, targetKind, isActionAoe, rawActionAoeRange);
    aoeKind = GetSpellAoeKind(spellInfo);
    actionTargetIndex = GetResolvedActionTargetIndex(spellInfo, targetManager);
    targetKind = GetDebugPlateKind(actionTargetIndex);

    if (
        aoeKind == 'enemy' and
        spellInfo.resourceKind == 'spell' and
        IsEnemyAuraResource(spellInfo) ~= true and
        spellInfo.isBlueMagic ~= true and
        IsFriendlyPlateKind(targetKind) == true
    ) then
        aoeKind = 'friendly';
    end

    if (
        aoeKind == 'friendly' and
        spellInfo.resourceKind == 'spell' and
        targetKind == 'enemy'
    ) then
        return nil;
    end

    local petAoeKind = GetPetSkillAoeKind(spellInfo);

    if (petAoeKind ~= nil) then
        aoeKind = petAoeKind;
    elseif (spellInfo.resourceKind == 'ability' and HasFriendlyTargetFlag(spellInfo.targets) == true) then
        aoeKind = 'friendly';
    elseif (spellInfo.resourceKind == 'ability') then
        if (IsFriendlyPlateKind(targetKind) == true) then
            aoeKind = 'friendly';
        elseif (targetKind == 'enemy') then
            aoeKind = 'enemy';
        end
    end

    local resourceManager = AshitaCore:GetResourceManager();
    local resourceAoeRange = nil;

    if (resourceManager ~= nil and resourceManager.GetSpellRange ~= nil) then
        resourceAoeRange = SafeNumber(function() return resourceManager:GetSpellRange(actionId, true); end);
    end

    if (
        IsGeomancyResource(spellInfo) == true and
        rawActionAoeRange ~= nil and
        rawActionAoeRange > 0
    ) then
        resourceAoeRange = rawActionAoeRange;
    end

    if (
        spellInfo.resourceKind == 'spell' and
        (isActionAoe == 1 or isActionAoe == 2) and
        rawActionAoeRange ~= nil and
        rawActionAoeRange > 0 and
        (resourceAoeRange == nil or resourceAoeRange <= 0) and
        (
            HasSelfTargetFlag(spellInfo.targets) == true or
            HasFriendlyTargetFlag(spellInfo.targets) == true
        )
    ) then
        resourceAoeRange = rawActionAoeRange;
    end

    local petSkillAoeRange = GetPetSkillAoeRange(spellInfo);

    if (petSkillAoeRange ~= nil and petSkillAoeRange > 0) then
        resourceAoeRange = petSkillAoeRange;
    end

    if (
        spellInfo.resourceKind == 'ability' and
        (isActionAoe == 1 or isActionAoe == 2) and
        rawActionAoeRange ~= nil and
        rawActionAoeRange > 0
    ) then
        resourceAoeRange = rawActionAoeRange;
    end

    if (spellInfo.resourceKind == 'ability' and tonumber(spellInfo.range) ~= nil and tonumber(spellInfo.range) > 0) then
        if (petSkillAoeRange ~= nil and petSkillAoeRange > 0) then
            resourceAoeRange = petSkillAoeRange;
        elseif (aoeKind == 'enemy' and rawActionAoeRange ~= nil and rawActionAoeRange > 0) then
            resourceAoeRange = rawActionAoeRange;
        elseif (resourceAoeRange == nil or resourceAoeRange <= 0) then
            resourceAoeRange = math.max(tonumber(resourceAoeRange) or 0, tonumber(spellInfo.range));
        end
    end

    if (
        isActionAoe ~= 1 and
        isActionAoe ~= 2 and
        (resourceAoeRange == nil or resourceAoeRange <= 0)
    ) then
        return nil;
    end

    if (spellInfo.isBlueMagic == true) then
        local blueRange = resourceAoeRange;

        if (blueRange ~= nil and blueRange > 0) then
            return {
                range = blueRange,
                centerIndex = GetSelfIndex(),
                kind = aoeKind,
            };
        end
    end

    if (resourceAoeRange ~= nil and resourceAoeRange > 0) then
        return {
            range = resourceAoeRange,
            centerIndex = GetCurrentActionCenterIndex(spellInfo),
            kind = aoeKind,
        };
    end

    return nil;
end

function aoeNameHighlight.GetCurrentActionTargetRange()
    if (IsSuppressed() == true) then
        return nil;
    end

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
    local queuedAction = GetQueuedActionForId(actionId);

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

    local spellInfo = GetActionInfoForQueuedAction(actionId, queuedAction);

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
    local queuedAction = GetQueuedActionForId(actionId);
    local spellInfo = GetActionInfoForQueuedAction(actionId, queuedAction);
    local rawAoeRange = targetManager.GetActionAoeRange ~= nil and SafeNumber(function() return targetManager:GetActionAoeRange(); end) or nil;
    local rmSpellRange = nil;
    local rmTargetRange = nil;
    local resourceManager = AshitaCore:GetResourceManager();
    if (resourceManager ~= nil and resourceManager.GetSpellRange ~= nil and actionId ~= nil) then
        rmSpellRange = SafeNumber(function() return resourceManager:GetSpellRange(actionId, true); end);
        rmTargetRange = SafeNumber(function() return resourceManager:GetSpellRange(actionId, false); end);
    end
    local liveAoe = GetLiveActionAoe();
    local actionTargetIndex = GetResolvedActionTargetIndex(spellInfo, targetManager);
    local debugTargetKind = GetDebugPlateKind(actionTargetIndex);
    spellInfo = ResolveSelfTargetAbilityCollision(actionId, spellInfo, debugTargetKind, isActionAoe, rawAoeRange);
    actionTargetIndex = GetResolvedActionTargetIndex(spellInfo, targetManager);
    local petSkill = GetPetSkillInfo(spellInfo);
    local nearby = {};
    local targetDistance = nil;

    if (liveAoe ~= nil and tonumber(liveAoe.centerIndex) ~= nil and tonumber(liveAoe.range) ~= nil) then
        local entityManager = memory ~= nil and memory:GetEntity() or nil;
        local centerPosition = GetWorldPosition(liveAoe.centerIndex);
        targetDistance = Distance2D(GetWorldPosition(actionTargetIndex), centerPosition);

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
        'petSkill=' .. tostring(petSkill ~= nil and (tostring(petSkill.name) .. '#' .. tostring((tonumber(actionId) or 0) - 512)) or nil),
        'petValid=' .. tostring(petSkill ~= nil and petSkill.validTargets or nil),
        'petRadius=' .. tostring(petSkill ~= nil and petSkill.radius or nil),
        'rawAoeRange=' .. tostring(rawAoeRange),
        'rmSpellRange=' .. tostring(rmSpellRange),
        'rmTargetRange=' .. tostring(rmTargetRange),
        'kind=' .. tostring(liveAoe ~= nil and liveAoe.kind or GetSpellAoeKind(spellInfo)),
        'targetKind=' .. tostring(GetDebugPlateKind(actionTargetIndex)),
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

    local cache = GetHighlightCache();
    local resultKey = tostring(index) .. ':' .. tostring(plateKind or '');

    if (cache.results[resultKey] ~= nil) then
        return cache.results[resultKey] == true;
    end

    local liveAoe = GetCachedLiveActionAoe();

    if (liveAoe ~= nil and tonumber(liveAoe.range) ~= nil and tonumber(liveAoe.range) > 0 and PlateMatchesAoeKind(index, plateKind, liveAoe.kind) == true) then
        local centerIndex = tonumber(liveAoe.centerIndex) or GetSelfIndex();

        if (index == centerIndex) then
            cache.results[resultKey] = true;
            return true;
        end

        local subjectPosition = GetCachedWorldPosition(index);
        local centerPosition = GetCachedWorldPosition(centerIndex);
        local distance = Distance2D(subjectPosition, centerPosition);

        if (distance ~= nil and distance <= (tonumber(liveAoe.range) + aoeEdgeAllowance)) then
            cache.results[resultKey] = true;
            return true;
        end
    end

    local subjectPosition = nil;

    for _, castData in ipairs(GetCachedActiveAoeCasts()) do
        local radius = tonumber(castData.aoeRadius) or 0;
        local targetIndex = tonumber(castData.aoeCenterIndex or castData.targetIndex) or 0;

        if (radius > 0 and targetIndex > 0 and PlateMatchesAoeKind(index, plateKind, castData.aoeKind) == true) then
            if (targetIndex == index) then
                cache.results[resultKey] = true;
                return true;
            end

            subjectPosition = subjectPosition or GetCachedWorldPosition(index);
            local targetPosition = GetCachedWorldPosition(targetIndex);
            local distance = Distance2D(subjectPosition, targetPosition);

            if (distance ~= nil and distance <= (radius + aoeEdgeAllowance)) then
                cache.results[resultKey] = true;
                return true;
            end
        end
    end

    cache.results[resultKey] = false;
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

function aoeNameHighlight.HasLiveAoe()
    return GetCachedLiveActionAoe() ~= nil;
end

return aoeNameHighlight;
