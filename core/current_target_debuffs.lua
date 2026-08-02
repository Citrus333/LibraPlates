require('common');

local statusEffects = require('core.status_effects');

local currentTargetDebuffs = {};
local tracked = {};

local statusOnMessages = T{144, 160, 164, 166, 186, 194, 203, 205, 230, 236, 266, 267, 268, 269, 237, 271, 272, 277, 278, 279, 280, 319, 320, 375, 412, 645, 754, 755, 804};
local statusOffMessages = T{206, 64, 159, 168, 204, 321, 322, 341, 342, 343, 344, 350, 378, 531, 647, 805, 806};
local deathMessages = T{6, 20, 97, 113, 406, 605, 646};
local spellDamageMessages = T{2, 252, 264, 265};

local LUNAR_CRY_BP_ID = 530;
local LUNAR_CRY_EFFECT_A = 146;
local LUNAR_CRY_EFFECT_B = 148;
local LUNAR_CRY_DURATION = 60;

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

local function GetDuration(spellId)
    spellId = tonumber(spellId) or 0;

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

    return 300;
end

local function Track(serverId, statusId, duration)
    serverId = tonumber(serverId) or 0;
    statusId = tonumber(statusId) or 0;

    if (serverId == 0 or statusId <= 0) then
        return;
    end

    tracked[serverId] = tracked[serverId] or {};
    tracked[serverId][statusId] = os.time() + (tonumber(duration) or 300);
end

local function Clear(serverId, statusId)
    serverId = tonumber(serverId) or 0;
    statusId = tonumber(statusId) or 0;

    if (serverId == 0 or statusId <= 0 or tracked[serverId] == nil) then
        return;
    end

    tracked[serverId][statusId] = nil;
end

local function HandleActionPacket(packet)
    if (packet == nil) then
        return;
    end

    local spellId = tonumber(packet.Param) or 0;

    for _, target in ipairs(packet.Targets or {}) do
        for _, action in ipairs(target.Actions or {}) do
            local message = tonumber(action.Message) or 0;

            if (packet.Type == 13 and spellId == LUNAR_CRY_BP_ID) then
                Track(target.Id, LUNAR_CRY_EFFECT_A, LUNAR_CRY_DURATION);
                Track(target.Id, LUNAR_CRY_EFFECT_B, LUNAR_CRY_DURATION);
            end

            if (statusOffMessages:contains(message)) then
                Clear(target.Id, action.Param);
            elseif (packet.Type == 4 and spellDamageMessages:contains(message)) then
                if (spellId == 23 or spellId == 24 or spellId == 25 or spellId == 33) then
                    Track(target.Id, 134, spellId == 24 and 120 or spellId == 25 and 150 or 60);
                    Clear(target.Id, 135);
                elseif (spellId == 230 or spellId == 231 or spellId == 232) then
                    Track(target.Id, 135, spellId == 231 and 120 or spellId == 232 and 150 or 60);
                    Clear(target.Id, 134);
                end
            elseif (statusOnMessages:contains(message)) then
                local statusId = tonumber(action.Param) or statusEffects.GetDebuffIdBySpellId(spellId);
                Track(target.Id, statusId, GetDuration(spellId));
            end
        end
    end
end

function currentTargetDebuffs.HandlePacketIn(e)
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

        if (deathMessages:contains(message.message)) then
            tracked[message.target] = nil;
        elseif (statusOffMessages:contains(message.message)) then
            Clear(message.target, message.param);
        end
    end
end

function currentTargetDebuffs.GetRows(serverId)
    serverId = tonumber(serverId) or 0;

    if (serverId == 0 or tracked[serverId] == nil) then
        return {};
    end

    local now = os.time();
    local rows = {};

    for statusId, expiresAt in pairs(tracked[serverId]) do
        local seconds = (tonumber(expiresAt) or 0) - now;
        if (seconds > 0) then
            rows[#rows + 1] = {
                id = statusId,
                seconds = seconds,
            };
        else
            tracked[serverId][statusId] = nil;
        end
    end

    table.sort(rows, function(a, b)
        return (tonumber(a.seconds) or 0) < (tonumber(b.seconds) or 0);
    end);

    return rows;
end

return currentTargetDebuffs;
