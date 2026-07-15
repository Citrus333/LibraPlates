require('common');

local statusEffects = require('core.status_effects');
local actionRelevance = require('core.action_relevance');

local trustStatusIcons = {};
local activeStatuses = {};
local nextOrder = 1;

local statusOnMessages = T{ 100, 144, 160, 164, 166, 186, 194, 203, 205, 230, 236, 266, 267, 268, 269, 271, 272, 277, 278, 279, 280, 319, 320, 375, 412, 420, 421, 424, 425, 645, 754, 755, 804 };
local statusOffMessages = T{ 64, 159, 168, 204, 206, 321, 322, 341, 342, 343, 344, 350, 378, 531, 647, 805, 806 };
local deathMessages = T{ 6, 20, 97, 113, 406, 605, 646 };
local spellDamageMessages = T{ 2, 252, 264, 265 };
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

local function GetSpellName(spellId)
    spellId = tonumber(spellId) or 0;

    if (spellId <= 0) then
        return nil;
    end

    return SafeCall(nil, function()
        local spell = AshitaCore:GetResourceManager():GetSpellById(spellId);

        if (spell == nil) then
            return nil;
        end

        if (type(spell.Name) == 'table') then
            return spell.Name[1] or spell.Name[0] or spell.Name.en or spell.Name.English;
        end

        return spell.Name or spell.NameSingle;
    end);
end

local function GetStatusIdBySpellId(spellId)
    spellId = tonumber(spellId) or 0;

    if (spellToBuff[spellId] ~= nil) then
        return spellToBuff[spellId];
    end

    local debuffId = statusEffects.GetDebuffIdBySpellId(spellId);

    if (debuffId ~= nil) then
        return debuffId;
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

local function GetTrustStatusDuration(statusId, spellId)
    spellId = tonumber(spellId) or 0;

    if (spellId == 23 or spellId == 33 or spellId == 230) then
        return 60;
    elseif (spellId == 24 or spellId == 231) then
        return 120;
    elseif (spellId == 25 or spellId == 232) then
        return 150;
    elseif (spellId >= 220 and spellId <= 229) then
        return 120;
    elseif (spellId >= 235 and spellId <= 240) then
        return 120;
    end

    return statusDurations[tonumber(statusId) or 0] or 300;
end

local function TrackStatus(serverId, statusId, duration)
    serverId = tonumber(serverId) or 0;
    statusId = tonumber(statusId) or 0;
    duration = tonumber(duration) or GetTrustStatusDuration(statusId);

    if (serverId == 0 or statusId <= 0 or actionRelevance.IsPartyOrAllianceServerId(serverId) ~= true) then
        return;
    end

    if (statusEffects.IsBuff(statusId) ~= true and statusEffects.IsDebuff(statusId) ~= true) then
        return;
    end

    activeStatuses[serverId] = activeStatuses[serverId] or {};

    if (activeStatuses[serverId][statusId] == nil) then
        activeStatuses[serverId][statusId] = {
            order = nextOrder,
            seenAt = os.clock(),
            expiresAt = os.clock() + duration,
        };
        nextOrder = nextOrder + 1;
    else
        activeStatuses[serverId][statusId].seenAt = os.clock();
        activeStatuses[serverId][statusId].expiresAt = os.clock() + duration;
    end
end

local function ClearStatus(serverId, statusId)
    serverId = tonumber(serverId) or 0;
    statusId = tonumber(statusId) or 0;

    if (serverId == 0 or statusId <= 0 or actionRelevance.IsPartyOrAllianceServerId(serverId) ~= true or activeStatuses[serverId] == nil) then
        return;
    end

    activeStatuses[serverId][statusId] = nil;
end

local function HandleActionPacket(packet)
    if (packet == nil) then
        return;
    end

    if (actionRelevance.ShouldIgnoreOutsideFriendlyCaster(packet) == true) then
        return;
    end

    for _, target in ipairs(packet.Targets or {}) do
        for _, action in ipairs(target.Actions or {}) do
            local spellId = tonumber(packet.Param) or 0;
            local statusId = (tonumber(packet.Type) == 4) and GetStatusIdBySpellId(spellId) or tonumber(action.Param);
            local message = tonumber(action.Message) or 0;

            if (statusOffMessages:contains(message)) then
                ClearStatus(target.Id, statusId);
            elseif (tonumber(packet.Type) == 4 and spellDamageMessages:contains(message) and (statusId == 134 or statusId == 135)) then
                -- Dia and Bio report their initial damage rather than a normal
                -- status-on message. They overwrite one another in game.
                ClearStatus(target.Id, statusId == 134 and 135 or 134);
                TrackStatus(target.Id, statusId, GetTrustStatusDuration(statusId, spellId));
            elseif (statusOnMessages:contains(message)) then
                TrackStatus(target.Id, statusId, GetTrustStatusDuration(statusId, spellId));
            end
        end
    end
end

function trustStatusIcons.HandlePacketIn(e)
    if (e == nil) then
        return;
    end

    if (e.id == 0x000A) then
        activeStatuses = {};
    elseif (e.id == 0x0028) then
        HandleActionPacket(ParseActionPacket(e));
    elseif (e.id == 0x0029) then
        local message = ParseMessagePacket(e);

        if (message ~= nil) then
            if (actionRelevance.IsPartyOrAllianceServerId(message.target) ~= true) then
                return;
            end

            if (deathMessages:contains(message.message)) then
                activeStatuses[tonumber(message.target) or 0] = nil;
            elseif (statusOffMessages:contains(message.message)) then
                ClearStatus(message.target, message.param);
            end
        end
    end
end

function trustStatusIcons.GetRows(serverId, kind)
    serverId = tonumber(serverId) or 0;

    if (serverId == 0 or activeStatuses[serverId] == nil) then
        return {};
    end

    local rows = {};
    local now = os.clock();

    for statusId, data in pairs(activeStatuses[serverId]) do
        if (tonumber(data.expiresAt) ~= nil and tonumber(data.expiresAt) <= now) then
            activeStatuses[serverId][statusId] = nil;
        elseif (
            (kind == 'buff' and statusEffects.IsBuff(statusId) == true) or
            (kind == 'debuff' and statusEffects.IsDebuff(statusId) == true) or
            (kind ~= 'buff' and kind ~= 'debuff')
        ) then
            rows[#rows + 1] = {
                id = statusId,
                order = tonumber(data.order) or 0,
            };
        end
    end

    table.sort(rows, function(a, b)
        return (tonumber(a.order) or 0) < (tonumber(b.order) or 0);
    end);

    return rows;
end

return trustStatusIcons;
