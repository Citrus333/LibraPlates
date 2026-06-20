require('common');

local statusEffects = require('core.status_effects');

local partyStatuses = {};
local partyBuffs = {};
local trackedTimers = {};
local lastMemoryRefresh = 0;
local levelSyncStatusIds = {
    [269] = true,
};
local statusOnMessages = T{ 100, 144, 160, 164, 166, 186, 194, 203, 205, 230, 236, 266, 267, 268, 269, 271, 272, 277, 278, 279, 280, 319, 320, 375, 412, 420, 421, 424, 425, 645, 754, 755, 804 };
local statusOffMessages = T{ 64, 159, 168, 204, 206, 321, 322, 341, 342, 343, 344, 350, 378, 531, 647, 805, 806 };
local deathMessages = T{ 6, 20, 97, 113, 406, 605, 646 };
local abilityTypes = T{ 6, 14, 15 };

local knownStatusDurations = {
    [33] = 180,  -- Haste
    [36] = 300,  -- Blink
    [37] = 300,  -- Stoneskin
    [38] = 300,  -- Shock Spikes
    [39] = 300,  -- Aquaveil
    [40] = 1800, -- Protect
    [41] = 1800, -- Shell
    [42] = 75,   -- Regen
    [43] = 150,  -- Refresh
    [69] = 300,  -- Invisible
    [71] = 300,  -- Sneak
    [113] = 3600, -- Reraise
    [116] = 180, -- Phalanx
};

local knownSpellDurations = {
    [53] = 300,  -- Blink
    [54] = 300,  -- Stoneskin
    [55] = 600,  -- Aquaveil
    [57] = 300,  -- Haste
    [108] = 300, -- Regen
    [109] = 300, -- Refresh
    [135] = 3600, [136] = 3600, [137] = 3600, -- Reraise
    [136] = 300, -- Invisible
    [137] = 300, -- Sneak
    [138] = 300, -- Deodorize
};

local protectShellSpellLevels = {
    [43] = 7,  [44] = 27, [45] = 47, [46] = 63, [47] = 76, -- Protect
    [48] = 17, [49] = 37, [50] = 57, [51] = 68, [52] = 76, -- Shell
    [125] = 7,  [126] = 27, [127] = 47, [128] = 63, [129] = 76, -- Protectra
    [130] = 17, [131] = 37, [132] = 57, [133] = 68, [134] = 76, -- Shellra
};

local function SafeCall(fallback, fn)
    local ok, result = pcall(fn);

    if (ok ~= true or result == nil) then
        return fallback;
    end

    return result;
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

    return SafeCall(nil, function()
        return {
            target = struct.unpack('i4', e.data, 0x08 + 1),
            param = struct.unpack('i4', e.data, 0x0C + 1),
            message = bit.band(struct.unpack('i2', e.data, 0x18 + 1), 0x7FFF),
        };
    end);
end

local function IsPartyMember(serverId)
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

    for index = 0, 5 do
        local memberId = SafeCall(0, function()
            return party:GetMemberServerId(index);
        end);

        if ((tonumber(memberId) or 0) == serverId) then
            return true;
        end
    end

    return false;
end

local function GetPartyMemberLevel(serverId)
    serverId = tonumber(serverId) or 0;

    if (serverId == 0) then
        return nil;
    end

    local party = SafeCall(nil, function()
        return AshitaCore:GetMemoryManager():GetParty();
    end);

    if (party == nil) then
        return nil;
    end

    for index = 0, 5 do
        local memberId = SafeCall(0, function()
            return party:GetMemberServerId(index);
        end);

        if ((tonumber(memberId) or 0) == serverId) then
            return SafeCall(nil, function()
                if (party.GetMemberMainJobLevel ~= nil) then
                    return party:GetMemberMainJobLevel(index);
                end

                if (party.GetMemberMainLevel ~= nil) then
                    return party:GetMemberMainLevel(index);
                end

                if (party.GetMemberLevel ~= nil) then
                    return party:GetMemberLevel(index);
                end

                return nil;
            end);
        end
    end

    return nil;
end

local function GetResourceDuration(resource)
    if (resource == nil) then
        return nil;
    end

    for _, key in ipairs({ 'Duration', 'duration', 'BaseDuration', 'base_duration' }) do
        local value = tonumber(resource[key]);

        if (value ~= nil and value > 0) then
            return value;
        end
    end

    return nil;
end

local function GetProtectShellDuration(actionId, targetId)
    local spellLevel = tonumber(protectShellSpellLevels[tonumber(actionId) or 0]);

    if (spellLevel == nil or spellLevel <= 0) then
        return nil;
    end

    local targetLevel = tonumber(GetPartyMemberLevel(targetId));

    if (targetLevel == nil or targetLevel <= 0) then
        return 1800;
    end

    local ratio = targetLevel / spellLevel;

    if (ratio > 1) then
        ratio = 1;
    end

    return math.floor(math.max(1800 * ratio, 90));
end

local function GetDuration(packetType, actionId, statusId, targetId)
    actionId = tonumber(actionId) or 0;
    statusId = tonumber(statusId) or 0;

    if (packetType == 4) then
        local protectShellDuration = GetProtectShellDuration(actionId, targetId);

        if (protectShellDuration ~= nil) then
            return protectShellDuration;
        end

        local duration = knownSpellDurations[actionId];

        if (duration ~= nil) then
            return duration;
        end

        duration = SafeCall(nil, function()
            return GetResourceDuration(AshitaCore:GetResourceManager():GetSpellById(actionId));
        end);

        if (duration ~= nil) then
            return duration;
        end
    end

    return knownStatusDurations[statusId] or 300;
end

local function TrackTimer(serverId, statusId, duration)
    serverId = tonumber(serverId) or 0;
    statusId = tonumber(statusId) or 0;
    duration = tonumber(duration) or 0;

    if (serverId == 0 or statusId <= 0 or duration <= 0 or IsPartyMember(serverId) ~= true) then
        return;
    end

    trackedTimers[serverId] = trackedTimers[serverId] or {};
    trackedTimers[serverId][statusId] = os.clock() + duration;
end

local function ClearTimer(serverId, statusId)
    serverId = tonumber(serverId) or 0;
    statusId = tonumber(statusId) or 0;

    if (serverId == 0 or statusId <= 0 or trackedTimers[serverId] == nil) then
        return;
    end

    trackedTimers[serverId][statusId] = nil;
end

local function GetTrackedSeconds(serverId, statusId)
    serverId = tonumber(serverId) or 0;
    statusId = tonumber(statusId) or 0;

    if (serverId == 0 or statusId <= 0 or trackedTimers[serverId] == nil) then
        return nil;
    end

    local expiresAt = tonumber(trackedTimers[serverId][statusId]);

    if (expiresAt == nil) then
        return nil;
    end

    local seconds = expiresAt - os.clock();

    if (seconds <= 0) then
        trackedTimers[serverId][statusId] = nil;
        return nil;
    end

    return seconds;
end

local function CountTrackedTimers(serverId)
    serverId = tonumber(serverId) or 0;

    if (serverId == 0 or trackedTimers[serverId] == nil) then
        return 0;
    end

    local count = 0;

    for _, _ in pairs(trackedTimers[serverId]) do
        count = count + 1;
    end

    return count;
end

local function HandleActionPacket(packet)
    if (packet == nil) then
        return;
    end

    for _, target in ipairs(packet.Targets or {}) do
        for _, action in ipairs(target.Actions or {}) do
            local statusId = tonumber(action.Param);
            local message = tonumber(action.Message) or 0;

            if (statusOffMessages:contains(message)) then
                ClearTimer(target.Id, statusId);
            elseif (statusOnMessages:contains(message) and statusId ~= nil and statusId > 0) then
                TrackTimer(target.Id, statusId, GetDuration(packet.Type, packet.Param, statusId, target.Id));
            end
        end
    end
end

local function ClearMissingTimers()
    for serverId, timers in pairs(trackedTimers) do
        local statusIds = partyBuffs[serverId];

        if (statusIds == nil) then
            trackedTimers[serverId] = nil;
        else
            local active = {};

            for _, statusId in ipairs(statusIds) do
                statusId = tonumber(statusId);

                if (statusId ~= nil and statusId > 0 and statusId ~= 255) then
                    active[statusId] = true;
                end
            end

            for statusId, _ in pairs(timers) do
                if (active[statusId] ~= true) then
                    timers[statusId] = nil;
                end
            end
        end
    end
end

local function ReadMemberBuffsFromPointer(memberPtr)
    local buffs = {};
    local empty = false;

    for buffIndex = 0, 31 do
        if (empty == true) then
            buffs[buffIndex + 1] = -1;
        else
            local highBits = ashita.memory.read_uint8(memberPtr + 8 + math.floor(buffIndex / 4));
            local shift = math.fmod(buffIndex, 4) * 2;
            highBits = bit.lshift(bit.band(bit.rshift(highBits, shift), 0x03), 8);

            local lowBits = ashita.memory.read_uint8(memberPtr + 16 + buffIndex);
            local statusId = highBits + lowBits;

            if (statusId == 255) then
                empty = true;
                buffs[buffIndex + 1] = -1;
            else
                buffs[buffIndex + 1] = statusId;
            end
        end
    end

    return buffs;
end

local function ReadPartyBuffsFromMemory()
    local pointerAddress = SafeCall(0, function()
        return AshitaCore:GetPointerManager():Get('party.statusicons');
    end);

    pointerAddress = tonumber(pointerAddress) or 0;

    if (pointerAddress == 0) then
        return {};
    end

    local ptrPartyBuffs = SafeCall(0, function()
        return ashita.memory.read_uint32(pointerAddress);
    end);

    ptrPartyBuffs = tonumber(ptrPartyBuffs) or 0;

    if (ptrPartyBuffs == 0) then
        return {};
    end

    local results = {};

    for memberIndex = 0, 4 do
        local memberPtr = ptrPartyBuffs + (0x30 * memberIndex);
        local serverId = SafeCall(0, function()
            return ashita.memory.read_uint32(memberPtr);
        end);

        serverId = tonumber(serverId) or 0;

        if (serverId ~= 0) then
            results[serverId] = ReadMemberBuffsFromPointer(memberPtr);
        end
    end

    return results;
end

local function ReadPartyBuffsFromPacket(e)
    if (e == nil or e.data == nil or e.data_raw == nil or ashita.bits == nil) then
        return nil;
    end

    local results = {};

    for memberIndex = 0, 4 do
        local memberOffset = 0x04 + (0x30 * memberIndex) + 1;
        local serverId = SafeCall(0, function()
            return struct.unpack('L', e.data, memberOffset);
        end);

        serverId = tonumber(serverId) or 0;

        if (serverId ~= 0) then
            local buffs = {};
            local empty = false;

            for buffIndex = 0, 31 do
                if (empty == true) then
                    buffs[buffIndex + 1] = -1;
                else
                    local highBits = bit.lshift(ashita.bits.unpack_be(e.data_raw, memberOffset + 7, buffIndex * 2, 2), 8);
                    local lowBits = SafeCall(0, function()
                        return struct.unpack('B', e.data, memberOffset + 0x10 + buffIndex);
                    end);
                    local statusId = highBits + lowBits;

                    if (statusId == 255) then
                        empty = true;
                        buffs[buffIndex + 1] = -1;
                    else
                        buffs[buffIndex + 1] = statusId;
                    end
                end
            end

            results[serverId] = buffs;
        end
    end

    return results;
end

local function RefreshFromMemoryIfEmpty()
    if (next(partyBuffs) ~= nil) then
        return;
    end

    local now = os.clock();

    if ((now - lastMemoryRefresh) < 0.50) then
        return;
    end

    lastMemoryRefresh = now;
    partyBuffs = ReadPartyBuffsFromMemory();
end

function partyStatuses.HandlePacketIn(e)
    if (e == nil) then
        return;
    end

    if (e.id == 0x000A) then
        partyBuffs = {};
        trackedTimers = {};
    elseif (e.id == 0x0028) then
        HandleActionPacket(ParseActionPacket(e));
    elseif (e.id == 0x0029) then
        local message = ParseMessagePacket(e);

        if (message ~= nil) then
            if (deathMessages:contains(message.message)) then
                trackedTimers[message.target] = nil;
            elseif (statusOffMessages:contains(message.message)) then
                ClearTimer(message.target, message.param);
            end
        end
    elseif (e.id == 0x0076) then
        local packetBuffs = ReadPartyBuffsFromPacket(e);

        if (packetBuffs ~= nil) then
            partyBuffs = packetBuffs;
            ClearMissingTimers();
        end
    end
end

function partyStatuses.GetMemberRows(serverId, kind)
    serverId = tonumber(serverId) or 0;

    if (serverId == 0) then
        return {};
    end

    RefreshFromMemoryIfEmpty();

    local statusIds = partyBuffs[serverId];
    local rows = {};

    if (statusIds == nil) then
        return rows;
    end

    for index = 1, 32 do
        local statusId = tonumber(statusIds[index]);

        if (
            statusId ~= nil and
            statusId > 0 and
            statusId ~= 255 and
            levelSyncStatusIds[statusId] ~= true and
            (
                (kind == 'buff' and statusEffects.IsBuff(statusId) == true) or
                (kind == 'debuff' and statusEffects.IsDebuff(statusId) == true) or
                (kind ~= 'buff' and kind ~= 'debuff')
            )
        ) then
            rows[#rows + 1] = {
                id = statusId,
                order = index,
                seconds = GetTrackedSeconds(serverId, statusId),
            };
        end
    end

    table.sort(rows, function(a, b)
        local aSeconds = tonumber(a.seconds);
        local bSeconds = tonumber(b.seconds);
        local aHasTimer = aSeconds ~= nil and aSeconds >= 0;
        local bHasTimer = bSeconds ~= nil and bSeconds >= 0;

        if (aHasTimer ~= bHasTimer) then
            return aHasTimer == true;
        end

        if (aHasTimer == true and bHasTimer == true and aSeconds ~= bSeconds) then
            return aSeconds < bSeconds;
        end

        return (tonumber(a.order) or 0) < (tonumber(b.order) or 0);
    end);

    return rows;
end

function partyStatuses.HasLevelSyncStatus(serverId)
    serverId = tonumber(serverId) or 0;

    if (serverId == 0) then
        return false;
    end

    RefreshFromMemoryIfEmpty();

    local statusIds = partyBuffs[serverId];

    if (statusIds == nil) then
        return false;
    end

    local startIndex = statusIds[0] ~= nil and 0 or 1;

    for offset = 0, 31 do
        local index = startIndex + offset;
        local statusId = tonumber(statusIds[index]);

        if (statusId ~= nil and levelSyncStatusIds[statusId] == true) then
            return true;
        end
    end

    return false;
end

function partyStatuses.GetDebugText(serverId)
    serverId = tonumber(serverId) or 0;
    RefreshFromMemoryIfEmpty();

    local statusIds = partyBuffs[serverId];

    if (statusIds == nil) then
        return 'partyRaw=0 partyIds=none';
    end

    local raw = {};
    local rawCount = 0;

    for index = 1, 32 do
        local statusId = tonumber(statusIds[index]);

        if (statusId ~= nil and statusId > 0 and statusId ~= 255) then
            rawCount = rawCount + 1;

            if (#raw < 8) then
                raw[#raw + 1] = tostring(statusId);
            end
        end
    end

    return 'partyRaw=' .. tostring(rawCount) ..
        ' partyIds=' .. (#raw > 0 and table.concat(raw, '/') or 'none') ..
        ' partyBuffs=' .. tostring(#partyStatuses.GetMemberRows(serverId, 'buff')) ..
        ' partyDebuffs=' .. tostring(#partyStatuses.GetMemberRows(serverId, 'debuff')) ..
        ' partyTimers=' .. tostring(CountTrackedTimers(serverId));
end

return partyStatuses;
