require('common');

local bit = require('bit');

local bstCharmTimer = {};
local log = require('core.log');
local debugEnabled = false;
local lastCharmActionAt = 0;
local lastCharmActionTargetId = nil;
local lastCharmActionTargetIndex = nil;

local packetId = {
    outAction = 0x01A,
    outCheck = 0x0DD,
    inCheck = 0x029,
    inAction = 0x028,
};

local charmActionId = 0x34;
local familiarActionInfo = 0x618;

local charmState = {
    none = 0,
    waitingCheck = 1,
};

local charmGear = {
    [17936] = 1,
    [17950] = 2,
    [12517] = 4,
    [15157] = 5,
    [15158] = 6,
    [16104] = 5,
    [16105] = 6,
    [15080] = 5,
    [15233] = 4,
    [15253] = 5,
    [12646] = 5,
    [14418] = 5,
    [14419] = 6,
    [14566] = 5,
    [14567] = 6,
    [15095] = 6,
    [14481] = 6,
    [14508] = 7,
    [13969] = 3,
    [14850] = 5,
    [14851] = 6,
    [14981] = 5,
    [14982] = 6,
    [14898] = 3,
    [15110] = 4,
    [14917] = 4,
    [14222] = 6,
    [14319] = 5,
    [14320] = 6,
    [15645] = 5,
    [15646] = 6,
    [15125] = 2,
    [15569] = 6,
    [15588] = 2,
    [14097] = 2,
    [15307] = 5,
    [15308] = 6,
    [15731] = 5,
    [15732] = 6,
    [15360] = 2,
    [15140] = 3,
    [15673] = 3,
    [14658] = 4,
    [13667] = 5,
};

local levelModifiers = {
    [-6] = 0.04,
    [-5] = 0.08,
    [-4] = 0.12,
    [-3] = 0.16,
    [-2] = 0.33,
    [-1] = 0.66,
    [0] = 1.00,
    [1] = 1.40,
    [2] = 1.80,
    [3] = 2.20,
    [4] = 2.60,
    [5] = 3.00,
    [6] = 3.40,
    [7] = 4.00,
    [8] = 5.00,
    [9] = 6.00,
};

local function GetCachePath()
    local installPath = nil;

    pcall(function()
        installPath = AshitaCore:GetInstallPath();
    end);

    if (type(installPath) ~= 'string' or installPath == '') then
        return nil;
    end

    return installPath .. '\\config\\addons\\LibraPlates\\bst_charm_timer.cache';
end

local function LoadCachedCharmState()
    local path = GetCachePath();

    if (path == nil) then
        return nil;
    end

    local file = io.open(path, 'r');

    if (file == nil) then
        return nil;
    end

    local petServerId = tonumber(file:read('*l'));
    local petIndex = tonumber(file:read('*l'));
    local startTime = tonumber(file:read('*l'));
    local expireTime = tonumber(file:read('*l'));
    file:close();

    if (
        petServerId == nil or
        petIndex == nil or
        startTime == nil or
        expireTime == nil or
        expireTime <= os.time()
    ) then
        return nil;
    end

    return {
        petIndex = petIndex,
        petServerId = petServerId,
        petName = nil,
        petType = 'charm',
        startTime = startTime,
        expireTime = expireTime,
        recoverRequestedAt = nil,
        recoverPetServerId = nil,
        loadedFromCache = true,
    };
end

local function RemoveCachedCharmState()
    local path = GetCachePath();

    if (path ~= nil) then
        pcall(os.remove, path);
    end
end

local state = rawget(_G, 'LibraPlatesBstCharmTimerState');

if (type(state) ~= 'table') then
    state = LoadCachedCharmState() or {
        petIndex = nil,
        petServerId = nil,
        petName = nil,
        petType = nil,
        startTime = nil,
        expireTime = nil,
        recoverRequestedAt = nil,
        recoverPetServerId = nil,
    };
    _G.LibraPlatesBstCharmTimerState = state;
end

-- An addon reload can happen between sending and receiving a packet.  Keep
-- the Charm expiry, but restart the short-lived packet interception state.
state.packetState = charmState.none;
state.targetId = nil;
state.targetIndex = nil;
state.checkRequestedAt = nil;
state.pendingCharmTargetId = nil;
state.pendingCharmTargetIndex = nil;
state.pendingCharmUntil = nil;
state.cacheLoadClock = state.loadedFromCache == true and os.clock() or nil;

local function SaveCachedCharmState()
    if (
        state.petServerId == nil or
        state.petIndex == nil or
        state.startTime == nil or
        state.expireTime == nil
    ) then
        return;
    end

    local path = GetCachePath();

    if (path == nil) then
        return;
    end

    local file = io.open(path, 'w');

    if (file == nil) then
        return;
    end

    file:write(
        tostring(math.floor(tonumber(state.petServerId) or 0)), '\n',
        tostring(math.floor(tonumber(state.petIndex) or 0)), '\n',
        tostring(math.floor(tonumber(state.startTime) or 0)), '\n',
        tostring(math.floor(tonumber(state.expireTime) or 0)), '\n'
    );
    file:close();
    state.loadedFromCache = false;
    state.cacheLoadClock = nil;
end

local function GetPacketData(e)
    return (e ~= nil and (e.data_modified or e.data)) or nil;
end

local function Read(data, format, offset)
    local ok, value = pcall(function()
        return struct.unpack(format, data, offset + 1);
    end);

    if (ok ~= true) then
        return nil;
    end

    return tonumber(value);
end

local function ClearPet()
    local hadTrackedCharm = state.petServerId ~= nil or state.expireTime ~= nil or state.loadedFromCache == true;

    state.petIndex = nil;
    state.petServerId = nil;
    state.petName = nil;
    state.petType = nil;
    state.startTime = nil;
    state.expireTime = nil;
    state.loadedFromCache = false;
    state.cacheLoadClock = nil;
    state.pendingCharmTargetId = nil;
    state.pendingCharmTargetIndex = nil;
    state.pendingCharmUntil = nil;

    if (hadTrackedCharm == true) then
        RemoveCachedCharmState();
    end
end

local function GetCharmEquipValue()
    local inventory = AshitaCore:GetMemoryManager():GetInventory();
    local charmValue = 0;

    if (inventory == nil) then
        return 0;
    end

    for i = 0, 15 do
        local equippedItem = nil;
        pcall(function()
            equippedItem = inventory:GetEquippedItem(i);
        end);

        if (equippedItem ~= nil and equippedItem.Index ~= nil) then
            local index = bit.band(equippedItem.Index, 0x00FF);

            if (index > 0) then
                local container = bit.rshift(bit.band(equippedItem.Index, 0xFF00), 8);
                local item = nil;
                pcall(function()
                    item = inventory:GetContainerItem(container, index);
                end);

                if (item ~= nil and charmGear[item.Id] ~= nil) then
                    charmValue = charmValue + charmGear[item.Id];
                end
            end
        end
    end

    return charmValue;
end

local function CalculateCharmExpireTime(mobLevel)
    local player = AshitaCore:GetMemoryManager():GetPlayer();

    if (player == nil or mobLevel == nil) then
        if (debugEnabled == true) then
            log.Info(
                'Charm probe calculate player=' .. tostring(player ~= nil) ..
                ' mobLevel=' .. tostring(mobLevel)
            );
        end
        return nil;
    end

    local playerLevel = nil;
    local charisma = nil;

    pcall(function()
        playerLevel = player:GetMainJobLevel();
    end);

    pcall(function()
        charisma = player:GetStat(6);
    end);

    playerLevel = tonumber(playerLevel);
    charisma = tonumber(charisma);

    if (debugEnabled == true) then
        log.Info(
            'Charm probe calculate mobLevel=' .. tostring(mobLevel) ..
            ' playerLevel=' .. tostring(playerLevel) ..
            ' charisma=' .. tostring(charisma)
        );
    end

    if (playerLevel == nil or charisma == nil) then
        return nil;
    end

    local levelDifference = math.max(-6, math.min(9, playerLevel - mobLevel));
    local modifier = levelModifiers[levelDifference] or 0;
    local baseDuration = math.floor((1.25 * charisma) + 150);
    local duration = (baseDuration * modifier) * (1 + (0.05 * GetCharmEquipValue()));

    return os.time() + duration;
end

local function QueueHiddenCheck(targetId, targetIndex)
    if (targetId == nil or targetIndex == nil) then
        return false;
    end

    local packet = struct.pack(
        'BBBBIIBBBB',
        packetId.outCheck,
        0x04,
        0x00,
        0x00,
        tonumber(targetId) or 0,
        tonumber(targetIndex) or 0,
        0x00,
        0x00,
        0x00,
        0x00
    ):totable();
    local sent = pcall(function()
        AshitaCore:GetPacketManager():AddOutgoingPacket(packetId.outCheck, packet);
    end);

    if (debugEnabled == true) then
        log.Info(
            'Charm probe check-send targetId=' .. tostring(targetId) ..
            ' targetIndex=' .. tostring(targetIndex) ..
            ' sent=' .. tostring(sent)
        );
    end

    if (sent ~= true) then
        state.packetState = charmState.none;
        return false;
    end

    state.targetId = targetId;
    state.targetIndex = targetIndex;
    state.checkRequestedAt = os.time();
    state.packetState = charmState.waitingCheck;
    return true;
end

function bstCharmTimer.SyncPet(pet, isCharmedPet)
    if (
        state.packetState == charmState.waitingCheck and
        state.checkRequestedAt ~= nil and
        (os.time() - state.checkRequestedAt) >= 3
    ) then
        state.packetState = charmState.none;
        state.targetId = nil;
        state.targetIndex = nil;
        state.checkRequestedAt = nil;
    end

    if (pet == nil) then
        if (
            state.pendingCharmUntil ~= nil and
            os.clock() < state.pendingCharmUntil
        ) then
            return;
        end

        if (
            state.loadedFromCache == true and
            state.cacheLoadClock ~= nil and
            (os.clock() - state.cacheLoadClock) < 5
        ) then
            return;
        end

        if (state.packetState == charmState.none) then
            ClearPet();
        end
        return;
    end

    if (isCharmedPet ~= true) then
        ClearPet();
        return;
    end

    if (
        state.petIndex ~= pet.index or
        state.petServerId ~= pet.serverId or
        state.petName ~= pet.name
    ) then
        if (state.petServerId ~= nil and state.petServerId ~= pet.serverId) then
            state.startTime = nil;
            state.expireTime = nil;
            RemoveCachedCharmState();
        end

        state.petIndex = pet.index;
        state.petServerId = pet.serverId;
        state.petName = pet.name;
        state.petType = 'charm';
        state.startTime = state.startTime or os.time();
        state.loadedFromCache = false;
        state.cacheLoadClock = nil;

        if (state.expireTime ~= nil) then
            SaveCachedCharmState();
        end

        if (
            state.pendingCharmTargetId == nil or
            tonumber(state.pendingCharmTargetId) == tonumber(pet.serverId)
        ) then
            state.pendingCharmTargetId = nil;
            state.pendingCharmTargetIndex = nil;
            state.pendingCharmUntil = nil;
        end
    end
end

function bstCharmTimer.HandlePacketOut(e)
    if (e == nil or e.data == nil) then
        return;
    end

    if (e.id ~= packetId.outAction) then
        return;
    end

    local data = GetPacketData(e);
    local category = Read(data, 'H', 0x0A);
    local actionId = Read(data, 'I', 0x0C);

    if (debugEnabled == true and category == 0x09) then
        log.Info(
            'Charm probe action-out category=' .. tostring(category) ..
            ' actionId=' .. tostring(actionId) ..
            ' targetId=' .. tostring(Read(data, 'I', 0x04)) ..
            ' targetIndex=' .. tostring(Read(data, 'H', 0x08))
        );
    end

    if (category ~= 0x09 or actionId ~= charmActionId) then
        return;
    end

    local targetId = Read(data, 'I', 0x04);
    local targetIndex = Read(data, 'H', 0x08);
    local now = os.clock();

    if (
        targetId == lastCharmActionTargetId and
        targetIndex == lastCharmActionTargetIndex and
        (now - lastCharmActionAt) < 0.5
    ) then
        if (debugEnabled == true) then
            log.Info('Charm probe duplicate action suppressed.');
        end
        return;
    end

    lastCharmActionAt = now;
    lastCharmActionTargetId = targetId;
    lastCharmActionTargetIndex = targetIndex;
    state.pendingCharmTargetId = targetId;
    state.pendingCharmTargetIndex = targetIndex;
    state.pendingCharmUntil = now + 10;
    QueueHiddenCheck(targetId, targetIndex);
end

function bstCharmTimer.HandlePacketIn(e)
    if (e == nil or e.data == nil) then
        return;
    end

    if (e.id == packetId.inAction) then
        local playerEntity = GetPlayerEntity();

        if (playerEntity ~= nil and state.petType == 'charm') then
            local actorId = Read(e.data_modified or e.data, 'I', 0x05);
            local rawActionInfo = Read(e.data_modified or e.data, 'H', 0x0A);

            if (actorId == playerEntity.ServerId and rawActionInfo == familiarActionInfo and state.expireTime ~= nil) then
                state.expireTime = state.expireTime + 1500;
                SaveCachedCharmState();
            end
        end

        return;
    end

    if (e.id ~= packetId.inCheck or state.packetState ~= charmState.waitingCheck) then
        return;
    end

    local data = GetPacketData(e);
    local responseTargetId = Read(data, 'I', 0x08);
    local responseTargetIndex = Read(data, 'H', 0x16);

    if (debugEnabled == true) then
        log.Info(
            'Charm probe check-in targetId=' .. tostring(responseTargetId) ..
            ' targetIndex=' .. tostring(responseTargetIndex) ..
            ' expectedId=' .. tostring(state.targetId) ..
            ' expectedIndex=' .. tostring(state.targetIndex) ..
            ' param1=' .. tostring(Read(data, 'l', 0x0C)) ..
            ' param2=' .. tostring(Read(data, 'L', 0x10)) ..
            ' message=' .. tostring(Read(data, 'H', 0x18))
        );
    end

    if (
        responseTargetId ~= tonumber(state.targetId) or
        responseTargetIndex ~= tonumber(state.targetIndex)
    ) then
        return;
    end

    e.blocked = true;
    local param1 = Read(data, 'l', 0x0C);
    local param2 = Read(data, 'L', 0x10);
    local message = Read(data, 'H', 0x18);

    if (
        param1 ~= nil and
        (
            (message ~= nil and message >= 0xAA and message <= 0xB2) or
            (param2 ~= nil and param2 >= 0x40 and param2 <= 0x47)
        )
    ) then
        local expireTime = CalculateCharmExpireTime(param1);

        if (expireTime ~= nil) then
            state.startTime = os.time();
            state.expireTime = expireTime;
            state.petType = 'charm';
            SaveCachedCharmState();
        end
    end

    state.packetState = charmState.none;
    state.targetId = nil;
    state.targetIndex = nil;
    state.checkRequestedAt = nil;
end

function bstCharmTimer.GetRemainingSeconds()
    if (state.petType ~= 'charm' or state.expireTime == nil) then
        return nil;
    end

    -- Keep the signed estimate so the UI can show how long the same pet has
    -- remained charmed beyond the calculated expiry.
    return state.expireTime - os.time();
end

function bstCharmTimer.SetDebugEnabled(value)
    debugEnabled = value == true;
end

function bstCharmTimer.GetDebugStatusText()
    return 'Charm probe enabled=' .. tostring(debugEnabled) ..
        ' packetState=' .. tostring(state.packetState) ..
        ' petId=' .. tostring(state.petServerId) ..
        ' petIndex=' .. tostring(state.petIndex) ..
        ' start=' .. tostring(state.startTime) ..
        ' expire=' .. tostring(state.expireTime);
end

return bstCharmTimer;
