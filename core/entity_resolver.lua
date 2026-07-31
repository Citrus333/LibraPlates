local bit = require('bit');

local entityResolver = {};
local serverToIndex = {};
local indexToServer = {};
local lastFullScan = -1000;
local fullScanIntervalSeconds = 0.25;
local fullScanCount = 0;
local cacheHitCount = 0;

local function SafeCall(fallback, callback)
    local ok, result = pcall(callback);

    if (ok ~= true or result == nil) then
        return fallback;
    end

    return result;
end

local function GetEntityManager()
    local memory = SafeCall(nil, function()
        return AshitaCore:GetMemoryManager();
    end);

    return memory ~= nil and SafeCall(nil, function()
        return memory:GetEntity();
    end) or nil;
end

local function ReadServerId(entityManager, index)
    index = tonumber(index) or 0;

    if (entityManager == nil or index <= 0 or index > 0x8FF) then
        return 0;
    end

    return tonumber(SafeCall(0, function()
        return entityManager:GetServerId(index);
    end)) or 0;
end

local function Remember(index, serverId)
    index = tonumber(index) or 0;
    serverId = tonumber(serverId) or 0;

    if (index <= 0 or serverId <= 0) then
        return;
    end

    local previousServerId = indexToServer[index];
    if (previousServerId ~= nil and previousServerId ~= serverId) then
        serverToIndex[previousServerId] = nil;
    end

    indexToServer[index] = serverId;
    serverToIndex[serverId] = index;
end

local function TryDerivedIndex(entityManager, serverId)
    local index = bit.band(serverId, 0xFFF);

    if (index >= 0x900) then
        index = index - 0x100;
    end

    if (index > 0 and index <= 0x8FF and ReadServerId(entityManager, index) == serverId) then
        Remember(index, serverId);
        return index;
    end

    return 0;
end

local function Rebuild(entityManager)
    local newServerToIndex = {};
    local newIndexToServer = {};

    for index = 1, 0x8FF do
        local serverId = ReadServerId(entityManager, index);

        if (serverId > 0) then
            newServerToIndex[serverId] = index;
            newIndexToServer[index] = serverId;
        end
    end

    serverToIndex = newServerToIndex;
    indexToServer = newIndexToServer;
    lastFullScan = os.clock();
    fullScanCount = fullScanCount + 1;
end

function entityResolver.GetIndex(serverId)
    serverId = tonumber(serverId) or 0;

    if (serverId <= 0) then
        return 0;
    end

    local entityManager = GetEntityManager();

    if (entityManager == nil) then
        return 0;
    end

    local cachedIndex = tonumber(serverToIndex[serverId]) or 0;

    if (cachedIndex > 0 and ReadServerId(entityManager, cachedIndex) == serverId) then
        cacheHitCount = cacheHitCount + 1;
        return cachedIndex;
    end

    if (cachedIndex > 0) then
        serverToIndex[serverId] = nil;
        indexToServer[cachedIndex] = nil;
    end

    local derivedIndex = TryDerivedIndex(entityManager, serverId);
    if (derivedIndex > 0) then
        return derivedIndex;
    end

    if ((os.clock() - lastFullScan) >= fullScanIntervalSeconds) then
        Rebuild(entityManager);
    end

    return tonumber(serverToIndex[serverId]) or 0;
end

function entityResolver.GetServerId(index)
    index = tonumber(index) or 0;

    if (index <= 0 or index > 0x8FF) then
        return 0;
    end

    local entityManager = GetEntityManager();

    if (entityManager == nil) then
        return 0;
    end

    local serverId = ReadServerId(entityManager, index);

    if (serverId > 0) then
        Remember(index, serverId);
    elseif (indexToServer[index] ~= nil) then
        serverToIndex[indexToServer[index]] = nil;
        indexToServer[index] = nil;
    end

    return serverId;
end

function entityResolver.Reset()
    serverToIndex = {};
    indexToServer = {};
    lastFullScan = -1000;
end

function entityResolver.GetStats()
    local count = 0;

    for _ in pairs(serverToIndex) do
        count = count + 1;
    end

    return {
        entries = count,
        fullScans = fullScanCount,
        cacheHits = cacheHitCount,
    };
end

return entityResolver;
