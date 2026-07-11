local bit = require('bit');
local log = require('core.log');
local state = require('core.state');
local mounted = require('core.mounted');
local globalDefaults = require('config.global');

local mounts = {};

local cachedChoices = nil;
local cachedOwnedChoices = nil;
local cachedOwnedAt = 0;
local ownedCacheSeconds = 3.0;
local scanStartId = 3072;
local scanEndId = 3110;
local GetResourceManager = nil;
local packetOwnedMountIds = nil;
local packetOwnedAt = 0;
local packetSeenCount = 0;
local packetLastBytes = 'none';
local packetLastOffset = 'none';
local scoutUntil = 0;
local scoutSeen = {};
local scoutOrder = {};
local pendingMountName = nil;
local pendingMountUntil = 0;
local mountRecastUntil = 0;
local mountRecastDuration = 60;
local randomMountIndex = 0;
local randomMountPoolKey = '';
local lastRandomMount = nil;

local function AddUnique(list, seen, name)
    name = tostring(name or ''):gsub('^%s+', ''):gsub('%s+$', '');

    if (name == '' or seen[name] == true) then
        return;
    end

    seen[name] = true;
    list[#list + 1] = name;
end

local function ReadResourceMountNames()
    local names = T{};
    local seen = {};

    if (AshitaCore == nil or AshitaCore.GetResourceManager == nil) then
        return names;
    end

    local ok, resources = pcall(function()
        return AshitaCore:GetResourceManager();
    end);

    if (ok ~= true or resources == nil or resources.GetString == nil) then
        return names;
    end

    for id = 0, 255 do
        local readOk, name = pcall(function()
            return resources:GetString('mounts.names', id);
        end);

        if (readOk == true) then
            AddUnique(names, seen, name);
        end
    end

    return names;
end

local function ReadResourceMountName(id)
    local resources = GetResourceManager();

    if (resources == nil or resources.GetString == nil) then
        return nil;
    end

    local ok, name = pcall(function()
        return resources:GetString('mounts.names', id);
    end);

    if (ok ~= true) then
        return nil;
    end

    local choices = T{};
    local seen = {};
    AddUnique(choices, seen, name);

    return choices[1];
end

local function Trim(value)
    return tostring(value or ''):gsub('^%s+', ''):gsub('%s+$', '');
end

local function NormalizeMountKeyItemName(name)
    name = Trim(name);

    if (name == '') then
        return nil;
    end

    if (name:sub(1, 3) == '♪') then
        name = name:gsub('^♪%s*', '');
    else
        local lower = name:lower();

        if (lower:find('mount') == nil and lower:find('companion') == nil) then
            return nil;
        end
    end

    name = name:gsub('%s+companion$', '');
    name = name:gsub('%s+mount$', '');
    name = Trim(name);

    if (name == '') then
        return nil;
    end

    return name;
end

local function ReadResourceKeyItemName(id)
    local resources = GetResourceManager();

    if (resources == nil or resources.GetString == nil) then
        return nil;
    end

    for _, tableName in ipairs({ 'keyitems.names', 'key_items.names', 'keyitem.names' }) do
        local ok, name = pcall(function()
            return resources:GetString(tableName, id);
        end);
        local mountName = ok == true and NormalizeMountKeyItemName(name) or nil;

        if (mountName ~= nil) then
            return mountName;
        end
    end

    return nil;
end

GetResourceManager = function()
    if (AshitaCore == nil or AshitaCore.GetResourceManager == nil) then
        return nil;
    end

    local ok, resources = pcall(function()
        return AshitaCore:GetResourceManager();
    end);

    if (ok ~= true) then
        return nil;
    end

    return resources;
end

local function GetPlayer()
    if (AshitaCore == nil or AshitaCore.GetMemoryManager == nil) then
        return nil;
    end

    local ok, player = pcall(function()
        local memory = AshitaCore:GetMemoryManager();
        return memory ~= nil and memory:GetPlayer() or nil;
    end);

    if (ok ~= true) then
        return nil;
    end

    return player;
end

local function HasKeyItem(player, id)
    id = tonumber(id) or 0;

    if (player == nil or id <= 0) then
        return false;
    end

    local ok, value = pcall(function()
        return player:HasKeyItem(id);
    end);

    return ok == true and (value == true or tonumber(value) == 1);
end

local function IsMounted()
    return mounted.IsSelfMounted();
end

local function GetLearnedMountList()
    local global = state.GetGlobalSettings(globalDefaults);

    global.quickMenu = global.quickMenu or {};
    global.quickMenu.self = global.quickMenu.self or {};
    global.quickMenu.self.learnedMounts = global.quickMenu.self.learnedMounts or {};

    return global.quickMenu.self.learnedMounts;
end

local function LearnMountName(name)
    name = Trim(name);

    if (name == '' or mounts.IsKnown(name) ~= true) then
        return false;
    end

    local learned = GetLearnedMountList();
    local seen = {};

    for _, learnedName in ipairs(learned) do
        seen[tostring(learnedName)] = true;
    end

    if (seen[name] == true) then
        return false;
    end

    learned[#learned + 1] = name;
    cachedOwnedChoices = nil;
    pcall(function()
        state.Save();
    end);
    log.Info('Learned owned mount: ' .. name);

    return true;
end

local function ReadOwnedMountNames()
    local names = T{};
    local seen = {};
    local player = GetPlayer();

    if (type(packetOwnedMountIds) == 'table') then
        for _, mountId in ipairs(packetOwnedMountIds) do
            AddUnique(names, seen, ReadResourceMountName(mountId));
        end

        if (#names > 0) then
            return names;
        end
    end

    for _, name in ipairs(GetLearnedMountList()) do
        AddUnique(names, seen, name);
    end

    if (#names > 0) then
        return names;
    end

    if (player == nil) then
        return T{};
    end

    for id = scanStartId, scanEndId do
        if (HasKeyItem(player, id) == true) then
            AddUnique(names, seen, ReadResourceKeyItemName(id));
        end
    end

    return names;
end

function mounts.GetChoices()
    if (cachedChoices ~= nil) then
        return cachedChoices;
    end

    local choices = ReadResourceMountNames();
    local seen = {};

    for _, name in ipairs(choices) do
        seen[name] = true;
    end

    cachedChoices = choices;
    return cachedChoices;
end

function mounts.GetOwnedChoices()
    local now = os.clock();

    if (cachedOwnedChoices == nil or (now - cachedOwnedAt) >= ownedCacheSeconds) then
        cachedOwnedChoices = ReadOwnedMountNames();
        table.sort(cachedOwnedChoices, function(left, right)
            return tostring(left) < tostring(right);
        end);
        cachedOwnedAt = now;
    end

    local choices = T{};

    for _, name in ipairs(cachedOwnedChoices) do
        choices[#choices + 1] = name;
    end

    if (#choices > 0) then
        table.insert(choices, 1, 'Random');
    end

    return choices;
end

function mounts.GetRandomOwnedChoice()
    return mounts.GetRandomChoice();
end

function mounts.GetRandomChoice()
    local choices = mounts.GetOwnedChoices();
    local pool = {};

    for _, name in ipairs(choices) do
        if (name ~= 'Random') then
            pool[#pool + 1] = name;
        end
    end

    if (#pool == 0) then
        return nil;
    end

    table.sort(pool, function(left, right)
        return tostring(left) < tostring(right);
    end);

    local poolKey = table.concat(pool, '\31');
    if (randomMountPoolKey ~= poolKey) then
        randomMountPoolKey = poolKey;
        randomMountIndex = 0;
    end

    randomMountIndex = randomMountIndex + 1;
    if (randomMountIndex > #pool) then
        randomMountIndex = 1;
    end

    local choice = pool[randomMountIndex];

    if (#pool > 1 and choice == lastRandomMount) then
        randomMountIndex = randomMountIndex + 1;
        if (randomMountIndex > #pool) then
            randomMountIndex = 1;
        end
        choice = pool[randomMountIndex];
    end

    lastRandomMount = choice;
    return choice;
end

local function FormatProbeResult(label, ok, value)
    if (ok ~= true) then
        return label .. '=ERR';
    end

    if (type(value) == 'table') then
        local count = 0;

        for _, _ in pairs(value) do
            count = count + 1;
            if (count >= 8) then
                break;
            end
        end

        return label .. '=table(' .. tostring(count) .. '+)';
    end

    return label .. '=' .. tostring(value);
end

local function GetPacketData(e)
    if (e == nil) then
        return nil;
    end

    if (type(e.data_modified) == 'string') then
        return e.data_modified;
    end

    if (type(e.data) == 'string') then
        return e.data;
    end

    if (type(e.data_raw) == 'string') then
        return e.data_raw;
    end

    return nil;
end

local function FormatPacketBytes(data)
    local parts = {};
    local limit = math.min(#data, 16);

    for index = 1, limit do
        parts[#parts + 1] = string.format('%02X', string.byte(data, index) or 0);
    end

    return table.concat(parts, ' ');
end

local function FormatPacketId(id)
    return string.format('0x%03X', tonumber(id) or 0);
end

local function RecordScoutPacket(e, data, direction)
    if (os.clock() > scoutUntil) then
        return;
    end

    local id = tonumber(e.id) or 0;
    local key = tostring(direction or 'in') .. ':' .. FormatPacketId(id);

    if (scoutSeen[key] == nil) then
        scoutOrder[#scoutOrder + 1] = key;
        scoutSeen[key] = {
            count = 0,
            len = data ~= nil and #data or 0,
            bytes = data ~= nil and FormatPacketBytes(data) or 'none',
        };
    end

    scoutSeen[key].count = scoutSeen[key].count + 1;
end

local function ReadMountIdsFromPacketData(data, startOffset)
    local owned = T{};

    for byteIndex = 0, 7 do
        local value = string.byte(data, startOffset + byteIndex + 1) or 0;

        for bitIndex = 0, 7 do
            if (bit.band(value, bit.lshift(1, bitIndex)) ~= 0) then
                local mountId = (byteIndex * 8) + bitIndex;

                if (ReadResourceMountName(mountId) ~= nil) then
                    owned[#owned + 1] = mountId;
                end
            end
        end
    end

    return owned;
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

function mounts.GetDebugStatusText(includeRaw)
    local player = GetPlayer();
    local entityMountText = 'entityMountId=unavailable';
    local parts = {};
    local rawParts = {};
    local probes = {};
    local scoutText = 'idle';
    local packetText = 'nil seen=' .. tostring(packetSeenCount);

    if (type(packetOwnedMountIds) == 'table') then
        packetText = table.concat(packetOwnedMountIds, ',') .. ' age=' .. string.format('%.1f', os.clock() - packetOwnedAt)
            .. ' seen=' .. tostring(packetSeenCount) .. ' offset=' .. tostring(packetLastOffset) .. ' bytes=' .. packetLastBytes;
    end

    if (#scoutOrder > 0) then
        local scoutParts = {};

        for _, key in ipairs(scoutOrder) do
            local entry = scoutSeen[key];
            scoutParts[#scoutParts + 1] = key .. 'x' .. tostring(entry.count) .. '/len' .. tostring(entry.len) .. '/' .. entry.bytes;

            if (#scoutParts >= 12) then
                break;
            end
        end

        scoutText = table.concat(scoutParts, ' | ');
    elseif (os.clock() <= scoutUntil) then
        scoutText = 'watching';
    end

    if (player == nil) then
        return 'Mount debug: player=nil packet=' .. packetText .. ' scout=' .. scoutText;
    end

    pcall(function()
        local memory = AshitaCore:GetMemoryManager();
        local party = memory ~= nil and memory:GetParty() or nil;
        local entity = memory ~= nil and memory:GetEntity() or nil;
        local selfIndex = party ~= nil and party:GetMemberTargetIndex(0) or nil;

        if (entity ~= nil and entity.GetMountId ~= nil and selfIndex ~= nil and selfIndex > 0) then
            entityMountText = 'entityMountId=' .. tostring(entity:GetMountId(selfIndex));
        end
    end);

    for _, methodName in ipairs({ 'GetMounts', 'GetMountList', 'GetUnlockedMounts', 'GetMountMask', 'GetKeyItems' }) do
        local ok, value = pcall(function()
            return player[methodName](player);
        end);

        probes[#probes + 1] = FormatProbeResult(methodName, ok, value);
    end

    for id = (includeRaw == true and 0 or scanStartId), (includeRaw == true and 4095 or scanEndId) do
        local ok, value = pcall(function()
            return player:HasKeyItem(id);
        end);

        if (ok == true and (value == true or tonumber(value) == 1)) then
            local name = ReadResourceKeyItemName(id);

            if (name ~= nil) then
                parts[#parts + 1] = tostring(id) .. '=' .. tostring(name);
            elseif (includeRaw == true and id >= 3000 and id <= 3300) then
                rawParts[#rawParts + 1] = tostring(id);
            end
        end
    end

    if (#parts == 0) then
        if (includeRaw == true and #rawParts > 0) then
        return 'Mount debug: named=none raw3000-3300=' .. table.concat(rawParts, ',') .. ' ' .. entityMountText .. ' packet=' .. packetText .. ' scout=' .. scoutText .. ' probes=' .. table.concat(probes, ' ');
        end

        return 'Mount debug: owned=none from HasKeyItem ' .. tostring(scanStartId) .. '-' .. tostring(scanEndId) .. ' ' .. entityMountText .. ' packet=' .. packetText .. ' scout=' .. scoutText .. ' probes=' .. table.concat(probes, ' ');
    end

    local text = 'Mount debug: owned=' .. table.concat(parts, ', ');

    if (includeRaw == true and #rawParts > 0) then
        text = text .. ' raw3000-3300=' .. table.concat(rawParts, ',');
    end

    return text .. ' ' .. entityMountText .. ' packet=' .. packetText .. ' scout=' .. scoutText .. ' probes=' .. table.concat(probes, ' ');
end

function mounts.StartPacketScout(seconds)
    scoutUntil = os.clock() + math.max(5, math.min(tonumber(seconds) or 15, 60));
    scoutSeen = {};
    scoutOrder = {};
    log.Info('Mount packet scout watching for ' .. tostring(math.floor(scoutUntil - os.clock())) .. 's. Open the in-game mount menu, then run /lp mountdebug.');
end

function mounts.HandleCommandText(command)
    local text = tostring(command or '');
    local mountName = text:match('^%s*/mount%s+"([^"]+)"%s*$') or text:match("^%s*/mount%s+'([^']+)'%s*$") or text:match('^%s*/mount%s+(.+)%s*$');

    if (mountName == nil) then
        return;
    end

    mountName = Trim(mountName);

    if (mountName == '' or mountName:lower() == 'random' or mounts.IsKnown(mountName) ~= true or IsMounted() == true) then
        return;
    end

    pendingMountName = mountName;
    pendingMountUntil = os.clock() + 8.0;
end

function mounts.Update()
    if (pendingMountName == nil) then
        return;
    end

    if (IsMounted() == true) then
        LearnMountName(pendingMountName);
        pendingMountName = nil;
        pendingMountUntil = 0;
        return;
    end

    if (os.clock() > pendingMountUntil) then
        pendingMountName = nil;
        pendingMountUntil = 0;
    end
end

function mounts.IsMounted()
    return IsMounted();
end

function mounts.GetRecastProgress()
    local remaining = (tonumber(mountRecastUntil) or 0) - os.clock();

    if (remaining <= 0) then
        return nil;
    end

    return math.max(0, math.min(1, remaining / mountRecastDuration));
end

function mounts.HandlePacketIn(e)
    local data = GetPacketData(e);
    RecordScoutPacket(e, data, 'in');

    if (tonumber(e.id) == 0x119 and data ~= nil and #data >= 0x104) then
        local recastSeconds = ReadUInt32(data, 0x0FC);
        local recastId = ReadUInt32(data, 0x100);

        if (recastId == 256) then
            mountRecastUntil = os.clock() + math.max(0, math.min(mountRecastDuration, recastSeconds));
        elseif (recastSeconds == 0) then
            mountRecastUntil = 0;
        end
    end

    if (tonumber(e.id) ~= 0x0AE) then
        return;
    end

    if (data == nil or #data < 8) then
        return;
    end

    local owned = #data >= 12 and ReadMountIdsFromPacketData(data, 0x04) or T{};
    packetLastOffset = #data >= 12 and '4' or '0';

    if (#owned == 0) then
        owned = ReadMountIdsFromPacketData(data, 0x00);
        packetLastOffset = '0';
    end

    packetSeenCount = packetSeenCount + 1;
    packetLastBytes = FormatPacketBytes(data);
    packetOwnedMountIds = owned;
    packetOwnedAt = os.clock();
    cachedOwnedChoices = nil;
end

function mounts.HandlePacketOut(e)
    RecordScoutPacket(e, GetPacketData(e), 'out');
end

function mounts.IsKnown(name)
    name = tostring(name or '');

    for _, choice in ipairs(mounts.GetChoices()) do
        if (choice == name) then
            return true;
        end
    end

    return false;
end

function mounts.IsOwned(name)
    name = tostring(name or '');

    if (name == 'Random') then
        return true;
    end

    for _, choice in ipairs(mounts.GetOwnedChoices()) do
        if (choice == name) then
            return true;
        end
    end

    return false;
end

return mounts;
