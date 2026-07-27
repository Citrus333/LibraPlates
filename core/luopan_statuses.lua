require('common');

local entities = require('core.entities');
local log = require('core.log');

local luopanStatuses = {};
local activeStatuses = {};
local nextOrder = 1;
local probeUntil = nil;
local activeLuopanServerId = nil;

local abilityStatuses = {
    [346] = { statusId = 515 }, -- Lasting Emanation
    [347] = { statusId = 516 }, -- Ecliptic Attrition
    [350] = { statusId = 569 }, -- Blaze of Glory
    [351] = { statusId = 518, duration = 60 }, -- Dematerialize
};
local statusAbilityIds = {
    [515] = 346,
    [516] = 347,
    [569] = 350,
    [518] = 351,
};

local function SafeCall(fallback, fn)
    local ok, result = pcall(fn);

    if (ok ~= true or result == nil) then
        return fallback;
    end

    return result;
end

local function GetSelfServerId()
    return tonumber(SafeCall(0, function()
        return AshitaCore:GetMemoryManager():GetParty():GetMemberServerId(0);
    end)) or 0;
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

local function IsProbeEnabled()
    return tonumber(probeUntil) ~= nil and os.clock() < tonumber(probeUntil);
end

local function SyncCurrentLuopan()
    local luopan = entities.GetOwnLuopan();
    local luopanServerId = luopan ~= nil and tonumber(luopan.serverId) or nil;

    if (luopanServerId == nil or luopanServerId == 0) then
        activeStatuses = {};
        activeLuopanServerId = nil;
        return nil;
    end

    if (activeLuopanServerId ~= nil and activeLuopanServerId ~= luopanServerId) then
        activeStatuses = {};
    end

    activeLuopanServerId = luopanServerId;
    return luopanServerId;
end

local function TrackStatus(statusId, duration, luopanServerId)
    statusId = tonumber(statusId) or 0;
    duration = tonumber(duration);
    luopanServerId = tonumber(luopanServerId) or SyncCurrentLuopan();

    if (statusId <= 0 or luopanServerId == nil or luopanServerId == 0) then
        return;
    end

    activeLuopanServerId = luopanServerId;

    if (activeStatuses[statusId] == nil) then
        activeStatuses[statusId] = {
            order = nextOrder,
            expiresAt = duration ~= nil and (os.clock() + duration) or nil,
        };
        nextOrder = nextOrder + 1;
    else
        activeStatuses[statusId].expiresAt = duration ~= nil and (os.clock() + duration) or nil;
    end

    if (IsProbeEnabled() == true) then
        log.Info('Luopan tracked status=' .. tostring(statusId) .. ' duration=' .. tostring(duration or 'luopan'));
    end
end

local function FormatActions(target)
    local parts = {};

    for actionIndex, action in ipairs(target.Actions or {}) do
        parts[#parts + 1] =
            '#' .. tostring(actionIndex) ..
            ':param=' .. tostring(action.Param) ..
            ',msg=' .. tostring(action.Message) ..
            ',react=' .. tostring(action.Reaction) ..
            ',anim=' .. tostring(action.Animation) ..
            ',flags=' .. tostring(action.Flags);
    end

    if (#parts == 0) then
        return '-';
    end

    return table.concat(parts, ';');
end

local function ProbeActionPacket(packet, ability, luopanServerId, matchedLuopan)
    if (IsProbeEnabled() ~= true or packet == nil) then
        return;
    end

    local shouldLog = ability ~= nil;

    if (shouldLog ~= true) then
        for _, target in ipairs(packet.Targets or {}) do
            for _, action in ipairs(target.Actions or {}) do
                if (statusAbilityIds[tonumber(action.Param) or 0] ~= nil) then
                    shouldLog = true;
                    break;
                end
            end
            if (shouldLog == true) then
                break;
            end
        end
    end

    if (shouldLog ~= true) then
        return;
    end

    local targetParts = {};

    for targetIndex, target in ipairs(packet.Targets or {}) do
        targetParts[#targetParts + 1] =
            '#' .. tostring(targetIndex) ..
            ':id=' .. tostring(target.Id) ..
            ',actions=' .. FormatActions(target);
    end

    log.Info(
        'Luopan probe packet user=' .. tostring(packet.UserId) ..
        ' type=' .. tostring(packet.Type) ..
        ' param=' .. tostring(packet.Param) ..
        ' mappedStatus=' .. tostring(ability ~= nil and ability.statusId or nil) ..
        ' luopanServer=' .. tostring(luopanServerId) ..
        ' matchedLuopan=' .. tostring(matchedLuopan) ..
        ' targets=' .. table.concat(targetParts, ' | ')
    );
end

local function HandleActionPacket(packet)
    if (packet == nil) then
        return;
    end

    local ability = abilityStatuses[tonumber(packet.Param) or 0];

    local selfServerId = GetSelfServerId();

    if (selfServerId ~= 0 and tonumber(packet.UserId) ~= selfServerId) then
        return;
    end

    local luopanServerId = SyncCurrentLuopan() or 0;
    local matchedLuopan = luopanServerId == 0;

    for _, target in ipairs(packet.Targets or {}) do
        if (luopanServerId ~= 0 and tonumber(target.Id) == luopanServerId) then
            matchedLuopan = true;
            break;
        end
    end

    ProbeActionPacket(packet, ability, luopanServerId, matchedLuopan);

    if (ability ~= nil and matchedLuopan == true) then
        TrackStatus(ability.statusId, ability.duration, luopanServerId);
    end
end

function luopanStatuses.HandlePacketIn(e)
    if (e == nil) then
        return;
    end

    if (e.id == 0x000A) then
        activeStatuses = {};
        activeLuopanServerId = nil;
    elseif (e.id == 0x0028) then
        HandleActionPacket(ParseActionPacket(e));
    end
end

function luopanStatuses.GetRows(kind)
    if (kind ~= nil and kind ~= 'buff') then
        return {};
    end

    local rows = {};
    local now = os.clock();
    SyncCurrentLuopan();

    for statusId, data in pairs(activeStatuses) do
        local expiresAt = tonumber(data.expiresAt) or 0;

        if (tonumber(data.expiresAt) ~= nil and expiresAt <= now) then
            activeStatuses[statusId] = nil;
        else
            rows[#rows + 1] = {
                id = statusId,
                order = tonumber(data.order) or 0,
                seconds = tonumber(data.expiresAt) ~= nil and (expiresAt - now) or nil,
            };
        end
    end

    table.sort(rows, function(a, b)
        return (tonumber(a.order) or 0) < (tonumber(b.order) or 0);
    end);

    return rows;
end

function luopanStatuses.Reset()
    activeStatuses = {};
    activeLuopanServerId = nil;
end

function luopanStatuses.EnableProbe(seconds)
    seconds = math.max(1, math.min(600, tonumber(seconds) or 120));
    probeUntil = os.clock() + seconds;
    log.Info('Luopan probe on for ' .. tostring(seconds) .. ' seconds.');
end

function luopanStatuses.DisableProbe()
    probeUntil = nil;
    log.Info('Luopan probe off.');
end

function luopanStatuses.GetProbeStatusText()
    local remaining = 0;
    local rows = luopanStatuses.GetRows('buff');
    local rowParts = {};

    if (tonumber(probeUntil) ~= nil) then
        remaining = math.max(0, tonumber(probeUntil) - os.clock());
    end

    for _, row in ipairs(rows) do
        rowParts[#rowParts + 1] = tostring(row.id) .. ':' .. (tonumber(row.seconds) ~= nil and string.format('%.1f', tonumber(row.seconds) or 0) or 'luopan');
    end

    return 'Luopan probe enabled=' .. tostring(IsProbeEnabled()) .. ' remaining=' .. string.format('%.1f', remaining) .. ' luopanServer=' .. tostring(activeLuopanServerId) .. ' active=' .. (#rowParts > 0 and table.concat(rowParts, '/') or 'none');
end

return luopanStatuses;
