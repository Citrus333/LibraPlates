local targetActionRange = {};
local log = require('core.log');
local petCommands = require('data.pet_commands');
local resourceCache = {};
local lastAction = nil;
local recentAction = nil;
local lastQueuedPacketSignature = nil;
local lastQueuedPacketAt = 0;
local actionCacheSeconds = nil;
local debugUntil = nil;
local commandOverrideWindowSeconds = 1.0;
local queuedPacketDedupeSeconds = 2.5;
local commandDedupeWindowSeconds = 0.35;
local lastCommandQueuedAt = nil;
local lastCommandQueuedSignature = nil;
local debugPacketOutEnabled = false;
local lastCastCommandSignature = nil;
local lastCastCommandSeenAt = -1;
local petCommandCategory = 18;

local trackedCategories = {
    [2] = true,   -- Ability queue variants used by this client packet path
    [3] = true,  -- Spell
    [7] = true,  -- Weaponskill
    [9] = true,  -- Ability
    [16] = true, -- Ranged
    [18] = true, -- Pet command
};
local debugEnabled = false;
local actionPacketIds = {
    [0x01A] = true,
    [0x015] = true,
    [0x061] = true,
    [0x0C0] = true,
    [0x1A2] = true,
};
local function GetPacketData(e)
    return (e ~= nil) and (e.data_modified or e.data or e.data_raw) or nil;
end
local function GetPacketSize(e)
    return (tonumber(e.size) or 0);
end
local ScanActionCandidates;
local lastPacketOutLogAt = {
    ['0x1a'] = -1,
    ['0x61'] = -1,
    ['0xc0'] = -1,
};
local packetLogCooldown = 1.0;
local actionCommandNameCache = {};
local lastQueuedActionName = nil;
local lastQueuedActionSource = nil;
local categoryNames = {
    [2] = 'ability',
    [3] = 'spell',
    [7] = 'weaponskill',
    [9] = 'ability',
    [16] = 'ranged',
    [18] = 'petcommand',
};

local resourceMethodCandidates = {
    [2] = { 'GetAbilityById', 'GetAbilityByTimerId', 'GetSpellById', 'GetWeaponSkillById' }, -- alternate JA/action packet categories
    [3] = { 'GetSpellById', 'GetAbilityById' },
    [7] = { 'GetWeaponSkillById', 'GetMobSkillById' },
    [9] = { 'GetAbilityById', 'GetAbilityByTimerId', 'GetSpellById' }, -- JA
    [16] = { 'GetAbilityById', 'GetMobSkillById', 'GetSpellById' },
};
local strictResourceMethodCandidates = {
    [2] = { 'GetAbilityById', 'GetAbilityByTimerId', 'GetWeaponSkillById' },
    [3] = { 'GetSpellById', 'GetAbilityById' },
    [7] = { 'GetWeaponSkillById', 'GetMobSkillById' },
    [9] = { 'GetAbilityById', 'GetAbilityByTimerId', 'GetSpellById' },
    [16] = { 'GetAbilityById', 'GetMobSkillById', 'GetSpellById' },
};
local strictResourceMethodCandidatesNoTimer = {
    [2] = { 'GetAbilityById', 'GetSpellById' },
    [3] = { 'GetSpellById', 'GetAbilityById' },
    [7] = { 'GetWeaponSkillById', 'GetMobSkillById' },
    [9] = { 'GetAbilityById', 'GetSpellById' },
    [16] = { 'GetAbilityById', 'GetMobSkillById', 'GetSpellById' },
};

local function BuildActionCandidateIds(category, actionId)
    local candidates = {};
    local seen = {};

    local function add(value)
        local id = tonumber(value);

        if (id == nil or id <= 0 or id > 0xFFFF) then
            return;
        end

        if (seen[id] == true) then
            return;
        end

        seen[id] = true;
        candidates[#candidates + 1] = id;
    end

    add(actionId);
    add(actionId + 0x100);
    add(actionId + 0x200);
    add(actionId + 0x1000);
    add(actionId - 0x100);
    add(actionId - 0x200);
    add(actionId - 0x1000);

    if (category == 2 or category == 9) then
        add(actionId + 0x2000);
        add(actionId - 0x2000);
    end

    return candidates;
end

local function IsDebugEnabled()
    if (debugEnabled == true) then
        return true;
    end

    if (debugUntil == nil) then
        return false;
    end

    return tonumber(debugUntil) ~= nil and os.clock() < tonumber(debugUntil);
end

local function IsPacketDebugEnabled()
    return debugPacketOutEnabled == true and IsDebugEnabled() == true;
end

local function DebugLog(message)
    if (IsDebugEnabled() ~= true) then
        return;
    end

    log.Info(message);
end

local function NormalizeCommandText(commandText)
    return tostring(commandText or '')
        :lower()
        :gsub('^%s*%/?', '')
        :gsub('%s+$', '')
        :gsub('%s+', ' ');
end

local function IsLikelyDuplicateCommand(commandText)
    local normalized = NormalizeCommandText(commandText);
    local now = os.clock();

    if (lastCastCommandSignature == nil or lastCastCommandSignature ~= normalized) then
        lastCastCommandSignature = normalized;
        lastCastCommandSeenAt = now;
        return false;
    end

    if ((now - (lastCastCommandSeenAt or 0)) <= commandDedupeWindowSeconds) then
        return true;
    end

    lastCastCommandSeenAt = now;
    return false;
end

local function SafeCall(fallback, fn)
    local ok, result = pcall(fn);

    if (ok ~= true or result == nil) then
        return fallback;
    end

    return result;
end

local function ResolveResourceByMethod(resourceManager, methodName, resourceId)
    if (resourceManager == nil or resourceId == nil or methodName == nil) then
        return nil;
    end

    local id = tonumber(resourceId);
    if (id == nil or id <= 0) then
        return nil;
    end

    local method = nil;
    if (methodName == 'GetAbilityById' and type(resourceManager.GetAbilityById) == 'function') then
        method = resourceManager.GetAbilityById;
    elseif (methodName == 'GetAbilityByTimerId' and type(resourceManager.GetAbilityByTimerId) == 'function') then
        method = resourceManager.GetAbilityByTimerId;
    elseif (methodName == 'GetSpellById' and type(resourceManager.GetSpellById) == 'function') then
        method = resourceManager.GetSpellById;
    elseif (methodName == 'GetWeaponSkillById' and type(resourceManager.GetWeaponSkillById) == 'function') then
        method = resourceManager.GetWeaponSkillById;
    elseif (methodName == 'GetMobSkillById' and type(resourceManager.GetMobSkillById) == 'function') then
        method = resourceManager.GetMobSkillById;
    end

    if (type(method) ~= 'function') then
        return nil;
    end

    return SafeCall(nil, function()
        return method(resourceManager, id);
    end);
end

local function FormatWordPairs(data, offsets)
    if (data == nil or type(offsets) ~= 'table') then
        return '';
    end

    local function ReadWordLocal(raw, offset, littleEndian)
        if (raw == nil or offset == nil) then
            return nil;
        end

        local i = tonumber(offset) + 1;
        local b1 = string.byte(raw, i, i + 1);

        if (b1 == nil) then
            return nil;
        end

        local second = string.byte(raw, i + 1);

        if (second == nil) then
            return nil;
        end

        if (littleEndian ~= false) then
            return b1 + (second * 256);
        end

        return (b1 * 256) + second;
    end

    local parts = {};

    for _, offset in ipairs(offsets) do
        if (offset ~= nil) then

            local leCategory = ReadWordLocal(data, offset, true);
            local leAction = ReadWordLocal(data, offset + 2, true);
            local beCategory = ReadWordLocal(data, offset, false);
            local beAction = ReadWordLocal(data, offset + 2, false);

            if (
                leCategory ~= nil or leAction ~= nil or
                beCategory ~= nil or beAction ~= nil
            ) then
                parts[#parts + 1] = string.format(
                    'off=%x le=%s/%s be=%s/%s',
                    tonumber(offset) or 0,
                    tostring(leCategory or '-'),
                    tostring(leAction or '-'),
                    tostring(beCategory or '-'),
                    tostring(beAction or '-')
                );
            end
        end
    end

    return table.concat(parts, ' | ');
end

local function NormalizeActionName(value)
    if (value == nil) then
        return nil;
    end

    local text = tostring(value):lower();
    text = text:gsub('[%p%s]', ' ');
    text = text:gsub('%s+', ' ');
    text = text:gsub('^%s+', '');
    text = text:gsub('%s+$', '');

    if (text == '' or text == '.') then
        return nil;
    end

    return text;
end

local ReadRecordDisplayName = nil;
local NormalizeActionDisplayName = nil;

local function ResolveActionIdByNameSlow(category, normalizedActionName)
    local function GetResourceManagerSafe()
        local accessor = GetResourceManager;
        local manager = nil;

        if (type(accessor) == 'function') then
            manager = SafeCall(nil, function()
                return accessor();
            end);
        end

        if (manager == nil) then
            manager = SafeCall(nil, function()
                return AshitaCore:GetResourceManager();
            end);
        end

        if (
            manager == nil or
            (type(manager) ~= 'table' and type(manager) ~= 'userdata')
        ) then
            return nil;
        end

        return manager;
    end

    local resourceManager = GetResourceManagerSafe();
    if (resourceManager == nil) then
        return nil, nil;
    end

    local methodCandidates = {
        [2] = { 'GetAbilityById', 'GetSpellById', 'GetAbilityByTimerId' },
        [3] = { 'GetSpellById', 'GetAbilityById', 'GetAbilityByTimerId' },
        [7] = { 'GetWeaponSkillById', 'GetAbilityById' },
        [9] = { 'GetAbilityById', 'GetAbilityByTimerId', 'GetSpellById' },
        [16] = { 'GetAbilityById', 'GetAbilityByTimerId', 'GetSpellById' },
    };
    local scanLimits = {
        [2] = 4096,
        [3] = 4096,
        [7] = 2048,
        [9] = 4096,
        [16] = 4096,
    };

    local methods = methodCandidates[tonumber(category)] or {};
    local limit = scanLimits[tonumber(category)] or 2048;

    for id = 1, limit do
        for _, methodName in ipairs(methods) do
            local record = ResolveResourceByMethod(resourceManager, methodName, id);
            if (record ~= nil) then
                local readName = SafeCall(nil, function()
                    return NormalizeActionDisplayName(record);
                end);
                if (type(readName) == 'string' and readName == normalizedActionName) then
                    return id, methodName;
                end
            end
        end
    end

    return nil, nil;
end
local function ParseActionCommand(commandText)
    local text = tostring(commandText or '');
    local lowered = text:lower():gsub('^%s*', ''):gsub('%s+$', '');
    local withoutSlash = lowered:gsub('^/', '', 1);
    local commandName, rest = withoutSlash:match('^(%S+)%s*(.-)$');

    if (commandName == nil) then
        return nil, nil;
    end

    local command = commandName:lower();
    local category = nil;

    if (
        command == 'ma' or
        command == 'magic' or
        command == 'so' or
        command == 'nin' or
        command:match('^m%d+$') ~= nil
    ) then
        category = 3;
    elseif (command == 'ja' or command == 'jobability') then
        category = 2;
    elseif (command == 'pet') then
        category = petCommandCategory;
    elseif (command == 'ws' or command == 'weaponskill') then
        category = 7;
    elseif (
        command == 'ra' or
        command == 'ranged' or
        command == 'range' or
        command == 'shoot' or
        command == 'throw'
    ) then
        category = 16;
    else
        return nil, nil;
    end

    rest = tostring(rest or ''):gsub('^%s+', '');
    if (rest == '') then
        return nil, nil;
    end

    local actionName = rest:match('^"(.-)"') or rest:match("^'(.-)'") or rest;
    actionName = actionName:gsub('%s*<[^>]*>.*$', '');
    actionName = actionName:gsub('%s+%d+%s*$', '');
    actionName = actionName:gsub('%s*;.*$', '');
    actionName = actionName:gsub('%s+', ' ');
    actionName = actionName:gsub('^%s+', '');
    actionName = actionName:gsub('%s+$', '');

    if (actionName == '') then
        return nil, nil;
    end

    return category, NormalizeActionName(actionName), actionName;
end

local function BuildActionCommandLookup(category)
    local normalizedCategory = tonumber(category) or 0;
    if (normalizedCategory <= 0) then
        return nil;
    end

    if (type(actionCommandNameCache) ~= 'table') then
        actionCommandNameCache = {};
    end

    if (actionCommandNameCache[normalizedCategory] ~= nil) then
        return actionCommandNameCache[normalizedCategory];
    end

    if (normalizedCategory == petCommandCategory) then
        local map = {};

        for id, command in pairs(petCommands) do
            local normalized = NormalizeActionName(command.en or command.name);
            if (type(normalized) == 'string' and normalized ~= '') then
                map[normalized] = {
                    id = tonumber(command.id) or tonumber(id),
                    method = 'PetCommand',
                };
            end
        end

        actionCommandNameCache[normalizedCategory] = map;
        return map;
    end

    local methodCandidates = {
        [2] = { 'GetAbilityById', 'GetSpellById' },
        [3] = { 'GetSpellById', 'GetAbilityById' },
        [7] = { 'GetWeaponSkillById', 'GetAbilityById' },
        [9] = { 'GetAbilityById', 'GetAbilityByTimerId', 'GetSpellById' },
        [16] = { 'GetAbilityById', 'GetAbilityByTimerId', 'GetSpellById' },
    };
    local scanLimits = {
        [2] = 4096,
        [3] = 4096,
        [7] = 2048,
        [9] = 4096,
        [16] = 4096,
    };
    local methods = methodCandidates[normalizedCategory] or {};
    local limit = scanLimits[normalizedCategory] or 2048;
    local resourceManagerAccessor = GetResourceManager;
    local resourceManager = nil;
    if (type(resourceManagerAccessor) == 'function') then
        resourceManager = SafeCall(nil, function()
            return resourceManagerAccessor();
        end);
    end
    if (resourceManager == nil) then
        resourceManager = SafeCall(nil, function()
            return AshitaCore:GetResourceManager();
        end);
    end
    if (resourceManager == nil) then
        return nil;
    end
    if (type(resourceManager) ~= 'table' and type(resourceManager) ~= 'userdata') then
        return nil;
    end

    local map = {};
    for id = 1, limit do
        for _, methodName in ipairs(methods) do
            local record = ResolveResourceByMethod(resourceManager, methodName, id);
            if (record ~= nil) then
                local normalized = nil;

                if (type(NormalizeActionDisplayName) == 'function') then
                    normalized = SafeCall(nil, function()
                        return NormalizeActionDisplayName(record);
                    end);
                else
                    normalized = SafeCall(nil, function()
                        local readName = ReadRecordDisplayName(record);
                        return NormalizeActionName(readName);
                    end);
                end

                if (type(normalized) == 'string' and normalized ~= '') then
                    local normalizedRecordName = normalized:lower();
                    if (map[normalizedRecordName] == nil) then
                        map[normalizedRecordName] = {
                            id = id,
                            method = methodName,
                        };
                    end
                end
            end
        end
    end

    if (type(actionCommandNameCache) == 'table') then
        actionCommandNameCache[normalizedCategory] = map;
    end
    return map;
end

local function ResolveActionIdByName(category, actionName)
    local normalized = NormalizeActionName(actionName);
    local rawActionName = tostring(actionName or '');
    local resolvedCategory = tonumber(category) or 0;

    if (normalized == nil or resolvedCategory <= 0) then
        return nil, nil;
    end

    local map = BuildActionCommandLookup(resolvedCategory);
    if (map == nil) then
        return nil, nil;
    end

    local entry = map[normalized];
    if (entry ~= nil) then
        local candidateId = tonumber(entry.id);
        local candidateMethod = tostring(entry.method or '');
        if (resolvedCategory == petCommandCategory and candidateId ~= nil) then
            return candidateId, 'PetCommand';
        end
        if (candidateId ~= nil and candidateMethod ~= '') then
            local idMethods = {
                [2] = { 'GetAbilityById', 'GetAbilityByTimerId', 'GetSpellById' },
                [3] = { 'GetSpellById', 'GetAbilityById', 'GetAbilityByTimerId' },
                [7] = { 'GetWeaponSkillById', 'GetMobSkillById' },
                [9] = { 'GetAbilityById', 'GetAbilityByTimerId', 'GetSpellById' },
                [16] = { 'GetAbilityById', 'GetMobSkillById', 'GetSpellById' },
            };

            local function IsCacheMethod(methodName)
                if (methodName == nil or methodName == '') then
                    return false;
                end

                for _, validMethod in ipairs(idMethods[resolvedCategory] or {}) do
                    if (methodName == validMethod) then
                        return true;
                    end
                end

                return false;
            end

            local manager = nil;
            local resourceManagerAccessor = GetResourceManager;
            if (type(resourceManagerAccessor) == 'function') then
                manager = SafeCall(nil, function()
                    return resourceManagerAccessor();
                end);
            end
            if (manager == nil) then
                manager = SafeCall(nil, function()
                    return AshitaCore:GetResourceManager();
                end);
            end

            local resolved = nil;
            if (
                IsCacheMethod(candidateMethod) == true and
                manager ~= nil and
                type(manager) == 'table' and
                type(manager[candidateMethod]) == 'function'
            ) then
                resolved = SafeCall(nil, function()
                    return ResolveResourceByMethod(manager, candidateMethod, candidateId);
                end);
            end

            local resolvedName = SafeCall(nil, function()
                return NormalizeActionDisplayName(resolved);
            end);
            if (type(resolvedName) == 'string' and resolvedName == normalized) then
                return candidateId, candidateMethod;
            end
            if (type(map) == 'table') then
                map[normalized] = nil;
            end
            if (IsDebugEnabled() == true) then
                DebugLog('action-range cached command resolution mismatch=' .. tostring(normalized) .. ' id=' .. tostring(candidateId) .. ' method=' .. tostring(candidateMethod));
            end
        end
    end

    local resourceManagerAccessor = GetResourceManager;
    local resourceManager = nil;
    if (type(resourceManagerAccessor) == 'function') then
        resourceManager = SafeCall(nil, function()
            return resourceManagerAccessor();
        end);
    end
    if (resourceManager == nil) then
        resourceManager = SafeCall(nil, function()
            return AshitaCore:GetResourceManager();
        end);
    end

    local function ReadRecordNameForCategory(categoryId, checkId)
        local resolvedId = tonumber(checkId);
        if (resolvedId == nil or resolvedId <= 0) then
            return nil;
        end

        local idMethods = {
            [2] = { 'GetAbilityById', 'GetAbilityByTimerId', 'GetSpellById' },
            [3] = { 'GetSpellById', 'GetAbilityById', 'GetAbilityByTimerId' },
            [7] = { 'GetWeaponSkillById', 'GetAbilityById' },
            [9] = { 'GetAbilityById', 'GetAbilityByTimerId', 'GetSpellById' },
            [16] = { 'GetAbilityById', 'GetMobSkillById', 'GetSpellById' },
        };

        local methods = idMethods[tonumber(categoryId) or 0] or {};

        for _, methodName in ipairs(methods) do
            if (type(resourceManager[methodName]) == 'function') then
                local record = SafeCall(nil, function()
                    return resourceManager[methodName](resourceManager, resolvedId);
                end);
                local name = SafeCall(nil, function()
                    return NormalizeActionDisplayName(record);
                end);
                if (type(name) == 'string' and name ~= '') then
                    return name, methodName;
                end
            end
        end

        return nil, nil;
    end

    if (
        resourceManager ~= nil and
        (type(resourceManager) == 'table' or type(resourceManager) == 'userdata')
    ) then
        local function ResolveByName(methodName, name)
            local method = resourceManager[methodName];
            if (type(method) ~= 'function') then
                return nil;
            end

            local directMethods = {
                { name },
                { name, 0 },
                { name, 1 },
            };

            for _, args in ipairs(directMethods) do
                local value = SafeCall(nil, function()
                    return method(resourceManager, unpack(args));
                end);
                if (value ~= nil) then
                    return value;
                end
            end

            return nil;
        end

        local directNameLookupMethods = {
            [2] = { 'GetAbilityByName', 'GetSpellByName', 'GetWeaponSkillByName', 'GetMobSkillByName' },
            [3] = { 'GetSpellByName', 'GetAbilityByName', 'GetWeaponSkillByName' },
            [7] = { 'GetWeaponSkillByName', 'GetMobSkillByName', 'GetAbilityByName' },
            [9] = { 'GetAbilityByName', 'GetSpellByName', 'GetWeaponSkillByName', 'GetMobSkillByName' },
            [16] = { 'GetAbilityByName', 'GetWeaponSkillByName', 'GetMobSkillByName', 'GetSpellByName' },
        };
        local nameMethods = directNameLookupMethods[resolvedCategory] or {};
        local actionNameVariants = {
            rawActionName,
            rawActionName:upper(),
            rawActionName:gsub('(%a)([%w]*)', function(first, rest)
                return first:upper() .. rest;
            end),
        };

        for _, methodName in ipairs(nameMethods) do
                if (type(resourceManager[methodName]) == 'function') then
                for _, attemptName in ipairs(actionNameVariants) do
                    local value = ResolveByName(methodName, attemptName);

                    local resolvedId = nil;
                    if (type(value) == 'number') then
                        resolvedId = value;
                    elseif (type(value) == 'table' or type(value) == 'userdata') then
                        resolvedId = SafeCall(nil, function()
                            return value.Id;
                        end);
                        if (resolvedId == nil or resolvedId == false) then
                            resolvedId = SafeCall(nil, function()
                                return value.ID;
                            end);
                        end
                        if (resolvedId == nil or resolvedId == false) then
                            resolvedId = SafeCall(nil, function()
                                return value.id;
                            end);
                        end
                    end

                    if (type(resolvedId) == 'number' and resolvedId > 0) then
                        local checkName, checkMethod = ReadRecordNameForCategory(resolvedCategory, resolvedId);
                        if (type(checkName) == 'string' and checkName == normalized and type(checkMethod) == 'string') then
                            map[normalized] = {
                                id = resolvedId,
                                method = checkMethod,
                            };
                            return resolvedId, checkMethod;
                        end
                    end
                end
            end
        end
    end

    local fallbackId, fallbackMethod = ResolveActionIdByNameSlow(resolvedCategory, normalized);
    if (fallbackId ~= nil) then
        if (type(map) == 'table') then
            map[normalized] = {
                id = fallbackId,
                method = fallbackMethod,
            };
        end
        return fallbackId, fallbackMethod;
    end

    return nil, nil;
end

local function ClearQueuedActionForContextChange()
    lastAction = nil;
    lastQueuedPacketSignature = nil;
    lastQueuedPacketAt = 0;
    lastCommandQueuedAt = nil;
    lastCommandQueuedSignature = nil;
end

local function FormatAction(action)
    if (action == nil) then
        return 'none';
    end

    return string.format(
        'category=%s(%s) id=%s range=%s updated=%s',
        tostring(action.category or 'nil'),
        tostring(categoryNames[tonumber(action.category) or 0] or 'unknown'),
        tostring(action.id or 'nil'),
        tostring(action.range),
        tostring(action.updated or 0)
    );
end

local function UpdateQueuedActionText(name, source)
    local text = tostring(name or ''):gsub('^%s+', ''):gsub('%s+$', '');

    if (text == '') then
        return;
    end

    lastQueuedActionName = text;
    lastQueuedActionSource = tostring(source or 'unknown');
end

local function IsPacketLogAllowed(hexId)
    local now = os.clock();
    local last = tonumber(lastPacketOutLogAt[hexId]) or -1;

    if ((now - last) < packetLogCooldown) then
        return false;
    end

    lastPacketOutLogAt[hexId] = now;
    return true;
end

local function DebugLogPacket(e, parsedCategory, parsedActionId)
    if (e == nil or IsPacketDebugEnabled() ~= true) then
        return;
    end

    local packetKey = string.format('%#04x', tonumber(e.id) or 0);
    local packetData = GetPacketData(e);
    local sizeText = tostring(GetPacketSize(e));
    local function formatPacketBytesFallback(data, maxBytes)
        local bytes = {};
        local len = math.min(tonumber(maxBytes) or 16, #(tostring(data or '')));

        for i = 1, len do
            bytes[#bytes + 1] = string.format('%02X', string.byte(data, i) or 0);
        end

        return table.concat(bytes, ' ');
    end
    if (IsPacketLogAllowed(packetKey) ~= true) then
        return;
    end

    if (parsedCategory ~= nil or parsedActionId ~= nil) then
        local candidateOffsets = {
            0x00, 0x02, 0x04, 0x06, 0x08, 0x0A, 0x0C,
            0x0E, 0x10, 0x12, 0x14, 0x16, 0x18, 0x1A, 0x1C,
            0x1E, 0x20,
        };
        local candidatesText = FormatWordPairs(packetData, candidateOffsets);
        DebugLog(string.format(
            'action-range packet seen id=%s size=%s rawCategory=%s rawAction=%s scan=%s',
            packetKey,
            sizeText,
            tostring(parsedCategory),
            tostring(parsedActionId),
            candidatesText
        ));
    else
        DebugLog(string.format(
            'action-range packet seen id=%s size=%s (no parsed action) head=%s',
            packetKey,
            sizeText,
            (FormatPacketBytes ~= nil and FormatPacketBytes(packetData, 24)) or formatPacketBytesFallback(packetData, 24)
        ));
    end
end

local function Read(data, format, offset)
    if (data == nil) then
        return nil;
    end

    local ok, value = pcall(function()
        return struct.unpack(format, data, offset + 1);
    end);

    if (ok ~= true) then
        return nil;
    end

    return tonumber(value);
end

local function ReadWord(data, offset, littleEndian)
    if (data == nil or offset == nil) then
        return nil;
    end

    local i = tonumber(offset) + 1;
    local b1 = string.byte(data, i, i + 1);

    if (b1 == nil) then
        return nil;
    end

    local first = b1;
    local second = string.byte(data, i + 1);

    if (second == nil) then
        return nil;
    end

    if (littleEndian ~= false) then
        return first + (second * 256);
    end

    return (first * 256) + second;
end

local function FormatPacketBytes(data, maxBytes)
    maxBytes = tonumber(maxBytes) or 16;
    data = tostring(data or '');
    local length = math.min(maxBytes, #data);
    local bytes = {};

    for index = 1, length do
        bytes[#bytes + 1] = string.format('%02X', string.byte(data, index) or 0);
    end

    return table.concat(bytes, ' ');
end

local function NormalizeNumber(value)
    local number = tonumber(value);

    if (number == nil) then
        return nil;
    end

    return number;
end

local function IsLikelyNoopActionId(actionId)
    actionId = tonumber(actionId);
    return (
        actionId == nil or
        actionId <= 0 or
        actionId == 0x00FF or
        actionId <= 0x02
    );
end

local function ReadResourceField(resource, key)
    if (resource == nil or type(key) ~= 'string') then
        return nil;
    end

    local ok, value = pcall(function()
        return resource[key];
    end);

    if (ok ~= true) then
        return nil;
    end

    return value;
end

local abilityNameLookupCache = {};

NormalizeActionDisplayName = function(record)
    local name = ReadRecordDisplayName(record);
    return NormalizeActionName(name);
end

ReadRecordDisplayName = function(record)
    if (record == nil) then
        return nil;
    end

    local function ReadFieldName(value)
        if (type(value) == 'table') then
            if (value[1] ~= nil) then
                if (tostring(value[1]) ~= '' and tostring(value[1]) ~= '.') then
                    return tostring(value[1]);
                end
            end

            for index = 2, 20 do
                local candidate = value[index];
                if (candidate ~= nil and tostring(candidate) ~= '' and tostring(candidate) ~= '.') then
                    return tostring(candidate);
                end
            end

            return nil;
        end

        local valueType = type(value);
        if (valueType == 'userdata') then
            for index = 1, 20 do
                local candidate = SafeCall(nil, function()
                    return value[index];
                end);
                if (candidate ~= nil and tostring(candidate) ~= '' and tostring(candidate) ~= '.') then
                    return tostring(candidate);
                end
            end

            local userdataKeys = {
                'Name',
                'name',
                'English',
                'english',
                'FullName',
                'fullName',
            };

            for _, key in ipairs(userdataKeys) do
                local candidate = SafeCall(nil, function()
                    return value[key];
                end);
                if (candidate ~= nil and tostring(candidate) ~= '' and tostring(candidate) ~= '.') then
                    return tostring(candidate);
                end
            end

            return nil;
        end
        if (valueType ~= 'string' and valueType ~= 'number') then
            return nil;
        end

        local text = tostring(value);
        if (text ~= nil and text ~= '' and text ~= '.') then
            return text;
        end

        return nil;
    end

    local directName = ReadFieldName(SafeCall(nil, function()
        return record.Name;
    end));
    if (directName ~= nil) then
        return directName;
    end

    local lowerName = ReadFieldName(SafeCall(nil, function()
        return record.name;
    end));
    if (lowerName ~= nil) then
        return lowerName;
    end

    local keyCandidates = {
        'english',
        'English',
        'fullName',
        'FullName',
        'description',
        'Description',
    };

    for _, key in ipairs(keyCandidates) do
        local value = ReadResourceField(record, key);
        local text = ReadFieldName(value);
        if (text ~= nil) then
            return text;
        end
    end

    local canIterate = pcall(function()
        for _ in pairs(record) do
        end
    end);

    if (canIterate == true and type(record) == 'table') then
        for key, value in pairs(record) do
            if (
                type(key) == 'string' and
                type(value) == 'string' and
                key:lower():find('name') ~= nil and
                value ~= '' and
                value ~= '.'
            ) then
                return value;
            end

            if (type(value) == 'table' and type(key) == 'string' and key:lower():find('name') ~= nil) then
                local text = ReadFieldName(value);
                if (text ~= nil) then
                    return text;
                end
            end
        end
    end

    return nil;
end

local function ResolveRecordByTimerId(resourceManager, timerId)
    timerId = tonumber(timerId);
    if (timerId == nil or resourceManager == nil) then
        return nil;
    end

    local cacheKey = tostring(timerId);
    local cached = abilityNameLookupCache[cacheKey];
    if (cached ~= nil) then
        if (cached == false) then
            return nil;
        end

        return cached;
    end

    local getAbilityById = resourceManager.GetAbilityById;
    local getAbilityByTimer = resourceManager.GetAbilityByTimerId;

    local function MatchTimer(record)
        local timerFieldNames = {
            'RecastTimerId',
            'recastTimerId',
            'RecastId',
            'recastId',
            'RecastDelay',
            'recastDelay',
            'Recast',
            'recast',
        };

        for _, key in ipairs(timerFieldNames) do
            local matchTimer = ReadResourceField(record, key);
            if (NormalizeNumber(matchTimer) == timerId) then
                return true;
            end
        end

        local canIterate = true;
        local okIter = pcall(function()
            for _ in pairs(record) do
                canIterate = true;
                break;
            end
        end);

        if (okIter == true) then
            for key, value in pairs(record) do
                if (type(key) == 'string' and type(value) ~= 'table') then
                    local keyLower = key:lower();
                    if (keyLower:find('timer') ~= nil or keyLower:find('recast') ~= nil) then
                        if (NormalizeNumber(value) == timerId) then
                            return true;
                        end
                    end
                end
            end
        end

        return false;
    end

    local function ScanAbilityIdRange(limit)
        for abilityId = 1, limit do
            local record = nil;
            if (getAbilityById ~= nil) then
                record = SafeCall(nil, function()
                    return getAbilityById(resourceManager, abilityId);
                end);
            end

            if (record == nil and getAbilityByTimer ~= nil) then
                record = SafeCall(nil, function()
                    return getAbilityByTimer(resourceManager, abilityId);
                end);
            end

            if (record ~= nil and MatchTimer(record) == true) then
                abilityNameLookupCache[cacheKey] = record;
                return record;
            end
        end

        return nil;
    end

    local ranges = { 256, 1024, 2048, 4096, 8192 };
    for _, limit in ipairs(ranges) do
        local match = ScanAbilityIdRange(limit);
        if (match ~= nil) then
            return match;
        end
    end

    abilityNameLookupCache[cacheKey] = false;
    return nil;
end

local function GetQueuedActionName(resource, category, actionId, resolvedId)
    local resourceManagerAccessor = GetResourceManager;
    local resourceManager = nil;
    if (type(resourceManagerAccessor) == 'function') then
        resourceManager = SafeCall(nil, function()
            return resourceManagerAccessor();
        end);
        if (resourceManager == nil or resourceManager == false) then
            resourceManager = nil;
        end
    end

    if (resourceManager == nil) then
        resourceManager = SafeCall(nil, function()
            return AshitaCore:GetResourceManager();
        end);
    end

    local resolved = tonumber(resolvedId) or tonumber(actionId);

    if (resource ~= nil) then
        local resourceName = ReadRecordDisplayName(resource);
        if (type(resourceName) == 'string' and resourceName ~= '') then
            return resourceName;
        end
    end

    if (resourceManager ~= nil and resolved ~= nil) then
        local getAbility = resourceManager.GetAbilityById;
        local getAbilityByTimerId = resourceManager.GetAbilityByTimerId;
        local getSpell = resourceManager.GetSpellById;
        local getWeaponSkill = resourceManager.GetWeaponSkillById;
        local getMobSkill = resourceManager.GetMobSkillById;
        local record = nil;

        if (
            category == 2 or category == 9 or category == 16 or
            category == 7
        ) then
            if (getAbility ~= nil) then
                record = SafeCall(nil, function()
                    return getAbility(resourceManager, resolved);
                end);
            end

            if (record == nil and getAbilityByTimerId ~= nil) then
                record = SafeCall(nil, function()
                    return getAbilityByTimerId(resourceManager, resolved);
                end);
            end

            if (record == nil and getWeaponSkill ~= nil) then
                record = SafeCall(nil, function()
                    return getWeaponSkill(resourceManager, resolved);
                end);
            end

            if (record == nil and getMobSkill ~= nil) then
                record = SafeCall(nil, function()
                    return getMobSkill(resourceManager, resolved);
                end);
            end
        elseif (category == 3 and getSpell ~= nil) then
            record = SafeCall(nil, function()
                return getSpell(resourceManager, resolved);
            end);
        end

        local recordName = ReadRecordDisplayName(record);
        if (type(recordName) == 'string' and recordName ~= '') then
            return recordName;
        end

        if (category == 2 or category == 7 or category == 9 or category == 16) then
            local timerRecord = ResolveRecordByTimerId(resourceManager, resolved);
            local timerName = ReadRecordDisplayName(timerRecord);
            if (type(timerName) == 'string' and timerName ~= '') then
                return timerName;
            end
        end
    end

    return 'actionId ' .. tostring(actionId or '-');
end

local abilityRangeLookup = {
    [0x0000] = 0,
    [0x0001] = 1,
    [0x0003] = 3,
    [0x0004] = 4,
    [0x0005] = 5,
    [0x0006] = 6,
    [0x0007] = 7,
    [0x0008] = 8,
    [0x000A] = 10,
    [0x000C] = 12,
    [0x000E] = 14,
    [0x0010] = 16,
    [0x0014] = 20,
    [0x0019] = 25,
    [0x001E] = 30,
    [0x00FF] = 255,
};

local areaRangeLookup = {
    [0x0000] = 0,
    [0x0001] = 1,
    [0x0003] = 3,
    [0x0004] = 4,
    [0x0005] = 5,
    [0x0006] = 6,
    [0x0007] = 7,
    [0x0008] = 8,
    [0x000A] = 10,
    [0x000C] = 12,
    [0x000E] = 14,
    [0x0010] = 16,
    [0x0014] = 20,
    [0x0019] = 25,
    [0x001E] = 30,
    [0x0023] = 35,
    [0x00FF] = 255,
};

local petCommandRangeLookup = {
    [0x000B] = 18,
};

local function DecodeRangeCode(resource, rawValue)
    local index = NormalizeNumber(rawValue);

    if (index == nil) then
        return nil;
    end

    local shapeType = tonumber(resource and resource.AreaShapeType) or tonumber(resource and resource.areaShapeType);
    local lookup = abilityRangeLookup;

    if (shapeType == 3) then
        lookup = areaRangeLookup;
    end

    local actionType = tostring(ReadResourceField(resource, 'type') or ReadResourceField(resource, 'Type') or ''):lower();
    if (actionType == 'petcommand') then
        local petCommandDecoded = petCommandRangeLookup[index];
        if (petCommandDecoded ~= nil) then
            return petCommandDecoded;
        end
    end

    local decoded = lookup[index];
    if (decoded ~= nil) then
        return decoded;
    end

    if (shapeType ~= 3) then
        return nil;
    end

    return abilityRangeLookup[index];
end

local function IsBlueMagicResource(resource)
    if (resource == nil) then
        return false;
    end

    local actionType = tostring(ReadResourceField(resource, 'type') or ReadResourceField(resource, 'Type') or '');
    if (actionType:lower() == 'bluemagic') then
        return true;
    end

    if (NormalizeNumber(ReadResourceField(resource, 'skill') or ReadResourceField(resource, 'Skill')) == 43) then
        return true;
    end

    return NormalizeNumber(ReadResourceField(resource, 'blu_points') or ReadResourceField(resource, 'BluPoints')) ~= nil;
end

local function ResolveRangeFromResourceManager(category, actionId)
    local resourceManagerAccessor = GetResourceManager;
    local resourceManager = nil;
    if (type(resourceManagerAccessor) == 'function') then
        resourceManager = SafeCall(nil, function()
            return resourceManagerAccessor();
        end);
        if (resourceManager == nil or resourceManager == false) then
            resourceManager = nil;
        end
    end

    if (resourceManager == nil) then
        resourceManager = SafeCall(nil, function()
            return AshitaCore:GetResourceManager();
        end);
    end

    if (resourceManager == nil) then
        return nil;
    end

    local methodsByCategory = {
        [2] = { 'GetAbilityRange' },
        [3] = { 'GetSpellRange' },
        [7] = { 'GetAbilityRange', 'GetSpellRange' },
        [9] = { 'GetAbilityRange' },
        [16] = { 'GetAbilityRange', 'GetSpellRange' },
    };

    local methods = methodsByCategory[tonumber(category) or 0];
    if (methods == nil) then
        return nil;
    end

    for _, methodName in ipairs(methods) do
        if (resourceManager[methodName] ~= nil) then
            local value = SafeCall(nil, function()
                return resourceManager[methodName](resourceManager, tonumber(actionId), false);
            end);

            if (value ~= nil) then
                local number = NormalizeNumber(value);
                if (number ~= nil and number > 0) then
                    return number;
                end
            end
        end
    end

    return nil;
end

local function ExtractRange(resource, category, actionId)
    local function ResolveCandidate(value)
        local number = NormalizeNumber(value);
        if (number ~= nil and number > 0) then
            local decoded = DecodeRangeCode(resource, number);
            if (decoded ~= nil and decoded > 0) then
                return decoded;
            end
            return number;
        end

        if (type(value) == 'table') then
            local first = NormalizeNumber(value[1]);
            if (first ~= nil and first > 0) then
                local decoded = DecodeRangeCode(resource, first);
                if (decoded ~= nil and decoded > 0) then
                    return decoded;
                end
                return first;
            end
        end

        return nil;
    end

    if (tonumber(category) == 3 and IsBlueMagicResource(resource) == true) then
        local blueRange = ResolveCandidate(ReadResourceField(resource, 'Range') or ReadResourceField(resource, 'range'));
        if (blueRange ~= nil and blueRange > 0) then
            return blueRange;
        end
    end

    local methodRange = ResolveRangeFromResourceManager(category, actionId);
    if (methodRange ~= nil and methodRange > 0) then
        return methodRange;
    end

    local candidateKeys = {
        'Range',
        'range',
        'TargetRange',
        'targetRange',
        'Distance',
        'distance',
        'MaxRange',
        'maxRange',
    };

    for _, key in ipairs(candidateKeys) do
        local value = ReadResourceField(resource, key);
        local resolved = ResolveCandidate(value);
        if (resolved ~= nil and resolved > 0) then
            return resolved;
        end
    end

    local scannedResult = nil;
    local scanned = pcall(function()
        for key, value in pairs(resource) do
            if (type(key) == 'string') then
                local lower = key:lower();
                if (
                    lower:find('range') ~= nil or
                    lower:find('distance') ~= nil
                ) then
                    local isAreaRange = (
                        lower:find('area') ~= nil or
                        lower:find('aoe') ~= nil or
                        lower:find('radius') ~= nil
                    );

                    if (isAreaRange ~= true) then
                        local resolved = ResolveCandidate(value);
                        if (resolved ~= nil and resolved > 0) then
                            scannedResult = resolved;
                            return;
                        end
                    end
                end
            end
        end
    end);

    if (scanned == true and scannedResult ~= nil) then
        return scannedResult;
    end

    if (scanned == true) then
        return nil;
    end

    if (resource == nil) then
        return nil;
    end

    local ok, resourceType = pcall(function()
        return type(resource);
    end);
    if (ok ~= true or resourceType ~= 'table') then
        return nil;
    end

    return nil;
end

local function DescribeResourceRangeHints(resource)
    if (resource == nil) then
        return '';
    end

    local keys = {};
    local function AddHint(label, keyName, value)
        keys[#keys + 1] = string.format('%s=%s:%s', tostring(label), tostring(keyName), tostring(value));
    end

    local hintKeys = {
        'Range',
        'range',
        'TargetRange',
        'targetRange',
        'Distance',
        'distance',
        'MaxRange',
        'maxRange',
        'Radius',
        'radius',
        'AreaRange',
        'areaRange',
        'AOERange',
        'aoeRange',
    };

    for _, key in ipairs(hintKeys) do
        local value = ReadResourceField(resource, key);
        if (value ~= nil) then
            AddHint(key, key, value);
        end
    end

    local ok = pcall(function()
        for key, value in pairs(resource) do
            if (type(key) == 'string') then
                local lower = key:lower();
                if (
                    lower:find('range') ~= nil or
                    lower:find('distance') ~= nil or
                    lower:find('radius') ~= nil
                ) then
                    AddHint(key, key, value);
                end
            end
        end
    end);

    if (ok ~= true) then
        return table.concat(keys, ',');
    end

    return table.concat(keys, ',');
end

local function GetResourceManager()
    local ok, value = pcall(function()
        return AshitaCore:GetResourceManager();
    end);

    if (ok ~= true) then
        return nil;
    end

    return value;
end

local function ResolveActionResource(category, actionId, requireKnownMethods, skipTimerMethods)
    actionId = tonumber(actionId);
    category = tonumber(category) or 0;

    if (actionId == nil or actionId <= 0) then
        return nil, nil, nil;
    end

    if (category == petCommandCategory) then
        local resource = petCommands[actionId];
        resourceCache[tostring(category) .. ':' .. tostring(actionId)] = {
            resource = resource,
            method = 'PetCommand',
            id = actionId,
            category = category,
            resolvedId = actionId,
        };

        return resource, 'PetCommand', actionId;
    end

    local key = tostring(category) .. ':' .. tostring(actionId);

    if (resourceCache[key] ~= nil) then
        local entry = resourceCache[key];
        return entry.resource, entry.method, entry.resolvedId;
    end

    local resourceManager = GetResourceManager();

    if (resourceManager == nil) then
        return nil, nil;
    end

    local methods = nil;

    if (requireKnownMethods == true) then
        methods = (skipTimerMethods == true) and strictResourceMethodCandidatesNoTimer[category] or strictResourceMethodCandidates[category];
    else
        methods = resourceMethodCandidates[category];
    end
    if (methods == nil) then
        if (requireKnownMethods == true) then
            return nil, nil, nil;
        end

        methods = {
            'GetSpellById',
            'GetAbilityById',
            'GetAbilityByTimerId',
            'GetWeaponSkillById',
            'GetMobSkillById',
            'GetItemById',
        };
    end

    local resource = nil;
    local methodUsed = nil;
    local resolvedId = nil;

    for _, methodName in ipairs(methods) do
            if (resourceManager[methodName] ~= nil) then
            local candidateIds = BuildActionCandidateIds(category, actionId);
            for _, candidateId in ipairs(candidateIds) do
                local value = SafeCall(nil, function()
                    return resourceManager[methodName](resourceManager, candidateId);
                end);

                if (value ~= nil) then
                    resource = value;
                    methodUsed = methodName;
                    resolvedId = candidateId;
                    break;
                end
            end

            if (resource ~= nil) then
                break;
            end
        end
    end

    resourceCache[key] = {
        resource = resource,
        method = methodUsed,
        id = actionId,
        category = category,
        resolvedId = resolvedId,
    };

    if (resource == nil and IsDebugEnabled() == true) then
        DebugLog('action-range resource miss category=' .. tostring(category) .. ' id=' .. tostring(actionId) .. ' methods=' .. table.concat(methods, ','));
    end

    return resource, methodUsed, resolvedId;
end

local function ResolveActionRange(category, actionId)
    local cached = resourceCache[tostring(category) .. ':' .. tostring(actionId)];

    if (cached ~= nil and cached.range ~= nil) then
        return cached.range;
    end

    local resourceMethodOk, resource, method, resolvedId = pcall(function()
        return ResolveActionResource(category, actionId);
    end);
    resource = (resourceMethodOk == true and resource) or nil;
    method = (resourceMethodOk == true and method) or nil;
    resolvedId = (resourceMethodOk == true and resolvedId) or nil;
    local range = ExtractRange(resource, category, actionId);

    if (cached == nil) then
        cached = {
            resource = resource,
            method = method,
            id = tonumber(actionId),
            category = tonumber(category),
        };
        resourceCache[tostring(category) .. ':' .. tostring(actionId)] = cached;
    else
        cached.resource = resource;
        cached.id = tonumber(actionId);
        cached.category = tonumber(category);
        cached.method = method;
        cached.resolvedId = resolvedId;
    end

    cached.range = range;
    cached.lookupMethod = method;
    cached.lookupId = resolvedId;

    if (cached.range == nil and IsDebugEnabled() == true) then
        DebugLog('action-range resolve result category=' .. tostring(category) .. ' id=' .. tostring(actionId) .. ' resolvedId=' .. tostring(resolvedId or actionId) .. ' method=' .. tostring(method) .. ' range=nil hints=' .. tostring(DescribeResourceRangeHints(resource)));
    end

    return range;
end

local function ParseOutActionPacket(e)
    if (e == nil or e.id ~= 0x01A) then
        return nil, nil;
    end

    local data = GetPacketData(e);
    local categoryLe = ReadWord(data, 0x0A, true);
    local actionIdLe = ReadWord(data, 0x0C, true);
    local categoryBe = ReadWord(data, 0x0A, false);
    local actionIdBe = ReadWord(data, 0x0C, false);

    local function HasResource(candidateCategory, candidateActionId)
        if (IsLikelyNoopActionId(candidateActionId) == true) then
            return false;
        end
        local resourceMethodOk, resource = pcall(function()
            return ResolveActionResource(candidateCategory, candidateActionId, true, true);
        end);

        return (resourceMethodOk == true and resource ~= nil);
    end

    if ((categoryLe == nil or actionIdLe == nil) and (categoryBe == nil or actionIdBe == nil)) then
        return nil, nil;
    end

    if (HasResource(categoryLe, actionIdLe) == true) then
        return categoryLe, actionIdLe;
    end

    if (HasResource(categoryBe, actionIdBe) == true) then
        return categoryBe, actionIdBe;
    end

    if (trackedCategories[tonumber(categoryLe) or 0] == true) then
        return tonumber(categoryLe), tonumber(actionIdLe);
    end

    if (trackedCategories[tonumber(categoryBe) or 0] == true) then
        return tonumber(categoryBe), tonumber(actionIdBe);
    end

    if ((categoryLe == nil and categoryBe == nil) or (actionIdLe == nil and actionIdBe == nil)) then
        return nil, nil;
    end

    if (actionIdLe ~= nil and categoryLe ~= nil) then
        return categoryLe, actionIdLe;
    end

    return categoryBe, actionIdBe;
end

local function ParseOutActionChunkPacket(e)
    if (e == nil) then
        return nil, nil;
    end

    local chunkData = e.chunk_data_raw or e.chunk_data;
    local chunkSize = tonumber(e.chunk_size) or 0;
    local fallbackData = GetPacketData(e);
    local fallbackSize = tonumber(e.size) or 0;

    if (chunkData == nil or chunkSize <= 0) then
        if (fallbackData ~= nil and fallbackSize > 0x0E) then
            return ScanActionCandidates(fallbackData, fallbackSize, true, true);
        end

        return nil, nil;
    end

    local ok, category, actionId = pcall(function()
        local offset = 0;
        while (offset < chunkSize) do
            local packetId = ashita.bits.unpack_be(chunkData, offset, 0, 9);
            local size = ashita.bits.unpack_be(chunkData, offset, 9, 7) * 4;

            if (size <= 0) then
                break;
            end

            if (packetId == 0x01A) then
                local actionData = struct.unpack('c' .. size, chunkData, offset + 1);
                local categoryLe = ReadWord(actionData, 0x0A, true);
                local actionIdLe = ReadWord(actionData, 0x0C, true);
                local categoryBe = ReadWord(actionData, 0x0A, false);
                local actionIdBe = ReadWord(actionData, 0x0C, false);

                local function HasResource(candidateCategory, candidateActionId)
                    if (IsLikelyNoopActionId(candidateActionId) == true) then
                        return false;
                    end
                    local resourceMethodOk, resource = pcall(function()
                        return ResolveActionResource(candidateCategory, candidateActionId, true, true);
                    end);

                    return (resourceMethodOk == true and resource ~= nil);
                end

                if (HasResource(categoryLe, actionIdLe) == true) then
                    return categoryLe, actionIdLe;
                end

                if (HasResource(categoryBe, actionIdBe) == true) then
                    return categoryBe, actionIdBe;
                end

                if (trackedCategories[tonumber(categoryLe) or 0] == true) then
                    return tonumber(categoryLe), tonumber(actionIdLe);
                end

                if (trackedCategories[tonumber(categoryBe) or 0] == true) then
                    return tonumber(categoryBe), tonumber(actionIdBe);
                end

                if (categoryLe ~= nil and actionIdLe ~= nil) then
                    return categoryLe, actionIdLe;
                end
            end

            offset = offset + size;
        end

        return nil, nil;
    end);

    if (ok ~= true) then
        return nil, nil;
    end

    if ((category == nil or actionId == nil) and fallbackData ~= nil and fallbackSize > 0x0E) then
        return ScanActionCandidates(fallbackData, fallbackSize, true, true);
    end

    return category, actionId;
end

ScanActionCandidates = function(data, size, requireResolved)
    size = tonumber(size) or 0;
    if (data == nil or size < 0x0E) then
        return nil, nil;
    end

    local trackedOrder = {};
    local fallbackOrder = {};
    local sizeLimit = math.min(size, #data);
    local function AddCandidate(offset, category, actionId)
        if (category == nil or actionId == nil) then
            return;
        end

        category = tonumber(category);
        actionId = tonumber(actionId);

        if (
            category == nil or actionId == nil or
            IsLikelyNoopActionId(actionId) == true or category <= 0
        ) then
            return;
        end

        local entry = {
            offset = offset,
            category = category,
            action = actionId,
            tracked = trackedCategories[category] == true,
            plausible = (category >= 1 and category <= 31 and actionId > 0 and actionId <= 0xFFFF)
        };

        if (entry.tracked == true) then
            trackedOrder[#trackedOrder + 1] = entry;
        elseif (entry.plausible == true) then
            fallbackOrder[#fallbackOrder + 1] = entry;
        end
    end

    local function ScanRange(startOffset, littleEndian)
        for offset = startOffset, (sizeLimit - 4) do
            local category = ReadWord(data, offset, littleEndian);
            local actionId = ReadWord(data, offset + 2, littleEndian);
            AddCandidate(offset, category, actionId);
        end
    end

    local candidateOffsets = {
        0x00, 0x02, 0x04, 0x06, 0x08, 0x0A, 0x0C, 0x0E, 0x10, 0x12, 0x14,
    };

    for _, offset in ipairs(candidateOffsets) do
        if (offset <= (sizeLimit - 4)) then
            local category = ReadWord(data, offset, true);
            local actionId = ReadWord(data, offset + 2, true);
            AddCandidate(offset, category, actionId);

            local beCategory = ReadWord(data, offset, false);
            local beActionId = ReadWord(data, offset + 2, false);
            AddCandidate(offset, beCategory, beActionId);
        end
    end

    ScanRange(0x20, true);
    ScanRange(0x20, false);

    local bestList = trackedOrder[1] ~= nil and trackedOrder or fallbackOrder;
    local best = bestList[1];

    if (best == nil or DebugLog == nil) then
        return nil, nil;
    end

    if (requireResolved == true) then
        local function ResolveCandidate(candidateList)
            for _, candidate in ipairs(candidateList) do
                if (IsLikelyNoopActionId(candidate.action) ~= true) then
                    local resourceMethodOk, resource = pcall(function()
                        return ResolveActionResource(candidate.category, candidate.action, true, true);
                    end);

                    if (resourceMethodOk == true and resource ~= nil) then
                        DebugLog('action-range candidate resolved=' .. tostring(candidate.category) .. ' action=' .. tostring(candidate.action) .. ' offset=' .. tostring(candidate.offset));
                        return candidate.category, candidate.action;
                    end
                end
            end

            return nil, nil;
        end

        local resolvedCategory, resolvedAction = ResolveCandidate(trackedOrder);

        if (resolvedCategory == nil and bestList ~= fallbackOrder) then
            resolvedCategory, resolvedAction = ResolveCandidate(fallbackOrder);
        end

        if (resolvedCategory ~= nil) then
            return resolvedCategory, resolvedAction;
        end
    end

    if (#trackedOrder > 0) then
        DebugLog('action-range candidate tracked=' .. tostring(best.category) .. ' action=' .. tostring(best.action) .. ' offset=' .. tostring(best.offset));
        return best.category, best.action;
    end

    DebugLog('action-range candidate fallback=' .. tostring(best.category) .. ' action=' .. tostring(best.action) .. ' offset=' .. tostring(best.offset));

    return best.category, best.action;
end;

local function ParseOutActionLoosePacket(e)
    if (e == nil) then
        return nil, nil;
    end

    local data = GetPacketData(e);
    local packetSize = GetPacketSize(e);
    if (data == nil or packetSize < 0x0E) then
        return nil, nil;
    end

    local packetId = tonumber(e.id) or -1;

    if (packetId == 0x015 or packetId == 0x1A2) then
        local preferredOffsets = {
            0x04, 0x06, 0x08,
            0x0A, 0x0C, 0x0E,
            0x10, 0x12, 0x14, 0x16,
            0x18, 0x1A,
        };
        for _, offset in ipairs(preferredOffsets) do
            local candidateCategory = ReadWord(data, offset, true);
            local candidateAction = ReadWord(data, offset + 2, true);
            local beCategory = ReadWord(data, offset, false);
            local beAction = ReadWord(data, offset + 2, false);
            local categoryNumber = tonumber(candidateCategory);
            local actionNumber = tonumber(candidateAction);
            local beCategoryNumber = tonumber(beCategory);
            local beActionNumber = tonumber(beAction);

            local function ResolveAndTrack(candidateCategoryId, candidateActionId)
                if (
                    candidateCategoryId == nil or candidateActionId == nil or
                    candidateCategoryId <= 0 or candidateActionId <= 0
                ) then
                    return nil, nil;
                end

                if (candidateActionId <= 2) then
                    return nil, nil;
                end

                local function HasResource(candidateCategoryId2, candidateActionId2)
                    if (IsLikelyNoopActionId(candidateActionId2) == true) then
                        return false;
                    end
                    local resourceMethodOk, resource = pcall(function()
                        return ResolveActionResource(candidateCategoryId2, candidateActionId2, true, true);
                    end);

                    return (resourceMethodOk == true and resource ~= nil);
                end

                if (HasResource(candidateCategoryId, candidateActionId) == true) then
                    return candidateCategoryId, candidateActionId;
                end

                return nil, nil;
            end

            local foundCategory, foundAction = ResolveAndTrack(categoryNumber, actionNumber);
            if (foundCategory ~= nil and foundAction ~= nil) then
                return foundCategory, foundAction;
            end

            local foundBeCategory, foundBeAction = ResolveAndTrack(beCategoryNumber, beActionNumber);
            if (foundBeCategory ~= nil and foundBeAction ~= nil) then
                return foundBeCategory, foundBeAction;
            end

        end
    end

    local category = ReadWord(data, 0x0A, true);
    local actionId = ReadWord(data, 0x0C, true);
    local categoryNumber = tonumber(category);
    local actionIdNumber = tonumber(actionId);

    if (categoryNumber == nil or actionIdNumber == nil or actionIdNumber <= 0) then
        return nil, nil;
    end

    if (categoryNumber <= 0 or categoryNumber > 0xFFFF) then
        return nil, nil;
    end

    local function HasResourceForPacket(candidateCategory, candidateAction)
        if (IsLikelyNoopActionId(candidateAction) == true) then
            return false;
        end
        local resourceMethodOk, resource = pcall(function()
            return ResolveActionResource(candidateCategory, candidateAction, true, true);
        end);

        return (resourceMethodOk == true and resource ~= nil);
    end

    if (trackedCategories[categoryNumber] == true or (categoryNumber >= 3 and categoryNumber <= 31)) then
        if (HasResourceForPacket(categoryNumber, actionIdNumber) == true) then
            return categoryNumber, actionIdNumber;
        end

        DebugLog('action-range header parse no resource category=' .. tostring(categoryNumber) .. ' action=' .. tostring(actionIdNumber) .. ' rescanning');
    end

    return ScanActionCandidates(data, packetSize, true);
end

local function ParseActionPacket(e)
    if (e == nil or e.id == nil) then
        return nil, nil;
    end

    if (tonumber(e.id) == 0x015) then
        return ParseOutActionLoosePacket(e);
    end

    if (e.id == 0x01A) then
        return ParseOutActionPacket(e);
    end

    if (e.id == 0x1A2) then
        return ParseOutActionLoosePacket(e);
    end

    if ((e.id == 0x61) or (e.id == 0xC0)) then
        return ParseOutActionChunkPacket(e);
    end

    return nil, nil;
end

local function ApplyQueuedAction(category, actionId, source, displayName)
    category = tonumber(category);
    actionId = tonumber(actionId);
    local now = os.clock();

    if (actionId == nil or actionId <= 0) then
        if (source ~= 'command') then
            DebugLog('action-range queue cleared category=' .. tostring(category) .. ' actionId=' .. tostring(actionId));
        end
        ClearQueuedActionForContextChange();
        return false;
    end

    local range = ResolveActionRange(category, actionId);
    if (trackedCategories[category] ~= true and range == nil) then
        if (IsDebugEnabled() == true) then
            DebugLog('action-range ignored category=' .. tostring(category) .. ' actionId=' .. tostring(actionId) .. ' range=' .. tostring(range));
        end
        return false;
    end

    if (
        lastQueuedPacketSignature ~= nil and
        lastQueuedPacketSignature.category == category and
        lastQueuedPacketSignature.action == actionId and
        (now - lastQueuedPacketAt) < queuedPacketDedupeSeconds
    ) then
        return false;
    end

    if (
        source == 'packet' and
        lastCommandQueuedAt ~= nil and
        (now - lastCommandQueuedAt) <= commandOverrideWindowSeconds and
        (
            lastCommandQueuedSignature == nil or
            lastCommandQueuedSignature.category ~= category or
            lastCommandQueuedSignature.action ~= actionId
        )
    ) then
        if (IsDebugEnabled() == true) then
            DebugLog('action-range packet ignored while command queue window active category=' .. tostring(category) .. ' action=' .. tostring(actionId));
        end
        return false;
    end

    local queuedResource = nil;
    local queuedMethod = nil;
    local queuedResolvedId = nil;
    local resolvedOk = pcall(function()
        queuedResource, queuedMethod, queuedResolvedId = ResolveActionResource(category, actionId);
    end);
    local queuedType = 'action';
    if (queuedMethod == 'GetAbilityById' or queuedMethod == 'GetAbilityByTimerId') then
        queuedType = 'ability';
    elseif (queuedMethod == 'GetSpellById') then
        queuedType = 'spell';
    elseif (queuedMethod == 'GetWeaponSkillById') then
        queuedType = 'weaponskill';
    elseif (queuedMethod == 'GetMobSkillById') then
        queuedType = 'mobskill';
    elseif (queuedMethod == 'GetItemById') then
        queuedType = 'item';
    elseif (queuedMethod == 'PetCommand' or category == petCommandCategory) then
        queuedType = 'petcommand';
    elseif (category == 3) then
        queuedType = 'spell';
    elseif (category == 2 or category == 7 or category == 9 or category == 16) then
        queuedType = 'ability';
    end
    local queuedName = GetQueuedActionName(
        (resolvedOk == true and queuedResource or nil),
        category,
        actionId,
        queuedResolvedId
    );
    if (queuedName == nil) then
        queuedName = tostring(displayName or '');
    end

    if (
        (queuedName == nil or queuedName == '') or
        tostring(queuedName):find('actionId') ~= nil
    ) then
        queuedName = 'actionId ' .. tostring(actionId);
    end

    UpdateQueuedActionText(queuedName, source);

    lastAction = {
        category = category,
        id = actionId,
        range = range,
        name = queuedName,
        resource = resolvedOk == true and queuedResource or nil,
        resourceMethod = queuedMethod,
        resolvedId = queuedResolvedId,
        updated = os.clock(),
    };
    recentAction = lastAction;
    lastQueuedPacketSignature = {
        category = category,
        action = actionId,
    };
    lastQueuedPacketAt = now;

    if (IsDebugEnabled() == true) then
        DebugLog(tostring(queuedName) .. ' is now queued');
        DebugLog('cast queue source=' .. tostring(source) .. ' category=' .. tostring(category) .. ' id=' .. tostring(actionId));
    end

    if (source == 'command') then
        lastCommandQueuedAt = now;
        lastCommandQueuedSignature = {
            category = category,
            action = actionId,
        };
    end

    return true;
end

function targetActionRange.HandleActionCommand(commandText)
    local normalized = NormalizeCommandText(commandText);

    if (IsLikelyDuplicateCommand(normalized) == true) then
        return true;
    end

    local parsedCategory, parsedActionName, parsedActionDisplay = ParseActionCommand(commandText);
    if (parsedCategory == nil or parsedActionName == nil) then
        if (IsDebugEnabled() == true) then
            local text = tostring(commandText or ''):lower():gsub('^%s*', '');
            local check = text:gsub('^/', '', 1);
            local token = tostring(check:match('^(%S+)') or '');

            if (
                token == 'ma' or token == 'magic' or token:match('^m%d+$') ~= nil or
                token == 'so' or token == 'nin' or
                token == 'ja' or token == 'jobability' or token == 'pet' or
                token == 'ws' or token == 'weaponskill' or
                token == 'ra' or token == 'ranged' or
                token == 'range' or token == 'shoot' or token == 'throw'
            ) then
                DebugLog('cast debug command parse failed=' .. tostring(commandText));
            end
        end
        return false;
    end

    local ok, actionId, actionMethod = pcall(ResolveActionIdByName, parsedCategory, parsedActionName);
    if (ok ~= true) then
        if (IsDebugEnabled() == true) then
            DebugLog('cast queue command resolve failed=' .. tostring(commandText) .. ' err=' .. tostring(actionId));
        end
        return false;
    end

    local category = parsedCategory;
    if (actionId == nil) then
        if (IsDebugEnabled() == true) then
            local commandName = tostring(parsedActionDisplay or parsedActionName or '');
            UpdateQueuedActionText(commandName .. ' (command)', 'command');
            DebugLog('cast queue command not resolved=' .. tostring(commandText));
            DebugLog(tostring(commandName) .. ' is now queued');
            DebugLog('cast queue source=command category=' .. tostring(parsedCategory) .. ' name=' .. tostring(commandName));
        end
        return false;
    end

    return ApplyQueuedAction(category, actionId, 'command', parsedActionDisplay);
end

function targetActionRange.ProbeCommandText(commandText)
    local parsedCategory, parsedActionName, parsedActionDisplay = ParseActionCommand(commandText);

    if (parsedCategory == nil or parsedActionName == nil) then
        return 'cast range probe: could not parse action command=' .. tostring(commandText or '');
    end

    local ok, actionId, actionMethod = pcall(ResolveActionIdByName, parsedCategory, parsedActionName);
    if (ok ~= true) then
        return 'cast range probe: resolve error command=' .. tostring(commandText or '') .. ' err=' .. tostring(actionId);
    end

    if (actionId == nil) then
        return
            'cast range probe: action not found name=' .. tostring(parsedActionDisplay or parsedActionName) ..
            ' category=' .. tostring(categoryNames[parsedCategory] or parsedCategory) ..
            ' samples=' .. tostring(targetActionRange.GetResourceNameSamples(parsedCategory, 12));
    end

    local resource, resourceMethod, resolvedId = ResolveActionResource(parsedCategory, actionId);
    local range = ResolveActionRange(parsedCategory, actionId);
    local displayName = GetQueuedActionName(resource, parsedCategory, actionId, resolvedId) or parsedActionDisplay or parsedActionName;

    return
        'cast range probe: name=' .. tostring(displayName) ..
        ' category=' .. tostring(categoryNames[parsedCategory] or parsedCategory) ..
        ' id=' .. tostring(actionId) ..
        ' commandMethod=' .. tostring(actionMethod or 'unknown') ..
        ' resourceMethod=' .. tostring(resourceMethod or 'none') ..
        ' resolvedId=' .. tostring(resolvedId or actionId) ..
        ' range=' .. tostring(range or 'nil') ..
        ' hints=' .. tostring(DescribeResourceRangeHints(resource));
end

function targetActionRange.GetResourceNameSamples(category, count)
    local resourceManager = GetResourceManager();
    local normalizedCategory = tonumber(category) or 0;
    local maxCount = math.max(1, math.min(40, tonumber(count) or 12));

    if (resourceManager == nil) then
        return 'no resource manager';
    end

    local methodsByCategory = {
        [2] = { 'GetAbilityById' },
        [3] = { 'GetSpellById' },
        [7] = { 'GetWeaponSkillById' },
        [9] = { 'GetAbilityById' },
        [16] = { 'GetAbilityById' },
    };
    local methods = methodsByCategory[normalizedCategory] or { 'GetSpellById', 'GetAbilityById' };
    local samples = {};

    for _, methodName in ipairs(methods) do
        local method = resourceManager[methodName];
        if (type(method) == 'function') then
            local found = 0;

            for id = 1, 256 do
                local record = SafeCall(nil, function()
                    return method(resourceManager, id);
                end);
                local name = ReadRecordDisplayName(record);

                if (name ~= nil and tostring(name) ~= '') then
                    samples[#samples + 1] = methodName .. '[' .. tostring(id) .. ']=' .. tostring(name);
                    found = found + 1;

                    if (found >= maxCount) then
                        break;
                    end
                end
            end
        else
            samples[#samples + 1] = methodName .. '=missing';
        end
    end

    if (#samples == 0) then
        return 'none';
    end

    return table.concat(samples, ' | ');
end

function targetActionRange.HandleCommandText(commandText)
    return targetActionRange.HandleActionCommand(commandText);
end

local function IsSelfActionResultPacket(e)
    if (e == nil or e.id ~= 0x028) then
        return false;
    end

    local memory = AshitaCore:GetMemoryManager();
    local party = memory and memory:GetParty();
    local actorId = party and party:GetMemberServerId(0);
    local sourceId = Read(e.data, 'L', 0x04);

    if (actorId == nil or sourceId == nil) then
        return false;
    end

    return sourceId == actorId;
end

function targetActionRange.HandlePacketOut(e)
    if (e == nil) then
        return;
    end

    local packetId = tonumber(e.id) or -1;
    if (actionPacketIds[packetId] ~= true) then
        return;
    end

    local category, actionId = ParseActionPacket(e);

    DebugLogPacket(e, category, actionId);

    if (category == nil or actionId == nil) then
        return;
    end

    ApplyQueuedAction(category, actionId, 'packet');
end

function targetActionRange.HandlePacketIn(e)
    if (IsSelfActionResultPacket(e) == true) then
        if (lastAction ~= nil) then
            DebugLog('action-range cleared after action result ' .. FormatAction(lastAction));
        end
        lastAction = nil;
    end
end

function targetActionRange.GetCurrentAction()
    return lastAction;
end

function targetActionRange.GetRecentAction()
    if (recentAction == nil) then
        return nil;
    end

    local updated = tonumber(recentAction.updated) or 0;
    if (updated > 0 and (os.clock() - updated) > 10.0) then
        recentAction = nil;
        return nil;
    end

    return recentAction;
end

function targetActionRange.GetCurrentRange()
    if (lastAction == nil) then
        return nil;
    end

    local updated = tonumber(lastAction.updated) or 0;
    if (tonumber(actionCacheSeconds) ~= nil and updated > 0 and (os.clock() - updated) > tonumber(actionCacheSeconds)) then
        lastAction = nil;
        return nil;
    end

    return tonumber(lastAction.range);
end

function targetActionRange.Clear()
    ClearQueuedActionForContextChange();
    debugUntil = nil;
end

function targetActionRange.SetDebugEnabled(enabled)
    debugEnabled = (enabled == true);
    if (debugEnabled ~= true) then
        debugUntil = nil;
    end
end

function targetActionRange.SetPacketDebugEnabled(enabled)
    debugPacketOutEnabled = (enabled == true);
end

function targetActionRange.EnableDebugForSeconds(seconds)
    local secondsNumber = tonumber(seconds) or 0;

    if (secondsNumber > 0) then
        debugUntil = os.clock() + secondsNumber;
        debugEnabled = false;
        debugPacketOutEnabled = false;
    else
        debugUntil = nil;
        debugEnabled = false;
        debugPacketOutEnabled = false;
    end
end

function targetActionRange.EnablePacketDebugForSeconds(seconds)
    local secondsNumber = tonumber(seconds) or 0;

    if (secondsNumber > 0) then
        debugUntil = os.clock() + secondsNumber;
        debugEnabled = false;
        debugPacketOutEnabled = true;
    else
        debugUntil = nil;
        debugEnabled = false;
        debugPacketOutEnabled = false;
    end
end

function targetActionRange.GetDebugEnabled()
    return IsDebugEnabled();
end

function targetActionRange.GetPacketDebugEnabled()
    return IsPacketDebugEnabled();
end

function targetActionRange.GetDebugRemaining()
    if (debugUntil == nil) then
        return 0;
    end

    local remaining = tonumber(debugUntil) - os.clock();
    if (remaining < 0) then
        return 0;
    end

    return remaining;
end

function targetActionRange.GetDebugText()
    if (lastAction == nil) then
        return 'target action range: none remaining=' .. tostring(targetActionRange.GetDebugRemaining());
    end

    return 'target action range: ' .. FormatAction(lastAction) .. ' remaining=' .. tostring(targetActionRange.GetDebugRemaining());
end

function targetActionRange.GetQueuedActionText()
    if (lastQueuedActionName == nil) then
        return 'cast queue: none';
    end

    return 'cast queue: ' .. tostring(lastQueuedActionName) .. ' source=' .. tostring(lastQueuedActionSource or 'unknown');
end

return targetActionRange;
