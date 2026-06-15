local ffi = require('ffi');
local log = require('core.log');

local enemyCasts = {};
local casts = {};
local interruptedCasts = {};
local defaultAoeRadius = 10.0;
local interruptedCastMessages = {
    [84] = true,
    [85] = true,
};
local debugEnabled = false;
local debugUntil = nil;
local debugLines = {};
local debugLiveSamples = {};

local function IsDebugEnabled()
    if (debugUntil ~= nil and os.clock() >= debugUntil) then
        debugEnabled = false;
        debugUntil = nil;
    end

    return debugEnabled == true;
end

local function AddDebugLine(text, silent)
    local line = string.format('%.3f %s', os.clock(), tostring(text or ''));

    debugLines[#debugLines + 1] = line;
    while (#debugLines > 24) do
        table.remove(debugLines, 1);
    end

    if (silent ~= true and IsDebugEnabled() == true) then
        log.Info('Cast capture: ' .. line);
    end
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

local function GetIndexFromServerId(serverId)
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

local function GetSelfServerId()
    local memory = AshitaCore:GetMemoryManager();
    local party = memory ~= nil and memory:GetParty() or nil;
    local entityManager = memory ~= nil and memory:GetEntity() or nil;
    local selfIndex = nil;

    if (party == nil or entityManager == nil) then
        return nil;
    end

    selfIndex = SafeCall(nil, function()
        return party:GetMemberTargetIndex(0);
    end);

    if (selfIndex == nil or tonumber(selfIndex) == 0) then
        return nil;
    end

    return SafeCall(nil, function()
        return entityManager:GetServerId(selfIndex);
    end);
end

local function GetEntityPosition(index)
    index = tonumber(index) or 0;

    if (index == 0) then
        return nil;
    end

    local entityManager = GetEntityManager();

    if (entityManager == nil) then
        return nil;
    end

    local x = SafeCall(nil, function() return entityManager:GetLocalPositionX(index); end);
    local y = SafeCall(nil, function() return entityManager:GetLocalPositionY(index); end);
    local z = SafeCall(nil, function() return entityManager:GetLocalPositionZ(index); end);

    if (x == nil or y == nil or z == nil) then
        return nil;
    end

    return {
        x = tonumber(x),
        y = tonumber(y),
        z = tonumber(z),
    };
end

local function SafeEntityField(entity, key)
    if (entity == nil) then
        return nil;
    end

    return SafeCall(nil, function()
        return entity[key];
    end);
end

local function GetLiveCastSnapshot(serverId)
    local index = GetIndexFromServerId(serverId);
    local entityManager = GetEntityManager();
    local entity = nil;

    if (index > 0) then
        entity = SafeCall(nil, function()
            return GetEntity(index);
        end);
    end

    return {
        index = index,
        status = SafeEntityField(entity, 'Status'),
        managerStatus = (index > 0 and entityManager ~= nil) and SafeCall(nil, function()
            return entityManager:GetStatus(index);
        end) or nil,
        animation = SafeEntityField(entity, 'Animation'),
        action = SafeEntityField(entity, 'Action'),
        actionTimer = SafeEntityField(entity, 'ActionTimer'),
        modelAnimation = SafeEntityField(entity, 'ModelAnimation'),
        serverAnimation = SafeEntityField(entity, 'ServerAnimation'),
        position = GetEntityPosition(index),
    };
end

local function HasMovedFromCastStart(castData)
    if (castData == nil or castData.isSelfCast ~= true or castData.startPosition == nil) then
        return false;
    end

    local elapsed = os.clock() - (tonumber(castData.startTime) or os.clock());
    if (elapsed < 0.20) then
        return false;
    end

    local current = GetEntityPosition(castData.userIndex);
    if (current == nil) then
        return false;
    end

    local dx = (tonumber(current.x) or 0) - (tonumber(castData.startPosition.x) or 0);
    local dy = (tonumber(current.y) or 0) - (tonumber(castData.startPosition.y) or 0);
    local dz = (tonumber(current.z) or 0) - (tonumber(castData.startPosition.z) or 0);
    local movedSq = (dx * dx) + (dy * dy) + (dz * dz);

    return movedSq >= 0.0025;
end

local function StartInterruptedCast(serverId, castData, reason)
    if (castData == nil or castData.isSelfCast ~= true) then
        return;
    end

    local now = os.clock();
    local startTime = tonumber(castData.startTime) or now;
    local castTime = math.max(0.1, tonumber(castData.castTime) or 0.1);
    local elapsed = math.max(0, now - startTime);
    local remaining = math.max(0, castTime - elapsed);

    if (remaining <= 0.05) then
        interruptedCasts[serverId] = nil;
        return;
    end

    interruptedCasts[serverId] = {
        spellId = castData.spellId,
        spellIconId = castData.spellIconId,
        spellStatusId = castData.spellStatusId,
        spellName = castData.spellName,
        startTime = now,
        originalCastTime = castTime,
        duration = remaining,
        reason = tostring(reason or 'interrupt'),
    };
end

local function AddLiveDebugSample(serverId, castData)
    if (IsDebugEnabled() ~= true) then
        return;
    end

    local now = os.clock();
    local lastSample = debugLiveSamples[serverId];

    if (lastSample ~= nil and (now - lastSample) < 0.25) then
        return;
    end

    debugLiveSamples[serverId] = now;

    local live = GetLiveCastSnapshot(serverId);
    AddDebugLine(
        'live user=' .. tostring(serverId) ..
        ' elapsed=' .. string.format('%.2f', now - (tonumber(castData.startTime) or now)) ..
        '/' .. tostring(castData.castTime) ..
        ' index=' .. tostring(live.index) ..
        ' status=' .. tostring(live.status) ..
        ' mstatus=' .. tostring(live.managerStatus) ..
        ' anim=' .. tostring(live.animation) ..
        ' action=' .. tostring(live.action) ..
        ' timer=' .. tostring(live.actionTimer) ..
        ' modelAnim=' .. tostring(live.modelAnimation) ..
        ' serverAnim=' .. tostring(live.serverAnimation) ..
        ' pos=' .. tostring(live.position ~= nil and string.format('%.3f,%.3f,%.3f', live.position.x or 0, live.position.y or 0, live.position.z or 0) or nil),
        true
    );
end

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

local function GetSpellResourceById(spellId)
    spellId = tonumber(spellId) or 0;

    if (spellId <= 0) then
        return nil;
    end

    return SafeCall(nil, function()
        return AshitaCore:GetResourceManager():GetSpellById(spellId);
    end);
end

local function GetSpellNameByResource(spell, spellId)
    spellId = tonumber(spellId) or 0;

    if (spell == nil) then
        return tostring(spellId);
    end

    if (spell.Name ~= nil) then
        local name1 = GetSpellNameValue(spell.Name[1]);

        if (name1 ~= nil) then
            return name1;
        end

        local name2 = GetSpellNameValue(spell.Name[2]);

        if (name2 ~= nil) then
            return name2;
        end
    end

    local en = GetSpellNameValue(spell.En);

    if (en ~= nil) then
        return en;
    end

    return tostring(spellId);
end

local function GetSpellCastTimeByResource(spell)
    if (spell == nil or spell.CastTime == nil) then
        return 3.0;
    end

    local castTime = spell.CastTime / 4.0;

    if (castTime <= 0) then
        return 1.0;
    end

    return castTime;
end

local function GetSpellIconIdByResource(spell, spellId)
    spellId = tonumber(spellId) or 0;

    if (spell ~= nil) then
        for _, key in ipairs({ 'Icon', 'icon', 'IconId', 'iconId', 'IconID', 'icon_id' }) do
            local value = tonumber(spell[key]);

            if (value ~= nil and value > 0) then
                return value;
            end
        end
    end

    return spellId > 0 and spellId or nil;
end

local function GetSpellStatusIdByResource(spell)
    if (spell ~= nil) then
        for _, key in ipairs({ 'Status', 'status', 'StatusId', 'statusId', 'StatusID', 'status_id' }) do
            local value = tonumber(spell[key]);

            if (value ~= nil and value > 0) then
                return value;
            end
        end
    end

    return nil;
end

local function GetSpellTargetsByResource(spell)
    if (spell == nil) then
        return nil;
    end

    for _, key in ipairs({ 'Targets', 'targets', 'Target', 'target' }) do
        local value = tonumber(spell[key]);

        if (value ~= nil) then
            return value;
        end
    end

    return nil;
end

local function GetSpellTypeByResource(spell)
    if (spell == nil) then
        return nil;
    end

    for _, key in ipairs({ 'Type', 'type' }) do
        local value = spell[key];

        if (value ~= nil and tostring(value) ~= '') then
            return tostring(value);
        end
    end

    return nil;
end

local function GetSpellRangeByResource(spell)
    if (spell == nil) then
        return nil;
    end

    for _, key in ipairs({ 'Range', 'range' }) do
        local value = tonumber(spell[key]);

        if (value ~= nil) then
            return value;
        end
    end

    return nil;
end

local function IsDefensiveAoeSpellName(spellName)
    local name = tostring(spellName or ''):lower():gsub('[%s%-_]+', '');

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

local function GetAoeRadiusByResource(spell, spellName)
    if (IsDefensiveAoeSpellName(spellName) ~= true) then
        local spellType = GetSpellTypeByResource(spell);
        local spellRange = GetSpellRangeByResource(spell);

        if (spellType == 'BlueMagic' and spellRange ~= nil and spellRange > 0) then
            return spellRange;
        end

        return nil;
    end

    return defaultAoeRadius;
end

local function GetAoeKindByResource(spell)
    if (GetSpellTypeByResource(spell) ~= 'BlueMagic') then
        return 'all';
    end

    local targets = GetSpellTargetsByResource(spell);
    if (targets == 32) then
        return 'enemy';
    end

    return 'friendly';
end

local function GetBlueMagicAoeKind(spell, spellId, spellName)
    if (GetSpellTypeByResource(spell) ~= 'BlueMagic') then
        return 'all';
    end

    local targets = GetSpellTargetsByResource(spell);
    if (targets == 32) then
        return 'enemy';
    elseif (targets == 1) then
        return 'friendly';
    end

    local normalizedName = tostring(spellName or ''):lower():gsub('[%s%-_]+', '');
    if (tonumber(spellId) == 584 or normalizedName == 'sheepsong') then
        return 'enemy';
    end

    return 'friendly';
end

local function ResolveSpell(candidateIds)
    for _, candidateId in ipairs(candidateIds) do
        local spellId = tonumber(candidateId) or 0;
        local spell = GetSpellResourceById(spellId);

        if (spell ~= nil) then
            return spellId, spell;
        end
    end

    return 0, nil;
end

local function ParseActionPacket(e)
    if (e == nil or e.id ~= 0x0028 or e.data_raw == nil or ashita.bits == nil) then
        return nil;
    end

    local bitData = e.data_raw;
    local bitOffset = 40;
    local maxLength = (tonumber(e.size) or 0) * 8;

    local function UnpackBits(length)
        if ((bitOffset + length) >= maxLength) then
            maxLength = 0;
            return 0;
        end

        local value = ashita.bits.unpack_be(bitData, 0, bitOffset, length);
        bitOffset = bitOffset + length;
        return value;
    end

    local actionPacket = {
        UserId = UnpackBits(32),
        Targets = {},
    };
    actionPacket.UserIndex = GetIndexFromServerId(actionPacket.UserId);

    local targetCount = UnpackBits(6);
    bitOffset = bitOffset + 4;
    actionPacket.Type = UnpackBits(4);

    if (actionPacket.Type == 8 or actionPacket.Type == 9) then
        actionPacket.Param = UnpackBits(16);
        actionPacket.SpellGroup = UnpackBits(16);
    else
        actionPacket.Param = UnpackBits(32);
    end

    actionPacket.Recast = UnpackBits(32);

    if (targetCount > 0) then
        for _ = 1, targetCount do
            local target = {
                Id = UnpackBits(32),
                Actions = {},
            };
            local actionCount = UnpackBits(4);

            if (actionCount == 0) then
                break;
            end

            for _ = 1, actionCount do
                local action = {};
                action.Reaction = UnpackBits(5);
                action.Animation = UnpackBits(12);
                action.SpecialEffect = UnpackBits(7);
                action.Knockback = UnpackBits(3);
                action.Param = UnpackBits(17);
                action.Message = UnpackBits(10);
                action.Flags = UnpackBits(31);

                if (UnpackBits(1) == 1) then
                    action.AdditionalEffect = {
                        Damage = UnpackBits(10),
                        Param = UnpackBits(17),
                        Message = UnpackBits(10),
                    };
                end

                if (UnpackBits(1) == 1) then
                    action.SpikesEffect = {
                        Damage = UnpackBits(10),
                        Param = UnpackBits(14),
                        Message = UnpackBits(10),
                    };
                end

                target.Actions[#target.Actions + 1] = action;
            end

            actionPacket.Targets[#actionPacket.Targets + 1] = target;
        end
    end

    if (maxLength ~= 0 and #actionPacket.Targets > 0) then
        return actionPacket;
    end

    return nil;
end

local function HandleEnemyCastActionPacket(actionPacket)
    if (actionPacket == nil or actionPacket.UserId == nil) then
        return;
    end

    if (actionPacket.Type == 8 or actionPacket.Type == 9) then
        if (
            actionPacket.Targets == nil or
            actionPacket.Targets[1] == nil or
            actionPacket.Targets[1].Actions == nil or
            actionPacket.Targets[1].Actions[1] == nil
        ) then
            return;
        end

        local action = actionPacket.Targets[1].Actions[1];
        local message = tonumber(action.Message) or 0;
        AddDebugLine(
            'type=' .. tostring(actionPacket.Type) ..
            ' user=' .. tostring(actionPacket.UserId) ..
            ' activeBefore=' .. tostring(casts[actionPacket.UserId] ~= nil) ..
            ' message=' .. tostring(message) ..
            ' param=' .. tostring(actionPacket.Param) ..
            ' actionParam=' .. tostring(action.Param)
        );

        if (message == 0) then
            StartInterruptedCast(actionPacket.UserId, casts[actionPacket.UserId], 'message0');
            casts[actionPacket.UserId] = nil;
            AddDebugLine('clear-message0 user=' .. tostring(actionPacket.UserId) .. ' activeAfter=' .. tostring(casts[actionPacket.UserId] ~= nil));
            return;
        end

        local spellId, spell = ResolveSpell({
            action.Param,
            actionPacket.Param,
        });

        if (interruptedCastMessages[message] == true) then
            StartInterruptedCast(actionPacket.UserId, casts[actionPacket.UserId], 'message' .. tostring(message));
            casts[actionPacket.UserId] = nil;
            AddDebugLine('clear-interrupt-message user=' .. tostring(actionPacket.UserId) .. ' message=' .. tostring(message));
            return;
        end

        if (spellId == 0 or spell == nil) then
            return;
        end

        local spellName = GetSpellNameByResource(spell, spellId);
        local targetServerId = actionPacket.Targets[1].Id;
        local spellType = GetSpellTypeByResource(spell);
        local aoeRadius = GetAoeRadiusByResource(spell, spellName);
        local aoeCenterIndex = GetIndexFromServerId(targetServerId);

        if (spellType == 'BlueMagic' and aoeRadius ~= nil and aoeRadius > 0) then
            aoeCenterIndex = actionPacket.UserIndex;
        end

        casts[actionPacket.UserId] = {
            userIndex = actionPacket.UserIndex,
            isSelfCast = tonumber(actionPacket.UserId) == tonumber(GetSelfServerId()),
            startPosition = GetEntityPosition(actionPacket.UserIndex),
            spellId = spellId,
            spellIconId = GetSpellIconIdByResource(spell, spellId),
            spellStatusId = GetSpellStatusIdByResource(spell),
            spellName = spellName,
            spellTargets = GetSpellTargetsByResource(spell),
            targetServerId = targetServerId,
            targetIndex = GetIndexFromServerId(targetServerId),
            aoeCenterIndex = aoeCenterIndex,
            aoeRadius = aoeRadius,
            aoeKind = GetBlueMagicAoeKind(spell, spellId, spellName),
            startTime = os.clock(),
            castTime = GetSpellCastTimeByResource(spell),
        };
        AddDebugLine('start user=' .. tostring(actionPacket.UserId) .. ' spell=' .. tostring(spellName) .. ' castTime=' .. tostring(casts[actionPacket.UserId].castTime));

        return;
    end

    if (actionPacket.Type == 4 or actionPacket.Type == 11) then
        casts[actionPacket.UserId] = nil;
        AddDebugLine('clear-type user=' .. tostring(actionPacket.UserId) .. ' type=' .. tostring(actionPacket.Type));
    end
end

function enemyCasts.HandlePacketIn(e)
    if (e == nil) then
        return;
    end

    if (e.id == 0x000A) then
        casts = {};
        interruptedCasts = {};
        return;
    end

    if (e.id ~= 0x0028) then
        return;
    end

    HandleEnemyCastActionPacket(ParseActionPacket(e));
end

function enemyCasts.GetActiveCast(serverId)
    serverId = tonumber(serverId) or 0;

    if (serverId == 0 or casts[serverId] == nil) then
        return nil;
    end

    local castData = casts[serverId];

    if (HasMovedFromCastStart(castData) == true) then
        StartInterruptedCast(serverId, castData, 'movement');
        casts[serverId] = nil;
        debugLiveSamples[serverId] = nil;
        AddDebugLine('clear-self-movement user=' .. tostring(serverId) .. ' spell=' .. tostring(castData.spellName));
        return nil;
    end

    if ((os.clock() - castData.startTime) >= castData.castTime) then
        casts[serverId] = nil;
        debugLiveSamples[serverId] = nil;
        return nil;
    end

    AddLiveDebugSample(serverId, castData);

    return castData;
end

function enemyCasts.TickDebug()
    if (IsDebugEnabled() ~= true) then
        return;
    end

    for serverId, castData in pairs(casts) do
        if (HasMovedFromCastStart(castData) == true) then
            StartInterruptedCast(serverId, castData, 'movement');
            casts[serverId] = nil;
            debugLiveSamples[serverId] = nil;
            AddDebugLine('clear-self-movement user=' .. tostring(serverId) .. ' spell=' .. tostring(castData.spellName));
        elseif ((os.clock() - (tonumber(castData.startTime) or os.clock())) < (tonumber(castData.castTime) or 0)) then
            AddLiveDebugSample(serverId, castData);
        end
    end
end

function enemyCasts.GetInterruptedCast(serverId)
    serverId = tonumber(serverId) or 0;

    if (serverId == 0 or interruptedCasts[serverId] == nil) then
        return nil;
    end

    local data = interruptedCasts[serverId];
    local duration = math.max(0.1, tonumber(data.duration) or 0.1);
    local elapsed = math.max(0, os.clock() - (tonumber(data.startTime) or os.clock()));

    if (elapsed >= duration) then
        interruptedCasts[serverId] = nil;
        return nil;
    end

    data.elapsed = elapsed;
    data.remaining = math.max(0, duration - elapsed);
    data.castTime = tonumber(data.originalCastTime) or duration;
    data.progress = math.max(0, math.min(100, (data.remaining / math.max(0.1, data.castTime)) * 100));
    data.interrupted = true;

    return data;
end

function enemyCasts.EnableDebugForSeconds(seconds)
    debugEnabled = true;
    debugUntil = os.clock() + (tonumber(seconds) or 20);
    AddDebugLine('debug-on seconds=' .. tostring(tonumber(seconds) or 20));
end

function enemyCasts.SetDebugEnabled(value)
    debugEnabled = value == true;
    debugUntil = nil;
    AddDebugLine('debug=' .. tostring(debugEnabled));
end

function enemyCasts.GetDebugText()
    local lines = {};

    lines[#lines + 1] = 'Cast capture enabled=' .. tostring(IsDebugEnabled()) .. ' active=' .. tostring(next(casts) ~= nil);

    for _, line in ipairs(debugLines) do
        lines[#lines + 1] = line;
    end

    return table.concat(lines, ' | ');
end

function enemyCasts.GetActiveAoeCasts()
    local results = {};
    local now = os.clock();

    for serverId, castData in pairs(casts) do
        if ((now - (tonumber(castData.startTime) or now)) >= (tonumber(castData.castTime) or 0)) then
            casts[serverId] = nil;
        elseif (tonumber(castData.aoeRadius) ~= nil and tonumber(castData.aoeCenterIndex or castData.targetIndex) ~= nil and tonumber(castData.aoeCenterIndex or castData.targetIndex) > 0) then
            results[#results + 1] = castData;
        end
    end

    return results;
end

return enemyCasts;
