local playerBlacklist = require('core.player_blacklist');
local log = require('core.log');

local blacklistModelReplace = {};
local loggedServerIds = {};
local debugEnabled = false;
local debugPacketCount = 0;
local fomorModels = {
    hume = { 0x05, 0x00, 0xFA, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 },
    elvaan = { 0x05, 0x00, 0xFF, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 },
    tarutaru = { 0x05, 0x00, 0x03, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 },
    mithra = { 0x05, 0x00, 0x09, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 },
    galka = { 0x05, 0x00, 0x0F, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 },
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

local function WriteModelWord(ffiRef, packet, slot, value)
    pcall(function()
        ffiRef.cast('uint16_t*', packet + 0x48)[slot] = math.max(0, math.min(65535, math.floor(tonumber(value) or 0)));
    end);
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

function blacklistModelReplace.HandlePacketIn(e)
    if (e == nil or e.blocked == true or e.id ~= 0x000D or e.data_modified_raw == nil) then
        return;
    end

    local settings = playerBlacklist.GetModelReplaceSettings();

    if (settings.modelReplaceEnabled ~= true) then
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
    local entry = playerBlacklist.GetEntry(player);
    local originalRace = packet[0x49];
    local raceFamily = GetRaceFamily(originalRace);
    local targetRace = settings.modelReplacePreserveRace ~= false and originalRace or ClampByte(settings.modelReplaceRace, 5);

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

    if (entry == nil) then
        return;
    end

    if (settings.modelReplaceUseFomor ~= false and WriteModelBytes(packet, fomorModels[raceFamily]) == true) then
        -- Full Fomor model bytes already include the placeholder body.
    elseif (settings.modelReplaceClearGear == true) then
        for slot = 1, 8 do
            WriteModelWord(ffiRef, packet, slot, 0);
        end

        packet[0x48] = ClampByte(settings.modelReplaceHair, 2);
        packet[0x49] = targetRace;
    else
        packet[0x48] = ClampByte(settings.modelReplaceHair, 2);
        packet[0x49] = targetRace;
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

function blacklistModelReplace.GetDebugStatusText()
    return 'Blacklist model replacement debug=' .. tostring(debugEnabled == true) ..
        ' packetsLogged=' .. tostring(debugPacketCount) ..
        '/40';
end

return blacklistModelReplace;
