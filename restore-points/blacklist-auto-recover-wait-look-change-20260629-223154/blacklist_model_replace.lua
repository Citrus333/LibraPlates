local playerBlacklist = require('core.player_blacklist');
local state = require('core.state');
local log = require('core.log');

local blacklistModelReplace = {};
local loggedServerIds = {};
local debugEnabled = false;
local debugPacketCount = 0;
local fomorProbeEnabled = false;
local fomorProbePacketCount = 0;
local fomorProbeLoggedIndexes = {};
local fomorProbeTargetIndex = nil;
local fomorProbeCache = {};
local pendingClearNames = {};
local pendingClearIds = {};
local pendingClearAllUntil = 0;
local lastRefreshStatus = 'none';
local cachedPlayerPacketsByName = {};
local cachedPlayerPacketsById = {};
local incomingReplayWarned = false;
local pendingCostumeApplies = {};
local pendingLookApplies = {};
local pendingBlacklistRecoveries = {};
local suppressBlacklistRecoveryWrites = {};
local stableBlacklistRecoveredActors = {};
local costumeWatch = nil;
local blacklistWatch = nil;
local fomorModels = {
    hume = { 0x05, 0x01, 0xFA, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 },
    elvaan = { 0x05, 0x03, 0xFF, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 },
    tarutaru = { 0x05, 0x05, 0x03, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 },
    mithra = { 0x05, 0x07, 0x09, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 },
    galka = { 0x05, 0x08, 0x0F, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 },
};
local raceFamilyAliases = {
    hume = { race = 1, family = 'hume' },
    h = { race = 1, family = 'hume' },
    elvaan = { race = 3, family = 'elvaan' },
    elv = { race = 3, family = 'elvaan' },
    e = { race = 3, family = 'elvaan' },
    tarutaru = { race = 5, family = 'tarutaru' },
    taru = { race = 5, family = 'tarutaru' },
    t = { race = 5, family = 'tarutaru' },
    mithra = { race = 7, family = 'mithra' },
    mith = { race = 7, family = 'mithra' },
    m = { race = 7, family = 'mithra' },
    galka = { race = 8, family = 'galka' },
    g = { race = 8, family = 'galka' },
};

local function FormatHex(value)
    return '0x' .. string.format('%X', tonumber(value) or 0);
end

local function GetFfi()
    if (_G.ffi ~= nil) then
        return _G.ffi;
    end

    local ok, loaded = pcall(require, 'ffi');

    if (ok == true) then
        return loaded;
    end

    return nil;
end

local function ClampByte(value, fallback)
    local number = math.floor(tonumber(value) or fallback or 0);

    if (number < 0) then
        return 0;
    end

    if (number > 255) then
        return 255;
    end

    return number;
end

local function ResolveReplacementRace(value)
    local text = tostring(value or ''):lower():gsub('^%s+', ''):gsub('%s+$', '');
    local alias = raceFamilyAliases[text];

    if (alias ~= nil) then
        return alias.race, alias.family;
    end

    local number = math.floor(tonumber(value) or 0);

    if (number < 1 or number > 8) then
        return nil, nil;
    end

    return number, nil;
end

local function HasFlag(value, flag)
    value = math.floor(tonumber(value) or 0);
    flag = math.floor(tonumber(flag) or 0);

    if (flag <= 0) then
        return false;
    end

    return (math.floor(value / flag) % 2) == 1;
end

local function ReadServerId(ffiRef, packet)
    local ok, value = pcall(function()
        return tonumber(ffiRef.cast('uint32_t*', packet + 0x04)[0]) or 0;
    end);

    if (ok ~= true) then
        return 0;
    end

    return value;
end

local function ReadActIndex(ffiRef, packet)
    local ok, value = pcall(function()
        return tonumber(ffiRef.cast('uint16_t*', packet + 0x08)[0]) or 0;
    end);

    if (ok ~= true) then
        return 0;
    end

    return value;
end

local function ReadName(ffiRef, packet)
    local ok, value = pcall(function()
        return ffiRef.string(packet + 0x5A, 16);
    end);

    if (ok ~= true) then
        return '';
    end

    return tostring(value or ''):gsub('%z.*$', ''):gsub('^%s+', ''):gsub('%s+$', '');
end

local function ReadModelWord(ffiRef, packet, slot)
    local ok, value = pcall(function()
        return tonumber(ffiRef.cast('uint16_t*', packet + 0x48)[slot]) or 0;
    end);

    if (ok ~= true) then
        return 0;
    end

    return value;
end

local function ReadModelWordFromBytes(bytes, slot)
    if (type(bytes) ~= 'table') then
        return 0;
    end

    local offset = 3 + ((math.max(1, math.floor(tonumber(slot) or 1)) - 1) * 2);
    local low = tonumber(bytes[offset]) or 0;
    local high = tonumber(bytes[offset + 1]) or 0;

    return low + (high * 256);
end

local function WriteModelWord(ffiRef, packet, slot, value)
    pcall(function()
        ffiRef.cast('uint16_t*', packet + 0x48)[slot] = math.max(0, math.min(65535, math.floor(tonumber(value) or 0)));
    end);
end

local function WriteCostumeId(ffiRef, packet, value)
    pcall(function()
        ffiRef.cast('uint16_t*', packet + 0x30)[0] = math.max(0, math.min(65535, math.floor(tonumber(value) or 0)));
    end);
end

local function ReadCostumeId(ffiRef, packet)
    local ok, value = pcall(function()
        return tonumber(ffiRef.cast('uint16_t*', packet + 0x30)[0]) or 0;
    end);

    if (ok ~= true) then
        return 0;
    end

    return value;
end

local function ClonePacketString(data)
    if (type(data) ~= 'string' or #data == 0) then
        return nil;
    end

    local bytes = {};

    for offset = 1, #data do
        bytes[offset] = string.byte(data, offset) or 0;
    end

    return bytes;
end

local function ClonePacketBytes(bytes)
    if (type(bytes) ~= 'table') then
        return nil;
    end

    local copy = {};

    for offset = 1, #bytes do
        copy[offset] = ClampByte(bytes[offset], 0);
    end

    return copy;
end

local function ReadByteModelRace(bytes)
    if (type(bytes) ~= 'table') then
        return 0;
    end

    return tonumber(bytes[0x49 + 1]) or 0;
end

local function WriteUInt16Bytes(bytes, offset, value)
    if (type(bytes) ~= 'table') then
        return false;
    end

    local number = math.max(0, math.min(65535, math.floor(tonumber(value) or 0)));

    bytes[offset + 1] = number % 256;
    bytes[offset + 2] = math.floor(number / 256);

    return true;
end

local function GetPacketDataString(e)
    if (e == nil) then
        return nil;
    end

    if (type(e.data) == 'string') then
        return e.data;
    end

    if (type(e.data_raw) == 'string') then
        return e.data_raw;
    end

    if (type(e.data_modified) == 'string') then
        return e.data_modified;
    end

    return nil;
end

local function AddIncomingPacket(id, bytes)
    if (type(bytes) ~= 'table') then
        return false;
    end

    local packetManager = AshitaCore ~= nil and AshitaCore.GetPacketManager ~= nil and AshitaCore:GetPacketManager() or nil;

    if (packetManager == nil or packetManager.AddIncomingPacket == nil) then
        if (incomingReplayWarned ~= true) then
            incomingReplayWarned = true;
            log.Warn('Blacklist model refresh cannot replay packets: AddIncomingPacket is unavailable.');
        end
        return false;
    end

    local ok, err = pcall(function()
        packetManager:AddIncomingPacket(id, bytes);
    end);

    if (ok ~= true) then
        log.Warn('Blacklist model refresh packet replay failed: ' .. tostring(err));
        return false;
    end

    return true;
end

local function NormalizeName(name)
    return tostring(name or ''):gsub('^%s+', ''):gsub('%s+$', ''):lower();
end

local function ServerIdKey(serverId)
    local value = tonumber(serverId) or 0;

    if (value <= 0) then
        return nil;
    end

    return tostring(math.floor(value));
end

local function GetRaceFamily(race)
    race = tonumber(race) or 0;

    if (race == 1 or race == 2) then
        return 'hume';
    elseif (race == 3 or race == 4) then
        return 'elvaan';
    elseif (race == 5 or race == 6) then
        return 'tarutaru';
    elseif (race == 7) then
        return 'mithra';
    elseif (race == 8) then
        return 'galka';
    end

    return 'hume';
end

local function WriteModelBytes(packet, bytes)
    if (type(bytes) ~= 'table') then
        return false;
    end

    for offset = 1, math.min(#bytes, 18) do
        packet[0x47 + offset] = ClampByte(bytes[offset], 0);
    end

    return true;
end

local function WriteFomorPlaceholderBytes(packet, bytes)
    if (type(bytes) ~= 'table') then
        return false;
    end

    -- Keep body gear intact. The fixed NPC Fomor ids are unsafe on remote players,
    -- and clearing the gear table makes players appear in underclothes.
    packet[0x48] = ClampByte(bytes[1], packet[0x48]);
    packet[0x49] = ClampByte(bytes[2], packet[0x49]);

    local headLow = tonumber(bytes[3]) or 0;
    local headHigh = tonumber(bytes[4]) or 0;

    if ((headLow + headHigh) > 0) then
        packet[0x4A] = ClampByte(headLow, packet[0x4A]);
        packet[0x4B] = ClampByte(headHigh, packet[0x4B]);
    end

    return true;
end

local function WriteFomorPlaceholderBytesAt(packet, baseOffset, bytes)
    if (type(bytes) ~= 'table') then
        return false;
    end

    baseOffset = math.max(0, math.floor(tonumber(baseOffset) or 0));

    -- Same conservative replacement as 0x00D: hair/race/head only. This avoids
    -- forcing a full gear table into packets that may not be carrying one.
    packet[baseOffset] = ClampByte(bytes[1], packet[baseOffset]);
    packet[baseOffset + 1] = ClampByte(bytes[2], packet[baseOffset + 1]);

    local headLow = tonumber(bytes[3]) or 0;
    local headHigh = tonumber(bytes[4]) or 0;

    if ((headLow + headHigh) > 0) then
        packet[baseOffset + 2] = ClampByte(headLow, packet[baseOffset + 2]);
        packet[baseOffset + 3] = ClampByte(headHigh, packet[baseOffset + 3]);
    end

    return true;
end

local function CloneModelBytes(bytes)
    if (type(bytes) ~= 'table') then
        return nil;
    end

    local copy = {};

    for offset = 1, 18 do
        copy[offset] = ClampByte(bytes[offset], 0);
    end

    return copy;
end

local function NormalizeModelBytesForPlayer(bytes, fallbackRace)
    local copy = CloneModelBytes(bytes);

    if (copy == nil) then
        return nil;
    end

    if ((tonumber(copy[2]) or 0) < 1 or (tonumber(copy[2]) or 0) > 8) then
        copy[2] = ClampByte(fallbackRace, 5);
    end

    return copy;
end

local function FormatModelBytes(bytes)
    if (type(bytes) ~= 'table') then
        return '';
    end

    local parts = {};

    for offset = 1, math.min(#bytes, 18) do
        parts[#parts + 1] = string.format('%02X', ClampByte(bytes[offset], 0));
    end

    return table.concat(parts, ' ');
end

local function ReadModelBytesFromString(data)
    if (type(data) ~= 'string' or #data < 0x5A) then
        return nil;
    end

    local bytes = {};

    for offset = 1, 18 do
        bytes[offset] = string.byte(data, 0x48 + offset) or 0;
    end

    return bytes;
end

local function ReadNpcEquipmentBytesFromString(data)
    if (type(data) ~= 'string' or #data < 0x44) then
        return nil;
    end

    local bytes = {};

    for offset = 1, 18 do
        bytes[offset] = string.byte(data, 0x32 + offset) or 0;
    end

    return bytes;
end

local function ReadString(data, offset, length)
    if (type(data) ~= 'string') then
        return '';
    end

    return tostring(data:sub(offset + 1, offset + length) or ''):gsub('%z.*$', ''):gsub('^%s+', ''):gsub('%s+$', '');
end

local function ReadUInt16(data, offset)
    if (type(data) ~= 'string' or #data < offset + 2) then
        return 0;
    end

    local low = string.byte(data, offset + 1) or 0;
    local high = string.byte(data, offset + 2) or 0;

    return low + (high * 256);
end

local function ReadUInt32(data, offset)
    if (type(data) ~= 'string' or #data < offset + 4) then
        return 0;
    end

    local b1 = string.byte(data, offset + 1) or 0;
    local b2 = string.byte(data, offset + 2) or 0;
    local b3 = string.byte(data, offset + 3) or 0;
    local b4 = string.byte(data, offset + 4) or 0;

    return b1 + (b2 * 256) + (b3 * 65536) + (b4 * 16777216);
end

local function FormatPacketBytes(data, maxBytes)
    if (type(data) ~= 'string' or data == '') then
        return '';
    end

    local size = math.min(#data, math.max(1, tonumber(maxBytes) or 64));
    local parts = {};

    for index = 1, size do
        parts[#parts + 1] = string.format('%02X', string.byte(data, index) or 0);
    end

    if (#data > size) then
        parts[#parts + 1] = '...';
    end

    return table.concat(parts, ' ');
end

local function GetNpcSubKind(data)
    local value = ReadUInt16(data, 0x30);

    return value % 8;
end

local function GetNpcFixedModelId(data)
    return ReadUInt16(data, 0x32);
end

local function BuildFomorProbeLine(number, index, name, sendFlag, subKind, fixedModelId, bytes, race, raceFamily, canCapture)
    return 'Fomor probe ' .. tostring(number) ..
        ' index=' .. tostring(index) ..
        ' name=' .. tostring(name) ..
        ' flag=' .. FormatHex(sendFlag) ..
        ' subKind=' .. tostring(subKind) ..
        ' fixedModelId=' .. tostring(fixedModelId or '') ..
        ' family=' .. tostring(canCapture == true and raceFamily or 'unknown') ..
        ' hair=' .. tostring(bytes ~= nil and bytes[1] or '') ..
        ' race=' .. tostring(race) ..
        ' head=' .. tostring(ReadModelWordFromBytes(bytes, 1)) ..
        ' body=' .. tostring(ReadModelWordFromBytes(bytes, 2)) ..
        ' hands=' .. tostring(ReadModelWordFromBytes(bytes, 3)) ..
        ' legs=' .. tostring(ReadModelWordFromBytes(bytes, 4)) ..
        ' feet=' .. tostring(ReadModelWordFromBytes(bytes, 5)) ..
        ' bytes=' .. tostring(bytes ~= nil and FormatModelBytes(bytes) or '');
end

local function GetEntityName(index)
    index = tonumber(index) or 0;

    if (index <= 0) then
        return '';
    end

    local ok, entities = pcall(require, 'core.entities');

    if (ok ~= true or entities == nil or entities.GetEntity == nil) then
        return '';
    end

    local entity = entities.GetEntity(index);

    return tostring(entity ~= nil and entity.Name or ''):gsub('^%s+', ''):gsub('%s+$', '');
end

local function GetRawEntityCostumeSummary(index)
    local ok, entity = pcall(function()
        return GetEntity(index);
    end);

    if (ok ~= true or entity == nil) then
        return 'entity=none';
    end

    return 'entityCostume=' .. tostring(entity.CostumeId) ..
        ' entityRace=' .. tostring(entity.Race) ..
        ' entityHair=' .. tostring(entity.Look ~= nil and entity.Look.Hair or '') ..
        ' modelUpdate=' .. tostring(entity.ModelUpdateFlags);
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

local function PulseTarget(index)
    local targetIndex = tonumber(index) or 0;

    if (targetIndex <= 0) then
        return false;
    end

    local okTargeting, targeting = pcall(require, 'core.targeting');

    if (okTargeting ~= true or targeting == nil or targeting.SelectTarget == nil) then
        return false;
    end

    local previous = targeting.GetCurrentTargetIndex ~= nil and targeting.GetCurrentTargetIndex() or nil;
    local selected = targeting.SelectTarget(targetIndex);

    if (selected == true and previous ~= nil and previous ~= 0 and tonumber(previous) ~= targetIndex) then
        targeting.SelectTarget(previous);
    end

    return selected == true;
end

local function ResolvePlayerIndex(playerOrName)
    if (type(playerOrName) == 'table') then
        local index = tonumber(playerOrName.index or playerOrName.targetIndex);
        if (index ~= nil and index > 0) then
            return math.floor(index), tostring(playerOrName.name or playerOrName.clickName or '');
        end
    end

    local directIndex = tonumber(playerOrName);
    if (directIndex ~= nil and directIndex > 0) then
        return math.floor(directIndex), GetEntityName(directIndex);
    end

    local player = FindNearbyPlayerByName(playerOrName);
    if (player ~= nil and tonumber(player.index) ~= nil and tonumber(player.index) > 0) then
        return math.floor(tonumber(player.index)), tostring(player.name or playerOrName or '');
    end

    return nil, tostring(playerOrName or '');
end

local function ResolveRawPlayerIndex(playerOrName)
    local function findRawPcByServerId(serverId)
        local id = tonumber(serverId) or 0;

        if (id <= 0) then
            return nil, '';
        end

        local ok, entities = pcall(require, 'core.entities');

        if (ok ~= true or entities == nil or entities.GetEntity == nil or entities.GetEntityManager == nil) then
            return nil, '';
        end

        local entityManager = entities.GetEntityManager();

        if (entityManager == nil or entityManager.GetServerId == nil) then
            return nil, '';
        end

        for rawIndex = 1024, 1791 do
            local okServer, rawServerId = pcall(function()
                return entityManager:GetServerId(rawIndex);
            end);

            if (okServer == true and tonumber(rawServerId) == id) then
                local entity = entities.GetEntity(rawIndex);
                local entityName = tostring(entity ~= nil and entity.Name or ''):gsub('^%s+', ''):gsub('%s+$', '');

                return rawIndex, entityName;
            end
        end

        return nil, '';
    end

    local numeric = tonumber(playerOrName);

    if (numeric ~= nil) then
        numeric = math.floor(numeric);

        if (numeric >= 1024 and numeric <= 1791) then
            return numeric, GetEntityName(numeric);
        end

        local serverIndex, serverName = findRawPcByServerId(numeric);

        if (serverIndex ~= nil) then
            return serverIndex, serverName;
        end

        return nil, tostring(playerOrName or '');
    end

    local index, name = ResolvePlayerIndex(playerOrName);

    if (index ~= nil and index > 0) then
        return index, name;
    end

    local nameKey = NormalizeName(playerOrName);

    if (nameKey == '') then
        return nil, tostring(playerOrName or '');
    end

    local ok, entities = pcall(require, 'core.entities');

    if (ok ~= true or entities == nil or entities.GetEntity == nil) then
        return nil, tostring(playerOrName or '');
    end

    for rawIndex = 1024, 1791 do
        local entity = entities.GetEntity(rawIndex);
        local entityName = tostring(entity ~= nil and entity.Name or ''):gsub('^%s+', ''):gsub('%s+$', '');

        if (NormalizeName(entityName) == nameKey) then
            return rawIndex, entityName;
        end
    end

    local okList, rows = pcall(function()
        return playerBlacklist.List();
    end);

    if (okList == true and type(rows) == 'table') then
        for _, row in ipairs(rows) do
            if (NormalizeName(row ~= nil and row.name or '') == nameKey and row.serverId ~= nil) then
                local serverIndex, serverName = findRawPcByServerId(row.serverId);

                if (serverIndex ~= nil) then
                    return serverIndex, serverName ~= '' and serverName or tostring(row.name or playerOrName or '');
                end
            end
        end
    end

    return nil, tostring(playerOrName or '');
end

local function GetEntityManager()
    local ok, entities = pcall(require, 'core.entities');

    if (ok == true and entities ~= nil and entities.GetEntityManager ~= nil) then
        local entityManager = entities.GetEntityManager();
        if (entityManager ~= nil) then
            return entityManager;
        end
    end

    if (AshitaCore ~= nil and AshitaCore.GetMemoryManager ~= nil) then
        local memoryManager = AshitaCore:GetMemoryManager();
        if (memoryManager ~= nil and memoryManager.GetEntity ~= nil) then
            return memoryManager:GetEntity();
        end
    end

    return nil;
end

local function FormatBool(value)
    return value == true and 'yes' or 'no';
end

local function FormatDebugInfo(info)
    if (info == nil) then
        return 'entity=none';
    end

    return table.concat({
        'index=' .. tostring(info.index or ''),
        'name=' .. tostring(info.name or ''),
        'type=' .. tostring(info.type or ''),
        'status=' .. tostring(info.status or ''),
        'distance=' .. (info.distance ~= nil and string.format('%.1f', tonumber(info.distance) or 0) or ''),
        'visible=' .. FormatBool(info.visible),
        'skeleton=' .. FormatBool(info.visibleWithSkeleton),
        'settled=' .. FormatBool(info.settled),
        'inRange=' .. FormatBool(info.inRange),
        'pcScan=' .. FormatBool((tonumber(info.index) or 0) >= 1024 and (tonumber(info.index) or 0) <= 1791 and info.visibleWithSkeleton == true),
        'r0=' .. string.format('0x%X', tonumber(info.renderFlags0) or 0),
        'spawn=' .. string.format('0x%X', tonumber(info.spawnFlags) or 0),
    }, ' ');
end

local function GetEntityDebugSummary(index)
    local okEntities, entities = pcall(require, 'core.entities');

    if (okEntities ~= true or entities == nil or entities.GetEntityDebugInfo == nil) then
        return 'entityDebug=unavailable';
    end

    return FormatDebugInfo(entities.GetEntityDebugInfo(index, 64.4)) .. ' ' .. GetRawEntityCostumeSummary(index);
end

local function GetWatchState(index)
    local okEntities, entities = pcall(require, 'core.entities');
    local info = okEntities == true and entities ~= nil and entities.GetEntityDebugInfo ~= nil
        and entities.GetEntityDebugInfo(index, 64.4)
        or nil;
    local okEntity, entity = pcall(function()
        return GetEntity(index);
    end);

    if (okEntity ~= true) then
        entity = nil;
    end

    return {
        info = info,
        key = table.concat({
            tostring(info ~= nil and info.name or ''),
            tostring(info ~= nil and info.type or ''),
            tostring(info ~= nil and info.status or ''),
            tostring(info ~= nil and info.visible == true),
            tostring(info ~= nil and info.visibleWithSkeleton == true),
            tostring(info ~= nil and info.settled == true),
            tostring(info ~= nil and info.inRange == true),
            tostring(entity ~= nil and entity.CostumeId or ''),
            tostring(entity ~= nil and entity.Race or ''),
            tostring(entity ~= nil and entity.Look ~= nil and entity.Look.Hair or ''),
            tostring(entity ~= nil and entity.ModelUpdateFlags or ''),
        }, '|'),
        text = FormatDebugInfo(info) .. ' ' .. GetRawEntityCostumeSummary(index),
    };
end

local function WatchMatches(player)
    if (blacklistWatch == nil or player == nil) then
        return false;
    end

    if ((tonumber(blacklistWatch.untilAt) or 0) > 0 and os.clock() > blacklistWatch.untilAt) then
        blacklistWatch = nil;
        return false;
    end

    local serverId = tonumber(player.serverId) or tonumber(player.packetServerId) or 0;
    local index = tonumber(player.index) or 0;
    local nameKey = NormalizeName(player.name);

    return (
        (blacklistWatch.serverId ~= nil and serverId > 0 and tostring(blacklistWatch.serverId) == tostring(serverId)) or
        (blacklistWatch.index ~= nil and index > 0 and tonumber(blacklistWatch.index) == index) or
        (blacklistWatch.nameKey ~= '' and nameKey ~= '' and blacklistWatch.nameKey == nameKey)
    );
end

local function LogWatchLine(text)
    if (blacklistWatch == nil) then
        return;
    end

    blacklistWatch.count = (tonumber(blacklistWatch.count) or 0) + 1;

    if (blacklistWatch.count <= (tonumber(blacklistWatch.maxCount) or 20)) then
        log.Info(text);
    end

    if (blacklistWatch.count >= (tonumber(blacklistWatch.maxCount) or 20)) then
        log.Info('Blacklist watch reached log limit; watch stopped.');
        blacklistWatch = nil;
    end
end

local function SetModelRefreshFlags(entityManager, index)
    if (entityManager == nil or index == nil) then
        return false;
    end

    local refreshed = false;

    if (entityManager.SetModelUpdateFlags ~= nil) then
        local ok = pcall(function()
            entityManager:SetModelUpdateFlags(index, 0x10);
        end);
        refreshed = refreshed or ok == true;
    end

    if (entityManager.SetIsDirty ~= nil) then
        pcall(function()
            entityManager:SetIsDirty(index, 1);
        end);
    end

    return refreshed;
end

local function SetRawEntityCostume(entityManager, index, value)
    local rawSet = false;
    local rawError = nil;

    local okGlobal, globalErr = pcall(function()
        local entity = GetEntity(index);
        if (entity == nil) then
            error('GetEntity returned nil');
        end

        entity.CostumeId = value;
        entity.ModelUpdateFlags = 0x10;
    end);

    rawSet = okGlobal == true;
    rawError = globalErr;

    if (rawSet ~= true and entityManager ~= nil and entityManager.GetRawEntity ~= nil) then
        local okRaw, rawErr = pcall(function()
            local entity = entityManager:GetRawEntity(index);
            if (entity == nil) then
                error('GetRawEntity returned nil');
            end

            entity.CostumeId = value;
            entity.ModelUpdateFlags = 0x10;
        end);

        rawSet = okRaw == true;
        rawError = rawErr;
    end

    return rawSet, rawError;
end

local function SetRawEntityType(index, value)
    local ok, err = pcall(function()
        local entity = GetEntity(index);
        if (entity == nil) then
            error('GetEntity returned nil');
        end

        if (entity.Type == nil) then
            error('entity Type field unavailable');
        end

        entity.Type = value;
        entity.ModelUpdateFlags = 0x10;
    end);

    return ok == true, err;
end

local function QueueBlacklistModelRecovery(player, fixedModelId, expectedHair)
    if (player == nil) then
        return;
    end

    local now = os.clock();
    local serverId = tonumber(player.serverId) or tonumber(player.packetServerId) or 0;
    local index = tonumber(player.index) or 0;
    local name = tostring(player.name or ''):gsub('^%s+', ''):gsub('%s+$', '');
    local key = serverId > 0 and ('s:' .. tostring(serverId)) or (name ~= '' and ('n:' .. NormalizeName(name)) or ('i:' .. tostring(index)));

    pendingBlacklistRecoveries[key] = {
        index = index > 0 and index or nil,
        name = name,
        serverId = serverId > 0 and serverId or nil,
        fixedModelId = math.floor(tonumber(fixedModelId) or 0),
        expectedHair = tonumber(expectedHair),
        queuedAt = now,
        nextAt = now + 0.35,
        expiresAt = now + 2.50,
        attempts = 0,
    };
end

local function GetBlacklistRecoveryKey(player)
    if (player == nil) then
        return nil;
    end

    local serverId = tonumber(player.serverId) or tonumber(player.packetServerId) or 0;
    local index = tonumber(player.index) or 0;
    local name = tostring(player.name or ''):gsub('^%s+', ''):gsub('%s+$', '');

    if (serverId > 0) then
        return 's:' .. tostring(serverId);
    end

    if (name ~= '') then
        return 'n:' .. NormalizeName(name);
    end

    if (index > 0) then
        return 'i:' .. tostring(index);
    end

    return nil;
end

local function ShouldSuppressBlacklistRecoveryWrite(player)
    local key = GetBlacklistRecoveryKey(player);

    if (key == nil) then
        return false;
    end

    local untilAt = tonumber(suppressBlacklistRecoveryWrites[key]) or 0;

    if (untilAt <= 0) then
        return false;
    end

    if (os.clock() > untilAt) then
        suppressBlacklistRecoveryWrites[key] = nil;
        return false;
    end

    return true;
end

local function IsStableBlacklistRecoveredActor(player, expectedHair)
    local key = GetBlacklistRecoveryKey(player);

    if (key == nil or stableBlacklistRecoveredActors[key] ~= true) then
        return false;
    end

    local index = tonumber(player ~= nil and player.index or 0) or 0;

    if (index <= 0) then
        stableBlacklistRecoveredActors[key] = nil;
        return false;
    end

    local okInfo, info = pcall(function()
        local entities = require('core.entities');
        return entities.GetEntityDebugInfo ~= nil and entities.GetEntityDebugInfo(index, 64.4) or nil;
    end);

    if (okInfo == true and info ~= nil and info.visible ~= true) then
        stableBlacklistRecoveredActors[key] = nil;
        return false;
    end

    local okEntity, entity = pcall(function()
        return GetEntity(index);
    end);

    if (okEntity ~= true or entity == nil) then
        stableBlacklistRecoveredActors[key] = nil;
        return false;
    end

    if (tonumber(entity.Type) ~= 0 or tonumber(entity.CostumeId) ~= 0) then
        stableBlacklistRecoveredActors[key] = nil;
        return false;
    end

    local targetHair = tonumber(expectedHair);
    if (targetHair ~= nil and tonumber(entity.Look ~= nil and entity.Look.Hair or nil) ~= targetHair) then
        stableBlacklistRecoveredActors[key] = nil;
        return false;
    end

    return true;
end

local function HasRecoveredBlacklistLook(index, expectedHair)
    local targetIndex = tonumber(index) or 0;
    local targetHair = tonumber(expectedHair);

    if (targetIndex <= 0 or targetHair == nil) then
        return false;
    end

    local ok, entity = pcall(function()
        return GetEntity(targetIndex);
    end);

    if (ok ~= true or entity == nil) then
        return false;
    end

    return tonumber(entity.Type) == 0
        and tonumber(entity.CostumeId) == 0
        and tonumber(entity.Look ~= nil and entity.Look.Hair or nil) == targetHair;
end

local function ProcessBlacklistModelRecoveries()
    local now = os.clock();
    local entityManager = nil;
    local entities = nil;

    for key, pending in pairs(pendingBlacklistRecoveries) do
        if (now > (tonumber(pending.expiresAt) or 0)) then
            pendingBlacklistRecoveries[key] = nil;
        elseif (now >= (tonumber(pending.nextAt) or 0)) then
            local index = tonumber(pending.index) or 0;

            if (index <= 0) then
                local resolvedIndex = ResolveRawPlayerIndex(pending.serverId or pending.name);
                index = tonumber(resolvedIndex) or 0;
                pending.index = index > 0 and index or nil;
            end

            local okEntity, entity = pcall(function()
                return GetEntity(index);
            end);

            if (index <= 0 or okEntity ~= true or entity == nil) then
                pending.nextAt = now + 0.20;
            else
                local currentType = tonumber(entity.Type) or 0;
                local currentCostume = tonumber(entity.CostumeId) or 0;
                local currentHair = tonumber(entity.Look ~= nil and entity.Look.Hair or nil);
                local expectedHair = tonumber(pending.expectedHair);

                if (
                    expectedHair ~= nil and
                    currentHair ~= expectedHair and
                    (now - (tonumber(pending.queuedAt) or now)) < 0.90 and
                    currentType == 2
                ) then
                    pending.nextAt = now + 0.10;
                elseif (currentType ~= 2 and currentCostume ~= (tonumber(pending.fixedModelId) or 0)) then
                    pendingBlacklistRecoveries[key] = nil;
                else
                    entityManager = entityManager or GetEntityManager();
                    local costumeSet = SetRawEntityCostume(entityManager, index, 0);
                    local typeSet = SetRawEntityType(index, 0);
                    local refreshed = SetModelRefreshFlags(entityManager, index);
                    local selected = PulseTarget(index);

                    pending.attempts = (tonumber(pending.attempts) or 0) + 1;

                    if (debugEnabled == true or blacklistWatch ~= nil) then
                        entities = entities or (pcall(require, 'core.entities') and require('core.entities') or nil);
                        local info = entities ~= nil and entities.GetEntityDebugInfo ~= nil
                            and entities.GetEntityDebugInfo(index, 64.4)
                            or nil;
                        log.Info(
                            'Blacklist auto recover: index=' .. tostring(index) ..
                            ' name=' .. tostring(pending.name or '') ..
                            ' costume0=' .. FormatBool(costumeSet) ..
                            ' type0=' .. FormatBool(typeSet) ..
                            ' refreshFlags=' .. FormatBool(refreshed) ..
                            ' targetPulse=' .. FormatBool(selected) ..
                            ' state=' .. FormatDebugInfo(info) ..
                            ' ' .. GetRawEntityCostumeSummary(index)
                        );
                    end

                    if (costumeSet == true and typeSet == true) then
                        suppressBlacklistRecoveryWrites[key] = now + 2.00;
                        stableBlacklistRecoveredActors[key] = true;
                        pendingBlacklistRecoveries[key] = nil;
                    elseif (pending.attempts >= 3) then
                        pendingBlacklistRecoveries[key] = nil;
                    else
                        pending.nextAt = now + 0.25;
                    end
                end
            end
        end
    end
end

local function SetLiveLook(playerOrName, race, face)
    local index, name = ResolvePlayerIndex(playerOrName);

    if (index == nil or index <= 0) then
        return false, 'player not found: ' .. tostring(name or playerOrName or '');
    end

    local targetRace = ClampByte(race, 5);
    local targetFace = math.max(0, math.min(65535, math.floor(tonumber(face) or 2)));
    local entityManager = GetEntityManager();

    if (entityManager == nil) then
        return false, 'Ashita entity manager is unavailable';
    end

    local methodSet = false;
    local rawSet = false;

    local okMethod = pcall(function()
        if (entityManager.SetRace ~= nil) then
            entityManager:SetRace(index, targetRace);
        end
        if (entityManager.SetLookHair ~= nil) then
            entityManager:SetLookHair(index, targetFace);
        end
    end);

    methodSet = okMethod == true;

    local okRaw = pcall(function()
        local entity = GetEntity(index);
        if (entity == nil) then
            error('GetEntity returned nil');
        end

        entity.Race = targetRace;
        if (entity.Look ~= nil) then
            entity.Look.Hair = targetFace;
        end
        entity.ModelUpdateFlags = 0x10;
    end);

    rawSet = okRaw == true;

    local refreshed = SetModelRefreshFlags(entityManager, index);
    PulseTarget(index);

    if (methodSet ~= true and rawSet ~= true) then
        return false, 'look write failed';
    end

    return true,
        'index=' .. tostring(index) ..
        ' name=' .. tostring(name ~= '' and name or GetEntityName(index)) ..
        ' race=' .. tostring(targetRace) ..
        ' face=' .. tostring(targetFace) ..
        ' refresh=' .. tostring(refreshed == true) ..
        ' method=' .. tostring(methodSet == true) ..
        ' raw=' .. tostring(rawSet == true);
end

local function MarkClear(playerOrName)
    local name = type(playerOrName) == 'table' and (playerOrName.name or playerOrName.clickName) or playerOrName;
    local serverId = type(playerOrName) == 'table' and playerOrName.serverId or nil;
    local nameKey = NormalizeName(name);
    local idKey = ServerIdKey(serverId);

    if (nameKey ~= '') then
        pendingClearNames[nameKey] = true;
    end

    if (idKey ~= nil) then
        pendingClearIds[idKey] = true;
    end
end

local function HasPendingClear()
    if (os.clock() <= pendingClearAllUntil) then
        return true;
    end

    for _, _ in pairs(pendingClearNames) do
        return true;
    end

    for _, _ in pairs(pendingClearIds) do
        return true;
    end

    return false;
end

local function ShouldClearPlayer(player)
    if (os.clock() <= pendingClearAllUntil) then
        return true;
    end

    local idKey = ServerIdKey(player ~= nil and player.serverId);
    local nameKey = NormalizeName(player ~= nil and player.name or '');

    return (idKey ~= nil and pendingClearIds[idKey] == true) or (nameKey ~= '' and pendingClearNames[nameKey] == true);
end

local function ClearPlayerPending(player)
    local idKey = ServerIdKey(player ~= nil and player.serverId);
    local nameKey = NormalizeName(player ~= nil and player.name or '');

    if (idKey ~= nil) then
        pendingClearIds[idKey] = nil;
    end

    if (nameKey ~= '') then
        pendingClearNames[nameKey] = nil;
    end
end

local function QueueCostumeApply(playerOrName, costumeId, reason)
    local value = math.max(0, math.min(65535, math.floor(tonumber(costumeId) or 0)));
    local player = type(playerOrName) == 'table' and playerOrName or FindNearbyPlayerByName(playerOrName);
    local name = type(playerOrName) == 'table' and (playerOrName.name or playerOrName.clickName) or playerOrName;
    local nameKey = NormalizeName(name or (player ~= nil and player.name) or '');
    local idKey = ServerIdKey(player ~= nil and player.serverId);
    local queueKey = idKey or nameKey;

    if (queueKey == nil or queueKey == '') then
        return false, 'no player key';
    end

    pendingCostumeApplies[queueKey] = {
        value = value,
        name = tostring(name or (player ~= nil and player.name) or ''),
        serverId = player ~= nil and player.serverId or nil,
        index = player ~= nil and player.index or nil,
        reason = tostring(reason or 'manual'),
        waitingForPacket = true,
        nextAt = os.clock(),
        untilAt = os.clock() + 12.0,
        attempts = 0,
        maxAttempts = 24,
    };

    return true, queueKey;
end

local function QueueLookApply(playerOrName, race, face, reason)
    local player = type(playerOrName) == 'table' and playerOrName or FindNearbyPlayerByName(playerOrName);
    local name = type(playerOrName) == 'table' and (playerOrName.name or playerOrName.clickName) or playerOrName;
    local nameKey = NormalizeName(name or (player ~= nil and player.name) or '');
    local idKey = ServerIdKey(player ~= nil and player.serverId);
    local queueKey = idKey or nameKey;

    if (queueKey == nil or queueKey == '') then
        return false, 'no player key';
    end

    pendingLookApplies[queueKey] = {
        race = ClampByte(race, 5),
        face = math.max(0, math.min(65535, math.floor(tonumber(face) or 2))),
        name = tostring(name or (player ~= nil and player.name) or ''),
        serverId = player ~= nil and player.serverId or nil,
        index = player ~= nil and player.index or nil,
        reason = tostring(reason or 'manual'),
        waitingForPacket = true,
        nextAt = os.clock(),
        untilAt = os.clock() + 12.0,
        attempts = 0,
        maxAttempts = 24,
    };

    return true, queueKey;
end

local function MatchesCostumeWatch(player)
    if (costumeWatch == nil or player == nil) then
        return false;
    end

    local idKey = ServerIdKey(player.serverId);
    local nameKey = NormalizeName(player.name or player.clickName);

    return (costumeWatch.serverId ~= nil and idKey ~= nil and tostring(costumeWatch.serverId) == idKey)
        or (costumeWatch.nameKey ~= '' and nameKey == costumeWatch.nameKey)
        or (costumeWatch.index ~= nil and tonumber(player.index) == tonumber(costumeWatch.index));
end

local function HandleCostumeWatchPartyBuffPacket(e)
    if (costumeWatch == nil or e == nil or e.id ~= 0x0076) then
        return;
    end

    local data = GetPacketDataString(e);

    if (type(data) ~= 'string') then
        return;
    end

    for memberIndex = 0, 4 do
        local memberOffset = 0x04 + (0x30 * memberIndex);
        local serverId = ReadUInt32(data, memberOffset);

        if (serverId ~= 0 and costumeWatch.serverId ~= nil and tostring(serverId) == tostring(costumeWatch.serverId)) then
            local ids = {};

            for buffIndex = 0, 31 do
                local value = string.byte(data, memberOffset + 0x0F + buffIndex + 1) or 0;
                ids[#ids + 1] = tostring(value);
            end

            log.Info('Costume watch 0x076 slot=' .. tostring(memberIndex) ..
                ' server=' .. tostring(serverId) ..
                ' lowStatusBytes=' .. table.concat(ids, ',') ..
                ' bytes=' .. FormatPacketBytes(data, 80));
        end
    end
end

local function GetQueuedCostumeApply(player)
    if (player == nil) then
        return nil, nil;
    end

    local idKey = ServerIdKey(player.serverId);
    if (idKey ~= nil and pendingCostumeApplies[idKey] ~= nil) then
        return pendingCostumeApplies[idKey], idKey;
    end

    local nameKey = NormalizeName(player.name or player.clickName);
    if (nameKey ~= '' and pendingCostumeApplies[nameKey] ~= nil) then
        return pendingCostumeApplies[nameKey], nameKey;
    end

    return nil, nil;
end

local function GetQueuedLookApply(player)
    if (player == nil) then
        return nil, nil;
    end

    local idKey = ServerIdKey(player.serverId);
    if (idKey ~= nil and pendingLookApplies[idKey] ~= nil) then
        return pendingLookApplies[idKey], idKey;
    end

    local nameKey = NormalizeName(player.name or player.clickName);
    if (nameKey ~= '' and pendingLookApplies[nameKey] ~= nil) then
        return pendingLookApplies[nameKey], nameKey;
    end

    return nil, nil;
end

local function CachePlayerPacket(player, e)
    if (player == nil) then
        return;
    end

    local packetBytes = ClonePacketString(GetPacketDataString(e));

    if (packetBytes == nil) then
        return;
    end

    local cacheEntry = {
        bytes = packetBytes,
        at = os.clock(),
        savedAt = os.time(),
        name = tostring(player.name or ''),
        serverId = tonumber(player.serverId) or 0,
    };
    local nameKey = NormalizeName(player.name);
    local idKey = ServerIdKey(player.serverId);
    local settings = playerBlacklist.GetModelReplaceSettings();

    if (nameKey ~= '') then
        cachedPlayerPacketsByName[nameKey] = cacheEntry;
        settings.modelReplacePacketCache[nameKey] = {
            bytes = ClonePacketBytes(packetBytes),
            savedAt = cacheEntry.savedAt,
            name = cacheEntry.name,
            serverId = cacheEntry.serverId,
        };
        state.SaveThrottled(2.0);
    end

    if (idKey ~= nil) then
        cachedPlayerPacketsById[idKey] = cacheEntry;
    end
end

local function GetCachedPlayerPacket(playerOrName)
    local function GetSavedByName(name)
        local nameKey = NormalizeName(name);

        if (nameKey == '') then
            return nil;
        end

        local settings = playerBlacklist.GetModelReplaceSettings();
        local saved = type(settings.modelReplacePacketCache) == 'table' and settings.modelReplacePacketCache[nameKey] or nil;

        if (type(saved) == 'table' and type(saved.bytes) == 'table') then
            return {
                bytes = ClonePacketBytes(saved.bytes),
                at = os.clock(),
                savedAt = tonumber(saved.savedAt) or 0,
                name = tostring(saved.name or name or ''),
                serverId = tonumber(saved.serverId) or 0,
            };
        end

        return nil;
    end

    if (type(playerOrName) == 'table') then
        local idKey = ServerIdKey(playerOrName.serverId);
        local nameKey = NormalizeName(playerOrName.name or playerOrName.clickName);

        return (idKey ~= nil and cachedPlayerPacketsById[idKey]) or (nameKey ~= '' and cachedPlayerPacketsByName[nameKey]) or GetSavedByName(playerOrName.name or playerOrName.clickName);
    end

    local nameKey = NormalizeName(playerOrName);

    if (nameKey == '') then
        return nil;
    end

    local cached = cachedPlayerPacketsByName[nameKey];

    if (cached ~= nil) then
        return cached;
    end

    return GetSavedByName(playerOrName);
end

local function ReplayCachedPlayerPacket(playerOrName, clear)
    local cached = GetCachedPlayerPacket(playerOrName);

    if (cached == nil or type(cached.bytes) ~= 'table') then
        return false, 'no cached packet';
    end

    if ((tonumber(cached.savedAt) or os.time()) > 0 and (os.time() - (tonumber(cached.savedAt) or os.time())) > 1800) then
        return false, 'saved packet too old';
    end

    if ((os.clock() - (tonumber(cached.at) or os.clock())) > 300.0 and (tonumber(cached.savedAt) or 0) <= 0) then
        return false, 'cached packet too old';
    end

    local replayBytes = ClonePacketBytes(cached.bytes);
    local settings = playerBlacklist.GetModelReplaceSettings();
    local costumeId = 0;

    if (clear ~= true) then
        if (settings.modelReplaceUseNpcCostume == true) then
            if (settings.modelReplaceNpcCostumeByRace == true) then
                costumeId = GetFixedFomorModelId(settings, GetRaceFamily(ReadByteModelRace(replayBytes)));
            else
                costumeId = math.floor(tonumber(settings.modelReplaceNpcCostumeId) or 0);
            end
        elseif (settings.modelReplaceUseCostume == true) then
            costumeId = math.floor(tonumber(settings.modelReplaceCostumeId) or 0);
        end
    end

    WriteUInt16Bytes(replayBytes, 0x30, costumeId);

    return AddIncomingPacket(0x000D, replayBytes), 'cached packet costume=' .. tostring(costumeId);
end

local function GetCapturedFomorModel(settings, raceFamily)
    if (type(settings) ~= 'table' or type(settings.modelReplaceCapturedFomorModels) ~= 'table') then
        return nil;
    end

    return settings.modelReplaceCapturedFomorModels[raceFamily];
end

local function GetFomorModelBytes(settings, raceFamily, fallbackRace)
    local captured = NormalizeModelBytesForPlayer(GetCapturedFomorModel(settings, raceFamily), fallbackRace);

    if (captured ~= nil) then
        return captured;
    end

    return NormalizeModelBytesForPlayer(fomorModels[raceFamily], fallbackRace);
end

local function GetFixedFomorModelId(settings, raceFamily)
    if (type(settings) ~= 'table' or type(settings.modelReplaceFixedFomorModels) ~= 'table') then
        return 0;
    end

    return math.floor(tonumber(settings.modelReplaceFixedFomorModels[raceFamily]) or 0);
end

local function GetLiveTargetProbeInfo(index)
    local targetIndex = tonumber(index) or 0;

    if (targetIndex <= 0) then
        return nil;
    end

    local okEntities, entities = pcall(require, 'core.entities');
    local okProbe, worldMarkerProbe = pcall(require, 'core.world_marker_probe');

    if (okEntities ~= true or okProbe ~= true or entities == nil or worldMarkerProbe == nil) then
        return nil;
    end

    local ok, debug = pcall(function()
        return worldMarkerProbe.GetVisibilityDebug(targetIndex, entities.GetEntityManager, entities.GetBone);
    end);

    if (ok ~= true or debug == nil) then
        return nil;
    end

    return debug;
end

local function LogLiveTargetProbe(index)
    local debug = GetLiveTargetProbeInfo(index);

    if (debug == nil) then
        return false;
    end

    log.Info(
        'Fomor live probe index=' .. tostring(index) ..
        ' name=' .. tostring(debug.name or '') ..
        ' type=' .. tostring(debug.type) ..
        ' spawn=0x' .. string.format('%X', tonumber(debug.spawnFlags) or 0) ..
        ' render0=0x' .. string.format('%X', tonumber(debug.renderFlags0) or 0) ..
        ' render1=0x' .. string.format('%X', tonumber(debug.renderFlags1) or 0) ..
        ' actorInts=' .. tostring(debug.actorInts or '') ..
        ' objectInts=' .. tostring(debug.objectInts or '')
    );

    return true;
end

local function ParseNpcModelPacket(e)
    if (e == nil or e.blocked == true or e.id ~= 0x000E) then
        return nil;
    end

    local data = e.data_modified or e.data;

    if (type(data) ~= 'string') then
        return nil;
    end

    local index = ReadUInt16(data, 0x08);
    local name = ReadString(data, 0x5A, 16);

    if (name == '') then
        name = GetEntityName(index);
    end

    local sendFlag = string.byte(data, 0x0A + 1) or 0;
    local subKind = GetNpcSubKind(data);
    local isEquippedNpc = subKind == 1 or subKind == 7;
    local bytes = isEquippedNpc == true and ReadNpcEquipmentBytesFromString(data) or nil;
    local fixedModelId = isEquippedNpc ~= true and GetNpcFixedModelId(data) or nil;
    local race = tonumber(bytes ~= nil and bytes[2] or 0) or 0;
    local raceFamily = GetRaceFamily(race);
    local canCapture = race >= 1 and race <= 8;

    return {
        index = index,
        name = name,
        sendFlag = sendFlag,
        subKind = subKind,
        fixedModelId = fixedModelId,
        bytes = bytes,
        race = race,
        raceFamily = raceFamily,
        canCapture = canCapture,
    };
end

local function CacheFomorProbeInfo(info)
    if (info == nil or tonumber(info.index) == nil or tostring(info.name or ''):lower():find('fomor', 1, true) == nil) then
        return;
    end

    fomorProbeCache[tostring(info.index)] = info;
end

local function LogFomorProbeInfo(info)
    if (info == nil) then
        return false;
    end

    fomorProbePacketCount = fomorProbePacketCount + 1;
    log.Info(BuildFomorProbeLine(fomorProbePacketCount, info.index, info.name, info.sendFlag, info.subKind, info.fixedModelId, info.bytes, info.race, info.raceFamily, info.canCapture));
    fomorProbeLoggedIndexes[tostring(info.index)] = true;

    if (info.canCapture == true) then
        local settings = playerBlacklist.GetModelReplaceSettings();
        settings.modelReplaceCapturedFomorModels[info.raceFamily] = CloneModelBytes(info.bytes);
        state.SaveThrottled(0.25);
        log.Info('Captured blacklist Fomor model for family=' .. tostring(info.raceFamily) .. '.');
    end

    return true;
end

local function HandleFomorProbePacket(e)
    local info = ParseNpcModelPacket(e);

    CacheFomorProbeInfo(info);

    if ((fomorProbeEnabled ~= true and fomorProbeTargetIndex == nil) or info == nil) then
        return;
    end

    local targetProbeMatch = fomorProbeTargetIndex ~= nil and tonumber(fomorProbeTargetIndex) == tonumber(info.index);

    if (fomorProbeTargetIndex ~= nil and targetProbeMatch ~= true) then
        return;
    end

    if (targetProbeMatch ~= true and tostring(info.name or ''):lower():find('fomor', 1, true) == nil) then
        return;
    end

    if (targetProbeMatch ~= true and fomorProbeLoggedIndexes[tostring(info.index)] == true) then
        return;
    end

    LogFomorProbeInfo(info);

    if (targetProbeMatch == true) then
        fomorProbeTargetIndex = nil;
    end
end

local function GetEntityPlayer(actIndex, packetServerId, packetName)
    actIndex = tonumber(actIndex) or 0;

    if (actIndex <= 0) then
        return {
            index = actIndex,
            name = packetName,
            serverId = packetServerId,
        };
    end

    local ok, entities = pcall(require, 'core.entities');

    if (ok ~= true or entities == nil or entities.GetEntity == nil or entities.GetEntityManager == nil) then
        return {
            index = actIndex,
            name = packetName,
            serverId = packetServerId,
        };
    end

    local entity = entities.GetEntity(actIndex);
    local name = tostring(packetName or '');

    if (name == '' and entity ~= nil and entity.Name ~= nil) then
        name = tostring(entity.Name or ''):gsub('^%s+', ''):gsub('%s+$', '');
    end

    local serverId = packetServerId;
    local entityManager = entities.GetEntityManager();
    local okServerId, entityServerId = pcall(function()
        return entityManager:GetServerId(actIndex);
    end);

    if (okServerId == true and tonumber(entityServerId) ~= nil and tonumber(entityServerId) > 0) then
        serverId = entityServerId;
    end

    return {
        index = actIndex,
        name = name,
        serverId = serverId,
        packetServerId = packetServerId,
    };
end

local function HandlePlayerModelPacket00E(e, settings)
    if (e == nil or e.blocked == true or e.id ~= 0x000E or e.data_modified_raw == nil) then
        return;
    end

    if (settings.modelReplaceEnabled ~= true or settings.modelReplaceUseFomor == false) then
        return;
    end

    local ffiRef = GetFfi();

    if (ffiRef == nil) then
        return;
    end

    local ok, packet = pcall(function()
        return ffiRef.cast('uint8_t*', e.data_modified_raw);
    end);

    if (ok ~= true or packet == nil) then
        return;
    end

    local sendFlag = packet[0x0A];
    local isPcLikeModelUpdate = (sendFlag == 0x0F or sendFlag == 0x57) and packet[0x1F] ~= 0x09 and packet[0x30] == 1;

    if (isPcLikeModelUpdate ~= true) then
        return;
    end

    local serverId = ReadServerId(ffiRef, packet);
    local actIndex = ReadActIndex(ffiRef, packet);
    local name = HasFlag(sendFlag, 0x08) == true and ReadName(ffiRef, packet) or '';
    local player = GetEntityPlayer(actIndex, serverId, name);
    local entry = playerBlacklist.GetEntry(player);

    if (WatchMatches(player) == true) then
        LogWatchLine(
            'BL watch 0x00E pre' ..
            ' flag=' .. FormatHex(sendFlag) ..
            ' packetId=' .. tostring(serverId) ..
            ' index=' .. tostring(actIndex) ..
            ' id=' .. tostring(player.serverId or '') ..
            ' name=' .. tostring(player.name or '') ..
            ' listed=' .. tostring(entry ~= nil) ..
            ' hair=' .. tostring(packet[0x32]) ..
            ' race=' .. tostring(packet[0x33]) ..
            ' info=' .. GetEntityDebugSummary(actIndex)
        );
    end

    if (entry == nil) then
        return;
    end

    local originalHair = packet[0x32];
    local originalRace = packet[0x33];
    local targetRace = settings.modelReplacePreserveRace ~= false and originalRace or ClampByte(settings.modelReplaceRace, 5);
    local raceFamily = GetRaceFamily(targetRace);
    packet[0x32] = ClampByte(fomorModels[raceFamily] ~= nil and fomorModels[raceFamily][1] or settings.modelReplaceHair, 2);
    packet[0x33] = targetRace;

    if (WatchMatches(player) == true) then
        LogWatchLine(
            'BL watch 0x00E post' ..
            ' index=' .. tostring(actIndex) ..
            ' afterHair=' .. tostring(packet[0x32]) ..
            ' afterRace=' .. tostring(packet[0x33]) ..
            ' info=' .. GetEntityDebugSummary(actIndex)
        );
    end

    if (debugEnabled == true and debugPacketCount < 40) then
        debugPacketCount = debugPacketCount + 1;
        log.Info(
            'BL model 0x00E ' .. tostring(debugPacketCount) ..
            ' flag=' .. FormatHex(sendFlag) ..
            ' packetId=' .. tostring(serverId) ..
            ' index=' .. tostring(actIndex) ..
            ' id=' .. tostring(player.serverId or '') ..
            ' name=' .. tostring(player.name or '') ..
            ' listed=true' ..
            ' beforeHair=' .. tostring(originalHair) ..
            ' beforeRace=' .. tostring(originalRace) ..
            ' afterHair=' .. tostring(packet[0x32]) ..
            ' afterRace=' .. tostring(packet[0x33]) ..
            ' family=' .. tostring(raceFamily)
        );
    end
end

function blacklistModelReplace.HandlePacketIn(e)
    HandleFomorProbePacket(e);
    HandleCostumeWatchPartyBuffPacket(e);

    if (e ~= nil and e.id == 0x000E) then
        HandlePlayerModelPacket00E(e, playerBlacklist.GetModelReplaceSettings());
        return;
    end

    if (e == nil or e.blocked == true or e.id ~= 0x000D or e.data_modified_raw == nil) then
        return;
    end

    local settings = playerBlacklist.GetModelReplaceSettings();

    if (settings.modelReplaceEnabled ~= true and HasPendingClear() ~= true) then
        return;
    end

    local ffiRef = GetFfi();

    if (ffiRef == nil) then
        return;
    end

    local ok, packet = pcall(function()
        return ffiRef.cast('uint8_t*', e.data_modified_raw);
    end);

    if (ok ~= true or packet == nil) then
        return;
    end

    local sendFlag = packet[0x0A];

    if (HasFlag(sendFlag, 0x10) ~= true) then
        return;
    end

    local serverId = ReadServerId(ffiRef, packet);
    local actIndex = ReadActIndex(ffiRef, packet);
    local name = HasFlag(sendFlag, 0x08) == true and ReadName(ffiRef, packet) or '';
    local player = GetEntityPlayer(actIndex, serverId, name);
    CachePlayerPacket(player, e);
    local entry = playerBlacklist.GetEntry(player);
    local queuedCostume = nil;
    local queuedLook = nil;
    local originalRace = packet[0x49];
    local targetRace = settings.modelReplacePreserveRace ~= false and originalRace or ClampByte(settings.modelReplaceRace, 5);
    local raceFamily = GetRaceFamily(targetRace);
    local originalRaceFamily = GetRaceFamily(originalRace);

    if (WatchMatches(player) == true) then
        LogWatchLine(
            'BL watch 0x00D pre' ..
            ' flag=' .. FormatHex(sendFlag) ..
            ' packetId=' .. tostring(serverId) ..
            ' index=' .. tostring(actIndex) ..
            ' id=' .. tostring(player.serverId or '') ..
            ' name=' .. tostring(player.name or '') ..
            ' listed=' .. tostring(entry ~= nil) ..
            ' hair=' .. tostring(packet[0x48]) ..
            ' race=' .. tostring(packet[0x49]) ..
            ' costume=' .. tostring(ReadCostumeId(ffiRef, packet)) ..
            ' head=' .. tostring(ReadModelWord(ffiRef, packet, 1)) ..
            ' body=' .. tostring(ReadModelWord(ffiRef, packet, 2)) ..
            ' info=' .. GetEntityDebugSummary(actIndex)
        );
    end

    if (debugEnabled == true and debugPacketCount < 40) then
        debugPacketCount = debugPacketCount + 1;
        log.Info(
            'BL model packet ' .. tostring(debugPacketCount) ..
            ' flag=' .. FormatHex(sendFlag) ..
            ' packetId=' .. tostring(serverId) ..
            ' index=' .. tostring(actIndex) ..
            ' id=' .. tostring(player.serverId or '') ..
            ' name=' .. tostring(player.name or '') ..
            ' listed=' .. tostring(entry ~= nil) ..
            ' beforeHair=' .. tostring(packet[0x48]) ..
            ' beforeRace=' .. tostring(packet[0x49]) ..
            ' beforeCostume=' .. tostring(ReadCostumeId(ffiRef, packet)) ..
            ' head=' .. tostring(ReadModelWord(ffiRef, packet, 1)) ..
            ' body=' .. tostring(ReadModelWord(ffiRef, packet, 2)) ..
            ' family=' .. tostring(raceFamily) ..
            ' fomor=' .. tostring(settings.modelReplaceUseFomor ~= false) ..
            ' targetHair=' .. tostring(settings.modelReplaceHair) ..
            ' targetRace=' .. tostring(targetRace) ..
            ' preserveRace=' .. tostring(settings.modelReplacePreserveRace ~= false) ..
            ' clearGear=' .. tostring(settings.modelReplaceClearGear == true)
        );
    end

    if (MatchesCostumeWatch(player) == true) then
        local data = GetPacketDataString(e);
        log.Info(
            'Costume watch 0x00D' ..
            ' flag=' .. FormatHex(sendFlag) ..
            ' packetId=' .. tostring(serverId) ..
            ' index=' .. tostring(actIndex) ..
            ' name=' .. tostring(player.name or '') ..
            ' packetCostume=' .. tostring(ReadCostumeId(ffiRef, packet)) ..
            ' race=' .. tostring(packet[0x49]) ..
            ' hair=' .. tostring(packet[0x48]) ..
            ' head=' .. tostring(ReadModelWord(ffiRef, packet, 1)) ..
            ' body=' .. tostring(ReadModelWord(ffiRef, packet, 2)) ..
            ' ' .. GetRawEntityCostumeSummary(actIndex) ..
            ' bytes=' .. FormatPacketBytes(data, 96)
        );
    end

    if (queuedLook ~= nil) then
        packet[0x48] = ClampByte(queuedLook.face, packet[0x48]);
        packet[0x49] = ClampByte(queuedLook.race, packet[0x49]);
        queuedLook.index = actIndex;
        queuedLook.serverId = player.serverId or serverId;
        queuedLook.name = player.name ~= '' and player.name or queuedLook.name;
        queuedLook.waitingForPacket = false;
        queuedLook.nextAt = os.clock() + 0.05;
    end

    if (entry == nil and queuedCostume == nil and queuedLook == nil) then
        if (ShouldClearPlayer(player) == true) then
            ClearPlayerPending(player);
        end
        return;
    end

    local fixedModelId = GetFixedFomorModelId(settings, raceFamily);
    local originalFixedModelId = GetFixedFomorModelId(settings, originalRaceFamily);
    local npcCostumeId = settings.modelReplaceNpcCostumeByRace == true
        and originalFixedModelId
        or math.floor(tonumber(settings.modelReplaceNpcCostumeId) or 0);
    local costumeId = math.floor(tonumber(settings.modelReplaceCostumeId) or 0);

    local expectedFomorHair = fomorModels[raceFamily] ~= nil and fomorModels[raceFamily][1] or settings.modelReplaceHair;
    local alreadyRecovered = HasRecoveredBlacklistLook(actIndex, expectedFomorHair);
    local stableRecovered = IsStableBlacklistRecoveredActor(player, expectedFomorHair);

    if (
        entry ~= nil and
        settings.modelReplaceUseFomor ~= false and
        ShouldSuppressBlacklistRecoveryWrite(player) ~= true and
        alreadyRecovered ~= true and
        stableRecovered ~= true
    ) then
        WriteCostumeId(ffiRef, packet, fixedModelId);
        QueueBlacklistModelRecovery(player, fixedModelId, expectedFomorHair);
    elseif (settings.modelReplaceUseNpcCostume == true and npcCostumeId > 0) then
        -- Fixed NPC model ids can make remote player bodies disappear after a real
        -- range reload. Keep the setting/debug path for investigation, but never
        -- apply it to live players.
    end

    if (WatchMatches(player) == true) then
        LogWatchLine(
            'BL watch 0x00D post' ..
            ' index=' .. tostring(actIndex) ..
            ' afterHair=' .. tostring(packet[0x48]) ..
            ' afterRace=' .. tostring(packet[0x49]) ..
            ' afterCostume=' .. tostring(ReadCostumeId(ffiRef, packet)) ..
            ' head=' .. tostring(ReadModelWord(ffiRef, packet, 1)) ..
            ' body=' .. tostring(ReadModelWord(ffiRef, packet, 2)) ..
            ' info=' .. GetEntityDebugSummary(actIndex)
        );
    end

    local logKey = tostring(player.serverId or serverId or player.name or '');

    if (logKey ~= '' and loggedServerIds[logKey] ~= true) then
        loggedServerIds[logKey] = true;
        log.Info('Applied blacklist model replacement to ' .. tostring(player.name ~= '' and player.name or player.serverId or serverId) .. '.');
    end
end

function blacklistModelReplace.SetDebugEnabled(value)
    debugEnabled = value == true;
    debugPacketCount = 0;
end

function blacklistModelReplace.SetFomorProbeEnabled(value)
    fomorProbeEnabled = value == true;
    fomorProbePacketCount = 0;
    fomorProbeLoggedIndexes = {};
end

function blacklistModelReplace.SetFomorProbeTarget(index)
    local value = tonumber(index) or 0;

    if (value <= 0) then
        return false;
    end

    local cached = fomorProbeCache[tostring(value)];

    if (cached ~= nil) then
        LogFomorProbeInfo(cached);
        fomorProbeTargetIndex = nil;
        return true, 'cached';
    end

    LogLiveTargetProbe(value);
    fomorProbeTargetIndex = value;
    return true, 'armed';
end

function blacklistModelReplace.ClearCapturedFomorModels()
    local settings = playerBlacklist.GetModelReplaceSettings();

    settings.modelReplaceCapturedFomorModels = {};
    settings.modelReplaceFixedFomorModels = {};
    state.Save();
end

function blacklistModelReplace.SetFixedFomorModel(family, modelId)
    local key = tostring(family or ''):lower();
    local value = math.floor(tonumber(modelId) or 0);

    if (key == 'taru' or key == 'tarutaru') then
        key = 'tarutaru';
    elseif (key == 'hume' or key == 'human') then
        key = 'hume';
    elseif (key == 'elvaan' or key == 'elf') then
        key = 'elvaan';
    elseif (key == 'mithra') then
        key = 'mithra';
    elseif (key == 'galka') then
        key = 'galka';
    else
        return false, 'unknown family';
    end

    if (value <= 0 or value > 65535) then
        return false, 'invalid model id';
    end

    local settings = playerBlacklist.GetModelReplaceSettings();
    settings.modelReplaceFixedFomorModels[key] = value;
    state.Save();

    return true, key;
end

function blacklistModelReplace.SetCostumeModel(modelId)
    local value = math.floor(tonumber(modelId) or 0);
    local settings = playerBlacklist.GetModelReplaceSettings();

    if (value <= 0) then
        settings.modelReplaceUseCostume = false;
        settings.modelReplaceCostumeId = 0;
        state.Save();
        return true, 'off';
    end

    settings.modelReplaceUseCostume = false;
    settings.modelReplaceUseNpcCostume = false;
    settings.modelReplaceCostumeId = value;
    state.Save();

    return false, 'disabled';
end

function blacklistModelReplace.QueueCostumeApply(playerOrName, modelId, reason)
    return false, 'disabled';
end

function blacklistModelReplace.QueueLookApply(playerOrName, race, face, reason)
    return false, 'disabled';
end

function blacklistModelReplace.SetLiveLook(playerOrName, race, face)
    return false, 'disabled';
end

function blacklistModelReplace.SetCostumeWatch(playerOrName)
    local index, name = ResolvePlayerIndex(playerOrName);
    local player = FindNearbyPlayerByName(name);
    local entityManager = GetEntityManager();
    local serverId = nil;

    if ((index == nil or index <= 0) and player ~= nil) then
        index = tonumber(player.index);
    end

    if (index ~= nil and index > 0 and entityManager ~= nil and entityManager.GetServerId ~= nil) then
        pcall(function()
            serverId = entityManager:GetServerId(index);
        end);
    end

    if ((name == nil or name == '') and index ~= nil and index > 0) then
        name = GetEntityName(index);
    end

    if ((name == nil or name == '') and player ~= nil) then
        name = player.name;
    end

    if ((index == nil or index <= 0) and (name == nil or name == '')) then
        costumeWatch = nil;
        return false, 'player not found';
    end

    costumeWatch = {
        index = index,
        name = tostring(name or ''),
        nameKey = NormalizeName(name),
        serverId = ServerIdKey(serverId or (player ~= nil and player.serverId)),
        startedAt = os.clock(),
    };

    return true,
        'index=' .. tostring(costumeWatch.index or '') ..
        ' name=' .. tostring(costumeWatch.name or '') ..
        ' server=' .. tostring(costumeWatch.serverId or '');
end

function blacklistModelReplace.SetBlacklistWatch(playerOrName)
    local text = tostring(playerOrName or ''):gsub('^%s+', ''):gsub('%s+$', '');

    if (text == '' or text:lower() == 'off' or text:lower() == 'clear') then
        blacklistWatch = nil;
        return true, 'cleared';
    end

    local index, resolvedName = ResolveRawPlayerIndex(text);
    local serverId = nil;
    local entityManager = GetEntityManager();

    if (index ~= nil and entityManager ~= nil and entityManager.GetServerId ~= nil) then
        local okServer, value = pcall(function()
            return entityManager:GetServerId(index);
        end);

        if (okServer == true and tonumber(value) ~= nil and tonumber(value) > 0) then
            serverId = tonumber(value);
        end
    end

    local numeric = tonumber(text);
    if (serverId == nil and numeric ~= nil and (numeric < 1024 or numeric > 1791)) then
        serverId = math.floor(numeric);
    end

    blacklistWatch = {
        input = text,
        index = index,
        name = resolvedName,
        nameKey = NormalizeName(resolvedName ~= '' and resolvedName or text),
        serverId = serverId,
        untilAt = os.clock() + 180.0,
        count = 0,
        maxCount = 80,
    };

    return true,
        'input=' .. tostring(text) ..
        ' index=' .. tostring(index or '') ..
        ' name=' .. tostring(resolvedName or '') ..
        ' server=' .. tostring(serverId or '') ..
        ' seconds=180';
end

function blacklistModelReplace.ClearCostumeWatch()
    costumeWatch = nil;
end

function blacklistModelReplace.SetLiveCostume(playerOrName, modelId)
    return false, 'disabled';
end

function blacklistModelReplace.Update()
    pendingCostumeApplies = {};
    pendingLookApplies = {};
    ProcessBlacklistModelRecoveries();

    if (blacklistWatch == nil) then
        return;
    end

    local now = os.clock();

    if (now > (tonumber(blacklistWatch.untilAt) or 0)) then
        log.Info('Blacklist watch expired after 180 seconds.');
        blacklistWatch = nil;
        return;
    end

    if (now < (tonumber(blacklistWatch.nextPollAt) or 0)) then
        return;
    end

    blacklistWatch.nextPollAt = now + 0.25;

    local index = tonumber(blacklistWatch.index);

    if (index == nil or index <= 0) then
        local resolvedIndex, resolvedName = ResolveRawPlayerIndex(blacklistWatch.input);

        index = resolvedIndex;
        if (index ~= nil and index > 0) then
            blacklistWatch.index = index;
            blacklistWatch.name = resolvedName;
        end
    end

    if (index == nil or index <= 0) then
        local key = 'missing';
        if (blacklistWatch.lastStateKey ~= key) then
            blacklistWatch.lastStateKey = key;
            LogWatchLine('BL watch state player not found input=' .. tostring(blacklistWatch.input or ''));
        end
        return;
    end

    local state = GetWatchState(index);

    if (blacklistWatch.lastStateKey ~= state.key) then
        blacklistWatch.lastStateKey = state.key;
        LogWatchLine('BL watch state ' .. tostring(state.text or ''));
    end
end

function blacklistModelReplace.SetNpcCostumeModel(modelId)
    local text = tostring(modelId or ''):lower();
    local value = math.floor(tonumber(modelId) or 0);
    local settings = playerBlacklist.GetModelReplaceSettings();

    if (text == 'race' or text == 'byrace' or text == 'perrace' or text == 'fomor') then
        settings.modelReplaceUseNpcCostume = false;
        settings.modelReplaceUseCostume = false;
        settings.modelReplaceNpcCostumeByRace = true;
        settings.modelReplaceNpcCostumeId = 0;
        state.Save();
        return false, 'unsafe';
    end

    if (value <= 0) then
        settings.modelReplaceUseNpcCostume = false;
        settings.modelReplaceNpcCostumeByRace = false;
        settings.modelReplaceNpcCostumeId = 0;
        pendingClearAllUntil = os.clock() + 30.0;
        state.Save();
        return true, 'off';
    end

    settings.modelReplaceUseNpcCostume = false;
    settings.modelReplaceUseCostume = false;
    settings.modelReplaceNpcCostumeByRace = false;
    settings.modelReplaceNpcCostumeId = value;
    state.Save();

    return false, 'unsafe';
end

function blacklistModelReplace.RequestPlayerRefresh(playerOrName, clear)
    local player = type(playerOrName) == 'table' and playerOrName or FindNearbyPlayerByName(playerOrName);
    local name = type(playerOrName) == 'table' and (playerOrName.name or playerOrName.clickName) or playerOrName;

    if (clear == true) then
        MarkClear(player or name);
    end

    if (player == nil) then
        local replayed = false;
        local replayReason = 'replay disabled';
        lastRefreshStatus = 'queued clear=' .. tostring(clear == true) ..
            ' name=' .. tostring(name or '') ..
            ' nearby=false' ..
            ' replay=' .. tostring(replayed == true) ..
            ' replayReason=' .. tostring(replayReason or '');
        return false;
    end

    local replayed = false;
    local replayReason = 'replay disabled';
    local selected = PulseTarget(player.index);
    lastRefreshStatus = 'queued clear=' .. tostring(clear == true) ..
        ' name=' .. tostring(player.name or name or '') ..
        ' index=' .. tostring(player.index or '') ..
        ' replay=' .. tostring(replayed == true) ..
        ' replayReason=' .. tostring(replayReason or '') ..
        ' targetPulse=' .. tostring(selected == true);

    return replayed == true or selected == true;
end

function blacklistModelReplace.DiagnosePlayerRefresh(playerOrName)
    local index, name = ResolveRawPlayerIndex(playerOrName);
    local okEntities, entities = pcall(require, 'core.entities');
    local entityManager = GetEntityManager();

    if (index == nil or index <= 0) then
        return {
            ok = false,
            lines = {
                'Blacklist test: player not found nearby/raw: ' .. tostring(name or playerOrName or ''),
            },
        };
    end

    local before = okEntities == true and entities ~= nil and entities.GetEntityDebugInfo ~= nil
        and entities.GetEntityDebugInfo(index, 64.4)
        or nil;
    local serverId = nil;

    if (entityManager ~= nil and entityManager.GetServerId ~= nil) then
        local okServer, value = pcall(function()
            return entityManager:GetServerId(index);
        end);
        if (okServer == true) then
            serverId = value;
        end
    end

    local player = {
        index = index,
        name = before ~= nil and before.name or name,
        serverId = serverId,
    };
    local listed = playerBlacklist.IsListed(player) == true;
    local refreshed = SetModelRefreshFlags(entityManager, index);
    local selected = PulseTarget(index);
    local after = okEntities == true and entities ~= nil and entities.GetEntityDebugInfo ~= nil
        and entities.GetEntityDebugInfo(index, 64.4)
        or nil;

    return {
        ok = true,
        lines = {
            'Blacklist test: input=' .. tostring(playerOrName or '') ..
                ' index=' .. tostring(index) ..
                ' name=' .. tostring(player.name or '') ..
                ' server=' .. tostring(serverId or '') ..
                ' blacklisted=' .. FormatBool(listed),
            'Before: ' .. FormatDebugInfo(before) .. ' ' .. GetRawEntityCostumeSummary(index),
            'Pulse: selected=' .. FormatBool(selected) .. ' refreshFlags=' .. FormatBool(refreshed),
            'After: ' .. FormatDebugInfo(after) .. ' ' .. GetRawEntityCostumeSummary(index),
        },
    };
end

function blacklistModelReplace.RecoverBlacklistedPlayer(playerOrName)
    local index, name = ResolveRawPlayerIndex(playerOrName);
    local okEntities, entities = pcall(require, 'core.entities');
    local entityManager = GetEntityManager();

    if (index == nil or index <= 0) then
        return {
            ok = false,
            lines = {
                'Blacklist recover: player not found nearby/raw: ' .. tostring(name or playerOrName or ''),
            },
        };
    end

    local before = okEntities == true and entities ~= nil and entities.GetEntityDebugInfo ~= nil
        and entities.GetEntityDebugInfo(index, 64.4)
        or nil;
    local serverId = nil;

    if (entityManager ~= nil and entityManager.GetServerId ~= nil) then
        local okServer, value = pcall(function()
            return entityManager:GetServerId(index);
        end);
        if (okServer == true) then
            serverId = value;
        end
    end

    local player = {
        index = index,
        name = before ~= nil and before.name or name,
        serverId = serverId,
    };
    local listed = playerBlacklist.IsListed(player) == true;
    local costumeSet, costumeErr = SetRawEntityCostume(entityManager, index, 0);
    local typeSet, typeErr = SetRawEntityType(index, 0);
    local refreshed = SetModelRefreshFlags(entityManager, index);
    local selected = PulseTarget(index);
    local after = okEntities == true and entities ~= nil and entities.GetEntityDebugInfo ~= nil
        and entities.GetEntityDebugInfo(index, 64.4)
        or nil;

    return {
        ok = true,
        lines = {
            'Blacklist recover: input=' .. tostring(playerOrName or '') ..
                ' index=' .. tostring(index) ..
                ' name=' .. tostring(player.name or '') ..
                ' server=' .. tostring(serverId or '') ..
                ' blacklisted=' .. FormatBool(listed),
            'Before: ' .. FormatDebugInfo(before) .. ' ' .. GetRawEntityCostumeSummary(index),
            'Recover: costume0=' .. FormatBool(costumeSet) ..
                ' type0=' .. FormatBool(typeSet) ..
                ' refreshFlags=' .. FormatBool(refreshed) ..
                ' targetPulse=' .. FormatBool(selected) ..
                ' costumeErr=' .. tostring(costumeSet == true and '' or costumeErr or '') ..
                ' typeErr=' .. tostring(typeSet == true and '' or typeErr or ''),
            'After: ' .. FormatDebugInfo(after) .. ' ' .. GetRawEntityCostumeSummary(index),
        },
    };
end

function blacklistModelReplace.GetRefreshStatus(name)
    local cached = GetCachedPlayerPacket(name);

    if (cached == nil) then
        return 'refresh=' .. tostring(lastRefreshStatus) .. ' cache=none';
    end

    return 'refresh=' .. tostring(lastRefreshStatus) ..
        ' cache=name=' .. tostring(cached.name or name or '') ..
        ' server=' .. tostring(cached.serverId or '') ..
        ' bytes=' .. tostring(type(cached.bytes) == 'table' and #cached.bytes or 0) ..
        ' savedAge=' .. tostring((tonumber(cached.savedAt) or 0) > 0 and (os.time() - (tonumber(cached.savedAt) or os.time())) or 'session');
end

function blacklistModelReplace.SetPreserveRace(value)
    local settings = playerBlacklist.GetModelReplaceSettings();

    settings.modelReplacePreserveRace = value == true;
    state.Save();
end

function blacklistModelReplace.SetReplacementRace(value)
    local number, family = ResolveReplacementRace(value);

    if (number == nil) then
        return false, nil, 0;
    end

    local settings = playerBlacklist.GetModelReplaceSettings();
    local resolvedFamily = family or GetRaceFamily(number);

    settings.modelReplaceRace = number;
    settings.modelReplacePreserveRace = false;

    if (fomorModels[resolvedFamily] ~= nil) then
        settings.modelReplaceHair = fomorModels[resolvedFamily][1];
    end

    state.Save();

    return true, resolvedFamily, GetFixedFomorModelId(settings, resolvedFamily);
end

function blacklistModelReplace.GetDebugStatusText()
    local settings = playerBlacklist.GetModelReplaceSettings();
    local captured = {};
    local fixed = {};

    if (type(settings.modelReplaceCapturedFomorModels) == 'table') then
        for _, family in ipairs({ 'hume', 'elvaan', 'tarutaru', 'mithra', 'galka' }) do
            if (settings.modelReplaceCapturedFomorModels[family] ~= nil) then
                captured[#captured + 1] = family;
            end
        end
    end

    if (type(settings.modelReplaceFixedFomorModels) == 'table') then
        for _, family in ipairs({ 'hume', 'elvaan', 'tarutaru', 'mithra', 'galka' }) do
            if ((tonumber(settings.modelReplaceFixedFomorModels[family]) or 0) > 0) then
                fixed[#fixed + 1] = family .. '=' .. tostring(settings.modelReplaceFixedFomorModels[family]);
            end
        end
    end

    return 'Blacklist model replacement debug=' .. tostring(debugEnabled == true) ..
        ' packetsLogged=' .. tostring(debugPacketCount) ..
        '/40' ..
        ' fomorProbe=' .. tostring(fomorProbeEnabled == true) ..
        ' fomorPackets=' .. tostring(fomorProbePacketCount) ..
        ' targetProbe=' .. tostring(fomorProbeTargetIndex or 'none') ..
        ' captured=' .. (#captured > 0 and table.concat(captured, ',') or 'none') ..
        ' fixed=' .. (#fixed > 0 and table.concat(fixed, ',') or 'none') ..
        ' costume=' .. tostring(settings.modelReplaceUseCostume == true and settings.modelReplaceCostumeId or 'off') ..
        ' npcCostume=' .. tostring(settings.modelReplaceUseNpcCostume == true and (settings.modelReplaceNpcCostumeByRace == true and 'by-race' or settings.modelReplaceNpcCostumeId) or 'off') ..
        ' refresh=' .. tostring(lastRefreshStatus);
end

return blacklistModelReplace;
