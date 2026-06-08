local ffi = require('ffi');

local enemyCasts = {};
local casts = {};

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

    if (actionPacket.Type == 8) then
        if (
            actionPacket.Targets == nil or
            actionPacket.Targets[1] == nil or
            actionPacket.Targets[1].Actions == nil or
            actionPacket.Targets[1].Actions[1] == nil
        ) then
            return;
        end

        local action = actionPacket.Targets[1].Actions[1];
        local spellId, spell = ResolveSpell({
            action.Param,
            actionPacket.Param,
        });

        if (spellId == 0 or spell == nil) then
            return;
        end

        casts[actionPacket.UserId] = {
            spellId = spellId,
            spellName = GetSpellNameByResource(spell, spellId),
            startTime = os.clock(),
            castTime = GetSpellCastTimeByResource(spell),
        };

        return;
    end

    if (actionPacket.Type == 4 or actionPacket.Type == 11) then
        casts[actionPacket.UserId] = nil;
    end
end

function enemyCasts.HandlePacketIn(e)
    if (e == nil) then
        return;
    end

    if (e.id == 0x000A) then
        casts = {};
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

    if ((os.clock() - castData.startTime) >= castData.castTime) then
        casts[serverId] = nil;
        return nil;
    end

    return castData;
end

return enemyCasts;
