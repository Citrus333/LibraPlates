local state = require('core.state');
local log = require('core.log');

local playerBlacklist = {};

local function NormalizeName(name)
    local text = tostring(name or ''):gsub('^%s+', ''):gsub('%s+$', '');

    return text:lower();
end

local function ServerIdKey(serverId)
    local id = tonumber(serverId) or 0;

    if (id <= 0) then
        return nil;
    end

    return tostring(math.floor(id));
end

local function Now()
    return os.time();
end

local function EnsureStore()
    return state.GetVisualBlacklist();
end

local defaultFixedFomorModels = {
    hume = 1012,
    elvaan = 1022,
    tarutaru = 1026,
    mithra = 1032,
    galka = 1038,
};
local defaultForcedFomorRace = 7;
local defaultForcedFomorHair = 5;

local function GetName(player)
    return tostring(player ~= nil and (player.name or player.clickName) or ''):gsub('^%s+', ''):gsub('%s+$', '');
end

local function PromotePending(player)
    local name = GetName(player);
    local key = NormalizeName(name);
    local idKey = ServerIdKey(player ~= nil and player.serverId);

    if (key == '' or idKey == nil) then
        return nil;
    end

    local store = EnsureStore();
    local pending = store.pendingNames[key];

    if (pending == nil) then
        return store.entries[idKey];
    end

    local existing = store.entries[idKey] or {};
    existing.name = name ~= '' and name or existing.name or pending.name;
    existing.reason = existing.reason or pending.reason or '';
    existing.displayName = existing.displayName or pending.displayName or '';
    existing.addedAt = existing.addedAt or pending.addedAt or Now();
    existing.lastSeenAt = Now();
    existing.source = existing.source or pending.source or 'manual';
    existing.pendingName = nil;
    store.entries[idKey] = existing;
    store.pendingNames[key] = nil;
    state.SaveThrottled(0.25);

    return existing;
end

function playerBlacklist.AddPlayer(player, reason, source, displayName)
    local name = GetName(player);
    local displayNameValue = tostring(displayName or ''):gsub('^%s+', ''):gsub('%s+$', '');
    local idKey = ServerIdKey(player ~= nil and player.serverId);
    local entry = {
        name = name,
        reason = tostring(reason or ''):gsub('^%s+', ''):gsub('%s+$', ''),
        displayName = displayNameValue,
        addedAt = Now(),
        lastSeenAt = Now(),
        source = tostring(source or 'manual'),
    };
    local store = EnsureStore();

    if (idKey ~= nil) then
        local existing = store.entries[idKey] or {};
        existing.name = name ~= '' and name or existing.name;
        if (entry.reason ~= '' or existing.reason == nil) then
            existing.reason = entry.reason;
        end
        if (entry.displayName ~= '' or existing.displayName == nil) then
            existing.displayName = entry.displayName;
        end
        existing.addedAt = existing.addedAt or entry.addedAt;
        existing.lastSeenAt = entry.lastSeenAt;
        existing.source = entry.source;
        store.entries[idKey] = existing;
        state.Save();
        return true, existing;
    end

    local nameKey = NormalizeName(name);

    if (nameKey == '') then
        return false, 'Missing player name.';
    end

    entry.pendingName = true;
    if (store.pendingNames[nameKey] ~= nil and entry.reason == '') then
        local existing = store.pendingNames[nameKey];
        existing.name = entry.name;
        existing.addedAt = existing.addedAt or entry.addedAt;
        existing.lastSeenAt = entry.lastSeenAt;
        existing.source = entry.source;
    else
        store.pendingNames[nameKey] = entry;
    end
    state.Save();

    return true, entry;
end

local function FindNearbyPlayerByName(name)
    local nameKey = NormalizeName(name);

    if (nameKey == '') then
        return nil;
    end

    local ok, entities = pcall(require, 'core.entities');

    if (ok ~= true or entities == nil or entities.GetNearbyPlayers == nil) then
        return nil;
    end

    local players = entities.GetNearbyPlayers(64.4) or {};

    for _, player in ipairs(players) do
        if (NormalizeName(player ~= nil and player.name or '') == nameKey) then
            return player;
        end
    end

    return nil;
end

local function GetPlayerFromTargetIndex(index)
    index = tonumber(index);

    if (index == nil or index <= 0) then
        return nil;
    end

    local ok, entities = pcall(require, 'core.entities');

    if (ok ~= true or entities == nil or entities.GetEntity == nil or entities.GetEntityManager == nil) then
        return nil;
    end

    local entity = entities.GetEntity(index);
    local name = tostring(entity ~= nil and entity.Name or ''):gsub('^%s+', ''):gsub('%s+$', '');

    if (name == '') then
        return nil;
    end

    local entityManager = entities.GetEntityManager();
    local okServerId, serverId = pcall(function()
        return entityManager:GetServerId(index);
    end);

    return {
        index = index,
        name = name,
        serverId = okServerId == true and serverId or nil,
    };
end

local function ResolvePlayerToken(name)
    local token = NormalizeName(name);

    if (token ~= '<t>' and token ~= '<target>' and token ~= '<st>' and token ~= '<stpc>' and token ~= '<subtarget>') then
        return nil;
    end

    local ok, targeting = pcall(require, 'core.targeting');

    if (ok ~= true or targeting == nil) then
        return nil;
    end

    if (token == '<t>' or token == '<target>') then
        return GetPlayerFromTargetIndex(targeting.GetCurrentTargetIndex());
    end

    return GetPlayerFromTargetIndex(targeting.GetCurrentSubTargetIndex());
end

function playerBlacklist.AddName(name, reason, source, displayName)
    local found = ResolvePlayerToken(name) or FindNearbyPlayerByName(name);

    if (found ~= nil) then
        return playerBlacklist.AddPlayer(found, reason, source or 'command', displayName);
    end

    return playerBlacklist.AddPlayer({ name = name }, reason, source or 'command', displayName);
end

function playerBlacklist.RemovePlayer(playerOrName)
    local store = EnsureStore();
    local idKey = ServerIdKey(type(playerOrName) == 'table' and playerOrName.serverId or nil);
    local name = type(playerOrName) == 'table' and GetName(playerOrName) or tostring(playerOrName or '');
    local nameKey = NormalizeName(name);
    local removed = false;

    if (idKey ~= nil and store.entries[idKey] ~= nil) then
        store.entries[idKey] = nil;
        removed = true;
    end

    if (nameKey ~= '' and store.pendingNames[nameKey] ~= nil) then
        store.pendingNames[nameKey] = nil;
        removed = true;
    end

    if (nameKey ~= '') then
        for key, entry in pairs(store.entries) do
            if (NormalizeName(entry ~= nil and entry.name or '') == nameKey) then
                store.entries[key] = nil;
                removed = true;
            end
        end
    end

    if (removed == true) then
        state.Save();
    end

    return removed;
end

function playerBlacklist.RemoveName(name)
    local found = ResolvePlayerToken(name) or FindNearbyPlayerByName(name);

    if (found ~= nil) then
        return playerBlacklist.RemovePlayer(found);
    end

    return playerBlacklist.RemovePlayer(name);
end

function playerBlacklist.RemoveEntry(row)
    if (type(row) ~= 'table') then
        return false;
    end

    local store = EnsureStore();

    if (row.serverId ~= nil) then
        local idKey = ServerIdKey(row.serverId) or tostring(row.key or '');

        if (idKey ~= '' and store.entries[idKey] ~= nil) then
            store.entries[idKey] = nil;
            state.Save();
            return true;
        end
    end

    local pendingKey = NormalizeName(row.key or row.name);

    if (pendingKey ~= '' and store.pendingNames[pendingKey] ~= nil) then
        store.pendingNames[pendingKey] = nil;
        state.Save();
        return true;
    end

    return playerBlacklist.RemoveName(row.name);
end

function playerBlacklist.SetReason(row, reason)
    if (type(row) ~= 'table') then
        return false;
    end

    local store = EnsureStore();
    local value = tostring(reason or ''):gsub('^%s+', ''):gsub('%s+$', '');

    if (row.serverId ~= nil) then
        local idKey = ServerIdKey(row.serverId);

        if (idKey ~= nil and store.entries[idKey] ~= nil) then
            store.entries[idKey].reason = value;
            state.SaveThrottled(0.50);
            return true;
        end
    end

    local nameKey = NormalizeName(row.name);

    if (nameKey ~= '' and store.pendingNames[nameKey] ~= nil) then
        store.pendingNames[nameKey].reason = value;
        state.SaveThrottled(0.50);
        return true;
    end

    return false;
end

function playerBlacklist.SetDisplayName(row, displayName)
    if (type(row) ~= 'table') then
        return false;
    end

    local store = EnsureStore();
    local value = tostring(displayName or ''):gsub('^%s+', ''):gsub('%s+$', '');

    if (row.serverId ~= nil) then
        local idKey = ServerIdKey(row.serverId);

        if (idKey ~= nil and store.entries[idKey] ~= nil) then
            store.entries[idKey].displayName = value;
            state.SaveThrottled(0.50);
            return true;
        end
    end

    local nameKey = NormalizeName(row.name);

    if (nameKey ~= '' and store.pendingNames[nameKey] ~= nil) then
        store.pendingNames[nameKey].displayName = value;
        state.SaveThrottled(0.50);
        return true;
    end

    return false;
end

function playerBlacklist.GetEntry(player)
    local idKey = ServerIdKey(player ~= nil and player.serverId);
    local nameKey = NormalizeName(GetName(player));
    local store = EnsureStore();

    PromotePending(player);

    if (idKey ~= nil and store.entries[idKey] ~= nil) then
        local entry = store.entries[idKey];
        entry.lastSeenAt = Now();
        if (GetName(player) ~= '' and entry.name ~= GetName(player)) then
            entry.name = GetName(player);
        end
        state.SaveThrottled(2.0);
        return entry, idKey;
    end

    if (nameKey ~= '' and store.pendingNames[nameKey] ~= nil) then
        return store.pendingNames[nameKey], nil;
    end

    return nil, nil;
end

function playerBlacklist.IsListed(player)
    return playerBlacklist.GetEntry(player) ~= nil;
end

function playerBlacklist.GetDisplayName(player, fallback)
    local store = EnsureStore();

    if (store.displayNameReplaceEnabled == nil) then
        store.displayNameReplaceEnabled = true;
    end

    local entry = playerBlacklist.GetEntry(player);

    if (store.displayNameReplaceEnabled == true and entry ~= nil) then
        local displayName = tostring(entry.displayName or ''):gsub('^%s+', ''):gsub('%s+$', '');
        return displayName ~= '' and displayName or 'Blacklisted';
    end

    return fallback;
end

function playerBlacklist.GetDisplayNameColor(player, fallback)
    local store = EnsureStore();

    if (type(store.displayNameColor) ~= 'table') then
        store.displayNameColor = { 1.0, 0.22, 0.22, 1.0 };
    end

    if (playerBlacklist.IsListed(player) == true) then
        return store.displayNameColor;
    end

    return fallback;
end

function playerBlacklist.GetSignature(player)
    local entry, idKey = playerBlacklist.GetEntry(player);
    local store = EnsureStore();

    if (entry == nil) then
        return 'bl=0';
    end

    if (type(store.displayNameColor) ~= 'table') then
        store.displayNameColor = { 1.0, 0.22, 0.22, 1.0 };
    end

    return table.concat({
        'bl=1',
        'id=' .. tostring(idKey or ''),
        'name=' .. tostring(entry.name or ''),
        'reason=' .. tostring(entry.reason or ''),
        'customName=' .. tostring(entry.displayName or ''),
        'displayName=' .. tostring(store.displayNameReplaceEnabled ~= false),
        'displayColor=' .. table.concat({
            tostring(store.displayNameColor[1] or ''),
            tostring(store.displayNameColor[2] or ''),
            tostring(store.displayNameColor[3] or ''),
            tostring(store.displayNameColor[4] or ''),
        }, ','),
    }, ';');
end

function playerBlacklist.GetModelReplaceSettings()
    local store = EnsureStore();

    if (store.modelReplaceEnabled == nil) then
        store.modelReplaceEnabled = true;
    end

    store.modelReplaceRace = tonumber(store.modelReplaceRace) or defaultForcedFomorRace;
    store.modelReplaceHair = tonumber(store.modelReplaceHair) or defaultForcedFomorHair;
    if (store.modelReplacePreserveRace == nil) then
        store.modelReplacePreserveRace = false;
    elseif (store.modelReplacePreserveRace == true and store.modelReplaceRace == 5 and store.modelReplaceHair == 2) then
        store.modelReplacePreserveRace = false;
        store.modelReplaceRace = defaultForcedFomorRace;
        store.modelReplaceHair = defaultForcedFomorHair;
    end
    if (store.modelReplaceClearGear == nil) then
        store.modelReplaceClearGear = true;
    end
    if (store.modelReplaceUseFomor == nil) then
        store.modelReplaceUseFomor = true;
    end
    if (store.displayNameReplaceEnabled == nil) then
        store.displayNameReplaceEnabled = true;
    end
    if (type(store.displayNameColor) ~= 'table') then
        store.displayNameColor = { 1.0, 0.22, 0.22, 1.0 };
    end
    store.modelReplaceUseCostume = false;
    store.modelReplaceCostumeId = tonumber(store.modelReplaceCostumeId) or 0;
    store.modelReplaceUseNpcCostume = false;
    if (store.modelReplaceNpcCostumeByRace == nil) then
        store.modelReplaceNpcCostumeByRace = false;
    end
    store.modelReplaceNpcCostumeId = tonumber(store.modelReplaceNpcCostumeId) or 0;
    if (type(store.modelReplaceCapturedFomorModels) ~= 'table') then
        store.modelReplaceCapturedFomorModels = {};
    end
    if (type(store.modelReplaceFixedFomorModels) ~= 'table') then
        store.modelReplaceFixedFomorModels = {};
    end
    store.modelReplacePacketCache = {};
    for family, modelId in pairs(defaultFixedFomorModels) do
        if ((tonumber(store.modelReplaceFixedFomorModels[family]) or 0) <= 0) then
            store.modelReplaceFixedFomorModels[family] = modelId;
        end
    end

    return store;
end

function playerBlacklist.List()
    local store = EnsureStore();
    local rows = {};

    for id, entry in pairs(store.entries) do
        rows[#rows + 1] = {
            key = tostring(id),
            serverId = tonumber(id) or id,
            name = entry.name or '',
            reason = entry.reason or '',
            displayName = entry.displayName or '',
            addedAt = entry.addedAt,
            lastSeenAt = entry.lastSeenAt,
            source = entry.source,
            pendingName = false,
        };
    end

    for key, entry in pairs(store.pendingNames) do
        rows[#rows + 1] = {
            key = tostring(key or ''),
            serverId = nil,
            name = entry.name or '',
            reason = entry.reason or '',
            displayName = entry.displayName or '',
            addedAt = entry.addedAt,
            lastSeenAt = entry.lastSeenAt,
            source = entry.source,
            pendingName = true,
        };
    end

    table.sort(rows, function(left, right)
        return tostring(left.name or ''):lower() < tostring(right.name or ''):lower();
    end);

    return rows;
end

local function ParseCommandText(commandText)
    local text = tostring(commandText or ''):gsub('^%s+', ''):gsub('%s+$', '');
    local command, rest = text:match('^(%S+)%s*(.-)$');

    command = tostring(command or ''):lower();

    if (
        command ~= '/blacklist' and
        command ~= '/blist' and
        command ~= '/blias'
    ) then
        return nil;
    end

    local action, tail = tostring(rest or ''):match('^(%S+)%s*(.-)$');
    action = tostring(action or ''):lower();
    tail = tostring(tail or ''):gsub('^%s+', ''):gsub('%s+$', '');

    local name, reason = tail:match('^"([^"]+)"%s*(.-)$');

    if (name == nil) then
        name, reason = tail:match("^[']([^']+)[']%s*(.-)$");
    end

    if (name == nil) then
        name, reason = tail:match('^(%S+)%s*(.-)$');
    end

    if (name == nil or tostring(name or '') == '') then
        return nil;
    end

    return action, name, tostring(reason or ''):gsub('^%s+', ''):gsub('%s+$', '');
end

function playerBlacklist.HandleCommandText(commandText)
    local action, name, reason = ParseCommandText(commandText);

    if (action == nil) then
        return false;
    end

    if (action == 'add' or action == 'insert') then
        local ok, err = playerBlacklist.AddName(name, reason, 'native-command');
        if (ok == true) then
            log.Info('Mirrored native blacklist add: ' .. tostring(name));
        else
            log.Warn(tostring(err or ('Could not mirror blacklist add: ' .. tostring(name))));
        end
        return ok == true;
    elseif (
        action == 'delete' or
        action == 'del' or
        action == 'remove' or
        action == 'rm'
    ) then
        if (playerBlacklist.RemoveName(name) == true) then
            log.Info('Mirrored native blacklist remove: ' .. tostring(name));
            return true;
        end
        log.Info('Native blacklist remove already clear locally: ' .. tostring(name));
        return false;
    end

    return false;
end

return playerBlacklist;
