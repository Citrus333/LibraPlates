require('common');

local textureLoader = require('core.texture_loader');
local log = require('core.log');
local fishingDatabase = require('core.fishing_database');
local gameMode = require('core.game_mode');

local fishing = {};
local iconTextureIds = {};
local lastResult = nil;
local lastResultClock = 0;
local resultTimeoutSeconds = 45;
local packetDebugEnabled = false;
local packetDebugUntil = 0;
local suppressCommandErrorUntil = 0;
local lastCommandErrorClock = 0;
local commandErrorRepeatCount = 0;
local commandErrorStormUntil = 0;
local postFishingLockoutUntil = 0;
local postFishingCooldownStart = 0;
local postFishingCooldownDuration = 6;
local fishingSuccessCooldownSeconds = 6;
local fishingFailureCooldownSeconds = 2;
local resultStatusConsumed = false;
local trackedSelfFishingStatus = nil;
local trackedSelfFishingStatusClock = 0;
local queuedFishCount = 0;
local lastQueuedFishClock = 0;
local lastQueuedFishSource = nil;
local lastQueuedFishStatus = nil;
local hudRevision = 0;
local lastCatchName = nil;
local lastCatchClock = 0;
local currentCatchName = nil;
local currentCatchClock = 0;
local selectedTargetName = nil;
local selectedTargetId = nil;
local sessionCatchCount = 0;
local lastFeelingLabel = nil;
local lastFeelingClock = 0;
local ventureCmdQueue = {};
local ventureCmdNextTime = 0;
local fatigue = {
    requestedClock = 0,
    updatedClock = 0,
    nextRequestClock = 0,
    ownerKey = nil,
    jstDay = nil,
    used = nil,
    cap = nil,
    remaining = nil,
    text = nil,
    mode = nil,
    pending = false,
};
local venture = {
    requestedClock = 0,
    updatedClock = 0,
    nextRequestClock = 0,
    pending = false,
    currentPool = nil,
    entries = {},
    low = '',
    mid = '',
    high = '',
    fishingRawText = '',
    text = nil,
    jstDay = nil,
};
local equipmentCache = {
    clock = 0,
    rod = '',
    bait = '',
    baitCount = nil,
};
local gearOptionsCache = {
    clock = 0,
    zoneName = nil,
    fishName = nil,
    rods = {},
    baits = {},
};
local inventoryContainerMax = 31;
local inventorySlotMax = 100;
local session = {
    active = false,
    hookClock = 0,
    parameters = nil,
    lastActionClock = 0,
    lastStaminaPercent = nil,
    maxStamina = nil,
    currentStamina = nil,
    initialStaminaPercent = nil,
    lastStaminaClock = 0,
    lastActionType = nil,
    lastGoldArrowChance = nil,
};
local iconFiles = {
    'fishing_00.png',
    'fishing_01.png',
    'fishing_02.png',
    'fishing_03.png',
    'fishing_04.png',
    'fishing_05.png',
    'fishing_06.png',
};

local function TouchHud()
    hudRevision = hudRevision + 1;
end

local function ReleaseMouseState()
end

local function CleanName(value)
    return tostring(value or ''):gsub('\170', ''):gsub('%c', ''):gsub('^%s+', ''):gsub('%s+$', '');
end

local function QueueServerCommand(delay, cmd)
    if (AshitaCore == nil or AshitaCore.GetChatManager == nil) then
        return;
    end

    local chat = AshitaCore:GetChatManager();
    if (chat == nil) then
        return;
    end

    delay = tonumber(delay) or 1;
    if (delay < 0) then
        delay = 0;
    end

    chat:QueueCommand(delay, cmd);
end

local function GetResourceItemName(itemId)
    local resource = nil;

    pcall(function()
        resource = AshitaCore:GetResourceManager():GetItemById(tonumber(itemId) or 0);
    end);

    if (resource == nil) then
        return '';
    end

    local candidates = {
        function() return resource.Name[1]; end,
        function() return resource.Name[0]; end,
        function() return resource.Name; end,
        function() return resource.NameSingular[1]; end,
        function() return resource.NameSingular[0]; end,
        function() return resource.NameSingular; end,
        function() return resource.LogNameSingular[1]; end,
        function() return resource.LogNameSingular[0]; end,
        function() return resource.LogNameSingular; end,
        function() return resource.En; end,
        function() return resource.en; end,
        function() return resource.English; end,
        function() return resource.english; end,
    };

    for _, getter in ipairs(candidates) do
        local ok, value = pcall(getter);

        if (ok == true and value ~= nil) then
            local text = CleanName(value);

            if (text ~= '' and text:find('userdata:', 1, true) == nil) then
                return text;
            end
        end
    end

    return '';
end

local function GetEquippedItemName(slot)
    local inventory = AshitaCore:GetMemoryManager():GetInventory();

    if (inventory == nil) then
        return nil;
    end

    local equippedItem = nil;
    pcall(function()
        equippedItem = inventory:GetEquippedItem(slot);
    end);

    if (equippedItem == nil or equippedItem.Index == nil or bit == nil) then
        return nil;
    end

    local index = bit.band(equippedItem.Index, 0x00FF);

    if (index <= 0) then
        return nil;
    end

    local container = bit.rshift(bit.band(equippedItem.Index, 0xFF00), 8);
    local item = nil;

    pcall(function()
        item = inventory:GetContainerItem(container, index);
    end);

    if (item == nil or tonumber(item.Id) == nil or tonumber(item.Id) == 0) then
        return nil;
    end

    return GetResourceItemName(item.Id);
end

local function GetInventoryItemCount(name)
    name = CleanName(name):lower();
    if (name == '') then
        return nil;
    end

    local inventory = AshitaCore:GetMemoryManager():GetInventory();
    if (inventory == nil) then
        return nil;
    end

    local total = 0;
    for container = 0, inventoryContainerMax do
        for index = 0, inventorySlotMax do
            local item = nil;
            pcall(function()
                item = inventory:GetContainerItem(container, index);
            end);

            if (item ~= nil and tonumber(item.Id) ~= nil and tonumber(item.Id) ~= 0) then
                local itemName = GetResourceItemName(item.Id):lower();
                if (itemName == name) then
                    total = total + (tonumber(item.Count) or 1);
                end
            end
        end
    end

    return total;
end

local function GetCurrentZoneName()
    local zoneId = nil;
    pcall(function()
        zoneId = AshitaCore:GetMemoryManager():GetParty():GetMemberZone(0);
    end);

    if (zoneId ~= nil and AshitaCore ~= nil and AshitaCore.GetResourceManager ~= nil) then
        local ok, zoneName = pcall(function()
            return AshitaCore:GetResourceManager():GetString('zones.names', zoneId);
        end);

        if (ok == true and zoneName ~= nil and tostring(zoneName) ~= '' and tostring(zoneName) ~= 'nil') then
            return CleanName(zoneName);
        end
    end

    return nil;
end

local function GetCurrentZoneId()
    local zoneId = nil;
    pcall(function()
        zoneId = AshitaCore:GetMemoryManager():GetParty():GetMemberZone(0);
    end);

    return tonumber(zoneId);
end

local function NormalizeLookupName(value)
    return CleanName(value):lower():gsub('[^%w]+', '');
end

local function GetJstDayId()
    local secondsPerDay = 60 * 60 * 24;
    local jstOffset = 9 * 60 * 60;
    return math.floor(((os.time() or 0) + jstOffset) / secondsPerDay);
end

local function ResetVentureCacheForNewJstDay()
    local day = GetJstDayId();
    if (venture.jstDay == nil) then
        venture.jstDay = day;
        return;
    end

    if (venture.jstDay ~= day) then
        venture.jstDay = day;
        venture.updatedClock = 0;
        venture.pending = false;
        venture.currentPool = nil;
        venture.entries = {};
        venture.low = '';
        venture.mid = '';
        venture.high = '';
        venture.fishingRawText = '';
        venture.text = nil;
        TouchHud();
    end
end

local function CleanChatLine(value)
    local text = tostring(value or ''):gsub(string.char(0x1E) .. '.', ''):gsub('[%z\1-\31]', '');
    text = CleanName(text);

    while (text:match('^%[[^%]]+%]%s*') ~= nil) do
        text = CleanName(text:gsub('^%[[^%]]+%]%s*', '', 1));
    end

    return text;
end

local function GetSelfPosition()
    local memory = AshitaCore:GetMemoryManager();
    local party = memory ~= nil and memory:GetParty() or nil;
    local entity = memory ~= nil and memory:GetEntity() or nil;
    local selfIndex = nil;

    pcall(function()
        selfIndex = party ~= nil and party:GetMemberTargetIndex(0) or nil;
    end);

    if (selfIndex == nil or tonumber(selfIndex) == 0 or entity == nil) then
        return nil;
    end

    local x, y, z = nil, nil, nil;
    pcall(function() x = entity:GetLocalPositionX(tonumber(selfIndex)); end);
    pcall(function() y = entity:GetLocalPositionY(tonumber(selfIndex)); end);
    pcall(function() z = entity:GetLocalPositionZ(tonumber(selfIndex)); end);

    if (tonumber(x) == nil or tonumber(y) == nil or tonumber(z) == nil) then
        return nil;
    end

    return {
        x = tonumber(x),
        y = tonumber(y),
        z = tonumber(z),
    };
end

local function GetSelfTargetIndex()
    local memory = AshitaCore:GetMemoryManager();
    local party = memory ~= nil and memory:GetParty() or nil;
    local selfIndex = nil;

    pcall(function()
        selfIndex = party ~= nil and party:GetMemberTargetIndex(0) or nil;
    end);

    return tonumber(selfIndex);
end

local function GetSelfServerId()
    local memory = AshitaCore:GetMemoryManager();
    local party = memory ~= nil and memory:GetParty() or nil;
    local serverId = nil;

    pcall(function()
        serverId = party ~= nil and party:GetMemberServerId(0) or nil;
    end);

    return tonumber(serverId) or 0;
end

local function GetSelfName()
    local memory = AshitaCore:GetMemoryManager();
    local party = memory ~= nil and memory:GetParty() or nil;
    local name = nil;

    pcall(function()
        name = party ~= nil and party:GetMemberName(0) or nil;
    end);

    return CleanName(name);
end

local function IsSelfNamedMessage(message)
    local text = CleanChatLine(message);
    local selfName = GetSelfName();

    if (text == '' or selfName == '') then
        return false;
    end

    return
        text == selfName or
        text:sub(1, #selfName + 1) == selfName .. ' ' or
        text:sub(1, #selfName + 2) == selfName .. "'s";
end

local function IsLocalFishingMessage(message)
    local text = CleanChatLine(message);

    if (text == '') then
        return false;
    end

    return
        text:sub(1, 4) == 'You ' or
        text:sub(1, 5) == 'Your ' or
        IsSelfNamedMessage(text) == true;
end

local function GetSelfGameMode()
    local selfIndex = GetSelfTargetIndex();
    if (selfIndex == nil or selfIndex <= 0) then
        return '';
    end

    return gameMode.Resolve(selfIndex, false);
end

local function GetFatigueOwnerKey(mode)
    mode = tostring(mode or GetSelfGameMode() or '');
    return tostring(GetSelfServerId()) .. ':' .. mode;
end

local function ResetFatigueCacheForCurrentOwner(mode)
    mode = tostring(mode or GetSelfGameMode() or '');
    local ownerKey = GetFatigueOwnerKey(mode);
    local jstDay = GetJstDayId();

    if (fatigue.ownerKey == nil) then
        fatigue.ownerKey = ownerKey;
        fatigue.jstDay = jstDay;
        return;
    end

    if (fatigue.ownerKey ~= ownerKey or fatigue.jstDay ~= jstDay) then
        fatigue.ownerKey = ownerKey;
        fatigue.jstDay = jstDay;
        fatigue.requestedClock = 0;
        fatigue.updatedClock = 0;
        fatigue.nextRequestClock = 0;
        fatigue.used = nil;
        fatigue.cap = nil;
        fatigue.remaining = nil;
        fatigue.text = nil;
        fatigue.mode = mode;
        fatigue.pending = false;
        TouchHud();
    end
end

local function IsFatigueExemptMode(mode)
    mode = tostring(mode or '');
    return mode == 'CW' or mode == 'UCW';
end

local function SupportsFishingFatigue(mode)
    mode = tostring(mode or '');
    return mode == 'ACE' or mode == 'WEW';
end

local function AddOwnedGear(target, kind, name, count, itemId, container, index)
    name = CleanName(name);
    local knownById = fishingDatabase.IsKnownGearById ~= nil and fishingDatabase.IsKnownGearById(kind, itemId) == true;
    if (name == '' or (knownById ~= true and fishingDatabase.IsKnownGear(kind, name) ~= true)) then
        return;
    end

    local canonicalName = CleanName(
        fishingDatabase.GetCanonicalGearNameById ~= nil and fishingDatabase.GetCanonicalGearNameById(kind, itemId, name) or
        fishingDatabase.GetCanonicalGearName(kind, name)
    );
    local key = canonicalName:lower();
    local existing = target[key];
    if (existing == nil) then
        target[key] = {
            name = canonicalName ~= '' and canonicalName or name,
            itemName = name,
            itemId = tonumber(itemId) or 0,
            container = tonumber(container),
            index = tonumber(index),
            count = tonumber(count) or 0,
            owned = true,
        };
    else
        existing.count = (tonumber(existing.count) or 0) + (tonumber(count) or 0);
        if ((tonumber(existing.itemId) or 0) == 0 and tonumber(itemId) ~= nil) then
            existing.itemId = tonumber(itemId) or 0;
            existing.itemName = name;
            existing.container = tonumber(container);
            existing.index = tonumber(index);
        end
    end
end

local function ReadOwnedFishingGear()
    local rodsByName = {};
    local baitsByName = {};
    local inventory = AshitaCore:GetMemoryManager():GetInventory();

    if (inventory == nil) then
        return {}, {};
    end

    for container = 0, inventoryContainerMax do
        for index = 0, inventorySlotMax do
            local item = nil;
            pcall(function()
                item = inventory:GetContainerItem(container, index);
            end);

            if (item ~= nil and tonumber(item.Id) ~= nil and tonumber(item.Id) ~= 0) then
                local itemName = GetResourceItemName(item.Id);
                local count = tonumber(item.Count) or 1;
                AddOwnedGear(rodsByName, 'rod', itemName, count, item.Id, container, index);
                AddOwnedGear(baitsByName, 'bait', itemName, count, item.Id, container, index);
            end
        end
    end

    return rodsByName, baitsByName;
end

local function BuildGearOptions(kind, ownedByName, suggestedByKey, equippedName, onlySuggested)
    local options = {};
    local added = {};
    local equippedLower = CleanName(equippedName):lower();
    local equippedCanonical = CleanName(fishingDatabase.GetCanonicalGearName(kind, equippedName)):lower();
    local ownedCanonical = {};

    for _, item in pairs(ownedByName or {}) do
        ownedCanonical[CleanName(fishingDatabase.GetCanonicalGearName(kind, item.name)):lower()] = true;
    end

    local function AddOption(name, owned, suggested, count, metadata)
        name = CleanName(name);
        if (name == '') then
            return nil;
        end

        local key = name:lower();
        if (added[key] == true) then
            return nil;
        end

        added[key] = true;
        local option = {
            name = name,
            owned = owned == true,
            suggested = suggested == true,
            missing = owned ~= true and suggested == true,
            count = count,
            equipped = key == equippedLower,
        };

        if (type(metadata) == 'table') then
            option.itemName = metadata.itemName;
            option.itemId = metadata.itemId;
            option.container = metadata.container;
            option.index = metadata.index;
        end

        options[#options + 1] = option;
        return option;
    end

    if (equippedName ~= nil and CleanName(equippedName) ~= '' and CleanName(equippedName) ~= 'None') then
        local owned = ownedByName[CleanName(equippedName):lower()];
        local equippedSuggested = suggestedByKey ~= nil and (suggestedByKey[CleanName(equippedName):lower()] ~= nil or suggestedByKey[equippedCanonical] ~= nil);
        if (onlySuggested ~= true or equippedSuggested == true) then
            AddOption(
                equippedName,
                true,
                equippedSuggested,
                owned ~= nil and owned.count or nil
            );
        end
    end

    local ownedOptions = {};
    for _, item in pairs(ownedByName or {}) do
        local canonical = fishingDatabase.GetCanonicalGearName(kind, item.name);
        local suggested = suggestedByKey ~= nil and (suggestedByKey[CleanName(canonical):lower()] ~= nil or suggestedByKey[CleanName(item.name):lower()] ~= nil);
        if (onlySuggested ~= true or suggested == true) then
            ownedOptions[#ownedOptions + 1] = {
                name = item.name,
                itemName = item.itemName,
                itemId = item.itemId,
                container = item.container,
                index = item.index,
                count = item.count,
                suggested = suggested,
            };
        end
    end

    table.sort(ownedOptions, function(left, right)
        if (left.suggested ~= right.suggested) then
            return left.suggested == true;
        end

        return tostring(left.name):lower() < tostring(right.name):lower();
    end);

    for _, item in ipairs(ownedOptions) do
        AddOption(item.name, true, item.suggested, item.count, item);
    end

    local missingOptions = {};
    for _, name in pairs(suggestedByKey or {}) do
        local owned = ownedByName[CleanName(name):lower()] ~= nil or ownedCanonical[CleanName(fishingDatabase.GetCanonicalGearName(kind, name)):lower()] == true;
        if (owned ~= true) then
            missingOptions[#missingOptions + 1] = name;
        end
    end

    table.sort(missingOptions, function(left, right)
        return tostring(left):lower() < tostring(right):lower();
    end);

    for _, name in ipairs(missingOptions) do
        AddOption(name, false, true, nil);
    end

    return options;
end

local function GetGearOptions(zoneName, fishName, fishId)
    local now = os.clock();
    local zoneKey = CleanName(zoneName);
    local fishKey = CleanName(fishName);

    if (
        (now - (tonumber(gearOptionsCache.clock) or 0)) < 3.0 and
        gearOptionsCache.zoneName == zoneKey and
        gearOptionsCache.fishName == fishKey .. ':' .. tostring(fishId or '')
    ) then
        return gearOptionsCache.rods, gearOptionsCache.baits;
    end

    local ownedRods, ownedBaits = ReadOwnedFishingGear();
    local suggested = fishingDatabase.GetSuggestedGear(zoneName, fishName, fishId);
    local suggestedRods = {};
    local suggestedBaits = {};

    for key, name in pairs(suggested ~= nil and suggested.rods or {}) do
        suggestedRods[CleanName(fishingDatabase.GetCanonicalGearName('rod', name)):lower()] = name;
        suggestedRods[CleanName(key):lower()] = name;
    end

    for key, name in pairs(suggested ~= nil and suggested.baits or {}) do
        suggestedBaits[CleanName(fishingDatabase.GetCanonicalGearName('bait', name)):lower()] = name;
        suggestedBaits[CleanName(key):lower()] = name;
    end

    gearOptionsCache.clock = now;
    gearOptionsCache.zoneName = zoneKey;
    gearOptionsCache.fishName = fishKey .. ':' .. tostring(fishId or '');
    local hasTargetFish = fishKey ~= '' and fishKey ~= 'None';
    gearOptionsCache.rods = BuildGearOptions('rod', ownedRods, suggestedRods, equipmentCache.rod);
    gearOptionsCache.baits = BuildGearOptions('bait', ownedBaits, suggestedBaits, equipmentCache.bait, hasTargetFish);

    return gearOptionsCache.rods, gearOptionsCache.baits;
end

local function EscapeCommandText(value)
    return tostring(value or ''):gsub('"', '\\"');
end

function fishing.EquipFishingItem(slot, name)
    local itemName = CleanName(name);
    if (itemName == '') then
        return false;
    end

    local equipSlot = tostring(slot or ''):lower();
    if (equipSlot ~= 'range' and equipSlot ~= 'ammo') then
        return false;
    end

    AshitaCore:GetChatManager():QueueCommand(-1, '/equip ' .. equipSlot .. ' "' .. EscapeCommandText(itemName) .. '"');
    equipmentCache.clock = 0;
    gearOptionsCache.clock = 0;
    TouchHud();
    return true;
end

function fishing.SetTargetFish(name, fishId)
    local value = CleanName(name);
    if (value == '' or value == 'Auto' or value == 'Any') then
        selectedTargetName = nil;
        selectedTargetId = nil;
    else
        selectedTargetName = value;
        selectedTargetId = tonumber(fishId);
    end

    gearOptionsCache.clock = 0;
    TouchHud();
    return true;
end

local function ExtractCaughtName(message)
    if (IsLocalFishingMessage(message) ~= true) then
        return nil;
    end

    local catchName = tostring(message or ''):match('caught an? ([^!%.]+)');

    if (catchName == nil or catchName == '') then
        return nil;
    end

    return CleanName(catchName);
end

local function ExtractRevealedCatchName(message)
    local catchName = tostring(message or ''):match('pull of an? ([^!%.]+)');

    if (catchName == nil or catchName == '') then
        return nil;
    end

    return CleanName(catchName);
end

local function ParseFatigueMessage(message)
    local text = tostring(message or ''):gsub(string.char(0x1E) .. '.', ''):gsub('[%z\1-\31]', '');
    local lower = text:lower();
    if (
        lower:find('fatigue', 1, true) == nil and
        lower:find('daily cap', 1, true) == nil and
        lower:find('daily fishing limit', 1, true) == nil
    ) then
        return nil;
    end

    local used, cap = text:match("[Yy]ou'?ve caught%s+(%d+)%s*/%s*(%d+)%s+of your daily fishing limit");
    if (used == nil) then
        used, cap = text:match('(%d+)%s*/%s*(%d+)');
    end
    if (used == nil) then
        used, cap = text:match('(%d+)%s+of%s+(%d+)');
    end
    if (used == nil) then
        used, cap = text:match('(%d+)%s+/%s+(%d+)');
    end

    local remaining = text:match('(%d+)%s+remaining') or text:match('remaining%s*:?%s*(%d+)');
    local parsed = {
        raw = CleanName(text),
        used = tonumber(used),
        cap = tonumber(cap),
        remaining = tonumber(remaining),
    };

    if (parsed.used ~= nil and parsed.cap ~= nil and parsed.remaining == nil) then
        parsed.remaining = math.max(0, parsed.cap - parsed.used);
    elseif (parsed.remaining ~= nil and parsed.cap ~= nil and parsed.used == nil) then
        parsed.used = math.max(0, parsed.cap - parsed.remaining);
    end

    if (parsed.used == nil and parsed.cap == nil and parsed.remaining == nil and parsed.raw == '') then
        return nil;
    end

    return parsed;
end

local function UpdateFatigueFromMessage(message)
    local now = os.clock();
    if (fatigue.pending ~= true and (now - (tonumber(fatigue.requestedClock) or 0)) > 8.0) then
        return false;
    end

    local parsed = ParseFatigueMessage(message);
    if (parsed == nil) then
        return false;
    end

    local mode = GetSelfGameMode();
    ResetFatigueCacheForCurrentOwner(mode);
    fatigue.used = parsed.used;
    fatigue.cap = parsed.cap;
    fatigue.remaining = parsed.remaining;
    fatigue.text = parsed.raw;
    fatigue.mode = mode;
    fatigue.updatedClock = now;
    fatigue.pending = false;
    TouchHud();
    return true;
end

local function RequestFatigue(settings, force)
    settings = settings or {};
    if (settings.showFatigue ~= true) then
        return;
    end

    local mode = GetSelfGameMode();
    ResetFatigueCacheForCurrentOwner(mode);
    fatigue.mode = mode;
    if (SupportsFishingFatigue(mode) ~= true) then
        return;
    end

    local now = os.clock();
    if (force ~= true and now < (tonumber(fatigue.nextRequestClock) or 0)) then
        return;
    end

    fatigue.requestedClock = now;
    fatigue.nextRequestClock = now + 300;
    fatigue.pending = true;
    pcall(function()
        AshitaCore:GetChatManager():QueueCommand(-1, '!fatigue');
    end);
end

local function FormatFatigue()
    local mode = GetSelfGameMode();
    ResetFatigueCacheForCurrentOwner(mode);
    fatigue.mode = mode;

    if (IsFatigueExemptMode(mode) == true) then
        return {
            mode = mode,
            exempt = true,
            text = 'Exempt',
        };
    end

    if (SupportsFishingFatigue(mode) ~= true) then
        return {
            mode = mode,
            text = 'Unavailable',
        };
    end

    if (fatigue.used ~= nil and fatigue.cap ~= nil) then
        local text = tostring(fatigue.used) .. ' / ' .. tostring(fatigue.cap);
        if (fatigue.remaining ~= nil) then
            text = text .. ' (' .. tostring(fatigue.remaining) .. ' left)';
        end

        return {
            mode = mode,
            used = fatigue.used,
            cap = fatigue.cap,
            remaining = fatigue.remaining,
            text = text,
            age = fatigue.updatedClock > 0 and (os.clock() - fatigue.updatedClock) or nil,
        };
    end

    return {
        mode = mode,
        pending = fatigue.pending == true,
        text = fatigue.pending == true and 'Checking...' or 'Waiting for data',
    };
end

local function ParseVentureEntries(pool, text)
    pool = tostring(pool or ''):upper();
    text = tostring(text or '');

    if (pool ~= 'A' and pool ~= 'B') then
        return 0;
    end

    local count = 0;
    for minLevel, maxLevel, zoneName, percent in text:gmatch('%((%d+)%s*%-%s*(%d+)%)%s*([^@]+)@%s*(%d+)%%') do
        zoneName = CleanName(tostring(zoneName or ''):gsub(',%s*$', ''));
        if (zoneName ~= '') then
            for splitZone in zoneName:gmatch('[^,]+') do
                splitZone = CleanName(splitZone);
                if (splitZone ~= '') then
                    table.insert(venture.entries, {
                        pool = pool,
                        minLevel = tonumber(minLevel),
                        maxLevel = tonumber(maxLevel),
                        zone = splitZone,
                        percent = tonumber(percent),
                    });
                    count = count + 1;
                end
            end
        end
    end

    return count;
end

local function UpdateFishingVentureEntriesFromRaw()
    local raw = CleanName(venture.fishingRawText):gsub('%s+', ' ');
    raw = raw:gsub(' ,', ','):gsub(',%s*,', ','):gsub('%s+$', '');

    if (raw == '') then
        venture.entries = {};
        venture.low = '';
        venture.mid = '';
        venture.high = '';
        return false;
    end

    local entries = {};
    local items = {};

    for part in raw:gmatch('[^,]+') do
        part = CleanName(part);
        local range, name = part:match('^%(([^)]+)%)%s*(.+)$');

        if (range == nil or name == nil) then
            name, range = part:match('^(.+)%s+%(([^)]+)%)$');
        end

        range = CleanName(range);
        name = CleanName(name);

        if (range ~= '' and name ~= '') then
            items[#items + 1] = string.format('%s (%s)', name, range);

            local minLevel, maxLevel = range:match('^(%d+)%s*%-%s*(%d+)$');
            entries[#entries + 1] = {
                fish = name,
                minLevel = tonumber(minLevel),
                maxLevel = tonumber(maxLevel),
                range = range,
            };
        end
    end

    if (#items == 0) then
        return false;
    end

    local function JoinItems(a, b)
        local values = {};
        if (a ~= nil and a ~= '') then
            values[#values + 1] = a;
        end
        if (b ~= nil and b ~= '') then
            values[#values + 1] = b;
        end
        return table.concat(values, ', ');
    end

    venture.entries = entries;
    venture.low = JoinItems(items[1], items[2]);
    venture.mid = JoinItems(items[3], items[4]);

    local high = {};
    for index = 5, #items do
        high[#high + 1] = items[index];
    end
    venture.high = table.concat(high, ', ');

    venture.currentPool = nil;
    venture.text = nil;
    venture.updatedClock = os.clock();
    venture.pending = false;
    TouchHud();
    return true;
end

local function UpdateVentureFromMessage(message)
    ResetVentureCacheForNewJstDay();

    local text = CleanChatLine(message);

    if (text == '' or text:find('!ventures', 1, true) ~= nil) then
        return false;
    end

    local fishingRest = text:match('^Fishing:%s*(.+)$');
    if (fishingRest ~= nil) then
        venture.fishingRawText = fishingRest;
        return UpdateFishingVentureEntriesFromRaw();
    end

    if (venture.fishingRawText ~= '' and text:match('^%(%d') ~= nil) then
        venture.fishingRawText = venture.fishingRawText .. ' ' .. text;
        return UpdateFishingVentureEntriesFromRaw();
    end

    local pool, rest = text:match('^Pool%s+([AB]):%s*(.+)$');
    if (pool ~= nil and rest ~= nil) then
        pool = tostring(pool):upper();
        if (pool == 'A') then
            venture.entries = {};
            venture.low = '';
            venture.mid = '';
            venture.high = '';
        end
        venture.currentPool = pool;
        local parsed = ParseVentureEntries(pool, rest);
        if (parsed > 0) then
            venture.updatedClock = os.clock();
            venture.pending = false;
            TouchHud();
            return true;
        end
    end

    if (
        venture.currentPool ~= nil and
        text:find('(', 1, true) ~= nil and
        text:find('@', 1, true) ~= nil
    ) then
        local parsed = ParseVentureEntries(venture.currentPool, text);
        if (parsed > 0) then
            venture.updatedClock = os.clock();
            venture.pending = false;
            TouchHud();
            return true;
        end
    end

    return false;
end

local function IsRecentRequestedVentureLine(message)
    local now = os.clock();
    if ((now - (tonumber(venture.requestedClock) or 0)) > 12.0) then
        return false;
    end

    local text = CleanChatLine(message);
    if (text == '') then
        return false;
    end

    return
        text:find('!ventures', 1, true) ~= nil or
        text:find("Today's Goblin Ventures", 1, true) ~= nil or
        text:match('^Fishing:%s*') ~= nil or
        text:match('^Pool%s+[AB]:%s*') ~= nil or
        text:match('^%(%d+%-%d+%)%s+') ~= nil;
end

local function RequestVenture(force)
    ResetVentureCacheForNewJstDay();

    local now = os.clock();
    if (force ~= true and now < (tonumber(venture.nextRequestClock) or 0)) then
        return;
    end

    if (venture.low ~= '' or venture.mid ~= '' or venture.high ~= '') then
        return;
    end

    venture.requestedClock = now;
    venture.nextRequestClock = now + 300;
    venture.pending = true;
    ventureCmdQueue = {
        '!ventures fishing',
    };
    ventureCmdNextTime = os.clock() + 2.0;

    TouchHud();
end

function fishing.HandlePresent()
    if (type(ventureCmdQueue) ~= 'table' or #ventureCmdQueue == 0) then
        return;
    end

    local now = os.clock();
    if (now < (tonumber(ventureCmdNextTime) or 0)) then
        return;
    end

    local cmd = table.remove(ventureCmdQueue, 1);
    if (cmd ~= nil and cmd ~= '') then
        QueueServerCommand(1, cmd);
    end

    ventureCmdNextTime = now + 3.5;
end

local function FormatVenture(zoneName)
    ResetVentureCacheForNewJstDay();

    zoneName = CleanName(zoneName);
    local now = os.clock();

    if (venture.pending == true and (now - (tonumber(venture.requestedClock) or 0)) > 12.0) then
        venture.pending = false;
        if (venture.updatedClock == 0) then
            venture.nextRequestClock = math.min(tonumber(venture.nextRequestClock) or now, now + 30);
        end
    end

    if (venture.low ~= '' or venture.mid ~= '' or venture.high ~= '') then
        return {
            loaded = true,
            low = venture.low,
            mid = venture.mid,
            high = venture.high,
        };
    end

    if (type(venture.entries) == 'table' and #venture.entries > 0) then
        local zoneKey = NormalizeLookupName(zoneName);
        local matches = {};

        if (zoneKey ~= '') then
            for _, entry in ipairs(venture.entries) do
                if (NormalizeLookupName(entry.zone) == zoneKey) then
                    local range = '?';
                    if (entry.minLevel ~= nil and entry.maxLevel ~= nil) then
                        range = tostring(entry.minLevel) .. '-' .. tostring(entry.maxLevel);
                    end

                    local percent = entry.percent ~= nil and (' @' .. tostring(entry.percent) .. '%') or '';
                    table.insert(matches, 'Pool ' .. tostring(entry.pool) .. ' ' .. range .. percent);
                end
            end
        end

        if (#matches > 0) then
            return {
                loaded = true,
                low = table.concat(matches, ', '),
                mid = '',
                high = '',
            };
        end

        return {
            loaded = true,
            low = 'No venture here',
            mid = '',
            high = '',
        };
    end

    if (venture.pending == true) then
        return {
            loaded = false,
            text = 'Checking...',
        };
    end

    return {
        loaded = false,
        text = 'Not loaded',
    };
end
local gutFeelingResults = {
    {
        pattern = "You didn't catch anything",
        label = "You didn't catch anything",
        iconFile = 'fishing_00.png',
    },
    {
        pattern = 'You have a good feeling about this one!',
        label = 'Easy catch',
        iconFile = 'fishing_01.png',
    },
    {
        pattern = "You don't know if you have enough skill to reel this one in.",
        label = 'Moderate catch',
        iconFile = 'fishing_02.png',
    },
    {
        pattern = "You're fairly sure you don't have enough skill to reel this one in.",
        label = 'Hard catch',
        iconFile = 'fishing_03.png',
    },
    {
        pattern = "You're positive you don't have enough skill to reel this one in!",
        label = 'Very difficult catch',
        iconFile = 'fishing_04.png',
    },
    {
        pattern = 'You have a bad feeling about this one.',
        label = 'Extreme catch',
        iconFile = 'fishing_05.png',
    },
    {
        pattern = 'You have a terrible feeling about this one...',
        label = 'Dangerous catch',
        iconFile = 'fishing_06.png',
    },
};

local fishingStatuses = {
    [38] = true, -- Fishing fighting
    [39] = true, -- Fishing caught
    [40] = true, -- Fishing broken rod
    [41] = true, -- Fishing broken line
    [42] = true, -- Fishing caught monster
    [43] = true, -- Fishing lost catch
    [50] = true, -- Fishing
    [51] = true, -- Fishing fighting center
    [52] = true, -- Fishing fighting right
    [53] = true, -- Fishing fighting left
    [56] = true, -- Fishing rod in water
    [57] = true, -- Fishing fish on hook
    [58] = true, -- Fishing caught fish
    [59] = true, -- Fishing rod break
    [60] = true, -- Fishing line break
    [61] = true, -- Fishing monster catch
    [62] = true, -- Fishing no catch or lost
};

local fishingActiveStatuses = {
    [38] = true,
    [50] = true,
    [51] = true,
    [52] = true,
    [53] = true,
    [56] = true,
    [57] = true,
};

local fishingResultStatuses = {
    [39] = true,
    [40] = true,
    [41] = true,
    [42] = true,
    [43] = true,
    [58] = true,
    [59] = true,
    [60] = true,
    [61] = true,
    [62] = true,
};

local fishingFailureResultStatuses = {
    [40] = true, -- Fishing broken rod
    [41] = true, -- Fishing broken line
    [43] = true, -- Fishing lost catch
    [59] = true, -- Fishing rod break
    [60] = true, -- Fishing line break
    [62] = true, -- Fishing no catch or lost
};

function fishing.IsFishingStatus(status)
    return fishingStatuses[tonumber(status) or 0] == true;
end

function fishing.IsFishingActiveStatus(status)
    return fishingActiveStatuses[tonumber(status) or 0] == true;
end

function fishing.IsFishingResultStatus(status)
    return fishingResultStatuses[tonumber(status) or 0] == true;
end

local function GetResultCooldownSeconds(status)
    if (fishingFailureResultStatuses[tonumber(status) or 0] == true) then
        return fishingFailureCooldownSeconds;
    end

    return fishingSuccessCooldownSeconds;
end

local function GetSelfFishingStatus()
    if (trackedSelfFishingStatus ~= nil) then
        return tonumber(trackedSelfFishingStatus);
    end

    local memory = AshitaCore:GetMemoryManager();
    local party = memory ~= nil and memory:GetParty() or nil;
    local entity = memory ~= nil and memory:GetEntity() or nil;
    local selfIndex = nil;

    pcall(function()
        selfIndex = party ~= nil and party:GetMemberTargetIndex(0) or nil;
    end);

    if (selfIndex == nil or tonumber(selfIndex) == 0 or entity == nil or entity.GetStatus == nil) then
        return nil;
    end

    local status = nil;
    pcall(function()
        status = entity:GetStatus(tonumber(selfIndex));
    end);

    return tonumber(status);
end

local function IsSelfFishingStatus()
    return fishing.IsFishingActiveStatus(GetSelfFishingStatus()) == true;
end

local function IsTrackedSelfFishingStatus()
    return trackedSelfFishingStatus ~= nil and fishing.IsFishingActiveStatus(trackedSelfFishingStatus) == true;
end

local function IsSelfFishingResultStatus()
    return fishing.IsFishingResultStatus(GetSelfFishingStatus()) == true;
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

    return value;
end

local function PacketDebugActive()
    if (packetDebugEnabled ~= true) then
        return false;
    end

    if (packetDebugUntil > 0 and os.clock() > packetDebugUntil) then
        packetDebugEnabled = false;
        packetDebugUntil = 0;
        return false;
    end

    return true;
end

local function FormatParameters(parameters)
    local parts = {};

    for index = 1, #(parameters or {}) do
        parts[#parts + 1] = tostring(parameters[index]);
    end

    return table.concat(parts, ',');
end

local function GetStaminaBaseCandidates(parameters)
    local stamina = tonumber(parameters ~= nil and parameters[1]);
    local candidates = {};

    if (stamina == nil or stamina <= 0) then
        return candidates;
    end

    for roll = 95, 105 do
        if ((stamina % roll) == 0) then
            candidates[#candidates + 1] = math.floor(stamina / roll);
        end
    end

    return candidates;
end

local function GetStaminaBaseText(parameters)
    local candidates = GetStaminaBaseCandidates(parameters);

    if (#candidates == 0) then
        return nil;
    end

    local parts = {};

    for index = 1, #candidates do
        parts[#parts + 1] = tostring(candidates[index]);
    end

    return table.concat(parts, '/');
end

local function UpdateLocalStamina()
    if (fishing.IsSessionActive() ~= true or session.parameters == nil) then
        return;
    end

    local now = os.clock();
    local current = tonumber(session.currentStamina);
    local maximum = tonumber(session.maxStamina);
    if (current == nil or maximum == nil or maximum <= 0) then
        return;
    end

    local lastClock = tonumber(session.lastStaminaClock) or now;
    local elapsed = math.max(0, now - lastClock);
    session.lastStaminaClock = now;

    if (elapsed <= 0) then
        return;
    end

    local regen = tonumber(session.parameters[3]) or 128;
    local gameTime = math.max(6, math.min(24, (tonumber(session.parameters[7]) or 40) * 0.35));
    local drainPerSecond = 100 / gameTime;
    local regenBiasPerSecond = (regen - 128) * 0.25;
    local driftPerSecond = regenBiasPerSecond - drainPerSecond;

    if (driftPerSecond ~= 0) then
        session.currentStamina = math.max(0, math.min(maximum, current + (driftPerSecond * elapsed)));
    end
end

local function GetLiveStaminaPercent()
    if (fishing.IsSessionActive() ~= true or session.parameters == nil) then
        return nil;
    end

    UpdateLocalStamina();

    local current = tonumber(session.currentStamina);
    local maximum = tonumber(session.maxStamina);
    if (current == nil or maximum == nil or maximum <= 0) then
        return nil;
    end

    local progress = (current / maximum) * 100;
    session.lastStaminaPercent = progress;

    return math.max(0, math.min(100, progress));
end

function fishing.GetStaminaBarState(settings)
    settings = settings or {};

    if (settings.showStaminaBar == false) then
        return nil;
    end

    if (fishing.ShouldCaptureFishBar() ~= true) then
        return nil;
    end

    local nativeTargetArrow = package.loaded ~= nil and package.loaded['core.native_target_arrow'] or nil;
    local localProgress = GetLiveStaminaPercent();
    if (nativeTargetArrow ~= nil and nativeTargetArrow.GetFishingBarState ~= nil) then
        local nativeState = nativeTargetArrow.GetFishingBarState(1.5);
        if (nativeState ~= nil and tonumber(nativeState.progress) ~= nil) then
            local progress = math.max(0, math.min(100, tonumber(nativeState.progress) or 0));
            local sessionAge = os.clock() - (tonumber(session.hookClock) or 0);
            if (progress <= 1 and tonumber(localProgress) ~= nil and localProgress > 50 and sessionAge >= 0 and sessionAge <= 2.0) then
                progress = localProgress;
            end
            return {
                progress = progress,
                text = tostring(math.floor(progress + 0.5)) .. '%',
                labelText = 'Fish stamina',
                baseStamina = GetStaminaBaseText(session.parameters),
                live = true,
                source = nativeState.source or 'native-geometry',
            };
        end
    end

    if (tonumber(localProgress) ~= nil) then
        local progress = math.max(0, math.min(100, tonumber(localProgress) or 0));
        return {
            progress = progress,
            text = tostring(math.floor(progress + 0.5)) .. '%',
            labelText = 'Fish stamina',
            baseStamina = GetStaminaBaseText(session.parameters),
            live = true,
            source = 'session',
        };
    end

    return nil;
end

function fishing.GetStaminaSignature()
    local progress = GetLiveStaminaPercent();

    if (progress == nil) then
        return 'none';
    end

    return table.concat({
        tostring(math.floor(progress + 0.5)),
        tostring(GetStaminaBaseText(session.parameters) or ''),
        tostring(session.lastActionType or ''),
    }, ':');
end

function fishing.EnablePacketDebugForSeconds(seconds)
    packetDebugEnabled = true;
    packetDebugUntil = os.clock() + math.max(1, tonumber(seconds) or 30);
end

function fishing.SetPacketDebugEnabled(value)
    packetDebugEnabled = value == true;
    packetDebugUntil = 0;
end

function fishing.GetPacketDebugEnabled()
    return PacketDebugActive() == true;
end

function fishing.MarkFishCommandAttempt(seconds)
    suppressCommandErrorUntil = math.max(
        suppressCommandErrorUntil,
        os.clock() + math.max(1, tonumber(seconds) or 4)
    );
end

function fishing.MarkFishCommandQueued(source, status)
    queuedFishCount = queuedFishCount + 1;
    lastQueuedFishClock = os.clock();
    lastQueuedFishSource = tostring(source or 'unknown');
    lastQueuedFishStatus = tostring(status or '');
    TouchHud();
end

function fishing.MarkFishingEnded(seconds, replace)
    local now = os.clock();
    local duration = math.max(1, tonumber(seconds) or 6);
    local untilClock = now + duration;

    ReleaseMouseState();
    postFishingCooldownStart = now;
    postFishingCooldownDuration = duration;
    if (replace == true) then
        postFishingLockoutUntil = untilClock;
    else
        postFishingLockoutUntil = math.max(postFishingLockoutUntil, untilClock);
    end
    suppressCommandErrorUntil = math.max(suppressCommandErrorUntil, untilClock);
    TouchHud();
end

function fishing.IsPostFishingLockout()
    return os.clock() <= (tonumber(postFishingLockoutUntil) or 0);
end

function fishing.GetPostFishingCooldown()
    local now = os.clock();
    local selfStatus = GetSelfFishingStatus();
    if (fishing.IsFishingResultStatus(selfStatus) == true) then
        if (resultStatusConsumed ~= true) then
            resultStatusConsumed = true;
            if (now > (tonumber(postFishingLockoutUntil) or 0)) then
                fishing.MarkFishingEnded(GetResultCooldownSeconds(selfStatus));
            end
        end
    else
        resultStatusConsumed = false;
    end

    local remaining = math.max(0, (tonumber(postFishingLockoutUntil) or 0) - now);
    local duration = math.max(1, tonumber(postFishingCooldownDuration) or 6);
    local progress = 1 - (remaining / duration);

    if (remaining <= 0) then
        return {
            active = false,
            remaining = 0,
            duration = duration,
            progress = 1,
        };
    end

    return {
        active = true,
        remaining = remaining,
        duration = duration,
        progress = math.max(0, math.min(1, progress)),
        started = postFishingCooldownStart,
    };
end

function fishing.IsSessionActive()
    if (session.active ~= true) then
        return false;
    end

    if ((os.clock() - (tonumber(session.hookClock) or 0)) > 75) then
        session.active = false;
        return false;
    end

    return true;
end

function fishing.ShouldCaptureFishBar()
    return fishing.IsSessionActive() == true or IsSelfFishingStatus() == true or IsTrackedSelfFishingStatus() == true;
end

function fishing.ShouldSuppressCommandErrorText()
    if (fishing.IsSessionActive() == true) then
        return true;
    end

    local now = os.clock();
    return now <= (tonumber(suppressCommandErrorUntil) or 0) or now <= (tonumber(commandErrorStormUntil) or 0);
end

function fishing.HandlePacketIn(e)
    if (e == nil) then
        return;
    end

    if (e.id == 0x000A) then
        trackedSelfFishingStatus = nil;
        trackedSelfFishingStatusClock = 0;
        session.active = false;
        session.parameters = nil;
        session.maxStamina = nil;
        session.currentStamina = nil;
        session.initialStaminaPercent = nil;
        session.lastStaminaClock = 0;
        return;
    end

    if (e.id == 0x0037) then
        local data = e.data_modified or e.data;
        local status = Read(data, 'B', 0x30);

        if (status ~= nil) then
            trackedSelfFishingStatus = tonumber(status) or 0;
            trackedSelfFishingStatusClock = os.clock();

            if (trackedSelfFishingStatus == 0) then
                session.active = false;
                session.parameters = nil;
                session.maxStamina = nil;
                session.currentStamina = nil;
                session.initialStaminaPercent = nil;
                session.lastStaminaClock = 0;
                resultStatusConsumed = false;
            elseif (fishing.IsFishingResultStatus(trackedSelfFishingStatus) == true) then
                session.active = false;
                if (resultStatusConsumed ~= true) then
                    resultStatusConsumed = true;
                    fishing.MarkFishingEnded(GetResultCooldownSeconds(trackedSelfFishingStatus));
                else
                    TouchHud();
                end
            elseif (fishing.IsFishingActiveStatus(trackedSelfFishingStatus) == true) then
                TouchHud();
            end
        end

        return;
    end

    if (e.id ~= 0x0115) then
        return;
    end

    local data = e.data_modified or e.data;
    local parameters = {};

    for index = 0, 7 do
        parameters[#parameters + 1] = Read(data, 'H', 0x04 + (index * 2)) or 0;
    end

    parameters[#parameters + 1] = Read(data, 'L', 0x14) or 0;

    session.active = true;
    session.hookClock = os.clock();
    postFishingLockoutUntil = 0;
    postFishingCooldownStart = 0;
    session.parameters = parameters;
    session.initialStaminaPercent = 100;
    session.currentStamina = 100;
    session.maxStamina = 100;
    session.lastStaminaClock = os.clock();
    session.lastStaminaPercent = 100;
    session.lastActionType = nil;
    session.lastGoldArrowChance = nil;
    TouchHud();

    if (PacketDebugActive() == true) then
        log.Info(
            'Fishing packet 0x115 parameters=' .. FormatParameters(parameters) ..
            ' baseStamina=' .. tostring(GetStaminaBaseText(parameters)) ..
            ' maxStamina=' .. tostring(session.maxStamina) ..
            ' initialPercent=' .. tostring(session.initialStaminaPercent) ..
            ' gameTime=' .. tostring(parameters[7]) ..
            ' regen=' .. tostring(parameters[3]) ..
            ' intuition=' .. tostring(parameters[9])
        );
    end
end

function fishing.HandlePacketOut(e)
    if (e == nil or e.id ~= 0x0110) then
        return;
    end

    local data = e.data_modified or e.data;
    local staminaPercent = Read(data, 'L', 0x08);
    local actionType = Read(data, 'H', 0x0E);
    local goldArrowChance = Read(data, 'L', 0x10);

    if (tonumber(actionType) == 2 or tonumber(actionType) == 4 or tonumber(actionType) == 5) then
        return;
    end

    if (tonumber(actionType) == 3) then
        if (tonumber(staminaPercent) ~= nil and tonumber(staminaPercent) >= 0 and tonumber(staminaPercent) <= (tonumber(session.maxStamina) or 0)) then
            session.currentStamina = tonumber(staminaPercent);
            session.lastStaminaPercent = ((tonumber(session.currentStamina) or 0) / math.max(1, tonumber(session.maxStamina) or 1)) * 100;
        end
        session.active = false;
        fishing.MarkFishingEnded(fishingSuccessCooldownSeconds);
    else
        session.active = true;
    end

    session.lastActionClock = os.clock();
    session.lastActionType = tonumber(actionType);
    session.lastGoldArrowChance = tonumber(goldArrowChance);
    TouchHud();

    if (PacketDebugActive() == true) then
        log.Info(
            'Fishing packet 0x110 stamina=' .. tostring(staminaPercent) ..
            ' action=' .. tostring(actionType) ..
            ' gold=' .. tostring(goldArrowChance)
        );
    end
end

function fishing.GetPacketDebugStatus()
    return 'fishPackets=' .. tostring(PacketDebugActive() == true) ..
        ' active=' .. tostring(session.active == true) ..
        ' params=' .. tostring(session.parameters ~= nil and FormatParameters(session.parameters) or 'nil') ..
        ' baseStamina=' .. tostring(GetStaminaBaseText(session.parameters)) ..
        ' currentStamina=' .. tostring(session.currentStamina) ..
        ' maxStamina=' .. tostring(session.maxStamina) ..
        ' initialPercent=' .. tostring(session.initialStaminaPercent) ..
        ' lastStamina=' .. tostring(session.lastStaminaPercent) ..
        ' lastAction=' .. tostring(session.lastActionType) ..
        ' lastGold=' .. tostring(session.lastGoldArrowChance) ..
        ' queuedFish=' .. tostring(queuedFishCount) ..
        ' lastQueuedFishAgo=' .. tostring(lastQueuedFishClock > 0 and string.format('%.1f', os.clock() - lastQueuedFishClock) or 'nil') ..
        ' lastQueuedFishSource=' .. tostring(lastQueuedFishSource) ..
        ' lastQueuedFishStatus=' .. tostring(lastQueuedFishStatus);
end

local function StripControlCodes(text)
    return tostring(text or ''):gsub(string.char(0x1E) .. '.', ''):gsub('[%z\1-\31]', '');
end

function fishing.HandleTextIn(e)
    local message = StripControlCodes(
        (e ~= nil and (e.message_modified or e.message or e.text or e.original or e.injected)) or ''
    );

    if (message == '') then
        return;
    end

    local requestedVentureLine = IsRecentRequestedVentureLine(message);
    if (UpdateVentureFromMessage(message) == true or requestedVentureLine == true) then
        local now = os.clock();
        if ((now - (tonumber(venture.requestedClock) or 0)) < 12.0) then
            e.blocked = true;
            return true;
        end
    end

    if (UpdateFatigueFromMessage(message) == true) then
        local now = os.clock();
        if (fatigue.pending == false and (now - (tonumber(fatigue.requestedClock) or 0)) < 8.0) then
            e.blocked = true;
            return true;
        end
    end

    local isLocalFishingLine = IsLocalFishingMessage(message) == true;
    local revealedCatchName = isLocalFishingLine == true and ExtractRevealedCatchName(message) or nil;
    if (revealedCatchName ~= nil) then
        currentCatchName = revealedCatchName;
        currentCatchClock = os.clock();
        TouchHud();
    end

    if (message:find('You cannot use that command at this time.', 1, true) ~= nil) then
        local now = os.clock();

        if ((now - lastCommandErrorClock) <= 2.5) then
            commandErrorRepeatCount = commandErrorRepeatCount + 1;
        else
            commandErrorRepeatCount = 1;
        end

        lastCommandErrorClock = now;

        commandErrorStormUntil = math.max(commandErrorStormUntil, now + 120);

        if (fishing.ShouldSuppressCommandErrorText() == true) then
            e.blocked = true;
            return true;
        end
    end

    local caughtName = ExtractCaughtName(message);
    local failedFishingResult =
        isLocalFishingLine == true and (
            message:find(" didn't catch anything", 1, true) ~= nil or
            message:find(' lost your catch', 1, true) ~= nil or
            message:find(' line broke', 1, true) ~= nil or
            message:find('Your line breaks', 1, true) ~= nil or
            message:find(' rod broke', 1, true) ~= nil or
            message:find('You give up', 1, true) ~= nil
        );

    if (
        caughtName ~= nil or
        failedFishingResult == true
    ) then
        if (caughtName ~= nil) then
            lastCatchName = caughtName;
            lastCatchClock = os.clock();
            currentCatchName = caughtName;
            currentCatchClock = lastCatchClock;
            sessionCatchCount = sessionCatchCount + 1;
            TouchHud();
        end

        session.active = false;
        if (failedFishingResult == true) then
            fishing.MarkFishingEnded(fishingFailureCooldownSeconds, true);
        else
            fishing.MarkFishingEnded(fishingSuccessCooldownSeconds);
        end
    end

    for _, result in ipairs(gutFeelingResults) do
        if (isLocalFishingLine == true and message:find(result.pattern, 1, true) ~= nil) then
            lastResult = result;
            lastResultClock = os.clock();
            lastFeelingLabel = result.label;
            lastFeelingClock = lastResultClock;
            TouchHud();
            return;
        end
    end
end

function fishing.ClearResult()
    lastResult = nil;
    lastResultClock = 0;
    session.active = false;
    session.parameters = nil;
    currentCatchName = nil;
    currentCatchClock = 0;
    session.lastStaminaPercent = nil;
    session.lastActionType = nil;
    session.lastGoldArrowChance = nil;
end

function fishing.GetResult()
    if (lastResult == nil) then
        return nil;
    end

    if ((os.clock() - lastResultClock) > resultTimeoutSeconds) then
        fishing.ClearResult();
        return nil;
    end

    return lastResult;
end

function fishing.GetHudRevision()
    return hudRevision;
end

function fishing.HasHudData()
    return IsSelfFishingStatus() == true or IsSelfFishingResultStatus() == true or fishing.IsSessionActive() == true or fishing.IsPostFishingLockout() == true or session.parameters ~= nil or fishing.GetResult() ~= nil or lastCatchName ~= nil;
end

function fishing.GetHudInfo(settings)
    settings = settings or {};

    local now = os.clock();
    if ((now - (tonumber(equipmentCache.clock) or 0)) > 1.0) then
        equipmentCache.rod = GetEquippedItemName(2) or '';
        equipmentCache.bait = GetEquippedItemName(3) or '';
        equipmentCache.baitCount = nil;

        if (equipmentCache.bait ~= '') then
            equipmentCache.baitCount = GetInventoryItemCount(equipmentCache.bait);
        end

        equipmentCache.clock = now;
    end

    local cooldown = fishing.GetPostFishingCooldown();
    local active = fishing.IsSessionActive() == true or IsTrackedSelfFishingStatus() == true;
    local status = 'Ready';
    if (cooldown.active == true) then
        status = 'Waiting';
        active = false;
    elseif (active == true) then
        status = 'Fishing';
        active = true;
    end

    local displayCatch = currentCatchName or lastCatchName;
    local zoneId = GetCurrentZoneId();
    local zoneName = GetCurrentZoneName();
    local targetInfo = nil;
    local targetOptions = {};
    if (fishingDatabase.GetTargetFishOptions ~= nil) then
        targetInfo = fishingDatabase.GetTargetFishOptions(zoneId, GetSelfPosition(), selectedTargetName);
        targetOptions = targetInfo ~= nil and targetInfo.options or {};
    end

    if (selectedTargetName ~= nil and type(targetOptions) == 'table' and #targetOptions > 0) then
        local selectedAvailable = false;
        for _, option in ipairs(targetOptions) do
            if (
                (selectedTargetId ~= nil and tonumber(option ~= nil and option.id) == selectedTargetId) or
                (selectedTargetId == nil and CleanName(option ~= nil and option.name):lower() == CleanName(selectedTargetName):lower())
            ) then
                selectedAvailable = true;
                if (selectedTargetId == nil and tonumber(option ~= nil and option.id) ~= nil) then
                    selectedTargetId = tonumber(option.id);
                end
                break;
            end
        end

        if (selectedAvailable ~= true) then
            selectedTargetName = nil;
            selectedTargetId = nil;
        end
    end

    local targetFish = selectedTargetName or displayCatch;
    local targetFishId = selectedTargetId;
    local recommendation = nil;
    if (targetFish ~= nil and fishingDatabase.GetRecommendation ~= nil) then
        recommendation = fishingDatabase.GetRecommendation(targetFish, equipmentCache.rod, equipmentCache.bait);
    end

    local rodOptions, baitOptions = GetGearOptions(zoneName, targetFish, targetFishId);

    local skill = nil;
    if (fishingDatabase.GetFishingSkill ~= nil) then
        skill = fishingDatabase.GetFishingSkill();
    end

    if (settings.showFatigue == true) then
        local mode = GetSelfGameMode();
        fatigue.mode = mode;
        if (SupportsFishingFatigue(mode) == true and (fatigue.updatedClock == 0 or (now - fatigue.updatedClock) > 300)) then
            RequestFatigue(settings, false);
        end
    end

    if (settings.showVentures ~= false and venture.updatedClock == 0 and venture.pending ~= true) then
        RequestVenture(false);
    end

    return {
        active = active,
        status = status,
        cooldown = cooldown,
        rod = equipmentCache.rod ~= '' and equipmentCache.rod or 'None',
        bait = equipmentCache.bait ~= '' and equipmentCache.bait or 'None',
        baitCount = equipmentCache.baitCount,
        recommendation = recommendation,
        target = selectedTargetName or 'Any',
        targetId = targetFishId,
        targetFish = targetFish,
        targetOptions = targetOptions,
        fishingArea = targetInfo ~= nil and targetInfo.area or nil,
        zoneId = zoneId,
        zone = zoneName,
        rodOptions = rodOptions,
        baitOptions = baitOptions,
        skill = skill,
        fatigue = FormatFatigue(),
        venture = settings.showVentures ~= false and FormatVenture(zoneName) or nil,
        currentCatch = currentCatchName,
        lastCatch = lastCatchName,
        totalCatches = sessionCatchCount,
        feeling = lastFeelingLabel,
        currentCatchAge = currentCatchClock > 0 and (os.clock() - currentCatchClock) or nil,
        feelingAge = lastFeelingClock > 0 and (os.clock() - lastFeelingClock) or nil,
        lastCatchAge = lastCatchClock > 0 and (os.clock() - lastCatchClock) or nil,
    };
end

local function IsKnownIcon(fileName)
    fileName = tostring(fileName or '');

    for _, iconFile in ipairs(iconFiles) do
        if (fileName == iconFile) then
            return true;
        end
    end

    return false;
end

local function GetIconTextureId(fileName)
    fileName = tostring(fileName or 'fishing_01.png');

    if (IsKnownIcon(fileName) ~= true) then
        fileName = 'fishing_01.png';
    end

    if (iconTextureIds[fileName] ~= nil) then
        return iconTextureIds[fileName];
    end

    local path = addon.path .. '\\assets\\images\\fishing\\' .. fileName;
    iconTextureIds[fileName] = textureLoader.ToTextureId(textureLoader.Load(path));
    return iconTextureIds[fileName];
end

function fishing.GetIconFiles()
    return iconFiles;
end

function fishing.GetTextureId(settings)
    settings = settings or {};

    local result = (settings.previewResult == true) and nil or fishing.GetResult();

    if (result == nil and settings.previewResult ~= true) then
        return nil;
    end

    local iconFile = (result ~= nil and result.iconFile) or settings.iconFile;

    return GetIconTextureId(iconFile);
end

function fishing.AddIcon(plateData, settings)
    local textureId = fishing.GetTextureId(settings);
    local result = (settings.previewResult == true) and nil or fishing.GetResult();

    if (plateData == nil or settings == nil or settings.enabled == false or textureId == nil) then
        return;
    end

    plateData.icons = plateData.icons or {};
    plateData.icons[#plateData.icons + 1] = {
        kind = 'fishing',
        textureId = textureId,
        size = math.max(6, math.min(200, tonumber(settings.iconSize) or 42)),
        offsetX = tonumber(settings.offsetX) or 0,
        offsetY = tonumber(settings.offsetY) or 38,
        timerText = (settings.showLabel ~= false and result ~= nil) and result.label or '',
        timerFontSize = math.max(4, tonumber(settings.labelFontSize) or 12),
        timerTextColor = settings.labelColor or { 1.0, 1.0, 1.0, 1.0 },
        timerTextOutline = (tonumber(settings.labelOutlineSize) or 2) > 0,
        timerTextOutlineColor = settings.labelOutlineColor or { 0.0, 0.0, 0.0, 1.0 },
        timerTextOutlineSize = tonumber(settings.labelOutlineSize) or 2,
        timerOffsetY = tonumber(settings.labelOffsetY) or 0,
    };
end

return fishing;
