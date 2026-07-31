require('common');

local statusEffects = require('core.status_effects');
local playerStatuses = require('core.player_statuses');
local actionRelevance = require('core.action_relevance');
local engagedEnemies = require('core.engaged_enemies');
local entityResolver = require('core.entity_resolver');
local targeting = require('core.targeting');

local enemyStatuses = {};
local tracked = {};
local debugUntil = 0;
local debugTargetServerId = 0;
local debugLines = {};
local AddDebugLine = nil;
local GetDuration = nil;
local TrackStatus = nil;
local ClearStatus = nil;

local statusOnMessages = T{100, 144, 160, 164, 166, 186, 194, 203, 205, 230, 236, 266, 267, 268, 269, 237, 271, 272, 277, 278, 279, 280, 319, 320, 375, 412, 420, 421, 424, 425, 645, 754, 755, 804};
local statusOffMessages = T{206, 64, 159, 168, 204, 321, 322, 341, 342, 343, 344, 350, 378, 531, 647, 805, 806};
local deathMessages = T{6, 20, 97, 113, 406, 605, 646};
local spellDamageMessages = T{2, 252, 264, 265};
local statusDurations = {
    [33] = 180,   -- Haste
    [34] = 180,   -- Blaze Spikes
    [35] = 180,   -- Ice Spikes
    [36] = 300,   -- Blink
    [37] = 300,   -- Stoneskin
    [38] = 180,   -- Shock Spikes
    [39] = 600,   -- Aquaveil
    [40] = 1800,  -- Protect
    [41] = 1800,  -- Shell
    [42] = 90,    -- Regen
    [43] = 150,   -- Refresh
    [116] = 180,  -- Phalanx
};
local spellToBuff = {
    [43] = 40, [44] = 40, [45] = 40, [46] = 40, [47] = 40,
    [48] = 41, [49] = 41, [50] = 41, [51] = 41, [52] = 41,
    [53] = 36,
    [54] = 37,
    [55] = 39,
    [57] = 33,
    [108] = 42,
    [109] = 43,
    [110] = 42,
    [111] = 42,
    [115] = 116,
    [116] = 116,
    [125] = 40, [126] = 40, [127] = 40, [128] = 40, [129] = 40,
    [130] = 41, [131] = 41, [132] = 41, [133] = 41, [134] = 41,
    [249] = 34,
    [250] = 35,
    [251] = 38,
    [511] = 33,
};

local LUNAR_CRY_BP_ID = 530;
local LUNAR_CRY_EFFECT_A = 146;
local LUNAR_CRY_EFFECT_B = 148;
local LUNAR_CRY_DURATION = 60;
local GEO_AURA_RADIUS = 5.5;
local activeGeoEnemyAura = nil;
local visibleNameCache = {};

local indiEnemyAuras = {
    [769] = 540, -- Indi-Poison
    [787] = 558, -- Indi-Wilt
    [788] = 559, -- Indi-Frailty
    [789] = 560, -- Indi-Fade
    [790] = 561, -- Indi-Malaise
    [791] = 562, -- Indi-Slip
    [792] = 563, -- Indi-Torpor
    [793] = 564, -- Indi-Vex
    [794] = 565, -- Indi-Languor
    [795] = 566, -- Indi-Slow
    [796] = 567, -- Indi-Paralysis
    [797] = 568, -- Indi-Gravity
};

local indiEnemyStatusToSpell = {
    [540] = 769, -- Indi-Poison
    [558] = 787, -- Indi-Wilt
    [559] = 788, -- Indi-Frailty
    [560] = 789, -- Indi-Fade
    [561] = 790, -- Indi-Malaise
    [562] = 791, -- Indi-Slip
    [563] = 792, -- Indi-Torpor
    [564] = 793, -- Indi-Vex
    [565] = 794, -- Indi-Languor
    [566] = 795, -- Indi-Slow
    [567] = 796, -- Indi-Paralysis
    [568] = 797, -- Indi-Gravity
};

local indiEnemyNameToAura = {
    ['indi-poison'] = { spellId = 769, statusId = 540 },
    ['indi-wilt'] = { spellId = 787, statusId = 558 },
    ['indi-frailty'] = { spellId = 788, statusId = 559 },
    ['indi-fade'] = { spellId = 789, statusId = 560 },
    ['indi-malaise'] = { spellId = 790, statusId = 561 },
    ['indi-slip'] = { spellId = 791, statusId = 562 },
    ['indi-torpor'] = { spellId = 792, statusId = 563 },
    ['indi-vex'] = { spellId = 793, statusId = 564 },
    ['indi-languor'] = { spellId = 794, statusId = 565 },
    ['indi-slow'] = { spellId = 795, statusId = 566 },
    ['indi-paralysis'] = { spellId = 796, statusId = 567 },
    ['indi-gravity'] = { spellId = 797, statusId = 568 },
};

local statusNameToBuff = {
    ['haste'] = 33,
    ['blaze spikes'] = 34,
    ['ice spikes'] = 35,
    ['blink'] = 36,
    ['stoneskin'] = 37,
    ['shock spikes'] = 38,
    ['aquaveil'] = 39,
    ['protect'] = 40,
    ['shell'] = 41,
    ['regen'] = 42,
    ['refresh'] = 43,
    ['phalanx'] = 116,
};

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

    local packet = {
        UserId = UnpackBits(32),
        Targets = {},
    };

    local targetCount = UnpackBits(6);
    bitOffset = bitOffset + 4;
    packet.Type = UnpackBits(4);

    if (packet.Type == 8 or packet.Type == 9) then
        packet.Param = UnpackBits(16);
        packet.SpellGroup = UnpackBits(16);
    else
        packet.Param = UnpackBits(32);
    end

    packet.Recast = UnpackBits(32);

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

        packet.Targets[#packet.Targets + 1] = target;
    end

    if (maxLength ~= 0 and #packet.Targets > 0) then
        return packet;
    end

    return nil;
end

local function ParseMessagePacket(e)
    if (e == nil or e.data == nil) then
        return nil;
    end

    local ok, packet = pcall(function()
        return {
            sender = struct.unpack('i4', e.data, 0x04 + 1),
            target = struct.unpack('i4', e.data, 0x08 + 1),
            param = struct.unpack('i4', e.data, 0x0C + 1),
            value = struct.unpack('i4', e.data, 0x10 + 1),
            sender_tgt = struct.unpack('i2', e.data, 0x14 + 1),
            target_tgt = struct.unpack('i2', e.data, 0x16 + 1),
            message = struct.unpack('i2', e.data, 0x18 + 1),
        };
    end);

    if (ok ~= true) then
        return nil;
    end

    return packet;
end

local function GetSelfServerId()
    local memory = AshitaCore:GetMemoryManager();
    local party = memory ~= nil and memory:GetParty() or nil;
    local entity = memory ~= nil and memory:GetEntity() or nil;

    if (party == nil or entity == nil) then
        return 0;
    end

    local okIndex, selfIndex = pcall(function()
        return party:GetMemberTargetIndex(0);
    end);

    selfIndex = okIndex == true and tonumber(selfIndex) or 0;

    if (selfIndex == 0) then
        return 0;
    end

    local okServer, serverId = pcall(function()
        return entity:GetServerId(selfIndex);
    end);

    return okServer == true and (tonumber(serverId) or 0) or 0;
end

local function RefreshGeoEnemyAura(spellId, statusId)
    spellId = tonumber(spellId) or 0;

    if (indiEnemyAuras[spellId] == nil) then
        return;
    end

    statusId = indiEnemyAuras[spellId];

    activeGeoEnemyAura = {
        spellId = spellId,
        statusId = statusId or indiEnemyAuras[spellId],
        expiresAt = os.time() + GetDuration(spellId),
    };

    AddDebugLine(
        'geo aura active spell=' .. tostring(activeGeoEnemyAura.spellId) ..
        ' status=' .. tostring(activeGeoEnemyAura.statusId)
    );
end

local function ClearGeoEnemyAura(statusId)
    statusId = tonumber(statusId) or 0;

    if (
        activeGeoEnemyAura ~= nil and
        (statusId == 0 or statusId == tonumber(activeGeoEnemyAura.statusId))
    ) then
        AddDebugLine('geo aura cleared status=' .. tostring(activeGeoEnemyAura.statusId));
        activeGeoEnemyAura = nil;
    end
end

local function StripControlCodes(text)
    return tostring(text or ''):gsub(string.char(0x1E) .. '.', ''):gsub('[%z\1-\31]', '');
end

local function SafeEntityCall(fallback, fn)
    local ok, result = pcall(fn);

    if (ok ~= true or result == nil) then
        return fallback;
    end

    return result;
end

local function NormalizeName(text)
    text = StripControlCodes(text);
    text = text:gsub('^The%s+', '');
    text = text:gsub('^the%s+', '');
    text = text:gsub('^%s+', ''):gsub('%s+$', '');
    return text:lower();
end

local function NormalizeStatusName(text)
    text = StripControlCodes(text);
    text = text:gsub('_', ' ');
    text = text:gsub('%s+', ' ');
    text = text:gsub('^%s+', ''):gsub('%s+$', '');
    text = text:gsub('%.+$', '');
    return text:lower();
end

local function GetServerIdByVisibleName(name)
    local wanted = NormalizeName(name);

    if (wanted == '') then
        return 0;
    end

    local memory = AshitaCore:GetMemoryManager();
    local entityManager = memory ~= nil and memory:GetEntity() or nil;

    if (entityManager == nil) then
        return 0;
    end

    local function ResolveCandidate(index)
        index = tonumber(index) or 0;

        if (index <= 0 or index > 2303) then
            return 0;
        end

        local entity = SafeEntityCall(nil, function() return entityManager:GetEntity(index); end);
        local entityName = entity ~= nil and tostring(entity.Name or '') or '';

        if (entityName ~= '' and NormalizeName(entityName) == wanted) then
            local serverId = entityResolver.GetServerId(index);

            if (serverId > 0 and actionRelevance.IsPartyOrAllianceServerId(serverId) ~= true) then
                visibleNameCache[wanted] = {
                    index = index,
                    serverId = serverId,
                    seenAt = os.clock(),
                };
                return serverId;
            end
        end

        return 0;
    end

    local cached = visibleNameCache[wanted];
    if (cached ~= nil and (os.clock() - (tonumber(cached.seenAt) or 0)) <= 30.0) then
        local cachedServerId = ResolveCandidate(cached.index);

        if cachedServerId > 0 and cachedServerId == tonumber(cached.serverId) then
            return cachedServerId;
        end

        visibleNameCache[wanted] = nil;
    end

    local candidates = {};
    local seenIndexes = {};
    local function AddCandidate(index)
        index = tonumber(index) or 0;

        if (index > 0 and index <= 2303 and seenIndexes[index] ~= true) then
            seenIndexes[index] = true;
            candidates[#candidates + 1] = index;
        end
    end

    local targetIndex, subTargetIndex = targeting.GetCurrentTargetAndSubTargetIndexes();
    AddCandidate(targetIndex);
    AddCandidate(subTargetIndex);

    for _, index in ipairs(engagedEnemies.GetTrackedIndexes()) do
        AddCandidate(index);
    end

    for serverId in pairs(tracked) do
        AddCandidate(entityResolver.GetIndex(serverId));
    end

    for _, index in ipairs(candidates) do
        local serverId = ResolveCandidate(index);

        if (serverId > 0) then
            return serverId;
        end
    end

    return 0;
end

local function GetStatusIdByStatusName(name)
    local normalized = NormalizeStatusName(name);

    if (statusNameToBuff[normalized] ~= nil) then
        return statusNameToBuff[normalized];
    end

    for prefix, statusId in pairs(statusNameToBuff) do
        if (string.find(normalized, prefix, 1, true) ~= nil) then
            return statusId;
        end
    end

    return nil;
end

local function SetGeoEnemyAuraFromName(name)
    local aura = indiEnemyNameToAura[tostring(name or ''):lower()];

    if (aura == nil) then
        return false;
    end

    activeGeoEnemyAura = {
        spellId = aura.spellId,
        statusId = aura.statusId,
        expiresAt = nil,
        source = 'text',
    };

    AddDebugLine('geo aura text spell=' .. tostring(aura.spellId) .. ' status=' .. tostring(aura.statusId));
    return true;
end

local function RefreshGeoEnemyAuraFromSelfStatuses()
    local rows = playerStatuses.GetSelfRows(nil);

    for _, row in ipairs(rows or {}) do
        local statusId = tonumber(row.id) or 0;
        local spellId = indiEnemyStatusToSpell[statusId];

        if (spellId ~= nil) then
            activeGeoEnemyAura = {
                spellId = spellId,
                statusId = statusId,
                expiresAt = nil,
            };

            return activeGeoEnemyAura;
        end
    end

    if (
        activeGeoEnemyAura ~= nil and
        activeGeoEnemyAura.source ~= 'text' and
        indiEnemyStatusToSpell[tonumber(activeGeoEnemyAura.statusId) or 0] ~= nil
    ) then
        activeGeoEnemyAura = nil;
    end

    return nil;
end

function enemyStatuses.HandleTextIn(e)
    local message = StripControlCodes(
        (e ~= nil and (e.message or e.text or e.original or e.modified or e.injected)) or ''
    );

    if (message == '') then
        return;
    end

    local gainedName, gainedStatus = message:match('^The%s+(.+)%s+gains the effect of%s+(.+)%.?$');
    if (gainedName == nil) then
        gainedName, gainedStatus = message:match('^(.+)%s+gains the effect of%s+(.+)%.?$');
    end

    if (gainedName ~= nil and gainedStatus ~= nil and TrackStatus ~= nil) then
        local statusId = GetStatusIdByStatusName(gainedStatus);

        if (statusId ~= nil) then
            local serverId = GetServerIdByVisibleName(gainedName);

            if (serverId > 0) then
                TrackStatus(serverId, statusId, 300);
                AddDebugLine('text tracked buff name=' .. tostring(gainedName) .. ' status=' .. tostring(gainedStatus) .. ' id=' .. tostring(statusId));
                return;
            end
        end
    end

    local wearsName, wearsStatus = message:match("^The%s+(.+)'s%s+(.+)%s+effect wears off%.?$");
    if (wearsName == nil) then
        wearsName, wearsStatus = message:match("^(.+)'s%s+(.+)%s+effect wears off%.?$");
    end

    if (wearsName ~= nil and wearsStatus ~= nil and ClearStatus ~= nil) then
        local statusId = GetStatusIdByStatusName(wearsStatus);

        if (statusId ~= nil) then
            local serverId = GetServerIdByVisibleName(wearsName);

            if (serverId > 0) then
                ClearStatus(serverId, statusId);
                AddDebugLine('text cleared buff name=' .. tostring(wearsName) .. ' status=' .. tostring(wearsStatus) .. ' id=' .. tostring(statusId));
                return;
            end
        end
    end

    local indiName = message:match('starts casting%s+(Indi%-%S+)%s+on%s+');

    if (indiName ~= nil and SetGeoEnemyAuraFromName(indiName) == true) then
        return;
    end

    if (message:find('Colure Active effect wears off', 1, true) ~= nil) then
        ClearGeoEnemyAura(0);
    end
end

local function GetSelfGeoStatusText()
    local rows = playerStatuses.GetSelfRows(nil);
    local parts = {};

    for _, row in ipairs(rows or {}) do
        local statusId = tonumber(row.id) or 0;

        if (indiEnemyStatusToSpell[statusId] ~= nil) then
            parts[#parts + 1] = tostring(statusId) .. '->' .. tostring(indiEnemyStatusToSpell[statusId]);
        end
    end

    return #parts > 0 and table.concat(parts, ',') or 'none';
end

TrackStatus = function(serverId, statusId, duration)
    serverId = tonumber(serverId) or 0;
    statusId = tonumber(statusId) or 0;

    if (serverId == 0 or statusId <= 0) then
        return;
    end

    tracked[serverId] = tracked[serverId] or {};
    tracked[serverId][statusId] = os.time() + (tonumber(duration) or 300);
end

AddDebugLine = function(text)
    if ((tonumber(debugUntil) or 0) <= os.clock()) then
        return;
    end

    debugLines[#debugLines + 1] = string.format('%.3f %s', os.clock(), tostring(text or ''));

    while (#debugLines > 24) do
        table.remove(debugLines, 1);
    end
end

local function ShouldDebugTarget(serverId)
    if ((tonumber(debugUntil) or 0) <= os.clock()) then
        return false;
    end

    local targetServerId = tonumber(debugTargetServerId) or 0;

    return targetServerId == 0 or targetServerId == (tonumber(serverId) or 0);
end

ClearStatus = function(serverId, statusId)
    serverId = tonumber(serverId) or 0;
    statusId = tonumber(statusId) or 0;

    if (serverId == 0 or statusId <= 0 or tracked[serverId] == nil) then
        return;
    end

    tracked[serverId][statusId] = nil;
end

local function ClearStatusFromMessage(message)
    if (message == nil) then
        return;
    end

    ClearStatus(message.target, message.param);
    ClearStatus(message.target, message.value);
end

local function SafeCall(fallback, fn)
    local ok, result = pcall(fn);

    if (ok ~= true or result == nil) then
        return fallback;
    end

    return result;
end

local function GetSpellResourceById(spellId)
    spellId = tonumber(spellId) or 0;

    if (spellId <= 0) then
        return nil;
    end

    local resourceManager = AshitaCore:GetResourceManager();

    if (resourceManager == nil or resourceManager.GetSpellById == nil) then
        return nil;
    end

    return SafeCall(nil, function()
        return resourceManager:GetSpellById(spellId);
    end);
end

local function GetSpellStatusByResource(spellId)
    local spell = GetSpellResourceById(spellId);

    if (spell == nil) then
        return nil;
    end

    for _, key in ipairs({ 'Status', 'status', 'StatusId', 'statusId', 'status_id' }) do
        local value = tonumber(SafeCall(nil, function()
            return spell[key];
        end));

        if (value ~= nil and value > 0) then
            return value;
        end
    end

    return nil;
end

local function GetSpellName(spellId)
    local spell = GetSpellResourceById(spellId);

    if (spell == nil) then
        return '';
    end

    return SafeCall('', function()
        if (type(spell.Name) == 'table') then
            return spell.Name[1] or spell.Name[0] or spell.Name.en or spell.Name.English or '';
        end

        return spell.Name or spell.NameSingle or '';
    end);
end

local function GetStatusIdBySpellId(spellId)
    spellId = tonumber(spellId) or 0;

    if (spellToBuff[spellId] ~= nil) then
        return spellToBuff[spellId];
    end

    local statusId = GetSpellStatusByResource(spellId) or statusEffects.GetDebuffIdBySpellId(spellId);

    if (statusId ~= nil and tonumber(statusId) > 0) then
        return statusId;
    end

    local spellName = string.lower(tostring(GetSpellName(spellId) or ''));
    spellName = string.gsub(spellName, '_', ' ');
    spellName = string.gsub(spellName, '%s+', ' ');
    spellName = string.gsub(spellName, '^%s+', '');
    spellName = string.gsub(spellName, '%s+$', '');

    if (string.find(spellName, 'protect', 1, true) ~= nil) then
        return 40;
    elseif (string.find(spellName, 'shell', 1, true) ~= nil) then
        return 41;
    elseif (string.find(spellName, 'haste', 1, true) ~= nil) then
        return 33;
    elseif (string.find(spellName, 'refresh', 1, true) ~= nil) then
        return 43;
    elseif (string.find(spellName, 'regen', 1, true) ~= nil) then
        return 42;
    elseif (spellName == 'blink') then
        return 36;
    elseif (spellName == 'stoneskin') then
        return 37;
    elseif (spellName == 'aquaveil') then
        return 39;
    elseif (string.find(spellName, 'phalanx', 1, true) ~= nil) then
        return 116;
    elseif (spellName == 'blaze spikes') then
        return 34;
    elseif (spellName == 'ice spikes') then
        return 35;
    elseif (spellName == 'shock spikes') then
        return 38;
    end

    return nil;
end

local function GetSpellDurationByResource(spellId)
    local spell = GetSpellResourceById(spellId);

    if (spell == nil) then
        return nil;
    end

    for _, key in ipairs({ 'Duration', 'duration', 'BaseDuration', 'base_duration' }) do
        local value = tonumber(SafeCall(nil, function()
            return spell[key];
        end));

        if (value ~= nil and value > 0) then
            return value;
        end
    end

    return nil;
end

GetDuration = function(spellId)
    spellId = tonumber(spellId) or 0;

    local resourceDuration = GetSpellDurationByResource(spellId);

    if (resourceDuration ~= nil and resourceDuration > 0) then
        return resourceDuration;
    end

    if (spellId == 58 or spellId == 80) then return 120; end
    if (spellId == 56 or spellId == 79) then return 180; end
    if (spellId == 216) then return 120; end
    if (spellId == 254 or spellId == 276) then return 180; end
    if (spellId == 59 or spellId == 359) then return 120; end
    if (spellId == 253 or spellId == 259 or spellId == 273 or spellId == 274) then return 90; end
    if (spellId == 258 or spellId == 362) then return 60; end
    if (spellId == 252) then return 5; end
    if (spellId >= 220 and spellId <= 229) then return 120; end
    if (spellId >= 235 and spellId <= 240) then return 120; end

    return statusDurations[tonumber(GetStatusIdBySpellId(spellId)) or 0] or 300;
end

local function HandleActionPacket(packet)
    if (packet == nil) then
        return;
    end

    if (actionRelevance.ShouldIgnoreOutsideFriendlyCaster(packet) == true) then
        return;
    end

    local now = os.time();

    for _, target in ipairs(packet.Targets or {}) do
        for _, action in ipairs(target.Actions or {}) do
            local spellId = packet.Param;
            local message = action.Message;

            if (ShouldDebugTarget(target.Id) == true) then
                AddDebugLine(
                    'action type=' .. tostring(packet.Type) ..
                    ' spell=' .. tostring(spellId) ..
                    ' target=' .. tostring(target.Id) ..
                    ' msg=' .. tostring(message) ..
                    ' param=' .. tostring(action.Param) ..
                    ' react=' .. tostring(action.Reaction) ..
                    ' anim=' .. tostring(action.Animation) ..
                    ' special=' .. tostring(action.SpecialEffect)
                );
            end

            if (packet.Type == 13 and packet.Param == LUNAR_CRY_BP_ID) then
                TrackStatus(target.Id, LUNAR_CRY_EFFECT_A, LUNAR_CRY_DURATION);
                TrackStatus(target.Id, LUNAR_CRY_EFFECT_B, LUNAR_CRY_DURATION);
                if (ShouldDebugTarget(target.Id) == true) then
                    AddDebugLine('tracked lunar-cry target=' .. tostring(target.Id));
                end
            end

            if (statusOffMessages:contains(message)) then
                ClearStatus(target.Id, action.Param);
                if (tonumber(target.Id) == GetSelfServerId()) then
                    ClearGeoEnemyAura(action.Param);
                end
            elseif (packet.Type == 4 and spellDamageMessages:contains(message)) then
                local expiry = nil;

                if (spellId == 23 or spellId == 33 or spellId == 230) then
                    expiry = now + 60;
                elseif (spellId == 24 or spellId == 231) then
                    expiry = now + 120;
                elseif (spellId == 25 or spellId == 232) then
                    expiry = now + 150;
                end

                tracked[target.Id] = tracked[target.Id] or {};

                if (spellId == 23 or spellId == 24 or spellId == 25 or spellId == 33) then
                    tracked[target.Id][134] = expiry;
                    tracked[target.Id][135] = nil;
                elseif (spellId == 230 or spellId == 231 or spellId == 232) then
                    tracked[target.Id][134] = nil;
                    tracked[target.Id][135] = expiry;
                end
            else
                local statusId = tonumber(action.Param);
                local inferredSpellStatusId = nil;

                if (packet.Type == 4) then
                    inferredSpellStatusId = GetStatusIdBySpellId(spellId);

                    if (statusId == nil or statusId <= 0) then
                        statusId = inferredSpellStatusId;
                    end
                end

                if (statusOnMessages:contains(message) or (packet.Type == 4 and inferredSpellStatusId ~= nil and statusEffects.IsBuff(inferredSpellStatusId) == true)) then
                    statusId = (statusEffects.IsBuff(inferredSpellStatusId) == true) and inferredSpellStatusId or statusId;
                    TrackStatus(target.Id, statusId, GetDuration(spellId));
                    if (tonumber(target.Id) == GetSelfServerId()) then
                        RefreshGeoEnemyAura(spellId, statusId);
                    end
                    if (ShouldDebugTarget(target.Id) == true) then
                        AddDebugLine(
                            'tracked status target=' .. tostring(target.Id) ..
                            ' id=' .. tostring(statusId) ..
                            ' duration=' .. tostring(GetDuration(spellId)) ..
                            ' isBuff=' .. tostring(statusEffects.IsBuff(statusId)) ..
                            ' isDebuff=' .. tostring(statusEffects.IsDebuff(statusId)) ..
                            ' inferred=' .. tostring(inferredSpellStatusId ~= nil)
                        );
                    end
                end
            end
        end
    end
end

function enemyStatuses.HandlePacketIn(e)
    if (e == nil) then
        return;
    end

    if (e.id == 0x000A) then
        tracked = {};
    elseif (e.id == 0x0028) then
        HandleActionPacket(ParseActionPacket(e));
    elseif (e.id == 0x0029) then
        local message = ParseMessagePacket(e);

        if (message == nil) then
            return;
        end

        if (actionRelevance.IsOutsideFriendlyIndex(actionRelevance.GetIndexFromServerId(message.sender)) == true) then
            return;
        end

        if (deathMessages:contains(message.message)) then
            tracked[message.target] = nil;
        elseif (statusOffMessages:contains(message.message)) then
            ClearStatusFromMessage(message);
            if (tonumber(message.target) == GetSelfServerId()) then
                ClearGeoEnemyAura(message.param);
                ClearGeoEnemyAura(message.value);
            end
        end

        if (ShouldDebugTarget(message.target) == true) then
            AddDebugLine(
                'message target=' .. tostring(message.target) ..
                ' msg=' .. tostring(message.message) ..
                ' param=' .. tostring(message.param) ..
                ' value=' .. tostring(message.value)
            );
        end
    end
end

function enemyStatuses.EnableDebugForSeconds(seconds, serverId)
    debugUntil = os.clock() + (tonumber(seconds) or 20);
    debugTargetServerId = tonumber(serverId) or 0;
    debugLines = {};
end

function enemyStatuses.SetDebugEnabled(enabled)
    if (enabled == true) then
        enemyStatuses.EnableDebugForSeconds(20, debugTargetServerId);
        return;
    end

    debugUntil = 0;
end

function enemyStatuses.GetDebugText(serverId)
    RefreshGeoEnemyAuraFromSelfStatuses();

    serverId = tonumber(serverId) or 0;

    local now = os.time();
    local parts = {};
    local rows = tracked[serverId] or {};

    for statusId, expiresAt in pairs(rows) do
        local seconds = (tonumber(expiresAt) or 0) - now;

        if (seconds > 0) then
            parts[#parts + 1] =
                tostring(statusId) .. ':' .. tostring(seconds) ..
                ':buff=' .. tostring(statusEffects.IsBuff(statusId)) ..
                ':debuff=' .. tostring(statusEffects.IsDebuff(statusId));
        end
    end

    table.sort(parts);

    return
        'Enemy status debug server=' .. tostring(serverId) ..
        ' tracked=' .. (#parts > 0 and table.concat(parts, ',') or 'none') ..
        ' selfGeo=' .. GetSelfGeoStatusText() ..
        ' ' .. playerStatuses.GetSelfRawStatusText() ..
        ' geoAura=' .. (
            activeGeoEnemyAura ~= nil
            and (tostring(activeGeoEnemyAura.spellId) .. '/' .. tostring(activeGeoEnemyAura.statusId) .. '/' .. tostring(activeGeoEnemyAura.expiresAt ~= nil and ((tonumber(activeGeoEnemyAura.expiresAt) or 0) - now) or 'aura'))
            or 'none'
        ) ..
        ' capture=' .. tostring((tonumber(debugUntil) or 0) > os.clock()) ..
        ' target=' .. tostring(debugTargetServerId) ..
        ' log=' .. (#debugLines > 0 and table.concat(debugLines, ' | ') or 'none');
end

function enemyStatuses.GetGeoAuraDebuffRows(enemyDistance, isEngaged)
    RefreshGeoEnemyAuraFromSelfStatuses();

    if (isEngaged ~= true or activeGeoEnemyAura == nil) then
        return {};
    end

    if (activeGeoEnemyAura.expiresAt ~= nil and (tonumber(activeGeoEnemyAura.expiresAt) or 0) <= os.time()) then
        activeGeoEnemyAura = nil;
        return {};
    end

    if ((tonumber(enemyDistance) or 999) > GEO_AURA_RADIUS) then
        return {};
    end

    return {
        {
            id = activeGeoEnemyAura.statusId,
            seconds = nil,
            order = 9000,
            source = 'geo-aura',
        },
    };
end

function enemyStatuses.GetGeoAuraSignature()
    RefreshGeoEnemyAuraFromSelfStatuses();

    if (activeGeoEnemyAura == nil) then
        return 'none';
    end

    return tostring(activeGeoEnemyAura.spellId) .. ':' .. tostring(activeGeoEnemyAura.statusId) .. ':' .. tostring(activeGeoEnemyAura.expiresAt ~= nil and ((tonumber(activeGeoEnemyAura.expiresAt) or 0) > os.time()) or 'aura');
end

function enemyStatuses.HasActiveStatus(serverId, kind)
    serverId = tonumber(serverId) or 0;

    if (serverId == 0 or tracked[serverId] == nil) then
        return false;
    end

    local now = os.time();

    for statusId, expiresAt in pairs(tracked[serverId]) do
        local seconds = (tonumber(expiresAt) or 0) - now;

        if (seconds > 0) then
            if (
                (kind == 'buff' and statusEffects.IsBuff(statusId)) or
                (kind == 'debuff' and statusEffects.IsDebuff(statusId)) or
                (kind ~= 'buff' and kind ~= 'debuff')
            ) then
                return true;
            end
        else
            tracked[serverId][statusId] = nil;
        end
    end

    return false;
end

function enemyStatuses.GetActiveStatusRows(serverId, kind)
    serverId = tonumber(serverId) or 0;

    if (serverId == 0 or tracked[serverId] == nil) then
        return {};
    end

    local now = os.time();
    local results = {};

    for statusId, expiresAt in pairs(tracked[serverId]) do
        local seconds = (tonumber(expiresAt) or 0) - now;

        if (seconds > 0) then
            if (
                (kind == 'buff' and statusEffects.IsBuff(statusId)) or
                (kind == 'debuff' and statusEffects.IsDebuff(statusId)) or
                (kind ~= 'buff' and kind ~= 'debuff')
            ) then
                results[#results + 1] = {
                    id = statusId,
                    seconds = seconds,
                };
            end
        else
            tracked[serverId][statusId] = nil;
        end
    end

    table.sort(results, function(a, b)
        if ((tonumber(a.seconds) or 0) == (tonumber(b.seconds) or 0)) then
            return (tonumber(a.id) or 0) < (tonumber(b.id) or 0);
        end

        return (tonumber(a.seconds) or 0) < (tonumber(b.seconds) or 0);
    end);

    return results;
end

return enemyStatuses;
