local abilityRecast = {};
local pointer = nil;

local function InitPointer()
    if (pointer ~= nil) then
        return true;
    end

    local found = ashita.memory.find('FFXiMain.dll', 0, '894124E9????????8B46??6A006A00508BCEE8', 0x19, 0);

    if (found == 0) then
        return false;
    end

    local ptr = ashita.memory.read_uint32(found);

    if (ptr == 0) then
        return false;
    end

    pointer = ptr;
    return true;
end

function abilityRecast.GetAbilityTimerByTimerId(timerId)
    timerId = tonumber(timerId);

    if (timerId == nil or InitPointer() ~= true) then
        return 0;
    end

    for i = 1, 31 do
        local compId = ashita.memory.read_uint8(pointer + (i * 8) + 3);

        if (compId == timerId) then
            return ashita.memory.read_uint32(pointer + (i * 4) + 0xF8);
        end
    end

    return 0;
end

function abilityRecast.GetAbilityTimerDataByTimerId(timerId)
    timerId = tonumber(timerId);

    if (timerId == nil or InitPointer() ~= true) then
        return { Modifier = 0, Recast = 0 };
    end

    for i = 1, 31 do
        local compId = ashita.memory.read_uint8(pointer + (i * 8) + 3);

        if (compId == timerId) then
            return {
                Modifier = ashita.memory.read_int16(pointer + (i * 8) + 4),
                Recast = ashita.memory.read_uint32(pointer + (i * 4) + 0xF8),
            };
        end
    end

    return { Modifier = 0, Recast = 0 };
end

function abilityRecast.FindAbilityRecast(abilityId)
    abilityId = tonumber(abilityId);

    if (abilityId == nil or InitPointer() ~= true) then
        return nil, 0;
    end

    local resourceManager = AshitaCore:GetResourceManager();

    if (resourceManager == nil or resourceManager.GetAbilityByTimerId == nil) then
        return nil, 0;
    end

    for i = 0, 31 do
        local timerId = ashita.memory.read_uint8(pointer + (i * 8) + 3);

        if (timerId > 0 or i == 0) then
            local ability = resourceManager:GetAbilityByTimerId(timerId);

            if (ability ~= nil and tonumber(ability.Id) == abilityId) then
                return timerId, ashita.memory.read_uint32(pointer + (i * 4) + 0xF8);
            end
        end
    end

    return nil, 0;
end

function abilityRecast.GetAbilityTimerByAbilityId(abilityId)
    local _, recast = abilityRecast.FindAbilityRecast(abilityId);
    return tonumber(recast) or 0;
end

function abilityRecast.GetDebugText()
    if (InitPointer() ~= true) then
        return 'ability recast pointer not found';
    end

    local resourceManager = AshitaCore:GetResourceManager();
    local parts = {};

    for i = 0, 31 do
        local timerId = ashita.memory.read_uint8(pointer + (i * 8) + 3);
        local recast = ashita.memory.read_uint32(pointer + (i * 4) + 0xF8);

        if (timerId > 0 or recast > 0) then
            local abilityName = '';

            if (resourceManager ~= nil and resourceManager.GetAbilityByTimerId ~= nil) then
                local ability = resourceManager:GetAbilityByTimerId(timerId);

                if (ability ~= nil) then
                    abilityName = tostring(ability.Name and ability.Name[1] or ability.Name or ability.Id or '');
                end
            end

            parts[#parts + 1] = string.format('[slot=%s timer=%s recast=%s ability=%s]', tostring(i), tostring(timerId), tostring(recast), abilityName);
        end
    end

    if (#parts == 0) then
        return 'ability recast slots empty';
    end

    return table.concat(parts, ' ');
end

return abilityRecast;
